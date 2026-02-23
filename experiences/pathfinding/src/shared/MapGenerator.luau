-- MapGenerator.lua
-- Procedural abandoned mental asylum map generator
-- Generates a multi-floor asylum building with surrounding forest and rain
-- Place as a ModuleScript in ServerScriptService or ReplicatedStorage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoomTemplates = require(ReplicatedStorage.Shared.RoomTemplates)

local MapGenerator = {}

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local SLOT_SIZE: number = 24
local FLOOR_HEIGHT: number = 16
local WALL_THICKNESS: number = 1

------------------------------------------------------------------------
-- Direction system
------------------------------------------------------------------------

local DIRECTIONS: { [string]: { x: number, z: number } } = {
	north = { x = 0, z = -1 },
	south = { x = 0, z = 1 },
	east = { x = 1, z = 0 },
	west = { x = -1, z = 0 },
}

local OPPOSITE: { [string]: string } = {
	north = "south",
	south = "north",
	east = "west",
	west = "east",
}

------------------------------------------------------------------------
-- Grid helpers
------------------------------------------------------------------------

--- Create a 2D grid of given width and depth, initialized to false
--- Uses false (not nil) so that #row correctly reports the grid depth.
--- @param width number
--- @param depth number
--- @return { { any } }
local function createGrid(width: number, depth: number): { { any } }
	local grid = {}
	for x = 1, width do
		grid[x] = table.create(depth, false)
	end
	return grid
end

--- Check whether (x, z) is within grid bounds
--- @param grid { { any } }
--- @param x number
--- @param z number
--- @return boolean
local function inBounds(grid: { { any } }, x: number, z: number): boolean
	return x >= 1 and x <= #grid and z >= 1 and z <= #grid[1]
end

--- Check whether a grid cell is empty (false)
--- @param grid { { any } }
--- @param x number
--- @param z number
--- @return boolean
local function isEmpty(grid: { { any } }, x: number, z: number): boolean
	return inBounds(grid, x, z) and grid[x][z] == false
end

--- Convert grid coordinates and floor index to world position (center of cell)
--- @param gridX number
--- @param gridZ number
--- @param floorIndex number
--- @return Vector3
local function gridToWorld(gridX: number, gridZ: number, floorIndex: number): Vector3
	local wx = (gridX - 1) * SLOT_SIZE + SLOT_SIZE / 2
	local wy = (floorIndex - 1) * FLOOR_HEIGHT
	local wz = (gridZ - 1) * SLOT_SIZE + SLOT_SIZE / 2
	return Vector3.new(wx, wy, wz)
end

--- Get cardinal neighbors of a grid cell
--- @param x number
--- @param z number
--- @return { { x: number, z: number, dir: string } }
local function getNeighbors(x: number, z: number): { { x: number, z: number, dir: string } }
	local result = {}
	for dir, delta in DIRECTIONS do
		table.insert(result, { x = x + delta.x, z = z + delta.z, dir = dir })
	end
	return result
end

------------------------------------------------------------------------
-- Module state
------------------------------------------------------------------------

local mapData: any = nil
local generatedParts: Folder? = nil

------------------------------------------------------------------------
-- Shuffle helper (Fisher-Yates)
------------------------------------------------------------------------

