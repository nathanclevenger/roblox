--!strict

--[[
	ResearchStation/DeepLevel — Deep Level (B2) and Dock geometry

	Main Chamber (excavation cavern), Server Room (objective),
	The Tank (containment vessel), Emergency Tunnel (to dock),
	Boat House, and Pier (extraction point).

	Deep Level Y = -30. Dock Y = -25 (coastal, slightly higher).
	Main Chamber is a massive open cavern with ~20m ceiling.
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
local DEEP_Y = -30
local DOCK_Y = -25
local ROOM_HEIGHT = 12
local CHAMBER_HEIGHT = 20
local WALL_THICKNESS = 1
local DOOR_WIDTH = 5
local DOOR_HEIGHT = 8

------------------------------------------------------------------------
-- Freight Elevator / Ladder Shaft (Lab Level to Deep Level)
------------------------------------------------------------------------

local function buildFreightElevator(
	parent: Instance,
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } }
)
	local model = Instance.new("Model")
	model.Name = "FreightElevator_LabToDeep"

	local shaftPos = Vector3.new(17, 0, 7)

	-- Elevator shaft walls
	local shaftHeight = LAB_Y - DEEP_Y + ROOM_HEIGHT
	local shaftCenterY = (LAB_Y + DEEP_Y) / 2
	Shared.createWall(Vector3.new(shaftPos.X - 4, shaftCenterY, shaftPos.Z), Vector3.new(1, shaftHeight, 8), model, "FreightShaft_West")
	Shared.createWall(Vector3.new(shaftPos.X + 4, shaftCenterY, shaftPos.Z), Vector3.new(1, shaftHeight, 8), model, "FreightShaft_East")
	Shared.createWall(Vector3.new(shaftPos.X, shaftCenterY, shaftPos.Z - 4), Vector3.new(8, shaftHeight, 1), model, "FreightShaft_North")

	-- Elevator car (at deep level)
	Shared.makePart(model, "FreightCar_Floor", Vector3.new(shaftPos.X, DEEP_Y, shaftPos.Z), Vector3.new(7, 0.5, 7), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	-- Chain hoist mechanism
	Shared.makePart(model, "ChainHoist", Vector3.new(shaftPos.X, LAB_Y - 2, shaftPos.Z), Vector3.new(1, 2, 1), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)

	-- Ladder shaft (beside elevator)
	local ladderPos = Vector3.new(shaftPos.X + 6, 0, shaftPos.Z)
	-- Ladder enclosure
	Shared.createWall(Vector3.new(ladderPos.X - 1.5, shaftCenterY, ladderPos.Z), Vector3.new(1, shaftHeight, 3), model, "LadderShaft_West")
	Shared.createWall(Vector3.new(ladderPos.X + 1.5, shaftCenterY, ladderPos.Z), Vector3.new(1, shaftHeight, 3), model, "LadderShaft_East")
	-- Ladder rungs
	for i = 0, math.floor(shaftHeight / 1.5) - 1 do
		local rungY = DEEP_Y + 1 + (i * 1.5)
		Shared.makePart(model, `Rung_{i}`, Vector3.new(ladderPos.X, rungY, ladderPos.Z + 1.2), Vector3.new(0.8, 0.15, 0.15), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	end

	-- Emergency lights in shaft
	Shared.createEmergencyLight(Vector3.new(shaftPos.X, DEEP_Y + 5, shaftPos.Z), model, 0.15)
	Shared.createEmergencyLight(Vector3.new(shaftPos.X, LAB_Y - 3, shaftPos.Z), model, 0.15)

	-- Waypoint
	table.insert(waypoints, {
		position = Vector3.new(shaftPos.X, DEEP_Y + 3, shaftPos.Z),
		roomId = "FreightElevator_Deep",
		dwellTime = 2,
	})

	model.Parent = parent
end

------------------------------------------------------------------------
-- Main Chamber (massive excavation cavern)
------------------------------------------------------------------------

local function buildMainChamber(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local chamberPos = Vector3.new(0, DEEP_Y, 0)
	local chamberRadius = 50

	local chamber = Instance.new("Model")
	chamber.Name = "MainChamber"

	-- Floor (rough excavation surface)
	Shared.createFloor(
		chamberPos + Vector3.new(0, -0.5, 0),
		Vector3.new(chamberRadius * 2, 1, chamberRadius * 2),
		chamber,
		"ChamberFloor"
	)
	-- Re-style as rock
	local floorPart = chamber:FindFirstChild("ChamberFloor") :: Part?
	if floorPart then
		floorPart.Material = Enum.Material.Slate
		floorPart.Color = Shared.Colors.Rock
	end

	-- Ceiling (high above — natural rock)
	Shared.makePart(chamber, "ChamberCeiling", chamberPos + Vector3.new(0, CHAMBER_HEIGHT + 0.5, 0), Vector3.new(chamberRadius * 2, 1, chamberRadius * 2), Shared.Colors.Rock, 0, Enum.Material.Slate)

	-- Perimeter walls (rough hewn rock)
	Shared.createWall(Vector3.new(chamberPos.X, chamberPos.Y + CHAMBER_HEIGHT / 2, chamberPos.Z - chamberRadius), Vector3.new(chamberRadius * 2, CHAMBER_HEIGHT, 2), chamber, "ChamberWall_N")
	Shared.createWall(Vector3.new(chamberPos.X, chamberPos.Y + CHAMBER_HEIGHT / 2, chamberPos.Z + chamberRadius), Vector3.new(chamberRadius * 2, CHAMBER_HEIGHT, 2), chamber, "ChamberWall_S")
	Shared.createWall(Vector3.new(chamberPos.X - chamberRadius, chamberPos.Y + CHAMBER_HEIGHT / 2, chamberPos.Z), Vector3.new(2, CHAMBER_HEIGHT, chamberRadius * 2), chamber, "ChamberWall_W")
	Shared.createWall(Vector3.new(chamberPos.X + chamberRadius, chamberPos.Y + CHAMBER_HEIGHT / 2, chamberPos.Z), Vector3.new(2, CHAMBER_HEIGHT, chamberRadius * 2), chamber, "ChamberWall_E")

	-- Re-style walls as rock
	for _, wallName in { "ChamberWall_N", "ChamberWall_S", "ChamberWall_W", "ChamberWall_E" } do
		local wall = chamber:FindFirstChild(wallName) :: Part?
		if wall then
			wall.Material = Enum.Material.Slate
			wall.Color = Shared.Colors.Rock
		end
	end

	-- Central depression (dig site — 10m across, 3m deep)
	local depCenter = chamberPos
	-- Depression floor (luminescent)
	local depFloor = Shared.makePart(chamber, "DigSite_Floor", depCenter + Vector3.new(0, -3, 0), Vector3.new(10, 0.5, 10), Shared.Colors.LuminescentBlue, 0.1, Enum.Material.SmoothPlastic)
	local lumGlow = Instance.new("PointLight")
	lumGlow.Brightness = 0.15
	lumGlow.Color = Shared.Colors.LuminescentBlue
	lumGlow.Range = 12
	lumGlow.Shadows = false
	lumGlow.Parent = depFloor

	-- Depression walls (smooth, unnaturally so)
	for _, dWall in {
		{ pos = Vector3.new(0, -1.5, -5.2), size = Vector3.new(10, 3, 0.4) },
		{ pos = Vector3.new(0, -1.5, 5.2), size = Vector3.new(10, 3, 0.4) },
		{ pos = Vector3.new(-5.2, -1.5, 0), size = Vector3.new(0.4, 3, 10) },
		{ pos = Vector3.new(5.2, -1.5, 0), size = Vector3.new(0.4, 3, 10) },
	} do
		Shared.makePart(chamber, "DigSite_Wall", depCenter + dWall.pos, dWall.size, Color3.fromRGB(100, 105, 115), 0, Enum.Material.SmoothPlastic)
	end

	-- Scaffolding (multiple sections around the chamber)
	Shared.createScaffolding(chamberPos + Vector3.new(-25, 0, -15), 12, chamber, "Scaffolding_NW")
	Shared.createScaffolding(chamberPos + Vector3.new(20, 0, -20), 16, chamber, "Scaffolding_NE")
	Shared.createScaffolding(chamberPos + Vector3.new(-20, 0, 20), 10, chamber, "Scaffolding_SW")

	-- Walkways at various heights
	Shared.makePart(chamber, "Walkway_Upper", chamberPos + Vector3.new(-15, 8, 0), Vector3.new(20, 0.3, 4), Color3.fromRGB(100, 95, 85), 0, Enum.Material.Metal)
	Shared.makePart(chamber, "Walkway_Mid", chamberPos + Vector3.new(10, 5, 15), Vector3.new(4, 0.3, 15), Color3.fromRGB(100, 95, 85), 0, Enum.Material.Metal)
	-- Railing on walkways
	Shared.makePart(chamber, "Railing_Upper", chamberPos + Vector3.new(-15, 9.2, -2), Vector3.new(20, 0.15, 0.15), Shared.Colors.HazmatYellow, 0, Enum.Material.Metal)
	Shared.makePart(chamber, "Railing_Upper2", chamberPos + Vector3.new(-15, 9.2, 2), Vector3.new(20, 0.15, 0.15), Shared.Colors.HazmatYellow, 0, Enum.Material.Metal)

	-- Excavation equipment
	Shared.createDrillingRig(chamberPos + Vector3.new(15, 0, -10), chamber)
	Shared.createEarthMover(chamberPos + Vector3.new(-30, 0, 10), chamber)

	-- Floodlights surrounding the depression (most burned out)
	local floodlightPositions = {
		{ pos = Vector3.new(-8, 0, -8), on = false },
		{ pos = Vector3.new(8, 0, -8), on = true },
		{ pos = Vector3.new(-8, 0, 8), on = false },
		{ pos = Vector3.new(8, 0, 8), on = false },
		{ pos = Vector3.new(0, 0, -10), on = true },
		{ pos = Vector3.new(0, 0, 10), on = false },
	}
	for _, fl in floodlightPositions do
		Shared.createFloodlight(chamberPos + fl.pos, chamber, fl.on)
	end

	-- Equipment crates
	for i = 0, 3 do
		local cratePos = chamberPos + Vector3.new(-35 + (i * 8), 1, 25 + (i % 2) * 3)
		Shared.makePart(chamber, `Crate_{i}`, cratePos, Vector3.new(3, 2, 3), Color3.fromRGB(100, 90, 70), 0, Enum.Material.Wood)
	end

	-- Toolbox on workbench near excavation
	Shared.makePart(chamber, "Workbench", chamberPos + Vector3.new(20, 1.5, 5), Vector3.new(4, 3, 2), Color3.fromRGB(100, 90, 80), 0, Enum.Material.Wood)
	Shared.makePart(chamber, "Toolbox", chamberPos + Vector3.new(20, 3.2, 5), Vector3.new(1.5, 0.8, 1), Shared.Colors.EmergencyRed, 0, Enum.Material.Metal)

	-- Dripping water sounds (visual: small puddles)
	for i = 1, 5 do
		local pudX = chamberPos.X + (math.random() - 0.5) * 60
		local pudZ = chamberPos.Z + (math.random() - 0.5) * 60
		Shared.makePart(chamber, `Puddle_{i}`, Vector3.new(pudX, DEEP_Y + 0.02, pudZ), Vector3.new(1 + math.random(), 0.02, 1 + math.random()), Color3.fromRGB(60, 70, 80), 0.5, Enum.Material.SmoothPlastic)
	end

	-- Hiding spots
	Shared.createHidingSpot(chamberPos + Vector3.new(-25, 1, -15), "Desk", "deep_scaffolding_nw", chamber)
	table.insert(hidingSpots, {
		id = "deep_scaffolding_nw",
		position = chamberPos + Vector3.new(-25, 1, -15),
		spotType = "Desk",
		isOccupied = false,
	})

	Shared.createHidingSpot(chamberPos + Vector3.new(15, 1, -8), "Desk", "deep_drilling_rig", chamber)
	table.insert(hidingSpots, {
		id = "deep_drilling_rig",
		position = chamberPos + Vector3.new(15, 1, -8),
		spotType = "Desk",
		isOccupied = false,
	})

	Shared.createHidingSpot(chamberPos + Vector3.new(-30, 1, 10), "Desk", "deep_earth_mover", chamber)
	table.insert(hidingSpots, {
		id = "deep_earth_mover",
		position = chamberPos + Vector3.new(-30, 1, 10),
		spotType = "Desk",
		isOccupied = false,
	})

	Shared.createHidingSpot(chamberPos + Vector3.new(0, -2.5, 0), "Desk", "deep_dig_site", chamber)
	table.insert(hidingSpots, {
		id = "deep_dig_site",
		position = chamberPos + Vector3.new(0, -2.5, 0),
		spotType = "Desk",
		isOccupied = false,
	})

	-- Waypoints
	table.insert(waypoints, {
		position = chamberPos + Vector3.new(0, 3, 0),
		roomId = "MainChamber_Center",
		dwellTime = 4,
	})
	table.insert(waypoints, {
		position = chamberPos + Vector3.new(-25, 3, 0),
		roomId = "MainChamber_West",
		dwellTime = 3,
	})
	table.insert(waypoints, {
		position = chamberPos + Vector3.new(25, 3, 0),
		roomId = "MainChamber_East",
		dwellTime = 3,
	})
	table.insert(waypoints, {
		position = chamberPos + Vector3.new(0, 3, 25),
		roomId = "MainChamber_South",
		dwellTime = 3,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = chamberPos + Vector3.new(-25, 4.5, -15),
		chance = 0.7,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = chamberPos + Vector3.new(15, 1, -10),
		chance = 0.5,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Flare",
		position = chamberPos + Vector3.new(20, 3.5, 5),
		chance = 0.6,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Battery",
		position = chamberPos + Vector3.new(-15, 8.5, 0),
		chance = 0.4,
		guaranteed = false,
	})

	chamber.Parent = parent
end

------------------------------------------------------------------------
-- Server Room
------------------------------------------------------------------------

local function buildServerRoom(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local roomPos = Vector3.new(35, DEEP_Y, 0)
	local roomSize = Vector3.new(18, ROOM_HEIGHT, 16)

	local room = Shared.createRoom({
		position = roomPos,
		size = roomSize,
		parent = parent,
		name = "ServerRoom",
		wallThickness = WALL_THICKNESS,
		wallColor = Shared.Colors.ConcreteGrey,
		floorColor = Color3.fromRGB(70, 70, 75),
		doorways = {
			{ wall = "west", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT },
		},
	})

	Shared.createDoor(
		Vector3.new(roomPos.X - roomSize.X / 2, DEEP_Y + DOOR_HEIGHT / 2, roomPos.Z),
		CFrame.Angles(0, math.rad(90), 0),
		room,
		"Door_ServerRoom",
		false,
		nil
	)

	-- Raised floor (cable routing, with removable tiles)
	Shared.makePart(room, "RaisedFloor", Vector3.new(roomPos.X, DEEP_Y + 0.2, roomPos.Z), Vector3.new(roomSize.X - 2, 0.3, roomSize.Z - 2), Color3.fromRGB(80, 80, 85), 0, Enum.Material.Metal)
	-- Tile grid lines
	for i = 0, 5 do
		local tileZ = roomPos.Z - roomSize.Z / 2 + 2 + (i * 2.5)
		Shared.makePart(room, `TileLine_{i}`, Vector3.new(roomPos.X, DEEP_Y + 0.36, tileZ), Vector3.new(roomSize.X - 2, 0.02, 0.05), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	end

	-- Server racks (4 rows of 4)
	for row = 0, 3 do
		for col = 0, 3 do
			local rackX = roomPos.X - 6 + (col * 4)
			local rackZ = roomPos.Z - 5 + (row * 3.5)
			Shared.createServerRack(Vector3.new(rackX, DEEP_Y + 0.3, rackZ), room, true)
		end
	end

	-- Central terminal (main interaction point)
	local terminalPos = Vector3.new(roomPos.X, DEEP_Y, roomPos.Z - 4)
	Shared.createFurniture("desk", terminalPos, room)
	Shared.createComputerTerminal(terminalPos + Vector3.new(0, 3, 0), room, true, "UploadTerminal")

	-- ProximityPrompt for upload sequence
	local terminalPart = room:FindFirstChild("UploadTerminal")
	if terminalPart then
		local terminalModel = terminalPart :: Model
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Begin Upload"
		prompt.ObjectText = "Server Terminal"
		prompt.HoldDuration = 1
		prompt.MaxActivationDistance = 6
		prompt.Parent = terminalModel
	end

	-- UPS unit (corner, refrigerator-sized)
	Shared.makePart(room, "UPS", Vector3.new(roomPos.X + roomSize.X / 2 - 2, DEEP_Y + 2.5, roomPos.Z + roomSize.Z / 2 - 2), Vector3.new(3, 5, 2.5), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	-- UPS indicator light
	Shared.makePart(room, "UPS_LED", Vector3.new(roomPos.X + roomSize.X / 2 - 2, DEEP_Y + 4, roomPos.Z + roomSize.Z / 2 - 0.7), Vector3.new(0.2, 0.2, 0.05), Shared.Colors.ServerLedGreen, 0, Enum.Material.Neon)

	-- Cooling (represented by ambient lighting and visual detail)
	Shared.createLight(Vector3.new(roomPos.X, DEEP_Y + ROOM_HEIGHT - 1, roomPos.Z), room, 0.25, Shared.Colors.ServerLedGreen)
	Shared.createLight(Vector3.new(roomPos.X - 5, DEEP_Y + ROOM_HEIGHT - 1, roomPos.Z), room, 0.15)
	Shared.createLight(Vector3.new(roomPos.X + 5, DEEP_Y + ROOM_HEIGHT - 1, roomPos.Z), room, 0.15)

	-- Hiding spots (between server racks)
	Shared.createHidingSpot(Vector3.new(roomPos.X - 4, DEEP_Y + 1, roomPos.Z), "Desk", "deep_server_rack1", room)
	table.insert(hidingSpots, {
		id = "deep_server_rack1",
		position = Vector3.new(roomPos.X - 4, DEEP_Y + 1, roomPos.Z),
		spotType = "Desk",
		isOccupied = false,
	})

	Shared.createHidingSpot(Vector3.new(roomPos.X + 4, DEEP_Y + 1, roomPos.Z + 3), "Desk", "deep_server_rack2", room)
	table.insert(hidingSpots, {
		id = "deep_server_rack2",
		position = Vector3.new(roomPos.X + 4, DEEP_Y + 1, roomPos.Z + 3),
		spotType = "Desk",
		isOccupied = false,
	})

	-- Under raised floor hiding (unique)
	Shared.createHidingSpot(Vector3.new(roomPos.X, DEEP_Y - 0.2, roomPos.Z + 2), "Desk", "deep_server_underfloor", room)
	table.insert(hidingSpots, {
		id = "deep_server_underfloor",
		position = Vector3.new(roomPos.X, DEEP_Y - 0.2, roomPos.Z + 2),
		spotType = "Desk",
		isOccupied = false,
	})

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(roomPos.X, DEEP_Y + 3, roomPos.Z),
		roomId = "ServerRoom",
		dwellTime = 6,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(roomPos.X - 2, DEEP_Y + 5, roomPos.Z + 2),
		chance = 0.8,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(roomPos.X, DEEP_Y - 0.1, roomPos.Z - 3),
		chance = 0.5,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = Vector3.new(roomPos.X + roomSize.X / 2 - 2, DEEP_Y + 3, roomPos.Z + roomSize.Z / 2 - 2),
		chance = 0.4,
		guaranteed = false,
	})
end

------------------------------------------------------------------------
-- The Tank
------------------------------------------------------------------------

local function buildTheTank(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local tankPos = Vector3.new(-30, DEEP_Y, -25)
	local tankRadius = 4
	local tankHeight = 6

	local model = Instance.new("Model")
	model.Name = "TheTank"

	-- Tank chamber walls
	Shared.createRoom({
		position = tankPos,
		size = Vector3.new(14, ROOM_HEIGHT, 14),
		parent = model,
		name = "TankChamber",
		wallThickness = WALL_THICKNESS,
		wallColor = Shared.Colors.ConcreteGrey,
		floorColor = Shared.Colors.Rock,
		floorMaterial = Enum.Material.Slate,
		doorways = {
			{ wall = "south", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT },
		},
	})

	-- Tank vessel (cylindrical approximation — octagonal)
	-- Main body
	Shared.makePart(model, "TankBody", tankPos + Vector3.new(0, tankHeight / 2 + 0.5, 0), Vector3.new(tankRadius * 2, tankHeight, tankRadius * 2), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)

	-- Plexiglass observation windows (scratched from inside — opaque)
	for i, wOffset in {
		Vector3.new(0, tankHeight / 2 + 0.5, tankRadius + 0.1),
		Vector3.new(0, tankHeight / 2 + 0.5, -tankRadius - 0.1),
		Vector3.new(tankRadius + 0.1, tankHeight / 2 + 0.5, 0),
		Vector3.new(-tankRadius - 0.1, tankHeight / 2 + 0.5, 0),
	} do
		local windowSize: Vector3
		if i <= 2 then
			windowSize = Vector3.new(3, 3, 0.2)
		else
			windowSize = Vector3.new(0.2, 3, 3)
		end
		Shared.makePart(model, `TankWindow_{i}`, tankPos + wOffset, windowSize, Shared.Colors.ReinforcedGlass, 0.7, Enum.Material.Glass)
	end

	-- Vault-style hatch (open)
	local hatchPos = tankPos + Vector3.new(0, 2, tankRadius + 1)
	Shared.makePart(model, "TankHatch_Frame", hatchPos, Vector3.new(2.5, 4, 0.5), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	-- Open door
	local hatchDoor = Shared.makePart(model, "TankHatch_Door", hatchPos + Vector3.new(1.5, 0, 0.5), Vector3.new(2.2, 3.5, 0.4), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	hatchDoor.Orientation = Vector3.new(0, -60, 0)

	-- Interior: steel platform with restraint clamps
	Shared.makePart(model, "TankPlatform", tankPos + Vector3.new(0, 0.3, 0), Vector3.new(3, 0.5, 3), Shared.Colors.StainlessSteel, 0, Enum.Material.Metal)
	-- Hydraulic clamps (deployed, open position)
	for _, clampOffset in {
		Vector3.new(-1.2, 1, -1.2),
		Vector3.new(1.2, 1, -1.2),
		Vector3.new(-1.2, 1, 1.2),
		Vector3.new(1.2, 1, 1.2),
	} do
		Shared.makePart(model, "HydroClamp", tankPos + clampOffset, Vector3.new(0.6, 1.5, 0.6), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	end

	-- Scratch marks on interior walls (varying — fine to deep gouges)
	Shared.createScratchMarks(tankPos + Vector3.new(0, 3, -tankRadius + 0.3), 8, "z", model)
	Shared.createScratchMarks(tankPos + Vector3.new(0, 3, tankRadius - 0.3), 8, "z", model)
	Shared.createScratchMarks(tankPos + Vector3.new(-tankRadius + 0.3, 3, 0), 8, "x", model)
	Shared.createScratchMarks(tankPos + Vector3.new(tankRadius - 0.3, 3, 0), 8, "x", model)

	-- Face drawings near floor drain (progression of human faces)
	for i = 0, 5 do
		local angle = (i / 6) * math.pi * 2
		local faceX = tankPos.X + math.cos(angle) * (tankRadius - 0.5)
		local faceZ = tankPos.Z + math.sin(angle) * (tankRadius - 0.5)
		-- Each drawing is a small flat part pressed against the wall
		local faceSize = Vector3.new(0.6 + i * 0.1, 0.6 + i * 0.1, 0.05)
		Shared.makePart(model, `FaceDrawing_{i}`, Vector3.new(faceX, DEEP_Y + 1 + i * 0.3, faceZ), faceSize, Shared.Colors.ScratchMark, 0, Enum.Material.Concrete)
	end

	-- Drainage grate
	Shared.makePart(model, "DrainGrate", tankPos + Vector3.new(0, 0.05, 0), Vector3.new(1, 0.05, 1), Shared.Colors.DarkMetal, 0.2, Enum.Material.Metal)

	-- Monitoring station (outside tank)
	local monitorPos = tankPos + Vector3.new(0, 0, tankRadius + 3)
	Shared.createFurniture("desk", monitorPos, model)
	Shared.createComputerTerminal(monitorPos + Vector3.new(0, 3, 0), model, true, "TankMonitorTerminal")

	-- Clamp activation panel
	Shared.makePart(model, "ClampPanel", monitorPos + Vector3.new(3, 3.5, 0), Vector3.new(1, 1, 0.3), Shared.Colors.HazmatYellow, 0, Enum.Material.Metal)

	-- Fluid stain under Tank
	Shared.makePart(model, "TankFluidStain", tankPos + Vector3.new(2, 0.02, tankRadius + 1), Vector3.new(3, 0.03, 4), Color3.fromRGB(50, 60, 55), 0.3, Enum.Material.SmoothPlastic)

	-- Lighting (antiseptic overhead)
	Shared.createLight(tankPos + Vector3.new(0, ROOM_HEIGHT - 1, 0), model, 0.2)
	Shared.createLight(monitorPos + Vector3.new(0, ROOM_HEIGHT - 1, 0), model, 0.25)

	-- Hiding spots
	Shared.createHidingSpot(tankPos + Vector3.new(0, 0.5, 0), "Desk", "deep_tank_inside", model)
	table.insert(hidingSpots, {
		id = "deep_tank_inside",
		position = tankPos + Vector3.new(0, 0.5, 0),
		spotType = "Desk",
		isOccupied = false,
	})

	-- Waypoints
	table.insert(waypoints, {
		position = monitorPos + Vector3.new(0, 3, 0),
		roomId = "TheTank_Monitor",
		dwellTime = 5,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Flare",
		position = tankPos + Vector3.new(0, 1, tankRadius + 0.5),
		chance = 0.5,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Battery",
		position = monitorPos + Vector3.new(0, 3.4, 0),
		chance = 0.6,
		guaranteed = false,
	})

	model.Parent = parent
end

------------------------------------------------------------------------
-- Emergency Tunnel (Main Chamber to Dock)
------------------------------------------------------------------------

local function buildEmergencyTunnel(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local model = Instance.new("Model")
	model.Name = "EmergencyTunnel"

	local tunnelStartZ = 50
	local tunnelEndZ = 250
	local tunnelY = DEEP_Y
	local tunnelWidth = 3
	local tunnelHeight = 8

	-- Main tunnel corridor
	Shared.createCorridor(
		Vector3.new(0, tunnelY, tunnelStartZ),
		Vector3.new(0, DOCK_Y, tunnelEndZ),
		tunnelWidth * 2,
		tunnelHeight,
		model,
		"EmergencyTunnel_Main"
	)

	-- Ceiling pipes
	for i = 0, 9 do
		local pipeZ = tunnelStartZ + (i * 20)
		Shared.createPipe(
			Vector3.new(0, tunnelY + tunnelHeight - 1, pipeZ),
			tunnelWidth * 2 + 2,
			0.2,
			Vector3.new(0, 0, 0),
			model,
			`CeilingPipe_{i}`
		)
	end

	-- Emergency lighting strips (every 10 meters)
	for i = 0, 19 do
		local stripZ = tunnelStartZ + (i * 10)
		local stripY = tunnelY + 0.1 + (i * (DOCK_Y - tunnelY) / 20) -- gradual slope
		Shared.createEmergencyStrip(Vector3.new(-tunnelWidth, stripY, stripZ), 3, "z", model)
		Shared.createEmergencyStrip(Vector3.new(tunnelWidth, stripY, stripZ), 3, "z", model)
	end

	-- Three emergency alcoves
	local alcovePositions = {
		tunnelStartZ + 50,
		tunnelStartZ + 100,
		tunnelStartZ + 150,
	}
	for i, alcoveZ in alcovePositions do
		local alcoveY = tunnelY + ((alcoveZ - tunnelStartZ) / (tunnelEndZ - tunnelStartZ)) * (DOCK_Y - tunnelY)

		-- Alcove recess (wider section)
		local alcove = Instance.new("Model")
		alcove.Name = `Alcove_{i}`

		Shared.makePart(alcove, "AlcoveFloor", Vector3.new(-tunnelWidth - 2, alcoveY, alcoveZ), Vector3.new(4, 0.5, 4), Shared.Colors.ConcreteGrey, 0, Enum.Material.Concrete)
		Shared.makePart(alcove, "AlcoveBack", Vector3.new(-tunnelWidth - 3.5, alcoveY + tunnelHeight / 2, alcoveZ), Vector3.new(0.5, tunnelHeight, 4), Shared.Colors.ConcreteGrey, 0, Enum.Material.Concrete)

		-- Fire extinguisher
		Shared.makePart(alcove, "FireExtinguisher", Vector3.new(-tunnelWidth - 3, alcoveY + 2.5, alcoveZ), Vector3.new(0.4, 1.5, 0.4), Shared.Colors.EmergencyRed, 0, Enum.Material.Metal)

		-- Emergency phone
		Shared.makePart(alcove, "EmergencyPhone", Vector3.new(-tunnelWidth - 3, alcoveY + 4.5, alcoveZ + 1), Vector3.new(0.3, 0.8, 0.3), Shared.Colors.HazmatYellow, 0, Enum.Material.Metal)

		-- Emergency light
		Shared.createEmergencyLight(Vector3.new(-tunnelWidth - 1, alcoveY + tunnelHeight - 1, alcoveZ), alcove, 0.2)

		-- Hiding spot
		Shared.createHidingSpot(Vector3.new(-tunnelWidth - 2, alcoveY + 1, alcoveZ), "Desk", `deep_tunnel_alcove_{i}`, alcove)
		table.insert(hidingSpots, {
			id = `deep_tunnel_alcove_{i}`,
			position = Vector3.new(-tunnelWidth - 2, alcoveY + 1, alcoveZ),
			spotType = "Desk",
			isOccupied = false,
		})

		alcove.Parent = model
	end

	-- Blast door at midpoint
	local blastDoorZ = tunnelStartZ + 100
	local blastDoorY = tunnelY + ((blastDoorZ - tunnelStartZ) / (tunnelEndZ - tunnelStartZ)) * (DOCK_Y - tunnelY)
	Shared.makePart(model, "BlastDoor_Frame", Vector3.new(0, blastDoorY + tunnelHeight / 2, blastDoorZ), Vector3.new(tunnelWidth * 2 + 2, tunnelHeight, 1), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	-- Door panels (open position)
	Shared.makePart(model, "BlastDoor_L", Vector3.new(-tunnelWidth - 0.5, blastDoorY + tunnelHeight / 2, blastDoorZ), Vector3.new(0.5, tunnelHeight - 1, 0.8), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	Shared.makePart(model, "BlastDoor_R", Vector3.new(tunnelWidth + 0.5, blastDoorY + tunnelHeight / 2, blastDoorZ), Vector3.new(0.5, tunnelHeight - 1, 0.8), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)

	-- Control panels for blast door
	Shared.makePart(model, "BlastCtrl_Near", Vector3.new(tunnelWidth + 0.5, blastDoorY + 4, blastDoorZ - 2), Vector3.new(0.3, 1, 0.8), Shared.Colors.HazmatYellow, 0, Enum.Material.Metal)
	Shared.makePart(model, "BlastCtrl_Far", Vector3.new(tunnelWidth + 0.5, blastDoorY + 4, blastDoorZ + 2), Vector3.new(0.3, 1, 0.8), Shared.Colors.HazmatYellow, 0, Enum.Material.Metal)

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(0, tunnelY + 3, tunnelStartZ + 25),
		roomId = "EmergencyTunnel_Start",
		dwellTime = 2,
	})
	table.insert(waypoints, {
		position = Vector3.new(0, blastDoorY + 3, blastDoorZ),
		roomId = "EmergencyTunnel_BlastDoor",
		dwellTime = 3,
	})
	table.insert(waypoints, {
		position = Vector3.new(0, DOCK_Y + 3, tunnelEndZ - 25),
		roomId = "EmergencyTunnel_End",
		dwellTime = 2,
	})

	-- Loot (in alcoves)
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(-tunnelWidth - 2, tunnelY + 2, alcovePositions[1]),
		chance = 0.5,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = Vector3.new(-tunnelWidth - 2, tunnelY + 2, alcovePositions[2]),
		chance = 0.5,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Flare",
		position = Vector3.new(-tunnelWidth - 2, tunnelY + 2, alcovePositions[3]),
		chance = 0.4,
		guaranteed = false,
	})

	model.Parent = parent
end

------------------------------------------------------------------------
-- Boat House & Pier (Extraction)
------------------------------------------------------------------------

local function buildDock(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local model = Instance.new("Model")
	model.Name = "Dock"

	local boatHousePos = Vector3.new(0, DOCK_Y, 260)

	-- Boat house (corrugated metal structure)
	local bhSize = Vector3.new(14, 10, 20)
	Shared.createRoom({
		position = boatHousePos,
		size = bhSize,
		parent = model,
		name = "BoatHouse",
		wallThickness = WALL_THICKNESS,
		wallColor = Shared.Colors.CorrugatedMetal,
		wallMaterial = Enum.Material.Metal,
		floorColor = Shared.Colors.ConcreteGrey,
		doorways = {
			{ wall = "north", offset = 0, width = 6, height = 8 }, -- from tunnel
			{ wall = "south", offset = 0, width = 10, height = 8 }, -- open to water
		},
	})

	-- Work light (single, harsh yellow)
	local workLightPos = Vector3.new(boatHousePos.X + 5, DOCK_Y + 8, boatHousePos.Z - 3)
	Shared.makePart(model, "WorkLight_Cage", workLightPos, Vector3.new(0.6, 0.6, 0.6), Shared.Colors.DarkMetal, 0.3, Enum.Material.Metal)
	local workLight = Instance.new("PointLight")
	workLight.Brightness = 1.5
	workLight.Color = Color3.fromRGB(255, 220, 120)
	workLight.Range = 25
	workLight.Shadows = true
	workLight.Parent = Shared.makePart(model, "WorkLight_Bulb", workLightPos, Vector3.new(0.3, 0.3, 0.3), Color3.fromRGB(255, 240, 180), 0.3, Enum.Material.Neon)

	-- Marine railway
	Shared.createMarineRailway(Vector3.new(boatHousePos.X, DOCK_Y, boatHousePos.Z + 5), 15, model)

	-- Boat on cradle
	Shared.createBoat(Vector3.new(boatHousePos.X, DOCK_Y + 1, boatHousePos.Z + 3), model)

	-- Fuel tank on wall
	Shared.createFuelTank(Vector3.new(boatHousePos.X - bhSize.X / 2 + 2, DOCK_Y, boatHousePos.Z - 3), model)

	-- Railway control panel
	Shared.makePart(model, "RailwayControl", Vector3.new(boatHousePos.X + bhSize.X / 2 - 1.5, DOCK_Y + 3.5, boatHousePos.Z + 2), Vector3.new(1.5, 2, 0.5), Shared.Colors.HazmatYellow, 0, Enum.Material.Metal)

	-- Workbench
	local workbenchPos = Vector3.new(boatHousePos.X + 4, DOCK_Y, boatHousePos.Z - 6)
	Shared.makePart(model, "Workbench", workbenchPos + Vector3.new(0, 1.5, 0), Vector3.new(4, 3, 2), Color3.fromRGB(100, 90, 80), 0, Enum.Material.Wood)

	-- Marine radio
	Shared.makePart(model, "MarineRadio", workbenchPos + Vector3.new(-1, 3.2, 0), Vector3.new(1, 0.8, 0.8), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)

	-- Dock manifest clipboard
	Shared.makePart(model, "DockManifest", workbenchPos + Vector3.new(1, 3.2, 0), Vector3.new(0.8, 0.05, 1), Color3.fromRGB(160, 140, 100), 0, Enum.Material.Wood)

	-- Pier (concrete, extending into water)
	local pierStartZ = boatHousePos.Z + bhSize.Z / 2
	local pierEndZ = pierStartZ + 20
	Shared.makePart(model, "Pier", Vector3.new(boatHousePos.X, DOCK_Y - 0.5, (pierStartZ + pierEndZ) / 2), Vector3.new(8, 1, pierEndZ - pierStartZ), Shared.Colors.ConcreteGrey, 0, Enum.Material.Concrete)

	-- Navigation buoy
	Shared.makePart(model, "NavBuoy", Vector3.new(boatHousePos.X, DOCK_Y + 1, pierEndZ), Vector3.new(0.6, 2, 0.6), Shared.Colors.EmergencyRed, 0, Enum.Material.Metal)
	local buoyLight = Instance.new("PointLight")
	buoyLight.Brightness = 0.5
	buoyLight.Color = Color3.fromRGB(255, 50, 30)
	buoyLight.Range = 15
	buoyLight.Shadows = false
	buoyLight.Parent = model:FindFirstChild("NavBuoy")

	-- Water surface (beyond pier)
	Shared.makePart(model, "WaterSurface", Vector3.new(boatHousePos.X, DOCK_Y - 2, pierEndZ + 30), Vector3.new(60, 0.5, 80), Shared.Colors.OceanDark, 0.3, Enum.Material.SmoothPlastic)

	-- Fog wall over water
	Shared.makePart(model, "FogWall_Water", Vector3.new(boatHousePos.X, DOCK_Y + 8, pierEndZ + 50), Vector3.new(80, 25, 5), Color3.fromRGB(180, 185, 180), 0.7, Enum.Material.SmoothPlastic)

	-- Hiding spots
	Shared.createHidingSpot(workbenchPos + Vector3.new(0, 0.5, 0), "Desk", "dock_workbench", model)
	table.insert(hidingSpots, {
		id = "dock_workbench",
		position = workbenchPos + Vector3.new(0, 0.5, 0),
		spotType = "Desk",
		isOccupied = false,
	})

	Shared.createHidingSpot(Vector3.new(boatHousePos.X, DOCK_Y + 1.5, boatHousePos.Z + 3), "Desk", "dock_inside_boat", model)
	table.insert(hidingSpots, {
		id = "dock_inside_boat",
		position = Vector3.new(boatHousePos.X, DOCK_Y + 1.5, boatHousePos.Z + 3),
		spotType = "Desk",
		isOccupied = false,
	})

	Shared.createHidingSpot(Vector3.new(boatHousePos.X - bhSize.X / 2 + 2, DOCK_Y + 1, boatHousePos.Z - 3), "Desk", "dock_behind_fuel", model)
	table.insert(hidingSpots, {
		id = "dock_behind_fuel",
		position = Vector3.new(boatHousePos.X - bhSize.X / 2 + 2, DOCK_Y + 1, boatHousePos.Z - 3),
		spotType = "Desk",
		isOccupied = false,
	})

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(boatHousePos.X, DOCK_Y + 3, boatHousePos.Z),
		roomId = "BoatHouse",
		dwellTime = 4,
	})
	table.insert(waypoints, {
		position = Vector3.new(boatHousePos.X, DOCK_Y + 3, (pierStartZ + pierEndZ) / 2),
		roomId = "Pier",
		dwellTime = 3,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = workbenchPos + Vector3.new(0, 3.4, 0),
		chance = 0.7,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = Vector3.new(boatHousePos.X, DOCK_Y + 2.5, boatHousePos.Z + 1),
		chance = 0.6,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Flare",
		position = Vector3.new(boatHousePos.X, DOCK_Y + 2.5, boatHousePos.Z + 5),
		chance = 0.5,
		guaranteed = false,
	})

	model.Parent = parent
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local DeepLevel = {}

function DeepLevel.build(parent: Instance): FloorData
	local floorModel = Instance.new("Model")
	floorModel.Name = "DeepLevel"
	floorModel.Parent = parent

	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	buildFreightElevator(floorModel, waypoints)
	buildMainChamber(floorModel, hidingSpots, waypoints, lootPositions)
	buildServerRoom(floorModel, hidingSpots, waypoints, lootPositions)
	buildTheTank(floorModel, hidingSpots, waypoints, lootPositions)
	buildEmergencyTunnel(floorModel, hidingSpots, waypoints, lootPositions)
	buildDock(floorModel, hidingSpots, waypoints, lootPositions)

	print(`[DeepLevel] Built: {#hidingSpots} hiding spots, {#waypoints} waypoints, {#lootPositions} loot positions`)

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return DeepLevel
