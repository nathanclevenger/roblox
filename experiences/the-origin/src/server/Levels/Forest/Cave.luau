--!strict

--[[
	Forest/Cave - Builds the optional Cave system accessible from the Ridge.

	Three chambers descending underground:
	  Upper Chamber — natural cavern with pool and one frozen Watcher
	  Painted Chamber — ancient cave paintings, Vasik's equipment
	  The Deep — terminal room with carved walls and breathing vibration

	High-risk, high-lore-reward area. Cave Watchers are frozen set pieces
	(centuries old, covered in mineral deposits). They trigger Proximity Fear
	but do not relocate.
]]

local Shared = require(script.Parent.Shared)

type HidingSpotData = Shared.HidingSpotData
type AreaData = Shared.AreaData

------------------------------------------------------------------------
-- Layout Constants
------------------------------------------------------------------------

local RIDGE_Y = 20
local CAVE_ENTRANCE_POS = Vector3.new(30, RIDGE_Y, -265)

-- Underground positions (descending)
local UPPER_CHAMBER_POS = Vector3.new(30, RIDGE_Y - 12, -265)
local NARROW_PASSAGE_POS = Vector3.new(30, RIDGE_Y - 16, -275)
local PAINTED_CHAMBER_POS = Vector3.new(30, RIDGE_Y - 20, -285)
local DESCENT_POS = Vector3.new(30, RIDGE_Y - 28, -295)
local DEEP_POS = Vector3.new(30, RIDGE_Y - 35, -305)

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local Cave = {}

