--[[
	CreatureModelFactory.luau
	Creates enhanced creature models with distinct silhouettes, glowing effects,
	limbs, particle auras, and death/hit animations.
	Each creature type is visually distinct and recognizable.
]]

local TweenService = game:GetService("TweenService")

local CreatureModelFactory = {}

-- Color map for creature types with enhanced details
local CREATURE_VISUALS = {
	-- Storm creatures
	thunder_crab = {
		bodySize = Vector3.new(2.5, 1.2, 3),
		bodyColor = Color3.fromRGB(255, 200, 50),
		material = Enum.Material.Neon,
		headSize = Vector3.new(0.8, 0.6, 0.8),
		label = "Thunder Crab",
		auraColor = Color3.fromRGB(255, 255, 100),
		legs = { count = 6, size = Vector3.new(0.3, 0.15, 1.5), color = Color3.fromRGB(200, 160, 40) },
		claws = true,
	},
	wind_wraith = {
		bodySize = Vector3.new(2, 4, 1.5),
		bodyColor = Color3.fromRGB(200, 210, 240),
		material = Enum.Material.ForceField,
		headSize = Vector3.new(1.2, 1.2, 1.2),
		label = "Wind Wraith",
		floats = true,
		auraColor = Color3.fromRGB(180, 200, 255),
		ghostTrail = true,
	},
	fog_phantom = {
		bodySize = Vector3.new(2, 5, 1.5),
		bodyColor = Color3.fromRGB(150, 150, 170),
		material = Enum.Material.ForceField,
		headSize = Vector3.new(1, 1, 1),
		label = "Fog Phantom",
		transparency = 0.4,
		auraColor = Color3.fromRGB(180, 180, 200),
		ghostTrail = true,
	},
	frost_wolf = {
		bodySize = Vector3.new(3, 2, 4),
		bodyColor = Color3.fromRGB(180, 210, 240),
		material = Enum.Material.Ice,
		headSize = Vector3.new(1.5, 1.2, 1.8),
		label = "Frost Wolf",
		auraColor = Color3.fromRGB(150, 200, 255),
		legs = { count = 4, size = Vector3.new(0.4, 1.5, 0.4), color = Color3.fromRGB(160, 190, 220) },
		tail = true,
	},
	storm_elemental = {
		bodySize = Vector3.new(4, 6, 4),
		bodyColor = Color3.fromRGB(100, 80, 120),
		material = Enum.Material.Neon,
		headSize = Vector3.new(2, 2, 2),
		label = "Storm Elemental",
		auraColor = Color3.fromRGB(130, 100, 200),
		arms = { size = Vector3.new(1, 4, 1), color = Color3.fromRGB(120, 100, 160) },
		electricSparks = true,
	},
	tide_horror = {
		bodySize = Vector3.new(3, 2, 5),
		bodyColor = Color3.fromRGB(40, 80, 60),
		material = Enum.Material.Slate,
		headSize = Vector3.new(1.5, 1, 2),
		label = "Tide Horror",
		tentacles = { count = 4, size = Vector3.new(0.4, 0.4, 3), color = Color3.fromRGB(30, 60, 50) },
		auraColor = Color3.fromRGB(40, 100, 80),
	},
	blood_creature = {
		bodySize = Vector3.new(3, 4, 3),
		bodyColor = Color3.fromRGB(180, 30, 30),
		material = Enum.Material.Neon,
		headSize = Vector3.new(1.5, 1.5, 1.5),
		label = "Crimson Amalgam",
		auraColor = Color3.fromRGB(255, 50, 50),
		drippingEffect = true,
	},

	-- Zone creatures
	marsh_lurker = {
		bodySize = Vector3.new(4, 1.5, 5),
		bodyColor = Color3.fromRGB(60, 80, 40),
		material = Enum.Material.Slate,
		headSize = Vector3.new(2, 1, 2),
		label = "Marsh Lurker",
		auraColor = Color3.fromRGB(80, 120, 60),
		legs = { count = 6, size = Vector3.new(0.4, 0.2, 2), color = Color3.fromRGB(50, 70, 35) },
	},
	swamp_snake = {
		bodySize = Vector3.new(1, 0.5, 4),
		bodyColor = Color3.fromRGB(80, 120, 40),
		material = Enum.Material.SmoothPlastic,
		headSize = Vector3.new(0.6, 0.4, 0.6),
		label = "Swamp Snake",
		segments = { count = 3, size = Vector3.new(0.8, 0.4, 1.2), color = Color3.fromRGB(70, 110, 35) },
	},
	rock_elemental = {
		bodySize = Vector3.new(5, 7, 5),
		bodyColor = Color3.fromRGB(140, 130, 120),
		material = Enum.Material.Slate,
		headSize = Vector3.new(2.5, 2, 2.5),
		label = "Rock Elemental",
		arms = { size = Vector3.new(1.5, 5, 1.5), color = Color3.fromRGB(120, 110, 100) },
		auraColor = Color3.fromRGB(160, 150, 140),
	},
	cave_bat = {
		bodySize = Vector3.new(2, 0.8, 1),
		bodyColor = Color3.fromRGB(50, 40, 40),
		material = Enum.Material.SmoothPlastic,
		headSize = Vector3.new(0.5, 0.5, 0.5),
		label = "Cave Bat",
		floats = true,
		wings = { span = 4, color = Color3.fromRGB(60, 50, 50) },
	},
	giant_crab = {
		bodySize = Vector3.new(4, 2, 5),
		bodyColor = Color3.fromRGB(200, 80, 50),
		material = Enum.Material.SmoothPlastic,
		headSize = Vector3.new(2, 1.5, 2),
		label = "Giant Crab",
		legs = { count = 8, size = Vector3.new(0.4, 0.2, 2), color = Color3.fromRGB(180, 70, 45) },
		claws = true,
	},
	reef_shark = {
		bodySize = Vector3.new(2, 2, 6),
		bodyColor = Color3.fromRGB(100, 110, 130),
		material = Enum.Material.SmoothPlastic,
		headSize = Vector3.new(1.5, 1, 2),
		label = "Reef Shark",
		fin = true,
		tail = true,
	},
}

