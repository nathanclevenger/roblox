--!strict

--[[
	TheOrigin/Labyrinth - The Warren semi-procedural tunnel network.

	Generates a graph-based tunnel maze with hand-authored tile sets.
	Contains: Branching Tunnels, Echo Chambers, Mirror Room, The Narrow,
	and connecting geometry. The layout changes each run but always
	guarantees a solvable path from entry to exit.

	The generation uses a simplified graph approach: a critical path is
	built first, required nodes (Mirror Room, Echo Chambers) are placed,
	then branches and dead ends are added. Tiles are instantiated as
	3D geometry along the graph.
]]

local Shared = require(script.Parent.Shared)

type HidingSpotData = Shared.HidingSpotData
type FloorData = Shared.FloorData

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local WARREN_Y: number = Shared.WARREN_Y
local TUNNEL_WIDTH: number = Shared.WARREN_TUNNEL_WIDTH
local TUNNEL_HEIGHT: number = Shared.WARREN_TUNNEL_HEIGHT
local NARROW_WIDTH: number = Shared.NARROW_WIDTH
local NARROW_HEIGHT: number = Shared.NARROW_HEIGHT

-- Tile dimensions
local TILE_SIZE: number = 12 -- standard tile footprint
local TUNNEL_LENGTH: number = 12 -- straight tunnel segment length

-- Warren origin (top-left corner of the grid)
local WARREN_ORIGIN = Vector3.new(30, WARREN_Y, -120)

------------------------------------------------------------------------
-- Type Definitions
------------------------------------------------------------------------

type TileType = "straight" | "t_junction" | "cross" | "l_bend" | "dead_end"
	| "echo_chamber" | "mirror_room" | "narrow_entry" | "shaft" | "grotto"

type TileNode = {
	id: number,
	tileType: TileType,
	gridX: number,
	gridZ: number,
	connections: { number }, -- IDs of connected nodes
	isCriticalPath: boolean,
	isRequired: boolean,
}

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
-- Tile Builders
------------------------------------------------------------------------

local function tileWorldPos(gridX: number, gridZ: number): Vector3
	return WARREN_ORIGIN + Vector3.new(gridX * TILE_SIZE, 0, gridZ * TILE_SIZE)
end

local function buildStraightTunnel(
	pos: Vector3,
	parent: Instance,
	name: string,
	vertical: boolean -- true = runs along Z, false = runs along X
): Model
	local model = Instance.new("Model")
	model.Name = name

	local length = TUNNEL_LENGTH
	local width = TUNNEL_WIDTH
	local height = TUNNEL_HEIGHT

	if vertical then
		-- Floor
		Shared.createStoneFloor(pos + Vector3.new(0, -0.5, 0), Vector3.new(width + 2, 1, length), model, "Floor")
		-- Ceiling
		Shared.createStoneCeiling(pos + Vector3.new(0, height + 0.5, 0), Vector3.new(width + 2, 1, length), model, "Ceiling")
		-- Walls
		Shared.createStoneWall(pos + Vector3.new(-width / 2 - 1, height / 2, 0), Vector3.new(1, height, length), model, "Wall_W")
		Shared.createStoneWall(pos + Vector3.new(width / 2 + 1, height / 2, 0), Vector3.new(1, height, length), model, "Wall_E")
	else
		Shared.createStoneFloor(pos + Vector3.new(0, -0.5, 0), Vector3.new(length, 1, width + 2), model, "Floor")
		Shared.createStoneCeiling(pos + Vector3.new(0, height + 0.5, 0), Vector3.new(length, 1, width + 2), model, "Ceiling")
		Shared.createStoneWall(pos + Vector3.new(0, height / 2, -width / 2 - 1), Vector3.new(length, height, 1), model, "Wall_N")
		Shared.createStoneWall(pos + Vector3.new(0, height / 2, width / 2 + 1), Vector3.new(length, height, 1), model, "Wall_S")
	end

	-- Atmospheric details: dripping water stain, grit on floor
	createPart(
		model, "WaterStain",
		pos + Vector3.new(0, 0.05, 0),
		Vector3.new(1.5, 0.05, 2),
		Color3.fromRGB(40, 45, 40), 0.5, Enum.Material.Slate
	)

	-- Torch sconce (unlit)
	Shared.createTorchSconce(
		pos + Vector3.new(if vertical then -width / 2 - 0.3 else 0, 2.5, if vertical then 0 else -width / 2 - 0.3),
		model
	)

	model.Parent = parent
	return model
