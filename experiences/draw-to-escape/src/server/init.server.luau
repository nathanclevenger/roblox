--!strict

--[[
	Draw to Escape — Server Entry Point
	Wires up all server systems: stage management, drawing materialization,
	world building, enemy AI, and remote event handling.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local StageConfig = require(ReplicatedStorage.Shared.StageConfig)

local DrawingMaterializer = require(script.Parent.DrawingMaterializer)
local EnemyAI = require(script.Parent.EnemyAI)
local Remotes = require(script.Parent.Remotes)
local StageManager = require(script.Parent.StageManager)
local StageMechanics = require(script.Parent.StageMechanics)
local WorldBuilder = require(script.Parent.WorldBuilder)

-- Initialize remotes first (clients need these)
Remotes.Init()

-- Initialize systems
local stageManager = StageManager.new()
local worldBuilder = WorldBuilder.new()
local materializer = DrawingMaterializer.new()
local enemyAI = EnemyAI.new()
local mechanics = StageMechanics.new()

-- Build the first two zones on startup
print("[Server] Building initial zones...")
worldBuilder:BuildZone(1)
worldBuilder:BuildZone(2)
print("[Server] Initial zones built")

-- Start enemy AI
enemyAI.StartAI()

-- Spawn enemies for stages that need them
local function spawnEnemiesForStage(stageId: number)
	local stageModel = worldBuilder:GetStageModel(stageId)
	if not stageModel then
		return
	end

	local enemySpawn = stageModel:FindFirstChild("EnemySpawn") :: Part?
	if not enemySpawn then
		return
	end

	local enemyType = enemySpawn:FindFirstChild("EnemyType") :: StringValue?
	if not enemyType then
		return
	end

	local patrolA = stageModel:FindFirstChild("PatrolA") :: Part?
	local patrolB = stageModel:FindFirstChild("PatrolB") :: Part?

	if patrolA and patrolB then
		enemyAI:SpawnEnemy(enemyType.Value, enemySpawn.Position, patrolA.Position, patrolB.Position)
	end
end

-- Spawn enemies and activate mechanics for initial stages
for stageId = 1, 10 do
	spawnEnemiesForStage(stageId)
	local stageModel = worldBuilder:GetStageModel(stageId)
	if stageModel then
		mechanics:ActivateStage(stageModel)
	end
end

-- Enemy kills player
enemyAI.OnPlayerTouched = function(player: Player)
	handlePlayerDeath(player)
end

-- Stage mechanics kill player (lasers, water, lightning, etc.)
mechanics.OnPlayerKill = function(player: Player)
	handlePlayerDeath(player)
end

-- Handle player death
function handlePlayerDeath(player: Player)
	stageManager:HandleDeath(player)
	materializer:RemovePlayerDrawings(player)

	local progress = stageManager:GetProgress(player)
	if not progress then
		return
	end

	-- Trigger jumpscare on client
	Remotes.FireClient("TriggerJumpscare", player)

	-- Respawn after delay
	task.delay(Constants.RESPAWN_DELAY, function()
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Teleport to stage spawn
				local spawnPos = stageManager:GetStageSpawnPosition(progress.CurrentStage)
				local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if rootPart then
					rootPart.CFrame = CFrame.new(spawnPos)
				end
				humanoid.Health = humanoid.MaxHealth
			end
		end

		-- Sync progress
		Remotes.FireClient("SyncProgress", player, progress)
	end)
end

-- Stage completion callback
stageManager.OnStageComplete = function(player: Player, stageId: number, stars: number)
	print(`[Server] {player.Name} completed Stage {stageId} with {stars} stars!`)

	local progress = stageManager:GetProgress(player)
	if not progress then
		return
	end

	-- Build next zone if needed
	local nextStage = StageConfig.GetStage(progress.CurrentStage)
	if nextStage then
		local zoneStart = (nextStage.Zone - 1) * Constants.STAGES_PER_ZONE + 1
		if not worldBuilder:GetStageModel(zoneStart) then
			worldBuilder:BuildZone(nextStage.Zone)
			-- Spawn enemies and activate mechanics for new zone
			for sId = zoneStart, zoneStart + Constants.STAGES_PER_ZONE - 1 do
				spawnEnemiesForStage(sId)
				local sModel = worldBuilder:GetStageModel(sId)
				if sModel then
					mechanics:ActivateStage(sModel)
				end
			end
		end
	end

	-- Fire completion event to client
	Remotes.FireClient("StageCompleted", player, stageId, stars)

	-- Teleport to next stage after a brief delay
	task.delay(2, function()
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				local spawnPos = stageManager:GetStageSpawnPosition(progress.CurrentStage)
				rootPart.CFrame = CFrame.new(spawnPos)
			end
		end

		-- Sync updated progress
		Remotes.FireClient("SyncProgress", player, progress)
		Remotes.FireClient("StageLoaded", player, progress.CurrentStage)
	end)
end

-- ================================================================
-- REMOTE EVENT HANDLERS
-- ================================================================

-- Player submits a drawing to be materialized
Remotes.Get("SubmitDrawing").OnServerEvent:Connect(function(player, drawingData)
	local progress = stageManager:GetProgress(player)
	if not progress then
		return
	end

	local stageDef = StageConfig.GetStage(progress.CurrentStage)
	if not stageDef then
		return
	end

	-- Validate drawing count
	local activeCount = materializer:GetPlayerDrawingCount(player)
	if activeCount >= stageDef.MaxDrawings then
		return
	end

	-- Validate it's actual drawing data
	if typeof(drawingData) ~= "table" or not drawingData.Strokes then
		return
	end

	-- Get spawn position (in front of the player)
	local character = player.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local spawnPos = rootPart.Position + rootPart.CFrame.LookVector * 8

	-- Track material used
	for _, stroke in drawingData.Strokes do
		if stroke.Material then
			stageManager:TrackMaterialUsed(player, stroke.Material)
		end
	end

	-- Materialize the drawing
	local model = materializer:Materialize(drawingData, spawnPos, player, stageDef.DrawingLifetime)

	if model then
		Remotes.FireClient("MaterializeDrawing", player, model)
	end
end)

-- Player requests respawn
Remotes.Get("RequestRespawn").OnServerEvent:Connect(function(player)
	handlePlayerDeath(player)
end)

-- Player requests hint
Remotes.Get("ShowHint").OnServerEvent:Connect(function(player)
	local progress = stageManager:GetProgress(player)
	if not progress then
		return
	end

	local stageDef = StageConfig.GetStage(progress.CurrentStage)
	if not stageDef then
		return
	end

	Remotes.FireClient("ShowHint", player, stageDef.Hint)
end)

-- ================================================================
-- PLAYER LIFECYCLE
-- ================================================================

local function onPlayerAdded(player: Player)
	print(`[Server] {player.Name} joined Draw to Escape`)

	-- Initialize progress
	stageManager:InitPlayer(player)

	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local stageValue = Instance.new("IntValue")
	stageValue.Name = "Stage"
	stageValue.Value = 1
	stageValue.Parent = leaderstats

	local starsValue = Instance.new("IntValue")
	starsValue.Name = "Stars"
	starsValue.Value = 0
	starsValue.Parent = leaderstats

	-- Handle character spawning
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid

		-- Teleport to current stage
		local progress = stageManager:GetProgress(player)
		if progress then
			task.wait(0.1)
			local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
			local spawnPos = stageManager:GetStageSpawnPosition(progress.CurrentStage)
			rootPart.CFrame = CFrame.new(spawnPos)

			-- Send stage info to client
			Remotes.FireClient("SyncProgress", player, progress)
			Remotes.FireClient("StageLoaded", player, progress.CurrentStage)
		end

		-- Death detection
		humanoid.Died:Connect(function()
			handlePlayerDeath(player)
		end)

		-- Fall death detection
		RunService.Heartbeat:Connect(function()
			if character.Parent and humanoid.Health > 0 then
				local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if rootPart and rootPart.Position.Y < Constants.DEATH_Y_THRESHOLD then
					humanoid.Health = 0
				end
			end
		end)
	end)
end

local function onPlayerRemoving(player: Player)
	print(`[Server] {player.Name} left Draw to Escape`)
	stageManager:RemovePlayer(player)
	materializer:RemovePlayerDrawings(player)
end

-- ================================================================
-- STAGE COMPLETION DETECTION
-- ================================================================

-- Check for players touching completion triggers
RunService.Heartbeat:Connect(function()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then
			continue
		end

		local progress = stageManager:GetProgress(player)
		if not progress then
			continue
		end

		-- Check if player reached the completion trigger
		local stageModel = worldBuilder:GetStageModel(progress.CurrentStage)
		if not stageModel then
			continue
		end

		local trigger = stageModel:FindFirstChild("CompletionTrigger") :: Part?
		if not trigger then
			continue
		end

		local dist = (rootPart.Position - trigger.Position).Magnitude
		if dist < 8 then
			local stars = stageManager:CompleteStage(player)
			if stars > 0 then
				-- Update leaderboard
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					local stageVal = leaderstats:FindFirstChild("Stage") :: IntValue?
					if stageVal then
						stageVal.Value = progress.CurrentStage
					end

					local starsVal = leaderstats:FindFirstChild("Stars") :: IntValue?
					if starsVal then
						local totalStars = 0
						for _, s in progress.StageStars do
							totalStars += s
						end
						starsVal.Value = totalStars
					end
				end
			end
		end

		-- Check timed stages
		if stageManager:IsStageTimedOut(player) then
			handlePlayerDeath(player)
		end
	end
end)

-- Connect player events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle already-connected players (Studio testing)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

print(`[Server] Draw to Escape v{Constants.GAME_VERSION} loaded!`)
