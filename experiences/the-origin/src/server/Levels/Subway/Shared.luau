--!strict

--[[
	Subway/Shared - Builder helper functions for the Level 2 subway geometry.

	Provides subway-specific primitives (tunnel sections, platform edges,
	track beds, rail lines, train car shells, turnstiles, ticket machines,
	vending machines, benches, overhead pipes, emergency lights, etc.)
	as well as re-exports of generic helpers (walls, floors, ceilings,
	rooms, corridors, doors, lights, hiding spots).

	All geometry is created via Instance.new() -- no external assets.
]]

local Shared = {}

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

-- Subway palette (dark, underground, industrial)
local CONCRETE_WALL_COLOR = Color3.fromRGB(100, 98, 92)
local CONCRETE_FLOOR_COLOR = Color3.fromRGB(85, 85, 80)
local CONCRETE_CEILING_COLOR = Color3.fromRGB(90, 88, 82)
local TILE_WALL_COLOR = Color3.fromRGB(165, 170, 165)
local TILE_FLOOR_COLOR = Color3.fromRGB(130, 135, 130)
local PLATFORM_EDGE_COLOR = Color3.fromRGB(200, 190, 50) -- yellow safety line
local RAIL_COLOR = Color3.fromRGB(120, 115, 105)
local TRACK_BED_COLOR = Color3.fromRGB(65, 60, 55)
local METAL_COLOR = Color3.fromRGB(110, 110, 105)
local TRAIN_EXTERIOR_COLOR = Color3.fromRGB(160, 165, 170)
local TRAIN_INTERIOR_COLOR = Color3.fromRGB(140, 140, 135)
local SEAT_COLOR = Color3.fromRGB(50, 70, 100)
local DARK_METAL_COLOR = Color3.fromRGB(55, 55, 50)
local PIPE_COLOR = Color3.fromRGB(100, 95, 90)
local RUBBLE_COLOR = Color3.fromRGB(110, 105, 100)
local REBAR_COLOR = Color3.fromRGB(130, 80, 60)
local WEBBING_COLOR = Color3.fromRGB(180, 170, 150)
local WATER_COLOR = Color3.fromRGB(40, 50, 55)

local DEFAULT_WALL_THICKNESS = 1
local DEFAULT_DOOR_WIDTH = 5
local DEFAULT_DOOR_HEIGHT = 8
local TUNNEL_HEIGHT = 14
local PLATFORM_HEIGHT = 4 -- platform surface above track bed

------------------------------------------------------------------------
-- Type Definitions
------------------------------------------------------------------------

export type DoorwayDef = {
	wall: "north" | "south" | "east" | "west",
	offset: number,
	width: number,
	height: number,
}

export type RoomConfig = {
	position: Vector3,
	size: Vector3,
	parent: Instance,
	name: string?,
	wallThickness: number?,
	floorMaterial: Enum.Material?,
	wallMaterial: Enum.Material?,
	ceilingMaterial: Enum.Material?,
	wallColor: Color3?,
	floorColor: Color3?,
	ceilingColor: Color3?,
	doorways: { DoorwayDef }?,
	noFloor: boolean?,
	noCeiling: boolean?,
}

export type HidingSpotData = {
	id: string,
	position: Vector3,
	spotType: string,
	isOccupied: boolean,
}

------------------------------------------------------------------------
-- Generic Primitive Builders
------------------------------------------------------------------------

function Shared.createWall(position: Vector3, size: Vector3, parent: Instance, name: string?): Part
	local wall = Instance.new("Part")
	wall.Name = name or "Wall"
	wall.Size = size
	wall.Position = position
	wall.Anchored = true
	wall.Material = Enum.Material.Concrete
	wall.Color = CONCRETE_WALL_COLOR
	wall.Parent = parent
	return wall
end

function Shared.createFloor(position: Vector3, size: Vector3, parent: Instance, name: string?): Part
	local floor = Instance.new("Part")
	floor.Name = name or "Floor"
	floor.Size = size
	floor.Position = position
	floor.Anchored = true
	floor.Material = Enum.Material.Concrete
	floor.Color = CONCRETE_FLOOR_COLOR
	floor.Parent = parent
	return floor
end

function Shared.createCeiling(position: Vector3, size: Vector3, parent: Instance, name: string?): Part
	local ceiling = Instance.new("Part")
	ceiling.Name = name or "Ceiling"
	ceiling.Size = size
	ceiling.Position = position
	ceiling.Anchored = true
	ceiling.Material = Enum.Material.Concrete
	ceiling.Color = CONCRETE_CEILING_COLOR
	ceiling.Parent = parent
	return ceiling
end

------------------------------------------------------------------------
-- Room Builder  (same algorithm as Hospital/Shared)
------------------------------------------------------------------------

