--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)
local PlayerController = require(script.PlayerController)
local ProximityFear = require(script.ProximityFear)
local ScareRenderer = require(script.ScareRenderer)

local player = Players.LocalPlayer

-- Client entry point
print(`[Client] {Constants.GAME_NAME} v{Constants.GAME_VERSION} — {player.Name} connected`)

-- Initialize client systems
local proximityFear = ProximityFear.new(player)
local playerController = PlayerController.new(player)
local scareRenderer = ScareRenderer.new(player)

-- Initialize UI (require after creation since directory may be new)
local UI = require(script.UI)
local gameUI = UI.new(player)

-- Wait for Remotes folder
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
if not remotesFolder then
	warn("[Client] Remotes folder not found!")
	return
end

-- Track entity distance for proximity fear
local entityPosition: Vector3? = nil
local _entityState: string? = nil
local isSpectating = false

-- Entity position updates
local entityPosRemote = remotesFolder:WaitForChild("EntityPositionUpdate", 5)
if entityPosRemote then
	(entityPosRemote :: RemoteEvent).OnClientEvent:Connect(function(pos: Vector3, state: string)
		entityPosition = pos
		_entityState = state
	end)
end

-- Entity state changes
local entityStateRemote = remotesFolder:WaitForChild("EntityStateChanged", 5)
if entityStateRemote then
	(entityStateRemote :: RemoteEvent).OnClientEvent:Connect(function(state: string)
		_entityState = state
	end)
end

-- Player damaged
local playerDamagedRemote = remotesFolder:WaitForChild("PlayerDamaged", 5)
if playerDamagedRemote then
	(playerDamagedRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		if data.health then
			gameUI:updateHealth(data.health, Constants.MAX_HEALTH, data.isBleeding or false)
		end
		if data.isBleeding then
			playerController:setInjuryModifier(Constants.SPEED_LIMP_MODIFIER)
		end
	end)
end

-- Player state update (full state sync)
local stateUpdateRemote = remotesFolder:WaitForChild("PlayerStateUpdate", 5)
if stateUpdateRemote then
	(stateUpdateRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		if data.state then
			local state = data.state
			gameUI:updateHealth(state.health, state.maxHealth, state.isBleeding)
			gameUI:updateInventory(state.inventory, state.keyItems)

			-- Update injury modifier based on health
			if state.health <= 2 and state.health > 0 then
				playerController:setInjuryModifier(Constants.SPEED_LIMP_MODIFIER)
			else
				playerController:setInjuryModifier(1.0)
			end

			-- Battery refill
			if data.batteryRefill then
				playerController:refillBattery()
			end
		end
	end)
end

-- Objective updates
local objectiveRemote = remotesFolder:WaitForChild("ObjectiveUpdated", 5)
if objectiveRemote then
	(objectiveRemote :: RemoteEvent).OnClientEvent:Connect(function(objective: any)
		gameUI:updateObjective(objective)
	end)
end

-- Objectives loaded
local objectivesLoadedRemote = remotesFolder:WaitForChild("ObjectivesLoaded", 5)
if objectivesLoadedRemote then
	(objectivesLoadedRemote :: RemoteEvent).OnClientEvent:Connect(function(objectives: any)
		gameUI:loadObjectives(objectives)
	end)
end

-- Item pickup result
local pickupResultRemote = remotesFolder:WaitForChild("ItemPickupResult", 5)
if pickupResultRemote then
	(pickupResultRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		if data.success and data.state then
			gameUI:updateInventory(data.state.inventory, data.state.keyItems)
		end
	end)
end

-- Hiding spot checked (entity is checking your hiding spot!)
local hidingCheckedRemote = remotesFolder:WaitForChild("HidingSpotChecked", 5)
if hidingCheckedRemote then
	(hidingCheckedRemote :: RemoteEvent).OnClientEvent:Connect(function()
		-- Spike dread: force proximity fear to max for a moment
		proximityFear:update(0.016, 5) -- simulate 5 studs distance
	end)
end

-- Flashlight flicker (entity electronic flatline)
local flickerRemote = remotesFolder:WaitForChild("FlashlightFlicker", 5)
if flickerRemote then
	(flickerRemote :: RemoteEvent).OnClientEvent:Connect(function()
		playerController:flickerFlashlight()
	end)
end

-- Jumpscare system — TriggerScare events from server
local triggerScareRemote = remotesFolder:WaitForChild("TriggerScare", 5)
if triggerScareRemote then
	(triggerScareRemote :: RemoteEvent).OnClientEvent:Connect(function(scareEvent: any)
		scareRenderer:onScareEvent(scareEvent)
	end)
end

