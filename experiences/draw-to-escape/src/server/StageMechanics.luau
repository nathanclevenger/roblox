--!strict

--[[
	StageMechanics
	Handles all interactive stage elements by scanning stage models for tagged parts
	and applying dynamic behaviors. Supports wind zones, water/river hazards, pressure
	plates, crumbling tiles, collapsing sections, lasers, timed gates, gravity flips,
	lightning zones, frozen gates, and unstable platforms.

	Usage:
		local mechanics = StageMechanics.new()
		mechanics.OnPlayerKill = function(player) handlePlayerDeath(player) end
		mechanics:ActivateStage(stageModel)
		-- later...
		mechanics:DeactivateStage(stageModel)
		mechanics:Destroy()
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage.Shared.Constants)

-- ================================================================
-- TYPES
-- ================================================================

type WindZone = {
	Part: Part,
	Force: Vector3,
}

type WaterZone = {
	Part: Part,
	Connection: RBXScriptConnection,
}

type PressurePlate = {
	Part: Part,
	RequiredWeight: number,
	Gates: { Part },
	IsActivated: boolean,
}

type CrumblingTile = {
	Part: Part,
	Connection: RBXScriptConnection,
	IsTriggered: boolean,
}

type CollapsingSection = {
	Part: Part,
	OriginalPosition: Vector3,
	IsTriggered: boolean,
}

type Laser = {
	Part: Part,
	Connection: RBXScriptConnection,
}

type TimedGate = {
	Gate: Part,
	Trigger: Part,
	OpenDuration: number,
	IsOpen: boolean,
	TriggerConnection: RBXScriptConnection,
}

type GravityFlipZone = {
	Part: Part,
	FlipInterval: number,
	Elapsed: number,
	IsFlipped: boolean,
	AffectedPlayers: { [Player]: boolean },
}

type LightningZone = {
	Part: Part,
	StrikeInterval: number,
	Elapsed: number,
}

type FrozenGate = {
	Gate: Part,
	HeatTarget: Part,
	IsMelted: boolean,
}

type UnstablePlatform = {
	Part: Part,
	Connection: RBXScriptConnection,
	IsTriggered: boolean,
	OriginalPosition: Vector3,
	ShakeElapsed: number,
}

type StageMechanicsData = {
	WindZones: { WindZone },
	WaterZones: { WaterZone },
	PressurePlates: { PressurePlate },
	CrumblingTiles: { CrumblingTile },
	CollapsingSections: { CollapsingSection },
	Lasers: { Laser },
	TimedGates: { TimedGate },
	GravityFlipZones: { GravityFlipZone },
	LightningZones: { LightningZone },
	FrozenGates: { FrozenGate },
	UnstablePlatforms: { UnstablePlatform },
}

type StageMechanicsImpl = {
	ActiveMechanics: { [Model]: StageMechanicsData },
	_connections: { RBXScriptConnection },
	_heartbeatConn: RBXScriptConnection?,
	OnPlayerKill: ((Player) -> ())?,
}

-- ================================================================
-- MODULE
-- ================================================================

local StageMechanics = {}
StageMechanics.__index = StageMechanics

-- ================================================================
-- HELPERS
-- ================================================================

--- Get the MaterializedDrawings folder for scanning drawings in the world.
local function getDrawingsFolder(): Folder?
	return workspace:FindFirstChild("MaterializedDrawings") :: Folder?
end

--- Check if a part's bounding box overlaps with a zone part's bounding box (AABB test).
local function isInsideZone(part: BasePart, zone: Part): boolean
	local zonePos = zone.Position
	local zoneHalf = zone.Size * 0.5
	local partPos = part.Position

	return math.abs(partPos.X - zonePos.X) < zoneHalf.X
		and math.abs(partPos.Y - zonePos.Y) < zoneHalf.Y
		and math.abs(partPos.Z - zonePos.Z) < zoneHalf.Z
end

--- Check if a player's character is inside a zone.
local function isPlayerInZone(player: Player, zone: Part): boolean
	local character = player.Character
	if not character then
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return false
	end

	return isInsideZone(rootPart, zone)
end

--- Get all unanchored drawing parts near a position within a radius.
local function getDrawingPartsInZone(zone: Part): { BasePart }
	local results: { BasePart } = {}
	local folder = getDrawingsFolder()
	if not folder then
		return results
	end

	for _, model in folder:GetChildren() do
		if not model:IsA("Model") then
			continue
		end
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") and isInsideZone(part, zone) then
				table.insert(results, part)
			end
		end
	end

	return results
end

--- Get a player's humanoid safely.
local function getHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

--- Get a player's root part safely.
local function getRootPart(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

--- Kill a player via the registered callback. Includes safety checks.
local function killPlayer(self: StageMechanicsImpl, player: Player)
	local humanoid = getHumanoid(player)
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if self.OnPlayerKill then
		self.OnPlayerKill(player)
	end
end

--- Check if a part belongs to a player character (to avoid self-kill on touch events).
local function getPlayerFromPart(hit: BasePart): Player?
	local character = hit.Parent
	if not character then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

--- Find all drawing models near a position within a given radius.
local function getDrawingModelsNear(position: Vector3, radius: number): { Model }
	local results: { Model } = {}
	local folder = getDrawingsFolder()
	if not folder then
		return results
	end

	for _, model in folder:GetChildren() do
		if not model:IsA("Model") then
			continue
		end
		local primary = model.PrimaryPart
		if primary and (primary.Position - position).Magnitude < radius then
			table.insert(results, model)
		end
	end

	return results
end

--- Determine if a drawing model uses a flammable material by checking part materials.
local function isDrawingFlammable(model: Model): boolean
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			-- Check against known flammable materials from Constants
			for _materialName, props in Constants.MATERIAL_PROPERTIES do
				if props.Flammable and part.Material == props.RobloxMaterial then
					return true
				end
			end
		end
	end
	return false
end

--- Check if a drawing model contains metal material (conductive).
local function isDrawingMetal(model: Model): boolean
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			if part.Material == Enum.Material.Metal then
				return true
			end
		end
	end
	return false
end

--- Get the total mass resting on a pressure plate by raycasting upward from the plate
--- and checking for overlapping parts using GetTouchingParts.
local function getMassOnPlate(plate: Part): number
	-- Temporarily enable a TouchInterest so GetTouchingParts works on anchored parts.
	-- We use an overlap region approach instead.
	local totalMass = 0.0
	local platePos = plate.Position
	local plateHalf = plate.Size * 0.5

	-- Check all players standing on it
	for _, player in Players:GetPlayers() do
		local rootPart = getRootPart(player)
		if not rootPart then
			continue
		end

		local pos = rootPart.Position
		-- Player must be above the plate and within horizontal bounds
		local abovePlate = pos.Y > platePos.Y and pos.Y < platePos.Y + 10
		local withinX = math.abs(pos.X - platePos.X) < plateHalf.X + 2
		local withinZ = math.abs(pos.Z - platePos.Z) < plateHalf.Z + 2
		if abovePlate and withinX and withinZ then
			-- Average Roblox character mass is roughly 10-15
			totalMass += 12
		end
	end

	-- Check drawing parts on the plate
	local folder = getDrawingsFolder()
	if folder then
		for _, model in folder:GetChildren() do
			if not model:IsA("Model") then
				continue
			end
			for _, part in model:GetDescendants() do
				if not part:IsA("BasePart") then
					continue
				end
				local pos = part.Position
				local abovePlate = pos.Y > platePos.Y and pos.Y < platePos.Y + 10
				local withinX = math.abs(pos.X - platePos.X) < plateHalf.X + 2
				local withinZ = math.abs(pos.Z - platePos.Z) < plateHalf.Z + 2
				if abovePlate and withinX and withinZ then
					local physProps = part.CustomPhysicalProperties
					local density = if physProps then physProps.Density else 1.0
					local volume = part.Size.X * part.Size.Y * part.Size.Z
					totalMass += density * volume
				end
			end
		end
	end

	return totalMass
end

-- ================================================================
-- SCANNER FUNCTIONS
-- Each scans a stage model for specific tagged parts and returns
-- the mechanic data structures with connections/state initialized.
-- ================================================================

--- Scan for WindZone parts (children with a "WindForce" Vector3Value).
local function scanWindZones(stageModel: Model): { WindZone }
	local zones: { WindZone } = {}
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local windValue = descendant:FindFirstChild("WindForce") :: Vector3Value?
		if windValue and windValue:IsA("Vector3Value") then
			table.insert(zones, {
				Part = descendant :: Part,
				Force = windValue.Value,
			})
		end
	end
	return zones
end

--- Scan for Water/River parts (children with "IsWater" BoolValue).
local function scanWaterZones(self: StageMechanicsImpl, stageModel: Model): { WaterZone }
	local zones: { WaterZone } = {}
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local waterTag = descendant:FindFirstChild("IsWater") :: BoolValue?
		if not waterTag or not waterTag:IsA("BoolValue") or not waterTag.Value then
			continue
		end

		local part = descendant :: Part
		local connection = part.Touched:Connect(function(hit: BasePart)
			local player = getPlayerFromPart(hit)
			if player then
				killPlayer(self, player)
			end
		end)

		table.insert(zones, {
			Part = part,
			Connection = connection,
		})
	end
	return zones
end

--- Scan for PressurePlate parts (children with "IsPressurePlate" BoolValue + "RequiredWeight" NumberValue).
--- Also finds linked "IsGate" parts within the same stage model.
local function scanPressurePlates(stageModel: Model): { PressurePlate }
	local plates: { PressurePlate } = {}

	-- First, collect all gate parts in this stage
	local gates: { Part } = {}
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local gateTag = descendant:FindFirstChild("IsGate") :: BoolValue?
		if gateTag and gateTag:IsA("BoolValue") and gateTag.Value then
			table.insert(gates, descendant :: Part)
		end
	end

	-- Now find pressure plates
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local plateTag = descendant:FindFirstChild("IsPressurePlate") :: BoolValue?
		if not plateTag or not plateTag:IsA("BoolValue") or not plateTag.Value then
			continue
		end

		local weightValue = descendant:FindFirstChild("RequiredWeight") :: NumberValue?
		local requiredWeight = if weightValue and weightValue:IsA("NumberValue") then weightValue.Value else 50

		table.insert(plates, {
			Part = descendant :: Part,
			RequiredWeight = requiredWeight,
			Gates = gates, -- All gates in the stage are linked to all plates
			IsActivated = false,
		})
	end

	return plates
end

--- Scan for CrumblingTile parts (children with "IsCrumblingTile" BoolValue).
local function scanCrumblingTiles(stageModel: Model): { CrumblingTile }
	local tiles: { CrumblingTile } = {}
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local tileTag = descendant:FindFirstChild("IsCrumblingTile") :: BoolValue?
		if not tileTag or not tileTag:IsA("BoolValue") or not tileTag.Value then
			continue
		end

		local part = descendant :: Part
		-- We create a placeholder connection; the actual Touched logic is set up below
		-- because we need `self` for the kill callback, but crumbling tiles don't kill --
		-- they just destroy themselves. We still track the connection for cleanup.
		local triggered = false

		local connection = part.Touched:Connect(function(hit: BasePart)
			if triggered then
				return
			end
			local player = getPlayerFromPart(hit)
			if not player then
				return
			end

			triggered = true

			-- Visual warning: change color to red-ish tint
			local originalColor = part.Color
			TweenService:Create(part, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Color = Color3.fromRGB(
					math.min(255, math.floor(originalColor.R * 255 + 80)),
					math.max(0, math.floor(originalColor.G * 255 - 60)),
					math.max(0, math.floor(originalColor.B * 255 - 60))
				),
			}):Play()

			-- Shake slightly
			task.spawn(function()
				local origin = part.Position
				for _ = 1, 20 do
					if not part.Parent then
						return
					end
					part.Position = origin
						+ Vector3.new(
							(math.random() - 0.5) * 0.3,
							(math.random() - 0.5) * 0.1,
							(math.random() - 0.5) * 0.3
						)
					task.wait(0.1)
				end
			end)

			-- After 2 seconds, shrink and destroy
			task.delay(2, function()
				if not part.Parent then
					return
				end
				local shrinkTween =
					TweenService:Create(part, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
						Size = Vector3.new(0.1, 0.1, 0.1),
						Transparency = 1,
					})
				shrinkTween:Play()
				shrinkTween.Completed:Wait()
				if part.Parent then
					part:Destroy()
				end
			end)
		end)

		table.insert(tiles, {
			Part = part,
			Connection = connection,
			IsTriggered = false,
		})
	end
	return tiles