local DEFAULT_VISUAL = {
	bodySize = Vector3.new(2, 3, 2),
	bodyColor = Color3.fromRGB(200, 50, 50),
	material = Enum.Material.SmoothPlastic,
	headSize = Vector3.new(1, 1, 1),
	label = "Unknown Creature",
}

-- ================================
-- HELPER: add an aura particle effect
-- ================================
local function addAura(parent, color, rate)
	local aura = Instance.new("ParticleEmitter")
	aura.Name = "Aura"
	aura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	aura.Color = ColorSequence.new(color)
	aura.Size = NumberSequence.new(0.2, 0)
	aura.Lifetime = NumberRange.new(0.5, 1.0)
	aura.Rate = rate or 10
	aura.Speed = NumberRange.new(1, 3)
	aura.SpreadAngle = Vector2.new(180, 180)
	aura.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	aura.LightEmission = 0.5
	aura.EmissionDirection = Enum.NormalId.Top
	aura.Parent = parent
	return aura
end

-- ================================
-- HELPER: add ghost/smoke trail
-- ================================
local function addGhostTrail(parent, color)
	local trail = Instance.new("ParticleEmitter")
	trail.Name = "GhostTrail"
	trail.Texture = "rbxasset://textures/particles/smoke_main.dds"
	trail.Color = ColorSequence.new(color or Color3.fromRGB(180, 180, 200))
	trail.Size = NumberSequence.new(2, 4)
	trail.Lifetime = NumberRange.new(1, 2)
	trail.Rate = 8
	trail.Speed = NumberRange.new(0, 1)
	trail.SpreadAngle = Vector2.new(180, 180)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.RotSpeed = NumberRange.new(-30, 30)
	trail.Rotation = NumberRange.new(0, 360)
	trail.EmissionDirection = Enum.NormalId.Bottom
	trail.Parent = parent
	return trail
end

-- ================================
-- HELPER: add electric sparks
-- ================================
local function addElectricSparks(parent)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "ElectricSparks"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 150, 255)),
	})
	sparks.Size = NumberSequence.new(0.1, 0.05)
	sparks.Lifetime = NumberRange.new(0.1, 0.3)
	sparks.Rate = 20
	sparks.Speed = NumberRange.new(10, 30)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Transparency = NumberSequence.new(0, 0.5)
	sparks.LightEmission = 1
	sparks.EmissionDirection = Enum.NormalId.Top
	sparks.Parent = parent

	-- Point light for glow
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(130, 170, 255)
	light.Brightness = 1
	light.Range = 12
	light.Parent = parent

	return sparks
