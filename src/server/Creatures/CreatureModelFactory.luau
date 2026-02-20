--[[
	CreatureModelFactory.luau
	Creates placeholder creature models for testing.
	Each creature type gets a distinct color/shape so you can tell them apart.
	Replace with proper meshes/rigs later.
]]

local CreatureModelFactory = {}

-- Color map for creature types
local CREATURE_VISUALS = {
	-- Storm creatures
	thunder_crab = {
		bodySize = Vector3.new(2, 1, 2.5),
		bodyColor = Color3.fromRGB(255, 200, 50),
		material = Enum.Material.Neon,
		headSize = Vector3.new(0.8, 0.6, 0.8),
		label = "Thunder Crab",
	},
	wind_wraith = {
		bodySize = Vector3.new(2, 4, 1.5),
		bodyColor = Color3.fromRGB(200, 210, 240),
		material = Enum.Material.ForceField,
		headSize = Vector3.new(1.2, 1.2, 1.2),
		label = "Wind Wraith",
		floats = true,
	},
	fog_phantom = {
		bodySize = Vector3.new(2, 5, 1.5),
		bodyColor = Color3.fromRGB(150, 150, 170),
		material = Enum.Material.ForceField,
		headSize = Vector3.new(1, 1, 1),
		label = "Fog Phantom",
		transparency = 0.4,
	},
	frost_wolf = {
		bodySize = Vector3.new(3, 2, 4),
		bodyColor = Color3.fromRGB(180, 210, 240),
		material = Enum.Material.Ice,
		headSize = Vector3.new(1.5, 1.2, 1.5),
		label = "Frost Wolf",
	},
	storm_elemental = {
		bodySize = Vector3.new(4, 6, 4),
		bodyColor = Color3.fromRGB(100, 80, 120),
		material = Enum.Material.Neon,
		headSize = Vector3.new(2, 2, 2),
		label = "Storm Elemental",
	},
	tide_horror = {
		bodySize = Vector3.new(3, 2, 5),
		bodyColor = Color3.fromRGB(40, 80, 60),
		material = Enum.Material.Slate,
		headSize = Vector3.new(1.5, 1, 2),
		label = "Tide Horror",
	},
	blood_creature = {
		bodySize = Vector3.new(3, 4, 3),
		bodyColor = Color3.fromRGB(180, 30, 30),
		material = Enum.Material.Neon,
		headSize = Vector3.new(1.5, 1.5, 1.5),
		label = "Crimson Amalgam",
	},

	-- Zone creatures
	marsh_lurker = {
		bodySize = Vector3.new(4, 1.5, 5),
		bodyColor = Color3.fromRGB(60, 80, 40),
		material = Enum.Material.Slate,
		headSize = Vector3.new(2, 1, 2),
		label = "Marsh Lurker",
	},
	swamp_snake = {
		bodySize = Vector3.new(1, 0.5, 4),
		bodyColor = Color3.fromRGB(80, 120, 40),
		material = Enum.Material.SmoothPlastic,
		headSize = Vector3.new(0.6, 0.4, 0.6),
		label = "Swamp Snake",
	},
	rock_elemental = {
		bodySize = Vector3.new(5, 7, 5),
		bodyColor = Color3.fromRGB(140, 130, 120),
		material = Enum.Material.Slate,
		headSize = Vector3.new(2.5, 2, 2.5),
		label = "Rock Elemental",
	},
	cave_bat = {
		bodySize = Vector3.new(2, 0.8, 1),
		bodyColor = Color3.fromRGB(50, 40, 40),
		material = Enum.Material.SmoothPlastic,
		headSize = Vector3.new(0.5, 0.5, 0.5),
		label = "Cave Bat",
		floats = true,
	},
	giant_crab = {
		bodySize = Vector3.new(4, 2, 5),
		bodyColor = Color3.fromRGB(200, 80, 50),
		material = Enum.Material.SmoothPlastic,
		headSize = Vector3.new(2, 1.5, 2),
		label = "Giant Crab",
	},
	reef_shark = {
		bodySize = Vector3.new(2, 2, 6),
		bodyColor = Color3.fromRGB(100, 110, 130),
		material = Enum.Material.SmoothPlastic,
		headSize = Vector3.new(1.5, 1, 2),
		label = "Reef Shark",
	},
}

