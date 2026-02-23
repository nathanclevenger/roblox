--!strict

--[[
	Death Animation (Client)

	Full-screen death overlay that plays when the player loses a heart.
	Three distinct animations based on death number:

	Death 1 (5s): Hearts fade in, leftmost cracks and shatters upward, text appears
	Death 2 (6s): First heart dim, second cracks slower/heavier, fragments fall down
	Death 3 (10s): Camera lingers, single heart detonates, absolute silence, letter-by-letter

	Hearts are organic, luminous, fragile — deep warm red glow, not cartoonish.
	Each breaks into 12-16 irregular fragments with ember trails.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local Constants = require(ReplicatedStorage.Shared.Constants)

-- Visual constants
local HEART_SIZE = UDim2.fromOffset(64, 58)
local HEART_GAP = 24
local FRAGMENT_COUNT = Constants.HEART_FRAGMENT_COUNT or 14
local FRAGMENT_MIN_SIZE = 4
local FRAGMENT_MAX_SIZE = 10

-- Colors
local COLOR_HEART = Color3.fromRGB(160, 25, 20)
local COLOR_HEART_GLOW = Color3.fromRGB(200, 50, 30)
local COLOR_HEART_DIM = Color3.fromRGB(50, 22, 20)
local COLOR_EMBER = Color3.fromRGB(255, 120, 40)
local COLOR_EMBER_DIM = Color3.fromRGB(180, 60, 20)
local COLOR_TEXT = Color3.fromRGB(255, 255, 255)
local COLOR_FOREVER = Color3.fromRGB(255, 235, 220) -- slightly warmer
local COLOR_CRACK = Color3.fromRGB(20, 8, 8)

-- Death sound asset IDs
local SOUND_THUD = "rbxassetid://5743160867" -- low resonant impact
local SOUND_CRACK = "rbxassetid://4591720231" -- brittle cracking
local SOUND_CRACK_WET = "rbxassetid://2785493068" -- organic crack (death 2)
local SOUND_SHATTER = "rbxassetid://4591720231" -- explosion shatter (death 3)
local SOUND_FLATLINE = "rbxassetid://9112854440" -- sustained low tone
local SOUND_ELEGY = "rbxassetid://2785661376" -- chord for final death

local DeathAnimation = {}
DeathAnimation.__index = DeathAnimation

export type DeathAnimation = typeof(setmetatable(
	{} :: {
		screenGui: ScreenGui,
		overlay: CanvasGroup,
		isPlaying: boolean,
		activeConnections: { RBXScriptConnection },
		activeTweens: { Tween },
		activeSounds: { Sound },
	},
	DeathAnimation
))

function DeathAnimation.new(parent: ScreenGui): DeathAnimation
	-- Create the ScreenGui for death overlay (highest display order)
	local overlay = Instance.new("CanvasGroup")
	overlay.Name = "DeathOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Position = UDim2.fromScale(0, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.GroupTransparency = 0
	overlay.ZIndex = 100
	overlay.Visible = false
	overlay.Parent = parent

	local self = setmetatable({
		screenGui = parent,
		overlay = overlay,
		isPlaying = false,
		activeConnections = {},
		activeTweens = {},
		activeSounds = {},
	}, DeathAnimation)

	return self
end

--[[
	Play the death animation for the given death number (1, 2, or 3).
	Returns after the full animation duration has elapsed.
]]
function DeathAnimation.play(self: DeathAnimation, deathNumber: number)
	if self.isPlaying then
		return
	end
	self.isPlaying = true

	-- Clean any previous state
	self:_clearOverlay()

	self.overlay.Visible = true
	self.overlay.GroupTransparency = 0

	if deathNumber == 1 then
		self:_playDeath1()
	elseif deathNumber == 2 then
		self:_playDeath2()
	else
		self:_playDeath3()
	end
end

-- =============================================================================
-- Death 1: 5 seconds
-- =============================================================================
function DeathAnimation._playDeath1(self: DeathAnimation)
	-- 0.0s: Screen cuts to black, impact thud
	self.overlay.BackgroundTransparency = 0
	self:_playSound(SOUND_THUD, 0.8)

	-- 0.5s: Three hearts fade in
	task.delay(0.5, function()
		if not self.isPlaying then return end

		local hearts = self:_createHeartRow(3, 3)
		-- Fade hearts in
		for _, heart in hearts do
			heart.GroupTransparency = 1
			local fadeIn = TweenService:Create(heart, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				GroupTransparency = 0,
			})
			fadeIn:Play()
			table.insert(self.activeTweens, fadeIn)
		end

		-- Synchronized pulse
		task.delay(0.4, function()
			if not self.isPlaying then return end
			self:_pulseHearts(hearts, 1)
		end)

		-- 1.5s: Leftmost heart cracks and shatters (fragments drift UP)
		task.delay(1.0, function()
			if not self.isPlaying then return end
			self:_playSound(SOUND_CRACK, 0.6)
			self:_crackHeart(hearts[1], 0.5, function()
				if not self.isPlaying then return end
				self:_shatterHeart(hearts[1], "up")
			end)
		end)

		-- 3.0s: Text fades in
		task.delay(2.5, function()
			if not self.isPlaying then return end
			self:_showDeathText("You've died.", false)
			self:_playSound(SOUND_FLATLINE, 0.3)
		end)

		-- 4.0s: Everything fades out
		task.delay(3.5, function()
			if not self.isPlaying then return end
			self:_fadeOutAll(1.0)
		end)

		-- 5.0s: Animation complete
		task.delay(4.5, function()
			self:_finish()
		end)
	end)
end

-- =============================================================================
-- Death 2: 6 seconds
-- =============================================================================
function DeathAnimation._playDeath2(self: DeathAnimation)
	-- 0.0s: Screen cuts to black, deeper impact
	self.overlay.BackgroundTransparency = 0
	self:_playSound(SOUND_THUD, 1.0)

	-- 0.5s: Three hearts fade in — first already cracked and dim
	task.delay(0.5, function()
		if not self.isPlaying then return end

		local hearts = self:_createHeartRow(3, 2) -- 2 alive, first already broken
		-- Fade hearts in
		for _, heart in hearts do
			heart.GroupTransparency = 1
			local fadeIn = TweenService:Create(heart, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				GroupTransparency = 0,
			})
			fadeIn:Play()
			table.insert(self.activeTweens, fadeIn)
		end

		-- Uneven, anxious pulse
		task.delay(0.4, function()
			if not self.isPlaying then return end
			self:_pulseHearts(hearts, 2)
		end)

		-- 1.8s: Second heart cracks slowly, fragments fall DOWN
		task.delay(1.3, function()
			if not self.isPlaying then return end
			self:_playSound(SOUND_CRACK_WET, 0.7)
			self:_crackHeart(hearts[2], 0.8, function() -- slower crack (0.8s)
				if not self.isPlaying then return end
				self:_shatterHeart(hearts[2], "down")
			end)
		end)

		-- 2.5s: Last heart pulses desperately alone
		task.delay(2.5, function()
			if not self.isPlaying then return end
			-- Hard desperate pulse on last heart
			self:_desperatePulse(hearts[3])
		end)

		-- 3.5s: Text fades in — slightly dimmer
		task.delay(3.0, function()
			if not self.isPlaying then return end
			self:_showDeathText("You've died.", false, 0.35) -- dimmer
			self:_playSound(SOUND_FLATLINE, 0.25)
		end)

		-- 5.0s: Last heart flickers before fading
		task.delay(4.5, function()
			if not self.isPlaying then return end
			self:_flickerHeart(hearts[3], 0.5)
		end)

		-- 5.5s: Fade out
		task.delay(5.0, function()
			if not self.isPlaying then return end
			self:_fadeOutAll(0.8)
		end)

		-- 6.0s: Complete
		task.delay(5.5, function()
			self:_finish()
		end)
	end)
