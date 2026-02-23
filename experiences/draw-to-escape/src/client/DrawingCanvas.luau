--!strict

--[[
	DrawingCanvas
	Client-side 2D drawing UI. Player draws on a canvas, selects materials
	and colors, then submits to server for 3D materialization.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Types = require(ReplicatedStorage.Shared.Types)

type DrawingPoint = Types.DrawingPoint
type DrawingStroke = Types.DrawingStroke
type DrawingData = Types.DrawingData
type DrawingMaterial = Types.DrawingMaterial

local LocalPlayer = Players.LocalPlayer

local DrawingCanvas = {}
DrawingCanvas.__index = DrawingCanvas

type DrawingCanvasImpl = {
	ScreenGui: ScreenGui,
	CanvasFrame: Frame,
	IsOpen: boolean,
	IsDrawing: boolean,
	CurrentStrokes: { DrawingStroke },
	CurrentPoints: { DrawingPoint },
	SelectedColor: Color3,
	SelectedMaterial: DrawingMaterial,
	SelectedThickness: number,
	AvailableMaterials: { DrawingMaterial },
	LineObjects: { Frame },
	OnSubmit: ((DrawingData) -> ())?,
	OnClose: (() -> ())?,
	_connections: { RBXScriptConnection },
}

local MATERIAL_COLORS: { [string]: Color3 } = {
	wood = Color3.fromRGB(160, 120, 60),
	stone = Color3.fromRGB(140, 140, 140),
	ice = Color3.fromRGB(180, 220, 255),
	balloon = Color3.fromRGB(255, 100, 120),
	metal = Color3.fromRGB(180, 180, 190),
	rubber = Color3.fromRGB(60, 60, 60),
	glass = Color3.fromRGB(200, 230, 255),
	magnet = Color3.fromRGB(200, 50, 50),
	neon = Color3.fromRGB(0, 255, 150),
}

local PALETTE_COLORS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(30, 30, 30),
	Color3.fromRGB(255, 60, 60),
	Color3.fromRGB(60, 130, 255),
	Color3.fromRGB(60, 200, 60),
	Color3.fromRGB(255, 200, 40),
	Color3.fromRGB(200, 60, 255),
	Color3.fromRGB(255, 140, 40),
}

function DrawingCanvas.new(): DrawingCanvasImpl
	local self = setmetatable({}, DrawingCanvas) :: any

	self.IsOpen = false
	self.IsDrawing = false
	self.CurrentStrokes = {}
	self.CurrentPoints = {}
	self.SelectedColor = Color3.fromRGB(30, 30, 30)
	self.SelectedMaterial = "wood" :: DrawingMaterial
	self.SelectedThickness = 4
	self.AvailableMaterials = { "wood", "stone" }
	self.LineObjects = {}
	self.OnSubmit = nil
	self.OnClose = nil
	self._connections = {}

	self:_buildUI()

	return self :: DrawingCanvasImpl
end

function DrawingCanvas._buildUI(self: DrawingCanvasImpl)
	-- Main ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DrawingCanvas"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	self.ScreenGui = screenGui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.4
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	-- Main container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.fromOffset(500, 440)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	container.BorderSizePixel = 0
	container.Parent = screenGui

	local containerCorner = Instance.new("UICorner")
	containerCorner.CornerRadius = UDim.new(0, 12)
	containerCorner.Parent = container

	local containerStroke = Instance.new("UIStroke")
	containerStroke.Color = Color3.fromRGB(80, 80, 90)
	containerStroke.Thickness = 2
	containerStroke.Parent = container

	-- Title bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 36)
	titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = container

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleBar

	-- Fix bottom corners of title bar
	local titleFix = Instance.new("Frame")
	titleFix.Size = UDim2.new(1, 0, 0, 12)
	titleFix.Position = UDim2.new(0, 0, 1, -12)
	titleFix.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	titleFix.BorderSizePixel = 0
	titleFix.Parent = titleBar

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -80, 1, 0)
	titleLabel.Position = UDim2.fromOffset(12, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Sketchpad"
	titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.Position = UDim2.new(1, -34, 0, 4)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 14
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = titleBar

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 6)
	closeBtnCorner.Parent = closeBtn

	-- Canvas area
	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.new(1, -20, 0, Constants.CANVAS_HEIGHT)
	canvas.Position = UDim2.fromOffset(10, 42)
	canvas.BackgroundColor3 = Color3.fromRGB(250, 248, 240)
	canvas.BorderSizePixel = 0
	canvas.ClipsDescendants = true
	canvas.Parent = container
	self.CanvasFrame = canvas

	local canvasCorner = Instance.new("UICorner")
	canvasCorner.CornerRadius = UDim.new(0, 4)
	canvasCorner.Parent = canvas

	-- Toolbar area (below canvas)
	local toolbar = Instance.new("Frame")
	toolbar.Name = "Toolbar"
	toolbar.Size = UDim2.new(1, -20, 0, 80)
	toolbar.Position = UDim2.fromOffset(10, 348)
	toolbar.BackgroundTransparency = 1
	toolbar.Parent = container

	-- Color palette
	local colorLabel = Instance.new("TextLabel")
	colorLabel.Size = UDim2.fromOffset(40, 16)
	colorLabel.BackgroundTransparency = 1
	colorLabel.Text = "Color"
	colorLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	colorLabel.TextSize = 11
	colorLabel.Font = Enum.Font.Gotham
	colorLabel.TextXAlignment = Enum.TextXAlignment.Left
	colorLabel.Parent = toolbar

	for i, color in PALETTE_COLORS do
		local colorBtn = Instance.new("TextButton")
		colorBtn.Name = `Color_{i}`
		colorBtn.Size = UDim2.fromOffset(22, 22)
		colorBtn.Position = UDim2.fromOffset((i - 1) * 27, 18)
		colorBtn.BackgroundColor3 = color
		colorBtn.Text = ""
		colorBtn.Parent = toolbar

		local colorBtnCorner = Instance.new("UICorner")
		colorBtnCorner.CornerRadius = UDim.new(0, 4)
		colorBtnCorner.Parent = colorBtn

		table.insert(
			self._connections,
			colorBtn.MouseButton1Click:Connect(function()
				self.SelectedColor = color
			end)
		)
	end

	-- Material selector
	local matLabel = Instance.new("TextLabel")
	matLabel.Size = UDim2.fromOffset(60, 16)
	matLabel.Position = UDim2.fromOffset(230, 0)
	matLabel.BackgroundTransparency = 1
	matLabel.Text = "Material"
	matLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
	matLabel.TextSize = 11
	matLabel.Font = Enum.Font.Gotham
	matLabel.TextXAlignment = Enum.TextXAlignment.Left
	matLabel.Parent = toolbar

	self:_buildMaterialButtons(toolbar)

	-- Action buttons
	local clearBtn = Instance.new("TextButton")
	clearBtn.Name = "ClearBtn"
	clearBtn.Size = UDim2.fromOffset(70, 30)
	clearBtn.Position = UDim2.new(1, -160, 0, 45)
	clearBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	clearBtn.Text = "Clear"
	clearBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
	clearBtn.TextSize = 13
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.Parent = toolbar

	local clearBtnCorner = Instance.new("UICorner")
	clearBtnCorner.CornerRadius = UDim.new(0, 6)
	clearBtnCorner.Parent = clearBtn

	local submitBtn = Instance.new("TextButton")
	submitBtn.Name = "SubmitBtn"
	submitBtn.Size = UDim2.fromOffset(80, 30)
	submitBtn.Position = UDim2.new(1, -80, 0, 45)
	submitBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 80)
	submitBtn.Text = "Bring to Life!"
	submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	submitBtn.TextSize = 13
	submitBtn.Font = Enum.Font.GothamBold
	submitBtn.Parent = toolbar

	local submitBtnCorner = Instance.new("UICorner")
	submitBtnCorner.CornerRadius = UDim.new(0, 6)
	submitBtnCorner.Parent = submitBtn

	-- Wire up canvas drawing
	table.insert(
		self._connections,
		canvas.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				self.IsDrawing = true
				self.CurrentPoints = {}
				local pos = input.Position
				local canvasPos = canvas.AbsolutePosition
				table.insert(self.CurrentPoints, {
					X = pos.X - canvasPos.X,
					Y = pos.Y - canvasPos.Y,
				})
			end
		end)
	)

	table.insert(
		self._connections,
		canvas.InputChanged:Connect(function(input)
			if not self.IsDrawing then
				return
			end
			if
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			then
				local pos = input.Position
				local canvasPos = canvas.AbsolutePosition
				local point: DrawingPoint = {
					X = pos.X - canvasPos.X,
					Y = pos.Y - canvasPos.Y,
				}
				table.insert(self.CurrentPoints, point)

				-- Draw line on canvas
				if #self.CurrentPoints >= 2 then
					local prev = self.CurrentPoints[#self.CurrentPoints - 1]
					self:_drawLine(prev, point)
				end
			end
		end)
	)

	table.insert(
		self._connections,
		UserInputService.InputEnded:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				if self.IsDrawing and #self.CurrentPoints >= 2 then
					local stroke: DrawingStroke = {
						Points = self.CurrentPoints,
						Color = self.SelectedColor,
						Thickness = self.SelectedThickness,
						Material = self.SelectedMaterial,
					}
					table.insert(self.CurrentStrokes, stroke)
				end
				self.IsDrawing = false
				self.CurrentPoints = {}
			end
		end)
	)

	-- Clear button
	table.insert(
		self._connections,
		clearBtn.MouseButton1Click:Connect(function()
			self:Clear()
		end)
	)

	-- Submit button
	table.insert(
		self._connections,
		submitBtn.MouseButton1Click:Connect(function()
			if #self.CurrentStrokes == 0 then
				return
			end

			local data: DrawingData = {
				Strokes = self.CurrentStrokes,
				Width = Constants.CANVAS_WIDTH,
				Height = Constants.CANVAS_HEIGHT,
			}

			if self.OnSubmit then
				self.OnSubmit(data)
			end

			self:Clear()
			self:Close()
		end)
	)

	-- Close button
	table.insert(
		self._connections,
		closeBtn.MouseButton1Click:Connect(function()
			self:Close()
		end)
	)
