--!strict

--[[
	ZoneBuilders5_6
	Stage geometry builders for Zone 5 (The Ink Ruins) stages 21-25
	and Zone 6 (The Neon Grid) stages 26-30.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneThemes = require(ReplicatedStorage.Shared.ZoneThemes)

local ZoneBuilders = {}

-- Helper to create a themed part
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

-- Helper to attach a BoolValue tag to a part
local function addBoolTag(parent: Instance, tagName: string, value: boolean): BoolValue
	local tag = Instance.new("BoolValue")
	tag.Name = tagName
	tag.Value = value
	tag.Parent = parent
	return tag
end

-- Helper to attach a NumberValue to a part
local function addNumberValue(parent: Instance, valueName: string, value: number): NumberValue
	local nv = Instance.new("NumberValue")
	nv.Name = valueName
	nv.Value = value
	nv.Parent = parent
	return nv
end

-- Helper to attach a StringValue to a part
local function addStringValue(parent: Instance, valueName: string, value: string): StringValue
	local sv = Instance.new("StringValue")
	sv.Name = valueName
	sv.Value = value
	sv.Parent = parent
	return sv
end

-- Helper to attach a Vector3Value to a part
local function addVector3Value(parent: Instance, valueName: string, value: Vector3): Vector3Value
	local v3 = Instance.new("Vector3Value")
	v3.Name = valueName
	v3.Value = value
	v3.Parent = parent
	return v3
end

-- ================================================================
-- ZONE 5: THE INK RUINS (Stages 21-25)
-- Ancient stone stained with ink, dark and heavy atmosphere
-- ================================================================

--[[
	Stage 21 - "The Crumbling Floor"
	Long corridor with a grid of small crumbling floor tiles. Each tile
	can collapse when stepped on. Walls run along both sides. A solid
	end platform awaits beyond the treacherous floor.
]]
local function buildStage21(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local corridorLength = 80
	local corridorWidth = 20
	local tileSize = 4
	local tileHeight = 1
	local wallHeight = 12

	-- Solid entry ramp leading into the corridor
	createPart(
		"EntryRamp",
		Vector3.new(corridorWidth, 2, 10),
		Vector3.new(0, 0, baseZ + 12),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Crumbling tile grid
	local tilesPerRow = math.floor(corridorWidth / tileSize)
	local tilesPerCol = math.floor(corridorLength / tileSize)
	local tileIndex = 0

	local gridStartZ = baseZ + 18
	local gridStartX = -corridorWidth / 2 + tileSize / 2

	for row = 0, tilesPerCol - 1 do
		for col = 0, tilesPerRow - 1 do
			tileIndex += 1
			local tileX = gridStartX + col * tileSize
			local tileZ = gridStartZ + row * tileSize + tileSize / 2

			-- Vary tile color slightly to look like worn stone
			local colorVariation = math.random(-15, 15)
			local tileColor = Color3.fromRGB(
				math.clamp(theme.GroundColor.R * 255 + colorVariation, 0, 255),
				math.clamp(theme.GroundColor.G * 255 + colorVariation, 0, 255),
				math.clamp(theme.GroundColor.B * 255 + colorVariation, 0, 255)
			)

			local tile = createPart(
				`FloorTile_{tileIndex}`,
				Vector3.new(tileSize, tileHeight, tileSize),
				Vector3.new(tileX, 0, tileZ),
				tileColor,
				theme.GroundMaterial,
				stageModel
			)

			addBoolTag(tile, "IsCrumblingTile", true)
		end
	end

	-- Left corridor wall
	createPart(
		"CorridorWallL",
		Vector3.new(2, wallHeight, corridorLength + 10),
		Vector3.new(-corridorWidth / 2 - 1, wallHeight / 2, baseZ + 18 + corridorLength / 2),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Right corridor wall
	createPart(
		"CorridorWallR",
		Vector3.new(2, wallHeight, corridorLength + 10),
		Vector3.new(corridorWidth / 2 + 1, wallHeight / 2, baseZ + 18 + corridorLength / 2),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Decorative ruined pillars along walls
	for i = 1, 4 do
		local pillarZ = baseZ + 18 + i * (corridorLength / 5)
		local pillarHeight = math.random(6, 10)

		createPart(
			`RuinPillarL_{i}`,
			Vector3.new(3, pillarHeight, 3),
			Vector3.new(-corridorWidth / 2 + 3, pillarHeight / 2, pillarZ),
			Color3.fromRGB(55, 50, 60),
			Enum.Material.Cobblestone,
			stageModel
		)
		createPart(
			`RuinPillarR_{i}`,
			Vector3.new(3, pillarHeight, 3),
			Vector3.new(corridorWidth / 2 - 3, pillarHeight / 2, pillarZ),
			Color3.fromRGB(55, 50, 60),
			Enum.Material.Cobblestone,
			stageModel
		)
	end

	-- Ink stain decorations on floor (non-collidable, visual only)
	for i = 1, 6 do
		local stainZ = baseZ + 20 + math.random(0, corridorLength - 10)
		local stainX = math.random(-8, 8)
		local stain = createPart(
			`InkStain_{i}`,
			Vector3.new(math.random(3, 7), 0.1, math.random(3, 7)),
			Vector3.new(stainX, 0.6, stainZ),
			Color3.fromRGB(15, 10, 30),
			Enum.Material.SmoothPlastic,
			stageModel
		)
		stain.CanCollide = false
	end

	-- Solid end platform
	createPart(
		"EndSolid",
		Vector3.new(corridorWidth, 2, 12),
		Vector3.new(0, 0, baseZ + 18 + corridorLength + 6),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
end

--[[
	Stage 22 - "The Sentry Statues"
	Wide room with 4 sentry statues that detect nearby players.
	Short cover walls between sentries let the player hide.
	The sentries are tall pillars topped with head-like forms.
]]
local function buildStage22(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local roomLength = 70
	local roomWidth = 24
	local wallHeight = 14

	-- Main floor
	createPart(
		"Floor",
		Vector3.new(roomWidth, 2, roomLength),
		Vector3.new(0, 0, baseZ + 10 + roomLength / 2),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Side walls
	createPart(
		"WallL",
		Vector3.new(2, wallHeight, roomLength),
		Vector3.new(-roomWidth / 2 - 1, wallHeight / 2, baseZ + 10 + roomLength / 2),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"WallR",
		Vector3.new(2, wallHeight, roomLength),
		Vector3.new(roomWidth / 2 + 1, wallHeight / 2, baseZ + 10 + roomLength / 2),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- 4 Sentry Statues placed at intervals along the center path
	local sentryPositions = {
		Vector3.new(-4, 0, baseZ + 22),
		Vector3.new(5, 0, baseZ + 36),
		Vector3.new(-3, 0, baseZ + 52),
		Vector3.new(6, 0, baseZ + 66),
	}

	for i, pos in sentryPositions do
		-- Statue base (wide pedestal)
		createPart(
			`SentryBase_{i}`,
			Vector3.new(5, 2, 5),
			Vector3.new(pos.X, 2, pos.Z),
			Color3.fromRGB(50, 45, 55),
			Enum.Material.Cobblestone,
			stageModel
		)

		-- Statue body (tall pillar)
		local bodyHeight = 10
		createPart(
			`SentryBody_{i}`,
			Vector3.new(3, bodyHeight, 3),
			Vector3.new(pos.X, 3 + bodyHeight / 2, pos.Z),
			Color3.fromRGB(60, 55, 65),
			Enum.Material.Cobblestone,
			stageModel
		)

		-- Statue head
		local sentry = createPart(
			`Sentry_{i}`,
			Vector3.new(4, 4, 4),
			Vector3.new(pos.X, 3 + bodyHeight + 2, pos.Z),
			Color3.fromRGB(40, 30, 50),
			Enum.Material.Slate,
			stageModel
		)

		addBoolTag(sentry, "IsSentry", true)
		addNumberValue(sentry, "DetectRange", 15)

		-- Glowing eyes (small neon accent parts)
		local eyeColor = theme.AccentColor
		local eyeL = createPart(
			`SentryEyeL_{i}`,
			Vector3.new(0.5, 0.5, 0.5),
			Vector3.new(pos.X - 0.8, 3 + bodyHeight + 2.3, pos.Z - 2),
			eyeColor,
			Enum.Material.Neon,
			stageModel
		)
		eyeL.CanCollide = false

		local eyeR = createPart(
			`SentryEyeR_{i}`,
			Vector3.new(0.5, 0.5, 0.5),
			Vector3.new(pos.X + 0.8, 3 + bodyHeight + 2.3, pos.Z - 2),
			eyeColor,
			Enum.Material.Neon,
			stageModel
		)
		eyeR.CanCollide = false
	end

	-- Cover walls between sentries (short, player can duck behind them)
	local coverPositions = {
		{ x = 0, z = baseZ + 29 },
		{ x = -2, z = baseZ + 44 },
		{ x = 3, z = baseZ + 59 },
	}

	for i, cpos in coverPositions do
		createPart(
			`CoverWall_{i}`,
			Vector3.new(8, 3, 2),
			Vector3.new(cpos.x, 2.5, cpos.z),
			Color3.fromRGB(65, 60, 70),
			Enum.Material.Brick,
			stageModel
		)
	end

	-- Scattered rubble for atmosphere
	for i = 1, 8 do
		local rubbleZ = baseZ + 15 + math.random(0, 60)
		local rubbleX = math.random(-9, 9)
		createPart(
			`Rubble_{i}`,
			Vector3.new(math.random(1, 3), math.random(1, 2), math.random(1, 3)),
			Vector3.new(rubbleX, 1, rubbleZ),
			Color3.fromRGB(55, 50, 58),
			Enum.Material.Cobblestone,
			stageModel
		)
	end
end

--[[
	Stage 23 - "The Pendulum Hall"
	Long hallway with floor and ceiling. 5 large pendulums hang from the
	ceiling and swing side to side. A raised platform path runs along one
	wall as an alternative route above the pendulums.
]]
local function buildStage23(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local hallLength = 80
	local hallWidth = 20
	local wallHeight = 18
	local ceilingHeight = wallHeight

	-- Main floor
	createPart(
		"Floor",
		Vector3.new(hallWidth, 2, hallLength),
		Vector3.new(0, 0, baseZ + 10 + hallLength / 2),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Ceiling
	createPart(
		"Ceiling",
		Vector3.new(hallWidth + 4, 2, hallLength),
		Vector3.new(0, ceilingHeight, baseZ + 10 + hallLength / 2),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Side walls
	createPart(
		"WallL",
		Vector3.new(2, wallHeight, hallLength),
		Vector3.new(-hallWidth / 2 - 1, wallHeight / 2, baseZ + 10 + hallLength / 2),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"WallR",
		Vector3.new(2, wallHeight, hallLength),
		Vector3.new(hallWidth / 2 + 1, wallHeight / 2, baseZ + 10 + hallLength / 2),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- 5 Pendulums hanging from the ceiling, evenly spaced
	local pendulumSpacing = hallLength / 6
	for i = 1, 5 do
		local pendZ = baseZ + 10 + i * pendulumSpacing

		-- Pendulum mount (attached to ceiling)
		createPart(
			`PendulumMount_{i}`,
			Vector3.new(2, 2, 2),
			Vector3.new(0, ceilingHeight - 1, pendZ),
			Color3.fromRGB(40, 35, 45),
			Enum.Material.Metal,
			stageModel
		)

		-- Pendulum arm (long thin vertical part)
		createPart(
			`PendulumArm_{i}`,
			Vector3.new(1, 10, 1),
			Vector3.new(0, ceilingHeight - 7, pendZ),
			Color3.fromRGB(50, 45, 55),
			Enum.Material.Metal,
			stageModel
		)

		-- Pendulum weight (large swinging mass at bottom)
		local pendulum = createPart(
			`Pendulum_{i}`,
			Vector3.new(6, 4, 3),
			Vector3.new(0, ceilingHeight - 14, pendZ),
			Color3.fromRGB(35, 25, 45),
			Enum.Material.Slate,
			stageModel
		)

		addBoolTag(pendulum, "IsPendulum", true)
		addNumberValue(pendulum, "SwingSpeed", 2 + i * 0.3) -- Slightly different speeds
		addNumberValue(pendulum, "SwingRange", 7)
	end

	-- Raised platform path along left wall (alternative route)
	local platformHeight = 8
	local platformWidth = 5

	-- Ramp up to raised path
	local ramp = createPart(
		"RaisedRampUp",
		Vector3.new(platformWidth, 1, 10),
		Vector3.new(-hallWidth / 2 + platformWidth / 2 + 1, platformHeight / 2, baseZ + 15),
		theme.AccentColor,
		Enum.Material.Cobblestone,
		stageModel
	)
	-- Use a wedge-like visual by tilting the ramp
	ramp.Orientation = Vector3.new(-20, 0, 0)

	-- Raised walkway segments (with gaps for challenge)
	local walkwaySegments = {
		{ z = baseZ + 25, length = 14 },
		{ z = baseZ + 43, length = 10 },
		{ z = baseZ + 58, length = 12 },
		{ z = baseZ + 76, length = 10 },
	}

	for i, seg in walkwaySegments do
		createPart(
			`RaisedWalkway_{i}`,
			Vector3.new(platformWidth, 1, seg.length),
			Vector3.new(-hallWidth / 2 + platformWidth / 2 + 1, platformHeight, seg.z),
			Color3.fromRGB(60, 55, 70),
			Enum.Material.Cobblestone,
			stageModel
		)
	end

	-- Ink drip decorations on ceiling
	for i = 1, 10 do
		local dripZ = baseZ + 12 + math.random(0, hallLength - 5)
		local dripX = math.random(-8, 8)
		local drip = createPart(
			`InkDrip_{i}`,
			Vector3.new(0.5, math.random(1, 4), 0.5),
			Vector3.new(dripX, ceilingHeight - 2, dripZ),
			Color3.fromRGB(10, 5, 20),
			Enum.Material.SmoothPlastic,
			stageModel
		)
		drip.CanCollide = false
	end
end

--[[
	Stage 24 - "The Puzzle Lock"
	Room with four raised pedestals, each requiring a specific drawn shape
	to be placed on it. A large gate blocks the exit until all pedestals
	are satisfied. Neon tops on pedestals hint at the shapes needed.
]]
local function buildStage24(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local roomLength = 60
	local roomWidth = 28
	local wallHeight = 14

	-- Main floor
	createPart(
		"Floor",
		Vector3.new(roomWidth, 2, roomLength),
		Vector3.new(0, 0, baseZ + 10 + roomLength / 2),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Side walls
	createPart(
		"WallL",
		Vector3.new(2, wallHeight, roomLength),
		Vector3.new(-roomWidth / 2 - 1, wallHeight / 2, baseZ + 10 + roomLength / 2),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"WallR",
		Vector3.new(2, wallHeight, roomLength),
		Vector3.new(roomWidth / 2 + 1, wallHeight / 2, baseZ + 10 + roomLength / 2),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Back wall (behind gate area)
	createPart(
		"BackWall",
		Vector3.new(roomWidth, wallHeight, 2),
		Vector3.new(0, wallHeight / 2, baseZ + 10 + roomLength + 1),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Four pedestals in a 2x2 arrangement
	local shapes = { "circle", "triangle", "square", "star" }
	local pedestalColors = {
		Color3.fromRGB(80, 200, 255), -- blue for circle
		Color3.fromRGB(255, 200, 50), -- yellow for triangle
		Color3.fromRGB(50, 255, 100), -- green for square
		Color3.fromRGB(255, 80, 200), -- pink for star
	}
	local pedestalPositions = {
		Vector3.new(-6, 0, baseZ + 30),
		Vector3.new(6, 0, baseZ + 30),
		Vector3.new(-6, 0, baseZ + 48),
		Vector3.new(6, 0, baseZ + 48),
	}

	for i = 1, 4 do
		local pos = pedestalPositions[i]

		-- Pedestal base (stone)
		createPart(
			`PedestalBase_{i}`,
			Vector3.new(6, 1, 6),
			Vector3.new(pos.X, 1.5, pos.Z),
			Color3.fromRGB(50, 45, 55),
			Enum.Material.Cobblestone,
			stageModel
		)

		-- Pedestal column
		local pedestal = createPart(
			`Pedestal_{i}`,
			Vector3.new(4, 3, 4),
			Vector3.new(pos.X, 3.5, pos.Z),
			Color3.fromRGB(60, 55, 65),
			Enum.Material.Cobblestone,
			stageModel
		)

		addStringValue(pedestal, "RequiredShape", shapes[i])
		addBoolTag(pedestal, "IsPedestal", true)

		-- Neon top to indicate placement surface and shape color
		local neonTop = createPart(
			`PedestalNeon_{i}`,
			Vector3.new(4, 0.3, 4),
			Vector3.new(pos.X, 5.15, pos.Z),
			pedestalColors[i],
			Enum.Material.Neon,
			stageModel
		)
		neonTop.CanCollide = false

		-- Small floating symbol hint above each pedestal (decorative marker)
		local hint = createPart(
			`PedestalHint_{i}`,
			Vector3.new(1.5, 1.5, 0.2),
			Vector3.new(pos.X, 7, pos.Z),
			pedestalColors[i],
			Enum.Material.Neon,
			stageModel
		)
		hint.CanCollide = false
		hint.Transparency = 0.3
	end

	-- Large gate blocking the exit
	local gate = createPart(
		"PuzzleGate",
		Vector3.new(roomWidth, wallHeight, 3),
		Vector3.new(0, wallHeight / 2, baseZ + 10 + roomLength - 5),
		Color3.fromRGB(100, 40, 40),
		Enum.Material.Brick,
		stageModel
	)
	addBoolTag(gate, "IsGate", true)
	addNumberValue(gate, "RequiredCount", 4)

	-- Decorative chains on gate
	for i = 1, 3 do
		local chainX = -8 + (i - 1) * 8
		local chain = createPart(
			`GateChain_{i}`,
			Vector3.new(0.5, wallHeight - 2, 0.5),
			Vector3.new(chainX, wallHeight / 2, baseZ + 10 + roomLength - 5 - 1.8),
			Color3.fromRGB(80, 75, 85),
			Enum.Material.Metal,
			stageModel
		)
		chain.CanCollide = false
	end

	-- Ink-stained floor patterns radiating from pedestals
	for i = 1, 4 do
		local pos = pedestalPositions[i]
		for j = 1, 3 do
			local angle = (j - 1) * 2.1 + i
			local dist = 3 + j
			local stainX = pos.X + math.cos(angle) * dist
			local stainZ = pos.Z + math.sin(angle) * dist
			local stain = createPart(
				`InkPattern_{i}_{j}`,
				Vector3.new(2, 0.1, 2),
				Vector3.new(stainX, 1.1, stainZ),
				Color3.fromRGB(20, 15, 35),
				Enum.Material.SmoothPlastic,
				stageModel
			)
			stain.CanCollide = false
		end
	end
end

--[[
	Stage 25 - "The Collapsing Bridge"
	Start platform, then a very long bridge (100 studs) made of collapsing
	sections over a deadly void. Each bridge section collapses after being
	stepped on. End platform on the far side.
]]
local function buildStage25(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local bridgeLength = 100
	local sectionSize = 8
	local sectionCount = math.floor(bridgeLength / sectionSize)
	local bridgeWidth = 8

	-- Start platform (solid, safe)
	createPart(
		"BridgeStartPlatform",
		Vector3.new(16, 2, 14),
		Vector3.new(0, 0, baseZ + 14),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Ruined archway at bridge entrance
	createPart(
		"ArchLeft",
		Vector3.new(3, 16, 3),
		Vector3.new(-bridgeWidth / 2 - 2, 8, baseZ + 22),
		Color3.fromRGB(50, 45, 55),
		Enum.Material.Cobblestone,
		stageModel
	)
	createPart(
		"ArchRight",
		Vector3.new(3, 16, 3),
		Vector3.new(bridgeWidth / 2 + 2, 8, baseZ + 22),
		Color3.fromRGB(50, 45, 55),
		Enum.Material.Cobblestone,
		stageModel
	)
	createPart(
		"ArchTop",
		Vector3.new(bridgeWidth + 7, 3, 3),
		Vector3.new(0, 17, baseZ + 22),
		Color3.fromRGB(50, 45, 55),
		Enum.Material.Cobblestone,
		stageModel
	)

	-- Collapsing bridge sections
	local bridgeStartZ = baseZ + 22
	for i = 1, sectionCount do
		local sectionZ = bridgeStartZ + (i - 1) * sectionSize + sectionSize / 2

		-- Vary color slightly for each section to show age
		local colorOffset = math.random(-10, 10)
		local sectionColor = Color3.fromRGB(
			math.clamp(theme.GroundColor.R * 255 + colorOffset, 0, 255),
			math.clamp(theme.GroundColor.G * 255 + colorOffset, 0, 255),
			math.clamp(theme.GroundColor.B * 255 + colorOffset, 0, 255)
		)

		local section = createPart(
			`BridgeSection_{i}`,
			Vector3.new(bridgeWidth, 1, sectionSize),
			Vector3.new(0, 0, sectionZ),
			sectionColor,
			theme.GroundMaterial,
			stageModel
		)

		addBoolTag(section, "IsCollapsingSection", true)
		addNumberValue(section, "CollapseDelay", 0.8 + math.random() * 0.4) -- Slight variation

		-- Cracks on top of each section (visual detail, non-collidable)
		if math.random() > 0.4 then
			local crack = createPart(
				`BridgeCrack_{i}`,
				Vector3.new(math.random(1, 4), 0.05, math.random(1, 6)),
				Vector3.new(math.random(-2, 2), 0.55, sectionZ),
				Color3.fromRGB(20, 15, 25),
				Enum.Material.SmoothPlastic,
				stageModel
			)
			crack.CanCollide = false
		end
	end

	-- Low railing remnants along bridge edges (broken, partial cover)
	for i = 1, 6 do
		local railZ = bridgeStartZ + math.random(5, bridgeLength - 5)
		local railSide = if i % 2 == 0 then 1 else -1
		local railHeight = math.random(2, 4)
		createPart(
			`BridgeRailRemnant_{i}`,
			Vector3.new(1, railHeight, math.random(3, 8)),
			Vector3.new(railSide * (bridgeWidth / 2 + 0.5), railHeight / 2, railZ),
			Color3.fromRGB(55, 50, 60),
			Enum.Material.Cobblestone,
			stageModel
		)
	end

	-- End platform (solid, safe)
	createPart(
		"BridgeEndPlatform",
		Vector3.new(16, 2, 14),
		Vector3.new(0, 0, bridgeStartZ + bridgeLength + 7),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Ruined archway at bridge exit
	createPart(
		"ExitArchLeft",
		Vector3.new(3, 16, 3),
		Vector3.new(-bridgeWidth / 2 - 2, 8, bridgeStartZ + bridgeLength),
		Color3.fromRGB(50, 45, 55),
		Enum.Material.Cobblestone,
		stageModel
	)
	createPart(
		"ExitArchRight",
		Vector3.new(3, 16, 3),
		Vector3.new(bridgeWidth / 2 + 2, 8, bridgeStartZ + bridgeLength),
		Color3.fromRGB(50, 45, 55),
		Enum.Material.Cobblestone,
		stageModel
	)
	createPart(
		"ExitArchTop",
		Vector3.new(bridgeWidth + 7, 3, 3),
		Vector3.new(0, 17, bridgeStartZ + bridgeLength),
		Color3.fromRGB(50, 45, 55),
		Enum.Material.Cobblestone,
		stageModel
	)

	-- Kill zone far below the bridge
	local killZone = Instance.new("Part")
	killZone.Name = "BridgeKillZone"
	killZone.Size = Vector3.new(bridgeWidth + 20, 2, bridgeLength + 20)
	killZone.Position = Vector3.new(0, -30, bridgeStartZ + bridgeLength / 2)
	killZone.Anchored = true
	killZone.CanCollide = false
	killZone.Transparency = 1
	killZone.Parent = stageModel

	addBoolTag(killZone, "IsKillZone", true)

	-- Foggy void effect below bridge (semi-transparent dark parts)
	for i = 1, 4 do
		local fogPart = createPart(
			`VoidFog_{i}`,
			Vector3.new(bridgeWidth + 10, 1, bridgeLength / 4),
			Vector3.new(0, -15 - i * 3, bridgeStartZ + (i - 1) * (bridgeLength / 4) + bridgeLength / 8),
			Color3.fromRGB(10, 8, 18),
			Enum.Material.SmoothPlastic,
			stageModel
		)
		fogPart.CanCollide = false
		fogPart.Transparency = 0.4 + i * 0.1
	end
end

-- ================================================================
-- ZONE 6: THE NEON GRID (Stages 26-30)
-- Tron-like, dark environment with glowing neon lines, digital feel
-- ================================================================

--[[
	Stage 26 - "The Laser Grid"
	Dark corridor with neon floor. Thin, bright red laser beams stretch
	across at various heights and angles. Player must find gaps between
	lasers to navigate through. Some horizontal, some diagonal.
]]
local function buildStage26(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local corridorLength = 70
	local corridorWidth = 16
	local wallHeight = 14

	-- Dark Neon floor
	createPart(
		"Floor",
		Vector3.new(corridorWidth, 2, corridorLength),
		Vector3.new(0, 0, baseZ + 10 + corridorLength / 2),
		Color3.fromRGB(8, 8, 18),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Neon grid lines on floor (non-collidable decorative)
	for i = 1, 8 do
		local lineZ = baseZ + 10 + i * (corridorLength / 9)
		local gridLine = createPart(
			`GridLineZ_{i}`,
			Vector3.new(corridorWidth, 0.05, 0.2),
			Vector3.new(0, 1.05, lineZ),
			theme.WallColor,
			Enum.Material.Neon,
			stageModel
		)
		gridLine.CanCollide = false
	end
	for i = 1, 4 do
		local lineX = -corridorWidth / 2 + i * (corridorWidth / 5)
		local gridLine = createPart(
			`GridLineX_{i}`,
			Vector3.new(0.2, 0.05, corridorLength),
			Vector3.new(lineX, 1.05, baseZ + 10 + corridorLength / 2),
			theme.WallColor,
			Enum.Material.Neon,
			stageModel
		)
		gridLine.CanCollide = false
	end

	-- Side walls (dark with neon edges)
	createPart(
		"WallL",
		Vector3.new(2, wallHeight, corridorLength),
		Vector3.new(-corridorWidth / 2 - 1, wallHeight / 2, baseZ + 10 + corridorLength / 2),
		Color3.fromRGB(5, 5, 12),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	createPart(
		"WallR",
		Vector3.new(2, wallHeight, corridorLength),
		Vector3.new(corridorWidth / 2 + 1, wallHeight / 2, baseZ + 10 + corridorLength / 2),
		Color3.fromRGB(5, 5, 12),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Neon wall edge accents
	createPart(
		"WallAccentL",
		Vector3.new(0.2, wallHeight, corridorLength),
		Vector3.new(-corridorWidth / 2, wallHeight / 2, baseZ + 10 + corridorLength / 2),
		theme.WallColor,
		Enum.Material.Neon,
		stageModel
	)
	createPart(
		"WallAccentR",
		Vector3.new(0.2, wallHeight, corridorLength),
		Vector3.new(corridorWidth / 2, wallHeight / 2, baseZ + 10 + corridorLength / 2),
		theme.WallColor,
		Enum.Material.Neon,
		stageModel
	)

	-- Ceiling
	createPart(
		"Ceiling",
		Vector3.new(corridorWidth + 4, 2, corridorLength),
		Vector3.new(0, wallHeight, baseZ + 10 + corridorLength / 2),
		Color3.fromRGB(5, 5, 12),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- LASERS - various configurations
	local laserColor = Color3.fromRGB(255, 30, 30)

	-- Horizontal lasers at different heights
	local horizontalLasers = {
		{ z = baseZ + 20, height = 3, width = corridorWidth },
		{ z = baseZ + 28, height = 7, width = corridorWidth },
		{ z = baseZ + 35, height = 2, width = 10 },
		{ z = baseZ + 35, height = 9, width = corridorWidth },
		{ z = baseZ + 44, height = 5, width = corridorWidth },
		{ z = baseZ + 52, height = 3, width = 8 },
		{ z = baseZ + 52, height = 10, width = corridorWidth },
		{ z = baseZ + 60, height = 4, width = corridorWidth },
		{ z = baseZ + 60, height = 8, width = 12 },
		{ z = baseZ + 68, height = 6, width = corridorWidth },
	}

	for i, laserDef in horizontalLasers do
		local laser = createPart(
			`Laser_{i}`,
			Vector3.new(laserDef.width, 0.3, 0.3),
			Vector3.new(0, laserDef.height, laserDef.z),
			laserColor,
			Enum.Material.Neon,
			stageModel
		)
		laser.CanCollide = false
		addBoolTag(laser, "IsLaser", true)
	end

	-- Diagonal lasers (rotated)
	local diagonalLasers = {
		{ z = baseZ + 24, height = 5, angle = 30 },
		{ z = baseZ + 40, height = 6, angle = -25 },
		{ z = baseZ + 56, height = 4, angle = 20 },
		{ z = baseZ + 64, height = 7, angle = -35 },
	}

	for i, diagDef in diagonalLasers do
		local diagLaser = createPart(
			`LaserDiag_{i}`,
			Vector3.new(corridorWidth * 0.7, 0.3, 0.3),
			Vector3.new(0, diagDef.height, diagDef.z),
			laserColor,
			Enum.Material.Neon,
			stageModel
		)
		diagLaser.CanCollide = false
		diagLaser.Orientation = Vector3.new(0, 0, diagDef.angle)
		addBoolTag(diagLaser, "IsLaser", true)
	end

	-- Vertical laser columns (floor to ceiling in some spots)
	local verticalLasers = {
		{ x = -3, z = baseZ + 32 },
		{ x = 4, z = baseZ + 48 },
	}

	for i, vertDef in verticalLasers do
		local vertLaser = createPart(
			`LaserVert_{i}`,
			Vector3.new(0.3, wallHeight - 4, 0.3),
			Vector3.new(vertDef.x, wallHeight / 2, vertDef.z),
			laserColor,
			Enum.Material.Neon,
			stageModel
		)
		vertLaser.CanCollide = false
		addBoolTag(vertLaser, "IsLaser", true)
	end

	-- Laser emitter housings (decorative boxes on walls where lasers originate)
	for i = 1, 6 do
		local emitterZ = baseZ + 15 + i * 9
		local side = if i % 2 == 0 then 1 else -1
		createPart(
			`LaserEmitter_{i}`,
			Vector3.new(1.5, 1.5, 1.5),
			Vector3.new(side * (corridorWidth / 2 - 0.5), math.random(3, 9), emitterZ),
			Color3.fromRGB(40, 10, 10),
			Enum.Material.Metal,
			stageModel
		)
	end
end

--[[
	Stage 27 - "The Conveyor"
	Three floating platforms that move in different directions. Player must
	bridge between them. Dark base below with neon accent edges on the
	platforms. Each platform has a conveyor direction and speed.
]]
local function buildStage27(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local roomWidth = 30

	-- Start ledge
	createPart(
		"StartLedge",
		Vector3.new(12, 2, 10),
		Vector3.new(0, 0, baseZ + 12),
		Color3.fromRGB(8, 8, 18),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	-- Neon edge on start ledge
	createPart(
		"StartLedgeEdge",
		Vector3.new(12, 0.2, 0.3),
		Vector3.new(0, 1.1, baseZ + 17),
		theme.WallColor,
		Enum.Material.Neon,
		stageModel
	)

	-- Three conveyor platforms with varying positions and directions
	local conveyorDefs = {
		{
			pos = Vector3.new(-8, 0, baseZ + 30),
			size = Vector3.new(10, 2, 10),
			direction = Vector3.new(1, 0, 0), -- moves right
			speed = 8,
		},
		{
			pos = Vector3.new(5, 3, baseZ + 48),
			size = Vector3.new(12, 2, 8),
			direction = Vector3.new(-1, 0, 0), -- moves left
			speed = 6,
		},
		{
			pos = Vector3.new(-3, 1, baseZ + 65),
			size = Vector3.new(10, 2, 10),
			direction = Vector3.new(0, 0, 1), -- moves forward
			speed = 10,
		},
	}

	for i, convDef in conveyorDefs do
		-- Main platform body (dark)
		local platform = createPart(
			`ConveyorPlatform_{i}`,
			convDef.size,
			convDef.pos,
			Color3.fromRGB(12, 12, 22),
			Enum.Material.SmoothPlastic,
			stageModel
		)

		addVector3Value(platform, "ConveyorDirection", convDef.direction)
		addNumberValue(platform, "ConveyorSpeed", convDef.speed)
		addBoolTag(platform, "IsConveyor", true)

		-- Neon accent edges on all four sides of each platform
		local halfW = convDef.size.X / 2
		local halfL = convDef.size.Z / 2
		local edgeH = convDef.pos.Y + convDef.size.Y / 2 + 0.1
		local edgeColor = if i % 2 == 0 then theme.AccentColor else theme.WallColor

		-- Front edge
		createPart(
			`ConveyorEdgeF_{i}`,
			Vector3.new(convDef.size.X, 0.2, 0.3),
			Vector3.new(convDef.pos.X, edgeH, convDef.pos.Z + halfL),
			edgeColor,
			Enum.Material.Neon,
			stageModel
		)
		-- Back edge
		createPart(
			`ConveyorEdgeB_{i}`,
			Vector3.new(convDef.size.X, 0.2, 0.3),
			Vector3.new(convDef.pos.X, edgeH, convDef.pos.Z - halfL),
			edgeColor,
			Enum.Material.Neon,
			stageModel
		)
		-- Left edge
		createPart(
			`ConveyorEdgeL_{i}`,
			Vector3.new(0.3, 0.2, convDef.size.Z),
			Vector3.new(convDef.pos.X - halfW, edgeH, convDef.pos.Z),
			edgeColor,
			Enum.Material.Neon,
			stageModel
		)
		-- Right edge
		createPart(
			`ConveyorEdgeR_{i}`,
			Vector3.new(0.3, 0.2, convDef.size.Z),
			Vector3.new(convDef.pos.X + halfW, edgeH, convDef.pos.Z),
			edgeColor,
			Enum.Material.Neon,
			stageModel
		)

		-- Directional arrow lines on platform surface (visual cue for direction)
		local arrowColor = Color3.fromRGB(200, 200, 255)
		for j = 1, 3 do
			local offset = (j - 2) * (convDef.size.Z / 4) * convDef.direction.Z
				+ (j - 2) * (convDef.size.X / 4) * convDef.direction.X
			local arrowX = convDef.pos.X + convDef.direction.X * offset
			local arrowZ = convDef.pos.Z + convDef.direction.Z * offset

			local arrow = createPart(
				`ConveyorArrow_{i}_{j}`,
				Vector3.new(1, 0.05, 0.3),
				Vector3.new(arrowX, edgeH, arrowZ),
				arrowColor,
				Enum.Material.Neon,
				stageModel
			)
			arrow.CanCollide = false
		end
	end

	-- End ledge
	createPart(
		"EndLedge",
		Vector3.new(12, 2, 10),
		Vector3.new(0, 0, baseZ + 82),
		Color3.fromRGB(8, 8, 18),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	createPart(
		"EndLedgeEdge",
		Vector3.new(12, 0.2, 0.3),
		Vector3.new(0, 1.1, baseZ + 77),
		theme.WallColor,
		Enum.Material.Neon,
		stageModel
	)

	-- Void kill zone below
	local voidKill = Instance.new("Part")
	voidKill.Name = "ConveyorKillZone"
	voidKill.Size = Vector3.new(roomWidth + 20, 2, 90)
	voidKill.Position = Vector3.new(0, -25, baseZ + 45)
	voidKill.Anchored = true
	voidKill.CanCollide = false
	voidKill.Transparency = 1
	voidKill.Parent = stageModel
	addBoolTag(voidKill, "IsKillZone", true)

	-- Floating data particles (decorative non-collidable cubes in the void)
	for i = 1, 12 do
		local particle = createPart(
			`DataParticle_{i}`,
			Vector3.new(0.5, 0.5, 0.5),
			Vector3.new(math.random(-12, 12), math.random(-15, -3), baseZ + 20 + math.random(0, 55)),
			if math.random() > 0.5 then theme.WallColor else theme.AccentColor,
			Enum.Material.Neon,
			stageModel
		)
		particle.CanCollide = false
		particle.Transparency = 0.3
	end
end

--[[
	Stage 28 - "The Gravity Flip"
	Enclosed room with platforms on both the floor AND ceiling. A gravity
	zone fills the room and periodically flips gravity. Neon accent lines
	on the walls. Players must time their movement with the gravity flips.
]]
local function buildStage28(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local roomLength = 60
	local roomWidth = 22
	local roomHeight = 24
	local wallThickness = 2

	-- Floor
	createPart(
		"Floor",
		Vector3.new(roomWidth, wallThickness, roomLength),
		Vector3.new(0, 0, baseZ + 10 + roomLength / 2),
		Color3.fromRGB(8, 8, 18),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Ceiling
	createPart(
		"Ceiling",
		Vector3.new(roomWidth, wallThickness, roomLength),
		Vector3.new(0, roomHeight, baseZ + 10 + roomLength / 2),
		Color3.fromRGB(8, 8, 18),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Side walls
	createPart(
		"WallL",
		Vector3.new(wallThickness, roomHeight, roomLength),
		Vector3.new(-roomWidth / 2 - wallThickness / 2, roomHeight / 2, baseZ + 10 + roomLength / 2),
		Color3.fromRGB(5, 5, 12),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	createPart(
		"WallR",
		Vector3.new(wallThickness, roomHeight, roomLength),
		Vector3.new(roomWidth / 2 + wallThickness / 2, roomHeight / 2, baseZ + 10 + roomLength / 2),
		Color3.fromRGB(5, 5, 12),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Neon accent lines on walls (horizontal stripes)
	for i = 1, 5 do
		local lineY = i * (roomHeight / 6)
		createPart(
			`WallAccentL_{i}`,
			Vector3.new(0.2, 0.3, roomLength),
			Vector3.new(-roomWidth / 2 + 0.1, lineY, baseZ + 10 + roomLength / 2),
			theme.WallColor,
			Enum.Material.Neon,
			stageModel
		)
		createPart(
			`WallAccentR_{i}`,
			Vector3.new(0.2, 0.3, roomLength),
			Vector3.new(roomWidth / 2 - 0.1, lineY, baseZ + 10 + roomLength / 2),
			theme.WallColor,
			Enum.Material.Neon,
			stageModel
		)
	end

	-- Neon accent lines on walls (vertical stripes)
	for i = 1, 6 do
		local lineZ = baseZ + 10 + i * (roomLength / 7)
		createPart(
			`WallVertAccentL_{i}`,
			Vector3.new(0.2, roomHeight, 0.3),
			Vector3.new(-roomWidth / 2 + 0.1, roomHeight / 2, lineZ),
			theme.AccentColor,
			Enum.Material.Neon,
			stageModel
		)
		createPart(
			`WallVertAccentR_{i}`,
			Vector3.new(0.2, roomHeight, 0.3),
			Vector3.new(roomWidth / 2 - 0.1, roomHeight / 2, lineZ),
			theme.AccentColor,
			Enum.Material.Neon,
			stageModel
		)
	end

	-- Floor platforms (normal gravity path)
	local floorPlatforms = {
		{ pos = Vector3.new(-5, 2, baseZ + 20), size = Vector3.new(8, 1, 8) },
		{ pos = Vector3.new(4, 2, baseZ + 32), size = Vector3.new(6, 1, 6) },
		{ pos = Vector3.new(-3, 2, baseZ + 44), size = Vector3.new(7, 1, 7) },
		{ pos = Vector3.new(5, 2, baseZ + 56), size = Vector3.new(8, 1, 8) },
		{ pos = Vector3.new(0, 2, baseZ + 66), size = Vector3.new(10, 1, 6) },
	}

	for i, platDef in floorPlatforms do
		local plat = createPart(
			`FloorPlatform_{i}`,
			platDef.size,
			platDef.pos,
			Color3.fromRGB(15, 15, 30),
			Enum.Material.SmoothPlastic,
			stageModel
		)

		-- Neon edge on platform
		createPart(
			`FloorPlatEdge_{i}`,
			Vector3.new(platDef.size.X, 0.15, 0.3),
			Vector3.new(platDef.pos.X, platDef.pos.Y + platDef.size.Y / 2 + 0.1, platDef.pos.Z + platDef.size.Z / 2),
			theme.WallColor,
			Enum.Material.Neon,
			plat
		)
	end

	-- Ceiling platforms (inverted gravity path)
	local ceilingPlatforms = {
		{ pos = Vector3.new(3, roomHeight - 2, baseZ + 25), size = Vector3.new(7, 1, 7) },
		{ pos = Vector3.new(-6, roomHeight - 2, baseZ + 37), size = Vector3.new(8, 1, 6) },
		{ pos = Vector3.new(2, roomHeight - 2, baseZ + 49), size = Vector3.new(6, 1, 8) },
		{ pos = Vector3.new(-4, roomHeight - 2, baseZ + 60), size = Vector3.new(7, 1, 7) },
		{ pos = Vector3.new(1, roomHeight - 2, baseZ + 68), size = Vector3.new(9, 1, 6) },
	}

	for i, platDef in ceilingPlatforms do
		local plat = createPart(
			`CeilingPlatform_{i}`,
			platDef.size,
			platDef.pos,
			Color3.fromRGB(15, 15, 30),
			Enum.Material.SmoothPlastic,
			stageModel
		)

		-- Neon edge (on bottom side for ceiling platforms)
		createPart(
			`CeilPlatEdge_{i}`,
			Vector3.new(platDef.size.X, 0.15, 0.3),
			Vector3.new(platDef.pos.X, platDef.pos.Y - platDef.size.Y / 2 - 0.1, platDef.pos.Z - platDef.size.Z / 2),
			theme.AccentColor,
			Enum.Material.Neon,
			plat
		)
	end

	-- Gravity zone (invisible, fills the room)
	local gravityZone = Instance.new("Part")
	gravityZone.Name = "GravityZone"
	gravityZone.Size = Vector3.new(roomWidth, roomHeight, roomLength)
	gravityZone.Position = Vector3.new(0, roomHeight / 2, baseZ + 10 + roomLength / 2)
	gravityZone.Anchored = true
	gravityZone.CanCollide = false
	gravityZone.Transparency = 1
	gravityZone.Parent = stageModel

	addBoolTag(gravityZone, "IsGravityFlip", true)
	addNumberValue(gravityZone, "FlipInterval", 10)

	-- Warning indicator lights (flash before gravity flips)
	local warningPositions = {
		Vector3.new(-roomWidth / 2 + 1, roomHeight / 2, baseZ + 15),
		Vector3.new(roomWidth / 2 - 1, roomHeight / 2, baseZ + 15),
		Vector3.new(-roomWidth / 2 + 1, roomHeight / 2, baseZ + 10 + roomLength - 5),
		Vector3.new(roomWidth / 2 - 1, roomHeight / 2, baseZ + 10 + roomLength - 5),
	}

	for i, warnPos in warningPositions do
		local warning = createPart(
			`GravityWarning_{i}`,
			Vector3.new(1, 1, 1),
			warnPos,
			Color3.fromRGB(255, 200, 0),
			Enum.Material.Neon,
			stageModel
		)
		warning.CanCollide = false
		warning.Shape = Enum.PartType.Ball
		addBoolTag(warning, "IsGravityWarning", true)
	end

	-- Mid-height obstacles that block both gravity directions
	createPart(
		"MidObstacle1",
		Vector3.new(roomWidth - 6, 2, 2),
		Vector3.new(-3, roomHeight / 2, baseZ + 28),
		Color3.fromRGB(20, 20, 35),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	createPart(
		"MidObstacle2",
		Vector3.new(roomWidth - 6, 2, 2),
		Vector3.new(3, roomHeight / 2, baseZ + 52),
		Color3.fromRGB(20, 20, 35),
		Enum.Material.SmoothPlastic,
		stageModel
	)
end

--[[
	Stage 29 - "The Clone Room"
	Mirrored room where the path splits into two halves. One side has the
	real exit, the other a fake exit with a wall behind it. A clone enemy
	spawns to pursue the player. Reflective walls give the mirrored feel.
]]
local function buildStage29(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local roomLength = 70
	local roomWidth = 30
	local wallHeight = 14
	local halfWidth = roomWidth / 2

	-- Central entry floor
	createPart(
		"EntryFloor",
		Vector3.new(roomWidth, 2, 15),
		Vector3.new(0, 0, baseZ + 15),
		Color3.fromRGB(8, 8, 18),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Center dividing wall (splits room into two mirrored halves)
	createPart(
		"CenterDivider",
		Vector3.new(2, wallHeight, roomLength - 20),
		Vector3.new(0, wallHeight / 2, baseZ + 30 + (roomLength - 20) / 2),
		Color3.fromRGB(10, 10, 20),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Neon stripe down center divider
	createPart(
		"DividerAccent",
		Vector3.new(0.3, wallHeight, roomLength - 20),
		Vector3.new(0, wallHeight / 2, baseZ + 30 + (roomLength - 20) / 2),
		theme.AccentColor,
		Enum.Material.Neon,
		stageModel
	)

	-- LEFT HALF (real exit side)
	createPart(
		"FloorLeft",
		Vector3.new(halfWidth - 2, 2, roomLength - 15),
		Vector3.new(-halfWidth / 2, 0, baseZ + 22 + (roomLength - 15) / 2),
		Color3.fromRGB(10, 10, 20),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Left side walls
	createPart(
		"OuterWallL",
		Vector3.new(2, wallHeight, roomLength),
		Vector3.new(-halfWidth - 1, wallHeight / 2, baseZ + 10 + roomLength / 2),
		Color3.fromRGB(30, 30, 50),
		Enum.Material.Glass,
		stageModel
	)

	-- Left side neon accent
	createPart(
		"OuterAccentL",
		Vector3.new(0.2, wallHeight, roomLength),
		Vector3.new(-halfWidth, wallHeight / 2, baseZ + 10 + roomLength / 2),
		theme.WallColor,
		Enum.Material.Neon,
		stageModel
	)

	-- Left path obstacles (small walls to navigate)
	createPart(
		"LeftObstacle1",
		Vector3.new(6, 6, 2),
		Vector3.new(-halfWidth / 2 + 3, 4, baseZ + 38),
		Color3.fromRGB(15, 15, 28),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	createPart(
		"LeftObstacle2",
		Vector3.new(6, 6, 2),
		Vector3.new(-halfWidth / 2 - 2, 4, baseZ + 52),
		Color3.fromRGB(15, 15, 28),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Real exit (left side) - the door frame with opening
	createPart(
		"RealExitFrameL",
		Vector3.new(4, wallHeight, 2),
		Vector3.new(-halfWidth / 2 - 4, wallHeight / 2, baseZ + 10 + roomLength - 3),
		Color3.fromRGB(12, 12, 24),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	createPart(
		"RealExitFrameR",
		Vector3.new(4, wallHeight, 2),
		Vector3.new(-halfWidth / 2 + 4, wallHeight / 2, baseZ + 10 + roomLength - 3),
		Color3.fromRGB(12, 12, 24),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	createPart(
		"RealExitFrameTop",
		Vector3.new(6, 3, 2),
		Vector3.new(-halfWidth / 2, wallHeight - 1.5, baseZ + 10 + roomLength - 3),
		Color3.fromRGB(12, 12, 24),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	-- Real exit neon trim
	createPart(
		"RealExitNeon",
		Vector3.new(6, 0.3, 0.3),
		Vector3.new(-halfWidth / 2, wallHeight - 3.2, baseZ + 10 + roomLength - 2),
		Color3.fromRGB(0, 255, 100),
		Enum.Material.Neon,
		stageModel
	)

	-- RIGHT HALF (fake exit side - mirrored)
	createPart(
		"FloorRight",
		Vector3.new(halfWidth - 2, 2, roomLength - 15),
		Vector3.new(halfWidth / 2, 0, baseZ + 22 + (roomLength - 15) / 2),
		Color3.fromRGB(10, 10, 20),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Right outer wall (reflective glass look)
	createPart(
		"OuterWallR",
		Vector3.new(2, wallHeight, roomLength),
		Vector3.new(halfWidth + 1, wallHeight / 2, baseZ + 10 + roomLength / 2),
		Color3.fromRGB(30, 30, 50),
		Enum.Material.Glass,
		stageModel
	)

	-- Right side neon accent
	createPart(
		"OuterAccentR",
		Vector3.new(0.2, wallHeight, roomLength),
		Vector3.new(halfWidth, wallHeight / 2, baseZ + 10 + roomLength / 2),
		theme.WallColor,
		Enum.Material.Neon,
		stageModel
	)

	-- Right path obstacles (mirrored from left)
	createPart(
		"RightObstacle1",
		Vector3.new(6, 6, 2),
		Vector3.new(halfWidth / 2 - 3, 4, baseZ + 38),
		Color3.fromRGB(15, 15, 28),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	createPart(
		"RightObstacle2",
		Vector3.new(6, 6, 2),
		Vector3.new(halfWidth / 2 + 2, 4, baseZ + 52),
		Color3.fromRGB(15, 15, 28),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Fake exit (right side) - looks the same but has a solid wall behind it
	createPart(
		"FakeExitFrameL",
		Vector3.new(4, wallHeight, 2),
		Vector3.new(halfWidth / 2 - 4, wallHeight / 2, baseZ + 10 + roomLength - 3),
		Color3.fromRGB(12, 12, 24),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	createPart(
		"FakeExitFrameR",
		Vector3.new(4, wallHeight, 2),
		Vector3.new(halfWidth / 2 + 4, wallHeight / 2, baseZ + 10 + roomLength - 3),
		Color3.fromRGB(12, 12, 24),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	createPart(
		"FakeExitFrameTop",
		Vector3.new(6, 3, 2),
		Vector3.new(halfWidth / 2, wallHeight - 1.5, baseZ + 10 + roomLength - 3),
		Color3.fromRGB(12, 12, 24),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	-- Fake exit neon trim (same green to deceive)
	createPart(
		"FakeExitNeon",
		Vector3.new(6, 0.3, 0.3),
		Vector3.new(halfWidth / 2, wallHeight - 3.2, baseZ + 10 + roomLength - 2),
		Color3.fromRGB(0, 255, 100),
		Enum.Material.Neon,
		stageModel
	)

	-- Hidden wall behind fake exit (blocks progress)
	local fakeWall = createPart(
		"FakeExitBlocker",
		Vector3.new(halfWidth - 2, wallHeight, 2),
		Vector3.new(halfWidth / 2, wallHeight / 2, baseZ + 10 + roomLength),
		Color3.fromRGB(8, 8, 18),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	addBoolTag(fakeWall, "IsFakeExit", true)

	-- Clone spawn point (in the center entry area)
	local cloneSpawn = Instance.new("Part")
	cloneSpawn.Name = "CloneSpawn"
	cloneSpawn.Size = Vector3.new(4, 6, 4)
	cloneSpawn.Position = Vector3.new(0, 4, baseZ + 26)
	cloneSpawn.Anchored = true
	cloneSpawn.CanCollide = false
	cloneSpawn.Transparency = 0.8
	cloneSpawn.Color = theme.AccentColor
	cloneSpawn.Material = Enum.Material.Neon
	cloneSpawn.Parent = stageModel

	addBoolTag(cloneSpawn, "IsCloneSpawn", true)

	-- Mirror-like panels on center divider (reflective glass strips)
	for i = 1, 5 do
		local mirrorZ = baseZ + 28 + i * 8
		-- Left-facing mirror
		createPart(
			`MirrorPanelL_{i}`,
			Vector3.new(0.3, 8, 5),
			Vector3.new(-1.2, wallHeight / 2, mirrorZ),
			Color3.fromRGB(40, 40, 70),
			Enum.Material.Glass,
			stageModel
		)
		-- Right-facing mirror
		createPart(
			`MirrorPanelR_{i}`,
			Vector3.new(0.3, 8, 5),
			Vector3.new(1.2, wallHeight / 2, mirrorZ),
			Color3.fromRGB(40, 40, 70),
			Enum.Material.Glass,
			stageModel
		)
	end

	-- Floor neon grid in both halves
	for i = 1, 6 do
		local gridZ = baseZ + 25 + i * 7
		createPart(
			`FloorGridL_{i}`,
			Vector3.new(halfWidth - 4, 0.05, 0.2),
			Vector3.new(-halfWidth / 2, 1.05, gridZ),
			theme.WallColor,
			Enum.Material.Neon,
			stageModel
		)
		createPart(
			`FloorGridR_{i}`,
			Vector3.new(halfWidth - 4, 0.05, 0.2),
			Vector3.new(halfWidth / 2, 1.05, gridZ),
			theme.WallColor,
			Enum.Material.Neon,
			stageModel
		)
	end
end

--[[
	Stage 30 - "The Speed Gate"
	Long runway (60 studs). A timed gate at the far end opens briefly when
	a trigger button near the start is activated. Player must draw a fast
	vehicle and race to the gate before it closes. Smooth neon floor.
]]
local function buildStage30(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local runwayLength = 60
	local runwayWidth = 14
	local wallHeight = 10

	-- Runway floor (smooth neon surface)
	createPart(
		"RunwayFloor",
		Vector3.new(runwayWidth, 2, runwayLength + 20),
		Vector3.new(0, 0, baseZ + 10 + (runwayLength + 20) / 2),
		Color3.fromRGB(10, 10, 25),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Neon center line (like a racing stripe)
	createPart(
		"CenterStripe",
		Vector3.new(0.5, 0.05, runwayLength + 10),
		Vector3.new(0, 1.05, baseZ + 15 + (runwayLength + 10) / 2),
		theme.WallColor,
		Enum.Material.Neon,
		stageModel
	)

	-- Dashed side lines
	for i = 1, 12 do
		local dashZ = baseZ + 14 + i * 5.5
		createPart(
			`DashL_{i}`,
			Vector3.new(0.3, 0.05, 3),
			Vector3.new(-runwayWidth / 2 + 1, 1.05, dashZ),
			theme.AccentColor,
			Enum.Material.Neon,
			stageModel
		)
		createPart(
			`DashR_{i}`,
			Vector3.new(0.3, 0.05, 3),
			Vector3.new(runwayWidth / 2 - 1, 1.05, dashZ),
			theme.AccentColor,
			Enum.Material.Neon,
			stageModel
		)
	end

	-- Side walls (low, with neon trim)
	createPart(
		"WallL",
		Vector3.new(2, wallHeight, runwayLength + 20),
		Vector3.new(-runwayWidth / 2 - 1, wallHeight / 2, baseZ + 10 + (runwayLength + 20) / 2),
		Color3.fromRGB(5, 5, 12),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	createPart(
		"WallR",
		Vector3.new(2, wallHeight, runwayLength + 20),
		Vector3.new(runwayWidth / 2 + 1, wallHeight / 2, baseZ + 10 + (runwayLength + 20) / 2),
		Color3.fromRGB(5, 5, 12),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Neon wall trims
	createPart(
		"WallTrimL",
		Vector3.new(0.2, 0.3, runwayLength + 20),
		Vector3.new(-runwayWidth / 2, 1.2, baseZ + 10 + (runwayLength + 20) / 2),
		theme.WallColor,
		Enum.Material.Neon,
		stageModel
	)
	createPart(
		"WallTrimR",
		Vector3.new(0.2, 0.3, runwayLength + 20),
		Vector3.new(runwayWidth / 2, 1.2, baseZ + 10 + (runwayLength + 20) / 2),
		theme.WallColor,
		Enum.Material.Neon,
		stageModel
	)

	-- Gate trigger button near the start of the runway
	local _triggerPlatform = createPart(
		"TriggerPlatform",
		Vector3.new(4, 0.5, 4),
		Vector3.new(0, 1.25, baseZ + 18),
		Color3.fromRGB(20, 20, 40),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	local trigger = createPart(
		"GateTrigger",
		Vector3.new(3, 1, 3),
		Vector3.new(0, 2, baseZ + 18),
		Color3.fromRGB(255, 50, 50),
		Enum.Material.Neon,
		stageModel
	)
	addBoolTag(trigger, "IsGateTrigger", true)

	-- Trigger activation zone (invisible, larger than the button for easier activation)
	local triggerZone = Instance.new("Part")
	triggerZone.Name = "TriggerZone"
	triggerZone.Size = Vector3.new(6, 6, 6)
	triggerZone.Position = Vector3.new(0, 4, baseZ + 18)
	triggerZone.Anchored = true
	triggerZone.CanCollide = false
	triggerZone.Transparency = 1
	triggerZone.Parent = stageModel
	addBoolTag(triggerZone, "IsTriggerZone", true)

	-- Countdown display frame above trigger (decorative)
	local displayFrame = createPart(
		"CountdownDisplay",
		Vector3.new(4, 2, 0.5),
		Vector3.new(0, 6, baseZ + 18),
		Color3.fromRGB(15, 15, 30),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Neon border on display
	local displayBorder = createPart(
		"DisplayBorder",
		Vector3.new(4.4, 2.4, 0.3),
		Vector3.new(0, 6, baseZ + 17.8),
		theme.WallColor,
		Enum.Material.Neon,
		stageModel
	)
	displayBorder.CanCollide = false

	-- BillboardGui on the display for timer text
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(120, 60)
	billboard.StudsOffset = Vector3.new(0, 0, -0.5)
	billboard.AlwaysOnTop = false
	billboard.Parent = displayFrame

	local timerLabel = Instance.new("TextLabel")
	timerLabel.Size = UDim2.fromScale(1, 1)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "PRESS"
	timerLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	timerLabel.TextSize = 28
	timerLabel.Font = Enum.Font.SciFi
	timerLabel.TextStrokeTransparency = 0.5
	timerLabel.Parent = billboard

	-- Timed gate at far end of runway
	local _gateFrameLeft = createPart(
		"GateFrameL",
		Vector3.new(3, wallHeight + 4, 3),
		Vector3.new(-runwayWidth / 2 + 1, (wallHeight + 4) / 2, baseZ + 10 + runwayLength + 5),
		Color3.fromRGB(15, 15, 30),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	local _gateFrameRight = createPart(
		"GateFrameR",
		Vector3.new(3, wallHeight + 4, 3),
		Vector3.new(runwayWidth / 2 - 1, (wallHeight + 4) / 2, baseZ + 10 + runwayLength + 5),
		Color3.fromRGB(15, 15, 30),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	local _gateFrameTop = createPart(
		"GateFrameTop",
		Vector3.new(runwayWidth, 3, 3),
		Vector3.new(0, wallHeight + 2.5, baseZ + 10 + runwayLength + 5),
		Color3.fromRGB(15, 15, 30),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Neon outline on gate frame
	createPart(
		"GateNeonL",
		Vector3.new(0.3, wallHeight + 4, 0.3),
		Vector3.new(-runwayWidth / 2 + 2.5, (wallHeight + 4) / 2, baseZ + 10 + runwayLength + 3.3),
		Color3.fromRGB(255, 50, 50),
		Enum.Material.Neon,
		stageModel
	)
	createPart(
		"GateNeonR",
		Vector3.new(0.3, wallHeight + 4, 0.3),
		Vector3.new(runwayWidth / 2 - 2.5, (wallHeight + 4) / 2, baseZ + 10 + runwayLength + 3.3),
		Color3.fromRGB(255, 50, 50),
		Enum.Material.Neon,
		stageModel
	)
	createPart(
		"GateNeonTop",
		Vector3.new(runwayWidth - 4, 0.3, 0.3),
		Vector3.new(0, wallHeight + 1, baseZ + 10 + runwayLength + 3.3),
		Color3.fromRGB(255, 50, 50),
		Enum.Material.Neon,
		stageModel
	)

	-- The actual gate (solid, blocks passage until opened)
	local gate = createPart(
		"SpeedGate",
		Vector3.new(runwayWidth - 4, wallHeight, 2),
		Vector3.new(0, wallHeight / 2, baseZ + 10 + runwayLength + 5),
		Color3.fromRGB(200, 30, 30),
		Enum.Material.Neon,
		stageModel
	)
	gate.Transparency = 0.3
	addBoolTag(gate, "IsTimedGate", true)
	addNumberValue(gate, "OpenDuration", 3)

	-- Walls blocking sides of the gate (so player must go through it)
	createPart(
		"GateBlockL",
		Vector3.new(3, wallHeight + 4, 4),
		Vector3.new(-runwayWidth / 2 - 0.5, (wallHeight + 4) / 2, baseZ + 10 + runwayLength + 5),
		Color3.fromRGB(5, 5, 12),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	createPart(
		"GateBlockR",
		Vector3.new(3, wallHeight + 4, 4),
		Vector3.new(runwayWidth / 2 + 0.5, (wallHeight + 4) / 2, baseZ + 10 + runwayLength + 5),
		Color3.fromRGB(5, 5, 12),
		Enum.Material.SmoothPlastic,
		stageModel
	)

	-- Speed boost visual markers on the runway (chevron-like patterns)
	for i = 1, 8 do
		local chevronZ = baseZ + 22 + i * 7
		createPart(
			`SpeedChevronL_{i}`,
			Vector3.new(3, 0.05, 0.4),
			Vector3.new(-2, 1.05, chevronZ),
			Color3.fromRGB(100, 200, 255),
			Enum.Material.Neon,
			stageModel
		)
		createPart(
			`SpeedChevronR_{i}`,
			Vector3.new(3, 0.05, 0.4),
			Vector3.new(2, 1.05, chevronZ),
			Color3.fromRGB(100, 200, 255),
			Enum.Material.Neon,
			stageModel
		)
	end

	-- End platform beyond the gate
	createPart(
		"GateEndPlatform",
		Vector3.new(runwayWidth, 2, 10),
		Vector3.new(0, 0, baseZ + 10 + runwayLength + 12),
		Color3.fromRGB(10, 10, 25),
		Enum.Material.SmoothPlastic,
		stageModel
	)
end

-- ================================================================
-- EXPORT BUILDERS TABLE
-- ================================================================

ZoneBuilders.Builders = {
	-- Zone 5: The Ink Ruins
	[21] = buildStage21, -- The Crumbling Floor
	[22] = buildStage22, -- The Sentry Statues
	[23] = buildStage23, -- The Pendulum Hall
	[24] = buildStage24, -- The Puzzle Lock
	[25] = buildStage25, -- The Collapsing Bridge

	-- Zone 6: The Neon Grid
	[26] = buildStage26, -- The Laser Grid
	[27] = buildStage27, -- The Conveyor
	[28] = buildStage28, -- The Gravity Flip
	[29] = buildStage29, -- The Clone Room
	[30] = buildStage30, -- The Speed Gate
}

return ZoneBuilders
