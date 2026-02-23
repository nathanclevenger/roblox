--!strict
--[[
	EventLogger — Injected into Roblox Studio via MCP run_code during capture sessions.
	Records game events from RemoteEvents and StateMachine transitions,
	then outputs them as JSON via print() between sentinel markers.

	This script does NOT modify game source — it only listens to existing remotes.
	Designed to be executed via: MCP run_code (paste entire file contents)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Sentinels for parsing events from console output
local SENTINEL_START = "__ORIGIN_EVENTS_START__"
local SENTINEL_END = "__ORIGIN_EVENTS_END__"

-- Event storage
local events: { any } = {}
local roundStartTime: number = 0
local isRecording = false
local lastEntityPosition: Vector3? = nil
local lastEntityState: string? = nil
local lastFearTier: string = "Safe"
local positionSampleTimer: number = 0
local POSITION_SAMPLE_INTERVAL = 0.25 -- 4Hz sampling

-- Fear tier calculation (mirrors ProximityFear/init.luau thresholds)
local FEAR_SAFE = 80
local FEAR_UNEASE = 50
local FEAR_DREAD = 25
local FEAR_PANIC = 10

local function getTimestamp(): number
	return os.clock() - roundStartTime
end

local function vec3ToTable(v: Vector3): { x: number, y: number, z: number }
	return { x = v.X, y = v.Y, z = v.Z }
end

local function recordEvent(eventType: string, data: { [string]: any })
	if not isRecording then
		return
	end
	table.insert(events, {
		type = eventType,
		timestamp = getTimestamp(),
		data = data,
	})
end

local function getFearTier(distance: number): (string, number)
	if distance >= FEAR_SAFE then
		return "Safe", 0
	elseif distance >= FEAR_UNEASE then
		local t = 1 - (distance - FEAR_UNEASE) / (FEAR_SAFE - FEAR_UNEASE)
		return "Unease", t * 0.25
	elseif distance >= FEAR_DREAD then
		local t = 1 - (distance - FEAR_DREAD) / (FEAR_UNEASE - FEAR_DREAD)
		return "Dread", 0.25 + t * 0.25
	elseif distance >= FEAR_PANIC then
		local t = 1 - (distance - FEAR_PANIC) / (FEAR_DREAD - FEAR_PANIC)
		return "Panic", 0.5 + t * 0.25
	else
		local t = 1 - distance / FEAR_PANIC
		return "Proximity", 0.75 + t * 0.25
	end
end

-- Wait for Remotes folder
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not remotesFolder then
	warn("[EventLogger] Remotes folder not found in ReplicatedStorage — aborting")
	return
end

local function getRemote(name: string): RemoteEvent?
	local remote = remotesFolder:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote :: RemoteEvent
	end
	return nil
end

-- Hook EntityPositionUpdate (server fires to all clients)
-- We listen on client side — the remote fires position + state
local entityPosRemote = getRemote("EntityPositionUpdate")
if entityPosRemote then
	entityPosRemote.OnClientEvent:Connect(function(position: Vector3, state: string)
		lastEntityPosition = position
		lastEntityState = state

		-- Calculate fear tier based on local player distance
		local player = Players.LocalPlayer
		if player and player.Character then
			local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
				local distance = (humanoidRootPart.Position - position).Magnitude
				local tier, intensity = getFearTier(distance)

				-- Record fear tier changes
				if tier ~= lastFearTier then
					recordEvent("FearTierChanged", {
						from = lastFearTier,
						to = tier,
						distance = math.floor(distance * 10) / 10,
						intensity = math.floor(intensity * 1000) / 1000,
					})
					lastFearTier = tier
				end
			end
		end
	end)
end

-- Hook EntityStateChanged
local entityStateRemote = getRemote("EntityStateChanged")
if entityStateRemote then
	entityStateRemote.OnClientEvent:Connect(function(newState: string)
		local oldState = lastEntityState or "Unknown"
		recordEvent("EntityStateChanged", {
			from = oldState,
			to = newState,
		})
		lastEntityState = newState
	end)
end

-- Hook HidingEntered / HidingExited
local hidingEnteredRemote = getRemote("HidingEntered")
if hidingEnteredRemote then
	hidingEnteredRemote.OnClientEvent:Connect(function(spotType: string, spotId: string)
		recordEvent("HidingEntered", {
			spotType = spotType,
			spotId = spotId,
		})
	end)
end

local hidingExitedRemote = getRemote("HidingExited")
if hidingExitedRemote then
	hidingExitedRemote.OnClientEvent:Connect(function(spotType: string, spotId: string)
		recordEvent("HidingExited", {
			spotType = spotType,
			spotId = spotId,
		})
	end)
end

-- Hook HidingSpotChecked
local hidingCheckedRemote = getRemote("HidingSpotChecked")
if hidingCheckedRemote then
	hidingCheckedRemote.OnClientEvent:Connect(function(spotId: string, found: boolean)
		recordEvent("HidingSpotChecked", {
			spotId = spotId,
			playerFound = found,
		})
	end)
end

-- Hook PlayerDamaged
local playerDamagedRemote = getRemote("PlayerDamaged")
if playerDamagedRemote then
	playerDamagedRemote.OnClientEvent:Connect(function(health: number, isDowned: boolean)
		recordEvent("PlayerDamaged", {
			health = health,
			isDowned = isDowned,
		})
		if isDowned then
			recordEvent("PlayerDeath", {
				health = 0,
				isDowned = true,
			})
		end
	end)
end

-- Hook GeneratorInteract
local genInteractRemote = getRemote("GeneratorInteract")
if genInteractRemote then
	genInteractRemote.OnClientEvent:Connect(function(generatorId: string)
		recordEvent("GeneratorInteract", {
			generatorId = generatorId,
		})
	end)
end

-- Hook GeneratorStateUpdate
local genStateRemote = getRemote("GeneratorStateUpdate")
if genStateRemote then
	genStateRemote.OnClientEvent:Connect(function(generatorId: string, active: boolean, totalActive: number, totalRequired: number)
		recordEvent("GeneratorStateUpdate", {
			generatorId = generatorId,
			active = active,
			totalActive = totalActive,
			totalRequired = totalRequired,
		})
	end)
end

-- Hook RoundStarted
local roundStartRemote = getRemote("RoundStarted")
if roundStartRemote then
	roundStartRemote.OnClientEvent:Connect(function()
		roundStartTime = os.clock()
		isRecording = true
		events = {}
		lastFearTier = "Safe"
		recordEvent("RoundStarted", {})
		print("[EventLogger] Recording started")
	end)
end

-- Hook RoundEnded
local roundEndRemote = getRemote("RoundEnded")
if roundEndRemote then
	roundEndRemote.OnClientEvent:Connect(function(outcome: string?)
		recordEvent("RoundEnded", {
			outcome = outcome or "unknown",
			duration = getTimestamp(),
			totalEvents = #events,
		})
		isRecording = false

		-- Flush events to console
		local json = HttpService:JSONEncode(events)
		print(SENTINEL_START .. json .. SENTINEL_END)
		print(`[EventLogger] Recording stopped — {#events} events captured`)
	end)
end

-- Hook PlayerStateUpdate for stamina/sprint tracking
local playerStateRemote = getRemote("PlayerStateUpdate")
if playerStateRemote then
	playerStateRemote.OnClientEvent:Connect(function(state: { [string]: any })
		recordEvent("PlayerStateUpdate", state)
	end)
end

-- Capture [StateMachine] logs from LogService
LogService.MessageOut:Connect(function(message: string, messageType: Enum.MessageType)
	if not isRecording then
		return
	end
	-- Match "[StateMachine] Transition: Patrol -> Chase (reason: player spotted)"
	local from, to, reason = string.match(message, "%[StateMachine%] Transition: (%w+) %-> (%w+) %(reason: (.-)%)")
	if from and to then
		recordEvent("StateMachineTransition", {
			from = from,
			to = to,
			reason = reason or "",
		})
	end
end)

-- Sample entity position at 4Hz via RenderStepped
RunService.RenderStepped:Connect(function(dt: number)
	if not isRecording then
		return
	end

	positionSampleTimer += dt
	if positionSampleTimer >= POSITION_SAMPLE_INTERVAL then
		positionSampleTimer = 0

		if lastEntityPosition and lastEntityState then
			recordEvent("EntityPosition", {
				position = vec3ToTable(lastEntityPosition),
				state = lastEntityState,
			})
		end
	end
end)

-- Manual flush command — call from console: EventLogger:Flush()
local module = {}

function module.Flush()
	local json = HttpService:JSONEncode(events)
	print(SENTINEL_START .. json .. SENTINEL_END)
	print(`[EventLogger] Manual flush — {#events} events`)
end

function module.Start()
	roundStartTime = os.clock()
	isRecording = true
	events = {}
	lastFearTier = "Safe"
	print("[EventLogger] Manual recording start")
end

function module.Stop()
	isRecording = false
	module.Flush()
	print("[EventLogger] Manual recording stop")
end

function module.GetEventCount(): number
	return #events
end

-- Expose globally for manual console control
_G.EventLogger = module

print(`[EventLogger] Initialized — listening on {#remotesFolder:GetChildren()} remotes`)
