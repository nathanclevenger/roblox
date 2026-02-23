--!strict

--[[
	Scare Renderer (Client)

	Receives scare events from the server via the TriggerScare remote and
	renders the appropriate visual/audio effects. Each scare id maps to a
	dedicated rendering function that handles the full visual lifecycle.

	Categories:
	  A — Environmental: world-space objects, sounds, light changes
	  B — Entity Proximity: silhouettes, sounds, environmental hints
	  C — Shock/Direct: full-screen flashes, camera jolts, brief apparitions
	  D — Persistent Anomaly: subtle, lingering changes the player notices over time
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Types = require(ReplicatedStorage.Shared.Types)

local player = Players.LocalPlayer

local ScareRenderer = {}
ScareRenderer.__index = ScareRenderer

export type ScareRenderer = typeof(setmetatable(
	{} :: {
		player: Player,
		scareGui: ScreenGui?,
		activeScares: { [string]: boolean }, -- track active scare renders to prevent overlap
		-- Persistent state for Category D
		secondShadowActive: boolean,
		secondShadowPart: Part?,
		backwardClockActive: boolean,
	},
	ScareRenderer
))

function ScareRenderer.new(localPlayer: Player): ScareRenderer
	local self = setmetatable({
		player = localPlayer,
		scareGui = nil,
		activeScares = {},
		secondShadowActive = false,
		secondShadowPart = nil,
		backwardClockActive = false,
	}, ScareRenderer)

	self:setupGui()

	return self
end

-- ============================================================================
-- GUI Setup
-- ============================================================================

--[[
	Create a dedicated ScreenGui for scare overlays (flashes, faces, figures).
	Sits at high DisplayOrder so it renders above normal UI.
]]
function ScareRenderer.setupGui(self: ScareRenderer)
	local playerGui = self.player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "ScareOverlay"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 300 -- above FearVignette (100) and SubliminalFlash (200)
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	self.scareGui = gui
end

-- ============================================================================
-- Dispatch
-- ============================================================================

--[[
	Main dispatch function. Called when a TriggerScare event is received.
	Routes to the appropriate rendering function based on scareId.
]]
function ScareRenderer.onScareEvent(self: ScareRenderer, event: Types.ScareEvent)
	local scareId = event.scareId

	-- Prevent overlapping renders of the same scare
	if self.activeScares[scareId] then
		return
	end

	-- Dispatch table
	local handlers: { [string]: (ScareRenderer, Types.ScareEvent) -> () } = {
		-- Category A: Environmental
		ceiling_tile_fall = ScareRenderer.renderCeilingTileFall,
		faucet_turns_on = ScareRenderer.renderFaucetTurnsOn,
		radio_static_burst = ScareRenderer.renderRadioStaticBurst,
		wheelchair_roll = ScareRenderer.renderWheelchairRoll,
		window_shutters_slam = ScareRenderer.renderWindowShuttersSlam,
		lights_flicker_sequence = ScareRenderer.renderLightsFlickerSequence,

		-- Category B: Entity Proximity
		shadow_hallway_end = ScareRenderer.renderShadowHallwayEnd,
		breathing_in_locker = ScareRenderer.renderBreathingInLocker,
		handprint_foggy_window = ScareRenderer.renderHandprintFoggyWindow,
		iv_drip_swinging = ScareRenderer.renderIvDripSwinging,
		flashlight_reveals_entity = ScareRenderer.renderFlashlightRevealsEntity,

		-- Category C: Shock/Direct
		mirror_face = ScareRenderer.renderMirrorFace,
		hand_under_bed = ScareRenderer.renderHandUnderBed,
		figure_in_corner = ScareRenderer.renderFigureInCorner,
		door_closes_behind = ScareRenderer.renderDoorClosesBehind,
		tv_security_footage = ScareRenderer.renderTvSecurityFootage,

		-- Category D: Persistent Anomaly
		painting_changed = ScareRenderer.renderPaintingChanged,
		backward_clock = ScareRenderer.renderBackwardClock,
		water_stain_face = ScareRenderer.renderWaterStainFace,
		second_shadow = ScareRenderer.renderSecondShadow,
		footprints_wrong_direction = ScareRenderer.renderFootprintsWrongDirection,
	}

	local handler = handlers[scareId]
	if handler then
		self.activeScares[scareId] = true
		task.spawn(function()
			handler(self, event)
			self.activeScares[scareId] = nil
		end)
	else
		warn(`[ScareRenderer] No handler for scare: {scareId}`)
	end
end

-- ============================================================================
-- Helper Utilities
-- ============================================================================

--[[
	Get the player's current position, or nil if no character.
]]
function ScareRenderer.getPlayerPosition(_self: ScareRenderer): Vector3?
	local character = player.Character
	if not character then
		return nil
	end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return nil
	end
	return hrp.Position
end

--[[
	Get the player's current CFrame, or nil if no character.
]]
function ScareRenderer.getPlayerCFrame(_self: ScareRenderer): CFrame?
	local character = player.Character
	if not character then
		return nil
	end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return nil
	end
	return hrp.CFrame
end

--[[
	Create a temporary Part that auto-destroys after a given duration.
]]
function ScareRenderer.createTempPart(_self: ScareRenderer, props: {
	size: Vector3?,
	position: Vector3?,
	color: Color3?,
	material: Enum.Material?,
	transparency: number?,
	anchored: boolean?,
	canCollide: boolean?,
	shape: Enum.PartType?,
	name: string?,
}, duration: number): Part
	local part = Instance.new("Part")
	part.Name = props.name or "ScarePart"
	part.Size = props.size or Vector3.new(1, 1, 1)
	part.Position = props.position or Vector3.zero
	part.Color = props.color or Color3.fromRGB(40, 40, 40)
	part.Material = props.material or Enum.Material.SmoothPlastic
	part.Transparency = props.transparency or 0
	part.Anchored = if props.anchored ~= nil then props.anchored else true
	part.CanCollide = if props.canCollide ~= nil then props.canCollide else false
	part.Shape = props.shape or Enum.PartType.Block
	part.CastShadow = true
	part.Parent = workspace

	task.delay(duration, function()
		if part and part.Parent then
			part:Destroy()
		end
	end)

	return part
end

--[[
	Play a brief camera shake effect.
]]
function ScareRenderer.shakeCamera(_self: ScareRenderer, intensity: number, duration: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local startTime = os.clock()
	local connection: RBXScriptConnection? = nil

	connection = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - startTime
		if elapsed >= duration then
			if connection then
				connection:Disconnect()
			end
			return
		end

		local decay = 1 - (elapsed / duration)
		local offsetX = (math.random() - 0.5) * intensity * decay
		local offsetY = (math.random() - 0.5) * intensity * decay
		camera.CFrame = camera.CFrame * CFrame.new(offsetX, offsetY, 0)
	end)
end

--[[
	Create a brief full-screen color flash overlay.
]]
function ScareRenderer.flashScreen(self: ScareRenderer, color: Color3, flashDuration: number, transparency: number?)
	if not self.scareGui then
		return
	end

	local frame = Instance.new("Frame")
	frame.Name = "ScreenFlash"
	frame.Size = UDim2.fromScale(1, 1)
	frame.Position = UDim2.fromScale(0, 0)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency or 0
	frame.BorderSizePixel = 0
	frame.ZIndex = 100
	frame.Parent = self.scareGui

	task.delay(flashDuration, function()
		if frame and frame.Parent then
			frame:Destroy()
		end
	end)
end

--[[
	Play a sound at a position in the world. Returns the Sound instance.
]]
function ScareRenderer.playPositionalSound(_self: ScareRenderer, position: Vector3, soundId: string, volume: number?, rollOffMax: number?): Sound
	local soundPart = Instance.new("Part")
	soundPart.Name = "ScareSound"
	soundPart.Transparency = 1
	soundPart.Size = Vector3.new(0.1, 0.1, 0.1)
	soundPart.Position = position
	soundPart.Anchored = true
	soundPart.CanCollide = false
	soundPart.Parent = workspace

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.RollOffMaxDistance = rollOffMax or 60
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.Parent = soundPart

	sound:Play()

	-- Clean up after sound finishes (with a safety timeout)
	task.delay(10, function()
		if soundPart and soundPart.Parent then
			soundPart:Destroy()
		end
	end)

	return sound
end

-- ============================================================================
-- Category A: Environmental Scares
-- ============================================================================

--[[
	A ceiling tile falls from above with dust particles and impact sound.
	Creates a falling rectangular Part that drops from above the player.
]]
function ScareRenderer.renderCeilingTileFall(self: ScareRenderer, event: Types.ScareEvent)
	local playerPos = self:getPlayerPosition()
	if not playerPos then
		return
	end

	-- Offset slightly in front and to the side so the player sees it
	local offset = Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
	local fallStart = playerPos + offset + Vector3.new(0, 12, 0)
	local fallEnd = playerPos + offset + Vector3.new(0, 0.1, 0)

	-- Create the ceiling tile
	local tile = self:createTempPart({
		size = Vector3.new(3, 0.15, 3),
		position = fallStart,
		color = Color3.fromRGB(200, 195, 185),
		material = Enum.Material.Concrete,
		name = "CeilingTile",
	}, 8)

	-- Dust particle emitter
	local dustAttachment = Instance.new("Attachment")
	dustAttachment.Parent = tile

	local dustEmitter = Instance.new("ParticleEmitter")
	dustEmitter.Color = ColorSequence.new(Color3.fromRGB(180, 175, 165))
	dustEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 2),
	})
	dustEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	dustEmitter.Lifetime = NumberRange.new(1, 2)
	dustEmitter.Rate = 40
	dustEmitter.Speed = NumberRange.new(1, 3)
	dustEmitter.SpreadAngle = Vector2.new(45, 45)
	dustEmitter.Parent = dustAttachment

	-- Tween the fall
	local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local fallTween = TweenService:Create(tile, tweenInfo, { Position = fallEnd })
	fallTween:Play()

	-- Impact sound placeholder (using a generic sound approach)
	fallTween.Completed:Connect(function()
		-- Camera shake on impact
		self:shakeCamera(0.3, 0.2)

		-- Stop emitting dust after a moment
		task.delay(1, function()
			dustEmitter.Rate = 0
		end)
	end)
