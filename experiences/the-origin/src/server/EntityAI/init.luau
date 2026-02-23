--!strict

--[[
	EntityAI Controller

	Manages entity lifecycle, delegates to StateMachine for behavior,
	Senses for detection, and AdaptiveBehavior for learning.

	Handles entity-to-player damage dealing, door interaction, and
	hiding spot searches.

	All entity logic runs server-side. Client receives position/state
	for rendering and proximity fear calculations only.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdaptiveBehavior = require(script.AdaptiveBehavior)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Remotes = require(script.Parent.Remotes)
local Senses = require(script.Senses)
local StateMachine = require(script.StateMachine)
local Types = require(ReplicatedStorage.Shared.Types)

local EntityController = {}
EntityController.__index = EntityController

export type EntityController = typeof(setmetatable(
	{} :: {
		active: boolean,
		entityModel: Model?,
		stateMachine: StateMachine.StateMachine,
		senses: Senses.Senses,
		adaptive: AdaptiveBehavior.AdaptiveBehavior,
		profile: Types.EntityProfile,
		position: Vector3,
		currentState: Types.EntityState,
		lastReplicatedState: Types.EntityState,
		-- Damage system
		lastDamageTime: { [Player]: number },
		-- External references (set by GameManager)
		playerStateManager: any,
		doorSystem: any,
		hidingSystem: any,
		-- Hiding spot reveal tracking
		activeHidingChecks: { [string]: { player: Player, startTime: number, spotId: string } },
	},
	EntityController
))

function EntityController.new(): EntityController
	-- Default to The Patient profile for Level 1
	local profile: Types.EntityProfile = {
		name = "The Patient",
		primarySense = "Hearing",
		patrolSpeed = 8,
		chaseSpeed = 20,
		senses = {
			hearingRange = 50,
			visionCone = Constants.ENTITY_VISION_CONE,
			visionRangeLit = Constants.ENTITY_VISION_LIT,
			visionRangeDark = Constants.ENTITY_VISION_DARK,
			flashlightDetectRange = Constants.ENTITY_FLASHLIGHT_DETECT,
			detectionRamp = 1.5,
		},
		checkHidingSpots = true,
		uniqueMechanic = "ElectronicFlatline",
	}

	local self = setmetatable({
		active = false,
		entityModel = nil,
		stateMachine = StateMachine.new(),
		senses = Senses.new(profile.senses),
		adaptive = AdaptiveBehavior.new(),
		profile = profile,
		position = Vector3.zero,
		currentState = "Idle" :: Types.EntityState,
		lastReplicatedState = "Idle" :: Types.EntityState,
		-- Damage system
		lastDamageTime = {},
		-- External references (set by GameManager)
		playerStateManager = nil,
		doorSystem = nil,
		hidingSystem = nil,
		-- Hiding spot reveal tracking
		activeHidingChecks = {},
	}, EntityController)

	-- Wire the onCheckHidingSpots callback on the state machine
	self.stateMachine.onCheckHidingSpots = function(searchPosition: Vector3, radius: number)
		self:checkHidingSpotsNear(searchPosition, radius)
	end

	return self
end

function EntityController.activate(self: EntityController, spawnPosition: Vector3)
	-- Create entity model
	local model = Instance.new("Model")
	model.Name = self.profile.name

	-- Create humanoid-like body
	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(2, 3, 1)
	torso.Position = spawnPosition + Vector3.new(0, 3, 0)
	torso.Anchored = true
	torso.CanCollide = false
	torso.Material = Enum.Material.SmoothPlastic
	torso.Color = Color3.fromRGB(40, 40, 45)
	torso.Transparency = 0.1
	torso.Parent = model

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.Position = spawnPosition + Vector3.new(0, 5, 0)
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(60, 55, 50)
	head.Parent = model

	-- Arms (thin, elongated for horror)
	for _, side in { -1, 1 } do
		local arm = Instance.new("Part")
		arm.Name = if side == -1 then "LeftArm" else "RightArm"
		arm.Size = Vector3.new(0.5, 3.5, 0.5)
		arm.Position = spawnPosition + Vector3.new(side * 1.5, 3, 0)
		arm.Anchored = true
		arm.CanCollide = false
		arm.Material = Enum.Material.SmoothPlastic
		arm.Color = Color3.fromRGB(45, 45, 50)
		arm.Parent = model
	end

	-- Legs
	for _, side in { -1, 1 } do
		local leg = Instance.new("Part")
		leg.Name = if side == -1 then "LeftLeg" else "RightLeg"
		leg.Size = Vector3.new(0.6, 3, 0.6)
		leg.Position = spawnPosition + Vector3.new(side * 0.5, 0.5, 0)
		leg.Anchored = true
		leg.CanCollide = false
		leg.Material = Enum.Material.SmoothPlastic
		leg.Color = Color3.fromRGB(35, 35, 40)
		leg.Parent = model
	end

	model.PrimaryPart = torso
	model.Parent = workspace

	self.entityModel = model
	self.position = spawnPosition
	self.active = true

	-- Clear damage cooldown tracking
	table.clear(self.lastDamageTime)
	table.clear(self.activeHidingChecks)

	-- Initialize state machine for patrol
	self.stateMachine:transition("Patrol")
	self.stateMachine:setPosition(spawnPosition)

	-- Update senses exclude list so raycasts ignore the entity model
	self.senses:setExcludeInstances({ model })

	print(`[EntityAI] {self.profile.name} activated at {spawnPosition}`)
end

function EntityController.deactivate(self: EntityController)
	if self.entityModel then
		self.entityModel:Destroy()
		self.entityModel = nil
	end

	self.active = false
	self.currentState = "Idle"
	table.clear(self.lastDamageTime)
	table.clear(self.activeHidingChecks)
end

function EntityController.onSoundEvent(self: EntityController, event: Types.SoundEvent)
	if not self.active then
		return
	end

	local canHear = self.senses:canHearSound(self.position, event)
	if canHear then
		self.stateMachine:onSoundDetected(event)
	end
end

function EntityController.update(self: EntityController, dt: number)
	if not self.active then
		return
	end

	-- Update state machine
	self.stateMachine:update(dt)

	-- Sync position and state from state machine
	self.position = self.stateMachine:getPosition()
	self.currentState = self.stateMachine.currentState

	-- Update entity model position to match
	self:updateModelPosition()

	-- Check all players for vision detection and damage
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			continue
		end

		local playerPos = (hrp :: BasePart).Position

		-- Vision detection
		local lookDir = (self.stateMachine.currentPosition - self.position).Unit
		if lookDir.Magnitude ~= lookDir.Magnitude then
			lookDir = Vector3.new(0, 0, 1) -- NaN check
		end

		local isLit = false -- simplified
		local hasFlashlight = false -- TODO: check player flashlight state

		local visionResult = self.senses:checkVision(self.position, lookDir, playerPos, isLit, hasFlashlight)
		local detected = self.senses:updateDetection(player, visionResult, dt)

		if detected then
			self.stateMachine:onPlayerSpotted(playerPos)
		end

		-- Damage dealing during CHASE state
		if self.currentState == "Chase" then
			local distance = (self.position - playerPos).Magnitude
			if distance <= Constants.ENTITY_DAMAGE_RANGE then
				self:tryDamagePlayer(player, now)
			end
		end
	end

	-- Door interaction
	self:handleDoorInteraction()

	-- Update active hiding spot checks (reveal timer)
	self:updateHidingChecks(now)

	-- Update adaptive behavior
	self.adaptive:update(dt)

	-- Apply unique mechanics
	if self.profile.uniqueMechanic == "ElectronicFlatline" then
		self:runUniqueMechanic()
	end

	-- Replicate position to all clients for proximity fear calculations
	if Remotes.EntityPositionUpdate then
		Remotes.EntityPositionUpdate:FireAllClients(self.position, self.currentState)
	end

	-- Replicate state changes to clients
	if self.currentState ~= self.lastReplicatedState then
		self.lastReplicatedState = self.currentState
		if Remotes.EntityStateChanged then
			Remotes.EntityStateChanged:FireAllClients(self.currentState)
		end
	end
end

--[[
	Update the entity model's part positions to match the current logical position.
]]
function EntityController.updateModelPosition(self: EntityController)
	if not self.entityModel or not self.entityModel.PrimaryPart then
		return
	end

	local pos = self.position
	self.entityModel.PrimaryPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))

	-- Move other parts relative to torso
	local head = self.entityModel:FindFirstChild("Head")
	if head then
		(head :: Part).Position = pos + Vector3.new(0, 5, 0)
	end
	local la = self.entityModel:FindFirstChild("LeftArm")
	if la then
		(la :: Part).Position = pos + Vector3.new(-1.5, 3, 0)
	end
	local ra = self.entityModel:FindFirstChild("RightArm")
	if ra then
		(ra :: Part).Position = pos + Vector3.new(1.5, 3, 0)
	end
	local ll = self.entityModel:FindFirstChild("LeftLeg")
	if ll then
		(ll :: Part).Position = pos + Vector3.new(-0.5, 0.5, 0)
	end
	local rl = self.entityModel:FindFirstChild("RightLeg")
	if rl then
		(rl :: Part).Position = pos + Vector3.new(0.5, 0.5, 0)
	end
