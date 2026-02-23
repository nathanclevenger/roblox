-- RoomTemplates.lua
-- Preset room definitions for the asylum map generator
-- Place as a ModuleScript in ReplicatedStorage

local RoomTemplates = {}

-- All templates use grid units (1 unit = 24 studs = one grid slot)
-- doorPositions: which edges CAN have a door (actual doors carved by generator)
-- weight: relative probability of being chosen during room filling (0 = not randomly placed)
-- furnitureSlots: named positions as {name, x, z} offsets within the room (in studs, relative to room origin)
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
		doorPositions = { "north", "south" }, -- stairs run along Z axis
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
--- @return { { template: any, weight: number } }
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
--- @param rng Random -- A Roblox Random object for deterministic selection
--- @return any -- The selected room template table
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

	-- Fallback: return last entry (should not normally be reached)
	return list[#list].template
end

return RoomTemplates