end

--[[
	A faucet turns on by itself in a bathroom. Creates a water particle
	effect near the player's position.
]]
function ScareRenderer.renderFaucetTurnsOn(self: ScareRenderer, event: Types.ScareEvent)
	local pos = event.position
	if not pos then
		pos = self:getPlayerPosition()
	end
	if not pos then
		return
	end

	-- Create a small water stream particle effect offset to the side
	local waterOrigin = pos + Vector3.new(math.random(-5, 5), 2, math.random(-5, 5))

	local emitterPart = self:createTempPart({
		size = Vector3.new(0.2, 0.2, 0.2),
		position = waterOrigin,
		transparency = 1,
		name = "FaucetWater",
	}, 6)

	local attachment = Instance.new("Attachment")
	attachment.Parent = emitterPart

	local waterEmitter = Instance.new("ParticleEmitter")
	waterEmitter.Color = ColorSequence.new(Color3.fromRGB(140, 170, 200))
	waterEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0.3),
	})
	waterEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.8),
	})
	waterEmitter.Lifetime = NumberRange.new(0.5, 1)
	waterEmitter.Rate = 60
	waterEmitter.Speed = NumberRange.new(2, 4)
	waterEmitter.SpreadAngle = Vector2.new(5, 5)
	waterEmitter.Acceleration = Vector3.new(0, -20, 0) -- gravity
	waterEmitter.Parent = attachment

	-- Turn off after 4 seconds
	task.delay(4, function()
		waterEmitter.Rate = 0
	end)
end

--[[
	Radio in security office emits a burst of static. Creates a brief
	flickering light and sound emitter.
]]
function ScareRenderer.renderRadioStaticBurst(self: ScareRenderer, event: Types.ScareEvent)
	local pos = event.position
	if not pos then
		pos = self:getPlayerPosition()
	end
	if not pos then
		return
	end

	local radioPos = pos + Vector3.new(math.random(-6, 6), 1, math.random(-6, 6))

	-- Create a flickering orange-red light to simulate radio glow
	local radioPart = self:createTempPart({
		size = Vector3.new(0.8, 0.5, 0.4),
		position = radioPos,
		color = Color3.fromRGB(60, 60, 60),
		material = Enum.Material.Metal,
		name = "Radio",
	}, 5)

	local radioLight = Instance.new("PointLight")
	radioLight.Color = Color3.fromRGB(255, 100, 50)
	radioLight.Brightness = 0.5
	radioLight.Range = 8
	radioLight.Parent = radioPart

	-- Flicker the light rapidly for 2 seconds
	task.spawn(function()
		local elapsed = 0
		while elapsed < 2 do
			radioLight.Brightness = math.random() * 1.5
			local flickerWait = 0.05 + math.random() * 0.1
			task.wait(flickerWait)
			elapsed += flickerWait
		end
		radioLight.Brightness = 0
	end)