function Shared.createRoom(config: RoomConfig): Model
	local model = Instance.new("Model")
	model.Name = config.name or "Room"

	local pos = config.position
	local sx = config.size.X
	local sy = config.size.Y
	local sz = config.size.Z
	local wt = config.wallThickness or DEFAULT_WALL_THICKNESS

	local wallMat = config.wallMaterial or Enum.Material.Concrete
	local wallCol = config.wallColor or CONCRETE_WALL_COLOR
	local floorMat = config.floorMaterial or Enum.Material.Concrete
	local floorCol = config.floorColor or CONCRETE_FLOOR_COLOR
	local ceilMat = config.ceilingMaterial or Enum.Material.Concrete
	local ceilCol = config.ceilingColor or CONCRETE_CEILING_COLOR

	local function stylePart(part: Part, mat: Enum.Material, col: Color3)
		part.Material = mat
		part.Color = col
	end

	-- Floor
	if not config.noFloor then
		local flr = Shared.createFloor(
			Vector3.new(pos.X, pos.Y - 0.5, pos.Z),
			Vector3.new(sx + wt * 2, 1, sz + wt * 2),
			model,
			"Floor"
		)
		stylePart(flr, floorMat, floorCol)
	end

	-- Ceiling
	if not config.noCeiling then
		local ceil = Shared.createCeiling(
			Vector3.new(pos.X, pos.Y + sy + 0.5, pos.Z),
			Vector3.new(sx + wt * 2, 1, sz + wt * 2),
			model,
			"Ceiling"
		)
		stylePart(ceil, ceilMat, ceilCol)
	end

	-- Build doorway lookup
	local doorwayMap: { [string]: { DoorwayDef } } = {
		north = {},
		south = {},
		east = {},
		west = {},
	}
	if config.doorways then
		for _, dw in config.doorways do
			table.insert(doorwayMap[dw.wall], dw)
		end
	end
	for _, list in doorwayMap do
		table.sort(list, function(a, b)
			return a.offset < b.offset
		end)
	end

	local function buildWallWithDoorways(
		wallCenter: Vector3,
		wallLen: number,
		wallHeight: number,
		axis: string,
		doorways: { DoorwayDef },
		wallName: string
	)
		if #doorways == 0 then
			local size: Vector3
			if axis == "x" then
				size = Vector3.new(wallLen, wallHeight, wt)
			else
				size = Vector3.new(wt, wallHeight, wallLen)
			end
			local w = Shared.createWall(wallCenter, size, model, wallName)
			stylePart(w, wallMat, wallCol)
			return
		end

		local segments: { { start: number, finish: number, isUpper: boolean, doorHeight: number } } = {}
		local cursor = 0

		for _, dw in doorways do
			local dwCenter = wallLen / 2 + dw.offset
			local dwStart = dwCenter - dw.width / 2
			local dwEnd = dwCenter + dw.width / 2
			dwStart = math.max(0, dwStart)
			dwEnd = math.min(wallLen, dwEnd)

			if dwStart > cursor then
				table.insert(segments, { start = cursor, finish = dwStart, isUpper = false, doorHeight = 0 })
			end

			local dwH = math.min(dw.height, wallHeight)
			if dwH < wallHeight then
				table.insert(segments, { start = dwStart, finish = dwEnd, isUpper = true, doorHeight = dwH })
			end

			cursor = dwEnd
		end

		if cursor < wallLen then
			table.insert(segments, { start = cursor, finish = wallLen, isUpper = false, doorHeight = 0 })
		end

		for i, seg in segments do
			local segLen = seg.finish - seg.start
			if segLen <= 0 then
				continue
			end

			local segCenter1D = seg.start + segLen / 2 - wallLen / 2
			local segPos: Vector3
			local segSize: Vector3

			if seg.isUpper then
				local transomH = wallHeight - seg.doorHeight
				local transomY = wallCenter.Y + seg.doorHeight / 2 + transomH / 2

				if axis == "x" then
					segPos = Vector3.new(wallCenter.X + segCenter1D, transomY, wallCenter.Z)
					segSize = Vector3.new(segLen, transomH, wt)
				else
					segPos = Vector3.new(wallCenter.X, transomY, wallCenter.Z + segCenter1D)
					segSize = Vector3.new(wt, transomH, segLen)
				end
			else
				if axis == "x" then
					segPos = Vector3.new(wallCenter.X + segCenter1D, wallCenter.Y, wallCenter.Z)
					segSize = Vector3.new(segLen, wallHeight, wt)
				else
					segPos = Vector3.new(wallCenter.X, wallCenter.Y, wallCenter.Z + segCenter1D)
					segSize = Vector3.new(wt, wallHeight, segLen)
				end
			end

			local w = Shared.createWall(segPos, segSize, model, `{wallName}_Seg{i}`)
			stylePart(w, wallMat, wallCol)
		end
	end

	local wallCY = pos.Y + sy / 2

	-- North wall
	buildWallWithDoorways(
		Vector3.new(pos.X, wallCY, pos.Z - sz / 2 - wt / 2),
		sx + wt * 2, sy, "x", doorwayMap["north"], "Wall_North"
	)
	-- South wall
	buildWallWithDoorways(
		Vector3.new(pos.X, wallCY, pos.Z + sz / 2 + wt / 2),
		sx + wt * 2, sy, "x", doorwayMap["south"], "Wall_South"
	)
	-- West wall
	buildWallWithDoorways(
		Vector3.new(pos.X - sx / 2 - wt / 2, wallCY, pos.Z),
		sz, sy, "z", doorwayMap["west"], "Wall_West"
	)
	-- East wall
	buildWallWithDoorways(
		Vector3.new(pos.X + sx / 2 + wt / 2, wallCY, pos.Z),
		sz, sy, "z", doorwayMap["east"], "Wall_East"
	)

	model.Parent = config.parent
	return model
end

------------------------------------------------------------------------
-- Corridor Builder
------------------------------------------------------------------------

function Shared.createCorridor(
	startPos: Vector3,
	endPos: Vector3,
	width: number,
	height: number,
	parent: Instance,
	name: string?
): Model
	local model = Instance.new("Model")
	model.Name = name or "Corridor"

	local dx = endPos.X - startPos.X
	local dz = endPos.Z - startPos.Z
	local centerX = (startPos.X + endPos.X) / 2
	local centerZ = (startPos.Z + endPos.Z) / 2
	local floorY = math.min(startPos.Y, endPos.Y)

	local length: number
	local isXAligned: boolean

	if math.abs(dx) >= math.abs(dz) then
		length = math.abs(dx)
		isXAligned = true
	else
		length = math.abs(dz)
		isXAligned = false
	end

	-- Floor
	if isXAligned then
		Shared.createFloor(Vector3.new(centerX, floorY - 0.5, centerZ), Vector3.new(length, 1, width), model, "Floor")
	else
		Shared.createFloor(Vector3.new(centerX, floorY - 0.5, centerZ), Vector3.new(width, 1, length), model, "Floor")
	end

	-- Ceiling
	if isXAligned then
		Shared.createCeiling(
			Vector3.new(centerX, floorY + height + 0.5, centerZ),
			Vector3.new(length, 1, width), model, "Ceiling"
		)
	else
		Shared.createCeiling(
			Vector3.new(centerX, floorY + height + 0.5, centerZ),
			Vector3.new(width, 1, length), model, "Ceiling"
		)
	end

	-- Side walls
	local wt = 1
	if isXAligned then
		Shared.createWall(
			Vector3.new(centerX, floorY + height / 2, centerZ - width / 2 - wt / 2),
			Vector3.new(length, height, wt), model, "Wall_Left"
		)
		Shared.createWall(
			Vector3.new(centerX, floorY + height / 2, centerZ + width / 2 + wt / 2),
			Vector3.new(length, height, wt), model, "Wall_Right"
		)
	else
		Shared.createWall(
			Vector3.new(centerX - width / 2 - wt / 2, floorY + height / 2, centerZ),
			Vector3.new(wt, height, length), model, "Wall_Left"
		)
		Shared.createWall(
			Vector3.new(centerX + width / 2 + wt / 2, floorY + height / 2, centerZ),
			Vector3.new(wt, height, length), model, "Wall_Right"
		)
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Stairwell Builder
------------------------------------------------------------------------

function Shared.createStairwell(
	bottomY: number,
	topY: number,
	position: Vector3,
	parent: Instance,
	name: string?
): Model
	local model = Instance.new("Model")
	model.Name = name or "Stairwell"

	local totalRise = topY - bottomY
	local stepCount = math.floor(totalRise)
	local stepWidth = 6
	local stepDepth = 2
	local stairDepth = stepCount / 2 * stepDepth

	-- Bottom landing
	local landingBottom = Shared.createFloor(
		Vector3.new(position.X, bottomY - 0.5, position.Z - stairDepth / 2 - 2),
		Vector3.new(stepWidth, 1, 4), model, "Landing_Bottom"
	)
	landingBottom.Material = Enum.Material.Concrete
	landingBottom.Color = Color3.fromRGB(100, 100, 95)

	-- First half steps (+Z)
	local halfSteps = math.floor(stepCount / 2)
	for i = 0, halfSteps - 1 do
		local step = Instance.new("Part")
		step.Name = `Step_{i}`
		step.Size = Vector3.new(stepWidth, 1, stepDepth)
		step.Position = Vector3.new(position.X, bottomY + i + 0.5, position.Z - stairDepth / 2 + i * stepDepth)
		step.Anchored = true
		step.Material = Enum.Material.Concrete
		step.Color = Color3.fromRGB(100, 100, 95)
		step.Parent = model
	end

	-- Mid landing
	local midY = bottomY + halfSteps
	local midLanding = Shared.createFloor(
		Vector3.new(position.X, midY - 0.5, position.Z + stairDepth / 2 + 2),
		Vector3.new(stepWidth, 1, 4), model, "Landing_Mid"
	)
	midLanding.Material = Enum.Material.Concrete
	midLanding.Color = Color3.fromRGB(100, 100, 95)

	-- Second half steps (-Z switchback)
	local remainingSteps = stepCount - halfSteps
	for i = 0, remainingSteps - 1 do
		local step = Instance.new("Part")
		step.Name = `Step_{halfSteps + i}`
		step.Size = Vector3.new(stepWidth, 1, stepDepth)
		step.Position = Vector3.new(position.X, midY + i + 0.5, position.Z + stairDepth / 2 - i * stepDepth)
		step.Anchored = true
		step.Material = Enum.Material.Concrete
		step.Color = Color3.fromRGB(100, 100, 95)
		step.Parent = model
	end

	-- Top landing
	local landingTop = Shared.createFloor(
		Vector3.new(position.X, topY - 0.5, position.Z - stairDepth / 2 - 2),
		Vector3.new(stepWidth, 1, 4), model, "Landing_Top"
	)
	landingTop.Material = Enum.Material.Concrete
	landingTop.Color = Color3.fromRGB(100, 100, 95)

	-- Shaft walls
	local shaftHeight = totalRise + 2
	local shaftCenterY = (bottomY + topY) / 2
	Shared.createWall(
		Vector3.new(position.X - stepWidth / 2 - 0.5, shaftCenterY, position.Z),
		Vector3.new(1, shaftHeight, stairDepth + 8), model, "ShaftWall_West"
	)
	Shared.createWall(
		Vector3.new(position.X + stepWidth / 2 + 0.5, shaftCenterY, position.Z),
		Vector3.new(1, shaftHeight, stairDepth + 8), model, "ShaftWall_East"
	)

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Door Builder
------------------------------------------------------------------------

