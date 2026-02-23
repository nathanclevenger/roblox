--!strict

--[[
	Revive System (Server)

	Manages the teammate revive interaction for co-op play. When a player
	enters the downed state, a ProximityPrompt is created on their character
	allowing nearby teammates to revive them.

	Integrates with PlayerStateManager for state mutations, LivesManager
	for heart tracking, and NotificationSystem for broadcasting events.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local Remotes = require(script.Parent.Remotes)

local ReviveSystem = {}
ReviveSystem.__index = ReviveSystem

export type ReviveSystem = typeof(setmetatable(
	{} :: {
		activePrompts: { [Player]: ProximityPrompt },
		revivingPlayers: { [Player]: boolean }, -- players currently holding the revive prompt
		playerStateManager: any, -- set after construction to avoid circular require
		livesManager: any, -- set after construction
		notificationSystem: any, -- set after construction
		spectatorManager: any, -- set after construction
	},
	ReviveSystem
))

--[[
	Create a new ReviveSystem.
]]
function ReviveSystem.new(): ReviveSystem
	local self = setmetatable({
		activePrompts = {},
		revivingPlayers = {},
		playerStateManager = nil,
		livesManager = nil,
		notificationSystem = nil,
		spectatorManager = nil,
	}, ReviveSystem)

	return self
end

--[[
	Wire in external dependencies after construction (avoids circular requires).
]]
function ReviveSystem.setPlayerStateManager(self: ReviveSystem, psm: any)
	self.playerStateManager = psm
end

function ReviveSystem.setLivesManager(self: ReviveSystem, lm: any)
	self.livesManager = lm
end

function ReviveSystem.setNotificationSystem(self: ReviveSystem, ns: any)
	self.notificationSystem = ns
end

function ReviveSystem.setSpectatorManager(self: ReviveSystem, sm: any)
	self.spectatorManager = sm
end

--[[
	Called when a player enters the downed state. Creates a ProximityPrompt
	on their character for teammates to interact with.
]]
function ReviveSystem.onPlayerDowned(self: ReviveSystem, downedPlayer: Player)
	local character = downedPlayer.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoidRootPart then
		return
	end

	-- Remove any existing prompt first
	self:_removePrompt(downedPlayer)

	-- Create the ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RevivePrompt"
	prompt.ActionText = `Revive {downedPlayer.Name}`
	prompt.ObjectText = "Downed Player"
	prompt.HoldDuration = Constants.REVIVE_HOLD_DURATION
	prompt.MaxActivationDistance = Constants.REVIVE_PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = humanoidRootPart

	self.activePrompts[downedPlayer] = prompt

	-- When a teammate starts holding the prompt
	prompt.PromptButtonHoldBegan:Connect(function(revivingPlayer: Player)
		if revivingPlayer == downedPlayer then
			return -- can't revive yourself
		end

		self.revivingPlayers[revivingPlayer] = true

		-- Restrict the reviving player's movement (can't sprint/hide)
		local revivingState = self.playerStateManager and self.playerStateManager:getState(revivingPlayer)
		if revivingState then
			revivingState.isSprinting = false
		end

		-- Notify all clients that a revive has started
		if Remotes.ReviveStarted then
			Remotes.ReviveStarted:FireAllClients({
				reviver = revivingPlayer.Name,
				target = downedPlayer.Name,
			})
		end

		print(`[ReviveSystem] {revivingPlayer.Name} started reviving {downedPlayer.Name}`)
	end)

	-- When a teammate cancels the hold
	prompt.PromptButtonHoldEnded:Connect(function(revivingPlayer: Player)
		self.revivingPlayers[revivingPlayer] = nil
		print(`[ReviveSystem] {revivingPlayer.Name} cancelled reviving {downedPlayer.Name}`)
	end)

	-- When the prompt is fully triggered (5-second hold complete)
	prompt.Triggered:Connect(function(revivingPlayer: Player)
		if revivingPlayer == downedPlayer then
			return
		end

		self.revivingPlayers[revivingPlayer] = nil

		-- Perform the revive
		self:_completeRevive(downedPlayer, revivingPlayer)
	end)

	-- Notify all clients that a player has fallen
	if self.notificationSystem then
		self.notificationSystem:notifyFallen(downedPlayer)
	end

	print(`[ReviveSystem] Revive prompt created for {downedPlayer.Name}`)
end

--[[
	Called when a downed player's revive window expires without being revived.
	The heart is lost and the player either respawns or enters spectator mode.
]]
function ReviveSystem.onReviveExpired(self: ReviveSystem, player: Player)
	-- Remove the prompt
	self:_removePrompt(player)

	-- Determine lives remaining
	local livesRemaining = 0
	if self.livesManager then
		livesRemaining = self.livesManager:getHearts(player)
	end

	-- The heart loss and death handling is done by LivesManager.onPlayerDeath
	-- which is triggered by PlayerStateManager.killPlayer (called by updateDownedTimers)
	-- So we only need to fire notifications here

	if livesRemaining <= 0 then
		-- Player is permanently dead
		if self.notificationSystem then
			self.notificationSystem:notifyGone(player)
		end
	else
		-- Player lost a heart but can respawn
		if self.notificationSystem then
			self.notificationSystem:notifyDied(player, livesRemaining)
		end
	end
end

--[[
	Check if a player is currently in the process of reviving someone.
]]
function ReviveSystem.isReviving(self: ReviveSystem, player: Player): boolean
	return self.revivingPlayers[player] == true
end

--[[
	Clean up all revive prompts and state.
]]
function ReviveSystem.cleanup(self: ReviveSystem)
	for player, prompt in self.activePrompts do
		if prompt and prompt.Parent then
			prompt:Destroy()
		end
	end

	self.activePrompts = {}
	self.revivingPlayers = {}

	print("[ReviveSystem] Cleaned up all revive prompts")
end

--[[
	Clean up state for a single player who is leaving.
]]
function ReviveSystem.removePlayer(self: ReviveSystem, player: Player)
	self:_removePrompt(player)
	self.revivingPlayers[player] = nil
end

--[[
	Complete a revive — restore the downed player and notify everyone.
]]
function ReviveSystem._completeRevive(self: ReviveSystem, downedPlayer: Player, revivingPlayer: Player)
	-- Remove the proximity prompt
	self:_removePrompt(downedPlayer)

	-- Perform the actual revive through PlayerStateManager
	if self.playerStateManager then
		self.playerStateManager:revive(downedPlayer)
	end

	-- Notify all clients
	if Remotes.ReviveCompleted then
		Remotes.ReviveCompleted:FireAllClients({
			reviver = revivingPlayer.Name,
			target = downedPlayer.Name,
		})
	end

	if self.notificationSystem then
		self.notificationSystem:notifyRevived(downedPlayer)
	end

	print(`[ReviveSystem] {revivingPlayer.Name} successfully revived {downedPlayer.Name}`)
end

--[[
	Remove a revive prompt from a player's character.
]]
function ReviveSystem._removePrompt(self: ReviveSystem, player: Player)
	local prompt = self.activePrompts[player]
	if prompt and prompt.Parent then
		prompt:Destroy()
	end
	self.activePrompts[player] = nil
end

return ReviveSystem