end

--[[
	Attempt to deal damage to a player. Respects cooldown per player.
	On hit: deals damage, stuns player briefly, fires attack remote for feedback.
]]
function EntityController.tryDamagePlayer(self: EntityController, player: Player, now: number)
	if not self.playerStateManager then
		return
	end

	-- Check if the player is hiding — hidden players are not directly damageable
	-- (they are handled through the hiding spot check system)
	if self.hidingSystem and self.hidingSystem:isPlayerHiding(player) then
		return
	end

	-- Check if the player is downed — skip damage on downed players
	local state = self.playerStateManager:getState(player)
	if not state or state.isDowned then
		return
	end

	-- Check cooldown
	local lastHit = self.lastDamageTime[player]
	if lastHit and (now - lastHit) < Constants.ENTITY_DAMAGE_COOLDOWN then
		return
	end

	-- Deal damage
	self.lastDamageTime[player] = now
	self.playerStateManager:damage(player, Constants.ENTITY_DAMAGE_AMOUNT)

	-- Stun the player briefly (reduce walk speed, then restore)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local originalSpeed = humanoid.WalkSpeed
			humanoid.WalkSpeed = 0

			-- Fire stun remote to client
			if Remotes.EntityStun then
				Remotes.EntityStun:FireClient(player, {
					duration = Constants.ENTITY_CATCH_STUN_DURATION,
				})
			end

			-- Restore speed after stun duration
			task.delay(Constants.ENTITY_CATCH_STUN_DURATION, function()
				if character.Parent and humanoid.Parent then
					humanoid.WalkSpeed = originalSpeed
				end
			end)
		end
	end

	-- Fire attack feedback remote to client (screen shake, red flash, impact sound)
	if Remotes.EntityAttack then
		Remotes.EntityAttack:FireClient(player, {
			damage = Constants.ENTITY_DAMAGE_AMOUNT,
			entityPosition = self.position,
		})
	end

	-- Generate a loud sound event (player taking damage)
	if Remotes.SoundEvent then
		-- The pain sound attracts more attention
		self:onSoundEvent({
			position = if character and character:FindFirstChild("HumanoidRootPart")
				then (character:FindFirstChild("HumanoidRootPart") :: BasePart).Position
				else self.position,
			radius = Constants.SOUND_PLAYER_DAMAGE,
			priority = "Critical",
			source = player,
		})
	end

	print(`[EntityAI] Hit {player.Name} for {Constants.ENTITY_DAMAGE_AMOUNT} damage`)
