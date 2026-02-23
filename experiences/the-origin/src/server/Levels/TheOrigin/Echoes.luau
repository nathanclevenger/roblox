--!strict

--[[
	TheOrigin/Echoes - Distorted recreations of previous levels.

	Scattered throughout the Warren and Sanctuary transitional spaces,
	fragments of earlier levels appear: hospital corridors at wrong
	angles, subway platforms half-absorbed into stone, research station
	panels fused with organic growth, forest bark growing from walls.

	These "echoes" exist at the boundary between zones, making the
	player question whether they have somehow returned to a previous
	level or whether the Origin is leaking its influence outward
	through time and space.

	Each echo fragment is built from corrupted versions of the Hospital
	Shared builder functions, with wrong colors, non-standard angles,
	organic growth, and impossible geometry.
]]

local Shared = require(script.Parent.Shared)

type HidingSpotData = Shared.HidingSpotData
type FloorData = Shared.FloorData

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local WARREN_Y: number = Shared.WARREN_Y
local SANCTUARY_Y: number = Shared.SANCTUARY_Y

-- Corrupted color palette (hospital colors shifted toward red/purple)
local COLOR_CORRUPT_WALL = Color3.fromRGB(140, 100, 100)
local COLOR_CORRUPT_FLOOR = Color3.fromRGB(100, 90, 85)
local COLOR_CORRUPT_CEILING = Color3.fromRGB(120, 95, 95)
local COLOR_CORRUPT_METAL = Color3.fromRGB(90, 80, 85)
local COLOR_CORRUPT_TILE = Color3.fromRGB(110, 100, 95)
local COLOR_CORRUPT_GLASS = Color3.fromRGB(80, 60, 70)
local COLOR_CORRUPT_WOOD = Color3.fromRGB(60, 35, 35)
local COLOR_SUBWAY_RUST = Color3.fromRGB(70, 50, 40)
local COLOR_LAB_PANEL = Color3.fromRGB(90, 90, 105)
local COLOR_FOREST_BARK = Color3.fromRGB(45, 30, 25)

------------------------------------------------------------------------
-- Helper: create a styled Part
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
-- Echo Fragment: Hospital Corridor Fragment
------------------------------------------------------------------------