end

-- ================================
-- HELPER: add dripping blood/slime effect
-- ================================
local function addDrippingEffect(parent, color)
	local drip = Instance.new("ParticleEmitter")
	drip.Name = "Drip"
	drip.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	drip.Color = ColorSequence.new(color or Color3.fromRGB(180, 20, 20))
	drip.Size = NumberSequence.new(0.15, 0.05)
	drip.Lifetime = NumberRange.new(0.5, 1.5)
	drip.Rate = 12
	drip.Speed = NumberRange.new(0, 2)
	drip.SpreadAngle = Vector2.new(20, 20)
	drip.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.8),
	})
	drip.Acceleration = Vector3.new(0, -20, 0)
	drip.EmissionDirection = Enum.NormalId.Bottom
	drip.Parent = parent
	return drip
end

-- ================================
-- CREATE MODEL
-- ================================

function CreatureModelFactory.create(creatureConfigId: string, position: Vector3, creatureId: string): Model
	local visual = CREATURE_VISUALS[creatureConfigId] or DEFAULT_VISUAL

	local model = Instance.new("Model")
	model.Name = "Creature_" .. creatureId
	model:SetAttribute("ConfigId", creatureConfigId)

	local heightOffset = visual.bodySize.Y / 2
	if visual.floats then
		heightOffset = heightOffset + 5
	end

	local bodyPos = position + Vector3.new(0, heightOffset, 0)

	-- Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = visual.bodySize
	body.Color = visual.bodyColor
	body.Material = visual.material
	body.Anchored = true
	body.CanCollide = true
	body.Position = bodyPos
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
	head.Position = bodyPos + Vector3.new(0, visual.bodySize.Y / 2 + visual.headSize.Y / 2, visual.bodySize.Z / 2 - 0.5)
	head.Transparency = visual.transparency or 0
	head.Parent = model

	-- Eyes (glowing)
	local eyeSpacing = visual.headSize.X * 0.3
	for i, xOffset in { -eyeSpacing, eyeSpacing } do
		local eye = Instance.new("Part")
		eye.Name = "Eye_" .. i
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.25, 0.25, 0.25)
		eye.Color = Color3.fromRGB(255, 50, 0)
		eye.Material = Enum.Material.Neon
		eye.Anchored = true
		eye.CanCollide = false
		eye.Position = head.Position + Vector3.new(xOffset, 0.1, visual.headSize.Z / 2 - 0.1)
		eye.Parent = model

		-- Glow on eyes
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(255, 50, 0)
		glow.Brightness = 0.5
		glow.Range = 4
		glow.Parent = eye
	end

	-- ====== APPENDAGES ======

	-- Legs
	if visual.legs then
		local legCfg = visual.legs
		for i = 1, legCfg.count do
			local side = (i % 2 == 0) and 1 or -1
			local along = (math.ceil(i / 2) - 1) / math.max(math.ceil(legCfg.count / 2) - 1, 1)
			local zPos = (along - 0.5) * visual.bodySize.Z * 0.8

			local leg = Instance.new("Part")
			leg.Name = "Leg_" .. i
			leg.Size = legCfg.size
			leg.Color = legCfg.color
			leg.Material = visual.material
			leg.Anchored = true
			leg.CanCollide = false
			leg.Position = bodyPos + Vector3.new(
				side * (visual.bodySize.X / 2 + legCfg.size.X / 2),
				-visual.bodySize.Y / 2 + legCfg.size.Y / 2,
				zPos)
			leg.Orientation = Vector3.new(0, side * 30, 0)
			leg.Parent = model
		end
	end

	-- Arms (humanoid creatures)
	if visual.arms then
		local armCfg = visual.arms
		for i, side in { -1, 1 } do
			local arm = Instance.new("Part")
			arm.Name = "Arm_" .. i
			arm.Size = armCfg.size
			arm.Color = armCfg.color
			arm.Material = visual.material
			arm.Anchored = true
			arm.CanCollide = false
			arm.Position = bodyPos + Vector3.new(
				side * (visual.bodySize.X / 2 + armCfg.size.X / 2),
				visual.bodySize.Y * 0.2,
				0)
			arm.Orientation = Vector3.new(0, 0, side * 15)
			arm.Parent = model
		end
	end

	-- Claws (for crabs)
	if visual.claws then
		for i, side in { -1, 1 } do
			local claw = Instance.new("Part")
			claw.Name = "Claw_" .. i
			claw.Size = Vector3.new(1.2, 0.8, 1.5)
			claw.Color = visual.bodyColor
			claw.Material = visual.material
			claw.Anchored = true
			claw.CanCollide = false
			claw.Position = bodyPos + Vector3.new(
				side * (visual.bodySize.X / 2 + 1),
				0.3,
				visual.bodySize.Z / 2)
			claw.Orientation = Vector3.new(0, side * -20, 0)
			claw.Parent = model
		end
	end

	-- Tentacles (for tide horror)
	if visual.tentacles then
		local tentCfg = visual.tentacles
		for i = 1, tentCfg.count do
			local angle = (i / tentCfg.count) * math.pi * 2
			local tentacle = Instance.new("Part")
			tentacle.Name = "Tentacle_" .. i
			tentacle.Size = tentCfg.size
			tentacle.Color = tentCfg.color
			tentacle.Material = visual.material
			tentacle.Anchored = true
			tentacle.CanCollide = false
			tentacle.Position = bodyPos + Vector3.new(
				math.cos(angle) * visual.bodySize.X * 0.4,
				-visual.bodySize.Y / 2,
				math.sin(angle) * visual.bodySize.Z * 0.4)
			tentacle.Orientation = Vector3.new(
				30 + math.random(-10, 10),
				math.deg(angle),
				0)
			tentacle.Parent = model
		end
	end

	-- Snake segments
	if visual.segments then
		local segCfg = visual.segments
		for i = 1, segCfg.count do
			local seg = Instance.new("Part")
			seg.Name = "Segment_" .. i
			seg.Size = segCfg.size * (1 - i * 0.15)
			seg.Color = segCfg.color
			seg.Material = visual.material
			seg.Anchored = true
			seg.CanCollide = false
			seg.Position = bodyPos + Vector3.new(0, 0, -visual.bodySize.Z / 2 - i * segCfg.size.Z * 0.8)
			seg.Parent = model
		end
	end

	-- Wings (for bats)
	if visual.wings then
		local wingCfg = visual.wings
		for i, side in { -1, 1 } do
			local wing = Instance.new("Part")
			wing.Name = "Wing_" .. i
			wing.Size = Vector3.new(wingCfg.span / 2, 0.1, 1.5)
			wing.Color = wingCfg.color
			wing.Material = visual.material
			wing.Anchored = true
			wing.CanCollide = false
			wing.Position = bodyPos + Vector3.new(
				side * (visual.bodySize.X / 2 + wingCfg.span / 4),
				0.2,
				0)
			wing.Orientation = Vector3.new(0, 0, side * 10)
			wing.Transparency = 0.2
			wing.Parent = model
		end
	end

	-- Fin (for sharks)
	if visual.fin then
		local fin = Instance.new("WedgePart")
		fin.Name = "DorsalFin"
		fin.Size = Vector3.new(0.3, 1.5, 1.5)
		fin.Color = visual.bodyColor
		fin.Material = visual.material
		fin.Anchored = true
		fin.CanCollide = false
		fin.CFrame = CFrame.new(bodyPos + Vector3.new(0, visual.bodySize.Y / 2 + 0.5, 0))
		fin.Parent = model
	end

	-- Tail
	if visual.tail then
		local tail = Instance.new("WedgePart")
		tail.Name = "Tail"
		tail.Size = Vector3.new(0.8, 1, 2)
		tail.Color = visual.bodyColor
		tail.Material = visual.material
		tail.Anchored = true
		tail.CanCollide = false
		tail.CFrame = CFrame.new(
			bodyPos + Vector3.new(0, -0.2, -visual.bodySize.Z / 2 - 1)
		) * CFrame.Angles(0, math.rad(180), 0)
		tail.Parent = model
	end

	-- ====== EFFECTS ======

	-- Aura particle effect
	if visual.auraColor then
		addAura(body, visual.auraColor, 10)
	end

	-- Ghost trail
	if visual.ghostTrail then
		addGhostTrail(body, visual.auraColor)
	end

	-- Electric sparks
	if visual.electricSparks then
		addElectricSparks(body)
	end

	-- Dripping blood/slime
	if visual.drippingEffect then
		addDrippingEffect(body, visual.bodyColor)
	end

	-- ====== NAME & HEALTH BAR ======

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, visual.bodySize.Y + 2, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 50
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = visual.label
	nameLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.Parent = billboard

	local healthBg = Instance.new("Frame")
	healthBg.Name = "HealthBg"
	healthBg.Size = UDim2.new(0.8, 0, 0.2, 0)
	healthBg.Position = UDim2.new(0.1, 0, 0.65, 0)
	healthBg.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = billboard

	local healthBgCorner = Instance.new("UICorner")
	healthBgCorner.CornerRadius = UDim.new(0.5, 0)
	healthBgCorner.Parent = healthBg

	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = healthBg

	local healthBarCorner = Instance.new("UICorner")
	healthBarCorner.CornerRadius = UDim.new(0.5, 0)
	healthBarCorner.Parent = healthBar

	model.PrimaryPart = body
	model.Parent = workspace

	return model
