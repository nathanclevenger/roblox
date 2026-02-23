--!strict

--[[
	ResearchStation/ContainmentWing — Containment areas on Lab Level (B1)

	Cell Block A (shattered A4), Cell Block B (mannequin in B3),
	Containment Control (monitors, Director's Keycard),
	and Containment Corridor connecting them.

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

local LAB_Y = -15
local ROOM_HEIGHT = 12
local WALL_THICKNESS = 1
local DOOR_WIDTH = 5
local DOOR_HEIGHT = 8
local CELL_SIZE = Vector3.new(6, ROOM_HEIGHT, 6)

------------------------------------------------------------------------
-- Cell Block A
------------------------------------------------------------------------

local function buildCellBlockA(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local blockModel = Instance.new("Model")
	blockModel.Name = "CellBlockA"

	local blockOriginX = -30
	local blockOriginZ = -40
	local cellSpacing = 8

	-- Cell A1: empty, intact, door open
	local cellA1Pos = Vector3.new(blockOriginX, LAB_Y, blockOriginZ)
	local cellA1 = Shared.createContainmentCell(cellA1Pos, CELL_SIZE, blockModel, "CellA1", false, "right")

	-- Steel bed frame inside A1
	Shared.makePart(cellA1, "BedFrame", cellA1Pos + Vector3.new(0, 1, -1.5), Vector3.new(3, 1.5, 5), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)

	-- Cell A2: knocked-over chair, circular scratch marks
	local cellA2Pos = Vector3.new(blockOriginX + cellSpacing, LAB_Y, blockOriginZ)
	local cellA2 = Shared.createContainmentCell(cellA2Pos, CELL_SIZE, blockModel, "CellA2", false, "right")

	-- Knocked-over chair
	local chairA2 = Shared.makePart(cellA2, "KnockedChair", cellA2Pos + Vector3.new(1, 0.5, 0), Vector3.new(1.5, 1.5, 1.5), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	chairA2.Orientation = Vector3.new(0, 20, 70)

	-- Circular scratch marks (at standing height on all walls)
	Shared.createScratchMarks(cellA2Pos + Vector3.new(0, 5, -CELL_SIZE.Z / 2 + 0.6), 5, "z", cellA2)
	Shared.createScratchMarks(cellA2Pos + Vector3.new(0, 5, CELL_SIZE.Z / 2 - 0.6), 5, "z", cellA2)
	Shared.createScratchMarks(cellA2Pos + Vector3.new(-CELL_SIZE.X / 2 + 0.6, 5, 0), 5, "x", cellA2)
	Shared.createScratchMarks(cellA2Pos + Vector3.new(CELL_SIZE.X / 2 - 0.6, 5, 0), 5, "x", cellA2)

	-- Cell A3: empty, camera still active (red blinking light)
	local cellA3Pos = Vector3.new(blockOriginX + cellSpacing * 2, LAB_Y, blockOriginZ)
	local cellA3 = Shared.createContainmentCell(cellA3Pos, CELL_SIZE, blockModel, "CellA3", false, "right")

	-- Active camera light
	local cameraLight = Shared.makePart(cellA3, "CameraLED", cellA3Pos + Vector3.new(CELL_SIZE.X / 4, LAB_Y + ROOM_HEIGHT - 0.5 + 15, CELL_SIZE.Z / 4), Vector3.new(0.1, 0.1, 0.1), Shared.Colors.EmergencyRed, 0, Enum.Material.Neon)
	local ledGlow = Instance.new("PointLight")
	ledGlow.Brightness = 0.2
	ledGlow.Color = Color3.fromRGB(255, 0, 0)
	ledGlow.Range = 3
	ledGlow.Shadows = false
	ledGlow.Parent = cameraLight

	-- Cell A4: shattered glass, bent bed frame
	local cellA4Pos = Vector3.new(blockOriginX + cellSpacing * 3, LAB_Y, blockOriginZ)
	local cellA4 = Shared.createContainmentCell(cellA4Pos, CELL_SIZE, blockModel, "CellA4", true, nil)

	-- Bent bed frame (twisted into humanoid sitting shape)
	local bentFrame = Shared.makePart(cellA4, "BentBedFrame_Base", cellA4Pos + Vector3.new(0, 1, 0), Vector3.new(3, 1, 5), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)
	bentFrame.Orientation = Vector3.new(0, 0, 15)
	-- Vertical piece (torso-like)
	local bentVertical = Shared.makePart(cellA4, "BentBedFrame_Vertical", cellA4Pos + Vector3.new(0, 3, -1), Vector3.new(1, 3, 0.5), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)
	bentVertical.Orientation = Vector3.new(-10, 0, 5)
	-- Head-like curl
	Shared.makePart(cellA4, "BentBedFrame_Top", cellA4Pos + Vector3.new(0, 4.5, -1.2), Vector3.new(0.8, 0.8, 0.8), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)

	-- Clipboard mounted outside A4 (on corridor wall)
	Shared.makePart(blockModel, "Clipboard_A4", cellA4Pos + Vector3.new(CELL_SIZE.X / 2 + 1, 4, CELL_SIZE.Z / 2 + 1), Vector3.new(0.8, 1, 0.05), Color3.fromRGB(160, 140, 100), 0, Enum.Material.Wood)

	-- Emergency Breach Protocol sign on wall
	Shared.makePart(blockModel, "BreachProtocol", Vector3.new(blockOriginX + cellSpacing, LAB_Y + 6, blockOriginZ + CELL_SIZE.Z / 2 + 2), Vector3.new(3, 2, 0.05), Color3.fromRGB(230, 225, 210), 0, Enum.Material.SmoothPlastic)

	-- Corridor lights (harsh fluorescent — emergency)
	Shared.createFluorescent(Vector3.new(blockOriginX + cellSpacing, LAB_Y + ROOM_HEIGHT - 0.5, blockOriginZ + CELL_SIZE.Z / 2 + 2), blockModel, true)
	Shared.createFluorescent(Vector3.new(blockOriginX + cellSpacing * 2.5, LAB_Y + ROOM_HEIGHT - 0.5, blockOriginZ + CELL_SIZE.Z / 2 + 2), blockModel, false)

	-- Cell lighting (dim, clinical)
	Shared.createLight(cellA1Pos + Vector3.new(0, ROOM_HEIGHT - 1, 0), cellA1, 0.2)
	Shared.createLight(cellA2Pos + Vector3.new(0, ROOM_HEIGHT - 1, 0), cellA2, 0.15)
	Shared.createLight(cellA3Pos + Vector3.new(0, ROOM_HEIGHT - 1, 0), cellA3, 0.2)
	Shared.createLight(cellA4Pos + Vector3.new(0, ROOM_HEIGHT - 1, 0), cellA4, 0.1)

	-- Observation corridor (runs south of cells)
	Shared.createCorridor(
		Vector3.new(blockOriginX - 2, LAB_Y, blockOriginZ + CELL_SIZE.Z / 2 + 2),
		Vector3.new(blockOriginX + cellSpacing * 3 + 2, LAB_Y, blockOriginZ + CELL_SIZE.Z / 2 + 2),
		5,
		ROOM_HEIGHT,
		blockModel,
		"CellBlockA_Corridor"
	)

	-- Hiding spots
	Shared.createHidingSpot(cellA1Pos + Vector3.new(0, LAB_Y + 1 + 15, 0), "Desk", "contain_cellA1", cellA1)
	table.insert(hidingSpots, {
		id = "contain_cellA1",
		position = cellA1Pos + Vector3.new(0, LAB_Y + 1 + 15, 0),
		spotType = "Desk",
		isOccupied = false,
	})

	Shared.createHidingSpot(cellA4Pos + Vector3.new(2, LAB_Y + 0.5 + 15, CELL_SIZE.Z / 2 + 1), "Desk", "contain_cellA4_debris", blockModel)
	table.insert(hidingSpots, {
		id = "contain_cellA4_debris",
		position = cellA4Pos + Vector3.new(2, LAB_Y + 0.5 + 15, CELL_SIZE.Z / 2 + 1),
		spotType = "Desk",
		isOccupied = false,
	})

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(blockOriginX + cellSpacing, LAB_Y + 3, blockOriginZ + CELL_SIZE.Z / 2 + 2),
		roomId = "CellBlockA_Corridor",
		dwellTime = 4,
	})
	table.insert(waypoints, {
		position = Vector3.new(blockOriginX + cellSpacing * 3, LAB_Y + 3, blockOriginZ + CELL_SIZE.Z / 2 + 2),
		roomId = "CellBlockA_A4",
		dwellTime = 5,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(blockOriginX + cellSpacing * 3, LAB_Y + 1, blockOriginZ + CELL_SIZE.Z / 2 + 2),
		chance = 0.6,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = cellA1Pos + Vector3.new(0, LAB_Y + 1 + 15, 0),
		chance = 0.5,
		guaranteed = false,
	})

	blockModel.Parent = parent
end

------------------------------------------------------------------------
-- Cell Block B
------------------------------------------------------------------------

local function buildCellBlockB(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local blockModel = Instance.new("Model")
	blockModel.Name = "CellBlockB"

	local blockOriginX = -30
	local blockOriginZ = -55
	local cellSpacing = 8

	-- Cell B1: empty
	local cellB1Pos = Vector3.new(blockOriginX, LAB_Y, blockOriginZ)
	Shared.createContainmentCell(cellB1Pos, CELL_SIZE, blockModel, "CellB1", false, "right")

	-- Cell B2: standard furnishings (bed, chair, camera)
	local cellB2Pos = Vector3.new(blockOriginX + cellSpacing, LAB_Y, blockOriginZ)
	local cellB2 = Shared.createContainmentCell(cellB2Pos, CELL_SIZE, blockModel, "CellB2", false, "right")
	Shared.makePart(cellB2, "BedFrame_B2", cellB2Pos + Vector3.new(-1, 1, -1), Vector3.new(3, 1.5, 5), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)
	Shared.createFurniture("chair", cellB2Pos + Vector3.new(1.5, LAB_Y + 15, 1), cellB2)

	-- Cell B3: mannequin standing at center, facing glass
	local cellB3Pos = Vector3.new(blockOriginX + cellSpacing * 2, LAB_Y, blockOriginZ)
	local cellB3 = Shared.createContainmentCell(cellB3Pos, CELL_SIZE, blockModel, "CellB3", false, "right")
	Shared.createMannequin(cellB3Pos + Vector3.new(0, 0, 0), cellB3, true)

	-- Classification plate on glass
	Shared.makePart(cellB3, "ClassificationPlate", cellB3Pos + Vector3.new(2, 5, CELL_SIZE.Z / 2 + 0.7), Vector3.new(2, 1, 0.05), Color3.fromRGB(200, 200, 195), 0, Enum.Material.Metal)

	-- Cell B4: dark, tinted glass (contents hidden until override)
	local cellB4Pos = Vector3.new(blockOriginX + cellSpacing * 3, LAB_Y, blockOriginZ)
	local cellB4 = Shared.createContainmentCell(cellB4Pos, CELL_SIZE, blockModel, "CellB4", false, "right")
	-- Tint the glass wall dark
	Shared.makePart(cellB4, "TintedOverlay", cellB4Pos + Vector3.new(0, ROOM_HEIGHT / 2, CELL_SIZE.Z / 2 + 0.6), Vector3.new(CELL_SIZE.X, ROOM_HEIGHT, 0.1), Color3.fromRGB(20, 20, 25), 0.4, Enum.Material.Glass)

	-- B4 interior (revealed after override): desk with drawings
	local drawingDeskPos = cellB4Pos + Vector3.new(0, 0, 0)
	Shared.createFurniture("desk", drawingDeskPos, cellB4)
	-- Drawings scattered on desk
	for i = 1, 4 do
		Shared.makePart(cellB4, `Drawing_{i}`, drawingDeskPos + Vector3.new((i - 2.5) * 0.8, 3.3, 0), Vector3.new(0.6, 0.02, 0.8), Color3.fromRGB(230, 225, 210), 0, Enum.Material.SmoothPlastic)
	end

	-- Observation corridor (south of B cells)
	Shared.createCorridor(
		Vector3.new(blockOriginX - 2, LAB_Y, blockOriginZ + CELL_SIZE.Z / 2 + 2),
		Vector3.new(blockOriginX + cellSpacing * 3 + 2, LAB_Y, blockOriginZ + CELL_SIZE.Z / 2 + 2),
		5,
		ROOM_HEIGHT,
		blockModel,
		"CellBlockB_Corridor"
	)

	-- Cell lighting
	for i, pos in { cellB1Pos, cellB2Pos, cellB3Pos } do
		Shared.createLight(pos + Vector3.new(0, ROOM_HEIGHT - 1, 0), blockModel, 0.2)
	end
	-- B4 is dark (no light until override)
	Shared.createLight(cellB4Pos + Vector3.new(0, ROOM_HEIGHT - 1, 0), cellB4, 0.02)

	-- Corridor lights
	Shared.createFluorescent(Vector3.new(blockOriginX + cellSpacing, LAB_Y + ROOM_HEIGHT - 0.5, blockOriginZ + CELL_SIZE.Z / 2 + 2), blockModel, true)

	-- Support column between B2 and B3
	local columnPos = Vector3.new(blockOriginX + cellSpacing * 1.5, LAB_Y + ROOM_HEIGHT / 2, blockOriginZ + CELL_SIZE.Z / 2 + 2)
	Shared.makePart(blockModel, "SupportColumn", columnPos, Vector3.new(1.5, ROOM_HEIGHT, 1.5), Shared.Colors.ConcreteGrey, 0, Enum.Material.Concrete)

	-- Hiding spots
	Shared.createHidingSpot(columnPos + Vector3.new(0, -ROOM_HEIGHT / 2 + 1, 0), "Desk", "contain_column_B2B3", blockModel)
	table.insert(hidingSpots, {
		id = "contain_column_B2B3",
		position = columnPos + Vector3.new(0, -ROOM_HEIGHT / 2 + 1, 0),
		spotType = "Desk",
		isOccupied = false,
	})

	Shared.createHidingSpot(cellB1Pos + Vector3.new(0, 1, 0), "Desk", "contain_cellB1", blockModel)
	table.insert(hidingSpots, {
		id = "contain_cellB1",
		position = cellB1Pos + Vector3.new(0, 1, 0),
		spotType = "Desk",
		isOccupied = false,
	})

	-- Shelf outside B1
	Shared.createFurniture("shelf", Vector3.new(blockOriginX, LAB_Y, blockOriginZ + CELL_SIZE.Z / 2 + 3), blockModel)

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(blockOriginX + cellSpacing * 1.5, LAB_Y + 3, blockOriginZ + CELL_SIZE.Z / 2 + 2),
		roomId = "CellBlockB_Corridor",
		dwellTime = 4,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(blockOriginX, LAB_Y + 3, blockOriginZ + CELL_SIZE.Z / 2 + 3),
		chance = 0.5,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Medkit",
		position = cellB4Pos + Vector3.new(0, 3.4, 0),
		chance = 1,
		guaranteed = true,
	})

	blockModel.Parent = parent
end

------------------------------------------------------------------------
-- Containment Control
------------------------------------------------------------------------

local function buildContainmentControl(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local roomPos = Vector3.new(5, LAB_Y, -47)
	local roomSize = Vector3.new(14, ROOM_HEIGHT, 10)

	local room = Shared.createRoom({
		position = roomPos,
		size = roomSize,
		parent = parent,
		name = "ContainmentControl",
		wallThickness = WALL_THICKNESS,
		wallColor = Shared.Colors.ConcreteGrey,
		floorColor = Color3.fromRGB(80, 80, 85),
		doorways = {
			{ wall = "west", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT },
		},
	})

	-- Security door (open)
	Shared.createDoor(
		Vector3.new(roomPos.X - roomSize.X / 2, LAB_Y + DOOR_HEIGHT / 2, roomPos.Z),
		CFrame.Angles(0, math.rad(90), 0),
		room,
		"Door_ContainmentControl",
		false,
		nil
	)

	-- Curved desk (approximated with multiple parts)
	local deskCenter = Vector3.new(roomPos.X, LAB_Y, roomPos.Z - 1)
	Shared.makePart(room, "CurvedDesk_Center", deskCenter + Vector3.new(0, 3, 0), Vector3.new(8, 0.5, 3), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	Shared.makePart(room, "CurvedDesk_Left", deskCenter + Vector3.new(-4.5, 3, 1), Vector3.new(3, 0.5, 2), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	Shared.makePart(room, "CurvedDesk_Right", deskCenter + Vector3.new(4.5, 3, 1), Vector3.new(3, 0.5, 2), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)

	-- Monitor bank (12 monitors: 8 dead, 4 live)
	Shared.createMonitorBank(Vector3.new(roomPos.X, LAB_Y + 3.2, roomPos.Z - roomSize.Z / 2 + 1.5), 12, room)

	-- Rolling chair
	Shared.createFurniture("chair", Vector3.new(roomPos.X, LAB_Y, roomPos.Z + 1), room)

	-- Lockdown panel on wall
	local lockdownPos = Vector3.new(roomPos.X + roomSize.X / 2 - 1, LAB_Y + 5, roomPos.Z)
	Shared.makePart(room, "LockdownPanel", lockdownPos, Vector3.new(0.3, 2, 1.5), Shared.Colors.EmergencyRed, 0, Enum.Material.Metal)
	-- Panel buttons
	for i = 0, 2 do
		Shared.makePart(room, `LockdownBtn_{i}`, lockdownPos + Vector3.new(0.2, -0.5 + (i * 0.5), 0), Vector3.new(0.05, 0.3, 0.3), Color3.fromRGB(220, 220, 220), 0, Enum.Material.SmoothPlastic)
	end

	-- Server rack (back wall)
	Shared.createServerRack(Vector3.new(roomPos.X + 4, LAB_Y, roomPos.Z + 3), room, true)

	-- Terminal for security log
	Shared.createComputerTerminal(deskCenter + Vector3.new(0, 3.2, 0), room, true, "SecurityTerminal")

	-- Director's Keycard in desk drawer (key item)
	local keycardPos = deskCenter + Vector3.new(2, 3.3, 0)
	local keycard = Shared.makePart(room, "DirectorKeycard", keycardPos, Vector3.new(0.5, 0.05, 0.8), Color3.fromRGB(200, 200, 200), 0, Enum.Material.SmoothPlastic)
	keycard:SetAttribute("KeyItem", "DirectorKeycard")
	local keycardGlow = Instance.new("PointLight")
	keycardGlow.Brightness = 0.35
	keycardGlow.Range = 5
	keycardGlow.Color = Color3.fromRGB(255, 200, 80)
	keycardGlow.Parent = keycard

	-- CRT monitor glow provides primary lighting
	Shared.createLight(Vector3.new(roomPos.X, LAB_Y + ROOM_HEIGHT - 1, roomPos.Z), room, 0.15, Shared.Colors.CrtBlue)

	-- First aid box on wall
	Shared.makePart(room, "FirstAidBox", Vector3.new(roomPos.X - 5, LAB_Y + 5, roomPos.Z + roomSize.Z / 2 - 0.6), Vector3.new(1.2, 1, 0.3), Shared.Colors.EmergencyRed, 0, Enum.Material.SmoothPlastic)

	-- Hiding spots
	local underDeskPos = Vector3.new(deskCenter.X, LAB_Y + 0.5, deskCenter.Z)
	Shared.createHidingSpot(underDeskPos, "Desk", "contain_control_desk", room)
	table.insert(hidingSpots, {
		id = "contain_control_desk",
		position = underDeskPos,
		spotType = "Desk",
		isOccupied = false,
	})

	local behindRackPos = Vector3.new(roomPos.X + 4, LAB_Y + 1, roomPos.Z + 3)
	Shared.createHidingSpot(behindRackPos, "Desk", "contain_control_rack", room)
	table.insert(hidingSpots, {
		id = "contain_control_rack",
		position = behindRackPos,
		spotType = "Desk",
		isOccupied = false,
	})

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(roomPos.X, LAB_Y + 3, roomPos.Z),
		roomId = "ContainmentControl",
		dwellTime = 5,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = deskCenter + Vector3.new(-3, 3.4, 0),
		chance = 0.7,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = Vector3.new(roomPos.X - 5, LAB_Y + 5, roomPos.Z + roomSize.Z / 2 - 0.6),
		chance = 0.5,
		guaranteed = false,
	})

	room.Parent = parent
end

------------------------------------------------------------------------
-- Containment Corridor (connects Cell Blocks to Lab Corridor)
------------------------------------------------------------------------

local function buildContainmentCorridor(
	parent: Instance,
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } }
)
	local corridor = Instance.new("Model")
	corridor.Name = "ContainmentCorridor"

	-- Main corridor connecting Block A corridor to Block B corridor
	Shared.createCorridor(
		Vector3.new(-30, LAB_Y, -36),
		Vector3.new(-30, LAB_Y, -50),
		5,
		ROOM_HEIGHT,
		corridor,
		"ContainmentCorridor_NS"
	)

	-- East-west connector to containment control
	Shared.createCorridor(
		Vector3.new(-30, LAB_Y, -47),
		Vector3.new(5, LAB_Y, -47),
		5,
		ROOM_HEIGHT,
		corridor,
		"ContainmentCorridor_EW"
	)

	-- Connector to main lab corridor
	Shared.createCorridor(
		Vector3.new(-30, LAB_Y, -30),
		Vector3.new(-30, LAB_Y, -20),
		5,
		ROOM_HEIGHT,
		corridor,
		"ContainmentCorridor_ToLab"
	)

	-- Biohazard signs at entrance
	Shared.createBiohazardSign(Vector3.new(-30, LAB_Y + 7, -30), corridor, "z")

	-- Emergency strips
	Shared.createEmergencyStrip(Vector3.new(-30, LAB_Y + 0.1, -43), 14, "z", corridor)
	Shared.createEmergencyStrip(Vector3.new(-12, LAB_Y + 0.1, -47), 36, "x", corridor)

	-- Corridor lights
	Shared.createFluorescent(Vector3.new(-30, LAB_Y + ROOM_HEIGHT - 0.5, -35), corridor, true)
	Shared.createFluorescent(Vector3.new(-30, LAB_Y + ROOM_HEIGHT - 0.5, -43), corridor, false)
	Shared.createFluorescent(Vector3.new(-15, LAB_Y + ROOM_HEIGHT - 0.5, -47), corridor, true)

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(-30, LAB_Y + 3, -43),
		roomId = "ContainmentCorridor_Center",
		dwellTime = 3,
	})
	table.insert(waypoints, {
		position = Vector3.new(-15, LAB_Y + 3, -47),
		roomId = "ContainmentCorridor_EW",
		dwellTime = 2,
	})

	corridor.Parent = parent
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local ContainmentWing = {}

function ContainmentWing.build(parent: Instance): FloorData
	local floorModel = Instance.new("Model")
	floorModel.Name = "ContainmentWing"
	floorModel.Parent = parent

	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	buildCellBlockA(floorModel, hidingSpots, waypoints, lootPositions)
	buildCellBlockB(floorModel, hidingSpots, waypoints, lootPositions)
	buildContainmentControl(floorModel, hidingSpots, waypoints, lootPositions)
	buildContainmentCorridor(floorModel, waypoints)

	print(`[ContainmentWing] Built: {#hidingSpots} hiding spots, {#waypoints} waypoints, {#lootPositions} loot positions`)

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return ContainmentWing