end

-- =============================================================================
-- Death 3: 10 seconds — "You've died forever."
-- =============================================================================
function DeathAnimation._playDeath3(self: DeathAnimation)
	-- 0.0s: Camera lingers on death for 1 second — screen stays transparent briefly
	self.overlay.BackgroundTransparency = 0.7

	-- 1.0s: Slow fade to black
	local fadeToBlack = TweenService:Create(self.overlay, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 0,
	})
	fadeToBlack:Play()
	table.insert(self.activeTweens, fadeToBlack)

	-- 1.5s: Single heart fades in, already cracked and trembling
	task.delay(1.5, function()
		if not self.isPlaying then return end

		local hearts = self:_createHeartRow(3, 0) -- all broken state
		-- Only show the last heart with special treatment
		-- Make ghost outlines of lost hearts barely visible
		hearts[1].GroupTransparency = 0.85
		hearts[2].GroupTransparency = 0.85

		-- The single remaining heart
		local lastHeart = hearts[3]
		lastHeart.GroupTransparency = 1

		-- Fade in the last heart with trembling
		local fadeIn = TweenService:Create(lastHeart, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = 0,
		})
		fadeIn:Play()
		table.insert(self.activeTweens, fadeIn)

		-- Add visible cracks to the last heart
		self:_addCracks(lastHeart, true)

		-- Trembling effect
		self:_startTrembling(lastHeart)

		-- 2.5s: One bright, strong pulse — the brightest moment
		task.delay(1.0, function()
			if not self.isPlaying then return end
			self:_playSound(SOUND_THUD, 1.0) -- deep bass hit

			-- Bright pulse: fill goes fully opaque and bright
			local fill = lastHeart:FindFirstChild("Fill")
			if fill and fill:IsA("Frame") then
				fill.BackgroundColor3 = Color3.fromRGB(240, 80, 50)
				fill.BackgroundTransparency = 0

				local brightPulse = TweenService:Create(fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					BackgroundColor3 = COLOR_HEART,
					BackgroundTransparency = 0.2,
				})
				brightPulse:Play()
				table.insert(self.activeTweens, brightPulse)
			end

			-- Scale up briefly
			local scalePulse = TweenService:Create(lastHeart, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(72, 66),
			})
			scalePulse:Play()
			table.insert(self.activeTweens, scalePulse)

			task.delay(0.15, function()
				if not self.isPlaying then return end
				local scaleBack = TweenService:Create(lastHeart, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = HEART_SIZE,
				})
				scaleBack:Play()
				table.insert(self.activeTweens, scaleBack)
			end)
		end)

		-- 3.5s: DETONATION — fragments scatter ALL directions
		task.delay(2.0, function()
			if not self.isPlaying then return end
			self:_playSound(SOUND_SHATTER, 1.0)
			self:_shatterHeart(lastHeart, "explode")

			-- Also fade ghost hearts
			for i = 1, 2 do
				local ghost = hearts[i]
				local ghostFade = TweenService:Create(ghost, TweenInfo.new(0.5), {
					GroupTransparency = 1,
				})
				ghostFade:Play()
				table.insert(self.activeTweens, ghostFade)
			end
		end)

		-- 5.0s: 2 seconds of ABSOLUTE silence and emptiness (starts at 3.5s after delay)
		-- (nothing happens — empty black — this is intentional)

		-- 7.0s: Text appears letter-by-letter
		task.delay(5.5, function()
			if not self.isPlaying then return end
			self:_playSound(SOUND_ELEGY, 0.5)
			self:_showDeathText("You've died forever.", true) -- letter-by-letter mode
		end)

		-- 8.5s: Hold with no control — text stays on screen
		-- (nothing happens, player sits with it)

		-- 10.0s: Text fades, then return to hub
		task.delay(8.5, function()
			if not self.isPlaying then return end
			self:_fadeOutAll(1.0)
		end)

		task.delay(9.5, function()
			self:_finish()
		end)
	end)
