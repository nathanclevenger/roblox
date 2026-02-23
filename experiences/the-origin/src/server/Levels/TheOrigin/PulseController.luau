--!strict

--[[
	TheOrigin/PulseController - Drives oscillating brightness on all
	pulsing lights in the level.

	Scans the level model for Parts with PulseMin/PulseMax/PulseSpeed
	attributes and updates their child PointLight brightness each frame
	using RunService.Heartbeat.

	This creates the "breathing walls" effect: bioluminescent carvings
	that pulse slowly like a heartbeat, flesh walls that seem to throb,
	and the Seal's crack that glows in sync with the player's fear.

	Usage:
		PulseController.start(levelModel)  -- begin pulsing
		PulseController.stop()             -- cleanup connection
]]

local RunService = game:GetService("RunService")

local PulseController = {}

local heartbeatConnection: RBXScriptConnection? = nil

function PulseController.start(levelModel: Model)
	-- Collect all pulsing fixtures
	local fixtures: { { part: Part, light: PointLight, min: number, max: number, speed: number, offset: number } } = {}

	for _, descendant in levelModel:GetDescendants() do
		if descendant:IsA("Part") and descendant:GetAttribute("PulseMin") ~= nil then
			local light = descendant:FindFirstChildOfClass("PointLight")
			if light then
				table.insert(fixtures, {
					part = descendant,
					light = light,
					min = descendant:GetAttribute("PulseMin") :: number,
					max = descendant:GetAttribute("PulseMax") :: number,
					speed = descendant:GetAttribute("PulseSpeed") :: number,
					offset = descendant:GetAttribute("PulseOffset") :: number,
				})
			end
		end
	end

	if #fixtures == 0 then
		return
	end

	local elapsed = 0

	heartbeatConnection = RunService.Heartbeat:Connect(function(dt: number)
		elapsed += dt

		for _, fixture in fixtures do
			-- Sinusoidal pulse: brightness oscillates between min and max
			local t = math.sin(elapsed * fixture.speed + fixture.offset)
			local normalized = (t + 1) / 2 -- map [-1,1] to [0,1]
			local brightness = fixture.min + (fixture.max - fixture.min) * normalized

			fixture.light.Brightness = brightness

			-- Also pulse the part transparency slightly for visual effect
			local baseTrans = fixture.part:GetAttribute("BaseTransparency") :: number?
			if baseTrans == nil then
				fixture.part:SetAttribute("BaseTransparency", fixture.part.Transparency)
				baseTrans = fixture.part.Transparency
			end
			fixture.part.Transparency = baseTrans :: number + (1 - normalized) * 0.15
		end
	end)

	print(`[PulseController] Started: driving {#fixtures} pulsing lights`)
end

function PulseController.stop()
	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
		print("[PulseController] Stopped")
	end
end

return PulseController