end

local function buildTJunction(
	pos: Vector3,
	parent: Instance,
	name: string
): Model
	local model = Instance.new("Model")
	model.Name = name

	local size = TILE_SIZE
	local height = TUNNEL_HEIGHT

	-- Open junction room
	Shared.createStoneFloor(pos + Vector3.new(0, -0.5, 0), Vector3.new(size, 1, size), model, "Floor")
	Shared.createStoneCeiling(pos + Vector3.new(0, height + 0.5, 0), Vector3.new(size, 1, size), model, "Ceiling")

	-- Partial walls (leaving 3 openings + 1 wall)
	-- North wall (solid)
	Shared.createStoneWall(
		pos + Vector3.new(0, height / 2, -size / 2),
		Vector3.new(size, height, 1), model, "Wall_N"
	)
	-- South opening segments (left and right of opening)
	Shared.createStoneWall(
		pos + Vector3.new(-size / 2 + 1.5, height / 2, size / 2),
		Vector3.new(3, height, 1), model, "Wall_S_L"
	)
	Shared.createStoneWall(
		pos + Vector3.new(size / 2 - 1.5, height / 2, size / 2),
		Vector3.new(3, height, 1), model, "Wall_S_R"
	)
	-- East opening segments
	Shared.createStoneWall(
		pos + Vector3.new(size / 2, height / 2, -size / 2 + 1.5),
		Vector3.new(1, height, 3), model, "Wall_E_Top"
	)
	Shared.createStoneWall(
		pos + Vector3.new(size / 2, height / 2, size / 2 - 1.5),
		Vector3.new(1, height, 3), model, "Wall_E_Bot"
	)
	-- West opening segments
	Shared.createStoneWall(
		pos + Vector3.new(-size / 2, height / 2, -size / 2 + 1.5),
		Vector3.new(1, height, 3), model, "Wall_W_Top"
	)
	Shared.createStoneWall(
		pos + Vector3.new(-size / 2, height / 2, size / 2 - 1.5),
		Vector3.new(1, height, 3), model, "Wall_W_Bot"
	)

	-- Archway at center
	Shared.createArchway(pos, TUNNEL_WIDTH, TUNNEL_HEIGHT, 1, model, "JunctionArch", true)

	model.Parent = parent
	return model
end

local function buildLBend(
	pos: Vector3,
	parent: Instance,
	name: string
): Model
	local model = Instance.new("Model")
	model.Name = name

	local size = TILE_SIZE
	local height = TUNNEL_HEIGHT

	Shared.createStoneFloor(pos + Vector3.new(0, -0.5, 0), Vector3.new(size, 1, size), model, "Floor")
	Shared.createStoneCeiling(pos + Vector3.new(0, height + 0.5, 0), Vector3.new(size, 1, size), model, "Ceiling")

	-- L-bend: open on south and east, closed on north and west
	Shared.createStoneWall(pos + Vector3.new(0, height / 2, -size / 2), Vector3.new(size, height, 1), model, "Wall_N")
	Shared.createStoneWall(pos + Vector3.new(-size / 2, height / 2, 0), Vector3.new(1, height, size), model, "Wall_W")
	-- South opening
	Shared.createStoneWall(
		pos + Vector3.new(-size / 2 + 1.5, height / 2, size / 2),
		Vector3.new(3, height, 1), model, "Wall_S_L"
	)
	Shared.createStoneWall(
		pos + Vector3.new(size / 2 - 1.5, height / 2, size / 2),
		Vector3.new(3, height, 1), model, "Wall_S_R"
	)
	-- East opening
	Shared.createStoneWall(
		pos + Vector3.new(size / 2, height / 2, -size / 2 + 1.5),
		Vector3.new(1, height, 3), model, "Wall_E_Top"
	)
	Shared.createStoneWall(
		pos + Vector3.new(size / 2, height / 2, size / 2 - 1.5),
		Vector3.new(1, height, 3), model, "Wall_E_Bot"
	)

	model.Parent = parent
	return model
end