end

-- =============================================================================
-- Heart Construction
-- =============================================================================

--[[
	Create a row of 3 hearts centered on screen.
	`aliveCount` determines how many are shown in full vs cracked/dim state.
]]
function DeathAnimation._createHeartRow(self: DeathAnimation, total: number, aliveCount: number): { CanvasGroup }
	local hearts: { CanvasGroup } = {}
	local totalWidth = total * 64 + (total - 1) * HEART_GAP

	for i = 1, total do
		local xOffset = (i - 1) * (64 + HEART_GAP)

		-- Use CanvasGroup for per-heart transparency control
		local heartGroup = Instance.new("CanvasGroup")
		heartGroup.Name = `DeathHeart_{i}`
		heartGroup.Size = HEART_SIZE
		heartGroup.Position = UDim2.new(0.5, xOffset - totalWidth / 2, 0.45, 0)
		heartGroup.AnchorPoint = Vector2.new(0, 0.5)
		heartGroup.BackgroundTransparency = 1
		heartGroup.GroupTransparency = 0
		heartGroup.ZIndex = 102
		heartGroup.Parent = self.overlay

		local isAlive = i > (total - aliveCount)

		-- Heart body
		local body = Instance.new("Frame")
		body.Name = "Body"
		body.Size = UDim2.fromScale(1, 1)
		body.Position = UDim2.fromScale(0, 0)
		body.BackgroundColor3 = if isAlive then COLOR_HEART else COLOR_HEART_DIM
		body.BackgroundTransparency = if isAlive then 0 else 0.4
		body.BorderSizePixel = 0
		body.ZIndex = 102
		body.Parent = heartGroup

		local bodyCorner = Instance.new("UICorner")
		bodyCorner.CornerRadius = UDim.new(0, 10)
		bodyCorner.Parent = body

		local bodyStroke = Instance.new("UIStroke")
		bodyStroke.Color = if isAlive then COLOR_HEART_GLOW else Color3.fromRGB(40, 18, 16)
		bodyStroke.Thickness = 2
		bodyStroke.Transparency = if isAlive then 0.2 else 0.6
		bodyStroke.Parent = body

		-- Inner fill / glow
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.Size = UDim2.new(1, -4, 1, -4)
		fill.Position = UDim2.new(0, 2, 0, 2)
		fill.BackgroundColor3 = if isAlive then COLOR_HEART_GLOW else COLOR_HEART_DIM
		fill.BackgroundTransparency = if isAlive then 0.2 else 0.7
		fill.BorderSizePixel = 0
		fill.ZIndex = 103
		fill.Parent = heartGroup

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 8)
		fillCorner.Parent = fill

		-- Gradient for luminous glow
		if isAlive then
			local gradient = Instance.new("UIGradient")
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(230, 70, 45)),
				ColorSequenceKeypoint.new(0.5, COLOR_HEART_GLOW),
				ColorSequenceKeypoint.new(1, COLOR_HEART),
			})
			gradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(0.3, 0.1),
				NumberSequenceKeypoint.new(1, 0.4),
			})
			gradient.Rotation = 45
			gradient.Parent = fill
		end

		-- If dead/cracked, add crack lines
		if not isAlive then
			self:_addCracks(heartGroup, false)
		end

		hearts[i] = heartGroup
	end

	-- Thread connections between hearts
	for i = 1, total - 1 do
		local xOffset = (i - 1) * (64 + HEART_GAP)
		local thread = Instance.new("Frame")
		thread.Name = `Thread_{i}`
		thread.Size = UDim2.new(0, HEART_GAP, 0, 1)
		thread.Position = UDim2.new(0.5, xOffset + 64 - totalWidth / 2, 0.45, 0)
		thread.AnchorPoint = Vector2.new(0, 0.5)
		thread.BackgroundColor3 = if i >= (total - aliveCount) then COLOR_HEART_DIM else Color3.fromRGB(80, 25, 20)
		thread.BackgroundTransparency = 0.3
		thread.BorderSizePixel = 0
		thread.ZIndex = 101
		thread.Parent = self.overlay
	end

	return hearts
