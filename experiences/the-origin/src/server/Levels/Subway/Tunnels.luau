--!strict

--[[
	Subway/Tunnels - Builds the tunnel network connecting Hargrove Street
	to Moorfield station, and the Deep Tunnels from Moorfield to Terminus.

	Areas:
		- Main Tunnel (200 studs, straight, no cover)
		- Service Tunnel (parallel, narrow, Crawler speed penalty)
		- Junction Chamber (4-way crossing, exposed)
		- Ventilation Shafts (crawlspace shortcuts)
		- Flooded Section (waist-deep water, loud movement)
		- Collapsed Section (squeeze points)
		- Unfinished Extension (pitch black, scaffolding maze)
		- The Nest (optional, extreme danger)
		- Drainage System (final approach to Terminus)

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

local PLATFORM_Y = -24
local TRACK_Y = -28
local TUNNEL_HEIGHT = 14
local TUNNEL_WIDTH = 12 -- main tunnel
local SERVICE_TUNNEL_WIDTH = 5 -- narrow
local SERVICE_TUNNEL_HEIGHT = 10 -- lower ceiling
local VENT_SHAFT_SIZE = 4 -- crawlspace dimension

-- Z coordinates define the tunnel network layout
-- Tunnels run primarily along Z axis (north-south) between stations
local HARGROVE_TUNNEL_ENTRY_Z = 60 -- just past Platform A
local MOORFIELD_TUNNEL_EXIT_Z = -340 -- approaching Moorfield
local MAIN_TUNNEL_LENGTH = 200

-- Tunnel start (Hargrove end) to tunnel end (Moorfield end)
local TUNNEL_START_Z = 70
local TUNNEL_END_Z = TUNNEL_START_Z - MAIN_TUNNEL_LENGTH -- = -130

-- Junction chamber at midpoint
local JUNCTION_Z = TUNNEL_START_Z - 100 -- = -30

-- Deep tunnel section (Moorfield to Terminus)
local DEEP_TUNNEL_START_Z = -360
local DEEP_TUNNEL_END_Z = -560

-- Colors
local TUNNEL_WALL_COLOR = Color3.fromRGB(90, 88, 82)
local TUNNEL_FLOOR_COLOR = Color3.fromRGB(70, 70, 65)
local RAW_CONCRETE_COLOR = Color3.fromRGB(80, 78, 72)
local DIM_RED = Color3.fromRGB(180, 40, 30)
local WORK_LIGHT_COLOR = Color3.fromRGB(255, 220, 150)
local BIOLUMINESCENT = Color3.fromRGB(80, 120, 70)

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local Tunnels = {}

function Tunnels.build(parent: Instance): FloorData
	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	local tunnelModel = Instance.new("Model")
	tunnelModel.Name = "TunnelNetwork"

	--------------------------------------------------------------------
	-- ==================== MAIN TUNNEL ==============================
	--------------------------------------------------------------------
	do
		local mainModel = Instance.new("Model")
		mainModel.Name = "MainTunnel"

		local tunnelStartPos = Vector3.new(0, TRACK_Y, TUNNEL_START_Z)
		local tunnelEndPos = Vector3.new(0, TRACK_Y, TUNNEL_END_Z)

		-- Tunnel shell (walls, floor, ceiling)
		Shared.createTunnelSection(
			tunnelStartPos, tunnelEndPos,
			TUNNEL_WIDTH, TUNNEL_HEIGHT,
			mainModel, "MainTunnel_Shell"
		)

		-- Dual track beds
		Shared.createTrackBed(
			Vector3.new(-3, TRACK_Y, TUNNEL_START_Z),
			Vector3.new(-3, TRACK_Y, TUNNEL_END_Z),
			mainModel, "Track_Left"
		)
		Shared.createTrackBed(
			Vector3.new(3, TRACK_Y, TUNNEL_START_Z),
			Vector3.new(3, TRACK_Y, TUNNEL_END_Z),
			mainModel, "Track_Right"
		)

		-- Overhead cable infrastructure
		Shared.createOverheadCables(
			Vector3.new(0, TRACK_Y + TUNNEL_HEIGHT - 2, TUNNEL_START_Z),
			Vector3.new(0, TRACK_Y + TUNNEL_HEIGHT - 2, TUNNEL_END_Z),
			mainModel, "OverheadCables"
		)

		-- Emergency lights every 50 studs (dim red)
		for i = 0, 3 do
			local lightZ = TUNNEL_START_Z - i * 50
			Shared.createEmergencyLight(
				Vector3.new(0, TRACK_Y + TUNNEL_HEIGHT - 1, lightZ),
				mainModel, DIM_RED
			)
		end

		-- Service tunnel access doors (at 50, 100, 150 studs)
		for i, offset in { 50, 100, 150 } do
			local doorZ = TUNNEL_START_Z - offset
			local accessDoor = Shared.createDoor(
				Vector3.new(-TUNNEL_WIDTH / 2 - 0.5, TRACK_Y + 4, doorZ),
				CFrame.Angles(0, math.rad(90), 0),
				mainModel, `ServiceAccess_{i}`, false
			)
			accessDoor:SetAttribute("HeavyDoor", true)
			accessDoor:SetAttribute("SoundRadius", 30)
			accessDoor.Material = Enum.Material.Metal
			accessDoor.Color = Color3.fromRGB(80, 80, 75)
		end

		-- Track-side detritus
		-- Abandoned maintenance carts (too low to hide behind)
		Shared.createMaintenanceCart(
			Vector3.new(4, TRACK_Y, TUNNEL_START_Z - 30),
			mainModel, "Cart_1"
		)
		Shared.createMaintenanceCart(
			Vector3.new(-4, TRACK_Y, TUNNEL_START_Z - 140),
			mainModel, "Cart_2"
		)

		-- Cable spools
		for i, zOff in { 60, 120, 170 } do
			local spool = Instance.new("Part")
			spool.Name = `CableSpool_{i}`
			spool.Shape = Enum.PartType.Cylinder
			spool.Size = Vector3.new(2, 3, 3)
			spool.Position = Vector3.new(5, TRACK_Y + 1.5, TUNNEL_START_Z - zOff)
			spool.Orientation = Vector3.new(0, 0, 90)
			spool.Anchored = true
			spool.Material = Enum.Material.Wood
			spool.Color = Color3.fromRGB(110, 85, 60)
			spool.Parent = mainModel
		end

		-- Midpoint maintenance cart with worker's belongings
		do
			local midZ = TUNNEL_START_Z - 100
			local midCart = Shared.createMaintenanceCart(
				Vector3.new(0, TRACK_Y, midZ),
				mainModel, "MidpointCart"
			)

			-- Thermos
			local thermos = Instance.new("Part")
			thermos.Name = "Thermos"
			thermos.Shape = Enum.PartType.Cylinder
			thermos.Size = Vector3.new(0.8, 0.4, 0.4)
			thermos.Position = Vector3.new(0.5, TRACK_Y + 1.8, midZ - 1)
			thermos.Orientation = Vector3.new(0, 0, 90)
			thermos.Anchored = true
			thermos.Material = Enum.Material.Metal
			thermos.Color = Color3.fromRGB(140, 40, 40)
			thermos.Parent = midCart

			-- Lunchbox with family photo
			local lunchbox = Instance.new("Part")
			lunchbox.Name = "Lunchbox"
			lunchbox.Size = Vector3.new(1, 0.6, 0.8)
			lunchbox.Position = Vector3.new(-0.5, TRACK_Y + 1.8, midZ + 0.5)
			lunchbox.Anchored = true
			lunchbox.Material = Enum.Material.Metal
			lunchbox.Color = Color3.fromRGB(50, 80, 50)
			lunchbox.Parent = midCart

			-- Dead radio
			local radio = Instance.new("Part")
			radio.Name = "DeadRadio"
			radio.Size = Vector3.new(0.8, 0.5, 0.4)
			radio.Position = Vector3.new(1, TRACK_Y + 1.8, midZ + 1)
			radio.Anchored = true
			radio.Material = Enum.Material.SmoothPlastic
			radio.Color = Color3.fromRGB(30, 30, 28)
			radio.Parent = midCart
		end

		-- Waypoints (along the tunnel)
		for i = 0, 3 do
			local wpZ = TUNNEL_START_Z - i * 50 - 25
			table.insert(waypoints, {
				position = Vector3.new(0, TRACK_Y + 3, wpZ),
				roomId = `MainTunnel_Section{i}`,
				dwellTime = 1.5,
			})
		end

		-- Loot
		table.insert(lootPositions, {
			itemType = "Battery", position = Vector3.new(0, TRACK_Y + 1.8, TUNNEL_START_Z - 100),
			chance = 0.4, guaranteed = false,
		})

		mainModel.Parent = tunnelModel
	end

	--------------------------------------------------------------------
	-- ==================== SERVICE TUNNEL ============================
	--------------------------------------------------------------------
	do
		local serviceModel = Instance.new("Model")
		serviceModel.Name = "ServiceTunnel"

		local stX = -TUNNEL_WIDTH / 2 - 4 -- parallel, offset west

		-- Tunnel shell
		Shared.createTunnelSection(
			Vector3.new(stX, TRACK_Y, TUNNEL_START_Z),
			Vector3.new(stX, TRACK_Y, TUNNEL_END_Z),
			SERVICE_TUNNEL_WIDTH, SERVICE_TUNNEL_HEIGHT,
			serviceModel, "ServiceTunnel_Shell"
		)

		-- Pipe-lined walls (overhead pipes along the length)
		for i = 0, 4 do
			local pipeZ = TUNNEL_START_Z - i * 50
			Shared.createPipe(
				Vector3.new(stX, TRACK_Y + SERVICE_TUNNEL_HEIGHT - 1.5, pipeZ),
				50, 0.25,
				Vector3.new(90, 0, 0),
				serviceModel, `ServicePipe_{i}`
			)
		end

		-- Flickering work lights
		for i = 0, 6 do
			local lightZ = TUNNEL_START_Z - i * 30
			Shared.createLight(
				Vector3.new(stX, TRACK_Y + SERVICE_TUNNEL_HEIGHT - 0.5, lightZ),
				serviceModel, 0.1, WORK_LIGHT_COLOR
			)
		end

		-- Maintenance alcoves every 30 studs (shallow cutouts)
		for i = 0, 5 do
			local alcoveZ = TUNNEL_START_Z - 15 - i * 30
			local alcove = Instance.new("Part")
			alcove.Name = `Alcove_{i}`
			alcove.Size = Vector3.new(3, SERVICE_TUNNEL_HEIGHT, 2)
			alcove.Position = Vector3.new(stX - SERVICE_TUNNEL_WIDTH / 2 - 1.5, TRACK_Y + SERVICE_TUNNEL_HEIGHT / 2, alcoveZ)
			alcove.Anchored = true
			alcove.Material = Enum.Material.Concrete
			alcove.Color = TUNNEL_WALL_COLOR
			alcove.Transparency = 1 -- invisible, just marks the space
			alcove.CanCollide = false
			alcove.Parent = serviceModel
			alcove:SetAttribute("InformalHidingSpot", true)
			alcove:SetAttribute("SurvivalChance", 0.7)

			-- Fuse box in each alcove
			local fuseBox = Instance.new("Part")
			fuseBox.Name = `FuseBox_{i}`
			fuseBox.Size = Vector3.new(1, 1.5, 0.3)
			fuseBox.Position = Vector3.new(stX - SERVICE_TUNNEL_WIDTH / 2 - 2.5, TRACK_Y + 5, alcoveZ)
			fuseBox.Anchored = true
			fuseBox.Material = Enum.Material.Metal
			fuseBox.Color = Color3.fromRGB(60, 65, 60)
			fuseBox.Parent = serviceModel
		end

		-- Burst pipe section (splash sounds)
		do
			local burstZ = TUNNEL_START_Z - 80
			local burstPipe = Instance.new("Part")
			burstPipe.Name = "BurstPipe"
			burstPipe.Shape = Enum.PartType.Cylinder
			burstPipe.Size = Vector3.new(3, 0.5, 0.5)
			burstPipe.Position = Vector3.new(stX - 2, TRACK_Y + 6, burstZ)
			burstPipe.Orientation = Vector3.new(90, 0, 0)
			burstPipe.Anchored = true
			burstPipe.Material = Enum.Material.Metal
			burstPipe.Color = Color3.fromRGB(100, 95, 90)
			burstPipe.Parent = serviceModel

			-- Water spray (semi-transparent particle marker)
			local spray = Instance.new("Part")
			spray.Name = "WaterSpray"
			spray.Size = Vector3.new(2, 5, 2)
			spray.Position = Vector3.new(stX - 2, TRACK_Y + 3, burstZ)
			spray.Anchored = true
			spray.Material = Enum.Material.Glass
			spray.Color = Color3.fromRGB(100, 140, 170)
			spray.Transparency = 0.7
			spray.CanCollide = false
			spray.Parent = serviceModel
			spray:SetAttribute("SplashSoundRadius_Walk", 15)
			spray:SetAttribute("SplashSoundRadius_Crouch", 8)

			-- Puddle on floor
			local puddle = Instance.new("Part")
			puddle.Name = "BurstPipePuddle"
			puddle.Size = Vector3.new(4, 0.05, 6)
			puddle.Position = Vector3.new(stX, TRACK_Y + 0.03, burstZ)
			puddle.Anchored = true
			puddle.Material = Enum.Material.Glass
			puddle.Color = Color3.fromRGB(60, 80, 100)
			puddle.Transparency = 0.5
			puddle.Parent = serviceModel
		end

		-- First aid station (wall-mounted)
		local firstAid = Instance.new("Part")
		firstAid.Name = "FirstAidStation"
		firstAid.Size = Vector3.new(1, 1.2, 0.3)
		firstAid.Position = Vector3.new(stX + SERVICE_TUNNEL_WIDTH / 2, TRACK_Y + 5, TUNNEL_START_Z - 60)
		firstAid.Anchored = true
		firstAid.Material = Enum.Material.SmoothPlastic
		firstAid.Color = Color3.fromRGB(200, 50, 50)
		firstAid.Parent = serviceModel

		-- Condensation drip markers
		for i = 0, 3 do
			local drip = Instance.new("Part")
			drip.Name = `Drip_{i}`
			drip.Size = Vector3.new(0.3, 0.3, 0.3)
			drip.Position = Vector3.new(stX, TRACK_Y + SERVICE_TUNNEL_HEIGHT - 0.5, TUNNEL_START_Z - 20 - i * 50)
			drip.Anchored = true
			drip.Transparency = 0.9
			drip.CanCollide = false
			drip.Material = Enum.Material.Glass
			drip.Color = Color3.fromRGB(100, 130, 150)
			drip.Parent = serviceModel
		end

		-- Waypoints
		for i = 0, 3 do
			local wpZ = TUNNEL_START_Z - i * 50 - 25
			table.insert(waypoints, {
				position = Vector3.new(stX, TRACK_Y + 3, wpZ),
				roomId = `ServiceTunnel_Section{i}`,
				dwellTime = 2,
			})
		end

		-- Loot
		table.insert(lootPositions, {
			itemType = "Bandage", position = Vector3.new(stX + SERVICE_TUNNEL_WIDTH / 2 - 0.5, TRACK_Y + 5.5, TUNNEL_START_Z - 60),
			chance = 1, guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Battery", position = Vector3.new(stX, TRACK_Y + 1, TUNNEL_START_Z - 150),
			chance = 0.5, guaranteed = false,
		})

		serviceModel.Parent = tunnelModel
	end

	--------------------------------------------------------------------
	-- ==================== JUNCTION CHAMBER =========================
	--------------------------------------------------------------------
	do
		local junctionModel = Instance.new("Model")
		junctionModel.Name = "JunctionChamber"

		local jPos = Vector3.new(0, TRACK_Y, JUNCTION_Z)
		local jSize = Vector3.new(40, 30, 40) -- octagonal-ish, tall ceiling

		-- Simplified as rectangular room with high ceiling
		Shared.createRoom({
			position = jPos,
			size = jSize,
			parent = junctionModel,
			name = "JunctionChamber",
			wallColor = TUNNEL_WALL_COLOR,
			floorColor = TUNNEL_FLOOR_COLOR,
			ceilingColor = Color3.fromRGB(70, 68, 62),
			wallMaterial = Enum.Material.Concrete,
			floorMaterial = Enum.Material.Concrete,
			doorways = {
				-- Main Tunnel north
				{ wall = "north", offset = 0, width = TUNNEL_WIDTH, height = TUNNEL_HEIGHT },
				-- Service Tunnel west
				{ wall = "west", offset = 5, width = SERVICE_TUNNEL_WIDTH, height = SERVICE_TUNNEL_HEIGHT },
				-- Flooded Section south
				{ wall = "south", offset = -5, width = 8, height = TUNNEL_HEIGHT },
				-- Ventilation shaft access east (elevated)
				{ wall = "east", offset = 5, width = 4, height = 4 },
				-- Collapsed Section south-east
				{ wall = "south", offset = 10, width = 6, height = TUNNEL_HEIGHT },
			},
		})

		-- Central ventilation fan unit (non-operational, jammed)
		local fanHousing = Instance.new("Part")
		fanHousing.Name = "VentFanHousing"
		fanHousing.Shape = Enum.PartType.Cylinder
		fanHousing.Size = Vector3.new(3, 8, 8)
		fanHousing.Position = jPos + Vector3.new(0, 5, 0)
		fanHousing.Orientation = Vector3.new(0, 0, 0)
		fanHousing.Anchored = true
		fanHousing.Material = Enum.Material.Metal
		fanHousing.Color = Color3.fromRGB(80, 80, 75)
		fanHousing.Parent = junctionModel

		-- Jammed fan blades (decorative)
		for i = 0, 3 do
			local blade = Instance.new("Part")
			blade.Name = `FanBlade_{i}`
			blade.Size = Vector3.new(0.2, 3.5, 0.8)
			blade.Position = jPos + Vector3.new(0, 5, 0)
			blade.CFrame = CFrame.new(jPos + Vector3.new(0, 5, 0))
				* CFrame.Angles(0, 0, math.rad(i * 90 + 15))
				* CFrame.new(0, 1.75, 0)
			blade.Anchored = true
			blade.Material = Enum.Material.Metal
			blade.Color = Color3.fromRGB(100, 100, 95)
			blade.Parent = junctionModel
		end

		-- Battery-powered work lamp (destroyable)
		local workLamp = Instance.new("Part")
		workLamp.Name = "WorkLamp"
		workLamp.Size = Vector3.new(1, 2, 1)
		workLamp.Position = jPos + Vector3.new(0, 2, 0)
		workLamp.Anchored = true
		workLamp.Material = Enum.Material.SmoothPlastic
		workLamp.Color = Color3.fromRGB(230, 220, 200)
		workLamp.Parent = junctionModel
		workLamp:SetAttribute("Destroyable", true)
		workLamp:SetAttribute("DestroyMethod", "ThrowItem")

		local workLight = Instance.new("PointLight")
		workLight.Brightness = 0.6
		workLight.Color = Color3.fromRGB(255, 255, 240)
		workLight.Range = 15
		workLight.Shadows = true
		workLight.Parent = workLamp

		-- Maintenance ladder to vent shaft access (east wall, elevated)
		local ladder = Instance.new("Part")
		ladder.Name = "VentLadder"
		ladder.Size = Vector3.new(1.5, 12, 0.3)
		ladder.Position = jPos + Vector3.new(20, 6, 5)
		ladder.Anchored = true
		ladder.Material = Enum.Material.Metal
		ladder.Color = Color3.fromRGB(120, 120, 115)
		ladder.Parent = junctionModel

		-- Ladder rungs
		for i = 0, 10 do
			local rung = Instance.new("Part")
			rung.Name = `Rung_{i}`
			rung.Size = Vector3.new(1.5, 0.15, 0.15)
			rung.Position = jPos + Vector3.new(20, 1 + i * 1.1, 5)
			rung.Anchored = true
			rung.Material = Enum.Material.Metal
			rung.Color = Color3.fromRGB(140, 140, 135)
			rung.Parent = junctionModel
		end

		-- Graffiti marker (wall near vent access)
		local graffiti = Instance.new("Part")
		graffiti.Name = "Graffiti"
		graffiti.Size = Vector3.new(0.05, 2, 4)
		graffiti.Position = jPos + Vector3.new(19.9, 8, 5)
		graffiti.Anchored = true
		graffiti.Material = Enum.Material.SmoothPlastic
		graffiti.Color = Color3.fromRGB(180, 30, 30)
		graffiti.Transparency = 0.3
		graffiti.CanCollide = false
		graffiti.Parent = junctionModel
		graffiti:SetAttribute("Text", "THEY COME FROM BELOW / NO. THEY COME FROM THE DARK.")

		-- Waypoints
		table.insert(waypoints, {
			position = jPos + Vector3.new(0, 3, 0),
			roomId = "JunctionChamber_Center",
			dwellTime = 2,
		})
		for _, dir in { Vector3.new(12, 0, 0), Vector3.new(-12, 0, 0), Vector3.new(0, 0, 12), Vector3.new(0, 0, -12) } do
			table.insert(waypoints, {
				position = jPos + dir + Vector3.new(0, 3, 0),
				roomId = `JunctionChamber_{if dir.X > 0 then "E" elseif dir.X < 0 then "W" elseif dir.Z > 0 then "S" else "N"}`,
				dwellTime = 1,
			})
		end

		-- Loot: Flare (guaranteed), Bandage (40%)
		table.insert(lootPositions, {
			itemType = "Flare", position = jPos + Vector3.new(3, 1, 5),
			chance = 1, guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Bandage", position = jPos + Vector3.new(-5, 1, -3),
			chance = 0.4, guaranteed = false,
		})

		junctionModel.Parent = tunnelModel
	end

	--------------------------------------------------------------------
	-- ==================== VENTILATION SHAFTS =======================
	--------------------------------------------------------------------
	do
		local ventModel = Instance.new("Model")
		ventModel.Name = "VentilationShafts"

		-- Branch A: Junction Chamber -> Moorfield Platform (bypass flooded section)
		local branchA_Start = Vector3.new(20, TRACK_Y + 10, JUNCTION_Z + 5)
		local branchA_Mid = Vector3.new(20, TRACK_Y + 10, JUNCTION_Z - 60)
		local branchA_End = Vector3.new(20, TRACK_Y + 10, TUNNEL_END_Z - 20)

		-- Simplified as narrow corridor sections
		Shared.createCorridor(
			branchA_Start, branchA_Mid,
			VENT_SHAFT_SIZE, VENT_SHAFT_SIZE,
			ventModel, "VentShaft_BranchA_Seg1"
		)
		Shared.createCorridor(
			branchA_Mid, branchA_End,
			VENT_SHAFT_SIZE, VENT_SHAFT_SIZE,
			ventModel, "VentShaft_BranchA_Seg2"
		)

		-- Branch B: Junction Chamber -> Collapsed Section (shortcut)
		local branchB_Start = Vector3.new(20, TRACK_Y + 10, JUNCTION_Z - 5)
		local branchB_End = Vector3.new(15, TRACK_Y + 10, JUNCTION_Z - 40)

		Shared.createCorridor(
			branchB_Start, branchB_End,
			VENT_SHAFT_SIZE, VENT_SHAFT_SIZE,
			ventModel, "VentShaft_BranchB"
		)

		-- Dead End C: Branch that terminates at grate overlooking Main Tunnel
		local deadEnd_Start = Vector3.new(20, TRACK_Y + 10, JUNCTION_Z)
		local deadEnd_End = Vector3.new(8, TRACK_Y + 10, JUNCTION_Z)

		Shared.createCorridor(
			deadEnd_Start, deadEnd_End,
			VENT_SHAFT_SIZE, VENT_SHAFT_SIZE,
			ventModel, "VentShaft_DeadEndC"
		)

		-- Grate at dead end (view into main tunnel)
		local grate = Instance.new("Part")
		grate.Name = "ObservationGrate"
		grate.Size = Vector3.new(VENT_SHAFT_SIZE, 0.2, VENT_SHAFT_SIZE)
		grate.Position = Vector3.new(6, TRACK_Y + 10, JUNCTION_Z)
		grate.Anchored = true
		grate.Material = Enum.Material.Metal
		grate.Color = Color3.fromRGB(90, 90, 85)
		grate.Transparency = 0.3
		grate.Parent = ventModel

		-- Scratch marks throughout shafts (thousands)
		for i = 1, 20 do
			local scratch = Instance.new("Part")
			scratch.Name = `ScratchMark_{i}`
			scratch.Size = Vector3.new(0.03, 0.5 + math.random() * 1, 0.03)
			scratch.Position = Vector3.new(
				20 + (math.random() - 0.5) * 3,
				TRACK_Y + 10 + (math.random() - 0.5) * 3,
				JUNCTION_Z - math.random() * 100
			)
			scratch.Orientation = Vector3.new(math.random(-20, 20), math.random(0, 180), math.random(-20, 20))
			scratch.Anchored = true
			scratch.Material = Enum.Material.Metal
			scratch.Color = Color3.fromRGB(60, 55, 50)
			scratch.CanCollide = false
			scratch.Parent = ventModel
		end

		-- Desiccated rat with wrong webbing
		local ratWebbing = Shared.createWebbing(
			Vector3.new(20, TRACK_Y + 12, JUNCTION_Z - 30),
			2, 5, ventModel, "RatWebbing"
		)

		-- Attributes for speed modifications
		ventModel:SetAttribute("PlayerSpeedMultiplier", 0.4)
		ventModel:SetAttribute("CrawlerSpeedMultiplier", 1.0) -- full speed for crawlers
		ventModel:SetAttribute("ForceCrouch", true)
		ventModel:SetAttribute("FlashlightRangeOverride", 7)

		-- Waypoints
		table.insert(waypoints, {
			position = branchA_Start + Vector3.new(0, 1, 0),
			roomId = "VentShaft_A_Start",
			dwellTime = 3,
		})
		table.insert(waypoints, {
			position = branchB_Start + Vector3.new(0, 1, 0),
			roomId = "VentShaft_B_Start",
			dwellTime = 3,
		})

		-- Loot: Battery (guaranteed, wedged against grate)
		table.insert(lootPositions, {
			itemType = "Battery", position = Vector3.new(7, TRACK_Y + 10.5, JUNCTION_Z),
			chance = 1, guaranteed = true,
		})

		ventModel.Parent = tunnelModel
	end

	--------------------------------------------------------------------
	-- ==================== FLOODED SECTION ==========================
	--------------------------------------------------------------------
	do
		local floodModel = Instance.new("Model")
		floodModel.Name = "FloodedSection"

		local floodStartZ = JUNCTION_Z - 20
		local floodEndZ = floodStartZ - 60

		-- Tunnel shell
		Shared.createTunnelSection(
			Vector3.new(-5, TRACK_Y, floodStartZ),
			Vector3.new(-5, TRACK_Y, floodEndZ),
			10, TUNNEL_HEIGHT,
			floodModel, "FloodedTunnel_Shell"
		)

		-- Water volume (waist-deep)
		local waterDepth = 3
		Shared.createWaterVolume(
			Vector3.new(-5, TRACK_Y + waterDepth / 2, (floodStartZ + floodEndZ) / 2),
			Vector3.new(10, waterDepth, math.abs(floodEndZ - floodStartZ)),
			floodModel, "FloodWater"
		)

		-- Overhead pipe for hand-pulling
		Shared.createPipe(
			Vector3.new(-8, TRACK_Y + 5, (floodStartZ + floodEndZ) / 2),
			math.abs(floodEndZ - floodStartZ),
			0.3,
			Vector3.new(90, 0, 0),
			floodModel, "GrabbablePipe"
		)

		-- Dry platform (collapsed elevated walkway at midpoint)
		local dryPlatZ = (floodStartZ + floodEndZ) / 2
		local dryPlat = Instance.new("Part")
		dryPlat.Name = "DryPlatform"
		dryPlat.Size = Vector3.new(6, 1, 5)
		dryPlat.Position = Vector3.new(-5, TRACK_Y + waterDepth + 0.5, dryPlatZ)
		dryPlat.Anchored = true
		dryPlat.Material = Enum.Material.Concrete
		dryPlat.Color = Color3.fromRGB(110, 108, 100)
		dryPlat.Parent = floodModel

		-- Submerged obstacles (shopping cart, debris)
		local cart = Instance.new("Part")
		cart.Name = "SubmergedCart"
		cart.Size = Vector3.new(2, 2, 3)
		cart.Position = Vector3.new(-3, TRACK_Y + 0.5, floodStartZ - 15)
		cart.Orientation = Vector3.new(10, 25, -5)
		cart.Anchored = true
		cart.Material = Enum.Material.Metal
		cart.Color = Color3.fromRGB(80, 80, 75)
		cart.Transparency = 0.5 -- barely visible under water
		cart.Parent = floodModel

		-- Submerged "body" (organic webbing bundle)
		local webBundle = Instance.new("Part")
		webBundle.Name = "SubmergedBundle"
		webBundle.Size = Vector3.new(1.5, 1, 4)
		webBundle.Position = Vector3.new(-6, TRACK_Y + 0.5, floodStartZ - 35)
		webBundle.Anchored = true
		webBundle.Material = Enum.Material.Fabric
		webBundle.Color = Color3.fromRGB(120, 110, 95)
		webBundle.Transparency = 0.6
		webBundle.Parent = floodModel
		webBundle:SetAttribute("TouchEvent", "WebbingEncounter")

		-- No lights in flooded section (total flashlight dependency)

		-- Waypoints
		table.insert(waypoints, {
			position = Vector3.new(-5, TRACK_Y + 3, floodStartZ - 10),
			roomId = "FloodedSection_Entry",
			dwellTime = 1,
		})
		table.insert(waypoints, {
			position = Vector3.new(-5, TRACK_Y + 3, dryPlatZ),
			roomId = "FloodedSection_DryPlatform",
			dwellTime = 2,
		})
		table.insert(waypoints, {
			position = Vector3.new(-5, TRACK_Y + 3, floodEndZ + 10),
			roomId = "FloodedSection_Exit",
			dwellTime = 1,
		})

		-- Loot: Medkit (guaranteed, on dry platform)
		table.insert(lootPositions, {
			itemType = "Medkit", position = Vector3.new(-5, TRACK_Y + waterDepth + 1.5, dryPlatZ),
			chance = 1, guaranteed = true,
		})

		floodModel.Parent = tunnelModel
	end

	--------------------------------------------------------------------
	-- ==================== COLLAPSED SECTION ========================
	--------------------------------------------------------------------
	do
		local collapseModel = Instance.new("Model")
		collapseModel.Name = "CollapsedSection"

		local colStartZ = JUNCTION_Z - 25
		local colEndZ = colStartZ - 40

		-- Tunnel shell (partially destroyed)
		Shared.createTunnelSection(
			Vector3.new(10, TRACK_Y, colStartZ),
			Vector3.new(10, TRACK_Y, colEndZ),
			8, TUNNEL_HEIGHT,
			collapseModel, "CollapsedTunnel_Shell"
		)

		-- Heavy rubble throughout
		Shared.createRubble(
			Vector3.new(10, TRACK_Y, colStartZ - 5), 6, 8,
			collapseModel, "Rubble_Entry"
		)
		Shared.createRubble(
			Vector3.new(10, TRACK_Y, colStartZ - 20), 8, 12,
			collapseModel, "Rubble_Mid"
		)
		Shared.createRubble(
			Vector3.new(10, TRACK_Y, colEndZ + 5), 6, 10,
			collapseModel, "Rubble_Exit"
		)

		-- Squeeze points (3 in sequence, each tighter)
		local squeezeWidths = { 3, 2.5, 2 }
		local squeezeDurations = { 2, 2, 3 }
		for i, width in squeezeWidths do
			local sqZ = colStartZ - 8 - (i - 1) * 12

			-- Narrow gap (two wall segments creating a squeeze)
			Shared.createWall(
				Vector3.new(10 - 2, TRACK_Y + 4, sqZ),
				Vector3.new(3, 8, 2), collapseModel, `SqueezeWall_L_{i}`
			)
			Shared.createWall(
				Vector3.new(10 + 2, TRACK_Y + 4, sqZ),
				Vector3.new(3, 8, 2), collapseModel, `SqueezeWall_R_{i}`
			)

			-- Invisible trigger part for squeeze animation
			local trigger = Instance.new("Part")
			trigger.Name = `SqueezeTrigger_{i}`
			trigger.Size = Vector3.new(width, 6, 2)
			trigger.Position = Vector3.new(10, TRACK_Y + 3, sqZ)
			trigger.Anchored = true
			trigger.Transparency = 1
			trigger.CanCollide = false
			trigger.Parent = collapseModel
			trigger:SetAttribute("SqueezePoint", true)
			trigger:SetAttribute("Duration", squeezeDurations[i])
			trigger:SetAttribute("CrawlerSqueezeTime", 4 + i)
		end

		-- Construction worker helmet with headlamp (between squeeze 1 and 2)
		local helmet = Instance.new("Part")
		helmet.Name = "ConstructionHelmet"
		helmet.Shape = Enum.PartType.Ball
		helmet.Size = Vector3.new(1, 1, 1)
		helmet.Position = Vector3.new(12, TRACK_Y + 0.5, colStartZ - 16)
		helmet.Anchored = true
		helmet.Material = Enum.Material.SmoothPlastic
		helmet.Color = Color3.fromRGB(200, 180, 40)
		helmet.Parent = collapseModel

		local helmetLight = Instance.new("PointLight")
		helmetLight.Brightness = 0.2
		helmetLight.Color = Color3.fromRGB(255, 240, 200)
		helmetLight.Range = 6
		helmetLight.Parent = helmet

		-- Fissure in ceiling (something moving up there)
		local fissure = Instance.new("Part")
		fissure.Name = "CeilingFissure"
		fissure.Size = Vector3.new(2, 0.5, 8)
		fissure.Position = Vector3.new(10, TRACK_Y + TUNNEL_HEIGHT, colStartZ - 25)
		fissure.Anchored = true
		fissure.Material = Enum.Material.Concrete
		fissure.Color = Color3.fromRGB(30, 30, 28)
		fissure.Parent = collapseModel
		fissure:SetAttribute("AmbientClawSounds", true)

		-- Emergency exit sign (wrong direction)
		local exitSign = Instance.new("Part")
		exitSign.Name = "WrongExitSign"
		exitSign.Size = Vector3.new(2, 0.8, 0.1)
		exitSign.Position = Vector3.new(13, TRACK_Y + 7, colEndZ + 2)
		exitSign.Anchored = true
		exitSign.Material = Enum.Material.Neon
		exitSign.Color = Color3.fromRGB(30, 150, 30)
		exitSign.Transparency = 0.3
		exitSign.Parent = collapseModel

		-- No lighting (total darkness)

		-- Waypoints
		table.insert(waypoints, {
			position = Vector3.new(10, TRACK_Y + 3, colStartZ - 5),
			roomId = "CollapsedSection_Entry",
			dwellTime = 1,
		})
		table.insert(waypoints, {
			position = Vector3.new(10, TRACK_Y + 3, colEndZ + 5),
			roomId = "CollapsedSection_Exit",
			dwellTime = 1,
		})

		-- Loot
		table.insert(lootPositions, {
			itemType = "Bandage", position = Vector3.new(10, TRACK_Y + 1, colStartZ - 15),
			chance = 1, guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Battery", position = Vector3.new(12, TRACK_Y + 1, colStartZ - 28),
			chance = 0.6, guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Flare", position = Vector3.new(8, TRACK_Y + 1, colEndZ + 3),
			chance = 0.3, guaranteed = false,
		})

		collapseModel.Parent = tunnelModel
	end

	--------------------------------------------------------------------
	-- ==================== UNFINISHED EXTENSION =====================
	--------------------------------------------------------------------
	do
		local extModel = Instance.new("Model")
		extModel.Name = "UnfinishedExtension"

		local extStartZ = DEEP_TUNNEL_START_Z
		local extEndZ = DEEP_TUNNEL_START_Z - 100

		-- Main path tunnel (raw concrete, no finishing)
		local mainPath = Shared.createTunnelSection(
			Vector3.new(0, TRACK_Y, extStartZ),
			Vector3.new(0, TRACK_Y, extEndZ),
			TUNNEL_WIDTH, TUNNEL_HEIGHT,
			extModel, "Extension_MainPath"
		)
		-- Override to raw concrete look
		for _, child in mainPath:GetDescendants() do
			if child:IsA("BasePart") then
				child.Color = RAW_CONCRETE_COLOR
				child.Material = Enum.Material.Concrete
			end
		end

		-- Exposed rebar in walls
		for i = 0, 7 do
			local rebar = Instance.new("Part")
			rebar.Name = `ExposedRebar_{i}`
			rebar.Size = Vector3.new(0.2, 3 + math.random() * 2, 0.2)
			rebar.Position = Vector3.new(
				(if i % 2 == 0 then -1 else 1) * (TUNNEL_WIDTH / 2),
				TRACK_Y + 3 + math.random() * 5,
				extStartZ - 10 - i * 12
			)
			rebar.Orientation = Vector3.new(math.random(-15, 15), 0, math.random(-15, 15))
			rebar.Anchored = true
			rebar.Material = Enum.Material.Metal
			rebar.Color = Color3.fromRGB(130, 80, 60)
			rebar.Parent = extModel
		end

		-- Construction scaffolding (maze-like, breaks sightlines)
		for i = 0, 4 do
			local scaffZ = extStartZ - 15 - i * 20

			-- Vertical poles
			for _, xOff in { -4, -1, 2, 5 } do
				local pole = Instance.new("Part")
				pole.Name = `ScaffoldPole_{i}_{xOff}`
				pole.Size = Vector3.new(0.3, TUNNEL_HEIGHT - 2, 0.3)
				pole.Position = Vector3.new(xOff, TRACK_Y + (TUNNEL_HEIGHT - 2) / 2, scaffZ)
				pole.Anchored = true
				pole.Material = Enum.Material.Metal
				pole.Color = Color3.fromRGB(140, 140, 50)
				pole.Parent = extModel
			end

			-- Horizontal platforms
			local platform = Instance.new("Part")
			platform.Name = `ScaffoldPlatform_{i}`
			platform.Size = Vector3.new(8, 0.3, 4)
			platform.Position = Vector3.new(0, TRACK_Y + 5 + (i % 2) * 3, scaffZ)
			platform.Anchored = true
			platform.Material = Enum.Material.DiamondPlate
			platform.Color = Color3.fromRGB(120, 120, 115)
			platform.Parent = extModel
		end

		-- Dormant boring machine
		do
			local bmZ = extEndZ + 15
			local boringBody = Instance.new("Part")
			boringBody.Name = "BoringMachine_Body"
			boringBody.Size = Vector3.new(8, 6, 12)
			boringBody.Position = Vector3.new(0, TRACK_Y + 3, bmZ)
			boringBody.Anchored = true
			boringBody.Material = Enum.Material.Metal
			boringBody.Color = Color3.fromRGB(120, 100, 50)
			boringBody.Parent = extModel

			-- Covered in webbing
			Shared.createWebbing(
				Vector3.new(0, TRACK_Y + 6, bmZ),
				8, 15, extModel, "BoringMachineWebbing"
			)

			-- Cutting head
			local cutHead = Instance.new("Part")
			cutHead.Name = "CuttingHead"
			cutHead.Shape = Enum.PartType.Cylinder
			cutHead.Size = Vector3.new(3, 7, 7)
			cutHead.Position = Vector3.new(0, TRACK_Y + 4, bmZ - 7)
			cutHead.Orientation = Vector3.new(90, 0, 0)
			cutHead.Anchored = true
			cutHead.Material = Enum.Material.Metal
			cutHead.Color = Color3.fromRGB(100, 90, 50)
			cutHead.Parent = extModel
		end

		-- Dead-end branch (construction office)
		do
			local deadEndZ = extStartZ - 40
			local deadEndX = -15

			-- Branch tunnel
			Shared.createCorridor(
				Vector3.new(-TUNNEL_WIDTH / 2, TRACK_Y, deadEndZ),
				Vector3.new(deadEndX, TRACK_Y, deadEndZ),
				5, TUNNEL_HEIGHT,
				extModel, "DeadEndBranch"
			)

			-- Dead-end wall
			Shared.createWall(
				Vector3.new(deadEndX - 15, TRACK_Y + TUNNEL_HEIGHT / 2, deadEndZ),
				Vector3.new(1, TUNNEL_HEIGHT, 6),
				extModel, "DeadEndWall"
			)

			-- Portable cabin (construction office)
			local cabin = Shared.createRoom({
				position = Vector3.new(deadEndX - 10, TRACK_Y, deadEndZ),
				size = Vector3.new(8, 8, 5),
				parent = extModel,
				name = "ConstructionOffice",
				wallColor = Color3.fromRGB(150, 140, 120),
				wallMaterial = Enum.Material.Metal,
				floorColor = Color3.fromRGB(110, 100, 85),
				floorMaterial = Enum.Material.Wood,
			})

			-- Desk with blueprints
			local desk = Instance.new("Part")
			desk.Name = "OfficeDeskTop"
			desk.Size = Vector3.new(5, 0.4, 2.5)
			desk.Position = Vector3.new(deadEndX - 10, TRACK_Y + 3, deadEndZ - 1)
			desk.Anchored = true
			desk.Material = Enum.Material.Wood
			desk.Color = Color3.fromRGB(100, 75, 55)
			desk.Parent = cabin

			-- Blueprints (Blackpoint documents with "VOID - DO NOT EXCAVATE")
			local blueprints = Instance.new("Part")
			blueprints.Name = "BlackpointBlueprints"
			blueprints.Size = Vector3.new(3, 0.02, 2)
			blueprints.Position = Vector3.new(deadEndX - 10, TRACK_Y + 3.5, deadEndZ - 1)
			blueprints.Anchored = true
			blueprints.Material = Enum.Material.SmoothPlastic
			blueprints.Color = Color3.fromRGB(200, 210, 220)
			blueprints.Parent = cabin

			local bpPrompt = Instance.new("ProximityPrompt")
			bpPrompt.ActionText = "Study"
			bpPrompt.ObjectText = "Blackpoint Blueprints"
			bpPrompt.HoldDuration = 1
			bpPrompt.MaxActivationDistance = 6
			bpPrompt.Parent = blueprints

			-- Modified radio equipment
			local radioEquip = Instance.new("Part")
			radioEquip.Name = "RadioEquipment"
			radioEquip.Size = Vector3.new(2, 1.5, 1)
			radioEquip.Position = Vector3.new(deadEndX - 12, TRACK_Y + 3.5, deadEndZ + 1)
			radioEquip.Anchored = true
			radioEquip.Material = Enum.Material.Metal
			radioEquip.Color = Color3.fromRGB(50, 50, 45)
			radioEquip.Parent = cabin
			radioEquip:SetAttribute("BiologicalMonitorFrequency", true)
		end

		-- Nest branch (side tunnel leading to the Nest)
		do
			local nestBranchZ = extStartZ - 60
			local nestBranchX = 15

			-- Branch tunnel
			Shared.createCorridor(
				Vector3.new(TUNNEL_WIDTH / 2, TRACK_Y, nestBranchZ),
				Vector3.new(nestBranchX + 10, TRACK_Y, nestBranchZ),
				5, TUNNEL_HEIGHT,
				extModel, "NestBranchTunnel"
			)

			-- Increasing webbing density approaching the Nest
			Shared.createWebbing(
				Vector3.new(nestBranchX, TRACK_Y + 5, nestBranchZ),
				4, 8, extModel, "NestApproachWebbing_1"
			)
			Shared.createWebbing(
				Vector3.new(nestBranchX + 5, TRACK_Y + 5, nestBranchZ),
				5, 15, extModel, "NestApproachWebbing_2"
			)
			Shared.createWebbing(
				Vector3.new(nestBranchX + 10, TRACK_Y + 5, nestBranchZ),
				6, 25, extModel, "NestApproachWebbing_3"
			)

			-- Breach in tunnel wall (entry to Nest cavity)
			local breach = Instance.new("Part")
			breach.Name = "NestBreach"
			breach.Size = Vector3.new(6, 8, 2)
			breach.Position = Vector3.new(nestBranchX + 12, TRACK_Y + 4, nestBranchZ)
			breach.Anchored = true
			breach.Material = Enum.Material.Concrete
			breach.Color = Color3.fromRGB(60, 55, 50)
			breach.Transparency = 0.8
			breach.CanCollide = false
			breach.Parent = extModel
			breach:SetAttribute("NestEntry", true)

			-- Faint warm glow from within (bioluminescence)
			local nestGlow = Instance.new("PointLight")
			nestGlow.Brightness = 0.05
			nestGlow.Color = BIOLUMINESCENT
			nestGlow.Range = 10
			nestGlow.Parent = breach
		end

		-- Webbing increases toward boring machine area
		Shared.createWebbing(
			Vector3.new(0, TRACK_Y + 8, extEndZ + 30),
			10, 20, extModel, "ExtensionWebbing"
		)

		-- Zero lighting (pitch black)
		-- No lights placed intentionally

		-- Waypoints
		for i = 0, 3 do
			table.insert(waypoints, {
				position = Vector3.new(0, TRACK_Y + 3, extStartZ - 20 - i * 25),
				roomId = `UnfinishedExtension_Section{i}`,
				dwellTime = 2,
			})
		end

		-- Loot
		-- Dead-end branch
		table.insert(lootPositions, {
			itemType = "Battery", position = Vector3.new(-25, TRACK_Y + 3.5, extStartZ - 40),
			chance = 1, guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Battery", position = Vector3.new(-23, TRACK_Y + 3.5, extStartZ - 40),
			chance = 1, guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Medkit", position = Vector3.new(-25, TRACK_Y + 1, extStartZ - 38),
			chance = 1, guaranteed = true,
		})
		-- Main path
		table.insert(lootPositions, {
			itemType = "Bandage", position = Vector3.new(3, TRACK_Y + 1, extStartZ - 50),
			chance = 0.5, guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Flare", position = Vector3.new(-3, TRACK_Y + 1, extStartZ - 75),
			chance = 0.3, guaranteed = false,
		})

		extModel.Parent = tunnelModel
	end

	--------------------------------------------------------------------
	-- ==================== THE NEST (Optional) ======================
	--------------------------------------------------------------------
	do
		local nestModel = Instance.new("Model")
		nestModel.Name = "TheNest"

		local nestBaseY = TRACK_Y - 10 -- below tunnel level
		local nestX = 25
		local nestZ = DEEP_TUNNEL_START_Z - 60

		-- Natural cavity (large irregular room)
		local nestRoom = Shared.createRoom({
			position = Vector3.new(nestX, nestBaseY, nestZ),
			size = Vector3.new(60, 50, 40),
			parent = nestModel,
			name = "NestCavity",
			wallColor = Color3.fromRGB(50, 45, 40),
			floorColor = Color3.fromRGB(40, 35, 30),
			ceilingColor = Color3.fromRGB(35, 30, 25),
			wallMaterial = Enum.Material.Rock,
			floorMaterial = Enum.Material.Rock,
			ceilingMaterial = Enum.Material.Rock,
		})

		-- Scaffolding ladder (entry from above)
		local ladderEntry = Instance.new("Part")
		ladderEntry.Name = "EntryLadder"
		ladderEntry.Size = Vector3.new(1.5, 12, 0.3)
		ladderEntry.Position = Vector3.new(nestX - 25, nestBaseY + 6, nestZ + 18)
		ladderEntry.Anchored = true
		ladderEntry.Material = Enum.Material.Metal
		ladderEntry.Color = Color3.fromRGB(120, 120, 115)
		ladderEntry.Parent = nestRoom
		ladderEntry:SetAttribute("ClimbDuration", 3)

		-- Organic webbing throughout (dense, architectural)
		for i = 1, 8 do
			local angle = (i / 8) * math.pi * 2
			local radius = 15 + math.random() * 8
			Shared.createWebbing(
				Vector3.new(
					nestX + math.cos(angle) * radius,
					nestBaseY + 5 + math.random() * 20,
					nestZ + math.sin(angle) * radius
				),
				8, 30, nestRoom, `NestWebbing_Pillar_{i}`
			)
		end

		-- Floor webbing (dense layer)
		Shared.createWebbing(
			Vector3.new(nestX, nestBaseY + 1, nestZ),
			25, 40, nestRoom, "NestFloorWebbing"
		)

		-- Alcove chambers (body-sized, around perimeter)
		for i = 0, 5 do
			local angle = (i / 6) * math.pi * 2
			local radius = 25
			local alcovePos = Vector3.new(
				nestX + math.cos(angle) * radius,
				nestBaseY + 2,
				nestZ + math.sin(angle) * radius
			)

			local alcove = Instance.new("Part")
			alcove.Name = `TransformationAlcove_{i}`
			alcove.Size = Vector3.new(3, 5, 2)
			alcove.Position = alcovePos
			alcove.Anchored = true
			alcove.Material = Enum.Material.Rock
			alcove.Color = Color3.fromRGB(45, 40, 35)
			alcove.Parent = nestRoom

			-- Webbing cocoon in some alcoves
			if i % 2 == 0 then
				Shared.createWebbing(
					alcovePos + Vector3.new(0, 1, 0),
					2, 12, nestRoom, `AlcoveCocoon_{i}`
				)
			end
		end

		-- Central mound (8 studs tall, pulsing organic mass)
		local mound = Instance.new("Part")
		mound.Name = "CentralMound"
		mound.Shape = Enum.PartType.Ball
		mound.Size = Vector3.new(16, 16, 16)
		mound.Position = Vector3.new(nestX, nestBaseY + 4, nestZ)
		mound.Anchored = true
		mound.Material = Enum.Material.Fabric
		mound.Color = Color3.fromRGB(80, 60, 50)
		mound.Parent = nestRoom
		mound:SetAttribute("Pulsing", true)
		mound:SetAttribute("PulseRate", 2.5)

		-- Pulsing organic base
		local organicBase = Instance.new("Part")
		organicBase.Name = "OrganicBase"
		organicBase.Size = Vector3.new(10, 3, 10)
		organicBase.Position = Vector3.new(nestX, nestBaseY + 1.5, nestZ)
		organicBase.Anchored = true
		organicBase.Material = Enum.Material.Fabric
		organicBase.Color = Color3.fromRGB(100, 70, 55)
		organicBase.Parent = nestRoom

		-- Bioluminescent glow from webbing
		for i = 1, 6 do
			local glowPos = Vector3.new(
				nestX + (math.random() - 0.5) * 40,
				nestBaseY + 2 + math.random() * 15,
				nestZ + (math.random() - 0.5) * 30
			)
			local glow = Instance.new("Part")
			glow.Name = `BioGlow_{i}`
			glow.Size = Vector3.new(1, 1, 1)
			glow.Position = glowPos
			glow.Anchored = true
			glow.Material = Enum.Material.Neon
			glow.Color = BIOLUMINESCENT
			glow.Transparency = 0.7
			glow.CanCollide = false
			glow.Parent = nestRoom

			local bioLight = Instance.new("PointLight")
			bioLight.Brightness = 0.03
			bioLight.Color = BIOLUMINESCENT
			bioLight.Range = 5
			bioLight.Parent = glow
		end

		-- Blackpoint containment unit (far side of mound)
		do
			local cuPos = Vector3.new(nestX + 15, nestBaseY, nestZ - 5)

			local container = Instance.new("Part")
			container.Name = "ContainmentUnit"
			container.Size = Vector3.new(6, 8, 4)
			container.Position = cuPos + Vector3.new(0, 4, 0)
			container.Anchored = true
			container.Material = Enum.Material.Metal
			container.Color = Color3.fromRGB(60, 65, 60)
			container.Parent = nestRoom

			-- Ripped-open door
			local cuDoor = Instance.new("Part")
			cuDoor.Name = "RippedDoor"
			cuDoor.Size = Vector3.new(3, 7, 0.5)
			cuDoor.Position = cuPos + Vector3.new(0, 3.5, 2.5)
			cuDoor.Orientation = Vector3.new(0, 30, -15) -- bent outward
			cuDoor.Anchored = true
			cuDoor.Material = Enum.Material.Metal
			cuDoor.Color = Color3.fromRGB(50, 55, 50)
			cuDoor.Parent = nestRoom

			-- Empty restraint systems inside
			for i = 0, 1 do
				local restraint = Instance.new("Part")
				restraint.Name = `Restraint_{i}`
				restraint.Size = Vector3.new(0.5, 5, 0.5)
				restraint.Position = cuPos + Vector3.new(-1 + i * 2, 2.5, 0)
				restraint.Anchored = true
				restraint.Material = Enum.Material.Metal
				restraint.Color = Color3.fromRGB(120, 120, 115)
				restraint.Parent = nestRoom
			end

			-- Data drive (key lore item)
			local dataDrive = Instance.new("Part")
			dataDrive.Name = "BlackpointDataDrive"
			dataDrive.Size = Vector3.new(0.8, 0.3, 0.5)
			dataDrive.Position = cuPos + Vector3.new(0, 1, 0)
			dataDrive.Anchored = true
			dataDrive.Material = Enum.Material.Metal
			dataDrive.Color = Color3.fromRGB(30, 30, 28)
			dataDrive.Parent = nestRoom

			local drivePrompt = Instance.new("ProximityPrompt")
			drivePrompt.ActionText = "Take"
			drivePrompt.ObjectText = "Blackpoint Data Drive"
			drivePrompt.HoldDuration = 5
			drivePrompt.MaxActivationDistance = 6
			drivePrompt.Parent = dataDrive

			-- Specimen transit manifest
			local manifest = Instance.new("Part")
			manifest.Name = "TransitManifest"
			manifest.Size = Vector3.new(0.6, 0.02, 0.8)
			manifest.Position = cuPos + Vector3.new(1, 0.5, -0.5)
			manifest.Anchored = true
			manifest.Material = Enum.Material.SmoothPlastic
			manifest.Color = Color3.fromRGB(220, 215, 200)
			manifest.Parent = nestRoom

			local manifestPrompt = Instance.new("ProximityPrompt")
			manifestPrompt.ActionText = "Read"
			manifestPrompt.ObjectText = "Specimen Transit Manifest"
			manifestPrompt.HoldDuration = 5
			manifestPrompt.MaxActivationDistance = 6
			manifestPrompt.Parent = manifest
		end

		-- Nest entity attributes
		nestModel:SetAttribute("NestArea", true)
		nestModel:SetAttribute("ResidentCrawlers", 2)
		nestModel:SetAttribute("CeilingDormant", true)
		nestModel:SetAttribute("ConvergenceTimer", 90) -- seconds before full pack arrives
		nestModel:SetAttribute("PermanentFearTier", "Unease")

		-- Bones on the floor
		for i = 1, 12 do
			local bone = Instance.new("Part")
			bone.Name = `Bone_{i}`
			bone.Size = Vector3.new(0.15 + math.random() * 0.3, 0.15, 0.8 + math.random() * 1.5)
			bone.Position = Vector3.new(
				nestX + (math.random() - 0.5) * 40,
				nestBaseY + 0.1,
				nestZ + (math.random() - 0.5) * 30
			)
			bone.Orientation = Vector3.new(0, math.random(0, 360), 0)
			bone.Anchored = true
			bone.Material = Enum.Material.SmoothPlastic
			bone.Color = Color3.fromRGB(200, 195, 175)
			bone.Parent = nestRoom
		end

		-- Waypoints (Crawler patrol)
		table.insert(waypoints, {
			position = Vector3.new(nestX, nestBaseY + 3, nestZ),
			roomId = "TheNest_Center",
			dwellTime = 5,
		})
		table.insert(waypoints, {
			position = Vector3.new(nestX - 20, nestBaseY + 3, nestZ),
			roomId = "TheNest_West",
			dwellTime = 3,
		})
		table.insert(waypoints, {
			position = Vector3.new(nestX + 20, nestBaseY + 3, nestZ),
			roomId = "TheNest_East",
			dwellTime = 3,
		})

		-- Loot
		table.insert(lootPositions, {
			itemType = "Lore", position = Vector3.new(nestX + 15, nestBaseY + 1, nestZ - 5),
			chance = 1, guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Lore", position = Vector3.new(nestX + 16, nestBaseY + 0.5, nestZ - 5.5),
			chance = 1, guaranteed = true,
		})
		-- Medkit near exit (mercy placement)
		table.insert(lootPositions, {
			itemType = "Medkit", position = Vector3.new(nestX - 25, nestBaseY + 1, nestZ + 18),
			chance = 1, guaranteed = true,
		})

		nestModel.Parent = tunnelModel
	end

	--------------------------------------------------------------------
	-- ==================== DRAINAGE SYSTEM ==========================
	--------------------------------------------------------------------
	do
		local drainModel = Instance.new("Model")
		drainModel.Name = "DrainageSystem"

		local drainY = TRACK_Y - 5 -- below tunnel level
		local drainStartZ = DEEP_TUNNEL_START_Z - 100
		local drainDiameter = 15

		-- Entry hatch (from Unfinished Extension floor)
		local hatch = Instance.new("Part")
		hatch.Name = "DrainageHatch"
		hatch.Size = Vector3.new(4, 0.3, 4)
		hatch.Position = Vector3.new(0, TRACK_Y, drainStartZ + 5)
		hatch.Anchored = true
		hatch.Material = Enum.Material.Metal
		hatch.Color = Color3.fromRGB(80, 80, 75)
		hatch.Parent = drainModel
		hatch:SetAttribute("DropDown", true)

		-- Segment 1: straight south (30 studs)
		local seg1EndZ = drainStartZ - 30
		Shared.createCorridor(
			Vector3.new(0, drainY, drainStartZ),
			Vector3.new(0, drainY, seg1EndZ),
			drainDiameter, drainDiameter,
			drainModel, "DrainSeg1"
		)

		-- Right-angle bend 1 (turn west)
		local bend1X = -5
		Shared.createCorridor(
			Vector3.new(0, drainY, seg1EndZ),
			Vector3.new(-30, drainY, seg1EndZ),
			drainDiameter, drainDiameter,
			drainModel, "DrainBend1"
		)

		-- Vertical access shaft at bend 1 (Crawler entry from above)
		local shaft1 = Instance.new("Part")
		shaft1.Name = "AccessShaft_1"
		shaft1.Size = Vector3.new(4, 15, 4)
		shaft1.Position = Vector3.new(bend1X, drainY + 7.5, seg1EndZ)
		shaft1.Anchored = true
		shaft1.Material = Enum.Material.Concrete
		shaft1.Color = RAW_CONCRETE_COLOR
		shaft1.Transparency = 0.9
		shaft1.CanCollide = false
		shaft1.Parent = drainModel
		shaft1:SetAttribute("CrawlerEntryShaft", true)

		-- Segment 2: south again (25 studs)
		local seg2StartZ = seg1EndZ
		local seg2EndZ = seg2StartZ - 25
		Shared.createCorridor(
			Vector3.new(-30, drainY, seg2StartZ),
			Vector3.new(-30, drainY, seg2EndZ),
			drainDiameter, drainDiameter,
			drainModel, "DrainSeg2"
		)

		-- Feeder pipe (small, Crawler entry)
		local feederPipe = Instance.new("Part")
		feederPipe.Name = "FeederPipe"
		feederPipe.Shape = Enum.PartType.Cylinder
		feederPipe.Size = Vector3.new(6, 3, 3)
		feederPipe.Position = Vector3.new(-30 + drainDiameter / 2 + 3, drainY + 3, (seg2StartZ + seg2EndZ) / 2)
		feederPipe.Orientation = Vector3.new(0, 0, 90)
		feederPipe.Anchored = true
		feederPipe.Material = Enum.Material.Concrete
		feederPipe.Color = Color3.fromRGB(70, 68, 62)
		feederPipe.Parent = drainModel
		feederPipe:SetAttribute("CrawlerEntry", true)

		-- Right-angle bend 2 (turn west again)
		Shared.createCorridor(
			Vector3.new(-30, drainY, seg2EndZ),
			Vector3.new(-50, drainY, seg2EndZ),
			drainDiameter, drainDiameter,
			drainModel, "DrainBend2"
		)

		-- Vertical access shaft at bend 2
		local shaft2 = Instance.new("Part")
		shaft2.Name = "AccessShaft_2"
		shaft2.Size = Vector3.new(4, 15, 4)
		shaft2.Position = Vector3.new(-40, drainY + 7.5, seg2EndZ)
		shaft2.Anchored = true
		shaft2.Material = Enum.Material.Concrete
		shaft2.Color = RAW_CONCRETE_COLOR
		shaft2.Transparency = 0.9
		shaft2.CanCollide = false
		shaft2.Parent = drainModel
		shaft2:SetAttribute("CrawlerEntryShaft", true)

		-- Final segment to Terminus
		local finalEndZ = seg2EndZ - 20
		Shared.createCorridor(
			Vector3.new(-50, drainY, seg2EndZ),
			Vector3.new(-50, drainY, finalEndZ),
			drainDiameter, drainDiameter,
			drainModel, "DrainFinal"
		)

		-- Shallow running water throughout
		Shared.createWaterVolume(
			Vector3.new(0, drainY + 1, drainStartZ - 15),
			Vector3.new(drainDiameter, 2, 30),
			drainModel, "DrainWater_Seg1"
		)
		Shared.createWaterVolume(
			Vector3.new(-30, drainY + 1, (seg2StartZ + seg2EndZ) / 2),
			Vector3.new(drainDiameter, 2, 25),
			drainModel, "DrainWater_Seg2"
		)
		Shared.createWaterVolume(
			Vector3.new(-50, drainY + 1, seg2EndZ - 10),
			Vector3.new(drainDiameter, 2, 20),
			drainModel, "DrainWater_Final"
		)

		-- Discolored water (darker fluid from Nest direction)
		for _, waterPart in drainModel:GetDescendants() do
			if waterPart:IsA("BasePart") and waterPart:GetAttribute("IsWater") then
				waterPart.Color = Color3.fromRGB(35, 40, 35) -- darker, contaminated
			end
		end

		-- Exit ladder up to Terminus
		local exitLadder = Instance.new("Part")
		exitLadder.Name = "TerminusLadder"
		exitLadder.Size = Vector3.new(1.5, 20, 0.3)
		exitLadder.Position = Vector3.new(-50, drainY + 10, finalEndZ + 2)
		exitLadder.Anchored = true
		exitLadder.Material = Enum.Material.Metal
		exitLadder.Color = Color3.fromRGB(120, 120, 115)
		exitLadder.Parent = drainModel
		exitLadder:SetAttribute("ClimbDuration", 4)

		-- Drainage system attributes
		drainModel:SetAttribute("EchoChamber", true)
		drainModel:SetAttribute("DirectionalAudioUnreliable", true)

		-- No lighting (total darkness)

		-- Waypoints
		table.insert(waypoints, {
			position = Vector3.new(0, drainY + 3, drainStartZ - 15),
			roomId = "Drainage_Seg1",
			dwellTime = 1.5,
		})
		table.insert(waypoints, {
			position = Vector3.new(-30, drainY + 3, (seg2StartZ + seg2EndZ) / 2),
			roomId = "Drainage_Seg2",
			dwellTime = 1.5,
		})
		table.insert(waypoints, {
			position = Vector3.new(-50, drainY + 3, finalEndZ + 5),
			roomId = "Drainage_Exit",
			dwellTime = 1,
		})

		-- Loot
		table.insert(lootPositions, {
			itemType = "Battery", position = Vector3.new(-30, drainY + 1, seg2StartZ - 10),
			chance = 1, guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Bandage", position = Vector3.new(-50, drainY + 1, finalEndZ + 8),
			chance = 0.5, guaranteed = false,
		})

		drainModel.Parent = tunnelModel
	end

	tunnelModel.Parent = parent

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return Tunnels
