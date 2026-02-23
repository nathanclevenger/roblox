--!strict

--[[
	Research Station Level Builder (Level 3: Blackpoint Research Station)

	Orchestrates all area builders and returns combined LevelData
	with hiding spots, patrol waypoints, loot positions, entity spawn
	positions, and the player spawn point.

	Four tiers of geometry:
		Surface   (Y = 0)   — Helipad, Admin Building, Barracks, Service Yard, Perimeter
		Lab Level (Y = -15)  — Containment Wing, Biology Lab, Audio Lab, Observation Deck, Medical Bay
		Deep Level(Y = -30)  — Main Chamber, Server Room, The Tank
		Dock      (Y = -25)  — Emergency Tunnel, Boat House, Pier (Extraction)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

local AdminArea = require(script.AdminArea)
local ContainmentWing = require(script.ContainmentWing)
local DeepLevel = require(script.DeepLevel)
local Exterior = require(script.Exterior)
local Labs = require(script.Labs)

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local SURFACE_Y = 0
local LAB_Y = -15
local DEEP_Y = -30

-- Player spawns at the Helipad
local PlayerSpawnPosition: Vector3 = Vector3.new(-60, SURFACE_Y + 3, -60)

-- Entity (Mimic) spawn positions — spread across facility tiers
local EntitySpawnPositions: { Vector3 } = {
	Vector3.new(-20, SURFACE_Y + 3, -50),  -- Admin Reception
	Vector3.new(-30, LAB_Y + 3, -15),       -- Lab Corridor near Containment
	Vector3.new(10, LAB_Y + 3, 0),          -- Observation Deck area
	Vector3.new(0, DEEP_Y + 3, 0),          -- Main Chamber center
	Vector3.new(35, DEEP_Y + 3, 0),         -- Server Room vicinity
}

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local ResearchStation = {}

function ResearchStation.build(): (Model, Types.LevelData)
	local levelModel = Instance.new("Model")
	levelModel.Name = "ResearchStation"

	-- Build all areas
	local exteriorData = Exterior.build(levelModel)
	local adminData = AdminArea.build(levelModel)
	local labsData = Labs.build(levelModel)
	local containmentData = ContainmentWing.build(levelModel)
	local deepData = DeepLevel.build(levelModel)

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

	merge(exteriorData)
	merge(adminData)
	merge(labsData)
	merge(containmentData)
	merge(deepData)

	-- Parent to workspace
	levelModel.Parent = workspace

	local levelData: Types.LevelData = {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
		spawnPoint = PlayerSpawnPosition,
		entitySpawnPositions = EntitySpawnPositions,
	}

	print(`[ResearchStation] Built: {#hidingSpots} hiding spots, {#waypoints} waypoints, {#lootPositions} loot positions`)

	return levelModel, levelData
end

function ResearchStation.cleanup(levelModel: Model)
	if levelModel then
		levelModel:Destroy()
	end
end

return ResearchStation
