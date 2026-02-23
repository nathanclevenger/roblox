--!strict

--[[
	StageManager
	Handles stage progression, checkpoints, star ratings, and player state.
	Server-authoritative: all progression decisions happen here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local StageConfig = require(ReplicatedStorage.Shared.StageConfig)
local Types = require(ReplicatedStorage.Shared.Types)

type PlayerProgress = Types.PlayerProgress
type StageDefinition = Types.StageDefinition

local StageManager = {}
StageManager.__index = StageManager

type StageManagerImpl = {
	PlayerProgress: { [Player]: PlayerProgress },
	PlayerStageTimers: { [Player]: number },
	PlayerStageMaterials: { [Player]: { [string]: boolean } },
	OnStageComplete: ((Player, number, number) -> ())?,
	OnPlayerDeath: ((Player) -> ())?,
}

function StageManager.new(): StageManagerImpl
	local self = setmetatable({}, StageManager) :: any

	self.PlayerProgress = {}
	self.PlayerStageTimers = {}
	self.PlayerStageMaterials = {}
	self.OnStageComplete = nil
	self.OnPlayerDeath = nil

	return self :: StageManagerImpl
end

function StageManager.InitPlayer(self: StageManagerImpl, player: Player)
	self.PlayerProgress[player] = {
		CurrentStage = 1,
		HighestStage = 1,
		StageStars = {},
		UnlockedMaterials = table.clone(Constants.STARTING_MATERIALS),
		TotalDeaths = 0,
		TotalDrawings = 0,
		BestTimes = {},
	}
	self.PlayerStageTimers[player] = tick()
	self.PlayerStageMaterials[player] = {}
end

function StageManager.RemovePlayer(self: StageManagerImpl, player: Player)
	self.PlayerProgress[player] = nil
	self.PlayerStageTimers[player] = nil
	self.PlayerStageMaterials[player] = nil
end

function StageManager.GetProgress(self: StageManagerImpl, player: Player): PlayerProgress?
	return self.PlayerProgress[player]
end

function StageManager.GetCurrentStage(self: StageManagerImpl, player: Player): StageDefinition?
	local progress = self.PlayerProgress[player]
	if not progress then
		return nil
	end
	return StageConfig.GetStage(progress.CurrentStage)
end

function StageManager.GetUnlockedMaterials(self: StageManagerImpl, player: Player): { Types.DrawingMaterial }
	local progress = self.PlayerProgress[player]
	if not progress then
		return table.clone(Constants.STARTING_MATERIALS)
	end
	return progress.UnlockedMaterials
end

function StageManager.TrackMaterialUsed(self: StageManagerImpl, player: Player, material: string)
	if not self.PlayerStageMaterials[player] then
		self.PlayerStageMaterials[player] = {}
	end
	self.PlayerStageMaterials[player][material] = true

	local progress = self.PlayerProgress[player]
	if progress then
		progress.TotalDrawings += 1
	end
end

function StageManager.CompleteStage(self: StageManagerImpl, player: Player): number
	local progress = self.PlayerProgress[player]
	if not progress then
		return 0
	end

	local stageId = progress.CurrentStage
	local stageDef = StageConfig.GetStage(stageId)
	if not stageDef then
		return 0
	end

	-- Calculate time taken
	local timeTaken = tick() - (self.PlayerStageTimers[player] or tick())

	-- Calculate star rating
	local stars = 1 -- Always get 1 star for completing

	-- 2 stars: under par time
	if timeTaken <= stageDef.ParTime * Constants.STAR_TIME_MULTIPLIER then
		stars = 2
	end

	-- 3 stars: under par time AND used creative solution (3+ materials)
	local materialsUsed = self.PlayerStageMaterials[player] or {}
	local uniqueMaterials = 0
	for _ in materialsUsed do
		uniqueMaterials += 1
	end

	if timeTaken <= stageDef.ParTime and uniqueMaterials >= Constants.CREATIVE_SOLUTION_MIN_TYPES then
		stars = 3
	end

	-- Update progress
	local existingStars = progress.StageStars[stageId] or 0
	progress.StageStars[stageId] = math.max(existingStars, stars)

	-- Track best time
	local bestTime = progress.BestTimes[stageId]
	if not bestTime or timeTaken < bestTime then
		progress.BestTimes[stageId] = timeTaken
	end

	-- Advance to next stage
	local nextStage = stageId + 1
	if nextStage <= Constants.TOTAL_STAGES then
		progress.CurrentStage = nextStage
		progress.HighestStage = math.max(progress.HighestStage, nextStage)

		-- Check for new zone = new material unlocks
		local nextStageDef = StageConfig.GetStage(nextStage)
		if nextStageDef then
			local newZone = nextStageDef.Zone
			local unlocks = Constants.ZONE_MATERIAL_UNLOCKS[newZone]
			if unlocks then
				for _, mat in unlocks do
					if not table.find(progress.UnlockedMaterials, mat) then
						table.insert(progress.UnlockedMaterials, mat)
					end
				end
			end
		end

		-- Reset timer and materials for next stage
		self.PlayerStageTimers[player] = tick()
		self.PlayerStageMaterials[player] = {}
	end

	if self.OnStageComplete then
		self.OnStageComplete(player, stageId, stars)
	end

	return stars
end

function StageManager.HandleDeath(self: StageManagerImpl, player: Player)
	local progress = self.PlayerProgress[player]
	if not progress then
		return
	end

	progress.TotalDeaths += 1

	-- Reset stage timer
	self.PlayerStageTimers[player] = tick()
	self.PlayerStageMaterials[player] = {}

	if self.OnPlayerDeath then
		self.OnPlayerDeath(player)
	end
end

function StageManager.GetCheckpointStage(self: StageManagerImpl, player: Player): number
	local progress = self.PlayerProgress[player]
	if not progress then
		return 1
	end

	-- Checkpoint is the start of the current zone
	local currentStage = progress.CurrentStage
	local stageDef = StageConfig.GetStage(currentStage)
	if not stageDef then
		return 1
	end

	return (stageDef.Zone - 1) * Constants.STAGES_PER_ZONE + 1
end

function StageManager.GetStageSpawnPosition(_self: StageManagerImpl, stageId: number): Vector3
	-- Stages are laid out linearly along the Z axis
	local zOffset = (stageId - 1) * Constants.STAGE_SPACING
	return Vector3.new(0, 5, zOffset)
end

function StageManager.IsStageTimedOut(self: StageManagerImpl, player: Player): boolean
	local progress = self.PlayerProgress[player]
	if not progress then
		return false
	end

	local stageDef = StageConfig.GetStage(progress.CurrentStage)
	if not stageDef or not stageDef.TimeLimit then
		return false
	end

	local elapsed = tick() - (self.PlayerStageTimers[player] or tick())
	return elapsed >= stageDef.TimeLimit
end

function StageManager.GetTimeRemaining(self: StageManagerImpl, player: Player): number?
	local progress = self.PlayerProgress[player]
	if not progress then
		return nil
	end

	local stageDef = StageConfig.GetStage(progress.CurrentStage)
	if not stageDef or not stageDef.TimeLimit then
		return nil
	end

	local elapsed = tick() - (self.PlayerStageTimers[player] or tick())
	return math.max(0, stageDef.TimeLimit - elapsed)
end

return StageManager