end

--- Scan for CollapsingSection parts (children with "IsCollapsingSection" BoolValue).
local function scanCollapsingSections(stageModel: Model): { CollapsingSection }
	local sections: { CollapsingSection } = {}
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local tag = descendant:FindFirstChild("IsCollapsingSection") :: BoolValue?
		if not tag or not tag:IsA("BoolValue") or not tag.Value then
			continue
		end

		table.insert(sections, {
			Part = descendant :: Part,
			OriginalPosition = (descendant :: Part).Position,
			IsTriggered = false,
		})
	end
	return sections
end

--- Scan for Laser parts (children with "IsLaser" BoolValue).
local function scanLasers(self: StageMechanicsImpl, stageModel: Model): { Laser }
	local lasers: { Laser } = {}
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local tag = descendant:FindFirstChild("IsLaser") :: BoolValue?
		if not tag or not tag:IsA("BoolValue") or not tag.Value then
			continue
		end

		local part = descendant :: Part
		local connection = part.Touched:Connect(function(hit: BasePart)
			local player = getPlayerFromPart(hit)
			if player then
				killPlayer(self, player)
			end
		end)

		table.insert(lasers, {
			Part = part,
			Connection = connection,
		})
	end
	return lasers
end

--- Scan for TimedGate parts (children with "IsTimedGate" BoolValue + "OpenDuration" NumberValue).
--- Also finds associated trigger parts with "IsGateTrigger" BoolValue.
local function scanTimedGates(stageModel: Model): { TimedGate }
	local timedGates: { TimedGate } = {}

	-- Collect timed gate parts
	local gatesByName: { [string]: Part } = {}
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local gateTag = descendant:FindFirstChild("IsTimedGate") :: BoolValue?
		if gateTag and gateTag:IsA("BoolValue") and gateTag.Value then
			gatesByName[descendant.Name] = descendant :: Part
		end
	end

	-- Find triggers and link them to gates
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local triggerTag = descendant:FindFirstChild("IsGateTrigger") :: BoolValue?
		if not triggerTag or not triggerTag:IsA("BoolValue") or not triggerTag.Value then
			continue
		end

		-- Find the corresponding gate. Convention: trigger has a "LinkedGate" StringValue
		-- pointing to the gate's name. If none, link to the first timed gate found.
		local linkedName = descendant:FindFirstChild("LinkedGate") :: StringValue?
		local gate: Part? = nil
		if linkedName and linkedName:IsA("StringValue") then
			gate = gatesByName[linkedName.Value]
		else
			-- Default: link to the first available timed gate
			for _, g in gatesByName do
				gate = g
				break
			end
		end

		if not gate then
			continue
		end

		local durationValue = gate:FindFirstChild("OpenDuration") :: NumberValue?
		local openDuration = if durationValue and durationValue:IsA("NumberValue") then durationValue.Value else 3

		local triggerPart = descendant :: Part
		local isOpen = false

		local connection = triggerPart.Touched:Connect(function(hit: BasePart)
			local player = getPlayerFromPart(hit)
			if not player or isOpen then
				return
			end

			isOpen = true

			-- Open the gate
			local originalTransparency = gate.Transparency
			local originalCanCollide = gate.CanCollide

			TweenService:Create(gate, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
				Transparency = 0.7,
			}):Play()
			gate.CanCollide = false

			-- Close after OpenDuration seconds
			task.delay(openDuration, function()
				if not gate.Parent then
					return
				end
				TweenService:Create(gate, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
					Transparency = originalTransparency,
				}):Play()
				gate.CanCollide = originalCanCollide
				isOpen = false
			end)
		end)

		table.insert(timedGates, {
			Gate = gate,
			Trigger = triggerPart,
			OpenDuration = openDuration,
			IsOpen = false,
			TriggerConnection = connection,
		})
	end

	return timedGates