function Shared.createDoor(
	position: Vector3,
	rotation: CFrame?,
	parent: Instance,
	name: string?,
	isLocked: boolean?,
	requiredKey: string?
): Part
	local door = Instance.new("Part")
	door.Name = name or "Door"
	door.Size = Vector3.new(DEFAULT_DOOR_WIDTH, DEFAULT_DOOR_HEIGHT, 0.5)
	door.Anchored = true
	door.Material = Enum.Material.Metal
	door.Color = DARK_METAL_COLOR

	if rotation then
		door.CFrame = rotation + position
	else
		door.Position = position
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = name or "Door"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 8

	if isLocked then
		prompt.ActionText = "Locked"
		prompt.Enabled = true
		door:SetAttribute("IsLocked", true)
		door:SetAttribute("RequiredKey", requiredKey or "")
	else
		prompt.ActionText = "Open"
	end

	prompt.Parent = door
	door.Parent = parent
	return door
end

------------------------------------------------------------------------
-- Light Builder
------------------------------------------------------------------------

function Shared.createLight(position: Vector3, parent: Instance, brightness: number?, color: Color3?): Part
	local fixture = Instance.new("Part")
	fixture.Name = "LightFixture"
	fixture.Size = Vector3.new(1, 0.5, 1)
	fixture.Position = position
	fixture.Anchored = true
	fixture.Material = Enum.Material.SmoothPlastic
	fixture.Color = Color3.fromRGB(200, 200, 190)
	fixture.Transparency = 0.3

	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = brightness or 0.2
	pointLight.Color = color or Color3.fromRGB(255, 200, 150)
	pointLight.Range = 20
	pointLight.Shadows = true
	pointLight.Parent = fixture

	fixture.Parent = parent
	return fixture
end

------------------------------------------------------------------------
-- Hiding Spot Builder
------------------------------------------------------------------------

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
-- Pipe Builder (cylinder)
------------------------------------------------------------------------

function Shared.createPipe(
	position: Vector3,
	length: number,
	radius: number,
	orientation: Vector3,
	parent: Instance,
	name: string?
): Part
	local pipe = Instance.new("Part")
	pipe.Name = name or "Pipe"
	pipe.Shape = Enum.PartType.Cylinder
	pipe.Size = Vector3.new(length, radius * 2, radius * 2)
	pipe.Position = position
	pipe.Orientation = orientation
	pipe.Anchored = true
	pipe.Material = Enum.Material.Metal
	pipe.Color = PIPE_COLOR
	pipe.Parent = parent
	return pipe
end

------------------------------------------------------------------------
-- Emergency Light (dim red/amber LED strip)
------------------------------------------------------------------------

function Shared.createEmergencyLight(position: Vector3, parent: Instance, color: Color3?): Part
	local lightColor = color or Color3.fromRGB(180, 40, 30) -- dim red
	local fixture = Instance.new("Part")
	fixture.Name = "EmergencyLight"
	fixture.Size = Vector3.new(2, 0.3, 0.3)
	fixture.Position = position
	fixture.Anchored = true
	fixture.Material = Enum.Material.Neon
	fixture.Color = lightColor
	fixture.Transparency = 0.2

	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 0.15
	pointLight.Color = lightColor
	pointLight.Range = 14
	pointLight.Shadows = true
	pointLight.Parent = fixture

	fixture.Parent = parent
	return fixture
end

------------------------------------------------------------------------
-- Subway-Specific: Track Bed
------------------------------------------------------------------------

--[[
	Creates a track bed (two rails + gravel base) along a line.
	Axis-aligned only. Returns a Model.
]]
function Shared.createTrackBed(
	startPos: Vector3,
	endPos: Vector3,
	parent: Instance,
	name: string?
): Model
	local model = Instance.new("Model")
	model.Name = name or "TrackBed"

	local dx = endPos.X - startPos.X
	local dz = endPos.Z - startPos.Z
	local centerX = (startPos.X + endPos.X) / 2
	local centerZ = (startPos.Z + endPos.Z) / 2
	local baseY = math.min(startPos.Y, endPos.Y)

	local isXAligned = math.abs(dx) >= math.abs(dz)
	local length = if isXAligned then math.abs(dx) else math.abs(dz)

	local trackGauge = 5 -- distance between rails
	local railHeight = 0.4
	local railWidth = 0.3
	local bedWidth = 8
	local bedHeight = 0.4

	-- Gravel bed
	local bed = Instance.new("Part")
	bed.Name = "GravelBed"
	bed.Anchored = true
	bed.Material = Enum.Material.Slate
	bed.Color = TRACK_BED_COLOR

	if isXAligned then
		bed.Size = Vector3.new(length, bedHeight, bedWidth)
		bed.Position = Vector3.new(centerX, baseY + bedHeight / 2, centerZ)
	else
		bed.Size = Vector3.new(bedWidth, bedHeight, length)
		bed.Position = Vector3.new(centerX, baseY + bedHeight / 2, centerZ)
	end
	bed.Parent = model

	-- Rails (two parallel)
	for _, offset in { -trackGauge / 2, trackGauge / 2 } do
		local rail = Instance.new("Part")
		rail.Name = "Rail"
		rail.Anchored = true
		rail.Material = Enum.Material.Metal
		rail.Color = RAIL_COLOR

		if isXAligned then
			rail.Size = Vector3.new(length, railHeight, railWidth)
			rail.Position = Vector3.new(centerX, baseY + bedHeight + railHeight / 2, centerZ + offset)
		else
			rail.Size = Vector3.new(railWidth, railHeight, length)
			rail.Position = Vector3.new(centerX + offset, baseY + bedHeight + railHeight / 2, centerZ)
		end
		rail.Parent = model
	end

	-- Ties / sleepers (every 4 studs)
	local tieCount = math.floor(length / 4)
	for i = 0, tieCount - 1 do
		local tie = Instance.new("Part")
		tie.Name = `Tie_{i}`
		tie.Anchored = true
		tie.Material = Enum.Material.Wood
		tie.Color = Color3.fromRGB(70, 55, 40)

		local tieOffset = -length / 2 + 2 + i * 4

		if isXAligned then
			tie.Size = Vector3.new(1, 0.3, trackGauge + 2)
			tie.Position = Vector3.new(centerX + tieOffset, baseY + bedHeight / 2, centerZ)
		else
			tie.Size = Vector3.new(trackGauge + 2, 0.3, 1)
			tie.Position = Vector3.new(centerX, baseY + bedHeight / 2, centerZ + tieOffset)
		end
		tie.Parent = model
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Platform Edge
------------------------------------------------------------------------

