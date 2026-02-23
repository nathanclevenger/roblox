# Abandoned Mental Asylum Map Generator — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a grid-based procedural map generator that creates a multi-floor abandoned mental asylum with forest exterior and rain, integrated with the existing A* pathfinding for cross-floor NPC navigation.

**Architecture:** Grid-based room stamping. Each floor is a 2D grid of 24x24-stud slots. Preset room templates are placed into slots, connected by hallways, with doors carved between adjacent rooms. A flood-fill pass guarantees solvability. The generator builds physical Roblox `BasePart`s for walls/floors/ceilings, then adds exterior shell, forest, and rain. Multi-floor pathfinding extends the existing `Pathfinding.lua` module.

**Tech Stack:** Luau (Roblox), existing `Pathfinding.lua` A* module. No external dependencies.

**Note:** This project has no test framework or git repo. Verification is done via `print()` assertions and visual checks in Roblox Studio. Each task ends with a verification step instead of automated tests.

---

### Task 1: Room Template Data

**Files:**
- Create: `RoomTemplates.lua`

**Step 1: Create the room template module with all 9 room types**

```lua
-- RoomTemplates.lua
-- Preset room definitions for the asylum map generator

local RoomTemplates = {}

-- All templates use grid units (1 unit = 24 studs = one grid slot)
-- doorPositions: which edges CAN have a door (actual doors carved by generator)
-- weight: relative probability of being chosen during room filling
-- furnitureSlots: named positions as {x, z} offsets within the room (in studs, relative to room origin)
-- conditions: which condition overlays this room type supports

RoomTemplates.templates = {
	Hallway = {
		type = "Hallway",
		gridSize = { x = 1, z = 1 },
		doorPositions = { "north", "south", "east", "west" },
		floorMaterial = Enum.Material.Concrete,
		wallMaterial = Enum.Material.Concrete,
		weight = 0, -- hallways are placed by the hallway-growing algorithm, not random fill
		furnitureSlots = {},
		conditions = { "normal", "flooded" },
	},

	Lobby = {
		type = "Lobby",
		gridSize = { x = 2, z = 2 },
		doorPositions = { "north", "south", "east", "west" },
		floorMaterial = Enum.Material.Marble,
		wallMaterial = Enum.Material.Concrete,
		weight = 0, -- placed explicitly on floor 1
		furnitureSlots = {
			{ name = "reception_desk", x = 12, z = 8 },
			{ name = "bench_1", x = 6, z = 20 },
			{ name = "bench_2", x = 18, z = 20 },
		},
		conditions = { "normal" },
	},

	Stairwell = {
		type = "Stairwell",
		gridSize = { x = 1, z = 1 },
		doorPositions = { "north", "south", "east", "west" },
		floorMaterial = Enum.Material.Concrete,
		wallMaterial = Enum.Material.Concrete,
		weight = 0, -- placed explicitly
		furnitureSlots = {},
		conditions = { "normal" },
	},

	PatientRoom = {
		type = "PatientRoom",
		gridSize = { x = 1, z = 1 },
		doorPositions = { "north", "south", "east", "west" },
		floorMaterial = Enum.Material.SmoothPlastic,
		wallMaterial = Enum.Material.SmoothPlastic,
		weight = 30,
		furnitureSlots = {
			{ name = "bed", x = 4, z = 12 },
			{ name = "nightstand", x = 4, z = 6 },
			{ name = "chair", x = 16, z = 16 },
		},
		conditions = { "normal", "flooded", "boarded" },
	},

	PaddedCell = {
		type = "PaddedCell",
		gridSize = { x = 1, z = 1 },
		doorPositions = { "north", "south", "east", "west" },
		floorMaterial = Enum.Material.Fabric,
		wallMaterial = Enum.Material.Fabric,
		weight = 10,
		furnitureSlots = {},
		conditions = { "normal", "collapsed" },
	},

	OperatingRoom = {
		type = "OperatingRoom",
		gridSize = { x = 2, z = 1 },
		doorPositions = { "north", "south", "east", "west" },
		floorMaterial = Enum.Material.SmoothPlastic,
		wallMaterial = Enum.Material.SmoothPlastic,
		weight = 5,
		furnitureSlots = {
			{ name = "table", x = 20, z = 12 },
			{ name = "cabinet", x = 6, z = 4 },
			{ name = "light", x = 20, z = 12 },
			{ name = "tray", x = 28, z = 8 },
		},
		conditions = { "normal", "flooded", "collapsed" },
	},

	Bathroom = {
		type = "Bathroom",
		gridSize = { x = 1, z = 1 },
		doorPositions = { "north", "south", "east", "west" },
		floorMaterial = Enum.Material.Marble,
		wallMaterial = Enum.Material.Marble,
		weight = 15,
		furnitureSlots = {
			{ name = "toilet", x = 4, z = 4 },
			{ name = "sink", x = 4, z = 16 },
		},
		conditions = { "normal", "flooded" },
	},

	Office = {
		type = "Office",
		gridSize = { x = 1, z = 1 },
		doorPositions = { "north", "south", "east", "west" },
		floorMaterial = Enum.Material.WoodPlanks,
		wallMaterial = Enum.Material.Concrete,
		weight = 10,
		furnitureSlots = {
			{ name = "desk", x = 12, z = 8 },
			{ name = "chair", x = 12, z = 14 },
			{ name = "cabinet", x = 4, z = 4 },
		},
		conditions = { "normal", "boarded" },
	},

	StorageRoom = {
		type = "StorageRoom",
		gridSize = { x = 1, z = 1 },
		doorPositions = { "north", "south", "east", "west" },
		floorMaterial = Enum.Material.Concrete,
		wallMaterial = Enum.Material.Concrete,
		weight = 15,
		furnitureSlots = {
			{ name = "shelf_1", x = 4, z = 6 },
			{ name = "shelf_2", x = 4, z = 14 },
			{ name = "crate", x = 16, z = 10 },
		},
		conditions = { "normal", "collapsed", "boarded" },
	},
}

--- Get a list of room types eligible for random placement (weight > 0)
function RoomTemplates.getWeightedList(): { { template: any, weight: number } }
	local list = {}
	for _, template in RoomTemplates.templates do
		if template.weight > 0 then
			table.insert(list, { template = template, weight = template.weight })
		end
	end
	return list
end

--- Pick a random room template using weighted selection
function RoomTemplates.pickRandom(rng: Random): any
	local list = RoomTemplates.getWeightedList()
	local totalWeight = 0
	for _, entry in list do
		totalWeight += entry.weight
	end

	local roll = rng:NextNumber() * totalWeight
	local cumulative = 0
	for _, entry in list do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.template
		end
	end

	return list[#list].template
end

return RoomTemplates
```

**Step 2: Verify**

Open in Roblox Studio. In the command bar run:
```lua
local RT = require(game.ReplicatedStorage.RoomTemplates)
print("Templates loaded:", #RT.getWeightedList(), "weighted types")
for _, entry in RT.getWeightedList() do
    print("  ", entry.template.type, "weight:", entry.weight)
end
```
Expected: 6 weighted types printed (PatientRoom, PaddedCell, OperatingRoom, Bathroom, Office, StorageRoom). Hallway/Lobby/Stairwell have weight 0 and should not appear.

---

### Task 2: MapGenerator Core — Grid Data Structure and Seeded RNG

**Files:**
- Create: `MapGenerator.lua`

**Step 1: Create the MapGenerator module skeleton with grid data structures**

