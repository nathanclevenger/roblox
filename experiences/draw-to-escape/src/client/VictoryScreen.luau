--!strict

--[[
	VictoryScreen
	Displayed when the player completes all 50 stages.
	Shows a gallery of their best drawings, stats, and a celebration.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local VictoryScreen = {}
VictoryScreen.__index = VictoryScreen

type VictoryScreenImpl = {
	ScreenGui: ScreenGui,
	IsShowing: boolean,
	_connections: { RBXScriptConnection },
}

function VictoryScreen.new(): VictoryScreenImpl
	local self = setmetatable({}, VictoryScreen) :: any
	self.IsShowing = false
	self._connections = {}
	self:_buildUI()
	return self :: VictoryScreenImpl
end

function VictoryScreen._buildUI(self: VictoryScreenImpl)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VictoryScreen"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 200
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.Enabled = false
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	self.ScreenGui = screenGui

	-- Full screen overlay
	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.Parent = screenGui

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0, 80)
	title.Position = UDim2.fromScale(0.1, 0.08)
	title.BackgroundTransparency = 1
	title.Text = "YOU ESCAPED!"
	title.TextColor3 = Color3.fromRGB(255, 220, 80)
	title.TextSize = 64
	title.Font = Enum.Font.GothamBlack
	title.TextTransparency = 1
	title.TextStrokeColor3 = Color3.fromRGB(180, 120, 0)
	title.TextStrokeTransparency = 1
	title.Parent = screenGui

	-- Subtitle
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(0.6, 0, 0, 30)
	subtitle.Position = UDim2.fromScale(0.2, 0.18)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Your drawings brought you to freedom"
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 210)
	subtitle.TextSize = 20
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.TextTransparency = 1
	subtitle.Parent = screenGui

	-- Stats container
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "Stats"
	statsFrame.Size = UDim2.new(0.5, 0, 0, 120)
	statsFrame.Position = UDim2.fromScale(0.25, 0.75)
	statsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	statsFrame.BackgroundTransparency = 1
	statsFrame.BorderSizePixel = 0
	statsFrame.Parent = screenGui

	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 12)
	statsCorner.Parent = statsFrame

	-- Stats labels (filled in when shown)
	for i, statName in { "Total Stars", "Total Deaths", "Total Drawings", "Best Time" } do
		local statLabel = Instance.new("TextLabel")
		statLabel.Name = `Stat_{statName:gsub(" ", "")}`
		statLabel.Size = UDim2.new(0.25, -10, 1, 0)
		statLabel.Position = UDim2.new((i - 1) * 0.25, 5, 0, 0)
		statLabel.BackgroundTransparency = 1
		statLabel.Text = `{statName}\n---`
		statLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		statLabel.TextSize = 14
		statLabel.Font = Enum.Font.GothamMedium
		statLabel.TextTransparency = 1
		statLabel.TextWrapped = true
		statLabel.Parent = statsFrame
	end

	-- Gallery area (center of screen for displaying art)
	local gallery = Instance.new("Frame")
	gallery.Name = "Gallery"
	gallery.Size = UDim2.fromScale(0.7, 0.45)
	gallery.Position = UDim2.fromScale(0.15, 0.25)
	gallery.BackgroundColor3 = Color3.fromRGB(250, 248, 240)
	gallery.BackgroundTransparency = 1
	gallery.BorderSizePixel = 0
	gallery.Parent = screenGui

	local galleryCorner = Instance.new("UICorner")
	galleryCorner.CornerRadius = UDim.new(0, 12)
	galleryCorner.Parent = gallery

	local galleryLabel = Instance.new("TextLabel")
	galleryLabel.Name = "GalleryLabel"
	galleryLabel.Size = UDim2.new(1, 0, 0, 30)
	galleryLabel.BackgroundTransparency = 1
	galleryLabel.Text = "Your Art Gallery"
	galleryLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
	galleryLabel.TextSize = 18
	galleryLabel.Font = Enum.Font.GothamBold
	galleryLabel.TextTransparency = 1
	galleryLabel.Parent = gallery

	-- Credits
	local credits = Instance.new("TextLabel")
	credits.Name = "Credits"
	credits.Size = UDim2.new(0.6, 0, 0, 40)
	credits.Position = UDim2.fromScale(0.2, 0.92)
	credits.BackgroundTransparency = 1
	credits.Text = "Draw to Escape  |  Thanks for playing!"
	credits.TextColor3 = Color3.fromRGB(140, 140, 150)
	credits.TextSize = 14
	credits.Font = Enum.Font.Gotham
	credits.TextTransparency = 1
	credits.Parent = screenGui