end

--- Scan for GravityFlip zones (children with "IsGravityFlip" BoolValue).
local function scanGravityFlipZones(stageModel: Model): { GravityFlipZone }
	local zones: { GravityFlipZone } = {}
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local tag = descendant:FindFirstChild("IsGravityFlip") :: BoolValue?
		if not tag or not tag:IsA("BoolValue") or not tag.Value then
			continue
		end

		local intervalValue = descendant:FindFirstChild("FlipInterval") :: NumberValue?
		local flipInterval = if intervalValue and intervalValue:IsA("NumberValue") then intervalValue.Value else 10

		table.insert(zones, {
			Part = descendant :: Part,
			FlipInterval = flipInterval,
			Elapsed = 0,
			IsFlipped = false,
			AffectedPlayers = {},
		})
	end
	return zones
end

--- Scan for LightningZone parts (children with "IsLightningZone" BoolValue + "StrikeInterval").
local function scanLightningZones(stageModel: Model): { LightningZone }
	local zones: { LightningZone } = {}
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local tag = descendant:FindFirstChild("IsLightningZone") :: BoolValue?
		if not tag or not tag:IsA("BoolValue") or not tag.Value then
			continue
		end

		local intervalValue = descendant:FindFirstChild("StrikeInterval") :: NumberValue?
		local strikeInterval = if intervalValue and intervalValue:IsA("NumberValue") then intervalValue.Value else 5

		table.insert(zones, {
			Part = descendant :: Part,
			StrikeInterval = strikeInterval,
			Elapsed = 0,
		})
	end
	return zones
