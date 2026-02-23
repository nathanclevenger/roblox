--!strict
--[[
	DirectorServer — Server-side action runner for choreographed video capture.

	Executed via run_script_in_play_mode during playtest.
	Template variables __TIMELINE_JSON__ and __DURATION__ are replaced by the orchestrator.

	Actions:
	  teleport_player      — set HumanoidRootPart.CFrame
	  entity_activate      — create/position entity model
	  entity_set_position  — move entity + fire EntityPositionUpdate remote
	  entity_transition    — fire EntityStateChanged remote
	  entity_target_player — make entity chase player direction
	  start_round / end_round — fire round remotes
	  teleport_to_stage    — DtE: move player to stage position
	  submit_drawing       — DtE: construct DrawingData and materialize
	  complete_stage       — DtE: fire stage completion
	  set_lighting         — modify Lighting properties
	  log_marker           — print sentinel marker for clip segmentation
	  run_luau             — execute arbitrary Luau code
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- Template placeholders (replaced by MCP director)
local TIMELINE_JSON_RAW = "__TIMELINE_JSON__"
local DURATION: number = __DURATION__

-- Parse actions
local actions: { any } = HttpService:JSONDecode(TIMELINE_JSON_RAW)

-- Sort by time
table.sort(actions, function(a, b)
	return a.time < b.time
end)

-- Sentinel markers
local SENTINEL_START = "__DIRECTOR_START"
local SENTINEL_END = "__DIRECTOR_END"

-- ── Helpers ─────────────────────────────────────────────

local function getPlayer(): Player?
	local players = Players:GetPlayers()
	if #players > 0 then
		return players[1]
	end
	return nil
end

local function getPlayerRootPart(): BasePart?
	local p = getPlayer()
	if p and p.Character then
		local hrp = p.Character:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			return hrp
		end
	end
	return nil
end

local function getRemotesFolder(): Folder?
	return ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
end

local function fireRemote(name: string, ...: any)
	local folder = getRemotesFolder()
	if not folder then
		warn("[DirectorServer] Remotes folder not found")
		return
	end
	local remote = folder:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		local p = getPlayer()
		if p then
			remote:FireClient(p, ...)
		end
	else
		warn(`[DirectorServer] Remote not found: {name}`)
	end
end

local function fireAllClientsRemote(name: string, ...: any)
	local folder = getRemotesFolder()
	if not folder then
		return
	end
	local remote = folder:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		remote:FireAllClients(...)
	end
end

-- ── Entity management ───────────────────────────────────

local function findEntityModel(name: string?): Model?
	local searchName = name or "ThePatient"
	local model = Workspace:FindFirstChild(searchName, true)
	if model and model:IsA("Model") then
		return model
	end
	return nil
end

local function createEntityModel(name: string, position: Vector3): Model
	-- Create a simple entity model for choreography purposes
	local model = Instance.new("Model")
	model.Name = name

	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(2, 5, 1)
	torso.Position = position
	torso.Anchored = true
	torso.CanCollide = false
	torso.Transparency = 0.5
	torso.Color = Color3.fromRGB(30, 30, 30)
	torso.Parent = model

	model.PrimaryPart = torso
	model.Parent = Workspace

	return model
end

-- ── Action executors ────────────────────────────────────

local actionExecutors: { [string]: (params: { [string]: any }) -> () } = {}

actionExecutors["teleport_player"] = function(params)
	local hrp = getPlayerRootPart()
	if hrp then
		local pos = params.position :: { x: number, y: number, z: number }
		hrp.CFrame = CFrame.new(pos.x, pos.y, pos.z)
		print(`[DirectorServer] Teleported player to {pos.x}, {pos.y}, {pos.z}`)
	end
end

actionExecutors["entity_activate"] = function(params)
	local name = (params.name :: string?) or "ThePatient"
	local pos = params.position :: { x: number, y: number, z: number }
	local position = Vector3.new(pos.x, pos.y, pos.z)

	local existing = findEntityModel(name)
	if existing then
		if existing.PrimaryPart then
			existing.PrimaryPart.CFrame = CFrame.new(position)
		end
	else
		createEntityModel(name, position)
	end

	-- Fire remote so client proximity fear picks it up
	fireRemote("EntityPositionUpdate", position, params.state or "Idle")
	print(`[DirectorServer] Entity '{name}' activated at {pos.x}, {pos.y}, {pos.z}`)
end

actionExecutors["entity_set_position"] = function(params)
	local name = (params.name :: string?) or "ThePatient"
	local pos = params.position :: { x: number, y: number, z: number }
	local position = Vector3.new(pos.x, pos.y, pos.z)
	local state = (params.state :: string?) or "Patrol"

	local model = findEntityModel(name)
	if model and model.PrimaryPart then
		model.PrimaryPart.CFrame = CFrame.new(position)
	end

	-- Fire remote so client proximity fear responds
	fireRemote("EntityPositionUpdate", position, state)
end

actionExecutors["entity_transition"] = function(params)
	local newState = params.state :: string
	fireAllClientsRemote("EntityStateChanged", newState)
	print(`[DirectorServer] Entity transition → {newState}`)
end

actionExecutors["entity_target_player"] = function(params)
	local name = (params.name :: string?) or "ThePatient"
	local model = findEntityModel(name)
	local hrp = getPlayerRootPart()

	if model and model.PrimaryPart and hrp then
		-- Face the entity toward the player
		local entityPos = model.PrimaryPart.Position
		local playerPos = hrp.Position
		local lookDir = (playerPos - entityPos).Unit
		model.PrimaryPart.CFrame = CFrame.lookAt(entityPos, entityPos + lookDir)
	end

	fireRemote("EntityStateChanged", params.state or "Hunt")
end

actionExecutors["start_round"] = function(_params)
	fireAllClientsRemote("RoundStarted")
	print("[DirectorServer] Round started")
end

actionExecutors["end_round"] = function(params)
	local outcome = (params.outcome :: string?) or "completed"
	fireAllClientsRemote("RoundEnded", outcome)
	print(`[DirectorServer] Round ended — {outcome}`)
end

actionExecutors["teleport_to_stage"] = function(params)
	local stageId = params.stageId :: number
	local hrp = getPlayerRootPart()
	if hrp then
		-- DtE stage positioning: each stage is 200 studs apart on Z axis
		local position = Vector3.new(0, 5, (stageId - 1) * 200)
		hrp.CFrame = CFrame.new(position)
		print(`[DirectorServer] Teleported to stage {stageId}`)
	end
end

actionExecutors["submit_drawing"] = function(params)
	-- Construct synthetic DrawingData and fire to server-side materializer
	local strokes = params.strokes :: { any }?
	local material = (params.material :: string?) or "wood"

	if not strokes then
		-- Default: simple bridge shape
		strokes = {
			{
				Points = { { X = 50, Y = 150 }, { X = 350, Y = 150 } },
				Color = { R = 0.6, G = 0.4, B = 0.2 },
				Thickness = 8,
				Material = material,
			},
		}
	end

	local drawingData = {
		Strokes = strokes,
		Width = 400,
		Height = 300,
	}

	-- Fire the drawing submission remote
	local folder = getRemotesFolder()
	if folder then
		local remote = folder:FindFirstChild("DrawingReceived")
		if remote and remote:IsA("RemoteEvent") then
			local p = getPlayer()
			if p then
				-- Server expects client to fire this, so we simulate it
				remote:FireServer(drawingData)
			end
		end
	end

	print(`[DirectorServer] Drawing submitted — {material}`)
end

actionExecutors["complete_stage"] = function(params)
	local stageId = params.stageId :: number
	local stars = (params.stars :: number?) or 3
	fireAllClientsRemote("StageComplete", stageId, stars)
	print(`[DirectorServer] Stage {stageId} completed — {stars} stars`)
end

actionExecutors["set_lighting"] = function(params)
	for key, value in params do
		local success = pcall(function()
			(Lighting :: any)[key] = value
		end)
		if not success then
			warn(`[DirectorServer] Failed to set Lighting.{key}`)
		end
	end
	print("[DirectorServer] Lighting updated")
end

actionExecutors["log_marker"] = function(params)
	local label = (params.label :: string?) or "marker"
	local time = (params.time :: number?) or 0
	print(`__MARKER__{label}__{time}__`)
end

actionExecutors["run_luau"] = function(params)
	local code = params.code :: string
	local fn = loadstring(code)
	if fn then
		local ok, err = pcall(fn)
		if not ok then
			warn(`[DirectorServer] run_luau error: {err}`)
		end
	else
		warn("[DirectorServer] Failed to compile run_luau code")
	end
end

-- ── Timeline execution ──────────────────────────────────

local function execute()
	-- Wait for player
	while #Players:GetPlayers() == 0 do
		task.wait(0.5)
	end
	task.wait(1) -- Extra buffer for character to spawn

	print(SENTINEL_START)
	print(`[DirectorServer] Starting choreography — {#actions} actions, {DURATION}s duration`)

	local startClock = os.clock()
	local actionIndex = 1

	-- Use Heartbeat for frame-accurate timing
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(_dt: number)
		local elapsed = os.clock() - startClock

		-- Execute all actions whose time has passed
		while actionIndex <= #actions do
			local action = actions[actionIndex]
			if action.time > elapsed then
				break
			end

			local executor = actionExecutors[action.type]
			if executor then
				local ok, err = pcall(executor, action.params or {})
				if not ok then
					warn(`[DirectorServer] Action error ({action.type} @ {action.time}s): {err}`)
				end
			else
				warn(`[DirectorServer] Unknown action type: {action.type}`)
			end

			actionIndex += 1
		end

		-- Check if we're past the total duration
		if elapsed >= DURATION then
			connection:Disconnect()
			print(`[DirectorServer] Choreography complete — {elapsed:.1f}s elapsed`)
			print(SENTINEL_END)
		end
	end)
end

-- Run
task.spawn(execute)

print(`[DirectorServer] Loaded — {#actions} actions, {DURATION}s total`)