end

function DrawingCanvas._buildMaterialButtons(self: DrawingCanvasImpl, toolbar: Frame)
	for i, mat in self.AvailableMaterials do
		local matBtn = Instance.new("TextButton")
		matBtn.Name = `Mat_{mat}`
		matBtn.Size = UDim2.fromOffset(50, 22)
		matBtn.Position = UDim2.fromOffset(230 + ((i - 1) % 3) * 55, 18 + math.floor((i - 1) / 3) * 26)
		matBtn.BackgroundColor3 = MATERIAL_COLORS[mat] or Color3.fromRGB(150, 150, 150)
		matBtn.Text = mat
		matBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		matBtn.TextSize = 10
		matBtn.Font = Enum.Font.GothamBold
		matBtn.Parent = toolbar

		local matBtnCorner = Instance.new("UICorner")
		matBtnCorner.CornerRadius = UDim.new(0, 4)
		matBtnCorner.Parent = matBtn

		table.insert(
			self._connections,
			matBtn.MouseButton1Click:Connect(function()
				self.SelectedMaterial = mat
			end)
		)
	end
end

function DrawingCanvas._drawLine(self: DrawingCanvasImpl, from: DrawingPoint, to: DrawingPoint)
	local dx = to.X - from.X
	local dy = to.Y - from.Y
	local length = math.sqrt(dx * dx + dy * dy)

	if length < 1 then
		return
	end

	local angle = math.atan2(dy, dx)

	local line = Instance.new("Frame")
	line.Size = UDim2.fromOffset(length, self.SelectedThickness)
	line.Position = UDim2.fromOffset(from.X, from.Y - self.SelectedThickness / 2)
	line.Rotation = math.deg(angle)
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.BackgroundColor3 = self.SelectedColor
	line.BorderSizePixel = 0
	line.Parent = self.CanvasFrame

	table.insert(self.LineObjects, line)
