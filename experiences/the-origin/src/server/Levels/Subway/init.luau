--!strict

--[[
	Subway Level Builder (Level 2: Line 13 Subway System)

	Orchestrates all area builders and returns combined LevelData
	with hiding spots, patrol waypoints, loot positions, entity spawn
	positions, and the player spawn point.

	The subway spans three stations (Hargrove Street, Moorfield, Terminus)
	connected by a tunnel network including Main Tunnel, Service Tunnel,
	Junction Chamber, Flooded Section, Collapsed Section, Ventilation Shafts,
	Deep Tunnels (Unfinished Extension, The Nest, Drainage System).

	Y-level layout:
		Street:     Y = 0
		Ticket Hall: Y = -8
		Mezzanine:  Y = -16
		Platform:   Y = -24
		Track:      Y = -28
		Nest:       Y = -38

	Z-axis layout (stations move in -Z direction):
		Hargrove Street: Z ~ 0
		Tunnel Network:  Z ~ -30 to -130
		Moorfield:       Z ~ -350
		Deep Tunnels:    Z ~ -360 to -460
		Terminus:        Z ~ -600
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

local Platform = require(script.Platform)
local Tunnels = require(script.Tunnels)
local TrainCars = require(script.TrainCars)
local ServiceAreas = require(script.ServiceAreas)

local Subway = {}

------------------------------------------------------------------------
-- Coordinate Constants
------------------------------------------------------------------------

-- Player spawn: top of Hargrove Street station stairs
local SPAWN_POINT = Vector3.new(0, 0, -18) -- street level, near entrance

-- Entity (Crawler) spawn positions
local ENTITY_SPAWN_POSITIONS: { Vector3 } = {
	Vector3.new(-10, -24 + 3, 55), -- Hargrove Platform A (Awakening event at 120s)
	Vector3.new(0, -28 + 3, -30), -- Junction Chamber (tunnel network)
	Vector3.new(0, -28 + 3, -80), -- Main Tunnel midpoint
	Vector3.new(-10, -28 + 3, -80), -- Service Tunnel midpoint
	Vector3.new(0, -24 + 3, -350), -- Moorfield Platform
	Vector3.new(15, -28 + 3, -360 - 60), -- Near Nest branch
	Vector3.new(25, -38 + 3, -360 - 60), -- Inside the Nest (dormant)
	Vector3.new(25, -38 + 20, -360 - 60), -- Nest ceiling (dormant)
}

------------------------------------------------------------------------
-- Build Function
------------------------------------------------------------------------

function Subway.build(): (Model, Types.LevelData)
	local levelModel = Instance.new("Model")
	levelModel.Name = "Subway"

	-- Build all areas
	local platformData = Platform.build(levelModel)
	local tunnelData = Tunnels.build(levelModel)
	local trainData = TrainCars.build(levelModel)
	local serviceData = ServiceAreas.build(levelModel)

	-- Combine all data
	local hidingSpots: { Types.HidingSpot } = {}
	local waypoints: { Types.PatrolWaypoint } = {}
	local lootPositions: { Types.LootSpawn } = {}

	local function merge(data: { hidingSpots: { any }, waypoints: { any }, lootPositions: { any } })
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

	merge(platformData)
	merge(tunnelData)
	merge(trainData)
	merge(serviceData)

	-- Set level-wide attributes for game systems
	levelModel:SetAttribute("LevelName", "Subway")
	levelModel:SetAttribute("LevelNumber", 2)
	levelModel:SetAttribute("EntityType", "Crawler")
	levelModel:SetAttribute("MaxEntityCount", 5)
	levelModel:SetAttribute("CrawlerActivationDelay", 120) -- seconds
	levelModel:SetAttribute("AmbientLightLevel", 0) -- underground, no ambient

	-- Parent to workspace
	levelModel.Parent = workspace

	local levelData: Types.LevelData = {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
		spawnPoint = SPAWN_POINT,
		entitySpawnPositions = ENTITY_SPAWN_POSITIONS,
	}

	print(`[Subway] Built: {#hidingSpots} hiding spots, {#waypoints} waypoints, {#lootPositions} loot positions`)

	return levelModel, levelData
end

------------------------------------------------------------------------
-- Cleanup Function
------------------------------------------------------------------------

function Subway.cleanup(levelModel: Model)
	if levelModel then
		levelModel:Destroy()
	end
end

return Subway
