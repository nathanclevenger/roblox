--!strict

--[[
	ResearchStation/Labs — Laboratory areas on Lab Level (B1)

	Biology Lab, Audio Lab, Observation Deck, Medical Bay,
	Lab Corridor (main artery), and elevator/stairwell connecting
	Surface to Lab Level.

	Lab Level Y = -15. Room height = 12 studs.
]]

local Shared = require(script.Parent.Shared)

type HidingSpotData = Shared.HidingSpotData

export type FloorData = {
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } },
}

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local SURFACE_Y = 0
local LAB_Y = -15
local ROOM_HEIGHT = 12
local WALL_THICKNESS = 1
local DOOR_WIDTH = 5
local DOOR_HEIGHT = 8

------------------------------------------------------------------------
-- Lab Corridor (main artery)
------------------------------------------------------------------------

local function buildLabCorridor(
	parent: Instance,
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } }
)
	local corridor = Instance.new("Model")
	corridor.Name = "LabCorridor"

	-- Main east-west corridor
	Shared.createCorridor(
		Vector3.new(-40, LAB_Y, -15),
		Vector3.new(40, LAB_Y, -15),
		6,
		ROOM_HEIGHT,
		corridor,
		"LabCorridor_Main"
	)

	-- North-south branch to containment wing
	Shared.createCorridor(
		Vector3.new(-30, LAB_Y, -15),
		Vector3.new(-30, LAB_Y, -25),
		5,
		ROOM_HEIGHT,
		corridor,
		"LabCorridor_ToContainment"
	)

	-- Corridor lights (some working, some dead)
	local lightPositions = {
		{ pos = Vector3.new(-35, LAB_Y + ROOM_HEIGHT - 0.5, -15), on = true },
		{ pos = Vector3.new(-20, LAB_Y + ROOM_HEIGHT - 0.5, -15), on = false },
		{ pos = Vector3.new(-5, LAB_Y + ROOM_HEIGHT - 0.5, -15), on = true },
		{ pos = Vector3.new(10, LAB_Y + ROOM_HEIGHT - 0.5, -15), on = false },
		{ pos = Vector3.new(25, LAB_Y + ROOM_HEIGHT - 0.5, -15), on = true },
		{ pos = Vector3.new(35, LAB_Y + ROOM_HEIGHT - 0.5, -15), on = false },
	}

	for _, lp in lightPositions do
		Shared.createFluorescent(lp.pos, corridor, lp.on)
	end

	-- Emergency floor strips
	Shared.createEmergencyStrip(Vector3.new(0, LAB_Y + 0.1, -15), 80, "x", corridor)
	Shared.createEmergencyStrip(Vector3.new(-30, LAB_Y + 0.1, -20), 10, "z", corridor)

	-- Biohazard signs at intervals
	Shared.createBiohazardSign(Vector3.new(-40, LAB_Y + 7, -12.5), corridor, "z")
	Shared.createBiohazardSign(Vector3.new(0, LAB_Y + 7, -12.5), corridor, "z")

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(-35, LAB_Y + 3, -15),
		roomId = "LabCorridor_West",
		dwellTime = 2,
	})
	table.insert(waypoints, {
		position = Vector3.new(-10, LAB_Y + 3, -15),
		roomId = "LabCorridor_CenterWest",
		dwellTime = 2,
	})
	table.insert(waypoints, {
		position = Vector3.new(10, LAB_Y + 3, -15),
		roomId = "LabCorridor_CenterEast",
		dwellTime = 2,
	})
	table.insert(waypoints, {
		position = Vector3.new(30, LAB_Y + 3, -15),
		roomId = "LabCorridor_East",
		dwellTime = 2,
	})

	corridor.Parent = parent
end

------------------------------------------------------------------------
-- Elevator / Stairwell (Surface to Lab Level)
------------------------------------------------------------------------

