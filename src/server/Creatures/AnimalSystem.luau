--[[
	AnimalSystem.luau
	Handles huntable animals (rabbits, deer, boars) that roam the map.
	Animals flee when attacked (except boars which charge).
	Drop raw_meat and leather on death.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local AnimalSystem = {}
AnimalSystem.__index = AnimalSystem

function AnimalSystem.new()
	local self = setmetatable({}, AnimalSystem)

	self.animals = {} -- id -> animal state
	self.spawnPoints = {} -- configId -> { positions }
	self.nextId = 1
	self.respawnQueue = {} -- { configId, spawnPos, respawnAt }

	return self
end

-- Register a spawn point for an animal type
function AnimalSystem:registerSpawnPoint(configId: string, position: Vector3)
	if not self.spawnPoints[configId] then
		self.spawnPoints[configId] = {}
	end
	table.insert(self.spawnPoints[configId], position)
end

-- Spawn initial animals at all registered spawn points
function AnimalSystem:spawnAll()
	for configId, positions in self.spawnPoints do
		for _, pos in positions do
			self:spawnAnimal(configId, pos)
		end
	end
end

-- Spawn a single animal
function AnimalSystem:spawnAnimal(configId: string, position: Vector3): number?
	local config = nil
	for _, animal in GameConfig.ANIMALS do
		if animal.id == configId then
			config = animal
			break
		end
	end
	if not config then return nil end

	local id = self.nextId
	self.nextId += 1

	self.animals[id] = {
		id = id,
		configId = configId,
		name = config.name,
		hp = config.hp,
		maxHP = config.hp,
		position = position,
		spawnPosition = position,
		isAlive = true,
		speed = config.speed,
		fleeRange = config.fleeRange,
		aggressive = config.aggressive or false,
		damage = config.damage or 0,
		drops = config.drops,
		size = config.size,
		color = config.color,
		respawnTime = config.respawnTime,
		-- AI state
		aiState = "idle", -- idle, fleeing, charging
		aiTarget = nil, -- position to move toward
		aiTimer = 0,
		wanderTimer = math.random(3, 8),
	}

	return id
end

-- Create a visual model for an animal
function AnimalSystem:createModel(animalId: number, parent: Instance): Instance?
	local animal = self.animals[animalId]
	if not animal then return nil end

	local model = Instance.new("Model")
	model.Name = "Animal_" .. animal.configId .. "_" .. animalId

	-- Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = animal.size
	body.Color = animal.color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.Position = animal.position + Vector3.new(0, animal.size.Y / 2, 0)
	body:SetAttribute("InteractType", "Animal")
	body:SetAttribute("AnimalId", animalId)
	body.Parent = model

	-- Head (smaller sphere)
	local headSize = animal.size.Y * 0.6
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(headSize, headSize, headSize)
	head.Color = animal.color
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Position = animal.position + Vector3.new(animal.size.X / 2, animal.size.Y * 0.6, 0)
	head.Parent = model

	-- Name billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 120, 0, 30)
	billboard.StudsOffset = Vector3.new(0, animal.size.Y + 1, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 40
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = animal.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Parent = billboard

	-- HP bar background
	local hpBg = Instance.new("Frame")
	hpBg.Name = "HPBarBg"
	hpBg.Size = UDim2.new(0.8, 0, 0.3, 0)
	hpBg.Position = UDim2.new(0.1, 0, 0.55, 0)
	hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	hpBg.BorderSizePixel = 0
	hpBg.Parent = billboard

	local hpFill = Instance.new("Frame")
	hpFill.Name = "HPBarFill"
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg

	model.PrimaryPart = body
	model.Parent = parent

	return model
end

-- Update model position
function AnimalSystem:updateModel(model: Instance, animalId: number)
	local animal = self.animals[animalId]
	if not animal or not model then return end

	local body = model:FindFirstChild("Body")
	if body then
		body.Position = animal.position + Vector3.new(0, animal.size.Y / 2, 0)
	end

	local head = model:FindFirstChild("Head")
	if head then
		head.Position = animal.position + Vector3.new(animal.size.X / 2, animal.size.Y * 0.6, 0)
	end

	-- Update HP bar
	local billboard = body and body:FindFirstChildOfClass("BillboardGui")
	if billboard then
		local hpBg = billboard:FindFirstChild("HPBarBg")
		if hpBg then
			local hpFill = hpBg:FindFirstChild("HPBarFill")
			if hpFill then
				local ratio = animal.hp / animal.maxHP
				hpFill.Size = UDim2.new(math.max(0, ratio), 0, 1, 0)
				if ratio > 0.5 then
					hpFill.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
				elseif ratio > 0.25 then
					hpFill.BackgroundColor3 = Color3.fromRGB(200, 200, 60)
				else
					hpFill.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
				end
			end
		end
	end
end

-- Deal damage to an animal. Returns drops if killed.
function AnimalSystem:damageAnimal(animalId: number, amount: number, attackerPos: Vector3?): (boolean, { { string | number } }?)
	local animal = self.animals[animalId]
	if not animal or not animal.isAlive then return false, nil end

	animal.hp = math.max(0, animal.hp - amount)

	if animal.hp <= 0 then
		-- Animal killed
		animal.isAlive = false

		-- Queue respawn
		table.insert(self.respawnQueue, {
			configId = animal.configId,
			spawnPos = animal.spawnPosition,
			respawnAt = tick() + animal.respawnTime,
		})

		-- Return drops
		local drops = {}
		for _, drop in animal.drops do
			local qty = math.random(drop.min, drop.max)
			if qty > 0 then
				table.insert(drops, { drop.id, qty })
			end
		end

		return true, drops
	end

	-- Not dead — trigger flee or charge behavior
	if animal.aggressive and attackerPos then
		animal.aiState = "charging"
		animal.aiTarget = attackerPos
		animal.aiTimer = 5
	elseif animal.fleeRange > 0 and attackerPos then
		-- Flee away from attacker
		local fleeDir = (animal.position - attackerPos)
		if fleeDir.Magnitude > 0 then
			fleeDir = fleeDir.Unit
		else
			fleeDir = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
		end
		animal.aiState = "fleeing"
		animal.aiTarget = animal.position + fleeDir * animal.fleeRange
		animal.aiTimer = 4
	end

	return false, nil
end

-- Update all animals (call from Heartbeat)
function AnimalSystem:update(deltaTime: number)
	-- Update live animals
	for id, animal in self.animals do
		if animal.isAlive then
			self:updateAnimalAI(animal, deltaTime)
		end
	end

	-- Process respawn queue
	local now = tick()
	local remaining = {}
	for _, entry in self.respawnQueue do
		if now >= entry.respawnAt then
			-- Respawn at original position
			self:spawnAnimal(entry.configId, entry.spawnPos)
		else
			table.insert(remaining, entry)
		end
	end
	self.respawnQueue = remaining

	-- Clean up dead animals
	for id, animal in self.animals do
		if not animal.isAlive then
			self.animals[id] = nil
		end
	end
end

function AnimalSystem:updateAnimalAI(animal, deltaTime: number)
	if animal.aiState == "idle" then
		animal.wanderTimer -= deltaTime
		if animal.wanderTimer <= 0 then
			-- Random wander near spawn
			local angle = math.random() * math.pi * 2
			local dist = math.random(5, 15)
			animal.aiTarget = animal.spawnPosition + Vector3.new(
				math.cos(angle) * dist, 0, math.sin(angle) * dist
			)
			animal.aiState = "wandering"
			animal.aiTimer = 3
			animal.wanderTimer = math.random(5, 12)
		end

	elseif animal.aiState == "wandering" then
		animal.aiTimer -= deltaTime
		if animal.aiTimer <= 0 or not animal.aiTarget then
			animal.aiState = "idle"
		else
			local dir = animal.aiTarget - animal.position
			dir = Vector3.new(dir.X, 0, dir.Z)
			if dir.Magnitude > 1 then
				local moveSpeed = animal.speed * 0.5 -- wander is slower
				animal.position = animal.position + dir.Unit * moveSpeed * deltaTime
			else
				animal.aiState = "idle"
			end
		end

	elseif animal.aiState == "fleeing" then
		animal.aiTimer -= deltaTime
		if animal.aiTimer <= 0 or not animal.aiTarget then
			animal.aiState = "idle"
		else
			local dir = animal.aiTarget - animal.position
			dir = Vector3.new(dir.X, 0, dir.Z)
			if dir.Magnitude > 2 then
				animal.position = animal.position + dir.Unit * animal.speed * deltaTime
			else
				animal.aiState = "idle"
			end
		end

	elseif animal.aiState == "charging" then
		animal.aiTimer -= deltaTime
		if animal.aiTimer <= 0 or not animal.aiTarget then
			animal.aiState = "idle"
		else
			local dir = animal.aiTarget - animal.position
			dir = Vector3.new(dir.X, 0, dir.Z)
			if dir.Magnitude > 2 then
				animal.position = animal.position + dir.Unit * animal.speed * 1.2 * deltaTime
			else
				-- Reached target, deal damage to nearby players
				animal.aiState = "idle"
			end
		end
	end
end

-- Get animal for checking attack range
function AnimalSystem:getAnimal(animalId: number)
	return self.animals[animalId]
end

-- Check if an aggressive animal is near a player position and should attack
function AnimalSystem:getAggressiveNearby(position: Vector3, range: number): number?
	for id, animal in self.animals do
		if animal.isAlive and animal.aggressive and animal.aiState == "charging" then
			local dist = (animal.position - position).Magnitude
			if dist < range then
				return id
			end
		end
	end
	return nil
end

-- Remove all animals (for cleanup)
function AnimalSystem:despawnAll()
	self.animals = {}
	self.respawnQueue = {}
end

return AnimalSystem
