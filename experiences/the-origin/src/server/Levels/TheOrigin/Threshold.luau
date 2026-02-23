--!strict

--[[
	TheOrigin/Threshold - Entry area and Upper Catacombs.

	Covers the descent from the hospital sub-basement door through the
	industrial stairwell, into the Upper Catacombs (Stone Corridors,
	Burial Chambers, Flooded Gallery, Desecrated Chapel) and the
	Descent Passage into the Warren.

	This is the teaching zone that re-introduces entity encounters in
	a controlled environment before the Warren.
]]

local Shared = require(script.Parent.Shared)

type HidingSpotData = Shared.HidingSpotData
type FloorData = Shared.FloorData

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local ENTRY_Y: number = Shared.ENTRY_Y
local CATACOMB_Y: number = Shared.CATACOMB_Y
local CORRIDOR_HEIGHT: number = Shared.CATACOMB_CORRIDOR_HEIGHT
local CORRIDOR_WIDTH: number = Shared.CATACOMB_CORRIDOR_WIDTH
local WALL_THICKNESS: number = Shared.CATACOMB_WALL_THICKNESS

------------------------------------------------------------------------
-- Helper: create a simple Part
------------------------------------------------------------------------

local function createPart(
	parent: Instance,
	name: string,
	position: Vector3,
	size: Vector3,
	color: Color3?,
	transparency: number?,
	material: Enum.Material?
): Part
	return Shared.createPart(parent, name, position, size, color, transparency, material)
end

------------------------------------------------------------------------
-- Entry Stairwell: Hospital sub-basement to Upper Catacombs
------------------------------------------------------------------------