local function buildDeadEnd(
	pos: Vector3,
	parent: Instance,
	name: string,
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
): Model
	local model = Instance.new("Model")
	model.Name = name

	local width = TUNNEL_WIDTH + 1
	local depth = 6
	local height = TUNNEL_HEIGHT

	Shared.createStoneFloor(pos + Vector3.new(0, -0.5, 0), Vector3.new(width + 2, 1, depth + 2), model, "Floor")
	Shared.createStoneCeiling(pos + Vector3.new(0, height + 0.5, 0), Vector3.new(width + 2, 1, depth + 2), model, "Ceiling")
	Shared.createStoneWall(pos + Vector3.new(0, height / 2, -depth / 2 - 0.5), Vector3.new(width + 2, height, 1), model, "Wall_Back")
	Shared.createStoneWall(pos + Vector3.new(-width / 2 - 0.5, height / 2, 0), Vector3.new(1, height, depth), model, "Wall_L")
	Shared.createStoneWall(pos + Vector3.new(width / 2 + 0.5, height / 2, 0), Vector3.new(1, height, depth), model, "Wall_R")

	-- False light (lure / trap marker)
	Shared.createPulsingLight(
		pos + Vector3.new(0, height - 1, -depth / 2 + 1),
		model, 0.02, 0.08,
		Color3.fromRGB(180, 160, 100),
		6, 0.5
	)

	-- Random loot at dead ends
	table.insert(lootPositions, {
		itemType = "Battery",
		position = pos + Vector3.new(0, 1, -1),
		chance = 0.4,
		guaranteed = false,
	})

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Special Tile: Echo Chamber
------------------------------------------------------------------------

local function buildEchoChamber(
	pos: Vector3,
	parent: Instance,
	name: string,
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
): Model
	local model = Instance.new("Model")
	model.Name = name

	local radius = 7
	local height = 6

	-- Approximate circular chamber with octagonal floor/ceiling
	Shared.createStoneFloor(
		pos + Vector3.new(0, -0.5, 0),
		Vector3.new(radius * 2, 1, radius * 2),
		model, "Floor"
	)
	Shared.createStoneCeiling(
		pos + Vector3.new(0, height + 0.5, 0),
		Vector3.new(radius * 2, 1, radius * 2),
		model, "Ceiling"
	)

	-- Approximate circular walls with 8 segments
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		local nextAngle = ((i + 1) / 8) * math.pi * 2
		local midAngle = (angle + nextAngle) / 2
		local wallX = math.cos(midAngle) * radius
		local wallZ = math.sin(midAngle) * radius
		local wallLen = 2 * radius * math.sin(math.pi / 8)
		local wallRot = math.deg(midAngle)

		-- Skip walls where tunnel exits would be (every other wall for 4 exits)
		if i % 2 == 0 then
			continue
		end

		local wall = Shared.createStoneWall(
			pos + Vector3.new(wallX, height / 2, wallZ),
			Vector3.new(wallLen, height, 1),
			model,
			`ChamberWall_{i}`
		)
		wall.Orientation = Vector3.new(0, wallRot, 0)
	end

	-- Stalactites and stalagmites
	for i = 1, 5 do
		local stalAngle = math.random() * math.pi * 2
		local stalDist = math.random() * (radius - 2)
		Shared.createStalactite(
			pos + Vector3.new(math.cos(stalAngle) * stalDist, height, math.sin(stalAngle) * stalDist),
			1 + math.random() * 1.5,
			model,
			`Stalactite_{i}`,
			true -- hanging down
		)
		Shared.createStalactite(
			pos + Vector3.new(math.cos(stalAngle + 1) * stalDist, 0, math.sin(stalAngle + 1) * stalDist),
			0.5 + math.random() * 1,
			model,
			`Stalagmite_{i}`,
			false -- growing up
		)
	end

	-- Water pool on floor
	createPart(
		model, "WaterPool",
		pos + Vector3.new(0, 0.05, 0),
		Vector3.new(4, 0.1, 4),
		Shared.COLOR_WATER_MURKY, 0.5, Enum.Material.Glass
	)

	-- Dim pulsing ambient light
	Shared.createPulsingLight(
		pos + Vector3.new(0, height - 1, 0),
		model, 0.02, 0.08,
		Shared.COLOR_BIOLUM, 10, 0.4
	)

	-- Echo Chamber marker attribute (used by audio system)
	local marker = Instance.new("Part")
	marker.Name = "EchoChamberMarker"
	marker.Size = Vector3.new(1, 1, 1)
	marker.Position = pos + Vector3.new(0, 2, 0)
	marker.Anchored = true
	marker.Transparency = 1
	marker.CanCollide = false
	marker:SetAttribute("IsEchoChamber", true)
	marker:SetAttribute("EchoDelay", 0.3 + math.random() * 0.9)
	marker.Parent = model

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = pos + Vector3.new(1, 1, 0),
		chance = 0.7,
		guaranteed = false,
	})

	-- Waypoint (Mimic hunting ground)
	table.insert(waypoints, {
		position = pos + Vector3.new(0, 3, 0),
		roomId = name,
		dwellTime = 6,
	})

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Special Tile: Mirror Room
------------------------------------------------------------------------

