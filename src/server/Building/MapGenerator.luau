--[[
	MapGenerator.luau
	Generates an enhanced version of Stormhaven with improved terrain,
	better lighting, decorative details, and atmospheric touches.
	Uses Roblox terrain API for natural ground and detailed Part geometry for buildings.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local MapGenerator = {}

-- Color palette
local COLORS = {
	ground = Color3.fromRGB(120, 135, 100),
	sand = Color3.fromRGB(210, 195, 150),
	rock = Color3.fromRGB(130, 125, 120),
	water = Color3.fromRGB(60, 100, 140),
	wood = Color3.fromRGB(140, 100, 60),
	wood_dark = Color3.fromRGB(100, 70, 40),
	stone_wall = Color3.fromRGB(180, 175, 170),
	stone_dark = Color3.fromRGB(140, 135, 130),
	roof = Color3.fromRGB(120, 55, 45),
	roof_dark = Color3.fromRGB(90, 40, 30),
	cobblestone = Color3.fromRGB(155, 150, 145),
	lighthouse = Color3.fromRGB(240, 235, 230),
	lighthouse_red = Color3.fromRGB(200, 50, 40),
	pier = Color3.fromRGB(130, 95, 55),
	metal = Color3.fromRGB(160, 160, 165),
	glass = Color3.fromRGB(180, 210, 230),
	grass = Color3.fromRGB(90, 140, 70),
	grass_dark = Color3.fromRGB(70, 110, 50),
	marsh = Color3.fromRGB(80, 100, 60),
	cliff = Color3.fromRGB(150, 140, 130),
	cliff_dark = Color3.fromRGB(110, 105, 100),
	chimney = Color3.fromRGB(100, 90, 85),
	window_glow = Color3.fromRGB(255, 220, 150),
	fire_orange = Color3.fromRGB(255, 130, 40),
	fire_red = Color3.fromRGB(255, 80, 20),
	lantern_glow = Color3.fromRGB(255, 200, 100),
	moss = Color3.fromRGB(60, 90, 40),
}

local MATERIALS = {
	ground = Enum.Material.Grass,
	sand = Enum.Material.Sand,
	rock = Enum.Material.Slate,
	wood = Enum.Material.Wood,
	stone = Enum.Material.Concrete,
	cobblestone = Enum.Material.Cobblestone,
	metal = Enum.Material.Metal,
	water = Enum.Material.Water,
	glass = Enum.Material.Glass,
	brick = Enum.Material.Brick,
	fabric = Enum.Material.Fabric,
}

-- Helper: create a part
local function createPart(parent, name, size, position, color, material, anchored)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color or COLORS.ground
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = anchored ~= false
	part.CanCollide = true
	part.CastShadow = true
	part.Parent = parent
	return part
end

-- Helper: create a wedge part (for sloped roofs)
local function createWedge(parent, name, size, cframe, color, material)
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Size = size
	wedge.CFrame = cframe
	wedge.Color = color or COLORS.roof
	wedge.Material = material or MATERIALS.wood
	wedge.Anchored = true
	wedge.CastShadow = true
	wedge.Parent = parent
	return wedge
end

-- Helper: add a point light to a part
local function addLight(part, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color or Color3.fromRGB(255, 230, 180)
	light.Brightness = brightness or 1
	light.Range = range or 20
	light.Shadows = true
	light.Parent = part
	return light
end

-- Helper: add fire particle to a part
local function addFireEffect(parent, size)
	size = size or 3
	local fire = Instance.new("Fire")
	fire.Size = size
	fire.Heat = size * 3
	fire.Color = COLORS.fire_orange
	fire.SecondaryColor = COLORS.fire_red
	fire.Parent = parent
	return fire
end

-- Helper: add smoke particle to a part
local function addSmoke(parent, color, opacity, riseVelocity)
	local smoke = Instance.new("Smoke")
	smoke.Color = color or Color3.fromRGB(100, 100, 100)
	smoke.Opacity = opacity or 0.3
	smoke.RiseVelocity = riseVelocity or 4
	smoke.Size = 3
	smoke.Parent = parent
	return smoke
end

-- Helper: add sparkles/glow to an object
local function addSparkles(parent, color)
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = color or Color3.fromRGB(255, 255, 200)
	sparkles.Parent = parent
	return sparkles
end

-- Helper: create a window (glowing panel)
local function createWindow(parent, position, size, wallNormal)
	local window = Instance.new("Part")
	window.Name = "Window"
	window.Size = size or Vector3.new(2, 2, 0.3)
	window.Position = position
	window.Color = COLORS.window_glow
	window.Material = Enum.Material.Neon
	window.Transparency = 0.3
	window.Anchored = true
	window.CanCollide = false
	window.CastShadow = false
	window.Parent = parent

	local light = Instance.new("PointLight")
	light.Color = COLORS.window_glow
	light.Brightness = 0.5
	light.Range = 10
	light.Parent = window

	return window
end

-- Helper: create a chimney with smoke
local function createChimney(parent, buildingPos, roofHeight, wallHeight)
	local chimney = createPart(parent, "Chimney",
		Vector3.new(2, 4, 2),
		buildingPos + Vector3.new(-3, wallHeight + 2, -2),
		COLORS.chimney, MATERIALS.brick)

	addSmoke(chimney, Color3.fromRGB(140, 140, 140), 0.2, 5)
	return chimney
end

-- Helper: scatter decorative rocks
local function scatterRocks(parent, center, radius, count, sizeRange)
	sizeRange = sizeRange or {1, 3}
	for i = 1, count do
		local angle = math.random() * math.pi * 2
		local dist = math.random() * radius
		local x = center.X + math.cos(angle) * dist
		local z = center.Z + math.sin(angle) * dist
		local s = math.random(sizeRange[1] * 10, sizeRange[2] * 10) / 10
		local rock = createPart(parent, "DecorRock_" .. i,
			Vector3.new(s, s * 0.6, s * 0.8),
			Vector3.new(x, center.Y + s * 0.3, z),
			COLORS.rock, MATERIALS.rock)
		rock.Orientation = Vector3.new(
			math.random(-15, 15),
			math.random(0, 360),
			math.random(-10, 10))
	end
end

-- Helper: scatter grass tufts
local function scatterGrass(parent, center, radius, count)
	for i = 1, count do
		local angle = math.random() * math.pi * 2
		local dist = math.random() * radius
		local x = center.X + math.cos(angle) * dist
		local z = center.Z + math.sin(angle) * dist
		local tuft = createPart(parent, "GrassTuft_" .. i,
			Vector3.new(0.5, math.random(5, 15) / 10, 0.5),
			Vector3.new(x, center.Y + 0.3, z),
			Color3.fromRGB(
				70 + math.random(0, 40),
				110 + math.random(0, 40),
				40 + math.random(0, 30)),
			MATERIALS.ground)
		tuft.CanCollide = false
		tuft.CastShadow = false
	end
end

-- Helper: create a tree (simple trunk + leafy top)
local function createTree(parent, position, name, scale)
	scale = scale or 1
	local folder = Instance.new("Folder")
	folder.Name = name or "Tree"
	folder.Parent = parent

	-- Trunk
	local trunk = createPart(folder, "Trunk",
		Vector3.new(1 * scale, 6 * scale, 1 * scale),
		position + Vector3.new(0, 3 * scale, 0),
		COLORS.wood_dark, MATERIALS.wood)

	-- Leafy canopy (stacked spherical parts)
	local canopyY = position.Y + 6 * scale
	for j = 0, 2 do
		local canopy = Instance.new("Part")
		canopy.Name = "Canopy_" .. j
		canopy.Shape = Enum.PartType.Ball
		local cSize = (4 - j * 0.8) * scale
		canopy.Size = Vector3.new(cSize, cSize, cSize)
		canopy.Position = Vector3.new(
			position.X + (math.random() - 0.5) * scale,
			canopyY + j * 1.5 * scale,
			position.Z + (math.random() - 0.5) * scale)
		canopy.Color = Color3.fromRGB(
			50 + math.random(0, 30),
			100 + math.random(0, 40),
			30 + math.random(0, 20))
		canopy.Material = MATERIALS.ground
		canopy.Anchored = true
		canopy.CanCollide = false
		canopy.CastShadow = true
		canopy.Parent = folder
	end

	return folder
end

-- Helper: create a building (walls + roof + floor + details)
local function createBuilding(parent, name, position, size, wallHeight, roofColor, attributes)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent

	local w, d = size.X, size.Z
	local wallThickness = 1

	-- Floor
	createPart(folder, "Floor", Vector3.new(w, 0.5, d),
		position + Vector3.new(0, 0.25, 0),
		COLORS.wood, MATERIALS.wood)

	-- Foundation (slightly larger)
	createPart(folder, "Foundation", Vector3.new(w + 1, 0.5, d + 1),
		position + Vector3.new(0, -0.25, 0),
		COLORS.stone_dark, MATERIALS.stone)

	-- Walls (4 sides)
	-- Front (Z-)
	local frontWall = createPart(folder, "Wall_Front", Vector3.new(w, wallHeight, wallThickness),
		position + Vector3.new(0, wallHeight/2, -d/2 + wallThickness/2),
		COLORS.stone_wall, MATERIALS.stone)
	frontWall:SetAttribute("WallIndex", 1)
	frontWall:SetAttribute("BuildingId", name)

	-- Back (Z+)
	local backWall = createPart(folder, "Wall_Back", Vector3.new(w, wallHeight, wallThickness),
		position + Vector3.new(0, wallHeight/2, d/2 - wallThickness/2),
		COLORS.stone_wall, MATERIALS.stone)
	backWall:SetAttribute("WallIndex", 2)
	backWall:SetAttribute("BuildingId", name)

	-- Left (X-)
	local leftWall = createPart(folder, "Wall_Left", Vector3.new(wallThickness, wallHeight, d),
		position + Vector3.new(-w/2 + wallThickness/2, wallHeight/2, 0),
		COLORS.stone_wall, MATERIALS.stone)
	leftWall:SetAttribute("WallIndex", 3)
	leftWall:SetAttribute("BuildingId", name)

	-- Right (X+)
	local rightWall = createPart(folder, "Wall_Right", Vector3.new(wallThickness, wallHeight, d),
		position + Vector3.new(w/2 - wallThickness/2, wallHeight/2, 0),
		COLORS.stone_wall, MATERIALS.stone)
	rightWall:SetAttribute("WallIndex", 4)
	rightWall:SetAttribute("BuildingId", name)

	-- Door gap
	local doorway = createPart(folder, "Doorway", Vector3.new(4, wallHeight, wallThickness + 0.2),
		position + Vector3.new(0, wallHeight/2, -d/2 + wallThickness/2),
		COLORS.stone_wall, MATERIALS.stone)
	doorway.Transparency = 1
	doorway.CanCollide = false
	doorway:SetAttribute("InteractType", "Building")
	doorway:SetAttribute("BuildingId", name)

	-- Peaked roof (two wedge parts)
	local roofPeakHeight = 3
	local roofOverhang = 2

	-- Left roof slope
	createWedge(folder, "Roof_Left",
		Vector3.new(d + roofOverhang, roofPeakHeight, w/2 + roofOverhang/2),
		CFrame.new(
			position.X - w/4 - roofOverhang/4, wallHeight + roofPeakHeight/2, position.Z
		) * CFrame.Angles(0, math.rad(-90), 0),
		roofColor or COLORS.roof, MATERIALS.wood)

	-- Right roof slope
	createWedge(folder, "Roof_Right",
		Vector3.new(d + roofOverhang, roofPeakHeight, w/2 + roofOverhang/2),
		CFrame.new(
			position.X + w/4 + roofOverhang/4, wallHeight + roofPeakHeight/2, position.Z
		) * CFrame.Angles(0, math.rad(90), 0),
		roofColor or COLORS.roof, MATERIALS.wood)

	-- Windows (add to front and back walls)
	if w > 8 then
		createWindow(folder,
			position + Vector3.new(-w/4, wallHeight * 0.5, -d/2 + 0.3),
			Vector3.new(2, 2.5, 0.3))
		createWindow(folder,
			position + Vector3.new(w/4, wallHeight * 0.5, -d/2 + 0.3),
			Vector3.new(2, 2.5, 0.3))
	end

	-- Chimney
	createChimney(folder, position, wallHeight + roofPeakHeight, wallHeight)

	-- Set attributes
	if attributes then
		for key, value in attributes do
			folder:SetAttribute(key, value)
		end
	end

	return folder
end

-- Helper: create a resource node
local function createResourceNode(parent, nodeType, position, resourceSystem)
	local part = Instance.new("Part")
	part.Name = "Resource_" .. nodeType
	part.Anchored = true
	part.CanCollide = true

	-- Visual based on type
	if nodeType == "driftwood" then
		part.Size = Vector3.new(4, 1, 1.5)
		part.Color = COLORS.wood
		part.Material = MATERIALS.wood
		part.Shape = Enum.PartType.Block
		part.Orientation = Vector3.new(0, math.random(0, 180), math.random(-5, 5))
	elseif nodeType == "rock_deposit" then
		part.Size = Vector3.new(3, 2, 3)
		part.Color = COLORS.rock
		part.Material = MATERIALS.rock
		part.Shape = Enum.PartType.Block
	elseif nodeType == "scrap_pile" then
		part.Size = Vector3.new(3, 1.5, 3)
		part.Color = COLORS.metal
		part.Material = MATERIALS.metal
	elseif nodeType == "fishing_spot" then
		part.Size = Vector3.new(2, 0.3, 2)
		part.Color = COLORS.water
		part.Material = Enum.Material.Neon
		part.Transparency = 0.5
		part.CanCollide = false
		-- Sparkle effect for fishing spots
		addSparkles(part, Color3.fromRGB(100, 180, 255))
	elseif nodeType == "tide_pool" then
		part.Size = Vector3.new(3, 0.3, 3)
		part.Color = Color3.fromRGB(80, 130, 160)
		part.Material = Enum.Material.Glass
		part.Transparency = 0.3
	elseif nodeType == "herb_patch" then
		part.Size = Vector3.new(2, 0.5, 2)
		part.Color = COLORS.grass
		part.Material = MATERIALS.ground
		-- Little green sparkle for herbs
		addSparkles(part, Color3.fromRGB(100, 255, 100))
	elseif nodeType == "oil_barrel" then
		part.Size = Vector3.new(1.5, 2.5, 1.5)
		part.Color = Color3.fromRGB(50, 50, 55)
		part.Material = MATERIALS.metal
		part.Shape = Enum.PartType.Cylinder
	elseif nodeType == "cloth_source" then
		part.Size = Vector3.new(2, 1, 2)
		part.Color = Color3.fromRGB(200, 195, 185)
		part.Material = MATERIALS.fabric
	elseif nodeType == "iron_vein" then
		part.Size = Vector3.new(3, 2.5, 2)
		part.Color = Color3.fromRGB(140, 110, 90)
		part.Material = MATERIALS.rock
	else
		part.Size = Vector3.new(2, 1, 2)
		part.Color = COLORS.rock
		part.Material = MATERIALS.rock
	end

	part.Position = position
	part:SetAttribute("InteractType", "Resource")
	part:SetAttribute("NodeType", nodeType)
	part.Parent = parent

	-- Register with resource system
	if resourceSystem then
		local nodeId = resourceSystem:registerNode(nodeType, position, part)
		part:SetAttribute("NodeId", nodeId)
	end

	return part
end

-- ================================
-- NPC MODEL CREATION
-- ================================

local NPC_VISUALS = {
	fishmonger = {
		shirtColor = Color3.fromRGB(80, 120, 160),
		pantsColor = Color3.fromRGB(60, 70, 50),
		hatColor = Color3.fromRGB(200, 180, 100),
		label = "Sally - Fishmonger",
	},
	shopkeeper = {
		shirtColor = Color3.fromRGB(140, 100, 60),
		pantsColor = Color3.fromRGB(60, 50, 40),
		hatColor = nil,
		label = "Harold - Shopkeeper",
	},
	barkeep = {
		shirtColor = Color3.fromRGB(120, 40, 50),
		pantsColor = Color3.fromRGB(50, 40, 40),
		hatColor = nil,
		label = "Maggie - Barkeep",
	},
}

local function createNPCModel(parent, npcId, position)
	local visual = NPC_VISUALS[npcId]
	if not visual then return nil end

	local model = Instance.new("Model")
	model.Name = "NPC_" .. npcId

	-- Body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2, 3, 1)
	body.Color = visual.shirtColor
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.Position = position + Vector3.new(0, 1.5, 0)
	body:SetAttribute("InteractType", "NPC")
	body:SetAttribute("NPCId", npcId)
	body.Parent = model

	-- Pants / lower body
	local legs = Instance.new("Part")
	legs.Name = "Legs"
	legs.Size = Vector3.new(2, 2, 1)
	legs.Color = visual.pantsColor
	legs.Material = Enum.Material.SmoothPlastic
	legs.Anchored = true
	legs.CanCollide = false
	legs.Position = position + Vector3.new(0, 0, 0)
	legs.Parent = model

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.5, 1.5, 1.5)
	head.Color = Color3.fromRGB(220, 180, 150)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Position = position + Vector3.new(0, 3.5, 0)
	head.Parent = model

	-- Hat (if applicable)
	if visual.hatColor then
		local hat = Instance.new("Part")
		hat.Name = "Hat"
		hat.Size = Vector3.new(1.8, 0.5, 1.8)
		hat.Color = visual.hatColor
		hat.Material = Enum.Material.SmoothPlastic
		hat.Anchored = true
		hat.CanCollide = false
		hat.Position = position + Vector3.new(0, 4.3, 0)
		hat.Parent = model
	end

	-- Name billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 30
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = visual.label
	nameLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.Parent = billboard

	model.PrimaryPart = body
	model.Parent = parent

	return model
end

-- ================================
-- MAIN MAP GENERATION
-- ================================

function MapGenerator.generate(resourceSystem)
	local map = Instance.new("Folder")
	map.Name = "Stormhaven"
	map.Parent = workspace

	-- ============================
	-- TERRAIN: Base ground
	-- ============================
	local terrain = Instance.new("Folder")
	terrain.Name = "Terrain"
	terrain.Parent = map

	-- Main ground plate (town area) with layered grass
	createPart(terrain, "MainGround", Vector3.new(500, 3, 500),
		Vector3.new(0, -1.5, 0), COLORS.ground, MATERIALS.ground)

	-- Darker ground border (visual depth)
	createPart(terrain, "GroundBorder", Vector3.new(520, 2, 520),
		Vector3.new(0, -3, 0), COLORS.grass_dark, MATERIALS.ground)

	-- Elevated cliff for lighthouse
	createPart(terrain, "LighthouseCliff", Vector3.new(80, 60, 80),
		Vector3.new(0, 30, -80), COLORS.cliff, MATERIALS.rock)

	-- Cliff face details (moss-covered rocky outcrops)
	for i = 1, 6 do
		local angle = math.random() * math.pi * 2
		local dist = 30 + math.random(0, 10)
		createPart(terrain, "CliffDetail_" .. i,
			Vector3.new(math.random(5, 15), math.random(3, 10), math.random(5, 12)),
			Vector3.new(math.cos(angle) * dist, 10 + math.random(0, 30), -80 + math.sin(angle) * dist),
			COLORS.cliff_dark, MATERIALS.rock)
	end

	-- Ramp to lighthouse
	local ramp = createPart(terrain, "LighthouseRamp", Vector3.new(8, 1, 100),
		Vector3.new(0, 30, -30), COLORS.cobblestone, MATERIALS.cobblestone)
	ramp.Orientation = Vector3.new(-17, 0, 0)

	-- Ramp railing (left)
	createPart(terrain, "RampRail_L", Vector3.new(0.5, 2, 100),
		Vector3.new(-4, 31, -30), COLORS.wood_dark, MATERIALS.wood)
	-- Ramp railing (right)
	createPart(terrain, "RampRail_R", Vector3.new(0.5, 2, 100),
		Vector3.new(4, 31, -30), COLORS.wood_dark, MATERIALS.wood)

	-- Residential hill (elevated, softer terrain)
	createPart(terrain, "ResidentialHill", Vector3.new(200, 20, 150),
		Vector3.new(-50, 10, -30), COLORS.ground, MATERIALS.ground)

	-- Hill grass edge
	createPart(terrain, "HillEdge", Vector3.new(210, 2, 160),
		Vector3.new(-50, 20.5, -30), COLORS.grass, MATERIALS.ground)

	-- Harbor area (at sea level)
	createPart(terrain, "HarborGround", Vector3.new(200, 1, 100),
		Vector3.new(0, 0, 100), COLORS.sand, MATERIALS.sand)

	-- Rocky shore
	for i = 1, 15 do
		local x = math.random(-200, 200)
		local z = 150 + math.random(0, 50)
		createPart(terrain, "Rock_" .. i,
			Vector3.new(math.random(3, 10), math.random(2, 6), math.random(3, 10)),
			Vector3.new(x, 1, z), COLORS.rock, MATERIALS.rock)
	end

	-- Ocean water plane
	local water = createPart(terrain, "Ocean", Vector3.new(2000, 0.5, 2000),
		Vector3.new(0, -1, 300), COLORS.water, Enum.Material.Glass)
	water.Transparency = 0.4
	water.CanCollide = false

	-- Beach area
	createPart(terrain, "Beach", Vector3.new(300, 0.5, 60),
		Vector3.new(0, -0.2, 155), COLORS.sand, MATERIALS.sand)

	-- Main Street cobblestone
	createPart(terrain, "MainStreet", Vector3.new(200, 0.3, 12),
		Vector3.new(0, 0.15, 42), COLORS.cobblestone, MATERIALS.cobblestone)

	-- Side path to residential
	createPart(terrain, "ResidentialPath", Vector3.new(8, 0.3, 60),
		Vector3.new(-50, 10.15, 0), COLORS.cobblestone, MATERIALS.cobblestone)

	-- ============================
	-- TREES & VEGETATION
	-- ============================
	local foliage = Instance.new("Folder")
	foliage.Name = "Foliage"
	foliage.Parent = map

	-- Town trees
	local treePositions = {
		Vector3.new(-70, 0, 25), Vector3.new(-85, 0, 45),
		Vector3.new(70, 0, 30), Vector3.new(85, 0, 50),
		Vector3.new(-40, 0, 70), Vector3.new(30, 0, 75),
		Vector3.new(-100, 0, 60), Vector3.new(100, 0, 55),
		-- Residential hill trees
		Vector3.new(-100, 20, -50), Vector3.new(-95, 20, -20),
		Vector3.new(-10, 20, -60), Vector3.new(-35, 20, -55),
		-- Near lighthouse
		Vector3.new(-25, 60, -65), Vector3.new(25, 60, -70),
	}

	for i, pos in treePositions do
		local scale = 0.8 + math.random() * 0.6
		createTree(foliage, pos, "Tree_" .. i, scale)
	end

	-- Grass tufts in open areas
	scatterGrass(foliage, Vector3.new(0, 0, 60), 80, 40)
	scatterGrass(foliage, Vector3.new(-50, 20, -40), 60, 30)
	scatterGrass(foliage, Vector3.new(0, 60, -75), 25, 15)

	-- Decorative rocks around paths
	scatterRocks(foliage, Vector3.new(0, 0, 45), 30, 10, {0.5, 1.5})
	scatterRocks(foliage, Vector3.new(0, 60, -80), 20, 8, {1, 3})

	-- ============================
	-- LIGHTHOUSE (Central Hub)
	-- ============================
	local lighthouse = Instance.new("Folder")
	lighthouse.Name = "Lighthouse"
	lighthouse.Parent = map

	-- Tower base (wider foundation)
	createPart(lighthouse, "Tower_Foundation", Vector3.new(14, 3, 14),
		Vector3.new(0, 61.5, -80), COLORS.stone_dark, MATERIALS.stone)

	-- Tower main body
	createPart(lighthouse, "Tower_Base", Vector3.new(10, 30, 10),
		Vector3.new(0, 75, -80), COLORS.lighthouse, MATERIALS.stone)

	-- Red stripe bands
	createPart(lighthouse, "Tower_Stripe1", Vector3.new(10.2, 3, 10.2),
		Vector3.new(0, 68, -80), COLORS.lighthouse_red, MATERIALS.stone)
	createPart(lighthouse, "Tower_Stripe2", Vector3.new(10.2, 3, 10.2),
		Vector3.new(0, 80, -80), COLORS.lighthouse_red, MATERIALS.stone)

	-- Beacon room (glass observation deck)
	createPart(lighthouse, "Beacon_Room", Vector3.new(12, 6, 12),
		Vector3.new(0, 93, -80), COLORS.glass, MATERIALS.glass)

	-- Beacon walkway rail
	createPart(lighthouse, "Beacon_Rail", Vector3.new(14, 1, 14),
		Vector3.new(0, 89.5, -80), COLORS.metal, MATERIALS.metal)

	-- Beacon light (bright glowing orb)
	local beacon = Instance.new("Part")
	beacon.Name = "Beacon"
	beacon.Shape = Enum.PartType.Ball
	beacon.Size = Vector3.new(3, 3, 3)
	beacon.Position = Vector3.new(0, 93, -80)
	beacon.Color = Color3.fromRGB(255, 255, 200)
	beacon.Material = Enum.Material.Neon
	beacon.Anchored = true
	beacon.CanCollide = false
	beacon.Parent = lighthouse

	local beaconLight = Instance.new("PointLight")
	beaconLight.Color = Color3.fromRGB(255, 240, 180)
	beaconLight.Brightness = 5
	beaconLight.Range = 120
	beaconLight.Shadows = true
	beaconLight.Parent = beacon

	-- Spotlight beam from beacon
	local spotlight = Instance.new("SpotLight")
	spotlight.Face = Enum.NormalId.Front
	spotlight.Brightness = 8
	spotlight.Range = 200
	spotlight.Angle = 30
	spotlight.Color = Color3.fromRGB(255, 240, 180)
	spotlight.Parent = beacon

	-- Storm Forge (glowing purple anvil area)
	local stormForge = createPart(lighthouse, "StormForge", Vector3.new(3, 2, 3),
		Vector3.new(5, 61, -80), Color3.fromRGB(80, 60, 120), Enum.Material.Neon)
	stormForge:SetAttribute("InteractType", "CraftStation")
	stormForge:SetAttribute("StationId", "storm_forge")
	addSparkles(stormForge, Color3.fromRGB(150, 100, 255))
	addLight(stormForge, Color3.fromRGB(120, 80, 200), 1.5, 15)

	-- Campfire (with actual fire effect!)
	local campfireBase = createPart(lighthouse, "CampfireBase", Vector3.new(4, 0.3, 4),
		Vector3.new(-10, 60.15, -75), COLORS.rock, MATERIALS.rock)

	local campfireLogs = createPart(lighthouse, "CampfireLogs", Vector3.new(2, 0.6, 2),
		Vector3.new(-10, 60.5, -75), COLORS.wood_dark, MATERIALS.wood)

	local campfire = createPart(lighthouse, "Campfire", Vector3.new(1, 1, 1),
		Vector3.new(-10, 60.8, -75), COLORS.fire_orange, Enum.Material.Neon)
	campfire:SetAttribute("InteractType", "Campfire")
	campfire.Transparency = 0.3
	campfire.CanCollide = false

	addFireEffect(campfire, 5)
	addLight(campfire, Color3.fromRGB(255, 150, 50), 3, 30)

	-- Sitting logs around campfire
	for i, offset in { Vector3.new(-3, 0.3, 0), Vector3.new(3, 0.3, 0), Vector3.new(0, 0.3, 3) } do
		local log = createPart(lighthouse, "SittingLog_" .. i,
			Vector3.new(3, 0.8, 1),
			Vector3.new(-10, 60, -75) + offset,
			COLORS.wood, MATERIALS.wood)
		log.Orientation = Vector3.new(0, i * 60, 0)
	end

	-- ============================
	-- HARBOR DISTRICT
	-- ============================
	local harbor = Instance.new("Folder")
	harbor.Name = "HarborDistrict"
	harbor.Parent = map

	-- Pier (with support posts)
	createPart(harbor, "Pier", Vector3.new(80, 1, 8),
		Vector3.new(0, 1.5, 130), COLORS.pier, MATERIALS.wood)

	-- Pier railing
	createPart(harbor, "PierRail_L", Vector3.new(80, 1.5, 0.3),
		Vector3.new(0, 2.75, 126), COLORS.wood_dark, MATERIALS.wood)
	createPart(harbor, "PierRail_R", Vector3.new(80, 1.5, 0.3),
		Vector3.new(0, 2.75, 134), COLORS.wood_dark, MATERIALS.wood)

	-- Pier posts
	for i = 0, 7 do
		createPart(harbor, "PierPost_" .. i, Vector3.new(1, 5, 1),
			Vector3.new(-35 + i * 10, -1, 130), COLORS.pier, MATERIALS.wood)
	end

	-- Pier lanterns
	for i = 0, 3 do
		local lanternPost = createPart(harbor, "PierLantern_" .. i,
			Vector3.new(0.3, 3, 0.3),
			Vector3.new(-30 + i * 20, 3.5, 126), COLORS.metal, MATERIALS.metal)
		local lanternBulb = createPart(harbor, "PierLanternBulb_" .. i,
			Vector3.new(0.6, 0.6, 0.6),
			Vector3.new(-30 + i * 20, 5.3, 126), COLORS.lantern_glow, Enum.Material.Neon)
		addLight(lanternBulb, COLORS.lantern_glow, 1, 15)
	end

	-- Harbormaster's Office
	local harborOffice = createBuilding(harbor, "harbormaster", Vector3.new(30, 0, 105),
		Vector3.new(14, 6, 10), 8, nil, {
			InteractType = "Building",
			BuildingId = "harbormaster",
		})

	-- Workbench inside harbormaster
	local workbench = createPart(harborOffice, "Workbench", Vector3.new(3, 2, 2),
		Vector3.new(33, 1, 105), COLORS.wood, MATERIALS.wood)
	workbench:SetAttribute("InteractType", "CraftStation")
	workbench:SetAttribute("StationId", "workbench")

	-- Fish Market
	local fishMarket = createBuilding(harbor, "fish_market", Vector3.new(50, 0, 110),
		Vector3.new(12, 6, 8), 7, nil, {
			InteractType = "NPC",
			NPCId = "fishmonger",
		})

	-- Fish Market NPC
	createNPCModel(fishMarket, "fishmonger", Vector3.new(50, 0, 110))

	-- Boathouse
	createBuilding(harbor, "boathouse", Vector3.new(55, 0, 125),
		Vector3.new(12, 5, 10), 6, nil, nil)

	-- Dock
	local dock = createPart(harbor, "Dock", Vector3.new(15, 1, 20),
		Vector3.new(60, 1, 135), COLORS.pier, MATERIALS.wood)
	dock:SetAttribute("InteractType", "CraftStation")
	dock:SetAttribute("StationId", "boat_workshop")

	-- Moored boats (decorative)
	local boat1 = createPart(harbor, "Boat_1", Vector3.new(4, 1.5, 8),
		Vector3.new(63, 0, 145), COLORS.wood, MATERIALS.wood)
	boat1.Orientation = Vector3.new(0, 20, 5)

	-- ============================
	-- MAIN STREET
	-- ============================
	local mainStreet = Instance.new("Folder")
	mainStreet.Name = "MainStreet"
	mainStreet.Parent = map

	-- General Store
	local store = createBuilding(mainStreet, "general_store", Vector3.new(-50, 0, 35),
		Vector3.new(12, 6, 10), 8, nil, {
			InteractType = "NPC",
			NPCId = "shopkeeper",
			RestorableBuilding = true,
		})
	createNPCModel(store, "shopkeeper", Vector3.new(-50, 0, 35))

	-- Blacksmith
	local blacksmith = createBuilding(mainStreet, "blacksmith", Vector3.new(-25, 0, 35),
		Vector3.new(12, 6, 10), 8, nil, {
			InteractType = "CraftStation",
			StationId = "anvil",
			RestorableBuilding = true,
		})

	-- Anvil with fire glow
	local anvilPart = createPart(blacksmith, "Anvil", Vector3.new(2, 1.5, 1.5),
		Vector3.new(-25, 0.75, 35), COLORS.metal, MATERIALS.metal)
	local forgeFire = createPart(blacksmith, "ForgeFirePit", Vector3.new(2, 0.5, 2),
		Vector3.new(-23, 0.25, 36), COLORS.fire_orange, Enum.Material.Neon)
	forgeFire.Transparency = 0.5
	addFireEffect(forgeFire, 2)
	addLight(forgeFire, COLORS.fire_orange, 1.5, 12)

	-- Town Hall
	createBuilding(mainStreet, "town_hall", Vector3.new(0, 0, 35),
		Vector3.new(16, 6, 12), 10, nil, nil)

	-- Town Hall bell
	local bellMount = createPart(mainStreet, "TownBellMount", Vector3.new(2, 2, 2),
		Vector3.new(0, 14, 35), COLORS.metal, MATERIALS.metal)
	local bell = Instance.new("Part")
	bell.Name = "TownBell"
	bell.Shape = Enum.PartType.Ball
	bell.Size = Vector3.new(1.5, 1.5, 1.5)
	bell.Color = Color3.fromRGB(200, 180, 60)
	bell.Material = Enum.Material.SmoothPlastic
	bell.Anchored = true
	bell.Position = Vector3.new(0, 12.5, 35)
	bell.Parent = mainStreet

	-- Tavern
	local tavern = createBuilding(mainStreet, "tavern", Vector3.new(-50, 0, 50),
		Vector3.new(14, 6, 10), 8, nil, {
			InteractType = "NPC",
			NPCId = "barkeep",
			RestorableBuilding = true,
		})
	createNPCModel(tavern, "barkeep", Vector3.new(-48, 0, 50))

	-- Stove inside tavern
	local stove = createPart(tavern, "Stove", Vector3.new(2, 2, 2),
		Vector3.new(-50, 1, 50), Color3.fromRGB(60, 60, 60), MATERIALS.metal)
	stove:SetAttribute("InteractType", "CraftStation")
	stove:SetAttribute("StationId", "stove")
	addLight(stove, COLORS.fire_orange, 0.5, 8)

	-- Tavern sign
	local tavernSign = createPart(mainStreet, "TavernSign", Vector3.new(4, 1.5, 0.3),
		Vector3.new(-50, 9, 45), COLORS.wood_dark, MATERIALS.wood)

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = tavernSign

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 1, 0)
	signText.BackgroundTransparency = 1
	signText.Text = "THE STORM'S REST"
	signText.TextColor3 = Color3.fromRGB(255, 220, 150)
	signText.TextSize = 24
	signText.Font = Enum.Font.Antique
	signText.Parent = signGui

	-- Clinic
	local clinic = createBuilding(mainStreet, "clinic", Vector3.new(-25, 0, 50),
		Vector3.new(12, 6, 10), 8, nil, {
			InteractType = "CraftStation",
			StationId = "medical_table",
			RestorableBuilding = true,
		})

	-- Clinic cross sign
	local clinicSign = createPart(clinic, "ClinicCross", Vector3.new(2, 2, 0.3),
		Vector3.new(-25, 9, 45), Color3.fromRGB(200, 50, 50), Enum.Material.Neon)
	addLight(clinicSign, Color3.fromRGB(255, 100, 100), 0.5, 10)

	-- Garage
	createBuilding(mainStreet, "garage", Vector3.new(0, 0, 50),
		Vector3.new(14, 6, 12), 7, COLORS.metal, nil)

	-- Street lamps (enhanced with warm glow)
	for i = -3, 3 do
		-- Post
		local lampPost = createPart(mainStreet, "LampPost_" .. i,
			Vector3.new(0.5, 8, 0.5),
			Vector3.new(i * 25, 4, 42), COLORS.metal, MATERIALS.metal)

		-- Lamp housing
		local lampHousing = createPart(mainStreet, "LampHousing_" .. i,
			Vector3.new(1.2, 1.2, 1.2),
			Vector3.new(i * 25, 8.6, 42), Color3.fromRGB(50, 50, 55), MATERIALS.metal)

		-- Lamp glow
		local lampGlow = createPart(mainStreet, "LampGlow_" .. i,
			Vector3.new(0.6, 0.6, 0.6),
			Vector3.new(i * 25, 8.6, 42), COLORS.lantern_glow, Enum.Material.Neon)
		lampGlow.Transparency = 0.2
		addLight(lampGlow, COLORS.lantern_glow, 1.5, 25)
	end

	-- ============================
	-- RESIDENTIAL HILL
	-- ============================
	local residential = Instance.new("Folder")
	residential.Name = "ResidentialHill"
	residential.Parent = map

	-- 6 Claimable houses
	local houses = {
		{ id = "cliff_house",     pos = Vector3.new(-80, 20, -60),  size = Vector3.new(12, 6, 10) },
		{ id = "cellar_house",    pos = Vector3.new(-50, 20, -50),  size = Vector3.new(12, 6, 10) },
		{ id = "garden_house",    pos = Vector3.new(-20, 20, -50),  size = Vector3.new(12, 6, 10) },
		{ id = "watchtower_house", pos = Vector3.new(-80, 20, -30), size = Vector3.new(10, 6, 10) },
		{ id = "workshop_house",  pos = Vector3.new(-50, 20, -30),  size = Vector3.new(12, 6, 10) },
		{ id = "seaside_cottage", pos = Vector3.new(50, 0, 85),     size = Vector3.new(10, 5, 8) },
	}

	for _, house in houses do
		createBuilding(residential, house.id, house.pos, house.size, 8, nil, {
			InteractType = "Building",
			BuildingId = house.id,
			Claimable = true,
		})
	end

	-- Watchtower extension (taller)
	createPart(residential, "Watchtower", Vector3.new(4, 18, 4),
		Vector3.new(-80, 37, -30), COLORS.stone_wall, MATERIALS.stone)

	-- Watchtower beacon
	local watchtowerLight = createPart(residential, "WatchtowerLight",
		Vector3.new(1, 1, 1),
		Vector3.new(-80, 46.5, -30), COLORS.lantern_glow, Enum.Material.Neon)
	addLight(watchtowerLight, COLORS.lantern_glow, 2, 40)

	-- Church
	local church = createBuilding(residential, "church", Vector3.new(-30, 20, -10),
		Vector3.new(16, 8, 12), 12, nil, {
			InteractType = "Building",
			BuildingId = "church",
			RestorableBuilding = true,
		})

	-- Bell tower
	createPart(church, "BellTower", Vector3.new(4, 18, 4),
		Vector3.new(-30, 38, -10), COLORS.stone_wall, MATERIALS.stone)

	-- Stained glass window on church
	local stainedGlass = createPart(church, "StainedGlass",
		Vector3.new(4, 5, 0.3),
		Vector3.new(-30, 26, -16),
		Color3.fromRGB(120, 80, 200), Enum.Material.Neon)
	stainedGlass.Transparency = 0.3
	addLight(stainedGlass, Color3.fromRGB(120, 80, 200), 0.5, 10)

	-- ============================
	-- RESOURCE NODES
	-- ============================
	local resources = Instance.new("Folder")
	resources.Name = "Resources"
	resources.Parent = map

	-- Harbor area resources
	createResourceNode(resources, "driftwood", Vector3.new(20, 0.5, 120), resourceSystem)
	createResourceNode(resources, "driftwood", Vector3.new(-30, 0.5, 115), resourceSystem)
	createResourceNode(resources, "driftwood", Vector3.new(40, 0.5, 140), resourceSystem)
	createResourceNode(resources, "scrap_pile", Vector3.new(35, 0.5, 100), resourceSystem)
	createResourceNode(resources, "scrap_pile", Vector3.new(-15, 0.5, 95), resourceSystem)
	createResourceNode(resources, "cloth_source", Vector3.new(10, 0.5, 100), resourceSystem)
	createResourceNode(resources, "fishing_spot", Vector3.new(-20, 0.5, 132), resourceSystem)
	createResourceNode(resources, "fishing_spot", Vector3.new(0, 0.5, 132), resourceSystem)
	createResourceNode(resources, "fishing_spot", Vector3.new(20, 0.5, 132), resourceSystem)

	-- Rocky shore resources
	createResourceNode(resources, "rock_deposit", Vector3.new(100, 0.5, 155), resourceSystem)
	createResourceNode(resources, "rock_deposit", Vector3.new(-80, 0.5, 160), resourceSystem)
	createResourceNode(resources, "tide_pool", Vector3.new(70, 0, 165), resourceSystem)
	createResourceNode(resources, "tide_pool", Vector3.new(-50, 0, 170), resourceSystem)
	createResourceNode(resources, "tide_pool", Vector3.new(120, 0, 158), resourceSystem)

	-- Main street resources
	createResourceNode(resources, "scrap_pile", Vector3.new(30, 0.5, 45), resourceSystem)
	createResourceNode(resources, "cloth_source", Vector3.new(-65, 0.5, 40), resourceSystem)
	createResourceNode(resources, "oil_barrel", Vector3.new(5, 0.5, 55), resourceSystem)

	-- Residential hill resources
	createResourceNode(resources, "driftwood", Vector3.new(-70, 20.5, -40), resourceSystem)
	createResourceNode(resources, "rock_deposit", Vector3.new(-90, 20.5, -50), resourceSystem)
	createResourceNode(resources, "herb_patch", Vector3.new(-15, 20.5, -45), resourceSystem)
	createResourceNode(resources, "herb_patch", Vector3.new(-35, 20.5, -35), resourceSystem)

	-- Near lighthouse
	createResourceNode(resources, "rock_deposit", Vector3.new(20, 60.5, -90), resourceSystem)
	createResourceNode(resources, "driftwood", Vector3.new(-20, 60.5, -70), resourceSystem)

	-- ============================
	-- LOOT CONTAINERS (searchable)
	-- ============================
	local lootContainers = Instance.new("Folder")
	lootContainers.Name = "LootContainers"
	lootContainers.Parent = map

	local LOOT_COLOR = {
		common = Color3.fromRGB(120, 100, 70),
		uncommon = Color3.fromRGB(80, 140, 80),
		rare = Color3.fromRGB(80, 100, 180),
		legendary = Color3.fromRGB(180, 140, 50),
	}

	local lootSpawns = {
		-- Harbor area (common loot)
		{ pos = Vector3.new(15, 0.8, 105), rarity = "common" },
		{ pos = Vector3.new(-25, 0.8, 110), rarity = "common" },
		{ pos = Vector3.new(40, 0.8, 118), rarity = "common" },
		{ pos = Vector3.new(55, 0.8, 130), rarity = "common" },
		-- Main Street alleys (common + uncommon)
		{ pos = Vector3.new(-60, 0.8, 42), rarity = "common" },
		{ pos = Vector3.new(35, 0.8, 38), rarity = "uncommon" },
		{ pos = Vector3.new(-10, 0.8, 55), rarity = "common" },
		{ pos = Vector3.new(20, 0.8, 55), rarity = "uncommon" },
		-- Behind buildings
		{ pos = Vector3.new(-55, 0.8, 28), rarity = "uncommon" },
		{ pos = Vector3.new(10, 0.8, 28), rarity = "uncommon" },
		-- Residential Hill (uncommon + rare)
		{ pos = Vector3.new(-70, 21, -55), rarity = "uncommon" },
		{ pos = Vector3.new(-40, 21, -40), rarity = "uncommon" },
		{ pos = Vector3.new(-20, 21, -25), rarity = "rare" },
		{ pos = Vector3.new(-85, 21, -35), rarity = "uncommon" },
		-- Near church (rare)
		{ pos = Vector3.new(-35, 21, -5), rarity = "rare" },
		-- Rocky Shore (uncommon + rare)
		{ pos = Vector3.new(90, 0.5, 150), rarity = "uncommon" },
		{ pos = Vector3.new(-70, 0.5, 155), rarity = "rare" },
		{ pos = Vector3.new(110, 0.5, 160), rarity = "uncommon" },
		-- Near lighthouse (rare + legendary)
		{ pos = Vector3.new(10, 61, -85), rarity = "rare" },
		{ pos = Vector3.new(-15, 61, -75), rarity = "rare" },
		{ pos = Vector3.new(0, 61, -95), rarity = "legendary" },
		-- Hidden spots
		{ pos = Vector3.new(60, 0.8, 80), rarity = "rare" },
		{ pos = Vector3.new(-100, 21, -60), rarity = "legendary" },
	}

	for i, loot in lootSpawns do
		local color = LOOT_COLOR[loot.rarity] or LOOT_COLOR.common
		local container = createPart(lootContainers, "LootCrate_" .. i,
			Vector3.new(2, 1.5, 1.5),
			loot.pos,
			color, MATERIALS.wood)
		container:SetAttribute("Rarity", loot.rarity)
		container:SetAttribute("LootIndex", i)

		-- Add a subtle glow for rarer containers
		if loot.rarity == "rare" or loot.rarity == "legendary" then
			addLight(container, color, 0.5, 8)
		end
	end

	-- ============================
	-- SPAWN POINT
	-- ============================
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(25, 2, 42)
	spawn.Color = Color3.fromRGB(100, 200, 100)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.5
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Parent = map

	-- ============================
	-- AMBIENT DETAILS
	-- ============================
	local ambient = Instance.new("Folder")
	ambient.Name = "AmbientDetails"
	ambient.Parent = map

	-- Seagull perch points (decorative)
	local perchPositions = {
		Vector3.new(0, 97, -80), -- lighthouse top
		Vector3.new(-35, 3, 130), -- pier
		Vector3.new(55, 8, 125), -- boathouse roof
	}
	for i, pos in perchPositions do
		local perch = Instance.new("Part")
		perch.Name = "SeagullPerch_" .. i
		perch.Shape = Enum.PartType.Ball
		perch.Size = Vector3.new(0.8, 0.8, 0.8)
		perch.Color = Color3.fromRGB(240, 240, 235)
		perch.Material = Enum.Material.SmoothPlastic
		perch.Position = pos
		perch.Anchored = true
		perch.CanCollide = false
		perch.Parent = ambient
	end

	-- Barrel clusters near harbor
	for i = 1, 4 do
		local barrel = createPart(ambient, "Barrel_" .. i,
			Vector3.new(1.5, 2, 1.5),
			Vector3.new(25 + i * 3, 1, 108),
			COLORS.wood_dark, MATERIALS.wood)
		barrel.Shape = Enum.PartType.Cylinder
	end

	-- Crates near general store
	for i = 1, 3 do
		createPart(ambient, "Crate_" .. i,
			Vector3.new(2, 2, 2),
			Vector3.new(-56 + i * 2.5, 1 + (i-1) * 0.5, 30),
			COLORS.wood, MATERIALS.wood)
	end

	-- ============================
	-- ENHANCED LIGHTING
	-- ============================
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.Ambient = Color3.fromRGB(50, 55, 65)
	Lighting.OutdoorAmbient = Color3.fromRGB(100, 110, 125)
	Lighting.FogEnd = 1500
	Lighting.FogColor = Color3.fromRGB(180, 195, 210)
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.4

	-- Sky
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.CelestialBodiesShown = true
		sky.StarCount = 3000
		sky.MoonAngularSize = 11
		sky.SunAngularSize = 21
		sky.Parent = Lighting
	end

	-- Atmosphere
	local atmosphere = Lighting:FindFirstChild("DefaultAtmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "DefaultAtmosphere"
		atmosphere.Density = 0.2
		atmosphere.Offset = 0.25
		atmosphere.Color = Color3.fromRGB(200, 210, 225)
		atmosphere.Decay = Color3.fromRGB(140, 150, 170)
		atmosphere.Glare = 0
		atmosphere.Haze = 1
		atmosphere.Parent = Lighting
	end

	-- Sun rays
	local sunRays = Lighting:FindFirstChild("SunRays")
	if not sunRays then
		sunRays = Instance.new("SunRaysEffect")
		sunRays.Name = "SunRays"
		sunRays.Intensity = 0.06
		sunRays.Spread = 0.5
		sunRays.Parent = Lighting
	end

	-- Color correction for warm coastal feel
	local colorCorrection = Lighting:FindFirstChild("DefaultCC")
	if not colorCorrection then
		colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.Name = "DefaultCC"
		colorCorrection.Brightness = 0.02
		colorCorrection.Contrast = 0.05
		colorCorrection.Saturation = 0.1
		colorCorrection.TintColor = Color3.fromRGB(255, 250, 245)
		colorCorrection.Parent = Lighting
	end

	-- Subtle bloom for sun highlights
	local defaultBloom = Lighting:FindFirstChild("DefaultBloom")
	if not defaultBloom then
		defaultBloom = Instance.new("BloomEffect")
		defaultBloom.Name = "DefaultBloom"
		defaultBloom.Intensity = 0.3
		defaultBloom.Size = 30
		defaultBloom.Threshold = 0.95
		defaultBloom.Parent = Lighting
	end

	print("[MapGenerator] Enhanced Stormhaven generated!")
	print("  - Terrain: ground, cliffs, beach, ocean, paths")
	print("  - Buildings: 6 houses, 6 shops/services, lighthouse")
	print("  - Foliage: trees, grass tufts, decorative rocks")
	print("  - NPCs: 3 town NPCs with models")
	print("  - Lighting: sky, atmosphere, sun rays, color correction")
	print("  - Resource nodes: " .. tostring(resourceSystem and #resourceSystem.nodes or "N/A"))

	return map
end

return MapGenerator
