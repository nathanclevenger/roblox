--!strict

--[[
	Forest/Shared - Builder helper functions for forest-specific geometry.

	Provides reusable primitives for outdoor forest environments:
	trees, rocks, bushes, fallen logs, stumps, streams, fog volumes,
	lantern posts, trail segments, tent structures, campfire pits,
	cabin-building helpers, and forest hiding spots.

	All geometry is built from Instance.new() — no external assets.
]]

local Shared = {}

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

-- Color palette: dark, desaturated, moonlit forest at dusk
local GROUND_COLOR = Color3.fromRGB(35, 40, 28) -- dark forest floor
local TRAIL_COLOR = Color3.fromRGB(75, 65, 50) -- packed dirt trail
local GRAVEL_COLOR = Color3.fromRGB(90, 85, 78) -- ranger station gravel
local BARK_COLOR_DARK = Color3.fromRGB(45, 32, 22) -- dark tree bark
local BARK_COLOR_MID = Color3.fromRGB(55, 40, 28) -- mid tree bark
local BARK_COLOR_LIGHT = Color3.fromRGB(65, 48, 35) -- lighter bark variation
local CANOPY_COLOR_DARK = Color3.fromRGB(18, 30, 15) -- dense canopy
local CANOPY_COLOR_MID = Color3.fromRGB(25, 38, 20) -- mid canopy
local DEAD_BRANCH_COLOR = Color3.fromRGB(40, 28, 18) -- bare branches
local ROCK_COLOR_DARK = Color3.fromRGB(60, 58, 55) -- dark rock
local ROCK_COLOR_LIGHT = Color3.fromRGB(80, 78, 72) -- lighter rock
local MOSS_COLOR = Color3.fromRGB(35, 50, 30) -- moss on rocks
local BUSH_COLOR = Color3.fromRGB(22, 35, 18) -- dark undergrowth
local WATER_COLOR = Color3.fromRGB(20, 30, 35) -- dark stream water
local FOG_WALL_COLOR = Color3.fromRGB(30, 32, 35) -- fog boundary
local WOOD_PLANK_COLOR = Color3.fromRGB(70, 52, 38) -- cabin wood
local WOOD_PLANK_DARK = Color3.fromRGB(50, 38, 28) -- weathered wood
local RUSTED_METAL = Color3.fromRGB(100, 70, 50) -- rusted metal
local STONE_CARVED = Color3.fromRGB(70, 68, 65) -- carved stone (The Ring)
local CONCRETE_COLOR = Color3.fromRGB(95, 92, 88) -- radio tower bunker
local TENT_FABRIC = Color3.fromRGB(80, 90, 75) -- tent canvas
local ASH_COLOR = Color3.fromRGB(45, 42, 40) -- cold fire pit ash
local MOONLIGHT_COLOR = Color3.fromRGB(140, 150, 180) -- cold moonlight tint
local CHARRED_COLOR = Color3.fromRGB(25, 20, 18) -- lightning-struck wood

------------------------------------------------------------------------
-- Type Definitions
------------------------------------------------------------------------

export type HidingSpotData = {
	id: string,
	position: Vector3,
	spotType: string,
	isOccupied: boolean,
}

export type AreaData = {
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } },
}

------------------------------------------------------------------------
-- Seeded Random Utility
------------------------------------------------------------------------

-- Deterministic random for reproducible placement
local _seed = 42
local function seededRandom(): number
	_seed = (_seed * 1103515245 + 12345) % 2147483648
	return _seed / 2147483648
end

local function seededRange(min: number, max: number): number
	return min + seededRandom() * (max - min)
end

function Shared.resetSeed(seed: number)
	_seed = seed
end

------------------------------------------------------------------------
-- Primitive: Ground Slab
------------------------------------------------------------------------

function Shared.createGround(position: Vector3, size: Vector3, parent: Instance, name: string?): Part
	local ground = Instance.new("Part")
	ground.Name = name or "Ground"
	ground.Size = size
	ground.Position = position
	ground.Anchored = true
	ground.Material = Enum.Material.LeafyGrass
	ground.Color = GROUND_COLOR
	ground.Parent = parent
	return ground
end

function Shared.createTrail(position: Vector3, size: Vector3, parent: Instance, name: string?): Part
	local trail = Instance.new("Part")
	trail.Name = name or "Trail"
	trail.Size = size
	trail.Position = position
	trail.Anchored = true
	trail.Material = Enum.Material.Ground
	trail.Color = TRAIL_COLOR
	trail.Parent = parent
	return trail
end

------------------------------------------------------------------------
-- Tree Builder
------------------------------------------------------------------------

