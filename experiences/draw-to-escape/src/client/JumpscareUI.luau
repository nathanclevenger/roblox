--!strict

--[[
	JumpscareUI
	Handles death jumpscare animation: screen flash, distortion,
	creepy visual, screen shake, and respawn transition.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)

local LocalPlayer = Players.LocalPlayer

local JumpscareUI = {}
JumpscareUI.__index = JumpscareUI

type JumpscareUIImpl = {
	ScreenGui: ScreenGui,
	FlashFrame: Frame,
	ScaryFrame: Frame,
	DistortionFrame: Frame,
	TextLabel: TextLabel,
	IsPlaying: boolean,
	_shakeConn: RBXScriptConnection?,
}

-- Creepy messages that show during jumpscare
local DEATH_MESSAGES = {
	"YOU FELL",
	"NOT GOOD ENOUGH",
	"TRY AGAIN",
	"DRAW BETTER",
	"THE VOID CLAIMS ALL",
	"BACK TO THE START",
	"OOPS",
	"SO CLOSE",
	"THINK HARDER",
	"DRAW FASTER",
}

-- Ink splatter shapes for the death screen
local SPLATTER_COUNT = 8

function JumpscareUI.new(): JumpscareUIImpl
	local self = setmetatable({}, JumpscareUI) :: any

	self.IsPlaying = false
	self._shakeConn = nil

	self:_buildUI()

	return self :: JumpscareUIImpl
end

function JumpscareUI._buildUI(self: JumpscareUIImpl)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "JumpscareUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = false
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	self.ScreenGui = screenGui

	-- White flash frame
	local flashFrame = Instance.new("Frame")
	flashFrame.Name = "Flash"
	flashFrame.Size = UDim2.fromScale(1, 1)
	flashFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flashFrame.BackgroundTransparency = 1
	flashFrame.BorderSizePixel = 0
	flashFrame.ZIndex = 10
	flashFrame.Parent = screenGui
	self.FlashFrame = flashFrame

	-- Scary distortion / dark overlay
	local distortionFrame = Instance.new("Frame")
	distortionFrame.Name = "Distortion"
	distortionFrame.Size = UDim2.fromScale(1, 1)
	distortionFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	distortionFrame.BackgroundTransparency = 1
	distortionFrame.BorderSizePixel = 0
	distortionFrame.ZIndex = 8
	distortionFrame.Parent = screenGui
	self.DistortionFrame = distortionFrame

	-- Scary visual frame (ink splatter / creepy drawing)
	local scaryFrame = Instance.new("Frame")
	scaryFrame.Name = "ScaryVisual"
	scaryFrame.Size = UDim2.fromScale(1, 1)
	scaryFrame.BackgroundTransparency = 1
	scaryFrame.BorderSizePixel = 0
	scaryFrame.ZIndex = 9
	scaryFrame.Parent = screenGui
	self.ScaryFrame = scaryFrame

	-- Create ink splatter elements
	for i = 1, SPLATTER_COUNT do
		local splat = Instance.new("Frame")
		splat.Name = `Splat_{i}`
		splat.Size = UDim2.fromOffset(math.random(80, 300), math.random(80, 300))
		splat.Position = UDim2.fromScale(math.random() * 0.8 + 0.1, math.random() * 0.8 + 0.1)
		splat.AnchorPoint = Vector2.new(0.5, 0.5)
		splat.Rotation = math.random(0, 360)
		splat.BackgroundColor3 = Color3.fromRGB(math.random(10, 40), math.random(0, 10), math.random(0, 15))
		splat.BackgroundTransparency = 1
		splat.BorderSizePixel = 0
		splat.Parent = scaryFrame

		local splatCorner = Instance.new("UICorner")
		splatCorner.CornerRadius = UDim.new(0.5, 0)
		splatCorner.Parent = splat
	end

	-- Death text
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "DeathText"
	textLabel.Size = UDim2.fromScale(0.8, 0.3)
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "YOU DIED"
	textLabel.TextColor3 = Color3.fromRGB(200, 20, 20)
	textLabel.TextSize = 72
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.TextTransparency = 1
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextStrokeTransparency = 1
	textLabel.ZIndex = 11
	textLabel.Parent = screenGui
	self.TextLabel = textLabel
end

function JumpscareUI.Play(self: JumpscareUIImpl, deathMessage: string?)
	if self.IsPlaying then
		return
	end
	self.IsPlaying = true
	self.ScreenGui.Enabled = true

	local message = deathMessage or DEATH_MESSAGES[math.random(1, #DEATH_MESSAGES)]
	self.TextLabel.Text = message

	-- Phase 1: Sudden white flash (0 - 0.15s)
	self.FlashFrame.BackgroundTransparency = 0

	local flashOut = TweenService:Create(
		self.FlashFrame,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)

	-- Phase 2: Dark overlay slams in + ink splatters appear (0.1 - 0.4s)
	task.delay(0.1, function()
		-- Dark background
		local darkIn = TweenService:Create(
			self.DistortionFrame,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0.1 }
		)
		darkIn:Play()

		-- Splatters appear in sequence
		for _, child in self.ScaryFrame:GetChildren() do
			if child:IsA("Frame") then
				task.delay(math.random() * 0.2, function()
					local splatIn = TweenService:Create(
						child,
						TweenInfo.new(0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
						{ BackgroundTransparency = 0, Size = child.Size + UDim2.fromOffset(30, 30) }
					)
					splatIn:Play()
				end)
			end
		end
	end)

	-- Phase 3: Death text appears with scale punch (0.2s)
	task.delay(0.15, function()
		self.TextLabel.TextTransparency = 0
		self.TextLabel.TextStrokeTransparency = 0.3
		self.TextLabel.TextSize = 120

		local textShrink = TweenService:Create(
			self.TextLabel,
			TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ TextSize = 72 }
		)
		textShrink:Play()
	end)

	-- Screen shake
	self:_startShake()

	flashOut:Play()

	-- Phase 4: Hold for dramatic effect then fade out
	task.delay(Constants.JUMPSCARE_DURATION, function()
		self:_stopShake()

		-- Fade everything out
		local fadeTime = 0.5

		TweenService:Create(
			self.DistortionFrame,
			TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		):Play()

		TweenService:Create(
			self.TextLabel,
			TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ TextTransparency = 1, TextStrokeTransparency = 1 }
		):Play()

		for _, child in self.ScaryFrame:GetChildren() do
			if child:IsA("Frame") then
				TweenService:Create(
					child,
					TweenInfo.new(fadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ BackgroundTransparency = 1 }
				):Play()
			end
		end

		task.delay(fadeTime + 0.1, function()
			self.ScreenGui.Enabled = false
			self.IsPlaying = false
			self:_resetElements()
		end)
	end)
end

function JumpscareUI._startShake(self: JumpscareUIImpl)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local elapsed = 0

	self._shakeConn = RunService.RenderStepped:Connect(function(dt)
		elapsed += dt

		local intensity = Constants.SCREEN_SHAKE_INTENSITY * math.max(0, 1 - elapsed / Constants.JUMPSCARE_DURATION)
		local freq = Constants.SCREEN_SHAKE_FREQUENCY

		local offsetX = math.sin(elapsed * freq) * intensity * (math.random() - 0.5) * 2
		local offsetY = math.cos(elapsed * freq * 1.3) * intensity * (math.random() - 0.5) * 2

		if camera then
			camera.CFrame = camera.CFrame * CFrame.new(offsetX * 0.01, offsetY * 0.01, 0)
		end
	end)
end

function JumpscareUI._stopShake(self: JumpscareUIImpl)
	if self._shakeConn then
		self._shakeConn:Disconnect()
		self._shakeConn = nil
	end
end

function JumpscareUI._resetElements(self: JumpscareUIImpl)
	self.FlashFrame.BackgroundTransparency = 1
	self.DistortionFrame.BackgroundTransparency = 1
	self.TextLabel.TextTransparency = 1
	self.TextLabel.TextStrokeTransparency = 1

	for _, child in self.ScaryFrame:GetChildren() do
		if child:IsA("Frame") then
			child.BackgroundTransparency = 1
		end
	end
end

function JumpscareUI.Destroy(self: JumpscareUIImpl)
	self:_stopShake()
	if self.ScreenGui.Parent then
		self.ScreenGui:Destroy()
	end
end

return JumpscareUI
