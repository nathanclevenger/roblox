--!strict

--[[
	Forest/Clearing - Builds the Ranger Station compound (entry zone),
	parking lot, supply shed, watchtower, main office, garage, and
	the perimeter fencing.

	This is the player's spawn area and the extraction point. The compound
	is at the southern edge of Ashwood Forest with a cleared gravel lot,
	outbuildings, and a watchtower providing the first view of the forest.
]]

local Shared = require(script.Parent.Shared)

type HidingSpotData = Shared.HidingSpotData
type AreaData = Shared.AreaData

------------------------------------------------------------------------
-- Layout Constants
------------------------------------------------------------------------

local FLOOR_Y = 0
local STATION_CENTER = Vector3.new(0, FLOOR_Y, 250)

-- Building positions relative to station center
local OFFICE_POS = Vector3.new(-35, FLOOR_Y, 245)
local GARAGE_POS = Vector3.new(0, FLOOR_Y, 240)
local WATCHTOWER_POS = Vector3.new(35, FLOOR_Y, 235)
local SUPPLY_SHED_POS = Vector3.new(-30, FLOOR_Y, 265)
local PARKING_POS = Vector3.new(10, FLOOR_Y, 275)
local SPAWN_POS = Vector3.new(10, FLOOR_Y + 3, 280)

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local Clearing = {}

