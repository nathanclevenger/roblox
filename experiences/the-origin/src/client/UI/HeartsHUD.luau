--!strict

--[[
	Hearts HUD (Client)

	Persistent HUD element showing 3 heart icons in the bottom-left of the screen.
	Each heart represents a life. As hearts are lost, they transition to a cracked,
	dimmed outline state. The last remaining heart pulses rapidly to convey fragility.

	Hearts pulse in sync with the Proximity Fear heartbeat at Tier 2+.
	Faint thread-like connections run between the hearts.
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local HEART_SIZE = UDim2.fromOffset(28, 26)
local HEART_GAP = 8
local CONTAINER_PADDING = 16
local MAX_HEARTS = 3

-- Colors
local COLOR_HEART_FILL = Color3.fromRGB(160, 25, 20) -- deep warm red
local COLOR_HEART_GLOW = Color3.fromRGB(200, 50, 30) -- inner glow
local COLOR_HEART_CRACKED = Color3.fromRGB(60, 30, 30) -- dim cracked outline
local COLOR_HEART_BORDER = Color3.fromRGB(90, 35, 30) -- border
local COLOR_THREAD = Color3.fromRGB(80, 25, 20) -- vein/thread connections
local COLOR_CONTAINER_BG = Color3.fromRGB(10, 8, 8) -- near-black bg

-- Pulse parameters
local PULSE_SPEED_CALM = 1.2 -- Hz at 3 hearts
local PULSE_SPEED_ANXIOUS = 2.0 -- Hz at 2 hearts
local PULSE_SPEED_DESPERATE = 4.0 -- Hz at 1 heart

local HeartsHUD = {}
HeartsHUD.__index = HeartsHUD

export type HeartsHUD = typeof(setmetatable(
	{} :: {
		container: Frame,
		hearts: { Frame },
		heartFills: { Frame },
		heartGlows: { Frame },
		heartCracks: { Frame },
		threads: { Frame },
		currentHearts: number,
		deathCount: number,
		pulseConnection: RBXScriptConnection?,
		fearTier: number, -- 0=safe, 1=unease, 2=dread, 3=panic, 4=proximity
	},
	HeartsHUD
))

function HeartsHUD.new(parent: ScreenGui): HeartsHUD
	-- Main container, bottom-left, above the health pips
	local container = Instance.new("Frame")
	container.Name = "HeartsHUD"
	local totalWidth = MAX_HEARTS * (28 + HEART_GAP) - HEART_GAP + 16
	container.Size = UDim2.fromOffset(totalWidth, 38)
	-- Position above the existing HealthDisplay (which is at bottom-left offset 16, height 28)
	container.Position = UDim2.new(0, CONTAINER_PADDING, 1, -CONTAINER_PADDING - 28 - 8 - 38)
	container.AnchorPoint = Vector2.new(0, 0)
	container.BackgroundColor3 = COLOR_CONTAINER_BG
	container.BackgroundTransparency = 0.5
	container.BorderSizePixel = 0
	container.ZIndex = 8
	container.Parent = parent

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 6)
	containerCorner.Parent = container

	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = Color3.fromRGB(40, 20, 18)
	containerStroke.Thickness = 1
	containerStroke.Transparency = 0.6
	containerStroke.Parent = container

	-- Hearts and sub-elements
	local hearts: { Frame } = {}
	local heartFills: { Frame } = {}
	local heartGlows: { Frame } = {}
	local heartCracks: { Frame } = {}
	local threads: { Frame } = {}

	for i = 1, MAX_HEARTS do
		local xOffset = 8 + (i - 1) * (28 + HEART_GAP)

		-- Heart outer frame
		local heart = Instance.new("Frame")
		heart.Name = `Heart_{i}`
		heart.Size = HEART_SIZE
		heart.Position = UDim2.new(0, xOffset, 0.5, 0)
		heart.AnchorPoint = Vector2.new(0, 0.5)
		heart.BackgroundColor3 = COLOR_HEART_FILL
		heart.BackgroundTransparency = 0
		heart.BorderSizePixel = 0
		heart.ZIndex = 10
		heart.Parent = container

		local heartCorner = Instance.new("UICorner")
		heartCorner.CornerRadius = UDim.new(0, 6)
		heartCorner.Parent = heart

		local heartStroke = Instance.new("UIStroke")
		heartStroke.Color = COLOR_HEART_BORDER
		heartStroke.Thickness = 1.5
		heartStroke.Transparency = 0.3
		heartStroke.Parent = heart

		-- Inner glow fill (UIGradient to simulate luminosity)
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.fromScale(1, 1)
		fill.Position = UDim2.fromScale(0, 0)
		fill.BackgroundColor3 = COLOR_HEART_GLOW
		fill.BackgroundTransparency = 0.3
		fill.BorderSizePixel = 0
		fill.ZIndex = 11
		fill.Parent = heart

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 6)
		fillCorner.Parent = fill

		local fillGradient = Instance.new("UIGradient")
		fillGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 60, 40)),
			ColorSequenceKeypoint.new(0.5, COLOR_HEART_GLOW),
			ColorSequenceKeypoint.new(1, COLOR_HEART_FILL),
		})
		fillGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(0.4, 0.2),
			NumberSequenceKeypoint.new(1, 0.5),
		})
		fillGradient.Rotation = 45
		fillGradient.Parent = fill

		-- Glow overlay (slightly larger, blurred look)
		local glow = Instance.new("Frame")
		glow.Name = "Glow"
		glow.Size = UDim2.new(1, 6, 1, 6)
		glow.Position = UDim2.new(0.5, 0, 0.5, 0)
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.BackgroundColor3 = COLOR_HEART_GLOW
		glow.BackgroundTransparency = 0.85
		glow.BorderSizePixel = 0
		glow.ZIndex = 9
		glow.Parent = heart

		local glowCorner = Instance.new("UICorner")
		glowCorner.CornerRadius = UDim.new(0, 8)
		glowCorner.Parent = glow

		-- Crack overlay (initially hidden, shown when heart is lost)
		local crack = Instance.new("Frame")
		crack.Name = "CrackOverlay"
		crack.Size = UDim2.fromScale(1, 1)
		crack.Position = UDim2.fromScale(0, 0)
		crack.BackgroundTransparency = 1
		crack.BorderSizePixel = 0
		crack.ZIndex = 12
		crack.Visible = false
		crack.Parent = heart

		-- Diagonal crack line
		local crackLine = Instance.new("Frame")
		crackLine.Name = "CrackLine"
		crackLine.Size = UDim2.new(0, 2, 1, 4)
		crackLine.Position = UDim2.new(0.45, 0, -0.1, 0)
		crackLine.Rotation = 15
		crackLine.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
		crackLine.BackgroundTransparency = 0.2
		crackLine.BorderSizePixel = 0
		crackLine.ZIndex = 12
		crackLine.Parent = crack

		-- Branch crack
		local crackBranch = Instance.new("Frame")
		crackBranch.Name = "CrackBranch"
		crackBranch.Size = UDim2.new(0, 1, 0.5, 0)
		crackBranch.Position = UDim2.new(0.55, 0, 0.3, 0)
		crackBranch.Rotation = -25
		crackBranch.BackgroundColor3 = Color3.fromRGB(30, 15, 15)
		crackBranch.BackgroundTransparency = 0.3
		crackBranch.BorderSizePixel = 0
		crackBranch.ZIndex = 12
		crackBranch.Parent = crack

		hearts[i] = heart
		heartFills[i] = fill
		heartGlows[i] = glow
		heartCracks[i] = crack

		-- Thread connections between hearts (not after the last one)
		if i < MAX_HEARTS then
			local thread = Instance.new("Frame")
			thread.Name = `Thread_{i}`
			thread.Size = UDim2.new(0, HEART_GAP, 0, 1)
			thread.Position = UDim2.new(0, xOffset + 28, 0.5, 0)
			thread.AnchorPoint = Vector2.new(0, 0.5)
			thread.BackgroundColor3 = COLOR_THREAD
			thread.BackgroundTransparency = 0.4
			thread.BorderSizePixel = 0
			thread.ZIndex = 9
			thread.Parent = container

			threads[i] = thread
		end
	end

	local self = setmetatable({
		container = container,
		hearts = hearts,
		heartFills = heartFills,
		heartGlows = heartGlows,
		heartCracks = heartCracks,
		threads = threads,
		currentHearts = MAX_HEARTS,
		deathCount = 0,
		pulseConnection = nil :: RBXScriptConnection?,
		fearTier = 0,
	}, HeartsHUD)

	-- Start the idle pulse
	self:_startPulse()

	return self