local function buildElevatorStairwell(
	parent: Instance,
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } }
)
	local model = Instance.new("Model")
	model.Name = "Elevator_SurfaceToLab"

	-- Elevator shaft
	local shaftPos = Vector3.new(0, (SURFACE_Y + LAB_Y) / 2, -28)
	local shaftHeight = SURFACE_Y - LAB_Y + ROOM_HEIGHT

	-- Shaft walls
	Shared.createWall(Vector3.new(shaftPos.X - 3, shaftPos.Y, shaftPos.Z), Vector3.new(1, shaftHeight, 6), model, "Shaft_West")
	Shared.createWall(Vector3.new(shaftPos.X + 3, shaftPos.Y, shaftPos.Z), Vector3.new(1, shaftHeight, 6), model, "Shaft_East")
	Shared.createWall(Vector3.new(shaftPos.X, shaftPos.Y, shaftPos.Z - 3), Vector3.new(6, shaftHeight, 1), model, "Shaft_North")

	-- Elevator car (at Lab level)
	Shared.makePart(model, "ElevatorCar_Floor", Vector3.new(shaftPos.X, LAB_Y, shaftPos.Z), Vector3.new(5, 0.5, 5), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	Shared.makePart(model, "ElevatorCar_Back", Vector3.new(shaftPos.X, LAB_Y + 4, shaftPos.Z - 2.3), Vector3.new(5, 8, 0.3), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)

	-- Stairwell (beside elevator)
	Shared.createStairwell(LAB_Y, SURFACE_Y, Vector3.new(6, 0, -28), model, "Stairwell_SurfaceToLab")

	-- Dim stairwell lighting
	Shared.createEmergencyLight(Vector3.new(6, LAB_Y + 5, -28), model, 0.15)
	Shared.createEmergencyLight(Vector3.new(6, (SURFACE_Y + LAB_Y) / 2, -28), model, 0.15)

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(0, LAB_Y + 3, -28),
		roomId = "Elevator_LabLevel",
		dwellTime = 2,
	})

	-- Connector from elevator to lab corridor
	Shared.createCorridor(
		Vector3.new(0, LAB_Y, -25),
		Vector3.new(0, LAB_Y, -18),
		5,
		ROOM_HEIGHT,
		model,
		"Corridor_ElevatorToLab"
	)

	model.Parent = parent
end

------------------------------------------------------------------------
-- Biology Lab
------------------------------------------------------------------------

