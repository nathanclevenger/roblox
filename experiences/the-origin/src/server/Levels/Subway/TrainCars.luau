--!strict

--[[
	Subway/TrainCars - Builds additional detail for the abandoned/derailed
	train cars throughout Level 2.

	This module adds environmental storytelling props, interactable objects,
	and atmospheric details to the train car shells built by Platform.luau.
	It also constructs the abandoned car on Platform A (Hargrove) and
	the interior details of the 6-car Moorfield stalled train.

	Returns hiding spots, patrol waypoints, and loot spawn positions.
]]

local Shared = require(script.Parent.Shared)

type HidingSpotData = Shared.HidingSpotData

export type FloorData = {
	hidingSpots: { HidingSpotData },
	waypoints: { { position: Vector3, roomId: string, dwellTime: number } },
	lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } },
}

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------

local TRACK_Y = -28
local PLATFORM_Y = -24
local MOORFIELD_Z_OFFSET = -350

------------------------------------------------------------------------
-- Module
------------------------------------------------------------------------

local TrainCars = {}

function TrainCars.build(parent: Instance): FloorData
	local hidingSpots: { HidingSpotData } = {}
	local waypoints: { { position: Vector3, roomId: string, dwellTime: number } } = {}
	local lootPositions: { { itemType: string, position: Vector3, chance: number, guaranteed: boolean } } = {}

	local trainModel = Instance.new("Model")
	trainModel.Name = "TrainCars"

	--------------------------------------------------------------------
	-- Platform A Abandoned Train Car — Interior Details
	--------------------------------------------------------------------
	do
		local carModel = Instance.new("Model")
		carModel.Name = "PlatformA_TrainInterior"

		local carBasePos = Vector3.new(-10, TRACK_Y + 1, 55)
		local carFloorY = carBasePos.Y + 0.5 -- above train car floor

		-- Scattered luggage and personal items
		for i = 1, 4 do
			local bag = Instance.new("Part")
			bag.Name = `Bag_{i}`
			bag.Size = Vector3.new(1 + math.random() * 0.5, 0.8, 1.2 + math.random() * 0.4)
			bag.Position = carBasePos + Vector3.new(
				-8 + i * 4 + (math.random() - 0.5) * 2,
				1.2,
				(math.random() - 0.5) * 3
			)
			bag.Orientation = Vector3.new(0, math.random(0, 360), 0)
			bag.Anchored = true
			bag.Material = Enum.Material.Fabric
			bag.Color = Color3.fromRGB(
				40 + math.random(0, 40),
				30 + math.random(0, 40),
				20 + math.random(0, 40)
			)
			bag.Parent = carModel
		end

		-- Ripped-off door at far end
		local tornDoor = Instance.new("Part")
		tornDoor.Name = "TornDoor"
		tornDoor.Size = Vector3.new(3.5, 6.5, 0.3)
		tornDoor.Position = carBasePos + Vector3.new(14, 3, 5)
		tornDoor.Orientation = Vector3.new(-10, 25, -15)
		tornDoor.Anchored = true
		tornDoor.Material = Enum.Material.Metal
		tornDoor.Color = Color3.fromRGB(150, 155, 160)
		tornDoor.Parent = carModel

		-- Claw marks on the door and inside windows
		for i = 1, 5 do
			local clawMark = Instance.new("Part")
			clawMark.Name = `ClawMark_Door_{i}`
			clawMark.Size = Vector3.new(0.05, 1.5 + math.random() * 0.5, 0.05)
			clawMark.Position = carBasePos + Vector3.new(
				14 + (math.random() - 0.5) * 1.5,
				2 + i * 0.6,
				5 + (math.random() - 0.5) * 0.5
			)
			clawMark.Orientation = Vector3.new(0, 0, math.random(-10, 10))
			clawMark.Anchored = true
			clawMark.Material = Enum.Material.Metal
			clawMark.Color = Color3.fromRGB(50, 45, 40)
			clawMark.Parent = carModel
		end

		-- Driver's cabin (small enclosed area at front)
		local cabinWall = Instance.new("Part")
		cabinWall.Name = "CabinDivider"
		cabinWall.Size = Vector3.new(7.2, 7.5, 0.4)
		cabinWall.Position = carBasePos + Vector3.new(-13, 4, 0)
		cabinWall.Anchored = true
		cabinWall.Material = Enum.Material.Metal
		cabinWall.Color = Color3.fromRGB(140, 140, 135)
		cabinWall.Parent = carModel

		-- Cabin door (ajar)
		local cabinDoor = Instance.new("Part")
		cabinDoor.Name = "CabinDoor"
		cabinDoor.Size = Vector3.new(0.3, 6, 2.5)
		cabinDoor.Position = carBasePos + Vector3.new(-12.6, 3.5, -1.5)
		cabinDoor.Orientation = Vector3.new(0, 30, 0)
		cabinDoor.Anchored = true
		cabinDoor.Material = Enum.Material.Metal
		cabinDoor.Color = Color3.fromRGB(130, 130, 125)
		cabinDoor.Parent = carModel

		-- Control console in cabin
		local console = Instance.new("Part")
		console.Name = "DriverConsole"
		console.Size = Vector3.new(5, 2, 2)
		console.Position = carBasePos + Vector3.new(-14, 2, 0)
		console.Anchored = true
		console.Material = Enum.Material.Metal
		console.Color = Color3.fromRGB(60, 60, 55)
		console.Parent = carModel

		-- Newspapers scattered on seats
		for i = 1, 3 do
			local paper = Instance.new("Part")
			paper.Name = `Newspaper_{i}`
			paper.Size = Vector3.new(0.8, 0.02, 1.1)
			paper.Position = carBasePos + Vector3.new(
				-6 + i * 5,
				2,
				(if i % 2 == 0 then -2.5 else 2.5)
			)
			paper.Orientation = Vector3.new(0, math.random(-30, 30), 0)
			paper.Anchored = true
			paper.Material = Enum.Material.SmoothPlastic
			paper.Color = Color3.fromRGB(210, 205, 190)
			paper.Parent = carModel
		end

		-- Ambient scratching sound trigger zone (inside train car)
		local scratchZone = Instance.new("Part")
		scratchZone.Name = "ScratchSoundZone"
		scratchZone.Size = Vector3.new(28, 8, 7)
		scratchZone.Position = carBasePos + Vector3.new(0, 4, 0)
		scratchZone.Anchored = true
		scratchZone.Transparency = 1
		scratchZone.CanCollide = false
		scratchZone.Parent = carModel
		scratchZone:SetAttribute("AmbientScratchingSounds", true)
		scratchZone:SetAttribute("SoundsStopWhenPlayerStops", true)

		-- Transit Worker's Journal (lore, on driver's console)
		local journal = Instance.new("Part")
		journal.Name = "TransitWorkerJournal"
		journal.Size = Vector3.new(0.6, 0.1, 0.8)
		journal.Position = carBasePos + Vector3.new(-14, 2.5, 0.5)
		journal.Anchored = true
		journal.Material = Enum.Material.SmoothPlastic
		journal.Color = Color3.fromRGB(80, 60, 40)
		journal.Parent = carModel

		local journalPrompt = Instance.new("ProximityPrompt")
		journalPrompt.ActionText = "Read"
		journalPrompt.ObjectText = "Transit Worker's Journal"
		journalPrompt.HoldDuration = 1
		journalPrompt.MaxActivationDistance = 6
		journalPrompt.Parent = journal

		-- Waypoint inside the car
		table.insert(waypoints, {
			position = carBasePos + Vector3.new(0, 3, 0),
			roomId = "PlatformA_InsideTrain",
			dwellTime = 3,
		})

		carModel.Parent = trainModel
	end

	--------------------------------------------------------------------
	-- Moorfield Stalled Train — Per-Car Interior Details
	--------------------------------------------------------------------
	do
		local moorTrainModel = Instance.new("Model")
		moorTrainModel.Name = "MoorfieldTrainDetails"

		local trainBaseZ = MOORFIELD_Z_OFFSET + 12 -- track position Z from Platform
		local trainBaseY = TRACK_Y + 1

		-- Car 1 (index 0): Lootable, abandoned-in-a-hurry scenario
		do
			local carX = -25
			local carModel = Instance.new("Model")
			carModel.Name = "Car1_Details"

			-- Scattered bags and coats
			for i = 1, 5 do
				local item = Instance.new("Part")
				item.Name = `AbandonedItem_{i}`
				item.Size = Vector3.new(0.8 + math.random() * 0.6, 0.5, 0.8 + math.random() * 0.6)
				item.Position = Vector3.new(
					carX + (math.random() - 0.5) * 20,
					trainBaseY + 1.5,
					trainBaseZ + (math.random() - 0.5) * 4
				)
				item.Orientation = Vector3.new(0, math.random(0, 360), 0)
				item.Anchored = true
				item.Material = Enum.Material.Fabric
				item.Color = Color3.fromRGB(
					50 + math.random(0, 60),
					40 + math.random(0, 50),
					30 + math.random(0, 50)
				)
				item.Parent = carModel
			end

			-- Overhead compartments (some open)
			for i = 0, 3 do
				local compartment = Instance.new("Part")
				compartment.Name = `Compartment_{i}`
				compartment.Size = Vector3.new(5, 1, 1.5)
				compartment.Position = Vector3.new(carX - 8 + i * 6, trainBaseY + 7, trainBaseZ + 3)
				compartment.Anchored = true
				compartment.Material = Enum.Material.SmoothPlastic
				compartment.Color = Color3.fromRGB(180, 180, 175)
				if i % 2 == 0 then
					compartment.Orientation = Vector3.new(30, 0, 0) -- hanging open
				end
				compartment.Parent = carModel
			end

			carModel.Parent = moorTrainModel
		end

		-- Car 2 (index 1): Locked, dark — no interior access, just atmosphere
		-- (Details handled by Platform.luau attributes)

		-- Car 3 (index 2): Lootable, passenger diary
		do
			local carX = -5
			local carModel = Instance.new("Model")
			carModel.Name = "Car3_Details"

			-- Child's toy (dropped)
			local toy = Instance.new("Part")
			toy.Name = "ChildsToy"
			toy.Shape = Enum.PartType.Ball
			toy.Size = Vector3.new(0.6, 0.6, 0.6)
			toy.Position = Vector3.new(carX + 2, trainBaseY + 0.8, trainBaseZ - 1)
			toy.Anchored = true
			toy.Material = Enum.Material.SmoothPlastic
			toy.Color = Color3.fromRGB(200, 60, 60)
			toy.Parent = carModel

			-- Passenger's Diary (lore item)
			local diary = Instance.new("Part")
			diary.Name = "PassengerDiary"
			diary.Size = Vector3.new(0.5, 0.08, 0.7)
			diary.Position = Vector3.new(carX - 3, trainBaseY + 2, trainBaseZ + 2.5)
			diary.Anchored = true
			diary.Material = Enum.Material.SmoothPlastic
			diary.Color = Color3.fromRGB(120, 50, 50)
			diary.Parent = carModel

			local diaryPrompt = Instance.new("ProximityPrompt")
			diaryPrompt.ActionText = "Read"
			diaryPrompt.ObjectText = "Passenger's Diary"
			diaryPrompt.HoldDuration = 1
			diaryPrompt.MaxActivationDistance = 6
			diaryPrompt.Parent = diary

			-- Scattered coat and scarf
			local coat = Instance.new("Part")
			coat.Name = "AbandonedCoat"
			coat.Size = Vector3.new(2, 0.3, 1.5)
			coat.Position = Vector3.new(carX + 5, trainBaseY + 1.8, trainBaseZ - 2.5)
			coat.Anchored = true
			coat.Material = Enum.Material.Fabric
			coat.Color = Color3.fromRGB(50, 50, 70)
			coat.Parent = carModel

			carModel.Parent = moorTrainModel
		end

		-- Car 4 (index 3): Transit worker body with maintenance key
		-- (Body created in Platform.luau, adding environmental details)
		do
			local carX = 5
			local carModel = Instance.new("Model")
			carModel.Name = "Car4_Details"

			-- Blood smear on window near body
			local bloodSmear = Instance.new("Part")
			bloodSmear.Name = "BloodSmear"
			bloodSmear.Size = Vector3.new(2, 1.5, 0.05)
			bloodSmear.Position = Vector3.new(carX + 5, trainBaseY + 4, trainBaseZ + 3.9)
			bloodSmear.Anchored = true
			bloodSmear.Material = Enum.Material.SmoothPlastic
			bloodSmear.Color = Color3.fromRGB(60, 20, 15)
			bloodSmear.Transparency = 0.4
			bloodSmear.CanCollide = false
			bloodSmear.Parent = carModel

			-- Dropped radio near body
			local radio = Instance.new("Part")
			radio.Name = "DroppedRadio"
			radio.Size = Vector3.new(0.5, 0.3, 0.3)
			radio.Position = Vector3.new(carX + 4, trainBaseY + 0.6, trainBaseZ + 0.5)
			radio.Orientation = Vector3.new(0, 45, 0)
			radio.Anchored = true
			radio.Material = Enum.Material.SmoothPlastic
			radio.Color = Color3.fromRGB(30, 30, 28)
			radio.Parent = carModel

			carModel.Parent = moorTrainModel
		end

		-- Car 5 (index 4): Roof breached, claw marks
		do
			local carX = 15
			local carModel = Instance.new("Model")
			carModel.Name = "Car5_Details"

			-- Claw marks radiating outward from breach
			for i = 1, 8 do
				local mark = Instance.new("Part")
				mark.Name = `BreachClawMark_{i}`
				local angle = (i / 8) * math.pi * 2
				mark.Size = Vector3.new(0.08, 0.08, 2 + math.random() * 1.5)
				mark.Position = Vector3.new(
					carX + math.cos(angle) * 2,
					trainBaseY + 8 + 0.1,
					trainBaseZ + math.sin(angle) * 2
				)
				mark.CFrame = CFrame.new(mark.Position, mark.Position + Vector3.new(math.cos(angle), 0, math.sin(angle)))
				mark.Anchored = true
				mark.Material = Enum.Material.Metal
				mark.Color = Color3.fromRGB(50, 45, 40)
				mark.Parent = carModel
			end

			-- Debris from breach on car floor
			Shared.createRubble(
				Vector3.new(carX, trainBaseY, trainBaseZ),
				4, 5, carModel, "BreachDebris"
			)

			-- Trigger zone for ceiling drop attack
			local dropZone = Instance.new("Part")
			dropZone.Name = "CeilingDropZone"
			dropZone.Size = Vector3.new(8, 2, 8)
			dropZone.Position = Vector3.new(carX, trainBaseY + 2, trainBaseZ)
			dropZone.Anchored = true
			dropZone.Transparency = 1
			dropZone.CanCollide = false
			dropZone.Parent = carModel
			dropZone:SetAttribute("CrawlerDropPoint", true)

			carModel.Parent = moorTrainModel
		end

		-- Car 6 (index 5): Empty with intercom
		-- (Attributes set in Platform.luau)
		do
			local carX = 25
			local carModel = Instance.new("Model")
			carModel.Name = "Car6_Details"

			-- Intercom speaker on wall
			local speaker = Instance.new("Part")
			speaker.Name = "IntercomSpeaker"
			speaker.Size = Vector3.new(1, 1, 0.3)
			speaker.Position = Vector3.new(carX + 8, trainBaseY + 6, trainBaseZ)
			speaker.Anchored = true
			speaker.Material = Enum.Material.Metal
			speaker.Color = Color3.fromRGB(80, 80, 75)
			speaker.Parent = carModel

			-- Eerie emptiness — no personal items, just clean seats
			-- This contrast with other cars is deliberate

			carModel.Parent = moorTrainModel
		end

		-- Waypoints along the Moorfield train
		table.insert(waypoints, {
			position = Vector3.new(-25, trainBaseY + 3, trainBaseZ),
			roomId = "MoorfieldTrain_Car1",
			dwellTime = 2,
		})
		table.insert(waypoints, {
			position = Vector3.new(-5, trainBaseY + 3, trainBaseZ),
			roomId = "MoorfieldTrain_Car3",
			dwellTime = 2,
		})
		table.insert(waypoints, {
			position = Vector3.new(15, trainBaseY + 3, trainBaseZ),
			roomId = "MoorfieldTrain_Car5",
			dwellTime = 3,
		})

		moorTrainModel.Parent = trainModel
	end

	trainModel.Parent = parent

	return {
		hidingSpots = hidingSpots,
		waypoints = waypoints,
		lootPositions = lootPositions,
	}
end

return TrainCars