function Clearing.build(parent: Instance): AreaData
	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	local stationModel = Instance.new("Model")
	stationModel.Name = "RangerStation"

	Shared.resetSeed(54321)

	--------------------------------------------------------------------
	-- Gravel Ground
	--------------------------------------------------------------------
	do
		local groundModel = Instance.new("Model")
		groundModel.Name = "StationGround"

		-- Main gravel area
		local gravel = Instance.new("Part")
		gravel.Name = "GravelLot"
		gravel.Size = Vector3.new(100, 0.3, 80)
		gravel.Position = STATION_CENTER + Vector3.new(0, 0.15, 5)
		gravel.Anchored = true
		gravel.Material = Enum.Material.Ground
		gravel.Color = Shared.Colors.GRAVEL
		gravel.Parent = groundModel

		-- Parking lot (asphalt area)
		local parking = Instance.new("Part")
		parking.Name = "ParkingLot"
		parking.Size = Vector3.new(30, 0.2, 20)
		parking.Position = PARKING_POS + Vector3.new(0, 0.1, 0)
		parking.Anchored = true
		parking.Material = Enum.Material.Concrete
		parking.Color = Color3.fromRGB(70, 68, 62)
		parking.Parent = groundModel

		-- Faded parking lines
		for i = 0, 3 do
			local line = Instance.new("Part")
			line.Name = `ParkingLine_{i}`
			line.Size = Vector3.new(0.2, 0.02, 5)
			line.Position = PARKING_POS + Vector3.new(-10 + i * 6, 0.22, 0)
			line.Anchored = true
			line.Material = Enum.Material.SmoothPlastic
			line.Color = Color3.fromRGB(150, 148, 130)
			line.Transparency = 0.5
			line.Parent = groundModel
		end

		groundModel.Parent = stationModel
	end

	--------------------------------------------------------------------
	-- Spawn Location
	--------------------------------------------------------------------
	do
		local spawnLocation = Instance.new("SpawnLocation")
		spawnLocation.Name = "PlayerSpawn"
		spawnLocation.Size = Vector3.new(6, 1, 6)
		spawnLocation.Position = PARKING_POS + Vector3.new(0, -0.5, 5)
		spawnLocation.Anchored = true
		spawnLocation.Material = Enum.Material.Concrete
		spawnLocation.Color = Shared.Colors.GRAVEL
		spawnLocation.Enabled = true
		spawnLocation.Neutral = true
		spawnLocation.Parent = stationModel
	end

	--------------------------------------------------------------------
	-- Main Office (single-story wood building)
	--------------------------------------------------------------------
	do
		local officeCabin = Shared.createCabin({
			position = OFFICE_POS,
			size = Vector3.new(14, 10, 10),
			parent = stationModel,
			name = "MainOffice",
			hasDoor = true,
			windowWalls = { "north", "east", "west" },
		})

		-- Interior: desk with radio
		Shared.createWoodTable(OFFICE_POS + Vector3.new(-3, 0, -2), officeCabin, "RadioDesk")

		-- Radio unit on desk
		local radio = Instance.new("Part")
		radio.Name = "RadioUnit"
		radio.Size = Vector3.new(2, 1, 1.5)
		radio.Position = OFFICE_POS + Vector3.new(-3, 3.5, -2)
		radio.Anchored = true
		radio.Material = Enum.Material.Metal
		radio.Color = Color3.fromRGB(50, 55, 50)
		radio.Parent = officeCabin

		local radioPrompt = Instance.new("ProximityPrompt")
		radioPrompt.ActionText = "Examine"
		radioPrompt.ObjectText = "Radio (Dead)"
		radioPrompt.HoldDuration = 0.5
		radioPrompt.MaxActivationDistance = 8
		radioPrompt.Parent = radio

		-- Filing cabinets
		local cabinet = Instance.new("Part")
		cabinet.Name = "FilingCabinet"
		cabinet.Size = Vector3.new(2, 5, 1.5)
		cabinet.Position = OFFICE_POS + Vector3.new(4, 2.5, -3)
		cabinet.Anchored = true
		cabinet.Material = Enum.Material.Metal
		cabinet.Color = Color3.fromRGB(120, 118, 112)
		cabinet.Parent = officeCabin

		-- Wall map (interactable)
		local wallMap = Instance.new("Part")
		wallMap.Name = "WallMap"
		wallMap.Size = Vector3.new(4, 3, 0.1)
		wallMap.Position = OFFICE_POS + Vector3.new(0, 5, -5 + 0.5)
		wallMap.Anchored = true
		wallMap.Material = Enum.Material.SmoothPlastic
		wallMap.Color = Color3.fromRGB(200, 190, 160) -- faded paper
		wallMap.Parent = officeCabin

		local mapPrompt = Instance.new("ProximityPrompt")
		mapPrompt.ActionText = "Examine"
		mapPrompt.ObjectText = "Forest Map"
		mapPrompt.HoldDuration = 0.5
		mapPrompt.MaxActivationDistance = 8
		mapPrompt.Parent = wallMap

		-- Corkboard with missing-person flyers
		local corkboard = Instance.new("Part")
		corkboard.Name = "Corkboard"
		corkboard.Size = Vector3.new(3, 2, 0.2)
		corkboard.Position = OFFICE_POS + Vector3.new(4, 5.5, -5 + 0.5)
		corkboard.Anchored = true
		corkboard.Material = Enum.Material.Wood
		corkboard.Color = Color3.fromRGB(150, 120, 80)
		corkboard.Parent = officeCabin

		-- Desk lamp (dim, flickering)
		Shared.createInteriorLight(OFFICE_POS + Vector3.new(-3, 4.5, -2), officeCabin, 0.4, Color3.fromRGB(255, 220, 160))

		-- Second desk (dead computer)
		Shared.createWoodTable(OFFICE_POS + Vector3.new(3, 0, 1), officeCabin, "Desk2")

		local monitor = Instance.new("Part")
		monitor.Name = "DeadMonitor"
		monitor.Size = Vector3.new(2, 1.5, 0.3)
		monitor.Position = OFFICE_POS + Vector3.new(3, 4, 1)
		monitor.Anchored = true
		monitor.Material = Enum.Material.Glass
		monitor.Color = Color3.fromRGB(15, 18, 20) -- dead screen
		monitor.Parent = officeCabin

		-- Chair
		Shared.createWoodChair(OFFICE_POS + Vector3.new(-3, 0, 0), officeCabin, false, "OfficeChair")

		-- Waypoint
		table.insert(waypoints, {
			position = OFFICE_POS + Vector3.new(0, 3, 0),
			roomId = "MainOffice",
			dwellTime = 3,
		})

		-- Loot
		table.insert(lootPositions, {
			itemType = "Battery",
			position = OFFICE_POS + Vector3.new(-3, 3.3, -1),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Battery",
			position = OFFICE_POS + Vector3.new(4, 2, -3),
			chance = 0.5,
			guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Bandage",
			position = OFFICE_POS + Vector3.new(-5, 4, -4),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Flare",
			position = OFFICE_POS + Vector3.new(-3, 2, -2),
			chance = 0.4,
			guaranteed = false,
		})
	end

	--------------------------------------------------------------------
	-- Garage (extraction vehicle)
	--------------------------------------------------------------------
	do
		local garageModel = Instance.new("Model")
		garageModel.Name = "Garage"

		-- Structure: larger than cabin, open front (roll-up door jammed open)
		local garageFloor = Instance.new("Part")
		garageFloor.Name = "GarageFloor"
		garageFloor.Size = Vector3.new(16, 0.5, 12)
		garageFloor.Position = GARAGE_POS + Vector3.new(0, -0.25, 0)
		garageFloor.Anchored = true
		garageFloor.Material = Enum.Material.Concrete
		garageFloor.Color = Color3.fromRGB(85, 82, 78)
		garageFloor.Parent = garageModel

		-- Back wall
		local backWall = Instance.new("Part")
		backWall.Name = "BackWall"
		backWall.Size = Vector3.new(16, 10, 1)
		backWall.Position = GARAGE_POS + Vector3.new(0, 5, -6.5)
		backWall.Anchored = true
		backWall.Material = Enum.Material.Wood
		backWall.Color = Shared.Colors.WOOD_PLANK
		backWall.Parent = garageModel

		-- Side walls
		for i, side in { -1, 1 } do
			local sideWall = Instance.new("Part")
			sideWall.Name = `SideWall_{i}`
			sideWall.Size = Vector3.new(1, 10, 12)
			sideWall.Position = GARAGE_POS + Vector3.new(side * 8.5, 5, 0)
			sideWall.Anchored = true
			sideWall.Material = Enum.Material.Wood
			sideWall.Color = Shared.Colors.WOOD_PLANK
			sideWall.Parent = garageModel
		end

		-- Roof
		local roof = Instance.new("Part")
		roof.Name = "GarageRoof"
		roof.Size = Vector3.new(18, 0.5, 14)
		roof.Position = GARAGE_POS + Vector3.new(0, 10.25, 0)
		roof.Anchored = true
		roof.Material = Enum.Material.Metal
		roof.Color = Color3.fromRGB(65, 62, 58)
		roof.Parent = garageModel

		-- Roll-up door frame (jammed open — no solid door part)
		local doorFrame = Instance.new("Part")
		doorFrame.Name = "DoorFrame"
		doorFrame.Size = Vector3.new(10, 1, 1)
		doorFrame.Position = GARAGE_POS + Vector3.new(0, 9.5, 6.5)
		doorFrame.Anchored = true
		doorFrame.Material = Enum.Material.Metal
		doorFrame.Color = Color3.fromRGB(75, 72, 68)
		doorFrame.Parent = garageModel

		-- Forest service pickup truck
		local truckModel = Instance.new("Model")
		truckModel.Name = "ExtractionVehicle"

		-- Truck body
		local truckBody = Instance.new("Part")
		truckBody.Name = "Body"
		truckBody.Size = Vector3.new(6, 4, 12)
		truckBody.Position = GARAGE_POS + Vector3.new(0, 2, -1)
		truckBody.Anchored = true
		truckBody.Material = Enum.Material.SmoothPlastic
		truckBody.Color = Color3.fromRGB(50, 80, 45) -- forest green
		truckBody.Parent = truckModel

		-- Truck cab
		local truckCab = Instance.new("Part")
		truckCab.Name = "Cab"
		truckCab.Size = Vector3.new(6, 3, 5)
		truckCab.Position = GARAGE_POS + Vector3.new(0, 2, 3)
		truckCab.Anchored = true
		truckCab.Material = Enum.Material.SmoothPlastic
		truckCab.Color = Color3.fromRGB(50, 80, 45)
		truckCab.Parent = truckModel

		-- Windshield
		local windshield = Instance.new("Part")
		windshield.Name = "Windshield"
		windshield.Size = Vector3.new(5.5, 2.5, 0.1)
		windshield.Position = GARAGE_POS + Vector3.new(0, 3, 5.5)
		windshield.Orientation = Vector3.new(-15, 0, 0)
		windshield.Anchored = true
		windshield.Material = Enum.Material.Glass
		windshield.Color = Color3.fromRGB(100, 110, 120)
		windshield.Transparency = 0.4
		windshield.Parent = truckModel

		-- Wheels
		for _, offset in {
			Vector3.new(-3, 0.8, -4),
			Vector3.new(3, 0.8, -4),
			Vector3.new(-3, 0.8, 3),
			Vector3.new(3, 0.8, 3),
		} do
			local wheel = Instance.new("Part")
			wheel.Name = "Wheel"
			wheel.Shape = Enum.PartType.Cylinder
			wheel.Size = Vector3.new(1, 1.6, 1.6)
			wheel.Position = GARAGE_POS + offset + Vector3.new(0, 0, -1)
			wheel.Anchored = true
			wheel.Material = Enum.Material.SmoothPlastic
			wheel.Color = Color3.fromRGB(25, 25, 25)
			wheel.Parent = truckModel
		end

		-- Headlights (off)
		for _, side in { -2.5, 2.5 } do
			local headlight = Instance.new("Part")
			headlight.Name = "Headlight"
			headlight.Shape = Enum.PartType.Cylinder
			headlight.Size = Vector3.new(0.3, 1, 1)
			headlight.CFrame = CFrame.new(GARAGE_POS + Vector3.new(side, 2, 5.5))
				* CFrame.Angles(0, math.rad(90), 0)
			headlight.Anchored = true
			headlight.Material = Enum.Material.Glass
			headlight.Color = Color3.fromRGB(200, 200, 180)
			headlight.Parent = truckModel
		end

		-- Fuel interaction
		local fuelPort = Instance.new("Part")
		fuelPort.Name = "FuelPort"
		fuelPort.Size = Vector3.new(1, 1, 1)
		fuelPort.Position = GARAGE_POS + Vector3.new(3.5, 1.5, 0)
		fuelPort.Anchored = true
		fuelPort.Transparency = 1
		fuelPort.CanCollide = false
		fuelPort.Parent = truckModel

		local fuelPrompt = Instance.new("ProximityPrompt")
		fuelPrompt.ActionText = "Fuel Vehicle"
		fuelPrompt.ObjectText = "Fuel Port"
		fuelPrompt.HoldDuration = 8 -- 8-second interaction
		fuelPrompt.MaxActivationDistance = 6
		fuelPrompt.Enabled = false -- Enabled when player has fuel canister
		fuelPrompt.Parent = fuelPort

		truckModel.Parent = garageModel

		-- Workbench
		local workbench = Instance.new("Part")
		workbench.Name = "Workbench"
		workbench.Size = Vector3.new(6, 3, 2)
		workbench.Position = GARAGE_POS + Vector3.new(-5, 1.5, -5)
		workbench.Anchored = true
		workbench.Material = Enum.Material.Wood
		workbench.Color = Shared.Colors.WOOD_DARK
		workbench.Parent = garageModel

		-- Empty fuel canisters on workbench
		for i = 1, 2 do
			local canister = Instance.new("Part")
			canister.Name = `EmptyCanister_{i}`
			canister.Size = Vector3.new(0.8, 1.2, 0.5)
			canister.Position = GARAGE_POS + Vector3.new(-5 + i * 1.5, 3.6, -5)
			canister.Anchored = true
			canister.Material = Enum.Material.Metal
			canister.Color = Color3.fromRGB(160, 40, 40) -- red fuel canister
			canister.Parent = garageModel
		end

		-- Interior light
		Shared.createInteriorLight(GARAGE_POS + Vector3.new(0, 9, 0), garageModel, 0.2)

		-- Waypoint
		table.insert(waypoints, {
			position = GARAGE_POS + Vector3.new(0, 3, 0),
			roomId = "Garage",
			dwellTime = 3,
		})

		-- Loot
		table.insert(lootPositions, {
			itemType = "Battery",
			position = GARAGE_POS + Vector3.new(-5, 3.5, -5),
			chance = 0.6,
			guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Bandage",
			position = GARAGE_POS + Vector3.new(-7, 4, -5),
			chance = 0.4,
			guaranteed = false,
		})

		garageModel.Parent = stationModel
	end

	--------------------------------------------------------------------
	-- Watchtower
	--------------------------------------------------------------------
	do
		Shared.createWatchtower(WATCHTOWER_POS, stationModel, "StationWatchtower")

		-- Binoculars on platform
		local binoculars = Instance.new("Part")
		binoculars.Name = "Binoculars"
		binoculars.Size = Vector3.new(1, 0.8, 0.4)
		binoculars.Position = WATCHTOWER_POS + Vector3.new(0, 41.5, -4)
		binoculars.Anchored = true
		binoculars.Material = Enum.Material.Metal
		binoculars.Color = Color3.fromRGB(40, 40, 38)
		binoculars.Parent = stationModel

		local binoPrompt = Instance.new("ProximityPrompt")
		binoPrompt.ActionText = "Look"
		binoPrompt.ObjectText = "Binoculars"
		binoPrompt.HoldDuration = 0.5
		binoPrompt.MaxActivationDistance = 6
		binoPrompt.Parent = binoculars

		-- Emergency kit on platform
		local emergKit = Instance.new("Part")
		emergKit.Name = "EmergencyKit"
		emergKit.Size = Vector3.new(1.5, 0.8, 1)
		emergKit.Position = WATCHTOWER_POS + Vector3.new(3, 40.4, 3)
		emergKit.Anchored = true
		emergKit.Material = Enum.Material.Metal
		emergKit.Color = Color3.fromRGB(180, 40, 40) -- red emergency kit
		emergKit.Parent = stationModel

		-- Watchtower loot
		table.insert(lootPositions, {
			itemType = "Battery",
			position = WATCHTOWER_POS + Vector3.new(3, 40.5, 3),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Flare",
			position = WATCHTOWER_POS + Vector3.new(-3, 40.5, 3),
			chance = 0.6,
			guaranteed = false,
		})

		-- Waypoint at platform
		table.insert(waypoints, {
			position = WATCHTOWER_POS + Vector3.new(0, 43, 0),
			roomId = "Watchtower",
			dwellTime = 5,
		})
	end

	--------------------------------------------------------------------
	-- Supply Shed (first Watcher encounter)
	--------------------------------------------------------------------
	do
		local shed = Shared.createCabin({
			position = SUPPLY_SHED_POS,
			size = Vector3.new(8, 8, 6),
			parent = stationModel,
			name = "SupplyShed",
			hasDoor = true,
			windowWalls = { "east" },
		})

		-- Shelving
		Shared.createShelf(SUPPLY_SHED_POS + Vector3.new(-2, 0, -1.5), shed, "ShelfA")
		Shared.createShelf(SUPPLY_SHED_POS + Vector3.new(2, 0, -1.5), shed, "ShelfB")

		-- Workbench
		local workbench = Instance.new("Part")
		workbench.Name = "ShedWorkbench"
		workbench.Size = Vector3.new(4, 3, 1.5)
		workbench.Position = SUPPLY_SHED_POS + Vector3.new(0, 1.5, 2)
		workbench.Anchored = true
		workbench.Material = Enum.Material.Wood
		workbench.Color = Shared.Colors.WOOD_DARK
		workbench.Parent = shed

		-- Watcher spawn marker (tutorial Watcher stands in back corner)
		local watcherSpawn = Instance.new("Part")
		watcherSpawn.Name = "TutorialWatcherSpawn"
		watcherSpawn.Size = Vector3.new(2, 8, 2)
		watcherSpawn.Position = SUPPLY_SHED_POS + Vector3.new(2, 4, -2)
		watcherSpawn.Anchored = true
		watcherSpawn.Transparency = 1
		watcherSpawn.CanCollide = false
		watcherSpawn.Parent = shed

		watcherSpawn:SetAttribute("WatcherSpawn", true)
		watcherSpawn:SetAttribute("WatcherType", "Tutorial")

		-- Loot
		table.insert(lootPositions, {
			itemType = "Battery",
			position = SUPPLY_SHED_POS + Vector3.new(-2, 2, -1.5),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Battery",
			position = SUPPLY_SHED_POS + Vector3.new(2, 2, -1.5),
			chance = 0.6,
			guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Bandage",
			position = SUPPLY_SHED_POS + Vector3.new(-2, 3.6, -1.5),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Bandage",
			position = SUPPLY_SHED_POS + Vector3.new(0, 3.3, 2),
			chance = 0.5,
			guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Flare",
			position = SUPPLY_SHED_POS + Vector3.new(2, 3.6, -1.5),
			chance = 1,
			guaranteed = true, -- tutorial mercy
		})

		-- Waypoint
		table.insert(waypoints, {
			position = SUPPLY_SHED_POS + Vector3.new(0, 3, 0),
			roomId = "SupplyShed",
			dwellTime = 2,
		})
	end

	--------------------------------------------------------------------
	-- Perimeter Fence (low wooden fence around compound)
	--------------------------------------------------------------------
	do
		local fenceModel = Instance.new("Model")
		fenceModel.Name = "PerimeterFence"

		-- Fence corners (compound roughly 100x80)
		local fenceCorners = {
			Vector3.new(-50, FLOOR_Y, 210),
			Vector3.new(50, FLOOR_Y, 210),
			Vector3.new(50, FLOOR_Y, 290),
			Vector3.new(-50, FLOOR_Y, 290),
		}

		for i = 1, #fenceCorners do
			local nextI = (i % #fenceCorners) + 1
			-- Leave a gap on the north side (trail entrance) and south (road exit)
			local start = fenceCorners[i]
			local finish = fenceCorners[nextI]

			-- Skip south side center (parking lot entrance) and north center (trail)
			if i == 1 then
				-- North fence, leave gap in center
				Shared.createFenceSegment(start, Vector3.new(-10, FLOOR_Y, 210), fenceModel, `Fence_{i}_L`)
				Shared.createFenceSegment(Vector3.new(10, FLOOR_Y, 210), finish, fenceModel, `Fence_{i}_R`)
			elseif i == 3 then
				-- South fence, leave gap for road
				Shared.createFenceSegment(start, Vector3.new(20, FLOOR_Y, 290), fenceModel, `Fence_{i}_L`)
				Shared.createFenceSegment(Vector3.new(-10, FLOOR_Y, 290), finish, fenceModel, `Fence_{i}_R`)
			else
				Shared.createFenceSegment(start, finish, fenceModel, `Fence_{i}`)
			end
		end

		-- Entrance sign
		local sign = Instance.new("Part")
		sign.Name = "EntranceSign"
		sign.Size = Vector3.new(8, 2, 0.3)
		sign.Position = Vector3.new(0, FLOOR_Y + 5, 210)
		sign.Anchored = true
		sign.Material = Enum.Material.Wood
		sign.Color = Color3.fromRGB(90, 65, 42)
		sign.Parent = fenceModel

		-- Sign text (SurfaceGui with TextLabel)
		local signGui = Instance.new("SurfaceGui")
		signGui.Name = "SignGui"
		signGui.Face = Enum.NormalId.Front
		signGui.Parent = sign

		local signText = Instance.new("TextLabel")
		signText.Name = "SignText"
		signText.Size = UDim2.new(1, 0, 1, 0)
		signText.BackgroundTransparency = 1
		signText.Text = "ASHWOOD RANGER STATION"
		signText.TextColor3 = Color3.fromRGB(200, 180, 140)
		signText.TextScaled = true
		signText.Font = Enum.Font.Antique
		signText.Parent = signGui

		fenceModel.Parent = stationModel
	end

	--------------------------------------------------------------------
	-- Forest Road (exit route, heading south)
	--------------------------------------------------------------------
	do
		local roadModel = Instance.new("Model")
		roadModel.Name = "ForestRoad"

		-- Road surface extending south from compound
		for i = 0, 5 do
			local roadSeg = Instance.new("Part")
			roadSeg.Name = `RoadSegment_{i}`
			roadSeg.Size = Vector3.new(8, 0.2, 30)
			roadSeg.Position = Vector3.new(5, FLOOR_Y + 0.1, 295 + i * 30)
			roadSeg.Anchored = true
			roadSeg.Material = Enum.Material.Ground
			roadSeg.Color = Color3.fromRGB(65, 60, 50) -- dirt road
			roadSeg.Parent = roadModel
		end

		-- Trees lining the road (for extraction driving sequence)
		for i = 1, 12 do
			local side = if i % 2 == 0 then 1 else -1
			local zPos = 300 + (i - 1) * 15
			Shared.createTree(
				Vector3.new(5 + side * 10, FLOOR_Y, zPos),
				"pine",
				roadModel,
				0.8 + math.random() * 0.4
			)
		end

		roadModel.Parent = stationModel
	end

	--------------------------------------------------------------------
	-- Ambient Lighting (warm interior, cold exterior)
	--------------------------------------------------------------------
	do
		-- Exterior station lights (dim, security-style)
		Shared.createMoonlight(STATION_CENTER + Vector3.new(0, 15, 0), stationModel, 0.15, 60)

		-- Slightly warmer light near office
		Shared.createInteriorLight(
			OFFICE_POS + Vector3.new(0, 8, 4),
			stationModel,
			0.2,
			Color3.fromRGB(255, 230, 180)
		)
	end

	stationModel.Parent = parent

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return Clearing