end

--- Scan for FrozenGate parts (children with "IsFrozenGate" BoolValue).
--- Also finds associated "IsHeatTarget" parts within the same stage model.
local function scanFrozenGates(stageModel: Model): { FrozenGate }
	local frozenGates: { FrozenGate } = {}

	-- Collect heat targets
	local heatTargets: { Part } = {}
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local tag = descendant:FindFirstChild("IsHeatTarget") :: BoolValue?
		if tag and tag:IsA("BoolValue") and tag.Value then
			table.insert(heatTargets, descendant :: Part)
		end
	end

	-- Collect frozen gates and pair with nearest heat target
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local tag = descendant:FindFirstChild("IsFrozenGate") :: BoolValue?
		if not tag or not tag:IsA("BoolValue") or not tag.Value then
			continue
		end

		-- Find the nearest heat target
		local gatePart = descendant :: Part
		local nearestTarget: Part? = nil
		local nearestDist = math.huge
		for _, target in heatTargets do
			local dist = (target.Position - gatePart.Position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearestTarget = target
			end
		end

		-- If no explicit heat target, use the gate itself as the proximity check point
		if not nearestTarget then
			nearestTarget = gatePart
		end

		table.insert(frozenGates, {
			Gate = gatePart,
			HeatTarget = nearestTarget :: Part,
			IsMelted = false,
		})
	end

	return frozenGates
end

--- Scan for UnstablePlatform parts (children with "IsUnstable" BoolValue).
local function scanUnstablePlatforms(stageModel: Model): { UnstablePlatform }
	local platforms: { UnstablePlatform } = {}
	for _, descendant in stageModel:GetDescendants() do
		if not descendant:IsA("BasePart") then
			continue
		end
		local tag = descendant:FindFirstChild("IsUnstable") :: BoolValue?
		if not tag or not tag:IsA("BoolValue") or not tag.Value then
			continue
		end

		local part = descendant :: Part
		local triggered = false
		local originalPosition = part.Position
		local shakeElapsed = 0.0

		local connection = part.Touched:Connect(function(hit: BasePart)
			if triggered then
				return
			end
			local player = getPlayerFromPart(hit)
			if not player then
				return
			end

			triggered = true

			-- Shake for 3 seconds, then unanchor and let fall
			task.spawn(function()
				local startTime = tick()
				while tick() - startTime < 3 do
					if not part.Parent then
						return
					end
					local intensity = (tick() - startTime) / 3 -- Increases over time
					part.Position = originalPosition
						+ Vector3.new(
							(math.random() - 0.5) * intensity * 0.8,
							(math.random() - 0.5) * intensity * 0.3,
							(math.random() - 0.5) * intensity * 0.8
						)
					task.wait(0.03)
				end

				if not part.Parent then
					return
				end

				-- Unanchor and let it fall
				part.Anchored = false
				part.CanCollide = true

				-- Destroy after falling for 3 seconds
				task.delay(3, function()
					if part.Parent then
						local fadeTween = TweenService:Create(part, TweenInfo.new(0.5), {
							Transparency = 1,
						})
						fadeTween:Play()
						fadeTween.Completed:Wait()
						if part.Parent then
							part:Destroy()
						end
					end
				end)
			end)
		end)

		table.insert(platforms, {
			Part = part,
			Connection = connection,
			IsTriggered = false,
			OriginalPosition = originalPosition,
			ShakeElapsed = shakeElapsed,
		})
	end
	return platforms
end

-- ================================================================
-- CONSTRUCTOR
-- ================================================================

function StageMechanics.new(): StageMechanicsImpl
	local self = setmetatable({}, StageMechanics) :: any

	self.ActiveMechanics = {}
	self._connections = {}
	self._heartbeatConn = nil
	self.OnPlayerKill = nil

	-- Start the main heartbeat loop that drives all frame-based mechanics
	self._heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
		self:_update(dt)
	end)

	return self :: StageMechanicsImpl