end

--[[
	Update the hearts display based on current heart count and death count.
]]
function HeartsHUD.update(self: HeartsHUD, hearts: number, deathCount: number)
	self.currentHearts = hearts
	self.deathCount = deathCount

	for i = 1, MAX_HEARTS do
		local heart = self.hearts[i]
		local fill = self.heartFills[i]
		local glow = self.heartGlows[i]
		local crack = self.heartCracks[i]

		if i <= hearts then
			-- This heart is alive
			heart.BackgroundColor3 = COLOR_HEART_FILL
			heart.BackgroundTransparency = 0
			fill.Visible = true
			glow.BackgroundTransparency = 0.85
			crack.Visible = false

			-- If this is the last heart and others are lost, show hairline cracks
			if hearts == 1 and i == 1 then
				-- Show subtle crack on the surviving heart
				crack.Visible = true
				crack.BackgroundTransparency = 1 -- the children show through
				-- Make crack lines more transparent (hairline)
				for _, child in crack:GetChildren() do
					if child:IsA("Frame") then
						child.BackgroundTransparency = 0.5
					end
				end
			elseif hearts == 2 and deathCount >= 1 then
				-- After first death, show faint cracks on remaining hearts
				crack.Visible = true
				for _, child in crack:GetChildren() do
					if child:IsA("Frame") then
						child.BackgroundTransparency = 0.7
					end
				end
			end
		else
			-- This heart is lost — cracked outline, dim
			heart.BackgroundColor3 = COLOR_HEART_CRACKED
			heart.BackgroundTransparency = 0.3
			fill.Visible = false
			glow.BackgroundTransparency = 1
			crack.Visible = true
			for _, child in crack:GetChildren() do
				if child:IsA("Frame") then
					child.BackgroundTransparency = 0.1
				end
			end
		end
	end

	-- Update thread connections — snap threads to broken hearts
	for i, thread in self.threads do
		if i >= hearts then
			-- Thread leads to a broken heart — dim and flicker
			thread.BackgroundTransparency = 0.8
			thread.BackgroundColor3 = Color3.fromRGB(40, 15, 12)
		else
			-- Thread between alive hearts
			thread.BackgroundTransparency = 0.4
			thread.BackgroundColor3 = COLOR_THREAD
		end
	end

	-- Restart pulse with appropriate speed
	self:_startPulse()