local function buildMirrorRoom(
	pos: Vector3,
	parent: Instance,
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } }
): Model
	local model = Instance.new("Model")
	model.Name = "MirrorRoom"

	local roomSize = 20
	local height = 5

	-- Floor (polished reflective)
	local floor = Shared.createStoneFloor(
		pos + Vector3.new(0, -0.5, 0),
		Vector3.new(roomSize, 1, roomSize),
		model, "Floor"
	)
	floor.Material = Enum.Material.Glass
	floor.Color = Color3.fromRGB(15, 15, 18)
	floor.Reflectance = 0.3

	-- Ceiling
	Shared.createStoneCeiling(
		pos + Vector3.new(0, height + 0.5, 0),
		Vector3.new(roomSize, 1, roomSize),
		model, "Ceiling"
	)

	-- Reflective walls (all 4 sides, with entry/exit gaps)
	-- North wall (entry)
	Shared.createReflectiveSurface(
		pos + Vector3.new(-roomSize / 2 + 3, height / 2, -roomSize / 2),
		Vector3.new(6, height, 0.5),
		model, "MirrorWall_N_L"
	)
	Shared.createReflectiveSurface(
		pos + Vector3.new(roomSize / 2 - 3, height / 2, -roomSize / 2),
		Vector3.new(6, height, 0.5),
		model, "MirrorWall_N_R"
	)
	-- South wall (exit)
	Shared.createReflectiveSurface(
		pos + Vector3.new(-roomSize / 2 + 3, height / 2, roomSize / 2),
		Vector3.new(6, height, 0.5),
		model, "MirrorWall_S_L"
	)
	Shared.createReflectiveSurface(
		pos + Vector3.new(roomSize / 2 - 3, height / 2, roomSize / 2),
		Vector3.new(6, height, 0.5),
		model, "MirrorWall_S_R"
	)
	-- East wall (full)
	Shared.createReflectiveSurface(
		pos + Vector3.new(roomSize / 2, height / 2, 0),
		Vector3.new(0.5, height, roomSize),
		model, "MirrorWall_E"
	)
	-- West wall (full)
	Shared.createReflectiveSurface(
		pos + Vector3.new(-roomSize / 2, height / 2, 0),
		Vector3.new(0.5, height, roomSize),
		model, "MirrorWall_W"
	)

	-- Ceiling reflective panels
	for i = 1, 3 do
		Shared.createReflectiveSurface(
			pos + Vector3.new(-6 + i * 4, height + 0.3, 0),
			Vector3.new(3, 0.3, roomSize * 0.6),
			model, `MirrorCeiling_{i}`
		)
	end

	-- Pulsing ambient light (warm, unsettling)
	Shared.createPulsingLight(
		pos + Vector3.new(0, height - 1, 0),
		model, 0.05, 0.15,
		Color3.fromRGB(200, 150, 120), 16, 0.6
	)

	-- Side ambient lights
	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2
		Shared.createPulsingLight(
			pos + Vector3.new(math.cos(angle) * 8, 2, math.sin(angle) * 8),
			model, 0.02, 0.08,
			Shared.COLOR_BIOLUM, 8, 0.3 + i * 0.1
		)
	end

	-- Mirror Room marker
	local marker = Instance.new("Part")
	marker.Name = "MirrorRoomMarker"
	marker.Size = Vector3.new(1, 1, 1)
	marker.Position = pos + Vector3.new(0, 2, 0)
	marker.Anchored = true
	marker.Transparency = 1
	marker.CanCollide = false
	marker:SetAttribute("IsMirrorRoom", true)
	marker.Parent = model

	-- Loot (Patient 31 effects box in center)
	local loreBox = createPart(
		model, "PersonalEffectsBox",
		pos + Vector3.new(0, 0.3, 0),
		Vector3.new(1, 0.6, 0.8),
		Color3.fromRGB(120, 100, 70), 0, Enum.Material.Cardboard
	)

	table.insert(lootPositions, {
		itemType = "Battery",
		position = pos + Vector3.new(3, 1, roomSize / 2 - 2),
		chance = 1,
		guaranteed = true,
	})

	-- Mimic entity waypoint
	table.insert(waypoints, {
		position = pos + Vector3.new(0, 3, 0),
		roomId = "MirrorRoom",
		dwellTime = 10,
	})

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Special Tile: The Narrow (crawlspace gauntlet)
------------------------------------------------------------------------