end

--[[
	Add crack lines to a heart element.
]]
function DeathAnimation._addCracks(self: DeathAnimation, heartGroup: CanvasGroup, intense: boolean)
	local crackContainer = Instance.new("Frame")
	crackContainer.Name = "Cracks"
	crackContainer.Size = UDim2.fromScale(1, 1)
	crackContainer.BackgroundTransparency = 1
	crackContainer.ZIndex = 104
	crackContainer.Parent = heartGroup

	-- Main diagonal crack
	local mainCrack = Instance.new("Frame")
	mainCrack.Size = UDim2.new(0, 2, 1, 6)
	mainCrack.Position = UDim2.new(0.4, 0, -0.05, 0)
	mainCrack.Rotation = 12
	mainCrack.BackgroundColor3 = COLOR_CRACK
	mainCrack.BackgroundTransparency = if intense then 0.1 else 0.3
	mainCrack.BorderSizePixel = 0
	mainCrack.ZIndex = 104
	mainCrack.Parent = crackContainer

	-- Branching cracks
	local branch1 = Instance.new("Frame")
	branch1.Size = UDim2.new(0, 1, 0.45, 0)
	branch1.Position = UDim2.new(0.55, 0, 0.25, 0)
	branch1.Rotation = -30
	branch1.BackgroundColor3 = COLOR_CRACK
	branch1.BackgroundTransparency = if intense then 0.15 else 0.4
	branch1.BorderSizePixel = 0
	branch1.ZIndex = 104
	branch1.Parent = crackContainer

	local branch2 = Instance.new("Frame")
	branch2.Size = UDim2.new(0, 1, 0.35, 0)
	branch2.Position = UDim2.new(0.3, 0, 0.5, 0)
	branch2.Rotation = 25
	branch2.BackgroundColor3 = COLOR_CRACK
	branch2.BackgroundTransparency = if intense then 0.2 else 0.5
	branch2.BorderSizePixel = 0
	branch2.ZIndex = 104
	branch2.Parent = crackContainer

	if intense then
		-- Additional hairline cracks for the final heart
		local branch3 = Instance.new("Frame")
		branch3.Size = UDim2.new(0, 1, 0.3, 0)
		branch3.Position = UDim2.new(0.65, 0, 0.15, 0)
		branch3.Rotation = -15
		branch3.BackgroundColor3 = COLOR_CRACK
		branch3.BackgroundTransparency = 0.25
		branch3.BorderSizePixel = 0
		branch3.ZIndex = 104
		branch3.Parent = crackContainer

		local branch4 = Instance.new("Frame")
		branch4.Size = UDim2.new(0, 1, 0.25, 0)
		branch4.Position = UDim2.new(0.2, 0, 0.6, 0)
		branch4.Rotation = 40
		branch4.BackgroundColor3 = COLOR_CRACK
		branch4.BackgroundTransparency = 0.3
		branch4.BorderSizePixel = 0
		branch4.ZIndex = 104
		branch4.Parent = crackContainer
	end