local function buildEntryStairwell(
	parent: Instance,
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local stairwell = Instance.new("Model")
	stairwell.Name = "EntryStairwell"

	-- The stairwell is a descent from hospital basement Y=-12 to ENTRY_Y
	local topY = -12
	local bottomY = ENTRY_Y
	local stairCenter = Vector3.new(30, 0, 30) -- Near sub-basement door position from LevelConfig

	-- Enclosing shaft walls (concrete transitioning to stone)
	local shaftHeight = topY - bottomY + 4
	local shaftCenterY = (topY + bottomY) / 2

	-- Concrete walls (upper portion)
	local concreteHeight = shaftHeight * 0.4
	Shared.createStoneWall(
		Vector3.new(stairCenter.X - 4, topY - concreteHeight / 2, stairCenter.Z),
		Vector3.new(1, concreteHeight, 10),
		stairwell,
		"ShaftWall_West_Concrete"
	).Material = Enum.Material.Concrete
	Shared.createStoneWall(
		Vector3.new(stairCenter.X + 4, topY - concreteHeight / 2, stairCenter.Z),
		Vector3.new(1, concreteHeight, 10),
		stairwell,
		"ShaftWall_East_Concrete"
	).Material = Enum.Material.Concrete

	-- Stone walls (lower portion, rough-hewn)
	local stoneHeight = shaftHeight * 0.6
	Shared.createStoneWall(
		Vector3.new(stairCenter.X - 4, bottomY + stoneHeight / 2, stairCenter.Z),
		Vector3.new(1, stoneHeight, 10),
		stairwell,
		"ShaftWall_West_Stone"
	)
	Shared.createStoneWall(
		Vector3.new(stairCenter.X + 4, bottomY + stoneHeight / 2, stairCenter.Z),
		Vector3.new(1, stoneHeight, 10),
		stairwell,
		"ShaftWall_East_Stone"
	)

	-- Steps (descending)
	local totalSteps = math.floor(topY - bottomY)
	local stepWidth = 6
	local stepDepth = 0.8
	for i = 0, totalSteps - 1 do
		local step = Instance.new("Part")
		step.Name = `Step_{i}`
		step.Size = Vector3.new(stepWidth, 0.5, stepDepth)
		step.Position = Vector3.new(stairCenter.X, topY - i - 0.25, stairCenter.Z - 4 + i * stepDepth * 0.8)
		step.Anchored = true
		step.Material = if i < totalSteps * 0.3 then Enum.Material.Concrete else Enum.Material.Slate
		step.Color = if i < totalSteps * 0.3
			then Color3.fromRGB(130, 130, 125)
			else Shared.COLOR_STONE
		step.Parent = stairwell
	end

	-- Landing at bottom
	Shared.createStoneFloor(
		Vector3.new(stairCenter.X, bottomY - 0.5, stairCenter.Z + 6),
		Vector3.new(8, 1, 6),
		stairwell,
		"Landing_Bottom"
	)

	-- Fluorescent lights (dying as player descends)
	for i = 0, 3 do
		local lightY = topY - i * 3
		local brightness = math.max(0.02, 0.3 - i * 0.08)
		local fixture = createPart(
			stairwell,
			`FluorescentLight_{i}`,
			Vector3.new(stairCenter.X, lightY, stairCenter.Z - 2 + i * 2),
			Vector3.new(2, 0.3, 0.5),
			Color3.fromRGB(220, 220, 210),
			0.3,
			Enum.Material.SmoothPlastic
		)

		local light = Instance.new("PointLight")
		light.Brightness = brightness
		light.Color = Color3.fromRGB(200, 210, 220)
		light.Range = 12
		light.Shadows = true
		light.Parent = fixture
	end

	-- Supply cache alcove at base of stairs
	local alcovePos = Vector3.new(stairCenter.X + 3, bottomY, stairCenter.Z + 8)

	-- Small shelf in alcove
	createPart(
		stairwell,
		"SupplyShelf",
		alcovePos + Vector3.new(0, 1.5, 0),
		Vector3.new(3, 0.3, 1.5),
		Shared.COLOR_STONE_LIGHT,
		0,
		Enum.Material.Slate
	)

	-- Guaranteed loot at entry (last easy supplies)
	table.insert(lootPositions, {
		itemType = "Battery",
		position = alcovePos + Vector3.new(-0.5, 2, 0),
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = alcovePos + Vector3.new(0.5, 2, 0),
		chance = 1,
		guaranteed = true,
	})

	stairwell.Parent = parent
end

------------------------------------------------------------------------
-- Stone Corridors: Hub connecting all Upper Catacomb areas
------------------------------------------------------------------------

local function buildStoneCorridors(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local corridors = Instance.new("Model")
	corridors.Name = "StoneCorridors"

	local basePos = Vector3.new(30, CATACOMB_Y, 30)

	-- Main corridor: North-South spine
	local mainStart = Vector3.new(basePos.X, CATACOMB_Y, basePos.Z)
	local mainEnd = Vector3.new(basePos.X, CATACOMB_Y, basePos.Z - 50)
	Shared.createCorridor(mainStart, mainEnd, CORRIDOR_WIDTH, CORRIDOR_HEIGHT, corridors, "MainCorridor")

	-- Branch West: to Burial Chambers
	local branchWStart = Vector3.new(basePos.X, CATACOMB_Y, basePos.Z - 20)
	local branchWEnd = Vector3.new(basePos.X - 25, CATACOMB_Y, basePos.Z - 20)
	Shared.createCorridor(branchWStart, branchWEnd, CORRIDOR_WIDTH, CORRIDOR_HEIGHT, corridors, "BranchWest")

	-- Branch East: dead end with loot
	local branchEStart = Vector3.new(basePos.X, CATACOMB_Y, basePos.Z - 20)
	local branchEEnd = Vector3.new(basePos.X + 15, CATACOMB_Y, basePos.Z - 20)
	Shared.createCorridor(branchEStart, branchEEnd, CORRIDOR_WIDTH, CORRIDOR_HEIGHT, corridors, "BranchEast_DeadEnd")

	-- Dead end wall
	Shared.createStoneWall(
		Vector3.new(basePos.X + 15.5, CATACOMB_Y + CORRIDOR_HEIGHT / 2, basePos.Z - 20),
		Vector3.new(WALL_THICKNESS, CORRIDOR_HEIGHT, CORRIDOR_WIDTH + WALL_THICKNESS * 2),
		corridors,
		"DeadEnd_Wall"
	)

	-- Archways at intersections
	Shared.createArchway(
		Vector3.new(basePos.X, CATACOMB_Y, basePos.Z - 10),
		CORRIDOR_WIDTH, CORRIDOR_HEIGHT, 1,
		corridors, "Arch_Main_1", true
	)
	Shared.createArchway(
		Vector3.new(basePos.X, CATACOMB_Y, basePos.Z - 30),
		CORRIDOR_WIDTH, CORRIDOR_HEIGHT, 1,
		corridors, "Arch_Main_2", true
	)

	-- Torch sconces along corridors (unlit)
	local sconcePositions = {
		Vector3.new(basePos.X - 2.2, CATACOMB_Y + 3, basePos.Z - 5),
		Vector3.new(basePos.X + 2.2, CATACOMB_Y + 3, basePos.Z - 15),
		Vector3.new(basePos.X - 2.2, CATACOMB_Y + 3, basePos.Z - 25),
		Vector3.new(basePos.X + 2.2, CATACOMB_Y + 3, basePos.Z - 35),
		Vector3.new(basePos.X + 2.2, CATACOMB_Y + 3, basePos.Z - 45),
	}
	for i, pos in sconcePositions do
		Shared.createTorchSconce(pos, corridors, false)
	end

	-- Wall alcoves (recessed niches in corridor walls for atmosphere)
	for i = 1, 6 do
		local alcoveZ = basePos.Z - 5 - i * 7
		local side = if i % 2 == 0 then 1 else -1
		createPart(
			corridors,
			`WallAlcove_{i}`,
			Vector3.new(basePos.X + side * (CORRIDOR_WIDTH / 2 + 0.5), CATACOMB_Y + 2, alcoveZ),
			Vector3.new(1.5, 2.5, 1.5),
			Shared.COLOR_STONE_DARK,
			0,
			Enum.Material.Slate
		)
	end

	-- Loot at dead end
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(basePos.X + 14, CATACOMB_Y + 1, basePos.Z - 20),
		chance = 0.5,
		guaranteed = false,
	})

	-- Patrol waypoints along corridor spine
	table.insert(waypoints, {
		position = Vector3.new(basePos.X, CATACOMB_Y + 3, basePos.Z - 5),
		roomId = "StoneCorridors_North",
		dwellTime = 3,
	})
	table.insert(waypoints, {
		position = Vector3.new(basePos.X, CATACOMB_Y + 3, basePos.Z - 20),
		roomId = "StoneCorridors_Center",
		dwellTime = 4,
	})
	table.insert(waypoints, {
		position = Vector3.new(basePos.X, CATACOMB_Y + 3, basePos.Z - 35),
		roomId = "StoneCorridors_South",
		dwellTime = 3,
	})
	table.insert(waypoints, {
		position = Vector3.new(basePos.X - 12, CATACOMB_Y + 3, basePos.Z - 20),
		roomId = "StoneCorridors_WestBranch",
		dwellTime = 5,
	})

	corridors.Parent = parent