--[[
	A section of hospital corridor embedded in cave stone at a wrong
	angle. Fluorescent light fixtures are present but dead. The linoleum
	floor is cracked and warped. Hospital walls terminate abruptly into
	raw stone. Everything is tinted red/brown.
]]
local function buildHospitalEcho(
	position: Vector3,
	parent: Instance,
	rotation: number, -- Y-axis rotation in degrees
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
): Model
	local model = Instance.new("Model")
	model.Name = "Echo_Hospital"

	-- Corridor fragment (tilted, partially embedded in stone)
	local corridorLength = 15
	local corridorWidth = 6
	local corridorHeight = 10

	-- Floor (linoleum, cracked)
	local floor = createPart(
		model, "HospitalFloor",
		position + Vector3.new(0, -0.5, 0),
		Vector3.new(corridorLength, 1, corridorWidth),
		COLOR_CORRUPT_FLOOR, 0, Enum.Material.SmoothPlastic
	)
	floor.Orientation = Vector3.new(3, rotation, -2) -- slightly tilted

	-- Ceiling
	local ceiling = createPart(
		model, "HospitalCeiling",
		position + Vector3.new(0, corridorHeight, 0),
		Vector3.new(corridorLength, 1, corridorWidth),
		COLOR_CORRUPT_CEILING, 0, Enum.Material.Concrete
	)
	ceiling.Orientation = Vector3.new(-2, rotation, 1)

	-- Walls (one intact, one broken off into stone)
	createPart(
		model, "HospitalWall_L",
		position + Vector3.new(0, corridorHeight / 2, -corridorWidth / 2),
		Vector3.new(corridorLength, corridorHeight, 1),
		COLOR_CORRUPT_WALL, 0, Enum.Material.Concrete
	).Orientation = Vector3.new(0, rotation, 0)

	-- Right wall (broken, partial)
	createPart(
		model, "HospitalWall_R_Fragment",
		position + Vector3.new(-2, corridorHeight / 2, corridorWidth / 2),
		Vector3.new(corridorLength * 0.6, corridorHeight, 1),
		COLOR_CORRUPT_WALL, 0, Enum.Material.Concrete
	).Orientation = Vector3.new(0, rotation + 5, -3)

	-- Dead fluorescent light fixtures
	for i = 1, 3 do
		local fixturePos = position + Vector3.new(-corridorLength / 2 + i * 4, corridorHeight - 0.5, 0)
		local fixture = createPart(
			model, `DeadLight_{i}`,
			fixturePos,
			Vector3.new(2, 0.3, 0.5),
			Color3.fromRGB(180, 175, 170), 0.2, Enum.Material.SmoothPlastic
		)
		-- One fixture flickers weakly
		if i == 2 then
			Shared.createPulsingLight(
				fixturePos, model, 0.0, 0.05,
				Color3.fromRGB(200, 210, 220), 8, 3.0
			)
		end
	end

	-- Gurney (tipped over, corrupted)
	local gurneyPos = position + Vector3.new(3, 1, 1)
	local gurneyFrame = createPart(
		model, "CorruptGurney_Frame",
		gurneyPos,
		Vector3.new(3, 0.3, 7),
		COLOR_CORRUPT_METAL, 0, Enum.Material.Metal
	)
	gurneyFrame.Orientation = Vector3.new(0, rotation + 15, 35) -- toppled

	-- Organic growth where hospital meets stone
	for i = 1, 4 do
		local veinPos = position + Vector3.new(
			corridorLength / 2 - 1 + math.random() * 2,
			math.random() * corridorHeight,
			-corridorWidth / 2 + math.random() * corridorWidth
		)
		Shared.createVein(
			veinPos, 2 + math.random() * 3, 0.1,
			Vector3.new(math.random(-30, 30), math.random(-180, 180), 90),
			model, `HospitalVein_{i}`
		)
	end

	-- Stone encroachment (raw rock eating into the corridor)
	createPart(
		model, "StoneEncroach_1",
		position + Vector3.new(corridorLength / 2 + 1, corridorHeight / 2, 0),
		Vector3.new(3, corridorHeight + 2, corridorWidth + 2),
		Shared.COLOR_STONE, 0, Enum.Material.Slate
	)
	createPart(
		model, "StoneEncroach_2",
		position + Vector3.new(-corridorLength / 2 - 0.5, corridorHeight * 0.4, 1),
		Vector3.new(2, corridorHeight * 0.8, corridorWidth * 0.6),
		Shared.COLOR_STONE_DARK, 0, Enum.Material.Slate
	)

	-- Blood stain on floor
	createPart(
		model, "CorruptBloodStain",
		position + Vector3.new(-2, 0.05, -1),
		Vector3.new(3, 0.05, 2.5),
		Color3.fromRGB(60, 15, 10), 0.3, Enum.Material.Concrete
	)

	-- Loot (sometimes)
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = gurneyPos + Vector3.new(0, 1, 0),
		chance = 0.3,
		guaranteed = false,
	})

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Echo Fragment: Subway Platform Fragment
------------------------------------------------------------------------

local function buildSubwayEcho(
	position: Vector3,
	parent: Instance,
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
): Model
	local model = Instance.new("Model")
	model.Name = "Echo_Subway"

	local platformLength = 12
	local platformWidth = 4
	local platformHeight = 1.5

	-- Platform slab (emerging from stone wall at impossible angle)
	local platform = createPart(
		model, "SubwayPlatform",
		position + Vector3.new(0, platformHeight / 2, 0),
		Vector3.new(platformLength, platformHeight, platformWidth),
		COLOR_CORRUPT_TILE, 0, Enum.Material.Marble
	)
	platform.Orientation = Vector3.new(-8, 12, 0)

	-- Rail tracks (bent, rusted, partially submerged in stone)
	for _, railOffset in { -1.5, 1.5 } do
		local rail = createPart(
			model, `SubwayRail_{railOffset}`,
			position + Vector3.new(0, 0.2, platformWidth / 2 + railOffset + 1),
			Vector3.new(platformLength + 2, 0.3, 0.3),
			COLOR_SUBWAY_RUST, 0, Enum.Material.Metal
		)
		rail.Orientation = Vector3.new(0, 15, 0)
	end

	-- Rail ties
	for i = 1, 5 do
		createPart(
			model, `RailTie_{i}`,
			position + Vector3.new(-platformLength / 2 + i * 2.5, 0.1, platformWidth / 2 + 2),
			Vector3.new(0.5, 0.2, 4),
			COLOR_CORRUPT_WOOD, 0, Enum.Material.Wood
		)
	end

	-- Subway tile wall fragment
	local tileWall = createPart(
		model, "SubwayTileWall",
		position + Vector3.new(-3, 3, -platformWidth / 2 - 0.5),
		Vector3.new(8, 5, 0.5),
		COLOR_CORRUPT_TILE, 0, Enum.Material.Marble
	)
	tileWall.Orientation = Vector3.new(0, 8, -5)

	-- Corrupted subway sign (illegible)
	createPart(
		model, "CorruptSign",
		position + Vector3.new(0, 4, -platformWidth / 2 - 0.3),
		Vector3.new(4, 1, 0.2),
		Color3.fromRGB(30, 50, 70), 0, Enum.Material.Metal
	)

	-- Organic tendrils growing over the platform
	for i = 1, 5 do
		Shared.createVein(
			position + Vector3.new(
				-platformLength / 2 + math.random() * platformLength,
				platformHeight + math.random() * 2,
				-platformWidth / 2 + math.random() * platformWidth
			),
			3 + math.random() * 2, 0.12,
			Vector3.new(math.random(-45, 45), math.random(-90, 90), 90),
			model, `SubwayVein_{i}`
		)
	end

	-- Stone consuming the edges
	createPart(
		model, "StoneEncroach_Subway",
		position + Vector3.new(platformLength / 2 + 2, 2, 0),
		Vector3.new(4, 6, platformWidth + 4),
		Shared.COLOR_STONE, 0, Enum.Material.Slate
	)

	table.insert(lootPositions, {
		itemType = "Battery",
		position = position + Vector3.new(2, platformHeight + 1, 0),
		chance = 0.3,
		guaranteed = false,
	})

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Echo Fragment: Research Station Panel Fragment
------------------------------------------------------------------------