```lua
-- MapGenerator.lua
-- Procedural map generator for abandoned mental asylum
-- Assembles preset room templates on a 2D grid, builds physical Roblox parts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoomTemplates = require(ReplicatedStorage:WaitForChild("RoomTemplates"))

local MapGenerator = {}

-- ── Constants ─────────────────────────────────────────────────────────────
local SLOT_SIZE = 24        -- Each grid slot is 24x24 studs
local FLOOR_HEIGHT = 16     -- Wall/ceiling height per floor in studs
local WALL_THICKNESS = 1    -- Wall part thickness in studs

-- ── Module State ──────────────────────────────────────────────────────────
local mapData = nil         -- Current generated map data
local generatedParts = nil  -- Folder holding all generated Roblox instances

-- ── Grid Helpers ──────────────────────────────────────────────────────────

-- Direction vectors for grid adjacency (grid units, not studs)
local GRID_DIRS = {
	north = { x = 0, z = -1 },
	south = { x = 0, z = 1 },
	east  = { x = 1, z = 0 },
	west  = { x = -1, z = 0 },
}

-- Opposite direction lookup
local OPPOSITE = {
	north = "south",
	south = "north",
	east = "west",
	west = "east",
}

--- Create an empty floor grid
--- Each cell is nil (empty) or a table: { roomType: string, roomId: number, doors: {string} }
local function createGrid(width: number, depth: number): { { any? } }
	local grid = {}
	for x = 1, width do
		grid[x] = {}
		for z = 1, depth do
			grid[x][z] = nil
		end
	end
	return grid
end

--- Check if a grid position is within bounds
local function inBounds(grid, x: number, z: number): boolean
	return x >= 1 and x <= #grid and z >= 1 and z <= #grid[1]
end

--- Check if a grid cell is empty
local function isEmpty(grid, x: number, z: number): boolean
	return inBounds(grid, x, z) and grid[x][z] == nil
end

--- Convert grid coords to world position (center of slot, at floor level)
local function gridToWorld(gridX: number, gridZ: number, floorIndex: number): Vector3
	return Vector3.new(
		(gridX - 1) * SLOT_SIZE + SLOT_SIZE / 2,
		(floorIndex - 1) * FLOOR_HEIGHT,
		(gridZ - 1) * SLOT_SIZE + SLOT_SIZE / 2
	)
end

--- Get all cardinal neighbors of a grid cell
local function getNeighbors(x: number, z: number): { { x: number, z: number, dir: string } }
	local neighbors = {}
	for dir, offset in GRID_DIRS do
		table.insert(neighbors, { x = x + offset.x, z = z + offset.z, dir = dir })
	end
	return neighbors
end

-- ── Public API (stubs) ────────────────────────────────────────────────────

function MapGenerator.generate(config: {
	floors: number?,
	gridWidth: number?,
	gridDepth: number?,
	seed: number?,
})
	-- Will be implemented in subsequent tasks
	local floors = config.floors or 2
	local gridWidth = config.gridWidth or 8
	local gridDepth = config.gridDepth or 6
	local seed = config.seed or os.time()
	local rng = Random.new(seed)

	print(("[MapGenerator] Generating %d floors, %dx%d grid, seed=%d"):format(
		floors, gridWidth, gridDepth, seed
	))

	-- Initialize map data
	mapData = {
		floors = {},
		stairwellPos = nil, -- {x, z} shared across all floors
		seed = seed,
		gridWidth = gridWidth,
		gridDepth = gridDepth,
		floorCount = floors,
	}

	for i = 1, floors do
		mapData.floors[i] = {
			grid = createGrid(gridWidth, gridDepth),
			rooms = {}, -- list of {id, type, cells: {{x,z}}, doors: {{x,z,dir}}, condition}
			nextRoomId = 1,
		}
	end

	return mapData
end

function MapGenerator.getFloorConnections(): { [number]: { Vector3 } }
	if not mapData then return {} end
	local connections = {}
	if mapData.stairwellPos then
		for i = 1, mapData.floorCount do
			connections[i] = {
				gridToWorld(mapData.stairwellPos.x, mapData.stairwellPos.z, i)
			}
		end
	end
	return connections
end

function MapGenerator.cleanup()
	if generatedParts then
		generatedParts:Destroy()
		generatedParts = nil
	end
	mapData = nil
end

return MapGenerator
```

**Step 2: Verify**

In Roblox Studio command bar:
```lua
local MG = require(game.ReplicatedStorage.MapGenerator)
local data = MG.generate({ floors = 2, gridWidth = 8, gridDepth = 6, seed = 12345 })
print("Floors:", #data.floors)
print("Grid size:", #data.floors[1].grid, "x", #data.floors[1].grid[1])
MG.cleanup()
print("Cleanup OK")
```
Expected: Prints "Generating 2 floors, 8x6 grid, seed=12345", then "Floors: 2", "Grid size: 8 x 6", "Cleanup OK".

---

### Task 3: Stairwell and Lobby Placement

**Files:**
- Modify: `MapGenerator.lua`

**Step 1: Add room placement helpers and stairwell/lobby logic**

Add these local functions after the grid helpers section, before the public API:

```lua
-- ── Room Placement ────────────────────────────────────────────────────────

local function placeRoomOnGrid(floor, grid, roomType: string, cells: { { x: number, z: number } }): number
	local roomId = floor.nextRoomId
	floor.nextRoomId += 1

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
			roomType = roomType,
			roomId = roomId,
			doors = {},
		}
	end

	return roomId
end

--- Place the stairwell on a floor at the shared stairwell position
local function placeStairwell(floor, grid, sx: number, sz: number)
	placeRoomOnGrid(floor, grid, "Stairwell", { { x = sx, z = sz } })
end

--- Place the lobby on floor 1 at the south edge (building entrance side)
local function placeLobby(floor, grid, gridWidth: number, gridDepth: number, rng: Random)
	-- Lobby is 2x2. Place it centered on the south edge.
	local lobbyX = math.clamp(rng:NextInteger(2, gridWidth - 2), 1, gridWidth - 1)
	local lobbyZ = gridDepth - 1 -- second-to-last row so it sits at the south edge

	local cells = {
		{ x = lobbyX, z = lobbyZ },
		{ x = lobbyX + 1, z = lobbyZ },
		{ x = lobbyX, z = lobbyZ + 1 },
		{ x = lobbyX + 1, z = lobbyZ + 1 },
	}

	-- Check all cells are empty
	for _, cell in cells do
		if not isEmpty(grid, cell.x, cell.z) then
			-- Fallback: just skip lobby if it overlaps stairwell
			return
		end
	end

	placeRoomOnGrid(floor, grid, "Lobby", cells)
end
```

**Step 2: Wire into `MapGenerator.generate`**

Replace the `return mapData` at the end of `generate` with:

```lua
	-- Step 1: Pick stairwell position (interior, away from edges)
	local sx = rng:NextInteger(3, gridWidth - 2)
	local sz = rng:NextInteger(3, gridDepth - 2)
	mapData.stairwellPos = { x = sx, z = sz }

	-- Place stairwell on every floor at the same position
	for i = 1, floors do
		placeStairwell(mapData.floors[i], mapData.floors[i].grid, sx, sz)
	end

	-- Step 2: Place lobby on floor 1
	placeLobby(mapData.floors[1], mapData.floors[1].grid, gridWidth, gridDepth, rng)

	return mapData
```

**Step 3: Verify**

```lua
local MG = require(game.ReplicatedStorage.MapGenerator)
local data = MG.generate({ floors = 2, gridWidth = 8, gridDepth = 6, seed = 42 })
print("Stairwell at:", data.stairwellPos.x, data.stairwellPos.z)
print("Floor 1 rooms:")
for _, room in data.floors[1].rooms do
    print("  ", room.type, "id:", room.id, "cells:", #room.cells)
end
print("Floor 2 rooms:")
for _, room in data.floors[2].rooms do
    print("  ", room.type, "id:", room.id)
end
MG.cleanup()
```
Expected: Stairwell on both floors, Lobby on floor 1 only with 4 cells.

---

### Task 4: Hallway Growing Algorithm

**Files:**
- Modify: `MapGenerator.lua`

**Step 1: Add hallway growing function**

Add after the `placeLobby` function:

```lua
--- Grow hallways from the stairwell using a random walk that favors straight lines
local function growHallways(floor, grid, startX: number, startZ: number, rng: Random, gridWidth: number, gridDepth: number)
	local hallwayCells = {}

	-- Start with the 4 cardinal neighbors of the stairwell as seeds
	local seeds = {}
	for dir, offset in GRID_DIRS do
		local nx, nz = startX + offset.x, startZ + offset.z
		if isEmpty(grid, nx, nz) then
			table.insert(seeds, { x = nx, z = nz, dir = dir })
		end
	end

	-- Grow a hallway branch from each seed
	for _, seed in seeds do
		local cx, cz = seed.x, seed.z
		local currentDir = seed.dir
		local branchLength = rng:NextInteger(3, math.max(gridWidth, gridDepth) - 2)

		for _ = 1, branchLength do
			if not isEmpty(grid, cx, cz) then break end

			placeRoomOnGrid(floor, grid, "Hallway", { { x = cx, z = cz } })
			table.insert(hallwayCells, { x = cx, z = cz })

			-- 70% chance to continue straight, 30% to turn
			local nextDir = currentDir
			if rng:NextNumber() < 0.3 then
				-- Pick a perpendicular direction
				if currentDir == "north" or currentDir == "south" then
					nextDir = rng:NextNumber() < 0.5 and "east" or "west"
				else
					nextDir = rng:NextNumber() < 0.5 and "north" or "south"
				end
			end

			local offset = GRID_DIRS[nextDir]
			local nx, nz = cx + offset.x, cz + offset.z

			-- Stay 1 cell away from grid edges to leave room for rooms on the sides
			if nx < 2 or nx > gridWidth - 1 or nz < 2 or nz > gridDepth - 1 then
				break
			end

			cx, cz = nx, nz
			currentDir = nextDir
		end
	end

	return hallwayCells
end
```