end

------------------------------------------------------------------------
-- Burial Chambers: 4 interconnected rooms with hiding niches
------------------------------------------------------------------------

local function buildBurialChambers(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local chambers = Instance.new("Model")
	chambers.Name = "BurialChambers"

	local chamberBaseX = 5
	local chamberBaseZ = 10

	-- Build 4 interconnected rectangular chambers
	for i = 0, 3 do
		local chamberPos = Vector3.new(chamberBaseX, CATACOMB_Y, chamberBaseZ - i * 14)
		local chamberSize = Vector3.new(8, CORRIDOR_HEIGHT, 12)

		local doorways: { any } = {}
		-- South doorway to next chamber (except last)
		if i < 3 then
			table.insert(doorways, {
				wall = "south" :: "south",
				offset = 0,
				width = 3,
				height = 3, -- Low archway, forces crouch
			})
		end
		-- North doorway from previous chamber (except first)
		if i > 0 then
			table.insert(doorways, {
				wall = "north" :: "north",
				offset = 0,
				width = 3,
				height = 3,
			})
		end
		-- East doorway for first chamber (connects to stone corridors)
		if i == 0 then
			table.insert(doorways, {
				wall = "east" :: "east",
				offset = 0,
				width = CORRIDOR_WIDTH,
				height = CORRIDOR_HEIGHT,
			})
		end

		Shared.createCatacombRoom({
			position = chamberPos,
			size = chamberSize,
			parent = chambers,
			name = `BurialChamber_{i + 1}`,
			doorways = doorways,
		})

		-- Very dim light
		Shared.createPulsingLight(
			chamberPos + Vector3.new(0, CORRIDOR_HEIGHT - 1, 0),
			chambers,
			0.01, 0.04,
			Shared.COLOR_BIOLUM,
			6, 0.3
		)

		-- Burial niches (2 per chamber)
		local nicheOffset1 = Vector3.new(-3.5, 2, -3)
		local nicheOffset2 = Vector3.new(-3.5, 2, 3)

		local _, spotData1 = Shared.createBurialNiche(
			chamberPos + nicheOffset1,
			chambers,
			`burial_niche_{i * 2 + 1}`,
			i % 2 == 0
		)
		table.insert(hidingSpots, spotData1)

		local _, spotData2 = Shared.createBurialNiche(
			chamberPos + nicheOffset2,
			chambers,
			`burial_niche_{i * 2 + 2}`,
			i % 2 == 1
		)
		table.insert(hidingSpots, spotData2)

		-- Patrol waypoints
		table.insert(waypoints, {
			position = chamberPos + Vector3.new(0, 3, 0),
			roomId = `BurialChamber_{i + 1}`,
			dwellTime = if i < 2 then 4 else 6,
		})
	end

	-- Deepest chamber: sarcophagus
	local deepChamberPos = Vector3.new(chamberBaseX, CATACOMB_Y, chamberBaseZ - 3 * 14)
	Shared.createSarcophagus(
		deepChamberPos,
		chambers,
		"CentralSarcophagus",
		true -- lid displaced
	)

	-- Sarcophagus hiding spot (risky: loud)
	local _, sarcSpotData = Shared.createHidingSpot(
		deepChamberPos + Vector3.new(0, 1, 0),
		"BurialNiche",
		"burial_sarcophagus",
		chambers
	)
	table.insert(hidingSpots, sarcSpotData)

	-- Loot
	table.insert(lootPositions, {
		itemType = "Medkit",
		position = deepChamberPos + Vector3.new(0, 2.5, 0),
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(chamberBaseX + 2, CATACOMB_Y + 1, chamberBaseZ - 14),
		chance = 0.4,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Flare",
		position = Vector3.new(chamberBaseX - 2, CATACOMB_Y + 1, chamberBaseZ - 28),
		chance = 0.3,
		guaranteed = false,
	})

	chambers.Parent = parent
end

------------------------------------------------------------------------
-- Flooded Gallery: Vaulted gallery with waist-deep water
------------------------------------------------------------------------

local function buildFloodedGallery(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local gallery = Instance.new("Model")
	gallery.Name = "FloodedGallery"

	local galleryPos = Vector3.new(30, CATACOMB_Y, -30) -- South end of main corridor
	local galleryWidth = 6
	local galleryLength = 60
	local galleryHeight = 5
	local waterLevel = CATACOMB_Y + 2.5

	-- Floor (descending)
	Shared.createStoneFloor(
		Vector3.new(galleryPos.X, CATACOMB_Y - 0.5, galleryPos.Z - galleryLength / 2),
		Vector3.new(galleryWidth + 2, 1, galleryLength),
		gallery,
		"GalleryFloor"
	)

	-- Vaulted ceiling
	Shared.createStoneCeiling(
		Vector3.new(galleryPos.X, CATACOMB_Y + galleryHeight, galleryPos.Z - galleryLength / 2),
		Vector3.new(galleryWidth + 2, 1, galleryLength),
		gallery,
		"GalleryCeiling"
	)

	-- Side walls
	Shared.createStoneWall(
		Vector3.new(galleryPos.X - galleryWidth / 2 - 1, CATACOMB_Y + galleryHeight / 2, galleryPos.Z - galleryLength / 2),
		Vector3.new(1, galleryHeight, galleryLength),
		gallery,
		"GalleryWall_West"
	)
	Shared.createStoneWall(
		Vector3.new(galleryPos.X + galleryWidth / 2 + 1, CATACOMB_Y + galleryHeight / 2, galleryPos.Z - galleryLength / 2),
		Vector3.new(1, galleryHeight, galleryLength),
		gallery,
		"GalleryWall_East"
	)

	-- Water surface
	Shared.createWaterSurface(
		Vector3.new(galleryPos.X, waterLevel, galleryPos.Z - galleryLength / 2),
		Vector3.new(galleryWidth, 0.2, galleryLength - 15),
		gallery,
		"GalleryWater"
	)

	-- Stone columns rising from water (every 10 studs)
	for i = 0, 5 do
		local colZ = galleryPos.Z - 15 - i * 10
		Shared.createPillar(
			Vector3.new(galleryPos.X, CATACOMB_Y + galleryHeight / 2, colZ),
			galleryHeight,
			1,
			gallery,
			`GalleryColumn_{i}`
		)
	end

	-- Steps at far end (rising out of water)
	for i = 0, 4 do
		createPart(
			gallery,
			`GalleryStep_{i}`,
			Vector3.new(galleryPos.X, CATACOMB_Y + i * 0.5, galleryPos.Z - galleryLength + 3 + i),
			Vector3.new(galleryWidth - 1, 0.5, 1),
			Shared.COLOR_STONE,
			0,
			Enum.Material.Slate
		)
	end

	-- Submerged side alcove (dry pocket for loot)
	local alcovePos = Vector3.new(galleryPos.X + galleryWidth / 2 + 2, CATACOMB_Y, galleryPos.Z - 35)
	Shared.createCatacombRoom({
		position = alcovePos,
		size = Vector3.new(4, 4, 4),
		parent = gallery,
		name = "SubmergedAlcove",
		doorways = {
			{ wall = "west" :: "west", offset = 0, width = 3, height = 3 },
		},
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(galleryPos.X, CATACOMB_Y + 3, galleryPos.Z - 35),
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = Vector3.new(galleryPos.X, CATACOMB_Y + 1, galleryPos.Z - galleryLength + 5),
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Flare",
		position = alcovePos + Vector3.new(0, 1, 0),
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Medkit",
		position = alcovePos + Vector3.new(1, 1, 0),
		chance = 0.5,
		guaranteed = false,
	})

	-- Entity spawn waypoints for aquatic crawlers
	table.insert(waypoints, {
		position = Vector3.new(galleryPos.X, CATACOMB_Y + 1, galleryPos.Z - 25),
		roomId = "FloodedGallery_Near",
		dwellTime = 8,
	})
	table.insert(waypoints, {
		position = Vector3.new(galleryPos.X, CATACOMB_Y + 1, galleryPos.Z - 45),
		roomId = "FloodedGallery_Far",
		dwellTime = 8,
	})

	gallery.Parent = parent
end

------------------------------------------------------------------------
-- Desecrated Chapel: Safe room, lore hub, gate to Warren
------------------------------------------------------------------------

local function buildDesecratedChapel(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local chapel = Instance.new("Model")
	chapel.Name = "DesecratedChapel"

	local chapelPos = Vector3.new(30, CATACOMB_Y, -95)
	local chapelSize = Vector3.new(20, 8, 30)

	-- Chapel room (vaulted ceiling)
	Shared.createCatacombRoom({
		position = chapelPos,
		size = chapelSize,
		parent = chapel,
		name = "ChapelRoom",
		doorways = {
			{ wall = "north" :: "north", offset = 0, width = 4, height = 4.5 },
		},
	})

	-- Inverted altar at far end
	local altarPos = Vector3.new(chapelPos.X, CATACOMB_Y, chapelPos.Z - 12)
	createPart(
		chapel,
		"InvertedAltar",
		altarPos + Vector3.new(0, 1.5, 0),
		Vector3.new(5, 3, 2.5),
		Shared.COLOR_STONE,
		0,
		Enum.Material.Slate
	)

	-- Inverted cross behind altar
	local crossVertical = createPart(
		chapel,
		"InvertedCross_V",
		altarPos + Vector3.new(0, 5, -1),
		Vector3.new(0.4, 4, 0.4),
		Shared.COLOR_IRON,
		0,
		Enum.Material.Metal
	)
	crossVertical.Orientation = Vector3.new(180, 0, 0)

	createPart(
		chapel,
		"InvertedCross_H",
		altarPos + Vector3.new(0, 6, -1),
		Vector3.new(2, 0.4, 0.4),
		Shared.COLOR_IRON,
		0,
		Enum.Material.Metal
	)

	-- Central basin (depression in floor)
	local basinPos = Vector3.new(chapelPos.X, CATACOMB_Y, chapelPos.Z)
	createPart(
		chapel,
		"Basin",
		basinPos - Vector3.new(0, 0.3, 0),
		Vector3.new(4, 0.6, 4),
		Color3.fromRGB(30, 15, 15),
		0,
		Enum.Material.Slate
	)

	-- Vein-like stains radiating from basin
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local dist = 2.5 + math.random() * 3
		Shared.createVein(
			basinPos + Vector3.new(math.cos(angle) * dist, 0.05, math.sin(angle) * dist),
			dist * 0.8,
			0.08,
			Vector3.new(0, math.deg(angle), 90),
			chapel,
			`BasinVein_{i}`
		)
	end

	-- Pews arranged in a circle
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local pewDist = 6
		local pewPos = Vector3.new(
			chapelPos.X + math.cos(angle) * pewDist,
			CATACOMB_Y,
			chapelPos.Z + math.sin(angle) * pewDist
		)
		local pew = Shared.createFurniture("pew", pewPos, chapel)
		-- Rotate pew to face center
		for _, child in pew:GetChildren() do
			if child:IsA("BasePart") then
				child.Orientation = Vector3.new(0, math.deg(angle) + 90, 0)
			end
		end
	end

	-- Candles (dozens, lit despite no one being here)
	local candlePositions = {
		altarPos + Vector3.new(-2, 3.2, 0),
		altarPos + Vector3.new(2, 3.2, 0),
		altarPos + Vector3.new(0, 3.2, -0.5),
		altarPos + Vector3.new(-1, 3.2, 0.5),
		altarPos + Vector3.new(1, 3.2, 0.5),
		chapelPos + Vector3.new(-8, 0.5, -8),
		chapelPos + Vector3.new(8, 0.5, -8),
		chapelPos + Vector3.new(-8, 0.5, 5),
		chapelPos + Vector3.new(8, 0.5, 5),
		chapelPos + Vector3.new(0, 0.5, 10),
		chapelPos + Vector3.new(-5, 0.5, -2),
		chapelPos + Vector3.new(5, 0.5, -2),
	}
	for i, pos in candlePositions do
		Shared.createCandle(pos, chapel, 0.15)
	end

	-- Stained glass windows (decorative, underground, no light transmission)
	for i = 1, 4 do
		local side = if i % 2 == 0 then 1 else -1
		local windowZ = chapelPos.Z - 10 + i * 5
		createPart(
			chapel,
			`StainedGlass_{i}`,
			Vector3.new(chapelPos.X + side * (chapelSize.X / 2 - 0.5), CATACOMB_Y + 5, windowZ),
			Vector3.new(0.3, 3, 2),
			Color3.fromRGB(60, 30 + i * 15, 40 + i * 10),
			0.4,
			Enum.Material.Glass
		)
	end

	-- Frescoes on walls (thin decorative parts)
	for i = 1, 7 do
		local frescoX = chapelPos.X - chapelSize.X / 2 + 0.6
		local frescoZ = chapelPos.Z - 12 + i * 3.5
		createPart(
			chapel,
			`Fresco_{i}`,
			Vector3.new(frescoX, CATACOMB_Y + 4, frescoZ),
			Vector3.new(0.05, 2.5, 2.5),
			Color3.fromRGB(80 + i * 8, 60 + i * 5, 50 + i * 3),
			0.1,
			Enum.Material.SmoothPlastic
		)
	end

	-- Descent Passage (hole in chapel floor behind altar)
	local descentPos = Vector3.new(chapelPos.X, CATACOMB_Y, chapelPos.Z - 14)
	createPart(
		chapel,
		"DescentHole",
		descentPos - Vector3.new(0, 0.5, 0),
		Vector3.new(4, 0.5, 4),
		Shared.COLOR_VOID,
		0.8,
		Enum.Material.SmoothPlastic
	)

	-- Rough staircase descending into darkness (to Warren level)
	local warrenY = Shared.WARREN_Y
	local descentSteps = math.floor(CATACOMB_Y - warrenY)
	for i = 0, math.min(descentSteps - 1, 15) do
		createPart(
			chapel,
			`DescentStep_{i}`,
			Vector3.new(descentPos.X, CATACOMB_Y - 1 - i, descentPos.Z - 1 - i * 0.5),
			Vector3.new(3, 0.5, 1),
			Shared.COLOR_STONE_DARK,
			0,
			Enum.Material.Slate
		)
	end

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = chapelPos + Vector3.new(3, 1, 4),
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = descentPos + Vector3.new(2, 1, 2),
		chance = 1,
		guaranteed = true,
	})

	-- No entity waypoints (safe room)

	chapel.Parent = parent
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local Threshold = {}

function Threshold.build(parent: Instance): FloorData
	local model = Instance.new("Model")
	model.Name = "Threshold"
	model.Parent = parent

	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	-- Build all sub-areas
	buildEntryStairwell(model, lootPositions)
	buildStoneCorridors(model, hidingSpots, waypoints, lootPositions)
	buildBurialChambers(model, hidingSpots, waypoints, lootPositions)
	buildFloodedGallery(model, hidingSpots, waypoints, lootPositions)
	buildDesecratedChapel(model, hidingSpots, waypoints, lootPositions)

	print(`[TheOrigin/Threshold] Built: {#hidingSpots} hiding spots, {#waypoints} waypoints, {#lootPositions} loot positions`)

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return Threshold