local function buildBiologyLab(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local roomPos = Vector3.new(-35, LAB_Y, -5)
	local roomSize = Vector3.new(16, ROOM_HEIGHT, 14)

	local room = Shared.createRoom({
		position = roomPos,
		size = roomSize,
		parent = parent,
		name = "BiologyLab",
		wallThickness = WALL_THICKNESS,
		wallColor = Shared.Colors.SterileWhite,
		floorColor = Color3.fromRGB(200, 200, 195),
		doorways = {
			{ wall = "north", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT },
		},
	})

	Shared.createDoor(
		Vector3.new(roomPos.X, LAB_Y + DOOR_HEIGHT / 2, roomPos.Z - roomSize.Z / 2),
		nil,
		room,
		"Door_BiologyLab",
		false,
		nil
	)

	-- Lab benches (2 rows)
	local bench1Pos = Vector3.new(roomPos.X - 3, LAB_Y, roomPos.Z - 2)
	local bench2Pos = Vector3.new(roomPos.X + 3, LAB_Y, roomPos.Z - 2)
	Shared.createLabBench(bench1Pos, room, "LabBench_1")
	Shared.createLabBench(bench2Pos, room, "LabBench_2")

	-- Microscopes on benches
	Shared.createMicroscope(bench1Pos + Vector3.new(-1, 3.4, 0), room)
	Shared.createMicroscope(bench2Pos + Vector3.new(1, 3.4, 0), room)

	-- Centrifuge on bench
	Shared.createCentrifuge(bench2Pos + Vector3.new(-1, 3.4, 0), room)

	-- Test tube racks
	Shared.createTestTubeRack(bench1Pos + Vector3.new(1.5, 3.4, 0), room)

	-- Specimen jar wall (along south wall)
	local jarShelfPos = Vector3.new(roomPos.X, LAB_Y + 3, roomPos.Z + roomSize.Z / 2 - 1.5)
	-- Shelf
	Shared.makePart(room, "SpecimenShelf", jarShelfPos + Vector3.new(0, 0, 0), Vector3.new(12, 0.3, 2), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)
	-- Upper shelf
	Shared.makePart(room, "SpecimenShelf_Upper", jarShelfPos + Vector3.new(0, 2.5, 0), Vector3.new(12, 0.3, 2), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)

	-- Specimen jars (row of jars, one large empty one)
	for i = 0, 7 do
		local jarX = jarShelfPos.X - 5 + (i * 1.5)
		local isEmpty = (i == 5) -- The large empty jar
		Shared.createSpecimenJar(Vector3.new(jarX, jarShelfPos.Y + 0.6, jarShelfPos.Z), room, isEmpty, `SpecimenJar_{i}`)
	end

	-- Large empty jar (prominent, eye level)
	local emptyJarPos = Vector3.new(jarShelfPos.X + 2, jarShelfPos.Y + 0.6, jarShelfPos.Z)
	-- Lid beside it
	Shared.makePart(room, "EmptyJar_Lid", emptyJarPos + Vector3.new(0.8, 0, 0), Vector3.new(0.7, 0.1, 0.7), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)

	-- Amber fluid spill trail
	Shared.makePart(room, "FluidSpill_Counter", jarShelfPos + Vector3.new(2, 0.2, 0.5), Vector3.new(2, 0.05, 1), Shared.Colors.SpecimenAmber, 0.3, Enum.Material.SmoothPlastic)
	Shared.makePart(room, "FluidSpill_Floor", Vector3.new(roomPos.X + 2, LAB_Y + 0.02, roomPos.Z + roomSize.Z / 2 - 2), Vector3.new(1.5, 0.03, 2), Shared.Colors.SpecimenAmber, 0.4, Enum.Material.SmoothPlastic)

	-- Backlight strip under specimen jars
	Shared.makePart(room, "JarBacklight", jarShelfPos + Vector3.new(0, -0.2, 0), Vector3.new(12, 0.1, 0.3), Color3.fromRGB(200, 180, 120), 0.2, Enum.Material.Neon)

	-- Biohazard refrigerator (corner)
	local fridgePos = Vector3.new(roomPos.X + roomSize.X / 2 - 2, LAB_Y, roomPos.Z + roomSize.Z / 2 - 2)
	Shared.createBioFridge(fridgePos, room)

	-- Sink on bench
	Shared.createFurniture("sink", Vector3.new(roomPos.X - 3, LAB_Y + 3, roomPos.Z + 2), room)

	-- Spill warning signs on floor
	Shared.makePart(room, "SpillWarning", Vector3.new(roomPos.X + 1, LAB_Y + 0.02, roomPos.Z + 3), Vector3.new(1, 0.02, 1), Shared.Colors.HazmatYellow, 0, Enum.Material.SmoothPlastic)

	-- Overturned reagent bottle
	local bottle = Shared.makePart(room, "ReagentBottle", bench1Pos + Vector3.new(2, 3.5, 0.5), Vector3.new(0.3, 0.8, 0.3), Color3.fromRGB(180, 140, 80), 0.3, Enum.Material.Glass)
	bottle.Orientation = Vector3.new(0, 0, 80)

	-- Lighting (specimen backlight + fluorescent)
	Shared.createFluorescent(Vector3.new(roomPos.X, LAB_Y + ROOM_HEIGHT - 0.5, roomPos.Z), room, true)
	Shared.createLight(Vector3.new(roomPos.X, LAB_Y + ROOM_HEIGHT - 1, roomPos.Z - 3), room, 0.3)

	-- Chemical storage cabinet
	local chemCabPos = Vector3.new(roomPos.X - roomSize.X / 2 + 2, LAB_Y, roomPos.Z + 3)
	Shared.createFurniture("cabinet", chemCabPos, room)
	-- Yellow "FLAMMABLE" label
	Shared.makePart(room, "FlammableLabel", chemCabPos + Vector3.new(0, 4, 1.1), Vector3.new(1.5, 1, 0.05), Shared.Colors.HazmatYellow, 0, Enum.Material.SmoothPlastic)

	-- Hiding spots
	Shared.createHidingSpot(Vector3.new(bench1Pos.X, LAB_Y + 0.5, bench1Pos.Z), "Desk", "lab_bio_bench1", room)
	table.insert(hidingSpots, {
		id = "lab_bio_bench1",
		position = Vector3.new(bench1Pos.X, LAB_Y + 0.5, bench1Pos.Z),
		spotType = "Desk",
		isOccupied = false,
	})

	Shared.createHidingSpot(Vector3.new(bench2Pos.X, LAB_Y + 0.5, bench2Pos.Z), "Desk", "lab_bio_bench2", room)
	table.insert(hidingSpots, {
		id = "lab_bio_bench2",
		position = Vector3.new(bench2Pos.X, LAB_Y + 0.5, bench2Pos.Z),
		spotType = "Desk",
		isOccupied = false,
	})

	Shared.createHidingSpot(fridgePos + Vector3.new(2, 1, 0), "Closet", "lab_bio_fridge", room)
	table.insert(hidingSpots, {
		id = "lab_bio_fridge",
		position = fridgePos + Vector3.new(2, 1, 0),
		spotType = "Closet",
		isOccupied = false,
	})

	Shared.createHidingSpot(chemCabPos + Vector3.new(0, 0.5, 0), "Closet", "lab_bio_chemcab", room)
	table.insert(hidingSpots, {
		id = "lab_bio_chemcab",
		position = chemCabPos + Vector3.new(0, 0.5, 0),
		spotType = "Closet",
		isOccupied = false,
	})

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(roomPos.X, LAB_Y + 3, roomPos.Z),
		roomId = "BiologyLab",
		dwellTime = 5,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = bench1Pos + Vector3.new(0, 3.5, 0),
		chance = 0.6,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Battery",
		position = bench2Pos + Vector3.new(0, 3.5, 0.5),
		chance = 0.5,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Medkit",
		position = fridgePos + Vector3.new(0, 2, 0),
		chance = 0.4,
		guaranteed = false,
	})