end

-- ================================
-- UPDATE POSITION
-- ================================

function CreatureModelFactory.updatePosition(model: Model, newPosition: Vector3)
	if not model or not model.PrimaryPart then return end

	local heightOffset = model.PrimaryPart.Size.Y / 2
	local offset = (newPosition + Vector3.new(0, heightOffset, 0)) - model.PrimaryPart.Position

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Position = part.Position + offset
		end
	end
end

-- ================================
-- UPDATE HEALTH BAR
-- ================================

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

	-- Smooth health bar transition
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(healthBar, tweenInfo, {
		Size = UDim2.new(ratio, 0, 1, 0),
	}):Play()

	-- Color: green -> yellow -> red
	local newColor
	if ratio > 0.5 then
		newColor = Color3.fromRGB(40, 200, 40)
	elseif ratio > 0.25 then
		newColor = Color3.fromRGB(220, 180, 40)
	else
		newColor = Color3.fromRGB(220, 40, 40)
	end

	TweenService:Create(healthBar, tweenInfo, {
		BackgroundColor3 = newColor,
	}):Play()
end

-- ================================
-- HIT FLASH EFFECT
-- ================================

function CreatureModelFactory.hitFlash(model: Model)
	if not model then return end

	task.spawn(function()
		local originalColors = {}

		-- Flash white
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") and part.Name ~= "Eye_1" and part.Name ~= "Eye_2" then
				originalColors[part] = part.Color
				part.Color = Color3.fromRGB(255, 255, 255)
			end
		end

		task.wait(0.08)

		-- Restore
		for part, color in originalColors do
			if part.Parent then
				part.Color = color
			end
		end
	end)
