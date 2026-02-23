--!strict

--[[
	EnemyAI
	Simple AI for enemies like the paper bear in Stage 9.
	Patrols between points, chases players who get close,
	and can be distracted by drawings.
]]

local RunService = game:GetService("RunService")

local EnemyAI = {}
EnemyAI.__index = EnemyAI

type EnemyInstance = {
	Model: Model,
	Body: Part,
	Type: string,
	PatrolA: Vector3,
	PatrolB: Vector3,
	Speed: number,
	DetectRange: number,
	KillRange: number,
	CurrentTarget: Vector3,
	GoingToB: boolean,
	IsChasing: boolean,
	DistractedUntil: number,
}

type EnemyAIImpl = {
	Enemies: { EnemyInstance },
	EnemiesFolder: Folder,
	_heartbeatConn: RBXScriptConnection?,
	OnPlayerTouched: ((Player) -> ())?,
}

local ENEMY_CONFIGS = {
	bear = {
		Speed = 12,
		DetectRange = 20,
		KillRange = 4,
		BodySize = Vector3.new(4, 5, 6),
		Color = Color3.fromRGB(160, 120, 80),
	},
	sentry = {
		Speed = 0,
		DetectRange = 30,
		KillRange = 2,
		BodySize = Vector3.new(3, 6, 3),
		Color = Color3.fromRGB(100, 100, 110),
	},
	eraser = {
		Speed = 15,
		DetectRange = 25,
		KillRange = 3,
		BodySize = Vector3.new(3, 4, 3),
		Color = Color3.fromRGB(255, 200, 200),
	},
}

function EnemyAI.new(): EnemyAIImpl
	local self = setmetatable({}, EnemyAI) :: any

	self.Enemies = {}
	self.OnPlayerTouched = nil

	local folder = Instance.new("Folder")
	folder.Name = "Enemies"
	folder.Parent = workspace
	self.EnemiesFolder = folder

	return self :: EnemyAIImpl
end

function EnemyAI.SpawnEnemy(
	self: EnemyAIImpl,
	enemyType: string,
	position: Vector3,
	patrolA: Vector3,
	patrolB: Vector3
): EnemyInstance
	local config = ENEMY_CONFIGS[enemyType] or ENEMY_CONFIGS.bear

	local model = Instance.new("Model")
	model.Name = `Enemy_{enemyType}`

	-- Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = config.BodySize
	body.Position = position
	body.Anchored = true
	body.CanCollide = true
	body.Material = Enum.Material.SmoothPlastic
	body.Color = config.Color
	body.Parent = model

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(config.BodySize.X * 0.7, config.BodySize.X * 0.7, config.BodySize.X * 0.7)
	head.Position = position + Vector3.new(0, config.BodySize.Y / 2 + config.BodySize.X * 0.35, config.BodySize.Z * 0.3)
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = config.Color
	head.Shape = Enum.PartType.Ball
	head.Parent = model

	-- Eyes (menacing red dots)
	for _, side in { -1, 1 } do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.4, 0.4, 0.4)
		eye.Position = head.Position + Vector3.new(side * 0.5, 0.2, config.BodySize.X * 0.3)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Material = Enum.Material.Neon
		eye.Color = Color3.fromRGB(255, 0, 0)
		eye.Shape = Enum.PartType.Ball
		eye.Parent = model
	end

	model.PrimaryPart = body
	model.Parent = self.EnemiesFolder

	-- Touch detection for kills
	body.Touched:Connect(function(hit)
		local character = hit.Parent
		if character then
			local player = game:GetService("Players"):GetPlayerFromCharacter(character)
			if player and self.OnPlayerTouched then
				self.OnPlayerTouched(player)
			end
		end
	end)

	local enemy: EnemyInstance = {
		Model = model,
		Body = body,
		Type = enemyType,
		PatrolA = patrolA,
		PatrolB = patrolB,
		Speed = config.Speed,
		DetectRange = config.DetectRange,
		KillRange = config.KillRange,
		CurrentTarget = patrolB,
		GoingToB = true,
		IsChasing = false,
		DistractedUntil = 0,
	}

	table.insert(self.Enemies, enemy)
	return enemy
end

function EnemyAI.StartAI(self: EnemyAIImpl)
	self._heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		self:_updateEnemies(dt)
	end)
end

function EnemyAI._updateEnemies(self: EnemyAIImpl, dt: number)
	local now = tick()

	for _, enemy in self.Enemies do
		if not enemy.Model.Parent or not enemy.Body.Parent then
			continue
		end

		-- Skip if distracted
		if now < enemy.DistractedUntil then
			continue
		end

		-- Check for nearby players
		local closestPlayer: Player? = nil
		local closestDist = enemy.DetectRange

		for _, player in game:GetService("Players"):GetPlayers() do
			local character = player.Character
			if character then
				local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if rootPart then
					local dist = (rootPart.Position - enemy.Body.Position).Magnitude
					if dist < closestDist then
						closestDist = dist
						closestPlayer = player
					end
				end
			end
		end

		-- Move toward target
		local targetPos: Vector3
		if closestPlayer and closestPlayer.Character then
			local rootPart = closestPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				targetPos = rootPart.Position
				enemy.IsChasing = true
			else
				targetPos = enemy.CurrentTarget
				enemy.IsChasing = false
			end
		else
			-- Patrol
			enemy.IsChasing = false
			targetPos = enemy.CurrentTarget

			local distToTarget = (Vector3.new(targetPos.X, enemy.Body.Position.Y, targetPos.Z) - enemy.Body.Position).Magnitude
			if distToTarget < 2 then
				enemy.GoingToB = not enemy.GoingToB
				enemy.CurrentTarget = if enemy.GoingToB then enemy.PatrolB else enemy.PatrolA
				targetPos = enemy.CurrentTarget
			end
		end

		if enemy.Speed > 0 then
			local direction = (Vector3.new(targetPos.X, enemy.Body.Position.Y, targetPos.Z) - enemy.Body.Position)
			if direction.Magnitude > 0.5 then
				direction = direction.Unit
				local movement = direction * enemy.Speed * dt
				local newPos = enemy.Body.Position + movement

				-- Move all parts in the model
				local offset = newPos - enemy.Body.Position
				for _, part in enemy.Model:GetDescendants() do
					if part:IsA("BasePart") then
						part.Position = part.Position + offset
					end
				end
			end
		end
	end
end

function EnemyAI.DistractEnemy(self: EnemyAIImpl, enemyIndex: number, duration: number)
	if self.Enemies[enemyIndex] then
		self.Enemies[enemyIndex].DistractedUntil = tick() + duration
	end
end

function EnemyAI.ClearEnemies(self: EnemyAIImpl)
	for _, enemy in self.Enemies do
		if enemy.Model.Parent then
			enemy.Model:Destroy()
		end
	end
	self.Enemies = {}
end

function EnemyAI.Destroy(self: EnemyAIImpl)
	if self._heartbeatConn then
		self._heartbeatConn:Disconnect()
		self._heartbeatConn = nil
	end
	self:ClearEnemies()
	if self.EnemiesFolder.Parent then
		self.EnemiesFolder:Destroy()
	end
end

return EnemyAI
