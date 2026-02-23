--!strict

--[[
	Door System

	Server-authoritative door interaction system. Tracks all doors in the
	level, handles player open/close/unlock logic, and entity door-breaking.
	Doors animate via TweenService and generate sound events for entity AI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)

local Remotes = require(script.Parent.Remotes)

local DoorSystem = {}
DoorSystem.__index = DoorSystem

export type DoorSystem = typeof(setmetatable(
	{} :: {
		doors: { [string]: Types.DoorState },
		playerStateManager: any, -- will be set by GameManager
		onSoundEvent: ((event: Types.SoundEvent) -> ())?,
	},
	DoorSystem
))

function DoorSystem.new(): DoorSystem
	local self = setmetatable({
		doors = {},
		playerStateManager = nil,
		onSoundEvent = nil,
	}, DoorSystem)

	self:connectRemotes()

	return self
end

--[[
	Wire the DoorInteract remote so player door requests are handled server-side.
]]
function DoorSystem.connectRemotes(self: DoorSystem)
	if Remotes.DoorInteract then
		Remotes.DoorInteract.OnServerEvent:Connect(function(player: Player, doorId: unknown)
			-- Never trust the client: validate argument type
			if typeof(doorId) ~= "string" then
				return
			end
			self:interactDoor(player, doorId :: string)
		end)
	end
end

--[[
	Register a door part with the system. Called during level build.
	The part should already exist in the workspace with a ProximityPrompt.
]]
function DoorSystem.registerDoor(
	self: DoorSystem,
	part: Part,
	id: string,
	isLocked: boolean,
	requiredKey: string?
)
	-- Calculate the open CFrame (90 degree rotation around the door's hinge edge)
	local closedCFrame = part.CFrame
	-- Hinge is at the left edge of the door (negative X local direction)
	local halfWidth = part.Size.X / 2
	local hingeOffset = closedCFrame:PointToWorldSpace(Vector3.new(-halfWidth, 0, 0))
	local openCFrame = CFrame.new(hingeOffset)
		* CFrame.Angles(0, math.rad(Constants.DOOR_OPEN_ANGLE), 0)
		* CFrame.new(-hingeOffset)
		* closedCFrame

	local doorState: Types.DoorState = {
		id = id,
		part = part,
		isLocked = isLocked,
		isOpen = false,
		requiredKey = requiredKey,
		soundRadius = Constants.SOUND_DOOR,
		brokenByEntity = false,
		closedCFrame = closedCFrame,
		openCFrame = openCFrame,
	}

	self.doors[id] = doorState

	-- Store door id on the part so the client can reference it
	part:SetAttribute("DoorId", id)

	print(`[DoorSystem] Registered door: {id} (locked: {isLocked})`)
end

--[[
	Handle a player interacting with a door.
	- Locked + has key -> unlock + open (consume key)
	- Locked + no key -> play locked feedback
	- Unlocked -> toggle open/close
]]
function DoorSystem.interactDoor(self: DoorSystem, player: Player, doorId: string)
	local door = self.doors[doorId]
	if not door then
		warn(`[DoorSystem] Player {player.Name} tried to interact with invalid door: {doorId}`)
		return
	end

	-- If broken by entity, door stays open permanently
	if door.brokenByEntity then
		return
	end

	if door.isLocked then
		-- Check if the player has the required key
		local hasKey = false
		if door.requiredKey and self.playerStateManager then
			local state = self.playerStateManager:getState(player)
			if state then
				for _, keyName in state.keyItems do
					if keyName == door.requiredKey then
						hasKey = true
						break
					end
				end
			end
		end

		if hasKey then
			-- Unlock and open: consume the key
			door.isLocked = false
			if door.part then
				door.part:SetAttribute("IsLocked", false)
				-- Update the ProximityPrompt
				local prompt = door.part:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					prompt.ActionText = "Close"
				end
			end

			-- Remove the key from the player's inventory
			if door.requiredKey and self.playerStateManager then
				self.playerStateManager:removeItem(player, door.requiredKey :: string)
			end

			self:openDoor(doorId, Constants.DOOR_OPEN_DURATION)
			self:notifyStateChanged(doorId, "unlocked")

			print(`[DoorSystem] {player.Name} unlocked door {doorId} with {door.requiredKey}`)
		else
			-- No key: send locked feedback to the client
			self:notifyStateChanged(doorId, "locked")
			-- Generate a quiet sound event (rattling the locked door)
			self:emitDoorSound(door, 10)
		end
	else
		-- Toggle open/close
		if door.isOpen then
			self:closeDoor(doorId, Constants.DOOR_OPEN_DURATION)
		else
			self:openDoor(doorId, Constants.DOOR_OPEN_DURATION)
		end
	end
end

--[[
	Open a door with a tween animation.
]]
function DoorSystem.openDoor(self: DoorSystem, doorId: string, duration: number)
	local door = self.doors[doorId]
	if not door or door.isOpen then
		return
	end

	door.isOpen = true

	if door.part and door.openCFrame then
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(door.part, tweenInfo, {
			CFrame = door.openCFrame,
		})
		tween:Play()
	end

	-- Update ProximityPrompt text
	if door.part then
		local prompt = door.part:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.ActionText = "Close"
		end
	end

	-- Emit sound event for entity hearing
	self:emitDoorSound(door, door.soundRadius)
	self:notifyStateChanged(doorId, "opened")
end

--[[
	Close a door with a tween animation.
]]
function DoorSystem.closeDoor(self: DoorSystem, doorId: string, duration: number)
	local door = self.doors[doorId]
	if not door or not door.isOpen then
		return
	end

	-- Cannot close a door broken by entity
	if door.brokenByEntity then
		return
	end

	door.isOpen = false

	if door.part and door.closedCFrame then
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(door.part, tweenInfo, {
			CFrame = door.closedCFrame,
		})
		tween:Play()
	end

	-- Update ProximityPrompt text
	if door.part then
		local prompt = door.part:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.ActionText = "Open"
		end
	end

	-- Emit sound event for entity hearing
	self:emitDoorSound(door, door.soundRadius)
	self:notifyStateChanged(doorId, "closed")
end

--[[
	Entity forces open a door during chase. The door slams open violently
	and stays open permanently.
]]
function DoorSystem.entityBreakDoor(self: DoorSystem, doorId: string)
	local door = self.doors[doorId]
	if not door then
		return
	end

	-- If already open or already broken, nothing to do
	if door.isOpen and door.brokenByEntity then
		return
	end

	-- Force unlock if locked
	door.isLocked = false
	door.isOpen = true
	door.brokenByEntity = true

	if door.part then
		door.part:SetAttribute("IsLocked", false)

		-- Violent slam open animation (fast tween)
		if door.openCFrame then
			local tweenInfo = TweenInfo.new(
				Constants.DOOR_ENTITY_BREAK_DURATION,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			)
			local tween = TweenService:Create(door.part, tweenInfo, {
				CFrame = door.openCFrame,
			})
			tween:Play()
		end

		-- Disable ProximityPrompt since the door is permanently open
		local prompt = door.part:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Enabled = false
		end
	end

	-- Loud sound event (1.5x normal door radius)
	self:emitDoorSound(door, door.soundRadius * 1.5)
	self:notifyStateChanged(doorId, "broken")

	print(`[DoorSystem] Entity broke door: {doorId}`)
end

--[[
	Entity opens a door normally during patrol/investigate (slower, quieter).
]]
function DoorSystem.entityOpenDoorQuietly(self: DoorSystem, doorId: string)
	local door = self.doors[doorId]
	if not door or door.isOpen then
		return
	end

	-- Force unlock if locked
	door.isLocked = false
	self:openDoor(doorId, Constants.DOOR_ENTITY_PATROL_OPEN_DURATION)
end

--[[
	Check if a door is currently open.
]]
function DoorSystem.isOpen(self: DoorSystem, doorId: string): boolean
	local door = self.doors[doorId]
	if not door then
		return true -- non-existent door counts as passable
	end
	return door.isOpen
end

--[[
	Find doors near a position that are closed (for entity door detection).
	Returns the first closed door found within range, or nil.
]]
function DoorSystem.findClosedDoorNear(
	self: DoorSystem,
	position: Vector3,
	direction: Vector3,
	range: number
): string?
	local bestDoorId: string? = nil
	local bestDist = math.huge

	for id, door in self.doors do
		if door.isOpen then
			continue
		end
		if not door.part then
			continue
		end

		local doorPos = door.part.Position
		local towardDoor = doorPos - position
		local flatToward = Vector3.new(towardDoor.X, 0, towardDoor.Z)
		local dist = flatToward.Magnitude

		if dist > range then
			continue
		end

		-- Check if the door is roughly in the movement direction
		local flatDir = Vector3.new(direction.X, 0, direction.Z)
		if flatDir.Magnitude > 0.01 then
			local dot = flatDir.Unit:Dot(flatToward.Unit)
			if dot < 0.3 then
				continue -- Door is not in front of entity
			end
		end

		if dist < bestDist then
			bestDist = dist
			bestDoorId = id
		end
	end

	return bestDoorId
end

--[[
	Emit a sound event from the door's position for entity hearing.
]]
function DoorSystem.emitDoorSound(self: DoorSystem, door: Types.DoorState, radius: number)
	if not self.onSoundEvent then
		return
	end

	local position = if door.part then door.part.Position else Vector3.zero
	self.onSoundEvent({
		position = position,
		radius = radius,
		priority = "Medium",
		source = nil,
	})
end

--[[
	Notify all clients of a door state change for animation sync.
]]
function DoorSystem.notifyStateChanged(_self: DoorSystem, doorId: string, action: string)
	if Remotes.DoorStateChanged then
		Remotes.DoorStateChanged:FireAllClients({
			doorId = doorId,
			action = action,
		})
	end
end

--[[
	Reset all doors to initial state (called on round end).
]]
function DoorSystem.cleanup(self: DoorSystem)
	-- Restore all doors to their closed CFrame before clearing
	for _, door in self.doors do
		if door.part and door.closedCFrame then
			door.part.CFrame = door.closedCFrame
		end
		-- Re-enable prompts
		if door.part then
			local prompt = door.part:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Enabled = true
			end
		end
	end

	table.clear(self.doors)
	print("[DoorSystem] Cleaned up all doors")
end

return DoorSystem