--[[
	Creates a platform edge (raised concrete slab with yellow safety line).
	Runs along one side of a track area.
]]
function Shared.createPlatformEdge(
	startPos: Vector3,
	endPos: Vector3,
	parent: Instance,
	name: string?
): Model
	local model = Instance.new("Model")
	model.Name = name or "PlatformEdge"

	local dx = endPos.X - startPos.X
	local dz = endPos.Z - startPos.Z
	local centerX = (startPos.X + endPos.X) / 2
	local centerZ = (startPos.Z + endPos.Z) / 2
	local baseY = math.min(startPos.Y, endPos.Y)

	local isXAligned = math.abs(dx) >= math.abs(dz)
	local length = if isXAligned then math.abs(dx) else math.abs(dz)

	local edgeWidth = 2
	local edgeHeight = PLATFORM_HEIGHT

	-- Platform edge concrete slab
	local edge = Instance.new("Part")
	edge.Name = "PlatformEdgeSlab"
	edge.Anchored = true
	edge.Material = Enum.Material.Concrete
	edge.Color = TILE_FLOOR_COLOR

	if isXAligned then
		edge.Size = Vector3.new(length, edgeHeight, edgeWidth)
		edge.Position = Vector3.new(centerX, baseY + edgeHeight / 2, centerZ)
	else
		edge.Size = Vector3.new(edgeWidth, edgeHeight, length)
		edge.Position = Vector3.new(centerX, baseY + edgeHeight / 2, centerZ)
	end
	edge.Parent = model

	-- Yellow safety line on top
	local line = Instance.new("Part")
	line.Name = "SafetyLine"
	line.Anchored = true
	line.Material = Enum.Material.SmoothPlastic
	line.Color = PLATFORM_EDGE_COLOR

	if isXAligned then
		line.Size = Vector3.new(length, 0.05, 0.5)
		line.Position = Vector3.new(centerX, baseY + edgeHeight + 0.03, centerZ)
	else
		line.Size = Vector3.new(0.5, 0.05, length)
		line.Position = Vector3.new(centerX, baseY + edgeHeight + 0.03, centerZ)
	end
	line.Parent = model

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Tunnel Section
------------------------------------------------------------------------

--[[
	Creates a rectangular tunnel section (floor, ceiling, two walls).
	For the main rail tunnels. Does NOT include tracks (add separately).
]]
function Shared.createTunnelSection(
	startPos: Vector3,
	endPos: Vector3,
	width: number,
	height: number?,
	parent: Instance,
	name: string?
): Model
	local h = height or TUNNEL_HEIGHT
	return Shared.createCorridor(startPos, endPos, width, h, parent, name)
end

------------------------------------------------------------------------
-- Subway-Specific: Turnstile
------------------------------------------------------------------------