end

-- =============================================================================
-- Heart Animations
-- =============================================================================

--[[
	Animate a crack spreading across a heart over the given duration,
	then call onComplete.
]]
function DeathAnimation._crackHeart(self: DeathAnimation, heartGroup: CanvasGroup, duration: number, onComplete: () -> ())
	-- Create an animated crack that spreads
	local crack = Instance.new("Frame")
	crack.Name = "AnimatedCrack"
	crack.Size = UDim2.new(0, 2, 0, 0) -- starts at zero height
	crack.Position = UDim2.new(0.45, 0, 0, 0)
	crack.Rotation = 10 + math.random(-5, 5)
	crack.BackgroundColor3 = COLOR_CRACK
	crack.BackgroundTransparency = 0
	crack.BorderSizePixel = 0
	crack.ZIndex = 105
	crack.Parent = heartGroup

	-- Animate the crack growing
	local crackGrow = TweenService:Create(crack, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 2, 1, 8),
	})
	crackGrow:Play()
	table.insert(self.activeTweens, crackGrow)

	-- Branch cracks appear partway through
	task.delay(duration * 0.4, function()
		if not self.isPlaying then return end

		for j = 1, 3 do
			local branch = Instance.new("Frame")
			branch.Size = UDim2.new(0, 1, 0, 0)
			branch.Position = UDim2.new(0.45 + (j - 2) * 0.15, 0, 0.2 + j * 0.15, 0)
			branch.Rotation = -20 + j * 15
			branch.BackgroundColor3 = COLOR_CRACK
			branch.BackgroundTransparency = 0.1
			branch.BorderSizePixel = 0
			branch.ZIndex = 105
			branch.Parent = heartGroup

			local branchGrow = TweenService:Create(branch, TweenInfo.new(duration * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 1, 0, 12 + math.random(0, 8)),
			})
			branchGrow:Play()
			table.insert(self.activeTweens, branchGrow)
		end
	end)

	task.delay(duration, function()
		onComplete()
	end)
end

