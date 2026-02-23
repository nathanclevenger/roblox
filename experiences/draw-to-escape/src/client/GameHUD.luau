--!strict

--[[
	GameHUD
	Heads-up display showing stage info, timer, hint button,
	draw button, and progress indicators.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local GameHUD = {}
GameHUD.__index = GameHUD

type GameHUDImpl = {
	ScreenGui: ScreenGui,
	StageLabel: TextLabel,
	ZoneLabel: TextLabel,
	TimerLabel: TextLabel,
	HintLabel: TextLabel,
	StarFrames: { Frame },
	DeathCounter: TextLabel,
	DrawButton: TextButton,
	HintButton: TextButton,
	OnDrawPressed: (() -> ())?,
	OnHintPressed: (() -> ())?,
	_connections: { RBXScriptConnection },
}

function GameHUD.new(): GameHUDImpl
	local self = setmetatable({}, GameHUD) :: any

	self.StarFrames = {}
	self.OnDrawPressed = nil
	self.OnHintPressed = nil
	self._connections = {}

	self:_buildUI()

	return self :: GameHUDImpl
end

function GameHUD._buildUI(self: GameHUDImpl)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	self.ScreenGui = screenGui

	-- Top bar container
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.Size = UDim2.new(1, 0, 0, 50)
	topBar.Position = UDim2.fromOffset(0, 0)
	topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	topBar.BackgroundTransparency = 0.5
	topBar.BorderSizePixel = 0
	topBar.Parent = screenGui

	-- Zone name (top left)
	local zoneLabel = Instance.new("TextLabel")
	zoneLabel.Name = "ZoneLabel"
	zoneLabel.Size = UDim2.new(0.3, 0, 0, 20)
	zoneLabel.Position = UDim2.fromOffset(16, 6)
	zoneLabel.BackgroundTransparency = 1
	zoneLabel.Text = "Zone 1: The Sketch Fields"
	zoneLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	zoneLabel.TextSize = 13
	zoneLabel.Font = Enum.Font.Gotham
	zoneLabel.TextXAlignment = Enum.TextXAlignment.Left
	zoneLabel.Parent = topBar
	self.ZoneLabel = zoneLabel

	-- Stage name (top left, below zone)
	local stageLabel = Instance.new("TextLabel")
	stageLabel.Name = "StageLabel"
	stageLabel.Size = UDim2.new(0.4, 0, 0, 24)
	stageLabel.Position = UDim2.fromOffset(16, 24)
	stageLabel.BackgroundTransparency = 1
	stageLabel.Text = "Stage 1: The Step"
	stageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	stageLabel.TextSize = 16
	stageLabel.Font = Enum.Font.GothamBold
	stageLabel.TextXAlignment = Enum.TextXAlignment.Left
	stageLabel.Parent = topBar
	self.StageLabel = stageLabel

	-- Timer (top center)
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.fromOffset(120, 36)
	timerLabel.Position = UDim2.new(0.5, -60, 0, 7)
	timerLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	timerLabel.BackgroundTransparency = 0.6
	timerLabel.Text = ""
	timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerLabel.TextSize = 22
	timerLabel.Font = Enum.Font.Code
	timerLabel.Parent = topBar
	self.TimerLabel = timerLabel

	local timerCorner = Instance.new("UICorner")
	timerCorner.CornerRadius = UDim.new(0, 6)
	timerCorner.Parent = timerLabel

	-- Stars (top right area)
	for i = 1, 3 do
		local starFrame = Instance.new("Frame")
		starFrame.Name = `Star_{i}`
		starFrame.Size = UDim2.fromOffset(24, 24)
		starFrame.Position = UDim2.new(1, -100 + (i - 1) * 28, 0, 13)
		starFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		starFrame.BackgroundTransparency = 0.5
		starFrame.Parent = topBar

		local starCorner = Instance.new("UICorner")
		starCorner.CornerRadius = UDim.new(0.5, 0)
		starCorner.Parent = starFrame

		local starLabel = Instance.new("TextLabel")
		starLabel.Size = UDim2.fromScale(1, 1)
		starLabel.BackgroundTransparency = 1
		starLabel.Text = "*"
		starLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
		starLabel.TextSize = 20
		starLabel.Font = Enum.Font.GothamBold
		starLabel.Parent = starFrame

		table.insert(self.StarFrames, starFrame)
	end

	-- Death counter (top right)
	local deathCounter = Instance.new("TextLabel")
	deathCounter.Name = "DeathCounter"
	deathCounter.Size = UDim2.fromOffset(60, 20)
	deathCounter.Position = UDim2.new(1, -60, 0, 42)
	deathCounter.BackgroundTransparency = 1
	deathCounter.Text = "Deaths: 0"
	deathCounter.TextColor3 = Color3.fromRGB(200, 80, 80)
	deathCounter.TextSize = 11
	deathCounter.Font = Enum.Font.Gotham
	deathCounter.TextXAlignment = Enum.TextXAlignment.Right
	deathCounter.Parent = topBar
	self.DeathCounter = deathCounter

	-- Hint display (bottom center)
	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "HintLabel"
	hintLabel.Size = UDim2.new(0.6, 0, 0, 40)
	hintLabel.Position = UDim2.new(0.2, 0, 1, -120)
	hintLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	hintLabel.BackgroundTransparency = 0.4
	hintLabel.Text = ""
	hintLabel.TextColor3 = Color3.fromRGB(255, 230, 150)
	hintLabel.TextSize = 14
	hintLabel.Font = Enum.Font.GothamMedium
	hintLabel.TextWrapped = true
	hintLabel.Visible = false
	hintLabel.Parent = screenGui
	self.HintLabel = hintLabel

	local hintCorner = Instance.new("UICorner")
	hintCorner.CornerRadius = UDim.new(0, 8)
	hintCorner.Parent = hintLabel

	-- Draw button (bottom right)
	local drawButton = Instance.new("TextButton")
	drawButton.Name = "DrawButton"
	drawButton.Size = UDim2.fromOffset(120, 50)
	drawButton.Position = UDim2.new(1, -140, 1, -80)
	drawButton.BackgroundColor3 = Color3.fromRGB(60, 140, 220)
	drawButton.Text = "DRAW"
	drawButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	drawButton.TextSize = 20
	drawButton.Font = Enum.Font.GothamBlack
	drawButton.Parent = screenGui
	self.DrawButton = drawButton

	local drawBtnCorner = Instance.new("UICorner")
	drawBtnCorner.CornerRadius = UDim.new(0, 10)
	drawBtnCorner.Parent = drawButton

	local drawBtnStroke = Instance.new("UIStroke")
	drawBtnStroke.Color = Color3.fromRGB(100, 180, 255)
	drawBtnStroke.Thickness = 2
	drawBtnStroke.Parent = drawButton

	-- Hint button (bottom right, above draw)
	local hintButton = Instance.new("TextButton")
	hintButton.Name = "HintButton"
	hintButton.Size = UDim2.fromOffset(80, 30)
	hintButton.Position = UDim2.new(1, -100, 1, -140)
	hintButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	hintButton.Text = "Hint?"
	hintButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	hintButton.TextSize = 14
	hintButton.Font = Enum.Font.GothamBold
	hintButton.Parent = screenGui
	self.HintButton = hintButton

	local hintBtnCorner = Instance.new("UICorner")
	hintBtnCorner.CornerRadius = UDim.new(0, 8)
	hintBtnCorner.Parent = hintButton

	-- Wire up buttons
	table.insert(
		self._connections,
		drawButton.MouseButton1Click:Connect(function()
			if self.OnDrawPressed then
				self.OnDrawPressed()
			end
		end)
	)

	table.insert(
		self._connections,
		hintButton.MouseButton1Click:Connect(function()
			if self.OnHintPressed then
				self.OnHintPressed()
			end
		end)
	)
end

function GameHUD.UpdateStage(self: GameHUDImpl, stageId: number, stageName: string, zoneName: string)
	self.StageLabel.Text = `Stage {stageId}: {stageName}`
	self.ZoneLabel.Text = zoneName
end

function GameHUD.UpdateTimer(self: GameHUDImpl, timeRemaining: number?)
	if timeRemaining then
		local seconds = math.ceil(timeRemaining)
		self.TimerLabel.Text = string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
		self.TimerLabel.Visible = true

		-- Flash red when low time
		if timeRemaining <= 10 then
			self.TimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		else
			self.TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	else
		self.TimerLabel.Text = ""
		self.TimerLabel.Visible = false
	end
end

function GameHUD.UpdateDeaths(self: GameHUDImpl, deaths: number)
	self.DeathCounter.Text = `Deaths: {deaths}`
end

function GameHUD.ShowHint(self: GameHUDImpl, hint: string)
	self.HintLabel.Text = hint
	self.HintLabel.Visible = true
	self.HintLabel.TextTransparency = 0

	-- Auto-hide after 5 seconds
	task.delay(5, function()
		local fadeOut = TweenService:Create(
			self.HintLabel,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ TextTransparency = 1 }
		)
		fadeOut:Play()
		task.delay(0.5, function()
			self.HintLabel.Visible = false
		end)
	end)
end

function GameHUD.ShowStageComplete(self: GameHUDImpl, stars: number)
	-- Light up stars
	for i, frame in self.StarFrames do
		if i <= stars then
			task.delay((i - 1) * 0.2, function()
				frame.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
				frame.BackgroundTransparency = 0

				local label = frame:FindFirstChildOfClass("TextLabel")
				if label then
					label.TextColor3 = Color3.fromRGB(255, 200, 50)
				end

				-- Pop animation
				local popOut = TweenService:Create(
					frame,
					TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Size = UDim2.fromOffset(32, 32) }
				)
				popOut:Play()

				task.delay(0.15, function()
					local popIn = TweenService:Create(
						frame,
						TweenInfo.new(0.1, Enum.EasingStyle.Quad),
						{ Size = UDim2.fromOffset(24, 24) }
					)
					popIn:Play()
				end)
			end)
		end
	end
end

function GameHUD.ResetStars(self: GameHUDImpl)
	for _, frame in self.StarFrames do
		frame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		frame.BackgroundTransparency = 0.5
		frame.Size = UDim2.fromOffset(24, 24)

		local label = frame:FindFirstChildOfClass("TextLabel")
		if label then
			label.TextColor3 = Color3.fromRGB(120, 120, 120)
		end
	end
end

function GameHUD.Destroy(self: GameHUDImpl)
	for _, conn in self._connections do
		conn:Disconnect()
	end
	self._connections = {}

	if self.ScreenGui.Parent then
		self.ScreenGui:Destroy()
	end
end

return GameHUD