function Cave.build(parent: Instance): AreaData
	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	local caveModel = Instance.new("Model")
	caveModel.Name = "CaveSystem"

	Shared.resetSeed(99999)

	--------------------------------------------------------------------
	-- Cave Entrance (fissure in rock face)
	--------------------------------------------------------------------
	do
		local entranceModel = Instance.new("Model")
		entranceModel.Name = "CaveEntrance"

		-- Rock face (cliff wall the fissure is cut into)
		local rockFace = Instance.new("Part")
		rockFace.Name = "RockFace"
		rockFace.Size = Vector3.new(20, 15, 3)
		rockFace.Position = CAVE_ENTRANCE_POS + Vector3.new(0, 7.5, 0)
		rockFace.Anchored = true
		rockFace.Material = Enum.Material.Slate
		rockFace.Color = Color3.fromRGB(60, 57, 52)
		rockFace.Parent = entranceModel

		-- Fissure opening (gap in rock face)
		-- Left wall of fissure
		local fissureL = Instance.new("Part")
		fissureL.Name = "Fissure_L"
		fissureL.Size = Vector3.new(3, 15, 3)
		fissureL.Position = CAVE_ENTRANCE_POS + Vector3.new(-3, 7.5, 0)
		fissureL.Anchored = true
		fissureL.Material = Enum.Material.Slate
		fissureL.Color = Color3.fromRGB(55, 52, 48)
		fissureL.Parent = entranceModel

		-- Right wall
		local fissureR = Instance.new("Part")
		fissureR.Name = "Fissure_R"
		fissureR.Size = Vector3.new(3, 15, 3)
		fissureR.Position = CAVE_ENTRANCE_POS + Vector3.new(3, 7.5, 0)
		fissureR.Anchored = true
		fissureR.Material = Enum.Material.Slate
		fissureR.Color = Color3.fromRGB(55, 52, 48)
		fissureR.Parent = entranceModel

		-- Transom above fissure
		local fissureTop = Instance.new("Part")
		fissureTop.Name = "Fissure_Top"
		fissureTop.Size = Vector3.new(6, 9, 3)
		fissureTop.Position = CAVE_ENTRANCE_POS + Vector3.new(0, 10.5, 0)
		fissureTop.Anchored = true
		fissureTop.Material = Enum.Material.Slate
		fissureTop.Color = Color3.fromRGB(55, 52, 48)
		fissureTop.Parent = entranceModel

		-- Vasik's rope (tied to rock at entrance)
		local ropeAnchor = Instance.new("Part")
		ropeAnchor.Name = "RopeAnchor"
		ropeAnchor.Size = Vector3.new(2, 1.5, 2)
		ropeAnchor.Position = CAVE_ENTRANCE_POS + Vector3.new(2, 0.75, 2)
		ropeAnchor.Anchored = true
		ropeAnchor.Material = Enum.Material.Slate
		ropeAnchor.Color = Color3.fromRGB(70, 65, 60)
		ropeAnchor.Parent = entranceModel

		-- Rope visual (thin cylinder descending)
		local rope = Instance.new("Part")
		rope.Name = "VasikRope"
		rope.Shape = Enum.PartType.Cylinder
		rope.Size = Vector3.new(14, 0.15, 0.15)
		rope.CFrame = CFrame.new(CAVE_ENTRANCE_POS + Vector3.new(1.5, -5, 1))
			* CFrame.Angles(0, 0, math.rad(80))
		rope.Anchored = true
		rope.Material = Enum.Material.Fabric
		rope.Color = Color3.fromRGB(140, 120, 80)
		rope.CanCollide = false
		rope.Parent = entranceModel

		-- Descent prompt
		local descentPart = Instance.new("Part")
		descentPart.Name = "RopeDescent"
		descentPart.Size = Vector3.new(3, 3, 3)
		descentPart.Position = CAVE_ENTRANCE_POS + Vector3.new(0, 1.5, 0)
		descentPart.Anchored = true
		descentPart.Transparency = 1
		descentPart.CanCollide = false
		descentPart.Parent = entranceModel

		local descentPrompt = Instance.new("ProximityPrompt")
		descentPrompt.ActionText = "Descend"
		descentPrompt.ObjectText = "Rope"
		descentPrompt.HoldDuration = 4 -- 4-second committed animation
		descentPrompt.MaxActivationDistance = 6
		descentPrompt.Parent = descentPart

		-- Cold air effect marker
		local coldAir = Instance.new("Part")
		coldAir.Name = "ColdAirZone"
		coldAir.Size = Vector3.new(6, 6, 6)
		coldAir.Position = CAVE_ENTRANCE_POS + Vector3.new(0, 3, 0)
		coldAir.Anchored = true
		coldAir.Transparency = 1
		coldAir.CanCollide = false
		coldAir.Parent = entranceModel

		coldAir:SetAttribute("AmbientZone", "ColdAir")

		entranceModel.Parent = caveModel
	end

	--------------------------------------------------------------------
	-- Upper Chamber (20x20 studs, natural cavern)
	--------------------------------------------------------------------
	do
		local upperModel = Instance.new("Model")
		upperModel.Name = "UpperChamber"

		local chamberSize = Vector3.new(20, 12, 20)
		local cPos = UPPER_CHAMBER_POS

		-- Floor (rough stone)
		local floor = Instance.new("Part")
		floor.Name = "ChamberFloor"
		floor.Size = Vector3.new(chamberSize.X, 1, chamberSize.Z)
		floor.Position = cPos + Vector3.new(0, -chamberSize.Y / 2 - 0.5, 0)
		floor.Anchored = true
		floor.Material = Enum.Material.Slate
		floor.Color = Color3.fromRGB(50, 47, 42)
		floor.Parent = upperModel

		-- Walls (irregular — multiple overlapping parts for organic feel)
		local wallDefs = {
			{ name = "N", pos = Vector3.new(0, 0, -chamberSize.Z / 2 - 1), size = Vector3.new(chamberSize.X + 4, chamberSize.Y, 2) },
			{ name = "S", pos = Vector3.new(0, 0, chamberSize.Z / 2 + 1), size = Vector3.new(chamberSize.X + 4, chamberSize.Y, 2) },
			{ name = "W", pos = Vector3.new(-chamberSize.X / 2 - 1, 0, 0), size = Vector3.new(2, chamberSize.Y, chamberSize.Z) },
			{ name = "E", pos = Vector3.new(chamberSize.X / 2 + 1, 0, 0), size = Vector3.new(2, chamberSize.Y, chamberSize.Z) },
		}

		for _, wd in wallDefs do
			local wall = Instance.new("Part")
			wall.Name = `CaveWall_{wd.name}`
			wall.Size = wd.size
			wall.Position = cPos + wd.pos
			wall.Anchored = true
			wall.Material = Enum.Material.Slate
			wall.Color = Color3.fromRGB(45, 42, 38)
			wall.Parent = upperModel
		end

		-- Ceiling
		local ceiling = Instance.new("Part")
		ceiling.Name = "ChamberCeiling"
		ceiling.Size = Vector3.new(chamberSize.X + 4, 2, chamberSize.Z + 4)
		ceiling.Position = cPos + Vector3.new(0, chamberSize.Y / 2 + 1, 0)
		ceiling.Anchored = true
		ceiling.Material = Enum.Material.Slate
		ceiling.Color = Color3.fromRGB(40, 38, 34)
		ceiling.Parent = upperModel

		-- Stalactites
		for i = 1, 8 do
			local stalactite = Instance.new("Part")
			stalactite.Name = `Stalactite_{i}`
			stalactite.Shape = Enum.PartType.Cylinder
			local height = math.random(2, 5)
			stalactite.Size = Vector3.new(height, 0.4 + math.random() * 0.3, 0.4 + math.random() * 0.3)
			stalactite.CFrame = CFrame.new(cPos + Vector3.new(
				math.random(-8, 8),
				chamberSize.Y / 2 - height / 2,
				math.random(-8, 8)
			)) * CFrame.Angles(0, 0, math.rad(90))
			stalactite.Anchored = true
			stalactite.Material = Enum.Material.Slate
			stalactite.Color = Color3.fromRGB(75, 70, 62)
			stalactite.Parent = upperModel
		end

		-- Pool of dark water (shallow)
		local pool = Instance.new("Part")
		pool.Name = "DarkPool"
		pool.Shape = Enum.PartType.Cylinder
		pool.Size = Vector3.new(0.4, 8, 8)
		pool.CFrame = CFrame.new(cPos + Vector3.new(-3, -chamberSize.Y / 2 + 0.2, 2))
			* CFrame.Angles(0, 0, math.rad(90))
		pool.Anchored = true
		pool.Material = Enum.Material.Glass
		pool.Color = Color3.fromRGB(15, 22, 28) -- very dark water
		pool.Transparency = 0.2
		pool.CanCollide = false
		pool.Parent = upperModel

		-- Watcher in the pool (frozen set piece, mineral-encrusted)
		local poolWatcher = Instance.new("Part")
		poolWatcher.Name = "CaveWatcher_Pool"
		poolWatcher.Size = Vector3.new(2, 8, 2)
		poolWatcher.Position = cPos + Vector3.new(-3, -chamberSize.Y / 2 + 4, 2)
		poolWatcher.Anchored = true
		poolWatcher.Transparency = 1
		poolWatcher.CanCollide = false
		poolWatcher.Parent = upperModel

		poolWatcher:SetAttribute("WatcherSpawn", true)
		poolWatcher:SetAttribute("WatcherType", "CaveFrozen")
		poolWatcher:SetAttribute("HasReflection", true) -- reflection moves independently
		poolWatcher:SetAttribute("TriggersProximityFear", true)

		-- Vasik's equipment bag
		local equipBag = Instance.new("Part")
		equipBag.Name = "VasikEquipBag"
		equipBag.Size = Vector3.new(2, 1.5, 1.5)
		equipBag.Position = cPos + Vector3.new(5, -chamberSize.Y / 2 + 0.75, -5)
		equipBag.Anchored = true
		equipBag.Material = Enum.Material.Fabric
		equipBag.Color = Color3.fromRGB(55, 65, 50)
		equipBag.Parent = upperModel

		local bagPrompt = Instance.new("ProximityPrompt")
		bagPrompt.ActionText = "Search"
		bagPrompt.ObjectText = "Equipment Bag"
		bagPrompt.HoldDuration = 1
		bagPrompt.MaxActivationDistance = 6
		bagPrompt.Parent = equipBag

		-- Passage to Painted Chamber (narrow opening in south wall)
		-- Represented as a gap — the south wall has a hole
		local passagePart = Instance.new("Part")
		passagePart.Name = "NarrowPassage"
		passagePart.Size = Vector3.new(3, 4, 10)
		passagePart.Position = NARROW_PASSAGE_POS
		passagePart.Anchored = true
		passagePart.Transparency = 1
		passagePart.CanCollide = false
		passagePart.Parent = upperModel

		-- Passage walls (tight corridor)
		for _, side in { -1, 1 } do
			local passageWall = Instance.new("Part")
			passageWall.Name = `PassageWall_{side}`
			passageWall.Size = Vector3.new(1.5, 6, 10)
			passageWall.Position = NARROW_PASSAGE_POS + Vector3.new(side * 2.25, 0, 0)
			passageWall.Anchored = true
			passageWall.Material = Enum.Material.Slate
			passageWall.Color = Color3.fromRGB(42, 40, 36)
			passageWall.Parent = upperModel
		end

		-- Passage ceiling (low — must crouch)
		local passageCeiling = Instance.new("Part")
		passageCeiling.Name = "PassageCeiling"
		passageCeiling.Size = Vector3.new(6, 1, 10)
		passageCeiling.Position = NARROW_PASSAGE_POS + Vector3.new(0, 3, 0)
		passageCeiling.Anchored = true
		passageCeiling.Material = Enum.Material.Slate
		passageCeiling.Color = Color3.fromRGB(40, 38, 34)
		passageCeiling.Parent = upperModel

		-- Waypoint
		table.insert(waypoints, {
			position = cPos + Vector3.new(0, -chamberSize.Y / 2 + 3, 0),
			roomId = "UpperChamber",
			dwellTime = 3,
		})

		-- Loot
		table.insert(lootPositions, {
			itemType = "Battery",
			position = cPos + Vector3.new(5, -chamberSize.Y / 2 + 1, -5),
			chance = 1,
			guaranteed = true,
		})
		table.insert(lootPositions, {
			itemType = "Medkit",
			position = cPos + Vector3.new(5, -chamberSize.Y / 2 + 1.5, -4),
			chance = 1,
			guaranteed = true,
		})

		upperModel.Parent = caveModel
	end

	--------------------------------------------------------------------
	-- Painted Chamber (15x25 studs, cave paintings)
	--------------------------------------------------------------------
	do
		local paintedModel = Instance.new("Model")
		paintedModel.Name = "PaintedChamber"

		local chamberSize = Vector3.new(15, 10, 25)
		local cPos = PAINTED_CHAMBER_POS

		-- Floor
		local floor = Instance.new("Part")
		floor.Name = "PaintedFloor"
		floor.Size = Vector3.new(chamberSize.X, 1, chamberSize.Z)
		floor.Position = cPos + Vector3.new(0, -chamberSize.Y / 2 - 0.5, 0)
		floor.Anchored = true
		floor.Material = Enum.Material.Slate
		floor.Color = Color3.fromRGB(48, 45, 40)
		floor.Parent = paintedModel

		-- Walls
		local paintedWalls = {
			{ name = "N", pos = Vector3.new(0, 0, -chamberSize.Z / 2 - 1), size = Vector3.new(chamberSize.X + 2, chamberSize.Y, 2) },
			{ name = "S", pos = Vector3.new(0, 0, chamberSize.Z / 2 + 1), size = Vector3.new(chamberSize.X + 2, chamberSize.Y, 2) },
			{ name = "W", pos = Vector3.new(-chamberSize.X / 2 - 1, 0, 0), size = Vector3.new(2, chamberSize.Y, chamberSize.Z) },
			{ name = "E", pos = Vector3.new(chamberSize.X / 2 + 1, 0, 0), size = Vector3.new(2, chamberSize.Y, chamberSize.Z) },
		}

		for _, wd in paintedWalls do
			local wall = Instance.new("Part")
			wall.Name = `PaintedWall_{wd.name}`
			wall.Size = wd.size
			wall.Position = cPos + wd.pos
			wall.Anchored = true
			wall.Material = Enum.Material.Slate
			wall.Color = Color3.fromRGB(50, 48, 43)
			wall.Parent = paintedModel
		end

		-- Ceiling
		local ceiling = Instance.new("Part")
		ceiling.Name = "PaintedCeiling"
		ceiling.Size = Vector3.new(chamberSize.X + 2, 2, chamberSize.Z + 2)
		ceiling.Position = cPos + Vector3.new(0, chamberSize.Y / 2 + 1, 0)
		ceiling.Anchored = true
		ceiling.Material = Enum.Material.Slate
		ceiling.Color = Color3.fromRGB(40, 38, 34)
		ceiling.Parent = paintedModel

		-- Cave paintings (colored overlays on walls, 5 sections)
		local paintingDefs = {
			{ name = "TheSeal", wall = "W", yOff = 0, zOff = -8 },
			{ name = "TheReaching", wall = "W", yOff = 0, zOff = 0 },
			{ name = "TheForest", wall = "W", yOff = 0, zOff = 8 },
			{ name = "TheDescent", wall = "N", yOff = 0, zOff = 0 },
			{ name = "Unfinished", wall = "E", yOff = 0, zOff = 0 },
		}

		for i, pd in paintingDefs do
			local painting = Instance.new("Part")
			painting.Name = `Painting_{pd.name}`

			if pd.wall == "W" then
				painting.Size = Vector3.new(0.1, 4, 5)
				painting.Position = cPos + Vector3.new(-chamberSize.X / 2 + 0.05, pd.yOff, pd.zOff)
			elseif pd.wall == "N" then
				painting.Size = Vector3.new(5, 4, 0.1)
				painting.Position = cPos + Vector3.new(0, pd.yOff, -chamberSize.Z / 2 + 0.05)
			elseif pd.wall == "E" then
				painting.Size = Vector3.new(0.1, 4, 5)
				painting.Position = cPos + Vector3.new(chamberSize.X / 2 - 0.05, pd.yOff, pd.zOff)
			end

			painting.Anchored = true
			painting.Material = Enum.Material.SmoothPlastic
			-- Different ochre/red tones for each painting
			local paintColors = {
				Color3.fromRGB(120, 60, 30), -- ochre
				Color3.fromRGB(100, 40, 25), -- dark red
				Color3.fromRGB(80, 90, 45), -- earthy green
				Color3.fromRGB(110, 50, 35), -- rust
				Color3.fromRGB(65, 60, 55), -- faded (unfinished)
			}
			painting.Color = paintColors[i]
			painting.Transparency = 0.4
			painting.CanCollide = false
			painting.Parent = paintedModel

			-- Interaction prompt for reading
			local paintPrompt = Instance.new("ProximityPrompt")
			paintPrompt.ActionText = "Examine"
			paintPrompt.ObjectText = `Cave Painting: {pd.name}`
			paintPrompt.HoldDuration = 0.5
			paintPrompt.MaxActivationDistance = 8
			paintPrompt.Parent = painting

			painting:SetAttribute("LoreId", `CavePainting_{pd.name}`)
		end

		-- Vasik's field equipment
		local camera = Instance.new("Part")
		camera.Name = "VasikCamera"
		camera.Size = Vector3.new(0.6, 0.4, 0.8)
		camera.Position = cPos + Vector3.new(-4, -chamberSize.Y / 2 + 0.5, -5)
		camera.Anchored = true
		camera.Material = Enum.Material.Metal
		camera.Color = Color3.fromRGB(30, 30, 28)
		camera.Parent = paintedModel

		-- Vasik's notebook (final written words)
		local notebook = Instance.new("Part")
		notebook.Name = "VasikNotebook"
		notebook.Size = Vector3.new(0.8, 0.1, 1.2)
		notebook.Position = cPos + Vector3.new(chamberSize.X / 2 - 2, -chamberSize.Y / 2 + 0.6, 0) -- at base of east wall (unfinished painting)
		notebook.Anchored = true
		notebook.Material = Enum.Material.SmoothPlastic
		notebook.Color = Color3.fromRGB(180, 170, 140)
		notebook.Parent = paintedModel

		local notebookPrompt = Instance.new("ProximityPrompt")
		notebookPrompt.ActionText = "Read"
		notebookPrompt.ObjectText = "Vasik's Notebook"
		notebookPrompt.HoldDuration = 0.5
		notebookPrompt.MaxActivationDistance = 6
		notebookPrompt.Parent = notebook

		-- Watcher in far corner (facing the paintings, back to player)
		local paintingWatcher = Instance.new("Part")
		paintingWatcher.Name = "CaveWatcher_Painting"
		paintingWatcher.Size = Vector3.new(2, 8, 2)
		paintingWatcher.Position = cPos + Vector3.new(-5, -chamberSize.Y / 2 + 4, 10)
		paintingWatcher.Anchored = true
		paintingWatcher.Transparency = 1
		paintingWatcher.CanCollide = false
		paintingWatcher.Parent = paintedModel

		paintingWatcher:SetAttribute("WatcherSpawn", true)
		paintingWatcher:SetAttribute("WatcherType", "CaveFrozen")
		paintingWatcher:SetAttribute("FacingDirection", "Wall") -- back to player
		paintingWatcher:SetAttribute("TriggersProximityFear", true)

		-- Waypoint
		table.insert(waypoints, {
			position = cPos + Vector3.new(0, -chamberSize.Y / 2 + 3, 0),
			roomId = "PaintedChamber",
			dwellTime = 5,
		})

		paintedModel.Parent = caveModel
	end

	--------------------------------------------------------------------
	-- Descent Slope (steep, connecting Painted Chamber to The Deep)
	--------------------------------------------------------------------
	do
		local descentModel = Instance.new("Model")
		descentModel.Name = "Descent"

		-- Sloped floor
		local slope = Instance.new("Part")
		slope.Name = "DescentSlope"
		slope.Size = Vector3.new(6, 1, 20)
		slope.CFrame = CFrame.new(DESCENT_POS) * CFrame.Angles(math.rad(20), 0, 0) -- steep slope
		slope.Anchored = true
		slope.Material = Enum.Material.Slate
		slope.Color = Color3.fromRGB(45, 42, 38)
		slope.Parent = descentModel

		-- Walls along descent
		for _, side in { -1, 1 } do
			local wall = Instance.new("Part")
			wall.Name = `DescentWall_{side}`
			wall.Size = Vector3.new(1.5, 8, 20)
			wall.CFrame = CFrame.new(DESCENT_POS + Vector3.new(side * 4, 2, 0))
				* CFrame.Angles(math.rad(20), 0, 0)
			wall.Anchored = true
			wall.Material = Enum.Material.Slate
			wall.Color = Color3.fromRGB(42, 40, 36)
			wall.Parent = descentModel
		end

		-- Ceiling
		local descentCeiling = Instance.new("Part")
		descentCeiling.Name = "DescentCeiling"
		descentCeiling.Size = Vector3.new(10, 1, 20)
		descentCeiling.CFrame = CFrame.new(DESCENT_POS + Vector3.new(0, 6, 0))
			* CFrame.Angles(math.rad(20), 0, 0)
		descentCeiling.Anchored = true
		descentCeiling.Material = Enum.Material.Slate
		descentCeiling.Color = Color3.fromRGB(38, 36, 32)
		descentCeiling.Parent = descentModel

		-- Movement speed zone marker (-30%)
		local slowZone = Instance.new("Part")
		slowZone.Name = "SteepDescentZone"
		slowZone.Size = Vector3.new(6, 8, 20)
		slowZone.Position = DESCENT_POS + Vector3.new(0, 2, 0)
		slowZone.Anchored = true
		slowZone.Transparency = 1
		slowZone.CanCollide = false
		slowZone.Parent = descentModel

		slowZone:SetAttribute("MovementModifier", -0.3)

		descentModel.Parent = caveModel
	end

	--------------------------------------------------------------------
	-- The Deep (10x10 terminal room)
	--------------------------------------------------------------------
	do
		local deepModel = Instance.new("Model")
		deepModel.Name = "TheDeep"

		local chamberSize = Vector3.new(10, 8, 10)
		local cPos = DEEP_POS

		-- Floor (worked stone, not natural)
		local floor = Instance.new("Part")
		floor.Name = "DeepFloor"
		floor.Size = Vector3.new(chamberSize.X, 1, chamberSize.Z)
		floor.Position = cPos + Vector3.new(0, -chamberSize.Y / 2 - 0.5, 0)
		floor.Anchored = true
		floor.Material = Enum.Material.Slate
		floor.Color = Shared.Colors.STONE_CARVED -- smooth, carved stone
		floor.Parent = deepModel

		-- Carved walls (smooth, worked stone with symbol overlays)
		local deepWalls = {
			{ name = "N", pos = Vector3.new(0, 0, -chamberSize.Z / 2 - 0.75), size = Vector3.new(chamberSize.X + 1.5, chamberSize.Y, 1.5) },
			{ name = "S", pos = Vector3.new(0, 0, chamberSize.Z / 2 + 0.75), size = Vector3.new(chamberSize.X + 1.5, chamberSize.Y, 1.5) },
			{ name = "W", pos = Vector3.new(-chamberSize.X / 2 - 0.75, 0, 0), size = Vector3.new(1.5, chamberSize.Y, chamberSize.Z) },
			{ name = "E", pos = Vector3.new(chamberSize.X / 2 + 0.75, 0, 0), size = Vector3.new(1.5, chamberSize.Y, chamberSize.Z) },
		}

		for _, wd in deepWalls do
			local wall = Instance.new("Part")
			wall.Name = `DeepWall_{wd.name}`
			wall.Size = wd.size
			wall.Position = cPos + wd.pos
			wall.Anchored = true
			wall.Material = Enum.Material.Slate
			wall.Color = Shared.Colors.STONE_CARVED
			wall.Parent = deepModel
		end

		-- Ceiling
		local ceiling = Instance.new("Part")
		ceiling.Name = "DeepCeiling"
		ceiling.Size = Vector3.new(chamberSize.X + 1.5, 1.5, chamberSize.Z + 1.5)
		ceiling.Position = cPos + Vector3.new(0, chamberSize.Y / 2 + 0.75, 0)
		ceiling.Anchored = true
		ceiling.Material = Enum.Material.Slate
		ceiling.Color = Color3.fromRGB(60, 58, 55)
		ceiling.Parent = deepModel

		-- Carved symbols on walls (thin overlaid parts with pattern)
		for _, wallName in { "N", "S", "W", "E" } do
			local symbolOverlay = Instance.new("Part")
			symbolOverlay.Name = `Symbols_{wallName}`

			if wallName == "N" or wallName == "S" then
				symbolOverlay.Size = Vector3.new(chamberSize.X - 1, chamberSize.Y - 2, 0.05)
				local zDir = if wallName == "N" then -1 else 1
				symbolOverlay.Position = cPos + Vector3.new(0, 0, zDir * (chamberSize.Z / 2 - 0.02))
			else
				symbolOverlay.Size = Vector3.new(0.05, chamberSize.Y - 2, chamberSize.Z - 1)
				local xDir = if wallName == "W" then -1 else 1
				symbolOverlay.Position = cPos + Vector3.new(xDir * (chamberSize.X / 2 - 0.02), 0, 0)
			end

			symbolOverlay.Anchored = true
			symbolOverlay.Material = Enum.Material.Slate
			symbolOverlay.Color = Color3.fromRGB(55, 52, 48) -- slightly different shade for carvings
			symbolOverlay.Transparency = 0.3
			symbolOverlay.CanCollide = false
			symbolOverlay.Parent = deepModel
		end

		-- The Source carving (far wall, large single carving)
		local sourceCarving = Instance.new("Part")
		sourceCarving.Name = "SourceCarving"
		sourceCarving.Size = Vector3.new(6, 6, 0.08)
		sourceCarving.Position = cPos + Vector3.new(0, 0, -chamberSize.Z / 2 + 0.04)
		sourceCarving.Anchored = true
		sourceCarving.Material = Enum.Material.Slate
		sourceCarving.Color = Color3.fromRGB(40, 38, 35) -- darkest
		sourceCarving.Transparency = 0.2
		sourceCarving.CanCollide = false
		sourceCarving.Parent = deepModel

		local carvingPrompt = Instance.new("ProximityPrompt")
		carvingPrompt.ActionText = "Examine"
		carvingPrompt.ObjectText = "The Origin"
		carvingPrompt.HoldDuration = 1
		carvingPrompt.MaxActivationDistance = 8
		carvingPrompt.Parent = sourceCarving

		sourceCarving:SetAttribute("LoreId", "TheOrigin")

		-- Flanking Watchers (two, at entrance, frozen)
		for i, side in { -1, 1 } do
			local flankWatcher = Instance.new("Part")
			flankWatcher.Name = `CaveWatcher_Flank_{i}`
			flankWatcher.Size = Vector3.new(2, 8, 2)
			flankWatcher.Position = cPos + Vector3.new(side * 3, -chamberSize.Y / 2 + 4, chamberSize.Z / 2 - 1)
			flankWatcher.Anchored = true
			flankWatcher.Transparency = 1
			flankWatcher.CanCollide = false
			flankWatcher.Parent = deepModel

			flankWatcher:SetAttribute("WatcherSpawn", true)
			flankWatcher:SetAttribute("WatcherType", "CaveFrozen")
			flankWatcher:SetAttribute("TriggersProximityFear", true)
		end

		-- Vibration / breathing zone marker
		local vibrationZone = Instance.new("Part")
		vibrationZone.Name = "VibrationZone"
		vibrationZone.Size = Vector3.new(chamberSize.X, chamberSize.Y, chamberSize.Z)
		vibrationZone.Position = cPos
		vibrationZone.Anchored = true
		vibrationZone.Transparency = 1
		vibrationZone.CanCollide = false
		vibrationZone.Parent = deepModel

		vibrationZone:SetAttribute("AmbientZone", "Breathing")
		vibrationZone:SetAttribute("ScreenShake", true)
		vibrationZone:SetAttribute("ProximityFearOverride", 1) -- constant Tier 1

		-- Waypoint
		table.insert(waypoints, {
			position = cPos + Vector3.new(0, -chamberSize.Y / 2 + 3, 0),
			roomId = "TheDeep",
			dwellTime = 8,
		})

		deepModel.Parent = caveModel
	end

	--------------------------------------------------------------------
	-- Ascent Prompt (at bottom of rope for returning)
	--------------------------------------------------------------------
	do
		local ascentPart = Instance.new("Part")
		ascentPart.Name = "RopeAscent"
		ascentPart.Size = Vector3.new(3, 3, 3)
		ascentPart.Position = UPPER_CHAMBER_POS + Vector3.new(0, 2, 0)
		ascentPart.Anchored = true
		ascentPart.Transparency = 1
		ascentPart.CanCollide = false
		ascentPart.Parent = caveModel

		local ascentPrompt = Instance.new("ProximityPrompt")
		ascentPrompt.ActionText = "Climb Up"
		ascentPrompt.ObjectText = "Rope"
		ascentPrompt.HoldDuration = 6 -- 6-second animation (longer than descent)
		ascentPrompt.MaxActivationDistance = 6
		ascentPrompt.Parent = ascentPart
	end

	caveModel.Parent = parent

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return Cave