end

-- ================================================================
-- ACTIVATE / DEACTIVATE
-- ================================================================

--- Scan a stage model for all tagged parts and set up the appropriate behaviors.
function StageMechanics.ActivateStage(self: StageMechanicsImpl, stageModel: Model)
	-- Don't double-activate
	if self.ActiveMechanics[stageModel] then
		return
	end

	local data: StageMechanicsData = {
		WindZones = scanWindZones(stageModel),
		WaterZones = scanWaterZones(self, stageModel),
		PressurePlates = scanPressurePlates(stageModel),
		CrumblingTiles = scanCrumblingTiles(stageModel),
		CollapsingSections = scanCollapsingSections(stageModel),
		Lasers = scanLasers(self, stageModel),
		TimedGates = scanTimedGates(stageModel),
		GravityFlipZones = scanGravityFlipZones(stageModel),
		LightningZones = scanLightningZones(stageModel),
		FrozenGates = scanFrozenGates(stageModel),
		UnstablePlatforms = scanUnstablePlatforms(stageModel),
	}

	self.ActiveMechanics[stageModel] = data

	-- Log activation summary
	local totalMechanics = #data.WindZones
		+ #data.WaterZones
		+ #data.PressurePlates
		+ #data.CrumblingTiles
		+ #data.CollapsingSections
		+ #data.Lasers
		+ #data.TimedGates
		+ #data.GravityFlipZones
		+ #data.LightningZones
		+ #data.FrozenGates
		+ #data.UnstablePlatforms

	if totalMechanics > 0 then
		print(`[StageMechanics] Activated {totalMechanics} mechanics for {stageModel.Name}`)
	end
end

--- Deactivate all mechanics for a stage, disconnecting events and cleaning up state.
function StageMechanics.DeactivateStage(self: StageMechanicsImpl, stageModel: Model)
	local data = self.ActiveMechanics[stageModel]
	if not data then
		return
	end

	-- Disconnect water zone touch connections
	for _, zone in data.WaterZones do
		zone.Connection:Disconnect()
	end

	-- Disconnect crumbling tile connections
	for _, tile in data.CrumblingTiles do
		tile.Connection:Disconnect()
	end

	-- Disconnect laser connections
	for _, laser in data.Lasers do
		laser.Connection:Disconnect()
	end

	-- Disconnect timed gate trigger connections
	for _, timedGate in data.TimedGates do
		timedGate.TriggerConnection:Disconnect()
	end

	-- Disconnect unstable platform connections
	for _, platform in data.UnstablePlatforms do
		platform.Connection:Disconnect()
	end

	-- Reset gravity for any affected players in gravity flip zones
	for _, zone in data.GravityFlipZones do
		for player, _ in zone.AffectedPlayers do
			local character = player.Character
			if character then
				local bodyForce = character:FindFirstChild("GravityFlipForce") :: BodyForce?
				if bodyForce then
					bodyForce:Destroy()
				end
			end
		end
	end

	self.ActiveMechanics[stageModel] = nil
	print(`[StageMechanics] Deactivated mechanics for {stageModel.Name}`)
end

-- ================================================================
-- HEARTBEAT UPDATE (frame-based mechanics)
-- ================================================================

--- Main update loop called every Heartbeat frame.
function StageMechanics._update(self: StageMechanicsImpl, dt: number)
	for stageModel, data in self.ActiveMechanics do
		-- Safety: if the stage model was destroyed externally, clean up
		if not stageModel.Parent then
			self:DeactivateStage(stageModel)
			continue
		end

		self:_updateWindZones(data, dt)
		self:_updatePressurePlates(data)
		self:_updateWaterBuoyancy(data, dt)
		self:_updateCollapsingSections(data)
		self:_updateGravityFlipZones(data, dt)
		self:_updateLightningZones(data, dt)
		self:_updateFrozenGates(data)
	end
end

-- ================================================================
-- WIND ZONES
-- ================================================================

