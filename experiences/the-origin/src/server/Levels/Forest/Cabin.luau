--!strict

--[[
	Forest/Cabin - Builds the Cabin Cluster (three cabins + root cellar)
	and the Radio Tower bunker on the Ridge.

	Cabin A (Researcher's) — Vasik's workspace, wall-pinned research, root cellar access
	Cabin B (Hunter's) — Fuel canister, trapping supplies, warm stove
	Cabin C (Collapsed) — Partially destroyed, trapped Watcher set piece
	Root Cellar — Underground safe room beneath Cabin A
	Radio Tower Bunker — Critical objective: power the transmitter
]]

local Shared = require(script.Parent.Shared)

type HidingSpotData = Shared.HidingSpotData
type AreaData = Shared.AreaData

------------------------------------------------------------------------
-- Layout Constants
------------------------------------------------------------------------

local FLOOR_Y = 0
local CABIN_CLUSTER_Z = -100

-- Cabins arranged in rough triangle, 30-40 studs apart
local CABIN_A_POS = Vector3.new(-30, FLOOR_Y, CABIN_CLUSTER_Z - 10) -- west
local CABIN_B_POS = Vector3.new(20, FLOOR_Y, CABIN_CLUSTER_Z - 15) -- east
local CABIN_C_POS = Vector3.new(0, FLOOR_Y, CABIN_CLUSTER_Z + 20) -- south

-- Root cellar beneath Cabin A
local CELLAR_POS = Vector3.new(-30, FLOOR_Y - 10, CABIN_CLUSTER_Z - 10)

-- Radio Tower / Bunker on the Ridge
local RIDGE_Y = 20 -- elevated terrain
local RADIO_TOWER_POS = Vector3.new(15, RIDGE_Y, -290)
local BUNKER_POS = Vector3.new(15, RIDGE_Y, -285)
local CLIFF_EDGE_POS = Vector3.new(10, RIDGE_Y - 2, -260)

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local Cabin = {}

function Cabin.build(parent: Instance): AreaData
	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	local cabinModel = Instance.new("Model")
	cabinModel.Name = "CabinCluster"

	Shared.resetSeed(67890)

	--------------------------------------------------------------------
	-- Cabin Cluster Common Area
	--------------------------------------------------------------------
	do
		local clusterModel = Instance.new("Model")
		clusterModel.Name = "ClusterCommon"

		-- Cleared area ground
		local clearing = Instance.new("Part")
		clearing.Name = "CabinClearing"
		clearing.Size = Vector3.new(80, 0.2, 60)
		clearing.Position = Vector3.new(0, FLOOR_Y + 0.1, CABIN_CLUSTER_Z)
		clearing.Anchored = true
		clearing.Material = Enum.Material.Ground
		clearing.Color = Color3.fromRGB(50, 45, 38)
		clearing.Parent = clusterModel

		-- Footpaths connecting cabins (narrow dirt)
		local pathWidth = 3
		local pathSegments = {
			-- A to B
			{ from = CABIN_A_POS + Vector3.new(5, 0, 0), to = CABIN_B_POS + Vector3.new(-5, 0, 0) },
			-- B to C
			{ from = CABIN_B_POS + Vector3.new(0, 0, 5), to = CABIN_C_POS + Vector3.new(5, 0, -5) },
			-- C to A
			{ from = CABIN_C_POS + Vector3.new(-5, 0, -5), to = CABIN_A_POS + Vector3.new(0, 0, 5) },
		}

		for i, seg in pathSegments do
			local diff = seg.to - seg.from
			local length = diff.Magnitude
			local center = (seg.from + seg.to) / 2
			local angle = math.deg(math.atan2(diff.X, diff.Z))

			local path = Instance.new("Part")
			path.Name = `FootPath_{i}`
			path.Size = Vector3.new(pathWidth, 0.12, length)
			path.CFrame = CFrame.new(center + Vector3.new(0, 0.06, 0))
				* CFrame.Angles(0, math.rad(angle), 0)
			path.Anchored = true
			path.Material = Enum.Material.Ground
			path.Color = Shared.Colors.TRAIL
			path.Parent = clusterModel
		end

		-- Wooden sign at entrance
		local signPost = Instance.new("Part")
		signPost.Name = "SignPost"
		signPost.Size = Vector3.new(0.4, 5, 0.4)
		signPost.Position = Vector3.new(0, FLOOR_Y + 2.5, CABIN_CLUSTER_Z + 35)
		signPost.Anchored = true
		signPost.Material = Enum.Material.Wood
		signPost.Color = Shared.Colors.WOOD_DARK
		signPost.Parent = clusterModel

		local signBoard = Instance.new("Part")
		signBoard.Name = "SignBoard"
		signBoard.Size = Vector3.new(6, 1.5, 0.3)
		signBoard.Position = Vector3.new(0, FLOOR_Y + 5, CABIN_CLUSTER_Z + 35)
		signBoard.Anchored = true
		signBoard.Material = Enum.Material.Wood
		signBoard.Color = Color3.fromRGB(80, 58, 38)
		signBoard.Parent = clusterModel

		-- Sign text
		local signGui = Instance.new("SurfaceGui")
		signGui.Face = Enum.NormalId.Front
		signGui.Parent = signBoard

		local signText = Instance.new("TextLabel")
		signText.Size = UDim2.new(1, 0, 1, 0)
		signText.BackgroundTransparency = 1
		signText.Text = "ASHWOOD CABINS"
		signText.TextColor3 = Color3.fromRGB(180, 160, 120)
		signText.TextScaled = true
		signText.Font = Enum.Font.Antique
		signText.Parent = signGui

		-- Moonlight for cluster
		Shared.createMoonlight(Vector3.new(0, 25, CABIN_CLUSTER_Z), clusterModel, 0.12, 45)

		clusterModel.Parent = cabinModel
	end

	--------------------------------------------------------------------
	-- Cabin A — Researcher's Cabin (Vasik's workspace)
	--------------------------------------------------------------------
	do
		local cabinA = Shared.createCabin({
			position = CABIN_A_POS,
			size = Vector3.new(12, 10, 10),
			parent = cabinModel,
			name = "CabinA_Research",
			hasDoor = true,
			windowWalls = { "south", "east" },
		})

		-- Desk (Vasik's research station)
		Shared.createWoodTable(CABIN_A_POS + Vector3.new(-3, 0, -2), cabinA, "VasikDesk")

		-- Chair
		Shared.createWoodChair(CABIN_A_POS + Vector3.new(-3, 0, 0), cabinA, false, "VasikChair")

		-- Cot
		Shared.createCot(CABIN_A_POS + Vector3.new(3, 0, -3), cabinA, "VasikCot")

		-- Shelf with research materials
		Shared.createShelf(CABIN_A_POS + Vector3.new(-5, 0, 0), cabinA, "ResearchShelf")

		-- Wood-burning stove (cold)
		Shared.createWoodStove(CABIN_A_POS + Vector3.new(4, 0, 3), cabinA, false, "CabinA_Stove")

		-- Wall-pinned research papers (flat parts covering walls)
		for wall = 1, 3 do
			local papers = Instance.new("Part")
			papers.Name = `ResearchPapers_{wall}`
			papers.Size = Vector3.new(if wall <= 2 then 8 else 0.1, 4, if wall <= 2 then 0.1 else 6)

			if wall == 1 then -- North wall
				papers.Position = CABIN_A_POS + Vector3.new(0, 5.5, -4.5)
			elseif wall == 2 then -- West wall (partial)
				papers.Position = CABIN_A_POS + Vector3.new(0, 5.5, 4.5)
			else -- East wall internal
				papers.Position = CABIN_A_POS + Vector3.new(-5.5, 5.5, 0)
			end

			papers.Anchored = true
			papers.Material = Enum.Material.SmoothPlastic
			papers.Color = Color3.fromRGB(210, 200, 175) -- aged paper
			papers.Transparency = 0.2
			papers.CanCollide = false
			papers.Parent = cabinA
		end

		-- String connecting pins (thin red line)
		local string = Instance.new("Part")
		string.Name = "StringWeb"
		string.Size = Vector3.new(6, 0.05, 4)
		string.Position = CABIN_A_POS + Vector3.new(0, 6, 0)
		string.Anchored = true
		string.Material = Enum.Material.Fabric
		string.Color = Color3.fromRGB(160, 40, 40)
		string.Transparency = 0.4
		string.CanCollide = false
		string.Parent = cabinA

		-- Floor hatch to root cellar
		local hatch = Instance.new("Part")
		hatch.Name = "CellarHatch"
		hatch.Size = Vector3.new(3, 0.3, 3)
		hatch.Position = CABIN_A_POS + Vector3.new(3, 0.15, 0)
		hatch.Anchored = true
		hatch.Material = Enum.Material.Wood
		hatch.Color = Color3.fromRGB(60, 45, 32)
		hatch.Parent = cabinA

		local hatchPrompt = Instance.new("ProximityPrompt")
		hatchPrompt.ActionText = "Descend"
		hatchPrompt.ObjectText = "Root Cellar"
		hatchPrompt.HoldDuration = 1
		hatchPrompt.MaxActivationDistance = 6
		hatchPrompt.Parent = hatch

		-- Desk lamp (dim)
		Shared.createInteriorLight(CABIN_A_POS + Vector3.new(-3, 4, -2), cabinA, 0.3)

		-- Hiding spot (inside cabin, behind desk)
		local _, cabinAHide = Shared.createHidingSpot(
			CABIN_A_POS + Vector3.new(-4, 1, -3),
			"InCabin",
			"CabinA_Hide",
			cabinA
		)
		table.insert(hidingSpots, cabinAHide)

		-- Waypoint
		table.insert(waypoints, {
			position = CABIN_A_POS + Vector3.new(0, 3, 0),
			roomId = "CabinA",
			dwellTime = 4,
		})

		-- Loot
		table.insert(lootPositions, {
			itemType = "Battery",
			position = CABIN_A_POS + Vector3.new(-3, 3.3, -1),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Battery",
			position = CABIN_A_POS + Vector3.new(-5, 2, 0),
			chance = 0.5,
			guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Bandage",
			position = CABIN_A_POS + Vector3.new(5, 2, 4),
			chance = 0.6,
			guaranteed = false,
		})
	end

	--------------------------------------------------------------------
	-- Root Cellar (beneath Cabin A)
	--------------------------------------------------------------------
	do
		local cellarModel = Instance.new("Model")
		cellarModel.Name = "RootCellar"

		-- Earth walls (box room)
		local cellarSize = Vector3.new(15, 10, 15)
		local cellarCenter = CELLAR_POS

		-- Floor
		local cellarFloor = Instance.new("Part")
		cellarFloor.Name = "CellarFloor"
		cellarFloor.Size = Vector3.new(cellarSize.X, 0.5, cellarSize.Z)
		cellarFloor.Position = cellarCenter + Vector3.new(0, -cellarSize.Y / 2 - 0.25, 0)
		cellarFloor.Anchored = true
		cellarFloor.Material = Enum.Material.Ground
		cellarFloor.Color = Color3.fromRGB(50, 42, 35) -- packed earth
		cellarFloor.Parent = cellarModel

		-- Earth walls
		local wallData = {
			{ name = "North", pos = Vector3.new(0, 0, -cellarSize.Z / 2 - 0.5), size = Vector3.new(cellarSize.X, cellarSize.Y, 1) },
			{ name = "South", pos = Vector3.new(0, 0, cellarSize.Z / 2 + 0.5), size = Vector3.new(cellarSize.X, cellarSize.Y, 1) },
			{ name = "West", pos = Vector3.new(-cellarSize.X / 2 - 0.5, 0, 0), size = Vector3.new(1, cellarSize.Y, cellarSize.Z) },
			{ name = "East", pos = Vector3.new(cellarSize.X / 2 + 0.5, 0, 0), size = Vector3.new(1, cellarSize.Y, cellarSize.Z) },
		}

		for _, wd in wallData do
			local wall = Instance.new("Part")
			wall.Name = `CellarWall_{wd.name}`
			wall.Size = wd.size
			wall.Position = cellarCenter + wd.pos
			wall.Anchored = true
			wall.Material = Enum.Material.Ground
			wall.Color = Color3.fromRGB(55, 45, 38) -- damp earth
			wall.Parent = cellarModel
		end

		-- Ceiling
		local cellarCeiling = Instance.new("Part")
		cellarCeiling.Name = "CellarCeiling"
		cellarCeiling.Size = Vector3.new(cellarSize.X + 2, 1, cellarSize.Z + 2)
		cellarCeiling.Position = cellarCenter + Vector3.new(0, cellarSize.Y / 2 + 0.5, 0)
		cellarCeiling.Anchored = true
		cellarCeiling.Material = Enum.Material.Ground
		cellarCeiling.Color = Color3.fromRGB(50, 42, 35)
		cellarCeiling.Parent = cellarModel

		-- Ladder (wooden, connects to hatch above)
		local ladder = Instance.new("Part")
		ladder.Name = "CellarLadder"
		ladder.Size = Vector3.new(2, cellarSize.Y, 0.3)
		ladder.Position = cellarCenter + Vector3.new(3, 0, 0)
		ladder.Anchored = true
		ladder.Material = Enum.Material.Wood
		ladder.Color = Shared.Colors.WOOD_DARK
		ladder.Parent = cellarModel

		-- Ladder rungs
		for r = 1, math.floor(cellarSize.Y / 1.5) do
			local rung = Instance.new("Part")
			rung.Name = `LadderRung_{r}`
			rung.Size = Vector3.new(2, 0.2, 0.3)
			rung.Position = cellarCenter + Vector3.new(3, -cellarSize.Y / 2 + r * 1.5, 0)
			rung.Anchored = true
			rung.Material = Enum.Material.Wood
			rung.Color = Shared.Colors.WOOD_PLANK
			rung.Parent = cellarModel
		end

		local ascendPrompt = Instance.new("ProximityPrompt")
		ascendPrompt.ActionText = "Climb Up"
		ascendPrompt.ObjectText = "Ladder"
		ascendPrompt.HoldDuration = 3 -- 3-second committed animation
		ascendPrompt.MaxActivationDistance = 6
		ascendPrompt.Parent = ladder

		-- Root systems through walls (decorative)
		for i = 1, 5 do
			local root = Instance.new("Part")
			root.Name = `Root_{i}`
			root.Shape = Enum.PartType.Cylinder
			root.Size = Vector3.new(math.random(3, 6), 0.3, 0.3)
			root.Position = cellarCenter + Vector3.new(
				math.random(-6, 6),
				math.random(-3, 3),
				math.random(-6, 6)
			)
			root.Orientation = Vector3.new(math.random(-20, 20), math.random(0, 180), math.random(-30, 30))
			root.Anchored = true
			root.Material = Enum.Material.Wood
			root.Color = Color3.fromRGB(40, 32, 22)
			root.Parent = cellarModel
		end

		-- Shelving with supplies
		Shared.createShelf(cellarCenter + Vector3.new(-5, -cellarSize.Y / 2, -5), cellarModel, "CellarShelf")

		-- Cot (rest point)
		local cellarCot = Shared.createCot(cellarCenter + Vector3.new(0, -cellarSize.Y / 2, 3), cellarModel, "CellarCot")

		local restPrompt = Instance.new("ProximityPrompt")
		restPrompt.ActionText = "Rest"
		restPrompt.ObjectText = "Cot"
		restPrompt.HoldDuration = 2
		restPrompt.MaxActivationDistance = 6
		restPrompt.Parent = cellarCot

		-- Battery-powered lantern
		local lantern = Instance.new("Part")
		lantern.Name = "CellarLantern"
		lantern.Size = Vector3.new(0.6, 0.8, 0.6)
		lantern.Position = cellarCenter + Vector3.new(-5, -cellarSize.Y / 2 + 4, -5)
		lantern.Anchored = true
		lantern.Material = Enum.Material.Metal
		lantern.Color = Color3.fromRGB(150, 140, 120)
		lantern.Parent = cellarModel

		local lanternLight = Instance.new("PointLight")
		lanternLight.Brightness = 0.2
		lanternLight.Color = Color3.fromRGB(255, 220, 160)
		lanternLight.Range = 12
		lanternLight.Parent = lantern

		-- Tape recorder (Vasik's audio log)
		local recorder = Instance.new("Part")
		recorder.Name = "TapeRecorder"
		recorder.Size = Vector3.new(0.8, 0.3, 1.2)
		recorder.Position = cellarCenter + Vector3.new(0, -cellarSize.Y / 2 + 1.5, 3)
		recorder.Anchored = true
		recorder.Material = Enum.Material.Metal
		recorder.Color = Color3.fromRGB(60, 55, 50)
		recorder.Parent = cellarModel

		local recorderPrompt = Instance.new("ProximityPrompt")
		recorderPrompt.ActionText = "Play"
		recorderPrompt.ObjectText = "Tape Recorder"
		recorderPrompt.HoldDuration = 0.5
		recorderPrompt.MaxActivationDistance = 6
		recorderPrompt.Parent = recorder

		-- Safe zone marker
		local cellarSafeZone = Instance.new("Part")
		cellarSafeZone.Name = "CellarSafeZone"
		cellarSafeZone.Size = Vector3.new(cellarSize.X, cellarSize.Y, cellarSize.Z)
		cellarSafeZone.Position = cellarCenter
		cellarSafeZone.Anchored = true
		cellarSafeZone.Transparency = 1
		cellarSafeZone.CanCollide = false
		cellarSafeZone.Parent = cellarModel

		cellarSafeZone:SetAttribute("IsSafeZone", true)
		cellarSafeZone:SetAttribute("ZoneType", "RootCellar")

		-- Hiding spot
		local _, cellarHide = Shared.createHidingSpot(
			cellarCenter + Vector3.new(-3, -cellarSize.Y / 2 + 1, 0),
			"InCellar",
			"RootCellar_Hide",
			cellarModel
		)
		table.insert(hidingSpots, cellarHide)

		-- Loot
		table.insert(lootPositions, {
			itemType = "Battery",
			position = cellarCenter + Vector3.new(-5, -cellarSize.Y / 2 + 2, -5),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Battery",
			position = cellarCenter + Vector3.new(0, -cellarSize.Y / 2 + 0.5, 4),
			chance = 0.7,
			guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Bandage",
			position = cellarCenter + Vector3.new(-5, -cellarSize.Y / 2 + 3.6, -5),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Medkit",
			position = cellarCenter + Vector3.new(-5, -cellarSize.Y / 2 + 1, -3),
			chance = 0.5,
			guaranteed = false,
		})

		cellarModel.Parent = cabinModel
	end

	--------------------------------------------------------------------
	-- Cabin B — Hunter's Cabin (fuel canister)
	--------------------------------------------------------------------
	do
		local cabinB = Shared.createCabin({
			position = CABIN_B_POS,
			size = Vector3.new(14, 10, 10),
			parent = cabinModel,
			name = "CabinB_Hunter",
			hasDoor = true,
			windowWalls = { "east" },
		})

		-- Heavy table (center)
		local heavyTable = Shared.createWoodTable(CABIN_B_POS + Vector3.new(0, 0, 0), cabinB, "HeavyTable")

		-- Barricade prompt on table
		local barricadePrompt = Instance.new("ProximityPrompt")
		barricadePrompt.ActionText = "Barricade Door"
		barricadePrompt.ObjectText = "Heavy Table"
		barricadePrompt.HoldDuration = 4
		barricadePrompt.MaxActivationDistance = 6
		barricadePrompt.Parent = heavyTable

		-- Two chairs (one upright, one overturned)
		Shared.createWoodChair(CABIN_B_POS + Vector3.new(-2, 0, 2), cabinB, false, "Chair_1")
		Shared.createWoodChair(CABIN_B_POS + Vector3.new(2, 0, 2), cabinB, true, "Chair_2_Overturned")

		-- Gun rack (empty)
		local gunRack = Instance.new("Part")
		gunRack.Name = "GunRack"
		gunRack.Size = Vector3.new(4, 3, 0.5)
		gunRack.Position = CABIN_B_POS + Vector3.new(0, 5.5, -4.5)
		gunRack.Anchored = true
		gunRack.Material = Enum.Material.Wood
		gunRack.Color = Shared.Colors.WOOD_DARK
		gunRack.Parent = cabinB

		-- Workbench with trapping supplies
		local workbench = Instance.new("Part")
		workbench.Name = "Workbench"
		workbench.Size = Vector3.new(6, 3, 2)
		workbench.Position = CABIN_B_POS + Vector3.new(-4, 1.5, -3)
		workbench.Anchored = true
		workbench.Material = Enum.Material.Wood
		workbench.Color = Shared.Colors.WOOD_DARK
		workbench.Parent = cabinB

		-- Coiled rope (on workbench, partially hiding the fuel canister)
		local rope = Instance.new("Part")
		rope.Name = "CoiledRope"
		rope.Shape = Enum.PartType.Cylinder
		rope.Size = Vector3.new(0.8, 1.5, 1.5)
		rope.CFrame = CFrame.new(CABIN_B_POS + Vector3.new(-4, 3.4, -3))
			* CFrame.Angles(0, 0, math.rad(90))
		rope.Anchored = true
		rope.Material = Enum.Material.Fabric
		rope.Color = Color3.fromRGB(140, 120, 80)
		rope.Parent = cabinB

		-- FUEL CANISTER (critical objective item)
		local fuelCanister = Instance.new("Part")
		fuelCanister.Name = "FuelCanister"
		fuelCanister.Size = Vector3.new(0.8, 1.2, 0.5)
		fuelCanister.Position = CABIN_B_POS + Vector3.new(-3, 3.6, -3)
		fuelCanister.Anchored = true
		fuelCanister.Material = Enum.Material.Metal
		fuelCanister.Color = Color3.fromRGB(180, 40, 40) -- red fuel canister
		fuelCanister.Parent = cabinB

		fuelCanister:SetAttribute("IsKeyItem", true)
		fuelCanister:SetAttribute("KeyItemType", "FuelCanister")

		local fuelPrompt = Instance.new("ProximityPrompt")
		fuelPrompt.ActionText = "Take"
		fuelPrompt.ObjectText = "Fuel Canister"
		fuelPrompt.HoldDuration = 1
		fuelPrompt.MaxActivationDistance = 6
		fuelPrompt.Parent = fuelCanister

		-- Wood-burning stove (embers still glowing)
		Shared.createWoodStove(CABIN_B_POS + Vector3.new(5, 0, -3), cabinB, true, "CabinB_Stove")

		-- Wall-mounted animal heads (dark shapes that catch flashlight)
		for i, offset in { Vector3.new(-3, 6, -4.5), Vector3.new(3, 6, -4.5) } do
			local mount = Instance.new("Part")
			mount.Name = `AnimalMount_{i}`
			mount.Size = Vector3.new(2, 2, 1)
			mount.Position = CABIN_B_POS + offset
			mount.Anchored = true
			mount.Material = Enum.Material.Wood
			mount.Color = Color3.fromRGB(70, 50, 35)
			mount.Parent = cabinB

			-- Antlers (thin parts)
			for a = 1, 3 do
				local antler = Instance.new("Part")
				antler.Name = `Antler_{i}_{a}`
				antler.Size = Vector3.new(0.15, 1.5, 0.15)
				antler.Position = CABIN_B_POS + offset + Vector3.new(
					(a - 2) * 0.6,
					1.2,
					-0.3
				)
				antler.Orientation = Vector3.new(0, 0, (a - 2) * 25)
				antler.Anchored = true
				antler.Material = Enum.Material.Wood
				antler.Color = Color3.fromRGB(200, 190, 170)
				antler.Parent = cabinB
			end
		end

		-- Cabinet
		local cabinet = Instance.new("Part")
		cabinet.Name = "Cabinet"
		cabinet.Size = Vector3.new(3, 5, 1.5)
		cabinet.Position = CABIN_B_POS + Vector3.new(5, 2.5, 3)
		cabinet.Anchored = true
		cabinet.Material = Enum.Material.Wood
		cabinet.Color = Shared.Colors.WOOD_PLANK
		cabinet.Parent = cabinB

		-- Hiding spot (behind workbench)
		local _, cabinBHide = Shared.createHidingSpot(
			CABIN_B_POS + Vector3.new(-5, 1, -3),
			"InCabin",
			"CabinB_Hide",
			cabinB
		)
		table.insert(hidingSpots, cabinBHide)

		-- Watcher spawn marker (outside cabin door after fuel pickup)
		local watcherSpawn = Instance.new("Part")
		watcherSpawn.Name = "FuelWatcherSpawn"
		watcherSpawn.Size = Vector3.new(2, 8, 2)
		watcherSpawn.Position = CABIN_B_POS + Vector3.new(0, 4, 20) -- 15 studs from door
		watcherSpawn.Anchored = true
		watcherSpawn.Transparency = 1
		watcherSpawn.CanCollide = false
		watcherSpawn.Parent = cabinModel

		watcherSpawn:SetAttribute("WatcherSpawn", true)
		watcherSpawn:SetAttribute("WatcherType", "FuelTrigger")

		-- Waypoint
		table.insert(waypoints, {
			position = CABIN_B_POS + Vector3.new(0, 3, 0),
			roomId = "CabinB",
			dwellTime = 3,
		})

		-- Loot
		table.insert(lootPositions, {
			itemType = "FuelCanister",
			position = CABIN_B_POS + Vector3.new(-3, 3.6, -3),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Battery",
			position = CABIN_B_POS + Vector3.new(0, 3.3, 0),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Bandage",
			position = CABIN_B_POS + Vector3.new(5, 2, 3),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Flare",
			position = CABIN_B_POS + Vector3.new(-5, 2, 3),
			chance = 0.7,
			guaranteed = false,
		})
	end

	--------------------------------------------------------------------
	-- Cabin C — Collapsed Cabin (trapped Watcher)
	--------------------------------------------------------------------
	do
		local cabinC = Shared.createCabin({
			position = CABIN_C_POS,
			size = Vector3.new(10, 8, 8),
			parent = cabinModel,
			name = "CabinC_Collapsed",
			hasDoor = true,
			collapsed = true,
		})

		-- Door hanging from one hinge
		local brokenDoor = Instance.new("Part")
		brokenDoor.Name = "BrokenDoor"
		brokenDoor.Size = Vector3.new(4, 7, 0.4)
		brokenDoor.CFrame = CFrame.new(CABIN_C_POS + Vector3.new(-1.5, 3.5, 4.5))
			* CFrame.Angles(0, math.rad(25), math.rad(-10))
		brokenDoor.Anchored = true
		brokenDoor.Material = Enum.Material.Wood
		brokenDoor.Color = Color3.fromRGB(55, 40, 28)
		brokenDoor.Parent = cabinC

		-- Trapped Watcher marker (immobilized set piece)
		local trappedWatcher = Instance.new("Part")
		trappedWatcher.Name = "TrappedWatcherSpawn"
		trappedWatcher.Size = Vector3.new(2, 8, 2)
		trappedWatcher.Position = CABIN_C_POS + Vector3.new(1, 3, -1)
		trappedWatcher.Anchored = true
		trappedWatcher.Transparency = 1
		trappedWatcher.CanCollide = false
		trappedWatcher.Parent = cabinC

		trappedWatcher:SetAttribute("WatcherSpawn", true)
		trappedWatcher:SetAttribute("WatcherType", "Immobilized")
		trappedWatcher:SetAttribute("TriggersProximityFear", true)

		-- Carved message on floor beam (lore)
		local carvedBeam = Instance.new("Part")
		carvedBeam.Name = "CarvedBeam"
		carvedBeam.Size = Vector3.new(8, 0.4, 0.6)
		carvedBeam.Position = CABIN_C_POS + Vector3.new(0, 0.5, -1)
		carvedBeam.Anchored = true
		carvedBeam.Material = Enum.Material.Wood
		carvedBeam.Color = Shared.Colors.WOOD_DARK
		carvedBeam.Parent = cabinC

		local carvingPrompt = Instance.new("ProximityPrompt")
		carvingPrompt.ActionText = "Read"
		carvingPrompt.ObjectText = "Carved Message"
		carvingPrompt.HoldDuration = 0.5
		carvingPrompt.MaxActivationDistance = 6
		carvingPrompt.Parent = carvedBeam

		-- Waypoint
		table.insert(waypoints, {
			position = CABIN_C_POS + Vector3.new(0, 3, 0),
			roomId = "CabinC",
			dwellTime = 2,
		})

		-- Loot (in back of cabin, past the Watcher)
		table.insert(lootPositions, {
			itemType = "Battery",
			position = CABIN_C_POS + Vector3.new(-3, 1, -2),
			chance = 0.8,
			guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Medkit",
			position = CABIN_C_POS + Vector3.new(3, 1, -2),
			chance = 0.4,
			guaranteed = false,
		})
	end

	--------------------------------------------------------------------
	-- Ridge Terrain (elevated area north of forest)
	--------------------------------------------------------------------
	do
		local ridgeModel = Instance.new("Model")
		ridgeModel.Name = "Ridge"

		-- Ridge ground (elevated slab)
		local ridgeGround = Instance.new("Part")
		ridgeGround.Name = "RidgeGround"
		ridgeGround.Size = Vector3.new(60, 2, 80)
		ridgeGround.Position = Vector3.new(15, RIDGE_Y - 1, -270)
		ridgeGround.Anchored = true
		ridgeGround.Material = Enum.Material.Slate
		ridgeGround.Color = Color3.fromRGB(55, 52, 48) -- rocky terrain
		ridgeGround.Parent = ridgeModel

		-- Cliff edge (flat rock outcropping)
		local cliffPlatform = Instance.new("Part")
		cliffPlatform.Name = "CliffPlatform"
		cliffPlatform.Size = Vector3.new(15, 1, 10)
		cliffPlatform.Position = CLIFF_EDGE_POS + Vector3.new(0, -0.5, 0)
		cliffPlatform.Anchored = true
		cliffPlatform.Material = Enum.Material.Slate
		cliffPlatform.Color = Color3.fromRGB(65, 60, 55)
		cliffPlatform.Parent = ridgeModel

		-- Cliff drop-off (invisible wall at edge)
		local cliffBarrier = Instance.new("Part")
		cliffBarrier.Name = "CliffBarrier"
		cliffBarrier.Size = Vector3.new(15, 20, 1)
		cliffBarrier.Position = CLIFF_EDGE_POS + Vector3.new(0, 10, -5)
		cliffBarrier.Anchored = true
		cliffBarrier.Transparency = 1
		cliffBarrier.CanCollide = true
		cliffBarrier.Parent = ridgeModel

		-- Rescue marker pole (lore item)
		local markerPole = Instance.new("Part")
		markerPole.Name = "RescueMarker"
		markerPole.Size = Vector3.new(0.3, 6, 0.3)
		markerPole.Position = CLIFF_EDGE_POS + Vector3.new(4, 3, 2)
		markerPole.Anchored = true
		markerPole.Material = Enum.Material.Metal
		markerPole.Color = Color3.fromRGB(180, 100, 30) -- orange rescue marker
		markerPole.Parent = ridgeModel

		local lorePrompt = Instance.new("ProximityPrompt")
		lorePrompt.ActionText = "Read"
		lorePrompt.ObjectText = "Emergency Broadcast"
		lorePrompt.HoldDuration = 0.5
		lorePrompt.MaxActivationDistance = 8
		lorePrompt.Parent = markerPole

		-- Sparse scrub brush on ridge
		for i = 1, 6 do
			Shared.createBush(
				Vector3.new(
					math.random(-10, 40),
					RIDGE_Y,
					math.random(-300, -240)
				),
				ridgeModel,
				0.5 + math.random() * 0.5,
				`RidgeScrub_{i}`
			)
		end

		-- Wind (the only place wind is heard — atmospheric marker)
		local windMarker = Instance.new("Part")
		windMarker.Name = "WindZone"
		windMarker.Size = Vector3.new(60, 30, 80)
		windMarker.Position = Vector3.new(15, RIDGE_Y + 15, -270)
		windMarker.Anchored = true
		windMarker.Transparency = 1
		windMarker.CanCollide = false
		windMarker.Parent = ridgeModel

		windMarker:SetAttribute("AmbientZone", "Wind")

		-- Moonlight (clearer at elevation, no canopy)
		Shared.createMoonlight(Vector3.new(15, RIDGE_Y + 25, -270), ridgeModel, 0.25, 50)

		-- Cliff edge loot
		table.insert(lootPositions, {
			itemType = "Battery",
			position = CLIFF_EDGE_POS + Vector3.new(-3, 0.5, 2),
			chance = 0.5,
			guaranteed = false,
		})

		-- Ridge waypoint
		table.insert(waypoints, {
			position = CLIFF_EDGE_POS + Vector3.new(0, 3, 0),
			roomId = "CliffEdge",
			dwellTime = 3,
		})

		ridgeModel.Parent = cabinModel
	end

	--------------------------------------------------------------------
	-- Radio Tower + Bunker (critical objective)
	--------------------------------------------------------------------
	do
		-- Radio tower (metal lattice)
		Shared.createRadioTower(RADIO_TOWER_POS, cabinModel, "RadioTower")

		-- Bunker at base of tower
		local bunker = Shared.createBunker(
			BUNKER_POS,
			Vector3.new(8, 8, 8),
			cabinModel,
			"RadioBunker"
		)

		-- Radio console (inside bunker)
		local console = Instance.new("Part")
		console.Name = "RadioConsole"
		console.Size = Vector3.new(4, 3, 1.5)
		console.Position = BUNKER_POS + Vector3.new(0, 1.5, -2.5)
		console.Anchored = true
		console.Material = Enum.Material.Metal
		console.Color = Color3.fromRGB(50, 55, 50)
		console.Parent = bunker

		-- Console screen (dead)
		local screen = Instance.new("Part")
		screen.Name = "ConsoleScreen"
		screen.Size = Vector3.new(2, 1.5, 0.2)
		screen.Position = BUNKER_POS + Vector3.new(0, 3.5, -2.5)
		screen.Anchored = true
		screen.Material = Enum.Material.Glass
		screen.Color = Color3.fromRGB(15, 20, 15)
		screen.Parent = bunker

		-- Power junction box (cut cable)
		local junction = Instance.new("Part")
		junction.Name = "PowerJunction"
		junction.Size = Vector3.new(1.5, 2, 0.8)
		junction.Position = BUNKER_POS + Vector3.new(3, 3, -3)
		junction.Anchored = true
		junction.Material = Enum.Material.Metal
		junction.Color = Color3.fromRGB(100, 95, 88)
		junction.Parent = bunker

		local junctionPrompt = Instance.new("ProximityPrompt")
		junctionPrompt.ActionText = "Reconnect"
		junctionPrompt.ObjectText = "Power Junction"
		junctionPrompt.HoldDuration = 3
		junctionPrompt.MaxActivationDistance = 6
		junctionPrompt.Parent = junction

		-- Emergency generator
		local generator = Instance.new("Part")
		generator.Name = "Generator"
		generator.Size = Vector3.new(2.5, 2, 2)
		generator.Position = BUNKER_POS + Vector3.new(-3, 1, 2)
		generator.Anchored = true
		generator.Material = Enum.Material.Metal
		generator.Color = Color3.fromRGB(80, 110, 70) -- olive drab
		generator.Parent = bunker

		local genPrompt = Instance.new("ProximityPrompt")
		genPrompt.ActionText = "Pull Cord"
		genPrompt.ObjectText = "Generator"
		genPrompt.HoldDuration = 1
		genPrompt.MaxActivationDistance = 6
		genPrompt.Parent = generator

		-- Radio transmit interaction (on console)
		local transmitPrompt = Instance.new("ProximityPrompt")
		transmitPrompt.ActionText = "Transmit"
		transmitPrompt.ObjectText = "Radio"
		transmitPrompt.HoldDuration = 5
		transmitPrompt.MaxActivationDistance = 6
		transmitPrompt.Enabled = false -- enabled after generator is running
		transmitPrompt.Parent = console

		-- Chair (Vasik's glasses on it)
		Shared.createWoodChair(BUNKER_POS + Vector3.new(0, 0, 0), bunker, false, "BunkerChair")

		local glasses = Instance.new("Part")
		glasses.Name = "VasikGlasses"
		glasses.Size = Vector3.new(0.6, 0.2, 0.3)
		glasses.Position = BUNKER_POS + Vector3.new(0, 2.3, 0)
		glasses.Anchored = true
		glasses.Material = Enum.Material.Glass
		glasses.Color = Color3.fromRGB(160, 155, 145)
		glasses.Parent = bunker

		-- Emergency LEDs (dim green)
		local led = Instance.new("Part")
		led.Name = "EmergencyLED"
		led.Size = Vector3.new(0.3, 0.3, 0.3)
		led.Position = BUNKER_POS + Vector3.new(2, 6, -3)
		led.Anchored = true
		led.Material = Enum.Material.Neon
		led.Color = Color3.fromRGB(30, 80, 30)
		led.Parent = bunker

		local ledLight = Instance.new("PointLight")
		ledLight.Brightness = 0.1
		ledLight.Color = Color3.fromRGB(40, 120, 40)
		ledLight.Range = 6
		ledLight.Parent = led

		-- Waypoints
		table.insert(waypoints, {
			position = BUNKER_POS + Vector3.new(0, 3, 0),
			roomId = "RadioBunker",
			dwellTime = 5,
		})
		table.insert(waypoints, {
			position = RADIO_TOWER_POS + Vector3.new(0, 3, 0),
			roomId = "RadioTower",
			dwellTime = 3,
		})

		-- Loot
		table.insert(lootPositions, {
			itemType = "Battery",
			position = BUNKER_POS + Vector3.new(-3, 3, -3),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Bandage",
			position = BUNKER_POS + Vector3.new(3, 2, 2),
			chance = 0.6,
			guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Flare",
			position = BUNKER_POS + Vector3.new(-3, 2, 2),
			chance = 0.5,
			guaranteed = false,
		})
	end

	cabinModel.Parent = parent

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return Cabin