**Step 2: Wire into `generate` (after lobby placement, before `return mapData`)**

```lua
	-- Step 3: Grow hallways from stairwell on each floor
	for i = 1, floors do
		growHallways(mapData.floors[i], mapData.floors[i].grid, sx, sz, rng, gridWidth, gridDepth)
	end
```

**Step 3: Verify**

```lua
local MG = require(game.ReplicatedStorage.MapGenerator)
local data = MG.generate({ floors = 2, gridWidth = 8, gridDepth = 6, seed = 42 })
local hallwayCount = 0
for x = 1, 8 do
    for z = 1, 6 do
        local cell = data.floors[1].grid[x][z]
        if cell and cell.roomType == "Hallway" then
            hallwayCount += 1
        end
    end
end
print("Floor 1 hallway cells:", hallwayCount)
-- Print a text map
for z = 1, 6 do
    local row = ""
    for x = 1, 8 do
        local cell = data.floors[1].grid[x][z]
        if cell == nil then row ..= "."
        elseif cell.roomType == "Stairwell" then row ..= "S"
        elseif cell.roomType == "Hallway" then row ..= "#"
        elseif cell.roomType == "Lobby" then row ..= "L"
        else row ..= "?" end
    end
    print(row)
end
MG.cleanup()
```
Expected: A text map showing S (stairwell), # (hallways branching out), L (lobby), and . (empty). Hallways should form connected branches from the stairwell.

---

### Task 5: Room Filling Algorithm

**Files:**
- Modify: `MapGenerator.lua`

**Step 1: Add the room filling function**

Add after `growHallways`:

```lua
--- Fill empty grid cells adjacent to hallways with random room templates
local function fillRooms(floor, grid, rng: Random, gridWidth: number, gridDepth: number)
	-- Collect all empty cells adjacent to a hallway or lobby
	local candidates = {}
	for x = 1, gridWidth do
		for z = 1, gridDepth do
			if isEmpty(grid, x, z) then
				-- Check if any neighbor is a hallway or lobby
				for _, neighbor in getNeighbors(x, z) do
					if inBounds(grid, neighbor.x, neighbor.z) then
						local adj = grid[neighbor.x][neighbor.z]
						if adj and (adj.roomType == "Hallway" or adj.roomType == "Lobby") then
							table.insert(candidates, { x = x, z = z })
							break
						end
					end
				end
			end
		end
	end

	-- Shuffle candidates for variety
	for i = #candidates, 2, -1 do
		local j = rng:NextInteger(1, i)
		candidates[i], candidates[j] = candidates[j], candidates[i]
	end

	-- Place rooms
	for _, pos in candidates do
		if not isEmpty(grid, pos.x, pos.z) then continue end

		local template = RoomTemplates.pickRandom(rng)

		-- Try to place multi-slot rooms
		if template.gridSize.x > 1 or template.gridSize.z > 1 then
			local cells = {}
			local canPlace = true
			for dx = 0, template.gridSize.x - 1 do
				for dz = 0, template.gridSize.z - 1 do
					local cx, cz = pos.x + dx, pos.z + dz
					if not isEmpty(grid, cx, cz) then
						canPlace = false
						break
					end
					table.insert(cells, { x = cx, z = cz })
				end
				if not canPlace then break end
			end

			if canPlace then
				placeRoomOnGrid(floor, grid, template.type, cells)
			else
				-- Fall back to a 1x1 room
				local fallback = RoomTemplates.pickRandom(rng)
				while fallback.gridSize.x > 1 or fallback.gridSize.z > 1 do
					fallback = RoomTemplates.pickRandom(rng)
				end
				placeRoomOnGrid(floor, grid, fallback.type, { { x = pos.x, z = pos.z } })
			end
		else
			placeRoomOnGrid(floor, grid, template.type, { { x = pos.x, z = pos.z } })
		end
	end

	-- Second pass: fill remaining empty cells that are adjacent to ANY placed room
	for x = 1, gridWidth do
		for z = 1, gridDepth do
			if isEmpty(grid, x, z) then
				local hasNeighbor = false
				for _, neighbor in getNeighbors(x, z) do
					if inBounds(grid, neighbor.x, neighbor.z) and grid[neighbor.x][neighbor.z] ~= nil then
						hasNeighbor = true
						break
					end
				end
				if hasNeighbor then
					local fallback = RoomTemplates.pickRandom(rng)
					while fallback.gridSize.x > 1 or fallback.gridSize.z > 1 do
						fallback = RoomTemplates.pickRandom(rng)
					end
					placeRoomOnGrid(floor, grid, fallback.type, { { x = x, z = z } })
				end
			end
		end
	end
end
```

**Step 2: Wire into `generate` (after hallway growing)**

```lua
	-- Step 4: Fill empty slots with rooms
	for i = 1, floors do
		fillRooms(mapData.floors[i], mapData.floors[i].grid, rng, gridWidth, gridDepth)
	end
```

**Step 3: Verify**

```lua
local MG = require(game.ReplicatedStorage.MapGenerator)
local data = MG.generate({ floors = 2, gridWidth = 8, gridDepth = 6, seed = 42 })
local counts = {}
for x = 1, 8 do
    for z = 1, 6 do
        local cell = data.floors[1].grid[x][z]
        if cell then
            counts[cell.roomType] = (counts[cell.roomType] or 0) + 1
        end
    end
end
for roomType, count in counts do
    print(roomType, count)
end
-- Should show a mix of room types filling most of the grid
```
Expected: Most grid cells filled. Room types distributed roughly according to weights.

---

### Task 6: Door Carving and Solvability Validation

**Files:**
- Modify: `MapGenerator.lua`

**Step 1: Add door carving function**

Add after `fillRooms`:

```lua
--- Carve doors between adjacent rooms that share an edge
local function carveDoors(floor, grid, gridWidth: number, gridDepth: number)
	local roomDoorCount = {} -- roomId -> number of doors placed

	for x = 1, gridWidth do
		for z = 1, gridDepth do
			local cell = grid[x][z]
			if not cell then continue end

			-- Check east and south neighbors to avoid duplicate checks
			local checkDirs = {
				{ dir = "east", nx = x + 1, nz = z },
				{ dir = "south", nx = x, nz = z + 1 },
			}

			for _, check in checkDirs do
				if not inBounds(grid, check.nx, check.nz) then continue end
				local neighbor = grid[check.nx][check.nz]
				if not neighbor then continue end

				-- Don't place doors between cells of the same room
				if cell.roomId == neighbor.roomId then continue end

				-- Check if both room templates allow a door on this edge
				local cellTemplate = RoomTemplates.templates[cell.roomType]
				local neighborTemplate = RoomTemplates.templates[neighbor.roomType]
				if not cellTemplate or not neighborTemplate then continue end

				local cellHasDoor = table.find(cellTemplate.doorPositions, check.dir)
				local neighborHasDoor = table.find(neighborTemplate.doorPositions, OPPOSITE[check.dir])

				if cellHasDoor and neighborHasDoor then
					-- Place door
					local door = { x = x, z = z, dir = check.dir }
					table.insert(cell.doors, check.dir)
					table.insert(neighbor.doors, OPPOSITE[check.dir])

					-- Track per-room door counts
					roomDoorCount[cell.roomId] = (roomDoorCount[cell.roomId] or 0) + 1
					roomDoorCount[neighbor.roomId] = (roomDoorCount[neighbor.roomId] or 0) + 1

					-- Record on room objects
					for _, room in floor.rooms do
						if room.id == cell.roomId then
							table.insert(room.doors, { x = x, z = z, dir = check.dir })
						elseif room.id == neighbor.roomId then
							table.insert(room.doors, { x = check.nx, z = check.nz, dir = OPPOSITE[check.dir] })
						end
					end
				end
			end
		end
	end

	-- Guarantee: every room must have at least one door
	for _, room in floor.rooms do
		if #room.doors == 0 and #room.cells > 0 then
			-- Force a door to any adjacent occupied cell
			for _, cell in room.cells do
				for _, neighbor in getNeighbors(cell.x, cell.z) do
					if inBounds(grid, neighbor.x, neighbor.z) then
						local adj = grid[neighbor.x][neighbor.z]
						if adj and adj.roomId ~= room.id then
							table.insert(grid[cell.x][cell.z].doors, neighbor.dir)
							table.insert(adj.doors, OPPOSITE[neighbor.dir])
							table.insert(room.doors, { x = cell.x, z = cell.z, dir = neighbor.dir })
							break
						end
					end
				end
				if #room.doors > 0 then break end
			end
		end
	end
end
```