-- Default for unknown creature types
local DEFAULT_VISUAL = {
	bodySize = Vector3.new(2, 3, 2),
	bodyColor = Color3.fromRGB(200, 50, 50),
	material = Enum.Material.SmoothPlastic,
	headSize = Vector3.new(1, 1, 1),
	label = "Unknown Creature",
}

-- Create a placeholder creature model
function CreatureModelFactory.create(creatureConfigId: string, position: Vector3, creatureId: string): Model
	local visual = CREATURE_VISUALS[creatureConfigId] or DEFAULT_VISUAL

	local model = Instance.new("Model")
	model.Name = "Creature_" .. creatureId

	-- Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = visual.bodySize
	body.Color = visual.bodyColor
	body.Material = visual.material
	body.Anchored = true
	body.CanCollide = true

	local heightOffset = visual.bodySize.Y / 2
	if visual.floats then
		heightOffset = heightOffset + 5
	end

	body.Position = position + Vector3.new(0, heightOffset, 0)
	body.Transparency = visual.transparency or 0
	body:SetAttribute("CreatureId", creatureId)
	body:SetAttribute("InteractType", "Creature")
	body.Parent = model

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = visual.headSize
	head.Color = visual.bodyColor
	head.Material = visual.material
	head.Anchored = true
	head.CanCollide = false
	head.Position = body.Position + Vector3.new(0, visual.bodySize.Y / 2 + visual.headSize.Y / 2, visual.bodySize.Z / 2 - 0.5)
	head.Transparency = visual.transparency or 0
	head.Parent = model

	-- Eyes (two small red dots)
	for i, xOffset in { -0.3, 0.3 } do
		local eye = Instance.new("Part")
		eye.Name = "Eye_" .. i
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.2, 0.2, 0.2)
		eye.Color = Color3.fromRGB(255, 0, 0)
		eye.Material = Enum.Material.Neon
		eye.Anchored = true
		eye.CanCollide = false
		eye.Position = head.Position + Vector3.new(xOffset, 0.1, visual.headSize.Z / 2 - 0.1)
		eye.Parent = model
	end

	-- Name label
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, visual.bodySize.Y + 2, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 40
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = visual.label
	nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent = billboard

	-- Health bar background
	local healthBg = Instance.new("Frame")
	healthBg.Name = "HealthBg"
	healthBg.Size = UDim2.new(0.8, 0, 0.2, 0)
	healthBg.Position = UDim2.new(0.1, 0, 0.65, 0)
	healthBg.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = billboard

	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = healthBg

	model.PrimaryPart = body
	model.Parent = workspace

	return model
end

-- Update creature model position (called from game loop)
function CreatureModelFactory.updatePosition(model: Model, newPosition: Vector3)
	if not model or not model.PrimaryPart then return end

	local visual = CREATURE_VISUALS[model:GetAttribute("ConfigId")] or DEFAULT_VISUAL
	local heightOffset = model.PrimaryPart.Size.Y / 2

	-- Move all parts relative to body
	local offset = (newPosition + Vector3.new(0, heightOffset, 0)) - model.PrimaryPart.Position
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Position = part.Position + offset
		end
	end
end

-- Update health bar on creature model
function CreatureModelFactory.updateHealthBar(model: Model, currentHP: number, maxHP: number)
	if not model then return end

	local body = model:FindFirstChild("Body")
	if not body then return end

	local billboard = body:FindFirstChildOfClass("BillboardGui")
	if not billboard then return end

	local healthBg = billboard:FindFirstChild("HealthBg")
	if not healthBg then return end

	local healthBar = healthBg:FindFirstChild("HealthBar")
	if not healthBar then return end

	local ratio = math.clamp(currentHP / math.max(maxHP, 1), 0, 1)
	healthBar.Size = UDim2.new(ratio, 0, 1, 0)

	-- Color: green -> yellow -> red
	if ratio > 0.5 then
		healthBar.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
	elseif ratio > 0.25 then
		healthBar.BackgroundColor3 = Color3.fromRGB(220, 180, 40)
	else
		healthBar.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
	end
end

-- Destroy a creature model (death animation placeholder)
function CreatureModelFactory.destroy(model: Model)
	if not model then return end

	-- Simple fade out
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			-- Quick fade
			task.spawn(function()
				for i = 0, 10 do
					part.Transparency = i / 10
					task.wait(0.1)
				end
			end)
		end
	end

	-- Remove after fade
	task.delay(1.5, function()
		if model and model.Parent then
			model:Destroy()
		end
	end)
end

return CreatureModelFactory
