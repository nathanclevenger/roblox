--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Shared.Constants)

local GameManager = require(script.GameManager)
local Remotes = require(script.Remotes)

-- Server entry point
print(`[Server] {Constants.GAME_NAME} v{Constants.GAME_VERSION} starting`)

-- Initialize remotes before any systems
Remotes.init()

-- Initialize game manager (owns all subsystems internally)
local gameManager = GameManager.new()

-- Server heartbeat — update entity AI, blood trails, downed timers, scare system
RunService.Heartbeat:Connect(function(dt: number)
	gameManager.entityController:update(dt)
	gameManager.bloodTrailSystem:update(dt)
	gameManager.playerStateManager:updateDownedTimers(dt)

	-- Feed entity position to scare manager for Category B triggers
	if gameManager.entityController.active then
		gameManager.scareManager:updateEntityPosition(
			gameManager.entityController.position,
			gameManager.entityController.currentState :: string
		)
	end

	-- Update scare manager (evaluates eligibility and fires scares)
	gameManager.scareManager:update(dt)
end)

-- Player connections
Players.PlayerAdded:Connect(function(player: Player)
	print(`[Server] {player.Name} joined`)
	gameManager:onPlayerJoin(player)

	player.CharacterAdded:Connect(function(_character: Model)
		gameManager:onPlayerSpawn(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	print(`[Server] {player.Name} left`)
	gameManager:onPlayerLeave(player)
end)

game:BindToClose(function()
	gameManager:onServerShutdown()
end)

-- Auto-start Level 1 for testing (remove in production)
task.delay(3, function()
	if gameManager:getPlayerCount() > 0 then
		gameManager:startRound("st-marens-hospital")
	end
end)