end

--[[
	A wheelchair rolls across the corridor by itself.
	Creates a wheelchair-like Part assembly and tweens it across the space.
]]
function ScareRenderer.renderWheelchairRoll(self: ScareRenderer, event: Types.ScareEvent)
	local playerCF = self:getPlayerCFrame()
	if not playerCF then
		return
	end

	-- Place the wheelchair to the side and slightly ahead of the player
	local rightVector = playerCF.RightVector
	local lookVector = playerCF.LookVector
	local startPos = playerCF.Position + rightVector * 8 + lookVector * 5 + Vector3.new(0, 0.5, 0)
	local endPos = startPos - rightVector * 16 -- roll across 16 studs

	-- Create wheelchair seat
	local seat = self:createTempPart({
		size = Vector3.new(2, 0.3, 2),
		position = startPos,
		color = Color3.fromRGB(50, 50, 55),
		material = Enum.Material.Metal,
		name = "WheelchairSeat",
	}, 10)

	-- Create wheelchair back
	local back = self:createTempPart({
		size = Vector3.new(2, 2.5, 0.2),
		position = startPos + Vector3.new(0, 1.25, -1),
		color = Color3.fromRGB(50, 50, 55),
		material = Enum.Material.Metal,
		name = "WheelchairBack",
	}, 10)

	-- Create wheels (small cylinders)
	local wheel1 = self:createTempPart({
		size = Vector3.new(0.3, 1.5, 1.5),
		position = startPos + Vector3.new(-1, -0.5, 0),
		color = Color3.fromRGB(30, 30, 30),
		material = Enum.Material.SmoothPlastic,
		shape = Enum.PartType.Cylinder,
		name = "WheelchairWheel",
	}, 10)

	local wheel2 = self:createTempPart({
		size = Vector3.new(0.3, 1.5, 1.5),
		position = startPos + Vector3.new(1, -0.5, 0),
		color = Color3.fromRGB(30, 30, 30),
		material = Enum.Material.SmoothPlastic,
		shape = Enum.PartType.Cylinder,
		name = "WheelchairWheel",
	}, 10)

	-- Tween all parts across the corridor
	local displacement = endPos - startPos
	local tweenInfo = TweenInfo.new(3.5, Enum.EasingStyle.Linear)

	local parts = { seat, back, wheel1, wheel2 }
	for _, part in parts do
		local targetPos = part.Position + displacement
		local tween = TweenService:Create(part, tweenInfo, { Position = targetPos })
		tween:Play()
	end

	-- Subtle metallic squeak sound would play here
	-- (sound asset not available, but the visual conveys the effect)
end

--[[
	Window shutters slam shut. Creates a brief camera shake and
	a dark frame flash.
]]
function ScareRenderer.renderWindowShuttersSlam(self: ScareRenderer, _event: Types.ScareEvent)
	-- Brief camera jolt
	self:shakeCamera(0.5, 0.15)

	-- Quick dark flash (simulating the sudden darkness)
	self:flashScreen(Color3.fromRGB(10, 10, 10), 0.08, 0.3)
end

--[[
	Lights in a room flicker in sequence then die.
	Finds nearby PointLights and flickers them one by one.
]]
function ScareRenderer.renderLightsFlickerSequence(self: ScareRenderer, event: Types.ScareEvent)
	local playerPos = self:getPlayerPosition()
	if not playerPos then
		return
	end

	-- Find all PointLights within 40 studs
	local nearbyLights: { PointLight } = {}

	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("PointLight") then
			local parent = descendant.Parent
			if parent and parent:IsA("BasePart") then
				local dist = (parent.Position - playerPos).Magnitude
				if dist <= 40 then
					table.insert(nearbyLights, descendant)
				end
			end
		end
	end

	if #nearbyLights == 0 then
		-- No lights found; create temporary lights to flicker
		for i = 1, 4 do
			local offset = Vector3.new(math.random(-10, 10), 8, math.random(-10, 10))
			local lightPart = self:createTempPart({
				size = Vector3.new(0.5, 0.2, 0.5),
				position = playerPos + offset,
				color = Color3.fromRGB(255, 245, 220),
				material = Enum.Material.Neon,
				transparency = 0,
				name = "TempLight",
			}, 8)

			local light = Instance.new("PointLight")
			light.Brightness = 1
			light.Range = 15
			light.Color = Color3.fromRGB(255, 245, 220)
			light.Parent = lightPart

			table.insert(nearbyLights, light)
		end
	end

	-- Flicker each light in sequence, then all die
	task.spawn(function()
		-- Store original brightness values
		local origBrightness: { [PointLight]: number } = {}
		for _, light in nearbyLights do
			origBrightness[light] = light.Brightness
		end

		-- Flicker each light one by one
		for _, light in nearbyLights do
			if not light.Parent then
				continue
			end

			-- Rapid flicker for this light
			for _ = 1, 4 do
				light.Brightness = 0
				task.wait(0.05 + math.random() * 0.05)
				light.Brightness = origBrightness[light] or 1
				task.wait(0.03 + math.random() * 0.05)
			end

			-- This light dies
			light.Brightness = 0
			task.wait(0.2)
		end

		-- Brief total darkness moment
		task.wait(1.5)

		-- Restore lights (they were only temporarily killed)
		for light, brightness in origBrightness do
			if light.Parent then
				light.Brightness = brightness
			end
		end
	end)
end

-- ============================================================================
-- Category B: Entity Proximity Scares
-- ============================================================================

