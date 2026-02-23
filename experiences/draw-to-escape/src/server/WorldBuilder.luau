--!strict

--[[
	WorldBuilder
	Procedurally generates the physical geometry for each stage.
	Each stage gets a start platform, end platform, and the obstacle
	geometry in between. Zones apply visual themes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local StageConfig = require(ReplicatedStorage.Shared.StageConfig)
local ZoneThemes = require(ReplicatedStorage.Shared.ZoneThemes)

-- Zone builder modules (stages 11-50)
local ZoneBuilders3_4 = require(script.Parent.ZoneBuilders3_4)
local ZoneBuilders5_6 = require(script.Parent.ZoneBuilders5_6)
local ZoneBuilders7_8 = require(script.Parent.ZoneBuilders7_8)
local ZoneBuilders9_10 = require(script.Parent.ZoneBuilders9_10)

local WorldBuilder = {}
WorldBuilder.__index = WorldBuilder

type WorldBuilderImpl = {
	StageModels: { [number]: Model },
	StagesFolder: Folder,
}

function WorldBuilder.new(): WorldBuilderImpl
	local self = setmetatable({}, WorldBuilder) :: any
	self.StageModels = {}

	local folder = Instance.new("Folder")
	folder.Name = "Stages"
	folder.Parent = workspace
	self.StagesFolder = folder

	return self :: WorldBuilderImpl
end

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

-- Creates the kill zone below a stage
local function createKillZone(stageModel: Model, baseZ: number, width: number, length: number)
	local killPart = Instance.new("Part")
	killPart.Name = "KillZone"
	killPart.Size = Vector3.new(width + 40, 2, length + 40)
	killPart.Position = Vector3.new(0, Constants.DEATH_Y_THRESHOLD, baseZ + length / 2)
	killPart.Anchored = true
	killPart.CanCollide = false
	killPart.Transparency = 1
	killPart.Parent = stageModel

	-- Tag it for detection
	local tag = Instance.new("BoolValue")
	tag.Name = "IsKillZone"
	tag.Value = true
	tag.Parent = killPart
end

-- Standard start/end platforms
local function createEndpoints(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme, stageLength: number)
	-- Start platform
	createPart(
		"StartPlatform",
		Vector3.new(16, 2, 16),
		Vector3.new(0, 0, baseZ),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Spawn point on start platform
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "StageSpawn"
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 1.5, baseZ)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Enabled = false
	spawn.Parent = stageModel

	-- End platform with completion trigger
	createPart(
		"EndPlatform",
		Vector3.new(16, 2, 16),
		Vector3.new(0, 0, baseZ + stageLength),
		Color3.fromRGB(80, 200, 80),
		Enum.Material.Neon,
		stageModel
	)

	-- Completion trigger zone
	local trigger = Instance.new("Part")
	trigger.Name = "CompletionTrigger"
	trigger.Size = Vector3.new(16, 10, 4)
	trigger.Position = Vector3.new(0, 5, baseZ + stageLength)
	trigger.Anchored = true
	trigger.CanCollide = false
	trigger.Transparency = 1
	trigger.Parent = stageModel

	local triggerTag = Instance.new("BoolValue")
	triggerTag.Name = "IsCompletionTrigger"
	triggerTag.Value = true
	triggerTag.Parent = trigger
end

-- ================================================================
-- STAGE GEOMETRY BUILDERS
-- Each function builds the obstacle for a specific stage type
-- ================================================================

local function buildStage_TheStep(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- A simple waist-high ledge between start and end
	createPart(
		"Floor",
		Vector3.new(20, 2, 40),
		Vector3.new(0, 0, baseZ + 30),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	createPart(
		"Ledge",
		Vector3.new(20, 6, 4),
		Vector3.new(0, 3, baseZ + 45),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"FloorAfter",
		Vector3.new(20, 2, 30),
		Vector3.new(0, 0, baseZ + 65),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
end

local function buildStage_ThePuddle(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Floor with a water gap
	createPart(
		"Floor1",
		Vector3.new(20, 2, 25),
		Vector3.new(0, 0, baseZ + 20),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	-- Water puddle (blue, non-collidable — touching = death)
	local water = createPart(
		"Puddle",
		Vector3.new(14, 1, 12),
		Vector3.new(0, 0.5, baseZ + 42),
		Color3.fromRGB(60, 120, 200),
		Enum.Material.Glass,
		stageModel
	)
	water.CanCollide = false

	local killTag = Instance.new("BoolValue")
	killTag.Name = "IsKillZone"
	killTag.Value = true
	killTag.Parent = water

	createPart(
		"Floor2",
		Vector3.new(20, 2, 25),
		Vector3.new(0, 0, baseZ + 60),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
end

local function buildStage_TheGap(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Two platforms with a gap between
	createPart(
		"Platform1",
		Vector3.new(20, 2, 30),
		Vector3.new(0, 0, baseZ + 20),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	-- Gap of 15 studs
	createPart(
		"Platform2",
		Vector3.new(20, 2, 30),
		Vector3.new(0, 0, baseZ + 65),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
end

local function buildStage_TheLockedDoor(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Floor leading to a door with a keyhole
	createPart(
		"Floor",
		Vector3.new(20, 2, 70),
		Vector3.new(0, 0, baseZ + 45),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Door wall
	createPart(
		"DoorWallL",
		Vector3.new(7, 14, 3),
		Vector3.new(-6.5, 7, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"DoorWallR",
		Vector3.new(7, 14, 3),
		Vector3.new(6.5, 7, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"DoorTop",
		Vector3.new(6, 4, 3),
		Vector3.new(0, 12, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Keyhole trigger (place a drawing here to unlock)
	local keyhole = Instance.new("Part")
	keyhole.Name = "KeyholeTrigger"
	keyhole.Size = Vector3.new(4, 4, 3)
	keyhole.Position = Vector3.new(0, 6, baseZ + 50)
	keyhole.Anchored = true
	keyhole.CanCollide = false
	keyhole.Transparency = 0.5
	keyhole.Color = Color3.fromRGB(255, 200, 0)
	keyhole.Material = Enum.Material.Neon
	keyhole.Parent = stageModel

	local puzzleTag = Instance.new("BoolValue")
	puzzleTag.Name = "IsPuzzleTrigger"
	puzzleTag.Value = true
	puzzleTag.Parent = keyhole
end

local function buildStage_TheHeavyButton(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	-- Floor with a pressure plate and a gate
	createPart(
		"Floor",
		Vector3.new(20, 2, 70),
		Vector3.new(0, 0, baseZ + 45),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Pressure plate (glowing)
	local plate = createPart(
		"PressurePlate",
		Vector3.new(6, 0.5, 6),
		Vector3.new(-5, 1.25, baseZ + 40),
		Color3.fromRGB(255, 80, 80),
		Enum.Material.Neon,
		stageModel
	)

	local weightTag = Instance.new("NumberValue")
	weightTag.Name = "RequiredWeight"
	weightTag.Value = 50
	weightTag.Parent = plate

	local puzzleTag = Instance.new("BoolValue")
	puzzleTag.Name = "IsPressurePlate"
	puzzleTag.Value = true
	puzzleTag.Parent = plate

	-- Gate (blocks until plate is pressed)
	local gate = createPart(
		"Gate",
		Vector3.new(20, 14, 3),
		Vector3.new(0, 7, baseZ + 55),
		Color3.fromRGB(150, 50, 50),
		theme.WallMaterial,
		stageModel
	)

	local gateTag = Instance.new("BoolValue")
	gateTag.Name = "IsGate"
	gateTag.Value = true
	gateTag.Parent = gate
end

local function buildStage_TheTallWall(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	createPart(
		"Floor",
		Vector3.new(20, 2, 80),
		Vector3.new(0, 0, baseZ + 50),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	createPart(
		"TallWall",
		Vector3.new(20, 20, 4),
		Vector3.new(0, 10, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
end

local function buildStage_TheWindyBridge(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	createPart(
		"Start",
		Vector3.new(20, 2, 20),
		Vector3.new(0, 0, baseZ + 15),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	-- Narrow bridge
	createPart(
		"Bridge",
		Vector3.new(4, 1, 50),
		Vector3.new(0, 0, baseZ + 50),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	createPart(
		"End",
		Vector3.new(20, 2, 20),
		Vector3.new(0, 0, baseZ + 80),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- Wind zone marker
	local windZone = Instance.new("Part")
	windZone.Name = "WindZone"
	windZone.Size = Vector3.new(40, 20, 50)
	windZone.Position = Vector3.new(0, 10, baseZ + 50)
	windZone.Anchored = true
	windZone.CanCollide = false
	windZone.Transparency = 1
	windZone.Parent = stageModel

	local windTag = Instance.new("Vector3Value")
	windTag.Name = "WindForce"
	windTag.Value = Vector3.new(80, 0, 0) -- Pushes sideways
	windTag.Parent = windZone
end

local function buildStage_TheFallenTree(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	createPart(
		"Floor",
		Vector3.new(20, 2, 80),
		Vector3.new(0, 0, baseZ + 50),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	-- Giant fallen tree trunk blocking the path
	createPart(
		"TreeTrunk",
		Vector3.new(22, 10, 8),
		Vector3.new(0, 5, baseZ + 50),
		Color3.fromRGB(140, 100, 60),
		Enum.Material.Wood,
		stageModel
	)
	-- Branches making it hard to go over
	createPart(
		"Branch1",
		Vector3.new(8, 3, 3),
		Vector3.new(-4, 12, baseZ + 48),
		Color3.fromRGB(120, 90, 50),
		Enum.Material.Wood,
		stageModel
	)
	createPart(
		"Branch2",
		Vector3.new(8, 3, 3),
		Vector3.new(5, 11, baseZ + 52),
		Color3.fromRGB(120, 90, 50),
		Enum.Material.Wood,
		stageModel
	)
end

local function buildStage_TheBear(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	createPart(
		"Floor",
		Vector3.new(24, 2, 90),
		Vector3.new(0, 0, baseZ + 50),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
	-- Side walls to constrain the path
	createPart(
		"WallL",
		Vector3.new(2, 10, 50),
		Vector3.new(-12, 5, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"WallR",
		Vector3.new(2, 10, 50),
		Vector3.new(12, 5, baseZ + 50),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	-- Bear patrol path marker
	local bearSpawn = Instance.new("Part")
	bearSpawn.Name = "EnemySpawn"
	bearSpawn.Size = Vector3.new(4, 6, 4)
	bearSpawn.Position = Vector3.new(0, 4, baseZ + 50)
	bearSpawn.Anchored = true
	bearSpawn.CanCollide = false
	bearSpawn.Transparency = 0.8
	bearSpawn.Color = Color3.fromRGB(255, 0, 0)
	bearSpawn.Parent = stageModel

	local enemyTag = Instance.new("StringValue")
	enemyTag.Name = "EnemyType"
	enemyTag.Value = "bear"
	enemyTag.Parent = bearSpawn

	local patrolStart = Instance.new("Part")
	patrolStart.Name = "PatrolA"
	patrolStart.Size = Vector3.new(1, 1, 1)
	patrolStart.Position = Vector3.new(-8, 2, baseZ + 50)
	patrolStart.Anchored = true
	patrolStart.CanCollide = false
	patrolStart.Transparency = 1
	patrolStart.Parent = stageModel

	local patrolEnd = Instance.new("Part")
	patrolEnd.Name = "PatrolB"
	patrolEnd.Size = Vector3.new(1, 1, 1)
	patrolEnd.Position = Vector3.new(8, 2, baseZ + 50)
	patrolEnd.Anchored = true
	patrolEnd.CanCollide = false
	patrolEnd.Transparency = 1
	patrolEnd.Parent = stageModel
end

local function buildStage_TheRiverCrossing(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme)
	createPart(
		"Shore1",
		Vector3.new(20, 2, 20),
		Vector3.new(0, 0, baseZ + 15),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)

	-- River (kill zone)
	local river = createPart(
		"River",
		Vector3.new(24, 3, 40),
		Vector3.new(0, -1, baseZ + 50),
		Color3.fromRGB(40, 100, 180),
		Enum.Material.Glass,
		stageModel
	)
	river.CanCollide = false
	river.Transparency = 0.3
	local killTag = Instance.new("BoolValue")
	killTag.Name = "IsWater"
	killTag.Value = true
	killTag.Parent = river

	createPart(
		"Shore2",
		Vector3.new(20, 2, 20),
		Vector3.new(0, 0, baseZ + 80),
		theme.GroundColor,
		theme.GroundMaterial,
		stageModel
	)
end

-- Generic obstacle builder for later stages (creates interesting geometry)
local function buildGenericStage(stageModel: Model, baseZ: number, theme: ZoneThemes.ZoneTheme, _stageId: number)
	local stageLength = Constants.STAGE_LENGTH

	-- Floor with gaps
	local segmentCount = math.random(3, 6)
	local segLength = stageLength / segmentCount

	for i = 0, segmentCount - 1 do
		local hasGap = i > 0 and i < segmentCount - 1 and math.random() > 0.4
		if not hasGap then
			local segZ = baseZ + 10 + i * segLength + segLength / 2
			createPart(
				`Floor_{i}`,
				Vector3.new(math.random(12, 20), 2, segLength - 2),
				Vector3.new(math.random(-3, 3), 0, segZ),
				theme.GroundColor,
				theme.GroundMaterial,
				stageModel
			)
		end
	end

	-- Walls
	local wallCount = math.random(1, 3)
	for i = 1, wallCount do
		local wallZ = baseZ + 20 + math.random(0, math.floor(stageLength - 40))
		local wallHeight = math.random(8, 20)
		createPart(
			`Wall_{i}`,
			Vector3.new(math.random(6, 18), wallHeight, 3),
			Vector3.new(math.random(-5, 5), wallHeight / 2, wallZ),
			theme.WallColor,
			theme.WallMaterial,
			stageModel
		)
	end

	-- Elevated platforms
	local platCount = math.random(0, 3)
	for i = 1, platCount do
		local platZ = baseZ + 15 + math.random(0, math.floor(stageLength - 30))
		createPart(
			`ElevatedPlatform_{i}`,
			Vector3.new(math.random(6, 12), 1, math.random(6, 12)),
			Vector3.new(math.random(-6, 6), math.random(5, 15), platZ),
			theme.AccentColor,
			theme.WallMaterial,
			stageModel
		)
	end
end

-- Map stage IDs to specific builders (Zone 1-2 built-in)
local STAGE_BUILDERS: { [number]: (Model, number, ZoneThemes.ZoneTheme) -> () } = {
	[1] = buildStage_TheStep,
	[2] = buildStage_ThePuddle,
	[3] = buildStage_TheGap,
	[4] = buildStage_TheLockedDoor,
	[5] = buildStage_TheHeavyButton,
	[6] = buildStage_TheTallWall,
	[7] = buildStage_TheWindyBridge,
	[8] = buildStage_TheFallenTree,
	[9] = buildStage_TheBear,
	[10] = buildStage_TheRiverCrossing,
}

-- Merge zone builder modules (stages 11-50)
for stageId, builder in ZoneBuilders3_4.Builders do
	STAGE_BUILDERS[stageId] = builder
end
for stageId, builder in ZoneBuilders5_6.Builders do
	STAGE_BUILDERS[stageId] = builder
end
for stageId, builder in ZoneBuilders7_8.Builders do
	STAGE_BUILDERS[stageId] = builder
end
for stageId, builder in ZoneBuilders9_10.Builders do
	STAGE_BUILDERS[stageId] = builder
end

function WorldBuilder.BuildStage(self: WorldBuilderImpl, stageId: number): Model?
	-- Don't rebuild if already exists
	if self.StageModels[stageId] then
		return self.StageModels[stageId]
	end

	local stageDef = StageConfig.GetStage(stageId)
	if not stageDef then
		return nil
	end

	local theme = ZoneThemes.GetTheme(stageDef.Zone)
	local baseZ = (stageId - 1) * Constants.STAGE_SPACING
	local stageLength = Constants.STAGE_LENGTH

	local stageModel = Instance.new("Model")
	stageModel.Name = `Stage_{stageId}_{stageDef.Name:gsub(" ", "_")}`

	-- Build standard endpoints
	createEndpoints(stageModel, baseZ, theme, stageLength)

	-- Build stage-specific obstacles
	local builder = STAGE_BUILDERS[stageId]
	if builder then
		builder(stageModel, baseZ, theme)
	else
		-- Stages without specific builders get procedural geometry
		buildGenericStage(stageModel, baseZ, theme, stageId)
	end

	-- Kill zone below
	createKillZone(stageModel, baseZ, Constants.STAGE_WIDTH, stageLength)

	-- Stage label
	-- We pass the stageDef data directly
	local labelPart = Instance.new("Part")
	labelPart.Name = "StageLabel"
	labelPart.Size = Vector3.new(1, 1, 1)
	labelPart.Position = Vector3.new(0, 12, baseZ - 5)
	labelPart.Anchored = true
	labelPart.CanCollide = false
	labelPart.Transparency = 1
	labelPart.Parent = stageModel

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(300, 80)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = labelPart

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.6)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = `Stage {stageDef.Id}: {stageDef.Name}`
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 24
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = billboard

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.fromScale(1, 0.4)
	descLabel.Position = UDim2.fromScale(0, 0.6)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = stageDef.Description
	descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	descLabel.TextSize = 14
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextStrokeTransparency = 0.7
	descLabel.TextWrapped = true
	descLabel.Parent = billboard

	-- Side walls to prevent going off-stage
	createPart(
		"BoundaryL",
		Vector3.new(2, Constants.WALL_HEIGHT, stageLength + 40),
		Vector3.new(-Constants.STAGE_WIDTH / 2, Constants.WALL_HEIGHT / 2, baseZ + stageLength / 2),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)
	createPart(
		"BoundaryR",
		Vector3.new(2, Constants.WALL_HEIGHT, stageLength + 40),
		Vector3.new(Constants.STAGE_WIDTH / 2, Constants.WALL_HEIGHT / 2, baseZ + stageLength / 2),
		theme.WallColor,
		theme.WallMaterial,
		stageModel
	)

	stageModel.Parent = self.StagesFolder
	self.StageModels[stageId] = stageModel

	return stageModel
end

function WorldBuilder.BuildZone(self: WorldBuilderImpl, zone: number)
	local startStage = (zone - 1) * Constants.STAGES_PER_ZONE + 1
	local endStage = zone * Constants.STAGES_PER_ZONE

	for stageId = startStage, endStage do
		self:BuildStage(stageId)
	end
end

function WorldBuilder.GetStageModel(self: WorldBuilderImpl, stageId: number): Model?
	return self.StageModels[stageId]
end

function WorldBuilder.ClearStage(self: WorldBuilderImpl, stageId: number)
	local model = self.StageModels[stageId]
	if model and model.Parent then
		model:Destroy()
	end
	self.StageModels[stageId] = nil
end

function WorldBuilder.Destroy(self: WorldBuilderImpl)
	for _, model in self.StageModels do
		if model.Parent then
			model:Destroy()
		end
	end
	self.StageModels = {}

	if self.StagesFolder.Parent then
		self.StagesFolder:Destroy()
	end
end

return WorldBuilder