end

--[[
	Handle entity interaction with doors based on current state.
	- CHASE: detect and break closed doors in movement path
	- PATROL/INVESTIGATE/HUNT/SEARCH: open doors normally (slower)
]]
function EntityController.handleDoorInteraction(self: EntityController)
	if not self.doorSystem then
		return
	end

	-- Calculate movement direction from the state machine
	local moveDir = Vector3.zero
	local target: Vector3? = nil

	if self.currentState == "Chase" then
		target = self.stateMachine.lastKnownPlayerPosition
	elseif self.currentState == "Investigate" or self.currentState == "Hunt" then
		target = self.stateMachine.investigateTarget
	elseif self.currentState == "Patrol" then
		local waypoints = self.stateMachine.patrolWaypoints
		local idx = self.stateMachine.patrolIndex
		if idx > 0 and idx <= #waypoints then
			target = waypoints[idx]
		end
	elseif self.currentState == "Search" then
		moveDir = self.stateMachine.searchDirection
	end

	if target then
		local offset = target - self.position
		local flat = Vector3.new(offset.X, 0, offset.Z)
		if flat.Magnitude > 0.1 then
			moveDir = flat.Unit
		end
	end

	if moveDir.Magnitude < 0.01 then
		return
	end

	-- Find a closed door in the entity's path
	local doorId = self.doorSystem:findClosedDoorNear(
		self.position,
		moveDir,
		Constants.ENTITY_DOOR_DETECT_RANGE
	)

	if not doorId then
		return
	end

	if self.currentState == "Chase" then
		-- Break the door violently during chase
		self.doorSystem:entityBreakDoor(doorId)
		self.stateMachine:triggerDoorDelay()
		print(`[EntityAI] Broke door {doorId} during chase`)
	elseif self.currentState == "Patrol" or self.currentState == "Investigate"
		or self.currentState == "Hunt" or self.currentState == "Search" then
		-- Open the door normally (quieter, slower)
		self.doorSystem:entityOpenDoorQuietly(doorId)
		-- Longer pause for non-chase door opening
		self.stateMachine.doorDelayTimer = Constants.DOOR_ENTITY_PATROL_OPEN_DURATION
		print(`[EntityAI] Opened door {doorId} during {self.currentState}`)
	end