--[[
	A dark humanoid silhouette appears at the end of a hallway.
	Fades away when the player looks directly at it.
]]
function ScareRenderer.renderShadowHallwayEnd(self: ScareRenderer, event: Types.ScareEvent)
	local playerCF = self:getPlayerCFrame()
	if not playerCF then
		return
	end

	-- Place the shadow figure far in front of the player
	local lookDir = playerCF.LookVector
	local shadowPos = playerCF.Position + lookDir * 35 + Vector3.new(0, 3, 0)

	-- Create dark silhouette (torso)
	local silhouette = self:createTempPart({
		size = Vector3.new(2, 5, 1),
		position = shadowPos,
		color = Color3.fromRGB(5, 5, 8),
		material = Enum.Material.SmoothPlastic,
		transparency = 0.3,
		name = "ShadowFigure",
	}, 10)

	-- Head
	local shadowHead = self:createTempPart({
		size = Vector3.new(1.2, 1.2, 1.2),
		position = shadowPos + Vector3.new(0, 3, 0),
		color = Color3.fromRGB(5, 5, 8),
		material = Enum.Material.SmoothPlastic,
		transparency = 0.3,
		shape = Enum.PartType.Ball,
		name = "ShadowHead",
	}, 10)

	-- Monitor player look direction; fade when looked at
	task.spawn(function()
		local elapsed = 0
		while elapsed < 8 and silhouette.Parent and shadowHead.Parent do
			local camera = workspace.CurrentCamera
			if camera then
				local toShadow = (silhouette.Position - camera.CFrame.Position).Unit
				local camLook = camera.CFrame.LookVector
				local dot = toShadow:Dot(camLook)

				-- If player is looking within ~15 degrees of the shadow, fade it
				if dot > 0.96 then
					-- Rapid fade
					local fadeInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
					TweenService:Create(silhouette, fadeInfo, { Transparency = 1 }):Play()
					TweenService:Create(shadowHead, fadeInfo, { Transparency = 1 }):Play()

					task.delay(0.4, function()
						if silhouette.Parent then
							silhouette:Destroy()
						end
						if shadowHead.Parent then
							shadowHead:Destroy()
						end
					end)
					return
				end
			end

			task.wait(0.05)
			elapsed += 0.05
		end

		-- If never looked at directly, fade after timeout
		if silhouette.Parent then
			silhouette.Transparency = 1
			silhouette:Destroy()
		end
		if shadowHead.Parent then
			shadowHead.Transparency = 1
			shadowHead:Destroy()
		end
	end)
end

--[[
	Breathing sound from inside a locker the player passes.
	Creates a positional sound emitter.
]]
function ScareRenderer.renderBreathingInLocker(self: ScareRenderer, event: Types.ScareEvent)
	local playerPos = self:getPlayerPosition()
	if not playerPos then
		return
	end

	-- Place the breathing sound to the side of the player
	local breathPos = playerPos + Vector3.new(math.random(-4, 4), 1, math.random(-4, 4))

	-- Visual cue: a slight fog/mist from locker vents
	local mistPart = self:createTempPart({
		size = Vector3.new(0.1, 0.1, 0.1),
		position = breathPos,
		transparency = 1,
		name = "BreathingMist",
	}, 8)

	local attachment = Instance.new("Attachment")
	attachment.Parent = mistPart

	local mistEmitter = Instance.new("ParticleEmitter")
	mistEmitter.Color = ColorSequence.new(Color3.fromRGB(200, 200, 210))
	mistEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1.5),
	})
	mistEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	mistEmitter.Lifetime = NumberRange.new(1, 2)
	mistEmitter.Rate = 8
	mistEmitter.Speed = NumberRange.new(0.5, 1)
	mistEmitter.SpreadAngle = Vector2.new(20, 20)
	mistEmitter.Parent = attachment

	-- Rhythmic pulsing to simulate breathing (3 second cycle)
	task.spawn(function()
		for _ = 1, 3 do
			mistEmitter.Rate = 15
			task.wait(1)
			mistEmitter.Rate = 3
			task.wait(1.5)
		end
		mistEmitter.Rate = 0
	end)
end

--[[
	A handprint appears on a foggy window near the player.
]]
function ScareRenderer.renderHandprintFoggyWindow(self: ScareRenderer, event: Types.ScareEvent)
	local playerPos = self:getPlayerPosition()
	if not playerPos then
		return
	end

	-- Create a foggy glass-like surface with a handprint decal
	local windowPos = playerPos + Vector3.new(math.random(-5, 5), 3, math.random(-5, 5))

	local windowPart = self:createTempPart({
		size = Vector3.new(4, 4, 0.1),
		position = windowPos,
		color = Color3.fromRGB(180, 200, 210),
		material = Enum.Material.Glass,
		transparency = 0.5,
		name = "FoggyWindow",
	}, 10)

	-- Create a handprint using a dark decal overlay (SurfaceGui)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = windowPart

	local handFrame = Instance.new("Frame")
	handFrame.Size = UDim2.fromScale(0.5, 0.7)
	handFrame.Position = UDim2.fromScale(0.25, 0.15)
	handFrame.BackgroundColor3 = Color3.fromRGB(80, 60, 50)
	handFrame.BackgroundTransparency = 0.3
	handFrame.BorderSizePixel = 0
	handFrame.Parent = surfaceGui

	-- Add a UICorner for a more organic shape
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = handFrame

	-- Fade in the handprint
	handFrame.BackgroundTransparency = 1
	local fadeIn = TweenService:Create(handFrame, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {
		BackgroundTransparency = 0.3,
	})
	fadeIn:Play()

	-- Fade out after a few seconds
	task.delay(5, function()
		if handFrame.Parent then
			local fadeOut = TweenService:Create(handFrame, TweenInfo.new(2, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 1,
			})
			fadeOut:Play()
		end
	end)
end

