--!strict

--[[
	Subway/Platform - Builds the three station platform areas for Level 2.

	Stations:
		1. Hargrove Street (Entry) — Ticket Hall, Mezzanine, Platform A, Platform B (collapsed),
		   Staff Room, Maintenance Closet
		2. Moorfield (Midpoint) — Platform with 6-car stalled train, Concourse
		3. Terminus (Extraction) — Platform, Emergency Exit, Sealed Blackpoint Door

	Returns hiding spots, patrol waypoints, and loot spawn positions.
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

-- Y-level layout (all underground)
local STREET_Y = 0 -- street level reference
local TICKET_HALL_Y = -8 -- just below street
local MEZZANINE_Y = -16 -- intermediate level
local PLATFORM_Y = -24 -- platform level (track level is PLATFORM_Y - 4)
local TRACK_Y = -28 -- track bed level

-- Moorfield is offset along Z axis (deeper into the level)
local MOORFIELD_Z_OFFSET = -350

-- Terminus is even deeper
local TERMINUS_Z_OFFSET = -600

local ROOM_HEIGHT = 12
local TUNNEL_HEIGHT = 14
local DOOR_WIDTH = 5
local DOOR_HEIGHT = 8

-- Color palette
local TILE_WALL_COLOR = Color3.fromRGB(165, 170, 165)
local TILE_FLOOR_COLOR = Color3.fromRGB(130, 135, 130)
local CONCRETE_COLOR = Color3.fromRGB(100, 98, 92)
local AMBER_LIGHT = Color3.fromRGB(255, 180, 80) -- emergency amber
local BLUE_WHITE_LIGHT = Color3.fromRGB(180, 200, 255) -- Moorfield lighting
local FLUORESCENT_LIGHT = Color3.fromRGB(220, 235, 255) -- Terminus post-power

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local Platform = {}

function Platform.build(parent: Instance): FloorData
	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	local platformModel = Instance.new("Model")
	platformModel.Name = "Platforms"

	--------------------------------------------------------------------
	-- ============= HARGROVE STREET STATION (Entry) =================
	--------------------------------------------------------------------
	do
		local stationModel = Instance.new("Model")
		stationModel.Name = "HargroveStreet"

		----------------------------------------------------------------
		-- Ticket Hall (Spawn Area)
		----------------------------------------------------------------
		do
			local roomPos = Vector3.new(0, TICKET_HALL_Y, 0)
			local roomSize = Vector3.new(40, ROOM_HEIGHT, 25)

			local room = Shared.createRoom({
				position = roomPos,
				size = roomSize,
				parent = stationModel,
				name = "TicketHall",
				wallColor = TILE_WALL_COLOR,
				floorColor = TILE_FLOOR_COLOR,
				floorMaterial = Enum.Material.Marble,
				wallMaterial = Enum.Material.Concrete,
				doorways = {
					-- Stairs from street (north wall)
					{ wall = "north", offset = 0, width = 8, height = DOOR_HEIGHT },
					-- To Mezzanine (south wall)
					{ wall = "south", offset = 0, width = 8, height = DOOR_HEIGHT },
					-- To Staff Room (east wall)
					{ wall = "east", offset = 6, width = DOOR_WIDTH, height = DOOR_HEIGHT },
				},
			})

			-- Street entrance stairs (going up from ticket hall)
			Shared.createStairwell(TICKET_HALL_Y, STREET_Y, Vector3.new(0, 0, -16), room, "StreetStairs")

			-- Security gate at top of stairs (decorative, impassable)
			local secGate = Instance.new("Part")
			secGate.Name = "SecurityGate"
			secGate.Size = Vector3.new(8, 8, 0.5)
			secGate.Position = Vector3.new(0, STREET_Y - 2, -20)
			secGate.Anchored = true
			secGate.Material = Enum.Material.Metal
			secGate.Color = Color3.fromRGB(80, 80, 75)
			secGate.Parent = room

			-- Turnstiles (row of 4)
			for i = 0, 3 do
				Shared.createTurnstile(
					roomPos + Vector3.new(-9 + i * 6, 0, 5),
					0, room, `Turnstile_{i}`
				)
			end

			-- Bent turnstile (forced outward — something came through)
			local bentTurnstile = Instance.new("Part")
			bentTurnstile.Name = "BentTurnstile"
			bentTurnstile.Size = Vector3.new(3, 3.5, 1.5)
			bentTurnstile.Position = roomPos + Vector3.new(9, 1.75, 5)
			bentTurnstile.Orientation = Vector3.new(0, 0, 25)
			bentTurnstile.Anchored = true
			bentTurnstile.Material = Enum.Material.Metal
			bentTurnstile.Color = Color3.fromRGB(110, 110, 105)
			bentTurnstile.Parent = room

			-- Claw marks on bent turnstile
			for i = 1, 3 do
				local scratch = Instance.new("Part")
				scratch.Name = `ClawMark_{i}`
				scratch.Size = Vector3.new(0.05, 1.5, 0.05)
				scratch.Position = roomPos + Vector3.new(8.5 + i * 0.3, 2 + i * 0.2, 5.8)
				scratch.Anchored = true
				scratch.Material = Enum.Material.Metal
				scratch.Color = Color3.fromRGB(50, 50, 45)
				scratch.Parent = room
			end

			-- Ticket machines (2, smashed)
			Shared.createTicketMachine(roomPos + Vector3.new(-12, 0, -5), 0, room, "TicketMachine_1")
			Shared.createTicketMachine(roomPos + Vector3.new(-6, 0, -5), 0, room, "TicketMachine_2")

			-- Transit map display on wall
			Shared.createMapDisplay(roomPos + Vector3.new(-19, 6, 0), 90, room, "TransitMap")

			-- Newspaper dispenser
			Shared.createNewspaperDispenser(roomPos + Vector3.new(15, 0, -8), 0, room, "NewspaperDispenser")

			-- Dropped backpack (loot container)
			local backpack = Instance.new("Part")
			backpack.Name = "DroppedBackpack"
			backpack.Size = Vector3.new(1.5, 1, 1.5)
			backpack.Position = roomPos + Vector3.new(10, 0.5, -3)
			backpack.Anchored = true
			backpack.Material = Enum.Material.Fabric
			backpack.Color = Color3.fromRGB(60, 80, 50)
			backpack.Parent = room

			-- Single shoe
			local shoe = Instance.new("Part")
			shoe.Name = "DroppedShoe"
			shoe.Size = Vector3.new(0.5, 0.3, 1)
			shoe.Position = roomPos + Vector3.new(12, 0.15, -1)
			shoe.Orientation = Vector3.new(0, 35, 0)
			shoe.Anchored = true
			shoe.Material = Enum.Material.Fabric
			shoe.Color = Color3.fromRGB(40, 35, 30)
			shoe.Parent = room

			-- Cracked phone (interactable)
			local phone = Instance.new("Part")
			phone.Name = "CrackedPhone"
			phone.Size = Vector3.new(0.3, 0.05, 0.6)
			phone.Position = roomPos + Vector3.new(11, 0.03, -2)
			phone.Anchored = true
			phone.Material = Enum.Material.Glass
			phone.Color = Color3.fromRGB(20, 20, 25)
			phone.Parent = room

			local phonePrompt = Instance.new("ProximityPrompt")
			phonePrompt.ActionText = "Read"
			phonePrompt.ObjectText = "Cracked Phone"
			phonePrompt.HoldDuration = 0.5
			phonePrompt.MaxActivationDistance = 6
			phonePrompt.Parent = phone

			-- Emergency lights (amber, 60% coverage)
			Shared.createLight(roomPos + Vector3.new(-10, ROOM_HEIGHT - 0.5, 0), room, 0.5, AMBER_LIGHT)
			Shared.createLight(roomPos + Vector3.new(10, ROOM_HEIGHT - 0.5, 0), room, 0.5, AMBER_LIGHT)
			Shared.createLight(roomPos + Vector3.new(0, ROOM_HEIGHT - 0.5, -5), room, 0.4, AMBER_LIGHT)

			-- Waypoint
			table.insert(waypoints, {
				position = roomPos + Vector3.new(0, 3, 0),
				roomId = "Hargrove_TicketHall",
				dwellTime = 3,
			})

			-- Loot: Battery (guaranteed), Bandage (guaranteed), Flare (40%)
			table.insert(lootPositions, {
				itemType = "Battery", position = roomPos + Vector3.new(10, 1, -3),
				chance = 1, guaranteed = true,
			})
			table.insert(lootPositions, {
				itemType = "Bandage", position = roomPos + Vector3.new(10, 1.2, -3.5),
				chance = 1, guaranteed = true,
			})
			table.insert(lootPositions, {
				itemType = "Flare", position = roomPos + Vector3.new(10.5, 1, -2.5),
				chance = 0.4, guaranteed = false,
			})
		end

		----------------------------------------------------------------
		-- Staff Room
		----------------------------------------------------------------
		do
			local roomPos = Vector3.new(26, TICKET_HALL_Y, 6)
			local roomSize = Vector3.new(12, ROOM_HEIGHT, 10)

			local room = Shared.createRoom({
				position = roomPos,
				size = roomSize,
				parent = stationModel,
				name = "StaffRoom",
				wallColor = Color3.fromRGB(170, 165, 155),
				floorColor = TILE_FLOOR_COLOR,
				doorways = {
					{ wall = "west", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT },
				},
			})

			-- Staff-only door (doesn't latch properly - attribute)
			local staffDoor = Shared.createDoor(
				roomPos + Vector3.new(-6.5, DOOR_HEIGHT / 2, 0),
				CFrame.Angles(0, math.rad(90), 0),
				room, "StaffDoor", false
			)
			staffDoor:SetAttribute("Unlatched", true)
			staffDoor:SetAttribute("SwingOpenDelay", 17) -- seconds

			-- Table with tablecloth
			local table_ = Instance.new("Part")
			table_.Name = "BreakTable_Top"
			table_.Size = Vector3.new(4, 0.4, 4)
			table_.Position = roomPos + Vector3.new(0, 3, 0)
			table_.Anchored = true
			table_.Material = Enum.Material.Wood
			table_.Color = Color3.fromRGB(100, 75, 55)
			table_.Parent = room

			-- Tablecloth (draping)
			local cloth = Instance.new("Part")
			cloth.Name = "Tablecloth"
			cloth.Size = Vector3.new(4.2, 3, 4.2)
			cloth.Position = roomPos + Vector3.new(0, 1.5, 0)
			cloth.Anchored = true
			cloth.Material = Enum.Material.Fabric
			cloth.Color = Color3.fromRGB(140, 130, 120)
			cloth.Transparency = 0.15
			cloth.Parent = room

			-- Table legs
			for _, offset in {
				Vector3.new(-1.6, 1.5, -1.6),
				Vector3.new(1.6, 1.5, -1.6),
				Vector3.new(-1.6, 1.5, 1.6),
				Vector3.new(1.6, 1.5, 1.6),
			} do
				local leg = Instance.new("Part")
				leg.Name = "TableLeg"
				leg.Size = Vector3.new(0.4, 3, 0.4)
				leg.Position = roomPos + offset
				leg.Anchored = true
				leg.Material = Enum.Material.Wood
				leg.Color = Color3.fromRGB(90, 65, 45)
				leg.Parent = room
			end

			-- Chairs
			for _, offset in { Vector3.new(3, 0, 0), Vector3.new(-3, 0, 0), Vector3.new(0, 0, 3) } do
				local chairSeat = Instance.new("Part")
				chairSeat.Name = "Chair"
				chairSeat.Size = Vector3.new(1.8, 0.3, 1.8)
				chairSeat.Position = roomPos + offset + Vector3.new(0, 1.8, 0)
				chairSeat.Anchored = true
				chairSeat.Material = Enum.Material.Plastic
				chairSeat.Color = Color3.fromRGB(60, 80, 100)
				chairSeat.Parent = room
			end

			-- Lockers (4 — 2 open, 1 locked, 1 welded)
			for i = 0, 3 do
				local locker = Instance.new("Part")
				locker.Name = `Locker_{i}`
				locker.Size = Vector3.new(2, 7, 2)
				locker.Position = roomPos + Vector3.new(-4 + i * 2.5, 3.5, -4)
				locker.Anchored = true
				locker.Material = Enum.Material.Metal
				locker.Color = Color3.fromRGB(100, 110, 100)
				locker.Parent = room

				if i == 2 then
					locker:SetAttribute("IsLocked", true)
					locker:SetAttribute("RedHerring", true)
				elseif i == 3 then
					locker:SetAttribute("IsWelded", true)
					-- "DON'T OPEN" note (decorative)
					local note = Instance.new("Part")
					note.Name = "WeldedLockerNote"
					note.Size = Vector3.new(0.8, 0.5, 0.02)
					note.Position = roomPos + Vector3.new(3.5, 5, -3)
					note.Anchored = true
					note.Material = Enum.Material.SmoothPlastic
					note.Color = Color3.fromRGB(230, 225, 200)
					note.Parent = room
				end
			end

			-- Corkboard with schematic map (key item)
			local corkboard = Instance.new("Part")
			corkboard.Name = "Corkboard"
			corkboard.Size = Vector3.new(5, 3, 0.3)
			corkboard.Position = roomPos + Vector3.new(0, 6, 4.8)
			corkboard.Anchored = true
			corkboard.Material = Enum.Material.Wood
			corkboard.Color = Color3.fromRGB(160, 130, 80)
			corkboard.Parent = room

			local corkPrompt = Instance.new("ProximityPrompt")
			corkPrompt.ActionText = "Study Map"
			corkPrompt.ObjectText = "Line 13 Schematic"
			corkPrompt.HoldDuration = 1
			corkPrompt.MaxActivationDistance = 8
			corkPrompt.Parent = corkboard

			-- Microwave
			local microwave = Instance.new("Part")
			microwave.Name = "Microwave"
			microwave.Size = Vector3.new(1.5, 1, 1.2)
			microwave.Position = roomPos + Vector3.new(4, 3.5, -4)
			microwave.Anchored = true
			microwave.Material = Enum.Material.Metal
			microwave.Color = Color3.fromRGB(180, 180, 175)
			microwave.Parent = room

			-- Wall clock (stopped at 3:47)
			local clock = Instance.new("Part")
			clock.Name = "WallClock"
			clock.Shape = Enum.PartType.Cylinder
			clock.Size = Vector3.new(0.2, 1.5, 1.5)
			clock.Position = roomPos + Vector3.new(5.8, 8, 0)
			clock.Orientation = Vector3.new(0, 0, 90)
			clock.Anchored = true
			clock.Material = Enum.Material.SmoothPlastic
			clock.Color = Color3.fromRGB(220, 215, 200)
			clock.Parent = room

			-- Light
			Shared.createLight(roomPos + Vector3.new(0, ROOM_HEIGHT - 0.5, 0), room, 0.4, AMBER_LIGHT)

			-- Hiding spots: under table, inside open lockers
			local _, spotData1 = Shared.createHidingSpot(
				roomPos + Vector3.new(0, 1, 0), "Desk", "Hargrove_StaffRoom_Table", room
			)
			table.insert(hidingSpots, spotData1)

			local _, spotData2 = Shared.createHidingSpot(
				roomPos + Vector3.new(-4, 1, -4), "Locker", "Hargrove_StaffRoom_Locker0", room
			)
			table.insert(hidingSpots, spotData2)

			-- Waypoint
			table.insert(waypoints, {
				position = roomPos + Vector3.new(0, 3, 0),
				roomId = "Hargrove_StaffRoom",
				dwellTime = 4,
			})

			-- Loot
			table.insert(lootPositions, {
				itemType = "Battery", position = roomPos + Vector3.new(-4, 1, -4),
				chance = 1, guaranteed = true,
			})
			table.insert(lootPositions, {
				itemType = "Bandage", position = roomPos + Vector3.new(-1.5, 1, -4),
				chance = 0.5, guaranteed = false,
			})
		end

		----------------------------------------------------------------
		-- Mezzanine / Concourse
		----------------------------------------------------------------
		do
			local roomPos = Vector3.new(0, MEZZANINE_Y, 20)
			local roomSize = Vector3.new(35, ROOM_HEIGHT, 20)

			local room = Shared.createRoom({
				position = roomPos,
				size = roomSize,
				parent = stationModel,
				name = "Mezzanine",
				wallColor = TILE_WALL_COLOR,
				floorColor = TILE_FLOOR_COLOR,
				floorMaterial = Enum.Material.Marble,
				doorways = {
					-- From Ticket Hall (north)
					{ wall = "north", offset = 0, width = 8, height = DOOR_HEIGHT },
					-- To Platform A (south-west)
					{ wall = "south", offset = -8, width = DOOR_WIDTH, height = DOOR_HEIGHT },
					-- To Platform B (south-east)
					{ wall = "south", offset = 8, width = DOOR_WIDTH, height = DOOR_HEIGHT },
					-- To Maintenance Closet (east)
					{ wall = "east", offset = 3, width = 4, height = DOOR_HEIGHT },
				},
			})

			-- Stairs up to ticket hall
			Shared.createStairwell(MEZZANINE_Y, TICKET_HALL_Y, Vector3.new(0, 0, 8), room, "StairsToTicketHall")

			-- Dead escalators (flanking central stairs)
			Shared.createDeadEscalator(
				roomPos + Vector3.new(-8, 0, 8),
				Vector3.new(-8, TICKET_HALL_Y - MEZZANINE_Y, -4) + roomPos,
				4, room, "Escalator_Left"
			)
			Shared.createDeadEscalator(
				roomPos + Vector3.new(8, 0, 8),
				Vector3.new(8, TICKET_HALL_Y - MEZZANINE_Y, -4) + roomPos,
				4, room, "Escalator_Right"
			)

			-- Information board (Line 13 route map)
			Shared.createMapDisplay(roomPos + Vector3.new(-17, 6, 0), 90, room, "InfoBoard")

			-- Advertising boards
			for i = 0, 2 do
				local adBoard = Instance.new("Part")
				adBoard.Name = `AdBoard_{i}`
				adBoard.Size = Vector3.new(4, 3, 0.2)
				adBoard.Position = roomPos + Vector3.new(17, 6, -6 + i * 6)
				adBoard.Anchored = true
				adBoard.Material = Enum.Material.SmoothPlastic
				adBoard.Color = Color3.fromRGB(200, 195, 185)
				adBoard.Parent = room
			end

			-- Busker's guitar case (open, coins scattered)
			local guitarCase = Instance.new("Part")
			guitarCase.Name = "GuitarCase"
			guitarCase.Size = Vector3.new(1.5, 0.3, 4)
			guitarCase.Position = roomPos + Vector3.new(-5, 0.15, -3)
			guitarCase.Anchored = true
			guitarCase.Material = Enum.Material.Fabric
			guitarCase.Color = Color3.fromRGB(40, 30, 25)
			guitarCase.Parent = room

			-- Smashed guitar
			local guitar = Instance.new("Part")
			guitar.Name = "SmashedGuitar"
			guitar.Size = Vector3.new(1.2, 0.4, 3)
			guitar.Position = roomPos + Vector3.new(-3, 0.5, -5)
			guitar.Orientation = Vector3.new(15, 30, -10)
			guitar.Anchored = true
			guitar.Material = Enum.Material.Wood
			guitar.Color = Color3.fromRGB(120, 80, 50)
			guitar.Parent = room

			-- Scattered coins
			for i = 1, 8 do
				local coin = Instance.new("Part")
				coin.Name = `Coin_{i}`
				coin.Shape = Enum.PartType.Cylinder
				coin.Size = Vector3.new(0.05, 0.4, 0.4)
				coin.Position = roomPos + Vector3.new(-5 + math.random() * 3, 0.03, -3 + math.random() * 2)
				coin.Orientation = Vector3.new(0, 0, 90)
				coin.Anchored = true
				coin.Material = Enum.Material.Metal
				coin.Color = Color3.fromRGB(180, 160, 80)
				coin.Parent = room
			end

			-- Lighting
			Shared.createLight(roomPos + Vector3.new(-8, ROOM_HEIGHT - 0.5, 0), room, 0.35, AMBER_LIGHT)
			Shared.createLight(roomPos + Vector3.new(8, ROOM_HEIGHT - 0.5, 0), room, 0.35, AMBER_LIGHT)

			-- Waypoint
			table.insert(waypoints, {
				position = roomPos + Vector3.new(0, 3, 0),
				roomId = "Hargrove_Mezzanine",
				dwellTime = 2,
			})

			-- Loot
			table.insert(lootPositions, {
				itemType = "Battery", position = roomPos + Vector3.new(-5, 0.3, -3),
				chance = 0.5, guaranteed = false,
			})
		end

		----------------------------------------------------------------
		-- Maintenance Closet
		----------------------------------------------------------------
		do
			local roomPos = Vector3.new(22, MEZZANINE_Y, 23)
			local roomSize = Vector3.new(8, ROOM_HEIGHT, 6)

			local room = Shared.createRoom({
				position = roomPos,
				size = roomSize,
				parent = stationModel,
				name = "MaintenanceCloset",
				wallColor = CONCRETE_COLOR,
				floorColor = Color3.fromRGB(85, 85, 80),
				doorways = {
					{ wall = "west", offset = 0, width = 4, height = DOOR_HEIGHT },
				},
			})

			-- Heavy door (broken lock)
			local mDoor = Shared.createDoor(
				roomPos + Vector3.new(-4.5, DOOR_HEIGHT / 2, 0),
				CFrame.Angles(0, math.rad(90), 0),
				room, "MaintenanceDoor", false
			)
			mDoor:SetAttribute("BrokenLock", true)

			-- Utility shelving
			local shelf = Instance.new("Part")
			shelf.Name = "UtilityShelf"
			shelf.Size = Vector3.new(6, 8, 2)
			shelf.Position = roomPos + Vector3.new(0, 4, -2)
			shelf.Anchored = true
			shelf.Material = Enum.Material.Metal
			shelf.Color = Color3.fromRGB(120, 120, 115)
			shelf.Parent = room

			-- Cleaning supplies (mop bucket, etc.)
			local mopBucket = Instance.new("Part")
			mopBucket.Name = "MopBucket"
			mopBucket.Size = Vector3.new(1.2, 1, 1.2)
			mopBucket.Position = roomPos + Vector3.new(-2, 0.5, 1)
			mopBucket.Anchored = true
			mopBucket.Material = Enum.Material.Metal
			mopBucket.Color = Color3.fromRGB(150, 150, 145)
			mopBucket.Parent = room

			-- Electrical panel (non-functional)
			local panel = Instance.new("Part")
			panel.Name = "ElectricalPanel"
			panel.Size = Vector3.new(2, 2.5, 0.3)
			panel.Position = roomPos + Vector3.new(3, 5, 2.8)
			panel.Anchored = true
			panel.Material = Enum.Material.Metal
			panel.Color = Color3.fromRGB(70, 70, 65)
			panel.Parent = room

			-- Ventilation grate in ceiling (Crawler entry point)
			local ventGrate = Instance.new("Part")
			ventGrate.Name = "VentGrate"
			ventGrate.Size = Vector3.new(3, 0.2, 3)
			ventGrate.Position = roomPos + Vector3.new(0, ROOM_HEIGHT + 0.4, 0)
			ventGrate.Anchored = true
			ventGrate.Material = Enum.Material.Metal
			ventGrate.Color = Color3.fromRGB(90, 90, 85)
			ventGrate.Parent = room
			ventGrate:SetAttribute("CrawlerEntryPoint", true)

			-- Hiding spot: behind shelving
			local _, spotData = Shared.createHidingSpot(
				roomPos + Vector3.new(-3, 1, -2), "Closet", "Hargrove_MaintenanceCloset_Shelf", room
			)
			table.insert(hidingSpots, spotData)

			-- Very dim light
			Shared.createLight(roomPos + Vector3.new(0, ROOM_HEIGHT - 0.5, 0), room, 0.15, AMBER_LIGHT)

			-- Waypoint
			table.insert(waypoints, {
				position = roomPos + Vector3.new(0, 3, 0),
				roomId = "Hargrove_MaintenanceCloset",
				dwellTime = 2,
			})

			-- Loot: 2x Battery (guaranteed), 1x Flare (50%)
			table.insert(lootPositions, {
				itemType = "Battery", position = roomPos + Vector3.new(-1, 2, -2),
				chance = 1, guaranteed = true,
			})
			table.insert(lootPositions, {
				itemType = "Battery", position = roomPos + Vector3.new(1, 4, -2),
				chance = 1, guaranteed = true,
			})
			table.insert(lootPositions, {
				itemType = "Flare", position = roomPos + Vector3.new(-2, 0.5, 1),
				chance = 0.5, guaranteed = false,
			})
		end

		----------------------------------------------------------------
		-- Platform A
		----------------------------------------------------------------
		do
			local platPos = Vector3.new(-10, PLATFORM_Y, 45)
			local platSize = Vector3.new(50, TUNNEL_HEIGHT, 12)

			local room = Shared.createRoom({
				position = platPos,
				size = platSize,
				parent = stationModel,
				name = "PlatformA",
				wallColor = TILE_WALL_COLOR,
				floorColor = TILE_FLOOR_COLOR,
				floorMaterial = Enum.Material.Marble,
				wallMaterial = Enum.Material.Concrete,
				noCeiling = true, -- Open to tunnel ceiling above
				doorways = {
					-- From Mezzanine
					{ wall = "north", offset = -12, width = DOOR_WIDTH, height = DOOR_HEIGHT },
					-- To tunnel (south, track level)
					{ wall = "south", offset = 0, width = 50, height = 4 },
				},
			})

			-- Stairs down from mezzanine
			Shared.createStairwell(PLATFORM_Y, MEZZANINE_Y, Vector3.new(-22, 0, 36), room, "StairsToPlatformA")

			-- Tunnel ceiling over platform
			Shared.createCeiling(
				Vector3.new(platPos.X, PLATFORM_Y + TUNNEL_HEIGHT + 0.5, platPos.Z),
				Vector3.new(52, 1, 30),
				room, "TunnelCeiling"
			)

			-- Platform edge with safety line
			Shared.createPlatformEdge(
				Vector3.new(-35, PLATFORM_Y, 51),
				Vector3.new(15, PLATFORM_Y, 51),
				room, "PlatformEdge_A"
			)

			-- Track bed (below platform)
			Shared.createTrackBed(
				Vector3.new(-35, TRACK_Y, 55),
				Vector3.new(15, TRACK_Y, 55),
				room, "TrackBed_A"
			)

			-- Destination board (flickering)
			local destBoard = Instance.new("Part")
			destBoard.Name = "DestinationBoard"
			destBoard.Size = Vector3.new(8, 2, 0.3)
			destBoard.Position = platPos + Vector3.new(0, TUNNEL_HEIGHT - 2, -5)
			destBoard.Anchored = true
			destBoard.Material = Enum.Material.Neon
			destBoard.Color = Color3.fromRGB(200, 100, 30)
			destBoard.Transparency = 0.3
			destBoard.Parent = room
			destBoard:SetAttribute("FlickerText", "MOORFIELD|TERMINUS|DO NOT BOARD")

			-- Benches
			Shared.createBench(platPos + Vector3.new(-15, 0, -3), 0, room, "Bench_A1")
			Shared.createBench(platPos + Vector3.new(5, 0, -3), 0, room, "Bench_A2")

			-- Abandoned train car on tracks (lootable)
			local trainCar = Shared.createTrainCar(
				Vector3.new(-10, TRACK_Y + 1, 55),
				"x", room, "AbandonedTrain_PlatformA",
				{ "left" }, -- doors forced open on platform side
				false
			)
			trainCar:SetAttribute("Lootable", true)

			-- Emergency lights (amber, 40% coverage)
			Shared.createEmergencyLight(platPos + Vector3.new(-15, TUNNEL_HEIGHT - 1, 0), room, AMBER_LIGHT)
			Shared.createEmergencyLight(platPos + Vector3.new(10, TUNNEL_HEIGHT - 1, 0), room, AMBER_LIGHT)

			-- Waypoints
			table.insert(waypoints, {
				position = platPos + Vector3.new(0, 3, 0),
				roomId = "Hargrove_PlatformA",
				dwellTime = 3,
			})
			table.insert(waypoints, {
				position = platPos + Vector3.new(-15, 3, 0),
				roomId = "Hargrove_PlatformA_West",
				dwellTime = 2,
			})

			-- Loot (in the train car area)
			table.insert(lootPositions, {
				itemType = "Bandage", position = Vector3.new(-10, TRACK_Y + 2.5, 55),
				chance = 1, guaranteed = true,
			})
			table.insert(lootPositions, {
				itemType = "Battery", position = Vector3.new(-25, TRACK_Y + 2.5, 55),
				chance = 0.6, guaranteed = false,
			})
		end

		----------------------------------------------------------------
		-- Platform B (Collapsed)
		----------------------------------------------------------------
		do
			local platPos = Vector3.new(10, PLATFORM_Y, 45)
			local platSize = Vector3.new(20, TUNNEL_HEIGHT, 12)

			local room = Shared.createRoom({
				position = platPos,
				size = platSize,
				parent = stationModel,
				name = "PlatformB_Collapsed",
				wallColor = TILE_WALL_COLOR,
				floorColor = TILE_FLOOR_COLOR,
				floorMaterial = Enum.Material.Marble,
				noCeiling = true,
				doorways = {
					{ wall = "north", offset = -2, width = DOOR_WIDTH, height = DOOR_HEIGHT },
				},
			})

			-- Partial ceiling (only first 10 studs, then collapsed)
			Shared.createCeiling(
				Vector3.new(platPos.X - 5, PLATFORM_Y + TUNNEL_HEIGHT + 0.5, platPos.Z - 3),
				Vector3.new(10, 1, 8),
				room, "PartialCeiling"
			)

			-- Rubble / collapse debris
			Shared.createRubble(platPos + Vector3.new(3, 0, 2), 12, 15, room, "CollapseRubble")

			-- Construction barricade
			Shared.createBarricade(
				platPos + Vector3.new(-2, 0, 0),
				Vector3.new(8, 4, 0.5), 0, room, "DangerBarricade"
			)

			-- Hard hat with headlamp (visible through rubble gap)
			local hardHat = Instance.new("Part")
			hardHat.Name = "HardHat"
			hardHat.Shape = Enum.PartType.Ball
			hardHat.Size = Vector3.new(1.2, 1.2, 1.2)
			hardHat.Position = platPos + Vector3.new(6, 1, 4)
			hardHat.Anchored = true
			hardHat.Material = Enum.Material.SmoothPlastic
			hardHat.Color = Color3.fromRGB(200, 180, 40)
			hardHat.Parent = room

			-- Headlamp light on hard hat
			local headlamp = Instance.new("PointLight")
			headlamp.Brightness = 0.3
			headlamp.Color = Color3.fromRGB(255, 240, 200)
			headlamp.Range = 8
			headlamp.Parent = hardHat

			-- Dark smear on rubble (not paint)
			local smear = Instance.new("Part")
			smear.Name = "DarkSmear"
			smear.Size = Vector3.new(2, 1.5, 0.1)
			smear.Position = platPos + Vector3.new(5, 2, 3)
			smear.Anchored = true
			smear.Material = Enum.Material.SmoothPlastic
			smear.Color = Color3.fromRGB(40, 20, 20)
			smear.Transparency = 0.3
			smear.Parent = room

			-- Minimal light (from headlamp only)

			-- Waypoint
			table.insert(waypoints, {
				position = platPos + Vector3.new(-5, 3, -3),
				roomId = "Hargrove_PlatformB",
				dwellTime = 1.5,
			})

			-- Loot
			table.insert(lootPositions, {
				itemType = "Bandage", position = platPos + Vector3.new(-3, 0.5, -1),
				chance = 0.3, guaranteed = false,
			})
		end

		stationModel.Parent = platformModel
	end

	--------------------------------------------------------------------
	-- ============= MOORFIELD STATION (Midpoint) ===================
	--------------------------------------------------------------------
	do
		local stationModel = Instance.new("Model")
		stationModel.Name = "MoorfieldStation"

		local mBase = Vector3.new(0, PLATFORM_Y, MOORFIELD_Z_OFFSET)

		----------------------------------------------------------------
		-- Moorfield Platform
		----------------------------------------------------------------
		do
			local platPos = mBase + Vector3.new(0, 0, 0)
			local platSize = Vector3.new(60, TUNNEL_HEIGHT, 15)

			local room = Shared.createRoom({
				position = platPos,
				size = platSize,
				parent = stationModel,
				name = "MoorfieldPlatform",
				wallColor = Color3.fromRGB(170, 175, 175),
				floorColor = Color3.fromRGB(135, 140, 140),
				floorMaterial = Enum.Material.Marble,
				wallMaterial = Enum.Material.Concrete,
				noCeiling = true,
				doorways = {
					-- Tunnel entry (west)
					{ wall = "west", offset = 0, width = 10, height = TUNNEL_HEIGHT },
					-- To Concourse (east, stairs up)
					{ wall = "east", offset = 0, width = 8, height = DOOR_HEIGHT },
					-- Control Room door (north)
					{ wall = "north", offset = 15, width = DOOR_WIDTH, height = DOOR_HEIGHT },
				},
			})

			-- Tunnel ceiling
			Shared.createCeiling(
				Vector3.new(platPos.X, PLATFORM_Y + TUNNEL_HEIGHT + 0.5, platPos.Z),
				Vector3.new(62, 1, 35),
				room, "MoorfieldCeiling"
			)

			-- Platform edge
			Shared.createPlatformEdge(
				Vector3.new(-30, PLATFORM_Y, platPos.Z + 8),
				Vector3.new(30, PLATFORM_Y, platPos.Z + 8),
				room, "MoorfieldEdge"
			)

			-- Track bed
			Shared.createTrackBed(
				Vector3.new(-30, TRACK_Y, platPos.Z + 12),
				Vector3.new(30, TRACK_Y, platPos.Z + 12),
				room, "MoorfieldTrack"
			)

			-- 6-car stalled train on tracks
			local carPositions = {}
			for carIdx = 0, 5 do
				local carX = -25 + carIdx * 10 -- spaced 10 apart (30-stud cars overlap slightly, creating coupled look)
				local carZ = platPos.Z + 12
				local carY = TRACK_Y + 1

				local doorConfig: { string } = {}
				-- Cars 1,3,5 have doors open on platform side (left)
				if carIdx == 0 or carIdx == 2 or carIdx == 4 then
					doorConfig = { "left" }
				end

				local isBreached = (carIdx == 4) -- Car 5 roof breached

				local carName = `MoorfieldTrain_Car{carIdx + 1}`
				local car = Shared.createTrainCar(
					Vector3.new(carX, carY, carZ),
					"x", room, carName,
					doorConfig, isBreached
				)

				-- Car 2 (index 1): locked, dark windows
				if carIdx == 1 then
					car:SetAttribute("Locked", true)
					car:SetAttribute("BangingEvent", true)
					-- Smeared windows
					for _, child in car:GetChildren() do
						if child:IsA("BasePart") and child.Name:find("Window") then
							child.Color = Color3.fromRGB(15, 10, 10)
							child.Transparency = 0.15
						end
					end
				end

				-- Car 4 (index 3): contains body with maintenance key
				if carIdx == 3 then
					car:SetAttribute("HasMaintenanceKey", true)
					local body = Instance.new("Part")
					body.Name = "TransitWorkerBody"
					body.Size = Vector3.new(1.5, 1.5, 3)
					body.Position = Vector3.new(carX + 5, carY + 1.5, carZ)
					body.Anchored = true
					body.Material = Enum.Material.Fabric
					body.Color = Color3.fromRGB(40, 50, 70)
					body.Parent = car

					local keyPrompt = Instance.new("ProximityPrompt")
					keyPrompt.ActionText = "Take Key"
					keyPrompt.ObjectText = "Chen, A. — Line 13 Operations"
					keyPrompt.HoldDuration = 1
					keyPrompt.MaxActivationDistance = 6
					keyPrompt.Parent = body
				end

				-- Car 6 (index 5): emergency intercom loop
				if carIdx == 5 then
					car:SetAttribute("IntercomLoop", true)
					car:SetAttribute("IntercomMessage", "Service on Line 13 has been suspended. Please proceed to the nearest exit.")
				end

				table.insert(carPositions, Vector3.new(carX, carY, carZ))
			end

			-- Benches (hiding spots)
			local bench1 = Shared.createBench(platPos + Vector3.new(-20, 0, -4), 0, room, "MoorfieldBench_1")
			local _, spotData1 = Shared.createHidingSpot(
				platPos + Vector3.new(-20, 0.5, -4), "Desk", "Moorfield_Bench1", bench1
			)
			table.insert(hidingSpots, spotData1)

			local bench2 = Shared.createBench(platPos + Vector3.new(10, 0, -4), 0, room, "MoorfieldBench_2")
			local _, spotData2 = Shared.createHidingSpot(
				platPos + Vector3.new(10, 0.5, -4), "Desk", "Moorfield_Bench2", bench2
			)
			table.insert(hidingSpots, spotData2)

			-- Transit map display
			Shared.createMapDisplay(platPos + Vector3.new(0, 6, -7), 0, room, "MoorfieldMap")

			-- Emergency lights (blue-white)
			for i = -2, 2 do
				Shared.createEmergencyLight(
					platPos + Vector3.new(i * 12, TUNNEL_HEIGHT - 1, 0),
					room, BLUE_WHITE_LIGHT
				)
			end

			-- Waypoints
			table.insert(waypoints, {
				position = platPos + Vector3.new(0, 3, 0),
				roomId = "Moorfield_Platform",
				dwellTime = 3,
			})
			table.insert(waypoints, {
				position = platPos + Vector3.new(-20, 3, 0),
				roomId = "Moorfield_Platform_West",
				dwellTime = 2,
			})
			table.insert(waypoints, {
				position = platPos + Vector3.new(20, 3, 0),
				roomId = "Moorfield_Platform_East",
				dwellTime = 2,
			})

			-- Loot (in train cars)
			-- Car 1
			table.insert(lootPositions, {
				itemType = "Battery", position = Vector3.new(-25, TRACK_Y + 2.5, platPos.Z + 12),
				chance = 1, guaranteed = true,
			})
			table.insert(lootPositions, {
				itemType = "Bandage", position = Vector3.new(-23, TRACK_Y + 2.5, platPos.Z + 12),
				chance = 0.5, guaranteed = false,
			})
			-- Car 3
			table.insert(lootPositions, {
				itemType = "Flare", position = Vector3.new(-5, TRACK_Y + 2.5, platPos.Z + 12),
				chance = 0.4, guaranteed = false,
			})
			-- Car 4 (Maintenance Key)
			table.insert(lootPositions, {
				itemType = "MaintenanceKey", position = Vector3.new(-0.5, TRACK_Y + 2.5, platPos.Z + 12),
				chance = 1, guaranteed = true,
			})
		end

		----------------------------------------------------------------
		-- Control Room
		----------------------------------------------------------------
		do
			local crPos = mBase + Vector3.new(15, 0, -8)
			local crSize = Vector3.new(12, ROOM_HEIGHT, 10)

			local room = Shared.createRoom({
				position = crPos,
				size = crSize,
				parent = stationModel,
				name = "ControlRoom",
				wallColor = Color3.fromRGB(130, 130, 125),
				floorColor = Color3.fromRGB(90, 90, 85),
				floorMaterial = Enum.Material.Concrete,
				doorways = {
					{ wall = "south", offset = 0, width = DOOR_WIDTH, height = DOOR_HEIGHT },
				},
			})

			-- Security door (requires Maintenance Key or force)
			local crDoor = Shared.createDoor(
				crPos + Vector3.new(0, DOOR_HEIGHT / 2, 5.5),
				nil, room, "ControlRoomDoor", true, "MaintenanceKey"
			)
			crDoor:SetAttribute("ForceOpenDuration", 5)
			crDoor:SetAttribute("ForceOpenSoundRadius", 50)

			-- Switching panel (main objective)
			local switchPanel = Shared.createSwitchingPanel(
				crPos + Vector3.new(0, 0, -4), 0, room, "MainSwitchingPanel"
			)
			switchPanel:SetAttribute("ObjectivePanel", true)
			switchPanel:SetAttribute("TargetCircuit", "TRM-13")

			-- Control desk
			local desk = Instance.new("Part")
			desk.Name = "ControlDesk"
			desk.Size = Vector3.new(8, 0.5, 3)
			desk.Position = crPos + Vector3.new(0, 3, 0)
			desk.Anchored = true
			desk.Material = Enum.Material.Metal
			desk.Color = Color3.fromRGB(70, 70, 65)
			desk.Parent = room

			-- Desk legs
			for _, offset in {
				Vector3.new(-3.5, 1.5, -1), Vector3.new(3.5, 1.5, -1),
				Vector3.new(-3.5, 1.5, 1), Vector3.new(3.5, 1.5, 1),
			} do
				local leg = Instance.new("Part")
				leg.Name = "DeskLeg"
				leg.Size = Vector3.new(0.4, 3, 0.4)
				leg.Position = crPos + offset
				leg.Anchored = true
				leg.Material = Enum.Material.Metal
				leg.Color = Color3.fromRGB(60, 60, 55)
				leg.Parent = room
			end

			-- Breaker sequence hint (scratched under desk)
			desk:SetAttribute("BreakerHint", "Sequence: 3-1-?")
			desk:SetAttribute("HiddenNumber", "7")

			-- Maintenance card pinned to wall (partial sequence)
			local maintenanceCard = Instance.new("Part")
			maintenanceCard.Name = "MaintenanceCard"
			maintenanceCard.Size = Vector3.new(0.6, 0.4, 0.02)
			maintenanceCard.Position = crPos + Vector3.new(-5, 5, -4.8)
			maintenanceCard.Anchored = true
			maintenanceCard.Material = Enum.Material.SmoothPlastic
			maintenanceCard.Color = Color3.fromRGB(230, 225, 200)
			maintenanceCard.Parent = room
			maintenanceCard:SetAttribute("BreakerSequence", "3-1-?")

			-- Monitor bank (mostly dead)
			for i = 0, 3 do
				local monitor = Instance.new("Part")
				monitor.Name = `Monitor_{i}`
				monitor.Size = Vector3.new(2, 1.5, 0.2)
				monitor.Position = crPos + Vector3.new(-3 + i * 2, 4.5, -4.5)
				monitor.Anchored = true
				monitor.Material = Enum.Material.Glass
				monitor.Color = Color3.fromRGB(10, 12, 15)
				monitor.Parent = room

				if i == 2 then
					-- One functional monitor (Terminus camera feed)
					monitor:SetAttribute("FunctionalScreen", true)
					monitor:SetAttribute("CameraFeed", "Terminus")
					monitor.Color = Color3.fromRGB(20, 30, 20)
				end
			end

			-- Main bus lever
			local lever = Instance.new("Part")
			lever.Name = "MainBusLever"
			lever.Size = Vector3.new(0.5, 2, 0.3)
			lever.Position = crPos + Vector3.new(5, 4, -4.5)
			lever.Anchored = true
			lever.Material = Enum.Material.Metal
			lever.Color = Color3.fromRGB(140, 50, 40)
			lever.Parent = room

			local leverPrompt = Instance.new("ProximityPrompt")
			leverPrompt.ActionText = "Engage Main Bus"
			leverPrompt.ObjectText = "Power Lever"
			leverPrompt.HoldDuration = 2
			leverPrompt.MaxActivationDistance = 6
			leverPrompt.Parent = lever
			lever:SetAttribute("SoundRadius", 60)

			-- Filing cabinet (Blackpoint memo)
			local cabinet = Instance.new("Part")
			cabinet.Name = "FilingCabinet"
			cabinet.Size = Vector3.new(2, 5, 1.5)
			cabinet.Position = crPos + Vector3.new(-5, 2.5, 3)
			cabinet.Anchored = true
			cabinet.Material = Enum.Material.Metal
			cabinet.Color = Color3.fromRGB(110, 110, 105)
			cabinet.Parent = room

			-- Light
			Shared.createLight(crPos + Vector3.new(0, ROOM_HEIGHT - 0.5, 0), room, 0.3, BLUE_WHITE_LIGHT)

			-- Waypoint
			table.insert(waypoints, {
				position = crPos + Vector3.new(0, 3, 0),
				roomId = "Moorfield_ControlRoom",
				dwellTime = 5,
			})

			-- Loot
			table.insert(lootPositions, {
				itemType = "Battery", position = crPos + Vector3.new(-3, 3.5, 0),
				chance = 1, guaranteed = true,
			})
			table.insert(lootPositions, {
				itemType = "Bandage", position = crPos + Vector3.new(2, 3.5, 0),
				chance = 1, guaranteed = true,
			})
		end

		----------------------------------------------------------------
		-- Moorfield Concourse
		----------------------------------------------------------------
		do
			local concPos = mBase + Vector3.new(40, 0, 0)
			local concSize = Vector3.new(30, TUNNEL_HEIGHT, 25)

			local room = Shared.createRoom({
				position = concPos,
				size = concSize,
				parent = stationModel,
				name = "MoorfieldConcourse",
				wallColor = Color3.fromRGB(175, 180, 175),
				floorColor = Color3.fromRGB(140, 145, 140),
				floorMaterial = Enum.Material.Marble,
				wallMaterial = Enum.Material.Concrete,
				doorways = {
					-- From platform (west)
					{ wall = "west", offset = 0, width = 8, height = DOOR_HEIGHT },
					-- To Deep Tunnels (south, security gate)
					{ wall = "south", offset = 0, width = 6, height = DOOR_HEIGHT },
				},
			})

			-- Ticket gates (open)
			for i = 0, 2 do
				Shared.createTurnstile(
					concPos + Vector3.new(-8 + i * 5, 0, -8), 0, room, `ConcTurnstile_{i}`
				)
			end

			-- Coffee shop (shutter half-open)
			local coffeeShop = Instance.new("Model")
			coffeeShop.Name = "CoffeeShop"

			local shopWall = Shared.createWall(
				concPos + Vector3.new(-12, TUNNEL_HEIGHT / 2, -10),
				Vector3.new(10, TUNNEL_HEIGHT, 1), coffeeShop, "ShopWall"
			)
			shopWall.Color = Color3.fromRGB(140, 100, 70)

			-- Half-open shutter
			local shutter = Instance.new("Part")
			shutter.Name = "Shutter"
			shutter.Size = Vector3.new(6, 4, 0.3)
			shutter.Position = concPos + Vector3.new(-12, TUNNEL_HEIGHT - 2, -9.5)
			shutter.Anchored = true
			shutter.Material = Enum.Material.Metal
			shutter.Color = Color3.fromRGB(120, 120, 115)
			shutter.Parent = coffeeShop

			-- Counter inside
			local counter = Instance.new("Part")
			counter.Name = "Counter"
			counter.Size = Vector3.new(6, 3, 1)
			counter.Position = concPos + Vector3.new(-12, 1.5, -11)
			counter.Anchored = true
			counter.Material = Enum.Material.Marble
			counter.Color = Color3.fromRGB(180, 175, 165)
			counter.Parent = coffeeShop

			-- Hiding spot: behind coffee shop counter
			local _, shopSpot = Shared.createHidingSpot(
				concPos + Vector3.new(-12, 1, -12), "Desk", "Moorfield_CoffeeShop_Counter", coffeeShop
			)
			table.insert(hidingSpots, shopSpot)

			coffeeShop.Parent = room

			-- Newsagent (shutter locked)
			local newsagent = Instance.new("Model")
			newsagent.Name = "Newsagent"

			local newsWall = Shared.createWall(
				concPos + Vector3.new(12, TUNNEL_HEIGHT / 2, -10),
				Vector3.new(8, TUNNEL_HEIGHT, 1), newsagent, "NewsagentWall"
			)
			newsWall.Color = Color3.fromRGB(130, 130, 125)

			local newsShutter = Instance.new("Part")
			newsShutter.Name = "LockedShutter"
			newsShutter.Size = Vector3.new(5, 8, 0.3)
			newsShutter.Position = concPos + Vector3.new(12, 4, -9.5)
			newsShutter.Anchored = true
			newsShutter.Material = Enum.Material.Metal
			newsShutter.Color = Color3.fromRGB(100, 100, 95)
			newsShutter.Parent = newsagent
			newsShutter:SetAttribute("CanForceOpen", true)
			newsShutter:SetAttribute("ForceOpenSoundRadius", 40)

			newsagent.Parent = room

			-- Vending machines
			Shared.createVendingMachine(concPos + Vector3.new(-3, 0, 10), 180, room, "VendingMachine_1")
			Shared.createVendingMachine(concPos + Vector3.new(3, 0, 10), 180, room, "VendingMachine_2")

			-- Public phone (interactable)
			local phone = Instance.new("Part")
			phone.Name = "PublicPhone"
			phone.Size = Vector3.new(1.5, 2.5, 1)
			phone.Position = concPos + Vector3.new(10, 4.5, 12)
			phone.Anchored = true
			phone.Material = Enum.Material.Metal
			phone.Color = Color3.fromRGB(120, 120, 115)
			phone.Parent = room

			local phonePrompt = Instance.new("ProximityPrompt")
			phonePrompt.ActionText = "Use Phone"
			phonePrompt.ObjectText = "Public Phone"
			phonePrompt.HoldDuration = 0.5
			phonePrompt.MaxActivationDistance = 6
			phonePrompt.Parent = phone
			phone:SetAttribute("SpecialNumber", "04731")

			-- Directional signage
			local sign = Instance.new("Part")
			sign.Name = "DeepTunnelSign"
			sign.Size = Vector3.new(5, 1, 0.1)
			sign.Position = concPos + Vector3.new(0, 8, 12.5)
			sign.Anchored = true
			sign.Material = Enum.Material.SmoothPlastic
			sign.Color = Color3.fromRGB(30, 80, 30)
			sign.Parent = room
			sign:SetAttribute("Text", "DEEP TUNNELS - NO ONE")

			-- Security gate (ripped apart from tunnel side)
			local secGate = Instance.new("Part")
			secGate.Name = "SecurityGate_Broken"
			secGate.Size = Vector3.new(6, 8, 0.5)
			secGate.Position = concPos + Vector3.new(0, 4, 13)
			secGate.Orientation = Vector3.new(0, 0, 5) -- slightly askew
			secGate.Anchored = true
			secGate.Material = Enum.Material.Metal
			secGate.Color = Color3.fromRGB(80, 80, 75)
			secGate.Parent = room
			secGate:SetAttribute("RippedOpen", true)

			-- Lighting (blue-white, breather space)
			Shared.createLight(concPos + Vector3.new(-8, TUNNEL_HEIGHT - 0.5, 0), room, 0.4, BLUE_WHITE_LIGHT)
			Shared.createLight(concPos + Vector3.new(8, TUNNEL_HEIGHT - 0.5, 0), room, 0.4, BLUE_WHITE_LIGHT)
			Shared.createLight(concPos + Vector3.new(0, TUNNEL_HEIGHT - 0.5, 0), room, 0.35, BLUE_WHITE_LIGHT)

			-- Waypoint
			table.insert(waypoints, {
				position = concPos + Vector3.new(0, 3, 0),
				roomId = "Moorfield_Concourse",
				dwellTime = 3,
			})

			-- Loot
			table.insert(lootPositions, {
				itemType = "Battery", position = concPos + Vector3.new(-12, 2, -11),
				chance = 0.5, guaranteed = false,
			})
			table.insert(lootPositions, {
				itemType = "Bandage", position = concPos + Vector3.new(12, 2, -11),
				chance = 1, guaranteed = true,
			})
		end

		stationModel.Parent = platformModel
	end

	--------------------------------------------------------------------
	-- =============== TERMINUS STATION (Extraction) ==================
	--------------------------------------------------------------------
	do
		local stationModel = Instance.new("Model")
		stationModel.Name = "TerminusStation"

		local tBase = Vector3.new(0, PLATFORM_Y, TERMINUS_Z_OFFSET)

		----------------------------------------------------------------
		-- Terminus Platform
		----------------------------------------------------------------
		do
			local platPos = tBase + Vector3.new(0, 0, 0)
			local platSize = Vector3.new(40, TUNNEL_HEIGHT, 15)

			local room = Shared.createRoom({
				position = platPos,
				size = platSize,
				parent = stationModel,
				name = "TerminusPlatform",
				wallColor = Color3.fromRGB(160, 160, 155),
				floorColor = Color3.fromRGB(130, 130, 125),
				floorMaterial = Enum.Material.Concrete,
				wallMaterial = Enum.Material.Concrete,
				noCeiling = true,
				doorways = {
					-- From drainage system (floor hatch area, west)
					{ wall = "west", offset = 0, width = 6, height = DOOR_HEIGHT },
					-- Emergency exit elevator (east)
					{ wall = "east", offset = -3, width = 4, height = DOOR_HEIGHT },
					-- Sealed Blackpoint door (east, offset)
					{ wall = "east", offset = 4, width = 6, height = 9 },
				},
			})

			-- Ceiling
			Shared.createCeiling(
				Vector3.new(platPos.X, PLATFORM_Y + TUNNEL_HEIGHT + 0.5, platPos.Z),
				Vector3.new(42, 1, 17),
				room, "TerminusCeiling"
			)

			-- Maintenance hatch in floor (entry from drainage)
			local hatch = Instance.new("Part")
			hatch.Name = "MaintenanceHatch"
			hatch.Size = Vector3.new(4, 0.3, 4)
			hatch.Position = platPos + Vector3.new(-15, 0.15, 0)
			hatch.Anchored = true
			hatch.Material = Enum.Material.Metal
			hatch.Color = Color3.fromRGB(80, 80, 75)
			hatch.Parent = room
			hatch:SetAttribute("DrainageEntry", true)

			-- Support pillars (2)
			for _, xOff in { -8, 8 } do
				local pillar = Instance.new("Part")
				pillar.Name = "SupportPillar"
				pillar.Size = Vector3.new(2, TUNNEL_HEIGHT, 2)
				pillar.Position = platPos + Vector3.new(xOff, TUNNEL_HEIGHT / 2, 0)
				pillar.Anchored = true
				pillar.Material = Enum.Material.Concrete
				pillar.Color = Color3.fromRGB(150, 150, 145)
				pillar.Parent = room
			end

			-- Bench
			Shared.createBench(platPos + Vector3.new(0, 0, -4), 0, room, "TerminusBench")

			-- Knocked-over vending machine
			local vendingKnocked = Instance.new("Part")
			vendingKnocked.Name = "KnockedVendingMachine"
			vendingKnocked.Size = Vector3.new(3.5, 7, 2.5)
			vendingKnocked.Position = platPos + Vector3.new(5, 1.25, 3)
			vendingKnocked.Orientation = Vector3.new(0, 15, 90)
			vendingKnocked.Anchored = true
			vendingKnocked.Material = Enum.Material.Metal
			vendingKnocked.Color = Color3.fromRGB(45, 60, 80)
			vendingKnocked.Parent = room

			-- Security cameras (dead)
			Shared.createSecurityCamera(platPos + Vector3.new(-15, TUNNEL_HEIGHT - 1, -7), 180, room, "SecurityCam_1")
			Shared.createSecurityCamera(platPos + Vector3.new(15, TUNNEL_HEIGHT - 1, -7), 180, room, "SecurityCam_2")

			-- Biometric scanners on walls (non-functional)
			for _, xOff in { -12, 12 } do
				local bioScan = Instance.new("Part")
				bioScan.Name = "BiometricScanner"
				bioScan.Size = Vector3.new(0.8, 1.2, 0.3)
				bioScan.Position = platPos + Vector3.new(xOff, 4, -7)
				bioScan.Anchored = true
				bioScan.Material = Enum.Material.SmoothPlastic
				bioScan.Color = Color3.fromRGB(30, 30, 28)
				bioScan.Parent = room
			end

			-- Electronic signage (garbled)
			local signage = Instance.new("Part")
			signage.Name = "ElectronicSign"
			signage.Size = Vector3.new(10, 1.5, 0.2)
			signage.Position = platPos + Vector3.new(0, TUNNEL_HEIGHT - 2, -7)
			signage.Anchored = true
			signage.Material = Enum.Material.Neon
			signage.Color = Color3.fromRGB(40, 80, 40)
			signage.Transparency = 0.4
			signage.Parent = room
			signage:SetAttribute("GarbledText", "BLACKPOINT TRANSIT CORRIDOR -- AUTHORIZED ACCESS ONLY")

			-- Ventilation grate (Crawler entry)
			local ventGrate = Instance.new("Part")
			ventGrate.Name = "VentGrate_Terminus"
			ventGrate.Size = Vector3.new(3, 3, 0.2)
			ventGrate.Position = platPos + Vector3.new(-5, 5, -7.4)
			ventGrate.Anchored = true
			ventGrate.Material = Enum.Material.Metal
			ventGrate.Color = Color3.fromRGB(90, 90, 85)
			ventGrate.Parent = room
			ventGrate:SetAttribute("CrawlerEntryPoint", true)

			-- Lighting (post-power: 40% fluorescent; pre-power: none)
			-- We place them but dimmed; power reroute script brightens them
			Shared.createLight(platPos + Vector3.new(-10, TUNNEL_HEIGHT - 0.5, 0), room, 0.08, FLUORESCENT_LIGHT)
			Shared.createLight(platPos + Vector3.new(10, TUNNEL_HEIGHT - 0.5, 0), room, 0.08, FLUORESCENT_LIGHT)
			Shared.createLight(platPos + Vector3.new(0, TUNNEL_HEIGHT - 0.5, 0), room, 0.08, FLUORESCENT_LIGHT)

			-- Waypoints
			table.insert(waypoints, {
				position = platPos + Vector3.new(0, 3, 0),
				roomId = "Terminus_Platform",
				dwellTime = 3,
			})

			-- Loot
			table.insert(lootPositions, {
				itemType = "Battery", position = platPos + Vector3.new(5, 2, 3),
				chance = 0.5, guaranteed = false,
			})
			table.insert(lootPositions, {
				itemType = "Bandage", position = platPos + Vector3.new(-5, 0.5, 2),
				chance = 0.3, guaranteed = false,
			})
		end

		----------------------------------------------------------------
		-- Emergency Exit (elevator + stairwell)
		----------------------------------------------------------------
		do
			local exitPos = tBase + Vector3.new(22, 0, -3)
			local exitSize = Vector3.new(10, TUNNEL_HEIGHT, 8)

			local room = Shared.createRoom({
				position = exitPos,
				size = exitSize,
				parent = stationModel,
				name = "EmergencyExit",
				wallColor = CONCRETE_COLOR,
				floorColor = Color3.fromRGB(85, 85, 80),
				doorways = {
					{ wall = "west", offset = 0, width = 4, height = DOOR_HEIGHT },
				},
			})

			-- Elevator shaft area
			local elevatorDoor = Instance.new("Part")
			elevatorDoor.Name = "ElevatorDoor"
			elevatorDoor.Size = Vector3.new(4, 8, 0.5)
			elevatorDoor.Position = exitPos + Vector3.new(0, 4, -3.5)
			elevatorDoor.Anchored = true
			elevatorDoor.Material = Enum.Material.Metal
			elevatorDoor.Color = Color3.fromRGB(90, 90, 85)
			elevatorDoor.Parent = room

			-- Elevator call button
			local callButton = Instance.new("Part")
			callButton.Name = "ElevatorCallButton"
			callButton.Size = Vector3.new(0.5, 0.5, 0.2)
			callButton.Position = exitPos + Vector3.new(2.5, 4, -3.4)
			callButton.Anchored = true
			callButton.Material = Enum.Material.Metal
			callButton.Color = Color3.fromRGB(60, 60, 55)
			callButton.Parent = room

			local callPrompt = Instance.new("ProximityPrompt")
			callPrompt.ActionText = "Call Elevator"
			callPrompt.ObjectText = "Service Elevator"
			callPrompt.HoldDuration = 1
			callPrompt.MaxActivationDistance = 6
			callPrompt.Parent = callButton
			callButton:SetAttribute("ExtractionTrigger", true)
			callButton:SetAttribute("ElevatorWaitTime", 15)

			-- Stairwell above (to surface)
			Shared.createStairwell(PLATFORM_Y, STREET_Y, exitPos + Vector3.new(0, 0, 0), room, "ExitStairwell")

			-- Fire door at top (mechanical push-bar)
			local fireDoor = Instance.new("Part")
			fireDoor.Name = "FireDoor"
			fireDoor.Size = Vector3.new(5, 8, 0.5)
			fireDoor.Position = Vector3.new(exitPos.X, STREET_Y + 4, exitPos.Z - 4)
			fireDoor.Anchored = true
			fireDoor.Material = Enum.Material.Metal
			fireDoor.Color = Color3.fromRGB(140, 50, 40)
			fireDoor.Parent = room

			local firePrompt = Instance.new("ProximityPrompt")
			firePrompt.ActionText = "Push Open"
			firePrompt.ObjectText = "Fire Exit"
			firePrompt.HoldDuration = 3
			firePrompt.MaxActivationDistance = 6
			firePrompt.Parent = fireDoor
			fireDoor:SetAttribute("OneWayExit", true)

			-- Minimal emergency light
			Shared.createEmergencyLight(exitPos + Vector3.new(0, ROOM_HEIGHT - 1, 0), room)

			-- Waypoint
			table.insert(waypoints, {
				position = exitPos + Vector3.new(0, 3, 0),
				roomId = "Terminus_EmergencyExit",
				dwellTime = 1,
			})
		end

		----------------------------------------------------------------
		-- Sealed Blackpoint Door
		----------------------------------------------------------------
		do
			local doorPos = tBase + Vector3.new(22, 0, 4)

			Shared.createSealedBlackpointDoor(doorPos, 0, stationModel, "BlackpointDoor")

			-- Dropped ID badge on floor
			local badge = Instance.new("Part")
			badge.Name = "DrVossIDBadge"
			badge.Size = Vector3.new(0.6, 0.02, 0.9)
			badge.Position = doorPos + Vector3.new(-1, 0.02, 2)
			badge.Orientation = Vector3.new(0, 25, 0)
			badge.Anchored = true
			badge.Material = Enum.Material.SmoothPlastic
			badge.Color = Color3.fromRGB(220, 215, 200)
			badge.Parent = stationModel

			local badgePrompt = Instance.new("ProximityPrompt")
			badgePrompt.ActionText = "Pick Up"
			badgePrompt.ObjectText = "Dr. Voss ID Badge"
			badgePrompt.HoldDuration = 0.5
			badgePrompt.MaxActivationDistance = 6
			badgePrompt.Parent = badge

			-- Loot (lore item)
			table.insert(lootPositions, {
				itemType = "Lore", position = doorPos + Vector3.new(-1, 0.5, 2),
				chance = 1, guaranteed = true,
			})
		end

		stationModel.Parent = platformModel
	end

	platformModel.Parent = parent

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return Platform
