--!strict

--[[
	DrawingMaterializer
	Takes 2D drawing data from clients and converts it into 3D physical objects
	in the workspace. Handles material properties, physics, and lifetime management.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)

type DrawingData = Types.DrawingData
type DrawingStroke = Types.DrawingStroke
type MaterializedDrawing = Types.MaterializedDrawing
type DrawingMaterial = Types.DrawingMaterial

local DrawingMaterializer = {}
DrawingMaterializer.__index = DrawingMaterializer

type DrawingMaterializerImpl = {
	ActiveDrawings: { MaterializedDrawing },
	DrawingsFolder: Folder,
	_heartbeatConn: RBXScriptConnection?,
}

function DrawingMaterializer.new(): DrawingMaterializerImpl
	local self = setmetatable({}, DrawingMaterializer) :: any

	self.ActiveDrawings = {}

	local folder = Instance.new("Folder")
	folder.Name = "MaterializedDrawings"
	folder.Parent = workspace
	self.DrawingsFolder = folder

	self._heartbeatConn = RunService.Heartbeat:Connect(function()
		self:_cleanupExpired()
	end)

	return self :: DrawingMaterializerImpl
end

function DrawingMaterializer.Materialize(
	self: DrawingMaterializerImpl,
	drawingData: DrawingData,
	spawnPosition: Vector3,
	owner: Player,
	lifetime: number
): Model?
	if #drawingData.Strokes == 0 then
		return nil
	end

	local model = Instance.new("Model")
	model.Name = `Drawing_{owner.Name}_{tick()}`

	-- Determine primary material from most-used stroke material
	local materialCounts: { [string]: number } = {}
	for _, stroke in drawingData.Strokes do
		materialCounts[stroke.Material] = (materialCounts[stroke.Material] or 0) + #stroke.Points
	end

	local primaryMaterial: DrawingMaterial = "wood"
	local maxCount = 0
	for mat, count in materialCounts do
		if count > maxCount then
			maxCount = count
			primaryMaterial = mat :: DrawingMaterial
		end
	end

	local matProps = Constants.MATERIAL_PROPERTIES[primaryMaterial]

	-- Convert 2D strokes to 3D parts
	local scale = Constants.DRAWING_SCALE
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge

	-- First pass: find bounding box
	for _, stroke in drawingData.Strokes do
		for _, point in stroke.Points do
			minX = math.min(minX, point.X)
			minY = math.min(minY, point.Y)
			maxX = math.max(maxX, point.X)
			maxY = math.max(maxY, point.Y)
		end
	end

	local centerX = (minX + maxX) / 2
	local centerY = (minY + maxY) / 2

	-- Second pass: create parts for each stroke segment
	local partCount = 0
	local maxParts = 100

	for _, stroke in drawingData.Strokes do
		local strokeMatProps = Constants.MATERIAL_PROPERTIES[stroke.Material] or matProps

		for i = 1, #stroke.Points - 1 do
			if partCount >= maxParts then
				break
			end

			local p1 = stroke.Points[i]
			local p2 = stroke.Points[i + 1]

			local dx = (p2.X - p1.X) * scale
			local dy = (p2.Y - p1.Y) * scale
			local length = math.sqrt(dx * dx + dy * dy)

			if length < 0.1 then
				continue
			end

			local thickness = math.clamp(stroke.Thickness * scale, 0.2, 2)

			local part = Instance.new("Part")
			part.Size = Vector3.new(thickness, thickness, length)
			part.Anchored = false
			part.CanCollide = true
			part.Material = strokeMatProps.RobloxMaterial
			part.Color = stroke.Color

			if strokeMatProps.GlowsInDark then
				local light = Instance.new("PointLight")
				light.Color = stroke.Color
				light.Brightness = 1.5
				light.Range = 12
				light.Parent = part
			end

			if strokeMatProps.Transparent then
				part.Transparency = 0.4
			end

			-- Position relative to spawn
			local midX = ((p1.X + p2.X) / 2 - centerX) * scale
			local midY = -((p1.Y + p2.Y) / 2 - centerY) * scale
			part.Position = spawnPosition + Vector3.new(midX, midY + 3, 0)

			-- Rotate to match stroke direction
			local angle = math.atan2(dy, dx)
			part.CFrame = CFrame.new(part.Position) * CFrame.Angles(0, 0, -angle)

			-- Physics properties
			local physProps =
				PhysicalProperties.new(strokeMatProps.Density, strokeMatProps.Friction, strokeMatProps.Elasticity)
			part.CustomPhysicalProperties = physProps

			part.Parent = model
			partCount += 1
		end
	end

	if partCount == 0 then
		model:Destroy()
		return nil
	end

	-- Weld all parts together
	local parts = model:GetChildren()
	local primaryPart = parts[1] :: Part
	model.PrimaryPart = primaryPart

	for i = 2, #parts do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = primaryPart
		weld.Part1 = parts[i] :: Part
		weld.Parent = primaryPart
	end

	-- Apply buoyancy if positive
	if matProps.Buoyancy > 0.5 then
		local bodyForce = Instance.new("BodyForce")
		bodyForce.Force = Vector3.new(0, matProps.Buoyancy * 500, 0)
		bodyForce.Parent = primaryPart
	end

	model.Parent = self.DrawingsFolder

	-- Track active drawing
	local materializedDrawing: MaterializedDrawing = {
		Model = model,
		Material = primaryMaterial,
		Behavior = self:_detectBehavior(drawingData, primaryMaterial),
		CreatedAt = tick(),
		Lifetime = lifetime,
		Owner = owner,
	}
	table.insert(self.ActiveDrawings, materializedDrawing)

	return model
end

function DrawingMaterializer._detectBehavior(
	_self: DrawingMaterializerImpl,
	drawingData: DrawingData,
	material: DrawingMaterial
): Types.DrawingBehavior
	-- Analyze the drawing shape to determine behavior
	local totalPoints = 0
	local avgY = 0
	local width = 0
	local height = 0

	for _, stroke in drawingData.Strokes do
		for _, point in stroke.Points do
			totalPoints += 1
			avgY += point.Y
		end
	end

	if totalPoints == 0 then
		return "static"
	end

	avgY /= totalPoints

	-- Calculate bounding box
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	for _, stroke in drawingData.Strokes do
		for _, point in stroke.Points do
			minX = math.min(minX, point.X)
			minY = math.min(minY, point.Y)
			maxX = math.max(maxX, point.X)
			maxY = math.max(maxY, point.Y)
		end
	end

	width = maxX - minX
	height = maxY - minY

	-- Balloon material always floats
	if material == "balloon" then
		return "floats"
	end

	-- Wide and flat = could be a bridge/platform (static)
	if width > height * 3 then
		return "static"
	end

	-- Roughly circular = bounces or rolls
	local aspectRatio = if height > 0 then width / height else 1
	if aspectRatio > 0.7 and aspectRatio < 1.3 and totalPoints > 20 then
		return "bounces"
	end

	-- Tall and narrow = walks (character-like)
	if height > width * 2 then
		return "walks"
	end

	return "static"
end

function DrawingMaterializer.GetPlayerDrawingCount(self: DrawingMaterializerImpl, player: Player): number
	local count = 0
	for _, drawing in self.ActiveDrawings do
		if drawing.Owner == player and drawing.Model.Parent ~= nil then
			count += 1
		end
	end
	return count
end

function DrawingMaterializer.RemovePlayerDrawings(self: DrawingMaterializerImpl, player: Player)
	for i = #self.ActiveDrawings, 1, -1 do
		local drawing = self.ActiveDrawings[i]
		if drawing.Owner == player then
			if drawing.Model.Parent then
				drawing.Model:Destroy()
			end
			table.remove(self.ActiveDrawings, i)
		end
	end
end

function DrawingMaterializer._cleanupExpired(self: DrawingMaterializerImpl)
	local now = tick()
	for i = #self.ActiveDrawings, 1, -1 do
		local drawing = self.ActiveDrawings[i]
		local age = now - drawing.CreatedAt

		-- Fade out before despawning
		if age > drawing.Lifetime - 2 and drawing.Model.Parent then
			local fadeProgress = (age - (drawing.Lifetime - 2)) / 2
			for _, part in drawing.Model:GetDescendants() do
				if part:IsA("BasePart") then
					part.Transparency = math.clamp(fadeProgress, 0, 0.9)
				end
			end
		end

		if age >= drawing.Lifetime then
			if drawing.Model.Parent then
				drawing.Model:Destroy()
			end
			table.remove(self.ActiveDrawings, i)
		end
	end
end

function DrawingMaterializer.Destroy(self: DrawingMaterializerImpl)
	if self._heartbeatConn then
		self._heartbeatConn:Disconnect()
		self._heartbeatConn = nil
	end

	for _, drawing in self.ActiveDrawings do
		if drawing.Model.Parent then
			drawing.Model:Destroy()
		end
	end
	self.ActiveDrawings = {}

	if self.DrawingsFolder.Parent then
		self.DrawingsFolder:Destroy()
	end
end

return DrawingMaterializer