local function buildLabEcho(
	position: Vector3,
	parent: Instance,
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
): Model
	local model = Instance.new("Model")
	model.Name = "Echo_Lab"

	-- Metal wall panel (Blackpoint research station aesthetic)
	local panel = createPart(
		model, "LabPanel",
		position + Vector3.new(0, 3, 0),
		Vector3.new(6, 5, 0.5),
		COLOR_LAB_PANEL, 0, Enum.Material.DiamondPlate
	)
	panel.Orientation = Vector3.new(-5, -8, 3)

	-- Dead monitor
	local monitor = createPart(
		model, "DeadMonitor",
		position + Vector3.new(-1.5, 3.5, 0.5),
		Vector3.new(2, 1.5, 0.3),
		Color3.fromRGB(15, 15, 20), 0, Enum.Material.Glass
	)

	-- Desk fragment (half-consumed by stone)
	createPart(
		model, "LabDesk_Fragment",
		position + Vector3.new(0, 1.5, 1.5),
		Vector3.new(4, 0.5, 2),
		COLOR_CORRUPT_METAL, 0, Enum.Material.Metal
	).Orientation = Vector3.new(0, -8, -10)

	-- Pipes (research station ductwork, bent and fused)
	for i = 1, 3 do
		Shared.createPipe(
			position + Vector3.new(-2 + i * 1.5, 5, -0.5),
			4, 0.15,
			Vector3.new(0, 10 + i * 5, 90),
			model, `LabPipe_{i}`
		)
	end

	-- Flesh growing through panel seams
	for i = 1, 3 do
		Shared.createFleshWall(
			position + Vector3.new(-2 + i * 2, 2 + i * 0.5, 0.2),
			Vector3.new(0.8, 0.5, 0.3),
			model, `PanelFlesh_{i}`
		)
	end

	-- Corrupted clipboard (lore prop)
	createPart(
		model, "CorruptClipboard",
		position + Vector3.new(1, 2, 1.5),
		Vector3.new(0.8, 0.05, 1.2),
		Color3.fromRGB(160, 150, 130), 0, Enum.Material.SmoothPlastic
	)

	table.insert(lootPositions, {
		itemType = "Battery",
		position = position + Vector3.new(1, 2.2, 1.5),
		chance = 0.4,
		guaranteed = false,
	})

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Echo Fragment: Forest / Bark Fragment
------------------------------------------------------------------------