--- Apply wind force to players and unanchored drawings inside wind zones.
function StageMechanics._updateWindZones(_self: StageMechanicsImpl, data: StageMechanicsData, dt: number)
	for _, zone in data.WindZones do
		if not zone.Part.Parent then
			continue
		end

		local force = zone.Force

		-- Apply to players
		for _, player in Players:GetPlayers() do
			local rootPart = getRootPart(player)
			if not rootPart then
				continue
			end

			if not isInsideZone(rootPart, zone.Part) then
				continue
			end

			-- Apply velocity change to the character's root part
			-- We use AssemblyLinearVelocity for direct physics interaction
			local currentVel = rootPart.AssemblyLinearVelocity
			rootPart.AssemblyLinearVelocity = currentVel + force * dt
		end

		-- Apply to unanchored drawing parts inside the zone
		local drawingParts = getDrawingPartsInZone(zone.Part)
		for _, part in drawingParts do
			if not part.Anchored then
				local currentVel = part.AssemblyLinearVelocity
				part.AssemblyLinearVelocity = currentVel + force * dt
			end
		end
	end
end

-- ================================================================
-- WATER BUOYANCY
-- ================================================================

--- Apply buoyancy forces to floating drawings in water zones.
function StageMechanics._updateWaterBuoyancy(_self: StageMechanicsImpl, data: StageMechanicsData, dt: number)
	for _, zone in data.WaterZones do
		if not zone.Part.Parent then
			continue
		end

		local drawingParts = getDrawingPartsInZone(zone.Part)
		local waterSurfaceY = zone.Part.Position.Y + zone.Part.Size.Y * 0.5

		for _, part in drawingParts do
			if part.Anchored then
				continue
			end

			-- Calculate submersion depth
			local partBottom = part.Position.Y - part.Size.Y * 0.5
			local submersionDepth = math.clamp(waterSurfaceY - partBottom, 0, part.Size.Y)
			local submersionRatio = submersionDepth / math.max(part.Size.Y, 0.01)

			-- Check material buoyancy
			local physProps = part.CustomPhysicalProperties
			local density = if physProps then physProps.Density else 1.0

			-- Buoyancy force: water density (1.0) vs part density, scaled by submersion
			local buoyancyForce = (1.0 - density * 0.5) * submersionRatio * 196.2 * dt
			if buoyancyForce > 0 then
				local currentVel = part.AssemblyLinearVelocity
				part.AssemblyLinearVelocity = Vector3.new(
					currentVel.X * (1 - 0.5 * dt), -- Water drag
					currentVel.Y + buoyancyForce,
					currentVel.Z * (1 - 0.5 * dt) -- Water drag
				)
			end
		end
	end
end

-- ================================================================
-- PRESSURE PLATES
-- ================================================================

--- Check pressure plates each frame and trigger gates when weight threshold is met.
function StageMechanics._updatePressurePlates(_self: StageMechanicsImpl, data: StageMechanicsData)
	for _, plate in data.PressurePlates do
		if not plate.Part.Parent then
			continue
		end

		local mass = getMassOnPlate(plate.Part)
		local shouldActivate = mass >= plate.RequiredWeight

		if shouldActivate and not plate.IsActivated then
			plate.IsActivated = true

			-- Visual feedback: plate sinks slightly and turns green
			TweenService:Create(plate.Part, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Position = plate.Part.Position - Vector3.new(0, 0.3, 0),
				Color = Color3.fromRGB(80, 255, 80),
			}):Play()

			-- Open all linked gates
			for _, gate in plate.Gates do
				if not gate.Parent then
					continue
				end
				gate.CanCollide = false
				TweenService:Create(gate, TweenInfo.new(1.0, Enum.EasingStyle.Quad), {
					Transparency = 0.5,
					Position = gate.Position + Vector3.new(0, gate.Size.Y, 0), -- Slide up
				}):Play()
			end
		elseif not shouldActivate and plate.IsActivated then
			plate.IsActivated = false

			-- Visual feedback: plate rises and turns red
			TweenService:Create(plate.Part, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Position = plate.Part.Position + Vector3.new(0, 0.3, 0),
				Color = Color3.fromRGB(255, 80, 80),
			}):Play()

			-- Close all linked gates (slide back down)
			for _, gate in plate.Gates do
				if not gate.Parent then
					continue
				end
				TweenService:Create(gate, TweenInfo.new(1.0, Enum.EasingStyle.Quad), {
					Transparency = 0,
					Position = gate.Position - Vector3.new(0, gate.Size.Y, 0), -- Slide down
				}):Play()
				-- Re-enable collision after tween completes
				task.delay(1.0, function()
					if gate.Parent then
						gate.CanCollide = true
					end
				end)
			end
		end
	end
end

-- ================================================================
-- COLLAPSING SECTIONS
-- ================================================================

