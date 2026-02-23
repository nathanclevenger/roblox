--!strict

--[[
	ResearchStation/Shared — Builder helper functions for Level 3 geometry.

	Provides research-station-specific primitives in addition to re-exporting
	the base Hospital/Shared helpers (walls, floors, ceilings, rooms, corridors,
	stairs, doors, lights, hiding spots, pipes).

	Station-specific builders:
		- Lab benches, microscopes, centrifuges, specimen jars
		- Containment cells (glass-walled observation cells)
		- Server racks, computer terminals, monitors
		- Decontamination chambers, biohazard signs
		- Emergency lighting strips, strobe lights
		- Containment pods / The Tank
		- Scaffolding, excavation equipment
		- Barbed-wire fence, guard towers, helipad markings
]]

local HospitalShared = require(script.Parent.Parent.Hospital.Shared)

local Shared = {}

------------------------------------------------------------------------
-- Re-export all Hospital/Shared functions
------------------------------------------------------------------------

Shared.createWall = HospitalShared.createWall
Shared.createFloor = HospitalShared.createFloor
Shared.createCeiling = HospitalShared.createCeiling
Shared.createRoom = HospitalShared.createRoom
Shared.createDoor = HospitalShared.createDoor
Shared.createCorridor = HospitalShared.createCorridor
Shared.createStairwell = HospitalShared.createStairwell
Shared.createFurniture = HospitalShared.createFurniture
Shared.createLight = HospitalShared.createLight
Shared.createHidingSpot = HospitalShared.createHidingSpot
Shared.createCurtain = HospitalShared.createCurtain
Shared.createPipe = HospitalShared.createPipe

------------------------------------------------------------------------
-- Re-export types
------------------------------------------------------------------------

export type DoorwayDef = HospitalShared.DoorwayDef
export type RoomConfig = HospitalShared.RoomConfig
export type HidingSpotData = HospitalShared.HidingSpotData

------------------------------------------------------------------------
-- Color Palette — Sterile / Clinical / Emergency
------------------------------------------------------------------------

local COLOR_STERILE_WHITE = Color3.fromRGB(220, 225, 220)
local COLOR_CONCRETE_GREY = Color3.fromRGB(150, 150, 148)
local COLOR_REINFORCED_GLASS = Color3.fromRGB(170, 195, 210)
local COLOR_STAINLESS_STEEL = Color3.fromRGB(185, 185, 190)
local COLOR_HAZMAT_YELLOW = Color3.fromRGB(220, 190, 40)
local COLOR_BIOHAZARD_ORANGE = Color3.fromRGB(220, 130, 30)
local COLOR_EMERGENCY_RED = Color3.fromRGB(200, 40, 30)
local COLOR_SERVER_LED_GREEN = Color3.fromRGB(30, 200, 60)
local COLOR_SERVER_LED_AMBER = Color3.fromRGB(220, 180, 40)
local COLOR_CRT_BLUE = Color3.fromRGB(80, 140, 200)
local COLOR_DARK_METAL = Color3.fromRGB(60, 60, 65)
local COLOR_LAB_BENCH = Color3.fromRGB(200, 200, 205)
local COLOR_SPECIMEN_AMBER = Color3.fromRGB(180, 140, 60)
local COLOR_RUST = Color3.fromRGB(140, 80, 50)
local COLOR_BLOOD_STAIN = Color3.fromRGB(80, 20, 15)
local COLOR_SCRATCH_MARK = Color3.fromRGB(60, 55, 50)
local COLOR_ROCK = Color3.fromRGB(90, 85, 80)
local COLOR_LUMINESCENT_BLUE = Color3.fromRGB(100, 120, 160)
local COLOR_CORRUGATED_METAL = Color3.fromRGB(130, 135, 130)
local COLOR_OCEAN_DARK = Color3.fromRGB(20, 35, 50)

-- Export colors for area modules
Shared.Colors = {
	SterileWhite = COLOR_STERILE_WHITE,
	ConcreteGrey = COLOR_CONCRETE_GREY,
	ReinforcedGlass = COLOR_REINFORCED_GLASS,
	StainlessSteel = COLOR_STAINLESS_STEEL,
	HazmatYellow = COLOR_HAZMAT_YELLOW,
	BiohazardOrange = COLOR_BIOHAZARD_ORANGE,
	EmergencyRed = COLOR_EMERGENCY_RED,
	ServerLedGreen = COLOR_SERVER_LED_GREEN,
	ServerLedAmber = COLOR_SERVER_LED_AMBER,
	CrtBlue = COLOR_CRT_BLUE,
	DarkMetal = COLOR_DARK_METAL,
	LabBench = COLOR_LAB_BENCH,
	SpecimenAmber = COLOR_SPECIMEN_AMBER,
	Rust = COLOR_RUST,
	BloodStain = COLOR_BLOOD_STAIN,
	ScratchMark = COLOR_SCRATCH_MARK,
	Rock = COLOR_ROCK,
	LuminescentBlue = COLOR_LUMINESCENT_BLUE,
	CorrugatedMetal = COLOR_CORRUGATED_METAL,
	OceanDark = COLOR_OCEAN_DARK,
}

------------------------------------------------------------------------
-- Helper: quick part creator (internal reuse)
------------------------------------------------------------------------

