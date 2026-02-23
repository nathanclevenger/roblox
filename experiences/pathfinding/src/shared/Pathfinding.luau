-- Pathfinding Module using A* Algorithm for Roblox
-- Place this as a ModuleScript in ReplicatedStorage or ServerStorage

local Pathfinding = {}

-- Configuration
local GRID_SIZE = 4 -- Size of each grid cell in studs
local MAX_ITERATIONS = 5000 -- Safety limit to prevent infinite loops
local DIRECTIONS = {
	Vector3.new(1, 0, 0),
	Vector3.new(-1, 0, 0),
	Vector3.new(0, 0, 1),
	Vector3.new(0, 0, -1),
	Vector3.new(1, 0, 1),
	Vector3.new(-1, 0, 1),
	Vector3.new(1, 0, -1),
	Vector3.new(-1, 0, -1),
}

-- Snap a world position to the nearest grid cell
local function toGrid(position: Vector3): Vector3
	return Vector3.new(
		math.round(position.X / GRID_SIZE) * GRID_SIZE,
		math.round(position.Y / GRID_SIZE) * GRID_SIZE,
		math.round(position.Z / GRID_SIZE) * GRID_SIZE
	)
end

-- Convert a Vector3 to a string key for table lookups
local function toKey(position: Vector3): string
	return position.X .. "," .. position.Y .. "," .. position.Z
end

-- Heuristic: Euclidean distance to the target
local function heuristic(a: Vector3, b: Vector3): number
	return (a - b).Magnitude
end

-- Check if a grid cell is walkable using a raycast
local function isWalkable(position: Vector3): boolean
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {}
	rayParams.RespectCanCollide = true -- ignore non-collidable parts (trim, decor)

	-- Check for ground below this cell
	local origin = position + Vector3.new(0, 8, 0)
	local direction = Vector3.new(0, -12, 0)
	local result = workspace:Raycast(origin, direction, rayParams)

	if result then
		-- There's ground here — now check for blocking obstacles above ground
		-- Start above typical step height, check up to humanoid head height
		local groundY = result.Position.Y
		local obstacleOrigin = Vector3.new(position.X, groundY + 2, position.Z)
		local obstacleDirection = Vector3.new(0, 3, 0) -- Check 2-5 studs above ground
		local obstacleResult = workspace:Raycast(obstacleOrigin, obstacleDirection, rayParams)

		if obstacleResult then
			return false -- Something blocking overhead
		end

		return true
	end

	return false -- No ground found
end

-- MinHeap for the open set (priority queue)
local MinHeap = {}
MinHeap.__index = MinHeap

function MinHeap.new()
	return setmetatable({ data = {} }, MinHeap)
end

function MinHeap:push(node)
	table.insert(self.data, node)
	local i = #self.data
	while i > 1 do
		local parent = math.floor(i / 2)
		if self.data[i].f < self.data[parent].f then
			self.data[i], self.data[parent] = self.data[parent], self.data[i]
			i = parent
		else
			break
		end
	end
end

function MinHeap:pop()
	local top = self.data[1]
	local last = table.remove(self.data)
	if #self.data > 0 then
		self.data[1] = last
		local i = 1
		while true do
			local smallest = i
			local left = 2 * i
			local right = 2 * i + 1
			if left <= #self.data and self.data[left].f < self.data[smallest].f then
				smallest = left
			end
			if right <= #self.data and self.data[right].f < self.data[smallest].f then
				smallest = right
			end
			if smallest ~= i then
				self.data[i], self.data[smallest] = self.data[smallest], self.data[i]
				i = smallest
			else
				break
			end
		end
	end
	return top
end

function MinHeap:isEmpty(): boolean
	return #self.data == 0
end

-- Reconstruct the path by walking back through the cameFrom table
local function reconstructPath(cameFrom, current: Vector3): { Vector3 }
	local path = { current }
	local key = toKey(current)
	while cameFrom[key] do
		current = cameFrom[key]
		key = toKey(current)
		table.insert(path, 1, current)
	end
	return path
end

--- Find a path from start to target using A*
--- @param startPos Vector3 -- World position to start from
--- @param targetPos Vector3 -- World position to reach
--- @return { Vector3 }? -- Array of waypoints, or nil if no path found
function Pathfinding.findPath(startPos: Vector3, targetPos: Vector3): { Vector3 }?
	local start = toGrid(startPos)
	local goal = toGrid(targetPos)

	local openSet = MinHeap.new()
	local closedSet = {}
	local cameFrom = {}
	local gScore = {}

	local startKey = toKey(start)
	gScore[startKey] = 0

	openSet:push({
		position = start,
		f = heuristic(start, goal),
	})

	local iterations = 0

	while not openSet:isEmpty() do
		iterations += 1
		if iterations > MAX_ITERATIONS then
			warn("[Pathfinding] Exceeded max iterations, no path found.")
			return nil
		end

		local current = openSet:pop()
		local currentKey = toKey(current.position)

		-- Reached the goal
		if current.position == goal then
			return reconstructPath(cameFrom, current.position)
		end

		-- Skip if already processed
		if closedSet[currentKey] then
			continue
		end
		closedSet[currentKey] = true

		-- Explore neighbors
		for _, dir in DIRECTIONS do
			local neighborPos = current.position + dir * GRID_SIZE
			local neighborKey = toKey(neighborPos)

			if not closedSet[neighborKey] and isWalkable(neighborPos) then
				local moveCost = dir.Magnitude * GRID_SIZE -- Diagonal costs more
				local tentativeG = gScore[currentKey] + moveCost

				if not gScore[neighborKey] or tentativeG < gScore[neighborKey] then
					gScore[neighborKey] = tentativeG
					cameFrom[neighborKey] = current.position

					openSet:push({
						position = neighborPos,
						f = tentativeG + heuristic(neighborPos, goal),
					})
				end
			end
		end
	end

	warn("[Pathfinding] No path found to target.")
	return nil
