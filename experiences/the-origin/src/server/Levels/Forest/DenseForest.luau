--!strict

--[[
	Forest/DenseForest - Builds the main forest terrain, trail system,
	dense woods zones, the clearing, creek bed, abandoned campsite,
	and The Ring safe zone.

	This is the largest area module: ~600x600 studs of navigable terrain
	between the Ranger Station (south) and the Ridge (north).
]]

local Shared = require(script.Parent.Shared)

type HidingSpotData = Shared.HidingSpotData
type AreaData = Shared.AreaData

------------------------------------------------------------------------
-- Layout Constants (matching design doc spatial relationships)
------------------------------------------------------------------------

-- The entire forest is centered around X=0, Z=0
-- Ranger Station is at Z = 250 (south)
-- Ridge is at Z = -300 (north)
-- Forest floor Y = 0

local FLOOR_Y = 0
local FOREST_SIZE = 600 -- total X and Z extent
local FOREST_HALF = FOREST_SIZE / 2

-- Key landmark positions (floor-center)
local RANGER_STATION_Z = 250 -- south
local FOREST_EDGE_Z = 190 -- where the tree line begins
local CAMPSITE_POS = Vector3.new(-40, FLOOR_Y, 100) -- on south trail
local CLEARING_POS = Vector3.new(50, FLOOR_Y, -20) -- central clearing
local RING_POS = Vector3.new(-80, FLOOR_Y, -40) -- west of center
local CREEK_CENTER = Vector3.new(-60, FLOOR_Y, 60) -- creek bed
local CABIN_CLUSTER_Z = -100 -- center-north

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local DenseForest = {}