**Step 2: Add solvability validation via flood fill**

```lua
--- Validate that all rooms are reachable from the stairwell via doors (flood fill)
--- Forces connections where needed
local function ensureSolvability(floor, grid, startX: number, startZ: number, gridWidth: number, gridDepth: number)
	-- Build adjacency: which roomIds connect via doors?
	local roomAdj = {} -- roomId -> set of connected roomIds
	for _, room in floor.rooms do
		roomAdj[room.id] = {}
	end

	for x = 1, gridWidth do
		for z = 1, gridDepth do
			local cell = grid[x][z]
			if not cell then continue end

			for _, dir in cell.doors do
				local offset = GRID_DIRS[dir]
				if not offset then continue end
				local nx, nz = x + offset.x, z + offset.z
				if inBounds(grid, nx, nz) and grid[nx][nz] then
					local neighborId = grid[nx][nz].roomId
					if neighborId ~= cell.roomId then
						roomAdj[cell.roomId][neighborId] = true
						roomAdj[neighborId][cell.roomId] = true
					end
				end
			end
		end
	end

	-- Flood fill from the stairwell's room
	local startCell = grid[startX][startZ]
	if not startCell then return end

	local visited = {}
	local queue = { startCell.roomId }
	visited[startCell.roomId] = true

	while #queue > 0 do
		local current = table.remove(queue, 1)
		for neighborId in roomAdj[current] do
			if not visited[neighborId] then
				visited[neighborId] = true
				table.insert(queue, neighborId)
			end
		end
	end

	-- Find unreachable rooms and force-connect them
	for _, room in floor.rooms do
		if not visited[room.id] then
			-- Find the closest reachable neighbor cell and force a door
			for _, cell in room.cells do
				local connected = false
				for _, neighbor in getNeighbors(cell.x, cell.z) do
					if inBounds(grid, neighbor.x, neighbor.z) then
						local adj = grid[neighbor.x][neighbor.z]
						if adj and visited[adj.roomId] then
							-- Force door
							table.insert(grid[cell.x][cell.z].doors, neighbor.dir)
							table.insert(adj.doors, OPPOSITE[neighbor.dir])
							table.insert(room.doors, { x = cell.x, z = cell.z, dir = neighbor.dir })
							-- Mark this room as reachable now
							visited[room.id] = true
							roomAdj[room.id][adj.roomId] = true
							roomAdj[adj.roomId][room.id] = true
							connected = true
							break
						end
					end
				end
				if connected then break end
			end
		end
	end
end
```

**Step 3: Wire into `generate`**

```lua
	-- Step 5: Carve doors between adjacent rooms
	for i = 1, floors do
		carveDoors(mapData.floors[i], mapData.floors[i].grid, gridWidth, gridDepth)
	end

	-- Step 6: Ensure all rooms are reachable
	for i = 1, floors do
		ensureSolvability(mapData.floors[i], mapData.floors[i].grid, sx, sz, gridWidth, gridDepth)
	end
```

**Step 4: Verify**

```lua
local MG = require(game.ReplicatedStorage.MapGenerator)
local data = MG.generate({ floors = 2, gridWidth = 8, gridDepth = 6, seed = 42 })
local doorless = 0
for _, room in data.floors[1].rooms do
    if #room.doors == 0 then
        doorless += 1
        print("WARNING: doorless room:", room.type, room.id)
    end
end
print("Rooms without doors:", doorless)
-- Should print 0
```
Expected: 0 doorless rooms. Every room has at least one door.

---

### Task 7: Condition Overlays and Furniture Placement

**Files:**
- Modify: `MapGenerator.lua`

**Step 1: Add condition and furniture functions**

Add after `ensureSolvability`:

```lua
--- Apply random condition overlays to rooms (flooded, collapsed, boarded)
--- Deeper floors have worse conditions
local function applyConditions(floor, rng: Random, floorIndex: number, floorCount: number)
	local conditionChance = 0.15 + (floorIndex - 1) * 0.15 -- 15% floor 1, 30% floor 2, 45% floor 3
	conditionChance = math.min(conditionChance, 0.5)

	for _, room in floor.rooms do
		-- Don't modify stairwells, lobbies, or hallways
		if room.type == "Stairwell" or room.type == "Lobby" or room.type == "Hallway" then
			continue
		end

		if rng:NextNumber() < conditionChance then
			local template = RoomTemplates.templates[room.type]
			if template and #template.conditions > 1 then
				-- Pick a random non-normal condition
				local options = {}
				for _, cond in template.conditions do
					if cond ~= "normal" then
						table.insert(options, cond)
					end
				end
				if #options > 0 then
					room.condition = options[rng:NextInteger(1, #options)]
				end
			end
		end
	end
end

--- Place furniture in rooms based on template furniture slots
--- Some slots randomly left empty for abandoned feel
local function placeFurniture(floor, rng: Random)
	for _, room in floor.rooms do
		local template = RoomTemplates.templates[room.type]
		if not template or #template.furnitureSlots == 0 then continue end

		room.furniture = {}
		for _, slot in template.furnitureSlots do
			-- 60% chance to place furniture (abandoned building)
			if rng:NextNumber() < 0.6 then
				table.insert(room.furniture, {
					name = slot.name,
					x = slot.x,
					z = slot.z,
					knocked = rng:NextNumber() < 0.3, -- 30% chance furniture is knocked over
				})
			end
		end
	end
end
```

**Step 2: Wire into `generate` (after solvability, before `return mapData`)**

```lua
	-- Step 7: Apply condition overlays
	for i = 1, floors do
		applyConditions(mapData.floors[i], rng, i, floors)
	end

	-- Step 8: Place furniture
	for i = 1, floors do
		placeFurniture(mapData.floors[i], rng)
	end
```

**Step 3: Verify**

```lua
local MG = require(game.ReplicatedStorage.MapGenerator)
local data = MG.generate({ floors = 3, gridWidth = 8, gridDepth = 6, seed = 42 })
local conditions = {}
for i = 1, 3 do
    conditions[i] = {}
    for _, room in data.floors[i].rooms do
        conditions[i][room.condition] = (conditions[i][room.condition] or 0) + 1
    end
    print(("Floor %d conditions:"):format(i))
    for cond, count in conditions[i] do
        print("  ", cond, count)
    end
end
```
Expected: Floor 1 has mostly "normal" rooms. Higher floors have more flooded/collapsed/boarded rooms.

---

### Task 8: Physical Part Building — Floors, Walls, Ceilings

**Files:**
- Modify: `MapGenerator.lua`

**Step 1: Add the part-building functions**

Add after `placeFurniture`:

