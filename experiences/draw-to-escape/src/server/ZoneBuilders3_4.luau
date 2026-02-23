--!strict

--[[
	ZoneBuilders3_4
	Stage geometry builders for Zone 3 (The Crayon Caverns, stages 11-15)
	and Zone 4 (The Watercolor Wetlands, stages 16-20).

	Each builder function creates the obstacle geometry for a specific stage.
	Called by WorldBuilder after creating the standard start/end platforms.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneThemes = require(ReplicatedStorage.Shared.ZoneThemes)

local ZoneBuilders = {}

-- Helper to create a themed part with standard properties
local function createPart(
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = true
	part.Material = material
	part.Color = color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Helper to add a BoolValue tag to a part
local function addBoolTag(parent: Instance, name: string, value: boolean)
	local tag = Instance.new("BoolValue")
	tag.Name = name
	tag.Value = value
	tag.Parent = parent
end

-- Helper to add a Vector3Value to a part
local function addVector3Value(parent: Instance, name: string, value: Vector3)
	local v = Instance.new("Vector3Value")
	v.Name = name
	v.Value = value
	v.Parent = parent
end

-- Helper to add a NumberValue to a part
local function addNumberValue(parent: Instance, name: string, value: number)
	local n = Instance.new("NumberValue")
	n.Name = name
	n.Value = value
	n.Parent = parent
end

-- Helper to create a kill zone part (invisible, non-collidable)
local function createKillPart(name: string, size: Vector3, position: Vector3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	addBoolTag(part, "IsKillZone", true)

	return part
end

-- Helper to create a neon crystal decoration
local function createCrystal(
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	parent: Instance,
	transparency: number?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = true
	part.Material = Enum.Material.Neon
	part.Color = color
	part.Transparency = transparency or 0
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- ================================================================
-- ZONE 3: THE CRAYON CAVERNS (Stages 11-15)
-- Dark underground caverns lit by dim neon crayon crystals.
-- ================================================================

--[[
	Stage 11: "The Darkness"
	Total darkness. No lighting at all. Hidden pit kill zones.
	The player needs to draw a glowing light source (neon material)
	to reveal the path and avoid the pits.
]]
local function buildStage_TheDarkness(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Main cavern floor: a winding path with strategic gaps (pits)
	-- Left section of floor
	createPart(
		"Floor_Left1",
		Vector3.new(10, 2, 30),
		Vector3.new(-5, 0, baseZ + 20),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Central corridor floor
	createPart(
		"Floor_Center1",
		Vector3.new(12, 2, 15),
		Vector3.new(0, 0, baseZ + 40),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Right section of floor continuing forward
	createPart(
		"Floor_Right1",
		Vector3.new(10, 2, 20),
		Vector3.new(5, 0, baseZ + 58),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Final stretch of floor before end
	createPart(
		"Floor_Final",
		Vector3.new(16, 2, 25),
		Vector3.new(0, 0, baseZ + 80),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Hidden pit kill zones in the gaps between floor sections
	-- Pit 1: between left and center sections
	createKillPart("PitKill_1", Vector3.new(14, 4, 8), Vector3.new(5, -3, baseZ + 33), stageModel)

	-- Pit 2: off to the side of center corridor (false path)
	createKillPart("PitKill_2", Vector3.new(10, 4, 15), Vector3.new(-8, -3, baseZ + 45), stageModel)

	-- Pit 3: between right section and final stretch
	createKillPart("PitKill_3", Vector3.new(12, 4, 8), Vector3.new(-3, -3, baseZ + 68), stageModel)

	-- Pit 4: sneaky pit right before the end platform
	createKillPart("PitKill_4", Vector3.new(8, 4, 6), Vector3.new(6, -3, baseZ + 90), stageModel)

	-- Cavern walls (enclosing the space, making it feel underground)
	createPart(
		"CavernWallL",
		Vector3.new(3, 20, 90),
		Vector3.new(-18, 10, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"CavernWallR",
		Vector3.new(3, 20, 90),
		Vector3.new(18, 10, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Low ceiling to make it feel claustrophobic
	createPart(
		"CavernCeiling",
		Vector3.new(36, 3, 90),
		Vector3.new(0, 22, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Dim neon crystal decorations on walls (barely visible)
	-- Left wall crystals
	local crystalColors = {
		Color3.fromRGB(80, 20, 120), -- dim purple
		Color3.fromRGB(20, 60, 80), -- dim teal
		Color3.fromRGB(80, 20, 40), -- dim crimson
		Color3.fromRGB(40, 60, 20), -- dim green
		Color3.fromRGB(60, 30, 80), -- dim violet
	}

	createCrystal(
		"Crystal_L1",
		Vector3.new(1.5, 4, 1.5),
		Vector3.new(-16, 6, baseZ + 25),
		crystalColors[1],
		stageModel,
		0.6
	)
	createCrystal(
		"Crystal_L2",
		Vector3.new(1, 3, 1),
		Vector3.new(-16, 8, baseZ + 45),
		crystalColors[2],
		stageModel,
		0.7
	)
	createCrystal(
		"Crystal_L3",
		Vector3.new(2, 5, 1.5),
		Vector3.new(-16, 5, baseZ + 70),
		crystalColors[3],
		stageModel,
		0.6
	)

	-- Right wall crystals
	createCrystal(
		"Crystal_R1",
		Vector3.new(1, 3.5, 1),
		Vector3.new(16, 7, baseZ + 30),
		crystalColors[4],
		stageModel,
		0.7
	)
	createCrystal(
		"Crystal_R2",
		Vector3.new(1.5, 4.5, 1.5),
		Vector3.new(16, 5, baseZ + 55),
		crystalColors[5],
		stageModel,
		0.6
	)
	createCrystal(
		"Crystal_R3",
		Vector3.new(1, 3, 1.5),
		Vector3.new(16, 9, baseZ + 80),
		crystalColors[1],
		stageModel,
		0.7
	)

	-- Floor crystals (very dim, some near pits as subtle warnings)
	createCrystal(
		"Crystal_Floor1",
		Vector3.new(1, 2, 1),
		Vector3.new(-1, 2, baseZ + 31),
		crystalColors[3],
		stageModel,
		0.8
	)
	createCrystal(
		"Crystal_Floor2",
		Vector3.new(0.8, 1.5, 0.8),
		Vector3.new(3, 2, baseZ + 66),
		crystalColors[5],
		stageModel,
		0.8
	)
end

--[[
	Stage 12: "The Pit"
	Floor with a large deep pit in the middle (20 stud gap).
	A hidden semi-transparent platform below activates when weight
	is placed on it (pressure plate mechanic).
]]
local function buildStage_ThePit(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Approach floor
	createPart(
		"Floor_Approach",
		Vector3.new(24, 2, 30),
		Vector3.new(0, 0, baseZ + 20),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Far side floor (after the pit)
	createPart(
		"Floor_FarSide",
		Vector3.new(24, 2, 30),
		Vector3.new(0, 0, baseZ + 75),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- The pit walls: left and right sides descending
	createPart(
		"PitWallL",
		Vector3.new(3, 30, 25),
		Vector3.new(-13, -14, baseZ + 48),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"PitWallR",
		Vector3.new(3, 30, 25),
		Vector3.new(13, -14, baseZ + 48),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Pit bottom (kill zone for falling too deep)
	createKillPart("PitBottom", Vector3.new(24, 2, 25), Vector3.new(0, -30, baseZ + 48), stageModel)

	-- Hidden platform inside the pit (semi-transparent, acts as pressure plate)
	local hiddenPlatform = createPart(
		"HiddenPlatform",
		Vector3.new(16, 2, 16),
		Vector3.new(0, -10, baseZ + 48),
		Color3.fromRGB(100, 60, 140),
		Enum.Material.Neon,
		stageModel
	)
	hiddenPlatform.Transparency = 0.8

	addBoolTag(hiddenPlatform, "IsPressurePlate", true)
	addNumberValue(hiddenPlatform, "RequiredWeight", 30)

	-- Decorative ledges inside the pit (small footholds, unreliable)
	createPart(
		"PitLedge_L1",
		Vector3.new(3, 1, 4),
		Vector3.new(-10, -5, baseZ + 43),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"PitLedge_R1",
		Vector3.new(3, 1, 4),
		Vector3.new(10, -8, baseZ + 52),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Neon crystal accents around the pit rim
	createCrystal(
		"PitCrystal_1",
		Vector3.new(1.5, 3, 1.5),
		Vector3.new(-8, 2, baseZ + 36),
		Color3.fromRGB(180, 40, 255),
		stageModel
	)
	createCrystal(
		"PitCrystal_2",
		Vector3.new(1, 2.5, 1),
		Vector3.new(9, 2, baseZ + 38),
		Color3.fromRGB(40, 200, 255),
		stageModel
	)
	createCrystal(
		"PitCrystal_3",
		Vector3.new(2, 4, 1.5),
		Vector3.new(-6, 2, baseZ + 58),
		Color3.fromRGB(255, 60, 180),
		stageModel
	)
	createCrystal(
		"PitCrystal_4",
		Vector3.new(1.5, 3.5, 1),
		Vector3.new(7, 2, baseZ + 60),
		Color3.fromRGB(60, 255, 120),
		stageModel
	)

	-- Cavern ceiling above the pit
	createPart(
		"CeilingAbovePit",
		Vector3.new(30, 3, 30),
		Vector3.new(0, 22, baseZ + 48),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- A gate on the far side that opens when the pressure plate is activated
	local gate = createPart(
		"Gate",
		Vector3.new(20, 12, 3),
		Vector3.new(0, 6, baseZ + 62),
		Color3.fromRGB(120, 40, 60),
		theme.WallMaterial,
		stageModel
	)
	addBoolTag(gate, "IsGate", true)
end

--[[
	Stage 13: "The Stalactite Gauntlet"
	Long corridor (80 studs) with continuous floor. Ceiling has
	stalactite-like parts hanging down as hazard markers. The
	player must run through and potentially draw overhead cover.
]]
local function buildStage_TheStalactiteGauntlet(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Long continuous corridor floor
	createPart(
		"CorridorFloor",
		Vector3.new(16, 2, 80),
		Vector3.new(0, 0, baseZ + 50),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Corridor walls
	createPart(
		"CorridorWallL",
		Vector3.new(3, 22, 80),
		Vector3.new(-10, 11, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"CorridorWallR",
		Vector3.new(3, 22, 80),
		Vector3.new(10, 11, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- High ceiling
	createPart(
		"CorridorCeiling",
		Vector3.new(20, 3, 80),
		Vector3.new(0, 23, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Stalactites hanging from the ceiling at varying heights
	-- These are long thin parts pointing downward, spaced along the corridor
	local stalactiteData = {
		-- { xOffset, hangLength, zOffset, widthX, widthZ }
		{ -4, 8, 15, 2, 2 },
		{ 3, 10, 20, 1.5, 1.5 },
		{ -2, 12, 26, 2.5, 2 },
		{ 5, 7, 32, 1.5, 1.5 },
		{ -6, 9, 37, 2, 1.5 },
		{ 1, 14, 42, 3, 2.5 },
		{ -3, 11, 48, 2, 2 },
		{ 4, 8, 53, 1.5, 1.5 },
		{ -5, 13, 58, 2.5, 2 },
		{ 2, 10, 63, 2, 1.5 },
		{ -1, 15, 68, 3, 2.5 },
		{ 6, 9, 73, 2, 2 },
		{ -4, 11, 78, 2, 1.5 },
		{ 0, 16, 83, 3, 3 },
		{ 3, 7, 88, 1.5, 1.5 },
	}

	local stalactiteColors = {
		Color3.fromRGB(60, 50, 75),
		Color3.fromRGB(50, 45, 65),
		Color3.fromRGB(70, 55, 80),
		Color3.fromRGB(55, 50, 70),
	}

	for i, data in stalactiteData do
		local xOff = data[1]
		local hangLen = data[2]
		local zOff = data[3]
		local wX = data[4]
		local wZ = data[5]

		-- Stalactite hangs from ceiling (Y=23) downward
		local stalY = 23 - hangLen / 2
		local stalColor = stalactiteColors[((i - 1) % #stalactiteColors) + 1]

		createPart(
			`Stalactite_{i}`,
			Vector3.new(wX, hangLen, wZ),
			Vector3.new(xOff, stalY, baseZ + zOff),
			stalColor,
			theme.WallMaterial,
			stageModel
		)

		-- Add a small neon crystal tip at the bottom of some stalactites
		if i % 3 == 0 then
			createCrystal(
				`StalactiteTip_{i}`,
				Vector3.new(wX * 0.5, 2, wZ * 0.5),
				Vector3.new(xOff, 23 - hangLen - 1, baseZ + zOff),
				theme.AccentColor,
				stageModel,
				0.3
			)
		end
	end

	-- Neon crystal clusters on the walls for atmosphere
	createCrystal(
		"WallCrystalL_1",
		Vector3.new(1.5, 3, 1.5),
		Vector3.new(-8, 4, baseZ + 25),
		Color3.fromRGB(255, 50, 200),
		stageModel,
		0.2
	)
	createCrystal(
		"WallCrystalR_1",
		Vector3.new(1, 4, 1),
		Vector3.new(8, 5, baseZ + 45),
		Color3.fromRGB(50, 200, 255),
		stageModel,
		0.2
	)
	createCrystal(
		"WallCrystalL_2",
		Vector3.new(2, 3.5, 1.5),
		Vector3.new(-8, 3, baseZ + 65),
		Color3.fromRGB(120, 255, 50),
		stageModel,
		0.2
	)
	createCrystal(
		"WallCrystalR_2",
		Vector3.new(1.5, 2.5, 1),
		Vector3.new(8, 6, baseZ + 80),
		Color3.fromRGB(255, 120, 50),
		stageModel,
		0.2
	)
end

--[[
	Stage 14: "The Boulder Chase"
	A long downhill ramp floor (tilted slightly). At the start end,
	a large sphere boulder (anchored initially). Path has side walls.
	End has a safe alcove off to the side.
]]
local function buildStage_TheBoulderChase(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Downhill ramp: use a WedgePart-like approach with angled Part
	-- We approximate the ramp with a long floor part rotated slightly
	-- Main ramp floor (long, tilted down from start toward end)
	local rampLength = 80
	local rampDrop = 8 -- drops 8 studs over 80 studs
	local rampMidY = -rampDrop / 2

	local rampFloor = createPart(
		"RampFloor",
		Vector3.new(18, 2, rampLength),
		Vector3.new(0, rampMidY, baseZ + 50),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	-- Tilt the ramp: front (start) is higher, back (end) is lower
	rampFloor.CFrame = CFrame.new(0, rampMidY, baseZ + 50)
		* CFrame.Angles(math.rad(math.atan(rampDrop / rampLength) * (180 / math.pi)), 0, 0)

	-- Side walls along the ramp to prevent easy escape
	createPart(
		"RampWallL",
		Vector3.new(3, 14, rampLength),
		Vector3.new(-11, 5 + rampMidY, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"RampWallR",
		Vector3.new(3, 14, rampLength),
		Vector3.new(11, 5 + rampMidY, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- The Boulder: large sphere at the start end of the ramp
	local boulder = Instance.new("Part")
	boulder.Name = "Boulder"
	boulder.Shape = Enum.PartType.Ball
	boulder.Size = Vector3.new(10, 10, 10)
	boulder.Position = Vector3.new(0, 7, baseZ + 15)
	boulder.Anchored = true
	boulder.CanCollide = true
	boulder.Material = Enum.Material.Slate
	boulder.Color = Color3.fromRGB(80, 70, 90)
	boulder.TopSurface = Enum.SurfaceType.Smooth
	boulder.BottomSurface = Enum.SurfaceType.Smooth
	boulder.Parent = stageModel

	addBoolTag(boulder, "IsBoulder", true)
	addNumberValue(boulder, "RollSpeed", 40)

	-- Safe alcove at the end (cut into the right wall)
	-- Player dives into this pocket to avoid the rolling boulder
	createPart(
		"AlcoveFloor",
		Vector3.new(10, 2, 10),
		Vector3.new(16, -rampDrop - 1, baseZ + 85),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	createPart(
		"AlcoveWallBack",
		Vector3.new(10, 12, 3),
		Vector3.new(16, 5 - rampDrop, baseZ + 91),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"AlcoveWallSide",
		Vector3.new(3, 12, 10),
		Vector3.new(22, 5 - rampDrop, baseZ + 85),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"AlcoveCeiling",
		Vector3.new(10, 2, 10),
		Vector3.new(16, 12 - rampDrop, baseZ + 85),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Obstacles along the ramp: rocks and debris to dodge around
	createPart(
		"Debris_1",
		Vector3.new(3, 3, 3),
		Vector3.new(-5, 1, baseZ + 35),
		Color3.fromRGB(65, 55, 70),
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"Debris_2",
		Vector3.new(4, 2, 4),
		Vector3.new(4, -1, baseZ + 50),
		Color3.fromRGB(55, 50, 65),
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"Debris_3",
		Vector3.new(3, 4, 2),
		Vector3.new(-3, -3, baseZ + 65),
		Color3.fromRGB(70, 60, 80),
		theme.WallMaterial,
		stageModel
	)

	-- Neon crystal warning lights near the boulder
	createCrystal(
		"WarningCrystal_1",
		Vector3.new(1, 3, 1),
		Vector3.new(-9, 4, baseZ + 18),
		Color3.fromRGB(255, 40, 40),
		stageModel,
		0.1
	)
	createCrystal(
		"WarningCrystal_2",
		Vector3.new(1, 3, 1),
		Vector3.new(9, 4, baseZ + 18),
		Color3.fromRGB(255, 40, 40),
		stageModel,
		0.1
	)

	-- Ceiling over the ramp
	createPart(
		"RampCeiling",
		Vector3.new(24, 3, rampLength),
		Vector3.new(0, 20, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
end

--[[
	Stage 15: "The Squeeze"
	Continuous floor with a thick wall blocking the path.
	A tiny gap at the bottom (2x2 studs). On the other side:
	a pressure plate and a gate further ahead.
]]
local function buildStage_TheSqueeze(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Full continuous floor
	createPart(
		"Floor",
		Vector3.new(24, 2, 90),
		Vector3.new(0, 0, baseZ + 50),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- The thick blocking wall with a tiny gap at the bottom
	-- Wall is built in sections to leave a 2x2 gap at the bottom center

	-- Left section of wall (from left edge to gap)
	createPart(
		"SqueezeWall_Left",
		Vector3.new(9, 18, 6),
		Vector3.new(-7.5, 9, baseZ + 45),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Right section of wall (from gap to right edge)
	createPart(
		"SqueezeWall_Right",
		Vector3.new(9, 18, 6),
		Vector3.new(7.5, 9, baseZ + 45),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Top section above the gap (bridges left and right sections)
	createPart(
		"SqueezeWall_Top",
		Vector3.new(6, 16, 6),
		Vector3.new(0, 10, baseZ + 45),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- The gap is at X=0, Y=1..3 (2 studs tall above floor), Z=baseZ+45
	-- The "SqueezeWall_Top" starts at Y=2 (bottom edge), leaving a 2-stud gap
	-- Recalculate: floor top is at Y=1, gap goes from Y=1 to Y=3 (2 studs)
	-- We need the wall sections around the gap:

	-- Additional wall piece above the gap: fills from Y=3 upward
	-- (Already covered by SqueezeWall_Top which is 16 tall centered at Y=10, so Y range 2..18)
	-- Adjust: make gap exactly 2 wide (X) and 2 tall (Y)

	-- Pressure plate on the far side of the wall
	local plate = createPart(
		"PressurePlate",
		Vector3.new(6, 0.5, 6),
		Vector3.new(0, 1.25, baseZ + 58),
		Color3.fromRGB(255, 80, 80),
		Enum.Material.Neon,
		stageModel
	)
	addBoolTag(plate, "IsPressurePlate", true)
	addNumberValue(plate, "RequiredWeight", 20)

	-- Visual indicator: glowing ring around the pressure plate
	createCrystal(
		"PlateGlow_1",
		Vector3.new(0.5, 0.3, 6),
		Vector3.new(-3.25, 1.15, baseZ + 58),
		Color3.fromRGB(255, 120, 120),
		stageModel,
		0.3
	)
	createCrystal(
		"PlateGlow_2",
		Vector3.new(0.5, 0.3, 6),
		Vector3.new(3.25, 1.15, baseZ + 58),
		Color3.fromRGB(255, 120, 120),
		stageModel,
		0.3
	)

	-- Gate further ahead (blocks passage until pressure plate pressed)
	local gate = createPart(
		"Gate",
		Vector3.new(24, 16, 3),
		Vector3.new(0, 8, baseZ + 72),
		Color3.fromRGB(150, 50, 50),
		theme.WallMaterial,
		stageModel
	)
	addBoolTag(gate, "IsGate", true)

	-- Neon crystal decorations on the squeeze wall
	createCrystal(
		"WallCrystal_1",
		Vector3.new(2, 5, 1),
		Vector3.new(-4, 14, baseZ + 42),
		Color3.fromRGB(200, 50, 255),
		stageModel,
		0.1
	)
	createCrystal(
		"WallCrystal_2",
		Vector3.new(1.5, 4, 1),
		Vector3.new(5, 12, baseZ + 48),
		Color3.fromRGB(50, 180, 255),
		stageModel,
		0.1
	)

	-- Hint markers: small arrows on the floor pointing toward the gap
	createCrystal(
		"GapHint_1",
		Vector3.new(1, 0.3, 2),
		Vector3.new(0, 1.15, baseZ + 40),
		Color3.fromRGB(255, 200, 50),
		stageModel,
		0.5
	)
	createCrystal(
		"GapHint_2",
		Vector3.new(1, 0.3, 1.5),
		Vector3.new(0, 1.15, baseZ + 38),
		Color3.fromRGB(255, 200, 50),
		stageModel,
		0.6
	)

	-- Side walls for the corridor
	createPart(
		"CorridorWallL",
		Vector3.new(3, 20, 90),
		Vector3.new(-14, 10, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"CorridorWallR",
		Vector3.new(3, 20, 90),
		Vector3.new(14, 10, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
end

-- ================================================================
-- ZONE 4: THE WATERCOLOR WETLANDS (Stages 16-20)
-- Soft, painted world with water everywhere. Everything feels
-- like a watercolor painting with soft edges and muted colors.
-- ================================================================

--[[
	Stage 16: "The Rapids"
	Two shores with a wide (30 stud) fast river between them.
	River is a Part with IsWater BoolValue, blue Glass material.
	Arrow-shaped parts show current flow direction.
]]
local function buildStage_TheRapids(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Near shore
	createPart(
		"Shore_Near",
		Vector3.new(24, 2, 25),
		Vector3.new(0, 0, baseZ + 18),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Far shore
	createPart(
		"Shore_Far",
		Vector3.new(24, 2, 25),
		Vector3.new(0, 0, baseZ + 78),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- River bed (lower section between shores, decorative)
	createPart(
		"RiverBed",
		Vector3.new(30, 2, 30),
		Vector3.new(0, -4, baseZ + 48),
		Color3.fromRGB(60, 80, 50),
		Enum.Material.Mud,
		stageModel
	)

	-- River water (wide, non-collidable, slightly transparent)
	local river = createPart(
		"River",
		Vector3.new(30, 4, 30),
		Vector3.new(0, -1, baseZ + 48),
		Color3.fromRGB(50, 130, 210),
		Enum.Material.Glass,
		stageModel
	)
	river.CanCollide = false
	river.Transparency = 0.3
	addBoolTag(river, "IsWater", true)

	-- Current direction: flows from left (+X) to right (-X) relative to the player
	addVector3Value(river, "CurrentForce", Vector3.new(60, 0, 0))

	-- Current arrow indicators showing flow direction
	-- Each arrow is made of two angled parts forming a chevron shape
	local arrowPositions = {
		{ z = baseZ + 38, y = 0 },
		{ z = baseZ + 45, y = -0.5 },
		{ z = baseZ + 52, y = 0 },
		{ z = baseZ + 58, y = -0.5 },
	}

	for i, pos in arrowPositions do
		-- Arrow shaft (pointing in the +X direction = current flow)
		local shaft = createPart(
			`CurrentArrow_{i}`,
			Vector3.new(6, 0.3, 1),
			Vector3.new(0, pos.y, pos.z),
			Color3.fromRGB(200, 230, 255),
			Enum.Material.Neon,
			stageModel
		)
		shaft.CanCollide = false
		shaft.Transparency = 0.4

		-- Arrow head (angled piece)
		local headTop = createPart(
			`CurrentArrowHead_{i}_A`,
			Vector3.new(3, 0.3, 0.5),
			Vector3.new(4, pos.y, pos.z - 1),
			Color3.fromRGB(200, 230, 255),
			Enum.Material.Neon,
			stageModel
		)
		headTop.CanCollide = false
		headTop.Transparency = 0.4
		headTop.CFrame = CFrame.new(4, pos.y, pos.z - 1) * CFrame.Angles(0, math.rad(30), 0)

		local headBot = createPart(
			`CurrentArrowHead_{i}_B`,
			Vector3.new(3, 0.3, 0.5),
			Vector3.new(4, pos.y, pos.z + 1),
			Color3.fromRGB(200, 230, 255),
			Enum.Material.Neon,
			stageModel
		)
		headBot.CanCollide = false
		headBot.Transparency = 0.4
		headBot.CFrame = CFrame.new(4, pos.y, pos.z + 1) * CFrame.Angles(0, math.rad(-30), 0)
	end

	-- Shore decorations: reeds and rocks
	-- Near shore rocks
	createPart(
		"ShoreRock_N1",
		Vector3.new(3, 2, 3),
		Vector3.new(-8, 1.5, baseZ + 28),
		Color3.fromRGB(90, 100, 80),
		Enum.Material.Rock,
		stageModel
	)
	createPart(
		"ShoreRock_N2",
		Vector3.new(2, 1.5, 2),
		Vector3.new(7, 1.25, baseZ + 26),
		Color3.fromRGB(85, 95, 75),
		Enum.Material.Rock,
		stageModel
	)

	-- Far shore rocks
	createPart(
		"ShoreRock_F1",
		Vector3.new(3, 2.5, 2),
		Vector3.new(-6, 1.75, baseZ + 68),
		Color3.fromRGB(95, 105, 85),
		Enum.Material.Rock,
		stageModel
	)
	createPart(
		"ShoreRock_F2",
		Vector3.new(2.5, 2, 3),
		Vector3.new(9, 1.5, baseZ + 70),
		Color3.fromRGB(80, 90, 70),
		Enum.Material.Rock,
		stageModel
	)

	-- Spray/mist effect markers near the rapids
	local mist1 = Instance.new("Part")
	mist1.Name = "MistZone_1"
	mist1.Size = Vector3.new(20, 6, 5)
	mist1.Position = Vector3.new(0, 3, baseZ + 34)
	mist1.Anchored = true
	mist1.CanCollide = false
	mist1.Transparency = 1
	mist1.Parent = stageModel

	local mist2 = Instance.new("Part")
	mist2.Name = "MistZone_2"
	mist2.Size = Vector3.new(20, 6, 5)
	mist2.Position = Vector3.new(0, 3, baseZ + 62)
	mist2.Anchored = true
	mist2.CanCollide = false
	mist2.Transparency = 1
	mist2.Parent = stageModel
end

--[[
	Stage 17: "The Rising Tide"
	An enclosed room (walls on all 4 sides + ceiling). Floor is low.
	A WaterLevel part (blue Glass, IsWater) starts at floor level.
	The exit is high up (15 studs) on one wall -- an opening.
	Player must draw platforms to climb as water rises.
]]
local function buildStage_TheRisingTide(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local roomWidth = 30
	local roomLength = 40
	local roomHeight = 22
	local roomCenterZ = baseZ + 50

	-- Room floor (slightly depressed to hold water)
	createPart(
		"RoomFloor",
		Vector3.new(roomWidth, 2, roomLength),
		Vector3.new(0, -2, roomCenterZ),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Room walls (4 sides)
	-- Left wall
	createPart(
		"RoomWallL",
		Vector3.new(3, roomHeight, roomLength),
		Vector3.new(-roomWidth / 2 - 1.5, roomHeight / 2 - 2, roomCenterZ),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	-- Right wall
	createPart(
		"RoomWallR",
		Vector3.new(3, roomHeight, roomLength),
		Vector3.new(roomWidth / 2 + 1.5, roomHeight / 2 - 2, roomCenterZ),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	-- Back wall (entrance side) - solid
	createPart(
		"RoomWallBack",
		Vector3.new(roomWidth + 6, roomHeight, 3),
		Vector3.new(0, roomHeight / 2 - 2, roomCenterZ - roomLength / 2 - 1.5),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	-- Front wall (exit side) - has opening high up
	-- Bottom section of front wall
	createPart(
		"RoomWallFront_Bottom",
		Vector3.new(roomWidth + 6, 13, 3),
		Vector3.new(0, 4.5, roomCenterZ + roomLength / 2 + 1.5),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	-- Left section of front wall (above exit opening)
	createPart(
		"RoomWallFront_Left",
		Vector3.new(10, 7, 3),
		Vector3.new(-10, 16.5, roomCenterZ + roomLength / 2 + 1.5),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	-- Right section of front wall (above exit opening)
	createPart(
		"RoomWallFront_Right",
		Vector3.new(10, 7, 3),
		Vector3.new(10, 16.5, roomCenterZ + roomLength / 2 + 1.5),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	-- Top piece above exit opening
	createPart(
		"RoomWallFront_Top",
		Vector3.new(10, 2, 3),
		Vector3.new(0, 19, roomCenterZ + roomLength / 2 + 1.5),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	-- Exit opening is at: X range -5..5, Y range 11..18, front wall Z

	-- Room ceiling
	createPart(
		"RoomCeiling",
		Vector3.new(roomWidth + 6, 3, roomLength + 6),
		Vector3.new(0, roomHeight - 0.5, roomCenterZ),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Water level part (starts at floor level, rises over time)
	local waterLevel = createPart(
		"WaterLevel",
		Vector3.new(roomWidth, 2, roomLength),
		Vector3.new(0, -1, roomCenterZ),
		Color3.fromRGB(60, 140, 220),
		Enum.Material.Glass,
		stageModel
	)
	waterLevel.CanCollide = false
	waterLevel.Transparency = 0.35
	addBoolTag(waterLevel, "IsWater", true)
	addNumberValue(waterLevel, "RiseSpeed", 1.5) -- studs per second

	-- Exit platform on the other side of the high exit
	createPart(
		"ExitLedge",
		Vector3.new(10, 2, 8),
		Vector3.new(0, 11, roomCenterZ + roomLength / 2 + 6),
		Color3.fromRGB(80, 180, 80),
		Enum.Material.Neon,
		stageModel
	)

	-- Interior decorations: pipes, grates, watermarks
	-- Rusty pipe on left wall
	createPart(
		"Pipe_L1",
		Vector3.new(2, 2, 8),
		Vector3.new(-13, 4, roomCenterZ - 8),
		Color3.fromRGB(100, 80, 60),
		Enum.Material.CorrodedMetal,
		stageModel
	)

	-- Small ledge on right wall (can be used early to climb)
	createPart(
		"WallLedge_R1",
		Vector3.new(4, 1, 6),
		Vector3.new(12, 5, roomCenterZ + 5),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Waterline stain markers on walls (visual indicator of max water height)
	local stain = createPart(
		"WaterStain",
		Vector3.new(roomWidth + 6, 0.3, 0.3),
		Vector3.new(0, 16, roomCenterZ - roomLength / 2 - 1),
		Color3.fromRGB(40, 100, 160),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	stain.CanCollide = false
	stain.Transparency = 0.5
end

--[[
	Stage 18: "The Whirlpool"
	Circular arena (approximated with multiple floor parts).
	Center has a WhirlpoolCenter part (non-collidable, with IsWhirlpool).
	Water surrounds the whirlpool. Exit on the far side.
]]
local function buildStage_TheWhirlpool(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local arenaCenter = Vector3.new(0, 0, baseZ + 50)
	local arenaRadius = 25

	-- Create circular floor using wedge-shaped segments
	-- Approximate a circle with 12 rectangular floor pieces arranged radially
	local segmentCount = 12
	for i = 0, segmentCount - 1 do
		local angle = (i / segmentCount) * math.pi * 2
		local nextAngle = ((i + 1) / segmentCount) * math.pi * 2
		local midAngle = (angle + nextAngle) / 2

		local dist = arenaRadius * 0.7
		local x = math.cos(midAngle) * dist
		local z = math.sin(midAngle) * dist

		local segWidth = arenaRadius * 0.5
		local segLength = arenaRadius * 0.45

		local seg = createPart(
			`ArenaFloor_{i + 1}`,
			Vector3.new(segWidth, 2, segLength),
			Vector3.new(arenaCenter.X + x, arenaCenter.Y, arenaCenter.Z + z),
			theme.GroundColor,
			theme.GroundMaterial,
			stageModel
		)
		seg.CFrame = CFrame.new(arenaCenter.X + x, arenaCenter.Y, arenaCenter.Z + z) * CFrame.Angles(0, -midAngle, 0)
	end

	-- Central whirlpool (non-collidable, visual marker + pull force)
	local whirlpool = Instance.new("Part")
	whirlpool.Name = "WhirlpoolCenter"
	whirlpool.Shape = Enum.PartType.Cylinder
	whirlpool.Size = Vector3.new(4, 12, 12) -- cylinder: Height along X, Radius via Y,Z
	whirlpool.CFrame = CFrame.new(arenaCenter.X, arenaCenter.Y - 1, arenaCenter.Z) * CFrame.Angles(0, 0, math.rad(90)) -- rotate to be vertical
	whirlpool.Anchored = true
	whirlpool.CanCollide = false
	whirlpool.Transparency = 0.5
	whirlpool.Material = Enum.Material.Glass
	whirlpool.Color = Color3.fromRGB(30, 80, 170)
	whirlpool.TopSurface = Enum.SurfaceType.Smooth
	whirlpool.BottomSurface = Enum.SurfaceType.Smooth
	whirlpool.Parent = stageModel

	addBoolTag(whirlpool, "IsWhirlpool", true)
	addNumberValue(whirlpool, "PullForce", 50)

	-- Kill zone at the center bottom of the whirlpool
	createKillPart("WhirlpoolDrain", Vector3.new(8, 4, 8), Vector3.new(arenaCenter.X, -6, arenaCenter.Z), stageModel)

	-- Water ring around the whirlpool
	-- Inner ring of water (around the whirlpool center, between center and floor)
	local waterRing = createPart(
		"WhirlpoolWater",
		Vector3.new(20, 3, 20),
		Vector3.new(arenaCenter.X, -1, arenaCenter.Z),
		Color3.fromRGB(50, 120, 200),
		Enum.Material.Glass,
		stageModel
	)
	waterRing.CanCollide = false
	waterRing.Transparency = 0.4
	addBoolTag(waterRing, "IsWater", true)

	-- Visual swirl indicators (concentric ring parts)
	for ring = 1, 3 do
		local ringRadius = 3 + ring * 3
		local ringParts = 8
		for j = 0, ringParts - 1 do
			local rAngle = (j / ringParts) * math.pi * 2 + ring * 0.3 -- offset each ring
			local rx = math.cos(rAngle) * ringRadius
			local rz = math.sin(rAngle) * ringRadius

			local swirlPart = createPart(
				`Swirl_{ring}_{j + 1}`,
				Vector3.new(2, 0.3, 0.5),
				Vector3.new(arenaCenter.X + rx, 0.2, arenaCenter.Z + rz),
				Color3.fromRGB(150, 200, 255),
				Enum.Material.Neon,
				stageModel
			)
			swirlPart.CanCollide = false
			swirlPart.Transparency = 0.3 + ring * 0.15
			swirlPart.CFrame = CFrame.new(arenaCenter.X + rx, 0.2, arenaCenter.Z + rz)
				* CFrame.Angles(0, -rAngle + math.rad(90), 0)
		end
	end

	-- Approach path from start platform to arena
	createPart(
		"ApproachPath",
		Vector3.new(10, 2, 15),
		Vector3.new(0, 0, baseZ + 18),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Exit path from arena to end platform (far side)
	createPart(
		"ExitPath",
		Vector3.new(10, 2, 15),
		Vector3.new(0, 0, baseZ + 82),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Arena boundary pillars (decorative, mark the edge)
	local pillarAngles = { 0, math.pi / 2, math.pi, math.pi * 3 / 2 }
	for i, pAngle in pillarAngles do
		local px = math.cos(pAngle) * (arenaRadius + 2)
		local pz = math.sin(pAngle) * (arenaRadius + 2)
		createPart(
			`ArenaPillar_{i}`,
			Vector3.new(3, 8, 3),
			Vector3.new(arenaCenter.X + px, 4, arenaCenter.Z + pz),
			theme.AccentColor,
			Enum.Material.SmoothPlastic,
			stageModel
		)
	end
end

--[[
	Stage 19: "The Ice Sheet"
	Flat floor made of Ice material. Walls around the edges.
	Finish platform on the far side. Obstacle pillars in the middle.
	Player slides around uncontrollably on the ice.
]]
local function buildStage_TheIceSheet(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Main ice floor (wide and long)
	local iceFloor = createPart(
		"IceFloor",
		Vector3.new(30, 2, 70),
		Vector3.new(0, 0, baseZ + 45),
		Color3.fromRGB(180, 220, 240),
		Enum.Material.Ice,
		stageModel
	)
	-- Set custom physical properties for extra slipperiness
	iceFloor.CustomPhysicalProperties = PhysicalProperties.new(
		0.9, -- density
		0.01, -- friction (very low)
		0.1, -- elasticity
		0.01, -- frictionWeight
		0.1 -- elasticityWeight
	)

	-- Perimeter walls to keep players on the ice
	-- Left wall
	createPart(
		"IceWallL",
		Vector3.new(3, 8, 70),
		Vector3.new(-16.5, 4, baseZ + 45),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	-- Right wall
	createPart(
		"IceWallR",
		Vector3.new(3, 8, 70),
		Vector3.new(16.5, 4, baseZ + 45),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	-- Back wall (near start)
	createPart(
		"IceWallBack",
		Vector3.new(36, 8, 3),
		Vector3.new(0, 4, baseZ + 11.5),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Obstacle pillars in the middle of the ice
	-- These create a slalom-like challenge on the slippery surface
	local pillarData = {
		-- { x, z_offset, width, depth, height }
		{ -8, 25, 3, 3, 8 },
		{ 6, 30, 4, 4, 10 },
		{ -3, 38, 3, 3, 7 },
		{ 10, 42, 3, 5, 9 },
		{ -10, 48, 4, 3, 8 },
		{ 2, 52, 5, 3, 11 },
		{ -6, 58, 3, 4, 7 },
		{ 8, 62, 3, 3, 9 },
		{ -1, 68, 4, 4, 10 },
	}

	for i, data in pillarData do
		local pillarColor: Color3
		if i % 3 == 0 then
			pillarColor = Color3.fromRGB(100, 140, 180)
		elseif i % 3 == 1 then
			pillarColor = Color3.fromRGB(120, 160, 200)
		else
			pillarColor = Color3.fromRGB(90, 130, 170)
		end

		createPart(
			`IcePillar_{i}`,
			Vector3.new(data[3], data[5], data[4]),
			Vector3.new(data[1], data[5] / 2, baseZ + data[2]),
			pillarColor,
			Enum.Material.Ice,
			stageModel
		)
	end

	-- Finish platform (warmer material, not ice -- safe landing)
	createPart(
		"FinishPlatform",
		Vector3.new(16, 2, 10),
		Vector3.new(0, 0, baseZ + 85),
		Color3.fromRGB(120, 180, 100),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Decorative frozen puddles (patches of slightly different colored ice)
	createPart(
		"FrozenPuddle_1",
		Vector3.new(6, 0.3, 6),
		Vector3.new(-7, 1.15, baseZ + 35),
		Color3.fromRGB(160, 200, 230),
		Enum.Material.Glass,
		stageModel
	)
	createPart(
		"FrozenPuddle_2",
		Vector3.new(5, 0.3, 8),
		Vector3.new(5, 1.15, baseZ + 55),
		Color3.fromRGB(170, 210, 235),
		Enum.Material.Glass,
		stageModel
	)

	-- Icicle decorations hanging from walls
	createPart(
		"Icicle_L1",
		Vector3.new(1, 4, 1),
		Vector3.new(-15, 6, baseZ + 30),
		Color3.fromRGB(200, 230, 245),
		Enum.Material.Ice,
		stageModel
	)
	createPart(
		"Icicle_L2",
		Vector3.new(0.8, 3, 0.8),
		Vector3.new(-15, 6.5, baseZ + 50),
		Color3.fromRGB(190, 225, 240),
		Enum.Material.Ice,
		stageModel
	)
	createPart(
		"Icicle_R1",
		Vector3.new(1, 3.5, 1),
		Vector3.new(15, 6.25, baseZ + 40),
		Color3.fromRGB(195, 228, 242),
		Enum.Material.Ice,
		stageModel
	)
	createPart(
		"Icicle_R2",
		Vector3.new(0.8, 4.5, 0.8),
		Vector3.new(15, 5.75, baseZ + 60),
		Color3.fromRGB(205, 232, 248),
		Enum.Material.Ice,
		stageModel
	)
end

--[[
	Stage 20: "The Waterfall Climb"
	Vertical stage. Start platform at the bottom. Series of small
	ledges going up a tall wall (30 studs). A WaterfallZone part
	covers the wall area (non-collidable, transparent, with downward
	WaterForce). End platform at the top.
]]
local function buildStage_TheWaterfallClimb(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local wallHeight = 30
	local wallCenterZ = baseZ + 50

	-- Bottom start platform (wide, solid)
	createPart(
		"BottomPlatform",
		Vector3.new(24, 2, 20),
		Vector3.new(0, 0, wallCenterZ - 5),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- The tall cliff wall (the surface being climbed)
	createPart(
		"CliffWall",
		Vector3.new(24, wallHeight, 3),
		Vector3.new(0, wallHeight / 2, wallCenterZ + 5),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Side walls to prevent going around
	createPart(
		"SideWallL",
		Vector3.new(3, wallHeight + 5, 25),
		Vector3.new(-13.5, wallHeight / 2, wallCenterZ),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"SideWallR",
		Vector3.new(3, wallHeight + 5, 25),
		Vector3.new(13.5, wallHeight / 2, wallCenterZ),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Series of small ledges going up the cliff face
	-- Zigzag pattern alternating left and right
	local ledgeData = {
		-- { x, y, width, depth }
		{ -6, 4, 6, 3 },
		{ 4, 7, 5, 3 },
		{ -3, 10, 5, 3 },
		{ 7, 13, 6, 3 },
		{ -7, 16, 5, 3 },
		{ 2, 19, 6, 3 },
		{ -5, 22, 5, 3 },
		{ 6, 25, 6, 3 },
		{ -2, 28, 5, 3 },
	}

	for i, data in ledgeData do
		local ledge = createPart(
			`Ledge_{i}`,
			Vector3.new(data[3], 1, data[4]),
			Vector3.new(data[1], data[2], wallCenterZ + 2),
			theme.GroundColor,
			theme.GroundMaterial,
			stageModel
		)
		-- Small ledges are barely visible in the waterfall
		ledge.Transparency = 0.1
	end

	-- The waterfall zone: covers the entire climbing area
	-- Non-collidable, semi-transparent, applies downward water force
	local waterfallZone = createPart(
		"WaterfallZone",
		Vector3.new(22, wallHeight, 10),
		Vector3.new(0, wallHeight / 2, wallCenterZ),
		Color3.fromRGB(70, 150, 220),
		Enum.Material.Glass,
		stageModel
	)
	waterfallZone.CanCollide = false
	waterfallZone.Transparency = 0.7

	addBoolTag(waterfallZone, "IsWater", true)
	addVector3Value(waterfallZone, "WaterForce", Vector3.new(0, -40, 0)) -- pushes downward

	-- Waterfall source at the top (decorative, the "origin" of the water)
	local waterfallSource = createPart(
		"WaterfallSource",
		Vector3.new(20, 4, 6),
		Vector3.new(0, wallHeight + 2, wallCenterZ + 2),
		Color3.fromRGB(100, 180, 240),
		Enum.Material.Glass,
		stageModel
	)
	waterfallSource.CanCollide = false
	waterfallSource.Transparency = 0.5

	-- Splash pool at the bottom (decorative, shallow water)
	local splashPool = createPart(
		"SplashPool",
		Vector3.new(18, 1, 12),
		Vector3.new(0, -0.5, wallCenterZ - 2),
		Color3.fromRGB(60, 140, 210),
		Enum.Material.Glass,
		stageModel
	)
	splashPool.CanCollide = false
	splashPool.Transparency = 0.4

	-- Top platform (end of the climb)
	createPart(
		"TopPlatform",
		Vector3.new(20, 2, 14),
		Vector3.new(0, wallHeight + 1, wallCenterZ - 4),
		Color3.fromRGB(80, 180, 80),
		Enum.Material.Neon,
		stageModel
	)

	-- Vine/moss decorations on the cliff wall (small colored accents)
	local mossPositions = {
		{ x = -8, y = 8, z = wallCenterZ + 3.5 },
		{ x = 5, y = 12, z = wallCenterZ + 3.5 },
		{ x = -3, y = 18, z = wallCenterZ + 3.5 },
		{ x = 8, y = 22, z = wallCenterZ + 3.5 },
		{ x = -6, y = 26, z = wallCenterZ + 3.5 },
	}

	for i, pos in mossPositions do
		local moss = createPart(
			`Moss_{i}`,
			Vector3.new(3, 2, 0.5),
			Vector3.new(pos.x, pos.y, pos.z),
			Color3.fromRGB(60, 120, 50),
			Enum.Material.Grass,
			stageModel
		)
		moss.CanCollide = false
		moss.Transparency = 0.2
	end

	-- Mist/spray particles marker at the base
	local mistZone = Instance.new("Part")
	mistZone.Name = "WaterfallMist"
	mistZone.Size = Vector3.new(20, 5, 15)
	mistZone.Position = Vector3.new(0, 2, wallCenterZ - 5)
	mistZone.Anchored = true
	mistZone.CanCollide = false
	mistZone.Transparency = 1
	mistZone.Parent = stageModel

	-- Rocky outcrops on the cliff face (can be grabbed/landed on)
	createPart(
		"RockOutcrop_1",
		Vector3.new(4, 2, 2),
		Vector3.new(-9, 6, wallCenterZ + 3),
		Color3.fromRGB(90, 85, 80),
		Enum.Material.Rock,
		stageModel
	)
	createPart(
		"RockOutcrop_2",
		Vector3.new(3, 1.5, 2),
		Vector3.new(8, 15, wallCenterZ + 3),
		Color3.fromRGB(85, 80, 75),
		Enum.Material.Rock,
		stageModel
	)
	createPart(
		"RockOutcrop_3",
		Vector3.new(4, 2, 2),
		Vector3.new(-4, 24, wallCenterZ + 3),
		Color3.fromRGB(95, 90, 85),
		Enum.Material.Rock,
		stageModel
	)
end

-- ================================================================
-- BUILDER REGISTRY
-- Maps stage IDs to their builder functions.
-- ================================================================

ZoneBuilders.Builders = {
	-- Zone 3: The Crayon Caverns
	[11] = buildStage_TheDarkness,
	[12] = buildStage_ThePit,
	[13] = buildStage_TheStalactiteGauntlet,
	[14] = buildStage_TheBoulderChase,
	[15] = buildStage_TheSqueeze,
	-- Zone 4: The Watercolor Wetlands
	[16] = buildStage_TheRapids,
	[17] = buildStage_TheRisingTide,
	[18] = buildStage_TheWhirlpool,
	[19] = buildStage_TheIceSheet,
	[20] = buildStage_TheWaterfallClimb,
}

return ZoneBuilders