--[[
	Creates a procedural tree from cylinder (trunk) + spheres (canopy).

	treeType:
	  "pine"    - tall, narrow conifer silhouette
	  "oak"     - broad deciduous, dense canopy
	  "dead"    - bare trunk with angular branches, no foliage
	  "ancient" - massive girth, dark bark, used for The Ring trees
	  "birch"   - thin trunk, sparse canopy

	scale: multiplier on base dimensions (default 1)
]]
function Shared.createTree(
	position: Vector3,
	treeType: string,
	parent: Instance,
	scale: number?,
	name: string?
): Model
	local s = scale or 1
	local model = Instance.new("Model")
	model.Name = name or `Tree_{treeType}`

	if treeType == "pine" then
		-- Trunk: tall, narrow cylinder
		local trunkHeight = 16 * s
		local trunkRadius = 0.6 * s

		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(trunkHeight, trunkRadius * 2, trunkRadius * 2)
		trunk.CFrame = CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		trunk.Anchored = true
		trunk.Material = Enum.Material.Wood
		trunk.Color = BARK_COLOR_DARK
		trunk.Parent = model

		-- Canopy: 3 stacked spheres, tapering upward
		local canopyLayers = {
			{ yOff = trunkHeight * 0.4, radius = 4 * s },
			{ yOff = trunkHeight * 0.6, radius = 3.2 * s },
			{ yOff = trunkHeight * 0.8, radius = 2.2 * s },
		}
		for i, layer in canopyLayers do
			local foliage = Instance.new("Part")
			foliage.Name = `Canopy_{i}`
			foliage.Shape = Enum.PartType.Ball
			foliage.Size = Vector3.new(layer.radius * 2, layer.radius * 2, layer.radius * 2)
			foliage.Position = position + Vector3.new(0, layer.yOff, 0)
			foliage.Anchored = true
			foliage.Material = Enum.Material.Grass
			foliage.Color = CANOPY_COLOR_DARK
			foliage.CastShadow = true
			foliage.Parent = model
		end

	elseif treeType == "oak" then
		-- Trunk: shorter, thicker
		local trunkHeight = 10 * s
		local trunkRadius = 1.2 * s

		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(trunkHeight, trunkRadius * 2, trunkRadius * 2)
		trunk.CFrame = CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		trunk.Anchored = true
		trunk.Material = Enum.Material.Wood
		trunk.Color = BARK_COLOR_MID
		trunk.Parent = model

		-- Broad canopy: single large sphere with smaller ones around it
		local mainCanopy = Instance.new("Part")
		mainCanopy.Name = "Canopy_Main"
		mainCanopy.Shape = Enum.PartType.Ball
		mainCanopy.Size = Vector3.new(8 * s, 6 * s, 8 * s)
		mainCanopy.Position = position + Vector3.new(0, trunkHeight + 2 * s, 0)
		mainCanopy.Anchored = true
		mainCanopy.Material = Enum.Material.Grass
		mainCanopy.Color = CANOPY_COLOR_MID
		mainCanopy.CastShadow = true
		mainCanopy.Parent = model

		-- Side canopy clusters
		for i = 1, 4 do
			local angle = (i - 1) * math.pi / 2 + seededRandom() * 0.5
			local dist = 3 * s
			local cluster = Instance.new("Part")
			cluster.Name = `Canopy_{i}`
			cluster.Shape = Enum.PartType.Ball
			cluster.Size = Vector3.new(5 * s, 4 * s, 5 * s)
			cluster.Position = position + Vector3.new(
				math.cos(angle) * dist,
				trunkHeight + 1 * s,
				math.sin(angle) * dist
			)
			cluster.Anchored = true
			cluster.Material = Enum.Material.Grass
			cluster.Color = CANOPY_COLOR_DARK
			cluster.CastShadow = true
			cluster.Parent = model
		end

	elseif treeType == "dead" then
		-- Bare trunk, no foliage, angular branches
		local trunkHeight = 12 * s
		local trunkRadius = 0.8 * s

		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(trunkHeight, trunkRadius * 2, trunkRadius * 2)
		trunk.CFrame = CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		trunk.Anchored = true
		trunk.Material = Enum.Material.Wood
		trunk.Color = DEAD_BRANCH_COLOR
		trunk.Parent = model

		-- Angular bare branches
		for b = 1, 5 do
			local branch = Instance.new("Part")
			branch.Name = `Branch_{b}`
			local bLen = seededRange(3, 6) * s
			branch.Size = Vector3.new(0.3 * s, bLen, 0.3 * s)
			local bY = trunkHeight * (0.4 + b * 0.1)
			local bAngleY = seededRange(0, 360)
			local bAngleZ = seededRange(20, 50)
			branch.Position = position + Vector3.new(
				math.cos(math.rad(bAngleY)) * 1.5 * s,
				bY,
				math.sin(math.rad(bAngleY)) * 1.5 * s
			)
			branch.Orientation = Vector3.new(0, bAngleY, bAngleZ)
			branch.Anchored = true
			branch.Material = Enum.Material.Wood
			branch.Color = DEAD_BRANCH_COLOR
			branch.Parent = model
		end

	elseif treeType == "ancient" then
		-- Massive trunk for The Ring trees
		local trunkHeight = 20 * s
		local trunkRadius = 2.5 * s

		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(trunkHeight, trunkRadius * 2, trunkRadius * 2)
		trunk.CFrame = CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		trunk.Anchored = true
		trunk.Material = Enum.Material.Wood
		trunk.Color = Color3.fromRGB(30, 22, 15) -- almost black bark
		trunk.Parent = model

		-- Bare crown branches (no leaves — fingers reaching upward)
		for b = 1, 7 do
			local branch = Instance.new("Part")
			branch.Name = `Branch_{b}`
			local bLen = seededRange(5, 10) * s
			branch.Size = Vector3.new(0.5 * s, bLen, 0.5 * s)
			local bAngleY = (b - 1) * 360 / 7 + seededRange(-10, 10)
			local bAngleZ = seededRange(15, 40)
			branch.Position = position + Vector3.new(
				math.cos(math.rad(bAngleY)) * 2 * s,
				trunkHeight - 1,
				math.sin(math.rad(bAngleY)) * 2 * s
			)
			branch.Orientation = Vector3.new(0, bAngleY, bAngleZ)
			branch.Anchored = true
			branch.Material = Enum.Material.Wood
			branch.Color = Color3.fromRGB(25, 18, 12)
			branch.Parent = model
		end

	elseif treeType == "birch" then
		-- Thin, white-ish trunk
		local trunkHeight = 14 * s
		local trunkRadius = 0.4 * s

		local trunk = Instance.new("Part")
		trunk.Name = "Trunk"
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(trunkHeight, trunkRadius * 2, trunkRadius * 2)
		trunk.CFrame = CFrame.new(position + Vector3.new(0, trunkHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		trunk.Anchored = true
		trunk.Material = Enum.Material.Wood
		trunk.Color = Color3.fromRGB(180, 175, 165) -- pale birch bark
		trunk.Parent = model

		-- Sparse canopy
		for i = 1, 2 do
			local foliage = Instance.new("Part")
			foliage.Name = `Canopy_{i}`
			foliage.Shape = Enum.PartType.Ball
			local r = seededRange(2, 3.5) * s
			foliage.Size = Vector3.new(r * 2, r * 1.5, r * 2)
			foliage.Position = position + Vector3.new(
				seededRange(-1, 1) * s,
				trunkHeight * (0.6 + i * 0.15),
				seededRange(-1, 1) * s
			)
			foliage.Anchored = true
			foliage.Material = Enum.Material.Grass
			foliage.Color = CANOPY_COLOR_MID
			foliage.CastShadow = true
			foliage.Parent = model
		end
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Rock Builder
------------------------------------------------------------------------

function Shared.createRock(
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string?
): Part
	local rock = Instance.new("Part")
	rock.Name = name or "Rock"
	-- Slightly random size variation
	local sx = size.X * seededRange(0.8, 1.2)
	local sy = size.Y * seededRange(0.7, 1.1)
	local sz = size.Z * seededRange(0.8, 1.2)
	rock.Size = Vector3.new(sx, sy, sz)
	rock.Position = position + Vector3.new(0, sy / 2, 0)
	rock.Anchored = true
	rock.Material = Enum.Material.Slate
	rock.Color = if seededRandom() > 0.5 then ROCK_COLOR_DARK else ROCK_COLOR_LIGHT
	rock.Parent = parent
	return rock
end

-- Larger boulder cluster
function Shared.createBoulderCluster(
	position: Vector3,
	parent: Instance,
	name: string?
): Model
	local model = Instance.new("Model")
	model.Name = name or "BoulderCluster"

	-- Main boulder
	Shared.createRock(position, Vector3.new(5, 3, 4), model, "MainBoulder")

	-- Smaller surrounding rocks
	for i = 1, 3 do
		local angle = seededRandom() * math.pi * 2
		local dist = seededRange(2, 4)
		Shared.createRock(
			position + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist),
			Vector3.new(2, 1.5, 2),
			model,
			`SmallRock_{i}`
		)
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Bush / Undergrowth
------------------------------------------------------------------------

function Shared.createBush(position: Vector3, parent: Instance, scale: number?, name: string?): Part
	local s = scale or 1
	local bush = Instance.new("Part")
	bush.Name = name or "Bush"
	bush.Shape = Enum.PartType.Ball
	local sx = seededRange(2.5, 4) * s
	local sy = seededRange(1.5, 2.5) * s
	bush.Size = Vector3.new(sx, sy, sx)
	bush.Position = position + Vector3.new(0, sy / 2 - 0.3, 0)
	bush.Anchored = true
	bush.Material = Enum.Material.Grass
	bush.Color = BUSH_COLOR
	bush.CanCollide = true
	bush.Parent = parent
	return bush
end

-- Dense undergrowth patch (multiple bushes)
function Shared.createUndergrowth(position: Vector3, radius: number, count: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "Undergrowth"

	for i = 1, count do
		local angle = seededRandom() * math.pi * 2
		local dist = seededRandom() * radius
		local bPos = position + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		Shared.createBush(bPos, model, seededRange(0.5, 1.2), `Bush_{i}`)
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Fallen Log
------------------------------------------------------------------------

function Shared.createFallenLog(
	position: Vector3,
	length: number,
	rotationY: number,
	parent: Instance,
	name: string?
): Part
	local log = Instance.new("Part")
	log.Name = name or "FallenLog"
	log.Shape = Enum.PartType.Cylinder
	local radius = seededRange(0.6, 1.2)
	log.Size = Vector3.new(length, radius * 2, radius * 2)
	log.CFrame = CFrame.new(position + Vector3.new(0, radius, 0))
		* CFrame.Angles(0, math.rad(rotationY), math.rad(90))
	log.Anchored = true
	log.Material = Enum.Material.Wood
	log.Color = BARK_COLOR_LIGHT
	log.Parent = parent
	return log
end

------------------------------------------------------------------------
-- Tree Stump
------------------------------------------------------------------------

function Shared.createStump(position: Vector3, parent: Instance, name: string?): Part
	local stump = Instance.new("Part")
	stump.Name = name or "Stump"
	stump.Shape = Enum.PartType.Cylinder
	local radius = seededRange(1, 2)
	local height = seededRange(0.8, 2)
	stump.Size = Vector3.new(height, radius * 2, radius * 2)
	stump.CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	stump.Anchored = true
	stump.Material = Enum.Material.Wood
	stump.Color = BARK_COLOR_MID
	stump.Parent = parent
	return stump
end

------------------------------------------------------------------------
-- Stream / Creek
------------------------------------------------------------------------

function Shared.createStreamSegment(
	position: Vector3,
	length: number,
	width: number,
	depth: number,
	rotationY: number,
	parent: Instance,
	name: string?
): Model
	local model = Instance.new("Model")
	model.Name = name or "StreamSegment"

	-- Riverbed (depression)
	local bed = Instance.new("Part")
	bed.Name = "Riverbed"
	bed.Size = Vector3.new(width + 4, depth, length)
	bed.CFrame = CFrame.new(position + Vector3.new(0, -depth / 2, 0)) * CFrame.Angles(0, math.rad(rotationY), 0)
	bed.Anchored = true
	bed.Material = Enum.Material.Slate
	bed.Color = Color3.fromRGB(50, 48, 42)
	bed.Parent = model

	-- Water surface
	local water = Instance.new("Part")
	water.Name = "WaterSurface"
	water.Size = Vector3.new(width, 0.3, length)
	water.CFrame = CFrame.new(position + Vector3.new(0, -depth + 0.5, 0)) * CFrame.Angles(0, math.rad(rotationY), 0)
	water.Anchored = true
	water.Material = Enum.Material.Glass
	water.Color = WATER_COLOR
	water.Transparency = 0.3
	water.CanCollide = false
	water.Parent = model

	-- Banks (raised edges)
	for i, side in { -1, 1 } do
		local bank = Instance.new("Part")
		bank.Name = `Bank_{i}`
		local bankWidth = 3
		local bankOffset = (width / 2 + bankWidth / 2)
		bank.Size = Vector3.new(bankWidth, depth + 1, length)
		bank.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rotationY), 0)
			* CFrame.new(side * bankOffset, 0, 0)
		bank.Anchored = true
		bank.Material = Enum.Material.Ground
		bank.Color = Color3.fromRGB(45, 40, 32)
		bank.Parent = model
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Lantern Post (trail markers, unlit)
------------------------------------------------------------------------