```lua
-- ── Physical Part Building ────────────────────────────────────────────────

--- Create a Part with common defaults
local function makePart(parent: Instance, name: string, size: Vector3, position: Vector3, material: Enum.Material, color: Color3): Part
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

--- Build the floor slab for a grid cell
local function buildFloor(parent: Instance, gridX: number, gridZ: number, floorIndex: number, material: Enum.Material, color: Color3, roomType: string)
	local worldPos = gridToWorld(gridX, gridZ, floorIndex)
	local floorY = worldPos.Y
	local part = makePart(
		parent,
		"Floor",
		Vector3.new(SLOT_SIZE, 1, SLOT_SIZE),
		Vector3.new(worldPos.X, floorY - 0.5, worldPos.Z),
		material,
		color
	)
	part:SetAttribute("RoomType", roomType)
	return part
end

--- Build the ceiling slab for a grid cell
local function buildCeiling(parent: Instance, gridX: number, gridZ: number, floorIndex: number, color: Color3)
	local worldPos = gridToWorld(gridX, gridZ, floorIndex)
	local ceilingY = worldPos.Y + FLOOR_HEIGHT
	return makePart(
		parent,
		"Ceiling",
		Vector3.new(SLOT_SIZE, 1, SLOT_SIZE),
		Vector3.new(worldPos.X, ceilingY + 0.5, worldPos.Z),
		Enum.Material.Concrete,
		color
	)
end

--- Build a wall segment on one edge of a grid cell
--- Does NOT build a wall if there is a door on that edge
local function buildWall(parent: Instance, gridX: number, gridZ: number, floorIndex: number, dir: string, material: Enum.Material, color: Color3)
	local worldPos = gridToWorld(gridX, gridZ, floorIndex)
	local baseY = worldPos.Y + FLOOR_HEIGHT / 2

	local size, position
	if dir == "north" then
		size = Vector3.new(SLOT_SIZE, FLOOR_HEIGHT, WALL_THICKNESS)
		position = Vector3.new(worldPos.X, baseY, worldPos.Z - SLOT_SIZE / 2 + WALL_THICKNESS / 2)
	elseif dir == "south" then
		size = Vector3.new(SLOT_SIZE, FLOOR_HEIGHT, WALL_THICKNESS)
		position = Vector3.new(worldPos.X, baseY, worldPos.Z + SLOT_SIZE / 2 - WALL_THICKNESS / 2)
	elseif dir == "east" then
		size = Vector3.new(WALL_THICKNESS, FLOOR_HEIGHT, SLOT_SIZE)
		position = Vector3.new(worldPos.X + SLOT_SIZE / 2 - WALL_THICKNESS / 2, baseY, worldPos.Z)
	elseif dir == "west" then
		size = Vector3.new(WALL_THICKNESS, FLOOR_HEIGHT, SLOT_SIZE)
		position = Vector3.new(worldPos.X - SLOT_SIZE / 2 + WALL_THICKNESS / 2, baseY, worldPos.Z)
	end

	return makePart(parent, "Wall_" .. dir, size, position, material, color)
end

--- Build a door frame (wall with opening) on one edge
local function buildDoorFrame(parent: Instance, gridX: number, gridZ: number, floorIndex: number, dir: string, material: Enum.Material, color: Color3)
	local worldPos = gridToWorld(gridX, gridZ, floorIndex)
	local baseY = worldPos.Y
	local doorWidth = 6
	local doorHeight = 10

	-- Build wall segments on either side of the door opening, and a lintel above
	local wallAboveDoor = FLOOR_HEIGHT - doorHeight

	if dir == "north" or dir == "south" then
		local wallZ
		if dir == "north" then
			wallZ = worldPos.Z - SLOT_SIZE / 2 + WALL_THICKNESS / 2
		else
			wallZ = worldPos.Z + SLOT_SIZE / 2 - WALL_THICKNESS / 2
		end

		local sideWidth = (SLOT_SIZE - doorWidth) / 2

		-- Left wall segment
		if sideWidth > 0 then
			makePart(parent, "DoorWall_L", Vector3.new(sideWidth, FLOOR_HEIGHT, WALL_THICKNESS),
				Vector3.new(worldPos.X - SLOT_SIZE / 2 + sideWidth / 2, baseY + FLOOR_HEIGHT / 2, wallZ), material, color)
		end
		-- Right wall segment
		if sideWidth > 0 then
			makePart(parent, "DoorWall_R", Vector3.new(sideWidth, FLOOR_HEIGHT, WALL_THICKNESS),
				Vector3.new(worldPos.X + SLOT_SIZE / 2 - sideWidth / 2, baseY + FLOOR_HEIGHT / 2, wallZ), material, color)
		end
		-- Lintel above door
		if wallAboveDoor > 0 then
			makePart(parent, "DoorLintel", Vector3.new(doorWidth, wallAboveDoor, WALL_THICKNESS),
				Vector3.new(worldPos.X, baseY + doorHeight + wallAboveDoor / 2, wallZ), material, color)
		end

	elseif dir == "east" or dir == "west" then
		local wallX
		if dir == "west" then
			wallX = worldPos.X - SLOT_SIZE / 2 + WALL_THICKNESS / 2
		else
			wallX = worldPos.X + SLOT_SIZE / 2 - WALL_THICKNESS / 2
		end

		local sideWidth = (SLOT_SIZE - doorWidth) / 2

		-- Left wall segment (toward -Z)
		if sideWidth > 0 then
			makePart(parent, "DoorWall_L", Vector3.new(WALL_THICKNESS, FLOOR_HEIGHT, sideWidth),
				Vector3.new(wallX, baseY + FLOOR_HEIGHT / 2, worldPos.Z - SLOT_SIZE / 2 + sideWidth / 2), material, color)
		end
		-- Right wall segment (toward +Z)
		if sideWidth > 0 then
			makePart(parent, "DoorWall_R", Vector3.new(WALL_THICKNESS, FLOOR_HEIGHT, sideWidth),
				Vector3.new(wallX, baseY + FLOOR_HEIGHT / 2, worldPos.Z + SLOT_SIZE / 2 - sideWidth / 2), material, color)
		end
		-- Lintel
		if wallAboveDoor > 0 then
			makePart(parent, "DoorLintel", Vector3.new(WALL_THICKNESS, wallAboveDoor, doorWidth),
				Vector3.new(wallX, baseY + doorHeight + wallAboveDoor / 2, worldPos.Z), material, color)
		end
	end
end

--- Get the color for a room based on type and condition
local function getRoomColor(roomType: string, condition: string): (Color3, Color3)
	-- Base wall and floor colors by room type (asylum aesthetic: muted, institutional)
	local wallColors = {
		Hallway = Color3.fromRGB(180, 175, 165),
		Lobby = Color3.fromRGB(170, 165, 155),
		Stairwell = Color3.fromRGB(160, 155, 150),
		PatientRoom = Color3.fromRGB(190, 185, 175),
		PaddedCell = Color3.fromRGB(200, 195, 180),
		OperatingRoom = Color3.fromRGB(200, 210, 200),
		Bathroom = Color3.fromRGB(195, 200, 195),
		Office = Color3.fromRGB(175, 165, 145),
		StorageRoom = Color3.fromRGB(155, 150, 140),
	}
	local floorColors = {
		Hallway = Color3.fromRGB(140, 135, 125),
		Lobby = Color3.fromRGB(160, 150, 130),
		Stairwell = Color3.fromRGB(130, 125, 120),
		PatientRoom = Color3.fromRGB(155, 150, 140),
		PaddedCell = Color3.fromRGB(170, 165, 150),
		OperatingRoom = Color3.fromRGB(170, 180, 170),
		Bathroom = Color3.fromRGB(165, 170, 165),
		Office = Color3.fromRGB(120, 95, 65),
		StorageRoom = Color3.fromRGB(130, 125, 115),
	}

	local wc = wallColors[roomType] or Color3.fromRGB(180, 175, 165)
	local fc = floorColors[roomType] or Color3.fromRGB(140, 135, 125)

	-- Darken/tint for conditions
	if condition == "flooded" then
		fc = Color3.fromRGB(80, 90, 100) -- dark wet floor
	elseif condition == "collapsed" then
		wc = Color3.fromRGB(120, 115, 105) -- dusty/dark walls
		fc = Color3.fromRGB(100, 95, 85)
	elseif condition == "boarded" then
		wc = Color3.fromRGB(140, 120, 90) -- wood-tinted
	end

	return wc, fc
end

--- Build all physical parts for one floor
local function buildFloorParts(parent: Instance, floor, grid, floorIndex: number, gridWidth: number, gridDepth: number, isTopFloor: boolean)
	local floorFolder = Instance.new("Folder")
	floorFolder.Name = "Floor_" .. floorIndex
	floorFolder.Parent = parent

	for x = 1, gridWidth do
		for z = 1, gridDepth do
			local cell = grid[x][z]
			if not cell then continue end

			local template = RoomTemplates.templates[cell.roomType]
			if not template then continue end

			-- Find this room's condition
			local condition = "normal"
			for _, room in floor.rooms do
				if room.id == cell.roomId then
					condition = room.condition
					break
				end
			end

			local wallColor, floorColor = getRoomColor(cell.roomType, condition)

			-- Build floor
			buildFloor(floorFolder, x, z, floorIndex, template.floorMaterial, floorColor, cell.roomType)

			-- Build ceiling (skip stairwell ceiling unless top floor)
			if cell.roomType ~= "Stairwell" or isTopFloor then
				buildCeiling(floorFolder, x, z, floorIndex, wallColor)
			end

			-- Build walls on each edge
			for _, dir in { "north", "south", "east", "west" } do
				local hasDoor = table.find(cell.doors, dir) ~= nil

				-- Check if neighbor is same room (no wall between cells of same room)
				local offset = GRID_DIRS[dir]
				local nx, nz = x + offset.x, z + offset.z
				local sameRoom = false
				if inBounds(grid, nx, nz) and grid[nx][nz] then
					sameRoom = grid[nx][nz].roomId == cell.roomId
				end

				if sameRoom then
					-- No wall between cells of the same multi-cell room
				elseif hasDoor then
					buildDoorFrame(floorFolder, x, z, floorIndex, dir, template.wallMaterial, wallColor)
				else
					-- Only build wall if neighbor is a different room or edge of grid
					local needsWall = not inBounds(grid, nx, nz) or grid[nx][nz] == nil or grid[nx][nz].roomId ~= cell.roomId
					if needsWall then
						buildWall(floorFolder, x, z, floorIndex, dir, template.wallMaterial, wallColor)
					end
				end
			end
		end
	end

	return floorFolder
end
```

