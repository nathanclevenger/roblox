--!strict

--[[
	Draw to Escape — Client Entry Point
	Wires up the drawing canvas, HUD, jumpscare system,
	and handles remote events from the server.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local StageConfig = require(ReplicatedStorage.Shared.StageConfig)

local DrawingCanvas = require(script.Parent.DrawingCanvas)
local GameHUD = require(script.Parent.GameHUD)
local JumpscareUI = require(script.Parent.JumpscareUI)
local SoundManager = require(script.Parent.SoundManager)
local VictoryScreen = require(script.Parent.VictoryScreen)

-- Wait for remotes to be ready
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local function getRemote(name: string): RemoteEvent
	return remotesFolder:WaitForChild(name) :: RemoteEvent
end

-- Initialize UI systems
local canvas = DrawingCanvas.new()
local hud = GameHUD.new()
local jumpscare = JumpscareUI.new()
local victoryScreen = VictoryScreen.new()

-- Initialize audio
SoundManager:Init()
SoundManager:PlayMusic(1)

local isCanvasOpen = false
local currentZone = 1

-- ================================================================
-- DRAWING CANVAS
-- ================================================================

canvas.OnSubmit = function(drawingData)
	-- Send to server for materialization
	getRemote("SubmitDrawing"):FireServer(drawingData)
	SoundManager:PlaySFX("Materialize")
	isCanvasOpen = false
end

canvas.OnClose = function()
	isCanvasOpen = false
end

-- ================================================================
-- HUD CALLBACKS
-- ================================================================

hud.OnDrawPressed = function()
	if not isCanvasOpen then
		isCanvasOpen = true
		canvas:Open()
	end
end

hud.OnHintPressed = function()
	getRemote("ShowHint"):FireServer()
end

-- ================================================================
-- REMOTE EVENT HANDLERS
-- ================================================================

-- Server syncs player progress
getRemote("SyncProgress").OnClientEvent:Connect(function(progress)
	if typeof(progress) ~= "table" then
		return
	end

	hud:UpdateDeaths(progress.TotalDeaths or 0)

	-- Update available materials on canvas
	if progress.UnlockedMaterials then
		canvas:SetAvailableMaterials(progress.UnlockedMaterials)
	end
end)

-- Server notifies new stage loaded
getRemote("StageLoaded").OnClientEvent:Connect(function(stageId)
	if typeof(stageId) ~= "number" then
		return
	end

	local stageDef = StageConfig.GetStage(stageId)
	if stageDef then
		hud:UpdateStage(stageId, stageDef.Name, stageDef.ZoneName)
		hud:ResetStars()

		-- Switch zone music if zone changed
		if stageDef.Zone ~= currentZone then
			currentZone = stageDef.Zone
			SoundManager:PlayMusic(currentZone)
		end

		-- Show stage description briefly as a hint
		hud:ShowHint(stageDef.Description)
	end
end)

-- Server notifies stage completion
getRemote("StageCompleted").OnClientEvent:Connect(function(stageId, stars)
	if typeof(stars) ~= "number" then
		return
	end

	hud:ShowStageComplete(stars)
	SoundManager:PlaySFX("StageComplete")

	-- Show completion message
	local stageDef = StageConfig.GetStage(stageId)
	if stageDef then
		print(`[Client] Completed Stage {stageId}: {stageDef.Name} with {stars} star(s)!`)
	end

	-- Show victory screen on final stage
	if stageId >= Constants.TOTAL_STAGES then
		SoundManager:StopMusic()
		SoundManager:PlaySFX("VictoryFanfare")
		victoryScreen:Show({
			TotalStars = stars,
			TotalDrawings = 0,
			TotalDeaths = 0,
			BestTime = "N/A",
		})
	end
end)

-- Server triggers jumpscare on death
getRemote("TriggerJumpscare").OnClientEvent:Connect(function()
	-- Close canvas if open
	if isCanvasOpen then
		canvas:Close()
		isCanvasOpen = false
	end

	jumpscare:Play()
	SoundManager:PlaySFX("Death")
end)

-- Server sends hint text
getRemote("ShowHint").OnClientEvent:Connect(function(hint)
	if typeof(hint) == "string" then
		hud:ShowHint(hint)
	end
end)

-- Server notifies timer update
getRemote("UpdateTimer").OnClientEvent:Connect(function(timeRemaining)
	if typeof(timeRemaining) == "number" then
		hud:UpdateTimer(timeRemaining)
	else
		hud:UpdateTimer(nil)
	end
end)

-- ================================================================
-- KEYBOARD SHORTCUTS
-- ================================================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	-- E key to open/close canvas
	if input.KeyCode == Enum.KeyCode.E then
		if isCanvasOpen then
			canvas:Close()
			isCanvasOpen = false
		else
			isCanvasOpen = true
			canvas:Open()
		end
	end

	-- H key for hint
	if input.KeyCode == Enum.KeyCode.H then
		getRemote("ShowHint"):FireServer()
	end

	-- R key to request respawn (if stuck)
	if input.KeyCode == Enum.KeyCode.R then
		getRemote("RequestRespawn"):FireServer()
	end
end)

-- ================================================================
-- INITIALIZATION
-- ================================================================

print(`[Client] Draw to Escape v{Constants.GAME_VERSION} loaded!`)
print("[Client] Press E to draw, H for hint, R to respawn")
