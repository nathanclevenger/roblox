--!strict

--[[
	TheOrigin/Shared - Builder helper functions for The Origin (Level 5).

	Provides Origin-specific primitives: corrupted/organic geometry, pulsing
	walls, impossible architecture, flesh-like surfaces, bioluminescent
	carvings, reality-warped elements, and catacomb stone construction.

	Also re-exports and wraps Hospital/Shared primitives for building
	distorted echoes of previous levels.
]]

local HospitalShared = require(script.Parent.Parent.Hospital.Shared)

local Shared = {}

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

-- Origin color palette
local COLOR_STONE = Color3.fromRGB(55, 50, 45)
local COLOR_STONE_DARK = Color3.fromRGB(35, 30, 28)
local COLOR_STONE_LIGHT = Color3.fromRGB(80, 75, 68)
local COLOR_FLESH = Color3.fromRGB(90, 30, 30)
local COLOR_FLESH_DARK = Color3.fromRGB(55, 18, 18)
local COLOR_FLESH_PALE = Color3.fromRGB(130, 75, 70)
local COLOR_VEIN = Color3.fromRGB(100, 20, 25)
local COLOR_BONE = Color3.fromRGB(160, 150, 130)
local COLOR_BIOLUM = Color3.fromRGB(60, 180, 160)
local COLOR_BIOLUM_BRIGHT = Color3.fromRGB(80, 220, 200)
local COLOR_VOID = Color3.fromRGB(8, 5, 10)
local COLOR_IRON = Color3.fromRGB(90, 85, 80)
local COLOR_CANDLE_GLOW = Color3.fromRGB(255, 180, 80)
local COLOR_WATER_MURKY = Color3.fromRGB(25, 35, 30)
local COLOR_SYMBOL = Color3.fromRGB(50, 160, 140)
local COLOR_CORRUPTED_WALL = Color3.fromRGB(70, 25, 30)
local COLOR_CORRUPTED_FLOOR = Color3.fromRGB(45, 15, 20)
local COLOR_CORRUPTED_CEILING = Color3.fromRGB(60, 20, 25)

-- Structural constants for catacomb geometry
local CATACOMB_WALL_THICKNESS: number = 1.5
local CATACOMB_CORRIDOR_WIDTH: number = 4
local CATACOMB_CORRIDOR_HEIGHT: number = 4.5
local WARREN_TUNNEL_WIDTH: number = 3
local WARREN_TUNNEL_HEIGHT: number = 3.5
local NARROW_WIDTH: number = 2
local NARROW_HEIGHT: number = 2

-- Y levels (descending from hospital basement at Y = -12)
local ENTRY_Y: number = -24
local CATACOMB_Y: number = -36
local WARREN_Y: number = -52
local SANCTUARY_Y: number = -72

------------------------------------------------------------------------
-- Type Definitions
------------------------------------------------------------------------

export type HidingSpotData = HospitalShared.HidingSpotData

export type FloorData = {
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } },
}

------------------------------------------------------------------------
-- Re-exported Hospital builders (for echo/fragment construction)
------------------------------------------------------------------------

Shared.createRoom = HospitalShared.createRoom
Shared.createCorridor = HospitalShared.createCorridor
Shared.createDoor = HospitalShared.createDoor
Shared.createFurniture = HospitalShared.createFurniture
Shared.createStairwell = HospitalShared.createStairwell
Shared.createCurtain = HospitalShared.createCurtain
Shared.createPipe = HospitalShared.createPipe
Shared.createHidingSpot = HospitalShared.createHidingSpot

------------------------------------------------------------------------
-- Primitive: generic styled Part
------------------------------------------------------------------------

