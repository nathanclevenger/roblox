--!strict

--[[
	Proximity Fear System (Client)

	Degrades the player's visual and audio experience based on distance
	to the nearest entity. All transitions are smooth lerps.

	Tier 0 (SAFE):      80+ studs  — Normal gameplay
	Tier 1 (UNEASE):    50-80      — Subtle subconscious cues
	Tier 2 (DREAD):     25-50      — Player notices something is wrong
	Tier 3 (PANIC):     10-25      — Full dread
	Tier 4 (PROXIMITY): 0-10       — Contact imminent
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AudioLayers = require(script.AudioLayers)
local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)
local VisualEffects = require(script.VisualEffects)

local ProximityFear = {}
ProximityFear.__index = ProximityFear

export type ProximityFear = typeof(setmetatable(
	{} :: {
		player: Player,
		visual: VisualEffects.VisualEffects,
		audio: AudioLayers.AudioLayers,
		currentTier: Types.FearTier,
		currentIntensity: number, -- 0 to 1, smooth lerp value
		targetIntensity: number,
		cooldownTimer: number,
		isInCooldown: boolean,
		isFrozen: boolean, -- true during death animation; effects freeze in place
	},
	ProximityFear
))

function ProximityFear.new(player: Player): ProximityFear
	local self = setmetatable({
		player = player,
		visual = VisualEffects.new(player),
		audio = AudioLayers.new(player),
		currentTier = "Safe" :: Types.FearTier,
		currentIntensity = 0,
		targetIntensity = 0,
		cooldownTimer = 0,
		isInCooldown = false,
		isFrozen = false,
	}, ProximityFear)

	return self
end

function ProximityFear.getTierFromDistance(_self: ProximityFear, distance: number): (Types.FearTier, number)
	if distance >= Constants.FEAR_SAFE then
		return "Safe", 0
	elseif distance >= Constants.FEAR_UNEASE then
		-- Lerp 0-0.25 across the Unease range
		local t = 1 - (distance - Constants.FEAR_UNEASE) / (Constants.FEAR_SAFE - Constants.FEAR_UNEASE)
		return "Unease", t * 0.25
	elseif distance >= Constants.FEAR_DREAD then
		local t = 1 - (distance - Constants.FEAR_DREAD) / (Constants.FEAR_UNEASE - Constants.FEAR_DREAD)
		return "Dread", 0.25 + t * 0.25
	elseif distance >= Constants.FEAR_PANIC then
		local t = 1 - (distance - Constants.FEAR_PANIC) / (Constants.FEAR_DREAD - Constants.FEAR_PANIC)
		return "Panic", 0.5 + t * 0.25
	else
		local t = 1 - distance / Constants.FEAR_PANIC
		return "Proximity", 0.75 + t * 0.25
	end
end

--[[
	Freeze all proximity fear effects at their current level.
	Called during the death animation so effects don't change.
]]
function ProximityFear.freeze(self: ProximityFear)
	self.isFrozen = true
	-- Mute audio during death (the death animation handles its own audio)
	self.audio:update(0, 0, "Safe")
end

--[[
	Unfreeze proximity fear effects, allowing them to update again.
]]
function ProximityFear.unfreeze(self: ProximityFear)
	self.isFrozen = false
end

--[[
	Reset to the Safe tier with zero intensity.
	Called after respawn to give the player a clean slate.
]]
function ProximityFear.resetToSafe(self: ProximityFear)
	self.currentTier = "Safe"
	self.currentIntensity = 0
	self.targetIntensity = 0
	self.isInCooldown = false
	self.cooldownTimer = 0
	self.visual:update(0, 0, "Safe")
	self.audio:update(0, 0, "Safe")
end

--[[
	Return the current fear tier as a numeric value (0-4).
]]
function ProximityFear.getTierNumber(self: ProximityFear): number
	if self.currentTier == "Safe" then return 0
	elseif self.currentTier == "Unease" then return 1
	elseif self.currentTier == "Dread" then return 2
	elseif self.currentTier == "Panic" then return 3
	else return 4
	end
end

function ProximityFear.update(self: ProximityFear, dt: number, entityDistance: number?)
	-- Skip updates while frozen (during death animation)
	if self.isFrozen then
		return
	end

	if entityDistance then
		local tier, intensity = self:getTierFromDistance(entityDistance)
		self.currentTier = tier
		self.targetIntensity = intensity
		self.isInCooldown = false
		self.cooldownTimer = 0
	else
		-- No entity nearby or entity is deactivated
		self.targetIntensity = 0
		self.currentTier = "Safe"
	end

	-- Smooth lerp toward target intensity
	local lerpSpeed = if self.targetIntensity > self.currentIntensity
		then 2.0 -- Ramp up at moderate speed
		else 0.5 -- Fade out slowly (post-escape dread lingers)

	-- If entering cooldown (was high, now dropping), use slow cooldown
	if self.currentIntensity > 0.5 and self.targetIntensity < 0.25 then
		self.isInCooldown = true
	end

	if self.isInCooldown then
		lerpSpeed = 1 / Constants.FEAR_COOLDOWN -- Slow fade over cooldown duration
	end

	self.currentIntensity += (self.targetIntensity - self.currentIntensity) * math.min(lerpSpeed * dt, 1)

	-- Apply effects
	self.visual:update(dt, self.currentIntensity, self.currentTier)
	self.audio:update(dt, self.currentIntensity, self.currentTier)
end

return ProximityFear
