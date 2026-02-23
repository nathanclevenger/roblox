--!strict

--[[
	Spectator UI (Client)

	Renders the full-screen CCTV overlay when the player is in spectator mode.
	Includes scan lines, VHS timestamp, camera label, desaturated green tint,
	subtle static grain, and camera cycling controls.
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Constants = require(ReplicatedStorage.Shared.Constants)

local SpectatorUI = {}
SpectatorUI.__index = SpectatorUI

export type SpectatorUI = typeof(setmetatable(
	{} :: {
		screenGui: ScreenGui,
		container: Frame,
		scanLines: Frame,
		cameraLabel: TextLabel,
		timestamp: TextLabel,
		controlsHint: TextLabel,
		staticOverlay: Frame,
		colorCorrection: ColorCorrectionEffect?,
		isActive: boolean,
		grainConnection: RBXScriptConnection?,
		timestampConnection: RBXScriptConnection?,
		grainFrames: { Frame },
	},
	SpectatorUI
))

-- VHS-style colors
local COLOR_SCANLINE = Color3.fromRGB(0, 0, 0)
local COLOR_TINT = Color3.fromRGB(30, 60, 30) -- green CCTV tint
local COLOR_TEXT = Color3.fromRGB(200, 200, 200)
local COLOR_TEXT_SHADOW = Color3.fromRGB(0, 0, 0)
local SCANLINE_COUNT = 120
local GRAIN_CELL_COUNT = 30 -- per row and column

function SpectatorUI.new(parent: ScreenGui): SpectatorUI
	-- Main container (covers entire screen, hidden by default)
	local container = Instance.new("Frame")
	container.Name = "SpectatorOverlay"
	container.Size = UDim2.fromScale(1, 1)
	container.Position = UDim2.fromScale(0, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ZIndex = 50
	container.Visible = false
	container.Parent = parent

	-- Green tint overlay
	local tintOverlay = Instance.new("Frame")
	tintOverlay.Name = "TintOverlay"
	tintOverlay.Size = UDim2.fromScale(1, 1)
	tintOverlay.BackgroundColor3 = COLOR_TINT
	tintOverlay.BackgroundTransparency = 0.85
	tintOverlay.BorderSizePixel = 0
	tintOverlay.ZIndex = 51
	tintOverlay.Parent = container

	-- Scan lines overlay
	local scanLines = Instance.new("Frame")
	scanLines.Name = "ScanLines"
	scanLines.Size = UDim2.fromScale(1, 1)
	scanLines.BackgroundTransparency = 1
	scanLines.BorderSizePixel = 0
	scanLines.ZIndex = 52
	scanLines.Parent = container

	-- Create individual scan lines
	local lineHeight = 1 / SCANLINE_COUNT
	for i = 0, SCANLINE_COUNT - 1 do
		-- Only draw every other line for the scan effect
		if i % 2 == 0 then
			local line = Instance.new("Frame")
			line.Name = `ScanLine_{i}`
			line.Size = UDim2.new(1, 0, 0, 1)
			line.Position = UDim2.fromScale(0, i * lineHeight)
			line.BackgroundColor3 = COLOR_SCANLINE
			line.BackgroundTransparency = 0.88
			line.BorderSizePixel = 0
			line.ZIndex = 53
			line.Parent = scanLines
		end
	end

	-- Static/grain overlay (a grid of semi-transparent cells that randomize)
	local staticOverlay = Instance.new("Frame")
	staticOverlay.Name = "StaticOverlay"
	staticOverlay.Size = UDim2.fromScale(1, 1)
	staticOverlay.BackgroundTransparency = 1
	staticOverlay.BorderSizePixel = 0
	staticOverlay.ZIndex = 54
	staticOverlay.Parent = container

	local grainFrames: { Frame } = {}
	local cellSize = 1 / GRAIN_CELL_COUNT
	for row = 0, GRAIN_CELL_COUNT - 1 do
		for col = 0, GRAIN_CELL_COUNT - 1 do
			local cell = Instance.new("Frame")
			cell.Size = UDim2.fromScale(cellSize, cellSize)
			cell.Position = UDim2.fromScale(col * cellSize, row * cellSize)
			cell.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			cell.BackgroundTransparency = 1 -- start fully transparent
			cell.BorderSizePixel = 0
			cell.ZIndex = 55
			cell.Parent = staticOverlay
			table.insert(grainFrames, cell)
		end
	end

	-- Camera label (top-left)
	local cameraLabel = Instance.new("TextLabel")
	cameraLabel.Name = "CameraLabel"
	cameraLabel.Size = UDim2.new(0, 400, 0, 40)
	cameraLabel.Position = UDim2.new(0, 24, 0, 24)
	cameraLabel.BackgroundTransparency = 1
	cameraLabel.Font = Enum.Font.RobotoMono
	cameraLabel.TextSize = 22
	cameraLabel.TextColor3 = COLOR_TEXT
	cameraLabel.TextStrokeColor3 = COLOR_TEXT_SHADOW
	cameraLabel.TextStrokeTransparency = 0.4
	cameraLabel.TextXAlignment = Enum.TextXAlignment.Left
	cameraLabel.TextYAlignment = Enum.TextYAlignment.Top
	cameraLabel.Text = "CAM 01 - RECEPTION"
	cameraLabel.ZIndex = 60
	cameraLabel.Parent = container

	-- REC indicator (blinking dot next to camera label)
	local recIndicator = Instance.new("TextLabel")
	recIndicator.Name = "RecIndicator"
	recIndicator.Size = UDim2.new(0, 80, 0, 30)
	recIndicator.Position = UDim2.new(0, 24, 0, 60)
	recIndicator.BackgroundTransparency = 1
	recIndicator.Font = Enum.Font.RobotoMono
	recIndicator.TextSize = 18
	recIndicator.TextColor3 = Color3.fromRGB(200, 40, 40)
	recIndicator.TextStrokeColor3 = COLOR_TEXT_SHADOW
	recIndicator.TextStrokeTransparency = 0.5
	recIndicator.TextXAlignment = Enum.TextXAlignment.Left
	recIndicator.Text = "● REC"
	recIndicator.ZIndex = 60
	recIndicator.Parent = container

	-- VHS timestamp (bottom-right)
	local timestamp = Instance.new("TextLabel")
	timestamp.Name = "Timestamp"
	timestamp.Size = UDim2.new(0, 300, 0, 30)
	timestamp.Position = UDim2.new(1, -24, 1, -48)
	timestamp.AnchorPoint = Vector2.new(1, 1)
	timestamp.BackgroundTransparency = 1
	timestamp.Font = Enum.Font.RobotoMono
	timestamp.TextSize = 18
	timestamp.TextColor3 = COLOR_TEXT
	timestamp.TextStrokeColor3 = COLOR_TEXT_SHADOW
	timestamp.TextStrokeTransparency = 0.5
	timestamp.TextXAlignment = Enum.TextXAlignment.Right
	timestamp.TextYAlignment = Enum.TextYAlignment.Bottom
	timestamp.Text = "03/15/1997  02:34:17 AM"
	timestamp.ZIndex = 60
	timestamp.Parent = container

	-- Controls hint (bottom-center)
	local controlsHint = Instance.new("TextLabel")
	controlsHint.Name = "ControlsHint"
	controlsHint.Size = UDim2.new(0, 500, 0, 30)
	controlsHint.Position = UDim2.new(0.5, 0, 1, -24)
	controlsHint.AnchorPoint = Vector2.new(0.5, 1)
	controlsHint.BackgroundTransparency = 1
	controlsHint.Font = Enum.Font.RobotoMono
	controlsHint.TextSize = 16
	controlsHint.TextColor3 = Color3.fromRGB(160, 160, 160)
	controlsHint.TextStrokeColor3 = COLOR_TEXT_SHADOW
	controlsHint.TextStrokeTransparency = 0.5
	controlsHint.TextXAlignment = Enum.TextXAlignment.Center
	controlsHint.TextYAlignment = Enum.TextYAlignment.Bottom
	controlsHint.Text = "[Q] Prev Camera    [E] Next Camera"
	controlsHint.ZIndex = 60
	controlsHint.Parent = container

	-- Vignette corners (dark edges)
	local vignette = Instance.new("Frame")
	vignette.Name = "Vignette"
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundTransparency = 1
	vignette.BorderSizePixel = 0
	vignette.ZIndex = 56
	vignette.Parent = container

	-- Top vignette edge
	local topVig = Instance.new("Frame")
	topVig.Size = UDim2.new(1, 0, 0.15, 0)
	topVig.Position = UDim2.fromScale(0, 0)
	topVig.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	topVig.BackgroundTransparency = 0.5
	topVig.BorderSizePixel = 0
	topVig.Parent = vignette

	local topGrad = Instance.new("UIGradient")
	topGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	topGrad.Rotation = 90
	topGrad.Parent = topVig

	-- Bottom vignette edge
	local botVig = Instance.new("Frame")
	botVig.Size = UDim2.new(1, 0, 0.15, 0)
	botVig.Position = UDim2.new(0, 0, 0.85, 0)
	botVig.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	botVig.BackgroundTransparency = 0.5
	botVig.BorderSizePixel = 0
	botVig.Parent = vignette

	local botGrad = Instance.new("UIGradient")
	botGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	botGrad.Rotation = 90
	botGrad.Parent = botVig

	local self = setmetatable({
		screenGui = parent,
		container = container,
		scanLines = scanLines,
		cameraLabel = cameraLabel,
		timestamp = timestamp,
		controlsHint = controlsHint,
		staticOverlay = staticOverlay,
		colorCorrection = nil :: ColorCorrectionEffect?,
		isActive = false,
		grainConnection = nil :: RBXScriptConnection?,
		timestampConnection = nil :: RBXScriptConnection?,
		grainFrames = grainFrames,
	}, SpectatorUI)

	return self
end

--[[
	Activate the spectator overlay. Creates a color correction effect for
	desaturation and starts the grain animation loop.
]]
function SpectatorUI.enter(self: SpectatorUI, cameraName: string?)
	if self.isActive then
		return
	end

	self.isActive = true
	self.container.Visible = true

	-- Set initial camera label
	if cameraName then
		self.cameraLabel.Text = cameraName
	end

	-- Add color correction for desaturation
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "SpectatorCC"
	cc.Saturation = Constants.CCTV_DESATURATION
	cc.TintColor = Color3.fromRGB(200, 220, 200) -- slight green tint
	cc.Brightness = -0.05
	cc.Contrast = 0.1
	cc.Parent = Lighting
	self.colorCorrection = cc

	-- Start grain animation (randomize cell transparency each frame)
	self.grainConnection = RunService.Heartbeat:Connect(function()
		-- Only update a subset each frame for performance
		local updateCount = math.min(80, #self.grainFrames)
		for _ = 1, updateCount do
			local idx = math.random(1, #self.grainFrames)
			local cell = self.grainFrames[idx]
			-- Random transparency between 0.88 and 1.0 for subtle grain
			local intensity = Constants.CCTV_STATIC_INTENSITY
			local trans = 1 - (math.random() * intensity)
			cell.BackgroundTransparency = trans
		end
	end)

	-- Start VHS timestamp update (fake date that ticks)
	local fakeHour = math.random(0, 23)
	local fakeMinute = math.random(0, 59)
	local fakeSecond = math.random(0, 59)
	local fakeMonth = math.random(1, 12)
	local fakeDay = math.random(1, 28)

	self.timestampConnection = RunService.Heartbeat:Connect(function(dt: number)
		fakeSecond += dt
		if fakeSecond >= 60 then
			fakeSecond -= 60
			fakeMinute += 1
			if fakeMinute >= 60 then
				fakeMinute -= 60
				fakeHour += 1
				if fakeHour >= 24 then
					fakeHour = 0
				end
			end
		end

		local ampm = if fakeHour >= 12 then "PM" else "AM"
		local displayHour = fakeHour % 12
		if displayHour == 0 then
			displayHour = 12
		end

		self.timestamp.Text = string.format(
			"%02d/%02d/1997  %02d:%02d:%02d %s",
			fakeMonth,
			fakeDay,
			displayHour,
			math.floor(fakeMinute),
			math.floor(fakeSecond),
			ampm
		)
	end)

	print("[SpectatorUI] Entered spectator view")
end

--[[
	Deactivate the spectator overlay. Cleans up color correction and animations.
]]
function SpectatorUI.exit(self: SpectatorUI)
	if not self.isActive then
		return
	end

	self.isActive = false
	self.container.Visible = false

	-- Remove color correction
	if self.colorCorrection then
		self.colorCorrection:Destroy()
		self.colorCorrection = nil
	end

	-- Stop grain animation
	if self.grainConnection then
		self.grainConnection:Disconnect()
		self.grainConnection = nil
	end

	-- Stop timestamp
	if self.timestampConnection then
		self.timestampConnection:Disconnect()
		self.timestampConnection = nil
	end

	-- Reset grain cells
	for _, cell in self.grainFrames do
		cell.BackgroundTransparency = 1
	end

	print("[SpectatorUI] Exited spectator view")
end

--[[
	Update the displayed camera name when switching cameras.
]]
function SpectatorUI.updateCamera(self: SpectatorUI, cameraName: string, index: number, total: number)
	self.cameraLabel.Text = cameraName
end

return SpectatorUI