-- Entity attack feedback (screen shake, red flash, impact sound)
local entityAttackRemote = remotesFolder:WaitForChild("EntityAttack", 5)
if entityAttackRemote then
	(entityAttackRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		-- Screen shake
		local camera = workspace.CurrentCamera
		if camera then
			local shakeIntensity = 1.5
			local shakeDuration = 0.3
			task.spawn(function()
				local elapsed = 0
				while elapsed < shakeDuration do
					local dt = task.wait()
					elapsed += dt
					local factor = 1 - (elapsed / shakeDuration)
					local offsetX = (math.random() - 0.5) * 2 * shakeIntensity * factor
					local offsetY = (math.random() - 0.5) * 2 * shakeIntensity * factor
					camera.CFrame = camera.CFrame * CFrame.new(offsetX, offsetY, 0)
				end
			end)
		end

		-- Red flash vignette via ColorCorrection
		local lighting = game:GetService("Lighting")
		local flash = Instance.new("ColorCorrectionEffect")
		flash.Name = "EntityAttackFlash"
		flash.TintColor = Color3.fromRGB(255, 50, 50)
		flash.Saturation = -0.5
		flash.Brightness = 0.1
		flash.Parent = lighting

		-- Fade out the red flash
		task.spawn(function()
			local fadeDuration = 0.5
			local fadeElapsed = 0
			while fadeElapsed < fadeDuration do
				local dt = task.wait()
				fadeElapsed += dt
				local alpha = 1 - (fadeElapsed / fadeDuration)
				flash.Brightness = 0.1 * alpha
				flash.Saturation = -0.5 * alpha
				flash.TintColor = Color3.fromRGB(
					math.floor(255 * alpha + 255 * (1 - alpha)),
					math.floor(50 * alpha + 255 * (1 - alpha)),
					math.floor(50 * alpha + 255 * (1 - alpha))
				)
			end
			flash:Destroy()
		end)

		-- Spike proximity fear
		proximityFear:update(0.016, 2)

		-- Log if dragged out of hiding spot
		if data.draggedOut then
			print("[Client] Dragged out of hiding spot by entity!")
		end
	end)
end

-- Entity stun notification (brief movement lock)
local entityStunRemote = remotesFolder:WaitForChild("EntityStun", 5)
if entityStunRemote then
	(entityStunRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		local duration = data.duration or 0.5
		print(`[Client] Stunned by entity for {duration}s`)
		-- Movement lock is handled server-side via humanoid.WalkSpeed = 0
		-- Client-side: we show a brief black bar or jolt effect
		proximityFear:update(0.016, 1) -- extreme proximity spike
	end)
end

-- Door state changed (animation sync, sound feedback)
local doorStateRemote = remotesFolder:WaitForChild("DoorStateChanged", 5)
if doorStateRemote then
	(doorStateRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		local doorId = data.doorId
		local action = data.action

		if action == "locked" then
			-- Show "Locked" feedback text
			gameUI:showNotification("Locked")
		elseif action == "broken" then
			-- Entity broke a door — loud slam sound feedback
			-- Screen shake if player is nearby
			local character = player.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					-- Find the door part in workspace by DoorId attribute
					local doorPart: Part? = nil
					for _, desc in workspace:GetDescendants() do
						if desc:IsA("Part") and desc:GetAttribute("DoorId") == doorId then
							doorPart = desc :: Part
							break
						end
					end

					if doorPart then
						local dist = ((hrp :: BasePart).Position - doorPart.Position).Magnitude
						if dist < 40 then
							-- Nearby door break: screen shake scaled by distance
							local camera = workspace.CurrentCamera
							if camera then
								local intensity = math.clamp(1 - dist / 40, 0, 1) * 0.8
								task.spawn(function()
									local elapsed = 0
									while elapsed < 0.2 do
										local dt = task.wait()
										elapsed += dt
										local factor = 1 - (elapsed / 0.2)
										local offsetX = (math.random() - 0.5) * 2 * intensity * factor
										local offsetY = (math.random() - 0.5) * 2 * intensity * factor
										camera.CFrame = camera.CFrame * CFrame.new(offsetX, offsetY, 0)
									end
								end)
							end
						end
					end
				end
			end
		end

		-- Door tween animation is handled server-side via TweenService
		-- (Parts are replicated automatically)
	end)
end

