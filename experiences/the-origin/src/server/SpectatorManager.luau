--!strict

--[[
	Spectator Manager (Server)

	Manages players who have permanently died (lost all 3 hearts) in co-op.
	Dead players enter spectator mode with a CCTV camera system — they can
	watch surviving players through fixed cameras but cannot communicate.

	The CCTV system uses pre-defined camera positions per level. Spectators
	cycle between cameras with Q/E input sent via the CycleCCTVCamera remote.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)

local Remotes = require(script.Parent.Remotes)

-- Pre-defined CCTV camera positions per level
local CCTV_CAMERAS: { [string]: { Types.CCTVCamera } } = {
	["st-marens-hospital"] = {
		{
			id = "cam_01",
			name = "CAM 01 - RECEPTION",
			cframe = CFrame.new(5, 12, -2) * CFrame.Angles(math.rad(-30), math.rad(180), 0),
			level = "st-marens-hospital",
		},
		{
			id = "cam_02",
			name = "CAM 02 - GROUND CORRIDOR",
			cframe = CFrame.new(60, 10, 30) * CFrame.Angles(math.rad(-25), math.rad(-90), 0),
			level = "st-marens-hospital",
		},
		{
			id = "cam_03",
			name = "CAM 03 - EMERGENCY WARD",
			cframe = CFrame.new(40, 14, 15) * CFrame.Angles(math.rad(-35), math.rad(0), 0),
			level = "st-marens-hospital",
		},
		{
			id = "cam_04",
			name = "CAM 04 - UPPER HALLWAY",
			cframe = CFrame.new(60, 25, 60) * CFrame.Angles(math.rad(-20), math.rad(180), 0),
			level = "st-marens-hospital",
		},
		{
			id = "cam_05",
			name = "CAM 05 - BASEMENT",
			cframe = CFrame.new(30, -6, 45) * CFrame.Angles(math.rad(-15), math.rad(90), 0),
			level = "st-marens-hospital",
		},
		{
			id = "cam_06",
			name = "CAM 06 - ROOFTOP",
			cframe = CFrame.new(35, 40, 30) * CFrame.Angles(math.rad(-45), math.rad(0), 0),
			level = "st-marens-hospital",
		},
	},
}

local SpectatorManager = {}
SpectatorManager.__index = SpectatorManager

export type SpectatorManager = typeof(setmetatable(
	{} :: {
		spectators: { [Player]: boolean },
		cameraIndex: { [Player]: number },
		currentLevel: string?,
		storedCharacters: { [Player]: Model? },
	},
	SpectatorManager
))

--[[
	Create a new SpectatorManager and wire up the camera cycling remote.
]]
function SpectatorManager.new(): SpectatorManager
	local self = setmetatable({
		spectators = {},
		cameraIndex = {},
		currentLevel = nil,
		storedCharacters = {},
	}, SpectatorManager)

	-- Listen for camera cycle requests from spectating clients
	task.defer(function()
		if Remotes.CycleCCTVCamera then
			Remotes.CycleCCTVCamera.OnServerEvent:Connect(function(player: Player, direction: unknown)
				if not self.spectators[player] then
					return
				end

				-- Validate direction
				if typeof(direction) ~= "string" then
					return
				end

				local dir = direction :: string
				if dir ~= "next" and dir ~= "prev" then
					return
				end

				self:_cycleCamera(player, dir)
			end)
		end
	end)

	return self
end

--[[
	Set the current level so the correct CCTV cameras are used.
]]
function SpectatorManager.setLevel(self: SpectatorManager, levelName: string)
	self.currentLevel = levelName
end

--[[
	Transition a player into spectator mode after permanent death.
	Removes their character, sets up CCTV camera, and blocks communication.
]]
function SpectatorManager.enterSpectator(self: SpectatorManager, player: Player)
	if self.spectators[player] then
		return -- already spectating
	end

	self.spectators[player] = true

	-- Store reference to character before removing it
	local character = player.Character
	if character then
		self.storedCharacters[player] = character

		-- Make character invisible and intangible (effectively remove from game)
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				part.Transparency = 1
				part.CanCollide = false
			elseif part:IsA("Decal") or part:IsA("Texture") then
				(part :: Decal).Transparency = 1
			end
		end

		-- Disable the humanoid so the character can't move
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end

	-- Block text chat for this player
	self:_mutePlayer(player)

	-- Get CCTV cameras for the current level
	local levelCameras = self:_getLevelCameras()
	if #levelCameras == 0 then
		warn(`[SpectatorManager] No CCTV cameras found for level {self.currentLevel or "unknown"}`)
		return
	end

	-- Start on camera 1
	self.cameraIndex[player] = 1

	-- Serialize camera data for the client (CFrame can't be sent directly in some contexts)
	local serializedCameras = {}
	for _, cam in levelCameras do
		table.insert(serializedCameras, {
			id = cam.id,
			name = cam.name,
			cframe = cam.cframe,
			level = cam.level,
		})
	end

	-- Send spectator mode entry to client with all camera positions
	if Remotes.EnterSpectator then
		Remotes.EnterSpectator:FireClient(player, {
			cameras = serializedCameras,
			currentIndex = 1,
		})
	end

	print(`[SpectatorManager] {player.Name} entered spectator mode`)
end

--[[
	Exit spectator mode for a player (called when round ends).
	Restores normal camera mode and re-enables communication.
]]
function SpectatorManager.exitSpectator(self: SpectatorManager, player: Player)
	if not self.spectators[player] then
		return
	end

	self.spectators[player] = nil
	self.cameraIndex[player] = nil

	-- Restore character visibility if it still exists
	local storedCharacter = self.storedCharacters[player]
	if storedCharacter and storedCharacter.Parent then
		for _, part in storedCharacter:GetDescendants() do
			if part:IsA("BasePart") then
				part.Transparency = 0
				part.CanCollide = true
			elseif part:IsA("Decal") or part:IsA("Texture") then
				(part :: Decal).Transparency = 0
			end
		end

		local humanoid = storedCharacter:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Constants.SPEED_WALK
			humanoid.JumpPower = 50
		end
	end
	self.storedCharacters[player] = nil

	-- Re-enable communication
	self:_unmutePlayer(player)

	-- Tell client to exit spectator mode
	if Remotes.ExitSpectator then
		Remotes.ExitSpectator:FireClient(player, {})
	end

	print(`[SpectatorManager] {player.Name} exited spectator mode`)
end

--[[
	Exit all spectators (called at round end).
]]
function SpectatorManager.exitAllSpectators(self: SpectatorManager)
	-- Collect keys first to avoid modifying table during iteration
	local spectatorList: { Player } = {}
	for player in self.spectators do
		table.insert(spectatorList, player)
	end

	for _, player in spectatorList do
		self:exitSpectator(player)
	end
end

--[[
	Get a list of all players currently in spectator mode.
]]
function SpectatorManager.getSpectators(self: SpectatorManager): { Player }
	local result: { Player } = {}
	for player in self.spectators do
		table.insert(result, player)
	end
	return result
end

--[[
	Check if a specific player is currently spectating.
]]
function SpectatorManager.isSpectating(self: SpectatorManager, player: Player): boolean
	return self.spectators[player] == true
end

--[[
	Clean up state for a player who is leaving.
]]
function SpectatorManager.removePlayer(self: SpectatorManager, player: Player)
	self.spectators[player] = nil
	self.cameraIndex[player] = nil
	self.storedCharacters[player] = nil
end

--[[
	Cycle the CCTV camera for a spectating player.
]]
function SpectatorManager._cycleCamera(self: SpectatorManager, player: Player, direction: string)
	local cameras = self:_getLevelCameras()
	if #cameras == 0 then
		return
	end

	local currentIndex = self.cameraIndex[player] or 1

	if direction == "next" then
		currentIndex += 1
		if currentIndex > #cameras then
			currentIndex = 1
		end
	elseif direction == "prev" then
		currentIndex -= 1
		if currentIndex < 1 then
			currentIndex = #cameras
		end
	end

	self.cameraIndex[player] = currentIndex

	local camera = cameras[currentIndex]

	-- Send camera update to client
	if Remotes.CCTVCameraUpdate then
		Remotes.CCTVCameraUpdate:FireClient(player, {
			cframe = camera.cframe,
			name = camera.name,
			index = currentIndex,
			total = #cameras,
		})
	end
end

--[[
	Get the CCTV cameras for the current level.
]]
function SpectatorManager._getLevelCameras(self: SpectatorManager): { Types.CCTVCamera }
	if not self.currentLevel then
		return {}
	end

	return CCTV_CAMERAS[self.currentLevel] or {}
end

--[[
	Mute a player's text chat. In a real implementation this would also
	disable voice chat via the VoiceChatService API.
]]
function SpectatorManager._mutePlayer(self: SpectatorManager, player: Player)
	-- Attempt to mute via TextChatService (modern chat system)
	local success, err = pcall(function()
		local textChannels = TextChatService:FindFirstChild("TextChannels")
		if textChannels then
			for _, channel in textChannels:GetChildren() do
				if channel:IsA("TextChannel") then
					-- Remove player from channel sources if possible
					for _, source in channel:GetChildren() do
						if source:IsA("TextSource") and source.UserId == player.UserId then
							source.CanSend = false
						end
					end
				end
			end
		end
	end)

	if not success then
		warn(`[SpectatorManager] Failed to mute {player.Name}: {err}`)
	end

	print(`[SpectatorManager] Muted {player.Name}`)
end

--[[
	Unmute a player's text chat and voice chat.
]]
function SpectatorManager._unmutePlayer(self: SpectatorManager, player: Player)
	local success, err = pcall(function()
		local textChannels = TextChatService:FindFirstChild("TextChannels")
		if textChannels then
			for _, channel in textChannels:GetChildren() do
				if channel:IsA("TextChannel") then
					for _, source in channel:GetChildren() do
						if source:IsA("TextSource") and source.UserId == player.UserId then
							source.CanSend = true
						end
					end
				end
			end
		end
	end)

	if not success then
		warn(`[SpectatorManager] Failed to unmute {player.Name}: {err}`)
	end

	print(`[SpectatorManager] Unmuted {player.Name}`)
end

return SpectatorManager
