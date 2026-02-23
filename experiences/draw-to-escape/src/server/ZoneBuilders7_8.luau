--!strict

--[[
	ZoneBuilders7_8
	Stage geometry builders for Zone 7 (The Storm Peaks) and Zone 8 (The Living Canvas).
	Stages 31-40.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneThemes = require(ReplicatedStorage.Shared.ZoneThemes)

local ZoneBuilders7_8 = {}

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
-- ZONE 7: THE STORM PEAKS
-- Harsh mountain landscape battered by wind, rain, and lightning.
-- ================================================================

--[[
	Stage 31 - "The Gale Ledge"
	A narrow ledge along a cliff face with devastating wind.
	Wall on one side, lethal drop on the other.
]]
local function buildStage31(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Narrow ledge floor: 3 studs wide, 60 studs long
	createPart(
		"LedgeFloor",
		Vector3.new(3, 2, 60),
		Vector3.new(-8, 0, baseZ + 40),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Cliff wall rising on the left (inner side)
	createPart(
		"CliffWall_Lower",
		Vector3.new(6, 30, 60),
		Vector3.new(-12.5, 15, baseZ + 40),
		Color3.fromRGB(80, 75, 70),
		Enum.Material.Rock,
		stageModel
	)
	createPart(
		"CliffWall_Upper",
		Vector3.new(8, 20, 60),
		Vector3.new(-13.5, 40, baseZ + 40),
		Color3.fromRGB(70, 65, 60),
		Enum.Material.Rock,
		stageModel
	)

	-- Jagged rock outcrops along the cliff face for visual interest
	createPart(
		"RockOutcrop_1",
		Vector3.new(3, 4, 5),
		Vector3.new(-9.5, 8, baseZ + 25),
		Color3.fromRGB(85, 80, 72),
		Enum.Material.Rock,
		stageModel
	)
	createPart(
		"RockOutcrop_2",
		Vector3.new(2, 5, 4),
		Vector3.new(-9.5, 12, baseZ + 45),
		Color3.fromRGB(75, 70, 65),
		Enum.Material.Rock,
		stageModel
	)
	createPart(
		"RockOutcrop_3",
		Vector3.new(3, 3, 6),
		Vector3.new(-9.5, 6, baseZ + 58),
		Color3.fromRGB(90, 82, 75),
		Enum.Material.Rock,
		stageModel
	)

	-- Starting wider platform before the ledge
	createPart(
		"StartArea",
		Vector3.new(12, 2, 12),
		Vector3.new(-6, 0, baseZ + 8),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Ending wider platform after the ledge
	createPart(
		"EndArea",
		Vector3.new(12, 2, 12),
		Vector3.new(-6, 0, baseZ + 72),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Kill zone below the ledge (the abyss on the right side)
	local abyss = Instance.new("Part")
	abyss.Name = "AbyssKillZone"
	abyss.Size = Vector3.new(40, 4, 70)
	abyss.Position = Vector3.new(10, -30, baseZ + 40)
	abyss.Anchored = true
	abyss.CanCollide = false
	abyss.Transparency = 1
	abyss.Parent = stageModel

	local abyssKillTag = Instance.new("BoolValue")
	abyssKillTag.Name = "IsKillZone"
	abyssKillTag.Value = true
	abyssKillTag.Parent = abyss

	-- Fog/cloud part below for visual effect
	local fogBelow = createPart(
		"CloudLayer",
		Vector3.new(50, 2, 80),
		Vector3.new(5, -20, baseZ + 40),
		Color3.fromRGB(180, 180, 190),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	fogBelow.CanCollide = false
	fogBelow.Transparency = 0.6

	-- Wind zone covering the entire ledge area
	local windZone = Instance.new("Part")
	windZone.Name = "WindZone"
	windZone.Size = Vector3.new(20, 15, 65)
	windZone.Position = Vector3.new(-5, 8, baseZ + 40)
	windZone.Anchored = true
	windZone.CanCollide = false
	windZone.Transparency = 1
	windZone.Parent = stageModel

	local windForce = Instance.new("Vector3Value")
	windForce.Name = "WindForce"
	windForce.Value = Vector3.new(120, 0, 0) -- Strong sideways push toward the drop
	windForce.Parent = windZone

	-- Sparse rocks on the ledge for partial cover
	createPart(
		"CoverRock_1",
		Vector3.new(2, 3, 2),
		Vector3.new(-8, 2.5, baseZ + 30),
		Color3.fromRGB(95, 88, 80),
		Enum.Material.Rock,
		stageModel
	)
	createPart(
		"CoverRock_2",
		Vector3.new(2, 2, 3),
		Vector3.new(-8, 2, baseZ + 50),
		Color3.fromRGB(88, 82, 76),
		Enum.Material.Rock,
		stageModel
	)
end

--[[
	Stage 32 - "The Lightning Field"
	Open flat field with tall metal lightning rods.
	Lightning strikes randomly every few seconds.
]]
local function buildStage32(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Open field floor
	createPart(
		"FieldFloor",
		Vector3.new(40, 2, 60),
		Vector3.new(0, 0, baseZ + 40),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Scorched earth patches for visual flavor
	createPart(
		"ScorchMark_1",
		Vector3.new(5, 0.3, 5),
		Vector3.new(-8, 1.1, baseZ + 30),
		Color3.fromRGB(30, 25, 20),
		Enum.Material.Slate,
		stageModel
	)
	createPart(
		"ScorchMark_2",
		Vector3.new(4, 0.3, 4),
		Vector3.new(10, 1.1, baseZ + 50),
		Color3.fromRGB(35, 28, 22),
		Enum.Material.Slate,
		stageModel
	)
	createPart(
		"ScorchMark_3",
		Vector3.new(6, 0.3, 3),
		Vector3.new(2, 1.1, baseZ + 65),
		Color3.fromRGB(28, 22, 18),
		Enum.Material.Slate,
		stageModel
	)

	-- Tall metal lightning rods scattered across the field
	local rodPositions = {
		Vector3.new(-12, 8.5, baseZ + 25),
		Vector3.new(8, 8.5, baseZ + 30),
		Vector3.new(-5, 8.5, baseZ + 42),
		Vector3.new(14, 8.5, baseZ + 45),
		Vector3.new(-15, 8.5, baseZ + 55),
		Vector3.new(3, 8.5, baseZ + 58),
		Vector3.new(12, 8.5, baseZ + 65),
	}

	for i, pos in rodPositions do
		createPart(
			`LightningRod_{i}`,
			Vector3.new(1, 15, 1),
			pos,
			Color3.fromRGB(160, 165, 170),
			Enum.Material.Metal,
			stageModel
		)
		-- Small base plate for each rod
		createPart(
			`RodBase_{i}`,
			Vector3.new(3, 0.5, 3),
			Vector3.new(pos.X, 1.25, pos.Z),
			Color3.fromRGB(120, 120, 130),
			Enum.Material.Metal,
			stageModel
		)
	end

	-- Lightning zone covering the entire field
	local lightningZone = Instance.new("Part")
	lightningZone.Name = "LightningZone"
	lightningZone.Size = Vector3.new(44, 40, 64)
	lightningZone.Position = Vector3.new(0, 20, baseZ + 40)
	lightningZone.Anchored = true
	lightningZone.CanCollide = false
	lightningZone.Transparency = 1
	lightningZone.Parent = stageModel

	local lightningTag = Instance.new("BoolValue")
	lightningTag.Name = "IsLightningZone"
	lightningTag.Value = true
	lightningTag.Parent = lightningZone

	local strikeInterval = Instance.new("NumberValue")
	strikeInterval.Name = "StrikeInterval"
	strikeInterval.Value = 3
	strikeInterval.Parent = lightningZone

	-- Strike warning markers (small neon yellow circles on the ground)
	local markerPositions = {
		Vector3.new(-10, 1.2, baseZ + 28),
		Vector3.new(5, 1.2, baseZ + 35),
		Vector3.new(-3, 1.2, baseZ + 44),
		Vector3.new(10, 1.2, baseZ + 48),
		Vector3.new(-8, 1.2, baseZ + 55),
		Vector3.new(6, 1.2, baseZ + 60),
		Vector3.new(0, 1.2, baseZ + 38),
		Vector3.new(-14, 1.2, baseZ + 50),
		Vector3.new(15, 1.2, baseZ + 55),
	}

	for i, pos in markerPositions do
		local marker = createPart(
			`StrikeMarker_{i}`,
			Vector3.new(3, 0.2, 3),
			pos,
			Color3.fromRGB(255, 255, 60),
			Enum.Material.Neon,
			stageModel
		)
		marker.CanCollide = false
		marker.Transparency = 0.4
	end

	-- Low rock cover scattered around for player to hide behind
	createPart(
		"CoverRock_1",
		Vector3.new(4, 3, 4),
		Vector3.new(-6, 2.5, baseZ + 33),
		Color3.fromRGB(85, 80, 75),
		Enum.Material.Rock,
		stageModel
	)
	createPart(
		"CoverRock_2",
		Vector3.new(3, 2.5, 5),
		Vector3.new(8, 2.25, baseZ + 52),
		Color3.fromRGB(80, 75, 70),
		Enum.Material.Rock,
		stageModel
	)
end

--[[
	Stage 33 - "The Avalanche"
	Downhill slope through a narrowing valley.
	An avalanche trigger at the top sends debris cascading down.
]]
local function buildStage33(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Tilted slope floor using CFrame (downhill from high to low along Z axis)
	local slopeLength = 70
	local slopeHeight = 20
	local slopeAngle = math.atan2(slopeHeight, slopeLength)

	local slopeFloor = Instance.new("Part")
	slopeFloor.Name = "SlopeFloor"
	slopeFloor.Size = Vector3.new(24, 2, math.sqrt(slopeLength * slopeLength + slopeHeight * slopeHeight))
	slopeFloor.Anchored = true
	slopeFloor.CanCollide = true
	slopeFloor.Material = theme.GroundMaterial
	slopeFloor.Color = theme.GroundColor
	slopeFloor.TopSurface = Enum.SurfaceType.Smooth
	slopeFloor.BottomSurface = Enum.SurfaceType.Smooth
	-- Tilt so the start (high) is at baseZ+15 and end (low) is at baseZ+85
	slopeFloor.CFrame = CFrame.new(0, slopeHeight / 2, baseZ + 50) * CFrame.Angles(slopeAngle, 0, 0)
	slopeFloor.Parent = stageModel

	-- Valley walls narrowing from 24 studs wide at top to 12 studs at bottom
	-- Left wall
	local wallL = Instance.new("Part")
	wallL.Name = "ValleyWallL"
	wallL.Size = Vector3.new(4, 25, 75)
	wallL.Anchored = true
	wallL.CanCollide = true
	wallL.Material = Enum.Material.Rock
	wallL.Color = Color3.fromRGB(100, 92, 85)
	wallL.TopSurface = Enum.SurfaceType.Smooth
	wallL.BottomSurface = Enum.SurfaceType.Smooth
	wallL.CFrame = CFrame.new(-14, 15, baseZ + 50)
	wallL.Parent = stageModel

	-- Right wall
	local wallR = Instance.new("Part")
	wallR.Name = "ValleyWallR"
	wallR.Size = Vector3.new(4, 25, 75)
	wallR.Anchored = true
	wallR.CanCollide = true
	wallR.Material = Enum.Material.Rock
	wallR.Color = Color3.fromRGB(100, 92, 85)
	wallR.TopSurface = Enum.SurfaceType.Smooth
	wallR.BottomSurface = Enum.SurfaceType.Smooth
	wallR.CFrame = CFrame.new(14, 15, baseZ + 50)
	wallR.Parent = stageModel

	-- Narrowing inner walls toward the bottom half
	createPart(
		"NarrowWallL",
		Vector3.new(4, 18, 35),
		Vector3.new(-10, 9, baseZ + 65),
		Color3.fromRGB(95, 88, 80),
		Enum.Material.Rock,
		stageModel
	)
	createPart(
		"NarrowWallR",
		Vector3.new(4, 18, 35),
		Vector3.new(10, 9, baseZ + 65),
		Color3.fromRGB(95, 88, 80),
		Enum.Material.Rock,
		stageModel
	)

	-- Flat arrival area at the bottom of the slope
	createPart(
		"BottomPlatform",
		Vector3.new(16, 2, 16),
		Vector3.new(0, 0, baseZ + 88),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Elevated start platform at the top
	createPart(
		"TopPlatform",
		Vector3.new(16, 2, 10),
		Vector3.new(0, slopeHeight + 1, baseZ + 12),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Avalanche trigger behind the start point
	local avalancheTrigger = Instance.new("Part")
	avalancheTrigger.Name = "AvalancheTrigger"
	avalancheTrigger.Size = Vector3.new(30, 20, 8)
	avalancheTrigger.Position = Vector3.new(0, slopeHeight + 15, baseZ + 5)
	avalancheTrigger.Anchored = true
	avalancheTrigger.CanCollide = false
	avalancheTrigger.Transparency = 0.8
	avalancheTrigger.Color = Color3.fromRGB(200, 200, 210)
	avalancheTrigger.Material = Enum.Material.SmoothPlastic
	avalancheTrigger.Parent = stageModel

	local avalancheTag = Instance.new("BoolValue")
	avalancheTag.Name = "IsAvalanche"
	avalancheTag.Value = true
	avalancheTag.Parent = avalancheTrigger

	-- Scattered rock debris on the slope for cover
	local debrisData = {
		{ name = "Debris_1", size = Vector3.new(4, 3, 3), pos = Vector3.new(-5, 16, baseZ + 28) },
		{ name = "Debris_2", size = Vector3.new(3, 2, 4), pos = Vector3.new(6, 13, baseZ + 36) },
		{ name = "Debris_3", size = Vector3.new(5, 4, 3), pos = Vector3.new(-2, 10, baseZ + 48) },
		{ name = "Debris_4", size = Vector3.new(3, 3, 3), pos = Vector3.new(4, 7, baseZ + 58) },
		{ name = "Debris_5", size = Vector3.new(4, 2, 5), pos = Vector3.new(-6, 5, baseZ + 65) },
		{ name = "Debris_6", size = Vector3.new(2, 3, 2), pos = Vector3.new(3, 3, baseZ + 75) },
	}

	for _, d in debrisData do
		createPart(d.name, d.size, d.pos, Color3.fromRGB(110, 105, 95), Enum.Material.Rock, stageModel)
	end

	-- Snow piles for atmosphere
	createPart(
		"SnowPile_1",
		Vector3.new(6, 1, 4),
		Vector3.new(-8, slopeHeight + 2, baseZ + 20),
		Color3.fromRGB(230, 235, 240),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	createPart(
		"SnowPile_2",
		Vector3.new(5, 1, 5),
		Vector3.new(7, 8, baseZ + 55),
		Color3.fromRGB(225, 230, 235),
		Enum.Material.SmoothPlastic,
		stageModel
	)
end

--[[
	Stage 34 - "The Frozen Lock"
	Room with a frozen gate blocking the exit.
	Melt the ice by heating a nearby target, but beware:
	the ice floor can melt too.
]]
local function buildStage34(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Main room floor (mostly stone)
	createPart(
		"Floor_Stone",
		Vector3.new(30, 2, 30),
		Vector3.new(0, 0, baseZ + 25),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Ice floor section near the gate (meltable)
	local iceFloor = createPart(
		"IceFloorSection",
		Vector3.new(30, 2, 25),
		Vector3.new(0, 0, baseZ + 52),
		Color3.fromRGB(160, 210, 240),
		Enum.Material.Ice,
		stageModel
	)

	local meltableTag = Instance.new("BoolValue")
	meltableTag.Name = "IsMeltable"
	meltableTag.Value = true
	meltableTag.Parent = iceFloor

	-- Floor continuation past the gate
	createPart(
		"Floor_Past",
		Vector3.new(30, 2, 20),
		Vector3.new(0, 0, baseZ + 78),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Side walls of the room
	createPart(
		"RoomWallL",
		Vector3.new(3, 18, 70),
		Vector3.new(-16.5, 9, baseZ + 45),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"RoomWallR",
		Vector3.new(3, 18, 70),
		Vector3.new(16.5, 9, baseZ + 45),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Frozen gate blocking the exit (thick ice wall)
	local frozenGate = createPart(
		"FrozenGate",
		Vector3.new(30, 16, 5),
		Vector3.new(0, 8, baseZ + 66),
		Color3.fromRGB(140, 200, 235),
		Enum.Material.Ice,
		stageModel
	)

	local gateTag = Instance.new("BoolValue")
	gateTag.Name = "IsFrozenGate"
	gateTag.Value = true
	gateTag.Parent = frozenGate

	-- Ice crystal decorations on the gate
	createPart(
		"IceCrystal_1",
		Vector3.new(2, 6, 2),
		Vector3.new(-8, 14, baseZ + 66),
		Color3.fromRGB(180, 225, 250),
		Enum.Material.Ice,
		stageModel
	)
	createPart(
		"IceCrystal_2",
		Vector3.new(1.5, 8, 1.5),
		Vector3.new(6, 15, baseZ + 66),
		Color3.fromRGB(170, 220, 248),
		Enum.Material.Ice,
		stageModel
	)
	createPart(
		"IceCrystal_3",
		Vector3.new(2, 5, 2),
		Vector3.new(0, 17, baseZ + 66),
		Color3.fromRGB(185, 228, 252),
		Enum.Material.Ice,
		stageModel
	)

	-- Heat target mechanism (a brazier-like object near the gate)
	local heatTarget = createPart(
		"HeatTarget",
		Vector3.new(4, 5, 4),
		Vector3.new(10, 3.5, baseZ + 58),
		Color3.fromRGB(140, 80, 40),
		Enum.Material.Brick,
		stageModel
	)

	local heatTag = Instance.new("BoolValue")
	heatTag.Name = "IsHeatTarget"
	heatTag.Value = true
	heatTag.Parent = heatTarget

	-- Visual hint: charred ring around heat target
	local charRing = createPart(
		"CharRing",
		Vector3.new(6, 0.2, 6),
		Vector3.new(10, 1.1, baseZ + 58),
		Color3.fromRGB(40, 30, 20),
		Enum.Material.Slate,
		stageModel
	)
	charRing.CanCollide = false

	-- Icicles hanging from ceiling for atmosphere
	createPart(
		"Icicle_1",
		Vector3.new(1, 6, 1),
		Vector3.new(-6, 20, baseZ + 40),
		Color3.fromRGB(175, 220, 245),
		Enum.Material.Ice,
		stageModel
	)
	createPart(
		"Icicle_2",
		Vector3.new(0.8, 5, 0.8),
		Vector3.new(4, 21, baseZ + 35),
		Color3.fromRGB(170, 215, 240),
		Enum.Material.Ice,
		stageModel
	)
	createPart(
		"Icicle_3",
		Vector3.new(1.2, 7, 1.2),
		Vector3.new(-2, 19.5, baseZ + 55),
		Color3.fromRGB(180, 225, 250),
		Enum.Material.Ice,
		stageModel
	)
	createPart(
		"Icicle_4",
		Vector3.new(0.6, 4, 0.6),
		Vector3.new(8, 22, baseZ + 48),
		Color3.fromRGB(165, 210, 238),
		Enum.Material.Ice,
		stageModel
	)

	-- Ceiling
	createPart(
		"Ceiling",
		Vector3.new(36, 2, 70),
		Vector3.new(0, 24, baseZ + 45),
		Color3.fromRGB(75, 70, 65),
		Enum.Material.Rock,
		stageModel
	)
end

--[[
	Stage 35 - "The Collapsing Summit"
	The peak of a mountain. Multiple floating rock platforms at varying heights.
	Some are unstable. Wind + lightning zones. Large gap to cross at the end.
]]
local function buildStage35(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Starting rock formation (stable ground)
	createPart(
		"SummitBase",
		Vector3.new(14, 3, 14),
		Vector3.new(0, 10, baseZ + 12),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Rock pillar supporting the start
	createPart(
		"SummitPillar",
		Vector3.new(8, 12, 8),
		Vector3.new(0, 4, baseZ + 12),
		Color3.fromRGB(85, 80, 75),
		Enum.Material.Rock,
		stageModel
	)

	-- Array of floating rock platforms at varying heights
	-- Some stable, some unstable
	local platformData = {
		{
			name = "RockPlatform_1",
			size = Vector3.new(8, 2, 8),
			pos = Vector3.new(-6, 12, baseZ + 24),
			unstable = false,
		},
		{ name = "RockPlatform_2", size = Vector3.new(6, 2, 6), pos = Vector3.new(5, 14, baseZ + 30), unstable = true },
		{
			name = "RockPlatform_3",
			size = Vector3.new(7, 2, 5),
			pos = Vector3.new(-4, 16, baseZ + 38),
			unstable = false,
		},
		{ name = "RockPlatform_4", size = Vector3.new(5, 2, 7), pos = Vector3.new(8, 13, baseZ + 42), unstable = true },
		{ name = "RockPlatform_5", size = Vector3.new(6, 2, 6), pos = Vector3.new(0, 18, baseZ + 48), unstable = true },
		{
			name = "RockPlatform_6",
			size = Vector3.new(9, 2, 6),
			pos = Vector3.new(-7, 15, baseZ + 55),
			unstable = false,
		},
		{ name = "RockPlatform_7", size = Vector3.new(5, 2, 5), pos = Vector3.new(6, 20, baseZ + 58), unstable = true },
		{
			name = "RockPlatform_8",
			size = Vector3.new(7, 2, 7),
			pos = Vector3.new(-3, 22, baseZ + 65),
			unstable = false,
		},
		{ name = "RockPlatform_9", size = Vector3.new(4, 2, 4), pos = Vector3.new(5, 19, baseZ + 70), unstable = true },
	}

	for _, pd in platformData do
		local plat = createPart(
			pd.name,
			pd.size,
			pd.pos,
			pd.unstable and Color3.fromRGB(120, 110, 100) or Color3.fromRGB(95, 90, 82),
			Enum.Material.Rock,
			stageModel
		)

		if pd.unstable then
			local unstableTag = Instance.new("BoolValue")
			unstableTag.Name = "IsUnstable"
			unstableTag.Value = true
			unstableTag.Parent = plat

			-- Crack detail on unstable platforms
			local crack = createPart(
				pd.name .. "_Crack",
				Vector3.new(pd.size.X * 0.8, 0.15, pd.size.Z * 0.8),
				Vector3.new(pd.pos.X, pd.pos.Y + 1.1, pd.pos.Z),
				Color3.fromRGB(50, 45, 40),
				Enum.Material.Slate,
				stageModel
			)
			crack.CanCollide = false
		end
	end

	-- Tall rock spires for dramatic scenery
	createPart(
		"Spire_1",
		Vector3.new(3, 30, 3),
		Vector3.new(-15, 15, baseZ + 35),
		Color3.fromRGB(80, 75, 68),
		Enum.Material.Rock,
		stageModel
	)
	createPart(
		"Spire_2",
		Vector3.new(4, 25, 4),
		Vector3.new(15, 12, baseZ + 50),
		Color3.fromRGB(75, 70, 65),
		Enum.Material.Rock,
		stageModel
	)
	createPart(
		"Spire_3",
		Vector3.new(2, 20, 2),
		Vector3.new(12, 18, baseZ + 68),
		Color3.fromRGB(85, 78, 72),
		Enum.Material.Rock,
		stageModel
	)

	-- Large gap before the exit (25 studs, requires flight/gliding)
	-- Exit platform far away and slightly lower
	createPart(
		"ExitPlatform",
		Vector3.new(14, 3, 14),
		Vector3.new(0, 8, baseZ + 95),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	createPart(
		"ExitPillar",
		Vector3.new(8, 10, 8),
		Vector3.new(0, 3, baseZ + 95),
		Color3.fromRGB(85, 80, 75),
		Enum.Material.Rock,
		stageModel
	)

	-- Wind zone covering the entire summit area
	local windZone = Instance.new("Part")
	windZone.Name = "WindZone"
	windZone.Size = Vector3.new(50, 30, 90)
	windZone.Position = Vector3.new(0, 20, baseZ + 50)
	windZone.Anchored = true
	windZone.CanCollide = false
	windZone.Transparency = 1
	windZone.Parent = stageModel

	local windForce = Instance.new("Vector3Value")
	windForce.Name = "WindForce"
	windForce.Value = Vector3.new(100, 20, 0) -- Sideways + upward gusting
	windForce.Parent = windZone

	-- Lightning zone also covering the summit
	local lightningZone = Instance.new("Part")
	lightningZone.Name = "LightningZone"
	lightningZone.Size = Vector3.new(50, 40, 90)
	lightningZone.Position = Vector3.new(0, 25, baseZ + 50)
	lightningZone.Anchored = true
	lightningZone.CanCollide = false
	lightningZone.Transparency = 1
	lightningZone.Parent = stageModel

	local lightningTag = Instance.new("BoolValue")
	lightningTag.Name = "IsLightningZone"
	lightningTag.Value = true
	lightningTag.Parent = lightningZone

	local strikeInterval = Instance.new("NumberValue")
	strikeInterval.Name = "StrikeInterval"
	strikeInterval.Value = 2.5 -- Faster strikes than the lightning field
	strikeInterval.Parent = lightningZone

	-- Strike markers on key platforms
	local strikeMarkerPlatforms = { 2, 4, 5, 7, 9 }
	for _, idx in strikeMarkerPlatforms do
		local pd = platformData[idx]
		local marker = createPart(
			`SummitStrikeMarker_{idx}`,
			Vector3.new(2, 0.2, 2),
			Vector3.new(pd.pos.X, pd.pos.Y + 1.15, pd.pos.Z),
			Color3.fromRGB(255, 255, 60),
			Enum.Material.Neon,
			stageModel
		)
		marker.CanCollide = false
		marker.Transparency = 0.5
	end

	-- Kill zone far below
	local deepAbyss = Instance.new("Part")
	deepAbyss.Name = "SummitAbyss"
	deepAbyss.Size = Vector3.new(60, 4, 100)
	deepAbyss.Position = Vector3.new(0, -40, baseZ + 50)
	deepAbyss.Anchored = true
	deepAbyss.CanCollide = false
	deepAbyss.Transparency = 1
	deepAbyss.Parent = stageModel

	local abyssKill = Instance.new("BoolValue")
	abyssKill.Name = "IsKillZone"
	abyssKill.Value = true
	abyssKill.Parent = deepAbyss

	-- Cloud layer below for visual effect
	local cloudLayer = createPart(
		"CloudLayer",
		Vector3.new(60, 2, 100),
		Vector3.new(0, -10, baseZ + 50),
		Color3.fromRGB(180, 185, 195),
		Enum.Material.SmoothPlastic,
		stageModel
	)
	cloudLayer.CanCollide = false
	cloudLayer.Transparency = 0.5
end

-- ================================================================
-- ZONE 8: THE LIVING CANVAS
-- Surreal, breathing organic world. Fabric walls that pulse.
-- ================================================================

--[[
	Stage 36 - "The Mimic"
	Normal-looking room where player drawings come alive as hostile mimics.
	Cage structures nearby to trap them.
]]
local function buildStage36(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Main room floor
	createPart(
		"Floor",
		Vector3.new(36, 2, 70),
		Vector3.new(0, 0, baseZ + 45),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Fabric walls (organic, breathing feel)
	createPart(
		"WallL",
		Vector3.new(3, 16, 70),
		Vector3.new(-19.5, 8, baseZ + 45),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)
	createPart(
		"WallR",
		Vector3.new(3, 16, 70),
		Vector3.new(19.5, 8, baseZ + 45),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)
	createPart(
		"WallBack",
		Vector3.new(42, 16, 3),
		Vector3.new(0, 8, baseZ + 8),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)

	-- Organic pillar decorations (fleshy columns)
	local pillarPositions = {
		Vector3.new(-12, 6, baseZ + 30),
		Vector3.new(12, 6, baseZ + 30),
		Vector3.new(-12, 6, baseZ + 55),
		Vector3.new(12, 6, baseZ + 55),
	}
	for i, pos in pillarPositions do
		createPart(
			`OrganicPillar_{i}`,
			Vector3.new(3, 12, 3),
			pos,
			Color3.fromRGB(170, 130, 150),
			Enum.Material.Fabric,
			stageModel
		)
	end

	-- Mimic spawn zones (invisible trigger areas where drawings come alive)
	local mimicZonePositions = {
		Vector3.new(-6, 5, baseZ + 28),
		Vector3.new(7, 5, baseZ + 38),
		Vector3.new(-4, 5, baseZ + 50),
		Vector3.new(8, 5, baseZ + 60),
		Vector3.new(0, 5, baseZ + 42),
	}

	for i, pos in mimicZonePositions do
		local mimicZone = Instance.new("Part")
		mimicZone.Name = `MimicSpawn_{i}`
		mimicZone.Size = Vector3.new(10, 10, 10)
		mimicZone.Position = pos
		mimicZone.Anchored = true
		mimicZone.CanCollide = false
		mimicZone.Transparency = 1
		mimicZone.Parent = stageModel

		local mimicTag = Instance.new("BoolValue")
		mimicTag.Name = "IsMimicZone"
		mimicTag.Value = true
		mimicTag.Parent = mimicZone
	end

	-- Cage structures for trapping mimics
	-- Cage 1 (left side)
	local function buildCage(cageName: string, cagePos: Vector3)
		local cageSize = 8
		local barThickness = 0.5
		local barColor = Color3.fromRGB(130, 100, 120)

		-- Floor of cage
		createPart(
			cageName .. "_Floor",
			Vector3.new(cageSize, 0.5, cageSize),
			Vector3.new(cagePos.X, cagePos.Y - 3, cagePos.Z),
			barColor,
			Enum.Material.Fabric,
			stageModel
		)

		-- Vertical bars (4 corners + midpoints)
		local barOffsets = {
			Vector3.new(-cageSize / 2, 0, -cageSize / 2),
			Vector3.new(cageSize / 2, 0, -cageSize / 2),
			Vector3.new(-cageSize / 2, 0, cageSize / 2),
			Vector3.new(cageSize / 2, 0, cageSize / 2),
			Vector3.new(0, 0, -cageSize / 2),
			Vector3.new(0, 0, cageSize / 2),
			Vector3.new(-cageSize / 2, 0, 0),
			Vector3.new(cageSize / 2, 0, 0),
		}

		for j, offset in barOffsets do
			createPart(
				`{cageName}_Bar_{j}`,
				Vector3.new(barThickness, 7, barThickness),
				Vector3.new(cagePos.X + offset.X, cagePos.Y, cagePos.Z + offset.Z),
				barColor,
				Enum.Material.Fabric,
				stageModel
			)
		end

		-- Top of cage (open center for luring mimics in)
		createPart(
			cageName .. "_TopL",
			Vector3.new(cageSize, 0.5, 2),
			Vector3.new(cagePos.X, cagePos.Y + 3.5, cagePos.Z - cageSize / 2 + 1),
			barColor,
			Enum.Material.Fabric,
			stageModel
		)
		createPart(
			cageName .. "_TopR",
			Vector3.new(cageSize, 0.5, 2),
			Vector3.new(cagePos.X, cagePos.Y + 3.5, cagePos.Z + cageSize / 2 - 1),
			barColor,
			Enum.Material.Fabric,
			stageModel
		)
	end

	buildCage("Cage_1", Vector3.new(-12, 5, baseZ + 40))
	buildCage("Cage_2", Vector3.new(12, 5, baseZ + 55))

	-- Pulsing accent floor patches (visual effect for the "alive" theme)
	local accentPositions = {
		Vector3.new(-5, 1.05, baseZ + 30),
		Vector3.new(8, 1.05, baseZ + 45),
		Vector3.new(-3, 1.05, baseZ + 60),
	}
	for i, pos in accentPositions do
		local accent = createPart(
			`PulseAccent_{i}`,
			Vector3.new(5, 0.1, 5),
			pos,
			theme.AccentColor,
			Enum.Material.Neon,
			stageModel
		)
		accent.CanCollide = false
		accent.Transparency = 0.6
	end
end

--[[
	Stage 37 - "The Eraser"
	Corridor with multiple paths. A roaming eraser entity destroys drawings.
	Player must use decoys and alternate routes.
]]
local function buildStage37(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Main corridor floor
	createPart(
		"MainFloor",
		Vector3.new(30, 2, 80),
		Vector3.new(0, 0, baseZ + 50),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Side walls
	createPart(
		"WallL",
		Vector3.new(3, 14, 80),
		Vector3.new(-16.5, 7, baseZ + 50),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)
	createPart(
		"WallR",
		Vector3.new(3, 14, 80),
		Vector3.new(16.5, 7, baseZ + 50),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)

	-- Central divider wall creating the main path split
	createPart(
		"CentralDivider",
		Vector3.new(3, 10, 40),
		Vector3.new(0, 5, baseZ + 45),
		Color3.fromRGB(150, 115, 135),
		Enum.Material.Fabric,
		stageModel
	)

	-- Left side path (wider, main route - where eraser patrols)
	-- Partial walls creating turns
	createPart(
		"LeftPathWall_1",
		Vector3.new(6, 8, 2),
		Vector3.new(-8, 4, baseZ + 35),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)
	createPart(
		"LeftPathWall_2",
		Vector3.new(6, 8, 2),
		Vector3.new(-8, 4, baseZ + 55),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)

	-- Right side path (narrower, tighter route)
	createPart(
		"RightPathWall_1",
		Vector3.new(5, 8, 2),
		Vector3.new(8, 4, baseZ + 32),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)
	createPart(
		"RightPathWall_2",
		Vector3.new(5, 8, 2),
		Vector3.new(8, 4, baseZ + 48),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)
	createPart(
		"RightPathWall_3",
		Vector3.new(5, 8, 2),
		Vector3.new(8, 4, baseZ + 62),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)

	-- Upper catwalk path (elevated side route)
	createPart(
		"Catwalk",
		Vector3.new(5, 1, 30),
		Vector3.new(12, 7, baseZ + 45),
		Color3.fromRGB(140, 110, 130),
		Enum.Material.Fabric,
		stageModel
	)
	-- Ramp up to catwalk
	local ramp = Instance.new("Part")
	ramp.Name = "CatwalkRamp"
	ramp.Size = Vector3.new(5, 1, 10)
	ramp.Anchored = true
	ramp.CanCollide = true
	ramp.Material = Enum.Material.Fabric
	ramp.Color = Color3.fromRGB(140, 110, 130)
	ramp.TopSurface = Enum.SurfaceType.Smooth
	ramp.BottomSurface = Enum.SurfaceType.Smooth
	ramp.CFrame = CFrame.new(12, 4, baseZ + 28) * CFrame.Angles(math.rad(-20), 0, 0)
	ramp.Parent = stageModel

	-- Eraser spawn point
	local eraserSpawn = Instance.new("Part")
	eraserSpawn.Name = "EraserSpawn"
	eraserSpawn.Size = Vector3.new(4, 6, 4)
	eraserSpawn.Position = Vector3.new(-7, 4, baseZ + 45)
	eraserSpawn.Anchored = true
	eraserSpawn.CanCollide = false
	eraserSpawn.Transparency = 0.8
	eraserSpawn.Color = Color3.fromRGB(255, 255, 255)
	eraserSpawn.Material = Enum.Material.SmoothPlastic
	eraserSpawn.Parent = stageModel

	local enemyType = Instance.new("StringValue")
	enemyType.Name = "EnemyType"
	enemyType.Value = "eraser"
	enemyType.Parent = eraserSpawn

	-- Patrol points for the eraser (walks left path)
	local patrolA = Instance.new("Part")
	patrolA.Name = "PatrolA"
	patrolA.Size = Vector3.new(1, 1, 1)
	patrolA.Position = Vector3.new(-7, 2, baseZ + 25)
	patrolA.Anchored = true
	patrolA.CanCollide = false
	patrolA.Transparency = 1
	patrolA.Parent = stageModel

	local patrolB = Instance.new("Part")
	patrolB.Name = "PatrolB"
	patrolB.Size = Vector3.new(1, 1, 1)
	patrolB.Position = Vector3.new(-7, 2, baseZ + 65)
	patrolB.Anchored = true
	patrolB.CanCollide = false
	patrolB.Transparency = 1
	patrolB.Parent = stageModel

	-- Eraser zones (areas where drawings get destroyed on contact)
	local eraserZoneData = {
		{ pos = Vector3.new(-7, 4, baseZ + 30), size = Vector3.new(12, 8, 10) },
		{ pos = Vector3.new(-7, 4, baseZ + 45), size = Vector3.new(12, 8, 10) },
		{ pos = Vector3.new(-7, 4, baseZ + 60), size = Vector3.new(12, 8, 10) },
	}

	for i, zd in eraserZoneData do
		local eraserZone = Instance.new("Part")
		eraserZone.Name = `EraserZone_{i}`
		eraserZone.Size = zd.size
		eraserZone.Position = zd.pos
		eraserZone.Anchored = true
		eraserZone.CanCollide = false
		eraserZone.Transparency = 1
		eraserZone.Parent = stageModel

		local eraserTag = Instance.new("BoolValue")
		eraserTag.Name = "IsEraserZone"
		eraserTag.Value = true
		eraserTag.Parent = eraserZone
	end

	-- Organic debris on the floor (erased remnants)
	local remnantColors = {
		Color3.fromRGB(200, 100, 100),
		Color3.fromRGB(100, 200, 100),
		Color3.fromRGB(100, 100, 200),
		Color3.fromRGB(200, 200, 100),
	}
	for i = 1, 6 do
		local rx = math.random(-12, 12)
		local rz = baseZ + 20 + math.random(0, 50)
		local remnant = createPart(
			`ErasedRemnant_{i}`,
			Vector3.new(math.random(1, 3), 0.2, math.random(1, 3)),
			Vector3.new(rx, 1.1, rz),
			remnantColors[(i - 1) % #remnantColors + 1],
			Enum.Material.Fabric,
			stageModel
		)
		remnant.CanCollide = false
		remnant.Transparency = 0.5
	end
end

--[[
	Stage 38 - "The Canvas Thief"
	Room where the player cannot draw (MaxDrawings = 0).
	Must navigate using pre-placed leftover drawings as stepping stones.
]]
local function buildStage38(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Start platform
	createPart(
		"StartFloor",
		Vector3.new(14, 2, 10),
		Vector3.new(0, 0, baseZ + 12),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- End platform (far away and slightly elevated)
	createPart(
		"EndFloor",
		Vector3.new(14, 2, 10),
		Vector3.new(0, 4, baseZ + 82),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Side walls defining the room
	createPart(
		"WallL",
		Vector3.new(3, 18, 80),
		Vector3.new(-18.5, 9, baseZ + 48),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)
	createPart(
		"WallR",
		Vector3.new(3, 18, 80),
		Vector3.new(18.5, 9, baseZ + 48),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)

	-- No floor in between! Just a void with leftover drawings as platforms

	-- Kill zone below
	local voidKill = Instance.new("Part")
	voidKill.Name = "VoidKillZone"
	voidKill.Size = Vector3.new(40, 4, 60)
	voidKill.Position = Vector3.new(0, -20, baseZ + 48)
	voidKill.Anchored = true
	voidKill.CanCollide = false
	voidKill.Transparency = 1
	voidKill.Parent = stageModel

	local voidKillTag = Instance.new("BoolValue")
	voidKillTag.Name = "IsKillZone"
	voidKillTag.Value = true
	voidKillTag.Parent = voidKill

	-- Pre-placed "leftover drawings" as stepping stones
	-- These are colorful, irregular shapes left by "previous players"
	local leftoverData = {
		-- Path A: Main stepping stone route
		{
			name = "LeftoverDrawing_1",
			size = Vector3.new(6, 1, 4),
			pos = Vector3.new(-2, 1, baseZ + 22),
			color = Color3.fromRGB(255, 120, 80),
		},
		{
			name = "LeftoverDrawing_2",
			size = Vector3.new(4, 1, 5),
			pos = Vector3.new(5, 2, baseZ + 30),
			color = Color3.fromRGB(80, 200, 120),
		},
		{
			name = "LeftoverDrawing_3",
			size = Vector3.new(5, 1, 3),
			pos = Vector3.new(-3, 3, baseZ + 38),
			color = Color3.fromRGB(120, 80, 255),
		},
		{
			name = "LeftoverDrawing_4",
			size = Vector3.new(3, 1, 6),
			pos = Vector3.new(4, 2, baseZ + 46),
			color = Color3.fromRGB(255, 200, 50),
		},
		{
			name = "LeftoverDrawing_5",
			size = Vector3.new(5, 1, 4),
			pos = Vector3.new(-1, 3, baseZ + 54),
			color = Color3.fromRGB(200, 80, 200),
		},
		{
			name = "LeftoverDrawing_6",
			size = Vector3.new(4, 1, 5),
			pos = Vector3.new(6, 4, baseZ + 62),
			color = Color3.fromRGB(80, 180, 255),
		},
		{
			name = "LeftoverDrawing_7",
			size = Vector3.new(6, 1, 3),
			pos = Vector3.new(-2, 4, baseZ + 70),
			color = Color3.fromRGB(255, 150, 150),
		},

		-- Path B: Alternative route (harder, more spread out)
		{
			name = "LeftoverDrawing_8",
			size = Vector3.new(3, 1, 3),
			pos = Vector3.new(-10, 3, baseZ + 26),
			color = Color3.fromRGB(100, 255, 100),
		},
		{
			name = "LeftoverDrawing_9",
			size = Vector3.new(4, 1, 3),
			pos = Vector3.new(-8, 5, baseZ + 40),
			color = Color3.fromRGB(255, 100, 255),
		},
		{
			name = "LeftoverDrawing_10",
			size = Vector3.new(3, 1, 4),
			pos = Vector3.new(-11, 4, baseZ + 55),
			color = Color3.fromRGB(255, 255, 100),
		},
		{
			name = "LeftoverDrawing_11",
			size = Vector3.new(5, 1, 3),
			pos = Vector3.new(-6, 5, baseZ + 68),
			color = Color3.fromRGB(100, 200, 255),
		},

		-- Decoy platforms (too far apart to reach, or dead ends)
		{
			name = "LeftoverDrawing_12",
			size = Vector3.new(3, 1, 3),
			pos = Vector3.new(12, 6, baseZ + 35),
			color = Color3.fromRGB(150, 150, 150),
		},
		{
			name = "LeftoverDrawing_13",
			size = Vector3.new(2, 1, 2),
			pos = Vector3.new(14, 8, baseZ + 50),
			color = Color3.fromRGB(180, 180, 180),
		},
	}

	for _, ld in leftoverData do
		local leftover = createPart(ld.name, ld.size, ld.pos, ld.color, Enum.Material.SmoothPlastic, stageModel)

		local leftoverTag = Instance.new("BoolValue")
		leftoverTag.Name = "IsLeftoverDrawing"
		leftoverTag.Value = true
		leftoverTag.Parent = leftover

		-- Give them a slight glow/neon outline effect
		local highlight = Instance.new("SurfaceLight")
		highlight.Name = "DrawingGlow"
		highlight.Color = ld.color
		highlight.Brightness = 0.4
		highlight.Range = 6
		highlight.Parent = leftover
	end

	-- Faded "ghost" drawings on the walls (pure decoration, non-collidable)
	local ghostColors = {
		Color3.fromRGB(180, 140, 160),
		Color3.fromRGB(160, 140, 180),
		Color3.fromRGB(180, 160, 140),
	}
	for i = 1, 4 do
		local side = (i % 2 == 0) and 17 or -17
		local ghost = createPart(
			`GhostDrawing_{i}`,
			Vector3.new(0.3, 4, 6),
			Vector3.new(side, 8, baseZ + 20 + i * 12),
			ghostColors[(i - 1) % #ghostColors + 1],
			Enum.Material.Neon,
			stageModel
		)
		ghost.CanCollide = false
		ghost.Transparency = 0.7
	end
end

--[[
	Stage 39 - "The Shape-Shifter"
	Circular arena with a core that shifts between four forms every 15 seconds.
	Each form presents a different obstacle type.
]]
local function buildStage39(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Arena floor (large, roughly circular using octagonal approximation)
	createPart(
		"ArenaFloor_Center",
		Vector3.new(32, 2, 32),
		Vector3.new(0, 0, baseZ + 50),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	-- Corner fillers to approximate a circle
	createPart(
		"ArenaFloor_NW",
		Vector3.new(10, 2, 10),
		Vector3.new(-16, 0, baseZ + 34),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	createPart(
		"ArenaFloor_NE",
		Vector3.new(10, 2, 10),
		Vector3.new(16, 0, baseZ + 34),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	createPart(
		"ArenaFloor_SW",
		Vector3.new(10, 2, 10),
		Vector3.new(-16, 0, baseZ + 66),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	createPart(
		"ArenaFloor_SE",
		Vector3.new(10, 2, 10),
		Vector3.new(16, 0, baseZ + 66),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Entry corridor
	createPart(
		"EntryFloor",
		Vector3.new(10, 2, 16),
		Vector3.new(0, 0, baseZ + 18),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Exit corridor
	createPart(
		"ExitFloor",
		Vector3.new(10, 2, 16),
		Vector3.new(0, 0, baseZ + 82),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Arena walls (curved approximation)
	createPart(
		"ArenaWallN",
		Vector3.new(36, 14, 3),
		Vector3.new(0, 7, baseZ + 27),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)
	createPart(
		"ArenaWallS",
		Vector3.new(36, 14, 3),
		Vector3.new(0, 7, baseZ + 73),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)
	createPart(
		"ArenaWallW",
		Vector3.new(3, 14, 44),
		Vector3.new(-20, 7, baseZ + 50),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)
	createPart(
		"ArenaWallE",
		Vector3.new(3, 14, 44),
		Vector3.new(20, 7, baseZ + 50),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)

	-- Entry and exit openings in the walls
	-- (The N wall and S wall have gaps in their centers for corridors)
	-- Entry gap decoration
	createPart(
		"EntryArchL",
		Vector3.new(2, 10, 3),
		Vector3.new(-6, 5, baseZ + 27),
		theme.AccentColor,
		Enum.Material.Neon,
		stageModel
	)
	createPart(
		"EntryArchR",
		Vector3.new(2, 10, 3),
		Vector3.new(6, 5, baseZ + 27),
		theme.AccentColor,
		Enum.Material.Neon,
		stageModel
	)
	createPart(
		"ExitArchL",
		Vector3.new(2, 10, 3),
		Vector3.new(-6, 5, baseZ + 73),
		theme.AccentColor,
		Enum.Material.Neon,
		stageModel
	)
	createPart(
		"ExitArchR",
		Vector3.new(2, 10, 3),
		Vector3.new(6, 5, baseZ + 73),
		theme.AccentColor,
		Enum.Material.Neon,
		stageModel
	)

	-- Shape-Shifter Core in the center
	local core = createPart(
		"ShapeShifterCore",
		Vector3.new(6, 8, 6),
		Vector3.new(0, 5, baseZ + 50),
		theme.AccentColor,
		Enum.Material.Neon,
		stageModel
	)

	local shapeTag = Instance.new("BoolValue")
	shapeTag.Name = "IsShapeShifter"
	shapeTag.Value = true
	shapeTag.Parent = core

	local shiftInterval = Instance.new("NumberValue")
	shiftInterval.Name = "ShiftInterval"
	shiftInterval.Value = 15
	shiftInterval.Parent = core

	-- Form 1: Wall configuration (walls that box the player in)
	local formWall = Instance.new("Model")
	formWall.Name = "Form_wall"
	formWall.Parent = stageModel

	local wallParts = {
		{ name = "ShiftWall_1", size = Vector3.new(20, 10, 2), pos = Vector3.new(0, 5, baseZ + 40) },
		{ name = "ShiftWall_2", size = Vector3.new(20, 10, 2), pos = Vector3.new(0, 5, baseZ + 60) },
		{ name = "ShiftWall_3", size = Vector3.new(2, 10, 18), pos = Vector3.new(-10, 5, baseZ + 50) },
		{ name = "ShiftWall_4", size = Vector3.new(2, 10, 18), pos = Vector3.new(10, 5, baseZ + 50) },
	}
	for _, wp in wallParts do
		local w = createPart(wp.name, wp.size, wp.pos, Color3.fromRGB(200, 80, 80), Enum.Material.Fabric, formWall)
		w.Transparency = 1 -- Initially invisible
		w.CanCollide = false -- Initially non-collidable
	end

	-- Form 2: Gap configuration (floor disappears, gaps appear)
	local formGap = Instance.new("Model")
	formGap.Name = "Form_gap"
	formGap.Parent = stageModel

	local gapKillZones = {
		{ name = "GapKill_1", size = Vector3.new(12, 4, 8), pos = Vector3.new(-8, -2, baseZ + 42) },
		{ name = "GapKill_2", size = Vector3.new(12, 4, 8), pos = Vector3.new(8, -2, baseZ + 55) },
		{ name = "GapKill_3", size = Vector3.new(8, 4, 12), pos = Vector3.new(0, -2, baseZ + 50) },
	}
	for _, gk in gapKillZones do
		local gapPart = Instance.new("Part")
		gapPart.Name = gk.name
		gapPart.Size = gk.size
		gapPart.Position = gk.pos
		gapPart.Anchored = true
		gapPart.CanCollide = false
		gapPart.Transparency = 1
		gapPart.Parent = formGap

		local gapTag = Instance.new("BoolValue")
		gapTag.Name = "IsKillZone"
		gapTag.Value = true
		gapTag.Parent = gapPart
	end

	-- Form 3: Flood configuration (rising water markers)
	local formFlood = Instance.new("Model")
	formFlood.Name = "Form_flood"
	formFlood.Parent = stageModel

	local floodWater = Instance.new("Part")
	floodWater.Name = "FloodWater"
	floodWater.Size = Vector3.new(34, 1, 34)
	floodWater.Position = Vector3.new(0, 0.5, baseZ + 50)
	floodWater.Anchored = true
	floodWater.CanCollide = false
	floodWater.Transparency = 1
	floodWater.Color = Color3.fromRGB(60, 100, 180)
	floodWater.Material = Enum.Material.Glass
	floodWater.Parent = formFlood

	local floodTag = Instance.new("BoolValue")
	floodTag.Name = "IsFloodZone"
	floodTag.Value = true
	floodTag.Parent = floodWater

	local floodRiseRate = Instance.new("NumberValue")
	floodRiseRate.Name = "RiseRate"
	floodRiseRate.Value = 2 -- Studs per second
	floodRiseRate.Parent = floodWater

	-- Elevated safety platforms for flood form
	local safetyPlat1 = createPart(
		"FloodSafety_1",
		Vector3.new(4, 1, 4),
		Vector3.new(-10, 8, baseZ + 42),
		Color3.fromRGB(80, 200, 80),
		Enum.Material.Neon,
		formFlood
	)
	safetyPlat1.Transparency = 1
	safetyPlat1.CanCollide = false

	local safetyPlat2 = createPart(
		"FloodSafety_2",
		Vector3.new(4, 1, 4),
		Vector3.new(10, 8, baseZ + 58),
		Color3.fromRGB(80, 200, 80),
		Enum.Material.Neon,
		formFlood
	)
	safetyPlat2.Transparency = 1
	safetyPlat2.CanCollide = false

	-- Form 4: Enemy configuration (spawn points)
	local formEnemy = Instance.new("Model")
	formEnemy.Name = "Form_enemy"
	formEnemy.Parent = stageModel

	local enemySpawns = {
		{ name = "FormEnemy_1", pos = Vector3.new(-8, 4, baseZ + 40) },
		{ name = "FormEnemy_2", pos = Vector3.new(8, 4, baseZ + 40) },
		{ name = "FormEnemy_3", pos = Vector3.new(-8, 4, baseZ + 60) },
		{ name = "FormEnemy_4", pos = Vector3.new(8, 4, baseZ + 60) },
	}
	for _, es in enemySpawns do
		local enemySpawn = Instance.new("Part")
		enemySpawn.Name = es.name
		enemySpawn.Size = Vector3.new(3, 5, 3)
		enemySpawn.Position = es.pos
		enemySpawn.Anchored = true
		enemySpawn.CanCollide = false
		enemySpawn.Transparency = 1
		enemySpawn.Color = Color3.fromRGB(255, 0, 0)
		enemySpawn.Parent = formEnemy

		local eType = Instance.new("StringValue")
		eType.Name = "EnemyType"
		eType.Value = "mimic"
		eType.Parent = enemySpawn
	end

	-- Pulsing ring around the core for visual flair
	local coreRing = createPart(
		"CoreRing",
		Vector3.new(12, 0.3, 12),
		Vector3.new(0, 1.15, baseZ + 50),
		theme.AccentColor,
		Enum.Material.Neon,
		stageModel
	)
	coreRing.CanCollide = false
	coreRing.Transparency = 0.3
end

--[[
	Stage 40 - "The Reflection"
	Room split by a mirrored wall. Obstacles on the right side,
	but drawings appear mirrored on the left side.
]]
local function buildStage40(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Full room floor
	createPart(
		"Floor",
		Vector3.new(36, 2, 80),
		Vector3.new(0, 0, baseZ + 50),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Mirror wall down the center (Glass material, semi-transparent)
	local mirrorWall = createPart(
		"MirrorWall",
		Vector3.new(1, 16, 70),
		Vector3.new(0, 8, baseZ + 45),
		Color3.fromRGB(200, 210, 220),
		Enum.Material.Glass,
		stageModel
	)
	mirrorWall.Transparency = 0.3
	mirrorWall.Reflectance = 0.8

	-- Side walls
	createPart(
		"WallL",
		Vector3.new(3, 16, 80),
		Vector3.new(-19.5, 8, baseZ + 50),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)
	createPart(
		"WallR",
		Vector3.new(3, 16, 80),
		Vector3.new(19.5, 8, baseZ + 50),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)

	-- Back wall
	createPart(
		"WallBack",
		Vector3.new(42, 16, 3),
		Vector3.new(0, 8, baseZ + 8),
		theme.WallColor,
		Enum.Material.Fabric,
		stageModel
	)

	-- Mirror zone on the LEFT side (drawings placed here get mirrored to the right)
	local mirrorZone = Instance.new("Part")
	mirrorZone.Name = "MirrorZone"
	mirrorZone.Size = Vector3.new(18, 14, 70)
	mirrorZone.Position = Vector3.new(-9, 7, baseZ + 45)
	mirrorZone.Anchored = true
	mirrorZone.CanCollide = false
	mirrorZone.Transparency = 1
	mirrorZone.Parent = stageModel

	local mirrorTag = Instance.new("BoolValue")
	mirrorTag.Name = "IsMirrorZone"
	mirrorTag.Value = true
	mirrorTag.Parent = mirrorZone

	-- === RIGHT SIDE OBSTACLES (the actual challenge) ===
	-- The player is on the right side, obstacles block their path

	-- Gap in the floor (right side only)
	local gapKill = Instance.new("Part")
	gapKill.Name = "RightGapKill"
	gapKill.Size = Vector3.new(16, 4, 12)
	gapKill.Position = Vector3.new(9, -2, baseZ + 35)
	gapKill.Anchored = true
	gapKill.CanCollide = false
	gapKill.Transparency = 1
	gapKill.Parent = stageModel

	local gapKillTag = Instance.new("BoolValue")
	gapKillTag.Name = "IsKillZone"
	gapKillTag.Value = true
	gapKillTag.Parent = gapKill

	-- Remove the floor section where the gap is
	-- Floor before gap (right side)
	createPart(
		"FloorR_Before",
		Vector3.new(16, 2, 16),
		Vector3.new(9, 0, baseZ + 20),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	-- Floor after gap (right side)
	createPart(
		"FloorR_After",
		Vector3.new(16, 2, 38),
		Vector3.new(9, 0, baseZ + 60),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Wall obstacle on the right side
	createPart(
		"RightWall_1",
		Vector3.new(14, 12, 3),
		Vector3.new(9, 6, baseZ + 50),
		Color3.fromRGB(180, 140, 160),
		Enum.Material.Fabric,
		stageModel
	)

	-- Small gap in the wall (player needs to figure out how to get through)
	-- Wall with hole: left piece + right piece + top piece
	createPart(
		"RightWall_2_L",
		Vector3.new(5, 12, 3),
		Vector3.new(4, 6, baseZ + 65),
		Color3.fromRGB(170, 130, 150),
		Enum.Material.Fabric,
		stageModel
	)
	createPart(
		"RightWall_2_R",
		Vector3.new(5, 12, 3),
		Vector3.new(14, 6, baseZ + 65),
		Color3.fromRGB(170, 130, 150),
		Enum.Material.Fabric,
		stageModel
	)
	createPart(
		"RightWall_2_Top",
		Vector3.new(4, 5, 3),
		Vector3.new(9, 9.5, baseZ + 65),
		Color3.fromRGB(170, 130, 150),
		Enum.Material.Fabric,
		stageModel
	)

	-- === LEFT SIDE (drawing canvas area, mostly open) ===
	-- Left floor is continuous
	createPart(
		"FloorL",
		Vector3.new(16, 2, 70),
		Vector3.new(-9, 0, baseZ + 45),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Visual markers showing where drawings will appear on the right
	local markerPositions = {
		Vector3.new(-9, 1.1, baseZ + 35),
		Vector3.new(-9, 1.1, baseZ + 50),
		Vector3.new(-9, 1.1, baseZ + 65),
	}
	for i, pos in markerPositions do
		local marker = createPart(
			`MirrorMarker_{i}`,
			Vector3.new(8, 0.15, 4),
			pos,
			Color3.fromRGB(200, 200, 255),
			Enum.Material.Neon,
			stageModel
		)
		marker.CanCollide = false
		marker.Transparency = 0.5
	end

	-- Mirror frame decoration (glowing border around the mirror wall)
	createPart(
		"MirrorFrame_Top",
		Vector3.new(1.5, 1, 72),
		Vector3.new(0, 16.5, baseZ + 45),
		theme.AccentColor,
		Enum.Material.Neon,
		stageModel
	)
	createPart(
		"MirrorFrame_Bottom",
		Vector3.new(1.5, 1, 72),
		Vector3.new(0, 1.5, baseZ + 45),
		theme.AccentColor,
		Enum.Material.Neon,
		stageModel
	)

	-- Reflection distortion decoration (wavy fabric parts near the mirror)
	for i = 1, 5 do
		local distortion = createPart(
			`Distortion_{i}`,
			Vector3.new(0.5, 2, 3),
			Vector3.new(-0.5, 3 + i * 2.5, baseZ + 20 + i * 10),
			Color3.fromRGB(220, 180, 200),
			Enum.Material.Neon,
			stageModel
		)
		distortion.CanCollide = false
		distortion.Transparency = 0.6
	end
end

-- ================================================================
-- EXPORTS
-- ================================================================

type BuilderFunction = (stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme) -> ()

ZoneBuilders7_8.Builders = {
	[31] = buildStage31,
	[32] = buildStage32,
	[33] = buildStage33,
	[34] = buildStage34,
	[35] = buildStage35,
	[36] = buildStage36,
	[37] = buildStage37,
	[38] = buildStage38,
	[39] = buildStage39,
	[40] = buildStage40,
} :: { [number]: BuilderFunction }

return ZoneBuilders7_8