local function shuffle(tbl: { any }, rng: Random)
	for i = #tbl, 2, -1 do
		local j = rng:NextInteger(1, i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

------------------------------------------------------------------------
-- Generation: Room Placement Helper
------------------------------------------------------------------------

--- Place a room on the grid, creating a room record and marking cells
--- @param floor any -- floor data table
--- @param grid { { any? } }
--- @param roomType string
--- @param cells { { x: number, z: number } }
--- @return any -- the created room record
local function placeRoomOnGrid(
	floor: any,
	grid: { { any? } },
	roomType: string,
	cells: { { x: number, z: number } }
): any
	local roomId = #floor.rooms + 1
	local room = {
		id = roomId,
		type = roomType,
		cells = cells,
		doors = {},
		condition = "normal",
	}
	table.insert(floor.rooms, room)
	for _, cell in cells do
		grid[cell.x][cell.z] = {
			roomId = roomId,
			roomType = roomType,
			doors = {},
		}
	end
	return room
end

------------------------------------------------------------------------
-- Generation: Stairwell Placement
------------------------------------------------------------------------

--- Place a 1x1 stairwell at the given grid position
--- @param floor any
--- @param grid { { any? } }
--- @param sx number
--- @param sz number
local function placeStairwell(floor: any, grid: { { any? } }, sx: number, sz: number)
	placeRoomOnGrid(floor, grid, "Stairwell", { { x = sx, z = sz } })
end

------------------------------------------------------------------------
-- Generation: Lobby Placement
------------------------------------------------------------------------

--- Place a 2x2 lobby near the south edge of floor 1
--- @param floor any
--- @param grid { { any? } }
--- @param gridWidth number
--- @param gridDepth number
--- @param rng Random
local function placeLobby(floor: any, grid: { { any? } }, gridWidth: number, gridDepth: number, rng: Random)
	local z = gridDepth - 1
	-- Try random X positions
	local attempts = {}
	for x = 1, gridWidth - 1 do
		table.insert(attempts, x)
	end
	shuffle(attempts, rng)

	for _, x in attempts do
		-- Check all 4 cells of the 2x2 lobby
		local cells = {
			{ x = x, z = z },
			{ x = x + 1, z = z },
			{ x = x, z = z + 1 },
			{ x = x + 1, z = z + 1 },
		}
		local canPlace = true
		for _, cell in cells do
			if not isEmpty(grid, cell.x, cell.z) then
				canPlace = false
				break
			end
		end
		if canPlace then
			placeRoomOnGrid(floor, grid, "Lobby", cells)
			return
		end
	end
end

------------------------------------------------------------------------
-- Generation: Hallway Growing
------------------------------------------------------------------------

--- Grow hallway branches from the stairwell
--- @param floor any
--- @param grid { { any? } }
--- @param startX number -- stairwell X
--- @param startZ number -- stairwell Z
--- @param rng Random
--- @param gridWidth number
--- @param gridDepth number
--- @return { { x: number, z: number } }
local function growHallways(
	floor: any,
	grid: { { any? } },
	startX: number,
	startZ: number,
	rng: Random,
	gridWidth: number,
	gridDepth: number
): { { x: number, z: number } }
	local hallwayCells = {}
	local dirNames = { "north", "south", "east", "west" }

	for _, dirName in dirNames do
		local delta = DIRECTIONS[dirName]
		local seedX = startX + delta.x
		local seedZ = startZ + delta.z

		if not inBounds(grid, seedX, seedZ) or not isEmpty(grid, seedX, seedZ) then
			continue
		end

		-- Grow a branch from this seed
		local maxLen = math.max(gridWidth, gridDepth) - 2
		local branchLen = rng:NextInteger(3, math.max(3, maxLen))
		local curX = seedX
		local curZ = seedZ
		local curDir = dirName

		for _ = 1, branchLen do
			-- Stay 1 cell from grid edges to leave room for rooms on sides
			if curX <= 1 or curX >= gridWidth or curZ <= 1 or curZ >= gridDepth then
				break
			end

			if not isEmpty(grid, curX, curZ) then
				break
			end

			-- Place hallway cell
			placeRoomOnGrid(floor, grid, "Hallway", { { x = curX, z = curZ } })
			table.insert(hallwayCells, { x = curX, z = curZ })

			-- Decide next direction: 70% straight, 30% turn
			local roll = rng:NextNumber()
			if roll > 0.7 then
				-- Turn perpendicular
				local perpDirs
				if curDir == "north" or curDir == "south" then
					perpDirs = { "east", "west" }
				else
					perpDirs = { "north", "south" }
				end
				curDir = perpDirs[rng:NextInteger(1, 2)]
			end

			local nextDelta = DIRECTIONS[curDir]
			curX = curX + nextDelta.x
			curZ = curZ + nextDelta.z
		end
	end

	return hallwayCells
end

------------------------------------------------------------------------
-- Generation: Room Filling
------------------------------------------------------------------------

--- Fill empty grid cells with random room templates
--- @param floor any
--- @param grid { { any? } }
--- @param rng Random
--- @param gridWidth number
--- @param gridDepth number
local function fillRooms(floor: any, grid: { { any? } }, rng: Random, gridWidth: number, gridDepth: number)
	-- First pass: fill empty cells adjacent to hallways/lobby
	local candidates = {}
	for x = 1, gridWidth do
		for z = 1, gridDepth do
			if not isEmpty(grid, x, z) then
				continue
			end
			-- Check if adjacent to a hallway or lobby
			local adjToHallwayOrLobby = false
			for _, neighbor in getNeighbors(x, z) do
				if inBounds(grid, neighbor.x, neighbor.z) and grid[neighbor.x][neighbor.z] ~= false then
					local cellData = grid[neighbor.x][neighbor.z]
					if cellData.roomType == "Hallway" or cellData.roomType == "Lobby" then
						adjToHallwayOrLobby = true
						break
					end
				end
			end
			if adjToHallwayOrLobby then
				table.insert(candidates, { x = x, z = z })
			end
		end
	end

	shuffle(candidates, rng)

	for _, cand in candidates do
		if not isEmpty(grid, cand.x, cand.z) then
			continue -- may have been claimed by a multi-slot room
		end

		local template = RoomTemplates.pickRandom(rng)
		local placed = false

		-- Try multi-slot rooms
		if template.gridSize.x > 1 or template.gridSize.z > 1 then
			local sizeX = template.gridSize.x
			local sizeZ = template.gridSize.z
			local cells = {}
			local canFit = true

			for dx = 0, sizeX - 1 do
				for dz = 0, sizeZ - 1 do
					local cx = cand.x + dx
					local cz = cand.z + dz
					if not isEmpty(grid, cx, cz) then
						canFit = false
						break
					end
					table.insert(cells, { x = cx, z = cz })
				end
				if not canFit then
					break
				end
			end

			if canFit then
				placeRoomOnGrid(floor, grid, template.type, cells)
				placed = true
			end
		end

		-- Fallback to 1x1 room
		if not placed then
			if template.gridSize.x == 1 and template.gridSize.z == 1 then
				placeRoomOnGrid(floor, grid, template.type, { { x = cand.x, z = cand.z } })
			else
				-- Pick a 1x1 fallback
				local fallback = RoomTemplates.pickRandom(rng)
				local tries = 0
				while (fallback.gridSize.x > 1 or fallback.gridSize.z > 1) and tries < 20 do
					fallback = RoomTemplates.pickRandom(rng)
					tries += 1
				end
				if fallback.gridSize.x == 1 and fallback.gridSize.z == 1 then
					placeRoomOnGrid(floor, grid, fallback.type, { { x = cand.x, z = cand.z } })
				else
					-- Ultimate fallback: PatientRoom
					placeRoomOnGrid(floor, grid, "PatientRoom", { { x = cand.x, z = cand.z } })
				end
			end
		end
	end

	-- Second pass: fill remaining empty cells adjacent to ANY placed room
	local changed = true
	while changed do
		changed = false
		for x = 1, gridWidth do
			for z = 1, gridDepth do
				if not isEmpty(grid, x, z) then
					continue
				end
				local adjToRoom = false
				for _, neighbor in getNeighbors(x, z) do
					if inBounds(grid, neighbor.x, neighbor.z) and grid[neighbor.x][neighbor.z] ~= false then
						adjToRoom = true
						break
					end
				end
				if adjToRoom then
					local template = RoomTemplates.pickRandom(rng)
					-- Only place 1x1 rooms in second pass
					local tries = 0
					while (template.gridSize.x > 1 or template.gridSize.z > 1) and tries < 20 do
						template = RoomTemplates.pickRandom(rng)
						tries += 1
					end
					if template.gridSize.x == 1 and template.gridSize.z == 1 then
						placeRoomOnGrid(floor, grid, template.type, { { x = x, z = z } })
					else
						placeRoomOnGrid(floor, grid, "PatientRoom", { { x = x, z = z } })
					end
					changed = true
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- Generation: Door Carving
------------------------------------------------------------------------

--- Carve doors between adjacent rooms
--- @param floor any
--- @param grid { { any? } }
--- @param gridWidth number
--- @param gridDepth number
--- @param rng Random
local function carveDoors(floor: any, grid: { { any? } }, gridWidth: number, gridDepth: number, rng: Random)
	-- Check east and south neighbors to avoid duplicate checks
	for x = 1, gridWidth do
		for z = 1, gridDepth do
			local cellA = grid[x][z]
			if cellA == false then
				continue
			end

			-- Check east neighbor
			if x + 1 <= gridWidth and grid[x + 1][z] ~= false then
				local cellB = grid[x + 1][z]
				if cellA.roomId ~= cellB.roomId then
					-- Navigation-critical connections always get doors
					local isNav = cellA.roomType == "Hallway"
						or cellA.roomType == "Stairwell"
						or cellA.roomType == "Lobby"
						or cellB.roomType == "Hallway"
						or cellB.roomType == "Stairwell"
						or cellB.roomType == "Lobby"
					if isNav or rng:NextNumber() <= 0.35 then
						-- Check if both templates allow doors on these edges
						local templateA = RoomTemplates.templates[cellA.roomType]
						local templateB = RoomTemplates.templates[cellB.roomType]
						local aAllows = table.find(templateA.doorPositions, "east") ~= nil
						local bAllows = table.find(templateB.doorPositions, "west") ~= nil
						if aAllows and bAllows then
							-- Record door on both cells
							table.insert(cellA.doors, { dir = "east", neighborRoomId = cellB.roomId })
							table.insert(cellB.doors, { dir = "west", neighborRoomId = cellA.roomId })
							-- Record on room objects
							local roomA = floor.rooms[cellA.roomId]
							local roomB = floor.rooms[cellB.roomId]
							table.insert(
								roomA.doors,
								{ dir = "east", fromCell = { x = x, z = z }, toRoomId = cellB.roomId }
							)
							table.insert(
								roomB.doors,
								{ dir = "west", fromCell = { x = x + 1, z = z }, toRoomId = cellA.roomId }
							)
						end
					end
				end
			end

			-- Check south neighbor
			if z + 1 <= gridDepth and grid[x][z + 1] ~= false then
				local cellB = grid[x][z + 1]
				if cellA.roomId ~= cellB.roomId then
					-- Navigation-critical connections always get doors
					local isNav = cellA.roomType == "Hallway"
						or cellA.roomType == "Stairwell"
						or cellA.roomType == "Lobby"
						or cellB.roomType == "Hallway"
						or cellB.roomType == "Stairwell"
						or cellB.roomType == "Lobby"
					if isNav or rng:NextNumber() <= 0.35 then
						local templateA = RoomTemplates.templates[cellA.roomType]
						local templateB = RoomTemplates.templates[cellB.roomType]
						local aAllows = table.find(templateA.doorPositions, "south") ~= nil
						local bAllows = table.find(templateB.doorPositions, "north") ~= nil
						if aAllows and bAllows then
							table.insert(cellA.doors, { dir = "south", neighborRoomId = cellB.roomId })
							table.insert(cellB.doors, { dir = "north", neighborRoomId = cellA.roomId })
							local roomA = floor.rooms[cellA.roomId]
							local roomB = floor.rooms[cellB.roomId]
							table.insert(
								roomA.doors,
								{ dir = "south", fromCell = { x = x, z = z }, toRoomId = cellB.roomId }
							)
							table.insert(
								roomB.doors,
								{ dir = "north", fromCell = { x = x, z = z + 1 }, toRoomId = cellA.roomId }
							)
						end
					end
				end
			end
		end
	end

	-- Guarantee: every room gets at least 1 door
	for _, room in floor.rooms do
		if #room.doors == 0 then
			-- Force-connect to any adjacent room
			local connected = false
			for _, cell in room.cells do
				if connected then
					break
				end
				for _, neighbor in getNeighbors(cell.x, cell.z) do
					if inBounds(grid, neighbor.x, neighbor.z) and grid[neighbor.x][neighbor.z] ~= false then
						local neighborCell = grid[neighbor.x][neighbor.z]
						if neighborCell.roomId ~= room.id then
							local dir = neighbor.dir
							local oppDir = OPPOSITE[dir]
							-- Add door on both sides
							table.insert(
								grid[cell.x][cell.z].doors,
								{ dir = dir, neighborRoomId = neighborCell.roomId }
							)
							table.insert(neighborCell.doors, { dir = oppDir, neighborRoomId = room.id })
							table.insert(
								room.doors,
								{ dir = dir, fromCell = { x = cell.x, z = cell.z }, toRoomId = neighborCell.roomId }
							)
							local neighborRoom = floor.rooms[neighborCell.roomId]
							table.insert(
								neighborRoom.doors,
								{ dir = oppDir, fromCell = { x = neighbor.x, z = neighbor.z }, toRoomId = room.id }
							)
							connected = true
							break
						end
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- Generation: Solvability
------------------------------------------------------------------------

--- Ensure all rooms are reachable from the stairwell via doors
--- @param floor any
--- @param grid { { any? } }
--- @param startX number -- stairwell X
--- @param startZ number -- stairwell Z
--- @param gridWidth number
--- @param gridDepth number
local function ensureSolvability(
	floor: any,
	grid: { { any? } },
	startX: number,
	startZ: number,
	_gridWidth: number,
	_gridDepth: number
)
	-- Build room adjacency graph from doors
	local adjacency: { [number]: { [number]: boolean } } = {}
	for _, room in floor.rooms do
		adjacency[room.id] = {}
		for _, door in room.doors do
			adjacency[room.id][door.toRoomId] = true
		end
	end

	-- Find stairwell room id
	local stairwellCell = grid[startX][startZ]
	if stairwellCell == false then
		return
	end
	local startRoomId = stairwellCell.roomId

	-- Flood fill from stairwell room
	local visited: { [number]: boolean } = {}
	local queue = { startRoomId }
	visited[startRoomId] = true

	while #queue > 0 do
		local currentId = table.remove(queue, 1)
		if adjacency[currentId] then
			for neighborId, _ in adjacency[currentId] do
				if not visited[neighborId] then
					visited[neighborId] = true
					table.insert(queue, neighborId)
				end
			end
		end
	end

	-- Any unreachable room: force a door to the nearest reachable neighbor
	-- Repeat until all rooms are connected (handles island clusters)
	local changed = true
	while changed do
		changed = false
		for _, room in floor.rooms do
			if visited[room.id] then
				continue
			end

			-- Find nearest reachable neighbor room by checking adjacent cells
			local connected = false
			for _, cell in room.cells do
				if connected then
					break
				end
				for _, neighbor in getNeighbors(cell.x, cell.z) do
					if connected then
						break
					end
					if inBounds(grid, neighbor.x, neighbor.z) and grid[neighbor.x][neighbor.z] ~= false then
						local neighborCell = grid[neighbor.x][neighbor.z]
						if visited[neighborCell.roomId] then
							-- Force a door
							local dir = neighbor.dir
							local oppDir = OPPOSITE[dir]
							table.insert(
								grid[cell.x][cell.z].doors,
								{ dir = dir, neighborRoomId = neighborCell.roomId }
							)
							table.insert(neighborCell.doors, { dir = oppDir, neighborRoomId = room.id })
							table.insert(
								room.doors,
								{ dir = dir, fromCell = { x = cell.x, z = cell.z }, toRoomId = neighborCell.roomId }
							)
							local neighborRoom = floor.rooms[neighborCell.roomId]
							table.insert(
								neighborRoom.doors,
								{ dir = oppDir, fromCell = { x = neighbor.x, z = neighbor.z }, toRoomId = room.id }
							)

							-- Update adjacency
							if not adjacency[room.id] then
								adjacency[room.id] = {}
							end
							adjacency[room.id][neighborCell.roomId] = true
							if not adjacency[neighborCell.roomId] then
								adjacency[neighborCell.roomId] = {}
							end
							adjacency[neighborCell.roomId][room.id] = true

							-- Mark this room and flood fill from it
							visited[room.id] = true
							local subQueue = { room.id }
							while #subQueue > 0 do
								local curId = table.remove(subQueue, 1)
								if adjacency[curId] then
									for nId, _ in adjacency[curId] do
										if not visited[nId] then
											visited[nId] = true
											table.insert(subQueue, nId)
										end
									end
								end
							end

							connected = true
							changed = true
						end
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- Generation: Conditions
------------------------------------------------------------------------

--- Apply condition overlays to rooms based on floor level
--- @param floor any
--- @param rng Random
--- @param floorIndex number
local function applyConditions(floor: any, rng: Random, floorIndex: number)
	local conditionChance = math.min(0.5, 0.15 + (floorIndex - 1) * 0.15)

	for _, room in floor.rooms do
		-- Skip Stairwell, Lobby, Hallway
		if room.type == "Stairwell" or room.type == "Lobby" or room.type == "Hallway" then
			continue
		end

		if rng:NextNumber() > conditionChance then
			continue
		end

		local template = RoomTemplates.templates[room.type]
		if template == nil then
			continue
		end

		-- Pick a random non-"normal" condition from template's conditions list
		local nonNormalConditions = {}
		for _, cond in template.conditions do
			if cond ~= "normal" then
				table.insert(nonNormalConditions, cond)
			end
		end

		if #nonNormalConditions > 0 then
			room.condition = nonNormalConditions[rng:NextInteger(1, #nonNormalConditions)]
		end
	end
end

------------------------------------------------------------------------
-- Generation: Furniture
------------------------------------------------------------------------

--- Place furniture in rooms based on their template slots
--- @param floor any
--- @param rng Random
local function placeFurniture(floor: any, rng: Random)
	for _, room in floor.rooms do
		local template = RoomTemplates.templates[room.type]
		if template == nil or template.furnitureSlots == nil or #template.furnitureSlots == 0 then
			continue
		end

		room.furniture = {}
		for _, slot in template.furnitureSlots do
			-- 60% chance to place each furniture item
			if rng:NextNumber() <= 0.6 then
				local knocked = rng:NextNumber() <= 0.3
				table.insert(room.furniture, {
					name = slot.name,
					x = slot.x,
					z = slot.z,
					knocked = knocked,
				})
			end
		end
	end
end

------------------------------------------------------------------------
-- Physical Part Building
------------------------------------------------------------------------

--- Create an anchored Part with given properties
--- @param parent Instance
--- @param name string
--- @param size Vector3
--- @param position Vector3
--- @param material Enum.Material
--- @param color Color3
--- @return Part
local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	position: Vector3,
	material: Enum.Material,
	color: Color3
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Material = material
	part.Color = color
	part.Parent = parent
	return part
end

--- Build a full wall on one edge of a grid cell
--- @param parent Instance
--- @param gridX number
--- @param gridZ number
--- @param floorIndex number
--- @param dir string
--- @param material Enum.Material
--- @param color Color3
local function buildWall(
	parent: Instance,
	gridX: number,
	gridZ: number,
	floorIndex: number,
	dir: string,
	material: Enum.Material,
	color: Color3,
	inset: number?
)
	local offset = inset or 0
	local worldPos = gridToWorld(gridX, gridZ, floorIndex)
	local floorY = worldPos.Y
	local wallCenterY = floorY + FLOOR_HEIGHT / 2

	local size: Vector3
	local position: Vector3

	if dir == "north" then
		size = Vector3.new(SLOT_SIZE, FLOOR_HEIGHT, WALL_THICKNESS)
		position = Vector3.new(worldPos.X, wallCenterY, worldPos.Z - SLOT_SIZE / 2 + offset)
	elseif dir == "south" then
		size = Vector3.new(SLOT_SIZE, FLOOR_HEIGHT, WALL_THICKNESS)
		position = Vector3.new(worldPos.X, wallCenterY, worldPos.Z + SLOT_SIZE / 2 - offset)
	elseif dir == "east" then
		size = Vector3.new(WALL_THICKNESS, FLOOR_HEIGHT, SLOT_SIZE)
		position = Vector3.new(worldPos.X + SLOT_SIZE / 2 - offset, wallCenterY, worldPos.Z)
	elseif dir == "west" then
		size = Vector3.new(WALL_THICKNESS, FLOOR_HEIGHT, SLOT_SIZE)
		position = Vector3.new(worldPos.X - SLOT_SIZE / 2 + offset, wallCenterY, worldPos.Z)
	end

	makePart(parent, "Wall_" .. dir, size, position, material, color)
end

--- Build a wall with a door opening (6 stud wide, 10 stud tall)
--- @param parent Instance
--- @param gridX number
--- @param gridZ number
--- @param floorIndex number
--- @param dir string
--- @param material Enum.Material
--- @param color Color3
local function buildDoorFrame(
	parent: Instance,
	gridX: number,
	gridZ: number,
	floorIndex: number,
	dir: string,
	material: Enum.Material,
	color: Color3,
	inset: number?
)
	local offset = inset or 0
	local worldPos = gridToWorld(gridX, gridZ, floorIndex)
	local floorY = worldPos.Y
	local doorWidth = 6
	local doorHeight = 10

	if dir == "north" or dir == "south" then
		local wallZ
		if dir == "north" then
			wallZ = worldPos.Z - SLOT_SIZE / 2 + offset
		else
			wallZ = worldPos.Z + SLOT_SIZE / 2 - offset
		end

		-- Left wall segment
		local leftWidth = (SLOT_SIZE - doorWidth) / 2
		makePart(
			parent,
			"DoorFrame_" .. dir .. "_Left",
			Vector3.new(leftWidth, FLOOR_HEIGHT, WALL_THICKNESS),
			Vector3.new(worldPos.X - SLOT_SIZE / 2 + leftWidth / 2, floorY + FLOOR_HEIGHT / 2, wallZ),
			material,
			color
		)

		-- Right wall segment
		local rightWidth = (SLOT_SIZE - doorWidth) / 2
		makePart(
			parent,
			"DoorFrame_" .. dir .. "_Right",
			Vector3.new(rightWidth, FLOOR_HEIGHT, WALL_THICKNESS),
			Vector3.new(worldPos.X + SLOT_SIZE / 2 - rightWidth / 2, floorY + FLOOR_HEIGHT / 2, wallZ),
			material,
			color
		)

		-- Lintel above door
		local lintelHeight = FLOOR_HEIGHT - doorHeight
		makePart(
			parent,
			"DoorFrame_" .. dir .. "_Lintel",
			Vector3.new(doorWidth, lintelHeight, WALL_THICKNESS),
			Vector3.new(worldPos.X, floorY + doorHeight + lintelHeight / 2, wallZ),
			material,
			color
		)

		-- Door frame trim (wooden jambs + header) — non-collidable decoration
		local trimThick = 0.3
		local trimDepth = WALL_THICKNESS + 0.4
		local trimColor = Color3.fromRGB(80, 60, 40)
		local jambBottom = floorY + 0.1
		local jambTop = floorY + doorHeight - trimThick
		local jambHeight = jambTop - jambBottom
		local jambCenterY = (jambBottom + jambTop) / 2
		-- Left jamb
		local lj = makePart(
			parent,
			"DoorTrim_" .. dir .. "_LJamb",
			Vector3.new(trimThick, jambHeight, trimDepth),
			Vector3.new(worldPos.X - doorWidth / 2, jambCenterY, wallZ),
			Enum.Material.WoodPlanks,
			trimColor
		)
		lj.CanCollide = false
		-- Right jamb
		local rj = makePart(
			parent,
			"DoorTrim_" .. dir .. "_RJamb",
			Vector3.new(trimThick, jambHeight, trimDepth),
			Vector3.new(worldPos.X + doorWidth / 2, jambCenterY, wallZ),
			Enum.Material.WoodPlanks,
			trimColor
		)
		rj.CanCollide = false
		-- Header (inside the opening, below the lintel)
		local hdr = makePart(
			parent,
			"DoorTrim_" .. dir .. "_Header",
			Vector3.new(doorWidth + trimThick * 2, trimThick, trimDepth),
			Vector3.new(worldPos.X, floorY + doorHeight - trimThick / 2, wallZ),
			Enum.Material.WoodPlanks,
			trimColor
		)
		hdr.CanCollide = false
		-- Metal threshold at floor level
		local thr = makePart(
			parent,
			"DoorTrim_" .. dir .. "_Threshold",
			Vector3.new(doorWidth + trimThick * 2, 0.3, trimDepth),
			Vector3.new(worldPos.X, floorY + 0.15, wallZ),
			Enum.Material.Metal,
			Color3.fromRGB(120, 120, 125)
		)
		thr.CanCollide = false
	elseif dir == "east" or dir == "west" then
		local wallX
		if dir == "east" then
			wallX = worldPos.X + SLOT_SIZE / 2 - offset
		else
			wallX = worldPos.X - SLOT_SIZE / 2 + offset
		end

		-- Left (north side) wall segment
		local segmentLength = (SLOT_SIZE - doorWidth) / 2
		makePart(
			parent,
			"DoorFrame_" .. dir .. "_Left",
			Vector3.new(WALL_THICKNESS, FLOOR_HEIGHT, segmentLength),
			Vector3.new(wallX, floorY + FLOOR_HEIGHT / 2, worldPos.Z - SLOT_SIZE / 2 + segmentLength / 2),
			material,
			color
		)

		-- Right (south side) wall segment
		makePart(
			parent,
			"DoorFrame_" .. dir .. "_Right",
			Vector3.new(WALL_THICKNESS, FLOOR_HEIGHT, segmentLength),
			Vector3.new(wallX, floorY + FLOOR_HEIGHT / 2, worldPos.Z + SLOT_SIZE / 2 - segmentLength / 2),
			material,
			color
		)

		-- Lintel above door
		local lintelHeight = FLOOR_HEIGHT - doorHeight
		makePart(
			parent,
			"DoorFrame_" .. dir .. "_Lintel",
			Vector3.new(WALL_THICKNESS, lintelHeight, doorWidth),
			Vector3.new(wallX, floorY + doorHeight + lintelHeight / 2, worldPos.Z),
			material,
			color
		)

		-- Door frame trim (wooden jambs + header) — non-collidable decoration
		local trimThick = 0.3
		local trimDepth = WALL_THICKNESS + 0.4
		local trimColor = Color3.fromRGB(80, 60, 40)
		local jambBottom = floorY + 0.1
		local jambTop = floorY + doorHeight - trimThick
		local jambHeight = jambTop - jambBottom
		local jambCenterY = (jambBottom + jambTop) / 2
		-- Left jamb (north side)
		local lj = makePart(
			parent,
			"DoorTrim_" .. dir .. "_LJamb",
			Vector3.new(trimDepth, jambHeight, trimThick),
			Vector3.new(wallX, jambCenterY, worldPos.Z - doorWidth / 2),
			Enum.Material.WoodPlanks,
			trimColor
		)
		lj.CanCollide = false
		-- Right jamb (south side)
		local rj = makePart(
			parent,
			"DoorTrim_" .. dir .. "_RJamb",
			Vector3.new(trimDepth, jambHeight, trimThick),
			Vector3.new(wallX, jambCenterY, worldPos.Z + doorWidth / 2),
			Enum.Material.WoodPlanks,
			trimColor
		)
		rj.CanCollide = false
		-- Header (inside the opening, below the lintel)
		local hdr = makePart(
			parent,
			"DoorTrim_" .. dir .. "_Header",
			Vector3.new(trimDepth, trimThick, doorWidth + trimThick * 2),
			Vector3.new(wallX, floorY + doorHeight - trimThick / 2, worldPos.Z),
			Enum.Material.WoodPlanks,
			trimColor
		)
		hdr.CanCollide = false
		-- Metal threshold at floor level
		local thr = makePart(
			parent,
			"DoorTrim_" .. dir .. "_Threshold",
			Vector3.new(trimDepth, 0.3, doorWidth + trimThick * 2),
			Vector3.new(wallX, floorY + 0.15, worldPos.Z),
			Enum.Material.Metal,
			Color3.fromRGB(120, 120, 125)
		)
		thr.CanCollide = false
	end
end

--- Get wall and floor colors for a room type and condition
--- @param roomType string
--- @param condition string
--- @return Color3, Color3 -- wallColor, floorColor
local function getRoomColor(roomType: string, condition: string): (Color3, Color3)
	local wallColor: Color3
	local floorColor: Color3

	if roomType == "Hallway" then
		wallColor = Color3.fromRGB(180, 175, 165)
		floorColor = Color3.fromRGB(140, 135, 125)
	elseif roomType == "Lobby" then
		wallColor = Color3.fromRGB(170, 165, 155)
		floorColor = Color3.fromRGB(160, 150, 130)
	elseif roomType == "Stairwell" then
		wallColor = Color3.fromRGB(160, 155, 150)
		floorColor = Color3.fromRGB(130, 125, 120)
	elseif roomType == "PatientRoom" then
		wallColor = Color3.fromRGB(190, 185, 175)
		floorColor = Color3.fromRGB(155, 150, 140)
	elseif roomType == "PaddedCell" then
		wallColor = Color3.fromRGB(200, 195, 180)
		floorColor = Color3.fromRGB(170, 165, 150)
	elseif roomType == "OperatingRoom" then
		wallColor = Color3.fromRGB(200, 210, 200)
		floorColor = Color3.fromRGB(170, 180, 170)
	elseif roomType == "Bathroom" then
		wallColor = Color3.fromRGB(195, 200, 195)
		floorColor = Color3.fromRGB(165, 170, 165)
	elseif roomType == "Office" then
		wallColor = Color3.fromRGB(175, 165, 145)
		floorColor = Color3.fromRGB(120, 95, 65)
	elseif roomType == "StorageRoom" then
		wallColor = Color3.fromRGB(155, 150, 140)
		floorColor = Color3.fromRGB(130, 125, 115)
	else
		wallColor = Color3.fromRGB(175, 170, 160)
		floorColor = Color3.fromRGB(135, 130, 120)
	end

	-- Condition overrides
	if condition == "flooded" then
		floorColor = Color3.fromRGB(80, 90, 100)
	elseif condition == "collapsed" then
		wallColor = Color3.fromRGB(120, 115, 105)
		floorColor = Color3.fromRGB(100, 95, 85)
	elseif condition == "boarded" then
		wallColor = Color3.fromRGB(140, 120, 90)
	end

	return wallColor, floorColor
end

--- Build a simple furniture part
--- @param parent Instance
--- @param furnitureData any
--- @param roomWorldPos Vector3
--- @param floorY number
local function buildFurniturePart(parent: Instance, furnitureData: any, roomWorldPos: Vector3, floorY: number)
	local furnitureSize = Vector3.new(3, 3, 3)
	local furnitureColor = Color3.fromRGB(100, 80, 60)
	local furnitureMaterial = Enum.Material.WoodPlanks

	-- Adjust size/color based on furniture name
	local name = furnitureData.name
	if string.find(name, "bed") then
		furnitureSize = Vector3.new(5, 2, 8)
	elseif string.find(name, "desk") or string.find(name, "table") then
		furnitureSize = Vector3.new(6, 3, 4)
	elseif string.find(name, "chair") then
		furnitureSize = Vector3.new(2, 3, 2)
	elseif string.find(name, "cabinet") or string.find(name, "shelf") then
		furnitureSize = Vector3.new(4, 5, 2)
	elseif string.find(name, "bench") then
		furnitureSize = Vector3.new(6, 2, 2)
	elseif string.find(name, "crate") then
		furnitureSize = Vector3.new(3, 3, 3)
		furnitureMaterial = Enum.Material.WoodPlanks
	elseif string.find(name, "sink") or string.find(name, "toilet") then
		furnitureSize = Vector3.new(2, 3, 2)
		furnitureColor = Color3.fromRGB(200, 200, 195)
		furnitureMaterial = Enum.Material.SmoothPlastic
	elseif string.find(name, "tray") then
		furnitureSize = Vector3.new(2, 3, 1)
		furnitureMaterial = Enum.Material.Metal
		furnitureColor = Color3.fromRGB(160, 160, 165)
	elseif string.find(name, "light") then
		furnitureSize = Vector3.new(2, 1, 2)
		furnitureMaterial = Enum.Material.Metal
		furnitureColor = Color3.fromRGB(180, 180, 185)
	elseif string.find(name, "reception") then
		furnitureSize = Vector3.new(8, 3, 4)
	end

	-- Position relative to room origin (bottom-left corner of first cell)
	local originX = roomWorldPos.X - SLOT_SIZE / 2
	local originZ = roomWorldPos.Z - SLOT_SIZE / 2
	local posX = originX + furnitureData.x
	local posZ = originZ + furnitureData.z
	local posY = floorY + furnitureSize.Y / 2

	local part = makePart(
		parent,
		"Furniture_" .. name,
		furnitureSize,
		Vector3.new(posX, posY, posZ),
		furnitureMaterial,
		furnitureColor
	)

	-- Knocked over: rotate on X axis
	if furnitureData.knocked then
		part.Orientation = Vector3.new(90, 0, 0)
		part.Position = Vector3.new(posX, floorY + furnitureSize.Z / 2, posZ)
	end
end

--- Build all physical parts for one floor
--- @param parent Instance
--- @param floor any
--- @param grid { { any? } }
--- @param floorIndex number
--- @param gridWidth number
--- @param gridDepth number
local function buildFloorParts(
	parent: Instance,
	floor: any,
	grid: { { any? } },
	floorIndex: number,
	gridWidth: number,
	gridDepth: number
)
	-- Track which rooms have had furniture built (use first cell)
	local furnitureBuilt: { [number]: boolean } = {}

	for x = 1, gridWidth do
		for z = 1, gridDepth do
			local cellData = grid[x][z]
			if cellData == false then
				continue
			end

			local room = floor.rooms[cellData.roomId]
			local template = RoomTemplates.templates[cellData.roomType]
			if template == nil then
				continue
			end

			local condition = room.condition or "normal"
			local wallColor, floorColor = getRoomColor(cellData.roomType, condition)

			-- Compute inset floor/ceiling bounds: trim edges where there's an
			-- interior wall (different-room neighbor in bounds) so the slab fits
			-- snugly inside the double-sided walls.  Grid-boundary edges and
			-- same-room edges stay at full SLOT_SIZE.
			local worldPos = gridToWorld(x, z, floorIndex)
			local halfSlot = SLOT_SIZE / 2
			local wallOffset = WALL_THICKNESS / 2
			local xMin = worldPos.X - halfSlot
			local xMax = worldPos.X + halfSlot
			local zMin = worldPos.Z - halfSlot
			local zMax = worldPos.Z + halfSlot

			for dir, delta in DIRECTIONS do
				local nx = x + delta.x
				local nz = z + delta.z
				-- Only inset if neighbor is in-bounds AND belongs to a different room
				-- AND there is NO door on this edge (floors extend through doorways)
				local hasInteriorWall = inBounds(grid, nx, nz)
					and (grid[nx][nz] == false or grid[nx][nz].roomId ~= cellData.roomId)
				local hasDoorOnEdge = false
				for _, door in cellData.doors do
					if door.dir == dir then
						hasDoorOnEdge = true
						break
					end
				end
				-- On upper floors, inset even at door edges (wooden plank fills gap)
				if hasInteriorWall and (not hasDoorOnEdge or floorIndex > 1) then
					if dir == "west" then
						xMin = xMin + wallOffset
					elseif dir == "east" then
						xMax = xMax - wallOffset
					elseif dir == "north" then
						zMin = zMin + wallOffset
					elseif dir == "south" then
						zMax = zMax - wallOffset
					end
				end
			end

			local slabSizeX = xMax - xMin
			local slabSizeZ = zMax - zMin
			local slabCenterX = (xMin + xMax) / 2
			local slabCenterZ = (zMin + zMax) / 2
			local floorThickness = 0.2
			local floorY = worldPos.Y - floorThickness / 2

			-- Build floor slab (thin, top surface flush with worldPos.Y)
			-- Skip stairwell on floors above 1 so the shaft stays open
			if cellData.roomType ~= "Stairwell" or floorIndex == 1 then
				local floorPart = makePart(
					parent,
					"Floor",
					Vector3.new(slabSizeX, floorThickness, slabSizeZ),
					Vector3.new(slabCenterX, floorY, slabCenterZ),
					template.floorMaterial,
					floorColor
				)
				floorPart:SetAttribute("RoomType", cellData.roomType)
			end

			-- On upper floors, fill the doorway floor gap with a wooden plank
			if floorIndex > 1 then
				local doorWidth = 6
				local woodColor = Color3.fromRGB(90, 65, 45)
				for _, door in cellData.doors do
					local d = door.dir
					local plank
					if d == "north" then
						plank = makePart(
							parent,
							"DoorPlank_north",
							Vector3.new(doorWidth, floorThickness, wallOffset),
							Vector3.new(worldPos.X, floorY, worldPos.Z - halfSlot + wallOffset / 2),
							Enum.Material.WoodPlanks,
							woodColor
						)
					elseif d == "south" then
						plank = makePart(
							parent,
							"DoorPlank_south",
							Vector3.new(doorWidth, floorThickness, wallOffset),
							Vector3.new(worldPos.X, floorY, worldPos.Z + halfSlot - wallOffset / 2),
							Enum.Material.WoodPlanks,
							woodColor
						)
					elseif d == "east" then
						plank = makePart(
							parent,
							"DoorPlank_east",
							Vector3.new(wallOffset, floorThickness, doorWidth),
							Vector3.new(worldPos.X + halfSlot - wallOffset / 2, floorY, worldPos.Z),
							Enum.Material.WoodPlanks,
							woodColor
						)
					elseif d == "west" then
						plank = makePart(
							parent,
							"DoorPlank_west",
							Vector3.new(wallOffset, floorThickness, doorWidth),
							Vector3.new(worldPos.X - halfSlot + wallOffset / 2, floorY, worldPos.Z),
							Enum.Material.WoodPlanks,
							woodColor
						)
					end
					if plank then
						plank.CanCollide = false
					end
				end
			end

			-- Thin ceiling slab matching the room's floor color, positioned
			-- well below the floor slab of the level above.
			-- Skip stairwells so the shaft stays open.
			if cellData.roomType ~= "Stairwell" then
				local ceilingThickness = 0.1
				local ceilingTopY = worldPos.Y + FLOOR_HEIGHT - 0.5 -- clear of floor above
				local ceilingCenterY = ceilingTopY - ceilingThickness / 2
				makePart(
					parent,
					"Ceiling",
					Vector3.new(SLOT_SIZE, ceilingThickness, SLOT_SIZE),
					Vector3.new(worldPos.X, ceilingCenterY, worldPos.Z),
					template.floorMaterial,
					floorColor
				)
			end

			-- Build walls for each direction
			for dir, delta in DIRECTIONS do
				local nx = x + delta.x
				local nz = z + delta.z

				-- Check if there's a door on this edge
				local hasDoor = false
				for _, door in cellData.doors do
					if door.dir == dir then
						hasDoor = true
						break
					end
				end

				-- Check if neighbor is same room (no wall needed)
				local sameRoom = false
				if inBounds(grid, nx, nz) and grid[nx][nz] ~= false then
					if grid[nx][nz].roomId == cellData.roomId then
						sameRoom = true
					end
				end

				if sameRoom then
					-- No wall between cells of same room
					continue
				end

				-- Skip walls at grid boundary (exterior shell handles perimeter)
				if not inBounds(grid, nx, nz) then
					continue
				end

				-- Each room builds its own wall on its interior side, offset inward
				-- so adjacent rooms each see their own color/material
				local wallInset = WALL_THICKNESS / 2

				if hasDoor then
					buildDoorFrame(parent, x, z, floorIndex, dir, template.wallMaterial, wallColor, wallInset)
				else
					buildWall(parent, x, z, floorIndex, dir, template.wallMaterial, wallColor, wallInset)
				end
			end

			-- Build furniture for first cell of each room
			if not furnitureBuilt[cellData.roomId] and room.furniture and #room.furniture > 0 then
				furnitureBuilt[cellData.roomId] = true
				for _, furnitureItem in room.furniture do
					buildFurniturePart(parent, furnitureItem, worldPos, worldPos.Y)
				end
			end
		end
	end
end

--- Build a staircase connecting one floor to the next
--- @param parent Instance
--- @param gridX number
--- @param gridZ number
--- @param floorIndex number
local function buildStaircase(parent: Instance, gridX: number, gridZ: number, floorIndex: number)
	local worldPos = gridToWorld(gridX, gridZ, floorIndex)
	local baseY = worldPos.Y
	local stairColor = Color3.fromRGB(140, 135, 130)
	local stepCount = 8
	local stepHeight = FLOOR_HEIGHT / stepCount
	local stepDepth = (SLOT_SIZE - 4) / stepCount -- stair length along Z
	local stepWidth = SLOT_SIZE - 4

	for i = 0, stepCount - 1 do
		local stepY = baseY + (i + 0.5) * stepHeight
		local stepZ = worldPos.Z - (SLOT_SIZE - 4) / 2 + (i + 0.5) * stepDepth
		makePart(
			parent,
			"Stair_" .. tostring(i + 1),
			Vector3.new(stepWidth, stepHeight, stepDepth),
			Vector3.new(worldPos.X, stepY, stepZ),
			Enum.Material.Concrete,
			stairColor
		)
	end
end

------------------------------------------------------------------------
-- Exterior
------------------------------------------------------------------------

--- Build an exterior wall segment with optional window for one grid cell width
local function buildExteriorSegment(
	parent: Instance,
	centerAlongWall: number,
	wallPerpPos: number,
	floorIndex: number,
	hasWindow: boolean,
	isNorthSouth: boolean,
	color: Color3
)
	local floorY = (floorIndex - 1) * FLOOR_HEIGHT
	local wallCenterY = floorY + FLOOR_HEIGHT / 2

	if not hasWindow then
		-- Solid segment
		local size, pos
		if isNorthSouth then
			size = Vector3.new(SLOT_SIZE, FLOOR_HEIGHT, WALL_THICKNESS)
			pos = Vector3.new(centerAlongWall, wallCenterY, wallPerpPos)
		else
			size = Vector3.new(WALL_THICKNESS, FLOOR_HEIGHT, SLOT_SIZE)
			pos = Vector3.new(wallPerpPos, wallCenterY, centerAlongWall)
		end
		makePart(parent, "ExteriorWall", size, pos, Enum.Material.Concrete, color)
		return
	end

	-- Window dimensions
	local winWidth = 5
	local winHeight = 6
	local sillHeight = 4
	local sideWidth = (SLOT_SIZE - winWidth) / 2
	local headerHeight = FLOOR_HEIGHT - sillHeight - winHeight

	-- Sill (below window, full cell width)
	if isNorthSouth then
		makePart(
			parent,
			"ExteriorWall_Sill",
			Vector3.new(SLOT_SIZE, sillHeight, WALL_THICKNESS),
			Vector3.new(centerAlongWall, floorY + sillHeight / 2, wallPerpPos),
			Enum.Material.Concrete,
			color
		)
	else
		makePart(
			parent,
			"ExteriorWall_Sill",
			Vector3.new(WALL_THICKNESS, sillHeight, SLOT_SIZE),
			Vector3.new(wallPerpPos, floorY + sillHeight / 2, centerAlongWall),
			Enum.Material.Concrete,
			color
		)
	end

	-- Left side of window
	if isNorthSouth then
		makePart(
			parent,
			"ExteriorWall_WinL",
			Vector3.new(sideWidth, winHeight, WALL_THICKNESS),
			Vector3.new(
				centerAlongWall - SLOT_SIZE / 2 + sideWidth / 2,
				floorY + sillHeight + winHeight / 2,
				wallPerpPos
			),
			Enum.Material.Concrete,
			color
		)
	else
		makePart(
			parent,
			"ExteriorWall_WinL",
			Vector3.new(WALL_THICKNESS, winHeight, sideWidth),
			Vector3.new(
				wallPerpPos,
				floorY + sillHeight + winHeight / 2,
				centerAlongWall - SLOT_SIZE / 2 + sideWidth / 2
			),
			Enum.Material.Concrete,
			color
		)
	end

	-- Right side of window
	if isNorthSouth then
		makePart(
			parent,
			"ExteriorWall_WinR",
			Vector3.new(sideWidth, winHeight, WALL_THICKNESS),
			Vector3.new(
				centerAlongWall + SLOT_SIZE / 2 - sideWidth / 2,
				floorY + sillHeight + winHeight / 2,
				wallPerpPos
			),
			Enum.Material.Concrete,
			color
		)
	else
		makePart(
			parent,
			"ExteriorWall_WinR",
			Vector3.new(WALL_THICKNESS, winHeight, sideWidth),
			Vector3.new(
				wallPerpPos,
				floorY + sillHeight + winHeight / 2,
				centerAlongWall + SLOT_SIZE / 2 - sideWidth / 2
			),
			Enum.Material.Concrete,
			color
		)
	end

	-- Header (above window)
	if headerHeight > 0 then
		if isNorthSouth then
			makePart(
				parent,
				"ExteriorWall_Header",
				Vector3.new(SLOT_SIZE, headerHeight, WALL_THICKNESS),
				Vector3.new(centerAlongWall, floorY + sillHeight + winHeight + headerHeight / 2, wallPerpPos),
				Enum.Material.Concrete,
				color
			)
		else
			makePart(
				parent,
				"ExteriorWall_Header",
				Vector3.new(WALL_THICKNESS, headerHeight, SLOT_SIZE),
				Vector3.new(wallPerpPos, floorY + sillHeight + winHeight + headerHeight / 2, centerAlongWall),
				Enum.Material.Concrete,
				color
			)
		end
	end

	-- Glass pane in window opening
	local glassColor = Color3.fromRGB(180, 200, 220)
	local glass: Part
	if isNorthSouth then
		glass = makePart(
			parent,
			"WindowGlass",
			Vector3.new(winWidth, winHeight, WALL_THICKNESS * 0.3),
			Vector3.new(centerAlongWall, floorY + sillHeight + winHeight / 2, wallPerpPos),
			Enum.Material.Glass,
			glassColor
		)
	else
		glass = makePart(
			parent,
			"WindowGlass",
			Vector3.new(WALL_THICKNESS * 0.3, winHeight, winWidth),
			Vector3.new(wallPerpPos, floorY + sillHeight + winHeight / 2, centerAlongWall),
			Enum.Material.Glass,
			glassColor
		)
	end
	glass.Transparency = 0.6
end

--- Build exterior walls, roof, and ground around the building
--- @param parent Instance
--- @param gridWidth number
--- @param gridDepth number
--- @param floorCount number
--- @param rng Random
local function buildExterior(parent: Instance, gridWidth: number, gridDepth: number, floorCount: number, _rng: Random)
	local extColor = Color3.fromRGB(140, 130, 120)
	local buildingWidth = gridWidth * SLOT_SIZE
	local buildingDepth = gridDepth * SLOT_SIZE
	local buildingHeight = floorCount * FLOOR_HEIGHT
	local centerX = buildingWidth / 2
	local centerZ = buildingDepth / 2

	-- North, East, West walls with windows
	for floorIndex = 1, floorCount do
		for cellIdx = 1, gridWidth do
			local centerX_cell = (cellIdx - 1) * SLOT_SIZE + SLOT_SIZE / 2
			local hasWindow = (cellIdx % 2 == 0) -- windows on even cells
			buildExteriorSegment(parent, centerX_cell, 0, floorIndex, hasWindow, true, extColor) -- North
		end
		for cellIdx = 1, gridDepth do
			local centerZ_cell = (cellIdx - 1) * SLOT_SIZE + SLOT_SIZE / 2
			local hasWindow = (cellIdx % 2 == 0)
			buildExteriorSegment(parent, centerZ_cell, buildingWidth, floorIndex, hasWindow, false, extColor) -- East
			buildExteriorSegment(parent, centerZ_cell, 0, floorIndex, hasWindow, false, extColor) -- West
		end
	end

	-- South wall with entrance and windows
	local entranceWidth = 8
	local entranceHeight = 12
	local entranceCenterCell = math.ceil(gridWidth / 2) -- which cell the entrance is in

	for floorIndex = 1, floorCount do
		for cellIdx = 1, gridWidth do
			local centerX_cell = (cellIdx - 1) * SLOT_SIZE + SLOT_SIZE / 2
			local floorY = (floorIndex - 1) * FLOOR_HEIGHT

			if cellIdx == entranceCenterCell and floorIndex == 1 then
				-- Build entrance opening (same as before but for one cell width)
				local leftWidth = (SLOT_SIZE - entranceWidth) / 2
				-- Left segment
				makePart(
					parent,
					"ExteriorWall_South_Left",
					Vector3.new(leftWidth, FLOOR_HEIGHT, WALL_THICKNESS),
					Vector3.new(centerX_cell - SLOT_SIZE / 2 + leftWidth / 2, floorY + FLOOR_HEIGHT / 2, buildingDepth),
					Enum.Material.Concrete,
					extColor
				)
				-- Right segment
				makePart(
					parent,
					"ExteriorWall_South_Right",
					Vector3.new(leftWidth, FLOOR_HEIGHT, WALL_THICKNESS),
					Vector3.new(centerX_cell + SLOT_SIZE / 2 - leftWidth / 2, floorY + FLOOR_HEIGHT / 2, buildingDepth),
					Enum.Material.Concrete,
					extColor
				)
				-- Lintel
				local lintelH = FLOOR_HEIGHT - entranceHeight
				if lintelH > 0 then
					makePart(
						parent,
						"ExteriorWall_South_Lintel",
						Vector3.new(entranceWidth, lintelH, WALL_THICKNESS),
						Vector3.new(centerX_cell, floorY + entranceHeight + lintelH / 2, buildingDepth),
						Enum.Material.Concrete,
						extColor
					)
				end
			else
				local hasWindow = (cellIdx % 2 == 0)
				buildExteriorSegment(parent, centerX_cell, buildingDepth, floorIndex, hasWindow, true, extColor)
			end
		end
	end

	-- Roof slab
	makePart(
		parent,
		"Roof",
		Vector3.new(buildingWidth, 1, buildingDepth),
		Vector3.new(centerX, buildingHeight + 0.5, centerZ),
		Enum.Material.Concrete,
		extColor
	)
end

------------------------------------------------------------------------
-- Forest
------------------------------------------------------------------------

--- Build a forest of trees around the building
--- @param parent Instance
--- @param gridWidth number
--- @param gridDepth number
--- @param rng Random
local function buildForest(parent: Instance, gridWidth: number, gridDepth: number, rng: Random)
	local forestRadius = 200
	local buildingWidth = gridWidth * SLOT_SIZE
	local buildingDepth = gridDepth * SLOT_SIZE
	local centerX = buildingWidth / 2
	local centerZ = buildingDepth / 2

	local groundSize = 2 * forestRadius + math.max(buildingWidth, buildingDepth)

	-- Green grass ground plane
	makePart(
		parent,
		"ForestGround",
		Vector3.new(groundSize, 1, groundSize),
		Vector3.new(centerX, -1, centerZ),
		Enum.Material.Grass,
		Color3.fromRGB(60, 100, 40)
	)

	-- Tree placement by rejection sampling
	local trees: { { x: number, z: number } } = {}
	local minSpacing = 12
	local buildingMargin = 10
	local maxAttempts = 1500

	for _ = 1, maxAttempts do
		local tx = centerX + rng:NextNumber() * (groundSize - 20) - (groundSize - 20) / 2
		local tz = centerZ + rng:NextNumber() * (groundSize - 20) - (groundSize - 20) / 2

		-- Skip if inside or near building
		if
			tx > -buildingMargin
			and tx < buildingWidth + buildingMargin
			and tz > -buildingMargin
			and tz < buildingDepth + buildingMargin
		then
			continue
		end

		-- Check minimum spacing from other trees
		local tooClose = false
		for _, existingTree in trees do
			local dx = tx - existingTree.x
			local dz = tz - existingTree.z
			if math.sqrt(dx * dx + dz * dz) < minSpacing then
				tooClose = true
				break
			end
		end

		if tooClose then
			continue
		end

		table.insert(trees, { x = tx, z = tz })

		-- Build tree
		local trunkHeight = rng:NextNumber() * 8 + 8 -- 8 to 16
		local trunkRadius = rng:NextNumber() * 0.5 + 1.0 -- 1.0 to 1.5
		local canopySize = rng:NextNumber() * 6 + 8 -- 8 to 14

		-- Trunk (cylinder oriented vertically via rotation)
		local trunk = makePart(
			parent,
			"TreeTrunk",
			Vector3.new(trunkHeight, trunkRadius * 2, trunkRadius * 2),
			Vector3.new(tx, trunkHeight / 2, tz),
			Enum.Material.WoodPlanks,
			Color3.fromRGB(rng:NextInteger(80, 110), rng:NextInteger(55, 75), rng:NextInteger(30, 50))
		)
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Orientation = Vector3.new(0, 0, 90)

		-- Canopy (ball)
		local canopy = makePart(
			parent,
			"TreeCanopy",
			Vector3.new(canopySize, canopySize, canopySize),
			Vector3.new(tx, trunkHeight + canopySize / 3, tz),
			Enum.Material.Grass,
			Color3.fromRGB(rng:NextInteger(30, 70), rng:NextInteger(90, 140), rng:NextInteger(25, 55))
		)
		canopy.Shape = Enum.PartType.Ball
		canopy.CanCollide = false
	end
end

------------------------------------------------------------------------
-- Rain
------------------------------------------------------------------------

--- Create a rain emitter part with standard rain settings
--- @param parent Instance
--- @param name string
--- @param size Vector3
--- @param position Vector3
local function makeRainStrip(parent: Instance, name: string, size: Vector3, position: Vector3)
	local rainPart = Instance.new("Part")
	rainPart.Name = name
	rainPart.Size = size
	rainPart.Position = position
	rainPart.Anchored = true
	rainPart.Transparency = 1
	rainPart.CanCollide = false
	rainPart.Parent = parent

	-- Scale rate to surface area relative to a 500x500 reference
	local area = size.X * size.Z
	local rate = math.clamp(math.floor(area / (500 * 500) * 3000), 50, 3000)

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Rain"
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(2, 4)
	emitter.Speed = NumberRange.new(50, 65)
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.SpreadAngle = Vector2.new(1, 1)
	emitter.Color = ColorSequence.new(Color3.fromRGB(180, 190, 200))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 0.08),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	emitter.Parent = rainPart
end

--- Build rain emitters around (but not over) the building
--- @param parent Instance
--- @param gridWidth number
--- @param gridDepth number
local function buildRain(parent: Instance, gridWidth: number, gridDepth: number)
	local buildingWidth = gridWidth * SLOT_SIZE
	local buildingDepth = gridDepth * SLOT_SIZE
	local centerX = buildingWidth / 2
	local centerZ = buildingDepth / 2
	local margin = 200 -- how far rain extends beyond building
	local gap = 10 -- keep rain strips away from building edges
	local rainY = 80

	-- North strip (behind building, gap away from wall)
	local nDepth = margin - gap
	makeRainStrip(
		parent,
		"RainNorth",
		Vector3.new(buildingWidth + margin * 2, 1, nDepth),
		Vector3.new(centerX, rainY, -gap - nDepth / 2)
	)

	-- South strip (in front of building, gap away from wall)
	local sDepth = margin - gap
	makeRainStrip(
		parent,
		"RainSouth",
		Vector3.new(buildingWidth + margin * 2, 1, sDepth),
		Vector3.new(centerX, rainY, buildingDepth + gap + sDepth / 2)
	)

	-- West strip (left of building, gap away from wall)
	local wWidth = margin - gap
	makeRainStrip(
		parent,
		"RainWest",
		Vector3.new(wWidth, 1, buildingDepth),
		Vector3.new(-gap - wWidth / 2, rainY, centerZ)
	)

	-- East strip (right of building, gap away from wall)
	local eWidth = margin - gap
	makeRainStrip(
		parent,
		"RainEast",
		Vector3.new(eWidth, 1, buildingDepth),
		Vector3.new(buildingWidth + gap + eWidth / 2, rainY, centerZ)
	)
end

------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------

--- Generate a procedural asylum map
--- @param config { floors: number?, gridWidth: number?, gridDepth: number?, seed: number? }?
--- @return any -- mapData table
function MapGenerator.generate(config: { floors: number?, gridWidth: number?, gridDepth: number?, seed: number? }?): any
	config = config or {}
	local floorCount = config.floors or 2
	local gridWidth = math.max(5, config.gridWidth or 8)
	local gridDepth = math.max(5, config.gridDepth or 6)
	local seed = config.seed or os.time()

	-- Cleanup previous generation
	MapGenerator.cleanup()

	-- Init RNG
	local rng = Random.new(seed)

	-- Create output folder
	generatedParts = Instance.new("Folder")
	generatedParts.Name = "GeneratedAsylum"
	generatedParts.Parent = workspace

	-- Init mapData
	mapData = {
		floors = {},
		stairwellPos = nil,
		seed = seed,
		gridWidth = gridWidth,
		gridDepth = gridDepth,
		floorCount = floorCount,
	}

	-- Pick stairwell position (interior, away from edges)
	local stairX = rng:NextInteger(3, math.max(3, gridWidth - 2))
	local stairZ = rng:NextInteger(3, math.max(3, gridDepth - 2))
	mapData.stairwellPos = { x = stairX, z = stairZ }

	print(
		("[MapGen] Starting generation: %d floors, %dx%d grid, seed=%d"):format(floorCount, gridWidth, gridDepth, seed)
	)
	print(("[MapGen] Stairwell at grid (%d, %d)"):format(stairX, stairZ))

	-- Generate each floor
	for floorIndex = 1, floorCount do
		local floor = {
			index = floorIndex,
			rooms = {},
			grid = nil,
		}
		local grid = createGrid(gridWidth, gridDepth)
		floor.grid = grid

		-- Step 3: Place stairwell on every floor at same position
		placeStairwell(floor, grid, stairX, stairZ)

		-- Step 4: Place lobby on floor 1
		if floorIndex == 1 then
			placeLobby(floor, grid, gridWidth, gridDepth, rng)
		end

		-- Step 5: Grow hallways from stairwell
		growHallways(floor, grid, stairX, stairZ, rng, gridWidth, gridDepth)

		-- Step 6: Fill empty slots with rooms
		fillRooms(floor, grid, rng, gridWidth, gridDepth)

		-- Step 7: Carve doors
		carveDoors(floor, grid, gridWidth, gridDepth, rng)

		-- Step 8: Ensure solvability
		ensureSolvability(floor, grid, stairX, stairZ, gridWidth, gridDepth)

		-- Step 9: Apply conditions
		applyConditions(floor, rng, floorIndex)

		-- Step 10: Place furniture
		placeFurniture(floor, rng)

		print(("[MapGen]   Floor %d: %d rooms, %d doors total"):format(
			floorIndex,
			#floor.rooms,
			(function()
				local count = 0
				for _, room in floor.rooms do
					count += #room.doors
				end
				return count
			end)()
		))
		table.insert(mapData.floors, floor)
	end

	-- Step 11: Build physical parts (floors, walls, ceilings + staircases)
	for floorIndex, floor in mapData.floors do
		local floorFolder = Instance.new("Folder")
		floorFolder.Name = "Floor_" .. tostring(floorIndex)
		floorFolder.Parent = generatedParts

		buildFloorParts(floorFolder, floor, floor.grid, floorIndex, gridWidth, gridDepth)

		-- Build staircase on every floor except the top floor
		if floorIndex ~= floorCount then
			buildStaircase(floorFolder, stairX, stairZ, floorIndex)
		end

		print(("[MapGen]   Floor %d built: %d parts"):format(floorIndex, #floorFolder:GetChildren()))
	end

	-- Step 12: Build exterior shell
	local exteriorFolder = Instance.new("Folder")
	exteriorFolder.Name = "Exterior"
	exteriorFolder.Parent = generatedParts
	buildExterior(exteriorFolder, gridWidth, gridDepth, floorCount, rng)
	print(("[MapGen] Exterior built: %d parts"):format(#exteriorFolder:GetChildren()))

	-- Step 13: Build forest
	local forestFolder = Instance.new("Folder")
	forestFolder.Name = "Forest"
	forestFolder.Parent = generatedParts
	buildForest(forestFolder, gridWidth, gridDepth, rng)
	print(("[MapGen] Forest built: %d parts"):format(#forestFolder:GetChildren()))

	-- Step 14: Add rain
	local weatherFolder = Instance.new("Folder")
	weatherFolder.Name = "Weather"
	weatherFolder.Parent = generatedParts
	buildRain(weatherFolder, gridWidth, gridDepth)
	print("[MapGen] Rain emitter created")

	print(("[MapGen] Generation complete! Total parts: %d"):format(#generatedParts:GetDescendants()))

	return mapData
end

--- Get stairwell world positions per floor
--- @return { [number]: { Vector3 } }
function MapGenerator.getFloorConnections(): { [number]: { Vector3 } }
	local connections: { [number]: { Vector3 } } = {}
	if mapData == nil or mapData.stairwellPos == nil then
		return connections
	end

	for floorIndex = 1, mapData.floorCount do
		local worldPos = gridToWorld(mapData.stairwellPos.x, mapData.stairwellPos.z, floorIndex)
		connections[floorIndex] = { worldPos }
	end

	return connections
end

--- Destroy all generated parts and clear map data
function MapGenerator.cleanup()
	if generatedParts then
		generatedParts:Destroy()
		generatedParts = nil
	end
	mapData = nil
end

return MapGenerator