end

-- ================================
-- DEATH ANIMATION
-- ================================

function CreatureModelFactory.destroy(model: Model)
	if not model then return end

	-- Stop particle effects
	for _, emitter in model:GetDescendants() do
		if emitter:IsA("ParticleEmitter") then
			emitter.Rate = 0
		end
	end

	-- Death burst particles on body
	local body = model:FindFirstChild("Body")
	if body then
		local burst = Instance.new("ParticleEmitter")
		burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		burst.Color = ColorSequence.new(body.Color)
		burst.Size = NumberSequence.new(0.3, 0)
		burst.Lifetime = NumberRange.new(0.5, 1)
		burst.Speed = NumberRange.new(10, 25)
		burst.SpreadAngle = Vector2.new(180, 180)
		burst.Transparency = NumberSequence.new(0, 1)
		burst.LightEmission = 0.5
		burst.Rate = 0
		burst.Parent = body
		burst:Emit(30)
	end

	-- Fade out all parts
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			TweenService:Create(part, tweenInfo, { Transparency = 1 }):Play()
		end
	end

	-- Sink into ground slightly
	if body then
		local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(body, tweenInfo, {
			Position = body.Position + Vector3.new(0, -1, 0),
		}):Play()
	end

	-- Remove after animation
	task.delay(1.2, function()
		if model and model.Parent then
			model:Destroy()
		end
	end)
end

return CreatureModelFactory