--- Check for players approaching collapsing sections from behind.
--- Triggered when a player is within 10 studs behind the section.
function StageMechanics._updateCollapsingSections(_self: StageMechanicsImpl, data: StageMechanicsData)
	for _, section in data.CollapsingSections do
		if section.IsTriggered or not section.Part.Parent then
			continue
		end

		for _, player in Players:GetPlayers() do
			local rootPart = getRootPart(player)
			if not rootPart then
				continue
			end

			-- "Behind" the section: player is at a lower Z than the section
			-- (stages progress along +Z axis per StageManager.GetStageSpawnPosition)
			local dist = (rootPart.Position - section.Part.Position).Magnitude
			local isBehind = rootPart.Position.Z < section.Part.Position.Z

			if dist < 10 and isBehind then
				section.IsTriggered = true

				-- Start collapse timer
				task.delay(1.5, function()
					if not section.Part.Parent then
						return
					end

					-- Shake briefly
					task.spawn(function()
						local origin = section.Part.Position
						for _ = 1, 10 do
							if not section.Part.Parent then
								return
							end
							section.Part.Position = origin
								+ Vector3.new(
									(math.random() - 0.5) * 0.5,
									(math.random() - 0.5) * 0.2,
									(math.random() - 0.5) * 0.5
								)
							task.wait(0.05)
						end
					end)

					-- Fall animation: unanchor and add downward force
					task.delay(0.5, function()
						if not section.Part.Parent then
							return
						end
						section.Part.Anchored = false

						-- Apply a slight random rotation for dramatic effect
						section.Part.AssemblyAngularVelocity =
							Vector3.new((math.random() - 0.5) * 2, 0, (math.random() - 0.5) * 2)

						-- Fade and destroy after falling
						task.delay(2.5, function()
							if section.Part.Parent then
								local fadeTween = TweenService:Create(section.Part, TweenInfo.new(0.5), {
									Transparency = 1,
								})
								fadeTween:Play()
								fadeTween.Completed:Wait()
								if section.Part.Parent then
									section.Part:Destroy()
								end
							end
						end)
					end)
				end)

				break -- Only one player needs to trigger it
			end
		end
	end
end

-- ================================================================
-- GRAVITY FLIP ZONES
-- ================================================================

--- Toggle gravity for players inside gravity flip zones.
--- Normal gravity = 196.2, flipped = -196.2.
function StageMechanics._updateGravityFlipZones(_self: StageMechanicsImpl, data: StageMechanicsData, dt: number)
	local NORMAL_GRAVITY = 196.2
	local FLIPPED_GRAVITY_FORCE = NORMAL_GRAVITY * 2 -- Counteract normal + apply upward

	for _, zone in data.GravityFlipZones do
		if not zone.Part.Parent then
			continue
		end

		zone.Elapsed += dt

		-- Check if it's time to flip
		if zone.Elapsed >= zone.FlipInterval then
			zone.Elapsed = 0
			zone.IsFlipped = not zone.IsFlipped
		end

		-- Track which players are inside the zone
		for _, player in Players:GetPlayers() do
			local isInside = isPlayerInZone(player, zone.Part)
			local wasInside = zone.AffectedPlayers[player] or false
			local character = player.Character

			if isInside and not wasInside then
				-- Player entered the zone
				zone.AffectedPlayers[player] = true
			elseif not isInside and wasInside then
				-- Player left the zone: remove gravity override
				zone.AffectedPlayers[player] = nil
				if character then
					local bodyForce = character:FindFirstChild("GravityFlipForce") :: BodyForce?
					if bodyForce then
						bodyForce:Destroy()
					end
				end
			end

			-- Apply or remove gravity flip for players inside the zone
			if isInside and character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if rootPart then
						local bodyForce = character:FindFirstChild("GravityFlipForce") :: BodyForce?

						if zone.IsFlipped then
							-- Apply upward force to counteract gravity and push upward
							if not bodyForce then
								bodyForce = Instance.new("BodyForce")
								bodyForce.Name = "GravityFlipForce"
								bodyForce.Parent = character
							end
							-- Force = mass * (2 * gravity) to counteract and reverse
							local mass = rootPart.AssemblyMass
							bodyForce.Force = Vector3.new(0, mass * FLIPPED_GRAVITY_FORCE, 0)
						else
							-- Normal gravity: remove the force
							if bodyForce then
								bodyForce:Destroy()
							end
						end
					end
				end
			end
		end
	end
end

-- ================================================================
-- LIGHTNING ZONES
-- ================================================================

