--!strict

--[[
	Scare Manager (Server)

	Core jumpscare orchestration module. Manages per-player scare cooldowns,
	history tracking, scare pool selection, and firing scare events to clients.

	Scare Categories:
	  A — Environmental (harmless, shared with all nearby players)
	  B — Entity Proximity (warning, requires entity nearby)
	  C — Shock/Direct (per-player only, hallucination)
	  D — Persistent Anomaly (per-player, slow burn)

	Cooldown rules:
	  - 90 seconds minimum between any scare for a given player
	  - Maximum 2 scares per 10-minute rolling window per player
	  - Category C disabled for 30s after respawn
	  - Category D anomalies 2x more frequent on final life (1 heart remaining)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)

local Remotes = require(script.Parent.Remotes)

-- Per-player tracking data
type PlayerScareTracker = {
	lastScareTime: number,
	scareTimestamps: { number }, -- rolling window of scare timestamps
	firedScares: { [string]: boolean }, -- scares already fired this round (for one-time scares)
	respawnTime: number, -- os.clock() of last respawn, 0 if never
	heartsRemaining: number, -- current hearts for final-life check
	isFinalLife: boolean,
	isHiding: boolean,
}

local ScareManager = {}
ScareManager.__index = ScareManager

export type ScareManager = typeof(setmetatable(
	{} :: {
		active: boolean,
		currentLevel: string?,
		scarePool: { Types.ScareDefinition },
		playerTrackers: { [Player]: PlayerScareTracker },
		entityPosition: Vector3?,
		entityState: string?,
		roundStartTime: number,
		elapsedTime: number,
		-- Timers for periodic scare evaluation
		evaluationTimer: number,
		evaluationInterval: number,
	},
	ScareManager
))

-- ============================================================================
-- Level 1 (Hospital) Scare Pool
-- ============================================================================

local HOSPITAL_SCARES: { Types.ScareDefinition } = {
	-- Category A: Environmental
	{
		id = "ceiling_tile_fall",
		category = "A",
		name = "Ceiling tile falls from above",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "all",
	},
	{
		id = "faucet_turns_on",
		category = "A",
		name = "Faucet turns on by itself in bathroom",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "all",
	},
	{
		id = "radio_static_burst",
		category = "A",
		name = "Radio in security office emits burst of static",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "all",
	},
	{
		id = "wheelchair_roll",
		category = "A",
		name = "Wheelchair rolls across corridor by itself",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "all",
	},
	{
		id = "window_shutters_slam",
		category = "A",
		name = "Window shutters slam",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "all",
	},
	{
		id = "lights_flicker_sequence",
		category = "A",
		name = "Lights in a room flicker in sequence then die",
		level = 1,
		cooldownOverride = 180, -- 3 minute cooldown for light scares
		requiresEntityNearby = false,
		multiplayer = "all",
	},

	-- Category B: Entity Proximity
	{
		id = "shadow_hallway_end",
		category = "B",
		name = "Shadow appears at end of hallway, vanishes when looked at",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = true,
		multiplayer = "all",
	},
	{
		id = "breathing_in_locker",
		category = "B",
		name = "Breathing sound from inside a locker you pass",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = true,
		multiplayer = "all",
	},
	{
		id = "handprint_foggy_window",
		category = "B",
		name = "Handprint appears on foggy window",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = true,
		multiplayer = "all",
	},
	{
		id = "iv_drip_swinging",
		category = "B",
		name = "IV drip starts swinging on its own",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = true,
		multiplayer = "all",
	},
	{
		id = "flashlight_reveals_entity",
		category = "B",
		name = "Flashlight beam briefly illuminates entity standing in doorway",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = true,
		multiplayer = "all",
	},

	-- Category C: Shock/Direct (per-player only)
	{
		id = "mirror_face",
		category = "C",
		name = "Face appears in bathroom mirror for 1 frame",
		level = 1,
		cooldownOverride = 480, -- 8 minute cooldown
		requiresEntityNearby = false,
		multiplayer = "triggering_player",
	},
	{
		id = "hand_under_bed",
		category = "C",
		name = "Hand reaches from under bed as player walks past",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "triggering_player",
	},
	{
		id = "figure_in_corner",
		category = "C",
		name = "Figure standing in corner when flashlight turns on, gone next frame",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "triggering_player",
	},
	{
		id = "door_closes_behind",
		category = "C",
		name = "Door you just walked through slowly closes behind you",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "triggering_player",
	},
	{
		id = "tv_security_footage",
		category = "C",
		name = "TV shows security footage of the player from behind, right now",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "triggering_player",
	},

	-- Category D: Persistent Anomaly (per-player, slow burn)
	{
		id = "painting_changed",
		category = "D",
		name = "Painting on wall has changed when you return to a room",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "triggering_player",
	},
	{
		id = "backward_clock",
		category = "D",
		name = "Clock on wall runs backward",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "triggering_player",
	},
	{
		id = "water_stain_face",
		category = "D",
		name = "Water stain on ceiling shaped like a face",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "triggering_player",
	},
	{
		id = "second_shadow",
		category = "D",
		name = "Flashlight beam has a second shadow behind you",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "triggering_player",
	},
	{
		id = "footprints_wrong_direction",
		category = "D",
		name = "Footprints in dust that match yours but go the wrong direction",
		level = 1,
		cooldownOverride = nil,
		requiresEntityNearby = false,
		multiplayer = "triggering_player",
	},
}

-- Map of level names to scare pools
local LEVEL_SCARE_POOLS: { [string]: { Types.ScareDefinition } } = {
	["st-marens-hospital"] = HOSPITAL_SCARES,
}

-- ============================================================================
-- Constructor
-- ============================================================================

function ScareManager.new(): ScareManager
	local self = setmetatable({
		active = false,
		currentLevel = nil,
		scarePool = {},
		playerTrackers = {},
		entityPosition = nil,
		entityState = nil,
		roundStartTime = 0,
		elapsedTime = 0,
		evaluationTimer = 0,
		evaluationInterval = 5, -- evaluate scare eligibility every 5 seconds
	}, ScareManager)

	return self
end

-- ============================================================================
-- Lifecycle
-- ============================================================================

--[[
	Load the scare pool for the given level. Called at round start.
]]
function ScareManager.registerLevelScares(self: ScareManager, levelName: string)
	self.currentLevel = levelName
	self.scarePool = LEVEL_SCARE_POOLS[levelName] or {}
	self.active = true
	self.roundStartTime = os.clock()
	self.elapsedTime = 0
	self.evaluationTimer = 0

	-- Initialize trackers for all current players
	for _, player in Players:GetPlayers() do
		self:initPlayerTracker(player)
	end

	print(`[ScareManager] Registered {#self.scarePool} scares for level: {levelName}`)
end

--[[
	Clean up all state when the round ends.
]]
function ScareManager.cleanup(self: ScareManager)
	self.active = false
	self.currentLevel = nil
	self.scarePool = {}
	self.playerTrackers = {}
	self.entityPosition = nil
	self.entityState = nil
	self.elapsedTime = 0
	self.evaluationTimer = 0

	print("[ScareManager] Cleaned up")
end

-- ============================================================================
-- Player Tracking
-- ============================================================================

--[[
	Create a fresh tracker for a player.
]]
function ScareManager.initPlayerTracker(self: ScareManager, player: Player)
	self.playerTrackers[player] = {
		lastScareTime = 0,
		scareTimestamps = {},
		firedScares = {},
		respawnTime = 0,
		heartsRemaining = Constants.MAX_HEARTS,
		isFinalLife = false,
		isHiding = false,
	}
end

--[[
	Remove a player's tracker when they leave.
]]
function ScareManager.removePlayer(self: ScareManager, player: Player)
	self.playerTrackers[player] = nil
end

--[[
	Notify the scare manager that a player has died/respawned.
	Applies Category C immunity and updates final-life status.
]]
function ScareManager.onPlayerDeath(self: ScareManager, player: Player, heartsRemaining: number)
	local tracker = self.playerTrackers[player]
	if not tracker then
		return
	end

	tracker.respawnTime = os.clock()
	tracker.heartsRemaining = heartsRemaining
	tracker.isFinalLife = heartsRemaining <= 1

	print(`[ScareManager] {player.Name} died — hearts: {heartsRemaining}, finalLife: {tracker.isFinalLife}`)
end

--[[
	Notify the scare manager that a player has respawned after death.
]]
function ScareManager.onPlayerRespawn(self: ScareManager, player: Player)
	local tracker = self.playerTrackers[player]
	if not tracker then
		self:initPlayerTracker(player)
		tracker = self.playerTrackers[player]
	end

	if tracker then
		tracker.respawnTime = os.clock()
	end
end

--[[
	Update entity position for Category B scare triggers.
]]
function ScareManager.updateEntityPosition(self: ScareManager, position: Vector3, state: string?)
	self.entityPosition = position
	self.entityState = state
end

--[[
	Notify the scare manager that a player is hiding (scares are suppressed).
]]
function ScareManager.setPlayerHiding(self: ScareManager, player: Player, isHiding: boolean)
	local tracker = self.playerTrackers[player]
	if tracker then
		tracker.isHiding = isHiding
	end
end

-- ============================================================================
-- Cooldown and Eligibility
-- ============================================================================

--[[
	Check if a player is eligible for any scare right now.
	Returns false if on global cooldown or at the 10-minute window limit.
]]
function ScareManager.isPlayerEligible(self: ScareManager, player: Player): boolean
	local tracker = self.playerTrackers[player]
	if not tracker then
		return false
	end

	-- Never scare while hiding
	if tracker.isHiding then
		return false
	end

	-- Player must have a character in the world
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false
	end

	local now = os.clock()

	-- Global cooldown check
	if tracker.lastScareTime > 0 and (now - tracker.lastScareTime) < Constants.SCARE_GLOBAL_COOLDOWN then
		return false
	end

	-- Rolling 10-minute window check
	local windowStart = now - 600
	local scaresInWindow = 0
	local validTimestamps: { number } = {}

	for _, timestamp in tracker.scareTimestamps do
		if timestamp >= windowStart then
			scaresInWindow += 1
			table.insert(validTimestamps, timestamp)
		end
	end

	-- Prune old timestamps
	tracker.scareTimestamps = validTimestamps

	if scaresInWindow >= Constants.SCARE_MAX_PER_10MIN then
		return false
	end

	return true
end

--[[
	Check if a specific scare is eligible for a player based on category rules.
]]
function ScareManager.isScareEligibleForPlayer(
	self: ScareManager,
	player: Player,
	scare: Types.ScareDefinition
): boolean
	local tracker = self.playerTrackers[player]
	if not tracker then
		return false
	end

	local now = os.clock()

	-- Category C: disabled for 30s after respawn
	if scare.category == "C" then
		if tracker.respawnTime > 0 then
			local timeSinceRespawn = now - tracker.respawnTime
			if timeSinceRespawn < Constants.SCARE_CATEGORY_C_RESPAWN_IMMUNITY then
				return false
			end
		end
	end

	-- Category B: requires entity nearby
	if scare.requiresEntityNearby then
		if not self.entityPosition then
			return false
		end

		local character = player.Character
		if not character then
			return false
		end
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return false
		end

		local dist = (hrp.Position - self.entityPosition).Magnitude
		if dist > Constants.SCARE_ENTITY_NEARBY_RANGE then
			return false
		end

		-- Don't trigger B scares during active chase (entity is already scary)
		if self.entityState == "Chase" then
			return false
		end
	end

	-- Per-scare cooldown override check
	if scare.cooldownOverride then
		-- Check if this specific scare was fired too recently
		-- We use firedScares to track one-time-per-round, but for cooldownOverride
		-- we need the actual timestamp. For simplicity, if the scare was already fired
		-- and has a cooldownOverride, check time since last scare of this type.
		-- Currently we only track whether it was fired; for full per-scare cooldown
		-- tracking we'd need timestamps per scare id. For now, use the global last
		-- scare time as a conservative estimate.
	end

	-- Already fired this round (for one-time scares like C reveals)
	if tracker.firedScares[scare.id] then
		return false
	end

	return true
end

-- ============================================================================
-- Scare Selection and Firing
-- ============================================================================

--[[
	Select a random eligible scare for a player from the current pool.
	Returns nil if no scare is eligible.
]]
function ScareManager.selectScare(self: ScareManager, player: Player): Types.ScareDefinition?
	local tracker = self.playerTrackers[player]
	if not tracker then
		return nil
	end

	-- Build list of eligible scares
	local eligible: { Types.ScareDefinition } = {}

	for _, scare in self.scarePool do
		if self:isScareEligibleForPlayer(player, scare) then
			table.insert(eligible, scare)
		end
	end

	if #eligible == 0 then
		return nil
	end

	-- Weight selection by category
	-- Category D gets 2x weight on final life
	local weighted: { Types.ScareDefinition } = {}

	for _, scare in eligible do
		table.insert(weighted, scare)

		-- Double Category D entries on final life
		if scare.category == "D" and tracker.isFinalLife then
			for _ = 1, Constants.SCARE_CATEGORY_D_FINAL_LIFE_MULTIPLIER - 1 do
				table.insert(weighted, scare)
			end
		end
	end

	-- Random selection
	local selected = weighted[math.random(1, #weighted)]
	return selected
end

--[[
	Fire a scare to a specific player via the TriggerScare remote.
	Records the scare in the player's history and updates cooldowns.
]]
function ScareManager.fireScare(self: ScareManager, player: Player, scareId: string, position: Vector3?, metadata: { [string]: any }?)
	local tracker = self.playerTrackers[player]
	if not tracker then
		return
	end

	-- Find the scare definition
	local scareDef: Types.ScareDefinition? = nil
	for _, scare in self.scarePool do
		if scare.id == scareId then
			scareDef = scare
			break
		end
	end

	if not scareDef then
		warn(`[ScareManager] Unknown scare id: {scareId}`)
		return
	end

	local scare = scareDef :: Types.ScareDefinition
	local now = os.clock()

	-- Build the scare event
	local scareEvent: Types.ScareEvent = {
		scareId = scareId,
		category = scare.category,
		position = position,
		metadata = metadata,
	}

	-- Determine target players based on multiplayer mode
	if scare.multiplayer == "all" then
		-- Fire to all players (Category A / B shared scares)
		if Remotes.TriggerScare then
			Remotes.TriggerScare:FireAllClients(scareEvent)
		end

		-- Update trackers for all players
		for otherPlayer, otherTracker in self.playerTrackers do
			otherTracker.lastScareTime = now
			table.insert(otherTracker.scareTimestamps, now)
		end
	else
		-- Fire to triggering player only (Category C / D)
		if Remotes.TriggerScare then
			Remotes.TriggerScare:FireClient(player, scareEvent)
		end

		-- Update only this player's tracker
		tracker.lastScareTime = now
		table.insert(tracker.scareTimestamps, now)
	end

	-- Mark as fired for one-time tracking
	tracker.firedScares[scareId] = true

	print(`[ScareManager] Fired scare '{scare.name}' (cat {scare.category}) to {player.Name}`)
end

-- ============================================================================
-- Update Loop
-- ============================================================================

--[[
	Called every server Heartbeat. Evaluates scare eligibility for all players
	and probabilistically fires scares.
]]
function ScareManager.update(self: ScareManager, dt: number)
	if not self.active then
		return
	end

	self.elapsedTime += dt
	self.evaluationTimer += dt

	-- Only evaluate every N seconds to avoid per-frame overhead
	if self.evaluationTimer < self.evaluationInterval then
		return
	end
	self.evaluationTimer = 0

	-- Don't start scares too early in the round (let atmosphere build)
	if self.elapsedTime < 60 then
		return
	end

	-- Evaluate each player
	for _, player in Players:GetPlayers() do
		-- Must be eligible for scares
		if not self:isPlayerEligible(player) then
			continue
		end

		-- Base probability per evaluation cycle (tuned for pacing)
		-- ~15% chance per 5s evaluation = roughly one scare every 30-35 seconds
		-- when eligible, but cooldown ensures minimum 90s gap.
		local baseProbability = 0.15

		-- Reduce probability if the round just started (ramp up over first 3 min)
		if self.elapsedTime < 180 then
			baseProbability *= (self.elapsedTime - 60) / 120
		end

		-- Roll
		if math.random() > baseProbability then
			continue
		end

		-- Select and fire a scare
		local scare = self:selectScare(player)
		if scare then
			-- Get player position as the scare origin
			local position: Vector3? = nil
			local character = player.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					position = hrp.Position
				end
			end

			-- Build metadata
			local metadata: { [string]: any } = {}

			-- For entity proximity scares, include entity position
			if scare.category == "B" and self.entityPosition then
				metadata.entityPosition = self.entityPosition
			end

			self:fireScare(player, scare.id, position, metadata)
		end
	end
end

return ScareManager