-- Door interaction: wire ProximityPrompts on doors to fire the DoorInteract remote
-- This runs whenever a part with DoorId gets a ProximityPrompt triggered
do
	local doorInteractRemote = remotesFolder:WaitForChild("DoorInteract", 5)
	if doorInteractRemote then
		-- Listen for ProximityPrompt triggers on any door in workspace
		local function connectDoorPrompt(part: Instance)
			if not part:IsA("Part") then
				return
			end
			local doorId = part:GetAttribute("DoorId")
			if not doorId then
				return
			end
			local prompt = part:FindFirstChildOfClass("ProximityPrompt")
			if not prompt then
				return
			end
			prompt.Triggered:Connect(function(_triggeringPlayer: Player)
				(doorInteractRemote :: RemoteEvent):FireServer(doorId)
			end)
		end

		-- Connect existing doors
		for _, desc in workspace:GetDescendants() do
			connectDoorPrompt(desc)
		end

		-- Connect doors added later (during level build)
		workspace.DescendantAdded:Connect(function(desc: Instance)
			-- Defer to allow the DoorId attribute to be set
			task.defer(function()
				connectDoorPrompt(desc)
			end)
		end)
	end
end

-- ============================================================================
-- Lives / Death System Remotes
-- ============================================================================

-- Player died — play death animation and update hearts HUD
local playerDiedRemote = remotesFolder:WaitForChild("PlayerDied", 5)
if playerDiedRemote then
	(playerDiedRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		local deathNumber: number = data.deathNumber or 1
		local heartsRemaining: number = data.heartsRemaining or 0

		print(`[Client] Death #{deathNumber} — {heartsRemaining} hearts remaining`)

		-- Freeze proximity fear effects during death animation
		proximityFear:freeze()

		-- Play the death animation (blocking visual)
		gameUI:playDeathAnimation(deathNumber)
	end)
end

-- Player respawned — re-show HUD, reset proximity fear
local playerRespawnedRemote = remotesFolder:WaitForChild("PlayerRespawned", 5)
if playerRespawnedRemote then
	(playerRespawnedRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		local heartsRemaining: number = data.heartsRemaining or 0
		local deathCount: number = data.deathCount or 0

		print(`[Client] Respawned — {heartsRemaining} hearts remaining`)

		-- Re-show HUD elements
		gameUI:onRespawn()

		-- Update hearts display
		gameUI:updateHearts(heartsRemaining, deathCount)

		-- Unfreeze and reset proximity fear (grace period handled server-side)
		proximityFear:unfreeze()
		proximityFear:resetToSafe()

		-- Apply post-death-2 desaturation if on last life
		if deathCount >= 2 then
			local lighting = game:GetService("Lighting")
			local deathDesaturation = lighting:FindFirstChild("DeathDesaturation")
			if not deathDesaturation then
				local cc = Instance.new("ColorCorrectionEffect")
				cc.Name = "DeathDesaturation"
				cc.Saturation = -Constants.POST_DEATH2_DESATURATION
				cc.Parent = lighting
			end
		end
	end)
end

-- Heart update — sync hearts HUD with server state
local heartUpdateRemote = remotesFolder:WaitForChild("HeartUpdate", 5)
if heartUpdateRemote then
	(heartUpdateRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		-- Own hearts update
		if data.hearts and data.maxHearts then
			gameUI:updateHearts(data.hearts, data.deathCount or 0)
		end

		-- Other player death notification
		if data.otherPlayer then
			local msg = if data.isFinalDeath
				then `{data.otherPlayer} has died permanently.`
				else `{data.otherPlayer} has died. ({data.otherPlayerHearts} lives remaining)`
			gameUI:showNotification(msg)
		end
	end)
end

-- Checkpoint reached — subtle notification
local checkpointRemote = remotesFolder:WaitForChild("CheckpointReached", 5)
if checkpointRemote then
	(checkpointRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		-- Very subtle checkpoint indication — brief text that fades quickly
		local name = data.name or "Checkpoint"
		gameUI:showNotification(name)
	end)
end

-- ============================================================================
-- Spectator / CCTV System Remotes
-- ============================================================================

-- Enter spectator mode — server tells us to show the CCTV overlay
local enterSpectatorRemote = remotesFolder:WaitForChild("EnterSpectator", 5)
if enterSpectatorRemote then
	(enterSpectatorRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		isSpectating = true

		-- Set camera to scriptable mode for CCTV
		local camera = workspace.CurrentCamera
		if camera then
			camera.CameraType = Enum.CameraType.Scriptable
		end

		-- Get the first camera name and set its CFrame
		local cameras = data.cameras
		if cameras and #cameras > 0 then
			local firstCam = cameras[1]
			if camera and firstCam.cframe then
				camera.CFrame = firstCam.cframe
			end
			gameUI:enterSpectator(firstCam.name)
		else
			gameUI:enterSpectator("CAM 01")
		end

		-- Freeze proximity fear during spectator mode
		proximityFear:freeze()

		print("[Client] Entered spectator mode")
	end)
