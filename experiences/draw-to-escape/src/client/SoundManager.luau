--!strict

--[[
	SoundManager — Client-side audio controller for Draw to Escape.
	Manages zone music with crossfading, one-shot SFX with pooling,
	and layered ambient loops tied to zone changes.

	Usage:
		local SoundManager = require(script.Parent.SoundManager)
		SoundManager:Init()
		SoundManager:PlayMusic(3)             -- crossfade to zone 3 music
		SoundManager:PlaySFX("StageComplete") -- one-shot sound effect
		SoundManager:PlayAmbient("Wind")      -- start a looping ambient layer
		SoundManager:StopAmbient("Wind")      -- stop a specific ambient layer
		SoundManager:StopAll()                -- silence everything
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundConfig = require(ReplicatedStorage.Shared.SoundConfig)

type SoundEntry = SoundConfig.SoundEntry

-- ================================================================
-- MODULE
-- ================================================================

local SoundManager = {}

-- Internal state
local initialized: boolean = false
local currentZone: number = 0
local currentMusicSound: Sound? = nil
local musicGroup: SoundGroup = nil :: any
local sfxGroup: SoundGroup = nil :: any
local ambientGroup: SoundGroup = nil :: any

-- Folder references for organizing Sound instances under SoundService
local musicFolder: Folder = nil :: any
local sfxFolder: Folder = nil :: any
local ambientFolder: Folder = nil :: any

-- Active ambient loops keyed by name
local activeAmbients: { [string]: Sound } = {}

-- SFX object pool: each SFX name maps to a list of reusable Sound instances
local sfxPool: { [string]: { Sound } } = {}
local SFX_POOL_SIZE = 3

-- Crossfade timing
local CROSSFADE_DURATION = 1.0
-- ================================================================
-- PRIVATE HELPERS
-- ================================================================

--- Create a Sound instance from a SoundEntry config table.
local function createSoundFromEntry(entry: SoundEntry, parent: Instance): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = entry.Id
	sound.Volume = entry.Volume
	sound.Looped = if entry.Looped then entry.Looped else false
	sound.PlaybackSpeed = if entry.PlaybackSpeed then entry.PlaybackSpeed else 1.0
	sound.Parent = parent
	return sound
end

--- Tween a Sound's volume to a target value over the given duration.
local function tweenVolume(sound: Sound, targetVolume: number, duration: number, callback: (() -> ())?): Tween
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(sound, tweenInfo, { Volume = targetVolume })
	if callback then
		tween.Completed:Once(function()
			callback()
		end)
	end
	tween:Play()
	return tween
end

--- Get or create a pooled SFX Sound instance. Returns one that is not currently playing.
local function getPooledSFX(name: string): Sound?
	local entry = SoundConfig.SFX[name]
	if not entry then
		warn(`[SoundManager] Unknown SFX: {name}`)
		return nil
	end

	-- Initialize pool for this SFX name if needed
	if not sfxPool[name] then
		sfxPool[name] = {}
		for _ = 1, SFX_POOL_SIZE do
			local sound = createSoundFromEntry(entry, sfxFolder)
			sound.Name = `SFX_{name}`
			table.insert(sfxPool[name], sound)
		end
	end

	-- Find a sound that is not currently playing
	local pool = sfxPool[name]
	for _, sound in pool do
		if not sound.IsPlaying then
			return sound
		end
	end

	-- All in use — expand pool by one
	local sound = createSoundFromEntry(entry, sfxFolder)
	sound.Name = `SFX_{name}`
	table.insert(pool, sound)
	return sound
end

-- ================================================================
-- PUBLIC API
-- ================================================================

--- Initialize the SoundManager. Must be called once before any other method.
function SoundManager:Init()
	if initialized then
		return
	end
	initialized = true

	-- Create SoundGroups for independent volume control
	musicGroup = Instance.new("SoundGroup")
	musicGroup.Name = "MusicGroup"
	musicGroup.Volume = 1.0
	musicGroup.Parent = SoundService

	sfxGroup = Instance.new("SoundGroup")
	sfxGroup.Name = "SFXGroup"
	sfxGroup.Volume = 1.0
	sfxGroup.Parent = SoundService

	ambientGroup = Instance.new("SoundGroup")
	ambientGroup.Name = "AmbientGroup"
	ambientGroup.Volume = 1.0
	ambientGroup.Parent = SoundService

	-- Create folders to organize Sound instances
	musicFolder = Instance.new("Folder")
	musicFolder.Name = "Music"
	musicFolder.Parent = SoundService

	sfxFolder = Instance.new("Folder")
	sfxFolder.Name = "SFX"
	sfxFolder.Parent = SoundService

	ambientFolder = Instance.new("Folder")
	ambientFolder.Name = "Ambient"
	ambientFolder.Parent = SoundService

	print("[SoundManager] Initialized")
end

--- Crossfade to the music track for the given zone number.
--- If already playing this zone's music, does nothing.
function SoundManager:PlayMusic(zone: number)
	if not initialized then
		warn("[SoundManager] Not initialized. Call :Init() first.")
		return
	end

	if zone == currentZone then
		return
	end

	local entry = SoundConfig.Music[zone]
	if not entry then
		warn(`[SoundManager] No music configured for zone {zone}`)
		return
	end

	currentZone = zone

	-- Fade out old music if playing
	local oldMusic = currentMusicSound
	if oldMusic and oldMusic.IsPlaying then
		tweenVolume(oldMusic, 0, CROSSFADE_DURATION, function()
			oldMusic:Stop()
			oldMusic:Destroy()
		end)
	elseif oldMusic then
		oldMusic:Stop()
		oldMusic:Destroy()
	end

	-- Create and fade in new music
	local newMusic = createSoundFromEntry(entry, musicFolder)
	newMusic.Name = `Music_Zone{zone}`
	newMusic.SoundGroup = musicGroup
	newMusic.Volume = 0 -- Start silent, fade in
	newMusic:Play()

	currentMusicSound = newMusic

	tweenVolume(newMusic, entry.Volume, CROSSFADE_DURATION)

	-- Update ambient layers for the new zone
	self:_updateZoneAmbients(zone)

	print(`[SoundManager] Playing music for zone {zone}`)
end

--- Stop the currently playing music with a fade out.
function SoundManager:StopMusic()
	if not initialized then
		return
	end

	currentZone = 0

	if currentMusicSound and currentMusicSound.IsPlaying then
		local fadingSound = currentMusicSound
		currentMusicSound = nil
		tweenVolume(fadingSound, 0, CROSSFADE_DURATION, function()
			fadingSound:Stop()
			fadingSound:Destroy()
		end)
	elseif currentMusicSound then
		currentMusicSound:Stop()
		currentMusicSound:Destroy()
		currentMusicSound = nil
	end
end

--- Play a one-shot sound effect by name (from SoundConfig.SFX).
--- Uses an object pool to avoid creating new instances every call.
function SoundManager:PlaySFX(name: string)
	if not initialized then
		warn("[SoundManager] Not initialized. Call :Init() first.")
		return
	end

	local sound = getPooledSFX(name)
	if not sound then
		return
	end

	-- Reset volume from config in case it was tweened previously
	local entry = SoundConfig.SFX[name]
	if entry then
		sound.Volume = entry.Volume
		sound.PlaybackSpeed = if entry.PlaybackSpeed then entry.PlaybackSpeed else 1.0
	end

	sound.SoundGroup = sfxGroup
	sound:Play()
end

--- Start a looping ambient sound by name (from SoundConfig.Ambient).
--- If already playing, does nothing.
function SoundManager:PlayAmbient(name: string)
	if not initialized then
		warn("[SoundManager] Not initialized. Call :Init() first.")
		return
	end

	-- Already playing this ambient?
	if activeAmbients[name] then
		return
	end

	local entry = SoundConfig.Ambient[name]
	if not entry then
		warn(`[SoundManager] Unknown ambient: {name}`)
		return
	end

	local sound = createSoundFromEntry(entry, ambientFolder)
	sound.Name = `Ambient_{name}`
	sound.SoundGroup = ambientGroup
	sound.Volume = 0 -- Fade in
	sound:Play()

	activeAmbients[name] = sound

	tweenVolume(sound, entry.Volume, CROSSFADE_DURATION)
end

--- Stop a specific looping ambient sound by name with a fade out.
function SoundManager:StopAmbient(name: string)
	if not initialized then
		return
	end

	local sound = activeAmbients[name]
	if not sound then
		return
	end

	activeAmbients[name] = nil

	tweenVolume(sound, 0, CROSSFADE_DURATION, function()
		sound:Stop()
		sound:Destroy()
	end)
end

--- Stop all music, SFX, and ambient sounds immediately.
function SoundManager:StopAll()
	if not initialized then
		return
	end

	-- Stop music
	currentZone = 0
	if currentMusicSound then
		currentMusicSound:Stop()
		currentMusicSound:Destroy()
		currentMusicSound = nil
	end

	-- Stop all ambients
	for name, sound in activeAmbients do
		sound:Stop()
		sound:Destroy()
		activeAmbients[name] = nil
	end

	-- Stop all pooled SFX
	for _, pool in sfxPool do
		for _, sound in pool do
			if sound.IsPlaying then
				sound:Stop()
			end
		end
	end

	print("[SoundManager] All sounds stopped")
end

--- Set the master volume for a specific category.
--- Category must be "Music", "SFX", or "Ambient".
function SoundManager:SetCategoryVolume(category: string, volume: number)
	if not initialized then
		return
	end

	volume = math.clamp(volume, 0, 1)

	if category == "Music" and musicGroup then
		musicGroup.Volume = volume
	elseif category == "SFX" and sfxGroup then
		sfxGroup.Volume = volume
	elseif category == "Ambient" and ambientGroup then
		ambientGroup.Volume = volume
	else
		warn(`[SoundManager] Unknown category: {category}`)
	end
end

--- Get the currently active zone number (0 if no music playing).
function SoundManager:GetCurrentZone(): number
	return currentZone
end

-- ================================================================
-- INTERNAL: ZONE AMBIENT MANAGEMENT
-- ================================================================

--- Update ambient loops to match the target zone.
--- Stops ambients not needed in the new zone, starts ones that are.
function SoundManager:_updateZoneAmbients(zone: number)
	local targetAmbients = SoundConfig.ZoneAmbient[zone] or {}

	-- Build a set of desired ambient names for fast lookup
	local desired: { [string]: boolean } = {}
	for _, name in targetAmbients do
		desired[name] = true
	end

	-- Stop ambients that are playing but not desired in the new zone
	for name, _sound in activeAmbients do
		if not desired[name] then
			self:StopAmbient(name)
		end
	end

	-- Start ambients that are desired but not yet playing
	for _, name in targetAmbients do
		if not activeAmbients[name] then
			self:PlayAmbient(name)
		end
	end
end

-- ================================================================
-- CLEANUP
-- ================================================================

--- Destroy all sound instances and reset state. Call on player leaving or cleanup.
function SoundManager:Destroy()
	self:StopAll()

	-- Destroy all pooled SFX
	for name, pool in sfxPool do
		for _, sound in pool do
			sound:Destroy()
		end
		sfxPool[name] = nil
	end

	-- Destroy organizational folders
	if musicFolder then
		musicFolder:Destroy()
	end
	if sfxFolder then
		sfxFolder:Destroy()
	end
	if ambientFolder then
		ambientFolder:Destroy()
	end

	-- Destroy sound groups
	if musicGroup then
		musicGroup:Destroy()
	end
	if sfxGroup then
		sfxGroup:Destroy()
	end
	if ambientGroup then
		ambientGroup:Destroy()
	end

	initialized = false
	currentZone = 0
	currentMusicSound = nil
	print("[SoundManager] Destroyed")
end

return SoundManager