function DenseForest.build(parent: Instance): AreaData
	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	local forestModel = Instance.new("Model")
	forestModel.Name = "DenseForest"

	Shared.resetSeed(12345) -- deterministic forest layout

	--------------------------------------------------------------------
	-- Ground Plane (entire forest floor)
	--------------------------------------------------------------------
	do
		local groundPlane = Shared.createGround(
			Vector3.new(0, FLOOR_Y - 0.5, 0),
			Vector3.new(FOREST_SIZE, 1, FOREST_SIZE),
			forestModel,
			"ForestFloor"
		)
		groundPlane.Material = Enum.Material.LeafyGrass
		groundPlane.Color = Shared.Colors.GROUND
	end

	--------------------------------------------------------------------
	-- Trail System
	--------------------------------------------------------------------
	do
		local trailModel = Instance.new("Model")
		trailModel.Name = "TrailSystem"

		local trailWidth = 6
		local trailThickness = 0.15

		-- South Trail: Ranger Station (Z=250) to Cabin Cluster (Z=-100)
		-- With a gentle curve through the campsite
		local southTrailSegments = {
			-- Parking lot to forest edge
			{ start = Vector3.new(0, FLOOR_Y, RANGER_STATION_Z), finish = Vector3.new(0, FLOOR_Y, FOREST_EDGE_Z) },
			-- Forest edge to campsite approach
			{ start = Vector3.new(0, FLOOR_Y, FOREST_EDGE_Z), finish = Vector3.new(-20, FLOOR_Y, 140) },
			-- Through campsite area
			{ start = Vector3.new(-20, FLOOR_Y, 140), finish = Vector3.new(-40, FLOOR_Y, 100) },
			-- Campsite to mid-forest
			{ start = Vector3.new(-40, FLOOR_Y, 100), finish = Vector3.new(-30, FLOOR_Y, 40) },
			-- Mid-forest to cabin cluster
			{ start = Vector3.new(-30, FLOOR_Y, 40), finish = Vector3.new(-20, FLOOR_Y, -20) },
			{ start = Vector3.new(-20, FLOOR_Y, -20), finish = Vector3.new(0, FLOOR_Y, -80) },
			{ start = Vector3.new(0, FLOOR_Y, -80), finish = Vector3.new(0, FLOOR_Y, CABIN_CLUSTER_Z) },
		}

		for i, seg in southTrailSegments do
			local dx = seg.finish.X - seg.start.X
			local dz = seg.finish.Z - seg.start.Z
			local length = math.sqrt(dx * dx + dz * dz)
			local angle = math.deg(math.atan2(dx, dz))
			local center = (seg.start + seg.finish) / 2

			local trail = Instance.new("Part")
			trail.Name = `SouthTrail_{i}`
			trail.Size = Vector3.new(trailWidth, trailThickness, length)
			trail.CFrame = CFrame.new(center + Vector3.new(0, trailThickness / 2, 0))
				* CFrame.Angles(0, math.rad(angle), 0)
			trail.Anchored = true
			trail.Material = Enum.Material.Ground
			trail.Color = Shared.Colors.TRAIL
			trail.Parent = trailModel
		end

		-- North Trail: Cabin Cluster to Ridge Trail base
		local northTrailSegments = {
			{ start = Vector3.new(0, FLOOR_Y, CABIN_CLUSTER_Z), finish = Vector3.new(10, FLOOR_Y, -160) },
			{ start = Vector3.new(10, FLOOR_Y, -160), finish = Vector3.new(20, FLOOR_Y, -220) },
			-- Incline begins
			{ start = Vector3.new(20, FLOOR_Y, -220), finish = Vector3.new(20, FLOOR_Y + 8, -260) },
			{ start = Vector3.new(20, FLOOR_Y + 8, -260), finish = Vector3.new(15, FLOOR_Y + 15, -290) },
		}

		for i, seg in northTrailSegments do
			local diff = seg.finish - seg.start
			local length = diff.Magnitude
			local center = (seg.start + seg.finish) / 2
			local angle = math.deg(math.atan2(diff.X, diff.Z))

			local trail = Instance.new("Part")
			trail.Name = `NorthTrail_{i}`
			trail.Size = Vector3.new(trailWidth - 1, trailThickness, length) -- slightly narrower
			trail.CFrame = CFrame.new(center + Vector3.new(0, trailThickness / 2, 0))
				* CFrame.Angles(0, math.rad(angle), 0)
			trail.Anchored = true
			trail.Material = Enum.Material.Ground
			trail.Color = Shared.Colors.TRAIL
			trail.Parent = trailModel
		end

		-- West Trail: branches off South Trail toward Creek Bed
		local westTrailSegments = {
			{ start = Vector3.new(-30, FLOOR_Y, 40), finish = Vector3.new(-50, FLOOR_Y, 50) },
			{ start = Vector3.new(-50, FLOOR_Y, 50), finish = Vector3.new(-60, FLOOR_Y, 60) },
		}

		for i, seg in westTrailSegments do
			local diff = seg.finish - seg.start
			local length = diff.Magnitude
			local center = (seg.start + seg.finish) / 2
			local angle = math.deg(math.atan2(diff.X, diff.Z))

			local trail = Instance.new("Part")
			trail.Name = `WestTrail_{i}`
			trail.Size = Vector3.new(trailWidth - 2, trailThickness, length) -- narrowest, overgrown
			trail.CFrame = CFrame.new(center + Vector3.new(0, trailThickness / 2, 0))
				* CFrame.Angles(0, math.rad(angle), 0)
			trail.Anchored = true
			trail.Material = Enum.Material.Ground
			trail.Color = Color3.fromRGB(60, 55, 42) -- more overgrown
			trail.Parent = trailModel
		end

		-- Lantern posts along South Trail (unlit, every ~40 studs)
		local lanternPositions = {
			Vector3.new(4, FLOOR_Y, 180),
			Vector3.new(-6, FLOOR_Y, 140),
			Vector3.new(-35, FLOOR_Y, 80),
			Vector3.new(-25, FLOOR_Y, 20),
			Vector3.new(-15, FLOOR_Y, -40),
			Vector3.new(2, FLOOR_Y, -70),
		}
		for i, lPos in lanternPositions do
			Shared.createLanternPost(lPos, trailModel, `Lantern_{i}`)
		end

		-- Trail waypoints (entity patrol)
		local trailWPs = {
			{ pos = Vector3.new(0, FLOOR_Y + 3, 170), id = "SouthTrail_1" },
			{ pos = Vector3.new(-30, FLOOR_Y + 3, 70), id = "SouthTrail_2" },
			{ pos = Vector3.new(-10, FLOOR_Y + 3, 0), id = "SouthTrail_3" },
			{ pos = Vector3.new(5, FLOOR_Y + 3, -50), id = "SouthTrail_4" },
			{ pos = Vector3.new(10, FLOOR_Y + 3, -150), id = "NorthTrail_1" },
			{ pos = Vector3.new(20, FLOOR_Y + 10, -240), id = "RidgeTrail_1" },
		}
		for _, wp in trailWPs do
			table.insert(waypoints, { position = wp.pos, roomId = wp.id, dwellTime = 3 })
		end

		trailModel.Parent = forestModel
	end

	--------------------------------------------------------------------
	-- Dense Forest Tree Placement (procedural)
	--------------------------------------------------------------------
	do
		local treeModel = Instance.new("Model")
		treeModel.Name = "ForestTrees"

		-- Zone definitions for tree density
		-- We avoid placing trees on trails and key areas
		local treeTypes = { "pine", "pine", "pine", "oak", "oak", "birch", "dead" }

		-- Place trees in a grid with jitter
		local gridSpacing = 18 -- average space between trees
		local jitter = 8

		for gx = -FOREST_HALF + 20, FOREST_HALF - 20, gridSpacing do
			for gz = -FOREST_HALF + 20, FOREST_HALF - 20, gridSpacing do
				local tx = gx + (Shared.resetSeed(gx * 1000 + gz) or 0) * 0 -- reset is side-effect
				-- Use seeded random for jitter
				local jx = gx + (math.random() * 2 - 1) * jitter
				local jz = gz + (math.random() * 2 - 1) * jitter
				local tPos = Vector3.new(jx, FLOOR_Y, jz)

				-- Exclusion zones: skip if near trails, clearings, structures
				local skipTree = false

				-- Skip near south trail (rough corridor)
				if math.abs(jx) < 12 and jz > CABIN_CLUSTER_Z and jz < RANGER_STATION_Z then
					skipTree = true
				end

				-- Skip in clearing area
				if (tPos - CLEARING_POS).Magnitude < 30 then
					skipTree = true
				end

				-- Skip in Ring area (but place Ring trees separately)
				if (tPos - RING_POS).Magnitude < 18 then
					skipTree = true
				end

				-- Skip near campsite
				if (tPos - CAMPSITE_POS).Magnitude < 20 then
					skipTree = true
				end

				-- Skip near cabin cluster center
				if math.abs(jz - CABIN_CLUSTER_Z) < 30 and math.abs(jx) < 50 then
					skipTree = true
				end

				-- Skip in ranger station area
				if jz > FOREST_EDGE_Z then
					skipTree = true
				end

				-- Skip in ridge area (sparse)
				if jz < -220 then
					skipTree = math.random() < 0.7 -- sparse ridge
				end

				-- Skip near creek bed
				if (tPos - CREEK_CENTER).Magnitude < 15 then
					skipTree = true
				end

				if not skipTree then
					local treeTypeIdx = math.random(1, #treeTypes)
					local treeType = treeTypes[treeTypeIdx]
					local scale = 0.7 + math.random() * 0.6

					-- Denser trees off-trail (closer spacing)
					-- We just vary the scale for visual variety
					Shared.createTree(tPos, treeType, treeModel, scale)
				end
			end
		end

		-- Extra-dense tree clusters in specific off-trail areas
		local denseZones = {
			{ center = Vector3.new(100, FLOOR_Y, 50), radius = 40, count = 20 },
			{ center = Vector3.new(-120, FLOOR_Y, 0), radius = 35, count = 18 },
			{ center = Vector3.new(80, FLOOR_Y, -60), radius = 30, count = 15 },
			{ center = Vector3.new(-100, FLOOR_Y, -120), radius = 35, count = 18 },
		}

		for _, zone in denseZones do
			for i = 1, zone.count do
				local angle = math.random() * math.pi * 2
				local dist = math.random() * zone.radius
				local pos = zone.center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
				local ttype = treeTypes[math.random(1, #treeTypes)]
				Shared.createTree(pos, ttype, treeModel, 0.6 + math.random() * 0.5)
			end
		end

		treeModel.Parent = forestModel
	end

	--------------------------------------------------------------------
	-- Undergrowth, Rocks, Stumps, Fallen Logs (scattered)
	--------------------------------------------------------------------
	do
		local scatterModel = Instance.new("Model")
		scatterModel.Name = "ForestScatter"

		-- Rock clusters along trails and in woods
		local rockPositions = {
			Vector3.new(15, FLOOR_Y, 150),
			Vector3.new(-45, FLOOR_Y, 70),
			Vector3.new(30, FLOOR_Y, -10),
			Vector3.new(-70, FLOOR_Y, -60),
			Vector3.new(60, FLOOR_Y, 40),
			Vector3.new(-20, FLOOR_Y, -140),
			Vector3.new(80, FLOOR_Y, -30),
			Vector3.new(-90, FLOOR_Y, 30),
			Vector3.new(40, FLOOR_Y, 120),
			Vector3.new(-50, FLOOR_Y, -100),
			Vector3.new(100, FLOOR_Y, -80),
			Vector3.new(-130, FLOOR_Y, -60),
		}

		for i, rPos in rockPositions do
			if i % 3 == 0 then
				Shared.createBoulderCluster(rPos, scatterModel, `BoulderCluster_{i}`)
			else
				Shared.createRock(rPos, Vector3.new(3, 2, 3), scatterModel, `Rock_{i}`)
			end
		end

		-- Hiding spots behind large rocks
		local rockHidingPositions = {
			{ pos = Vector3.new(16, FLOOR_Y + 1, 152), id = "Forest_Rock_1" },
			{ pos = Vector3.new(-44, FLOOR_Y + 1, 72), id = "Forest_Rock_2" },
			{ pos = Vector3.new(31, FLOOR_Y + 1, -8), id = "Forest_Rock_3" },
			{ pos = Vector3.new(81, FLOOR_Y + 1, -28), id = "Forest_Rock_4" },
		}
		for _, rh in rockHidingPositions do
			local _, spotData = Shared.createHidingSpot(rh.pos, "BehindRock", rh.id, scatterModel)
			table.insert(hidingSpots, spotData)
		end

		-- Fallen logs
		local logPlacements = {
			{ pos = Vector3.new(25, FLOOR_Y, 80), length = 10, rot = 30 },
			{ pos = Vector3.new(-60, FLOOR_Y, 20), length = 12, rot = -15 },
			{ pos = Vector3.new(50, FLOOR_Y, -50), length = 8, rot = 70 },
			{ pos = Vector3.new(-30, FLOOR_Y, -80), length = 14, rot = 45 },
			{ pos = Vector3.new(70, FLOOR_Y, 100), length = 10, rot = -40 },
			{ pos = Vector3.new(-80, FLOOR_Y, -20), length = 11, rot = 10 },
			{ pos = Vector3.new(20, FLOOR_Y, -120), length = 9, rot = 60 },
		}
		for i, lp in logPlacements do
			Shared.createFallenLog(lp.pos, lp.length, lp.rot, scatterModel, `FallenLog_{i}`)
		end

		-- Hiding spots under fallen logs
		local logHidingPositions = {
			{ pos = Vector3.new(25, FLOOR_Y + 0.5, 81), id = "Forest_Log_1" },
			{ pos = Vector3.new(-60, FLOOR_Y + 0.5, 21), id = "Forest_Log_2" },
			{ pos = Vector3.new(-30, FLOOR_Y + 0.5, -79), id = "Forest_Log_3" },
		}
		for _, lh in logHidingPositions do
			local _, spotData = Shared.createHidingSpot(lh.pos, "UnderLog", lh.id, scatterModel)
			table.insert(hidingSpots, spotData)
		end

		-- Undergrowth patches
		local undergrowthZones = {
			{ pos = Vector3.new(40, FLOOR_Y, 60), radius = 12, count = 8 },
			{ pos = Vector3.new(-50, FLOOR_Y, 40), radius = 10, count = 6 },
			{ pos = Vector3.new(80, FLOOR_Y, -20), radius = 15, count = 10 },
			{ pos = Vector3.new(-100, FLOOR_Y, -30), radius = 12, count = 7 },
			{ pos = Vector3.new(60, FLOOR_Y, 130), radius = 10, count = 6 },
			{ pos = Vector3.new(-40, FLOOR_Y, -60), radius = 14, count = 9 },
			{ pos = Vector3.new(110, FLOOR_Y, 20), radius = 12, count = 8 },
			{ pos = Vector3.new(-70, FLOOR_Y, 80), radius = 10, count = 6 },
		}
		for i, ug in undergrowthZones do
			Shared.createUndergrowth(ug.pos, ug.radius, ug.count, scatterModel, `Undergrowth_{i}`)
		end

		-- Bush hiding spots
		local bushHidingPositions = {
			{ pos = Vector3.new(42, FLOOR_Y + 1, 62), id = "Forest_Bush_1" },
			{ pos = Vector3.new(-48, FLOOR_Y + 1, 42), id = "Forest_Bush_2" },
			{ pos = Vector3.new(82, FLOOR_Y + 1, -18), id = "Forest_Bush_3" },
			{ pos = Vector3.new(-98, FLOOR_Y + 1, -28), id = "Forest_Bush_4" },
		}
		for _, bh in bushHidingPositions do
			local _, spotData = Shared.createHidingSpot(bh.pos, "InBush", bh.id, scatterModel)
			table.insert(hidingSpots, spotData)
		end

		-- Stumps
		local stumpPositions = {
			Vector3.new(35, FLOOR_Y, 90),
			Vector3.new(-25, FLOOR_Y, 50),
			Vector3.new(55, FLOOR_Y, -30),
			Vector3.new(-45, FLOOR_Y, -50),
			Vector3.new(90, FLOOR_Y, 70),
		}
		for i, sp in stumpPositions do
			Shared.createStump(sp, scatterModel, `Stump_{i}`)
		end

		scatterModel.Parent = forestModel
	end

	--------------------------------------------------------------------
	-- The Clearing (50-stud diameter open area)
	--------------------------------------------------------------------
	do
		local clearingModel = Instance.new("Model")
		clearingModel.Name = "Clearing"

		-- Clearing ground (lighter, grassy)
		local clearingGround = Instance.new("Part")
		clearingGround.Name = "ClearingGround"
		clearingGround.Shape = Enum.PartType.Cylinder
		clearingGround.Size = Vector3.new(0.3, 50, 50)
		clearingGround.CFrame = CFrame.new(CLEARING_POS + Vector3.new(0, 0.15, 0))
			* CFrame.Angles(0, 0, math.rad(90))
		clearingGround.Anchored = true
		clearingGround.Material = Enum.Material.Grass
		clearingGround.Color = Color3.fromRGB(45, 55, 35) -- slightly lighter than forest floor
		clearingGround.Parent = clearingModel

		-- Dead tree in center (lightning-struck, blackened)
		local deadTree = Instance.new("Part")
		deadTree.Name = "DeadTree_Center"
		deadTree.Shape = Enum.PartType.Cylinder
		deadTree.Size = Vector3.new(14, 2, 2)
		deadTree.CFrame = CFrame.new(CLEARING_POS + Vector3.new(0, 7, 0))
			* CFrame.Angles(0, 0, math.rad(90))
		deadTree.Anchored = true
		deadTree.Material = Enum.Material.Wood
		deadTree.Color = Shared.Colors.CHARRED
		deadTree.Parent = clearingModel

		-- Charred branches
		for b = 1, 4 do
			local branch = Instance.new("Part")
			branch.Name = `CharredBranch_{b}`
			branch.Size = Vector3.new(0.4, math.random(3, 5), 0.4)
			local bAngle = b * 90 + math.random(-15, 15)
			branch.Position = CLEARING_POS + Vector3.new(
				math.cos(math.rad(bAngle)) * 1,
				10 + b,
				math.sin(math.rad(bAngle)) * 1
			)
			branch.Orientation = Vector3.new(0, bAngle, math.random(20, 45))
			branch.Anchored = true
			branch.Material = Enum.Material.Wood
			branch.Color = Shared.Colors.CHARRED
			branch.Parent = clearingModel
		end

		-- Scattered rocks in clearing
		for i = 1, 4 do
			local angle = math.random() * math.pi * 2
			local dist = math.random(10, 20)
			Shared.createRock(
				CLEARING_POS + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist),
				Vector3.new(2, 1, 2),
				clearingModel,
				`ClearingRock_{i}`
			)
		end

		-- Moonlight source (clearing gets more moonlight)
		Shared.createMoonlight(CLEARING_POS + Vector3.new(0, 25, 0), clearingModel, 0.25, 30)

		-- Waypoints
		table.insert(waypoints, { position = CLEARING_POS + Vector3.new(0, 3, 0), roomId = "Clearing", dwellTime = 4 })

		clearingModel.Parent = forestModel
	end

	--------------------------------------------------------------------
	-- Creek Bed
	--------------------------------------------------------------------
	do
		local creekModel = Instance.new("Model")
		creekModel.Name = "CreekBed"

		-- Main stream segments (east-west through forest)
		local streamSegments = {
			{ pos = Vector3.new(-100, FLOOR_Y, 60), length = 40, width = 8, depth = 6, rot = 10 },
			{ pos = Vector3.new(-60, FLOOR_Y, 62), length = 45, width = 10, depth = 7, rot = 5 },
			{ pos = Vector3.new(-20, FLOOR_Y, 65), length = 40, width = 8, depth = 6, rot = -5 },
			{ pos = Vector3.new(20, FLOOR_Y, 63), length = 40, width = 7, depth = 5, rot = 8 },
		}

		for i, seg in streamSegments do
			Shared.createStreamSegment(
				seg.pos,
				seg.length,
				seg.width,
				seg.depth,
				seg.rot,
				creekModel,
				`Stream_{i}`
			)
		end

		-- Smooth stones in creek
		for i = 1, 8 do
			local stone = Instance.new("Part")
			stone.Name = `CreekStone_{i}`
			stone.Shape = Enum.PartType.Ball
			local sr = 0.5 + math.random() * 0.8
			stone.Size = Vector3.new(sr * 2, sr, sr * 2)
			stone.Position = CREEK_CENTER + Vector3.new(
				math.random(-30, 30),
				-5,
				math.random(-3, 3)
			)
			stone.Anchored = true
			stone.Material = Enum.Material.Slate
			stone.Color = Color3.fromRGB(90, 88, 82)
			stone.Parent = creekModel
		end

		-- Torres's abandoned pack
		local pack = Instance.new("Part")
		pack.Name = "TorressPack"
		pack.Size = Vector3.new(2, 1.5, 1)
		pack.Position = CREEK_CENTER + Vector3.new(-5, -4, 2)
		pack.Anchored = true
		pack.Material = Enum.Material.Fabric
		pack.Color = Color3.fromRGB(60, 70, 55)
		pack.Parent = creekModel

		local packPrompt = Instance.new("ProximityPrompt")
		packPrompt.ActionText = "Search"
		packPrompt.ObjectText = "Abandoned Pack"
		packPrompt.HoldDuration = 1
		packPrompt.MaxActivationDistance = 8
		packPrompt.Parent = pack

		-- Torres's boot
		local boot = Instance.new("Part")
		boot.Name = "TorressBoot"
		boot.Size = Vector3.new(0.8, 0.6, 1.2)
		boot.Position = CREEK_CENTER + Vector3.new(8, -5, -1)
		boot.Orientation = Vector3.new(15, 40, 0)
		boot.Anchored = true
		boot.Material = Enum.Material.Leather
		boot.Color = Color3.fromRGB(50, 40, 30)
		boot.Parent = creekModel

		-- Smashed compass
		local compass = Instance.new("Part")
		compass.Name = "SmashedCompass"
		compass.Shape = Enum.PartType.Cylinder
		compass.Size = Vector3.new(0.2, 1, 1)
		compass.CFrame = CFrame.new(CREEK_CENTER + Vector3.new(3, -5.5, 0))
			* CFrame.Angles(0, 0, math.rad(90))
		compass.Anchored = true
		compass.Material = Enum.Material.Metal
		compass.Color = Color3.fromRGB(130, 125, 110)
		compass.Parent = creekModel

		-- Waypoints
		table.insert(waypoints, {
			position = CREEK_CENTER + Vector3.new(0, -2, 0),
			roomId = "CreekBed",
			dwellTime = 3,
		})

		-- Loot
		table.insert(lootPositions, {
			itemType = "Battery",
			position = CREEK_CENTER + Vector3.new(-10, -4, 1),
			chance = 0.5,
			guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Bandage",
			position = CREEK_CENTER + Vector3.new(-5, -4, 2),
			chance = 0.4,
			guaranteed = false,
		})

		creekModel.Parent = forestModel
	end

	--------------------------------------------------------------------
	-- Abandoned Campsite
	--------------------------------------------------------------------
	do
		local campModel = Instance.new("Model")
		campModel.Name = "AbandonedCampsite"

		-- Cleared ground area
		local campGround = Instance.new("Part")
		campGround.Name = "CampGround"
		campGround.Size = Vector3.new(30, 0.2, 30)
		campGround.Position = CAMPSITE_POS + Vector3.new(0, 0.1, 0)
		campGround.Anchored = true
		campGround.Material = Enum.Material.Ground
		campGround.Color = Color3.fromRGB(55, 50, 40)
		campGround.Parent = campModel

		-- Tents: 2 standing, 1 collapsed, 1 shredded
		Shared.createTent(CAMPSITE_POS + Vector3.new(-8, 0, -6), campModel, "standing", "Tent_A")
		Shared.createTent(CAMPSITE_POS + Vector3.new(6, 0, -8), campModel, "standing", "Tent_B")
		Shared.createTent(CAMPSITE_POS + Vector3.new(-6, 0, 8), campModel, "collapsed", "Tent_C")
		Shared.createTent(CAMPSITE_POS + Vector3.new(8, 0, 6), campModel, "shredded", "Tent_D")

		-- Central fire pit
		Shared.createFirePit(CAMPSITE_POS, campModel, "CampFirePit")

		-- Folding table with maps and equipment
		local tableModel = Shared.createWoodTable(CAMPSITE_POS + Vector3.new(10, 0, 0), campModel, "CampTable")

		-- Map on table (flat part)
		local mapPart = Instance.new("Part")
		mapPart.Name = "Map"
		mapPart.Size = Vector3.new(2, 0.05, 1.5)
		mapPart.Position = CAMPSITE_POS + Vector3.new(10, 3.25, 0)
		mapPart.Anchored = true
		mapPart.Material = Enum.Material.SmoothPlastic
		mapPart.Color = Color3.fromRGB(200, 190, 160)
		mapPart.Parent = campModel

		-- Overturned camp chairs
		for i, offset in { Vector3.new(3, 0, 3), Vector3.new(-3, 0, -3) } do
			Shared.createWoodChair(CAMPSITE_POS + offset, campModel, true, `CampChair_{i}`)
		end

		-- Camp lantern (lightable)
		local lantern = Instance.new("Part")
		lantern.Name = "CampLantern"
		lantern.Size = Vector3.new(0.8, 1.2, 0.8)
		lantern.Position = CAMPSITE_POS + Vector3.new(10, 3.5, 0.5)
		lantern.Anchored = true
		lantern.Material = Enum.Material.Metal
		lantern.Color = Shared.Colors.RUSTED_METAL
		lantern.Parent = campModel

		local lanternPrompt = Instance.new("ProximityPrompt")
		lanternPrompt.ActionText = "Light Lantern"
		lanternPrompt.ObjectText = "Camp Lantern"
		lanternPrompt.HoldDuration = 1
		lanternPrompt.MaxActivationDistance = 8
		lanternPrompt.Parent = lantern

		-- Hiding spot: collapsed tent
		local _, tentHideData = Shared.createHidingSpot(
			CAMPSITE_POS + Vector3.new(-6, 0.5, 8),
			"InTent",
			"Campsite_Tent_Hide",
			campModel
		)
		table.insert(hidingSpots, tentHideData)

		-- Waypoints
		table.insert(waypoints, {
			position = CAMPSITE_POS + Vector3.new(0, 3, 0),
			roomId = "AbandonedCampsite",
			dwellTime = 4,
		})

		-- Loot
		table.insert(lootPositions, {
			itemType = "Battery",
			position = CAMPSITE_POS + Vector3.new(10, 3.3, -0.5),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Battery",
			position = CAMPSITE_POS + Vector3.new(-8, 0.5, -6),
			chance = 0.4,
			guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Bandage",
			position = CAMPSITE_POS + Vector3.new(10, 3.3, 0.5),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Bandage",
			position = CAMPSITE_POS + Vector3.new(6, 0.5, -8),
			chance = 0.6,
			guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Medkit",
			position = CAMPSITE_POS + Vector3.new(-8, 0.5, -5),
			chance = 0.3,
			guaranteed = false,
		})
		table.insert(lootPositions, {
			itemType = "Flare",
			position = CAMPSITE_POS + Vector3.new(10, 3.3, -1),
			chance = 0.5,
			guaranteed = false,
		})

		campModel.Parent = forestModel
	end

	--------------------------------------------------------------------
	-- The Ring (Safe Zone)
	--------------------------------------------------------------------
	do
		local ringModel = Instance.new("Model")
		ringModel.Name = "TheRing"

		-- Bare earth interior
		local ringGround = Instance.new("Part")
		ringGround.Name = "RingGround"
		ringGround.Shape = Enum.PartType.Cylinder
		ringGround.Size = Vector3.new(0.3, 25, 25)
		ringGround.CFrame = CFrame.new(RING_POS + Vector3.new(0, 0.15, 0))
			* CFrame.Angles(0, 0, math.rad(90))
		ringGround.Anchored = true
		ringGround.Material = Enum.Material.Ground
		ringGround.Color = Color3.fromRGB(60, 55, 48) -- packed earth, almost like stone
		ringGround.Parent = ringModel

		-- 12 ancient trees in a circle
		local ringRadius = 12.5
		for i = 0, 11 do
			local angle = i * (math.pi * 2 / 12)
			local treePos = RING_POS + Vector3.new(
				math.cos(angle) * ringRadius,
				0,
				math.sin(angle) * ringRadius
			)
			Shared.createTree(treePos, "ancient", ringModel, 1, `RingTree_{i}`)
		end

		-- Center stone (flat rock with carvings)
		local centerStone = Instance.new("Part")
		centerStone.Name = "CenterStone"
		centerStone.Shape = Enum.PartType.Cylinder
		centerStone.Size = Vector3.new(0.8, 3, 3)
		centerStone.CFrame = CFrame.new(RING_POS + Vector3.new(0, 0.4, 0))
			* CFrame.Angles(0, 0, math.rad(90))
		centerStone.Anchored = true
		centerStone.Material = Enum.Material.Slate
		centerStone.Color = Shared.Colors.STONE_CARVED
		centerStone.Parent = ringModel

		-- Carving texture on stone (surface decal placeholder — thin overlaid part)
		local carvingOverlay = Instance.new("Part")
		carvingOverlay.Name = "CarvingOverlay"
		carvingOverlay.Shape = Enum.PartType.Cylinder
		carvingOverlay.Size = Vector3.new(0.1, 2.8, 2.8)
		carvingOverlay.CFrame = CFrame.new(RING_POS + Vector3.new(0, 0.85, 0))
			* CFrame.Angles(0, 0, math.rad(90))
		carvingOverlay.Anchored = true
		carvingOverlay.Material = Enum.Material.Slate
		carvingOverlay.Color = Color3.fromRGB(50, 48, 45)
		carvingOverlay.Transparency = 0.3
		carvingOverlay.CanCollide = false
		carvingOverlay.Parent = ringModel

		-- Ring safe zone volume (invisible, marks the safe zone)
		local safeZone = Instance.new("Part")
		safeZone.Name = "RingSafeZone"
		safeZone.Shape = Enum.PartType.Cylinder
		safeZone.Size = Vector3.new(30, 25, 25) -- tall enough to encompass players
		safeZone.CFrame = CFrame.new(RING_POS + Vector3.new(0, 15, 0))
			* CFrame.Angles(0, 0, math.rad(90))
		safeZone.Anchored = true
		safeZone.Transparency = 1
		safeZone.CanCollide = false
		safeZone.Parent = ringModel

		safeZone:SetAttribute("IsSafeZone", true)
		safeZone:SetAttribute("ZoneType", "TheRing")

		-- Loot (battery at base of center stone)
		table.insert(lootPositions, {
			itemType = "Battery",
			position = RING_POS + Vector3.new(1.5, 0.5, 0),
			chance = 1,
			guaranteed = true,
		})

		ringModel.Parent = forestModel
	end

	--------------------------------------------------------------------
	-- Canopy Ceiling (blocks sky, creates overhead darkness)
	--------------------------------------------------------------------
	do
		local canopyModel = Instance.new("Model")
		canopyModel.Name = "CanopyCeiling"

		-- Large semi-transparent dark canopy planes high above
		-- Placed in sections to allow gaps (clearing, ridge)
		local canopySections = {
			{ pos = Vector3.new(-80, 35, 80), size = Vector3.new(200, 0.5, 200) },
			{ pos = Vector3.new(80, 35, 80), size = Vector3.new(200, 0.5, 200) },
			{ pos = Vector3.new(-80, 35, -80), size = Vector3.new(200, 0.5, 200) },
			{ pos = Vector3.new(80, 35, -80), size = Vector3.new(200, 0.5, 160) },
		}

		for i, sec in canopySections do
			local canopy = Instance.new("Part")
			canopy.Name = `CanopyLayer_{i}`
			canopy.Size = sec.size
			canopy.Position = sec.pos
			canopy.Anchored = true
			canopy.Material = Enum.Material.Grass
			canopy.Color = Color3.fromRGB(10, 18, 8) -- very dark canopy
			canopy.Transparency = 0.4
			canopy.CanCollide = false
			canopy.CastShadow = true
			canopy.Parent = canopyModel
		end

		canopyModel.Parent = forestModel
	end

	--------------------------------------------------------------------
	-- Fog Boundary Walls
	--------------------------------------------------------------------
	do
		local fogModel = Instance.new("Model")
		fogModel.Name = "FogBoundary"

		local wallHeight = 50
		local boundaryDist = FOREST_HALF + 10

		local fogWalls = {
			{ pos = Vector3.new(0, wallHeight / 2, -boundaryDist), size = Vector3.new(boundaryDist * 2, wallHeight, 2) },
			{ pos = Vector3.new(0, wallHeight / 2, boundaryDist), size = Vector3.new(boundaryDist * 2, wallHeight, 2) },
			{ pos = Vector3.new(-boundaryDist, wallHeight / 2, 0), size = Vector3.new(2, wallHeight, boundaryDist * 2) },
			{ pos = Vector3.new(boundaryDist, wallHeight / 2, 0), size = Vector3.new(2, wallHeight, boundaryDist * 2) },
		}

		for i, fw in fogWalls do
			Shared.createFogWall(fw.pos, fw.size, fogModel, `FogWall_{i}`)
		end

		fogModel.Parent = forestModel
	end

	--------------------------------------------------------------------
	-- Ambient Moonlight Sources
	--------------------------------------------------------------------
	do
		local lightModel = Instance.new("Model")
		lightModel.Name = "AmbientLighting"

		-- Sparse moonlight filtering through canopy
		local moonlightPositions = {
			Vector3.new(0, 30, 100),
			Vector3.new(-50, 30, 0),
			Vector3.new(50, 30, -50),
			Vector3.new(0, 30, -150),
			Vector3.new(-100, 30, 50),
			Vector3.new(100, 30, -100),
		}

		for i, mPos in moonlightPositions do
			Shared.createMoonlight(mPos, lightModel, 0.1, 50)
		end

		-- Slightly brighter near the clearing (moonlight break in canopy)
		Shared.createMoonlight(CLEARING_POS + Vector3.new(0, 30, 0), lightModel, 0.2, 35)

		lightModel.Parent = forestModel
	end

	--------------------------------------------------------------------
	-- Entity spawn positions (in dense woods, near trails)
	--------------------------------------------------------------------
	-- Watcher idle positions are trail-adjacent (60%) and off-trail (40%)
	-- These are stored as waypoints with room IDs for the entity system
	local entityWaypoints = {
		-- Trail-adjacent positions (within 15 studs of trail)
		{ pos = Vector3.new(12, FLOOR_Y + 3, 160), id = "Watcher_Trail_1" },
		{ pos = Vector3.new(-15, FLOOR_Y + 3, 100), id = "Watcher_Trail_2" },
		{ pos = Vector3.new(-8, FLOOR_Y + 3, 30), id = "Watcher_Trail_3" },
		{ pos = Vector3.new(10, FLOOR_Y + 3, -30), id = "Watcher_Trail_4" },
		{ pos = Vector3.new(-5, FLOOR_Y + 3, -90), id = "Watcher_Trail_5" },
		{ pos = Vector3.new(15, FLOOR_Y + 3, -170), id = "Watcher_Trail_6" },
		-- Off-trail positions (dense woods)
		{ pos = Vector3.new(60, FLOOR_Y + 3, 50), id = "Watcher_Woods_1" },
		{ pos = Vector3.new(-80, FLOOR_Y + 3, -10), id = "Watcher_Woods_2" },
		{ pos = Vector3.new(90, FLOOR_Y + 3, -40), id = "Watcher_Woods_3" },
		{ pos = Vector3.new(-110, FLOOR_Y + 3, -80), id = "Watcher_Woods_4" },
		-- Creek bank positions
		{ pos = Vector3.new(-40, FLOOR_Y + 2, 55), id = "Watcher_Creek_1" },
		{ pos = Vector3.new(-80, FLOOR_Y + 2, 58), id = "Watcher_Creek_2" },
	}
	for _, ewp in entityWaypoints do
		table.insert(waypoints, { position = ewp.pos, roomId = ewp.id, dwellTime = 0 })
	end

	forestModel.Parent = parent

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return DenseForest