local function buildTheNarrow(
	pos: Vector3,
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
): Model
	local model = Instance.new("Model")
	model.Name = "TheNarrow"

	local narrowLength = 40
	local width = NARROW_WIDTH
	local height = NARROW_HEIGHT

	-- Main crawlspace tunnel (curving path approximated with segments)
	local segments = 8
	local segLength = narrowLength / segments
	for i = 0, segments - 1 do
		local segZ = pos.Z - i * segLength
		local segX = pos.X + math.sin(i * 0.8) * 2 -- gentle curve
		local segY = pos.Y - i * 0.3 -- slight descent

		-- Floor
		Shared.createStoneFloor(
			Vector3.new(segX, segY - 0.5, segZ),
			Vector3.new(width + 1, 0.5, segLength + 1),
			model, `NarrowFloor_{i}`
		)
		-- Ceiling (low)
		Shared.createStoneCeiling(
			Vector3.new(segX, segY + height + 0.3, segZ),
			Vector3.new(width + 1, 0.5, segLength + 1),
			model, `NarrowCeiling_{i}`
		)
		-- Walls
		Shared.createStoneWall(
			Vector3.new(segX - width / 2 - 0.5, segY + height / 2, segZ),
			Vector3.new(0.5, height, segLength + 1),
			model, `NarrowWall_L_{i}`
		)
		Shared.createStoneWall(
			Vector3.new(segX + width / 2 + 0.5, segY + height / 2, segZ),
			Vector3.new(0.5, height, segLength + 1),
			model, `NarrowWall_R_{i}`
		)

		-- Organic texture transition (later segments become more flesh-like)
		if i >= segments / 2 then
			local organicWall = createPart(
				model, `OrganicOverlay_{i}`,
				Vector3.new(segX - width / 2 - 0.2, segY + height / 2, segZ),
				Vector3.new(0.1, height * 0.6, segLength * 0.7),
				Shared.COLOR_FLESH_PALE, 0.3, Enum.Material.CorrodesMetal
			)
		end
	end

	-- Pinch points (2 squeeze spots where tunnel narrows further)
	for _, pinchIdx in { 2, 5 } do
		local pinchZ = pos.Z - pinchIdx * segLength
		local pinchX = pos.X + math.sin(pinchIdx * 0.8) * 2
		local pinchY = pos.Y - pinchIdx * 0.3

		-- Narrowing rocks from each side
		createPart(
			model, `Pinch_L_{pinchIdx}`,
			Vector3.new(pinchX - width / 2 + 0.3, pinchY + 0.5, pinchZ),
			Vector3.new(0.8, 1.5, 1.5),
			Shared.COLOR_STONE_LIGHT, 0, Enum.Material.Slate
		)
		createPart(
			model, `Pinch_R_{pinchIdx}`,
			Vector3.new(pinchX + width / 2 - 0.3, pinchY + 0.8, pinchZ),
			Vector3.new(0.6, 1.2, 1.2),
			Shared.COLOR_STONE_LIGHT, 0, Enum.Material.Slate
		)

		-- Pinch marker (used by gameplay system)
		local pinchMarker = Instance.new("Part")
		pinchMarker.Name = `PinchPoint_{pinchIdx}`
		pinchMarker.Size = Vector3.new(1, 1, 1)
		pinchMarker.Position = Vector3.new(pinchX, pinchY + 1, pinchZ)
		pinchMarker.Anchored = true
		pinchMarker.Transparency = 1
		pinchMarker.CanCollide = false
		pinchMarker:SetAttribute("IsPinchPoint", true)
		pinchMarker.Parent = model
	end

	-- Grottos (rest areas with hiding spot fissures)
	for grottoIdx, grottoSegIdx in { 3, 6 } do
		local grottoZ = pos.Z - grottoSegIdx * segLength
		local grottoX = pos.X + math.sin(grottoSegIdx * 0.8) * 2
		local grottoY = pos.Y - grottoSegIdx * 0.3

		-- Expanded area
		local grottoSize = Vector3.new(3, 3, 3)
		Shared.createCatacombRoom({
			position = Vector3.new(grottoX + width, grottoY, grottoZ),
			size = grottoSize,
			parent = model,
			name = `Grotto_{grottoIdx}`,
			doorways = {
				{ wall = "west" :: "west", offset = 0, width = width, height = NARROW_HEIGHT },
			},
		})

		-- Fissure hiding spot
		local fissurePos = Vector3.new(grottoX + width + 1, grottoY + 0.5, grottoZ)
		local _, spotData = Shared.createHidingSpot(
			fissurePos,
			"BurialNiche",
			`narrow_fissure_{grottoIdx}`,
			model
		)
		table.insert(hidingSpots, spotData)

		-- Grotto loot
		if grottoIdx == 1 then
			table.insert(lootPositions, {
				itemType = "Bandage",
				position = Vector3.new(grottoX + width, grottoY + 1, grottoZ),
				chance = 1,
				guaranteed = true,
			})
		else
			table.insert(lootPositions, {
				itemType = "Battery",
				position = Vector3.new(grottoX + width, grottoY + 1, grottoZ),
				chance = 0.5,
				guaranteed = false,
			})
		end
	end

	-- Threshold Gate at exit (archway with carved symbols)
	local exitZ = pos.Z - narrowLength
	local exitY = pos.Y - segments * 0.3
	Shared.createArchway(
		Vector3.new(pos.X, exitY, exitZ),
		TUNNEL_WIDTH, Shared.CATACOMB_CORRIDOR_HEIGHT, 1.5,
		model, "ThresholdGate", true
	)

	-- Sealed door marker behind threshold (point of no return)
	local gatePart = Instance.new("Part")
	gatePart.Name = "ThresholdGateMarker"
	gatePart.Size = Vector3.new(3, 4, 0.5)
	gatePart.Position = Vector3.new(pos.X, exitY + 2, exitZ + 1)
	gatePart.Anchored = true
	gatePart.Transparency = 1
	gatePart.CanCollide = false
	gatePart:SetAttribute("IsThresholdGate", true)
	gatePart.Parent = model

	-- Crawler waypoint (approaches from behind)
	table.insert(waypoints, {
		position = Vector3.new(pos.X, pos.Y + 1, pos.Z - narrowLength * 0.3),
		roomId = "TheNarrow_Mid",
		dwellTime = 0, -- always moving
	})

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Grotto Tile (rest/loot rooms within Warren)
------------------------------------------------------------------------

