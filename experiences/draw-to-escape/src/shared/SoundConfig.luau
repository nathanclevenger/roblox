--!strict

--[[
	SoundConfig — Central registry for all music and SFX in Draw to Escape.
	Each entry defines a Roblox asset ID, default volume, and optional looping.
	Zone music aligns with the 10 zones defined in ZoneThemes and Constants.
]]

local SoundConfig = {}

-- Types
export type SoundEntry = {
	Id: string,
	Volume: number,
	Looped: boolean?,
	PlaybackSpeed: number?,
}

-- ================================================================
-- ZONE MUSIC
-- One looping track per zone, cross-faded by SoundManager.
-- ================================================================

SoundConfig.Music = {
	-- Zone 1: The Sketch Fields — bright, cheerful, hand-drawn tutorial zone
	[1] = { Id = "rbxassetid://1837849285", Volume = 0.3, Looped = true },
	-- Zone 2: The Paper Forest — warm, organic, gentle woodwind feel
	[2] = { Id = "rbxassetid://1839879882", Volume = 0.3, Looped = true },
	-- Zone 3: The Crayon Caverns — dark, mysterious underground
	[3] = { Id = "rbxassetid://1839894436", Volume = 0.25, Looped = true },
	-- Zone 4: The Watercolor Wetlands — flowing, aquatic, calm but tense
	[4] = { Id = "rbxassetid://1838260727", Volume = 0.3, Looped = true },
	-- Zone 5: The Ink Ruins — ancient, brooding, heavy drums
	[5] = { Id = "rbxassetid://1839879882", Volume = 0.35, Looped = true, PlaybackSpeed = 0.85 },
	-- Zone 6: The Neon Grid — electronic, pulsing, synthwave
	[6] = { Id = "rbxassetid://1838260727", Volume = 0.35, Looped = true, PlaybackSpeed = 1.1 },
	-- Zone 7: The Storm Peaks — harsh, epic, orchestral tension
	[7] = { Id = "rbxassetid://1837849285", Volume = 0.3, Looped = true, PlaybackSpeed = 0.9 },
	-- Zone 8: The Living Canvas — surreal, unsettling, slow pulse
	[8] = { Id = "rbxassetid://1839894436", Volume = 0.3, Looped = true, PlaybackSpeed = 0.75 },
	-- Zone 9: The Void — minimal, sparse, echoing tones
	[9] = { Id = "rbxassetid://1839879882", Volume = 0.2, Looped = true, PlaybackSpeed = 0.6 },
	-- Zone 10: The Cliff — epic finale, dramatic crescendo
	[10] = { Id = "rbxassetid://1837849285", Volume = 0.4, Looped = true, PlaybackSpeed = 1.15 },
} :: { [number]: SoundEntry }

-- ================================================================
-- SOUND EFFECTS
-- One-shot sounds triggered by game events.
-- ================================================================

SoundConfig.SFX = {
	-- Drawing interaction
	DrawStart = { Id = "rbxassetid://9125402735", Volume = 0.4, PlaybackSpeed = 1.2 },
	DrawStroke = { Id = "rbxassetid://9125402735", Volume = 0.2, PlaybackSpeed = 0.8 },
	Materialize = { Id = "rbxassetid://9126254421", Volume = 0.6 },
	DrawingDespawn = { Id = "rbxassetid://9125402735", Volume = 0.25, PlaybackSpeed = 0.6 },

	-- Stage progression
	StageComplete = { Id = "rbxassetid://9125959830", Volume = 0.7, PlaybackSpeed = 1.3 },
	StarEarned = { Id = "rbxassetid://9125959830", Volume = 0.5, PlaybackSpeed = 1.5 },
	VictoryFanfare = { Id = "rbxassetid://9125959830", Volume = 0.8 },

	-- Death and danger
	Death = { Id = "rbxassetid://9126254421", Volume = 0.8, PlaybackSpeed = 0.7 },
	Jumpscare = { Id = "rbxassetid://9125959830", Volume = 1.0, PlaybackSpeed = 0.5 },
	EnemyGrowl = { Id = "rbxassetid://9126254421", Volume = 0.6, PlaybackSpeed = 0.6 },
	TimerWarning = { Id = "rbxassetid://9125959830", Volume = 0.6, PlaybackSpeed = 1.8 },

	-- UI interaction
	ButtonPress = { Id = "rbxassetid://9125402735", Volume = 0.5, PlaybackSpeed = 1.4 },
	HintReveal = { Id = "rbxassetid://9125402735", Volume = 0.3, PlaybackSpeed = 1.0 },

	-- World interaction
	GateOpen = { Id = "rbxassetid://9125402735", Volume = 0.6, PlaybackSpeed = 0.5 },
	Crumble = { Id = "rbxassetid://9125402735", Volume = 0.5, PlaybackSpeed = 0.7 },
	Thunder = { Id = "rbxassetid://9125959830", Volume = 0.7, PlaybackSpeed = 0.4 },
	Splash = { Id = "rbxassetid://9126254421", Volume = 0.5 },
} :: { [string]: SoundEntry }

-- ================================================================
-- AMBIENT LOOPS
-- Looping environmental sounds layered on top of music per zone.
-- ================================================================

SoundConfig.Ambient = {
	Wind = { Id = "rbxassetid://9120386620", Volume = 0.4, Looped = true },
	Water = { Id = "rbxassetid://1839894436", Volume = 0.3, Looped = true, PlaybackSpeed = 0.5 },
	CaveEcho = { Id = "rbxassetid://9120386620", Volume = 0.2, Looped = true, PlaybackSpeed = 0.4 },
	Rain = { Id = "rbxassetid://9120386620", Volume = 0.35, Looped = true, PlaybackSpeed = 1.3 },
	Electric = { Id = "rbxassetid://1838260727", Volume = 0.15, Looped = true, PlaybackSpeed = 0.3 },
	VoidHum = { Id = "rbxassetid://1839894436", Volume = 0.1, Looped = true, PlaybackSpeed = 0.2 },
} :: { [string]: SoundEntry }

-- ================================================================
-- ZONE AMBIENT MAPPING
-- Which ambient loops play in each zone. Multiple can layer.
-- ================================================================

SoundConfig.ZoneAmbient = {
	[1] = {}, -- Sketch Fields: quiet and cheerful, no ambient
	[2] = { "Wind" }, -- Paper Forest: gentle breeze
	[3] = { "CaveEcho" }, -- Crayon Caverns: echoing drips
	[4] = { "Water", "Rain" }, -- Watercolor Wetlands: water everywhere
	[5] = { "Wind" }, -- Ink Ruins: eerie wind through stone
	[6] = { "Electric" }, -- Neon Grid: electronic hum
	[7] = { "Wind", "Rain" }, -- Storm Peaks: harsh weather
	[8] = {}, -- Living Canvas: unsettling silence
	[9] = { "VoidHum" }, -- The Void: faint cosmic hum
	[10] = { "Wind", "Rain" }, -- The Cliff: stormy finale
} :: { [number]: { string } }

return SoundConfig