--[[
	Shatter a heart into fragments.
	direction: "up" (death 1), "down" (death 2), "explode" (death 3)
]]
function DeathAnimation._shatterHeart(self: DeathAnimation, heartGroup: CanvasGroup, direction: string)
	-- Get the heart's position for fragment origin
	local heartPos = heartGroup.AbsolutePosition
	local heartSize = heartGroup.AbsoluteSize

	-- Hide the original heart body
	for _, child in heartGroup:GetChildren() do
		if child:IsA("Frame") or child:IsA("CanvasGroup") then
			child.Visible = false
		end
	end
	heartGroup.BackgroundTransparency = 1

	-- Create fragments
	for i = 1, FRAGMENT_COUNT do
		local fragSize = math.random(FRAGMENT_MIN_SIZE, FRAGMENT_MAX_SIZE)

		-- Irregular shape via random corner radius
		local fragment = Instance.new("Frame")
		fragment.Name = `Fragment_{i}`
		fragment.Size = UDim2.fromOffset(fragSize, fragSize + math.random(-2, 3))
		-- Start at the heart's center
		fragment.Position = UDim2.new(
			0, heartPos.X + heartSize.X / 2 + math.random(-10, 10),
			0, heartPos.Y + heartSize.Y / 2 + math.random(-10, 10)
		)
		fragment.AnchorPoint = Vector2.new(0.5, 0.5)
		fragment.BackgroundColor3 = COLOR_HEART:Lerp(COLOR_EMBER, math.random() * 0.3)
		fragment.BackgroundTransparency = 0
		fragment.Rotation = math.random(0, 360)
		fragment.BorderSizePixel = 0
		fragment.ZIndex = 106
		fragment.Parent = self.overlay

		local fragCorner = Instance.new("UICorner")
		fragCorner.CornerRadius = UDim.new(0, math.random(1, 3))
		fragCorner.Parent = fragment

		-- Ember trail (small glowing dot behind fragment)
		local ember = Instance.new("Frame")
		ember.Name = "Ember"
		ember.Size = UDim2.fromOffset(math.max(2, fragSize - 2), math.max(2, fragSize - 2))
		ember.Position = UDim2.fromScale(0.5, 0.5)
		ember.AnchorPoint = Vector2.new(0.5, 0.5)
		ember.BackgroundColor3 = COLOR_EMBER
		ember.BackgroundTransparency = 0.3
		ember.BorderSizePixel = 0
		ember.ZIndex = 105
		ember.Parent = fragment

		local emberCorner = Instance.new("UICorner")
		emberCorner.CornerRadius = UDim.new(1, 0)
		emberCorner.Parent = ember

		-- Calculate target position based on direction
		local angle: number
		local distance = math.random(100, 300)

		if direction == "up" then
			-- Drift upward and outward
			angle = math.rad(-90 + math.random(-45, 45))
			distance = math.random(80, 200)
		elseif direction == "down" then
			-- Fall downward, heavier
			angle = math.rad(90 + math.random(-30, 30))
			distance = math.random(100, 250)
		else -- "explode"
			-- Scatter in all directions
			angle = math.rad(math.random(0, 360))
			distance = math.random(150, 400)
		end

		local targetX = heartPos.X + heartSize.X / 2 + math.cos(angle) * distance
		local targetY = heartPos.Y + heartSize.Y / 2 + math.sin(angle) * distance
		local targetRotation = math.random(-720, 720)

		-- Animation duration varies by direction
		local fragDuration = if direction == "explode"
			then math.random(8, 15) / 10 -- 0.8 - 1.5s
			elseif direction == "down"
			then math.random(10, 18) / 10 -- 1.0 - 1.8s
			else math.random(12, 22) / 10 -- 1.2 - 2.2s for drifting up

		local easingStyle = if direction == "down"
			then Enum.EasingStyle.Quad
			else Enum.EasingStyle.Sine

		-- Animate fragment movement
		local moveTween = TweenService:Create(fragment, TweenInfo.new(fragDuration, easingStyle, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(targetX, targetY),
			Rotation = targetRotation,
			BackgroundTransparency = 1,
		})
		moveTween:Play()
		table.insert(self.activeTweens, moveTween)

		-- Animate ember fade
		local emberFade = TweenService:Create(ember, TweenInfo.new(fragDuration * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
			BackgroundColor3 = COLOR_EMBER_DIM,
		})
		emberFade:Play()
		table.insert(self.activeTweens, emberFade)

		-- Clean up fragment after animation
		task.delay(fragDuration + 0.1, function()
			if fragment and fragment.Parent then
				fragment:Destroy()
			end
		end)
	end

	-- Fade the heart group to nothing
	local heartFade = TweenService:Create(heartGroup, TweenInfo.new(0.3), {
		GroupTransparency = 1,
	})
	heartFade:Play()
	table.insert(self.activeTweens, heartFade)
end

