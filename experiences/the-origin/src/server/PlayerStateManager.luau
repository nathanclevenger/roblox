--!strict

--[[
	Player State Manager (Server)

	Authoritative server-side manager for all player state: health, inventory,
	status effects (bleeding, downed, hiding), and the downed-revive lifecycle.

	Communicates state changes to clients via Remotes. Never trusts client input —
	all mutations are validated here before being applied.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)

local Remotes = require(script.Remotes)

local PlayerStateManager = {}
PlayerStateManager.__index = PlayerStateManager

export type PlayerStateManager = typeof(setmetatable(
	{} :: {
		states: { [Player]: Types.PlayerState },
		downedTimers: { [Player]: number },
		livesManager: any?, -- set after construction to avoid circular require
		reviveSystem: any?, -- set after construction to avoid circular require
	},
	PlayerStateManager
))

--[[
	Create a new PlayerStateManager and wire up the UseItem remote handler.
]]
function PlayerStateManager.new(): PlayerStateManager
	local self = setmetatable({
		states = {},
		downedTimers = {},
		livesManager = nil,
		reviveSystem = nil,
	}, PlayerStateManager)

	-- Connect client item-use requests (validated server-side)
	if Remotes.UseItem then
		Remotes.UseItem.OnServerEvent:Connect(function(player: Player, itemId: unknown)
			-- Never trust the client: validate argument type
			if typeof(itemId) ~= "string" then
				return
			end
			self:useItem(player, itemId :: string)
		end)
	end

	return self
end

--[[
	Initialize a fresh PlayerState for a newly joined / spawned player.
	Creates the leaderstats folder used by the default Roblox leaderboard.
]]
function PlayerStateManager.initPlayer(self: PlayerStateManager, player: Player)
	local state: Types.PlayerState = {
		health = Constants.MAX_HEALTH,
		maxHealth = Constants.MAX_HEALTH,
		stamina = 1.0,
		isSprinting = false,
		isCrouching = false,
		isHiding = false,
		isBleeding = false,
		isDowned = false,
		hidingSpotId = nil,
		inventory = {},
		keyItems = {},
	}

	self.states[player] = state

	-- Leaderstats (IntValue visible on the player list)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local healthValue = Instance.new("IntValue")
	healthValue.Name = "Health"
	healthValue.Value = state.health
	healthValue.Parent = leaderstats

	-- Send initial state to the client
	self:replicateState(player)

	print(`[PlayerStateManager] Initialized state for {player.Name}`)
end

--[[
	Wire in a LivesManager reference (set after construction to avoid circular require).
]]
function PlayerStateManager.setLivesManager(self: PlayerStateManager, livesManager: any)
	self.livesManager = livesManager
end

--[[
	Wire in a ReviveSystem reference (set after construction to avoid circular require).
]]
function PlayerStateManager.setReviveSystem(self: PlayerStateManager, reviveSystem: any)
	self.reviveSystem = reviveSystem
end

--[[
	Return the player's current state, or nil if they have none.
]]
function PlayerStateManager.getState(self: PlayerStateManager, player: Player): Types.PlayerState?
	return self.states[player]
end

--[[
	Apply damage to a player. Handles injury thresholds, bleeding, and
	the transition into the downed state.
]]
function PlayerStateManager.damage(self: PlayerStateManager, player: Player, amount: number)
	local state = self.states[player]
	if not state then
		return
	end

	-- Already downed — ignore further damage
	if state.isDowned then
		return
	end

	state.health = math.max(0, state.health - amount)

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local healthValue = leaderstats:FindFirstChild("Health") :: IntValue?
		if healthValue then
			healthValue.Value = state.health
		end
	end

	-- Injury thresholds
	-- Limping communicated via state update; client applies SPEED_LIMP_MODIFIER

	if state.health <= 1 and state.health > 0 then
		state.isBleeding = true
	end

	if state.health <= 0 then
		-- Determine if multiplayer for downed vs instant death
		local playerCount = 0
		for _ in self.states do
			playerCount += 1
		end

		if playerCount > 1 then
			self:enterDowned(player)
		else
			-- Solo: instant death
			self:killPlayer(player)
		end
	end

	-- Notify the damaged client
	if Remotes.PlayerDamaged then
		Remotes.PlayerDamaged:FireClient(player, {
			health = state.health,
			isBleeding = state.isBleeding,
			isDowned = state.isDowned,
		})
	end

	self:replicateState(player)
end

--[[
	Heal a player by the given amount. Clears bleeding and limp thresholds
	when health rises above their respective pip counts.
]]
function PlayerStateManager.heal(self: PlayerStateManager, player: Player, amount: number)
	local state = self.states[player]
	if not state then
		return
	end

	state.health = math.min(Constants.MAX_HEALTH, state.health + amount)

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local healthValue = leaderstats:FindFirstChild("Health") :: IntValue?
		if healthValue then
			healthValue.Value = state.health
		end
	end

	-- Clear status effects as health recovers
	if state.health > 1 then
		state.isBleeding = false
	end

	-- Limp clears above 2 pips (communicated via state; client reads threshold)

	-- Clear downed if healed while downed
	if state.isDowned and state.health > 0 then
		state.isDowned = false
		self.downedTimers[player] = nil

		-- Restore character walk speed
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if humanoid then
			humanoid.WalkSpeed = Constants.SPEED_WALK
		end
	end

	self:replicateState(player)
end

-- Set of item types that count as key items (no inventory slot cost)
local KEY_ITEM_TYPES: { [string]: boolean } = {
	Flashlight = true,
	FuelCanister = true,
	PharmacyKey = true,
	MasterKey = true,
	PsychWardKeycard = true,
}

--[[
	Attempt to add an item to a player's inventory.
	Key items are stored separately and do not consume inventory slots.
	Returns true if the item was successfully added.
]]
function PlayerStateManager.addItem(self: PlayerStateManager, player: Player, item: Types.InventoryItem): boolean
	local state = self.states[player]
	if not state then
		if Remotes.ItemPickupResult then
			Remotes.ItemPickupResult:FireClient(player, { success = false, item = item })
		end
		return false
	end

	local isKeyItem = KEY_ITEM_TYPES[item.itemType] or KEY_ITEM_TYPES[item.name]

	if isKeyItem then
		-- Key items go into the separate keyItems list
		table.insert(state.keyItems, item.name)
	else
		-- Regular items require an open inventory slot
		if #state.inventory >= Constants.INVENTORY_SLOTS then
			if Remotes.ItemPickupResult then
				Remotes.ItemPickupResult:FireClient(player, { success = false, item = item })
			end
			return false
		end
		table.insert(state.inventory, item)
	end

	if Remotes.ItemPickupResult then
		Remotes.ItemPickupResult:FireClient(player, { success = true, item = item })
	end

	self:replicateState(player)
	return true
end

--[[
	Remove an item from a player's inventory (or keyItems) by its id.
	Returns the removed item, or nil if not found.
]]
function PlayerStateManager.removeItem(self: PlayerStateManager, player: Player, itemId: string): Types.InventoryItem?
	local state = self.states[player]
	if not state then
		return nil
	end

	-- Search regular inventory
	for i, item in state.inventory do
		if item.id == itemId then
			table.remove(state.inventory, i)
			self:replicateState(player)
			return item
		end
	end

	-- Search key items (stored as strings, so we match by name)
	for i, keyName in state.keyItems do
		if keyName == itemId then
			table.remove(state.keyItems, i)
			self:replicateState(player)
			-- Return a synthetic InventoryItem for consistency
			return {
				id = itemId,
				name = keyName,
				itemType = keyName :: any,
			}
		end
	end

	return nil
end

--[[
	Handle a client's request to use an item. Dispatches based on itemType.
	All validation happens server-side.
]]
function PlayerStateManager.useItem(self: PlayerStateManager, player: Player, itemId: string)
	local state = self.states[player]
	if not state then
		return
	end

	-- Cannot use items while downed
	if state.isDowned then
		return
	end

	-- Find the item in inventory
	local foundItem: Types.InventoryItem? = nil
	local foundIndex: number? = nil

	for i, item in state.inventory do
		if item.id == itemId then
			foundItem = item
			foundIndex = i
			break
		end
	end

	if not foundItem or not foundIndex then
		return
	end

	local item = foundItem :: Types.InventoryItem

	if item.itemType == "Battery" then
		-- Refill flashlight battery — client handles the visual; we confirm via state
		table.remove(state.inventory, foundIndex :: number)
		self:replicateState(player)

		-- Fire a state update with a battery refill flag so the client knows
		if Remotes.PlayerStateUpdate then
			Remotes.PlayerStateUpdate:FireClient(player, {
				state = state,
				batteryRefill = true,
				batteryLife = Constants.FLASHLIGHT_BATTERY_LIFE,
			})
		end
	elseif item.itemType == "Bandage" then
		table.remove(state.inventory, foundIndex :: number)
		self:heal(player, Constants.BANDAGE_HEAL)
		-- heal already calls replicateState
	elseif item.itemType == "Medkit" then
		table.remove(state.inventory, foundIndex :: number)
		self:heal(player, Constants.MEDKIT_HEAL)
		-- heal already calls replicateState
	elseif item.itemType == "Flare" then
		table.remove(state.inventory, foundIndex :: number)

		-- Create a glowing flare part in the world at the player's forward direction
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				local forwardDirection = rootPart.CFrame.LookVector
				local flarePosition = rootPart.Position + forwardDirection * 20

				local flare = Instance.new("Part")
				flare.Name = "Flare"
				flare.Size = Vector3.new(0.5, 0.5, 0.5)
				flare.Position = flarePosition
				flare.Anchored = true
				flare.CanCollide = false
				flare.Material = Enum.Material.Neon
				flare.Color = Color3.fromRGB(255, 80, 20)
				flare.Shape = Enum.PartType.Ball

				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(255, 120, 40)
				light.Brightness = 3
				light.Range = 30
				light.Parent = flare

				flare.Parent = workspace

				-- Auto-destroy after the flare distract duration
				task.delay(Constants.FLARE_DISTRACT_DURATION, function()
					if flare and flare.Parent then
						flare:Destroy()
					end
				end)
			end
		end

		self:replicateState(player)
	end
end

--[[
	Transition a player into the downed state. Sets crawl speed and starts
	the revive countdown timer.
]]
function PlayerStateManager.enterDowned(self: PlayerStateManager, player: Player)
	local state = self.states[player]
	if not state then
		return
	end

	state.isDowned = true

	-- Set crawl speed on the character
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		humanoid.WalkSpeed = 2
	end

	-- Start the revive countdown
	self.downedTimers[player] = Constants.DOWNED_REVIVE_WINDOW

	self:replicateState(player)

	-- Notify ReviveSystem to create the ProximityPrompt and fire notifications
	if self.reviveSystem then
		self.reviveSystem:onPlayerDowned(player)
	end

	print(`[PlayerStateManager] {player.Name} is downed — {Constants.DOWNED_REVIVE_WINDOW}s to revive`)
end

--[[
	Revive a downed player. Restores them to 1 health pip with bleeding active.
]]
function PlayerStateManager.revive(self: PlayerStateManager, player: Player)
	local state = self.states[player]
	if not state then
		return
	end

	if not state.isDowned then
		return
	end

	state.isDowned = false
	state.health = Constants.DOWNED_REVIVE_HEALTH
	state.isBleeding = true -- revived at 1 pip, still bleeding

	-- Clear the downed timer
	self.downedTimers[player] = nil

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local healthValue = leaderstats:FindFirstChild("Health") :: IntValue?
		if healthValue then
			healthValue.Value = state.health
		end
	end

	-- Restore normal walk speed
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		humanoid.WalkSpeed = Constants.SPEED_WALK
	end

	self:replicateState(player)

	print(`[PlayerStateManager] {player.Name} has been revived`)
end

--[[
	Clean up all state for a player who is leaving.
]]
function PlayerStateManager.removePlayer(self: PlayerStateManager, player: Player)
	self.states[player] = nil
	self.downedTimers[player] = nil

	print(`[PlayerStateManager] Cleaned up state for {player.Name}`)
end

--[[
	Tick all active downed timers. Call this from RunService.Heartbeat.
	When a timer expires the player is killed.
]]
function PlayerStateManager.updateDownedTimers(self: PlayerStateManager, dt: number)
	for player, remaining in self.downedTimers do
		remaining -= dt
		if remaining <= 0 then
			self.downedTimers[player] = nil
			self:killPlayer(player)
		else
			self.downedTimers[player] = remaining
		end
	end
end

--[[
	Fire the current PlayerState to the specified client.
]]
function PlayerStateManager.replicateState(self: PlayerStateManager, player: Player)
	local state = self.states[player]
	if not state then
		return
	end

	if Remotes.PlayerStateUpdate then
		Remotes.PlayerStateUpdate:FireClient(player, {
			state = state,
		})
	end
end

--[[
	Kill a player outright. Routes through LivesManager if available to
	handle the hearts/lives lifecycle. Falls back to instant death if
	LivesManager is not wired in.
]]
function PlayerStateManager.killPlayer(self: PlayerStateManager, player: Player)
	local state = self.states[player]
	if state then
		state.health = 0
		state.isDowned = false
		state.isBleeding = false
	end

	self.downedTimers[player] = nil

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local healthValue = leaderstats:FindFirstChild("Health") :: IntValue?
		if healthValue then
			healthValue.Value = 0
		end
	end

	self:replicateState(player)

	-- Route through LivesManager for hearts/death animation lifecycle
	if self.livesManager then
		self.livesManager:onPlayerDeath(player)
		print(`[PlayerStateManager] {player.Name} killed — routed to LivesManager`)
	else
		-- Fallback: no LivesManager, force Roblox respawn directly
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if humanoid then
			humanoid.Health = 0
		end
		print(`[PlayerStateManager] {player.Name} has been killed (no LivesManager)`)
	end
end

return PlayerStateManager
