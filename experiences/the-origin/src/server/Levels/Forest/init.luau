--!strict

--[[
	Forest Level Builder (Level 4: Ashwood Forest & Cabins)

	Orchestrates all area builders and returns combined LevelData
	with hiding spots, patrol waypoints, loot positions, entity spawn
	positions, and the player spawn point.

	Areas:
	  - Clearing (Ranger Station compound: office, garage, watchtower, supply shed)
	  - DenseForest (trails, trees, undergrowth, clearing, creek bed, campsite, The Ring)
	  - Cabin (Cabin A/B/C, root cellar, ridge terrain, radio tower)
	  - Cave (optional underground area: upper chamber, painted chamber, The Deep)

	This is an OUTDOOR level. The geometry is ~600x600 studs of navigable
	forest terrain with procedurally placed trees, rocks, and undergrowth.
	Dense fog, minimal moonlight, dark canopy overhead.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Types = require(ReplicatedStorage.Shared.Types)

local Cabin = require(script.Cabin)
local Cave = require(script.Cave)
local Clearing = require(script.Clearing)
local DenseForest = require(script.DenseForest)

------------------------------------------------------------------------
-- Level 4 Constants
------------------------------------------------------------------------

local FLOOR_Y = 0

-- Player spawns at the Ranger Station parking lot
local PLAYER_SPAWN = Vector3.new(10, FLOOR_Y + 3, 280)

-- Entity (Watcher) initial spawn positions
-- Watchers appear progressively; these are the initial pool positions
local ENTITY_SPAWN_POSITIONS: { Vector3 } = {
	-- Supply Shed tutorial Watcher
	Vector3.new(-30, FLOOR_Y + 3, 265),
	-- Trail-adjacent (first forest traversal)
	Vector3.new(12, FLOOR_Y + 3, 160),
	Vector3.new(-15, FLOOR_Y + 3, 60),
	-- Dense woods
	Vector3.new(60, FLOOR_Y + 3, 50),
	Vector3.new(-80, FLOOR_Y + 3, -10),
	-- Near cabin cluster
	Vector3.new(10, FLOOR_Y + 3, -80),
	-- Ridge trail
	Vector3.new(18, FLOOR_Y + 12, -250),
	Vector3.new(16, FLOOR_Y + 18, -280),
}

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local Forest = {}

function Forest.build(): (Model, Types.LevelData)
	local levelModel = Instance.new("Model")
	levelModel.Name = "Forest"

	-- Configure lighting for dark forest atmosphere
	Forest._setupLighting()

	-- Build all areas
	local clearingData = Clearing.build(levelModel)
	local forestData = DenseForest.build(levelModel)
	local cabinData = Cabin.build(levelModel)
	local caveData = Cave.build(levelModel)

	-- Combine all data
	local hidingSpots: { Types.HidingSpot } = {}
	local waypoints: { Types.PatrolWaypoint } = {}
	local lootPositions: { Types.LootSpawn } = {}

	local function merge(data: {
		hidingSpots: { any },
		waypoints: { any },
		lootPositions: { any },
	})
		for _, spot in data.hidingSpots do
			table.insert(hidingSpots, spot)
		end
		for _, wp in data.waypoints do
			table.insert(waypoints, wp)
		end
		for _, loot in data.lootPositions do
			table.insert(lootPositions, loot)
		end
	end

	merge(clearingData)
	merge(forestData)
	merge(cabinData)
	merge(caveData)

	-- Parent to workspace
	levelModel.Parent = workspace

	local levelData: Types.LevelData = {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
		spawnPoint = PLAYER_SPAWN,
		entitySpawnPositions = ENTITY_SPAWN_POSITIONS,
	}

	print(`[Forest] Built: {#hidingSpots} hiding spots, {#waypoints} waypoints, {#lootPositions} loot positions`)
	print(`[Forest] Entity spawn positions: {#ENTITY_SPAWN_POSITIONS}`)

	return levelModel, levelData
end

function Forest.cleanup(levelModel: Model)
	-- Restore default lighting
	Forest._restoreLighting()

	if levelModel then
		levelModel:Destroy()
	end
end

------------------------------------------------------------------------
-- Lighting Setup (dark forest atmosphere)
------------------------------------------------------------------------

-- Store original values for restoration
local _originalLighting: {
	Ambient: Color3?,
	Brightness: number?,
	ClockTime: number?,
	FogColor: Color3?,
	FogEnd: number?,
	FogStart: number?,
	OutdoorAmbient: Color3?,
	EnvironmentDiffuseScale: number?,
	EnvironmentSpecularScale: number?,
} = {}

function Forest._setupLighting()
	-- Save current values
	_originalLighting.Ambient = Lighting.Ambient
	_originalLighting.Brightness = Lighting.Brightness
	_originalLighting.ClockTime = Lighting.ClockTime
	_originalLighting.FogColor = Lighting.FogColor
	_originalLighting.FogEnd = Lighting.FogEnd
	_originalLighting.FogStart = Lighting.FogStart
	_originalLighting.OutdoorAmbient = Lighting.OutdoorAmbient
	_originalLighting.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
	_originalLighting.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale

	-- Dark forest atmosphere: late dusk, overcast sky, minimal moonlight
	Lighting.ClockTime = 21 -- 9 PM, dusk-to-night
	Lighting.Brightness = 0.3 -- very dim
	Lighting.Ambient = Color3.fromRGB(15, 18, 22) -- near-black ambient
	Lighting.OutdoorAmbient = Color3.fromRGB(20, 25, 35) -- cold, desaturated
	Lighting.EnvironmentDiffuseScale = 0.2
	Lighting.EnvironmentSpecularScale = 0

	-- Persistent light fog (not the dynamic fog system, just base atmosphere)
	Lighting.FogColor = Color3.fromRGB(25, 28, 32) -- dark grey-blue fog
	Lighting.FogEnd = 250 -- moderate base visibility
	Lighting.FogStart = 50 -- fog begins relatively close

	-- Add Atmosphere effect if not present
	local atmosphere = Lighting:FindFirstChild("ForestAtmosphere") :: Atmosphere?
	if not atmosphere then
		local atm = Instance.new("Atmosphere")
		atm.Name = "ForestAtmosphere"
		atm.Density = 0.4 -- moderate atmospheric density
		atm.Offset = 0.1
		atm.Color = Color3.fromRGB(30, 35, 40) -- cool blue-grey
		atm.Decay = Color3.fromRGB(20, 22, 28) -- darker decay
		atm.Glare = 0
		atm.Haze = 6 -- noticeable haze
		atm.Parent = Lighting
	end

	-- Add ColorCorrection for desaturation
	local cc = Lighting:FindFirstChild("ForestColorCorrection") :: ColorCorrectionEffect?
	if not cc then
		local correction = Instance.new("ColorCorrectionEffect")
		correction.Name = "ForestColorCorrection"
		correction.Saturation = -0.3 -- desaturated
		correction.Contrast = 0.1 -- slight contrast boost
		correction.Brightness = -0.05 -- slightly darker
		correction.TintColor = Color3.fromRGB(200, 210, 230) -- cold tint
		correction.Parent = Lighting
	end

	-- Add Bloom for soft glow on moonlight
	local bloom = Lighting:FindFirstChild("ForestBloom") :: BloomEffect?
	if not bloom then
		local b = Instance.new("BloomEffect")
		b.Name = "ForestBloom"
		b.Intensity = 0.3
		b.Size = 20
		b.Threshold = 1.5
		b.Parent = Lighting
	end
end

function Forest._restoreLighting()
	-- Restore original values
	if _originalLighting.Ambient then
		Lighting.Ambient = _originalLighting.Ambient
	end
	if _originalLighting.Brightness then
		Lighting.Brightness = _originalLighting.Brightness
	end
	if _originalLighting.ClockTime then
		Lighting.ClockTime = _originalLighting.ClockTime
	end
	if _originalLighting.FogColor then
		Lighting.FogColor = _originalLighting.FogColor
	end
	if _originalLighting.FogEnd then
		Lighting.FogEnd = _originalLighting.FogEnd
	end
	if _originalLighting.FogStart then
		Lighting.FogStart = _originalLighting.FogStart
	end
	if _originalLighting.OutdoorAmbient then
		Lighting.OutdoorAmbient = _originalLighting.OutdoorAmbient
	end
	if _originalLighting.EnvironmentDiffuseScale then
		Lighting.EnvironmentDiffuseScale = _originalLighting.EnvironmentDiffuseScale
	end
	if _originalLighting.EnvironmentSpecularScale then
		Lighting.EnvironmentSpecularScale = _originalLighting.EnvironmentSpecularScale
	end

	-- Remove forest-specific effects
	local atmosphere = Lighting:FindFirstChild("ForestAtmosphere")
	if atmosphere then
		atmosphere:Destroy()
	end

	local cc = Lighting:FindFirstChild("ForestColorCorrection")
	if cc then
		cc:Destroy()
	end

	local bloom = Lighting:FindFirstChild("ForestBloom")
	if bloom then
		bloom:Destroy()
	end
end

return Forest