function Shared.createTurnstile(position: Vector3, rotation: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "Turnstile"

	-- Base unit
	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(3, 3.5, 1.5)
	base.CFrame = CFrame.new(position + Vector3.new(0, 1.75, 0)) * CFrame.Angles(0, math.rad(rotation), 0)
	base.Anchored = true
	base.Material = Enum.Material.Metal
	base.Color = METAL_COLOR
	base.Parent = model

	-- Arm bars (3 rotating arms)
	for i = 0, 2 do
		local arm = Instance.new("Part")
		arm.Name = `Arm_{i}`
		arm.Size = Vector3.new(0.15, 0.15, 2)
		arm.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
			* CFrame.Angles(0, math.rad(rotation), math.rad(i * 120))
			* CFrame.new(0, 0, -1)
		arm.Anchored = true
		arm.Material = Enum.Material.Metal
		arm.Color = Color3.fromRGB(180, 180, 175)
		arm.Parent = model
	end

	-- Card reader panel
	local reader = Instance.new("Part")
	reader.Name = "CardReader"
	reader.Size = Vector3.new(0.5, 0.8, 0.2)
	reader.CFrame = CFrame.new(position + Vector3.new(0, 3.2, 0.8))
		* CFrame.Angles(0, math.rad(rotation), 0)
	reader.Anchored = true
	reader.Material = Enum.Material.SmoothPlastic
	reader.Color = Color3.fromRGB(40, 40, 35)
	reader.Parent = model

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Ticket Machine
------------------------------------------------------------------------

function Shared.createTicketMachine(position: Vector3, rotation: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "TicketMachine"

	-- Main body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 6, 2)
	body.CFrame = CFrame.new(position + Vector3.new(0, 3, 0)) * CFrame.Angles(0, math.rad(rotation), 0)
	body.Anchored = true
	body.Material = Enum.Material.Metal
	body.Color = Color3.fromRGB(70, 70, 65)
	body.Parent = model

	-- Screen
	local screen = Instance.new("Part")
	screen.Name = "Screen"
	screen.Size = Vector3.new(2, 1.5, 0.1)
	screen.CFrame = CFrame.new(position + Vector3.new(0, 4.5, 1.05))
		* CFrame.Angles(0, math.rad(rotation), 0)
	screen.Anchored = true
	screen.Material = Enum.Material.Glass
	screen.Color = Color3.fromRGB(15, 20, 25)
	screen.Parent = model

	-- Coin slot
	local slot = Instance.new("Part")
	slot.Name = "CoinSlot"
	slot.Size = Vector3.new(0.3, 0.1, 0.2)
	slot.CFrame = CFrame.new(position + Vector3.new(0.8, 3.5, 1.05))
		* CFrame.Angles(0, math.rad(rotation), 0)
	slot.Anchored = true
	slot.Material = Enum.Material.Metal
	slot.Color = Color3.fromRGB(150, 150, 140)
	slot.Parent = model

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Vending Machine
------------------------------------------------------------------------

function Shared.createVendingMachine(position: Vector3, rotation: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "VendingMachine"

	-- Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3.5, 7, 2.5)
	body.CFrame = CFrame.new(position + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, math.rad(rotation), 0)
	body.Anchored = true
	body.Material = Enum.Material.Metal
	body.Color = Color3.fromRGB(45, 60, 80)
	body.Parent = model

	-- Glass front
	local glass = Instance.new("Part")
	glass.Name = "Glass"
	glass.Size = Vector3.new(2.8, 4, 0.1)
	glass.CFrame = CFrame.new(position + Vector3.new(0, 4.5, 1.3))
		* CFrame.Angles(0, math.rad(rotation), 0)
	glass.Anchored = true
	glass.Material = Enum.Material.Glass
	glass.Color = Color3.fromRGB(100, 120, 140)
	glass.Transparency = 0.4
	glass.Parent = model

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Bench (platform seating)
------------------------------------------------------------------------

function Shared.createBench(position: Vector3, rotation: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "Bench"

	-- Seat
	local seat = Instance.new("Part")
	seat.Name = "Seat"
	seat.Size = Vector3.new(6, 0.3, 1.8)
	seat.CFrame = CFrame.new(position + Vector3.new(0, 1.8, 0)) * CFrame.Angles(0, math.rad(rotation), 0)
	seat.Anchored = true
	seat.Material = Enum.Material.Metal
	seat.Color = METAL_COLOR
	seat.Parent = model

	-- Back rest
	local back = Instance.new("Part")
	back.Name = "BackRest"
	back.Size = Vector3.new(6, 1.5, 0.3)
	back.CFrame = CFrame.new(position + Vector3.new(0, 2.8, -0.75))
		* CFrame.Angles(0, math.rad(rotation), 0)
	back.Anchored = true
	back.Material = Enum.Material.Metal
	back.Color = METAL_COLOR
	back.Parent = model

	-- Legs (4)
	for _, offset in {
		Vector3.new(-2.5, 0.9, -0.5),
		Vector3.new(2.5, 0.9, -0.5),
		Vector3.new(-2.5, 0.9, 0.5),
		Vector3.new(2.5, 0.9, 0.5),
	} do
		local leg = Instance.new("Part")
		leg.Name = "Leg"
		leg.Size = Vector3.new(0.3, 1.8, 0.3)
		leg.CFrame = CFrame.new(position + offset) * CFrame.Angles(0, math.rad(rotation), 0)
		leg.Anchored = true
		leg.Material = Enum.Material.Metal
		leg.Color = DARK_METAL_COLOR
		leg.Parent = model
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Map Display (wall-mounted transit map)
------------------------------------------------------------------------

function Shared.createMapDisplay(position: Vector3, rotation: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "MapDisplay"

	-- Frame
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Size = Vector3.new(5, 3.5, 0.3)
	frame.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0)
	frame.Anchored = true
	frame.Material = Enum.Material.Metal
	frame.Color = Color3.fromRGB(50, 50, 45)
	frame.Parent = model

	-- Map surface
	local mapSurface = Instance.new("Part")
	mapSurface.Name = "MapSurface"
	mapSurface.Size = Vector3.new(4.5, 3, 0.05)
	mapSurface.CFrame = CFrame.new(position + Vector3.new(0, 0, 0.18))
		* CFrame.Angles(0, math.rad(rotation), 0)
	mapSurface.Anchored = true
	mapSurface.Material = Enum.Material.SmoothPlastic
	mapSurface.Color = Color3.fromRGB(220, 215, 200)
	mapSurface.Parent = model

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Rubble / Debris Cluster
------------------------------------------------------------------------

function Shared.createRubble(position: Vector3, spread: number, count: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "Rubble"

	for i = 1, count do
		local chunk = Instance.new("Part")
		chunk.Name = `Chunk_{i}`
		local sx = 1 + math.random() * 3
		local sy = 0.5 + math.random() * 2
		local sz = 1 + math.random() * 3
		chunk.Size = Vector3.new(sx, sy, sz)
		chunk.Position = position + Vector3.new(
			(math.random() - 0.5) * spread,
			sy / 2,
			(math.random() - 0.5) * spread
		)
		chunk.Orientation = Vector3.new(
			math.random(-15, 15),
			math.random(0, 360),
			math.random(-15, 15)
		)
		chunk.Anchored = true
		chunk.Material = Enum.Material.Concrete
		chunk.Color = RUBBLE_COLOR
		chunk.Parent = model
	end

	-- Occasional rebar sticking out
	for i = 1, math.max(1, math.floor(count / 4)) do
		local rebar = Instance.new("Part")
		rebar.Name = `Rebar_{i}`
		rebar.Size = Vector3.new(0.2, 2 + math.random() * 2, 0.2)
		rebar.Position = position + Vector3.new(
			(math.random() - 0.5) * spread * 0.6,
			1.5,
			(math.random() - 0.5) * spread * 0.6
		)
		rebar.Orientation = Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
		rebar.Anchored = true
		rebar.Material = Enum.Material.Metal
		rebar.Color = REBAR_COLOR
		rebar.Parent = model
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Train Car Shell (single car)
------------------------------------------------------------------------

--[[
	Creates a single subway train car as a Model.
	carLength: studs along the primary axis (default 30)
	carWidth: studs across (default 8)
	axis: "x" or "z" — which direction the car faces
	doorsOpen: which side doors are open { "left", "right" } or empty
	roofBreached: if true, a section of the roof is torn open
]]
function Shared.createTrainCar(
	position: Vector3,
	axis: string,
	parent: Instance,
	name: string?,
	doorsOpen: { string }?,
	roofBreached: boolean?
): Model
	local model = Instance.new("Model")
	model.Name = name or "TrainCar"

	local carLength = 30
	local carWidth = 8
	local carHeight = 8
	local wallThick = 0.4
	local floorThick = 0.4

	local isX = axis == "x"

	-- Helper: get size/position based on axis
	local function oriented(lenVal: number, widVal: number, hVal: number): Vector3
		if isX then
			return Vector3.new(lenVal, hVal, widVal)
		else
			return Vector3.new(widVal, hVal, lenVal)
		end
	end

	local function offsetAlong(dist: number): Vector3
		if isX then
			return Vector3.new(dist, 0, 0)
		else
			return Vector3.new(0, 0, dist)
		end
	end

	local function offsetAcross(dist: number): Vector3
		if isX then
			return Vector3.new(0, 0, dist)
		else
			return Vector3.new(dist, 0, 0)
		end
	end

	-- Floor
	local floor = Instance.new("Part")
	floor.Name = "CarFloor"
	floor.Size = oriented(carLength, carWidth, floorThick)
	floor.Position = position + Vector3.new(0, floorThick / 2, 0)
	floor.Anchored = true
	floor.Material = Enum.Material.DiamondPlate
	floor.Color = Color3.fromRGB(80, 80, 75)
	floor.Parent = model

	-- Emergency floor strip (dim light strip)
	local strip = Instance.new("Part")
	strip.Name = "FloorStrip"
	strip.Size = oriented(carLength - 2, 0.5, 0.05)
	strip.Position = position + Vector3.new(0, floorThick + 0.03, 0)
	strip.Anchored = true
	strip.Material = Enum.Material.Neon
	strip.Color = Color3.fromRGB(120, 150, 80)
	strip.Transparency = 0.5
	strip.Parent = model

	-- Roof (with optional breach)
	if roofBreached then
		-- Two halves of roof with a gap in the middle
		local halfLen = (carLength - 8) / 2
		for i, sign in { -1, 1 } do
			local roofPart = Instance.new("Part")
			roofPart.Name = `Roof_{i}`
			roofPart.Size = oriented(halfLen, carWidth, wallThick)
			roofPart.Position = position + Vector3.new(0, carHeight, 0) + offsetAlong(sign * (halfLen / 2 + 4))
			roofPart.Anchored = true
			roofPart.Material = Enum.Material.Metal
			roofPart.Color = TRAIN_EXTERIOR_COLOR
			roofPart.Parent = model
		end

		-- Torn edges around breach
		for i = 1, 4 do
			local torn = Instance.new("Part")
			torn.Name = `TornRoof_{i}`
			torn.Size = oriented(1.5, 1 + math.random() * 1.5, 0.2)
			torn.Position = position + Vector3.new(0, carHeight + 0.2, 0)
				+ offsetAlong((math.random() - 0.5) * 6)
				+ offsetAcross((math.random() - 0.5) * carWidth * 0.7)
			torn.Orientation = Vector3.new(math.random(-20, 20), math.random(0, 360), math.random(-20, 20))
			torn.Anchored = true
			torn.Material = Enum.Material.Metal
			torn.Color = Color3.fromRGB(140, 140, 135)
			torn.Parent = model
		end
	else
		local roof = Instance.new("Part")
		roof.Name = "Roof"
		roof.Size = oriented(carLength, carWidth, wallThick)
		roof.Position = position + Vector3.new(0, carHeight, 0)
		roof.Anchored = true
		roof.Material = Enum.Material.Metal
		roof.Color = TRAIN_EXTERIOR_COLOR
		roof.Parent = model
	end

	-- Side walls (with door cutouts simplified as separate panels)
	local openDoors = doorsOpen or {}
	local leftOpen = table.find(openDoors, "left") ~= nil
	local rightOpen = table.find(openDoors, "right") ~= nil

	for sideIndex, sideOffset in { -carWidth / 2, carWidth / 2 } do
		local sideName = if sideIndex == 1 then "Left" else "Right"
		local isOpen = if sideIndex == 1 then leftOpen else rightOpen

		if isOpen then
			-- Three wall segments with two door gaps
			local segmentLen = (carLength - 10) / 3 -- 3 segments, 2 doors of 5 each
			local doorWidth = 5
			local doorHeight = 6.5

			-- Segments
			local offsets = {
				-(carLength / 2) + segmentLen / 2,
				0,
				(carLength / 2) - segmentLen / 2,
			}
			for i, off in offsets do
				local wallPart = Instance.new("Part")
				wallPart.Name = `Wall_{sideName}_Seg{i}`
				wallPart.Size = oriented(segmentLen, wallThick, carHeight - floorThick)
				wallPart.Position = position + Vector3.new(0, floorThick + (carHeight - floorThick) / 2, 0)
					+ offsetAlong(off) + offsetAcross(sideOffset)
				wallPart.Anchored = true
				wallPart.Material = Enum.Material.Metal
				wallPart.Color = TRAIN_EXTERIOR_COLOR
				wallPart.Parent = model
			end

			-- Transom above each door
			local doorCenters = {
				-(carLength / 2) + segmentLen + doorWidth / 2,
				(carLength / 2) - segmentLen - doorWidth / 2,
			}
			for i, doorOff in doorCenters do
				local transom = Instance.new("Part")
				transom.Name = `Transom_{sideName}_{i}`
				local transomH = carHeight - floorThick - doorHeight
				transom.Size = oriented(doorWidth, wallThick, transomH)
				transom.Position = position + Vector3.new(0, floorThick + doorHeight + transomH / 2, 0)
					+ offsetAlong(doorOff) + offsetAcross(sideOffset)
				transom.Anchored = true
				transom.Material = Enum.Material.Metal
				transom.Color = TRAIN_EXTERIOR_COLOR
				transom.Parent = model
			end
		else
			-- Solid side wall
			local wallPart = Instance.new("Part")
			wallPart.Name = `Wall_{sideName}`
			wallPart.Size = oriented(carLength, wallThick, carHeight - floorThick)
			wallPart.Position = position + Vector3.new(0, floorThick + (carHeight - floorThick) / 2, 0)
				+ offsetAcross(sideOffset)
			wallPart.Anchored = true
			wallPart.Material = Enum.Material.Metal
			wallPart.Color = TRAIN_EXTERIOR_COLOR
			wallPart.Parent = model
		end

		-- Windows along the side (above door height)
		for i = 0, 4 do
			local window = Instance.new("Part")
			window.Name = `Window_{sideName}_{i}`
			window.Size = oriented(3, 0.1, 1.5)
			window.Position = position + Vector3.new(0, floorThick + 4.5, 0)
				+ offsetAlong(-carLength / 2 + 3 + i * 6)
				+ offsetAcross(sideOffset + (if sideIndex == 1 then -0.1 else 0.1))
			window.Anchored = true
			window.Material = Enum.Material.Glass
			window.Color = Color3.fromRGB(30, 40, 50)
			window.Transparency = 0.3
			window.Parent = model
		end
	end

	-- End walls
	for _, sign in { -1, 1 } do
		local endWall = Instance.new("Part")
		endWall.Name = if sign == -1 then "EndWall_Front" else "EndWall_Rear"
		endWall.Size = oriented(wallThick, carWidth - wallThick * 2, carHeight - floorThick)
		endWall.Position = position + Vector3.new(0, floorThick + (carHeight - floorThick) / 2, 0)
			+ offsetAlong(sign * carLength / 2)
		endWall.Anchored = true
		endWall.Material = Enum.Material.Metal
		endWall.Color = TRAIN_INTERIOR_COLOR
		endWall.Parent = model
	end

	-- Interior: seats (rows along both sides)
	for seatSide = -1, 1, 2 do
		for row = 0, 4 do
			local seat = Instance.new("Part")
			seat.Name = `Seat_{if seatSide == -1 then "L" else "R"}_{row}`
			seat.Size = oriented(4, 1.5, 1.5)
			seat.Position = position + Vector3.new(0, floorThick + 0.8, 0)
				+ offsetAlong(-carLength / 2 + 3 + row * 6)
				+ offsetAcross(seatSide * (carWidth / 2 - 1.5))
			seat.Anchored = true
			seat.Material = Enum.Material.Fabric
			seat.Color = SEAT_COLOR
			seat.Parent = model
		end
	end

	-- Grab poles (vertical)
	for i = 0, 3 do
		local pole = Instance.new("Part")
		pole.Name = `GrabPole_{i}`
		pole.Size = Vector3.new(0.2, carHeight - floorThick - 0.5, 0.2)
		pole.Position = position + Vector3.new(0, floorThick + (carHeight - floorThick) / 2, 0)
			+ offsetAlong(-carLength / 2 + 7.5 + i * 6)
		pole.Anchored = true
		pole.Material = Enum.Material.Metal
		pole.Color = Color3.fromRGB(180, 180, 175)
		pole.Parent = model

		-- Horizontal grab bar
		local bar = Instance.new("Part")
		bar.Name = `GrabBar_{i}`
		bar.Size = oriented(0.15, carWidth - 3, 0.15)
		bar.Position = position + Vector3.new(0, carHeight - 1, 0)
			+ offsetAlong(-carLength / 2 + 7.5 + i * 6)
		bar.Anchored = true
		bar.Material = Enum.Material.Metal
		bar.Color = Color3.fromRGB(180, 180, 175)
		bar.Parent = model
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Overhead Cable Infrastructure
------------------------------------------------------------------------

function Shared.createOverheadCables(
	startPos: Vector3,
	endPos: Vector3,
	parent: Instance,
	name: string?
): Model
	local model = Instance.new("Model")
	model.Name = name or "OverheadCables"

	local dx = endPos.X - startPos.X
	local dz = endPos.Z - startPos.Z
	local centerX = (startPos.X + endPos.X) / 2
	local centerZ = (startPos.Z + endPos.Z) / 2
	local cableY = math.min(startPos.Y, endPos.Y)

	local isXAligned = math.abs(dx) >= math.abs(dz)
	local length = if isXAligned then math.abs(dx) else math.abs(dz)

	-- Main cable
	local cable = Instance.new("Part")
	cable.Name = "MainCable"
	cable.Shape = Enum.PartType.Cylinder
	cable.Anchored = true
	cable.Material = Enum.Material.Metal
	cable.Color = Color3.fromRGB(50, 50, 45)

	if isXAligned then
		cable.Size = Vector3.new(length, 0.15, 0.15)
		cable.Position = Vector3.new(centerX, cableY, centerZ)
		cable.Orientation = Vector3.new(0, 0, 90)
	else
		cable.Size = Vector3.new(length, 0.15, 0.15)
		cable.Position = Vector3.new(centerX, cableY, centerZ)
		cable.Orientation = Vector3.new(90, 0, 0)
	end
	cable.Parent = model

	-- Suspension brackets every 20 studs
	local bracketCount = math.floor(length / 20)
	for i = 0, bracketCount do
		local bracket = Instance.new("Part")
		bracket.Name = `Bracket_{i}`
		bracket.Size = Vector3.new(0.3, 1.5, 0.3)
		bracket.Anchored = true
		bracket.Material = Enum.Material.Metal
		bracket.Color = DARK_METAL_COLOR

		local offset = -length / 2 + i * 20
		if isXAligned then
			bracket.Position = Vector3.new(centerX + offset, cableY + 0.75, centerZ)
		else
			bracket.Position = Vector3.new(centerX, cableY + 0.75, centerZ + offset)
		end
		bracket.Parent = model
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Webbing / Organic Material
------------------------------------------------------------------------

function Shared.createWebbing(position: Vector3, spread: number, density: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "Webbing"

	for i = 1, density do
		local strand = Instance.new("Part")
		strand.Name = `Strand_{i}`
		local sx = 0.1 + math.random() * 0.3
		local sy = 0.5 + math.random() * spread
		local sz = 0.1 + math.random() * 0.3
		strand.Size = Vector3.new(sx, sy, sz)
		strand.Position = position + Vector3.new(
			(math.random() - 0.5) * spread,
			(math.random() - 0.5) * spread * 0.5,
			(math.random() - 0.5) * spread
		)
		strand.Orientation = Vector3.new(
			math.random(-45, 45),
			math.random(0, 360),
			math.random(-45, 45)
		)
		strand.Anchored = true
		strand.Material = Enum.Material.Fabric
		strand.Color = WEBBING_COLOR
		strand.Transparency = 0.4
		strand.CanCollide = false
		strand.Parent = model
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Water Volume (for flooded sections)
------------------------------------------------------------------------

function Shared.createWaterVolume(position: Vector3, size: Vector3, parent: Instance, name: string?): Part
	local water = Instance.new("Part")
	water.Name = name or "WaterVolume"
	water.Size = size
	water.Position = position
	water.Anchored = true
	water.Material = Enum.Material.Glass
	water.Color = WATER_COLOR
	water.Transparency = 0.55
	water.CanCollide = false

	water:SetAttribute("IsWater", true)
	water:SetAttribute("WadingSoundRadius", 35)
	water:SetAttribute("CrouchWadeSoundRadius", 20)

	water.Parent = parent
	return water
end

------------------------------------------------------------------------
-- Subway-Specific: Escalator (dead / non-functional)
------------------------------------------------------------------------

function Shared.createDeadEscalator(
	bottomPos: Vector3,
	topPos: Vector3,
	width: number,
	parent: Instance,
	name: string?
): Model
	local model = Instance.new("Model")
	model.Name = name or "DeadEscalator"

	local rise = topPos.Y - bottomPos.Y
	local run = math.sqrt((topPos.X - bottomPos.X) ^ 2 + (topPos.Z - bottomPos.Z) ^ 2)
	local slopeLen = math.sqrt(rise ^ 2 + run ^ 2)
	local angle = math.atan2(rise, run)

	local centerX = (bottomPos.X + topPos.X) / 2
	local centerY = (bottomPos.Y + topPos.Y) / 2
	local centerZ = (bottomPos.Z + topPos.Z) / 2

	local dx = topPos.X - bottomPos.X
	local dz = topPos.Z - bottomPos.Z
	local yaw = math.atan2(dx, dz)

	-- Step surface (sloped slab)
	local surface = Instance.new("Part")
	surface.Name = "StepSurface"
	surface.Size = Vector3.new(width, 0.3, slopeLen)
	surface.CFrame = CFrame.new(Vector3.new(centerX, centerY, centerZ))
		* CFrame.Angles(0, yaw, 0)
		* CFrame.Angles(-angle, 0, 0)
	surface.Anchored = true
	surface.Material = Enum.Material.DiamondPlate
	surface.Color = METAL_COLOR
	surface.Parent = model

	-- Side walls / handrails
	for _, side in { -1, 1 } do
		local rail = Instance.new("Part")
		rail.Name = `Handrail_{if side == -1 then "L" else "R"}`
		rail.Size = Vector3.new(0.3, 3, slopeLen)
		rail.CFrame = CFrame.new(Vector3.new(
			centerX + side * (width / 2 + 0.15) * math.cos(yaw),
			centerY + 1.5,
			centerZ - side * (width / 2 + 0.15) * math.sin(yaw)
		)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(-angle, 0, 0)
		rail.Anchored = true
		rail.Material = Enum.Material.Metal
		rail.Color = DARK_METAL_COLOR
		rail.Parent = model
	end

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Maintenance Cart
------------------------------------------------------------------------

function Shared.createMaintenanceCart(position: Vector3, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "MaintenanceCart"

	-- Flatbed
	local bed = Instance.new("Part")
	bed.Name = "Flatbed"
	bed.Size = Vector3.new(4, 0.4, 6)
	bed.Position = position + Vector3.new(0, 1.2, 0)
	bed.Anchored = true
	bed.Material = Enum.Material.Metal
	bed.Color = METAL_COLOR
	bed.Parent = model

	-- Wheels (4)
	for _, offset in {
		Vector3.new(-1.5, 0.4, -2),
		Vector3.new(1.5, 0.4, -2),
		Vector3.new(-1.5, 0.4, 2),
		Vector3.new(1.5, 0.4, 2),
	} do
		local wheel = Instance.new("Part")
		wheel.Name = "Wheel"
		wheel.Shape = Enum.PartType.Cylinder
		wheel.Size = Vector3.new(0.4, 0.8, 0.8)
		wheel.Position = position + offset
		wheel.Orientation = Vector3.new(0, 0, 90)
		wheel.Anchored = true
		wheel.Material = Enum.Material.Metal
		wheel.Color = DARK_METAL_COLOR
		wheel.Parent = model
	end

	-- Tool box on cart
	local toolBox = Instance.new("Part")
	toolBox.Name = "ToolBox"
	toolBox.Size = Vector3.new(2, 1, 1.5)
	toolBox.Position = position + Vector3.new(-0.5, 1.9, -1.5)
	toolBox.Anchored = true
	toolBox.Material = Enum.Material.Metal
	toolBox.Color = Color3.fromRGB(140, 50, 40)
	toolBox.Parent = model

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Newspaper Dispenser
------------------------------------------------------------------------

function Shared.createNewspaperDispenser(position: Vector3, rotation: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "NewspaperDispenser"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2, 3.5, 1.5)
	body.CFrame = CFrame.new(position + Vector3.new(0, 1.75, 0)) * CFrame.Angles(0, math.rad(rotation), 0)
	body.Anchored = true
	body.Material = Enum.Material.Metal
	body.Color = Color3.fromRGB(50, 80, 50)
	body.Parent = model

	-- Window
	local window = Instance.new("Part")
	window.Name = "Window"
	window.Size = Vector3.new(1.5, 1.5, 0.1)
	window.CFrame = CFrame.new(position + Vector3.new(0, 2.5, 0.75))
		* CFrame.Angles(0, math.rad(rotation), 0)
	window.Anchored = true
	window.Material = Enum.Material.Glass
	window.Color = Color3.fromRGB(80, 100, 80)
	window.Transparency = 0.3
	window.Parent = model

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Construction Barricade
------------------------------------------------------------------------

function Shared.createBarricade(position: Vector3, size: Vector3, rotation: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "Barricade"

	-- Main barrier
	local barrier = Instance.new("Part")
	barrier.Name = "Barrier"
	barrier.Size = size
	barrier.CFrame = CFrame.new(position + Vector3.new(0, size.Y / 2, 0))
		* CFrame.Angles(0, math.rad(rotation), 0)
	barrier.Anchored = true
	barrier.Material = Enum.Material.Wood
	barrier.Color = Color3.fromRGB(200, 150, 50)
	barrier.Parent = model

	-- Danger stripes (decorative thin part)
	local stripe = Instance.new("Part")
	stripe.Name = "DangerStripe"
	stripe.Size = Vector3.new(size.X - 0.2, 0.3, 0.05)
	stripe.CFrame = CFrame.new(position + Vector3.new(0, size.Y * 0.7, size.Z / 2 + 0.03))
		* CFrame.Angles(0, math.rad(rotation), 0)
	stripe.Anchored = true
	stripe.Material = Enum.Material.SmoothPlastic
	stripe.Color = Color3.fromRGB(200, 40, 40)
	stripe.Parent = model

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Sealed Blackpoint Door
------------------------------------------------------------------------

function Shared.createSealedBlackpointDoor(position: Vector3, rotation: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "SealedBlackpointDoor"

	-- Heavy reinforced door
	local door = Instance.new("Part")
	door.Name = "ReinforcedDoor"
	door.Size = Vector3.new(6, 9, 1.5)
	door.CFrame = CFrame.new(position + Vector3.new(0, 4.5, 0))
		* CFrame.Angles(0, math.rad(rotation), 0)
	door.Anchored = true
	door.Material = Enum.Material.Metal
	door.Color = Color3.fromRGB(50, 50, 45)
	door.Parent = model

	-- Blackpoint logo (stylized circle with break)
	local logoRing = Instance.new("Part")
	logoRing.Name = "BlackpointLogo"
	logoRing.Shape = Enum.PartType.Cylinder
	logoRing.Size = Vector3.new(0.1, 2, 2)
	logoRing.CFrame = CFrame.new(position + Vector3.new(0, 6, 0.8))
		* CFrame.Angles(0, math.rad(rotation), math.rad(90))
	logoRing.Anchored = true
	logoRing.Material = Enum.Material.Metal
	logoRing.Color = Color3.fromRGB(20, 20, 20)
	logoRing.Parent = model

	-- Biometric scanner (non-functional)
	local scanner = Instance.new("Part")
	scanner.Name = "BiometricScanner"
	scanner.Size = Vector3.new(1, 1.5, 0.3)
	scanner.CFrame = CFrame.new(position + Vector3.new(3.5, 4.5, 0.8))
		* CFrame.Angles(0, math.rad(rotation), 0)
	scanner.Anchored = true
	scanner.Material = Enum.Material.SmoothPlastic
	scanner.Color = Color3.fromRGB(30, 30, 28)
	scanner.Parent = model

	-- Keycard reader
	local cardReader = Instance.new("Part")
	cardReader.Name = "KeycardReader"
	cardReader.Size = Vector3.new(0.6, 0.8, 0.2)
	cardReader.CFrame = CFrame.new(position + Vector3.new(3.5, 3, 0.8))
		* CFrame.Angles(0, math.rad(rotation), 0)
	cardReader.Anchored = true
	cardReader.Material = Enum.Material.SmoothPlastic
	cardReader.Color = Color3.fromRGB(40, 40, 38)
	cardReader.Parent = model

	-- Small reinforced window
	local window = Instance.new("Part")
	window.Name = "ReinforcedWindow"
	window.Size = Vector3.new(1.5, 1, 0.3)
	window.CFrame = CFrame.new(position + Vector3.new(0, 6.5, 0.8))
		* CFrame.Angles(0, math.rad(rotation), 0)
	window.Anchored = true
	window.Material = Enum.Material.Glass
	window.Color = Color3.fromRGB(20, 25, 30)
	window.Transparency = 0.2
	window.Parent = model

	-- Interaction prompt
	local promptPart = Instance.new("Part")
	promptPart.Name = "InteractionZone"
	promptPart.Size = Vector3.new(4, 6, 2)
	promptPart.CFrame = CFrame.new(position + Vector3.new(0, 3, 1.5))
		* CFrame.Angles(0, math.rad(rotation), 0)
	promptPart.Anchored = true
	promptPart.Transparency = 1
	promptPart.CanCollide = false
	promptPart.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Examine"
	prompt.ObjectText = "Blackpoint Coastal Research Facility"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.Parent = promptPart

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Electrical / Switching Panel
------------------------------------------------------------------------

function Shared.createSwitchingPanel(position: Vector3, rotation: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "SwitchingPanel"

	-- Panel body
	local body = Instance.new("Part")
	body.Name = "PanelBody"
	body.Size = Vector3.new(6, 7, 1)
	body.CFrame = CFrame.new(position + Vector3.new(0, 3.5, 0))
		* CFrame.Angles(0, math.rad(rotation), 0)
	body.Anchored = true
	body.Material = Enum.Material.Metal
	body.Color = Color3.fromRGB(60, 65, 60)
	body.Parent = model

	-- Breaker switches (3 rows of 4)
	for row = 0, 2 do
		for col = 0, 3 do
			local breaker = Instance.new("Part")
			breaker.Name = `Breaker_{row}_{col}`
			breaker.Size = Vector3.new(0.8, 0.3, 0.2)
			breaker.CFrame = CFrame.new(
				position + Vector3.new(-1.5 + col * 1.2, 2 + row * 1.5, 0.6)
			) * CFrame.Angles(0, math.rad(rotation), 0)
			breaker.Anchored = true
			breaker.Material = Enum.Material.Metal
			breaker.Color = Color3.fromRGB(30, 30, 28)
			breaker.Parent = model
		end
	end

	-- Labels (simplified as a face plate)
	local labelPlate = Instance.new("Part")
	labelPlate.Name = "LabelPlate"
	labelPlate.Size = Vector3.new(5, 5.5, 0.05)
	labelPlate.CFrame = CFrame.new(position + Vector3.new(0, 3.5, 0.55))
		* CFrame.Angles(0, math.rad(rotation), 0)
	labelPlate.Anchored = true
	labelPlate.Material = Enum.Material.SmoothPlastic
	labelPlate.Color = Color3.fromRGB(200, 195, 180)
	labelPlate.Parent = model

	model.Parent = parent
	return model
end

------------------------------------------------------------------------
-- Subway-Specific: Security Camera (dead)
------------------------------------------------------------------------

function Shared.createSecurityCamera(position: Vector3, rotation: number, parent: Instance, name: string?): Model
	local model = Instance.new("Model")
	model.Name = name or "SecurityCamera"

	-- Mount bracket
	local mount = Instance.new("Part")
	mount.Name = "Mount"
	mount.Size = Vector3.new(0.5, 0.5, 0.5)
	mount.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation), 0)
	mount.Anchored = true
	mount.Material = Enum.Material.Metal
	mount.Color = Color3.fromRGB(60, 60, 55)
	mount.Parent = model

	-- Camera body
	local camBody = Instance.new("Part")
	camBody.Name = "CameraBody"
	camBody.Size = Vector3.new(0.8, 0.6, 1.5)
	camBody.CFrame = CFrame.new(position + Vector3.new(0, -0.5, 0.5))
		* CFrame.Angles(0, math.rad(rotation), 0)
	camBody.Anchored = true
	camBody.Material = Enum.Material.Metal
	camBody.Color = Color3.fromRGB(40, 40, 38)
	camBody.Parent = model

	-- Lens
	local lens = Instance.new("Part")
	lens.Name = "Lens"
	lens.Shape = Enum.PartType.Cylinder
	lens.Size = Vector3.new(0.3, 0.4, 0.4)
	lens.CFrame = CFrame.new(position + Vector3.new(0, -0.5, 1.3))
		* CFrame.Angles(0, math.rad(rotation), math.rad(90))
	lens.Anchored = true
	lens.Material = Enum.Material.Glass
	lens.Color = Color3.fromRGB(20, 20, 30)
	lens.Parent = model

	model.Parent = parent
	return model
end

return Shared
