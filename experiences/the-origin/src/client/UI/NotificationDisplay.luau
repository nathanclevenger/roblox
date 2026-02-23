--!strict

--[[
	Notification Display (Client)

	Renders multiplayer event notifications at the top-center of the screen.
	Supports fade-in/out animations and stacking up to 3 visible notifications.
	Different notification types get different color accents.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)

local NotificationDisplay = {}
NotificationDisplay.__index = NotificationDisplay

-- Color accents per notification type
local TYPE_COLORS: { [string]: Color3 } = {
	fallen = Color3.fromRGB(230, 160, 50), -- orange
	revived = Color3.fromRGB(80, 200, 100), -- green
	died = Color3.fromRGB(200, 50, 50), -- red
	gone = Color3.fromRGB(140, 20, 20), -- dark red
	checkpoint = Color3.fromRGB(180, 180, 180), -- subtle white
	event = Color3.fromRGB(200, 200, 220), -- light blue-white
}

local TYPE_TEXT_SIZES: { [string]: number } = {
	fallen = 18,
	revived = 18,
	died = 18,
	gone = 22, -- slightly larger for permanent death
	checkpoint = 16,
	event = 18,
}

local NOTIFICATION_WIDTH = 500
local NOTIFICATION_HEIGHT = 40
local NOTIFICATION_GAP = 6
local NOTIFICATION_TOP_OFFSET = 80

export type NotificationDisplay = typeof(setmetatable(
	{} :: {
		container: Frame,
		activeNotifications: { Frame },
		maxVisible: number,
	},
	NotificationDisplay
))

function NotificationDisplay.new(parent: ScreenGui): NotificationDisplay
	-- Container anchored to top-center
	local container = Instance.new("Frame")
	container.Name = "NotificationDisplay"
	container.Size = UDim2.new(0, NOTIFICATION_WIDTH, 0, (NOTIFICATION_HEIGHT + NOTIFICATION_GAP) * Constants.MAX_VISIBLE_NOTIFICATIONS)
	container.Position = UDim2.new(0.5, 0, 0, NOTIFICATION_TOP_OFFSET)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ZIndex = 40
	container.Parent = parent

	local self = setmetatable({
		container = container,
		activeNotifications = {},
		maxVisible = Constants.MAX_VISIBLE_NOTIFICATIONS,
	}, NotificationDisplay)

	return self
end

--[[
	Display a new notification. Handles stacking, fade-in, hold, and fade-out.
]]
function NotificationDisplay.showNotification(self: NotificationDisplay, notification: Types.GameNotification)
	local notifType = notification.notificationType
	local message = notification.message

	-- If we have too many, remove the oldest
	while #self.activeNotifications >= self.maxVisible do
		local oldest = table.remove(self.activeNotifications, 1)
		if oldest and oldest.Parent then
			oldest:Destroy()
		end
	end

	-- Push existing notifications up
	for i, notif in self.activeNotifications do
		local targetY = (i - 1) * (NOTIFICATION_HEIGHT + NOTIFICATION_GAP)
		local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(notif, tweenInfo, {
			Position = UDim2.new(0.5, 0, 0, targetY),
		})
		tween:Play()
	end

	-- Create new notification frame
	local accentColor = TYPE_COLORS[notifType] or Color3.fromRGB(200, 200, 200)
	local textSize = TYPE_TEXT_SIZES[notifType] or 18

	local notifFrame = Instance.new("Frame")
	notifFrame.Name = "Notification"
	notifFrame.Size = UDim2.new(1, 0, 0, NOTIFICATION_HEIGHT)
	notifFrame.Position = UDim2.new(0.5, 0, 0, #self.activeNotifications * (NOTIFICATION_HEIGHT + NOTIFICATION_GAP))
	notifFrame.AnchorPoint = Vector2.new(0.5, 0)
	notifFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	notifFrame.BackgroundTransparency = 0.4
	notifFrame.BorderSizePixel = 0
	notifFrame.ZIndex = 41
	notifFrame.Parent = self.container

	-- Start invisible for fade-in
	notifFrame.BackgroundTransparency = 1

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = notifFrame

	-- Accent line on the left edge
	local accentLine = Instance.new("Frame")
	accentLine.Name = "AccentLine"
	accentLine.Size = UDim2.new(0, 3, 1, -8)
	accentLine.Position = UDim2.new(0, 6, 0, 4)
	accentLine.BackgroundColor3 = accentColor
	accentLine.BackgroundTransparency = 1
	accentLine.BorderSizePixel = 0
	accentLine.ZIndex = 42
	accentLine.Parent = notifFrame

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, 2)
	accentCorner.Parent = accentLine

	-- Message text
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Message"
	textLabel.Size = UDim2.new(1, -24, 1, 0)
	textLabel.Position = UDim2.new(0, 18, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamMedium
	textLabel.TextSize = textSize
	textLabel.TextColor3 = accentColor
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextStrokeTransparency = 0.3
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.Text = message
	textLabel.TextTransparency = 1 -- start invisible for fade-in
	textLabel.ZIndex = 43
	textLabel.Parent = notifFrame

	-- Add to active list
	table.insert(self.activeNotifications, notifFrame)

	-- Animate fade-in
	local fadeInTime = Constants.NOTIFICATION_FADE_IN
	local holdTime = Constants.NOTIFICATION_DISPLAY_TIME
	local fadeOutTime = Constants.NOTIFICATION_FADE_OUT

	local fadeInInfo = TweenInfo.new(fadeInTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local frameFadeIn = TweenService:Create(notifFrame, fadeInInfo, {
		BackgroundTransparency = 0.4,
	})
	local textFadeIn = TweenService:Create(textLabel, fadeInInfo, {
		TextTransparency = 0,
	})
	local accentFadeIn = TweenService:Create(accentLine, fadeInInfo, {
		BackgroundTransparency = 0,
	})

	frameFadeIn:Play()
	textFadeIn:Play()
	accentFadeIn:Play()

	-- Schedule hold and fade-out
	task.delay(fadeInTime + holdTime, function()
		if not notifFrame.Parent then
			return
		end

		local fadeOutInfo = TweenInfo.new(fadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		local frameFadeOut = TweenService:Create(notifFrame, fadeOutInfo, {
			BackgroundTransparency = 1,
		})
		local textFadeOut = TweenService:Create(textLabel, fadeOutInfo, {
			TextTransparency = 1,
		})
		local accentFadeOut = TweenService:Create(accentLine, fadeOutInfo, {
			BackgroundTransparency = 1,
		})

		frameFadeOut:Play()
		textFadeOut:Play()
		accentFadeOut:Play()

		-- Destroy after fade-out completes
		task.delay(fadeOutTime + 0.1, function()
			-- Remove from active list
			for idx, notif in self.activeNotifications do
				if notif == notifFrame then
					table.remove(self.activeNotifications, idx)
					break
				end
			end

			if notifFrame.Parent then
				notifFrame:Destroy()
			end
		end)
	end)
end

return NotificationDisplay
