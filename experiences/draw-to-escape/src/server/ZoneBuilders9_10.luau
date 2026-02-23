--!strict

--[[
	ZoneBuilders9_10
	Stage geometry builders for Zone 9 (The Void) and Zone 10 (The Cliff).
	Stages 41-50: The climax of the game.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneThemes = require(ReplicatedStorage.Shared.ZoneThemes)

local ZoneBuilders9_10 = {}

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

-- ================================================================
-- ZONE 9: THE VOID
-- Empty space, floating fragments, no ground, minimal, eerie.
-- ================================================================

--[[
	Stage 41 - "The First Step"
	NOTHING exists except a tiny start platform and the end platform 80 studs away.
	Complete void between them. Kill zone far below.
	Player must draw their own floor.
]]
local function buildStage41(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Tiny start platform - the only solid ground
	createPart(
		"StartIsland",
		Vector3.new(4, 1, 4),
		Vector3.new(0, 0, baseZ + 10),
		theme.AccentColor,
		Enum.Material.ForceField,
		stageModel
	)

	-- End platform 80 studs away across the void
	createPart(
		"EndIsland",
		Vector3.new(6, 1, 6),
		Vector3.new(0, 0, baseZ + 90),
		theme.AccentColor,
		Enum.Material.ForceField,
		stageModel
	)

	-- Kill zone far below in the void
	local killZone = Instance.new("Part")
	killZone.Name = "VoidKillZone"
	killZone.Size = Vector3.new(100, 2, 120)
	killZone.Position = Vector3.new(0, -80, baseZ + 50)
	killZone.Anchored = true
	killZone.CanCollide = false
	killZone.Transparency = 1
	killZone.Parent = stageModel

	local killTag = Instance.new("BoolValue")
	killTag.Name = "IsKillZone"
	killTag.Value = true
	killTag.Parent = killZone

	-- Atmospheric floating fragments (non-collidable, transparent, eerie)
	local fragmentPositions = {
		Vector3.new(-15, -10, baseZ + 30),
		Vector3.new(12, 8, baseZ + 45),
		Vector3.new(-8, -20, baseZ + 60),
		Vector3.new(20, 5, baseZ + 25),
		Vector3.new(-18, -15, baseZ + 75),
		Vector3.new(10, -25, baseZ + 50),
		Vector3.new(-5, 15, baseZ + 70),
		Vector3.new(16, -8, baseZ + 38),
	}

	for i, pos in fragmentPositions do
		local fragment = Instance.new("Part")
		fragment.Name = `VoidFragment_{i}`
		fragment.Size = Vector3.new(math.random(1, 3), math.random(1, 2), math.random(1, 3))
		fragment.Position = pos
		fragment.Anchored = true
		fragment.CanCollide = false
		fragment.Transparency = 0.6
		fragment.Material = Enum.Material.ForceField
		fragment.Color = theme.AccentColor
		fragment.TopSurface = Enum.SurfaceType.Smooth
		fragment.BottomSurface = Enum.SurfaceType.Smooth
		fragment.Parent = stageModel
	end
end

--[[
	Stage 42 - "The Orbit"
	Central anchor sphere with platforms orbiting around it.
	End platform outside the orbit ring.
]]
local function buildStage42(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local centerX = 0
	local centerY = 5
	local centerZ = baseZ + 50

	-- Start platform
	createPart(
		"StartIsland",
		Vector3.new(6, 1, 6),
		Vector3.new(-30, 0, centerZ),
		theme.AccentColor,
		Enum.Material.ForceField,
		stageModel
	)

	-- Central anchor sphere (large, glowing)
	local anchor = Instance.new("Part")
	anchor.Name = "OrbitalAnchor"
	anchor.Shape = Enum.PartType.Ball
	anchor.Size = Vector3.new(10, 10, 10)
	anchor.Position = Vector3.new(centerX, centerY, centerZ)
	anchor.Anchored = true
	anchor.CanCollide = true
	anchor.Material = Enum.Material.ForceField
	anchor.Color = theme.AccentColor
	anchor.TopSurface = Enum.SurfaceType.Smooth
	anchor.BottomSurface = Enum.SurfaceType.Smooth
	anchor.Parent = stageModel

	-- Orbiting platforms arranged in a circle (radius ~20 studs)
	local orbitRadius = 20
	local platformCount = 8
	for i = 1, platformCount do
		local angle = (i - 1) * (2 * math.pi / platformCount)
		local px = centerX + math.cos(angle) * orbitRadius
		local pz = centerZ + math.sin(angle) * orbitRadius

		local orbitPlatform = createPart(
			`OrbitPlatform_{i}`,
			Vector3.new(3, 1, 3),
			Vector3.new(px, 0, pz),
			theme.WallColor,
			Enum.Material.ForceField,
			stageModel
		)

		local isOrbiting = Instance.new("BoolValue")
		isOrbiting.Name = "IsOrbiting"
		isOrbiting.Value = true
		isOrbiting.Parent = orbitPlatform

		local orbitSpeed = Instance.new("NumberValue")
		orbitSpeed.Name = "OrbitSpeed"
		orbitSpeed.Value = 0.5 + (i % 3) * 0.3
		orbitSpeed.Parent = orbitPlatform
	end

	-- End platform outside the orbit ring
	createPart(
		"EndIsland",
		Vector3.new(8, 1, 8),
		Vector3.new(30, 0, centerZ),
		theme.AccentColor,
		Enum.Material.ForceField,
		stageModel
	)

	-- Void kill zone
	local killZone = Instance.new("Part")
	killZone.Name = "VoidKillZone"
	killZone.Size = Vector3.new(120, 2, 120)
	killZone.Position = Vector3.new(0, -80, centerZ)
	killZone.Anchored = true
	killZone.CanCollide = false
	killZone.Transparency = 1
	killZone.Parent = stageModel

	local killTag = Instance.new("BoolValue")
	killTag.Name = "IsKillZone"
	killTag.Value = true
	killTag.Parent = killZone
end

--[[
	Stage 43 - "The Gravity Wells"
	Floating zigzag path of platforms with gaps.
	Gravity well spheres pull drawings off course.
]]
local function buildStage43(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Start platform
	createPart(
		"StartIsland",
		Vector3.new(6, 1, 6),
		Vector3.new(-20, 0, baseZ + 10),
		theme.AccentColor,
		Enum.Material.ForceField,
		stageModel
	)

	-- Zigzag platforms with gaps between them
	local zigzagPlatforms = {
		{ pos = Vector3.new(-12, 2, baseZ + 25), size = Vector3.new(5, 1, 5) },
		{ pos = Vector3.new(5, 4, baseZ + 35), size = Vector3.new(4, 1, 4) },
		{ pos = Vector3.new(-8, 6, baseZ + 48), size = Vector3.new(5, 1, 5) },
		{ pos = Vector3.new(10, 3, baseZ + 58), size = Vector3.new(4, 1, 4) },
		{ pos = Vector3.new(-5, 5, baseZ + 70), size = Vector3.new(5, 1, 5) },
		{ pos = Vector3.new(8, 7, baseZ + 82), size = Vector3.new(4, 1, 4) },
		{ pos = Vector3.new(-10, 2, baseZ + 92), size = Vector3.new(5, 1, 5) },
	}

	for i, plat in zigzagPlatforms do
		createPart(`ZigzagPlatform_{i}`, plat.size, plat.pos, theme.WallColor, Enum.Material.ForceField, stageModel)
	end

	-- Gravity wells scattered among the path
	local gravityWells = {
		{ pos = Vector3.new(-3, 5, baseZ + 30), pull = 40 },
		{ pos = Vector3.new(8, 3, baseZ + 45), pull = 55 },
		{ pos = Vector3.new(-12, 6, baseZ + 60), pull = 45 },
		{ pos = Vector3.new(3, 4, baseZ + 75), pull = 60 },
		{ pos = Vector3.new(-6, 8, baseZ + 88), pull = 50 },
	}

	for i, well in gravityWells do
		local wellPart = Instance.new("Part")
		wellPart.Name = `GravityWell_{i}`
		wellPart.Shape = Enum.PartType.Ball
		wellPart.Size = Vector3.new(8, 8, 8)
		wellPart.Position = well.pos
		wellPart.Anchored = true
		wellPart.CanCollide = false
		wellPart.Transparency = 0.5
		wellPart.Material = Enum.Material.ForceField
		wellPart.Color = Color3.fromRGB(80, 40, 200)
		wellPart.TopSurface = Enum.SurfaceType.Smooth
		wellPart.BottomSurface = Enum.SurfaceType.Smooth
		wellPart.Parent = stageModel

		local isGravityWell = Instance.new("BoolValue")
		isGravityWell.Name = "IsGravityWell"
		isGravityWell.Value = true
		isGravityWell.Parent = wellPart

		local pullStrength = Instance.new("NumberValue")
		pullStrength.Name = "PullStrength"
		pullStrength.Value = well.pull
		pullStrength.Parent = wellPart
	end

	-- End platform
	createPart(
		"EndIsland",
		Vector3.new(6, 1, 6),
		Vector3.new(15, 0, baseZ + 105),
		theme.AccentColor,
		Enum.Material.ForceField,
		stageModel
	)

	-- Void kill zone
	local killZone = Instance.new("Part")
	killZone.Name = "VoidKillZone"
	killZone.Size = Vector3.new(120, 2, 140)
	killZone.Position = Vector3.new(0, -80, baseZ + 55)
	killZone.Anchored = true
	killZone.CanCollide = false
	killZone.Transparency = 1
	killZone.Parent = stageModel

	local killTag = Instance.new("BoolValue")
	killTag.Name = "IsKillZone"
	killTag.Value = true
	killTag.Parent = killZone
end

--[[
	Stage 44 - "The Invisible Maze"
	Floor exists but is dark and nearly transparent.
	Walls are INVISIBLE (Transparency=1, CanCollide=true).
	5x5 grid maze. Player throws drawings to find walls.
]]
local function buildStage44(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local mazeOriginX = -20
	local mazeOriginZ = baseZ + 15
	local cellSize = 8
	local wallHeight = 10
	local wallThickness = 1
	local gridSize = 5

	-- Nearly invisible floor (very dark, nearly transparent)
	createPart(
		"MazeFloor",
		Vector3.new(cellSize * gridSize + 4, 1, cellSize * gridSize + 4),
		Vector3.new(mazeOriginX + (cellSize * gridSize) / 2, -0.5, mazeOriginZ + (cellSize * gridSize) / 2),
		Color3.fromRGB(5, 5, 15),
		Enum.Material.ForceField,
		stageModel
	).Transparency =
		0.8

	-- Start platform (outside maze entrance)
	createPart(
		"StartIsland",
		Vector3.new(6, 1, 6),
		Vector3.new(mazeOriginX + cellSize / 2, 0, mazeOriginZ - 5),
		theme.AccentColor,
		Enum.Material.ForceField,
		stageModel
	)

	-- End platform (outside maze exit)
	createPart(
		"EndIsland",
		Vector3.new(6, 1, 6),
		Vector3.new(mazeOriginX + cellSize * (gridSize - 1) + cellSize / 2, 0, mazeOriginZ + cellSize * gridSize + 5),
		theme.AccentColor,
		Enum.Material.ForceField,
		stageModel
	)

	--[[
		Maze layout (5x5 grid, 1 = wall on right edge, 2 = wall on bottom edge, 3 = both)
		The maze is defined by which cell edges have walls.
		We place walls between cells to form corridors.

		Simple maze (S=start at top-left, E=exit at bottom-right):
		+--+--+--+--+--+
		|S       |     |
		+  +--+  +  +  +
		|  |     |  |  |
		+  +  +--+  +--+
		|     |        |
		+--+  +  +--+  +
		|     |  |     |
		+  +--+  +  +  +
		|           | E|
		+--+--+--+--+--+
	]]

	-- Outer boundary walls (invisible)
	local wallIndex = 0

	-- Top boundary
	local topWall = Instance.new("Part")
	topWall.Name = `InvisibleWall_{wallIndex}`
	wallIndex += 1
	topWall.Size = Vector3.new(cellSize * gridSize + wallThickness, wallHeight, wallThickness)
	topWall.Position = Vector3.new(mazeOriginX + (cellSize * gridSize) / 2, wallHeight / 2, mazeOriginZ)
	topWall.Anchored = true
	topWall.CanCollide = true
	topWall.Transparency = 1
	topWall.Parent = stageModel

	-- Bottom boundary
	local bottomWall = Instance.new("Part")
	bottomWall.Name = `InvisibleWall_{wallIndex}`
	wallIndex += 1
	bottomWall.Size = Vector3.new(cellSize * gridSize + wallThickness, wallHeight, wallThickness)
	bottomWall.Position =
		Vector3.new(mazeOriginX + (cellSize * gridSize) / 2, wallHeight / 2, mazeOriginZ + cellSize * gridSize)
	bottomWall.Anchored = true
	bottomWall.CanCollide = true
	bottomWall.Transparency = 1
	bottomWall.Parent = stageModel

	-- Left boundary
	local leftWall = Instance.new("Part")
	leftWall.Name = `InvisibleWall_{wallIndex}`
	wallIndex += 1
	leftWall.Size = Vector3.new(wallThickness, wallHeight, cellSize * gridSize + wallThickness)
	leftWall.Position = Vector3.new(mazeOriginX, wallHeight / 2, mazeOriginZ + (cellSize * gridSize) / 2)
	leftWall.Anchored = true
	leftWall.CanCollide = true
	leftWall.Transparency = 1
	leftWall.Parent = stageModel

	-- Right boundary
	local rightWall = Instance.new("Part")
	rightWall.Name = `InvisibleWall_{wallIndex}`
	wallIndex += 1
	rightWall.Size = Vector3.new(wallThickness, wallHeight, cellSize * gridSize + wallThickness)
	rightWall.Position =
		Vector3.new(mazeOriginX + cellSize * gridSize, wallHeight / 2, mazeOriginZ + (cellSize * gridSize) / 2)
	rightWall.Anchored = true
	rightWall.CanCollide = true
	rightWall.Transparency = 1
	rightWall.Parent = stageModel

	-- Internal walls: defined as segments {startRow, startCol, orientation, length}
	-- orientation: "h" = horizontal (along X), "v" = vertical (along Z)
	-- Coordinates are cell edges (0-indexed from top-left)
	local internalWalls = {
		-- Horizontal walls (block Z movement)
		{ row = 1, colStart = 0, colEnd = 1 }, -- row 1, col 0-1
		{ row = 1, colStart = 2, colEnd = 3 }, -- row 1, col 2-3
		{ row = 2, colStart = 1, colEnd = 2 }, -- row 2, col 1-2
		{ row = 2, colStart = 4, colEnd = 5 }, -- row 2, col 4-5 (right edge)
		{ row = 3, colStart = 0, colEnd = 1 }, -- row 3, col 0-1
		{ row = 3, colStart = 3, colEnd = 4 }, -- row 3, col 3-4
		{ row = 4, colStart = 1, colEnd = 2 }, -- row 4, col 1-2
		{ row = 4, colStart = 3, colEnd = 4 }, -- row 4, col 3-4 (near exit)
	}

	for _, wall in internalWalls do
		local wallPart = Instance.new("Part")
		wallPart.Name = `InvisibleWall_{wallIndex}`
		wallIndex += 1
		local wallLength = (wall.colEnd - wall.colStart) * cellSize
		wallPart.Size = Vector3.new(wallLength, wallHeight, wallThickness)
		wallPart.Position = Vector3.new(
			mazeOriginX + (wall.colStart + wall.colEnd) / 2 * cellSize,
			wallHeight / 2,
			mazeOriginZ + wall.row * cellSize
		)
		wallPart.Anchored = true
		wallPart.CanCollide = true
		wallPart.Transparency = 1
		wallPart.Parent = stageModel
	end

	-- Vertical internal walls (block X movement)
	local verticalWalls = {
		{ col = 1, rowStart = 1, rowEnd = 2 },
		{ col = 2, rowStart = 2, rowEnd = 3 },
		{ col = 3, rowStart = 0, rowEnd = 1 },
		{ col = 3, rowStart = 1, rowEnd = 2 },
		{ col = 4, rowStart = 1, rowEnd = 2 },
		{ col = 2, rowStart = 3, rowEnd = 4 },
		{ col = 3, rowStart = 3, rowEnd = 4 },
		{ col = 4, rowStart = 4, rowEnd = 5 },
	}

	for _, wall in verticalWalls do
		local wallPart = Instance.new("Part")
		wallPart.Name = `InvisibleWall_{wallIndex}`
		wallIndex += 1
		local wallLength = (wall.rowEnd - wall.rowStart) * cellSize
		wallPart.Size = Vector3.new(wallThickness, wallHeight, wallLength)
		wallPart.Position = Vector3.new(
			mazeOriginX + wall.col * cellSize,
			wallHeight / 2,
			mazeOriginZ + (wall.rowStart + wall.rowEnd) / 2 * cellSize
		)
		wallPart.Anchored = true
		wallPart.CanCollide = true
		wallPart.Transparency = 1
		wallPart.Parent = stageModel
	end
end

--[[
	Stage 45 - "The Platform Relay"
	Start platform, then 12 tiny platforms spaced 8 studs apart in a line.
	Each has a despawn timer. Player must chain-draw while jumping.
]]
local function buildStage45(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Start platform
	createPart(
		"StartIsland",
		Vector3.new(6, 1, 6),
		Vector3.new(0, 0, baseZ + 10),
		theme.AccentColor,
		Enum.Material.ForceField,
		stageModel
	)

	-- 12 tiny relay platforms in a line
	local platformSpacing = 8
	local startZ = baseZ + 22
	for i = 1, 12 do
		local relayPlatform = createPart(
			`RelayPlatform_{i}`,
			Vector3.new(2, 0.5, 2),
			Vector3.new(0, 0, startZ + (i - 1) * platformSpacing),
			theme.WallColor,
			Enum.Material.ForceField,
			stageModel
		)

		local isDespawning = Instance.new("BoolValue")
		isDespawning.Name = "IsDespawning"
		isDespawning.Value = true
		isDespawning.Parent = relayPlatform

		local despawnDelay = Instance.new("NumberValue")
		despawnDelay.Name = "DespawnDelay"
		despawnDelay.Value = 3
		despawnDelay.Parent = relayPlatform
	end

	-- End platform at the far side
	createPart(
		"EndIsland",
		Vector3.new(8, 1, 8),
		Vector3.new(0, 0, startZ + 12 * platformSpacing + 6),
		theme.AccentColor,
		Enum.Material.ForceField,
		stageModel
	)

	-- Void kill zone
	local killZone = Instance.new("Part")
	killZone.Name = "VoidKillZone"
	killZone.Size = Vector3.new(80, 2, 140)
	killZone.Position = Vector3.new(0, -80, baseZ + 60)
	killZone.Anchored = true
	killZone.CanCollide = false
	killZone.Transparency = 1
	killZone.Parent = stageModel

	local killTag = Instance.new("BoolValue")
	killTag.Name = "IsKillZone"
	killTag.Value = true
	killTag.Parent = killZone
end

-- ================================================================
-- ZONE 10: THE CLIFF
-- Epic finale. Massive vertical cliff. Stormy. Everything combined.
-- ================================================================

--[[
	Stage 46 - "The Base"
	The iconic cliff begins. Massive cliff wall (80 wide, 100 tall).
	Start at the bottom. Footholds on the face. Crumbling rocks.
	End platform at ~30 studs height.
]]
local function buildStage46(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local cliffX = 0
	local cliffZ = baseZ + 60

	-- THE CLIFF WALL - massive, imposing, 80 wide x 100 tall x 12 deep
	createPart(
		"CliffWall",
		Vector3.new(80, 100, 12),
		Vector3.new(cliffX, 50, cliffZ),
		Color3.fromRGB(55, 50, 60),
		Enum.Material.Rock,
		stageModel
	)

	-- Start platform at the bottom of the cliff
	createPart(
		"StartPlatform",
		Vector3.new(20, 2, 16),
		Vector3.new(cliffX, 0, cliffZ - 20),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Ground area at the base of the cliff
	createPart(
		"CliffBase",
		Vector3.new(80, 2, 20),
		Vector3.new(cliffX, 0, cliffZ - 16),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Small footholds on the cliff face (jutting out from the wall)
	local footholds = {
		{ pos = Vector3.new(-15, 5, cliffZ - 7), size = Vector3.new(4, 1, 3) },
		{ pos = Vector3.new(10, 8, cliffZ - 7), size = Vector3.new(3, 1, 3) },
		{ pos = Vector3.new(-5, 12, cliffZ - 7), size = Vector3.new(3, 1, 2) },
		{ pos = Vector3.new(20, 15, cliffZ - 7), size = Vector3.new(4, 1, 3) },
		{ pos = Vector3.new(-20, 18, cliffZ - 7), size = Vector3.new(3, 1, 2) },
		{ pos = Vector3.new(5, 22, cliffZ - 7), size = Vector3.new(3, 1, 3) },
		{ pos = Vector3.new(-10, 26, cliffZ - 7), size = Vector3.new(4, 1, 2) },
	}

	for i, foothold in footholds do
		createPart(
			`Foothold_{i}`,
			foothold.size,
			foothold.pos,
			Color3.fromRGB(70, 65, 72),
			Enum.Material.Rock,
			stageModel
		)
	end

	-- First ledge at 15 studs up
	createPart(
		"FirstLedge",
		Vector3.new(16, 2, 6),
		Vector3.new(cliffX, 15, cliffZ - 9),
		Color3.fromRGB(65, 60, 68),
		Enum.Material.Rock,
		stageModel
	)

	-- Crumbling rocks that break away when stepped on
	local crumblingRocks = {
		Vector3.new(-12, 10, cliffZ - 8),
		Vector3.new(8, 20, cliffZ - 8),
		Vector3.new(-18, 24, cliffZ - 8),
		Vector3.new(15, 28, cliffZ - 8),
	}

	for i, pos in crumblingRocks do
		local crumble = createPart(
			`CrumblingRock_{i}`,
			Vector3.new(5, 1.5, 4),
			pos,
			Color3.fromRGB(80, 70, 75),
			Enum.Material.Rock,
			stageModel
		)

		local isUnstable = Instance.new("BoolValue")
		isUnstable.Name = "IsUnstable"
		isUnstable.Value = true
		isUnstable.Parent = crumble
	end

	-- End platform at ~30 studs height
	createPart(
		"EndPlatformCliff",
		Vector3.new(14, 2, 10),
		Vector3.new(cliffX, 30, cliffZ - 12),
		Color3.fromRGB(80, 200, 80),
		Enum.Material.Neon,
		stageModel
	)

	-- Kill zone at the bottom
	local killZone = Instance.new("Part")
	killZone.Name = "CliffKillZone"
	killZone.Size = Vector3.new(120, 2, 80)
	killZone.Position = Vector3.new(cliffX, -20, cliffZ)
	killZone.Anchored = true
	killZone.CanCollide = false
	killZone.Transparency = 1
	killZone.Parent = stageModel

	local killTag = Instance.new("BoolValue")
	killTag.Name = "IsKillZone"
	killTag.Value = true
	killTag.Parent = killZone
end

--[[
	Stage 47 - "The Overhang"
	Cliff wall continues but juts outward creating an inverted section.
	Metal anchor points on the overhang. Start at 30 studs, end at 60 studs height.
]]
local function buildStage47(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local cliffX = 0
	local cliffZ = baseZ + 60

	-- Lower cliff wall section (30-50 studs, straight)
	createPart(
		"CliffWallLower",
		Vector3.new(80, 20, 12),
		Vector3.new(cliffX, 40, cliffZ),
		Color3.fromRGB(55, 50, 60),
		Enum.Material.Rock,
		stageModel
	)

	-- Overhang section: the cliff juts OUT over the player
	-- This is an angled slab that extends outward from the cliff face
	local overhang = Instance.new("Part")
	overhang.Name = "OverhangSlab"
	overhang.Size = Vector3.new(60, 4, 30)
	-- Rotated so it angles outward from the wall, creating an inverted ceiling
	overhang.CFrame = CFrame.new(cliffX, 52, cliffZ - 14) * CFrame.Angles(math.rad(-30), 0, 0)
	overhang.Anchored = true
	overhang.CanCollide = true
	overhang.Material = Enum.Material.Rock
	overhang.Color = Color3.fromRGB(50, 45, 55)
	overhang.TopSurface = Enum.SurfaceType.Smooth
	overhang.BottomSurface = Enum.SurfaceType.Smooth
	overhang.Parent = stageModel

	-- Upper cliff wall section (above the overhang, 55-100 studs)
	createPart(
		"CliffWallUpper",
		Vector3.new(80, 50, 12),
		Vector3.new(cliffX, 80, cliffZ),
		Color3.fromRGB(55, 50, 60),
		Enum.Material.Rock,
		stageModel
	)

	-- Start platform at 30 studs height (on a ledge)
	createPart(
		"StartLedge",
		Vector3.new(14, 2, 10),
		Vector3.new(cliffX, 30, cliffZ - 12),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Metal anchor points on the underside of the overhang
	-- Players can attach drawings to these to traverse underneath
	local anchorPositions = {
		Vector3.new(-20, 48, cliffZ - 18),
		Vector3.new(-8, 50, cliffZ - 22),
		Vector3.new(5, 49, cliffZ - 20),
		Vector3.new(15, 51, cliffZ - 24),
		Vector3.new(25, 50, cliffZ - 19),
		Vector3.new(-15, 52, cliffZ - 26),
		Vector3.new(10, 53, cliffZ - 28),
	}

	for i, pos in anchorPositions do
		local anchor = createPart(
			`MetalAnchor_{i}`,
			Vector3.new(2, 2, 2),
			pos,
			Color3.fromRGB(160, 160, 170),
			Enum.Material.Metal,
			stageModel
		)

		-- Magnetic tag for magnet material interaction
		local isMagnetic = Instance.new("BoolValue")
		isMagnetic.Name = "IsMagnetic"
		isMagnetic.Value = true
		isMagnetic.Parent = anchor
	end

	-- Side footholds on the cliff face near the overhang
	local sideHolds = {
		Vector3.new(-25, 35, cliffZ - 7),
		Vector3.new(22, 38, cliffZ - 7),
		Vector3.new(-18, 42, cliffZ - 7),
		Vector3.new(28, 45, cliffZ - 7),
	}

	for i, pos in sideHolds do
		createPart(
			`SideFoothold_{i}`,
			Vector3.new(3, 1, 3),
			pos,
			Color3.fromRGB(65, 60, 68),
			Enum.Material.Rock,
			stageModel
		)
	end

	-- End platform at ~60 studs height (above the overhang)
	createPart(
		"EndPlatformCliff",
		Vector3.new(14, 2, 10),
		Vector3.new(cliffX, 60, cliffZ - 12),
		Color3.fromRGB(80, 200, 80),
		Enum.Material.Neon,
		stageModel
	)

	-- Kill zone far below
	local killZone = Instance.new("Part")
	killZone.Name = "CliffKillZone"
	killZone.Size = Vector3.new(120, 2, 100)
	killZone.Position = Vector3.new(cliffX, -20, cliffZ)
	killZone.Anchored = true
	killZone.CanCollide = false
	killZone.Transparency = 1
	killZone.Parent = stageModel

	local killTag = Instance.new("BoolValue")
	killTag.Name = "IsKillZone"
	killTag.Value = true
	killTag.Parent = killZone
end

--[[
	Stage 48 - "The Nest"
	Cliff continues upward (60-80 studs).
	Large nest structure made of Wood parts arranged in a bowl shape.
	Bird enemy spawns. Drawing a nest befriends them.
]]
local function buildStage48(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local cliffX = 0
	local cliffZ = baseZ + 60

	-- Cliff wall section (60-100 studs)
	createPart(
		"CliffWall",
		Vector3.new(80, 50, 12),
		Vector3.new(cliffX, 85, cliffZ),
		Color3.fromRGB(55, 50, 60),
		Enum.Material.Rock,
		stageModel
	)

	-- Start ledge at 60 studs
	createPart(
		"StartLedge",
		Vector3.new(14, 2, 10),
		Vector3.new(cliffX, 60, cliffZ - 12),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Intermediate footholds climbing up to nest height
	local climbHolds = {
		Vector3.new(-15, 63, cliffZ - 8),
		Vector3.new(10, 66, cliffZ - 8),
		Vector3.new(-8, 69, cliffZ - 8),
		Vector3.new(18, 72, cliffZ - 8),
	}

	for i, pos in climbHolds do
		createPart(
			`ClimbHold_{i}`,
			Vector3.new(3, 1, 3),
			pos,
			Color3.fromRGB(70, 65, 72),
			Enum.Material.Rock,
			stageModel
		)
	end

	-- THE NEST - Large bowl shape made of wood parts at ~75 studs height
	-- Nest base (wide bottom of the bowl)
	local nestCenterX = 20
	local nestCenterY = 74
	local nestCenterZ = cliffZ - 18

	createPart(
		"NestBase",
		Vector3.new(18, 2, 18),
		Vector3.new(nestCenterX, nestCenterY, nestCenterZ),
		Color3.fromRGB(140, 100, 50),
		Enum.Material.Wood,
		stageModel
	)

	-- Nest rim pieces (angled outward to form a bowl shape)
	-- Front rim
	local frontRim = Instance.new("Part")
	frontRim.Name = "NestRim_Front"
	frontRim.Size = Vector3.new(20, 2, 4)
	frontRim.CFrame = CFrame.new(nestCenterX, nestCenterY + 2, nestCenterZ - 10) * CFrame.Angles(math.rad(25), 0, 0)
	frontRim.Anchored = true
	frontRim.CanCollide = true
	frontRim.Material = Enum.Material.Wood
	frontRim.Color = Color3.fromRGB(130, 90, 45)
	frontRim.TopSurface = Enum.SurfaceType.Smooth
	frontRim.BottomSurface = Enum.SurfaceType.Smooth
	frontRim.Parent = stageModel

	-- Back rim
	local backRim = Instance.new("Part")
	backRim.Name = "NestRim_Back"
	backRim.Size = Vector3.new(20, 2, 4)
	backRim.CFrame = CFrame.new(nestCenterX, nestCenterY + 2, nestCenterZ + 10) * CFrame.Angles(math.rad(-25), 0, 0)
	backRim.Anchored = true
	backRim.CanCollide = true
	backRim.Material = Enum.Material.Wood
	backRim.Color = Color3.fromRGB(130, 90, 45)
	backRim.TopSurface = Enum.SurfaceType.Smooth
	backRim.BottomSurface = Enum.SurfaceType.Smooth
	backRim.Parent = stageModel

	-- Left rim
	local leftRim = Instance.new("Part")
	leftRim.Name = "NestRim_Left"
	leftRim.Size = Vector3.new(4, 2, 18)
	leftRim.CFrame = CFrame.new(nestCenterX - 10, nestCenterY + 2, nestCenterZ) * CFrame.Angles(0, 0, math.rad(-25))
	leftRim.Anchored = true
	leftRim.CanCollide = true
	leftRim.Material = Enum.Material.Wood
	leftRim.Color = Color3.fromRGB(130, 90, 45)
	leftRim.TopSurface = Enum.SurfaceType.Smooth
	leftRim.BottomSurface = Enum.SurfaceType.Smooth
	leftRim.Parent = stageModel

	-- Right rim
	local rightRim = Instance.new("Part")
	rightRim.Name = "NestRim_Right"
	rightRim.Size = Vector3.new(4, 2, 18)
	rightRim.CFrame = CFrame.new(nestCenterX + 10, nestCenterY + 2, nestCenterZ) * CFrame.Angles(0, 0, math.rad(25))
	rightRim.Anchored = true
	rightRim.CanCollide = true
	rightRim.Material = Enum.Material.Wood
	rightRim.Color = Color3.fromRGB(130, 90, 45)
	rightRim.TopSurface = Enum.SurfaceType.Smooth
	rightRim.BottomSurface = Enum.SurfaceType.Smooth
	rightRim.Parent = stageModel

	-- Scattered twigs/branches in and around the nest
	local twigPositions = {
		{ pos = Vector3.new(nestCenterX - 6, nestCenterY + 1, nestCenterZ + 3), rot = 15 },
		{ pos = Vector3.new(nestCenterX + 4, nestCenterY + 1, nestCenterZ - 5), rot = -20 },
		{ pos = Vector3.new(nestCenterX + 7, nestCenterY + 1, nestCenterZ + 6), rot = 30 },
		{ pos = Vector3.new(nestCenterX - 3, nestCenterY + 1, nestCenterZ - 4), rot = -10 },
	}

	for i, twig in twigPositions do
		local twigPart = Instance.new("Part")
		twigPart.Name = `NestTwig_{i}`
		twigPart.Size = Vector3.new(6, 0.5, 0.8)
		twigPart.CFrame = CFrame.new(twig.pos) * CFrame.Angles(0, math.rad(twig.rot), 0)
		twigPart.Anchored = true
		twigPart.CanCollide = true
		twigPart.Material = Enum.Material.Wood
		twigPart.Color = Color3.fromRGB(120, 85, 40)
		twigPart.TopSurface = Enum.SurfaceType.Smooth
		twigPart.BottomSurface = Enum.SurfaceType.Smooth
		twigPart.Parent = stageModel
	end

	-- Bird spawn points (patrol around the nest)
	local birdSpawns = {
		Vector3.new(nestCenterX - 15, 82, nestCenterZ - 10),
		Vector3.new(nestCenterX + 15, 85, nestCenterZ + 5),
		Vector3.new(nestCenterX, 88, nestCenterZ - 15),
	}

	for i, pos in birdSpawns do
		local birdSpawn = Instance.new("Part")
		birdSpawn.Name = `BirdSpawn_{i}`
		birdSpawn.Size = Vector3.new(3, 3, 3)
		birdSpawn.Position = pos
		birdSpawn.Anchored = true
		birdSpawn.CanCollide = false
		birdSpawn.Transparency = 0.8
		birdSpawn.Color = Color3.fromRGB(255, 80, 80)
		birdSpawn.Parent = stageModel

		local enemyType = Instance.new("StringValue")
		enemyType.Name = "EnemyType"
		enemyType.Value = "bird"
		enemyType.Parent = birdSpawn

		-- Patrol points for each bird
		local patrolA = Instance.new("Part")
		patrolA.Name = `BirdPatrolA_{i}`
		patrolA.Size = Vector3.new(1, 1, 1)
		patrolA.Position = pos + Vector3.new(-20, 0, -10)
		patrolA.Anchored = true
		patrolA.CanCollide = false
		patrolA.Transparency = 1
		patrolA.Parent = stageModel

		local patrolB = Instance.new("Part")
		patrolB.Name = `BirdPatrolB_{i}`
		patrolB.Size = Vector3.new(1, 1, 1)
		patrolB.Position = pos + Vector3.new(20, 0, 10)
		patrolB.Anchored = true
		patrolB.CanCollide = false
		patrolB.Transparency = 1
		patrolB.Parent = stageModel
	end

	-- EggNest - drawing a nest here befriends the birds
	local eggNest = Instance.new("Part")
	eggNest.Name = "EggNest"
	eggNest.Size = Vector3.new(8, 4, 8)
	eggNest.Position = Vector3.new(nestCenterX, nestCenterY + 2, nestCenterZ)
	eggNest.Anchored = true
	eggNest.CanCollide = false
	eggNest.Transparency = 0.6
	eggNest.Color = Color3.fromRGB(255, 220, 100)
	eggNest.Material = Enum.Material.Neon
	eggNest.Parent = stageModel

	local isFriendlyTrigger = Instance.new("BoolValue")
	isFriendlyTrigger.Name = "IsFriendlyTrigger"
	isFriendlyTrigger.Value = true
	isFriendlyTrigger.Parent = eggNest

	-- End platform at ~80 studs height
	createPart(
		"EndPlatformCliff",
		Vector3.new(14, 2, 10),
		Vector3.new(cliffX, 80, cliffZ - 12),
		Color3.fromRGB(80, 200, 80),
		Enum.Material.Neon,
		stageModel
	)

	-- Kill zone far below
	local killZone = Instance.new("Part")
	killZone.Name = "CliffKillZone"
	killZone.Size = Vector3.new(120, 2, 100)
	killZone.Position = Vector3.new(cliffX, -20, cliffZ)
	killZone.Anchored = true
	killZone.CanCollide = false
	killZone.Transparency = 1
	killZone.Parent = stageModel

	local killTag = Instance.new("BoolValue")
	killTag.Name = "IsKillZone"
	killTag.Value = true
	killTag.Parent = killZone
end

--[[
	Stage 49 - "The Storm"
	Near the top of the cliff (80-100 studs).
	Extreme wind, lightning, rain. Everything tries to knock you off.
]]
local function buildStage49(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local cliffX = 0
	local cliffZ = baseZ + 60

	-- Cliff wall section (80-120 studs, extends above for drama)
	createPart(
		"CliffWall",
		Vector3.new(80, 50, 12),
		Vector3.new(cliffX, 105, cliffZ),
		Color3.fromRGB(50, 45, 55),
		Enum.Material.Rock,
		stageModel
	)

	-- Start ledge at 80 studs
	createPart(
		"StartLedge",
		Vector3.new(12, 2, 8),
		Vector3.new(cliffX, 80, cliffZ - 10),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Scattered small platforms on the cliff face (dangerous ascent)
	local stormPlatforms = {
		{ pos = Vector3.new(-18, 83, cliffZ - 8), size = Vector3.new(4, 1, 3) },
		{ pos = Vector3.new(12, 85, cliffZ - 8), size = Vector3.new(3, 1, 3) },
		{ pos = Vector3.new(-8, 88, cliffZ - 9), size = Vector3.new(3, 1, 2) },
		{ pos = Vector3.new(20, 90, cliffZ - 8), size = Vector3.new(4, 1, 3) },
		{ pos = Vector3.new(-22, 92, cliffZ - 9), size = Vector3.new(3, 1, 3) },
		{ pos = Vector3.new(5, 94, cliffZ - 8), size = Vector3.new(3, 1, 2) },
		{ pos = Vector3.new(-12, 96, cliffZ - 9), size = Vector3.new(4, 1, 3) },
		{ pos = Vector3.new(15, 98, cliffZ - 8), size = Vector3.new(3, 1, 2) },
	}

	for i, plat in stormPlatforms do
		createPart(`StormPlatform_{i}`, plat.size, plat.pos, Color3.fromRGB(65, 58, 68), Enum.Material.Rock, stageModel)
	end

	-- WIND ZONE - massive, covers the entire storm area
	local windZone = Instance.new("Part")
	windZone.Name = "WindZone"
	windZone.Size = Vector3.new(100, 30, 60)
	windZone.Position = Vector3.new(cliffX, 92, cliffZ - 10)
	windZone.Anchored = true
	windZone.CanCollide = false
	windZone.Transparency = 1
	windZone.Parent = stageModel

	local windForce = Instance.new("Vector3Value")
	windForce.Name = "WindForce"
	windForce.Value = Vector3.new(150, 50, 0) -- Very strong sideways + upward push
	windForce.Parent = windZone

	-- LIGHTNING ZONE - strikes frequently
	local lightningZone = Instance.new("Part")
	lightningZone.Name = "LightningZone"
	lightningZone.Size = Vector3.new(100, 30, 60)
	lightningZone.Position = Vector3.new(cliffX, 92, cliffZ - 10)
	lightningZone.Anchored = true
	lightningZone.CanCollide = false
	lightningZone.Transparency = 1
	lightningZone.Parent = stageModel

	local strikeInterval = Instance.new("NumberValue")
	strikeInterval.Name = "StrikeInterval"
	strikeInterval.Value = 2
	strikeInterval.Parent = lightningZone

	-- RAIN ZONE - makes drawings heavier and slippery
	local rainZone = Instance.new("Part")
	rainZone.Name = "RainZone"
	rainZone.Size = Vector3.new(100, 30, 60)
	rainZone.Position = Vector3.new(cliffX, 92, cliffZ - 10)
	rainZone.Anchored = true
	rainZone.CanCollide = false
	rainZone.Transparency = 1
	rainZone.Parent = stageModel

	local isRainZone = Instance.new("BoolValue")
	isRainZone.Name = "IsRainZone"
	isRainZone.Value = true
	isRainZone.Parent = rainZone

	-- End platform at ~100 studs height
	createPart(
		"EndPlatformCliff",
		Vector3.new(12, 2, 8),
		Vector3.new(cliffX, 100, cliffZ - 12),
		Color3.fromRGB(80, 200, 80),
		Enum.Material.Neon,
		stageModel
	)

	-- Kill zone far below
	local killZone = Instance.new("Part")
	killZone.Name = "CliffKillZone"
	killZone.Size = Vector3.new(120, 2, 100)
	killZone.Position = Vector3.new(cliffX, -20, cliffZ)
	killZone.Anchored = true
	killZone.CanCollide = false
	killZone.Transparency = 1
	killZone.Parent = stageModel

	local killTag = Instance.new("BoolValue")
	killTag.Name = "IsKillZone"
	killTag.Value = true
	killTag.Parent = killZone
end

--[[
	Stage 50 - "The Final Draw"
	The summit. Small platform at the top of the cliff (100+ studs up).
	One last gap (15 studs) to the golden victory platform.
	Gallery zone for displaying player art. THE ENDING.
]]
local function buildStage50(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	local cliffX = 0
	local cliffZ = baseZ + 60

	-- The final stretch of cliff wall (towering to 130 studs for drama)
	createPart(
		"CliffWallFinal",
		Vector3.new(80, 130, 12),
		Vector3.new(cliffX, 65, cliffZ),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Summit start platform (small, precarious, at 105 studs)
	createPart(
		"SummitPlatform",
		Vector3.new(8, 2, 8),
		Vector3.new(cliffX, 105, cliffZ - 12),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- The 15-stud gap to the victory platform
	-- Nothing in between. One drawing. One chance.

	-- THE VICTORY PLATFORM - large, golden, Neon material, dramatic
	createPart(
		"VictoryPlatform",
		Vector3.new(24, 3, 24),
		Vector3.new(cliffX, 105, cliffZ - 35),
		Color3.fromRGB(255, 200, 50),
		Enum.Material.Neon,
		stageModel
	)

	-- Victory platform accent ring (slightly larger, beneath)
	createPart(
		"VictoryRing",
		Vector3.new(28, 1, 28),
		Vector3.new(cliffX, 103, cliffZ - 35),
		Color3.fromRGB(255, 150, 30),
		Enum.Material.Neon,
		stageModel
	)

	-- Victory platform pedestal columns at corners
	local pedestalOffsets = {
		Vector3.new(-10, 0, -10),
		Vector3.new(10, 0, -10),
		Vector3.new(-10, 0, 10),
		Vector3.new(10, 0, 10),
	}

	for i, offset in pedestalOffsets do
		createPart(
			`VictoryPillar_{i}`,
			Vector3.new(2, 12, 2),
			Vector3.new(cliffX + offset.X, 112, cliffZ - 35 + offset.Z),
			Color3.fromRGB(255, 180, 40),
			Enum.Material.Neon,
			stageModel
		)
	end

	-- Victory arch above the platform
	createPart(
		"VictoryArch",
		Vector3.new(24, 2, 2),
		Vector3.new(cliffX, 119, cliffZ - 35),
		Color3.fromRGB(255, 220, 80),
		Enum.Material.Neon,
		stageModel
	)

	-- Gallery Zone - area for displaying player art
	local galleryZone = Instance.new("Part")
	galleryZone.Name = "GalleryZone"
	galleryZone.Size = Vector3.new(30, 20, 30)
	galleryZone.Position = Vector3.new(cliffX, 115, cliffZ - 35)
	galleryZone.Anchored = true
	galleryZone.CanCollide = false
	galleryZone.Transparency = 1
	galleryZone.Parent = stageModel

	local isGalleryZone = Instance.new("BoolValue")
	isGalleryZone.Name = "IsGalleryZone"
	isGalleryZone.Value = true
	isGalleryZone.Parent = galleryZone

	-- Completion trigger on the victory platform
	local completionTrigger = Instance.new("Part")
	completionTrigger.Name = "FinalCompletionTrigger"
	completionTrigger.Size = Vector3.new(24, 12, 24)
	completionTrigger.Position = Vector3.new(cliffX, 112, cliffZ - 35)
	completionTrigger.Anchored = true
	completionTrigger.CanCollide = false
	completionTrigger.Transparency = 1
	completionTrigger.Parent = stageModel

	local triggerTag = Instance.new("BoolValue")
	triggerTag.Name = "IsCompletionTrigger"
	triggerTag.Value = true
	triggerTag.Parent = completionTrigger

	-- Dramatic particle-emitting beacon pillars at the summit edges
	local beaconPositions = {
		Vector3.new(cliffX - 35, 105, cliffZ - 12),
		Vector3.new(cliffX + 35, 105, cliffZ - 12),
		Vector3.new(cliffX - 35, 105, cliffZ - 55),
		Vector3.new(cliffX + 35, 105, cliffZ - 55),
	}

	for i, pos in beaconPositions do
		local beacon = createPart(
			`SummitBeacon_{i}`,
			Vector3.new(3, 25, 3),
			Vector3.new(pos.X, pos.Y + 12, pos.Z),
			Color3.fromRGB(255, 100, 50),
			Enum.Material.Neon,
			stageModel
		)

		-- Point light on each beacon for dramatic glow
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 180, 80)
		light.Brightness = 3
		light.Range = 30
		light.Parent = beacon
	end

	-- Skybox-level floating victory text anchor (billboard will be added by WorldBuilder)
	local victoryLabel = Instance.new("Part")
	victoryLabel.Name = "VictoryLabel"
	victoryLabel.Size = Vector3.new(1, 1, 1)
	victoryLabel.Position = Vector3.new(cliffX, 130, cliffZ - 35)
	victoryLabel.Anchored = true
	victoryLabel.CanCollide = false
	victoryLabel.Transparency = 1
	victoryLabel.Parent = stageModel

	local victoryBillboard = Instance.new("BillboardGui")
	victoryBillboard.Size = UDim2.fromOffset(500, 120)
	victoryBillboard.StudsOffset = Vector3.new(0, 5, 0)
	victoryBillboard.AlwaysOnTop = true
	victoryBillboard.Parent = victoryLabel

	local victoryText = Instance.new("TextLabel")
	victoryText.Size = UDim2.fromScale(1, 1)
	victoryText.BackgroundTransparency = 1
	victoryText.Text = "YOU ESCAPED!"
	victoryText.TextColor3 = Color3.fromRGB(255, 220, 80)
	victoryText.TextSize = 48
	victoryText.Font = Enum.Font.GothamBold
	victoryText.TextStrokeTransparency = 0
	victoryText.TextStrokeColor3 = Color3.fromRGB(180, 100, 0)
	victoryText.Parent = victoryBillboard

	-- Kill zone far below the entire summit
	local killZone = Instance.new("Part")
	killZone.Name = "CliffKillZone"
	killZone.Size = Vector3.new(150, 2, 150)
	killZone.Position = Vector3.new(cliffX, -20, cliffZ - 20)
	killZone.Anchored = true
	killZone.CanCollide = false
	killZone.Transparency = 1
	killZone.Parent = stageModel

	local killTag = Instance.new("BoolValue")
	killTag.Name = "IsKillZone"
	killTag.Value = true
	killTag.Parent = killZone
end

-- ================================================================
-- EXPORTS
-- ================================================================

ZoneBuilders9_10.Builders = {
	[41] = buildStage41,
	[42] = buildStage42,
	[43] = buildStage43,
	[44] = buildStage44,
	[45] = buildStage45,
	[46] = buildStage46,
	[47] = buildStage47,
	[48] = buildStage48,
	[49] = buildStage49,
	[50] = buildStage50,
} :: { [number]: (Model, number, ZoneThemes.ZoneTheme) -> () }

return ZoneBuilders9_10