--[[
	Pulse hearts once in sync.
]]
function DeathAnimation._pulseHearts(self: DeathAnimation, hearts: { CanvasGroup }, deathNumber: number)
	for i, heart in hearts do
		local fill = heart:FindFirstChild("Fill")
		if fill and fill:IsA("Frame") and fill.Visible then
			-- Quick scale pulse
			local originalSize = heart.Size
			local pulseUp = TweenService:Create(heart, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.fromOffset(68, 62),
			})
			pulseUp:Play()
			table.insert(self.activeTweens, pulseUp)

			task.delay(0.15, function()
				if not self.isPlaying then return end
				local pulseDown = TweenService:Create(heart, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = originalSize,
				})
				pulseDown:Play()
				table.insert(self.activeTweens, pulseDown)
			end)
		end
	end
end

--[[
	Desperate single pulse on a lone heart (death 2).
]]
function DeathAnimation._desperatePulse(self: DeathAnimation, heartGroup: CanvasGroup)
	local fill = heartGroup:FindFirstChild("Fill")
	if fill and fill:IsA("Frame") then
		-- Hard, desperate pulse
		fill.BackgroundColor3 = Color3.fromRGB(230, 70, 45)
		fill.BackgroundTransparency = 0

		local pulseFade = TweenService:Create(fill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundColor3 = COLOR_HEART,
			BackgroundTransparency = 0.3,
		})
		pulseFade:Play()
		table.insert(self.activeTweens, pulseFade)

		-- Add visible cracks
		self:_addCracks(heartGroup, true)
	end
end

--[[
	Flicker a heart like a candle in wind before it goes dark.
]]
function DeathAnimation._flickerHeart(self: DeathAnimation, heartGroup: CanvasGroup, duration: number)
	local startTime = tick()
	local conn: RBXScriptConnection? = nil

	conn = game:GetService("RunService").Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		if elapsed >= duration or not self.isPlaying then
			if conn then
				conn:Disconnect()
			end
			return
		end

		-- Rapid random transparency flicker
		local flicker = math.random() > 0.4
		heartGroup.GroupTransparency = if flicker then 0.3 + math.random() * 0.5 else 0.1
	end)

	if conn then
		table.insert(self.activeConnections, conn)
	end
end

--[[
	Start a trembling effect on a heart element (death 3 final heart).
]]
function DeathAnimation._startTrembling(self: DeathAnimation, heartGroup: CanvasGroup)
	local originalPos = heartGroup.Position
	local conn: RBXScriptConnection? = nil

	conn = game:GetService("RunService").Heartbeat:Connect(function()
		if not self.isPlaying then
			if conn then
				conn:Disconnect()
			end
			return
		end

		-- Small random offset
		local offsetX = math.random(-2, 2)
		local offsetY = math.random(-1, 1)
		heartGroup.Position = UDim2.new(
			originalPos.X.Scale, originalPos.X.Offset + offsetX,
			originalPos.Y.Scale, originalPos.Y.Offset + offsetY
		)
	end)

	if conn then
		table.insert(self.activeConnections, conn)
	end
end

-- =============================================================================
-- Text
-- =============================================================================

