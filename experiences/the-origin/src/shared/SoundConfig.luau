--!strict
--# selene: allow(incorrect_standard_library_use)

--[[
	Sound configuration for The Origin.

	Asset IDs are placeholders — replace with actual uploaded audio asset IDs.
	Each entry defines a sound's properties for consistent use across client/server.
]]

export type SoundEntry = {
	assetId: string,
	volume: number,
	looped: boolean,
	rollOff: Enum.RollOffMode?,
	maxDistance: number?,
	group: string,
}

local SoundConfig = {
	-- Ambient
	HospitalAmbience = {
		assetId = "rbxassetid://9112854243", -- horror atmosphere
		volume = 0.3,
		looped = true,
		group = "Ambient",
	},
	BasementDrip = {
		assetId = "rbxassetid://1839580567", -- creepy ambience
		volume = 0.4,
		looped = true,
		rollOff = Enum.RollOffMode.InverseTapered,
		maxDistance = 40,
		group = "Ambient",
	},
	SteamVent = {
		assetId = "rbxassetid://3931575640", -- electrical buzz / hiss
		volume = 0.6,
		looped = false,
		rollOff = Enum.RollOffMode.InverseTapered,
		maxDistance = 30,
		group = "Ambient",
	},

	-- Player
	FootstepWalk = {
		assetId = "rbxassetid://9114367403", -- footstep concrete
		volume = 0.3,
		looped = false,
		group = "Player",
	},
	FootstepSprint = {
		assetId = "rbxassetid://9114367403", -- footstep concrete (louder)
		volume = 0.6,
		looped = false,
		group = "Player",
	},
	FootstepCrouch = {
		assetId = "rbxassetid://9114367785", -- footstep wood (soft)
		volume = 0.1,
		looped = false,
		group = "Player",
	},
	Breathing = {
		assetId = "rbxassetid://1837774870", -- wind ambience (breathing loop) -- TODO: find better sound
		volume = 0.5,
		looped = true,
		group = "Player",
	},
	BreathingPanic = {
		assetId = "rbxassetid://5765866884", -- tension building (panicked breathing)
		volume = 0.8,
		looped = true,
		group = "Player",
	},
	FlashlightClick = {
		assetId = "rbxassetid://6895079853", -- UI click
		volume = 0.4,
		looped = false,
		group = "Player",
	},
	Heartbeat = {
		assetId = "rbxassetid://9116260061", -- heartbeat
		volume = 0.6,
		looped = true,
		group = "Player",
	},

	-- Entity
	EntityFootstep = {
		assetId = "rbxassetid://9114368205", -- footstep metal (heavy entity steps)
		volume = 0.5,
		looped = false,
		rollOff = Enum.RollOffMode.InverseTapered,
		maxDistance = 60,
		group = "Entity",
	},
	EntityBreathing = {
		assetId = "rbxassetid://1843671399", -- eerie whisper (entity presence)
		volume = 0.4,
		looped = true,
		rollOff = Enum.RollOffMode.InverseTapered,
		maxDistance = 40,
		group = "Entity",
	},
	EntityChaseSound = {
		assetId = "rbxassetid://5766040688", -- scream (chase alert)
		volume = 0.8,
		looped = false,
		rollOff = Enum.RollOffMode.InverseTapered,
		maxDistance = 80,
		group = "Entity",
	},

	-- Proximity Fear (non-diegetic, client-only)
	SubBassDrone = {
		assetId = "rbxassetid://9112854440", -- dark ambient drone
		volume = 0.3,
		looped = true,
		group = "Fear",
	},
	DissonantStrings = {
		assetId = "rbxassetid://2785661376", -- scare chord (dissonant strings)
		volume = 0.5,
		looped = true,
		group = "Fear",
	},
	Whispers = {
		assetId = "rbxassetid://1843671399", -- eerie whisper
		volume = 0.4,
		looped = true,
		group = "Fear",
	},

	-- Environment
	DoorOpen = {
		assetId = "rbxassetid://876939830",
		volume = 0.5,
		looped = false,
		rollOff = Enum.RollOffMode.InverseTapered,
		maxDistance = 30,
		group = "Environment",
	},
	DoorSlam = {
		assetId = "rbxassetid://5766312844",
		volume = 0.8,
		looped = false,
		rollOff = Enum.RollOffMode.InverseTapered,
		maxDistance = 50,
		group = "Environment",
	},
	GlassCrunch = {
		assetId = "rbxassetid://4591720231",
		volume = 0.4,
		looped = false,
		rollOff = Enum.RollOffMode.InverseTapered,
		maxDistance = 25,
		group = "Environment",
	},
	MorgueDrawer = {
		assetId = "rbxassetid://4590657391",
		volume = 0.7,
		looped = false,
		rollOff = Enum.RollOffMode.InverseTapered,
		maxDistance = 35,
		group = "Environment",
	},
	GeneratorPull = {
		assetId = "rbxassetid://4590657391",
		volume = 0.9,
		looped = false,
		rollOff = Enum.RollOffMode.InverseTapered,
		maxDistance = 60,
		group = "Environment",
	},
	GeneratorRunning = {
		assetId = "rbxassetid://5766323235",
		volume = 0.7,
		looped = true,
		rollOff = Enum.RollOffMode.InverseTapered,
		maxDistance = 50,
		group = "Environment",
	},
	PhoneRing = {
		assetId = "rbxassetid://5766549480",
		volume = 0.6,
		looped = false,
		rollOff = Enum.RollOffMode.InverseTapered,
		maxDistance = 30,
		group = "Environment",
	},
	VendingMachine = {
		assetId = "rbxassetid://3931575640",
		volume = 0.5,
		looped = false,
		rollOff = Enum.RollOffMode.InverseTapered,
		maxDistance = 35,
		group = "Environment",
	},
}

return SoundConfig
