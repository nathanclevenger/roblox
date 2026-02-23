--!strict

--[[
	TheOrigin/Core - The Sanctuary: the level's climax zone.

	An underground cathedral of immense scale containing:
	- Central Chamber: vast amphitheater with bioluminescent floor diagram
	- Pillar Hall: forest of carved stone columns (Watcher gauntlet)
	- The Throne: circular chamber with the Original Entity (set piece)
	- The Seal: choice point (Reinforce / Destroy)

	After the claustrophobia of the Warren, the Sanctuary's open spaces
	create disorientation in the opposite direction.
]]

local Shared = require(script.Parent.Shared)

type HidingSpotData = Shared.HidingSpotData
type FloorData = Shared.FloorData

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local SANCTUARY_Y: number = Shared.SANCTUARY_Y

------------------------------------------------------------------------
-- Helper: create a styled Part
------------------------------------------------------------------------

local function createPart(
	parent: Instance,
	name: string,
	position: Vector3,
	size: Vector3,
	color: Color3?,
	transparency: number?,
	material: Enum.Material?
): Part
	return Shared.createPart(parent, name, position, size, color, transparency, material)
end

------------------------------------------------------------------------
-- Central Chamber: Underground cathedral, floor diagram
------------------------------------------------------------------------

local function buildCentralChamber(
	parent: Instance,
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local chamber = Instance.new("Model")
	chamber.Name = "CentralChamber"

	local centerPos = Vector3.new(30, SANCTUARY_Y, -300)
	local chamberWidth = 80
	local chamberDepth = 60
	local chamberHeight = 22 -- Too high for flashlight to reach ceiling

	-- Floor (massive continuous dark stone slab)
	local floor = Shared.createStoneFloor(
		centerPos + Vector3.new(0, -0.5, 0),
		Vector3.new(chamberWidth, 1, chamberDepth),
		chamber,
		"ChamberFloor"
	)
	floor.Color = Color3.fromRGB(25, 22, 20)
	floor.Material = Enum.Material.Slate

	-- Ceiling (so high the flashlight can barely reach it)
	Shared.createStoneCeiling(
		centerPos + Vector3.new(0, chamberHeight, 0),
		Vector3.new(chamberWidth + 4, 1, chamberDepth + 4),
		chamber,
		"ChamberCeiling"
	)

	-- Walls (curved approximation using large flat segments)
	-- North wall
	Shared.createStoneWall(
		centerPos + Vector3.new(0, chamberHeight / 2, -chamberDepth / 2 - 1),
		Vector3.new(chamberWidth + 2, chamberHeight, 2),
		chamber, "Wall_N"
	)
	-- South wall (with opening to Pillar Hall)
	Shared.createStoneWall(
		centerPos + Vector3.new(-chamberWidth / 4 - 5, chamberHeight / 2, chamberDepth / 2 + 1),
		Vector3.new(chamberWidth / 2 - 5, chamberHeight, 2),
		chamber, "Wall_S_L"
	)
	Shared.createStoneWall(
		centerPos + Vector3.new(chamberWidth / 4 + 5, chamberHeight / 2, chamberDepth / 2 + 1),
		Vector3.new(chamberWidth / 2 - 5, chamberHeight, 2),
		chamber, "Wall_S_R"
	)
	-- East and West walls
	Shared.createStoneWall(
		centerPos + Vector3.new(-chamberWidth / 2 - 1, chamberHeight / 2, 0),
		Vector3.new(2, chamberHeight, chamberDepth),
		chamber, "Wall_W"
	)
	Shared.createStoneWall(
		centerPos + Vector3.new(chamberWidth / 2 + 1, chamberHeight / 2, 0),
		Vector3.new(2, chamberHeight, chamberDepth),
		chamber, "Wall_E"
	)

	-- Amphitheater steps (descending toward center)
	local stepCount = 6
	for i = 0, stepCount - 1 do
		local stepWidth = chamberWidth - i * 8
		local stepDepth = chamberDepth - i * 6
		local stepY = SANCTUARY_Y - i * 0.5
		createPart(
			chamber,
			`AmphiStep_{i}`,
			centerPos + Vector3.new(0, stepY - 0.5, 0),
			Vector3.new(stepWidth, 0.5, stepDepth),
			Color3.fromRGB(30 + i * 3, 27 + i * 2, 25 + i * 2),
			0,
			Enum.Material.Slate
		)
	end

	-- Floor Diagram: concentric rings with radiating lines (bioluminescent)
	-- Ring 1: Hospital (outermost)
	-- Ring 2: Subway
	-- Ring 3: Research Station
	-- Ring 4: Forest
	-- Ring 5: Catacombs (innermost)
	local ringRadii = { 25, 20, 15, 10, 5 }
	local ringNames = { "Hospital", "Subway", "ResearchStation", "Forest", "Catacombs" }

	for ringIdx, radius in ringRadii do
		-- Approximate ring with 16 segments
		local segmentCount = 16
		for seg = 0, segmentCount - 1 do
			local angle1 = (seg / segmentCount) * math.pi * 2
			local angle2 = ((seg + 1) / segmentCount) * math.pi * 2
			local midAngle = (angle1 + angle2) / 2
			local x = math.cos(midAngle) * radius
			local z = math.sin(midAngle) * radius
			local segLen = 2 * radius * math.sin(math.pi / segmentCount)

			local ringPart = Shared.createBiolumLine(
				centerPos + Vector3.new(x, 0.05, z),
				Vector3.new(segLen, 0.05, 0.2),
				chamber,
				`Ring_{ringIdx}_Seg_{seg}`,
				0.15 + ringIdx * 0.05
			)
			ringPart.Orientation = Vector3.new(0, math.deg(midAngle), 0)
		end

		-- Examination point marker for each ring
		local examPos = centerPos + Vector3.new(radius, 0.5, 0)
		local examPart = Instance.new("Part")
		examPart.Name = `DiagramExam_{ringNames[ringIdx]}`
		examPart.Size = Vector3.new(2, 0.5, 2)
		examPart.Position = examPos
		examPart.Anchored = true
		examPart.Transparency = 1
		examPart.CanCollide = false
		examPart:SetAttribute("DiagramRing", ringNames[ringIdx])
		examPart:SetAttribute("RingLevel", ringIdx)
		examPart.Parent = chamber

		local examPrompt = Instance.new("ProximityPrompt")
		examPrompt.ActionText = `Examine Ring {ringIdx}`
		examPrompt.ObjectText = ringNames[ringIdx]
		examPrompt.HoldDuration = 1
		examPrompt.MaxActivationDistance = 5
		examPrompt.Parent = examPart
	end

	-- Radiating lines (connecting rings to center)
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local lineLength = ringRadii[1]
		local midX = math.cos(angle) * lineLength / 2
		local midZ = math.sin(angle) * lineLength / 2

		local line = Shared.createBiolumLine(
			centerPos + Vector3.new(midX, 0.05, midZ),
			Vector3.new(lineLength, 0.05, 0.15),
			chamber,
			`RadialLine_{i}`,
			0.2
		)
		line.Orientation = Vector3.new(0, math.deg(angle), 0)
	end

	-- Pulsing ambient glow (bioluminescent, breathing rhythm)
	Shared.createPulsingLight(
		centerPos + Vector3.new(0, 1, 0),
		chamber, 0.03, 0.12,
		Shared.COLOR_BIOLUM, 30, 0.3
	)

	-- Edge ambient lights (very dim)
	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local dist = 30
		Shared.createPulsingLight(
			centerPos + Vector3.new(math.cos(angle) * dist, 0.5, math.sin(angle) * dist),
			chamber, 0.01, 0.05,
			Shared.COLOR_BIOLUM, 12, 0.25 + i * 0.05
		)
	end

	-- Loot
	table.insert(lootPositions, {
		itemType = "Battery",
		position = centerPos + Vector3.new(20, 1, 15),
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Bandage",
		position = centerPos + Vector3.new(-20, 1, -15),
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Medkit",
		position = centerPos + Vector3.new(0, 1, 0),
		chance = 0.5,
		guaranteed = false,
	})

	-- Waypoint (transitional, no dedicated entities)
	table.insert(waypoints, {
		position = centerPos + Vector3.new(0, 3, 0),
		roomId = "CentralChamber_Center",
		dwellTime = 5,
	})

	chamber.Parent = parent
end

------------------------------------------------------------------------
-- Pillar Hall: Forest of carved stone columns (Watcher gauntlet)
------------------------------------------------------------------------

local function buildPillarHall(
	parent: Instance,
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } }
)
	local hall = Instance.new("Model")
	hall.Name = "PillarHall"

	local hallPos = Vector3.new(30, SANCTUARY_Y, -250)
	local hallWidth = 50
	local hallDepth = 20
	local hallHeight = 10

	-- Floor
	local floor = Shared.createStoneFloor(
		hallPos + Vector3.new(0, -0.5, 0),
		Vector3.new(hallWidth + 4, 1, hallDepth + 4),
		hall, "Floor"
	)
	floor.Color = Color3.fromRGB(22, 20, 18)

	-- Ceiling
	Shared.createStoneCeiling(
		hallPos + Vector3.new(0, hallHeight + 0.5, 0),
		Vector3.new(hallWidth + 4, 1, hallDepth + 4),
		hall, "Ceiling"
	)

	-- Side walls
	Shared.createStoneWall(
		hallPos + Vector3.new(-hallWidth / 2 - 1, hallHeight / 2, 0),
		Vector3.new(2, hallHeight, hallDepth + 4),
		hall, "Wall_W"
	)
	Shared.createStoneWall(
		hallPos + Vector3.new(hallWidth / 2 + 1, hallHeight / 2, 0),
		Vector3.new(2, hallHeight, hallDepth + 4),
		hall, "Wall_E"
	)

	-- North wall (opening from Central Chamber)
	Shared.createStoneWall(
		hallPos + Vector3.new(-hallWidth / 4 - 4, hallHeight / 2, -hallDepth / 2 - 1),
		Vector3.new(hallWidth / 2 - 4, hallHeight, 2),
		hall, "Wall_N_L"
	)
	Shared.createStoneWall(
		hallPos + Vector3.new(hallWidth / 4 + 4, hallHeight / 2, -hallDepth / 2 - 1),
		Vector3.new(hallWidth / 2 - 4, hallHeight, 2),
		hall, "Wall_N_R"
	)

	-- South wall (raised platform with archway to Throne)
	local platformHeight = 2
	createPart(
		hall, "RaisedPlatform",
		hallPos + Vector3.new(0, platformHeight / 2, hallDepth / 2 - 2),
		Vector3.new(12, platformHeight, 4),
		Shared.COLOR_STONE_DARK, 0, Enum.Material.Slate
	)
	Shared.createStoneWall(
		hallPos + Vector3.new(-hallWidth / 4 - 4, hallHeight / 2, hallDepth / 2 + 1),
		Vector3.new(hallWidth / 2 - 4, hallHeight, 2),
		hall, "Wall_S_L"
	)
	Shared.createStoneWall(
		hallPos + Vector3.new(hallWidth / 4 + 4, hallHeight / 2, hallDepth / 2 + 1),
		Vector3.new(hallWidth / 2 - 4, hallHeight, 2),
		hall, "Wall_S_R"
	)
	Shared.createArchway(
		hallPos + Vector3.new(0, platformHeight, hallDepth / 2),
		6, hallHeight - platformHeight, 2,
		hall, "ThroneArchway", true
	)

	-- Stone columns in grid (2-stud diameter, 5-stud spacing)
	local colSpacing = 5
	local colRadius = 1
	local colStartX = -hallWidth / 2 + colSpacing
	local colStartZ = -hallDepth / 2 + colSpacing
	local colEndX = hallWidth / 2 - colSpacing
	local colEndZ = hallDepth / 2 - colSpacing

	local pillarCount = 0
	local x = colStartX
	while x <= colEndX do
		local z = colStartZ
		while z <= colEndZ do
			pillarCount += 1
			Shared.createPillar(
				hallPos + Vector3.new(x, hallHeight / 2, z),
				hallHeight,
				colRadius,
				hall,
				`Pillar_{pillarCount}`,
				pillarCount % 3 == 0 -- every 3rd pillar has carvings
			)
			z += colSpacing
		end
		x += colSpacing
	end

	-- No bioluminescent glow here (genuinely dark)
	-- Very dim pulsing from behind columns (barely visible)
	Shared.createPulsingLight(
		hallPos + Vector3.new(0, 1, 0),
		hall, 0.005, 0.02,
		Shared.COLOR_BIOLUM, 8, 0.2
	)

	-- Watcher entity spawn markers
	local watcherSpawnPositions = {
		hallPos + Vector3.new(-15, 3, -5),
		hallPos + Vector3.new(-5, 3, 3),
		hallPos + Vector3.new(10, 3, -3),
		hallPos + Vector3.new(20, 3, 5),
	}
	for i, watcherPos in watcherSpawnPositions do
		local watcherMarker = Instance.new("Part")
		watcherMarker.Name = `WatcherSpawn_{i}`
		watcherMarker.Size = Vector3.new(1, 1, 1)
		watcherMarker.Position = watcherPos
		watcherMarker.Anchored = true
		watcherMarker.Transparency = 1
		watcherMarker.CanCollide = false
		watcherMarker:SetAttribute("IsWatcherSpawn", true)
		watcherMarker.Parent = hall

		table.insert(waypoints, {
			position = watcherPos,
			roomId = `PillarHall_Watcher_{i}`,
			dwellTime = 0, -- Watchers don't dwell, they stalk
		})
	end

	-- Loot
	table.insert(lootPositions, {
		itemType = "Flare",
		position = hallPos + Vector3.new(0, 1, 0),
		chance = 1,
		guaranteed = true,
	})
	table.insert(lootPositions, {
		itemType = "Battery",
		position = hallPos + Vector3.new(-10, 1, hallDepth / 2 - 3),
		chance = 1,
		guaranteed = true,
	})

	hall.Parent = parent