end

--- Smooth a path by removing unnecessary waypoints (line-of-sight simplification)
--- Then interpolates between remaining points with Catmull-Rom for curved movement
--- @param path { Vector3 } -- The raw A* path
--- @param subdivisions number? -- Points to insert between each pair (default 4)
--- @return { Vector3 } -- The smoothed path
function Pathfinding.smoothPath(path: { Vector3 }, subdivisions: number?): { Vector3 }
	if #path <= 2 then
		return path
	end

	subdivisions = subdivisions or 4

	-- Step 1: Line-of-sight simplification — skip waypoints we can walk straight past
	local simplified = { path[1] }
	local current = 1

	while current < #path do
		local farthest = current + 1

		-- Look ahead as far as possible with clear line-of-sight
		for check = #path, current + 2, -1 do
			local origin = path[current] + Vector3.new(0, 2, 0)
			local dir = (path[check] + Vector3.new(0, 2, 0)) - origin

			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = {}

			local result = workspace:Raycast(origin, dir, rayParams)
			if not result then
				farthest = check
				break
			end
		end

		table.insert(simplified, path[farthest])
		current = farthest
	end

	if #simplified <= 2 then
		return simplified
	end

	-- Step 2: Catmull-Rom spline interpolation for smooth curves
	local smoothed = {}

	for i = 1, #simplified do
		local p0 = simplified[math.max(i - 1, 1)]
		local p1 = simplified[i]
		local p2 = simplified[math.min(i + 1, #simplified)]
		local p3 = simplified[math.min(i + 2, #simplified)]

		-- Always include the control point itself
		table.insert(smoothed, p1)

		-- Add interpolated points between p1 and p2 (except for the last segment)
		if i < #simplified then
			for s = 1, subdivisions - 1 do
				local t = s / subdivisions

				-- Catmull-Rom formula
				local t2 = t * t
				local t3 = t2 * t

				local x = 0.5
					* (
						(2 * p1.X)
						+ (-p0.X + p2.X) * t
						+ (2 * p0.X - 5 * p1.X + 4 * p2.X - p3.X) * t2
						+ (-p0.X + 3 * p1.X - 3 * p2.X + p3.X) * t3
					)
				local y = p1.Y -- Keep Y flat to avoid floating/sinking
				local z = 0.5
					* (
						(2 * p1.Z)
						+ (-p0.Z + p2.Z) * t
						+ (2 * p0.Z - 5 * p1.Z + 4 * p2.Z - p3.Z) * t2
						+ (-p0.Z + 3 * p1.Z - 3 * p2.Z + p3.Z) * t3
					)

				table.insert(smoothed, Vector3.new(x, y, z))
			end
		end
	end

	return smoothed
end

--- Pick a random walkable position near an origin (for wandering)
--- @param origin Vector3 -- Center point to wander from
--- @param minRadius number -- Minimum wander distance
--- @param maxRadius number -- Maximum wander distance
--- @param maxAttempts number? -- How many times to try before giving up (default 10)
--- @return Vector3? -- A walkable position, or nil if none found
function Pathfinding.getRandomWalkablePosition(
	origin: Vector3,
	minRadius: number,
	maxRadius: number,
	maxAttempts: number?
): Vector3?
	maxAttempts = maxAttempts or 10

	for _ = 1, maxAttempts do
		local angle = math.random() * math.pi * 2
		local distance = minRadius + math.random() * (maxRadius - minRadius)

		local offset = Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)

		local candidate = toGrid(origin + offset)

		if isWalkable(candidate) then
			return candidate
		end
	end

	return nil
end

--- Check if a path is still valid from a given waypoint index onward
--- @param path { Vector3 } -- The path to validate
--- @param fromIndex number -- The waypoint index to start checking from
--- @return boolean -- True if all remaining waypoints are still walkable
function Pathfinding.isPathValid(path: { Vector3 }, fromIndex: number): boolean
	for i = fromIndex, #path do
		if not isWalkable(path[i]) then
			return false
		end

		-- Check line-of-sight between consecutive waypoints
		if i < #path then
			local origin = path[i] + Vector3.new(0, 2, 0)
			local direction = (path[i + 1] - path[i])
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = {}

			local result = workspace:Raycast(origin, direction, rayParams)
			if result then
				return false -- Something blocking the way between waypoints
			end
		end
	end
	return true
end

--- Visualize a path with small parts (useful for debugging)
--- @param path { Vector3 } -- The path returned by findPath
--- @param duration number? -- How long to show the visualization (default 5 seconds)
function Pathfinding.visualize(path: { Vector3 }, duration: number?)
	duration = duration or 5

	local folder = Instance.new("Folder")
	folder.Name = "PathVisualization"
	folder.Parent = workspace

	for i, waypoint in path do
		local part = Instance.new("Part")
		part.Size = Vector3.new(1, 1, 1)
		part.Position = waypoint + Vector3.new(0, 1, 0)
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Neon
		part.Shape = Enum.PartType.Ball

		-- Color gradient from green (start) to red (end)
		local t = (i - 1) / math.max(#path - 1, 1)
		part.Color = Color3.new(t, 1 - t, 0)

		part.Parent = folder
	end

	task.delay(duration, function()
		folder:Destroy()
	end)
end

--- Find a path across multiple floors by chaining single-floor A* paths through stairwells
--- @param startPos Vector3 -- World position to start from
--- @param targetPos Vector3 -- World position to reach
--- @param floorConnections { [number]: { Vector3 } } -- Floor index to stairwell positions (from MapGenerator.getFloorConnections())
--- @param floorHeight number? -- Height of each floor in studs (default 16)
--- @return { Vector3 }? -- Array of waypoints spanning all floors, or nil on failure
function Pathfinding.findPathMultiFloor(
	startPos: Vector3,
	targetPos: Vector3,
	floorConnections: { [number]: { Vector3 } },
	floorHeight: number?
): { Vector3 }?
	local DEFAULT_FLOOR_HEIGHT = 16
	floorHeight = floorHeight or DEFAULT_FLOOR_HEIGHT

	local STAIR_INTERPOLATION_STEPS = 4

	-- Determine which floor a world position belongs to (1-based)
	local function getFloor(pos: Vector3): number
		return math.max(1, math.floor(pos.Y / floorHeight) + 1)
	end

	local startFloor = getFloor(startPos)
	local targetFloor = getFloor(targetPos)

	-- Same floor: delegate directly to single-floor findPath
	if startFloor == targetFloor then
		return Pathfinding.findPath(startPos, targetPos)
	end

	-- Different floors: chain paths through stairwells
	local direction = targetFloor > startFloor and 1 or -1
	local fullPath: { Vector3 } = {}
	local currentPos = startPos

	for currentFloor = startFloor, targetFloor - direction, direction do
		-- Get stairwell positions on the current floor
		local stairwells = floorConnections[currentFloor]
		if not stairwells or #stairwells == 0 then
			warn(string.format("[Pathfinding] No stairwell on floor %d", currentFloor))
			return nil
		end

		-- Find closest stairwell to current position
		local bestStair: Vector3 = stairwells[1]
		local bestDist = (currentPos - bestStair).Magnitude
		for i = 2, #stairwells do
			local dist = (currentPos - stairwells[i]).Magnitude
			if dist < bestDist then
				bestDist = dist
				bestStair = stairwells[i]
			end
		end

		-- Path from current position to the stairwell on this floor
		local segmentPath = Pathfinding.findPath(currentPos, bestStair)
		if not segmentPath then
			warn(string.format("[Pathfinding] Cannot reach stairwell on floor %d", currentFloor))
			return nil
		end

		-- Append waypoints (skip first point on subsequent segments to avoid duplicates)
		local startIndex = #fullPath > 0 and 2 or 1
		for i = startIndex, #segmentPath do
			table.insert(fullPath, segmentPath[i])
		end

		-- Insert stair-traversal waypoints (linearly interpolated between floors)
		local _nextFloor = currentFloor + direction
		local currentY = bestStair.Y
		local nextY = currentY + (direction * floorHeight)
		for step = 1, STAIR_INTERPOLATION_STEPS do
			local t = step / STAIR_INTERPOLATION_STEPS
			local interpY = currentY + (nextY - currentY) * t
			table.insert(fullPath, Vector3.new(bestStair.X, interpY, bestStair.Z))
		end

		-- Update current position to the stairwell on the next floor
		currentPos = Vector3.new(bestStair.X, nextY, bestStair.Z)
	end

	-- Final segment: path from last stairwell arrival to the target on the target floor
	local finalPath = Pathfinding.findPath(currentPos, targetPos)
	if not finalPath then
		warn(string.format("[Pathfinding] Cannot reach target from stairwell on floor %d", targetFloor))
		return nil
	end

	-- Append final segment (skip first point to avoid duplicate with stair arrival)
	local finalStartIndex = #fullPath > 0 and 2 or 1
	for i = finalStartIndex, #finalPath do
		table.insert(fullPath, finalPath[i])
	end

	return fullPath
end

return Pathfinding