local function makePart(
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
	part.Color = color or COLOR_STERILE_WHITE
	part.Transparency = transparency or 0
	part.Material = material or Enum.Material.SmoothPlastic
	part.Parent = parent
	return part
end

-- Exported for area modules
Shared.makePart = makePart

------------------------------------------------------------------------
-- Emergency Light Strip (dim orange floor-level strip)
------------------------------------------------------------------------

function Shared.createEmergencyStrip(position: Vector3, length: number, axis: string, parent: Instance): Part
	local size: Vector3
	if axis == "x" then
		size = Vector3.new(length, 0.15, 0.4)
	else
		size = Vector3.new(0.4, 0.15, length)
	end

	local strip = makePart(parent, "EmergencyStrip", position, size, COLOR_BIOHAZARD_ORANGE, 0.2, Enum.Material.Neon)

	local light = Instance.new("PointLight")
	light.Brightness = 0.25
	light.Color = Color3.fromRGB(255, 160, 60)
	light.Range = 10
	light.Shadows = false
	light.Parent = strip

	return strip
end

------------------------------------------------------------------------
-- Emergency Red Light (pulsing ceiling mount)
------------------------------------------------------------------------

function Shared.createEmergencyLight(position: Vector3, parent: Instance, brightness: number?): Part
	local fixture = makePart(parent, "EmergencyLight", position, Vector3.new(0.8, 0.4, 0.8), COLOR_EMERGENCY_RED, 0.1, Enum.Material.Neon)

	local light = Instance.new("PointLight")
	light.Brightness = brightness or 0.35
	light.Color = Color3.fromRGB(255, 50, 30)
	light.Range = 16
	light.Shadows = true
	light.Parent = fixture

	return fixture
end

------------------------------------------------------------------------
-- Fluorescent Light (ceiling tube, clinical white — most off/flickering)
------------------------------------------------------------------------

function Shared.createFluorescent(position: Vector3, parent: Instance, isOn: boolean): Part
	local tube = makePart(
		parent,
		"Fluorescent",
		position,
		Vector3.new(4, 0.2, 0.6),
		if isOn then Color3.fromRGB(240, 245, 240) else Color3.fromRGB(180, 180, 175),
		if isOn then 0.3 else 0,
		if isOn then Enum.Material.Neon else Enum.Material.SmoothPlastic
	)

	if isOn then
		local light = Instance.new("PointLight")
		light.Brightness = 0.5
		light.Color = Color3.fromRGB(230, 240, 255)
		light.Range = 18
		light.Shadows = true
		light.Parent = tube
	end

	return tube
end

------------------------------------------------------------------------
-- Lab Bench (stainless steel workbench)
------------------------------------------------------------------------

function Shared.createLabBench(position: Vector3, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "LabBench"

	-- Bench top
	makePart(model, "BenchTop", position + Vector3.new(0, 3, 0), Vector3.new(6, 0.4, 3), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)

	-- Legs
	for _, offset in { Vector3.new(-2.5, 1.5, -1), Vector3.new(2.5, 1.5, -1), Vector3.new(-2.5, 1.5, 1), Vector3.new(2.5, 1.5, 1) } do
		makePart(model, "Leg", position + offset, Vector3.new(0.3, 3, 0.3), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)
	end

	-- Shelf under bench
	makePart(model, "Shelf", position + Vector3.new(0, 0.8, 0), Vector3.new(5.5, 0.2, 2.5), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Microscope
------------------------------------------------------------------------

function Shared.createMicroscope(position: Vector3, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Microscope"

	-- Base
	makePart(model, "Base", position + Vector3.new(0, 0.15, 0), Vector3.new(1, 0.3, 1.2), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	-- Stage
	makePart(model, "Stage", position + Vector3.new(0, 0.5, 0), Vector3.new(0.8, 0.1, 0.8), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)
	-- Arm (vertical column)
	makePart(model, "Arm", position + Vector3.new(0, 1.2, -0.3), Vector3.new(0.25, 1.4, 0.25), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	-- Eyepiece (tilted cylinder approximation)
	local eyepiece = makePart(model, "Eyepiece", position + Vector3.new(0, 1.8, 0.1), Vector3.new(0.3, 0.6, 0.3), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	eyepiece.Orientation = Vector3.new(30, 0, 0)
	-- Objective lens housing
	makePart(model, "Objective", position + Vector3.new(0, 0.7, 0), Vector3.new(0.5, 0.3, 0.5), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Centrifuge
------------------------------------------------------------------------

function Shared.createCentrifuge(position: Vector3, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Centrifuge"

	-- Body (cylindrical shape approximated as a box)
	makePart(model, "Body", position + Vector3.new(0, 0.5, 0), Vector3.new(1.2, 1, 1.2), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)
	-- Lid
	makePart(model, "Lid", position + Vector3.new(0, 1.1, 0), Vector3.new(1.3, 0.15, 1.3), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)
	-- Control panel (front)
	makePart(model, "Panel", position + Vector3.new(0, 0.5, 0.6), Vector3.new(0.6, 0.4, 0.1), COLOR_DARK_METAL, 0, Enum.Material.SmoothPlastic)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Specimen Jar (glass cylinder with amber fluid)
------------------------------------------------------------------------

function Shared.createSpecimenJar(position: Vector3, parent: Instance, isEmpty: boolean?, label: string?): Model
	local model = Instance.new("Model")
	model.Name = label or "SpecimenJar"

	-- Glass jar
	makePart(model, "Glass", position + Vector3.new(0, 0.6, 0), Vector3.new(0.6, 1.2, 0.6), Color3.fromRGB(200, 210, 215), 0.6, Enum.Material.Glass)

	if not isEmpty then
		-- Amber fluid
		makePart(model, "Fluid", position + Vector3.new(0, 0.5, 0), Vector3.new(0.5, 0.9, 0.5), COLOR_SPECIMEN_AMBER, 0.4, Enum.Material.Glass)
		-- Specimen mass
		makePart(model, "Specimen", position + Vector3.new(0, 0.5, 0), Vector3.new(0.3, 0.4, 0.3), Color3.fromRGB(120, 90, 80), 0.2, Enum.Material.SmoothPlastic)
	end

	-- Lid
	makePart(model, "Lid", position + Vector3.new(0, 1.25, 0), Vector3.new(0.65, 0.1, 0.65), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Test Tube Rack
------------------------------------------------------------------------

function Shared.createTestTubeRack(position: Vector3, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "TestTubeRack"

	-- Rack base
	makePart(model, "RackBase", position + Vector3.new(0, 0.1, 0), Vector3.new(1.5, 0.2, 0.6), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)

	-- Test tubes (6 small cylinders)
	for i = 0, 5 do
		local tubeX = position.X - 0.6 + (i * 0.25)
		makePart(
			model,
			`TestTube_{i}`,
			Vector3.new(tubeX, position.Y + 0.5, position.Z),
			Vector3.new(0.12, 0.6, 0.12),
			Color3.fromRGB(200, 210, 220),
			0.5,
			Enum.Material.Glass
		)
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Biohazard Refrigerator
------------------------------------------------------------------------

function Shared.createBioFridge(position: Vector3, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "BioFridge"

	-- Body
	makePart(model, "Body", position + Vector3.new(0, 2.5, 0), Vector3.new(3, 5, 2.5), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)
	-- Door
	makePart(model, "Door", position + Vector3.new(0, 2.5, 1.3), Vector3.new(2.8, 4.8, 0.15), Color3.fromRGB(180, 180, 185), 0, Enum.Material.Metal)
	-- Handle
	makePart(model, "Handle", position + Vector3.new(1, 2.5, 1.45), Vector3.new(0.2, 1.5, 0.15), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	-- Biohazard symbol indicator (small colored panel)
	makePart(model, "BiohazardIndicator", position + Vector3.new(0, 4, 1.45), Vector3.new(0.8, 0.8, 0.05), COLOR_BIOHAZARD_ORANGE, 0, Enum.Material.SmoothPlastic)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Computer Terminal (desktop monitor + keyboard on desk)
------------------------------------------------------------------------

function Shared.createComputerTerminal(position: Vector3, parent: Instance, isOn: boolean?, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "ComputerTerminal"

	-- Monitor housing
	makePart(model, "MonitorHousing", position + Vector3.new(0, 1.2, -0.2), Vector3.new(2, 1.6, 0.3), COLOR_DARK_METAL, 0, Enum.Material.SmoothPlastic)

	-- Screen
	local screenColor = if isOn then COLOR_CRT_BLUE else Color3.fromRGB(20, 20, 25)
	local screenTransparency = if isOn then 0.1 else 0
	local screen = makePart(model, "Screen", position + Vector3.new(0, 1.2, 0), Vector3.new(1.8, 1.3, 0.05), screenColor, screenTransparency, Enum.Material.Glass)

	if isOn then
		local glow = Instance.new("PointLight")
		glow.Brightness = 0.3
		glow.Color = COLOR_CRT_BLUE
		glow.Range = 6
		glow.Shadows = false
		glow.Parent = screen
	end

	-- Monitor stand
	makePart(model, "Stand", position + Vector3.new(0, 0.25, -0.2), Vector3.new(0.4, 0.5, 0.4), COLOR_DARK_METAL, 0, Enum.Material.SmoothPlastic)

	-- Keyboard
	makePart(model, "Keyboard", position + Vector3.new(0, 0.1, 0.8), Vector3.new(1.5, 0.1, 0.6), Color3.fromRGB(50, 50, 55), 0, Enum.Material.SmoothPlastic)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Monitor Bank (row of CRT monitors for security / containment control)
------------------------------------------------------------------------

function Shared.createMonitorBank(position: Vector3, count: number, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "MonitorBank"

	local spacing = 2.2
	local startX = position.X - ((count - 1) * spacing) / 2

	for i = 0, count - 1 do
		local monX = startX + (i * spacing)
		-- Monitor housing
		makePart(model, `Monitor_{i}_Housing`, Vector3.new(monX, position.Y + 1.2, position.Z), Vector3.new(2, 1.5, 0.3), COLOR_DARK_METAL, 0, Enum.Material.SmoothPlastic)

		-- Screen (some on, some off)
		local isLive = (i % 3 ~= 2) -- 2 of every 3 are live
		local screenColor = if isLive then COLOR_CRT_BLUE else Color3.fromRGB(15, 15, 18)
		local screen = makePart(model, `Monitor_{i}_Screen`, Vector3.new(monX, position.Y + 1.2, position.Z + 0.2), Vector3.new(1.8, 1.3, 0.05), screenColor, if isLive then 0.15 else 0, Enum.Material.Glass)

		if isLive then
			local glow = Instance.new("PointLight")
			glow.Brightness = 0.15
			glow.Color = COLOR_CRT_BLUE
			glow.Range = 4
			glow.Shadows = false
			glow.Parent = screen
		end
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Server Rack
------------------------------------------------------------------------

function Shared.createServerRack(position: Vector3, parent: Instance, isActive: boolean?): Model
	local model = Instance.new("Model")
	model.Name = "ServerRack"

	local active = if isActive ~= nil then isActive else true

	-- Rack frame
	makePart(model, "Frame", position + Vector3.new(0, 4, 0), Vector3.new(2.5, 8, 3), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	-- Front panel
	makePart(model, "FrontPanel", position + Vector3.new(0, 4, 1.55), Vector3.new(2.3, 7.5, 0.1), Color3.fromRGB(40, 40, 45), 0, Enum.Material.Metal)

	if active then
		-- LED indicators (green and amber dots)
		for row = 0, 5 do
			local ledY = position.Y + 1.5 + (row * 1.2)
			local ledColor = if row % 2 == 0 then COLOR_SERVER_LED_GREEN else COLOR_SERVER_LED_AMBER
			makePart(model, `LED_{row}`, Vector3.new(position.X - 0.8, ledY, position.Z + 1.62), Vector3.new(0.08, 0.08, 0.02), ledColor, 0, Enum.Material.Neon)
		end
	end

	-- Ventilation grilles (top and bottom)
	makePart(model, "Vent_Top", position + Vector3.new(0, 7.9, 0), Vector3.new(2.3, 0.1, 2.8), Color3.fromRGB(50, 50, 55), 0.3, Enum.Material.Metal)
	makePart(model, "Vent_Bot", position + Vector3.new(0, 0.2, 0), Vector3.new(2.3, 0.1, 2.8), Color3.fromRGB(50, 50, 55), 0.3, Enum.Material.Metal)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Containment Cell (glass-walled observation cell)
------------------------------------------------------------------------

function Shared.createContainmentCell(
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string,
	hasShatteredGlass: boolean?,
	doorSide: string?
): Model
	local model = Instance.new("Model")
	model.Name = name

	local sx = size.X
	local sy = size.Y
	local sz = size.Z

	-- Floor
	Shared.createFloor(
		Vector3.new(position.X, position.Y - 0.5, position.Z),
		Vector3.new(sx, 1, sz),
		model,
		"Floor"
	)

	-- Ceiling
	Shared.createCeiling(
		Vector3.new(position.X, position.Y + sy + 0.5, position.Z),
		Vector3.new(sx, 1, sz),
		model,
		"Ceiling"
	)

	-- Back wall (solid concrete — north)
	Shared.createWall(
		Vector3.new(position.X, position.Y + sy / 2, position.Z - sz / 2 - 0.5),
		Vector3.new(sx, sy, 1),
		model,
		"Wall_Back"
	)

	-- Side walls (solid)
	Shared.createWall(
		Vector3.new(position.X - sx / 2 - 0.5, position.Y + sy / 2, position.Z),
		Vector3.new(1, sy, sz),
		model,
		"Wall_Left"
	)
	Shared.createWall(
		Vector3.new(position.X + sx / 2 + 0.5, position.Y + sy / 2, position.Z),
		Vector3.new(1, sy, sz),
		model,
		"Wall_Right"
	)

	-- Front glass wall (south — facing corridor)
	if hasShatteredGlass then
		-- Broken glass remnants along the base
		for i = 0, 3 do
			local shardX = position.X - sx / 4 + (i * sx / 4)
			local shardSize = Vector3.new(0.8 + math.random() * 0.5, 0.6 + math.random() * 0.8, 0.15)
			local shard = makePart(
				model,
				`GlassShard_{i}`,
				Vector3.new(shardX, position.Y + 0.3, position.Z + sz / 2 + 0.5 + math.random() * 1.5),
				shardSize,
				COLOR_REINFORCED_GLASS,
				0.5,
				Enum.Material.Glass
			)
			shard.Orientation = Vector3.new(math.random(-30, 30), math.random(-45, 45), math.random(-20, 20))
		end

		-- Remaining glass frame (top portion)
		makePart(
			model,
			"GlassFrame_Top",
			Vector3.new(position.X, position.Y + sy - 1, position.Z + sz / 2 + 0.5),
			Vector3.new(sx, 2, 0.3),
			COLOR_REINFORCED_GLASS,
			0.5,
			Enum.Material.Glass
		)
	else
		-- Intact reinforced glass
		makePart(
			model,
			"GlassWall",
			Vector3.new(position.X, position.Y + sy / 2, position.Z + sz / 2 + 0.5),
			Vector3.new(sx, sy, 0.3),
			COLOR_REINFORCED_GLASS,
			0.5,
			Enum.Material.Glass
		)

		-- Cell door in glass wall
		local doorOffset = if doorSide == "left" then -sx / 4 else if doorSide == "right" then sx / 4 else 0
		Shared.createDoor(
			Vector3.new(position.X + doorOffset, position.Y + 4, position.Z + sz / 2 + 0.5),
			CFrame.Angles(0, 0, 0),
			model,
			`Door_{name}`,
			false,
			nil
		)
	end

	-- Floor drain
	makePart(model, "FloorDrain", Vector3.new(position.X, position.Y + 0.02, position.Z), Vector3.new(0.6, 0.04, 0.6), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	-- Ceiling camera mount
	makePart(model, "CameraMount", Vector3.new(position.X + sx / 4, position.Y + sy - 0.3, position.Z + sz / 4), Vector3.new(0.3, 0.3, 0.3), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Biohazard Sign
------------------------------------------------------------------------

function Shared.createBiohazardSign(position: Vector3, parent: Instance, facing: string?): Part
	local size: Vector3
	if facing == "x" then
		size = Vector3.new(0.1, 1.5, 1.5)
	else
		size = Vector3.new(1.5, 1.5, 0.1)
	end

	local sign = makePart(parent, "BiohazardSign", position, size, COLOR_HAZMAT_YELLOW, 0, Enum.Material.SmoothPlastic)
	sign:SetAttribute("SignType", "Biohazard")
	return sign
end

------------------------------------------------------------------------
-- Decontamination Chamber (small pass-through room with nozzles)
------------------------------------------------------------------------

function Shared.createDeconChamber(position: Vector3, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "DeconChamber"

	local sx, sy, sz = 6, 10, 4

	-- Walls (thin metal enclosure)
	makePart(model, "Wall_Left", Vector3.new(position.X - sx / 2, position.Y + sy / 2, position.Z), Vector3.new(0.3, sy, sz), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)
	makePart(model, "Wall_Right", Vector3.new(position.X + sx / 2, position.Y + sy / 2, position.Z), Vector3.new(0.3, sy, sz), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)
	makePart(model, "Ceiling", Vector3.new(position.X, position.Y + sy, position.Z), Vector3.new(sx, 0.3, sz), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)
	makePart(model, "Floor", Vector3.new(position.X, position.Y, position.Z), Vector3.new(sx, 0.3, sz), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)

	-- Floor grate
	makePart(model, "Grate", Vector3.new(position.X, position.Y + 0.2, position.Z), Vector3.new(sx - 1, 0.1, sz - 1), COLOR_DARK_METAL, 0.3, Enum.Material.Metal)

	-- Shower nozzles (ceiling-mounted)
	for _, offset in { Vector3.new(-1.5, sy - 0.5, 0), Vector3.new(0, sy - 0.5, 0), Vector3.new(1.5, sy - 0.5, 0) } do
		makePart(model, "Nozzle", position + offset, Vector3.new(0.3, 0.4, 0.3), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)
	end

	-- Warning stripe on floor
	makePart(model, "WarningStripe", Vector3.new(position.X, position.Y + 0.25, position.Z), Vector3.new(sx - 0.5, 0.02, 1), COLOR_HAZMAT_YELLOW, 0, Enum.Material.SmoothPlastic)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Scaffolding Section
------------------------------------------------------------------------

function Shared.createScaffolding(position: Vector3, height: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "Scaffolding"

	local width = 6
	local depth = 3

	-- Vertical poles (4 corners)
	for _, offset in {
		Vector3.new(-width / 2, height / 2, -depth / 2),
		Vector3.new(width / 2, height / 2, -depth / 2),
		Vector3.new(-width / 2, height / 2, depth / 2),
		Vector3.new(width / 2, height / 2, depth / 2),
	} do
		makePart(model, "Pole", position + offset, Vector3.new(0.3, height, 0.3), COLOR_HAZMAT_YELLOW, 0, Enum.Material.Metal)
	end

	-- Platforms at intervals
	local platformCount = math.floor(height / 4)
	for i = 1, platformCount do
		local platformY = position.Y + (i * 4)
		makePart(model, `Platform_{i}`, Vector3.new(position.X, platformY, position.Z), Vector3.new(width, 0.2, depth), Color3.fromRGB(100, 90, 80), 0, Enum.Material.Wood)
	end

	-- Cross braces (X pattern on sides)
	makePart(model, "Brace_Front", Vector3.new(position.X, position.Y + height / 2, position.Z + depth / 2), Vector3.new(width, 0.15, 0.15), COLOR_HAZMAT_YELLOW, 0, Enum.Material.Metal)
	makePart(model, "Brace_Back", Vector3.new(position.X, position.Y + height / 2, position.Z - depth / 2), Vector3.new(width, 0.15, 0.15), COLOR_HAZMAT_YELLOW, 0, Enum.Material.Metal)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Drilling Rig (excavation equipment)
------------------------------------------------------------------------

function Shared.createDrillingRig(position: Vector3, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "DrillingRig"

	-- Base / treads
	makePart(model, "Base", position + Vector3.new(0, 1, 0), Vector3.new(5, 2, 8), COLOR_HAZMAT_YELLOW, 0, Enum.Material.Metal)

	-- Cabin
	makePart(model, "Cabin", position + Vector3.new(0, 3.5, -2), Vector3.new(3.5, 3, 3), COLOR_HAZMAT_YELLOW, 0, Enum.Material.Metal)
	-- Cabin window
	makePart(model, "CabinWindow", position + Vector3.new(0, 4, -0.4), Vector3.new(2.5, 1.5, 0.1), Color3.fromRGB(150, 170, 185), 0.5, Enum.Material.Glass)

	-- Drill arm (vertical mast)
	makePart(model, "DrillMast", position + Vector3.new(0, 6, 2), Vector3.new(0.6, 6, 0.6), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	-- Drill bit
	makePart(model, "DrillBit", position + Vector3.new(0, 2, 2), Vector3.new(0.4, 2, 0.4), COLOR_STAINLESS_STEEL, 0, Enum.Material.Metal)

	-- Operator seat
	makePart(model, "Seat", position + Vector3.new(0, 3, -2.5), Vector3.new(1.5, 0.4, 1.5), Color3.fromRGB(60, 60, 60), 0, Enum.Material.Fabric)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Earth Mover (large construction vehicle)
------------------------------------------------------------------------

function Shared.createEarthMover(position: Vector3, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "EarthMover"

	-- Body
	makePart(model, "Body", position + Vector3.new(0, 2, 0), Vector3.new(6, 4, 10), COLOR_HAZMAT_YELLOW, 0, Enum.Material.Metal)
	-- Cabin
	makePart(model, "Cabin", position + Vector3.new(0, 5, -2), Vector3.new(4, 3, 4), COLOR_HAZMAT_YELLOW, 0, Enum.Material.Metal)
	-- Bucket
	makePart(model, "Bucket", position + Vector3.new(0, 1.5, 6), Vector3.new(5, 2, 3), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Floodlight Tripod
------------------------------------------------------------------------

function Shared.createFloodlight(position: Vector3, parent: Instance, isOn: boolean): Model
	local model = Instance.new("Model")
	model.Name = "Floodlight"

	-- Tripod legs
	for _, offset in { Vector3.new(-0.6, 1.5, -0.6), Vector3.new(0.6, 1.5, -0.6), Vector3.new(0, 1.5, 0.6) } do
		makePart(model, "Leg", position + offset, Vector3.new(0.15, 3, 0.15), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	end

	-- Pole
	makePart(model, "Pole", position + Vector3.new(0, 3.5, 0), Vector3.new(0.2, 2, 0.2), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	-- Light housing
	local housing = makePart(model, "Housing", position + Vector3.new(0, 4.5, 0.3), Vector3.new(1.2, 0.8, 0.5), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	if isOn then
		local light = Instance.new("SpotLight")
		light.Brightness = 2
		light.Color = Color3.fromRGB(255, 240, 200)
		light.Range = 40
		light.Angle = 60
		light.Shadows = true
		light.Face = Enum.NormalId.Front
		light.Parent = housing
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Bunk Bed
------------------------------------------------------------------------

function Shared.createBunkBed(position: Vector3, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "BunkBed"

	-- Frame posts (4 corners)
	for _, offset in {
		Vector3.new(-1.8, 3.5, -3),
		Vector3.new(1.8, 3.5, -3),
		Vector3.new(-1.8, 3.5, 3),
		Vector3.new(1.8, 3.5, 3),
	} do
		makePart(model, "Post", position + offset, Vector3.new(0.3, 7, 0.3), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	end

	-- Lower bunk frame + mattress
	makePart(model, "LowerFrame", position + Vector3.new(0, 1, 0), Vector3.new(3.5, 0.3, 6), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	makePart(model, "LowerMattress", position + Vector3.new(0, 1.4, 0), Vector3.new(3.2, 0.5, 5.5), Color3.fromRGB(140, 140, 130), 0, Enum.Material.Fabric)

	-- Upper bunk frame + mattress
	makePart(model, "UpperFrame", position + Vector3.new(0, 4.5, 0), Vector3.new(3.5, 0.3, 6), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	makePart(model, "UpperMattress", position + Vector3.new(0, 4.9, 0), Vector3.new(3.2, 0.5, 5.5), Color3.fromRGB(140, 140, 130), 0, Enum.Material.Fabric)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Chain-Link Fence Section
------------------------------------------------------------------------

function Shared.createFenceSection(position: Vector3, length: number, axis: string, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Fence"

	local fenceHeight = 8
	local postSpacing = 8

	-- Fence mesh (semi-transparent)
	local meshSize: Vector3
	if axis == "x" then
		meshSize = Vector3.new(length, fenceHeight, 0.15)
	else
		meshSize = Vector3.new(0.15, fenceHeight, length)
	end
	makePart(model, "Mesh", Vector3.new(position.X, position.Y + fenceHeight / 2, position.Z), meshSize, Color3.fromRGB(140, 145, 140), 0.4, Enum.Material.Metal)

	-- Posts
	local postCount = math.floor(length / postSpacing) + 1
	for i = 0, postCount - 1 do
		local postPos: Vector3
		if axis == "x" then
			postPos = Vector3.new(position.X - length / 2 + (i * postSpacing), position.Y + fenceHeight / 2 + 0.5, position.Z)
		else
			postPos = Vector3.new(position.X, position.Y + fenceHeight / 2 + 0.5, position.Z - length / 2 + (i * postSpacing))
		end
		makePart(model, `Post_{i}`, postPos, Vector3.new(0.3, fenceHeight + 1, 0.3), Color3.fromRGB(120, 120, 120), 0, Enum.Material.Metal)
	end

	-- Barbed wire (top)
	local bwSize: Vector3
	if axis == "x" then
		bwSize = Vector3.new(length, 0.3, 0.3)
	else
		bwSize = Vector3.new(0.3, 0.3, length)
	end
	makePart(model, "BarbedWire", Vector3.new(position.X, position.Y + fenceHeight + 1, position.Z), bwSize, Color3.fromRGB(100, 100, 95), 0.2, Enum.Material.Metal)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Helicopter Wreck
------------------------------------------------------------------------

function Shared.createHelicopterWreck(position: Vector3, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "HelicopterWreck"

	-- Fuselage (crushed)
	local fuselage = makePart(model, "Fuselage", position + Vector3.new(0, 2, 0), Vector3.new(4, 3, 10), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	fuselage.Orientation = Vector3.new(5, -8, 12) -- listing to one side

	-- Cockpit (crushed inward)
	local cockpit = makePart(model, "Cockpit", position + Vector3.new(0, 2.5, 5.5), Vector3.new(3.5, 2.5, 3), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	cockpit.Orientation = Vector3.new(8, -8, 15)

	-- Cracked windshield
	local windshield = makePart(model, "Windshield", position + Vector3.new(0, 3.5, 7), Vector3.new(3, 2, 0.2), Color3.fromRGB(150, 160, 170), 0.4, Enum.Material.Glass)
	windshield.Orientation = Vector3.new(30, -8, 15)

	-- Bent rotors (two flat beams at wrong angles)
	local rotor1 = makePart(model, "Rotor_1", position + Vector3.new(-3, 4, 0), Vector3.new(8, 0.15, 0.6), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	rotor1.Orientation = Vector3.new(15, 30, -25)

	local rotor2 = makePart(model, "Rotor_2", position + Vector3.new(3, 3.5, 1), Vector3.new(8, 0.15, 0.6), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	rotor2.Orientation = Vector3.new(-10, -40, 20)

	-- Tail boom (broken off)
	local tail = makePart(model, "TailBoom", position + Vector3.new(2, 1, -6), Vector3.new(1.5, 1.5, 5), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	tail.Orientation = Vector3.new(0, 15, -8)

	-- Landing skids (crumpled)
	makePart(model, "Skid_L", position + Vector3.new(-2, 0.3, 0), Vector3.new(0.3, 0.5, 8), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	makePart(model, "Skid_R", position + Vector3.new(2, 0.5, 0.5), Vector3.new(0.3, 0.4, 7), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	-- Headset dangling from cockpit
	makePart(model, "Headset", position + Vector3.new(1, 1, 6.5), Vector3.new(0.5, 0.4, 0.6), Color3.fromRGB(40, 40, 40), 0, Enum.Material.SmoothPlastic)
	makePart(model, "HeadsetCord", position + Vector3.new(1, 1.8, 6.2), Vector3.new(0.08, 1.2, 0.08), Color3.fromRGB(30, 30, 30), 0, Enum.Material.SmoothPlastic)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Boat (RHIB — rigid-hulled inflatable boat)
------------------------------------------------------------------------

function Shared.createBoat(position: Vector3, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "ExtractionBoat"

	-- Hull
	makePart(model, "Hull", position + Vector3.new(0, 1, 0), Vector3.new(4, 2, 10), Color3.fromRGB(70, 70, 75), 0, Enum.Material.SmoothPlastic)

	-- Inflatable tubes (side pontoons)
	makePart(model, "Pontoon_L", position + Vector3.new(-2.2, 1.5, 0), Vector3.new(1, 1.2, 10), Color3.fromRGB(50, 50, 55), 0, Enum.Material.SmoothPlastic)
	makePart(model, "Pontoon_R", position + Vector3.new(2.2, 1.5, 0), Vector3.new(1, 1.2, 10), Color3.fromRGB(50, 50, 55), 0, Enum.Material.SmoothPlastic)

	-- Console
	makePart(model, "Console", position + Vector3.new(0, 2.8, -1), Vector3.new(2, 1.5, 1.5), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	-- Steering wheel
	makePart(model, "Wheel", position + Vector3.new(0, 3.8, -0.5), Vector3.new(1, 1, 0.15), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	-- Outboard motors (twin)
	makePart(model, "Motor_L", position + Vector3.new(-1, 1.5, -5.5), Vector3.new(1, 2, 1.5), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	makePart(model, "Motor_R", position + Vector3.new(1, 1.5, -5.5), Vector3.new(1, 2, 1.5), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	-- Seating
	for i = 0, 3 do
		local seatZ = -3 + (i * 2)
		makePart(model, `Seat_{i}`, position + Vector3.new(0, 2.4, seatZ), Vector3.new(3, 0.3, 1.5), Color3.fromRGB(50, 55, 55), 0, Enum.Material.Fabric)
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Fuel Tank (wall-mounted)
------------------------------------------------------------------------

function Shared.createFuelTank(position: Vector3, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "FuelTank"

	-- Tank body
	makePart(model, "Tank", position + Vector3.new(0, 2, 0), Vector3.new(3, 4, 2), COLOR_EMERGENCY_RED, 0, Enum.Material.Metal)
	-- Gauge
	makePart(model, "Gauge", position + Vector3.new(0, 3, 1.05), Vector3.new(0.8, 0.8, 0.1), Color3.fromRGB(220, 220, 215), 0, Enum.Material.SmoothPlastic)
	-- Valve handle
	makePart(model, "Valve", position + Vector3.new(-1, 1.5, 1.05), Vector3.new(0.6, 0.6, 0.3), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	-- Hose
	makePart(model, "Hose", position + Vector3.new(-1.5, 0.5, 0.5), Vector3.new(0.2, 2, 0.2), Color3.fromRGB(30, 30, 30), 0, Enum.Material.SmoothPlastic)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Recording Console (Audio Lab)
------------------------------------------------------------------------

function Shared.createRecordingConsole(position: Vector3, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "RecordingConsole"

	-- Console desk
	makePart(model, "Desk", position + Vector3.new(0, 2.5, 0), Vector3.new(8, 0.5, 3), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	-- Angled control surface
	local surface = makePart(model, "ControlSurface", position + Vector3.new(0, 3.2, 0), Vector3.new(7.5, 0.3, 2.5), Color3.fromRGB(50, 50, 55), 0, Enum.Material.SmoothPlastic)
	surface.Orientation = Vector3.new(-15, 0, 0)

	-- Fader channels (visual detail)
	for i = 0, 7 do
		local faderX = position.X - 3.5 + (i * 1)
		makePart(model, `Fader_{i}`, Vector3.new(faderX, position.Y + 3.4, position.Z - 0.2), Vector3.new(0.15, 0.08, 0.6), Color3.fromRGB(200, 200, 200), 0, Enum.Material.Metal)
	end

	-- VU meters (small glowing panels)
	makePart(model, "VU_L", position + Vector3.new(-2, 3.6, -0.8), Vector3.new(1, 0.6, 0.1), Color3.fromRGB(30, 180, 60), 0.2, Enum.Material.Neon)
	makePart(model, "VU_R", position + Vector3.new(2, 3.6, -0.8), Vector3.new(1, 0.6, 0.1), Color3.fromRGB(30, 180, 60), 0.2, Enum.Material.Neon)

	-- Reel-to-reel tape deck on top
	makePart(model, "ReelDeck", position + Vector3.new(0, 3.8, 0.5), Vector3.new(2.5, 1.5, 1.5), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	-- Reels
	makePart(model, "Reel_L", position + Vector3.new(-0.6, 4.8, 0.5), Vector3.new(0.15, 1.2, 1.2), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	makePart(model, "Reel_R", position + Vector3.new(0.6, 4.8, 0.5), Vector3.new(0.15, 1.2, 1.2), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	-- Legs
	for _, offset in {
		Vector3.new(-3.5, 1.25, -1.2),
		Vector3.new(3.5, 1.25, -1.2),
		Vector3.new(-3.5, 1.25, 1.2),
		Vector3.new(3.5, 1.25, 1.2),
	} do
		makePart(model, "Leg", position + offset, Vector3.new(0.3, 2.5, 0.3), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Acoustic Panel
------------------------------------------------------------------------

function Shared.createAcousticPanel(position: Vector3, size: Vector3, parent: Instance): Part
	return makePart(parent, "AcousticPanel", position, size, Color3.fromRGB(60, 55, 65), 0, Enum.Material.Fabric)
end

------------------------------------------------------------------------
-- Mannequin (featureless humanoid form)
------------------------------------------------------------------------

function Shared.createMannequin(position: Vector3, parent: Instance, hasLabCoat: boolean?): Model
	local model = Instance.new("Model")
	model.Name = "Mannequin"

	-- Torso
	makePart(model, "Torso", position + Vector3.new(0, 3.5, 0), Vector3.new(2, 2.5, 1), Color3.fromRGB(200, 195, 185), 0, Enum.Material.SmoothPlastic)
	-- Head (featureless)
	makePart(model, "Head", position + Vector3.new(0, 5.2, 0), Vector3.new(1, 1.2, 1), Color3.fromRGB(200, 195, 185), 0, Enum.Material.SmoothPlastic)
	-- Arms
	makePart(model, "Arm_L", position + Vector3.new(-1.3, 3.5, 0), Vector3.new(0.5, 2.5, 0.5), Color3.fromRGB(200, 195, 185), 0, Enum.Material.SmoothPlastic)
	makePart(model, "Arm_R", position + Vector3.new(1.3, 3.5, 0), Vector3.new(0.5, 2.5, 0.5), Color3.fromRGB(200, 195, 185), 0, Enum.Material.SmoothPlastic)
	-- Legs
	makePart(model, "Leg_L", position + Vector3.new(-0.5, 1.2, 0), Vector3.new(0.6, 2.4, 0.6), Color3.fromRGB(200, 195, 185), 0, Enum.Material.SmoothPlastic)
	makePart(model, "Leg_R", position + Vector3.new(0.5, 1.2, 0), Vector3.new(0.6, 2.4, 0.6), Color3.fromRGB(200, 195, 185), 0, Enum.Material.SmoothPlastic)

	if hasLabCoat then
		-- Lab coat overlay on torso
		makePart(model, "LabCoat", position + Vector3.new(0, 3.2, 0), Vector3.new(2.3, 3, 1.2), Color3.fromRGB(235, 235, 230), 0.1, Enum.Material.Fabric)
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Marine Railway (boat launch rail)
------------------------------------------------------------------------

function Shared.createMarineRailway(position: Vector3, length: number, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "MarineRailway"

	-- Rails (two parallel)
	makePart(model, "Rail_L", Vector3.new(position.X - 1.5, position.Y + 0.15, position.Z), Vector3.new(0.3, 0.3, length), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	makePart(model, "Rail_R", Vector3.new(position.X + 1.5, position.Y + 0.15, position.Z), Vector3.new(0.3, 0.3, length), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	-- Cross ties
	local tieCount = math.floor(length / 2)
	for i = 0, tieCount - 1 do
		local tieZ = position.Z - length / 2 + (i * 2) + 1
		makePart(model, `Tie_{i}`, Vector3.new(position.X, position.Y + 0.08, tieZ), Vector3.new(4, 0.15, 0.5), Color3.fromRGB(80, 70, 60), 0, Enum.Material.Wood)
	end

	-- Cradle (boat holder)
	makePart(model, "Cradle_L", Vector3.new(position.X - 1.5, position.Y + 1, position.Z), Vector3.new(0.5, 1.5, 4), COLOR_DARK_METAL, 0, Enum.Material.Metal)
	makePart(model, "Cradle_R", Vector3.new(position.X + 1.5, position.Y + 1, position.Z), Vector3.new(0.5, 1.5, 4), COLOR_DARK_METAL, 0, Enum.Material.Metal)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Blood Stain
------------------------------------------------------------------------

function Shared.createBloodStain(position: Vector3, size: Vector3, parent: Instance): Part
	return makePart(parent, "BloodStain", position, size, COLOR_BLOOD_STAIN, 0.3, Enum.Material.Concrete)
end

------------------------------------------------------------------------
-- Scratch Marks (wall damage)
------------------------------------------------------------------------

function Shared.createScratchMarks(position: Vector3, count: number, wallNormal: string, parent: Instance)
	for i = 1, count do
		local offset = Vector3.new(
			if wallNormal == "x" then 0 else (math.random() - 0.5) * 2,
			(math.random() - 0.5) * 3,
			if wallNormal == "z" then 0 else (math.random() - 0.5) * 2
		)
		local size: Vector3
		if wallNormal == "x" then
			size = Vector3.new(0.08, 0.3 + math.random() * 0.4, 1.5 + math.random())
		else
			size = Vector3.new(1.5 + math.random(), 0.3 + math.random() * 0.4, 0.08)
		end
		makePart(parent, `Scratch_{i}`, position + offset, size, COLOR_SCRATCH_MARK, 0, Enum.Material.Concrete)
	end
end

return Shared
