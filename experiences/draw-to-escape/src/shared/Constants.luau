--!strict

local Constants = {}

-- Game Info
Constants.GAME_NAME = "Draw to Escape"
Constants.GAME_VERSION = "0.1.0"
Constants.MAX_PLAYERS = 20

-- Drawing
Constants.MAX_STROKES_PER_DRAWING = 50
Constants.MAX_POINTS_PER_STROKE = 200
Constants.DEFAULT_DRAWING_LIFETIME = 30
Constants.CANVAS_WIDTH = 400
Constants.CANVAS_HEIGHT = 300
Constants.MIN_STROKE_THICKNESS = 2
Constants.MAX_STROKE_THICKNESS = 12
Constants.DRAWING_COOLDOWN = 1
Constants.MAX_ACTIVE_DRAWINGS = 5
Constants.DRAWING_SCALE = 0.05 -- Canvas pixels to studs

-- Materials (unlocked by zone progression)
Constants.STARTING_MATERIALS = { "wood", "stone" }
Constants.ZONE_MATERIAL_UNLOCKS = {
	[1] = { "wood", "stone" },
	[2] = { "ice" },
	[3] = { "balloon" },
	[4] = { "rubber" },
	[5] = { "metal" },
	[6] = { "neon" },
	[7] = { "glass" },
	[8] = { "magnet" },
}

-- Stages
Constants.TOTAL_STAGES = 50
Constants.STAGES_PER_ZONE = 5
Constants.TOTAL_ZONES = 10
Constants.CHECKPOINT_INTERVAL = 5

-- Zone Names
Constants.ZONE_NAMES = {
	[1] = "The Sketch Fields",
	[2] = "The Paper Forest",
	[3] = "The Crayon Caverns",
	[4] = "The Watercolor Wetlands",
	[5] = "The Ink Ruins",
	[6] = "The Neon Grid",
	[7] = "The Storm Peaks",
	[8] = "The Living Canvas",
	[9] = "The Void",
	[10] = "The Cliff",
}

-- Stage dimensions
Constants.STAGE_WIDTH = 80
Constants.STAGE_LENGTH = 120
Constants.STAGE_SPACING = 200
Constants.WALL_HEIGHT = 30
Constants.WALL_THICKNESS = 4

-- Death / Jumpscare
Constants.JUMPSCARE_DURATION = 1.5
Constants.RESPAWN_DELAY = 2.5
Constants.DEATH_Y_THRESHOLD = -50
Constants.SCREEN_SHAKE_INTENSITY = 20
Constants.SCREEN_SHAKE_FREQUENCY = 30

-- Star ratings
Constants.STAR_TIME_MULTIPLIER = 1.5 -- Par time * this = 2-star threshold
Constants.CREATIVE_SOLUTION_MIN_TYPES = 3 -- Use 3+ different materials for 3rd star

-- Physics
Constants.MATERIAL_PROPERTIES = {
	wood = {
		Density = 0.5,
		Friction = 0.5,
		Elasticity = 0.2,
		Buoyancy = 0.8,
		RobloxMaterial = Enum.Material.Wood,
		Flammable = true,
		Conductive = false,
		Transparent = false,
		GlowsInDark = false,
	},
	stone = {
		Density = 2.5,
		Friction = 0.7,
		Elasticity = 0.1,
		Buoyancy = -1.0,
		RobloxMaterial = Enum.Material.Slate,
		Flammable = false,
		Conductive = false,
		Transparent = false,
		GlowsInDark = false,
	},
	ice = {
		Density = 0.9,
		Friction = 0.05,
		Elasticity = 0.3,
		Buoyancy = 0.5,
		RobloxMaterial = Enum.Material.Ice,
		Flammable = false,
		Conductive = false,
		Transparent = true,
		GlowsInDark = false,
	},
	balloon = {
		Density = 0.01,
		Friction = 0.3,
		Elasticity = 0.8,
		Buoyancy = 5.0,
		RobloxMaterial = Enum.Material.SmoothPlastic,
		Flammable = true,
		Conductive = false,
		Transparent = false,
		GlowsInDark = false,
	},
	metal = {
		Density = 5.0,
		Friction = 0.4,
		Elasticity = 0.15,
		Buoyancy = -3.0,
		RobloxMaterial = Enum.Material.Metal,
		Flammable = false,
		Conductive = true,
		Transparent = false,
		GlowsInDark = false,
	},
	rubber = {
		Density = 1.1,
		Friction = 0.9,
		Elasticity = 0.9,
		Buoyancy = 0.3,
		RobloxMaterial = Enum.Material.SmoothPlastic,
		Flammable = false,
		Conductive = false,
		Transparent = false,
		GlowsInDark = false,
	},
	glass = {
		Density = 2.2,
		Friction = 0.2,
		Elasticity = 0.05,
		Buoyancy = -1.5,
		RobloxMaterial = Enum.Material.Glass,
		Flammable = false,
		Conductive = false,
		Transparent = true,
		GlowsInDark = false,
	},
	magnet = {
		Density = 4.0,
		Friction = 0.5,
		Elasticity = 0.1,
		Buoyancy = -2.0,
		RobloxMaterial = Enum.Material.Metal,
		Flammable = false,
		Conductive = true,
		Transparent = false,
		GlowsInDark = false,
	},
	neon = {
		Density = 0.3,
		Friction = 0.3,
		Elasticity = 0.4,
		Buoyancy = 0.1,
		RobloxMaterial = Enum.Material.Neon,
		Flammable = false,
		Conductive = false,
		Transparent = false,
		GlowsInDark = true,
	},
}

-- Remote Events
Constants.REMOTES = {
	SubmitDrawing = "SubmitDrawing",
	MaterializeDrawing = "MaterializeDrawing",
	DrawingDespawned = "DrawingDespawned",
	StageCompleted = "StageCompleted",
	PlayerDied = "PlayerDied",
	RequestRespawn = "RequestRespawn",
	SyncProgress = "SyncProgress",
	StageLoaded = "StageLoaded",
	TriggerJumpscare = "TriggerJumpscare",
	OpenCanvas = "OpenCanvas",
	CloseCanvas = "CloseCanvas",
	UpdateTimer = "UpdateTimer",
	ShowHint = "ShowHint",
}

return Constants
