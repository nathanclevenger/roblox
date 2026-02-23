--!strict

--[[
	ResearchStation/AdminArea — Administrative Building geometry

	Reception, Offices 1-4 (Harlan, Tanaka, Webb, Chen),
	Director's Office (locked — requires Director's Keycard),
	and connecting hallway.

	Surface Y = 0. Single-storey concrete building.
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
local ROOM_HEIGHT = 10
local WALL_THICKNESS = 1
local DOOR_WIDTH = 5
local DOOR_HEIGHT = 8

local COLOR_ADMIN_WALL = Color3.fromRGB(195, 192, 180)
local COLOR_LINOLEUM = Color3.fromRGB(160, 158, 150)
local COLOR_DROP_CEILING = Color3.fromRGB(210, 208, 200)

------------------------------------------------------------------------
-- Reception
------------------------------------------------------------------------

local function buildReception(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local roomPos = Vector3.new(-20, SURFACE_Y, -50)
	local roomSize = Vector3.new(18, ROOM_HEIGHT, 16)

	local room = Shared.createRoom({
		position = roomPos,
		size = roomSize,
		parent = parent,
		name = "Reception",
		wallThickness = WALL_THICKNESS,
		wallColor = COLOR_ADMIN_WALL,
		floorColor = COLOR_LINOLEUM,
		ceilingColor = COLOR_DROP_CEILING,
		doorways = {
			{ wall = "north", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT }, -- from helipad
			{ wall = "east", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT }, -- to office hallway
			{ wall = "south", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT }, -- to service yard
		},
	})

	-- Front door (helipad side — one-way lock)
	Shared.createDoor(
		Vector3.new(roomPos.X, SURFACE_Y + DOOR_HEIGHT / 2, roomPos.Z - roomSize.Z / 2),
		nil,
		room,
		"Door_Reception_Front",
		false,
		nil
	)

	-- Reception desk (large L-shape)
	local deskPos = Vector3.new(roomPos.X, SURFACE_Y, roomPos.Z - 2)
	Shared.makePart(room, "ReceptionDesk_Main", deskPos + Vector3.new(0, 1.5, 0), Vector3.new(8, 3, 2), Color3.fromRGB(120, 100, 80), 0, Enum.Material.Wood)
	Shared.makePart(room, "ReceptionDesk_Side", deskPos + Vector3.new(4, 1.5, 2), Vector3.new(2, 3, 4), Color3.fromRGB(120, 100, 80), 0, Enum.Material.Wood)
	-- Desktop surface
	Shared.makePart(room, "DeskSurface", deskPos + Vector3.new(0, 3.1, 0), Vector3.new(8.2, 0.15, 2.2), Color3.fromRGB(140, 120, 95), 0, Enum.Material.Wood)

	-- Computer on desk (dead)
	Shared.createComputerTerminal(deskPos + Vector3.new(-2, 3.2, 0), room, false, "ReceptionPC")

	-- Phone on desk
	Shared.makePart(room, "DeskPhone", deskPos + Vector3.new(2, 3.3, 0), Vector3.new(0.6, 0.2, 0.8), Shared.Colors.DarkMetal, 0, Enum.Material.SmoothPlastic)

	-- Welcome sign on wall
	Shared.makePart(room, "WelcomeSign", Vector3.new(roomPos.X, SURFACE_Y + 7, roomPos.Z - roomSize.Z / 2 + 0.6), Vector3.new(10, 2, 0.1), Color3.fromRGB(30, 50, 80), 0, Enum.Material.SmoothPlastic)

	-- Photo board on wall
	Shared.makePart(room, "PhotoBoard", Vector3.new(roomPos.X - 6, SURFACE_Y + 5, roomPos.Z - roomSize.Z / 2 + 0.6), Vector3.new(4, 3, 0.1), Color3.fromRGB(140, 120, 80), 0, Enum.Material.Wood)

	-- Filing cabinets
	Shared.createFurniture("cabinet", Vector3.new(roomPos.X + 6, SURFACE_Y, roomPos.Z + 4), room)

	-- Overturned filing cabinet
	local overturnedCab = Shared.makePart(room, "OverturnedCabinet", Vector3.new(roomPos.X + 7, SURFACE_Y + 1.5, roomPos.Z - 5), Vector3.new(3, 6, 2), Color3.fromRGB(160, 160, 155), 0, Enum.Material.Metal)
	overturnedCab.Orientation = Vector3.new(0, 15, 70)

	-- Scattered papers
	for i = 1, 6 do
		local paperPos = Vector3.new(
			roomPos.X + (math.random() - 0.5) * 12,
			SURFACE_Y + 0.05,
			roomPos.Z + (math.random() - 0.5) * 10
		)
		Shared.makePart(room, `Paper_{i}`, paperPos, Vector3.new(0.6, 0.02, 0.8), Color3.fromRGB(230, 225, 210), 0, Enum.Material.SmoothPlastic)
	end

	-- Dead fluorescent (one flickers briefly on entry — handled by scripts)
	Shared.createFluorescent(Vector3.new(roomPos.X, SURFACE_Y + ROOM_HEIGHT - 0.5, roomPos.Z), room, false)
	-- Emergency strip on floor
	Shared.createEmergencyStrip(Vector3.new(roomPos.X, SURFACE_Y + 0.1, roomPos.Z), 14, "x", room)

	-- Hiding spots
	local underDeskPos = Vector3.new(deskPos.X, SURFACE_Y + 0.5, deskPos.Z)
	Shared.createHidingSpot(underDeskPos, "Desk", "admin_reception_desk", room)
	table.insert(hidingSpots, {
		id = "admin_reception_desk",
		position = underDeskPos,
		spotType = "Desk",
		isOccupied = false,
	})

	local behindCabPos = Vector3.new(roomPos.X + 7, SURFACE_Y + 1, roomPos.Z - 5)
	Shared.createHidingSpot(behindCabPos, "Desk", "admin_reception_cabinet", room)
	table.insert(hidingSpots, {
		id = "admin_reception_cabinet",
		position = behindCabPos,
		spotType = "Desk",
		isOccupied = false,
	})

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(roomPos.X, SURFACE_Y + 3, roomPos.Z),
		roomId = "Reception",
		dwellTime = 3,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = deskPos + Vector3.new(1, 3.4, 0),
		chance = 0.7,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = Vector3.new(roomPos.X - 7, SURFACE_Y + 3, roomPos.Z + 5),
		chance = 0.5,
		guaranteed = false,
	})