local function buildGrotto(
	pos: Vector3,
	parent: Instance,
	name: string,
	hidingSpots: { HidingSpotData },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
): Model
	local model = Instance.new("Model")
	model.Name = name

	local size = 6
	local height = Shared.CATACOMB_CORRIDOR_HEIGHT

	Shared.createCatacombRoom({
		position = pos,
		size = Vector3.new(size, height, size),
		parent = model,
		name = name .. "_Room",
		doorways = {
			{ wall = "south" :: "south", offset = 0, width = TUNNEL_WIDTH, height = TUNNEL_HEIGHT },
			{ wall = "north" :: "north", offset = 0, width = TUNNEL_WIDTH, height = TUNNEL_HEIGHT },
		},
	})

	-- Small shelf or alcove with supplies
	createPart(
		model, "Shelf",
		pos + Vector3.new(-2, 1.5, -2),
		Vector3.new(2, 0.3, 1),
		Shared.COLOR_STONE_LIGHT, 0, Enum.Material.Slate
	)

	-- Hiding spot (small alcove)
	local _, spotData = Shared.createHidingSpot(
		pos + Vector3.new(2, 0.5, 2),
		"BurialNiche",
		name .. "_alcove",
		model
	)
	table.insert(hidingSpots, spotData)

	-- Loot
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = pos + Vector3.new(-2, 2, -2),
		chance = 0.5,
		guaranteed = false,
	})

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Warren Generation: Build the full procedural layout
------------------------------------------------------------------------