--[[
	An IV drip starts swinging on its own near the player.
]]
function ScareRenderer.renderIvDripSwinging(self: ScareRenderer, event: Types.ScareEvent)
	local playerPos = self:getPlayerPosition()
	if not playerPos then
		return
	end

	local ivPos = playerPos + Vector3.new(math.random(-5, 5), 3, math.random(-5, 5))

	-- IV pole
	local pole = self:createTempPart({
		size = Vector3.new(0.15, 5, 0.15),
		position = ivPos,
		color = Color3.fromRGB(180, 180, 185),
		material = Enum.Material.Metal,
		name = "IVPole",
	}, 10)

	-- IV bag (swinging part)
	local bag = self:createTempPart({
		size = Vector3.new(0.4, 0.6, 0.15),
		position = ivPos + Vector3.new(0, 1.5, 0),
		color = Color3.fromRGB(200, 210, 220),
		material = Enum.Material.SmoothPlastic,
		transparency = 0.3,
		name = "IVBag",
	}, 10)

	-- Animate swinging using position oscillation
	task.spawn(function()
		local startPos = bag.Position
		local elapsed = 0

		while elapsed < 6 and bag.Parent do
			elapsed += 0.03
			local swing = math.sin(elapsed * 4) * 0.5 * math.max(0, 1 - elapsed / 6)
			bag.Position = startPos + Vector3.new(swing, 0, swing * 0.3)
			task.wait(0.03)
		end
	end)
end

--[[
	The player's flashlight beam briefly illuminates an entity standing
	in a doorway. Shows a dark silhouette frame on screen.
]]
function ScareRenderer.renderFlashlightRevealsEntity(self: ScareRenderer, event: Types.ScareEvent)
	local playerCF = self:getPlayerCFrame()
	if not playerCF then
		return
	end

	-- Create a silhouette figure ahead of the player
	local figurePos = playerCF.Position + playerCF.LookVector * 15 + Vector3.new(0, 3, 0)

	local figure = self:createTempPart({
		size = Vector3.new(2, 5.5, 1),
		position = figurePos,
		color = Color3.fromRGB(10, 10, 12),
		material = Enum.Material.SmoothPlastic,
		transparency = 0.1,
		name = "EntitySilhouette",
	}, 2)

	local figHead = self:createTempPart({
		size = Vector3.new(1.3, 1.3, 1.3),
		position = figurePos + Vector3.new(0, 3.2, 0),
		color = Color3.fromRGB(10, 10, 12),
		material = Enum.Material.SmoothPlastic,
		transparency = 0.1,
		shape = Enum.PartType.Ball,
		name = "EntitySilhouetteHead",
	}, 2)

	-- Brief flash to "reveal" the figure
	self:flashScreen(Color3.fromRGB(255, 255, 255), 0.05, 0.85)

	-- After 0.5s, vanish the figure rapidly
	task.delay(0.5, function()
		if figure.Parent then
			local fadeInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
			TweenService:Create(figure, fadeInfo, { Transparency = 1 }):Play()
			TweenService:Create(figHead, fadeInfo, { Transparency = 1 }):Play()
		end
	end)
end

-- ============================================================================
-- Category C: Shock/Direct Scares (Per-Player Only)
-- ============================================================================

--[[
	A face appears in a bathroom mirror for exactly 1 frame (~0.033s).
	Full-screen ImageLabel flash with audio sting.
]]
function ScareRenderer.renderMirrorFace(self: ScareRenderer, _event: Types.ScareEvent)
	if not self.scareGui then
		return
	end

	-- Create a full-screen dark frame with a "face" rendered as text
	-- (In production this would be an ImageLabel with a face texture asset)
	local faceFrame = Instance.new("Frame")
	faceFrame.Name = "MirrorFace"
	faceFrame.Size = UDim2.fromScale(1, 1)
	faceFrame.Position = UDim2.fromScale(0, 0)
	faceFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	faceFrame.BackgroundTransparency = 0.1
	faceFrame.BorderSizePixel = 0
	faceFrame.ZIndex = 200
	faceFrame.Parent = self.scareGui

	-- Eyes (two white circles)
	local leftEye = Instance.new("Frame")
	leftEye.Size = UDim2.fromScale(0.06, 0.06)
	leftEye.Position = UDim2.fromScale(0.38, 0.35)
	leftEye.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	leftEye.BorderSizePixel = 0
	leftEye.Parent = faceFrame
	local leftCorner = Instance.new("UICorner")
	leftCorner.CornerRadius = UDim.new(1, 0)
	leftCorner.Parent = leftEye

	local rightEye = Instance.new("Frame")
	rightEye.Size = UDim2.fromScale(0.06, 0.06)
	rightEye.Position = UDim2.fromScale(0.56, 0.35)
	rightEye.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	rightEye.BorderSizePixel = 0
	rightEye.Parent = faceFrame
	local rightCorner = Instance.new("UICorner")
	rightCorner.CornerRadius = UDim.new(1, 0)
	rightCorner.Parent = rightEye

	-- Pupils (small dark circles within eyes)
	local leftPupil = Instance.new("Frame")
	leftPupil.Size = UDim2.fromScale(0.4, 0.4)
	leftPupil.Position = UDim2.fromScale(0.3, 0.3)
	leftPupil.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	leftPupil.BorderSizePixel = 0
	leftPupil.Parent = leftEye
	Instance.new("UICorner", leftPupil).CornerRadius = UDim.new(1, 0)

	local rightPupil = Instance.new("Frame")
	rightPupil.Size = UDim2.fromScale(0.4, 0.4)
	rightPupil.Position = UDim2.fromScale(0.3, 0.3)
	rightPupil.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	rightPupil.BorderSizePixel = 0
	rightPupil.Parent = rightEye
	Instance.new("UICorner", rightPupil).CornerRadius = UDim.new(1, 0)

	-- Mouth (dark oval)
	local mouth = Instance.new("Frame")
	mouth.Size = UDim2.fromScale(0.12, 0.06)
	mouth.Position = UDim2.fromScale(0.44, 0.55)
	mouth.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
	mouth.BorderSizePixel = 0
	mouth.Parent = faceFrame
	Instance.new("UICorner", mouth).CornerRadius = UDim.new(0.5, 0)

	-- Camera jolt
	self:shakeCamera(0.8, 0.1)

	-- Remove after exactly 1 frame (~0.033s)
	task.delay(0.033, function()
		if faceFrame.Parent then
			faceFrame:Destroy()
		end
	end)
end