end

------------------------------------------------------------------------
-- Office Hallway
------------------------------------------------------------------------

local function buildOfficeHallway(
	parent: Instance,
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } }
)
	local hallway = Instance.new("Model")
	hallway.Name = "OfficeHallway"

	-- Narrow hallway running east from reception
	local hallStart = Vector3.new(-10, SURFACE_Y, -50)
	local hallEnd = Vector3.new(15, SURFACE_Y, -50)
	Shared.createCorridor(hallStart, hallEnd, 4, ROOM_HEIGHT, hallway, "OfficeHallway_Main")

	-- Emergency lighting (dim red)
	Shared.createEmergencyLight(Vector3.new(-5, SURFACE_Y + ROOM_HEIGHT - 1, -50), hallway, 0.2)
	Shared.createEmergencyLight(Vector3.new(5, SURFACE_Y + ROOM_HEIGHT - 1, -50), hallway, 0.2)
	Shared.createEmergencyLight(Vector3.new(12, SURFACE_Y + ROOM_HEIGHT - 1, -50), hallway, 0.2)

	-- Floor strip
	Shared.createEmergencyStrip(Vector3.new(2.5, SURFACE_Y + 0.1, -50), 25, "x", hallway)

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(-5, SURFACE_Y + 3, -50),
		roomId = "OfficeHallway_West",
		dwellTime = 2,
	})
	table.insert(waypoints, {
		position = Vector3.new(10, SURFACE_Y + 3, -50),
		roomId = "OfficeHallway_East",
		dwellTime = 2,
	})

	hallway.Parent = parent
end

------------------------------------------------------------------------
-- Offices 1-4
------------------------------------------------------------------------

