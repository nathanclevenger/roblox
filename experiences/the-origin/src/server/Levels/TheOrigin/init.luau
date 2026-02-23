--!strict

--[[
	The Origin Level Builder (Level 5: Beneath St. Maren's Hospital)

	Orchestrates all zone builders and returns combined LevelData
	with hiding spots, patrol waypoints, loot positions, entity spawn
	positions, and the player spawn point.

	The Origin is the final level -- a descent through ancient catacombs,
	a semi-procedural labyrinth, and an underground cathedral to the
	source of all entities: the Seal, and the choice to reinforce or
	destroy it.

	Zones:
	  - Threshold: Entry stairwell + Upper Catacombs (Stone Corridors,
	    Burial Chambers, Flooded Gallery, Desecrated Chapel, Descent Passage)
	  - Labyrinth: The Warren (semi-procedural tunnels, Echo Chambers,
	    Mirror Room, The Narrow, Threshold Gate)
	  - Core: The Sanctuary (Central Chamber, Pillar Hall, The Throne,
	    The Seal)
	  - Echoes: Distorted fragments of previous levels scattered
	    throughout (hospital corridors, subway platforms, lab panels,
	    forest growth -- all corrupted and wrong)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

local Core = require(script.Core)
local Echoes = require(script.Echoes)
local Labyrinth = require(script.Labyrinth)
local PulseController = require(script.PulseController)
local Shared = require(script.Shared)
local Threshold = require(script.Threshold)

local TheOrigin = {}

function TheOrigin.build(): (Model, Types.LevelData)
	local levelModel = Instance.new("Model")
	levelModel.Name = "TheOrigin"

	-- Build all zones
	local thresholdData = Threshold.build(levelModel)
	local labyrinthData = Labyrinth.build(levelModel)
	local coreData = Core.build(levelModel)
	local echoesData = Echoes.build(levelModel)

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

	merge(thresholdData)
	merge(labyrinthData)
	merge(coreData)
	merge(echoesData)

	-- Parent to workspace
	levelModel.Parent = workspace

	-- Start the pulse controller (drives all bioluminescent / pulsing lights)
	PulseController.start(levelModel)

	-- Player spawn: at the top of the entry stairwell (sub-basement door)
	local spawnPoint = Vector3.new(30, -12 + 3, 30)

	-- Entity spawn positions (distributed across zones)
	local entitySpawnPositions: { Vector3 } = {
		-- The Patient (Evolved) - Upper Catacombs
		Vector3.new(30, Shared.CATACOMB_Y + 3, 10),
		-- Crawlers (Aquatic) - Flooded Gallery
		Vector3.new(30, Shared.CATACOMB_Y + 1, -50),
		-- The Mimic (Evolved) - Warren entry area
		Vector3.new(30, Shared.WARREN_Y + 3, -130),
		-- The Mimic - Warren deep (near Mirror Room)
		Vector3.new(54, Shared.WARREN_Y + 3, -192),
		-- Crawlers (Juvenile) - The Narrow
		Vector3.new(54, Shared.WARREN_Y + 3, -250),
		-- Watchers (Evolved) - Pillar Hall
		Vector3.new(15, Shared.SANCTUARY_Y + 3, -250),
		Vector3.new(40, Shared.SANCTUARY_Y + 3, -250),
		Vector3.new(30, Shared.SANCTUARY_Y + 3, -245),
		Vector3.new(50, Shared.SANCTUARY_Y + 3, -255),
	}

	local levelData: Types.LevelData = {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
		spawnPoint = spawnPoint,
		entitySpawnPositions = entitySpawnPositions,
	}

	print(`[TheOrigin] Built: {#hidingSpots} hiding spots, {#waypoints} waypoints, {#lootPositions} loot positions, {#entitySpawnPositions} entity spawns`)

	return levelModel, levelData
end

function TheOrigin.cleanup(levelModel: Model)
	-- Stop the pulse controller before destroying geometry
	PulseController.stop()

	if levelModel then
		levelModel:Destroy()
	end
end

return TheOrigin
