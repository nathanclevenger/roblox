--!strict

--[[
	ResearchStation/Exterior — Surface-level exterior geometry

	Helipad (spawn), perimeter fence, guard towers, service yard,
	and outdoor connecting paths.

	Surface Y = 0. All exterior geometry sits at ground level.
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
local ROOM_HEIGHT = 12
local WALL_THICKNESS = 1

------------------------------------------------------------------------
-- Helipad (Spawn Point)
------------------------------------------------------------------------

local function buildHelipad(
	parent: Instance,
	_hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local model = Instance.new("Model")
	model.Name = "Helipad"

	-- Landing pad (concrete slab)
	Shared.createFloor(
		Vector3.new(-60, SURFACE_Y - 0.5, -60),
		Vector3.new(24, 1, 24),
		model,
		"HelipadSlab"
	)

	-- Helipad markings (H)
	Shared.makePart(model, "HeliMark_H_Left", Vector3.new(-62, SURFACE_Y + 0.05, -60), Vector3.new(1, 0.05, 10), Shared.Colors.HazmatYellow, 0, Enum.Material.SmoothPlastic)
	Shared.makePart(model, "HeliMark_H_Right", Vector3.new(-58, SURFACE_Y + 0.05, -60), Vector3.new(1, 0.05, 10), Shared.Colors.HazmatYellow, 0, Enum.Material.SmoothPlastic)
	Shared.makePart(model, "HeliMark_H_Cross", Vector3.new(-60, SURFACE_Y + 0.05, -60), Vector3.new(5, 0.05, 1), Shared.Colors.HazmatYellow, 0, Enum.Material.SmoothPlastic)

	-- Helipad circle marking
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		local cx = -60 + math.cos(angle) * 10
		local cz = -60 + math.sin(angle) * 10
		Shared.makePart(model, `HeliCircle_{i}`, Vector3.new(cx, SURFACE_Y + 0.05, cz), Vector3.new(3, 0.05, 0.5), Shared.Colors.HazmatYellow, 0, Enum.Material.SmoothPlastic)
	end

	-- Helicopter wreck
	Shared.createHelicopterWreck(Vector3.new(-60, SURFACE_Y, -55), model)

	-- Pilot's bag (ground near wreck)
	Shared.makePart(model, "PilotBag", Vector3.new(-55, SURFACE_Y + 0.4, -52), Vector3.new(1.5, 0.8, 1), Color3.fromRGB(50, 55, 45), 0, Enum.Material.Fabric)

	-- Clipboard near wreck
	Shared.makePart(model, "FlightLogClipboard", Vector3.new(-57, SURFACE_Y + 0.3, -50), Vector3.new(0.8, 0.05, 1.2), Color3.fromRGB(160, 140, 100), 0, Enum.Material.Wood)

	-- Path from helipad to admin building (concrete walkway)
	Shared.createFloor(
		Vector3.new(-40, SURFACE_Y - 0.5, -60),
		Vector3.new(30, 1, 4),
		model,
		"Walkway_HeliToAdmin"
	)

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(-60, SURFACE_Y + 3, -60),
		roomId = "Helipad",
		dwellTime = 3,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(-58, SURFACE_Y + 1, -53),
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = Vector3.new(-58, SURFACE_Y + 1, -54),
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Flare",
		position = Vector3.new(-55, SURFACE_Y + 0.8, -52),
		chance = 0.6,
		guaranteed = false,
	})

	model.Parent = parent
end

------------------------------------------------------------------------
-- Perimeter Fence & Guard Towers
------------------------------------------------------------------------

local function buildPerimeter(
	parent: Instance,
	_hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local model = Instance.new("Model")
	model.Name = "Perimeter"

	-- Fence around the entire station (rough rectangle)
	-- North fence
	Shared.createFenceSection(Vector3.new(0, SURFACE_Y, -90), 160, "x", model)
	-- South fence
	Shared.createFenceSection(Vector3.new(0, SURFACE_Y, 30), 160, "x", model)
	-- West fence
	Shared.createFenceSection(Vector3.new(-80, SURFACE_Y, -30), 120, "z", model)
	-- East fence
	Shared.createFenceSection(Vector3.new(80, SURFACE_Y, -30), 120, "z", model)

	-- Guard Tower 1 (NW corner)
	local tower1Pos = Vector3.new(-75, SURFACE_Y, -85)
	local tower1 = Instance.new("Model")
	tower1.Name = "GuardTower_1"

	-- Tower base (supports)
	for _, offset in {
		Vector3.new(-2, 4, -2),
		Vector3.new(2, 4, -2),
		Vector3.new(-2, 4, 2),
		Vector3.new(2, 4, 2),
	} do
		Shared.makePart(tower1, "Support", tower1Pos + offset, Vector3.new(0.4, 8, 0.4), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	end

	-- Platform
	Shared.makePart(tower1, "Platform", tower1Pos + Vector3.new(0, 8, 0), Vector3.new(6, 0.3, 6), Color3.fromRGB(100, 90, 80), 0, Enum.Material.Wood)

	-- Railing
	for _, rOffset in {
		{ pos = Vector3.new(0, 9.2, -3), size = Vector3.new(6, 0.15, 0.15) },
		{ pos = Vector3.new(0, 9.2, 3), size = Vector3.new(6, 0.15, 0.15) },
		{ pos = Vector3.new(-3, 9.2, 0), size = Vector3.new(0.15, 0.15, 6) },
		{ pos = Vector3.new(3, 9.2, 0), size = Vector3.new(0.15, 0.15, 6) },
	} do
		Shared.makePart(tower1, "Railing", tower1Pos + rOffset.pos, rOffset.size, Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	end

	-- Chair on platform
	Shared.createFurniture("chair", tower1Pos + Vector3.new(0, 8.3, 0), tower1)

	tower1.Parent = model

	-- Guard Tower 2 (NE corner)
	local tower2Pos = Vector3.new(75, SURFACE_Y, -85)
	local tower2 = Instance.new("Model")
	tower2.Name = "GuardTower_2"

	for _, offset in {
		Vector3.new(-2, 4, -2),
		Vector3.new(2, 4, -2),
		Vector3.new(-2, 4, 2),
		Vector3.new(2, 4, 2),
	} do
		Shared.makePart(tower2, "Support", tower2Pos + offset, Vector3.new(0.4, 8, 0.4), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	end
	Shared.makePart(tower2, "Platform", tower2Pos + Vector3.new(0, 8, 0), Vector3.new(6, 0.3, 6), Color3.fromRGB(100, 90, 80), 0, Enum.Material.Wood)
	Shared.createFurniture("desk", tower2Pos + Vector3.new(0, 8.3, 0), tower2)

	tower2.Parent = model

	-- Fog wall (thick transparent boundary beyond fence)
	Shared.makePart(model, "FogWall_N", Vector3.new(0, SURFACE_Y + 10, -100), Vector3.new(200, 30, 5), Color3.fromRGB(180, 185, 180), 0.7, Enum.Material.SmoothPlastic)
	Shared.makePart(model, "FogWall_S", Vector3.new(0, SURFACE_Y + 10, 40), Vector3.new(200, 30, 5), Color3.fromRGB(180, 185, 180), 0.7, Enum.Material.SmoothPlastic)
	Shared.makePart(model, "FogWall_W", Vector3.new(-90, SURFACE_Y + 10, -30), Vector3.new(5, 30, 140), Color3.fromRGB(180, 185, 180), 0.7, Enum.Material.SmoothPlastic)
	Shared.makePart(model, "FogWall_E", Vector3.new(90, SURFACE_Y + 10, -30), Vector3.new(5, 30, 140), Color3.fromRGB(180, 185, 180), 0.7, Enum.Material.SmoothPlastic)

	-- Ground terrain (large ground plane)
	Shared.createFloor(
		Vector3.new(0, SURFACE_Y - 1, -30),
		Vector3.new(180, 1, 140),
		model,
		"Terrain"
	)

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(-75, SURFACE_Y + 3, -85),
		roomId = "GuardTower_1",
		dwellTime = 3,
	})
	table.insert(waypoints, {
		position = Vector3.new(75, SURFACE_Y + 3, -85),
		roomId = "GuardTower_2",
		dwellTime = 3,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(-75, SURFACE_Y + 8.5, -85),
		chance = 0.3,
		guaranteed = false,
	})

	model.Parent = parent
end

------------------------------------------------------------------------
-- Service Yard (transition to Lab Level elevator/stairwell)
------------------------------------------------------------------------

local function buildServiceYard(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local model = Instance.new("Model")
	model.Name = "ServiceYard"

	local yardPos = Vector3.new(0, SURFACE_Y, -20)

	-- Concrete pad
	Shared.createFloor(
		Vector3.new(yardPos.X, yardPos.Y - 0.5, yardPos.Z),
		Vector3.new(30, 1, 20),
		model,
		"YardSlab"
	)

	-- Cargo container
	local containerPos = Vector3.new(yardPos.X - 10, SURFACE_Y, yardPos.Z + 2)
	Shared.makePart(model, "CargoContainer", containerPos + Vector3.new(0, 2.5, 0), Vector3.new(6, 5, 12), Shared.Colors.Rust, 0, Enum.Material.Metal)
	-- Container doors (back end)
	Shared.makePart(model, "ContainerDoor_L", containerPos + Vector3.new(-1.8, 2.5, 6.1), Vector3.new(2, 4.5, 0.15), Shared.Colors.Rust, 0, Enum.Material.Metal)
	Shared.makePart(model, "ContainerDoor_R", containerPos + Vector3.new(1.8, 2.5, 6.1), Vector3.new(2, 4.5, 0.15), Shared.Colors.Rust, 0, Enum.Material.Metal)

	-- Drainage channels
	for i = 0, 2 do
		local drainZ = yardPos.Z - 8 + (i * 8)
		Shared.makePart(model, `Drain_{i}`, Vector3.new(yardPos.X, yardPos.Y - 0.4, drainZ), Vector3.new(28, 0.2, 0.6), Shared.Colors.DarkMetal, 0.1, Enum.Material.Metal)
	end

	-- Floodlight pole (strobing — represented as single floodlight)
	Shared.createFloodlight(Vector3.new(yardPos.X + 8, SURFACE_Y, yardPos.Z), model, true)

	-- Loading dock (raised platform with metal shutter)
	local dockPos = Vector3.new(yardPos.X + 12, SURFACE_Y, yardPos.Z - 5)
	Shared.makePart(model, "LoadingDock_Platform", dockPos + Vector3.new(0, 1, 0), Vector3.new(8, 2, 6), Shared.Colors.ConcreteGrey, 0, Enum.Material.Concrete)
	-- Metal shutter (closed)
	Shared.makePart(model, "Shutter", dockPos + Vector3.new(0, 4, -3.1), Vector3.new(6, 5, 0.2), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)

	-- Shelf on loading dock
	Shared.createFurniture("shelf", dockPos + Vector3.new(2, 2, 0), model)

	-- Elevator housing (surface structure)
	local elevatorPos = Vector3.new(yardPos.X, SURFACE_Y, yardPos.Z - 8)
	Shared.makePart(model, "ElevatorHousing", elevatorPos + Vector3.new(0, 3, 0), Vector3.new(6, 6, 6), Shared.Colors.ConcreteGrey, 0, Enum.Material.Concrete)
	-- Elevator doors (industrial freight-style)
	Shared.makePart(model, "ElevDoor_L", elevatorPos + Vector3.new(-1.5, 3, 3.1), Vector3.new(2.5, 5, 0.2), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	Shared.makePart(model, "ElevDoor_R", elevatorPos + Vector3.new(1.5, 3, 3.1), Vector3.new(2.5, 5, 0.2), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)

	-- Stairwell fire door (beside elevator)
	local stairDoorPos = Vector3.new(elevatorPos.X + 5, SURFACE_Y, elevatorPos.Z)
	Shared.createDoor(
		stairDoorPos + Vector3.new(0, 4, 0),
		nil,
		model,
		"StairwellDoor_Surface",
		false,
		nil
	)

	-- Emergency light
	Shared.createEmergencyLight(Vector3.new(yardPos.X, SURFACE_Y + 5, yardPos.Z), model, 0.3)

	-- Hiding spots
	Shared.createHidingSpot(containerPos + Vector3.new(3, SURFACE_Y + 1, 0), "Desk", "ext_behind_container", model)
	table.insert(hidingSpots, {
		id = "ext_behind_container",
		position = containerPos + Vector3.new(3, SURFACE_Y + 1, 0),
		spotType = "Desk",
		isOccupied = false,
	})

	Shared.createHidingSpot(dockPos + Vector3.new(0, SURFACE_Y + 0.5, 2), "Desk", "ext_under_dock", model)
	table.insert(hidingSpots, {
		id = "ext_under_dock",
		position = dockPos + Vector3.new(0, SURFACE_Y + 0.5, 2),
		spotType = "Desk",
		isOccupied = false,
	})

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(yardPos.X, SURFACE_Y + 3, yardPos.Z),
		roomId = "ServiceYard",
		dwellTime = 3,
	})
	table.insert(waypoints, {
		position = Vector3.new(elevatorPos.X, SURFACE_Y + 3, elevatorPos.Z),
		roomId = "ServiceYard_Elevator",
		dwellTime = 2,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = containerPos + Vector3.new(0, 1, 0),
		chance = 0.8,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = containerPos + Vector3.new(0, 1, 2),
		chance = 0.6,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Flare",
		position = containerPos + Vector3.new(0, 1, -2),
		chance = 0.4,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Battery",
		position = dockPos + Vector3.new(2, 3, 0),
		chance = 0.5,
		guaranteed = false,
	})

	model.Parent = parent
end

------------------------------------------------------------------------
-- Barracks
------------------------------------------------------------------------

local function buildBarracks(
	parent: Instance,
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local barracksPos = Vector3.new(-35, SURFACE_Y, -35)
	local barracksSize = Vector3.new(20, ROOM_HEIGHT, 30)

	local room = Shared.createRoom({
		position = barracksPos,
		size = barracksSize,
		parent = parent,
		name = "Barracks",
		wallThickness = WALL_THICKNESS,
		wallColor = Color3.fromRGB(170, 170, 165),
		floorColor = Shared.Colors.ConcreteGrey,
		doorways = {
			{ wall = "east", offset = 0, width = 5, height = 8 },
		},
	})

	-- Door
	Shared.createDoor(
		Vector3.new(barracksPos.X + barracksSize.X / 2, SURFACE_Y + 4, barracksPos.Z),
		CFrame.Angles(0, math.rad(90), 0),
		room,
		"Door_Barracks",
		false,
		nil
	)

	-- Bunk beds (2 rows of 6)
	for row = 0, 1 do
		for col = 0, 5 do
			local bunkX = barracksPos.X - 6 + (row * 12)
			local bunkZ = barracksPos.Z - 12 + (col * 4.5)
			Shared.createBunkBed(Vector3.new(bunkX, SURFACE_Y, bunkZ), room)
		end
	end

	-- Lockers along west wall
	for i = 0, 11 do
		local lockerZ = barracksPos.Z - 13 + (i * 2.2)
		Shared.createFurniture("locker", Vector3.new(barracksPos.X - barracksSize.X / 2 + 1.5, SURFACE_Y, lockerZ), room)
	end

	-- Footlocker with card game
	local footlockerPos = Vector3.new(barracksPos.X + 3, SURFACE_Y + 0.3, barracksPos.Z - 5)
	Shared.makePart(room, "Footlocker", footlockerPos, Vector3.new(2, 0.6, 1.2), Color3.fromRGB(80, 90, 80), 0, Enum.Material.Metal)
	-- Cards scattered
	Shared.makePart(room, "Cards", footlockerPos + Vector3.new(0, 0.4, 0), Vector3.new(0.8, 0.02, 0.5), Color3.fromRGB(230, 230, 220), 0, Enum.Material.SmoothPlastic)

	-- Barricaded bathroom (far end)
	local bathroomPos = Vector3.new(barracksPos.X, SURFACE_Y, barracksPos.Z + barracksSize.Z / 2 - 4)
	-- Bathroom partition wall
	Shared.makePart(room, "BathroomWall", Vector3.new(bathroomPos.X, SURFACE_Y + ROOM_HEIGHT / 2, bathroomPos.Z - 2), Vector3.new(barracksSize.X - 2, ROOM_HEIGHT, WALL_THICKNESS), Color3.fromRGB(170, 170, 165), 0, Enum.Material.Concrete)

	-- Barricade (dismantled bunk parts)
	Shared.makePart(room, "Barricade_1", Vector3.new(bathroomPos.X - 2, SURFACE_Y + 1.5, bathroomPos.Z - 2.5), Vector3.new(3.5, 3, 0.5), Shared.Colors.DarkMetal, 0, Enum.Material.Metal)
	Shared.makePart(room, "Barricade_2", Vector3.new(bathroomPos.X + 2, SURFACE_Y + 2, bathroomPos.Z - 2.5), Vector3.new(4, 4, 0.3), Color3.fromRGB(100, 90, 80), 0, Enum.Material.Wood)

	-- Bathroom fixtures
	Shared.createFurniture("sink", Vector3.new(bathroomPos.X - 4, SURFACE_Y, bathroomPos.Z + 1), room)
	Shared.createFurniture("toilet", Vector3.new(bathroomPos.X + 3, SURFACE_Y, bathroomPos.Z + 1), room)

	-- Emergency light (red pulse)
	Shared.createEmergencyLight(Vector3.new(barracksPos.X, SURFACE_Y + ROOM_HEIGHT - 1, bathroomPos.Z - 3), room, 0.25)

	-- Dim main light
	Shared.createLight(Vector3.new(barracksPos.X, SURFACE_Y + ROOM_HEIGHT - 1, barracksPos.Z - 5), room, 0.15)
	Shared.createLight(Vector3.new(barracksPos.X, SURFACE_Y + ROOM_HEIGHT - 1, barracksPos.Z + 5), room, 0.1)

	-- Knocked-over coffee mug stain
	Shared.makePart(room, "CoffeeStain", Vector3.new(barracksPos.X + 5, SURFACE_Y + 0.02, barracksPos.Z - 2), Vector3.new(1, 0.02, 1.5), Color3.fromRGB(80, 60, 40), 0.4, Enum.Material.SmoothPlastic)

	-- Hiding spots: under bunks (select several), lockers, bathroom stall
	local bunkHidingPositions = {
		{ pos = Vector3.new(barracksPos.X - 6, SURFACE_Y + 0.5, barracksPos.Z - 12), id = "barracks_bunk_1" },
		{ pos = Vector3.new(barracksPos.X - 6, SURFACE_Y + 0.5, barracksPos.Z - 3), id = "barracks_bunk_4" },
		{ pos = Vector3.new(barracksPos.X + 6, SURFACE_Y + 0.5, barracksPos.Z - 8), id = "barracks_bunk_8" },
		{ pos = Vector3.new(barracksPos.X + 6, SURFACE_Y + 0.5, barracksPos.Z + 5), id = "barracks_bunk_11" },
	}

	for _, bh in bunkHidingPositions do
		Shared.createHidingSpot(bh.pos, "UnderBed", bh.id, room)
		table.insert(hidingSpots, {
			id = bh.id,
			position = bh.pos,
			spotType = "UnderBed",
			isOccupied = false,
		})
	end

	-- Locker hiding spots
	local lockerHidingPositions = {
		{ pos = Vector3.new(barracksPos.X - barracksSize.X / 2 + 1.5, SURFACE_Y + 1, barracksPos.Z - 13 + 2 * 2.2), id = "barracks_locker_2" },
		{ pos = Vector3.new(barracksPos.X - barracksSize.X / 2 + 1.5, SURFACE_Y + 1, barracksPos.Z - 13 + 5 * 2.2), id = "barracks_locker_5" },
		{ pos = Vector3.new(barracksPos.X - barracksSize.X / 2 + 1.5, SURFACE_Y + 1, barracksPos.Z - 13 + 11 * 2.2), id = "barracks_locker_11" },
	}

	for _, lh in lockerHidingPositions do
		Shared.createHidingSpot(lh.pos, "Locker", lh.id, room)
		table.insert(hidingSpots, {
			id = lh.id,
			position = lh.pos,
			spotType = "Locker",
			isOccupied = false,
		})
	end

	-- Bathroom stall hiding
	Shared.createHidingSpot(Vector3.new(bathroomPos.X + 3, SURFACE_Y + 1, bathroomPos.Z + 1), "BathroomStall", "barracks_bathroom", room)
	table.insert(hidingSpots, {
		id = "barracks_bathroom",
		position = Vector3.new(bathroomPos.X + 3, SURFACE_Y + 1, bathroomPos.Z + 1),
		spotType = "BathroomStall",
		isOccupied = false,
	})

	-- Waypoints
	table.insert(waypoints, {
		position = Vector3.new(barracksPos.X, SURFACE_Y + 3, barracksPos.Z),
		roomId = "Barracks_Center",
		dwellTime = 4,
	})
	table.insert(waypoints, {
		position = Vector3.new(barracksPos.X, SURFACE_Y + 3, barracksPos.Z - 10),
		roomId = "Barracks_Front",
		dwellTime = 3,
	})
	table.insert(waypoints, {
		position = Vector3.new(barracksPos.X, SURFACE_Y + 3, barracksPos.Z + 8),
		roomId = "Barracks_Bathroom",
		dwellTime = 5,
	})

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(barracksPos.X - barracksSize.X / 2 + 1.5, SURFACE_Y + 2, barracksPos.Z - 13 + 3 * 2.2),
		chance = 0.8,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Battery",
		position = Vector3.new(barracksPos.X - barracksSize.X / 2 + 1.5, SURFACE_Y + 2, barracksPos.Z - 13 + 7 * 2.2),
		chance = 0.4,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = Vector3.new(barracksPos.X - 6, SURFACE_Y + 1, barracksPos.Z - 3),
		chance = 0.6,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = Vector3.new(bathroomPos.X - 4, SURFACE_Y + 3, bathroomPos.Z + 1),
		chance = 0.8,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Medkit",
		position = Vector3.new(bathroomPos.X - 4, SURFACE_Y + 3.5, bathroomPos.Z + 1),
		chance = 0.3,
		guaranteed = false,
	})
	table.insert(lootPositions, {
		itemType = "Flare",
		position = footlockerPos + Vector3.new(0, 0.8, 0),
		chance = 0.5,
		guaranteed = false,
	})
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local Exterior = {}

function Exterior.build(parent: Instance): FloorData
	local floorModel = Instance.new("Model")
	floorModel.Name = "Exterior"
	floorModel.Parent = parent

	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	buildHelipad(floorModel, hidingSpots, waypoints, lootPositions)
	buildPerimeter(floorModel, hidingSpots, waypoints, lootPositions)
	buildServiceYard(floorModel, hidingSpots, waypoints, lootPositions)
	buildBarracks(floorModel, hidingSpots, waypoints, lootPositions)

	print(`[Exterior] Built: {#hidingSpots} hiding spots, {#waypoints} waypoints, {#lootPositions} loot positions`)

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return Exterior