local function buildOffice(
	parent: Instance,
	roomPos: Vector3,
	officeName: string,
	officeId: number,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local roomSize = Vector3.new(8, ROOM_HEIGHT, 8)

	local room = Shared.createRoom({
		position = roomPos,
		size = roomSize,
		parent = parent,
		name = officeName,
		wallThickness = WALL_THICKNESS,
		wallColor = COLOR_ADMIN_WALL,
		floorColor = COLOR_LINOLEUM,
		ceilingColor = COLOR_DROP_CEILING,
		doorways = {
			{ wall = "south", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT },
		},
	})

	Shared.createDoor(
		Vector3.new(roomPos.X, SURFACE_Y + DOOR_HEIGHT / 2, roomPos.Z + roomSize.Z / 2),
		nil,
		room,
		`Door_Office{officeId}`,
		false,
		nil
	)

	-- Desk
	local deskPos = Vector3.new(roomPos.X, SURFACE_Y, roomPos.Z - 1)
	Shared.createFurniture("desk", deskPos, room)

	-- Chair
	Shared.createFurniture("chair", Vector3.new(roomPos.X, SURFACE_Y, roomPos.Z + 1), room)

	-- Computer (dead)
	Shared.createComputerTerminal(deskPos + Vector3.new(0, 3, 0), room, false, `PC_Office{officeId}`)

	-- Filing cabinet
	local cabPos = Vector3.new(roomPos.X - 3, SURFACE_Y, roomPos.Z - 2)
	Shared.createFurniture("cabinet", cabPos, room)

	-- Very dim light
	Shared.createLight(Vector3.new(roomPos.X, SURFACE_Y + ROOM_HEIGHT - 1, roomPos.Z), room, 0.1)

	-- Office-specific props
	if officeId == 1 then
		-- Harlan's office: terrarium, specimen manifests
		Shared.makePart(room, "Terrarium", Vector3.new(roomPos.X + 3, SURFACE_Y + 4, roomPos.Z - 3), Vector3.new(1.5, 1, 1), Color3.fromRGB(180, 200, 180), 0.4, Enum.Material.Glass)
		-- Framed photo
		Shared.makePart(room, "FramedPhoto", Vector3.new(roomPos.X + 3, SURFACE_Y + 5.5, roomPos.Z - 3.5), Vector3.new(1, 0.8, 0.1), Color3.fromRGB(120, 100, 80), 0, Enum.Material.Wood)
		-- Loot
		table.insert(lootPositions, {
			itemType = "Battery",
			position = deskPos + Vector3.new(1, 3.4, 0),
			chance = 0.4,
			guaranteed = false,
		})
	elseif officeId == 2 then
		-- Tanaka's office: headphones, reel-to-reel, whiteboard
		Shared.makePart(room, "Headphones", deskPos + Vector3.new(-1.5, 3.3, 0), Vector3.new(0.6, 0.4, 0.6), Shared.Colors.DarkMetal, 0, Enum.Material.SmoothPlastic)
		-- Whiteboard
		Shared.makePart(room, "Whiteboard", Vector3.new(roomPos.X, SURFACE_Y + 6, roomPos.Z - roomSize.Z / 2 + 0.6), Vector3.new(5, 3, 0.15), Color3.fromRGB(240, 240, 240), 0, Enum.Material.SmoothPlastic)
		-- Waveform sketches on whiteboard
		Shared.makePart(room, "WaveformSketch", Vector3.new(roomPos.X, SURFACE_Y + 6, roomPos.Z - roomSize.Z / 2 + 0.7), Vector3.new(4, 0.08, 0.02), Color3.fromRGB(40, 60, 150), 0, Enum.Material.SmoothPlastic)
		-- Cassette tape (key item)
		local tapePos = deskPos + Vector3.new(1.5, 3.3, 0.5)
		local tape = Shared.makePart(room, "CassetteTape", tapePos, Vector3.new(0.6, 0.1, 0.4), Shared.Colors.DarkMetal, 0, Enum.Material.SmoothPlastic)
		tape:SetAttribute("KeyItem", "CassetteTape")
		local tapeGlow = Instance.new("PointLight")
		tapeGlow.Brightness = 0.3
		tapeGlow.Range = 4
		tapeGlow.Color = Color3.fromRGB(200, 180, 100)
		tapeGlow.Parent = tape
	elseif officeId == 3 then
		-- Webb's office: gun safe (open, empty), incident reports, facility map
		Shared.makePart(room, "GunSafe", Vector3.new(roomPos.X + 3, SURFACE_Y + 2, roomPos.Z - 3), Vector3.new(1.5, 4, 1.5), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
		-- Safe door (open)
		local safeDoor = Shared.makePart(room, "SafeDoor", Vector3.new(roomPos.X + 3, SURFACE_Y + 2, roomPos.Z - 2.2), Vector3.new(1.3, 3.5, 0.15), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
		safeDoor.Orientation = Vector3.new(0, 45, 0)
		-- Empty holster
		Shared.makePart(room, "Holster", deskPos + Vector3.new(-1, 3.2, 0), Vector3.new(0.4, 0.3, 0.6), Color3.fromRGB(60, 50, 40), 0, Enum.Material.Fabric)
		-- Facility map on wall
		Shared.makePart(room, "FacilityMap", Vector3.new(roomPos.X - 3, SURFACE_Y + 5.5, roomPos.Z - roomSize.Z / 2 + 0.6), Vector3.new(3, 2, 0.05), Color3.fromRGB(220, 215, 200), 0, Enum.Material.SmoothPlastic)

		-- Filing cabinet hiding spot (large)
		Shared.createHidingSpot(cabPos, "Closet", `admin_office{officeId}_cabinet`, room)
		table.insert(hidingSpots, {
			id = `admin_office{officeId}_cabinet`,
			position = cabPos,
			spotType = "Closet",
			isOccupied = false,
		})

		-- Guaranteed bandage
		table.insert(lootPositions, {
			itemType = "Bandage",
			position = deskPos + Vector3.new(0, 3.4, 0),
			chance = 1,
			guaranteed = true,
		})
	elseif officeId == 4 then
		-- Chen's office: medical charts, locked medicine cabinet
		-- Charts on desk
		Shared.makePart(room, "MedicalCharts", deskPos + Vector3.new(0, 3.3, -0.5), Vector3.new(2, 0.15, 1.5), Color3.fromRGB(230, 225, 210), 0, Enum.Material.SmoothPlastic)
		-- Locked medicine cabinet
		local medCabinetPos = Vector3.new(roomPos.X + 3, SURFACE_Y + 3, roomPos.Z + 2)
		Shared.makePart(room, "MedicineCabinet", medCabinetPos, Vector3.new(2, 3, 1), Color3.fromRGB(210, 210, 205), 0, Enum.Material.Metal)
		-- Lock indicator
		Shared.makePart(room, "CabinetLock", medCabinetPos + Vector3.new(0, 0, 0.55), Vector3.new(0.4, 0.4, 0.1), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)

		-- Medkit inside (locked, requires Medical Bay key)
		table.insert(lootPositions, {
			itemType = "Medkit",
			position = medCabinetPos,
			chance = 1,
			guaranteed = true,
		})
	end

	-- Under-desk hiding spot for all offices
	local underDeskPos = Vector3.new(deskPos.X, SURFACE_Y + 0.5, deskPos.Z)
	Shared.createHidingSpot(underDeskPos, "Desk", `admin_office{officeId}_desk`, room)
	table.insert(hidingSpots, {
		id = `admin_office{officeId}_desk`,
		position = underDeskPos,
		spotType = "Desk",
		isOccupied = false,
	})

	-- Waypoint
	table.insert(waypoints, {
		position = Vector3.new(roomPos.X, SURFACE_Y + 3, roomPos.Z),
		roomId = officeName,
		dwellTime = 4,
	})
end

------------------------------------------------------------------------
-- Director's Office (locked)
------------------------------------------------------------------------

local function buildDirectorOffice(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local roomPos = Vector3.new(0, SURFACE_Y, -65)
	local roomSize = Vector3.new(14, ROOM_HEIGHT, 12)

	local room = Shared.createRoom({
		position = roomPos,
		size = roomSize,
		parent = parent,
		name = "DirectorOffice",
		wallThickness = WALL_THICKNESS,
		wallColor = Color3.fromRGB(180, 170, 155),
		floorColor = Color3.fromRGB(100, 75, 55),
		floorMaterial = Enum.Material.Wood,
		ceilingColor = COLOR_DROP_CEILING,
		doorways = {
			{ wall = "north", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT },
		},
	})

	-- Reinforced steel door (locked — requires Director's Keycard)
	Shared.createDoor(
		Vector3.new(roomPos.X, SURFACE_Y + DOOR_HEIGHT / 2, roomPos.Z - roomSize.Z / 2),
		nil,
		room,
		"Door_DirectorOffice",
		true,
		"DirectorKeycard"
	)

	-- Keycard reader
	Shared.makePart(room, "KeycardReader", Vector3.new(roomPos.X + 3, SURFACE_Y + 4, roomPos.Z - roomSize.Z / 2 - 0.5), Vector3.new(0.4, 0.6, 0.15), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)

	-- Mahogany desk
	local deskPos = Vector3.new(roomPos.X, SURFACE_Y, roomPos.Z + 1)
	Shared.makePart(room, "MahoganyDesk_Top", deskPos + Vector3.new(0, 3, 0), Vector3.new(7, 0.5, 3.5), Color3.fromRGB(90, 55, 35), 0, Enum.Material.Wood)
	-- Desk modesty panel
	Shared.makePart(room, "MahoganyDesk_Panel", deskPos + Vector3.new(0, 1.5, -1.5), Vector3.new(6.5, 3, 0.3), Color3.fromRGB(90, 55, 35), 0, Enum.Material.Wood)
	-- Desk legs
	for _, offset in { Vector3.new(-3, 1.5, -1.5), Vector3.new(3, 1.5, -1.5), Vector3.new(-3, 1.5, 1.5), Vector3.new(3, 1.5, 1.5) } do
		Shared.makePart(room, "DeskLeg", deskPos + offset, Vector3.new(0.4, 3, 0.4), Color3.fromRGB(80, 50, 30), 0, Enum.Material.Wood)
	end

	-- Leather chair
	Shared.makePart(room, "LeatherChair_Seat", deskPos + Vector3.new(0, 2.2, 2), Vector3.new(2.5, 0.5, 2.5), Color3.fromRGB(50, 35, 25), 0, Enum.Material.Fabric)
	Shared.makePart(room, "LeatherChair_Back", deskPos + Vector3.new(0, 3.5, 3), Vector3.new(2.5, 2.5, 0.4), Color3.fromRGB(50, 35, 25), 0, Enum.Material.Fabric)

	-- Director's PC (boots when approached)
	Shared.createComputerTerminal(deskPos + Vector3.new(-2, 3, 0), room, true, "DirectorPC")

	-- Desk safe (under desk)
	Shared.makePart(room, "DeskSafe", deskPos + Vector3.new(2, 1, 0), Vector3.new(1.5, 1.5, 1.5), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)

	-- Whiskey glass
	Shared.makePart(room, "WhiskeyGlass", deskPos + Vector3.new(1, 3.4, -0.5), Vector3.new(0.3, 0.4, 0.3), Color3.fromRGB(200, 190, 160), 0.5, Enum.Material.Glass)

	-- Bookshelves along west wall
	for i = 0, 2 do
		local shelfZ = roomPos.Z - 3 + (i * 3)
		Shared.createFurniture("shelf", Vector3.new(roomPos.X - roomSize.X / 2 + 2, SURFACE_Y, shelfZ), room)
	end

	-- Conference table
	local confPos = Vector3.new(roomPos.X + 4, SURFACE_Y, roomPos.Z - 3)
	Shared.createFurniture("table", confPos, room)
	Shared.createFurniture("chair", confPos + Vector3.new(-2, 0, 0), room)
	Shared.createFurniture("chair", confPos + Vector3.new(2, 0, 0), room)

	-- First aid kit on conference table
	Shared.makePart(room, "FirstAidKit", confPos + Vector3.new(0, 3.5, 0), Vector3.new(1, 0.6, 0.6), Shared.Colors.EmergencyRed, 0, Enum.Material.SmoothPlastic)

	-- DoD commendation on wall (blacked out name)
	Shared.makePart(room, "Commendation", Vector3.new(roomPos.X + 5, SURFACE_Y + 6, roomPos.Z + roomSize.Z / 2 - 0.6), Vector3.new(2, 2.5, 0.1), Color3.fromRGB(140, 120, 80), 0, Enum.Material.Wood)

	-- Window overlooking service yard (west wall)
	Shared.makePart(room, "Window_Director", Vector3.new(roomPos.X + roomSize.X / 2 - 0.5, SURFACE_Y + 5, roomPos.Z), Vector3.new(0.2, 4, 6), Shared.Colors.ReinforcedGlass, 0.5, Enum.Material.Glass)

	-- Lighting
	Shared.createLight(Vector3.new(roomPos.X, SURFACE_Y + ROOM_HEIGHT - 1, roomPos.Z), room, 0.3)

	-- Hiding spots
	Shared.createHidingSpot(Vector3.new(confPos.X, SURFACE_Y + 0.5, confPos.Z), "Desk", "admin_director_table", room)
	table.insert(hidingSpots, {
		id = "admin_director_table",
		position = Vector3.new(confPos.X, SURFACE_Y + 0.5, confPos.Z),
		spotType = "Desk",
		isOccupied = false,
	})

	local behindShelfPos = Vector3.new(roomPos.X - roomSize.X / 2 + 1, SURFACE_Y + 1, roomPos.Z + 3)
	Shared.createHidingSpot(behindShelfPos, "Closet", "admin_director_shelf", room)
	table.insert(hidingSpots, {
		id = "admin_director_shelf",
		position = behindShelfPos,
		spotType = "Closet",
		isOccupied = false,
	})

	-- Waypoint
	table.insert(waypoints, {
		position = Vector3.new(roomPos.X, SURFACE_Y + 3, roomPos.Z),
		roomId = "DirectorOffice",
		dwellTime = 6,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = deskPos + Vector3.new(0, 3.4, 0),
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Medkit",
		position = confPos + Vector3.new(0, 3.5, 0),
		chance = 0.6,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Flare",
		position = deskPos + Vector3.new(-1, 3.4, 0),
		chance = 0.4,
		guaranteed = false,
	})
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local AdminArea = {}

function AdminArea.build(parent: Instance): FloorData
	local floorModel = Instance.new("Model")
	floorModel.Name = "AdminArea"
	floorModel.Parent = parent

	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	-- Build reception
	buildReception(floorModel, hidingSpots, waypoints, lootPositions)

	-- Build office hallway
	buildOfficeHallway(floorModel, waypoints)

	-- Build offices 1-4 (lined along hallway, north side)
	local officeConfigs = {
		{ pos = Vector3.new(-8, SURFACE_Y, -57), name = "Office1_Harlan", id = 1 },
		{ pos = Vector3.new(-1, SURFACE_Y, -57), name = "Office2_Tanaka", id = 2 },
		{ pos = Vector3.new(6, SURFACE_Y, -57), name = "Office3_Webb", id = 3 },
		{ pos = Vector3.new(13, SURFACE_Y, -57), name = "Office4_Chen", id = 4 },
	}

	for _, cfg in officeConfigs do
		buildOffice(floorModel, cfg.pos, cfg.name, cfg.id, hidingSpots, waypoints, lootPositions)
	end

	-- Build director's office
	buildDirectorOffice(floorModel, hidingSpots, waypoints, lootPositions)

	-- Connecting corridor from hallway to director's office
	Shared.createCorridor(
		Vector3.new(0, SURFACE_Y, -52),
		Vector3.new(0, SURFACE_Y, -60),
		4,
		ROOM_HEIGHT,
		floorModel,
		"Corridor_ToDirector"
	)

	-- Connecting corridor from reception south to service yard area
	Shared.createCorridor(
		Vector3.new(-20, SURFACE_Y, -42),
		Vector3.new(-20, SURFACE_Y, -30),
		4,
		ROOM_HEIGHT,
		floorModel,
		"Corridor_ToServiceYard"
	)

	print(`[AdminArea] Built: {#hidingSpots} hiding spots, {#waypoints} waypoints, {#lootPositions} loot positions`)

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return AdminArea