function Shared.createLanternPost(position: Vector3, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "LanternPost"

	-- Post
	local post = Instance.new("Part")
	post.Name = "Post"
	post.Shape = Enum.PartType.Cylinder
	post.Size = Vector3.new(6, 0.4, 0.4)
	post.CFrame = CFrame.new(position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	post.Anchored = true
	post.Material = Enum.Material.Wood
	post.Color = WOOD_PLANK_DARK
	post.Parent = model

	-- Lantern housing
	local housing = Instance.new("Part")
	housing.Name = "LanternHousing"
	housing.Size = Vector3.new(0.8, 1, 0.8)
	housing.Position = position + Vector3.new(0, 6.5, 0)
	housing.Anchored = true
	housing.Material = Enum.Material.Metal
	housing.Color = RUSTED_METAL
	housing.Parent = model

	-- Glass (unlit, dark)
	local glass = Instance.new("Part")
	glass.Name = "Glass"
	glass.Size = Vector3.new(0.6, 0.6, 0.6)
	glass.Position = position + Vector3.new(0, 6.5, 0)
	glass.Anchored = true
	glass.Material = Enum.Material.Glass
	glass.Color = Color3.fromRGB(30, 28, 25)
	glass.Transparency = 0.5
	glass.Parent = model

	-- ProximityPrompt for lighting with flare
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Light Lantern"
	prompt.ObjectText = "Lantern"
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 8
	prompt.Parent = housing

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Fog Volume (invisible boundary)
------------------------------------------------------------------------

function Shared.createFogWall(position: Vector3, size: Vector3, parent: Instance, name: string?): Part
	local wall = Instance.new("Part")
	wall.Name = name or "FogWall"
	wall.Size = size
	wall.Position = position
	wall.Anchored = true
	wall.Transparency = 1
	wall.CanCollide = true
	wall.Material = Enum.Material.SmoothPlastic
	wall.Color = FOG_WALL_COLOR
	wall.Parent = parent
	return wall
end

------------------------------------------------------------------------
-- Cabin Builder (wood structure)
------------------------------------------------------------------------

--[[
	Creates a simple wooden cabin with walls, floor, roof, and optional
	door/window openings. Returns a Model.

	config.position: floor-center position
	config.size: Vector3(width, wallHeight, depth)
	config.hasDoor: boolean (south wall)
	config.windowWalls: list of "north"|"south"|"east"|"west"
	config.roofAngle: degrees of roof pitch (0 = flat)
	config.collapsed: boolean (partially destroyed cabin)
]]
export type CabinConfig = {
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string?,
	hasDoor: boolean?,
	windowWalls: { string }?,
	roofAngle: number?,
	collapsed: boolean?,
}

function Shared.createCabin(config: CabinConfig): Model
	local model = Instance.new("Model")
	model.Name = config.name or "Cabin"

	local pos = config.position
	local sx = config.size.X
	local sy = config.size.Y
	local sz = config.size.Z
	local wt = 0.8 -- wall thickness for wooden cabin

	local wallMat = Enum.Material.Wood
	local wallCol = WOOD_PLANK_COLOR

	-- Floor
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(sx + wt * 2, 0.5, sz + wt * 2)
	floor.Position = Vector3.new(pos.X, pos.Y - 0.25, pos.Z)
	floor.Anchored = true
	floor.Material = Enum.Material.Wood
	floor.Color = WOOD_PLANK_DARK
	floor.Parent = model

	local windowSet: { [string]: boolean } = {}
	if config.windowWalls then
		for _, w in config.windowWalls do
			windowSet[w] = true
		end
	end

	-- Helper: create a cabin wall with optional window or door opening
	local function cabinWall(
		wallPos: Vector3,
		wallSize: Vector3,
		wallName: string,
		hasOpening: boolean,
		openingType: string -- "door" or "window"
	)
		if config.collapsed and (wallName == "Wall_North" or wallName == "Wall_West") then
			-- Collapsed walls: broken at angle
			local debris = Instance.new("Part")
			debris.Name = wallName .. "_Collapsed"
			debris.Size = Vector3.new(wallSize.X, wallSize.Y * 0.4, wallSize.Z)
			debris.Position = wallPos - Vector3.new(0, wallSize.Y * 0.3, 0)
			debris.Anchored = true
			debris.Material = wallMat
			debris.Color = WOOD_PLANK_DARK
			debris.Orientation = Vector3.new(seededRange(-15, -5), 0, seededRange(-5, 5))
			debris.Parent = model
			return
		end

		if not hasOpening then
			local wall = Instance.new("Part")
			wall.Name = wallName
			wall.Size = wallSize
			wall.Position = wallPos
			wall.Anchored = true
			wall.Material = wallMat
			wall.Color = wallCol
			wall.Parent = model
			return
		end

		-- Split wall for opening
		local openW: number
		local openH: number
		local openYoff: number

		if openingType == "door" then
			openW = 4
			openH = 7
			openYoff = 0
		else -- window
			openW = 3
			openH = 2.5
			openYoff = 2
		end

		-- Determine which axis the wall spans
		local isXWall = wallSize.X > wallSize.Z

		local wallLen = if isXWall then wallSize.X else wallSize.Z
		local halfOpen = openW / 2

		-- Left segment
		local leftLen = (wallLen - openW) / 2
		if leftLen > 0 then
			local leftWall = Instance.new("Part")
			leftWall.Name = wallName .. "_L"
			leftWall.Anchored = true
			leftWall.Material = wallMat
			leftWall.Color = wallCol
			if isXWall then
				leftWall.Size = Vector3.new(leftLen, wallSize.Y, wallSize.Z)
				leftWall.Position = wallPos + Vector3.new(-(leftLen + openW) / 2, 0, 0)
			else
				leftWall.Size = Vector3.new(wallSize.X, wallSize.Y, leftLen)
				leftWall.Position = wallPos + Vector3.new(0, 0, -(leftLen + openW) / 2)
			end
			leftWall.Parent = model
		end

		-- Right segment
		local rightLen = leftLen
		if rightLen > 0 then
			local rightWall = Instance.new("Part")
			rightWall.Name = wallName .. "_R"
			rightWall.Anchored = true
			rightWall.Material = wallMat
			rightWall.Color = wallCol
			if isXWall then
				rightWall.Size = Vector3.new(rightLen, wallSize.Y, wallSize.Z)
				rightWall.Position = wallPos + Vector3.new((rightLen + openW) / 2, 0, 0)
			else
				rightWall.Size = Vector3.new(wallSize.X, wallSize.Y, rightLen)
				rightWall.Position = wallPos + Vector3.new(0, 0, (rightLen + openW) / 2)
			end
			rightWall.Parent = model
		end

		-- Above-opening segment (transom)
		local transomH = wallSize.Y - openH - openYoff
		if transomH > 0 then
			local transom = Instance.new("Part")
			transom.Name = wallName .. "_Top"
			transom.Anchored = true
			transom.Material = wallMat
			transom.Color = wallCol
			if isXWall then
				transom.Size = Vector3.new(openW, transomH, wallSize.Z)
				transom.Position = wallPos + Vector3.new(0, (openH + openYoff) / 2 + transomH / 2 - wallSize.Y / 2, 0)
			else
				transom.Size = Vector3.new(wallSize.X, transomH, openW)
				transom.Position = wallPos + Vector3.new(0, (openH + openYoff) / 2 + transomH / 2 - wallSize.Y / 2, 0)
			end
			transom.Parent = model
		end

		-- Below-window sill (only for windows)
		if openingType == "window" and openYoff > 0 then
			local sill = Instance.new("Part")
			sill.Name = wallName .. "_Sill"
			sill.Anchored = true
			sill.Material = wallMat
			sill.Color = wallCol
			if isXWall then
				sill.Size = Vector3.new(openW, openYoff, wallSize.Z)
				sill.Position = wallPos + Vector3.new(0, -(wallSize.Y - openYoff) / 2, 0)
			else
				sill.Size = Vector3.new(wallSize.X, openYoff, openW)
				sill.Position = wallPos + Vector3.new(0, -(wallSize.Y - openYoff) / 2, 0)
			end
			sill.Parent = model
		end
	end

	-- Wall center Y
	local wallCY = pos.Y + sy / 2

	-- North wall
	cabinWall(
		Vector3.new(pos.X, wallCY, pos.Z - sz / 2 - wt / 2),
		Vector3.new(sx + wt * 2, sy, wt),
		"Wall_North",
		windowSet["north"] or false,
		"window"
	)

	-- South wall (door)
	cabinWall(
		Vector3.new(pos.X, wallCY, pos.Z + sz / 2 + wt / 2),
		Vector3.new(sx + wt * 2, sy, wt),
		"Wall_South",
		config.hasDoor or false,
		"door"
	)

	-- West wall
	cabinWall(
		Vector3.new(pos.X - sx / 2 - wt / 2, wallCY, pos.Z),
		Vector3.new(wt, sy, sz),
		"Wall_West",
		windowSet["west"] or false,
		"window"
	)

	-- East wall
	cabinWall(
		Vector3.new(pos.X + sx / 2 + wt / 2, wallCY, pos.Z),
		Vector3.new(wt, sy, sz),
		"Wall_East",
		windowSet["east"] or false,
		"window"
	)

	-- Roof
	if not config.collapsed then
		local roof = Instance.new("Part")
		roof.Name = "Roof"
		roof.Size = Vector3.new(sx + wt * 2 + 2, 0.5, sz + wt * 2 + 2) -- slight overhang
		roof.Position = Vector3.new(pos.X, pos.Y + sy + 0.25, pos.Z)
		roof.Anchored = true
		roof.Material = Enum.Material.Wood
		roof.Color = WOOD_PLANK_DARK
		roof.Parent = model
	else
		-- Sagging roof
		local roof = Instance.new("Part")
		roof.Name = "Roof_Collapsed"
		roof.Size = Vector3.new(sx + wt * 2, 0.5, sz + wt * 2)
		roof.Position = Vector3.new(pos.X - 1, pos.Y + sy * 0.6, pos.Z)
		roof.Orientation = Vector3.new(-15, 0, 8)
		roof.Anchored = true
		roof.Material = Enum.Material.Wood
		roof.Color = WOOD_PLANK_DARK
		roof.Parent = model

		-- Debris beams inside
		for i = 1, 4 do
			local beam = Instance.new("Part")
			beam.Name = `Debris_{i}`
			beam.Size = Vector3.new(seededRange(0.3, 0.6), seededRange(4, 8), seededRange(0.3, 0.6))
			beam.Position = pos + Vector3.new(
				seededRange(-sx / 3, sx / 3),
				seededRange(1, sy * 0.5),
				seededRange(-sz / 3, sz / 3)
			)
			beam.Orientation = Vector3.new(seededRange(-30, 30), seededRange(0, 180), seededRange(-20, 20))
			beam.Anchored = true
			beam.Material = Enum.Material.Wood
			beam.Color = WOOD_PLANK_DARK
			beam.Parent = model
		end
	end

	-- Door part (if cabin has a door)
	if config.hasDoor and not config.collapsed then
		local door = Instance.new("Part")
		door.Name = "Door"
		door.Size = Vector3.new(4, 7, 0.4)
		door.Position = Vector3.new(pos.X, pos.Y + 3.5, pos.Z + sz / 2 + wt / 2)
		door.Anchored = true
		door.Material = Enum.Material.Wood
		door.Color = Color3.fromRGB(60, 42, 30)
		door.Parent = model

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open"
		prompt.ObjectText = "Door"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 8
		prompt.Parent = door
	end

	model.Parent = config.parent
	return model
end

------------------------------------------------------------------------
-- Furniture for cabins/ranger station
------------------------------------------------------------------------

function Shared.createWoodTable(position: Vector3, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "WoodTable"

	local top = Instance.new("Part")
	top.Name = "Top"
	top.Size = Vector3.new(5, 0.4, 3)
	top.Position = position + Vector3.new(0, 3, 0)
	top.Anchored = true
	top.Material = Enum.Material.Wood
	top.Color = WOOD_PLANK_COLOR
	top.Parent = model

	for i, offset in {
		Vector3.new(-2.2, 1.5, -1.2),
		Vector3.new(2.2, 1.5, -1.2),
		Vector3.new(-2.2, 1.5, 1.2),
		Vector3.new(2.2, 1.5, 1.2),
	} do
		local leg = Instance.new("Part")
		leg.Name = `Leg_{i}`
		leg.Size = Vector3.new(0.4, 3, 0.4)
		leg.Position = position + offset
		leg.Anchored = true
		leg.Material = Enum.Material.Wood
		leg.Color = WOOD_PLANK_DARK
		leg.Parent = model
	end

	model.Parent = parent
	return model
end

function Shared.createWoodChair(position: Vector3, parent: Instance, overturned: boolean?, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "WoodChair"

	local seat = Instance.new("Part")
	seat.Name = "Seat"
	seat.Size = Vector3.new(2, 0.3, 2)
	seat.Anchored = true
	seat.Material = Enum.Material.Wood
	seat.Color = WOOD_PLANK_COLOR

	local back = Instance.new("Part")
	back.Name = "Back"
	back.Size = Vector3.new(2, 2.5, 0.3)
	back.Anchored = true
	back.Material = Enum.Material.Wood
	back.Color = WOOD_PLANK_COLOR

	if overturned then
		seat.Position = position + Vector3.new(0, 1, 0.5)
		seat.Orientation = Vector3.new(90, 0, 15)
		back.Position = position + Vector3.new(0, 0.5, -0.5)
		back.Orientation = Vector3.new(90, 0, 15)
	else
		seat.Position = position + Vector3.new(0, 2, 0)
		back.Position = position + Vector3.new(0, 3.25, -0.85)
	end

	seat.Parent = model
	back.Parent = model

	model.Parent = parent
	return model
end

function Shared.createCot(position: Vector3, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "Cot"

	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Size = Vector3.new(3, 1, 6)
	frame.Position = position + Vector3.new(0, 0.5, 0)
	frame.Anchored = true
	frame.Material = Enum.Material.Metal
	frame.Color = Color3.fromRGB(80, 80, 75)
	frame.Parent = model

	local mattress = Instance.new("Part")
	mattress.Name = "Mattress"
	mattress.Size = Vector3.new(2.8, 0.3, 5.8)
	mattress.Position = position + Vector3.new(0, 1.15, 0)
	mattress.Anchored = true
	mattress.Material = Enum.Material.Fabric
	mattress.Color = Color3.fromRGB(100, 95, 85)
	mattress.Parent = model

	model.Parent = parent
	return model
end

function Shared.createShelf(position: Vector3, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "Shelf"

	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Size = Vector3.new(4, 6, 1.5)
	frame.Position = position + Vector3.new(0, 3, 0)
	frame.Anchored = true
	frame.Material = Enum.Material.Wood
	frame.Color = WOOD_PLANK_DARK
	frame.Parent = model

	for i = 1, 3 do
		local shelf = Instance.new("Part")
		shelf.Name = `Shelf_{i}`
		shelf.Size = Vector3.new(3.8, 0.2, 1.3)
		shelf.Position = position + Vector3.new(0, i * 1.8, 0)
		shelf.Anchored = true
		shelf.Material = Enum.Material.Wood
		shelf.Color = WOOD_PLANK_COLOR
		shelf.Parent = model
	end

	model.Parent = parent
	return model
end

function Shared.createWoodStove(position: Vector3, parent: Instance, hasEmbers: boolean?, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "WoodStove"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 3, 2.5)
	body.Position = position + Vector3.new(0, 1.5, 0)
	body.Anchored = true
	body.Material = Enum.Material.Metal
	body.Color = Color3.fromRGB(40, 38, 35)
	body.Parent = model

	local chimney = Instance.new("Part")
	chimney.Name = "Chimney"
	chimney.Shape = Enum.PartType.Cylinder
	chimney.Size = Vector3.new(4, 0.8, 0.8)
	chimney.CFrame = CFrame.new(position + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	chimney.Anchored = true
	chimney.Material = Enum.Material.Metal
	chimney.Color = Color3.fromRGB(35, 33, 30)
	chimney.Parent = model

	if hasEmbers then
		local glow = Instance.new("Part")
		glow.Name = "Embers"
		glow.Size = Vector3.new(2, 0.3, 1.8)
		glow.Position = position + Vector3.new(0, 0.3, 0.5)
		glow.Anchored = true
		glow.Material = Enum.Material.Neon
		glow.Color = Color3.fromRGB(180, 60, 20)
		glow.Transparency = 0.3
		glow.Parent = model

		local light = Instance.new("PointLight")
		light.Brightness = 0.3
		light.Color = Color3.fromRGB(255, 120, 40)
		light.Range = 10
		light.Parent = glow
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Campfire Pit
------------------------------------------------------------------------

function Shared.createFirePit(position: Vector3, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "FirePit"

	-- Stone ring
	for i = 0, 7 do
		local angle = i * math.pi / 4
		local stone = Instance.new("Part")
		stone.Name = `Stone_{i}`
		stone.Size = Vector3.new(1.2, 0.6, 0.8)
		stone.Position = position + Vector3.new(math.cos(angle) * 2, 0.3, math.sin(angle) * 2)
		stone.Anchored = true
		stone.Material = Enum.Material.Slate
		stone.Color = ROCK_COLOR_DARK
		stone.Parent = model
	end

	-- Ash/charcoal center
	local ash = Instance.new("Part")
	ash.Name = "Ash"
	ash.Shape = Enum.PartType.Cylinder
	ash.Size = Vector3.new(0.3, 3, 3)
	ash.CFrame = CFrame.new(position + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ash.Anchored = true
	ash.Material = Enum.Material.Ground
	ash.Color = ASH_COLOR
	ash.Parent = model

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Tent
------------------------------------------------------------------------

function Shared.createTent(position: Vector3, parent: Instance, state: string?, name: string?): Model
	-- state: "standing", "collapsed", "shredded"
	local tentState = state or "standing"
	local model = Instance.new("Model")
	model.Name = name or `Tent_{tentState}`

	if tentState == "standing" then
		-- A-frame tent shape (two wedge-like slabs)
		local leftSide = Instance.new("Part")
		leftSide.Name = "LeftSide"
		leftSide.Size = Vector3.new(5, 0.1, 4)
		leftSide.CFrame = CFrame.new(position + Vector3.new(-1.2, 2, 0)) * CFrame.Angles(0, 0, math.rad(40))
		leftSide.Anchored = true
		leftSide.Material = Enum.Material.Fabric
		leftSide.Color = TENT_FABRIC
		leftSide.Parent = model

		local rightSide = Instance.new("Part")
		rightSide.Name = "RightSide"
		rightSide.Size = Vector3.new(5, 0.1, 4)
		rightSide.CFrame = CFrame.new(position + Vector3.new(1.2, 2, 0)) * CFrame.Angles(0, 0, math.rad(-40))
		rightSide.Anchored = true
		rightSide.Material = Enum.Material.Fabric
		rightSide.Color = TENT_FABRIC
		rightSide.Parent = model

		-- Ridge pole
		local pole = Instance.new("Part")
		pole.Name = "Pole"
		pole.Size = Vector3.new(0.2, 0.2, 4.5)
		pole.Position = position + Vector3.new(0, 3.2, 0)
		pole.Anchored = true
		pole.Material = Enum.Material.Metal
		pole.Color = Color3.fromRGB(120, 118, 115)
		pole.Parent = model

	elseif tentState == "collapsed" then
		local fabric = Instance.new("Part")
		fabric.Name = "CollapsedFabric"
		fabric.Size = Vector3.new(5, 0.4, 4)
		fabric.Position = position + Vector3.new(0, 0.2, 0)
		fabric.Orientation = Vector3.new(seededRange(-5, 5), seededRange(-10, 10), seededRange(-3, 3))
		fabric.Anchored = true
		fabric.Material = Enum.Material.Fabric
		fabric.Color = TENT_FABRIC
		fabric.Parent = model

	elseif tentState == "shredded" then
		-- Torn fabric strips
		for i = 1, 4 do
			local strip = Instance.new("Part")
			strip.Name = `Strip_{i}`
			strip.Size = Vector3.new(seededRange(1, 3), seededRange(2, 4), 0.1)
			strip.Position = position + Vector3.new(seededRange(-2, 2), seededRange(0.5, 2), seededRange(-2, 2))
			strip.Orientation = Vector3.new(seededRange(-30, 30), seededRange(0, 180), seededRange(-20, 20))
			strip.Anchored = true
			strip.Material = Enum.Material.Fabric
			strip.Color = TENT_FABRIC
			strip.CanCollide = false
			strip.Parent = model
		end

		-- Bent poles
		for i = 1, 2 do
			local pole = Instance.new("Part")
			pole.Name = `BentPole_{i}`
			pole.Size = Vector3.new(0.2, 3, 0.2)
			pole.Position = position + Vector3.new(seededRange(-1, 1), 1.5, seededRange(-1, 1))
			pole.Orientation = Vector3.new(seededRange(-20, 20), 0, seededRange(-30, 30))
			pole.Anchored = true
			pole.Material = Enum.Material.Metal
			pole.Color = Color3.fromRGB(120, 118, 115)
			pole.Parent = model
		end
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Hiding Spot Builder (forest-specific types)
------------------------------------------------------------------------

--[[
	Forest hiding spot types:
	- "BehindRock"
	- "InBush"
	- "UnderLog"
	- "InCabin"
	- "InTent"
	- "InCellar"
]]
function Shared.createHidingSpot(
	position: Vector3,
	spotType: string,
	id: string,
	parent: Instance
): (Part, HidingSpotData)
	local spot = Instance.new("Part")
	spot.Name = `HidingSpot_{id}`
	spot.Transparency = 1
	spot.CanCollide = false
	spot.Anchored = true
	spot.Size = Vector3.new(3, 5, 3)
	spot.Position = position

	spot:SetAttribute("HidingSpotId", id)
	spot:SetAttribute("SpotType", spotType)
	spot:SetAttribute("IsOccupied", false)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Hide"
	prompt.ObjectText = spotType
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 6
	prompt.Parent = spot

	spot.Parent = parent

	local data: HidingSpotData = {
		id = id,
		position = position,
		spotType = spotType,
		isOccupied = false,
	}

	return spot, data
end

------------------------------------------------------------------------
-- Moonlight / Ambient Light
------------------------------------------------------------------------

function Shared.createMoonlight(position: Vector3, parent: Instance, brightness: number?, range: number?): Part
	local fixture = Instance.new("Part")
	fixture.Name = "MoonlightSource"
	fixture.Size = Vector3.new(1, 1, 1)
	fixture.Position = position
	fixture.Anchored = true
	fixture.Transparency = 1
	fixture.CanCollide = false

	local light = Instance.new("PointLight")
	light.Brightness = brightness or 0.15
	light.Color = MOONLIGHT_COLOR
	light.Range = range or 40
	light.Shadows = true
	light.Parent = fixture

	fixture.Parent = parent
	return fixture
end

function Shared.createInteriorLight(position: Vector3, parent: Instance, brightness: number?, color: Color3?): Part
	local fixture = Instance.new("Part")
	fixture.Name = "InteriorLight"
	fixture.Size = Vector3.new(0.8, 0.3, 0.8)
	fixture.Position = position
	fixture.Anchored = true
	fixture.Material = Enum.Material.SmoothPlastic
	fixture.Color = Color3.fromRGB(200, 190, 160)
	fixture.Transparency = 0.5

	local light = Instance.new("PointLight")
	light.Brightness = brightness or 0.3
	light.Color = color or Color3.fromRGB(255, 220, 160)
	light.Range = 15
	light.Shadows = true
	light.Parent = fixture

	fixture.Parent = parent
	return fixture
end

------------------------------------------------------------------------
-- Watchtower
------------------------------------------------------------------------

function Shared.createWatchtower(position: Vector3, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "Watchtower"

	local towerHeight = 40
	local platformSize = 10
	local legInset = 3

	-- Four legs (wooden posts)
	local legPositions = {
		Vector3.new(-legInset, 0, -legInset),
		Vector3.new(legInset, 0, -legInset),
		Vector3.new(-legInset, 0, legInset),
		Vector3.new(legInset, 0, legInset),
	}

	for i, offset in legPositions do
		local leg = Instance.new("Part")
		leg.Name = `Leg_{i}`
		leg.Size = Vector3.new(1, towerHeight, 1)
		leg.Position = position + offset + Vector3.new(0, towerHeight / 2, 0)
		leg.Anchored = true
		leg.Material = Enum.Material.Wood
		leg.Color = WOOD_PLANK_DARK
		leg.Parent = model
	end

	-- Cross braces (X pattern on each face, simplified as diagonal parts)
	for i = 0, 3 do
		local brace = Instance.new("Part")
		brace.Name = `Brace_{i}`
		brace.Size = Vector3.new(0.4, towerHeight * 0.5, 0.4)
		local angle = i * math.pi / 2
		brace.Position = position + Vector3.new(
			math.cos(angle) * legInset,
			towerHeight * 0.25,
			math.sin(angle) * legInset
		)
		brace.Orientation = Vector3.new(0, math.deg(angle), 30)
		brace.Anchored = true
		brace.Material = Enum.Material.Wood
		brace.Color = WOOD_PLANK_DARK
		brace.Parent = model
	end

	-- Platform
	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = Vector3.new(platformSize, 0.5, platformSize)
	platform.Position = position + Vector3.new(0, towerHeight, 0)
	platform.Anchored = true
	platform.Material = Enum.Material.Wood
	platform.Color = WOOD_PLANK_COLOR
	platform.Parent = model

	-- Railing
	for side = 0, 3 do
		local rAngle = side * math.pi / 2
		local rPos = Vector3.new(
			math.cos(rAngle) * (platformSize / 2),
			towerHeight + 1.5,
			math.sin(rAngle) * (platformSize / 2)
		)
		local railing = Instance.new("Part")
		railing.Name = `Railing_{side}`
		if side % 2 == 0 then
			railing.Size = Vector3.new(platformSize, 0.4, 0.3)
		else
			railing.Size = Vector3.new(0.3, 0.4, platformSize)
		end
		railing.Position = position + rPos
		railing.Anchored = true
		railing.Material = Enum.Material.Wood
		railing.Color = WOOD_PLANK_DARK
		railing.Parent = model
	end

	-- Ladder
	local ladderHeight = towerHeight
	local ladderPost = Instance.new("Part")
	ladderPost.Name = "LadderRail_L"
	ladderPost.Size = Vector3.new(0.3, ladderHeight, 0.3)
	ladderPost.Position = position + Vector3.new(-1, ladderHeight / 2, platformSize / 2 + 0.5)
	ladderPost.Anchored = true
	ladderPost.Material = Enum.Material.Wood
	ladderPost.Color = WOOD_PLANK_DARK
	ladderPost.Parent = model

	local ladderPost2 = Instance.new("Part")
	ladderPost2.Name = "LadderRail_R"
	ladderPost2.Size = Vector3.new(0.3, ladderHeight, 0.3)
	ladderPost2.Position = position + Vector3.new(1, ladderHeight / 2, platformSize / 2 + 0.5)
	ladderPost2.Anchored = true
	ladderPost2.Material = Enum.Material.Wood
	ladderPost2.Color = WOOD_PLANK_DARK
	ladderPost2.Parent = model

	-- Ladder rungs
	for r = 1, math.floor(ladderHeight / 2) do
		local rung = Instance.new("Part")
		rung.Name = `Rung_{r}`
		rung.Size = Vector3.new(2, 0.2, 0.3)
		rung.Position = position + Vector3.new(0, r * 2, platformSize / 2 + 0.5)
		rung.Anchored = true
		rung.Material = Enum.Material.Wood
		rung.Color = WOOD_PLANK_COLOR
		rung.Parent = model
	end

	-- Ladder climb prompt
	local climbPart = Instance.new("Part")
	climbPart.Name = "LadderClimb"
	climbPart.Size = Vector3.new(3, 3, 2)
	climbPart.Position = position + Vector3.new(0, 1.5, platformSize / 2 + 0.5)
	climbPart.Anchored = true
	climbPart.Transparency = 1
	climbPart.CanCollide = false
	climbPart.Parent = model

	local climbPrompt = Instance.new("ProximityPrompt")
	climbPrompt.ActionText = "Climb"
	climbPrompt.ObjectText = "Watchtower Ladder"
	climbPrompt.HoldDuration = 4
	climbPrompt.MaxActivationDistance = 8
	climbPrompt.Parent = climbPart

	-- Roof (small pitched roof over platform)
	local roof = Instance.new("Part")
	roof.Name = "Roof"
	roof.Size = Vector3.new(platformSize + 2, 0.4, platformSize + 2)
	roof.Position = position + Vector3.new(0, towerHeight + 4, 0)
	roof.Anchored = true
	roof.Material = Enum.Material.Wood
	roof.Color = WOOD_PLANK_DARK
	roof.Parent = model

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Wooden Fence
------------------------------------------------------------------------

function Shared.createFenceSegment(startPos: Vector3, endPos: Vector3, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "Fence"

	local dx = endPos.X - startPos.X
	local dz = endPos.Z - startPos.Z
	local length = math.sqrt(dx * dx + dz * dz)
	local angle = math.atan2(dx, dz)
	local center = (startPos + endPos) / 2

	-- Posts at each end
	for _, pos in { startPos, endPos } do
		local post = Instance.new("Part")
		post.Name = "FencePost"
		post.Size = Vector3.new(0.4, 4, 0.4)
		post.Position = pos + Vector3.new(0, 2, 0)
		post.Anchored = true
		post.Material = Enum.Material.Wood
		post.Color = WOOD_PLANK_DARK
		post.Parent = model
	end

	-- Horizontal rails
	for _, yOff in { 1.5, 3 } do
		local rail = Instance.new("Part")
		rail.Name = "Rail"
		rail.Size = Vector3.new(0.3, 0.3, length)
		rail.CFrame = CFrame.new(center + Vector3.new(0, yOff, 0)) * CFrame.Angles(0, angle, 0)
		rail.Anchored = true
		rail.Material = Enum.Material.Wood
		rail.Color = WOOD_PLANK_COLOR
		rail.Parent = model
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Radio Tower (metal lattice)
------------------------------------------------------------------------

function Shared.createRadioTower(position: Vector3, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "RadioTower"

	local towerHeight = 60
	local baseWidth = 6
	local topWidth = 1.5

	-- Four main legs (tapered)
	for i, corner in {
		Vector3.new(-1, 0, -1),
		Vector3.new(1, 0, -1),
		Vector3.new(-1, 0, 1),
		Vector3.new(1, 0, 1),
	} do
		local sections = 6
		for s = 0, sections - 1 do
			local t0 = s / sections
			local t1 = (s + 1) / sections
			local w0 = baseWidth / 2 * (1 - t0) + topWidth / 2 * t0
			local w1 = baseWidth / 2 * (1 - t1) + topWidth / 2 * t1
			local y0 = towerHeight * t0
			local y1 = towerHeight * t1

			local sectionPart = Instance.new("Part")
			sectionPart.Name = `Leg_{i}_Section_{s}`
			local cx = (corner.X * w0 + corner.X * w1) / 2
			local cz = (corner.Z * w0 + corner.Z * w1) / 2
			sectionPart.Size = Vector3.new(0.4, towerHeight / sections, 0.4)
			sectionPart.Position = position + Vector3.new(cx, (y0 + y1) / 2, cz)
			sectionPart.Anchored = true
			sectionPart.Material = Enum.Material.Metal
			sectionPart.Color = Color3.fromRGB(110, 108, 105)
			sectionPart.Parent = model
		end
	end

	-- Cross-braces at intervals
	for level = 0, 5 do
		local t = level / 6
		local w = baseWidth * (1 - t) + topWidth * t
		local y = towerHeight * t

		local brace = Instance.new("Part")
		brace.Name = `CrossBrace_{level}`
		brace.Size = Vector3.new(w, 0.2, w)
		brace.Position = position + Vector3.new(0, y, 0)
		brace.Anchored = true
		brace.Material = Enum.Material.Metal
		brace.Color = Color3.fromRGB(100, 98, 95)
		brace.Parent = model
	end

	-- Antenna at top
	local antenna = Instance.new("Part")
	antenna.Name = "Antenna"
	antenna.Shape = Enum.PartType.Cylinder
	antenna.Size = Vector3.new(8, 0.3, 0.3)
	antenna.CFrame = CFrame.new(position + Vector3.new(0, towerHeight + 4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	antenna.Anchored = true
	antenna.Material = Enum.Material.Metal
	antenna.Color = Color3.fromRGB(150, 148, 145)
	antenna.Parent = model

	-- Warning light (dead)
	local warningLight = Instance.new("Part")
	warningLight.Name = "WarningLight"
	warningLight.Shape = Enum.PartType.Ball
	warningLight.Size = Vector3.new(1, 1, 1)
	warningLight.Position = position + Vector3.new(0, towerHeight + 8.5, 0)
	warningLight.Anchored = true
	warningLight.Material = Enum.Material.Glass
	warningLight.Color = Color3.fromRGB(60, 15, 15) -- dead red light
	warningLight.Parent = model

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Radio Bunker
------------------------------------------------------------------------

function Shared.createBunker(position: Vector3, size: Vector3, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "Bunker"

	local sx = size.X
	local sy = size.Y
	local sz = size.Z
	local wt = 1.5 -- thick concrete walls

	-- Floor
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(sx + wt * 2, 1, sz + wt * 2)
	floor.Position = Vector3.new(position.X, position.Y - 0.5, position.Z)
	floor.Anchored = true
	floor.Material = Enum.Material.Concrete
	floor.Color = CONCRETE_COLOR
	floor.Parent = model

	-- Walls
	local wallCY = position.Y + sy / 2
	-- North
	local nWall = Instance.new("Part")
	nWall.Name = "Wall_North"
	nWall.Size = Vector3.new(sx + wt * 2, sy, wt)
	nWall.Position = Vector3.new(position.X, wallCY, position.Z - sz / 2 - wt / 2)
	nWall.Anchored = true
	nWall.Material = Enum.Material.Concrete
	nWall.Color = CONCRETE_COLOR
	nWall.Parent = model

	-- East
	local eWall = Instance.new("Part")
	eWall.Name = "Wall_East"
	eWall.Size = Vector3.new(wt, sy, sz)
	eWall.Position = Vector3.new(position.X + sx / 2 + wt / 2, wallCY, position.Z)
	eWall.Anchored = true
	eWall.Material = Enum.Material.Concrete
	eWall.Color = CONCRETE_COLOR
	eWall.Parent = model

	-- West
	local wWall = Instance.new("Part")
	wWall.Name = "Wall_West"
	wWall.Size = Vector3.new(wt, sy, sz)
	wWall.Position = Vector3.new(position.X - sx / 2 - wt / 2, wallCY, position.Z)
	wWall.Anchored = true
	wWall.Material = Enum.Material.Concrete
	wWall.Color = CONCRETE_COLOR
	wWall.Parent = model

	-- South wall with door opening
	local doorW = 4
	local doorH = 7
	local sideLen = (sx + wt * 2 - doorW) / 2

	if sideLen > 0 then
		-- Left
		local sL = Instance.new("Part")
		sL.Name = "Wall_South_L"
		sL.Size = Vector3.new(sideLen, sy, wt)
		sL.Position = Vector3.new(position.X - (sideLen + doorW) / 2, wallCY, position.Z + sz / 2 + wt / 2)
		sL.Anchored = true
		sL.Material = Enum.Material.Concrete
		sL.Color = CONCRETE_COLOR
		sL.Parent = model

		-- Right
		local sR = Instance.new("Part")
		sR.Name = "Wall_South_R"
		sR.Size = Vector3.new(sideLen, sy, wt)
		sR.Position = Vector3.new(position.X + (sideLen + doorW) / 2, wallCY, position.Z + sz / 2 + wt / 2)
		sR.Anchored = true
		sR.Material = Enum.Material.Concrete
		sR.Color = CONCRETE_COLOR
		sR.Parent = model
	end

	-- Transom above door
	local transomH = sy - doorH
	if transomH > 0 then
		local transom = Instance.new("Part")
		transom.Name = "Wall_South_Top"
		transom.Size = Vector3.new(doorW, transomH, wt)
		transom.Position = Vector3.new(position.X, wallCY + doorH / 2 + transomH / 2 - sy / 2, position.Z + sz / 2 + wt / 2)
		transom.Anchored = true
		transom.Material = Enum.Material.Concrete
		transom.Color = CONCRETE_COLOR
		transom.Parent = model
	end

	-- Ceiling
	local ceiling = Instance.new("Part")
	ceiling.Name = "Ceiling"
	ceiling.Size = Vector3.new(sx + wt * 2, 1, sz + wt * 2)
	ceiling.Position = Vector3.new(position.X, position.Y + sy + 0.5, position.Z)
	ceiling.Anchored = true
	ceiling.Material = Enum.Material.Concrete
	ceiling.Color = CONCRETE_COLOR
	ceiling.Parent = model

	-- Steel door (ajar)
	local door = Instance.new("Part")
	door.Name = "SteelDoor"
	door.Size = Vector3.new(doorW, doorH, 0.4)
	door.CFrame = CFrame.new(position.X + doorW / 2, position.Y + doorH / 2, position.Z + sz / 2 + wt / 2)
		* CFrame.Angles(0, math.rad(30), 0) -- ajar
	door.Anchored = true
	door.Material = Enum.Material.Metal
	door.Color = Color3.fromRGB(80, 78, 75)
	door.Parent = model

	local doorPrompt = Instance.new("ProximityPrompt")
	doorPrompt.ActionText = "Close"
	doorPrompt.ObjectText = "Steel Door"
	doorPrompt.HoldDuration = 0.5
	doorPrompt.MaxActivationDistance = 8
	doorPrompt.Parent = door

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Exported Constants (for use by area modules)
------------------------------------------------------------------------

Shared.Colors = {
	GROUND = GROUND_COLOR,
	TRAIL = TRAIL_COLOR,
	GRAVEL = GRAVEL_COLOR,
	BARK_DARK = BARK_COLOR_DARK,
	BARK_MID = BARK_COLOR_MID,
	CANOPY_DARK = CANOPY_COLOR_DARK,
	CANOPY_MID = CANOPY_COLOR_MID,
	ROCK_DARK = ROCK_COLOR_DARK,
	ROCK_LIGHT = ROCK_COLOR_LIGHT,
	BUSH = BUSH_COLOR,
	WATER = WATER_COLOR,
	FOG_WALL = FOG_WALL_COLOR,
	WOOD_PLANK = WOOD_PLANK_COLOR,
	WOOD_DARK = WOOD_PLANK_DARK,
	RUSTED_METAL = RUSTED_METAL,
	STONE_CARVED = STONE_CARVED,
	CONCRETE = CONCRETE_COLOR,
	MOONLIGHT = MOONLIGHT_COLOR,
	CHARRED = CHARRED_COLOR,
	ASH = ASH_COLOR,
}

return Shared