end

------------------------------------------------------------------------
-- The Throne: Circular chamber with the Original Entity
------------------------------------------------------------------------

local function buildThrone(
	parent: Instance,
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } }
)
	local throneRoom = Instance.new("Model")
	throneRoom.Name = "ThroneRoom"

	local thronePos = Vector3.new(30, SANCTUARY_Y, -220)
	local roomDiameter = 15
	local roomHeight = 8

	-- Polished floor (mirror sheen)
	local floor = createPart(
		throneRoom, "ThroneFloor",
		thronePos + Vector3.new(0, -0.5, 0),
		Vector3.new(roomDiameter + 2, 1, roomDiameter + 2),
		Color3.fromRGB(10, 8, 10), 0, Enum.Material.Glass
	)
	floor.Reflectance = 0.4

	-- Domed ceiling (approximated with flat panel)
	Shared.createStoneCeiling(
		thronePos + Vector3.new(0, roomHeight, 0),
		Vector3.new(roomDiameter + 2, 1, roomDiameter + 2),
		throneRoom, "ThroneCeiling"
	)

	-- Circular walls (8 segments)
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		local nextAngle = ((i + 1) / 8) * math.pi * 2
		local midAngle = (angle + nextAngle) / 2
		local wallX = math.cos(midAngle) * (roomDiameter / 2 + 0.5)
		local wallZ = math.sin(midAngle) * (roomDiameter / 2 + 0.5)
		local wallLen = 2 * (roomDiameter / 2) * math.sin(math.pi / 8)

		-- Skip entrance wall (north-facing, i=6)
		if i == 6 then
			continue
		end

		local wall = Shared.createStoneWall(
			thronePos + Vector3.new(wallX, roomHeight / 2, wallZ),
			Vector3.new(wallLen, roomHeight, 1.5),
			throneRoom, `ThroneWall_{i}`
		)
		wall.Orientation = Vector3.new(0, math.deg(midAngle), 0)
		wall.Color = Shared.COLOR_VOID
	end

	-- The Throne itself (center, facing entrance)
	Shared.createThrone(thronePos, throneRoom)

	-- Passage to The Seal (behind the throne)
	local sealPassagePos = thronePos + Vector3.new(0, 0, 8)
	-- Narrow passage walls
	Shared.createStoneWall(
		sealPassagePos + Vector3.new(-2, roomHeight / 2, 0),
		Vector3.new(1, roomHeight, 5),
		throneRoom, "SealPassage_L"
	)
	Shared.createStoneWall(
		sealPassagePos + Vector3.new(2, roomHeight / 2, 0),
		Vector3.new(1, roomHeight, 5),
		throneRoom, "SealPassage_R"
	)
	-- Passage floor
	Shared.createStoneFloor(
		sealPassagePos + Vector3.new(0, -0.5, 0),
		Vector3.new(3, 1, 5),
		throneRoom, "SealPassage_Floor"
	)

	-- Atmosphere: warm temperature marker
	local tempMarker = Instance.new("Part")
	tempMarker.Name = "TemperatureMarker"
	tempMarker.Size = Vector3.new(roomDiameter, roomHeight, roomDiameter)
	tempMarker.Position = thronePos + Vector3.new(0, roomHeight / 2, 0)
	tempMarker.Anchored = true
	tempMarker.Transparency = 1
	tempMarker.CanCollide = false
	tempMarker:SetAttribute("Temperature", "fever_warm")
	tempMarker:SetAttribute("FearTierOverride", 3) -- PANIC
	tempMarker.Parent = throneRoom

	-- Examination points around the throne (4 lore triggers)
	local examPoints = {
		{ offset = Vector3.new(0, 2, -3), label = "The Figure", obj = "Examine the figure" },
		{ offset = Vector3.new(3, 2, 0), label = "The Throne", obj = "Examine the throne" },
		{ offset = Vector3.new(0, 0.5, 0), label = "The Dais", obj = "Examine the dais" },
		{ offset = Vector3.new(-5, 3, -5), label = "Chamber Walls", obj = "Examine the walls" },
	}
	for i, exam in examPoints do
		local examPart = Instance.new("Part")
		examPart.Name = `ThroneExam_{i}`
		examPart.Size = Vector3.new(2, 2, 2)
		examPart.Position = thronePos + exam.offset
		examPart.Anchored = true
		examPart.Transparency = 1
		examPart.CanCollide = false
		examPart:SetAttribute("ExamType", exam.label)
		examPart.Parent = throneRoom

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = exam.obj
		prompt.ObjectText = exam.label
		prompt.HoldDuration = 1.5
		prompt.MaxActivationDistance = 5
		prompt.Parent = examPart
	end

	-- Sub-bass vibration marker (controller rumble / audio cue)
	local vibrationMarker = Instance.new("Part")
	vibrationMarker.Name = "VibrationSource"
	vibrationMarker.Size = Vector3.new(1, 1, 1)
	vibrationMarker.Position = thronePos
	vibrationMarker.Anchored = true
	vibrationMarker.Transparency = 1
	vibrationMarker.CanCollide = false
	vibrationMarker:SetAttribute("SubBassActive", true)
	vibrationMarker:SetAttribute("VibrationIntensity", 0.4)
	vibrationMarker.Parent = throneRoom

	-- No entities, no loot (the reward is understanding)

	throneRoom.Parent = parent