--[[
	A hand reaches from under a bed as the player walks past.
	Animated Part that extends outward then retracts.
]]
function ScareRenderer.renderHandUnderBed(self: ScareRenderer, event: Types.ScareEvent)
	local playerCF = self:getPlayerCFrame()
	if not playerCF then
		return
	end

	-- Place the hand to the right side and below the player
	local rightDir = playerCF.RightVector
	local handStart = playerCF.Position + rightDir * 3 + Vector3.new(0, -0.8, 0)
	local handExtend = handStart + rightDir * -2 -- reach toward player

	-- Arm part
	local arm = self:createTempPart({
		size = Vector3.new(0.4, 0.25, 1.2),
		position = handStart,
		color = Color3.fromRGB(140, 110, 90),
		material = Enum.Material.SmoothPlastic,
		name = "ScareHand",
	}, 5)

	-- Hand/fingers
	local hand = self:createTempPart({
		size = Vector3.new(0.5, 0.15, 0.5),
		position = handStart + rightDir * -0.6,
		color = Color3.fromRGB(130, 100, 80),
		material = Enum.Material.SmoothPlastic,
		name = "ScareFingers",
	}, 5)

	-- Extend toward player
	local extendInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local armExtend = TweenService:Create(arm, extendInfo, { Position = handExtend })
	local handFollow = TweenService:Create(hand, extendInfo, {
		Position = handExtend + rightDir * -0.6,
	})

	armExtend:Play()
	handFollow:Play()

	-- Camera jolt
	task.delay(0.3, function()
		self:shakeCamera(0.4, 0.3)
	end)

	-- Retract after a beat
	task.delay(1.0, function()
		local retractInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		if arm.Parent then
			TweenService:Create(arm, retractInfo, { Position = handStart }):Play()
		end
		if hand.Parent then
			TweenService:Create(hand, retractInfo, { Position = handStart + rightDir * -0.6 }):Play()
		end
	end)
end

--[[
	A dark figure appears on screen for 2 frames when the flashlight turns on,
	standing in a corner. Pure UI overlay for maximum impact.
]]
function ScareRenderer.renderFigureInCorner(self: ScareRenderer, _event: Types.ScareEvent)
	if not self.scareGui then
		return
	end

	-- Create a dark figure silhouette in the corner of the screen
	local figureFrame = Instance.new("Frame")
	figureFrame.Name = "FigureInCorner"
	figureFrame.Size = UDim2.fromScale(0.15, 0.55)
	figureFrame.Position = UDim2.fromScale(0.82, 0.25)
	figureFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
	figureFrame.BackgroundTransparency = 0.1
	figureFrame.BorderSizePixel = 0
	figureFrame.ZIndex = 150
	figureFrame.Parent = self.scareGui

	-- Head
	local headFrame = Instance.new("Frame")
	headFrame.Size = UDim2.fromScale(0.55, 0.15)
	headFrame.Position = UDim2.fromScale(0.22, -0.15)
	headFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 8)
	headFrame.BackgroundTransparency = 0.1
	headFrame.BorderSizePixel = 0
	headFrame.Parent = figureFrame
	Instance.new("UICorner", headFrame).CornerRadius = UDim.new(1, 0)

	-- Remove after 2 frames (~0.066s)
	task.delay(0.066, function()
		if figureFrame.Parent then
			figureFrame:Destroy()
		end
	end)

	-- Subtle camera jolt
	self:shakeCamera(0.3, 0.05)
end

--[[
	The door the player just walked through slowly closes behind them.
	Creates a door-like Part that swings shut.
]]
function ScareRenderer.renderDoorClosesBehind(self: ScareRenderer, event: Types.ScareEvent)
	local playerCF = self:getPlayerCFrame()
	if not playerCF then
		return
	end

	-- Place a door behind the player
	local behindPos = playerCF.Position - playerCF.LookVector * 5

	local door = self:createTempPart({
		size = Vector3.new(4, 8, 0.3),
		position = behindPos + Vector3.new(0, 4, 0),
		color = Color3.fromRGB(100, 70, 45),
		material = Enum.Material.Wood,
		name = "ClosingDoor",
	}, 8)

	-- The door starts open (rotated 90 degrees) and closes
	local openCF = door.CFrame * CFrame.Angles(0, math.rad(90), 0)
	local closedCF = door.CFrame

	door.CFrame = openCF

	-- Slow, creepy close
	local closeInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local closeTween = TweenService:Create(door, closeInfo, { CFrame = closedCF })
	closeTween:Play()

	-- Thud when it closes
	closeTween.Completed:Connect(function()
		self:shakeCamera(0.15, 0.1)
	end)
end

--[[
	A TV shows security footage of the player from behind.
	Creates a brief UI overlay simulating CCTV static with a dark
	player silhouette.
]]
function ScareRenderer.renderTvSecurityFootage(self: ScareRenderer, _event: Types.ScareEvent)
	if not self.scareGui then
		return
	end

	-- CCTV frame
	local cctvFrame = Instance.new("Frame")
	cctvFrame.Name = "CCTVFootage"
	cctvFrame.Size = UDim2.fromScale(0.35, 0.3)
	cctvFrame.Position = UDim2.fromScale(0.325, 0.35)
	cctvFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 15)
	cctvFrame.BackgroundTransparency = 0
	cctvFrame.BorderSizePixel = 2
	cctvFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
	cctvFrame.ZIndex = 180
	cctvFrame.Parent = self.scareGui

	-- Static noise overlay
	local staticFrame = Instance.new("Frame")
	staticFrame.Size = UDim2.fromScale(1, 1)
	staticFrame.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	staticFrame.BackgroundTransparency = 0.85
	staticFrame.BorderSizePixel = 0
	staticFrame.Parent = cctvFrame

	-- Silhouette of a person (back view) in the center
	local silhouette = Instance.new("Frame")
	silhouette.Size = UDim2.fromScale(0.2, 0.6)
	silhouette.Position = UDim2.fromScale(0.4, 0.3)
	silhouette.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
	silhouette.BackgroundTransparency = 0.1
	silhouette.BorderSizePixel = 0
	silhouette.Parent = cctvFrame

	-- CCTV timestamp text
	local timestamp = Instance.new("TextLabel")
	timestamp.Size = UDim2.fromScale(0.5, 0.1)
	timestamp.Position = UDim2.fromScale(0.48, 0.88)
	timestamp.BackgroundTransparency = 1
	timestamp.TextColor3 = Color3.fromRGB(200, 200, 200)
	timestamp.TextScaled = true
	timestamp.Font = Enum.Font.Code
	timestamp.Text = "CAM-04  03:31:00"
	timestamp.TextXAlignment = Enum.TextXAlignment.Right
	timestamp.BorderSizePixel = 0
	timestamp.Parent = cctvFrame

	-- Flicker the static
	task.spawn(function()
		local elapsed = 0
		while elapsed < 2.5 and staticFrame.Parent do
			staticFrame.BackgroundTransparency = 0.7 + math.random() * 0.25
			task.wait(0.08)
			elapsed += 0.08
		end
	end)

	-- Remove after 2.5 seconds with a static burst
	task.delay(2.5, function()
		if cctvFrame.Parent then
			cctvFrame:Destroy()
		end
	end)
