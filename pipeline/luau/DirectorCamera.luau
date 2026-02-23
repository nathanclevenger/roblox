--!strict
--[[
	DirectorCamera — Client-side camera controller for choreographed video capture.

	Injected into StarterPlayerScripts BEFORE playtest starts.
	Template variables __CAMERA_JSON__ and __SETUP_DELAY__ are replaced by the orchestrator.

	Modes:
	  first_person  — releases camera to default (player controls)
	  follow_player — offset from local player's HumanoidRootPart
	  follow_entity — offset from named entity model in workspace
	  scripted      — exact position + lookAt interpolation between keyframes
	  fixed         — hold at a fixed position/lookAt (no interpolation)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

-- Template placeholders (replaced by MCP director)
local CAMERA_JSON_RAW = "__CAMERA_JSON__"
local SETUP_DELAY: number = __SETUP_DELAY__

-- Parse keyframes
local keyframes: { any } = HttpService:JSONDecode(CAMERA_JSON_RAW)

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local startTime: number = 0
local isRunning = false

-- ── Easing functions ────────────────────────────────────

local function easeLinear(t: number): number
	return t
end

local function easeIn(t: number): number
	return t * t
end

local function easeOut(t: number): number
	return 1 - (1 - t) * (1 - t)
end

local function easeInOut(t: number): number
	if t < 0.5 then
		return 2 * t * t
	else
		return 1 - (-2 * t + 2) ^ 2 / 2
	end
end

local easingFunctions: { [string]: (number) -> number } = {
	linear = easeLinear,
	ease_in = easeIn,
	ease_out = easeOut,
	ease_in_out = easeInOut,
}

-- ── Helpers ─────────────────────────────────────────────

local function tableToVec3(t: { x: number, y: number, z: number }?): Vector3?
	if not t then
		return nil
	end
	return Vector3.new(t.x, t.y, t.z)
end

local function lerpVec3(a: Vector3, b: Vector3, t: number): Vector3
	return a + (b - a) * t
end

local function lerpNumber(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function getPlayerPosition(): Vector3?
	if not player.Character then
		return nil
	end
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp.Position
	end
	return nil
end

local function getEntityModel(name: string?): Model?
	local searchName = name or "ThePatient"
	local model = Workspace:FindFirstChild(searchName, true)
	if model and model:IsA("Model") then
		return model
	end
	return nil
end

local function getEntityPosition(name: string?): Vector3?
	local model = getEntityModel(name)
	if model then
		local primaryPart = model.PrimaryPart
		if primaryPart then
			return primaryPart.Position
		end
		-- Fallback: use any BasePart child
		for _, child in model:GetChildren() do
			if child:IsA("BasePart") then
				return child.Position
			end
		end
	end
	return nil
end

-- ── Keyframe interpolation ──────────────────────────────

-- Find surrounding keyframes for a given time
local function findKeyframes(elapsed: number): (any?, any?, number)
	local prev = nil
	local next_ = nil

	for _, kf in keyframes do
		if kf.time <= elapsed then
			prev = kf
		end
		if kf.time > elapsed and not next_ then
			next_ = kf
			break
		end
	end

	-- Edge cases
	if not prev and not next_ then
		return nil, nil, 0
	end
	if not prev then
		return next_, next_, 1
	end
	if not next_ then
		return prev, prev, 0
	end

	-- Calculate interpolation factor
	local span = next_.time - prev.time
	if span <= 0 then
		return prev, next_, 1
	end

	local rawT = (elapsed - prev.time) / span

	-- Apply easing from the next keyframe
	local easingName = next_.easing or "linear"
	local easingFn = easingFunctions[easingName] or easeLinear
	local t = easingFn(math.clamp(rawT, 0, 1))

	return prev, next_, t
end

-- ── Camera update ───────────────────────────────────────

local function updateCamera(elapsed: number)
	local prev, next_, t = findKeyframes(elapsed)

	if not prev then
		return
	end

	-- Determine active mode from the most recent keyframe
	local mode = prev.mode or "scripted"
	local fov = prev.fov or 70

	-- Interpolate FOV if next keyframe has one
	if next_ and next_.fov then
		fov = lerpNumber(prev.fov or 70, next_.fov, t)
	end

	camera.FieldOfView = fov

	if mode == "first_person" then
		-- Release camera to default
		camera.CameraType = Enum.CameraType.Custom
		return
	end

	-- Take control
	camera.CameraType = Enum.CameraType.Scriptable

	if mode == "follow_player" then
		local playerPos = getPlayerPosition()
		if playerPos then
			local offset = tableToVec3(prev.followOffset) or Vector3.new(0, 5, -10)
			local camPos = playerPos + offset
			camera.CFrame = CFrame.lookAt(camPos, playerPos)
		end
		return
	end

	if mode == "follow_entity" then
		local entityPos = getEntityPosition(prev.followTarget)
		if entityPos then
			local offset = tableToVec3(prev.followOffset) or Vector3.new(0, 5, -10)
			local camPos = entityPos + offset
			camera.CFrame = CFrame.lookAt(camPos, entityPos)
		end
		return
	end

	-- scripted or fixed mode: interpolate position and lookAt
	local prevPos = tableToVec3(prev.position)
	local prevLookAt = tableToVec3(prev.lookAt)
	local nextPos = if next_ then tableToVec3(next_.position) else nil
	local nextLookAt = if next_ then tableToVec3(next_.lookAt) else nil

	local camPos: Vector3
	local lookAt: Vector3

	if prevPos and nextPos then
		camPos = lerpVec3(prevPos, nextPos, t)
	elseif prevPos then
		camPos = prevPos
	else
		return -- no position data
	end

	if prevLookAt and nextLookAt then
		lookAt = lerpVec3(prevLookAt, nextLookAt, t)
	elseif prevLookAt then
		lookAt = prevLookAt
	else
		-- Default: look slightly ahead from camera position
		lookAt = camPos + Vector3.new(0, 0, -10)
	end

	camera.CFrame = CFrame.lookAt(camPos, lookAt)
end

-- ── Lifecycle ───────────────────────────────────────────

-- Wait for character spawn
local function waitForCharacter()
	if player.Character then
		return
	end
	player.CharacterAdded:Wait()
end

-- Main loop
local function start()
	waitForCharacter()

	print("[DirectorCamera] Waiting setup delay:", SETUP_DELAY, "seconds")
	task.wait(SETUP_DELAY)

	print("[DirectorCamera] Starting camera choreography")
	startTime = os.clock()
	isRunning = true

	-- Find total duration from last keyframe
	local totalDuration = 0
	for _, kf in keyframes do
		if kf.time > totalDuration then
			totalDuration = kf.time
		end
	end
	totalDuration += 2 -- 2s buffer after last keyframe

	RunService.RenderStepped:Connect(function(_dt: number)
		if not isRunning then
			return
		end

		local elapsed = os.clock() - startTime
		if elapsed > totalDuration then
			isRunning = false
			camera.CameraType = Enum.CameraType.Custom
			print("[DirectorCamera] Choreography complete")
			return
		end

		updateCamera(elapsed)
	end)
end

-- Start
task.spawn(start)

print(`[DirectorCamera] Loaded — {#keyframes} keyframes, setup delay {SETUP_DELAY}s`)
