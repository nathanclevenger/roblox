--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Remote references (populated by init)
Remotes.EntityPositionUpdate = nil :: RemoteEvent?
Remotes.EntityStateChanged = nil :: RemoteEvent?
Remotes.SoundEvent = nil :: RemoteEvent?
Remotes.PlayerDamaged = nil :: RemoteEvent?
Remotes.ObjectiveUpdated = nil :: RemoteEvent?
Remotes.ObjectivesLoaded = nil :: RemoteEvent?
Remotes.ItemPickup = nil :: RemoteEvent?
Remotes.ItemPickupResult = nil :: RemoteEvent?
Remotes.UseItem = nil :: RemoteEvent?
Remotes.HidingEntered = nil :: RemoteEvent?
Remotes.HidingExited = nil :: RemoteEvent?
Remotes.HidingSpotChecked = nil :: RemoteEvent?
Remotes.GeneratorInteract = nil :: RemoteEvent?
Remotes.GeneratorStateUpdate = nil :: RemoteEvent?
Remotes.BeaconActivated = nil :: RemoteEvent?
Remotes.RoundStarted = nil :: RemoteEvent?
Remotes.RoundEnded = nil :: RemoteEvent?
Remotes.PlayerStateUpdate = nil :: RemoteEvent?
Remotes.FlashlightFlicker = nil :: RemoteEvent?
Remotes.TriggerScare = nil :: RemoteEvent?

-- Doors
Remotes.DoorInteract = nil :: RemoteEvent? -- client→server: player wants to interact with a door
Remotes.DoorStateChanged = nil :: RemoteEvent? -- server→client: door opened/closed/unlocked

-- Entity attack feedback
Remotes.EntityAttack = nil :: RemoteEvent? -- server→client: screen shake, red flash, impact sound
Remotes.EntityStun = nil :: RemoteEvent? -- server→client: brief stun notification

-- Lives / Death system
Remotes.PlayerDied = nil :: RemoteEvent?
Remotes.PlayerRespawned = nil :: RemoteEvent?
Remotes.HeartUpdate = nil :: RemoteEvent?
Remotes.CheckpointReached = nil :: RemoteEvent?

-- Spectator / CCTV
Remotes.EnterSpectator = nil :: RemoteEvent?
Remotes.ExitSpectator = nil :: RemoteEvent?
Remotes.CycleCCTVCamera = nil :: RemoteEvent?
Remotes.CCTVCameraUpdate = nil :: RemoteEvent?

-- Revive
Remotes.ReviveStarted = nil :: RemoteEvent?
Remotes.ReviveCompleted = nil :: RemoteEvent?

-- Notifications
Remotes.GameNotification = nil :: RemoteEvent?

function Remotes.init()
	-- Create container folder
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage

	-- Helper to create and register a RemoteEvent
	local function createRemote(name: string): RemoteEvent
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	end

	-- Create all remotes
	Remotes.EntityPositionUpdate = createRemote("EntityPositionUpdate")
	Remotes.EntityStateChanged = createRemote("EntityStateChanged")
	Remotes.SoundEvent = createRemote("SoundEvent")
	Remotes.PlayerDamaged = createRemote("PlayerDamaged")
	Remotes.ObjectiveUpdated = createRemote("ObjectiveUpdated")
	Remotes.ObjectivesLoaded = createRemote("ObjectivesLoaded")
	Remotes.ItemPickup = createRemote("ItemPickup")
	Remotes.ItemPickupResult = createRemote("ItemPickupResult")
	Remotes.UseItem = createRemote("UseItem")
	Remotes.HidingEntered = createRemote("HidingEntered")
	Remotes.HidingExited = createRemote("HidingExited")
	Remotes.HidingSpotChecked = createRemote("HidingSpotChecked")
	Remotes.GeneratorInteract = createRemote("GeneratorInteract")
	Remotes.GeneratorStateUpdate = createRemote("GeneratorStateUpdate")
	Remotes.BeaconActivated = createRemote("BeaconActivated")
	Remotes.RoundStarted = createRemote("RoundStarted")
	Remotes.RoundEnded = createRemote("RoundEnded")
	Remotes.PlayerStateUpdate = createRemote("PlayerStateUpdate")
	Remotes.FlashlightFlicker = createRemote("FlashlightFlicker")
	Remotes.TriggerScare = createRemote("TriggerScare")

	-- Doors
	Remotes.DoorInteract = createRemote("DoorInteract")
	Remotes.DoorStateChanged = createRemote("DoorStateChanged")

	-- Entity attack feedback
	Remotes.EntityAttack = createRemote("EntityAttack")
	Remotes.EntityStun = createRemote("EntityStun")

	-- Lives / Death system
	Remotes.PlayerDied = createRemote("PlayerDied")
	Remotes.PlayerRespawned = createRemote("PlayerRespawned")
	Remotes.HeartUpdate = createRemote("HeartUpdate")
	Remotes.CheckpointReached = createRemote("CheckpointReached")

	-- Spectator / CCTV
	Remotes.EnterSpectator = createRemote("EnterSpectator")
	Remotes.ExitSpectator = createRemote("ExitSpectator")
	Remotes.CycleCCTVCamera = createRemote("CycleCCTVCamera")
	Remotes.CCTVCameraUpdate = createRemote("CCTVCameraUpdate")

	-- Revive
	Remotes.ReviveStarted = createRemote("ReviveStarted")
	Remotes.ReviveCompleted = createRemote("ReviveCompleted")

	-- Notifications
	Remotes.GameNotification = createRemote("GameNotification")

	print("[Remotes] All remote events created")
end

return Remotes