end

-- ============================================================================
-- Category D: Persistent Anomaly Scares
-- ============================================================================

--[[
	A painting on the wall has changed when the player returns.
	Creates a wall-mounted frame with altered imagery.
]]
function ScareRenderer.renderPaintingChanged(self: ScareRenderer, event: Types.ScareEvent)
	local playerPos = self:getPlayerPosition()
	if not playerPos then
		return
	end

	-- Place a painting on a nearby "wall" surface
	local paintingPos = playerPos + Vector3.new(math.random(-6, 6), 4, math.random(-6, 6))

	-- Painting frame
	local frame = self:createTempPart({
		size = Vector3.new(3, 2.5, 0.1),
		position = paintingPos,
		color = Color3.fromRGB(80, 50, 30),
		material = Enum.Material.Wood,
		name = "ChangedPainting",
	}, 60) -- persists for a full minute (anomaly lingers)

	-- Canvas with a "wrong" color (was originally warm, now cold/unsettling)
	local canvas = self:createTempPart({
		size = Vector3.new(2.6, 2.1, 0.05),
		position = paintingPos + Vector3.new(0, 0, 0.08),
		color = Color3.fromRGB(40, 20, 30),
		material = Enum.Material.SmoothPlastic,
		name = "ChangedCanvas",
	}, 60)

	-- Add a SurfaceGui with disturbing text
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.Parent = canvas

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(120, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.Antique
	label.Text = "3:31"
	label.Parent = surfaceGui
end

--[[
	A clock on the wall runs backward. Creates a clock part with
	rotating hands that move counter-clockwise.
]]
function ScareRenderer.renderBackwardClock(self: ScareRenderer, event: Types.ScareEvent)
	local playerPos = self:getPlayerPosition()
	if not playerPos then
		return
	end

	local clockPos = playerPos + Vector3.new(math.random(-5, 5), 5, math.random(-5, 5))

	-- Clock face
	local clockFace = self:createTempPart({
		size = Vector3.new(2, 2, 0.1),
		position = clockPos,
		color = Color3.fromRGB(240, 235, 220),
		material = Enum.Material.SmoothPlastic,
		shape = Enum.PartType.Cylinder,
		name = "BackwardClock",
	}, 120) -- 2 minute anomaly

	-- Clock border ring
	local clockBorder = self:createTempPart({
		size = Vector3.new(0.15, 2.2, 2.2),
		position = clockPos,
		color = Color3.fromRGB(60, 40, 25),
		material = Enum.Material.Wood,
		shape = Enum.PartType.Cylinder,
		name = "ClockBorder",
	}, 120)

	-- Minute hand
	local minuteHand = self:createTempPart({
		size = Vector3.new(0.08, 0.8, 0.02),
		position = clockPos + Vector3.new(0, 0.3, -0.08),
		color = Color3.fromRGB(20, 20, 20),
		material = Enum.Material.Metal,
		name = "MinuteHand",
	}, 120)

	-- Hour hand (shorter)
	local hourHand = self:createTempPart({
		size = Vector3.new(0.08, 0.5, 0.02),
		position = clockPos + Vector3.new(0, 0.15, -0.1),
		color = Color3.fromRGB(20, 20, 20),
		material = Enum.Material.Metal,
		name = "HourHand",
	}, 120)

	-- Animate hands running backward
	task.spawn(function()
		local elapsed = 0
		local minuteAngle = 0
		local hourAngle = 0

		while elapsed < 115 and minuteHand.Parent and hourHand.Parent do
			elapsed += 0.1

			-- Run backwards: negative rotation speed
			-- Minute hand: full revolution every 10 seconds (accelerated for horror)
			minuteAngle -= 0.1 * (360 / 10)
			-- Hour hand: full revolution every 120 seconds
			hourAngle -= 0.1 * (360 / 120)

			local minuteRad = math.rad(minuteAngle)
			local hourRad = math.rad(hourAngle)

			if minuteHand.Parent then
				minuteHand.CFrame = CFrame.new(clockPos + Vector3.new(0, 0, -0.08))
					* CFrame.Angles(0, 0, minuteRad)
					* CFrame.new(0, 0.4, 0)
			end

			if hourHand.Parent then
				hourHand.CFrame = CFrame.new(clockPos + Vector3.new(0, 0, -0.1))
					* CFrame.Angles(0, 0, hourRad)
					* CFrame.new(0, 0.25, 0)
			end

			task.wait(0.1)
		end
	end)
end

--[[
	A water stain on the ceiling that looks like a face.
	Creates a decal on a ceiling part above the player.
]]
function ScareRenderer.renderWaterStainFace(self: ScareRenderer, event: Types.ScareEvent)
	local playerPos = self:getPlayerPosition()
	if not playerPos then
		return
	end

	local stainPos = playerPos + Vector3.new(math.random(-3, 3), 10, math.random(-3, 3))

	-- Ceiling patch with stain
	local ceilingPatch = self:createTempPart({
		size = Vector3.new(3, 0.1, 3),
		position = stainPos,
		color = Color3.fromRGB(160, 145, 120),
		material = Enum.Material.Concrete,
		name = "WaterStainCeiling",
	}, 90) -- persistent anomaly

	-- Create face-like pattern using SurfaceGui on bottom face
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Bottom
	surfaceGui.Parent = ceilingPatch

	-- Water stain base (irregular circle)
	local stainBase = Instance.new("Frame")
	stainBase.Size = UDim2.fromScale(0.7, 0.7)
	stainBase.Position = UDim2.fromScale(0.15, 0.15)
	stainBase.BackgroundColor3 = Color3.fromRGB(100, 90, 70)
	stainBase.BackgroundTransparency = 0.4
	stainBase.BorderSizePixel = 0
	stainBase.Parent = surfaceGui
	Instance.new("UICorner", stainBase).CornerRadius = UDim.new(0.5, 0)

	-- "Eye" stains
	local eyeL = Instance.new("Frame")
	eyeL.Size = UDim2.fromScale(0.15, 0.12)
	eyeL.Position = UDim2.fromScale(0.2, 0.25)
	eyeL.BackgroundColor3 = Color3.fromRGB(60, 50, 35)
	eyeL.BackgroundTransparency = 0.2
	eyeL.BorderSizePixel = 0
	eyeL.Parent = stainBase
	Instance.new("UICorner", eyeL).CornerRadius = UDim.new(1, 0)

	local eyeR = Instance.new("Frame")
	eyeR.Size = UDim2.fromScale(0.15, 0.12)
	eyeR.Position = UDim2.fromScale(0.65, 0.25)
	eyeR.BackgroundColor3 = Color3.fromRGB(60, 50, 35)
	eyeR.BackgroundTransparency = 0.2
	eyeR.BorderSizePixel = 0
	eyeR.Parent = stainBase
	Instance.new("UICorner", eyeR).CornerRadius = UDim.new(1, 0)

	-- "Mouth" stain
	local mouthStain = Instance.new("Frame")
	mouthStain.Size = UDim2.fromScale(0.25, 0.1)
	mouthStain.Position = UDim2.fromScale(0.375, 0.65)
	mouthStain.BackgroundColor3 = Color3.fromRGB(50, 40, 30)
	mouthStain.BackgroundTransparency = 0.3
	mouthStain.BorderSizePixel = 0
	mouthStain.Parent = stainBase
	Instance.new("UICorner", mouthStain).CornerRadius = UDim.new(0.5, 0)
end

--[[
	The player's flashlight beam creates a second shadow -- theirs, and
	something behind them. Creates a delayed shadow Part that follows
	the player with a slight offset.
]]
function ScareRenderer.renderSecondShadow(self: ScareRenderer, event: Types.ScareEvent)
	if self.secondShadowActive then
		return
	end

	self.secondShadowActive = true

	-- Create the shadow part
	local shadow = Instance.new("Part")
	shadow.Name = "SecondShadow"
	shadow.Size = Vector3.new(2, 0.05, 3)
	shadow.Color = Color3.fromRGB(5, 5, 5)
	shadow.Material = Enum.Material.SmoothPlastic
	shadow.Transparency = 0.4
	shadow.Anchored = true
	shadow.CanCollide = false
	shadow.CastShadow = false
	shadow.Parent = workspace
	self.secondShadowPart = shadow

	-- Follow the player with a delay (like a shadow that's 0.3s behind)
	local positionBuffer: { { position: Vector3, cframe: CFrame } } = {}
	local bufferDelay = 10 -- frames of delay (~0.33s at 30fps)

	task.spawn(function()
		local elapsed = 0
		local duration = 45 -- lasts 45 seconds (persistent anomaly)

		while elapsed < duration and shadow.Parent do
			local playerCF = self:getPlayerCFrame()
			if playerCF then
				-- Record current position
				table.insert(positionBuffer, {
					position = playerCF.Position,
					cframe = playerCF,
				})

				-- Use delayed position
				if #positionBuffer > bufferDelay then
					local delayed = positionBuffer[1]
					table.remove(positionBuffer, 1)

					-- Place shadow on the ground behind the delayed position
					local behindPos = delayed.position - delayed.cframe.LookVector * 2
					shadow.Position = Vector3.new(behindPos.X, delayed.position.Y - 2.5, behindPos.Z)
					shadow.CFrame = CFrame.new(shadow.Position)
						* CFrame.Angles(0, math.atan2(delayed.cframe.LookVector.X, delayed.cframe.LookVector.Z), 0)
				end
			end

			task.wait(0.033)
			elapsed += 0.033
		end

		-- Fade out
		if shadow.Parent then
			local fadeInfo = TweenInfo.new(2, Enum.EasingStyle.Quad)
			TweenService:Create(shadow, fadeInfo, { Transparency = 1 }):Play()

			task.delay(2.1, function()
				if shadow.Parent then
					shadow:Destroy()
				end
			end)
		end

		self.secondShadowActive = false
		self.secondShadowPart = nil
	end)
end

--[[
	Footprints appear in dust that match the player's but go the wrong
	direction. Places decal-like Parts on the ground facing opposite
	to the player's movement.
]]
function ScareRenderer.renderFootprintsWrongDirection(self: ScareRenderer, event: Types.ScareEvent)
	local playerCF = self:getPlayerCFrame()
	if not playerCF then
		return
	end

	-- Place footprints behind the player, but oriented facing backward
	-- (as if someone walked toward the player from ahead)
	local lookDir = playerCF.LookVector
	local rightDir = playerCF.RightVector

	-- Create 6 footprints in a trail ahead of the player, facing backward
	task.spawn(function()
		for i = 1, 6 do
			local stepOffset = lookDir * (i * 2.5) -- ahead of player
			local lateralOffset = rightDir * (if i % 2 == 0 then 0.4 else -0.4) -- alternating feet
			local footPos = playerCF.Position + stepOffset + lateralOffset + Vector3.new(0, -2.4, 0)

			-- Footprint part (flat on the ground, facing BACKWARD)
			local footprint = self:createTempPart({
				size = Vector3.new(0.4, 0.02, 0.9),
				position = footPos,
				color = Color3.fromRGB(80, 70, 60),
				material = Enum.Material.SmoothPlastic,
				transparency = 0.3,
				name = "WrongFootprint",
			}, 60) -- persistent for 60 seconds

			-- Rotate footprint to face backward (opposite of player's direction)
			local backwardAngle = math.atan2(-lookDir.X, -lookDir.Z)
			footprint.CFrame = CFrame.new(footPos) * CFrame.Angles(0, backwardAngle, 0)

			-- Stagger appearance for creepy effect
			task.wait(0.4)
		end
	end)
end

-- ============================================================================
-- Cleanup
-- ============================================================================

function ScareRenderer.cleanup(self: ScareRenderer)
	if self.scareGui then
		self.scareGui:Destroy()
		self.scareGui = nil
	end

	if self.secondShadowPart and self.secondShadowPart.Parent then
		self.secondShadowPart:Destroy()
	end
	self.secondShadowActive = false
	self.secondShadowPart = nil
	self.activeScares = {}
end

return ScareRenderer