end

function VictoryScreen.Show(self: VictoryScreenImpl, stats: { [string]: any }?)
	if self.IsShowing then
		return
	end
	self.IsShowing = true
	self.ScreenGui.Enabled = true

	-- Fade in background
	local bg = self.ScreenGui:FindFirstChild("Background") :: Frame
	TweenService:Create(bg, TweenInfo.new(1, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.15 }):Play()

	-- Animate title
	task.delay(0.5, function()
		local title = self.ScreenGui:FindFirstChild("Title") :: TextLabel
		TweenService:Create(title, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextTransparency = 0,
			TextStrokeTransparency = 0.3,
		}):Play()
	end)

	-- Animate subtitle
	task.delay(1.2, function()
		local subtitle = self.ScreenGui:FindFirstChild("Subtitle") :: TextLabel
		TweenService:Create(subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
	end)

	-- Animate gallery
	task.delay(1.5, function()
		local gallery = self.ScreenGui:FindFirstChild("Gallery") :: Frame
		TweenService:Create(gallery, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.1 }):Play()

		local galleryLabel = gallery:FindFirstChild("GalleryLabel") :: TextLabel
		TweenService:Create(galleryLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
	end)

	-- Animate stats
	task.delay(2.5, function()
		local statsFrame = self.ScreenGui:FindFirstChild("Stats") :: Frame
		TweenService:Create(statsFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.3 })
			:Play()

		if stats then
			local statValues = {
				TotalStars = stats.TotalStars or 0,
				TotalDeaths = stats.TotalDeaths or 0,
				TotalDrawings = stats.TotalDrawings or 0,
				BestTime = stats.BestTime or "N/A",
			}

			for _, child in statsFrame:GetChildren() do
				if child:IsA("TextLabel") then
					TweenService:Create(child, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { TextTransparency = 0 })
						:Play()

					local statKey = child.Name:gsub("Stat_", "")
					local value = statValues[statKey]
					if value ~= nil then
						local label = child.Text:split("\n")[1]
						child.Text = `{label}\n{value}`
					end
				end
			end
		end
	end)

	-- Credits fade in
	task.delay(3.5, function()
		local credits = self.ScreenGui:FindFirstChild("Credits") :: TextLabel
		TweenService:Create(credits, TweenInfo.new(1, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
	end)

	-- Particle celebration (golden sparkles)
	task.delay(0.3, function()
		self:_spawnParticles()
	end)
end

function VictoryScreen._spawnParticles(self: VictoryScreenImpl)
	-- Create golden sparkle frames that float upward
	for i = 1, 30 do
		task.delay(i * 0.1, function()
			local sparkle = Instance.new("Frame")
			sparkle.Size = UDim2.fromOffset(math.random(4, 10), math.random(4, 10))
			sparkle.Position = UDim2.fromScale(math.random() * 0.9 + 0.05, 1.05)
			sparkle.BackgroundColor3 =
				Color3.fromRGB(math.random(200, 255), math.random(180, 220), math.random(50, 100))
			sparkle.Rotation = math.random(0, 45)
			sparkle.BorderSizePixel = 0
			sparkle.Parent = self.ScreenGui

			local sparkleCorner = Instance.new("UICorner")
			sparkleCorner.CornerRadius = UDim.new(0.5, 0)
			sparkleCorner.Parent = sparkle

			-- Float upward and fade
			local duration = math.random(20, 40) / 10
			TweenService:Create(sparkle, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.fromScale(sparkle.Position.X.Scale + (math.random() - 0.5) * 0.2, -0.1),
				BackgroundTransparency = 1,
				Rotation = sparkle.Rotation + math.random(-90, 90),
			}):Play()

			task.delay(duration, function()
				sparkle:Destroy()
			end)
		end)
	end
end

function VictoryScreen.Destroy(self: VictoryScreenImpl)
	for _, conn in self._connections do
		conn:Disconnect()
	end
	if self.ScreenGui.Parent then
		self.ScreenGui:Destroy()
	end
end

return VictoryScreen