--- Periodically strike random positions in lightning zones.
--- Metal parts attract lightning (shift strike position toward nearest metal drawing).
function StageMechanics._updateLightningZones(self: StageMechanicsImpl, data: StageMechanicsData, dt: number)
	for _, zone in data.LightningZones do
		if not zone.Part.Parent then
			continue
		end

		zone.Elapsed += dt
		if zone.Elapsed < zone.StrikeInterval then
			continue
		end

		zone.Elapsed = 0

		-- Pick a random position within the zone
		local zonePos = zone.Part.Position
		local zoneHalf = zone.Part.Size * 0.5
		local strikeX = zonePos.X + (math.random() - 0.5) * zoneHalf.X * 2
		local strikeZ = zonePos.Z + (math.random() - 0.5) * zoneHalf.Z * 2
		local strikeY = zonePos.Y + zoneHalf.Y -- Strike from top of zone
		local strikePos = Vector3.new(strikeX, strikeY, strikeZ)

		-- Check for metal drawings to attract lightning toward them
		local metalAttractRange = 20
		local nearestMetalPos: Vector3? = nil
		local nearestMetalDist = metalAttractRange

		local folder = getDrawingsFolder()
		if folder then
			for _, model in folder:GetChildren() do
				if not model:IsA("Model") then
					continue
				end
				if not isDrawingMetal(model) then
					continue
				end
				local primary = model.PrimaryPart
				if not primary then
					continue
				end
				if not isInsideZone(primary, zone.Part) then
					continue
				end
				local dist = (primary.Position - strikePos).Magnitude
				if dist < nearestMetalDist then
					nearestMetalDist = dist
					nearestMetalPos = primary.Position
				end
			end
		end

		-- Shift strike position toward metal if found (80% attraction)
		if nearestMetalPos then
			strikePos = strikePos:Lerp(nearestMetalPos, 0.8)
		end

		-- Ground the strike: raycast down to find ground level
		local groundY = zonePos.Y - zoneHalf.Y
		local finalStrikePos = Vector3.new(strikePos.X, groundY, strikePos.Z)

		-- Create lightning flash effect: tall yellow neon part
		task.spawn(function()
			local bolt = Instance.new("Part")
			bolt.Name = "LightningBolt"
			bolt.Size = Vector3.new(1, zone.Part.Size.Y, 1)
			bolt.Position = Vector3.new(finalStrikePos.X, zonePos.Y, finalStrikePos.Z)
			bolt.Anchored = true
			bolt.CanCollide = false
			bolt.Material = Enum.Material.Neon
			bolt.Color = Color3.fromRGB(255, 255, 100)
			bolt.Transparency = 0
			bolt.Parent = workspace

			-- Add a PointLight for dramatic effect
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 255, 200)
			light.Brightness = 10
			light.Range = 40
			light.Parent = bolt

			-- Flash: visible for 0.15 seconds, then fade
			task.wait(0.15)
			if bolt.Parent then
				local fadeTween = TweenService:Create(bolt, TweenInfo.new(0.2), {
					Transparency = 1,
				})
				fadeTween:Play()
				fadeTween.Completed:Wait()
				if bolt.Parent then
					bolt:Destroy()
				end
			end
		end)

		-- Check if any player is within 5 studs of the strike
		local killRadius = 5
		for _, player in Players:GetPlayers() do
			local rootPart = getRootPart(player)
			if not rootPart then
				continue
			end

			local dist2D =
				Vector3.new(rootPart.Position.X - finalStrikePos.X, 0, rootPart.Position.Z - finalStrikePos.Z).Magnitude

			if dist2D < killRadius then
				killPlayer(self, player)
			end
		end
	end
end

-- ================================================================
-- FROZEN GATES
-- ================================================================

--- Check if a flammable drawing has been placed near a frozen gate's heat target.
--- If so, melt the gate (tween transparency to 1, then destroy).
function StageMechanics._updateFrozenGates(_self: StageMechanicsImpl, data: StageMechanicsData)
	local HEAT_RADIUS = 8

	for _, frozenGate in data.FrozenGates do
		if frozenGate.IsMelted or not frozenGate.Gate.Parent then
			continue
		end

		-- Check for flammable drawings near the heat target
		local nearbyDrawings = getDrawingModelsNear(frozenGate.HeatTarget.Position, HEAT_RADIUS)
		local hasFlammable = false

		for _, model in nearbyDrawings do
			if isDrawingFlammable(model) then
				hasFlammable = true
				break
			end
		end

		if hasFlammable then
			frozenGate.IsMelted = true

			-- Melt animation: change color to water-blue, increase transparency, then destroy
			task.spawn(function()
				local gate = frozenGate.Gate
				if not gate.Parent then
					return
				end

				-- Phase 1: Turn blue and start melting
				TweenService:Create(gate, TweenInfo.new(1.0, Enum.EasingStyle.Quad), {
					Color = Color3.fromRGB(100, 180, 255),
					Transparency = 0.3,
				}):Play()
				task.wait(1.0)

				if not gate.Parent then
					return
				end

				-- Phase 2: Shrink vertically and fade out
				TweenService:Create(gate, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = Vector3.new(gate.Size.X, 0.2, gate.Size.Z),
					Transparency = 1,
					Position = Vector3.new(gate.Position.X, gate.Position.Y - gate.Size.Y * 0.5, gate.Position.Z),
				}):Play()
				task.wait(1.5)

				-- Disable collision immediately so players can pass
				if gate.Parent then
					gate.CanCollide = false
					gate:Destroy()
				end
			end)
		end
	end
end

-- ================================================================
-- DESTROY
-- ================================================================

--- Clean up all active mechanics and disconnect the heartbeat connection.
function StageMechanics.Destroy(self: StageMechanicsImpl)
	-- Deactivate all active stages
	for stageModel, _ in self.ActiveMechanics do
		self:DeactivateStage(stageModel)
	end

	-- Disconnect heartbeat
	if self._heartbeatConn then
		self._heartbeatConn:Disconnect()
		self._heartbeatConn = nil
	end

	-- Disconnect any extra tracked connections
	for _, conn in self._connections do
		conn:Disconnect()
	end
	self._connections = {}

	print("[StageMechanics] Destroyed")
end

return StageMechanics
