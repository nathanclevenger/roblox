--!strict

--[[
	Lives Manager (Server)

	Tracks per-player lives (3 hearts per run). Each death decrements a heart,
	triggers the appropriate death animation on the client, and handles
	respawn (hearts 1 & 2) or permanent death (heart 3).

	Integrates with PlayerStateManager — instead of instant Humanoid.Health = 0,
	deaths route through here to manage the lives lifecycle.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)

local Remotes = require(script.Parent.Remotes)

local LivesManager = {}
LivesManager.__index = LivesManager

export type LivesManager = typeof(setmetatable(
	{} :: {
		hearts: { [Player]: number },
		checkpoints: { [Player]: Vector3 },
		deathCount: { [Player]: number },
		graceTimers: { [Player]: number },
		playerStateManager: any, -- set after construction to avoid circular require
		gameManager: any, -- set after construction
		notificationSystem: any, -- set after construction
		spectatorManager: any, -- set after construction
		reviveSystem: any, -- set after construction
	},
	LivesManager
))

--[[
	Create a new LivesManager.
]]
function LivesManager.new(): LivesManager
	local self = setmetatable({
		hearts = {},
		checkpoints = {},
		deathCount = {},
		graceTimers = {},
		playerStateManager = nil,
		gameManager = nil,
		notificationSystem = nil,
		spectatorManager = nil,
		reviveSystem = nil,
	}, LivesManager)

	return self
end

--[[
	Wire in external dependencies after construction (avoids circular requires).
]]
function LivesManager.setPlayerStateManager(self: LivesManager, psm: any)
	self.playerStateManager = psm
end

function LivesManager.setGameManager(self: LivesManager, gm: any)
	self.gameManager = gm
end

function LivesManager.setNotificationSystem(self: LivesManager, ns: any)
	self.notificationSystem = ns
end

function LivesManager.setSpectatorManager(self: LivesManager, sm: any)
	self.spectatorManager = sm
end

function LivesManager.setReviveSystem(self: LivesManager, rs: any)
	self.reviveSystem = rs
end

--[[
	Initialize lives for a player at the start of a run.
	Called when a round begins or when a player joins mid-round.
]]
function LivesManager.resetLives(self: LivesManager, player: Player)
	self.hearts[player] = Constants.MAX_HEARTS
	self.deathCount[player] = 0
	self.graceTimers[player] = 0

	-- Fire initial heart state to client
	if Remotes.HeartUpdate then
		Remotes.HeartUpdate:FireClient(player, {
			hearts = Constants.MAX_HEARTS,
			maxHearts = Constants.MAX_HEARTS,
			deathCount = 0,
		})
	end

	print(`[LivesManager] Reset lives for {player.Name} — {Constants.MAX_HEARTS} hearts`)
end

--[[
	Set a checkpoint position for a player. Called when a player enters
	an invisible checkpoint trigger zone.
]]
function LivesManager.setCheckpoint(self: LivesManager, player: Player, position: Vector3, checkpointName: string?)
	self.checkpoints[player] = position

	-- Subtle client notification
	if Remotes.CheckpointReached then
		Remotes.CheckpointReached:FireClient(player, {
			name = checkpointName or "Checkpoint",
			position = position,
		})
	end

	print(`[LivesManager] Checkpoint set for {player.Name}: {checkpointName or "unnamed"} at {position}`)
end

--[[
	Get the current heart count for a player.
]]
function LivesManager.getHearts(self: LivesManager, player: Player): number
	return self.hearts[player] or 0
end

--[[
	Get the current death count for a player.
]]
function LivesManager.getDeathCount(self: LivesManager, player: Player): number
	return self.deathCount[player] or 0
end

--[[
	Check if a player is currently in their respawn grace period.
]]
function LivesManager.isInGracePeriod(self: LivesManager, player: Player): boolean
	local timer = self.graceTimers[player]
	return timer ~= nil and timer > 0
end

--[[
	Called when a player dies. Decrements a heart, fires the death remote
	to the client with the appropriate death number, and handles respawn
	vs permanent death.
]]
function LivesManager.onPlayerDeath(self: LivesManager, player: Player)
	local currentHearts = self.hearts[player]
	if not currentHearts or currentHearts <= 0 then
		return
	end

	-- Increment death count and decrement hearts
	local deathNum = (self.deathCount[player] or 0) + 1
	self.deathCount[player] = deathNum

	currentHearts -= 1
	self.hearts[player] = currentHearts

	local isFinalDeath = currentHearts <= 0

	-- Build death data
	local deathData: Types.DeathData = {
		deathNumber = deathNum,
		heartsRemaining = currentHearts,
		isFinalDeath = isFinalDeath,
	}

	-- Fire death remote to the dying player's client
	if Remotes.PlayerDied then
		Remotes.PlayerDied:FireClient(player, deathData)
	end

	-- Fire heart update to keep HUD in sync
	if Remotes.HeartUpdate then
		Remotes.HeartUpdate:FireClient(player, {
			hearts = currentHearts,
			maxHearts = Constants.MAX_HEARTS,
			deathCount = deathNum,
		})
	end

	-- Notify other players (legacy HeartUpdate remote)
	self:_notifyOtherPlayers(player, deathData)

	-- Fire notification through NotificationSystem
	if self.notificationSystem then
		if isFinalDeath then
			self.notificationSystem:notifyGone(player)
		else
			self.notificationSystem:notifyDied(player, currentHearts)
		end
	end

	-- Notify revive system that the downed timer expired (prompt cleanup)
	if self.reviveSystem then
		self.reviveSystem:onReviveExpired(player)
	end

	print(`[LivesManager] {player.Name} died (death #{deathNum}, {currentHearts} hearts remaining)`)

	if isFinalDeath then
		-- Determine animation duration for final death before triggering end
		local animDuration = Constants.DEATH_ANIMATION_DURATION_3
		task.delay(animDuration, function()
			self:onFinalDeath(player)
		end)
	else
		-- Determine animation duration based on death number
		local animDuration = if deathNum == 1
			then Constants.DEATH_ANIMATION_DURATION_1
			else Constants.DEATH_ANIMATION_DURATION_2

		-- Schedule respawn after the death animation completes
		task.delay(animDuration, function()
			self:_respawnPlayer(player)
		end)
	end
end

--[[
	Handle the final (3rd) death. The run is over for this player.
	In solo, ends the round. In co-op, enters spectator mode.
]]
function LivesManager.onFinalDeath(self: LivesManager, player: Player)
	print(`[LivesManager] {player.Name} has died permanently — run over`)

	-- Check if this is solo or co-op
	local activePlayers = 0
	for p, h in self.hearts do
		if p ~= player and h > 0 then
			activePlayers += 1
		end
	end

	if activePlayers == 0 then
		-- Solo or all players dead: end the round as a failure
		if self.gameManager then
			self.gameManager:endRound(false)
		end
	else
		-- Co-op: this player enters spectator mode; round continues
		if self.spectatorManager then
			self.spectatorManager:enterSpectator(player)
		end

		if self.notificationSystem then
			self.notificationSystem:notifyGone(player)
		end

		print(`[LivesManager] {player.Name} enters spectator mode — {activePlayers} players remaining`)
	end
end

--[[
	Respawn a player at their most recent checkpoint after a non-final death.
	Restores health to full, clears injury states, and starts the grace period.
]]
function LivesManager._respawnPlayer(self: LivesManager, player: Player)
	-- Restore full health via PlayerStateManager
	if self.playerStateManager then
		local state = self.playerStateManager:getState(player)
		if state then
			state.health = Constants.MAX_HEALTH
			state.isBleeding = false
			state.isDowned = false

			-- Update leaderstats
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local healthValue = leaderstats:FindFirstChild("Health") :: IntValue?
				if healthValue then
					healthValue.Value = Constants.MAX_HEALTH
				end
			end

			self.playerStateManager:replicateState(player)
		end
	end

	-- Teleport to checkpoint
	local checkpointPos = self.checkpoints[player]
	local character = player.Character
	if character and checkpointPos then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoidRootPart then
			humanoidRootPart.CFrame = CFrame.new(checkpointPos + Vector3.new(0, 3, 0))
		end

		-- Restore humanoid health so the character is alive
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
			humanoid.WalkSpeed = Constants.SPEED_WALK
		end
	elseif character then
		-- No checkpoint set — use level spawn if available
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
			humanoid.WalkSpeed = Constants.SPEED_WALK
		end
	end

	-- Start respawn grace period (immunity from proximity fear triggers)
	self.graceTimers[player] = Constants.RESPAWN_GRACE_PERIOD

	-- Fire respawn remote to client
	if Remotes.PlayerRespawned then
		Remotes.PlayerRespawned:FireClient(player, {
			heartsRemaining = self.hearts[player] or 0,
			deathCount = self.deathCount[player] or 0,
			checkpointPosition = checkpointPos,
		})
	end

	print(`[LivesManager] {player.Name} respawned at checkpoint`)
end

--[[
	Notify other players about a death event. Shows notification like
	"[PlayerName] has died. (2 lives remaining)"
]]
function LivesManager._notifyOtherPlayers(self: LivesManager, deadPlayer: Player, deathData: Types.DeathData)
	for player in self.hearts do
		if player ~= deadPlayer then
			if Remotes.HeartUpdate then
				Remotes.HeartUpdate:FireClient(player, {
					otherPlayer = deadPlayer.Name,
					otherPlayerHearts = deathData.heartsRemaining,
					isFinalDeath = deathData.isFinalDeath,
				})
			end
		end
	end
end

--[[
	Tick grace period timers. Call from RunService.Heartbeat.
]]
function LivesManager.update(self: LivesManager, dt: number)
	for player, remaining in self.graceTimers do
		if remaining > 0 then
			remaining -= dt
			if remaining <= 0 then
				self.graceTimers[player] = 0
			else
				self.graceTimers[player] = remaining
			end
		end
	end
end

--[[
	Clean up all state for a player who is leaving.
]]
function LivesManager.removePlayer(self: LivesManager, player: Player)
	self.hearts[player] = nil
	self.checkpoints[player] = nil
	self.deathCount[player] = nil
	self.graceTimers[player] = nil
end

return LivesManager