**Step 2: Add staircase part building**

```lua
--- Build a staircase inside a stairwell cell connecting to the floor above
local function buildStaircase(parent: Instance, gridX: number, gridZ: number, floorIndex: number)
	local worldPos = gridToWorld(gridX, gridZ, floorIndex)
	local baseY = worldPos.Y
	local stairColor = Color3.fromRGB(140, 135, 130)

	local numSteps = 8
	local stepHeight = FLOOR_HEIGHT / numSteps
	local stepDepth = (SLOT_SIZE - 4) / numSteps -- leave 2 stud margin on each side

	for i = 0, numSteps - 1 do
		makePart(
			parent,
			"Stair_" .. i,
			Vector3.new(SLOT_SIZE - 4, stepHeight, stepDepth),
			Vector3.new(
				worldPos.X,
				baseY + (i * stepHeight) + stepHeight / 2,
				worldPos.Z - SLOT_SIZE / 2 + 2 + (i * stepDepth) + stepDepth / 2
			),
			Enum.Material.Concrete,
			stairColor
		)
	end
end
```

**Step 3: Wire the build phase into `generate` (after furniture, before `return mapData`)**

```lua
	-- Step 9: Build physical parts
	generatedParts = Instance.new("Folder")
	generatedParts.Name = "GeneratedMap"
	generatedParts.Parent = workspace

	for i = 1, floors do
		local isTopFloor = (i == floors)
		buildFloorParts(generatedParts, mapData.floors[i], mapData.floors[i].grid, i, gridWidth, gridDepth, isTopFloor)

		-- Build staircases (not on top floor)
		if not isTopFloor then
			buildStaircase(generatedParts, sx, sz, i)
		end
	end
```

**Step 4: Verify**

```lua
local MG = require(game.ReplicatedStorage.MapGenerator)
MG.cleanup()
MG.generate({ floors = 2, gridWidth = 8, gridDepth = 6, seed = 42 })
-- Look in workspace for "GeneratedMap" folder
-- Should see Floor_1 and Floor_2 folders with Part instances
print("Parts generated:", #workspace.GeneratedMap:GetDescendants())
```
Expected: A visible multi-floor asylum structure in the 3D viewport with floors, walls, ceilings, door openings, and staircases.

---

### Task 9: Furniture Part Building

**Files:**
- Modify: `MapGenerator.lua`

**Step 1: Add furniture building function**

Add after `buildStaircase`:

```lua
--- Build furniture parts for a room
local function buildFurniture(parent: Instance, room, gridX: number, gridZ: number, floorIndex: number, rng: Random)
	if not room.furniture then return end

	local worldOrigin = gridToWorld(gridX, gridZ, floorIndex)
	-- worldOrigin is center of cell; offset furniture from the cell's corner
	local cellCornerX = worldOrigin.X - SLOT_SIZE / 2
	local cellCornerZ = worldOrigin.Z - SLOT_SIZE / 2
	local baseY = worldOrigin.Y

	local furnitureColor = Color3.fromRGB(100, 80, 60) -- dark wood

	for _, item in room.furniture do
		local size, material, color

		if item.name == "bed" then
			size = Vector3.new(6, 3, 10)
			material = Enum.Material.Fabric
			color = Color3.fromRGB(160, 150, 130)
		elseif item.name == "desk" or item.name == "reception_desk" then
			size = Vector3.new(8, 4, 4)
			material = Enum.Material.WoodPlanks
			color = furnitureColor
		elseif item.name == "chair" then
			size = Vector3.new(3, 4, 3)
			material = Enum.Material.WoodPlanks
			color = furnitureColor
		elseif item.name == "nightstand" then
			size = Vector3.new(3, 3, 3)
			material = Enum.Material.WoodPlanks
			color = furnitureColor
		elseif item.name == "cabinet" or item.name == "shelf_1" or item.name == "shelf_2" then
			size = Vector3.new(6, 8, 2)
			material = Enum.Material.WoodPlanks
			color = Color3.fromRGB(90, 70, 50)
		elseif item.name == "table" then
			size = Vector3.new(10, 4, 6)
			material = Enum.Material.Metal
			color = Color3.fromRGB(180, 180, 180)
		elseif item.name == "toilet" then
			size = Vector3.new(2, 3, 3)
			material = Enum.Material.SmoothPlastic
			color = Color3.fromRGB(230, 230, 230)
		elseif item.name == "sink" then
			size = Vector3.new(3, 3, 2)
			material = Enum.Material.SmoothPlastic
			color = Color3.fromRGB(220, 220, 220)
		elseif item.name == "bench_1" or item.name == "bench_2" then
			size = Vector3.new(8, 3, 3)
			material = Enum.Material.WoodPlanks
			color = furnitureColor
		elseif item.name == "tray" then
			size = Vector3.new(3, 4, 2)
			material = Enum.Material.Metal
			color = Color3.fromRGB(170, 170, 170)
		elseif item.name == "crate" then
			size = Vector3.new(4, 4, 4)
			material = Enum.Material.WoodPlanks
			color = Color3.fromRGB(130, 110, 80)
		elseif item.name == "light" then
			-- Overhead light, skip physical part (or make a small ceiling fixture)
			size = Vector3.new(4, 1, 4)
			material = Enum.Material.Neon
			color = Color3.fromRGB(200, 200, 180)
		else
			size = Vector3.new(3, 3, 3)
			material = Enum.Material.WoodPlanks
			color = furnitureColor
		end

		local posX = cellCornerX + item.x
		local posZ = cellCornerZ + item.z
		local posY = baseY + size.Y / 2

		-- Knocked over: rotate and shift
		local orientation = Vector3.new(0, 0, 0)
		if item.knocked then
			posY = baseY + size.X / 2 -- lay on side
			orientation = Vector3.new(0, 0, 90)
		end

		-- Overhead light goes near ceiling
		if item.name == "light" then
			posY = baseY + FLOOR_HEIGHT - 1
		end

		local part = makePart(parent, item.name, size, Vector3.new(posX, posY, posZ), material, color)
		part.Orientation = orientation
		part.CanCollide = (item.name ~= "light") -- lights don't block movement
	end
end
```

**Step 2: Wire into the build phase inside `buildFloorParts` (after the wall-building loop, still inside the x,z loop)**

Add at the end of the `for x, z` loop in `buildFloorParts`, before the last `end end`:

```lua
			-- Build furniture for the first cell of each room (avoid duplicates for multi-cell rooms)
			local isFirstCell = false
			for _, room in floor.rooms do
				if room.id == cell.roomId and room.cells[1].x == x and room.cells[1].z == z then
					isFirstCell = true
					buildFurniture(floorFolder, room, x, z, floorIndex, nil)
					break
				end
			end
```

Note: Pass `nil` for rng since furniture positions are already determined. The `buildFurniture` function only reads `room.furniture` data.

**Step 3: Verify**

Regenerate the map in Roblox Studio. Look inside room folders for furniture parts (beds, desks, chairs etc.). Some should be knocked over (rotated 90 degrees).

---

### Task 10: Exterior Shell — Outer Walls, Entrance, Windows

**Files:**
- Modify: `MapGenerator.lua`

**Step 1: Add exterior building function**

Add after `buildFurniture`:

```lua
--- Build the exterior shell (outer walls, entrance, windows)
local function buildExterior(parent: Instance, gridWidth: number, gridDepth: number, floorCount: number, rng: Random)
	local exteriorFolder = Instance.new("Folder")
	exteriorFolder.Name = "Exterior"
	exteriorFolder.Parent = parent

	local totalWidth = gridWidth * SLOT_SIZE
	local totalDepth = gridDepth * SLOT_SIZE
	local totalHeight = floorCount * FLOOR_HEIGHT
	local exteriorColor = Color3.fromRGB(140, 130, 120) -- weathered concrete

	-- Entrance is centered on south wall
	local entranceWidth = 8
	local entranceHeight = 12

	-- Build 4 exterior walls
	local walls = {
		{ -- North wall
			size = Vector3.new(totalWidth + WALL_THICKNESS * 2, totalHeight, WALL_THICKNESS),
			pos = Vector3.new(totalWidth / 2, totalHeight / 2, -WALL_THICKNESS / 2),
			hasEntrance = false,
		},
		{ -- South wall (has entrance)
			size = Vector3.new(totalWidth + WALL_THICKNESS * 2, totalHeight, WALL_THICKNESS),
			pos = Vector3.new(totalWidth / 2, totalHeight / 2, totalDepth + WALL_THICKNESS / 2),
			hasEntrance = true,
		},
		{ -- East wall
			size = Vector3.new(WALL_THICKNESS, totalHeight, totalDepth),
			pos = Vector3.new(totalWidth + WALL_THICKNESS / 2, totalHeight / 2, totalDepth / 2),
			hasEntrance = false,
		},
		{ -- West wall
			size = Vector3.new(WALL_THICKNESS, totalHeight, totalDepth),
			pos = Vector3.new(-WALL_THICKNESS / 2, totalHeight / 2, totalDepth / 2),
			hasEntrance = false,
		},
	}

	for i, wall in walls do
		if wall.hasEntrance then
			-- South wall: build with entrance gap
			local sideWidth = (totalWidth - entranceWidth) / 2 + WALL_THICKNESS

			-- Left section
			makePart(exteriorFolder, "ExtWall_S_L",
				Vector3.new(sideWidth, totalHeight, WALL_THICKNESS),
				Vector3.new(sideWidth / 2 - WALL_THICKNESS, wall.pos.Y, wall.pos.Z),
				Enum.Material.Concrete, exteriorColor)

			-- Right section
			makePart(exteriorFolder, "ExtWall_S_R",
				Vector3.new(sideWidth, totalHeight, WALL_THICKNESS),
				Vector3.new(totalWidth - sideWidth / 2 + WALL_THICKNESS, wall.pos.Y, wall.pos.Z),
				Enum.Material.Concrete, exteriorColor)

			-- Lintel above entrance
			local lintelHeight = totalHeight - entranceHeight
			if lintelHeight > 0 then
				makePart(exteriorFolder, "ExtWall_S_Lintel",
					Vector3.new(entranceWidth, lintelHeight, WALL_THICKNESS),
					Vector3.new(totalWidth / 2, entranceHeight + lintelHeight / 2, wall.pos.Z),
					Enum.Material.Concrete, exteriorColor)
			end
		else
			makePart(exteriorFolder, "ExtWall_" .. i, wall.size, wall.pos, Enum.Material.Concrete, exteriorColor)
		end
	end

	-- Roof slab
	makePart(exteriorFolder, "Roof",
		Vector3.new(totalWidth + WALL_THICKNESS * 2, 1, totalDepth + WALL_THICKNESS * 2),
		Vector3.new(totalWidth / 2, totalHeight + 0.5, totalDepth / 2),
		Enum.Material.Concrete, Color3.fromRGB(120, 115, 110))

	-- Ground slab under building
	makePart(exteriorFolder, "BuildingGround",
		Vector3.new(totalWidth + 4, 1, totalDepth + 4),
		Vector3.new(totalWidth / 2, -0.5, totalDepth / 2),
		Enum.Material.Concrete, Color3.fromRGB(100, 95, 90))

	return exteriorFolder
end
```

**Step 2: Wire into `generate` (after the build loop, before `return mapData`)**

```lua
	-- Step 10: Build exterior shell
	buildExterior(generatedParts, gridWidth, gridDepth, floors, rng)
```

**Step 3: Verify**

Regenerate in Studio. The building should now have visible outer walls, a roof, an entrance gap on the south side, and a ground slab.

---

### Task 11: Forest Generation

**Files:**
- Modify: `MapGenerator.lua`

**Step 1: Add forest generation using Poisson disk sampling**

Add after `buildExterior`:

```lua
--- Generate a simple forest around the building
local function buildForest(parent: Instance, gridWidth: number, gridDepth: number, rng: Random)
	local forestFolder = Instance.new("Folder")
	forestFolder.Name = "Forest"
	forestFolder.Parent = parent

	local buildingWidth = gridWidth * SLOT_SIZE
	local buildingDepth = gridDepth * SLOT_SIZE
	local buildingCenterX = buildingWidth / 2
	local buildingCenterZ = buildingDepth / 2

	local forestRadius = 200
	local minTreeSpacing = 12
	local maxAttempts = 1500 -- total tree placement attempts

	-- Ground plane for the forest
	local groundSize = forestRadius * 2 + buildingWidth
	makePart(forestFolder, "ForestGround",
		Vector3.new(groundSize, 1, groundSize),
		Vector3.new(buildingCenterX, -0.5, buildingCenterZ),
		Enum.Material.Grass,
		Color3.fromRGB(60, 80, 40) -- dark forest grass
	)

	-- Place trees using rejection sampling
	local placedTrees = {} -- {x, z} positions

	local function isTooClose(x, z)
		-- Don't place inside or too close to the building
		local margin = 10
		if x > -margin and x < buildingWidth + margin and z > -margin and z < buildingDepth + margin then
			return true
		end
		-- Don't place too close to other trees
		for _, tree in placedTrees do
			local dx = x - tree.x
			local dz = z - tree.z
			if dx * dx + dz * dz < minTreeSpacing * minTreeSpacing then
				return true
			end
		end
		return false
	end

	for _ = 1, maxAttempts do
		local angle = rng:NextNumber() * math.pi * 2
		local dist = 20 + rng:NextNumber() * (forestRadius - 20) -- min 20 studs from center
		local x = buildingCenterX + math.cos(angle) * dist
		local z = buildingCenterZ + math.sin(angle) * dist

		if isTooClose(x, z) then continue end

		table.insert(placedTrees, { x = x, z = z })

		-- Tree trunk
		local trunkHeight = 8 + rng:NextNumber() * 8
		local trunkRadius = 1 + rng:NextNumber() * 0.5
		local trunk = makePart(forestFolder, "Trunk",
			Vector3.new(trunkRadius * 2, trunkHeight, trunkRadius * 2),
			Vector3.new(x, trunkHeight / 2, z),
			Enum.Material.WoodPlanks,
			Color3.fromRGB(80 + rng:NextInteger(0, 20), 55 + rng:NextInteger(0, 15), 30 + rng:NextInteger(0, 10))
		)
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Orientation = Vector3.new(0, 0, 90) -- cylinders default horizontal, rotate vertical

		-- Tree canopy (cone or ball)
		local canopySize = 8 + rng:NextNumber() * 6
		local canopyY = trunkHeight + canopySize / 2 - 2
		local canopy = makePart(forestFolder, "Canopy",
			Vector3.new(canopySize, canopySize * 1.2, canopySize),
			Vector3.new(x, canopyY, z),
			Enum.Material.Grass,
			Color3.fromRGB(30 + rng:NextInteger(0, 30), 60 + rng:NextInteger(0, 30), 20 + rng:NextInteger(0, 20))
		)
		canopy.Shape = Enum.PartType.Ball
		canopy.CanCollide = false -- let NPCs walk under canopy edges
	end

	print(("[MapGenerator] Placed %d trees"):format(#placedTrees))
	return forestFolder
end
```

**Step 2: Wire into `generate`**

```lua
	-- Step 11: Build forest
	buildForest(generatedParts, gridWidth, gridDepth, rng)
```

**Step 3: Verify**

Regenerate. You should see trees surrounding the asylum with no trees inside the building footprint. The ground should be green grass.

---

### Task 12: Rain Effect

**Files:**
- Modify: `MapGenerator.lua`

**Step 1: Add rain particle emitter**

Add after `buildForest`:

```lua
--- Create rain particle effect over the map
local function buildRain(parent: Instance, gridWidth: number, gridDepth: number)
	local rainFolder = Instance.new("Folder")
	rainFolder.Name = "Rain"
	rainFolder.Parent = parent

	local buildingWidth = gridWidth * SLOT_SIZE
	local buildingDepth = gridDepth * SLOT_SIZE
	local coverageSize = 500 -- cover forest area too

	-- Invisible part high above the map that emits rain
	local emitterPart = Instance.new("Part")
	emitterPart.Name = "RainEmitter"
	emitterPart.Size = Vector3.new(coverageSize, 1, coverageSize)
	emitterPart.Position = Vector3.new(buildingWidth / 2, 80, buildingDepth / 2)
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.Transparency = 1
	emitterPart.Parent = rainFolder

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Rain"
	emitter.Rate = 500
	emitter.Lifetime = NumberRange.new(2, 3)
	emitter.Speed = NumberRange.new(40, 50)
	emitter.SpreadAngle = Vector2.new(5, 5)
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Color = ColorSequence.new(Color3.fromRGB(180, 190, 200))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 0
	emitter.LightInfluence = 1
	emitter.Parent = emitterPart

	return rainFolder
end
```

**Step 2: Wire into `generate`**

```lua
	-- Step 12: Add rain
	buildRain(generatedParts, gridWidth, gridDepth)
```

**Step 3: Verify**

Regenerate. Rain particles should fall across the entire map area. They should be subtle bluish-white streaks.