--[[
	Show "You've died." or "You've died forever." text.
	If letterByLetter is true, each letter appears individually over 1.5 seconds.
]]
function DeathAnimation._showDeathText(self: DeathAnimation, text: string, letterByLetter: boolean, textTransparency: number?)
	local baseTransparency = textTransparency or 0.3

	if letterByLetter then
		-- Split into "You've died " and "forever."
		local mainPart = "You've died "
		local foreverPart = "forever."

		-- Main text label
		local mainLabel = Instance.new("TextLabel")
		mainLabel.Name = "DeathTextMain"
		mainLabel.Size = UDim2.new(1, 0, 0, 40)
		mainLabel.Position = UDim2.new(0, 0, 0.68, 0)
		mainLabel.BackgroundTransparency = 1
		mainLabel.Font = Enum.Font.SourceSansSemibold
		mainLabel.TextSize = 32
		mainLabel.TextColor3 = COLOR_TEXT
		mainLabel.TextTransparency = 1
		mainLabel.Text = ""
		mainLabel.ZIndex = 110
		mainLabel.TextXAlignment = Enum.TextXAlignment.Center
		mainLabel.TextYAlignment = Enum.TextYAlignment.Center
		mainLabel.Parent = self.overlay

		-- "forever." label — slightly lower and warmer
		local foreverLabel = Instance.new("TextLabel")
		foreverLabel.Name = "DeathTextForever"
		foreverLabel.Size = UDim2.new(1, 0, 0, 40)
		foreverLabel.Position = UDim2.new(0, 8, 0.72, 0)
		foreverLabel.BackgroundTransparency = 1
		foreverLabel.Font = Enum.Font.SourceSansSemibold
		foreverLabel.TextSize = 32
		foreverLabel.TextColor3 = COLOR_FOREVER
		foreverLabel.TextTransparency = 1
		foreverLabel.Text = ""
		foreverLabel.ZIndex = 110
		foreverLabel.TextXAlignment = Enum.TextXAlignment.Center
		foreverLabel.TextYAlignment = Enum.TextYAlignment.Center
		foreverLabel.Parent = self.overlay

		-- Reveal letters one at a time
		local fullText = mainPart .. foreverPart
		local letterDelay = 1.5 / #fullText

		for charIdx = 1, #fullText do
			task.delay(letterDelay * (charIdx - 1), function()
				if not self.isPlaying then return end

				if charIdx <= #mainPart then
					mainLabel.Text = string.sub(mainPart, 1, charIdx)
					mainLabel.TextTransparency = baseTransparency
				else
					mainLabel.Text = mainPart
					mainLabel.TextTransparency = baseTransparency
					local foreverIdx = charIdx - #mainPart
					foreverLabel.Text = string.sub(foreverPart, 1, foreverIdx)
					foreverLabel.TextTransparency = baseTransparency
				end
			end)
		end
	else
		-- Standard fade-in text
		local label = Instance.new("TextLabel")
		label.Name = "DeathText"
		label.Size = UDim2.new(1, 0, 0, 40)
		label.Position = UDim2.new(0, 0, 0.68, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.SourceSansSemibold
		label.TextSize = 30
		label.TextColor3 = COLOR_TEXT
		label.TextTransparency = 1
		label.Text = text
		label.ZIndex = 110
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Parent = self.overlay

		-- Fade in over 0.5s
		local fadeIn = TweenService:Create(label, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = baseTransparency,
		})
		fadeIn:Play()
		table.insert(self.activeTweens, fadeIn)
	end
end

-- =============================================================================
-- Audio
-- =============================================================================

--[[
	Play a sound with the given asset ID at the specified volume.
]]
function DeathAnimation._playSound(self: DeathAnimation, assetId: string, volume: number)
	-- Skip placeholder sounds
	if assetId == "rbxassetid://0" then
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = assetId
	sound.Volume = volume
	sound.PlayOnRemove = false
	sound.Parent = SoundService
	sound:Play()

	table.insert(self.activeSounds, sound)

	-- Clean up after playback
	sound.Ended:Once(function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

-- =============================================================================
-- Lifecycle
-- =============================================================================

--[[
	Fade out all elements in the overlay.
]]
function DeathAnimation._fadeOutAll(self: DeathAnimation, duration: number)
	local fade = TweenService:Create(self.overlay, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		GroupTransparency = 1,
	})
	fade:Play()
	table.insert(self.activeTweens, fade)
end

--[[
	Finish the animation — clean up and mark as not playing.
]]
function DeathAnimation._finish(self: DeathAnimation)
	self.isPlaying = false
	self.overlay.Visible = false
	self:_clearOverlay()
end

--[[
	Clear all children of the overlay and cancel active tweens/connections.
]]
function DeathAnimation._clearOverlay(self: DeathAnimation)
	-- Cancel active connections
	for _, conn in self.activeConnections do
		conn:Disconnect()
	end
	self.activeConnections = {}

	-- Cancel active tweens
	for _, tween in self.activeTweens do
		tween:Cancel()
	end
	self.activeTweens = {}

	-- Stop active sounds
	for _, sound in self.activeSounds do
		if sound and sound.Parent then
			sound:Stop()
			sound:Destroy()
		end
	end
	self.activeSounds = {}

	-- Clear overlay children (except the background itself)
	for _, child in self.overlay:GetChildren() do
		child:Destroy()
	end

	-- Reset overlay state
	self.overlay.BackgroundTransparency = 1
	self.overlay.GroupTransparency = 0
end

--[[
	Check if the animation is currently playing.
]]
function DeathAnimation.getIsPlaying(self: DeathAnimation): boolean
	return self.isPlaying
end

return DeathAnimation