function Shared.createPart(
	parent: Instance,
	name: string,
	position: Vector3,
	size: Vector3,
	color: Color3?,
	transparency: number?,
	material: Enum.Material?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color or COLOR_STONE
	part.Transparency = transparency or 0
	part.Material = material or Enum.Material.Slate
	part.Parent = parent
	return part
end

------------------------------------------------------------------------
-- Origin-specific: Stone Wall (rough catacomb stone)
------------------------------------------------------------------------

function Shared.createStoneWall(
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string?
): Part
	local wall = Instance.new("Part")
	wall.Name = name or "StoneWall"
	wall.Size = size
	wall.Position = position
	wall.Anchored = true
	wall.Material = Enum.Material.Slate
	wall.Color = COLOR_STONE
	wall.Parent = parent
	return wall
end

------------------------------------------------------------------------
-- Origin-specific: Stone Floor (rough flagstone)
------------------------------------------------------------------------

function Shared.createStoneFloor(
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string?
): Part
	local floor = Instance.new("Part")
	floor.Name = name or "StoneFloor"
	floor.Size = size
	floor.Position = position
	floor.Anchored = true
	floor.Material = Enum.Material.Cobblestone
	floor.Color = COLOR_STONE_DARK
	floor.Parent = parent
	return floor
end

------------------------------------------------------------------------
-- Origin-specific: Stone Ceiling (rough)
------------------------------------------------------------------------

function Shared.createStoneCeiling(
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string?
): Part
	local ceiling = Instance.new("Part")
	ceiling.Name = name or "StoneCeiling"
	ceiling.Size = size
	ceiling.Position = position
	ceiling.Anchored = true
	ceiling.Material = Enum.Material.Slate
	ceiling.Color = COLOR_STONE
	ceiling.Parent = parent
	return ceiling
end

------------------------------------------------------------------------
-- Origin-specific: Flesh Wall (organic surface, pulsing)
------------------------------------------------------------------------

--[[
	Creates a wall segment that simulates organic/biological tissue.
	Uses dark red coloring with Corroded Metal material. Attaches a
	pulsing PointLight to simulate living tissue illumination.
]]
function Shared.createFleshWall(
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string?
): Part
	local wall = Instance.new("Part")
	wall.Name = name or "FleshWall"
	wall.Size = size
	wall.Position = position
	wall.Anchored = true
	wall.Material = Enum.Material.CorrodesMetal
	wall.Color = COLOR_FLESH
	wall.Parent = parent

	-- Subtle pulsing glow to simulate living tissue
	local pulseLight = Instance.new("PointLight")
	pulseLight.Name = "PulseLight"
	pulseLight.Brightness = 0.15
	pulseLight.Color = COLOR_VEIN
	pulseLight.Range = 6
	pulseLight.Shadows = false
	pulseLight.Parent = wall

	return wall
end

------------------------------------------------------------------------
-- Origin-specific: Flesh Floor
------------------------------------------------------------------------

function Shared.createFleshFloor(
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string?
): Part
	local floor = Instance.new("Part")
	floor.Name = name or "FleshFloor"
	floor.Size = size
	floor.Position = position
	floor.Anchored = true
	floor.Material = Enum.Material.CorrodesMetal
	floor.Color = COLOR_FLESH_DARK
	floor.Parent = parent
	return floor
end

------------------------------------------------------------------------
-- Origin-specific: Vein / Tendril
------------------------------------------------------------------------

--[[
	Creates an organic vein or tendril element on surfaces.
	Uses cylinder shape to suggest biological tubing.
]]
function Shared.createVein(
	position: Vector3,
	length: number,
	radius: number,
	orientation: Vector3,
	parent: Instance,
	name: string?
): Part
	local vein = Instance.new("Part")
	vein.Name = name or "Vein"
	vein.Shape = Enum.PartType.Cylinder
	vein.Size = Vector3.new(length, radius * 2, radius * 2)
	vein.Position = position
	vein.Orientation = orientation
	vein.Anchored = true
	vein.Material = Enum.Material.CorrodesMetal
	vein.Color = COLOR_VEIN
	vein.Parent = parent
	return vein
end

------------------------------------------------------------------------
-- Origin-specific: Bioluminescent Line / Symbol carving
------------------------------------------------------------------------

--[[
	Creates a thin glowing line carved into stone surfaces.
	Emits a cold blue-green bioluminescent glow with attached PointLight.
]]
function Shared.createBiolumLine(
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string?,
	brightness: number?
): Part
	local line = Instance.new("Part")
	line.Name = name or "BiolumLine"
	line.Size = size
	line.Position = position
	line.Anchored = true
	line.Material = Enum.Material.Neon
	line.Color = COLOR_BIOLUM
	line.Transparency = 0.2
	line.Parent = parent

	local glow = Instance.new("PointLight")
	glow.Name = "BiolumGlow"
	glow.Brightness = brightness or 0.3
	glow.Color = COLOR_BIOLUM_BRIGHT
	glow.Range = 8
	glow.Shadows = false
	glow.Parent = line

	return line
end

------------------------------------------------------------------------
-- Origin-specific: Symbol Carving (decorative, non-glowing)
------------------------------------------------------------------------

function Shared.createSymbolCarving(
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string?
): Part
	local symbol = Instance.new("Part")
	symbol.Name = name or "SymbolCarving"
	symbol.Size = size
	symbol.Position = position
	symbol.Anchored = true
	symbol.Material = Enum.Material.Slate
	symbol.Color = COLOR_SYMBOL
	symbol.Transparency = 0.4
	symbol.CanCollide = false
	symbol.Parent = parent
	return symbol
end

------------------------------------------------------------------------
-- Origin-specific: Pulsing Light (oscillating brightness)
------------------------------------------------------------------------

--[[
	Creates a light fixture with an attached PointLight that pulses
	between min and max brightness. The pulse is driven by a Script
	child that uses RunService.Heartbeat.
]]
function Shared.createPulsingLight(
	position: Vector3,
	parent: Instance,
	minBrightness: number?,
	maxBrightness: number?,
	color: Color3?,
	range: number?,
	pulseSpeed: number?
): Part
	local minB = minBrightness or 0.05
	local maxB = maxBrightness or 0.4
	local speed = pulseSpeed or 1.0

	local fixture = Instance.new("Part")
	fixture.Name = "PulsingLightFixture"
	fixture.Size = Vector3.new(0.5, 0.5, 0.5)
	fixture.Position = position
	fixture.Anchored = true
	fixture.Material = Enum.Material.Neon
	fixture.Color = color or COLOR_BIOLUM
	fixture.Transparency = 0.5
	fixture.CanCollide = false

	local pointLight = Instance.new("PointLight")
	pointLight.Name = "PulseLight"
	pointLight.Brightness = (minB + maxB) / 2
	pointLight.Color = color or COLOR_BIOLUM
	pointLight.Range = range or 14
	pointLight.Shadows = true
	pointLight.Parent = fixture

	-- Pulsing behavior attributes (read by a central pulse controller)
	fixture:SetAttribute("PulseMin", minB)
	fixture:SetAttribute("PulseMax", maxB)
	fixture:SetAttribute("PulseSpeed", speed)
	fixture:SetAttribute("PulseOffset", math.random() * math.pi * 2)

	fixture.Parent = parent
	return fixture
end

------------------------------------------------------------------------
-- Origin-specific: Dim Stone Light (torch sconce, unlit)
------------------------------------------------------------------------

function Shared.createTorchSconce(
	position: Vector3,
	parent: Instance,
	isLit: boolean?
): Part
	local sconce = Instance.new("Part")
	sconce.Name = "TorchSconce"
	sconce.Size = Vector3.new(0.4, 1.2, 0.4)
	sconce.Position = position
	sconce.Anchored = true
	sconce.Material = Enum.Material.Metal
	sconce.Color = COLOR_IRON
	sconce.Parent = parent

	if isLit then
		-- Torch head (glowing)
		local torch = Instance.new("Part")
		torch.Name = "TorchFlame"
		torch.Size = Vector3.new(0.3, 0.5, 0.3)
		torch.Position = position + Vector3.new(0, 0.8, 0)
		torch.Anchored = true
		torch.Material = Enum.Material.Neon
		torch.Color = COLOR_CANDLE_GLOW
		torch.Transparency = 0.3
		torch.CanCollide = false
		torch.Parent = parent

		local torchLight = Instance.new("PointLight")
		torchLight.Brightness = 0.3
		torchLight.Color = COLOR_CANDLE_GLOW
		torchLight.Range = 12
		torchLight.Shadows = true
		torchLight.Parent = torch
	end

	return sconce
end

------------------------------------------------------------------------
-- Origin-specific: Candle
------------------------------------------------------------------------

function Shared.createCandle(
	position: Vector3,
	parent: Instance,
	brightness: number?
): Part
	-- Candle body
	local candle = Instance.new("Part")
	candle.Name = "Candle"
	candle.Shape = Enum.PartType.Cylinder
	candle.Size = Vector3.new(0.8, 0.2, 0.2)
	candle.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	candle.Anchored = true
	candle.Material = Enum.Material.SmoothPlastic
	candle.Color = Color3.fromRGB(200, 190, 170)
	candle.Parent = parent

	-- Flame (small neon part)
	local flame = Instance.new("Part")
	flame.Name = "CandleFlame"
	flame.Size = Vector3.new(0.1, 0.3, 0.1)
	flame.Position = position + Vector3.new(0, 0.5, 0)
	flame.Anchored = true
	flame.Material = Enum.Material.Neon
	flame.Color = COLOR_CANDLE_GLOW
	flame.Transparency = 0.2
	flame.CanCollide = false
	flame.Parent = parent

	local candleLight = Instance.new("PointLight")
	candleLight.Brightness = brightness or 0.2
	candleLight.Color = COLOR_CANDLE_GLOW
	candleLight.Range = 8
	candleLight.Shadows = true
	candleLight.Parent = flame

	return candle
end

------------------------------------------------------------------------
-- Origin-specific: Burial Niche (wall alcove hiding spot)
------------------------------------------------------------------------

function Shared.createBurialNiche(
	position: Vector3,
	parent: Instance,
	id: string,
	hasRemains: boolean?
): (Model, HidingSpotData)
	local model = Instance.new("Model")
	model.Name = `BurialNiche_{id}`

	-- Niche cavity (inset into wall)
	local cavity = Instance.new("Part")
	cavity.Name = "Cavity"
	cavity.Size = Vector3.new(3, 1.2, 2.5)
	cavity.Position = position
	cavity.Anchored = true
	cavity.Material = Enum.Material.Slate
	cavity.Color = COLOR_STONE_DARK
	cavity.Parent = model

	-- Stone slab (partial cover)
	local slab = Instance.new("Part")
	slab.Name = "CoverSlab"
	slab.Size = Vector3.new(3.2, 0.2, 0.8)
	slab.Position = position + Vector3.new(0, -0.5, 1.1)
	slab.Anchored = true
	slab.Material = Enum.Material.Slate
	slab.Color = COLOR_STONE_LIGHT
	slab.Parent = model

	if hasRemains then
		-- Skeletal remains (simplified shape)
		local remains = Instance.new("Part")
		remains.Name = "Remains"
		remains.Size = Vector3.new(1.5, 0.4, 2)
		remains.Position = position + Vector3.new(0, -0.3, 0)
		remains.Anchored = true
		remains.Material = Enum.Material.Slate
		remains.Color = COLOR_BONE
		remains.Transparency = 0.2
		remains.Parent = model
	end

	-- Hiding spot trigger
	local _, spotData = HospitalShared.createHidingSpot(position, "BurialNiche", id, model)

	model.Parent = parent

	return model, spotData
end

------------------------------------------------------------------------
-- Origin-specific: Sarcophagus
------------------------------------------------------------------------

function Shared.createSarcophagus(
	position: Vector3,
	parent: Instance,
	name: string?,
	lidDisplaced: boolean?
): Model
	local model = Instance.new("Model")
	model.Name = name or "Sarcophagus"

	-- Base
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(4, 2, 7)
	base.Position = position + Vector3.new(0, 1, 0)
	base.Anchored = true
	base.Material = Enum.Material.Slate
	base.Color = COLOR_STONE
	base.Parent = model

	-- Lid
	local lid = Instance.new("Part")
	lid.Name = "Lid"
	lid.Size = Vector3.new(4.2, 0.6, 7.2)
	if lidDisplaced then
		lid.Position = position + Vector3.new(1.5, 2.2, 0.5)
		lid.Orientation = Vector3.new(0, 8, -12)
	else
		lid.Position = position + Vector3.new(0, 2.3, 0)
	end
	lid.Anchored = true
	lid.Material = Enum.Material.Slate
	lid.Color = COLOR_STONE_LIGHT
	lid.Parent = model

	-- Symbol carvings on sides
	for i = 1, 3 do
		Shared.createSymbolCarving(
			position + Vector3.new(0, 0.5 + i * 0.4, 3.6),
			Vector3.new(2 - i * 0.3, 0.15, 0.05),
			model,
			`SarcSymbol_{i}`
		)
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Origin-specific: Catacomb Room (stone-walled room)
------------------------------------------------------------------------

export type CatacombRoomConfig = {
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string?,
	height: number?,
	doorways: { HospitalShared.DoorwayDef }?,
	noFloor: boolean?,
	noCeiling: boolean?,
	organic: boolean?, -- adds flesh-like elements
}

function Shared.createCatacombRoom(config: CatacombRoomConfig): Model
	local wallColor = if config.organic then COLOR_CORRUPTED_WALL else COLOR_STONE
	local floorColor = if config.organic then COLOR_CORRUPTED_FLOOR else COLOR_STONE_DARK
	local ceilingColor = if config.organic then COLOR_CORRUPTED_CEILING else COLOR_STONE
	local wallMat: Enum.Material = if config.organic then Enum.Material.CorrodesMetal else Enum.Material.Slate
	local floorMat: Enum.Material = if config.organic then Enum.Material.CorrodesMetal else Enum.Material.Cobblestone

	return HospitalShared.createRoom({
		position = config.position,
		size = config.size,
		parent = config.parent,
		name = config.name,
		wallThickness = CATACOMB_WALL_THICKNESS,
		wallMaterial = wallMat,
		floorMaterial = floorMat,
		ceilingMaterial = wallMat,
		wallColor = wallColor,
		floorColor = floorColor,
		ceilingColor = ceilingColor,
		doorways = config.doorways,
		noFloor = config.noFloor,
		noCeiling = config.noCeiling,
	})
end

------------------------------------------------------------------------
-- Origin-specific: Stone Column / Pillar
------------------------------------------------------------------------

function Shared.createPillar(
	position: Vector3,
	height: number,
	radius: number,
	parent: Instance,
	name: string?,
	hasCarving: boolean?
): Part
	local pillar = Instance.new("Part")
	pillar.Name = name or "Pillar"
	pillar.Shape = Enum.PartType.Cylinder
	pillar.Size = Vector3.new(height, radius * 2, radius * 2)
	pillar.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	pillar.Anchored = true
	pillar.Material = Enum.Material.Slate
	pillar.Color = COLOR_STONE
	pillar.Parent = parent

	if hasCarving then
		-- Add symbol carving on pillar surface
		Shared.createSymbolCarving(
			position + Vector3.new(radius + 0.05, 0, 0),
			Vector3.new(0.05, height * 0.6, radius),
			parent,
			(name or "Pillar") .. "_Carving"
		)
	end

	return pillar
end

------------------------------------------------------------------------
-- Origin-specific: Stone Archway
------------------------------------------------------------------------

function Shared.createArchway(
	position: Vector3,
	width: number,
	height: number,
	depth: number,
	parent: Instance,
	name: string?,
	hasSymbols: boolean?
): Model
	local model = Instance.new("Model")
	model.Name = name or "Archway"

	-- Left pillar
	Shared.createStoneWall(
		position + Vector3.new(-width / 2 - 0.5, height / 2, 0),
		Vector3.new(1, height, depth),
		model,
		"ArchPillar_L"
	)

	-- Right pillar
	Shared.createStoneWall(
		position + Vector3.new(width / 2 + 0.5, height / 2, 0),
		Vector3.new(1, height, depth),
		model,
		"ArchPillar_R"
	)

	-- Top arch (simplified as rectangular lintel)
	Shared.createStoneWall(
		position + Vector3.new(0, height + 0.5, 0),
		Vector3.new(width + 2, 1, depth),
		model,
		"ArchLintel"
	)

	if hasSymbols then
		-- Carved symbols above the arch
		Shared.createSymbolCarving(
			position + Vector3.new(0, height + 0.2, depth / 2 + 0.05),
			Vector3.new(width * 0.7, 0.6, 0.05),
			model,
			"ArchSymbols"
		)
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Origin-specific: Water Surface
------------------------------------------------------------------------

function Shared.createWaterSurface(
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string?
): Part
	local water = Instance.new("Part")
	water.Name = name or "WaterSurface"
	water.Size = size
	water.Position = position
	water.Anchored = true
	water.Material = Enum.Material.Glass
	water.Color = COLOR_WATER_MURKY
	water.Transparency = 0.4
	water.CanCollide = false
	water.Parent = parent
	return water
end

------------------------------------------------------------------------
-- Origin-specific: Stalactite / Stalagmite
------------------------------------------------------------------------

function Shared.createStalactite(
	position: Vector3,
	height: number,
	parent: Instance,
	name: string?,
	hangingDown: boolean?
): Part
	local stal = Instance.new("Part")
	stal.Name = name or (if hangingDown then "Stalactite" else "Stalagmite")
	-- Wedge shape approximation
	stal.Size = Vector3.new(0.6, height, 0.6)
	if hangingDown then
		stal.Position = position + Vector3.new(0, -height / 2, 0)
	else
		stal.Position = position + Vector3.new(0, height / 2, 0)
	end
	stal.Anchored = true
	stal.Material = Enum.Material.Slate
	stal.Color = COLOR_STONE_LIGHT
	stal.Parent = parent
	return stal
end

------------------------------------------------------------------------
-- Origin-specific: Corrupted Fragment (piece of previous level)
------------------------------------------------------------------------

--[[
	Creates a distorted fragment of geometry, as if a piece of a previous
	level has been pulled into The Origin's reality. Uses non-standard
	angles and corrupted colors.
]]
function Shared.createCorruptedFragment(
	position: Vector3,
	size: Vector3,
	parent: Instance,
	fragmentType: string, -- "hospital_wall", "hospital_floor", "hospital_tile", "subway_rail", "subway_tile", "lab_panel", "forest_bark"
	name: string?
): Part
	local fragment = Instance.new("Part")
	fragment.Name = name or `CorruptedFragment_{fragmentType}`
	fragment.Size = size
	fragment.Position = position
	fragment.Anchored = true

	-- Apply non-standard rotation to make it feel wrong
	fragment.Orientation = Vector3.new(
		math.random(-15, 15),
		math.random(-20, 20),
		math.random(-10, 10)
	)

	-- Material and color based on source level
	if fragmentType == "hospital_wall" then
		fragment.Material = Enum.Material.Concrete
		fragment.Color = Color3.fromRGB(140, 100, 100) -- hospital wall tinted red
	elseif fragmentType == "hospital_floor" then
		fragment.Material = Enum.Material.SmoothPlastic
		fragment.Color = Color3.fromRGB(100, 90, 85) -- hospital floor desaturated
	elseif fragmentType == "hospital_tile" then
		fragment.Material = Enum.Material.SmoothPlastic
		fragment.Color = Color3.fromRGB(120, 115, 105) -- tile discolored
	elseif fragmentType == "subway_rail" then
		fragment.Material = Enum.Material.Metal
		fragment.Color = Color3.fromRGB(70, 65, 60) -- rusted rail
	elseif fragmentType == "subway_tile" then
		fragment.Material = Enum.Material.Marble
		fragment.Color = Color3.fromRGB(90, 80, 75) -- subway tile stained
	elseif fragmentType == "lab_panel" then
		fragment.Material = Enum.Material.Metal
		fragment.Color = Color3.fromRGB(100, 100, 110) -- lab panel with purple tint
	elseif fragmentType == "forest_bark" then
		fragment.Material = Enum.Material.Wood
		fragment.Color = Color3.fromRGB(50, 35, 30) -- dead/corrupted bark
	else
		fragment.Material = Enum.Material.Concrete
		fragment.Color = Color3.fromRGB(100, 80, 80)
	end

	fragment.Parent = parent
	return fragment
end

------------------------------------------------------------------------
-- Origin-specific: Throne (The Original Entity's seat)
------------------------------------------------------------------------

function Shared.createThrone(
	position: Vector3,
	parent: Instance
): Model
	local model = Instance.new("Model")
	model.Name = "TheThrone"

	-- Dais (raised platform)
	local dais = Instance.new("Part")
	dais.Name = "Dais"
	dais.Size = Vector3.new(8, 1.5, 8)
	dais.Position = position + Vector3.new(0, 0.75, 0)
	dais.Anchored = true
	dais.Material = Enum.Material.Slate
	dais.Color = COLOR_STONE_DARK
	dais.Parent = model

	-- Throne base
	local throneBase = Instance.new("Part")
	throneBase.Name = "ThroneBase"
	throneBase.Size = Vector3.new(4, 3, 3)
	throneBase.Position = position + Vector3.new(0, 3, 0)
	throneBase.Anchored = true
	throneBase.Material = Enum.Material.Slate
	throneBase.Color = COLOR_VOID
	throneBase.Parent = model

	-- Throne back (tall slab)
	local throneBack = Instance.new("Part")
	throneBack.Name = "ThroneBack"
	throneBack.Size = Vector3.new(4.5, 5, 0.8)
	throneBack.Position = position + Vector3.new(0, 5.5, -1.3)
	throneBack.Anchored = true
	throneBack.Material = Enum.Material.Slate
	throneBack.Color = COLOR_VOID
	throneBack.Parent = model

	-- Armrests
	for _, side in { -1, 1 } do
		local armrest = Instance.new("Part")
		armrest.Name = `Armrest_{if side == -1 then "L" else "R"}`
		armrest.Size = Vector3.new(0.6, 1, 2)
		armrest.Position = position + Vector3.new(side * 2.2, 4, 0.2)
		armrest.Anchored = true
		armrest.Material = Enum.Material.Slate
		armrest.Color = COLOR_VOID
		armrest.Parent = model
	end

	-- The Figure (seated, humanoid shape)
	-- Torso
	local torso = Instance.new("Part")
	torso.Name = "Figure_Torso"
	torso.Size = Vector3.new(2.5, 3, 1.5)
	torso.Position = position + Vector3.new(0, 5.5, 0)
	torso.Anchored = true
	torso.Material = Enum.Material.Slate
	torso.Color = COLOR_VOID
	torso.Parent = model

	-- Head (featureless)
	local head = Instance.new("Part")
	head.Name = "Figure_Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.Position = position + Vector3.new(0, 7.5, 0)
	head.Anchored = true
	head.Material = Enum.Material.Slate
	head.Color = COLOR_VOID
	head.Parent = model

	-- Arms (resting on armrests, palms up)
	for _, side in { -1, 1 } do
		-- Upper arm
		local upperArm = Instance.new("Part")
		upperArm.Name = `Figure_UpperArm_{if side == -1 then "L" else "R"}`
		upperArm.Size = Vector3.new(0.5, 2, 0.5)
		upperArm.Position = position + Vector3.new(side * 1.5, 5.5, 0)
		upperArm.Anchored = true
		upperArm.Material = Enum.Material.Slate
		upperArm.Color = COLOR_VOID
		upperArm.Parent = model

		-- Forearm (on armrest)
		local forearm = Instance.new("Part")
		forearm.Name = `Figure_Forearm_{if side == -1 then "L" else "R"}`
		forearm.Size = Vector3.new(0.4, 0.4, 1.8)
		forearm.Position = position + Vector3.new(side * 2.2, 4.5, 0.2)
		forearm.Anchored = true
		forearm.Material = Enum.Material.Slate
		forearm.Color = COLOR_VOID
		forearm.Parent = model

		-- Hand (slightly curled, palm up)
		local hand = Instance.new("Part")
		hand.Name = `Figure_Hand_{if side == -1 then "L" else "R"}`
		hand.Size = Vector3.new(0.5, 0.2, 0.6)
		hand.Position = position + Vector3.new(side * 2.2, 4.6, 1.2)
		hand.Anchored = true
		hand.Material = Enum.Material.Slate
		hand.Color = COLOR_VOID
		hand.Parent = model
	end

	-- Legs
	for _, side in { -1, 1 } do
		local leg = Instance.new("Part")
		leg.Name = `Figure_Leg_{if side == -1 then "L" else "R"}`
		leg.Size = Vector3.new(0.6, 2.5, 0.6)
		leg.Position = position + Vector3.new(side * 0.6, 3.2, 0.8)
		leg.Orientation = Vector3.new(-20, 0, 0)
		leg.Anchored = true
		leg.Material = Enum.Material.Slate
		leg.Color = COLOR_VOID
		leg.Parent = model
	end

	-- The figure absorbs light: dim area around it
	local absorbLight = Instance.new("PointLight")
	absorbLight.Name = "LightAbsorption"
	absorbLight.Brightness = 0.02
	absorbLight.Color = COLOR_VOID
	absorbLight.Range = 10
	absorbLight.Shadows = true
	absorbLight.Parent = torso

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Origin-specific: The Seal
------------------------------------------------------------------------

function Shared.createSeal(
	position: Vector3,
	parent: Instance
): Model
	local model = Instance.new("Model")
	model.Name = "TheSeal"

	-- Seal disc
	local seal = Instance.new("Part")
	seal.Name = "SealDisc"
	seal.Shape = Enum.PartType.Cylinder
	seal.Size = Vector3.new(0.8, 6, 6)
	seal.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	seal.Anchored = true
	seal.Material = Enum.Material.Slate
	seal.Color = COLOR_STONE_DARK
	seal.Parent = model

	-- Iron bands (3 concentric rings)
	for i = 1, 3 do
		local ring = Instance.new("Part")
		ring.Name = `IronBand_{i}`
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.1, i * 2 + 0.1, i * 2 + 0.1)
		ring.CFrame = CFrame.new(position + Vector3.new(0, 0.45, 0)) * CFrame.Angles(0, 0, math.rad(90))
		ring.Anchored = true
		ring.Material = Enum.Material.Metal
		ring.Color = COLOR_IRON
		ring.Transparency = 0.1
		ring.Parent = model
	end

	-- Crack (bright bioluminescent line across the seal)
	local crack = Instance.new("Part")
	crack.Name = "SealCrack"
	crack.Size = Vector3.new(0.15, 0.1, 5)
	crack.Position = position + Vector3.new(0, 0.5, 0)
	crack.Anchored = true
	crack.Material = Enum.Material.Neon
	crack.Color = COLOR_BIOLUM_BRIGHT
	crack.Transparency = 0
	crack.Parent = model

	local crackGlow = Instance.new("PointLight")
	crackGlow.Name = "CrackGlow"
	crackGlow.Brightness = 0.8
	crackGlow.Color = COLOR_BIOLUM_BRIGHT
	crackGlow.Range = 12
	crackGlow.Shadows = true
	crackGlow.Parent = crack

	-- Seal interaction prompt
	local promptPart = Instance.new("Part")
	promptPart.Name = "SealInteraction"
	promptPart.Size = Vector3.new(3, 3, 3)
	promptPart.Position = position + Vector3.new(0, 1.5, 0)
	promptPart.Anchored = true
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Interact with the Seal"
	prompt.ObjectText = "The Seal"
	prompt.HoldDuration = 2
	prompt.MaxActivationDistance = 6
	prompt.Parent = promptPart

	-- Dense symbol carvings around the seal
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local dist = 3.5
		local symPos = position + Vector3.new(math.cos(angle) * dist, 0.05, math.sin(angle) * dist)
		Shared.createBiolumLine(
			symPos,
			Vector3.new(1.2, 0.05, 0.15),
			model,
			`SealSymbol_{i}`,
			0.2
		)
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Origin-specific: Reflective Surface (Mirror Room)
------------------------------------------------------------------------

function Shared.createReflectiveSurface(
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string?
): Part
	local surface = Instance.new("Part")
	surface.Name = name or "ReflectiveSurface"
	surface.Size = size
	surface.Position = position
	surface.Anchored = true
	surface.Material = Enum.Material.Glass
	surface.Color = Color3.fromRGB(20, 20, 25)
	surface.Reflectance = 0.6
	surface.Transparency = 0.1
	surface.Parent = parent
	return surface
end

------------------------------------------------------------------------
-- Origin-specific: Fog Volume (approximate with semi-transparent part)
------------------------------------------------------------------------

function Shared.createFogVolume(
	position: Vector3,
	size: Vector3,
	parent: Instance,
	color: Color3?,
	density: number?
): Part
	local fog = Instance.new("Part")
	fog.Name = "FogVolume"
	fog.Size = size
	fog.Position = position
	fog.Anchored = true
	fog.Material = Enum.Material.SmoothPlastic
	fog.Color = color or Color3.fromRGB(20, 20, 25)
	fog.Transparency = density or 0.92
	fog.CanCollide = false
	fog.Parent = parent
	return fog
end

------------------------------------------------------------------------
-- Exported Constants
------------------------------------------------------------------------

Shared.COLOR_STONE = COLOR_STONE
Shared.COLOR_STONE_DARK = COLOR_STONE_DARK
Shared.COLOR_STONE_LIGHT = COLOR_STONE_LIGHT
Shared.COLOR_FLESH = COLOR_FLESH
Shared.COLOR_FLESH_DARK = COLOR_FLESH_DARK
Shared.COLOR_FLESH_PALE = COLOR_FLESH_PALE
Shared.COLOR_VEIN = COLOR_VEIN
Shared.COLOR_BONE = COLOR_BONE
Shared.COLOR_BIOLUM = COLOR_BIOLUM
Shared.COLOR_BIOLUM_BRIGHT = COLOR_BIOLUM_BRIGHT
Shared.COLOR_VOID = COLOR_VOID
Shared.COLOR_IRON = COLOR_IRON
Shared.COLOR_CANDLE_GLOW = COLOR_CANDLE_GLOW
Shared.COLOR_WATER_MURKY = COLOR_WATER_MURKY
Shared.COLOR_SYMBOL = COLOR_SYMBOL
Shared.COLOR_CORRUPTED_WALL = COLOR_CORRUPTED_WALL
Shared.COLOR_CORRUPTED_FLOOR = COLOR_CORRUPTED_FLOOR

Shared.CATACOMB_WALL_THICKNESS = CATACOMB_WALL_THICKNESS
Shared.CATACOMB_CORRIDOR_WIDTH = CATACOMB_CORRIDOR_WIDTH
Shared.CATACOMB_CORRIDOR_HEIGHT = CATACOMB_CORRIDOR_HEIGHT
Shared.WARREN_TUNNEL_WIDTH = WARREN_TUNNEL_WIDTH
Shared.WARREN_TUNNEL_HEIGHT = WARREN_TUNNEL_HEIGHT
Shared.NARROW_WIDTH = NARROW_WIDTH
Shared.NARROW_HEIGHT = NARROW_HEIGHT

Shared.ENTRY_Y = ENTRY_Y
Shared.CATACOMB_Y = CATACOMB_Y
Shared.WARREN_Y = WARREN_Y
Shared.SANCTUARY_Y = SANCTUARY_Y

return Shared