end

------------------------------------------------------------------------
-- The Seal: Choice point alcove
------------------------------------------------------------------------

local function buildTheSeal(
	parent: Instance
)
	local sealRoom = Instance.new("Model")
	sealRoom.Name = "SealAlcove"

	local sealPos = Vector3.new(30, SANCTUARY_Y, -208)
	local alcoveSize = Vector3.new(8, 6, 8)

	-- Alcove room (every surface covered in symbols)
	Shared.createCatacombRoom({
		position = sealPos,
		size = alcoveSize,
		parent = sealRoom,
		name = "SealChamber",
		doorways = {
			{ wall = "north" :: "north", offset = 0, width = 3, height = 5 },
		},
	})

	-- Dense symbol carvings on all surfaces (bioluminescent, pulsing faster)
	-- Floor symbols
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local dist = 1 + math.random() * 2.5
		Shared.createBiolumLine(
			sealPos + Vector3.new(math.cos(angle) * dist, 0.05, math.sin(angle) * dist),
			Vector3.new(1.5, 0.05, 0.12),
			sealRoom,
			`FloorSymbol_{i}`,
			0.3
		).Orientation = Vector3.new(0, math.deg(angle), 0)
	end

	-- Wall symbols
	for wall = 1, 4 do
		for row = 1, 3 do
			local wallOffset: Vector3
			local symSize: Vector3
			if wall == 1 then
				wallOffset = Vector3.new(-3.5, row * 1.5, 0)
				symSize = Vector3.new(0.05, 0.8, 1.2)
			elseif wall == 2 then
				wallOffset = Vector3.new(3.5, row * 1.5, 0)
				symSize = Vector3.new(0.05, 0.8, 1.2)
			elseif wall == 3 then
				wallOffset = Vector3.new(0, row * 1.5, -3.5)
				symSize = Vector3.new(1.2, 0.8, 0.05)
			else
				wallOffset = Vector3.new(0, row * 1.5, 3.5)
				symSize = Vector3.new(1.2, 0.8, 0.05)
			end
			Shared.createBiolumLine(
				sealPos + wallOffset,
				symSize,
				sealRoom,
				`WallSymbol_{wall}_{row}`,
				0.25
			)
		end
	end

	-- Ceiling pulsing lights (fast pulse, brighter than elsewhere)
	Shared.createPulsingLight(
		sealPos + Vector3.new(0, 5.5, 0),
		sealRoom, 0.1, 0.5,
		Shared.COLOR_BIOLUM_BRIGHT, 12, 1.5
	)
	Shared.createPulsingLight(
		sealPos + Vector3.new(-2, 5, -2),
		sealRoom, 0.05, 0.3,
		Shared.COLOR_BIOLUM, 8, 1.2
	)
	Shared.createPulsingLight(
		sealPos + Vector3.new(2, 5, 2),
		sealRoom, 0.05, 0.3,
		Shared.COLOR_BIOLUM, 8, 1.8
	)

	-- The Seal itself
	Shared.createSeal(sealPos, sealRoom)

	-- Voice marker (the seal speaks)
	local voiceMarker = Instance.new("Part")
	voiceMarker.Name = "SealVoiceMarker"
	voiceMarker.Size = Vector3.new(3, 3, 3)
	voiceMarker.Position = sealPos + Vector3.new(0, 1, 0)
	voiceMarker.Anchored = true
	voiceMarker.Transparency = 1
	voiceMarker.CanCollide = false
	voiceMarker:SetAttribute("SealVoiceActive", true)
	voiceMarker:SetAttribute("FearTierOverride", 3)
	voiceMarker:SetAttribute("SubBassActive", true)
	voiceMarker:SetAttribute("VibrationIntensity", 0.6)
	voiceMarker.Parent = sealRoom

	sealRoom.Parent = parent
end

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local Core = {}

function Core.build(parent: Instance): FloorData
	local model = Instance.new("Model")
	model.Name = "Core"
	model.Parent = parent

	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	-- Build all Sanctuary sub-areas
	buildCentralChamber(model, waypoints, lootPositions)
	buildPillarHall(model, waypoints, lootPositions)
	buildThrone(model, waypoints)
	buildTheSeal(model)

	-- No hiding spots in the Sanctuary (exposed, nowhere to hide)

	print(`[TheOrigin/Core] Built: {#hidingSpots} hiding spots, {#waypoints} waypoints, {#lootPositions} loot positions`)

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return Core
