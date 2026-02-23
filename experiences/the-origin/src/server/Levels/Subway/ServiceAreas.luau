--!strict

--[[
	Subway/ServiceAreas - Builds the staff-only and service areas
	connecting the main station spaces.

	Areas:
		- Connecting corridors between Hargrove areas
		- Stairwells between Ticket Hall, Mezzanine, and Platforms
		- Transition tunnels between Hargrove and the tunnel network
		- Transition from Moorfield Concourse to Deep Tunnels
		- Emergency lighting infrastructure
		- Atmospheric details (pipes, grates, drip points, signage)

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

local TICKET_HALL_Y = -8
local MEZZANINE_Y = -16
local PLATFORM_Y = -24
local TRACK_Y = -28
local ROOM_HEIGHT = 12
local TUNNEL_HEIGHT = 14

local MOORFIELD_Z_OFFSET = -350
local DEEP_TUNNEL_START_Z = -360

-- Colors
local CONCRETE_COLOR = Color3.fromRGB(100, 98, 92)
local SERVICE_WALL_COLOR = Color3.fromRGB(120, 118, 112)
local SERVICE_FLOOR_COLOR = Color3.fromRGB(90, 90, 85)
local AMBER_LIGHT = Color3.fromRGB(255, 180, 80)
local DIM_RED = Color3.fromRGB(180, 40, 30)

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local ServiceAreas = {}

function ServiceAreas.build(parent: Instance): FloorData
	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	local serviceModel = Instance.new("Model")
	serviceModel.Name = "ServiceAreas"

	--------------------------------------------------------------------
	-- Hargrove Street: Ticket Hall to Mezzanine Stairwell
	--------------------------------------------------------------------
	do
		local stairModel = Instance.new("Model")
		stairModel.Name = "TicketToMezzanineStairs"

		-- Connecting corridor from Ticket Hall south to Mezzanine north
		Shared.createCorridor(
			Vector3.new(0, TICKET_HALL_Y, 12),
			Vector3.new(0, TICKET_HALL_Y, 18),
			8, ROOM_HEIGHT,
			stairModel, "TicketToMezz_Corridor"
		)

		-- Stairs down
		Shared.createStairwell(
			MEZZANINE_Y, TICKET_HALL_Y,
			Vector3.new(0, 0, 15),
			stairModel, "TicketToMezz_Stairs"
		)

		-- Dim transition lights
		Shared.createLight(
			Vector3.new(0, TICKET_HALL_Y + ROOM_HEIGHT - 0.5, 15),
			stairModel, 0.2, AMBER_LIGHT
		)

		-- Ceiling pipes
		Shared.createPipe(
			Vector3.new(0, TICKET_HALL_Y + ROOM_HEIGHT - 1.5, 15),
			10, 0.25,
			Vector3.new(0, 0, 90),
			stairModel, "TransitionPipe"
		)

		-- Waypoint at top of stairs
		table.insert(waypoints, {
			position = Vector3.new(0, TICKET_HALL_Y + 3, 15),
			roomId = "TicketToMezz_Transition",
			dwellTime = 1,
		})

		stairModel.Parent = serviceModel
	end

	--------------------------------------------------------------------
	-- Hargrove Street: Mezzanine to Platform A Stairwell
	--------------------------------------------------------------------
	do
		local stairModel = Instance.new("Model")
		stairModel.Name = "MezzToPlatformA_Stairs"

		-- Corridor to stairs
		Shared.createCorridor(
			Vector3.new(-8, MEZZANINE_Y, 30),
			Vector3.new(-8, MEZZANINE_Y, 38),
			6, ROOM_HEIGHT,
			stairModel, "MezzToA_Corridor"
		)

		-- Stairs down
		Shared.createStairwell(
			PLATFORM_Y, MEZZANINE_Y,
			Vector3.new(-8, 0, 35),
			stairModel, "MezzToA_Stairs"
		)

		-- Dim light
		Shared.createLight(
			Vector3.new(-8, MEZZANINE_Y + ROOM_HEIGHT - 0.5, 35),
			stairModel, 0.15, AMBER_LIGHT
		)

		-- Waypoint
		table.insert(waypoints, {
			position = Vector3.new(-8, MEZZANINE_Y + 3, 35),
			roomId = "MezzToA_Transition",
			dwellTime = 1,
		})

		stairModel.Parent = serviceModel
	end

	--------------------------------------------------------------------
	-- Hargrove Street: Mezzanine to Platform B Stairwell
	--------------------------------------------------------------------
	do
		local stairModel = Instance.new("Model")
		stairModel.Name = "MezzToPlatformB_Stairs"

		Shared.createCorridor(
			Vector3.new(8, MEZZANINE_Y, 30),
			Vector3.new(8, MEZZANINE_Y, 38),
			6, ROOM_HEIGHT,
			stairModel, "MezzToB_Corridor"
		)

		Shared.createStairwell(
			PLATFORM_Y, MEZZANINE_Y,
			Vector3.new(8, 0, 35),
			stairModel, "MezzToB_Stairs"
		)

		Shared.createLight(
			Vector3.new(8, MEZZANINE_Y + ROOM_HEIGHT - 0.5, 35),
			stairModel, 0.15, AMBER_LIGHT
		)

		table.insert(waypoints, {
			position = Vector3.new(8, MEZZANINE_Y + 3, 35),
			roomId = "MezzToB_Transition",
			dwellTime = 1,
		})

		stairModel.Parent = serviceModel
	end

	--------------------------------------------------------------------
	-- Hargrove: Platform A to Tunnel Entry Transition
	--------------------------------------------------------------------
	do
		local transModel = Instance.new("Model")
		transModel.Name = "PlatformToTunnel_Transition"

		-- Ramp/corridor from platform level down to track level
		-- and forward into the tunnel network
		Shared.createCorridor(
			Vector3.new(-10, TRACK_Y, 55),
			Vector3.new(-10, TRACK_Y, 70),
			12, TUNNEL_HEIGHT,
			transModel, "TunnelEntry_Corridor"
		)

		-- Track continues into tunnel
		Shared.createTrackBed(
			Vector3.new(-10, TRACK_Y, 55),
			Vector3.new(-10, TRACK_Y, 70),
			transModel, "TunnelEntry_Track"
		)

		-- Transition from tiled walls to raw concrete
		-- Left half: tile
		local tileSection = Shared.createWall(
			Vector3.new(-16.5, TRACK_Y + TUNNEL_HEIGHT / 2, 62),
			Vector3.new(1, TUNNEL_HEIGHT, 8),
			transModel, "TileToConcreteTransition_L"
		)
		tileSection.Color = Color3.fromRGB(165, 170, 165)

		-- Emergency light at tunnel mouth
		Shared.createEmergencyLight(
			Vector3.new(-10, TRACK_Y + TUNNEL_HEIGHT - 1, 65),
			transModel, DIM_RED
		)

		-- "MIND THE GAP" sign
		local mindGap = Instance.new("Part")
		mindGap.Name = "MindTheGapSign"
		mindGap.Size = Vector3.new(3, 0.5, 0.1)
		mindGap.Position = Vector3.new(-10, PLATFORM_Y + 0.3, 51.5)
		mindGap.Anchored = true
		mindGap.Material = Enum.Material.SmoothPlastic
		mindGap.Color = Color3.fromRGB(200, 190, 50)
		mindGap.Parent = transModel

		table.insert(waypoints, {
			position = Vector3.new(-10, TRACK_Y + 3, 65),
			roomId = "TunnelEntry",
			dwellTime = 1.5,
		})

		transModel.Parent = serviceModel
	end

	--------------------------------------------------------------------
	-- Moorfield: Tunnel Exit to Platform Transition
	--------------------------------------------------------------------
	do
		local transModel = Instance.new("Model")
		transModel.Name = "TunnelToMoorfield_Transition"

		-- Corridor from tunnel end to Moorfield platform west side
		Shared.createCorridor(
			Vector3.new(-30, TRACK_Y, MOORFIELD_Z_OFFSET - 5),
			Vector3.new(-30, TRACK_Y, MOORFIELD_Z_OFFSET + 5),
			12, TUNNEL_HEIGHT,
			transModel, "MoorfieldEntry_Corridor"
		)

		-- Track bed
		Shared.createTrackBed(
			Vector3.new(-30, TRACK_Y, MOORFIELD_Z_OFFSET - 5),
			Vector3.new(-30, TRACK_Y, MOORFIELD_Z_OFFSET + 5),
			transModel, "MoorfieldEntry_Track"
		)

		-- Emergency light
		Shared.createEmergencyLight(
			Vector3.new(-30, TRACK_Y + TUNNEL_HEIGHT - 1, MOORFIELD_Z_OFFSET),
			transModel, Color3.fromRGB(180, 200, 255) -- blue-white for Moorfield
		)

		table.insert(waypoints, {
			position = Vector3.new(-30, TRACK_Y + 3, MOORFIELD_Z_OFFSET),
			roomId = "MoorfieldTunnelEntry",
			dwellTime = 1.5,
		})

		transModel.Parent = serviceModel
	end

	--------------------------------------------------------------------
	-- Moorfield: Concourse to Deep Tunnels Transition
	--------------------------------------------------------------------
	do
		local transModel = Instance.new("Model")
		transModel.Name = "ConcourseTODeepTunnels"

		local concSouthZ = MOORFIELD_Z_OFFSET + 12 -- south edge of concourse

		-- Security gate passage (already broken, from Platform.luau)
		-- Corridor descending to deep tunnel level
		Shared.createCorridor(
			Vector3.new(40, PLATFORM_Y, concSouthZ),
			Vector3.new(40, PLATFORM_Y, concSouthZ + 15),
			8, ROOM_HEIGHT,
			transModel, "DeepTunnelApproach"
		)

		-- Ramp section (descending to track level)
		-- Simplified as a stairwell
		Shared.createStairwell(
			TRACK_Y, PLATFORM_Y,
			Vector3.new(40, 0, concSouthZ + 20),
			transModel, "DeepTunnelRamp"
		)

		-- Connecting corridor to deep tunnel start
		Shared.createCorridor(
			Vector3.new(40, TRACK_Y, concSouthZ + 25),
			Vector3.new(0, TRACK_Y, DEEP_TUNNEL_START_Z),
			10, TUNNEL_HEIGHT,
			transModel, "DeepTunnelConnector"
		)

		-- Signage (defaced)
		local deepSign = Instance.new("Part")
		deepSign.Name = "DeepTunnelSign"
		deepSign.Size = Vector3.new(4, 1, 0.1)
		deepSign.Position = Vector3.new(40, PLATFORM_Y + 8, concSouthZ + 5)
		deepSign.Anchored = true
		deepSign.Material = Enum.Material.SmoothPlastic
		deepSign.Color = Color3.fromRGB(30, 80, 30)
		deepSign.Parent = transModel
		deepSign:SetAttribute("Text", "DEEP TUNNELS - AUTHORIZED PERSONNEL ONLY")
		deepSign:SetAttribute("Defaced", true)

		-- Emergency light at entrance
		Shared.createEmergencyLight(
			Vector3.new(40, PLATFORM_Y + ROOM_HEIGHT - 1, concSouthZ + 5),
			transModel, DIM_RED
		)

		-- Last light before deep tunnel darkness
		Shared.createEmergencyLight(
			Vector3.new(20, TRACK_Y + TUNNEL_HEIGHT - 1, DEEP_TUNNEL_START_Z + 5),
			transModel, DIM_RED
		)

		table.insert(waypoints, {
			position = Vector3.new(40, PLATFORM_Y + 3, concSouthZ + 10),
			roomId = "DeepTunnelApproach",
			dwellTime = 1.5,
		})
		table.insert(waypoints, {
			position = Vector3.new(20, TRACK_Y + 3, DEEP_TUNNEL_START_Z + 5),
			roomId = "DeepTunnelEntry",
			dwellTime = 2,
		})

		transModel.Parent = serviceModel
	end

	--------------------------------------------------------------------
	-- Underground Infrastructure Details
	--------------------------------------------------------------------
	do
		local infraModel = Instance.new("Model")
		infraModel.Name = "Infrastructure"

		-- Drainage grates along platform edges (Hargrove)
		for i = 0, 4 do
			local grate = Instance.new("Part")
			grate.Name = `DrainGrate_{i}`
			grate.Size = Vector3.new(2, 0.1, 0.5)
			grate.Position = Vector3.new(-20 + i * 10, PLATFORM_Y + 0.05, 50)
			grate.Anchored = true
			grate.Material = Enum.Material.Metal
			grate.Color = Color3.fromRGB(80, 80, 75)
			grate.Parent = infraModel
		end

		-- Ventilation grates in ceilings throughout
		for i = 0, 2 do
			local vent = Instance.new("Part")
			vent.Name = `CeilingVent_Hargrove_{i}`
			vent.Size = Vector3.new(3, 0.2, 3)
			vent.Position = Vector3.new(-10 + i * 10, MEZZANINE_Y + ROOM_HEIGHT + 0.1, 20)
			vent.Anchored = true
			vent.Material = Enum.Material.Metal
			vent.Color = Color3.fromRGB(90, 90, 85)
			vent.Parent = infraModel
			vent:SetAttribute("CrawlerPathway", true)
		end

		-- Ceiling pipes running through service corridors
		for i = 0, 8 do
			Shared.createPipe(
				Vector3.new(0, MEZZANINE_Y + ROOM_HEIGHT - 1.5, 15 + i * 3),
				8, 0.2,
				Vector3.new(0, 0, 90),
				infraModel, `ServicePipe_Mezz_{i}`
			)
		end

		-- Drip points throughout (atmospheric)
		local dripPositions = {
			Vector3.new(-5, MEZZANINE_Y + ROOM_HEIGHT - 1, 25),
			Vector3.new(5, PLATFORM_Y + TUNNEL_HEIGHT - 1, 48),
			Vector3.new(0, TICKET_HALL_Y + ROOM_HEIGHT - 1, 5),
		}
		for i, pos in dripPositions do
			local drip = Instance.new("Part")
			drip.Name = `DripPoint_{i}`
			drip.Size = Vector3.new(0.4, 0.4, 0.4)
			drip.Position = pos
			drip.Anchored = true
			drip.Transparency = 0.9
			drip.CanCollide = false
			drip.Material = Enum.Material.Glass
			drip.Color = Color3.fromRGB(100, 130, 150)
			drip.Parent = infraModel

			-- Puddle below
			local puddle = Instance.new("Part")
			puddle.Name = `Puddle_{i}`
			puddle.Size = Vector3.new(1.5, 0.03, 1.5)
			puddle.Position = Vector3.new(pos.X, PLATFORM_Y + 0.02, pos.Z)
			puddle.Anchored = true
			puddle.Material = Enum.Material.Glass
			puddle.Color = Color3.fromRGB(60, 80, 100)
			puddle.Transparency = 0.5
			puddle.Parent = infraModel
		end

		-- Fire extinguisher stations (wall-mounted, throughout)
		local extPositions = {
			{ pos = Vector3.new(-15, MEZZANINE_Y + 4, 10), rot = 0 },
			{ pos = Vector3.new(15, PLATFORM_Y + 4, 40), rot = 0 },
			{ pos = Vector3.new(0, TRACK_Y + 4, MOORFIELD_Z_OFFSET - 5), rot = 90 },
		}
		for i, ext in extPositions do
			local extinguisher = Instance.new("Part")
			extinguisher.Name = `FireExtinguisher_{i}`
			extinguisher.Shape = Enum.PartType.Cylinder
			extinguisher.Size = Vector3.new(1.5, 0.6, 0.6)
			extinguisher.CFrame = CFrame.new(ext.pos) * CFrame.Angles(0, math.rad(ext.rot), 0)
			extinguisher.Anchored = true
			extinguisher.Material = Enum.Material.Metal
			extinguisher.Color = Color3.fromRGB(180, 40, 30)
			extinguisher.Parent = infraModel
		end

		-- Directional signage throughout
		local signs = {
			{ text = "PLATFORM A", pos = Vector3.new(-5, MEZZANINE_Y + 8, 25), color = Color3.fromRGB(40, 80, 150) },
			{ text = "PLATFORM B", pos = Vector3.new(5, MEZZANINE_Y + 8, 25), color = Color3.fromRGB(40, 80, 150) },
			{ text = "TICKET HALL", pos = Vector3.new(0, MEZZANINE_Y + 8, 12), color = Color3.fromRGB(40, 80, 150) },
			{ text = "WAY OUT", pos = Vector3.new(0, TICKET_HALL_Y + 8, -5), color = Color3.fromRGB(40, 150, 40) },
			{ text = "STAFF ONLY", pos = Vector3.new(20, TICKET_HALL_Y + 8, 6), color = Color3.fromRGB(150, 40, 40) },
		}
		for i, signDef in signs do
			local sign = Instance.new("Part")
			sign.Name = `Sign_{i}`
			sign.Size = Vector3.new(4, 1, 0.1)
			sign.Position = signDef.pos
			sign.Anchored = true
			sign.Material = Enum.Material.SmoothPlastic
			sign.Color = signDef.color
			sign.Parent = infraModel
			sign:SetAttribute("Text", signDef.text)
		end

		-- Emergency exit arrows (Hargrove)
		for i = 0, 2 do
			local arrow = Instance.new("Part")
			arrow.Name = `ExitArrow_{i}`
			arrow.Size = Vector3.new(1, 0.5, 0.05)
			arrow.Position = Vector3.new(-10 + i * 10, PLATFORM_Y + 8, 40)
			arrow.Anchored = true
			arrow.Material = Enum.Material.Neon
			arrow.Color = Color3.fromRGB(30, 150, 30)
			arrow.Transparency = 0.3
			arrow.Parent = infraModel
		end

		infraModel.Parent = serviceModel
	end

	--------------------------------------------------------------------
	-- Scattered Environmental Storytelling
	--------------------------------------------------------------------
	do
		local storyModel = Instance.new("Model")
		storyModel.Name = "EnvironmentalStory"

		-- Transit authority posters (Hargrove)
		for i = 0, 2 do
			local poster = Instance.new("Part")
			poster.Name = `Poster_{i}`
			poster.Size = Vector3.new(2, 2.5, 0.05)
			poster.Position = Vector3.new(-15 + i * 15, MEZZANINE_Y + 6, 9.9)
			poster.Anchored = true
			poster.Material = Enum.Material.SmoothPlastic
			poster.Color = Color3.fromRGB(200, 195, 180)
			poster.Parent = storyModel
		end

		-- Safety notice about "reporting unusual sounds"
		local safetyNotice = Instance.new("Part")
		safetyNotice.Name = "SafetyNotice"
		safetyNotice.Size = Vector3.new(1.5, 2, 0.05)
		safetyNotice.Position = Vector3.new(19, TICKET_HALL_Y + 5.5, -12)
		safetyNotice.Anchored = true
		safetyNotice.Material = Enum.Material.SmoothPlastic
		safetyNotice.Color = Color3.fromRGB(200, 200, 50)
		safetyNotice.Parent = storyModel
		safetyNotice:SetAttribute("Text", "REPORT UNUSUAL SOUNDS FROM SERVICE TUNNELS TO STATION MANAGER")

		-- Defaced advertising board (Mezzanine)
		-- One board with scratched symbols matching Patient 31's cell
		local defacedBoard = Instance.new("Part")
		defacedBoard.Name = "DefacedAdBoard"
		defacedBoard.Size = Vector3.new(4, 3, 0.2)
		defacedBoard.Position = Vector3.new(17, MEZZANINE_Y + 6, 24)
		defacedBoard.Anchored = true
		defacedBoard.Material = Enum.Material.SmoothPlastic
		defacedBoard.Color = Color3.fromRGB(180, 175, 165)
		defacedBoard.Parent = storyModel
		defacedBoard:SetAttribute("DefacedSymbols", true)
		defacedBoard:SetAttribute("MatchesPatient31", true)

		-- Scattered debris near tunnel entrances (something came through)
		Shared.createRubble(
			Vector3.new(-10, TRACK_Y, 60), 4, 5,
			storyModel, "TunnelMouthDebris"
		)

		storyModel.Parent = serviceModel
	end

	serviceModel.Parent = parent

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return ServiceAreas