local function buildForestEcho(
	position: Vector3,
	parent: Instance
): Model
	local model = Instance.new("Model")
	model.Name = "Echo_Forest"

	-- Dead tree trunk growing from stone floor
	local trunk = createPart(
		model, "DeadTrunk",
		position + Vector3.new(0, 3, 0),
		Vector3.new(1.5, 6, 1.5),
		COLOR_FOREST_BARK, 0, Enum.Material.Wood
	)
	trunk.Orientation = Vector3.new(-10, 0, 5) -- leaning

	-- Branches (reaching into ceiling/walls)
	for i = 1, 4 do
		local branchAngle = i * 90
		local branchLen = 2 + math.random() * 2
		createPart(
			model, `DeadBranch_{i}`,
			position + Vector3.new(
				math.cos(math.rad(branchAngle)) * 1.5,
				3 + i * 0.8,
				math.sin(math.rad(branchAngle)) * 1.5
			),
			Vector3.new(branchLen, 0.3, 0.3),
			COLOR_FOREST_BARK, 0, Enum.Material.Wood
		).Orientation = Vector3.new(
			-20 + math.random(-10, 10),
			branchAngle,
			0
		)
	end

	-- Roots (spreading across floor, fusing with stone)
	for i = 1, 5 do
		local rootAngle = (i / 5) * math.pi * 2
		local rootLen = 2 + math.random() * 2
		Shared.createVein(
			position + Vector3.new(
				math.cos(rootAngle) * rootLen / 2,
				0.1,
				math.sin(rootAngle) * rootLen / 2
			),
			rootLen, 0.15,
			Vector3.new(0, math.deg(rootAngle), 90),
			model, `Root_{i}`
		).Color = COLOR_FOREST_BARK
	end

	-- Leaves (dead, scattered, wrong — they shouldn't be underground)
	for i = 1, 6 do
		createPart(
			model, `DeadLeaf_{i}`,
			position + Vector3.new(
				math.random(-3, 3),
				0.05,
				math.random(-3, 3)
			),
			Vector3.new(0.4, 0.02, 0.3),
			Color3.fromRGB(50, 30, 20), 0.3, Enum.Material.Fabric
		)
	end

	-- Moss/lichen on surrounding stone
	for i = 1, 3 do
		createPart(
			model, `Moss_{i}`,
			position + Vector3.new(math.random(-2, 2), 0.5 + i * 0.5, math.random(-2, 2)),
			Vector3.new(1.5, 0.5, 1.5),
			Color3.fromRGB(30, 50, 25), 0.4, Enum.Material.Grass
		)
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Place all echo fragments throughout the level
------------------------------------------------------------------------

local function placeAllEchoes(
	parent: Instance,
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local echoes = Instance.new("Model")
	echoes.Name = "EchoFragments"

	-- Hospital echoes (scattered near Warren entry and corridor transitions)
	buildHospitalEcho(
		Vector3.new(45, WARREN_Y + 2, -130),
		echoes, 15, lootPositions
	)
	buildHospitalEcho(
		Vector3.new(15, WARREN_Y - 3, -180),
		echoes, -25, lootPositions
	)

	-- Subway echo (embedded in Warren mid-section wall)
	buildSubwayEcho(
		Vector3.new(55, WARREN_Y + 1, -160),
		echoes, lootPositions
	)

	-- Lab echo (near transition to Sanctuary)
	buildLabEcho(
		Vector3.new(20, WARREN_Y - 5, -220),
		echoes, lootPositions
	)
	buildLabEcho(
		Vector3.new(50, SANCTUARY_Y + 3, -280),
		echoes, lootPositions
	)

	-- Forest echoes (organic growth breaking through in Sanctuary approach)
	buildForestEcho(
		Vector3.new(40, SANCTUARY_Y + 1, -260),
		echoes
	)
	buildForestEcho(
		Vector3.new(20, SANCTUARY_Y + 1, -290),
		echoes
	)
	buildForestEcho(
		Vector3.new(35, WARREN_Y, -200),
		echoes
	)

	-- Additional corrupted fragments (scattered detail pieces)
	-- Corrupted hospital door frame hanging in mid-air
	Shared.createCorruptedFragment(
		Vector3.new(38, WARREN_Y + 4, -145),
		Vector3.new(5, 8, 0.5),
		echoes, "hospital_wall", "FloatingDoorFrame"
	)

	-- Subway rail section protruding from stone
	Shared.createCorruptedFragment(
		Vector3.new(28, WARREN_Y + 1, -170),
		Vector3.new(8, 0.3, 0.3),
		echoes, "subway_rail", "ProtrudingRail"
	)

	-- Lab panel fused with organic tissue
	Shared.createCorruptedFragment(
		Vector3.new(42, SANCTUARY_Y + 2, -270),
		Vector3.new(3, 4, 0.5),
		echoes, "lab_panel", "FusedLabPanel"
	)

	-- Forest bark wall section
	Shared.createCorruptedFragment(
		Vector3.new(25, WARREN_Y + 2, -190),
		Vector3.new(1.5, 5, 3),
		echoes, "forest_bark", "BarkWallSection"
	)

	-- Hospital floor tile floating at wrong angle
	Shared.createCorruptedFragment(
		Vector3.new(32, WARREN_Y + 6, -155),
		Vector3.new(4, 0.3, 4),
		echoes, "hospital_floor", "FloatingTile"
	)

	echoes.Parent = parent
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local Echoes = {}

function Echoes.build(parent: Instance): FloorData
	local model = Instance.new("Model")
	model.Name = "Echoes"
	model.Parent = parent

	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	placeAllEchoes(model, lootPositions)

	print(`[TheOrigin/Echoes] Built: {#hidingSpots} hiding spots, {#waypoints} waypoints, {#lootPositions} loot positions`)

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return Echoes