end

-- Exit spectator mode — server tells us to restore normal view
local exitSpectatorRemote = remotesFolder:WaitForChild("ExitSpectator", 5)
if exitSpectatorRemote then
	(exitSpectatorRemote :: RemoteEvent).OnClientEvent:Connect(function(_data: any)
		isSpectating = false

		-- Restore camera to default mode
		local camera = workspace.CurrentCamera
		if camera then
			camera.CameraType = Enum.CameraType.Custom
		end

		gameUI:exitSpectator()

		-- Unfreeze proximity fear
		proximityFear:unfreeze()

		print("[Client] Exited spectator mode")
	end)
end

-- CCTV camera update — server sends new camera CFrame when cycling
local cctvCameraUpdateRemote = remotesFolder:WaitForChild("CCTVCameraUpdate", 5)
if cctvCameraUpdateRemote then
	(cctvCameraUpdateRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		local camera = workspace.CurrentCamera
		if camera and data.cframe then
			camera.CFrame = data.cframe
		end

		if data.name then
			gameUI:updateSpectatorCamera(data.name, data.index or 1, data.total or 1)
		end
	end)
end

-- Input handling for CCTV camera cycling (Q = prev, E = next)
do
	local cycleCameraRemote = remotesFolder:WaitForChild("CycleCCTVCamera", 5)
	if cycleCameraRemote then
		UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
			if gameProcessed then
				return
			end
			if not isSpectating then
				return
			end

			if input.KeyCode == Enum.KeyCode.Q then
				(cycleCameraRemote :: RemoteEvent):FireServer("prev")
			elseif input.KeyCode == Enum.KeyCode.E then
				(cycleCameraRemote :: RemoteEvent):FireServer("next")
			end
		end)
	end
end

-- ============================================================================
-- Notification System Remotes
-- ============================================================================

-- Game notifications (multiplayer events: fallen, revived, died, gone, etc.)
local gameNotificationRemote = remotesFolder:WaitForChild("GameNotification", 5)
if gameNotificationRemote then
	(gameNotificationRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		local notification: Types.GameNotification = {
			message = data.message or "",
			notificationType = data.notificationType or "event",
			playerName = data.playerName,
		}
		gameUI:showGameNotification(notification)
	end)
end

-- Revive started — visual feedback that someone is being revived
local reviveStartedRemote = remotesFolder:WaitForChild("ReviveStarted", 5)
if reviveStartedRemote then
	(reviveStartedRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		print(`[Client] {data.reviver or "?"} is reviving {data.target or "?"}`)
	end)
end

-- Revive completed — visual feedback that revive succeeded
local reviveCompletedRemote = remotesFolder:WaitForChild("ReviveCompleted", 5)
if reviveCompletedRemote then
	(reviveCompletedRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		print(`[Client] {data.reviver or "?"} revived {data.target or "?"}`)
	end)
end

-- Round started
local roundStartedRemote = remotesFolder:WaitForChild("RoundStarted", 5)
if roundStartedRemote then
	(roundStartedRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		print(`[Client] Round started: {data.level or "unknown"}`)
	end)
end

-- Round ended
local roundEndedRemote = remotesFolder:WaitForChild("RoundEnded", 5)
if roundEndedRemote then
	(roundEndedRemote :: RemoteEvent).OnClientEvent:Connect(function(data: any)
		print(`[Client] Round ended: {if data.success then "Victory!" else "Defeat"}`)
		entityPosition = nil
		_entityState = nil

		-- Exit spectator mode if active (server also sends ExitSpectator, but
		-- handle it here as well for immediate cleanup)
		if isSpectating then
			isSpectating = false
			local camera = workspace.CurrentCamera
			if camera then
				camera.CameraType = Enum.CameraType.Custom
			end
			gameUI:exitSpectator()
			proximityFear:unfreeze()
		end

		-- Clean up any active scare effects
		scareRenderer:cleanup()
		scareRenderer:setupGui() -- reinitialize for next round
	end)
end

-- Main update loop: calculate entity distance and feed to proximity fear
RunService.Heartbeat:Connect(function(dt: number)
	-- Skip normal gameplay updates when spectating
	if isSpectating then
		return
	end

	local character = player.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local entityDist: number? = nil
	if entityPosition then
		entityDist = (hrp.Position - entityPosition).Magnitude
	end

	proximityFear:update(dt, entityDist)
	gameUI:updateStamina(playerController.stamina)

	-- Feed fear tier to hearts HUD for pulse synchronization
	gameUI:setFearTier(proximityFear:getTierNumber())
end)