end

function DrawingCanvas.SetAvailableMaterials(self: DrawingCanvasImpl, materials: { DrawingMaterial })
	self.AvailableMaterials = materials
	if self.SelectedMaterial and not table.find(materials, self.SelectedMaterial) then
		self.SelectedMaterial = materials[1] or "wood"
	end

	-- Rebuild material buttons
	local toolbar = self.ScreenGui:FindFirstChild("Container") :: Frame
	if toolbar then
		toolbar = toolbar:FindFirstChild("Toolbar") :: Frame
	end
	if toolbar then
		for _, child in toolbar:GetChildren() do
			if child.Name:sub(1, 4) == "Mat_" then
				child:Destroy()
			end
		end
		self:_buildMaterialButtons(toolbar)
	end
end

function DrawingCanvas.Open(self: DrawingCanvasImpl)
	self.IsOpen = true
	self.ScreenGui.Enabled = true
end

function DrawingCanvas.Close(self: DrawingCanvasImpl)
	self.IsOpen = false
	self.ScreenGui.Enabled = false
	self.IsDrawing = false
	if self.OnClose then
		self.OnClose()
	end
end

function DrawingCanvas.Clear(self: DrawingCanvasImpl)
	self.CurrentStrokes = {}
	self.CurrentPoints = {}
	self.IsDrawing = false

	for _, line in self.LineObjects do
		line:Destroy()
	end
	self.LineObjects = {}
end

function DrawingCanvas.Destroy(self: DrawingCanvasImpl)
	for _, conn in self._connections do
		conn:Disconnect()
	end
	self._connections = {}

	if self.ScreenGui.Parent then
		self.ScreenGui:Destroy()
	end
end

return DrawingCanvas