local function generateWarren(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local warren = Instance.new("Model")
	warren.Name = "TheWarren"

	--[[
		Simplified procedural generation:
		- Build a fixed critical path (14 nodes) with deterministic layout
		- Place required nodes (Mirror Room at midpoint, 2 Echo Chambers)
		- Add branches with dead ends
		- Connect with tunnel geometry

		For a full procedural system, this would use random seeds.
		Here we create a representative layout that demonstrates the
		architecture while being deterministic for testing.
	]]

	local nodeIndex = 0
	local function nextNode(): number
		nodeIndex += 1
		return nodeIndex
	end

	-- Critical path: Z decreases as we go deeper
	-- Entry -> Tunnels -> Echo 1 -> Tunnels -> Mirror Room -> Tunnels -> Echo 2 -> Grotto -> Narrow

	-- Node 1: Entry junction from Descent Passage
	local entryPos = tileWorldPos(0, 0)
	buildTJunction(entryPos, warren, "Warren_Entry")
	table.insert(waypoints, {
		position = entryPos + Vector3.new(0, 3, 0),
		roomId = "Warren_Entry",
		dwellTime = 3,
	})

	-- Node 2-3: Initial tunnels
	buildStraightTunnel(tileWorldPos(0, -1), warren, "Tunnel_1", true)
	buildLBend(tileWorldPos(0, -2), warren, "Bend_1")

	-- Node 4: Branch point
	buildTJunction(tileWorldPos(1, -2), warren, "Junction_1")
	table.insert(waypoints, {
		position = tileWorldPos(1, -2) + Vector3.new(0, 3, 0),
		roomId = "Warren_Junction_1",
		dwellTime = 4,
	})

	-- Branch 1: Dead end east
	buildStraightTunnel(tileWorldPos(2, -2), warren, "Branch1_Tunnel", false)
	buildDeadEnd(tileWorldPos(3, -2), warren, "DeadEnd_1", lootPositions)

	-- Node 5: Tunnel south
	buildStraightTunnel(tileWorldPos(1, -3), warren, "Tunnel_2", true)

	-- Node 6: Echo Chamber 1
	buildEchoChamber(tileWorldPos(1, -4), warren, "EchoChamber_1", waypoints, lootPositions)

	-- Node 7-8: Tunnels toward Mirror Room
	buildStraightTunnel(tileWorldPos(1, -5), warren, "Tunnel_3", true)
	buildLBend(tileWorldPos(1, -6), warren, "Bend_2")

	-- Node 9: Mirror Room (midpoint)
	local mirrorPos = tileWorldPos(2, -6)
	buildMirrorRoom(mirrorPos, warren, lootPositions, waypoints)

	-- Node 10: Junction after Mirror Room
	buildTJunction(tileWorldPos(2, -7), warren, "Junction_2")
	table.insert(waypoints, {
		position = tileWorldPos(2, -7) + Vector3.new(0, 3, 0),
		roomId = "Warren_Junction_2",
		dwellTime = 4,
	})

	-- Branch 2: Dead end west
	buildStraightTunnel(tileWorldPos(1, -7), warren, "Branch2_Tunnel", false)
	buildDeadEnd(tileWorldPos(0, -7), warren, "DeadEnd_2", lootPositions)

	-- Branch 3: Grotto east
	buildStraightTunnel(tileWorldPos(3, -7), warren, "Branch3_Tunnel", false)
	buildGrotto(tileWorldPos(4, -7), warren, "Grotto_1", hidingSpots, lootPositions)

	-- Node 11: Tunnel continuing
	buildStraightTunnel(tileWorldPos(2, -8), warren, "Tunnel_4", true)

	-- Node 12: Echo Chamber 2
	buildEchoChamber(tileWorldPos(2, -9), warren, "EchoChamber_2", waypoints, lootPositions)

	-- Node 13: Tunnel to Grotto
	buildStraightTunnel(tileWorldPos(2, -10), warren, "Tunnel_5", true)
	buildGrotto(tileWorldPos(2, -11), warren, "Grotto_2", hidingSpots, lootPositions)

	-- Node 14: The Narrow (exit)
	local narrowPos = tileWorldPos(2, -12)
	buildTheNarrow(narrowPos, warren, hidingSpots, waypoints, lootPositions)

	-- Graffiti scattered throughout (modern spray paint, some wrong directions)
	local graffitiTexts = { "TURN BACK", "IT KNOWS", "3RD LEFT", "NOT THIS WAY", "KEEP GOING" }
	local graffitiPositions = {
		tileWorldPos(0, -1) + Vector3.new(-TUNNEL_WIDTH / 2 - 0.4, 2, 0),
		tileWorldPos(1, -3) + Vector3.new(TUNNEL_WIDTH / 2 + 0.4, 1.5, 2),
		tileWorldPos(1, -5) + Vector3.new(-TUNNEL_WIDTH / 2 - 0.4, 2.5, -1),
		tileWorldPos(2, -8) + Vector3.new(TUNNEL_WIDTH / 2 + 0.4, 1.8, 0),
		tileWorldPos(2, -10) + Vector3.new(-TUNNEL_WIDTH / 2 - 0.4, 2, 1),
	}
	for i, grafPos in graffitiPositions do
		local graf = createPart(
			warren,
			`Graffiti_{i}`,
			grafPos,
			Vector3.new(0.05, 0.5, 2),
			Color3.fromRGB(200, 50, 30), 0.2, Enum.Material.Neon
		)
		graf:SetAttribute("GraffitiText", graffitiTexts[((i - 1) % #graffitiTexts) + 1])
		graf:SetAttribute("IsAccurate", i % 2 == 0) -- 50% correct
	end

	-- Dense fog blanket covering the entire warren
	-- Upper warren (entry area) - moderate fog
	Shared.createFogVolume(
		tileWorldPos(1, -2) + Vector3.new(0, TUNNEL_HEIGHT / 2, 0),
		Vector3.new(TILE_SIZE * 6, TUNNEL_HEIGHT + 2, TILE_SIZE * 4),
		warren,
		Color3.fromRGB(10, 10, 14),
		0.65
	)
	-- Mid warren (echo chambers, mirror room) - thick fog
	Shared.createFogVolume(
		tileWorldPos(2, -6) + Vector3.new(0, TUNNEL_HEIGHT / 2, 0),
		Vector3.new(TILE_SIZE * 6, TUNNEL_HEIGHT + 2, TILE_SIZE * 5),
		warren,
		Color3.fromRGB(8, 8, 12),
		0.55
	)
	-- Deep warren (the narrow, grotto) - very thick fog
	Shared.createFogVolume(
		tileWorldPos(2, -10) + Vector3.new(0, TUNNEL_HEIGHT / 2, 0),
		Vector3.new(TILE_SIZE * 5, TUNNEL_HEIGHT + 2, TILE_SIZE * 5),
		warren,
		Color3.fromRGB(5, 5, 10),
		0.45
	)

	-- Smoke emitters placed throughout the warren for volumetric fog effect
	local smokePositions = {
		tileWorldPos(0, -1) + Vector3.new(0, 1, 0),
		tileWorldPos(1, -3) + Vector3.new(0, 1, 0),
		tileWorldPos(1, -5) + Vector3.new(0, 1, 0),
		tileWorldPos(2, -6) + Vector3.new(0, 1, 0),
		tileWorldPos(2, -7) + Vector3.new(0, 1, 0),
		tileWorldPos(2, -9) + Vector3.new(0, 1, 0),
		tileWorldPos(2, -11) + Vector3.new(0, 1, 0),
		tileWorldPos(1, -7) + Vector3.new(0, 1, 0),
		tileWorldPos(3, -7) + Vector3.new(0, 1, 0),
		tileWorldPos(2, -12) + Vector3.new(0, 1, 0),
	}
	for i, smokePos in smokePositions do
		local emitterPart = Instance.new("Part")
		emitterPart.Name = `FogEmitter_{i}`
		emitterPart.Size = Vector3.new(1, 1, 1)
		emitterPart.Position = smokePos
		emitterPart.Anchored = true
		emitterPart.Transparency = 1
		emitterPart.CanCollide = false

		local smoke = Instance.new("Smoke")
		smoke.Color = Color3.fromRGB(15, 15, 20)
		smoke.Opacity = 0.4
		smoke.RiseVelocity = 0.5
		smoke.Size = 12
		smoke.Parent = emitterPart

		emitterPart.Parent = warren
	end

	-- Air particle direction markers (always point toward exit)
	for i = 1, 6 do
		local markerPos = tileWorldPos(
			if i <= 3 then 1 else 2,
			-2 * i
		)
		local particleMarker = Instance.new("Part")
		particleMarker.Name = `AirflowMarker_{i}`
		particleMarker.Size = Vector3.new(1, 1, 1)
		particleMarker.Position = markerPos + Vector3.new(0, 2, 0)
		particleMarker.Anchored = true
		particleMarker.Transparency = 1
		particleMarker.CanCollide = false
		particleMarker:SetAttribute("AirflowDirection", Vector3.new(0, -0.1, -1).Unit)
		particleMarker.Parent = warren
	end

	warren.Parent = parent
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local Labyrinth = {}

function Labyrinth.build(parent: Instance): FloorData
	local model = Instance.new("Model")
	model.Name = "Labyrinth"
	model.Parent = parent

	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	generateWarren(model, hidingSpots, waypoints, lootPositions)

	print(`[TheOrigin/Labyrinth] Built: {#hidingSpots} hiding spots, {#waypoints} waypoints, {#lootPositions} loot positions`)

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return Labyrinth