end

--[[
	Set the current fear tier for pulse synchronization.
]]
function HeartsHUD.setFearTier(self: HeartsHUD, tier: number)
	self.fearTier = tier
end

--[[
	Start the pulsing animation loop. Pulse speed depends on remaining hearts.
]]
function HeartsHUD._startPulse(self: HeartsHUD)
	-- Disconnect any existing pulse
	self:_stopPulse()

	local pulseSpeed = PULSE_SPEED_CALM
	if self.currentHearts == 2 then
		pulseSpeed = PULSE_SPEED_ANXIOUS
	elseif self.currentHearts <= 1 then
		pulseSpeed = PULSE_SPEED_DESPERATE
	end

	self.pulseConnection = RunService.Heartbeat:Connect(function()
		local t = tick()

		-- Override pulse speed with fear tier heartbeat at Tier 2+
		local effectiveSpeed = pulseSpeed
		if self.fearTier >= 2 then
			effectiveSpeed = math.max(pulseSpeed, PULSE_SPEED_ANXIOUS + self.fearTier * 0.5)
		end

		local alpha = (math.sin(t * effectiveSpeed * math.pi * 2) + 1) / 2

		for i = 1, MAX_HEARTS do
			if i <= self.currentHearts then
				local fill = self.heartFills[i]
				local glow = self.heartGlows[i]

				-- Pulse transparency
				local baseTransparency = 0.3
				if self.currentHearts == 1 then
					-- Last heart: more dramatic pulse, brighter peaks
					baseTransparency = 0.1
					fill.BackgroundTransparency = baseTransparency + alpha * 0.35
					glow.BackgroundTransparency = 0.7 + alpha * 0.2
				else
					fill.BackgroundTransparency = baseTransparency + alpha * 0.15
					glow.BackgroundTransparency = 0.85 + alpha * 0.1
				end

				-- Subtle size pulse on the last heart
				if self.currentHearts == 1 and i == self.currentHearts then
					local scale = 1.0 + alpha * 0.04
					self.hearts[i].Size = UDim2.fromOffset(
						math.floor(28 * scale),
						math.floor(26 * scale)
					)
				end
			end
		end
	end)
end

--[[
	Stop the pulse animation loop.
]]
function HeartsHUD._stopPulse(self: HeartsHUD)
	if self.pulseConnection then
		self.pulseConnection:Disconnect()
		self.pulseConnection = nil
	end
end

--[[
	Hide the hearts HUD (during death animation, etc.).
]]
function HeartsHUD.hide(self: HeartsHUD)
	self.container.Visible = false
end

--[[
	Show the hearts HUD.
]]
function HeartsHUD.show(self: HeartsHUD)
	self.container.Visible = true
end

--[[
	Clean up connections.
]]
function HeartsHUD.destroy(self: HeartsHUD)
	self:_stopPulse()
	self.container:Destroy()
end

return HeartsHUD
