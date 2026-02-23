--!strict

--[[
	Notification System (Server)

	Broadcasts multiplayer event notifications to connected clients.
	Supports targeted notifications (specific players) and broadcasts (all players).
	Each notification carries a type so the client can style it appropriately.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

local Remotes = require(script.Parent.Remotes)

local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

export type NotificationSystem = typeof(setmetatable(
	{} :: {
		-- no persistent state needed; this is a fire-and-forget broadcaster
	},
	NotificationSystem
))

--[[
	Create a new NotificationSystem.
]]
function NotificationSystem.new(): NotificationSystem
	local self = setmetatable({}, NotificationSystem)
	return self
end

--[[
	Send a notification to specific players, or all players if targetPlayers is nil.
]]
function NotificationSystem.notify(
	self: NotificationSystem,
	message: string,
	notificationType: Types.NotificationType,
	playerName: string?,
	targetPlayers: { Player }?
)
	local notification: Types.GameNotification = {
		message = message,
		notificationType = notificationType,
		playerName = playerName,
	}

	if not Remotes.GameNotification then
		return
	end

	if targetPlayers then
		for _, player in targetPlayers do
			Remotes.GameNotification:FireClient(player, notification)
		end
	else
		Remotes.GameNotification:FireAllClients(notification)
	end

	print(`[NotificationSystem] [{notificationType}] {message}`)
end

--[[
	Broadcast a notification to all connected players.
]]
function NotificationSystem.notifyAll(self: NotificationSystem, message: string, notificationType: Types.NotificationType, playerName: string?)
	self:notify(message, notificationType, playerName, nil)
end

--[[
	Notify that a player has been downed.
]]
function NotificationSystem.notifyFallen(self: NotificationSystem, player: Player)
	self:notifyAll(`{player.Name} has fallen.`, "fallen", player.Name)
end

--[[
	Notify that a player has been revived.
]]
function NotificationSystem.notifyRevived(self: NotificationSystem, player: Player)
	self:notifyAll(`{player.Name} has been revived.`, "revived", player.Name)
end

--[[
	Notify that a player has died and lost a heart.
]]
function NotificationSystem.notifyDied(self: NotificationSystem, player: Player, livesRemaining: number)
	self:notifyAll(`{player.Name} has died. ({livesRemaining} {if livesRemaining == 1 then "life" else "lives"} remaining)`, "died", player.Name)
end

--[[
	Notify that a player has permanently died (all hearts gone).
]]
function NotificationSystem.notifyGone(self: NotificationSystem, player: Player)
	self:notifyAll(`{player.Name} is gone.`, "gone", player.Name)
end

--[[
	Notify a checkpoint reached (subtle, typically to the triggering player only).
]]
function NotificationSystem.notifyCheckpoint(self: NotificationSystem, player: Player, checkpointName: string)
	self:notify(`Checkpoint: {checkpointName}`, "checkpoint", nil, { player })
end

--[[
	Notify a round event (extraction incoming, etc.) to all players.
]]
function NotificationSystem.notifyEvent(self: NotificationSystem, message: string)
	self:notifyAll(message, "event", nil)
end

return NotificationSystem