end

--[[
	Check hiding spots near a given position. Called by the StateMachine's
	onCheckHidingSpots callback during Investigate/Hunt/Search states.
]]
function EntityController.checkHidingSpotsNear(self: EntityController, searchPosition: Vector3, radius: number)
	if not self.hidingSystem then
		return
	end

	local nearbySpots = self.hidingSystem:getSpotsNear(searchPosition, radius)

	for _, spot in nearbySpots do
		if not spot.isOccupied then
			continue
		end

		-- Get the adaptive check chance for this spot
		local checkChance = self.hidingSystem:getCheckChance(spot.id, self.adaptive)
		local roll = math.random()

		if roll > checkChance then
			continue -- Entity doesn't check this spot this time
		end

		-- Entity decides to check this spot
		local occupant = self.hidingSystem:entityCheckSpot(spot.id)
		if not occupant then
			continue
		end

		-- Record the use for adaptive behavior
		self.hidingSystem:recordUse(spot.id, self.adaptive)

		-- Fire dread spike to the hidden player
		if Remotes.HidingSpotChecked then
			Remotes.HidingSpotChecked:FireClient(occupant, spot.id)
		end

		-- Start the reveal timer: if the player stays in the spot for
		-- ENTITY_HIDING_SPOT_REVEAL_TIME seconds, they get dragged out and damaged
		local now = os.clock()
		local checkKey = `{spot.id}_{occupant.UserId}`

		-- Only start a new check if there isn't already an active one for this spot
		if not self.activeHidingChecks[checkKey] then
			self.activeHidingChecks[checkKey] = {
				player = occupant,
				startTime = now,
				spotId = spot.id,
			}

			print(`[EntityAI] Checking hiding spot {spot.id} — {occupant.Name} has {Constants.ENTITY_HIDING_SPOT_REVEAL_TIME}s to escape`)
		end
	end
end

--[[
	Update all active hiding spot checks. If the reveal timer expires and the
	player is still hiding, force them out and deal damage. If the player
	exits early, transition to CHASE.
]]
function EntityController.updateHidingChecks(self: EntityController, now: number)
	if not self.hidingSystem or not self.playerStateManager then
		return
	end

	local checksToRemove: { string } = {}

	for checkKey, checkData in self.activeHidingChecks do
		local player = checkData.player
		local spotId = checkData.spotId
		local elapsed = now - checkData.startTime

		-- Check if the player has left the hiding spot early
		local currentSpot = self.hidingSystem:getPlayerSpot(player)
		if currentSpot ~= spotId then
			-- Player escaped the hiding spot — transition to CHASE
			local character = player.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					self.stateMachine:onPlayerSpotted((hrp :: BasePart).Position)
				end
			end

			table.insert(checksToRemove, checkKey)
			print(`[EntityAI] {player.Name} escaped from {spotId} — CHASE`)
			continue
		end

		-- Check if the reveal timer has expired
		if elapsed >= Constants.ENTITY_HIDING_SPOT_REVEAL_TIME then
			-- Force the player out of the hiding spot
			self.hidingSystem:exitSpot(player)

			-- Deal damage
			self.playerStateManager:damage(player, Constants.ENTITY_DAMAGE_AMOUNT)

			-- Fire attack feedback
			if Remotes.EntityAttack then
				Remotes.EntityAttack:FireClient(player, {
					damage = Constants.ENTITY_DAMAGE_AMOUNT,
					entityPosition = self.position,
					draggedOut = true,
				})
			end

			-- Now chase the player
			local character = player.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					self.stateMachine:onPlayerSpotted((hrp :: BasePart).Position)
				end
			end

			table.insert(checksToRemove, checkKey)
			print(`[EntityAI] Dragged {player.Name} out of {spotId} and dealt {Constants.ENTITY_DAMAGE_AMOUNT} damage`)
		end
	end

	-- Clean up completed checks
	for _, key in checksToRemove do
		self.activeHidingChecks[key] = nil
	end
end

function EntityController.runUniqueMechanic(_self: EntityController)
	-- TODO (Wave 4): Implement ElectronicFlatline mechanic
	-- When entity is within range of electronic objects (lights, generators),
	-- cause them to flicker and shut down, providing audio/visual cues to players.
end

return EntityController
