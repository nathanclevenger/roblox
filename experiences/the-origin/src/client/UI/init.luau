--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

local DeathAnimation = require(script.DeathAnimation)
local HealthDisplay = require(script.HealthDisplay)
local HeartsHUD = require(script.HeartsHUD)
local InventoryDisplay = require(script.InventoryDisplay)
local NotificationDisplay = require(script.NotificationDisplay)
local ObjectiveTracker = require(script.ObjectiveTracker)
local SpectatorUI = require(script.SpectatorUI)
local StaminaBar = require(script.StaminaBar)

local UI = {}

function UI.new(player: Player)
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameUI"
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 10
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local self = {
		screenGui = screenGui,
		health = HealthDisplay.new(screenGui),
		heartsHUD = HeartsHUD.new(screenGui),
		deathAnimation = DeathAnimation.new(screenGui),
		stamina = StaminaBar.new(screenGui),
		inventory = InventoryDisplay.new(screenGui),
		objectives = ObjectiveTracker.new(screenGui),
		spectator = SpectatorUI.new(screenGui),
		notifications = NotificationDisplay.new(screenGui),
	}

	return self
end

-- Update methods that remotes call into
function UI.updateHealth(self: any, health: number, maxHealth: number, isBleeding: boolean)
	self.health:update(health, maxHealth, isBleeding)
end

function UI.updateStamina(self: any, stamina: number)
	self.stamina:update(stamina)
end

function UI.updateInventory(self: any, inventory: { Types.InventoryItem }, keyItems: { string })
	self.inventory:update(inventory, keyItems)
end

function UI.updateObjective(self: any, objective: Types.ObjectiveStep?)
	self.objectives:update(objective)
end

function UI.loadObjectives(self: any, objectives: { Types.ObjectiveStep })
	self.objectives:loadAll(objectives)
end

--[[
	Update the hearts HUD display.
]]
function UI.updateHearts(self: any, hearts: number, deathCount: number)
	self.heartsHUD:update(hearts, deathCount)
end

--[[
	Set the proximity fear tier on the hearts HUD for pulse synchronization.
]]
function UI.setFearTier(self: any, tier: number)
	self.heartsHUD:setFearTier(tier)
end

--[[
	Play the death animation for the given death number (1, 2, or 3).
	Hides the HUD during the animation.
]]
function UI.playDeathAnimation(self: any, deathNumber: number)
	self.heartsHUD:hide()
	self.deathAnimation:play(deathNumber)
end

--[[
	Called after respawn — re-show the hearts HUD.
]]
function UI.onRespawn(self: any)
	self.heartsHUD:show()
end

--[[
	Check if the death animation is currently playing.
]]
function UI.isDeathAnimationPlaying(self: any): boolean
	return self.deathAnimation:getIsPlaying()
end

--[[
	Enter spectator mode — show the CCTV overlay.
]]
function UI.enterSpectator(self: any, cameraName: string?)
	self.spectator:enter(cameraName)
end

--[[
	Exit spectator mode — hide the CCTV overlay.
]]
function UI.exitSpectator(self: any)
	self.spectator:exit()
end

--[[
	Update the CCTV camera display when cycling cameras.
]]
function UI.updateSpectatorCamera(self: any, cameraName: string, index: number, total: number)
	self.spectator:updateCamera(cameraName, index, total)
end

--[[
	Show a game notification (multiplayer events: fallen, revived, died, gone, etc.)
]]
function UI.showGameNotification(self: any, notification: Types.GameNotification)
	self.notifications:showNotification(notification)
end

--[[
	Show a brief notification message on screen (e.g., "Locked", "Unlocked").
	Fades in, stays briefly, then fades out and self-destructs.
]]
function UI.showNotification(self: any, message: string)
	local TweenService = game:GetService("TweenService")

	local label = Instance.new("TextLabel")
	label.Name = "Notification"
	label.Text = message
	label.Font = Enum.Font.GothamBold
	label.TextSize = 28
	label.TextColor3 = Color3.fromRGB(220, 220, 210)
	label.TextStrokeTransparency = 0.5
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.4, 0, 0.06, 0)
	label.Position = UDim2.new(0.3, 0, 0.4, 0)
	label.AnchorPoint = Vector2.new(0, 0)
	label.TextTransparency = 1
	label.Parent = self.screenGui

	-- Fade in
	local fadeIn = TweenService:Create(label, TweenInfo.new(0.2), { TextTransparency = 0 })
	fadeIn:Play()

	-- Hold then fade out and destroy
	task.delay(1.5, function()
		local fadeOut = TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1 })
		fadeOut:Play()
		fadeOut.Completed:Wait()
		if label.Parent then
			label:Destroy()
		end
	end)
end

return UI