end

------------------------------------------------------------------------
-- Audio Lab
------------------------------------------------------------------------

local function buildAudioLab(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local roomPos = Vector3.new(-15, LAB_Y, -5)
	local roomSize = Vector3.new(14, ROOM_HEIGHT, 12)

	local room = Shared.createRoom({
		position = roomPos,
		size = roomSize,
		parent = parent,
		name = "AudioLab",
		wallThickness = WALL_THICKNESS,
		wallColor = Color3.fromRGB(60, 55, 65), -- acoustic panel color
		floorColor = Color3.fromRGB(50, 48, 55),
		ceilingColor = Color3.fromRGB(55, 50, 58),
		doorways = {
			{ wall = "north", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT },
		},
	})

	Shared.createDoor(
		Vector3.new(roomPos.X, LAB_Y + DOOR_HEIGHT / 2, roomPos.Z - roomSize.Z / 2),
		nil,
		room,
		"Door_AudioLab",
		false,
		nil
	)

	-- Acoustic panels on all walls (additional overlays)
	-- North wall
	Shared.createAcousticPanel(Vector3.new(roomPos.X - 4, LAB_Y + ROOM_HEIGHT / 2, roomPos.Z - roomSize.Z / 2 + 0.8), Vector3.new(3, ROOM_HEIGHT - 2, 0.4), room)
	Shared.createAcousticPanel(Vector3.new(roomPos.X + 4, LAB_Y + ROOM_HEIGHT / 2, roomPos.Z - roomSize.Z / 2 + 0.8), Vector3.new(3, ROOM_HEIGHT - 2, 0.4), room)
	-- South wall
	Shared.createAcousticPanel(Vector3.new(roomPos.X, LAB_Y + ROOM_HEIGHT / 2, roomPos.Z + roomSize.Z / 2 - 0.8), Vector3.new(12, ROOM_HEIGHT - 2, 0.4), room)
	-- East wall
	Shared.createAcousticPanel(Vector3.new(roomPos.X + roomSize.X / 2 - 0.8, LAB_Y + ROOM_HEIGHT / 2, roomPos.Z), Vector3.new(0.4, ROOM_HEIGHT - 2, 10), room)
	-- West wall
	Shared.createAcousticPanel(Vector3.new(roomPos.X - roomSize.X / 2 + 0.8, LAB_Y + ROOM_HEIGHT / 2, roomPos.Z), Vector3.new(0.4, ROOM_HEIGHT - 2, 10), room)
	-- Ceiling panels
	Shared.createAcousticPanel(Vector3.new(roomPos.X, LAB_Y + ROOM_HEIGHT - 0.4, roomPos.Z), Vector3.new(12, 0.4, 10), room)

	-- Recording console at center
	Shared.createRecordingConsole(Vector3.new(roomPos.X, LAB_Y, roomPos.Z), room)

	-- Speakers in corners
	local speakerPositions = {
		Vector3.new(roomPos.X - roomSize.X / 2 + 1.5, LAB_Y + 8, roomPos.Z - roomSize.Z / 2 + 1.5),
		Vector3.new(roomPos.X + roomSize.X / 2 - 1.5, LAB_Y + 8, roomPos.Z - roomSize.Z / 2 + 1.5),
		Vector3.new(roomPos.X - roomSize.X / 2 + 1.5, LAB_Y + 8, roomPos.Z + roomSize.Z / 2 - 1.5),
		Vector3.new(roomPos.X + roomSize.X / 2 - 1.5, LAB_Y + 8, roomPos.Z + roomSize.Z / 2 - 1.5),
	}
	for i, sp in speakerPositions do
		Shared.makePart(room, `Speaker_{i}`, sp, Vector3.new(1.2, 1.5, 0.8), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	end

	-- Shelf of labeled tapes (along one wall)
	local tapeShelfPos = Vector3.new(roomPos.X + roomSize.X / 2 - 2, LAB_Y + 3, roomPos.Z + 2)
	Shared.createFurniture("shelf", tapeShelfPos, room)
	-- Tape cases on shelf
	for i = 0, 5 do
		Shared.makePart(room, `TapeCase_{i}`, tapeShelfPos + Vector3.new(-1.5 + i * 0.5, 1, 0), Vector3.new(0.3, 0.5, 0.4), Shared.Colors.DarkMetal, 0, Enum.Material.SmoothPlastic)
	end

	-- Live microphone at center
	local micPos = Vector3.new(roomPos.X, LAB_Y + 4, roomPos.Z + 3)
	Shared.makePart(room, "MicStand", micPos + Vector3.new(0, -1, 0), Vector3.new(0.15, 2, 0.15), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	Shared.makePart(room, "Mic", micPos, Vector3.new(0.2, 0.6, 0.2), Color3.fromRGB(40, 40, 45), 0, Enum.Material.Metal)
	-- Green LED on mic
	Shared.makePart(room, "MicLED", micPos + Vector3.new(0, 0.35, 0.12), Vector3.new(0.06, 0.06, 0.02), Shared.Colors.ServerLedGreen, 0, Enum.Material.Neon)

	-- "RECORDING" light above door
	Shared.makePart(room, "RecordingLight", Vector3.new(roomPos.X, LAB_Y + ROOM_HEIGHT - 1, roomPos.Z - roomSize.Z / 2 + 1), Vector3.new(1.5, 0.5, 0.3), Shared.Colors.EmergencyRed, 0, Enum.Material.Neon)

	-- Leaning acoustic panels (partial cover)
	local leaningPanelPos = Vector3.new(roomPos.X - roomSize.X / 2 + 2, LAB_Y, roomPos.Z - 3)
	local panel = Shared.createAcousticPanel(leaningPanelPos + Vector3.new(0, 2.5, 0), Vector3.new(2, 5, 0.4), room)
	panel.Orientation = Vector3.new(0, 0, -15)

	-- Very dim ambient light (recording studio atmosphere)
	Shared.createLight(Vector3.new(roomPos.X, LAB_Y + ROOM_HEIGHT - 2, roomPos.Z), room, 0.1)

	-- PA switch visual
	Shared.makePart(room, "PA_Switch", Vector3.new(roomPos.X + 3, LAB_Y + 3.5, roomPos.Z - 0.5), Vector3.new(0.4, 0.4, 0.15), Shared.Colors.EmergencyRed, 0, Enum.Material.SmoothPlastic)

	-- Hiding spots
	Shared.createHidingSpot(Vector3.new(roomPos.X, LAB_Y + 0.5, roomPos.Z), "Desk", "lab_audio_console", room)
	table.insert(hidingSpots, {
		id = "lab_audio_console",
		position = Vector3.new(roomPos.X, LAB_Y + 0.5, roomPos.Z),
		spotType = "Desk",
		isOccupied = false,
	})

	Shared.createHidingSpot(leaningPanelPos, "Desk", "lab_audio_panels", room)
	table.insert(hidingSpots, {
		id = "lab_audio_panels",
		position = leaningPanelPos,
		spotType = "Desk",
		isOccupied = false,
	})

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(roomPos.X, LAB_Y + 3, roomPos.Z),
		roomId = "AudioLab",
		dwellTime = 5,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(roomPos.X + 2, LAB_Y + 3.5, roomPos.Z),
		chance = 0.8,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Battery",
		position = tapeShelfPos + Vector3.new(0, 2, 0),
		chance = 0.4,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Flare",
		position = leaningPanelPos + Vector3.new(0.5, 1, 0),
		chance = 0.3,
		guaranteed = false,
	})
end

------------------------------------------------------------------------
-- Observation Deck (overlooks Main Chamber)
------------------------------------------------------------------------

local function buildObservationDeck(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local roomPos = Vector3.new(10, LAB_Y, 0)
	local roomSize = Vector3.new(20, ROOM_HEIGHT, 14)

	local room = Shared.createRoom({
		position = roomPos,
		size = roomSize,
		parent = parent,
		name = "ObservationDeck",
		wallThickness = WALL_THICKNESS,
		wallColor = Shared.Colors.ConcreteGrey,
		floorColor = Color3.fromRGB(100, 100, 105),
		doorways = {
			{ wall = "north", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT }, -- from Lab Corridor
			{ wall = "south", offset = 5, width = DOOR_WIDTH, height = DOOR_HEIGHT }, -- elevator/ladder to Deep Level
		},
	})

	Shared.createDoor(
		Vector3.new(roomPos.X, LAB_Y + DOOR_HEIGHT / 2, roomPos.Z - roomSize.Z / 2),
		nil,
		room,
		"Door_ObsDeck_Lab",
		false,
		nil
	)

	-- Floor-to-ceiling observation window (south wall — overlooking Main Chamber below)
	Shared.makePart(room, "ObservationWindow", Vector3.new(roomPos.X - 3, LAB_Y + ROOM_HEIGHT / 2, roomPos.Z + roomSize.Z / 2 - 0.4), Vector3.new(14, ROOM_HEIGHT, 0.3), Shared.Colors.ReinforcedGlass, 0.4, Enum.Material.Glass)

	-- Monitoring desks along window
	for i = 0, 2 do
		local deskX = roomPos.X - 6 + (i * 5)
		Shared.createFurniture("desk", Vector3.new(deskX, LAB_Y, roomPos.Z + 4), room)
		Shared.createComputerTerminal(Vector3.new(deskX, LAB_Y + 3, roomPos.Z + 4), room, i ~= 1, `MonitorDesk_{i}`)
	end

	-- Telescope on tripod
	local telescopePos = Vector3.new(roomPos.X + 5, LAB_Y, roomPos.Z + 3)
	Shared.makePart(room, "TelescopeTripod_Leg1", telescopePos + Vector3.new(-0.4, 1.5, -0.4), Vector3.new(0.15, 3, 0.15), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	Shared.makePart(room, "TelescopeTripod_Leg2", telescopePos + Vector3.new(0.4, 1.5, -0.4), Vector3.new(0.15, 3, 0.15), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	Shared.makePart(room, "TelescopeTripod_Leg3", telescopePos + Vector3.new(0, 1.5, 0.4), Vector3.new(0.15, 3, 0.15), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	-- Telescope body
	local scopeBody = Shared.makePart(room, "TelescopeBody", telescopePos + Vector3.new(0, 3.2, 0), Vector3.new(0.5, 0.5, 2), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	scopeBody.Orientation = Vector3.new(30, 0, 0) -- pointing downward

	-- Freight elevator access (far end)
	local freightElevPos = Vector3.new(roomPos.X + 7, LAB_Y, roomPos.Z + roomSize.Z / 2 - 1)
	Shared.makePart(room, "FreightElevDoor_L", freightElevPos + Vector3.new(-1.5, 4, 0), Vector3.new(2.5, 7, 0.3), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	Shared.makePart(room, "FreightElevDoor_R", freightElevPos + Vector3.new(1.5, 4, 0), Vector3.new(2.5, 7, 0.3), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)

	-- Emergency floor strips
	Shared.createEmergencyStrip(Vector3.new(roomPos.X, LAB_Y + 0.1, roomPos.Z), 18, "x", room)

	-- Lighting
	Shared.createEmergencyStrip(Vector3.new(roomPos.X - 3, LAB_Y + 0.1, roomPos.Z + 5), 8, "x", room)
	Shared.createLight(Vector3.new(roomPos.X, LAB_Y + ROOM_HEIGHT - 1, roomPos.Z), room, 0.3)

	-- Hiding spots
	local underDeskPos = Vector3.new(roomPos.X - 6, LAB_Y + 0.5, roomPos.Z + 4)
	Shared.createHidingSpot(underDeskPos, "Desk", "lab_obsdeck_desk", room)
	table.insert(hidingSpots, {
		id = "lab_obsdeck_desk",
		position = underDeskPos,
		spotType = "Desk",
		isOccupied = false,
	})

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(roomPos.X, LAB_Y + 3, roomPos.Z),
		roomId = "ObservationDeck",
		dwellTime = 4,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(roomPos.X - 1, LAB_Y + 3.5, roomPos.Z + 4),
		chance = 0.6,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = freightElevPos + Vector3.new(-3, 3, 0),
		chance = 0.5,
		guaranteed = false,
	})
end

------------------------------------------------------------------------
-- Medical Bay
------------------------------------------------------------------------

local function buildMedicalBay(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local roomPos = Vector3.new(30, LAB_Y, -5)
	local roomSize = Vector3.new(16, ROOM_HEIGHT, 14)

	local room = Shared.createRoom({
		position = roomPos,
		size = roomSize,
		parent = parent,
		name = "MedicalBay",
		wallThickness = WALL_THICKNESS,
		wallColor = Shared.Colors.SterileWhite,
		floorColor = Color3.fromRGB(200, 200, 195),
		doorways = {
			{ wall = "north", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT },
		},
	})

	Shared.createDoor(
		Vector3.new(roomPos.X, LAB_Y + DOOR_HEIGHT / 2, roomPos.Z - roomSize.Z / 2),
		nil,
		room,
		"Door_MedicalBay",
		false,
		nil
	)

	-- Operating table with restraints
	local tablePos = Vector3.new(roomPos.X, LAB_Y, roomPos.Z - 1)
	Shared.makePart(room, "OpTable_Base", tablePos + Vector3.new(0, 1.5, 0), Vector3.new(3, 2.5, 6), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)
	Shared.makePart(room, "OpTable_Surface", tablePos + Vector3.new(0, 2.9, 0), Vector3.new(3.2, 0.3, 6.2), Color3.fromRGB(210, 210, 215), 0, Enum.Material.SmoothPlastic)

	-- Leather restraints
	for _, rPos in {
		Vector3.new(-1.2, 3.1, -2), Vector3.new(1.2, 3.1, -2), -- wrists
		Vector3.new(-0.8, 3.1, 2), Vector3.new(0.8, 3.1, 2), -- ankles
	} do
		Shared.makePart(room, "Restraint", tablePos + rPos, Vector3.new(0.8, 0.1, 0.4), Color3.fromRGB(80, 50, 30), 0, Enum.Material.Fabric)
	end

	-- Surgical light (overhead, still functional)
	Shared.makePart(room, "SurgicalArm", Vector3.new(roomPos.X, LAB_Y + ROOM_HEIGHT - 2, roomPos.Z - 1), Vector3.new(0.3, 3, 0.3), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)
	local surgLamp = Shared.makePart(room, "SurgicalLamp", Vector3.new(roomPos.X, LAB_Y + ROOM_HEIGHT - 4, roomPos.Z - 1), Vector3.new(2, 0.4, 2), Color3.fromRGB(220, 225, 220), 0, Enum.Material.Metal)
	local surgLight = Instance.new("SpotLight")
	surgLight.Brightness = 3
	surgLight.Color = Color3.fromRGB(255, 255, 240)
	surgLight.Range = 15
	surgLight.Angle = 45
	surgLight.Shadows = true
	surgLight.Face = Enum.NormalId.Bottom
	surgLight.Parent = surgLamp

	-- Instrument trays
	Shared.makePart(room, "InstrumentTray", tablePos + Vector3.new(-3, 2.8, 0), Vector3.new(1.5, 0.1, 2), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)
	-- Surgical instruments (small metallic props)
	for i = 0, 3 do
		Shared.makePart(room, `Instrument_{i}`, tablePos + Vector3.new(-3, 2.9, -0.5 + i * 0.4), Vector3.new(0.8, 0.05, 0.1), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)
	end
	-- Saw
	Shared.makePart(room, "BoneSaw", tablePos + Vector3.new(3, 2.9, 0), Vector3.new(0.8, 0.1, 0.15), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)

	-- Blood residue in sink
	Shared.createFurniture("sink", Vector3.new(roomPos.X + 5, LAB_Y + 3, roomPos.Z - 4), room)
	Shared.createBloodStain(Vector3.new(roomPos.X + 5, LAB_Y + 3.1, roomPos.Z - 4), Vector3.new(1, 0.02, 0.8), room)

	-- Recovery beds (2)
	for i = 0, 1 do
		local bedPos = Vector3.new(roomPos.X - 5, LAB_Y, roomPos.Z + 2 + i * 4)
		Shared.createFurniture("bed", bedPos, room)
		if i == 0 then
			-- IV drip stand
			Shared.makePart(room, "IVStand", bedPos + Vector3.new(2, 3, -0.5), Vector3.new(0.15, 6, 0.15), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)
			-- IV bag (empty — fluid pooled)
			Shared.makePart(room, "IVBag", bedPos + Vector3.new(2, 5.5, -0.5), Vector3.new(0.4, 0.8, 0.2), Color3.fromRGB(200, 200, 200), 0.3, Enum.Material.SmoothPlastic)
			-- Fluid pool on floor
			Shared.makePart(room, "IVFluidPool", bedPos + Vector3.new(2, LAB_Y + 0.02 + 15, -0.5), Vector3.new(1, 0.02, 1.5), Color3.fromRGB(180, 180, 175), 0.3, Enum.Material.SmoothPlastic)

			-- Nightstand with Medical Bay Key
			local nightstand = Vector3.new(bedPos.X + 3, LAB_Y, bedPos.Z)
			Shared.createFurniture("table", nightstand, room)
			local medKey = Shared.makePart(room, "MedicalBayKey", nightstand + Vector3.new(0, 3.3, 0), Vector3.new(0.5, 0.12, 0.8), Color3.fromRGB(190, 170, 50), 0, Enum.Material.Metal)
			medKey:SetAttribute("KeyItem", "MedicalBayKey")
			local keyGlow = Instance.new("PointLight")
			keyGlow.Brightness = 0.3
			keyGlow.Range = 4
			keyGlow.Color = Color3.fromRGB(255, 220, 100)
			keyGlow.Parent = medKey
		end
	end

	-- Supply closet (open door)
	local closetPos = Vector3.new(roomPos.X + roomSize.X / 2 - 2, LAB_Y, roomPos.Z + 3)
	Shared.makePart(room, "ClosetWall_L", closetPos + Vector3.new(-1.5, ROOM_HEIGHT / 2, 0), Vector3.new(WALL_THICKNESS, ROOM_HEIGHT, 4), COLOR_ADMIN_WALL, 0, Enum.Material.Concrete)
	Shared.makePart(room, "ClosetWall_B", closetPos + Vector3.new(0, ROOM_HEIGHT / 2, -2), Vector3.new(3, ROOM_HEIGHT, WALL_THICKNESS), COLOR_ADMIN_WALL, 0, Enum.Material.Concrete)
	-- Supply shelves inside
	Shared.createFurniture("shelf", closetPos + Vector3.new(0, 0, 0), room)

	-- Locked medication cabinet (combination lock)
	local medCabPos = Vector3.new(roomPos.X - 6, LAB_Y + 3, roomPos.Z - roomSize.Z / 2 + 1)
	Shared.makePart(room, "MedCabinet", medCabPos, Vector3.new(2.5, 3, 1), Color3.fromRGB(210, 210, 205), 0, Enum.Material.Metal)
	Shared.makePart(room, "MedCabLock", medCabPos + Vector3.new(0, 0, 0.55), Vector3.new(0.5, 0.5, 0.1), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)

	-- Blood stain on floor near table
	Shared.createBloodStain(tablePos + Vector3.new(1, -tablePos.Y + LAB_Y + 0.02, -2), Vector3.new(2.5, 0.03, 2), room)

	-- Hiding spots
	Shared.createHidingSpot(Vector3.new(tablePos.X, LAB_Y + 0.5, tablePos.Z), "Desk", "lab_med_optable", room)
	table.insert(hidingSpots, {
		id = "lab_med_optable",
		position = Vector3.new(tablePos.X, LAB_Y + 0.5, tablePos.Z),
		spotType = "Desk",
		isOccupied = false,
	})

	Shared.createHidingSpot(closetPos, "Closet", "lab_med_closet", room)
	table.insert(hidingSpots, {
		id = "lab_med_closet",
		position = closetPos,
		spotType = "Closet",
		isOccupied = false,
	})

	Shared.createHidingSpot(Vector3.new(roomPos.X - 5, LAB_Y + 0.5, roomPos.Z + 2), "Desk", "lab_med_recoverybed", room)
	table.insert(hidingSpots, {
		id = "lab_med_recoverybed",
		position = Vector3.new(roomPos.X - 5, LAB_Y + 0.5, roomPos.Z + 2),
		spotType = "Desk",
		isOccupied = false,
	})

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(roomPos.X, LAB_Y + 3, roomPos.Z),
		roomId = "MedicalBay",
		dwellTime = 5,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = closetPos + Vector3.new(0, 2, 0),
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = closetPos + Vector3.new(0, 4, 0),
		chance = 0.6,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Medkit",
		position = medCabPos,
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Battery",
		position = tablePos + Vector3.new(-3, 3, 0),
		chance = 0.4,
		guaranteed = false,
	})
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local Labs = {}

function Labs.build(parent: Instance): FloorData
	local floorModel = Instance.new("Model")
	floorModel.Name = "Labs"
	floorModel.Parent = parent

	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	buildLabCorridor(floorModel, waypoints)
	buildElevatorStairwell(floorModel, waypoints)
	buildBiologyLab(floorModel, hidingSpots, waypoints, lootPositions)
	buildAudioLab(floorModel, hidingSpots, waypoints, lootPositions)
	buildObservationDeck(floorModel, hidingSpots, waypoints, lootPositions)
	buildMedicalBay(floorModel, hidingSpots, waypoints, lootPositions)

	print(`[Labs] Built: {#hidingSpots} hiding spots, {#waypoints} waypoints, {#lootPositions} loot positions`)

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return Labs