---

### Task 13: Multi-Floor Pathfinding

**Files:**
- Modify: `Pathfinding.lua`

**Step 1: Add `findPathMultiFloor` function**

Add before `return Pathfinding` at the end of `Pathfinding.lua`:

```lua
--- Find a path that can traverse multiple floors via stairwell connections
--- @param startPos Vector3 -- World position to start from
--- @param targetPos Vector3 -- World position to reach
--- @param floorConnections { [number]: { Vector3 } } -- Stairwell positions per floor (from MapGenerator.getFloorConnections())
--- @param floorHeight number? -- Height of each floor in studs (default 16)
--- @return { Vector3 }? -- Array of waypoints across floors, or nil if no path found
function Pathfinding.findPathMultiFloor(startPos: Vector3, targetPos: Vector3, floorConnections: { [number]: { Vector3 } }, floorHeight: number?): { Vector3 }?
	floorHeight = floorHeight or 16

	-- Determine which floor each position is on (1-indexed)
	local startFloor = math.max(1, math.floor(startPos.Y / floorHeight) + 1)
	local targetFloor = math.max(1, math.floor(targetPos.Y / floorHeight) + 1)

	-- Same floor: just use regular pathfinding
	if startFloor == targetFloor then
		return Pathfinding.findPath(startPos, targetPos)
	end

	-- Different floors: build path through stairwells
	local fullPath = {}
	local direction = targetFloor > startFloor and 1 or -1

	local currentPos = startPos

	for floor = startFloor, targetFloor - direction, direction do
		local nextFloor = floor + direction

		-- Find stairwell on current floor
		local stairwells = floorConnections[floor]
		if not stairwells or #stairwells == 0 then
			warn(("[Pathfinding] No stairwell on floor %d"):format(floor))
			return nil
		end

		-- Find closest stairwell to current position
		local bestStair = stairwells[1]
		local bestDist = (currentPos - bestStair).Magnitude
		for _, stair in stairwells do
			local dist = (currentPos - stair).Magnitude
			if dist < bestDist then
				bestDist = dist
				bestStair = stair
			end
		end

		-- Path from current position to stairwell on this floor
		local pathToStair = Pathfinding.findPath(currentPos, bestStair)
		if not pathToStair then
			warn(("[Pathfinding] Cannot reach stairwell on floor %d"):format(floor))
			return nil
		end

		-- Add path to stairwell (skip first point if we already have points, to avoid duplicate)
		local startIdx = #fullPath > 0 and 2 or 1
		for i = startIdx, #pathToStair do
			table.insert(fullPath, pathToStair[i])
		end

		-- Add stair traversal waypoints (vertical movement through stairwell)
		local stairBottomY = (math.min(floor, nextFloor) - 1) * floorHeight
		local stairTopY = math.max(floor, nextFloor) * floorHeight - floorHeight
		local numStairPoints = 4
		local stairStartY = (floor - 1) * floorHeight
		local stairEndY = (nextFloor - 1) * floorHeight

		for s = 1, numStairPoints do
			local t = s / numStairPoints
			local y = stairStartY + (stairEndY - stairStartY) * t
			table.insert(fullPath, Vector3.new(bestStair.X, y, bestStair.Z))
		end

		-- Update current position to stairwell position on next floor
		local nextFloorStairs = floorConnections[nextFloor]
		if nextFloorStairs and #nextFloorStairs > 0 then
			currentPos = nextFloorStairs[1] -- stairwell aligns vertically
		end
	end

	-- Final segment: stairwell on target floor to target position
	local pathToTarget = Pathfinding.findPath(currentPos, targetPos)
	if not pathToTarget then
		warn(("[Pathfinding] Cannot reach target from stairwell on floor %d"):format(targetFloor))
		return nil
	end

	-- Append (skip first to avoid duplicate with stair exit point)
	for i = 2, #pathToTarget do
		table.insert(fullPath, pathToTarget[i])
	end

	return fullPath
end
```

**Step 2: Verify**

```lua
-- After generating a map:
local MG = require(game.ReplicatedStorage.MapGenerator)
local Pathfinding = require(game.ReplicatedStorage.Pathfinding)
MG.cleanup()
local data = MG.generate({ floors = 2, gridWidth = 8, gridDepth = 6, seed = 42 })
local connections = MG.getFloorConnections()
print("Floor connections:")
for floor, stairs in connections do
    for _, pos in stairs do
        print(("  Floor %d: %s"):format(floor, tostring(pos)))
    end
end
-- Test a cross-floor path (positions will depend on the generated layout)
local startPos = Vector3.new(50, 0, 50)
local targetPos = Vector3.new(50, 16, 50)
local path = Pathfinding.findPathMultiFloor(startPos, targetPos, connections)
if path then
    print("Multi-floor path found with", #path, "waypoints")
    Pathfinding.visualize(path, 10)
else
    print("No multi-floor path found")
end
```
Expected: A path that goes from floor 1 to the stairwell, up the stairs, then to the target on floor 2. Visualization should show the path crossing floors.

---

### Task 14: Final Integration — Wire Everything Together

**Files:**
- Modify: `MapGenerator.lua` (ensure all steps are in correct order in `generate`)

**Step 1: Verify the complete `generate` function flow**

The final `MapGenerator.generate` function should execute these steps in order:

```
1. Initialize RNG and map data
2. Place stairwell on all floors
3. Place lobby on floor 1
4. Grow hallways from stairwell on each floor
5. Fill empty slots with rooms on each floor
6. Carve doors between adjacent rooms on each floor
7. Ensure solvability via flood fill on each floor
8. Apply condition overlays on each floor
9. Place furniture on each floor
10. Build physical parts (floors, walls, ceilings, stairs)
11. Build exterior shell
12. Build forest
13. Add rain
14. Return mapData
```

**Step 2: Verify full generation**

```lua
local MG = require(game.ReplicatedStorage.MapGenerator)
MG.cleanup()
local data = MG.generate({ floors = 2, gridWidth = 8, gridDepth = 6, seed = 42 })
print("Generation complete!")
print("Floors:", data.floorCount)
print("Stairwell:", data.stairwellPos.x, data.stairwellPos.z)
for i = 1, data.floorCount do
    print(("Floor %d: %d rooms"):format(i, #data.floors[i].rooms))
end
print("Total parts:", #workspace.GeneratedMap:GetDescendants())
```

**Step 3: Test with different seeds**

```lua
-- Run several times to verify variety
for _, seed in {1, 42, 100, 999, 54321} do
    MG.cleanup()
    MG.generate({ floors = 2, gridWidth = 8, gridDepth = 6, seed = seed })
    task.wait(2) -- pause to visually inspect
end
```

**Step 4: Test pathfinding integration**

```lua
local Pathfinding = require(game.ReplicatedStorage.Pathfinding)
local connections = MG.getFloorConnections()

-- Test same-floor path
local p1 = Pathfinding.findPath(Vector3.new(20, 0, 20), Vector3.new(100, 0, 80))
if p1 then
    print("Same-floor path:", #p1, "waypoints")
    Pathfinding.visualize(p1, 5)
end

-- Test cross-floor path
local p2 = Pathfinding.findPathMultiFloor(Vector3.new(20, 0, 20), Vector3.new(100, 16, 80), connections)
if p2 then
    print("Cross-floor path:", #p2, "waypoints")
    Pathfinding.visualize(p2, 5)
end
```

Expected: Both paths should be visualized. The cross-floor path should traverse through the stairwell.

---

### Summary

| Task | What it builds | File(s) |
|------|---------------|---------|
| 1 | Room template data (9 types with weights, furniture, conditions) | `RoomTemplates.lua` |
| 2 | MapGenerator skeleton (grid, RNG, public API stubs) | `MapGenerator.lua` |
| 3 | Stairwell + lobby placement | `MapGenerator.lua` |
| 4 | Hallway growing algorithm | `MapGenerator.lua` |
| 5 | Room filling with weighted random selection | `MapGenerator.lua` |
| 6 | Door carving + flood-fill solvability | `MapGenerator.lua` |
| 7 | Condition overlays + furniture data | `MapGenerator.lua` |
| 8 | Physical parts: floors, walls, ceilings, stairs | `MapGenerator.lua` |
| 9 | Furniture part building | `MapGenerator.lua` |
| 10 | Exterior shell: outer walls, entrance, roof | `MapGenerator.lua` |
| 11 | Forest generation with tree placement | `MapGenerator.lua` |
| 12 | Rain particle effect | `MapGenerator.lua` |
| 13 | Multi-floor pathfinding | `Pathfinding.lua` |
| 14 | Full integration verification | All files |
