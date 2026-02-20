--[[
	MapGenerator.luau
	Generates a greybox/placeholder version of Stormhaven for testing.
	Creates terrain, buildings, resource nodes, and interactable objects
	using basic Part geometry. Replace with proper meshes/models later.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MapGenerator = {}

-- Color palette
local COLORS = {
	ground = Color3.fromRGB(120, 135, 100),
	sand = Color3.fromRGB(210, 195, 150),
	rock = Color3.fromRGB(130, 125, 120),
	water = Color3.fromRGB(60, 100, 140),
	wood = Color3.fromRGB(140, 100, 60),
	stone_wall = Color3.fromRGB(180, 175, 170),
	roof = Color3.fromRGB(120, 55, 45),
	cobblestone = Color3.fromRGB(155, 150, 145),
	lighthouse = Color3.fromRGB(240, 235, 230),
	lighthouse_red = Color3.fromRGB(200, 50, 40),
	pier = Color3.fromRGB(130, 95, 55),
	metal = Color3.fromRGB(160, 160, 165),
	glass = Color3.fromRGB(180, 210, 230),
	grass = Color3.fromRGB(90, 140, 70),
	marsh = Color3.fromRGB(80, 100, 60),
	cliff = Color3.fromRGB(150, 140, 130),
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
	part.Parent = parent
	return part
end

-- Helper: create a building (walls + roof + floor)
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

	-- Door gap (cut front wall — just make the front wall shorter with a gap)
	local doorway = createPart(folder, "Doorway", Vector3.new(4, wallHeight, wallThickness + 0.2),
		position + Vector3.new(0, wallHeight/2, -d/2 + wallThickness/2),
		COLORS.stone_wall, MATERIALS.stone)
	doorway.Transparency = 1
	doorway.CanCollide = false
	doorway:SetAttribute("InteractType", "Building")
	doorway:SetAttribute("BuildingId", name)

	-- Roof
	createPart(folder, "Roof", Vector3.new(w + 2, 0.5, d + 2),
		position + Vector3.new(0, wallHeight + 0.25, 0),
		roofColor or COLORS.roof, MATERIALS.wood)

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
	elseif nodeType == "tide_pool" then
		part.Size = Vector3.new(3, 0.3, 3)
		part.Color = Color3.fromRGB(80, 130, 160)
		part.Material = Enum.Material.Glass
		part.Transparency = 0.3
	elseif nodeType == "herb_patch" then
		part.Size = Vector3.new(2, 0.5, 2)
		part.Color = COLORS.grass
		part.Material = MATERIALS.ground
	elseif nodeType == "oil_barrel" then
		part.Size = Vector3.new(1.5, 2.5, 1.5)
		part.Color = Color3.fromRGB(50, 50, 55)
		part.Material = MATERIALS.metal
		part.Shape = Enum.PartType.Cylinder
	elseif nodeType == "cloth_source" then
		part.Size = Vector3.new(2, 1, 2)
		part.Color = Color3.fromRGB(200, 195, 185)
		part.Material = Enum.Material.Fabric
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

	-- Main ground plate (town area)
	createPart(terrain, "MainGround", Vector3.new(500, 3, 500),
		Vector3.new(0, -1.5, 0), COLORS.ground, MATERIALS.ground)

	-- Elevated cliff for lighthouse
	createPart(terrain, "LighthouseCliff", Vector3.new(80, 60, 80),
		Vector3.new(0, 30, -80), COLORS.cliff, MATERIALS.rock)

	-- Ramp to lighthouse
	local ramp = createPart(terrain, "LighthouseRamp", Vector3.new(8, 1, 100),
		Vector3.new(0, 30, -30), COLORS.cobblestone, MATERIALS.cobblestone)
	ramp.Orientation = Vector3.new(-17, 0, 0)

	-- Residential hill (elevated)
	createPart(terrain, "ResidentialHill", Vector3.new(200, 20, 150),
		Vector3.new(-50, 10, -30), COLORS.ground, MATERIALS.ground)

	-- Harbor area (at sea level)
	createPart(terrain, "HarborGround", Vector3.new(200, 1, 100),
		Vector3.new(0, 0, 100), COLORS.sand, MATERIALS.sand)

	-- Rocky shore
	for i = 1, 10 do
		local x = math.random(-200, 200)
		local z = 150 + math.random(0, 50)
		createPart(terrain, "Rock_" .. i, Vector3.new(math.random(3, 8), math.random(2, 5), math.random(3, 8)),
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
		Vector3.new(0, 0.15, 40), COLORS.cobblestone, MATERIALS.cobblestone)

	-- ============================
	-- LIGHTHOUSE (Central Hub)
	-- ============================
	local lighthouse = Instance.new("Folder")
	lighthouse.Name = "Lighthouse"
	lighthouse.Parent = map

	-- Tower base
	createPart(lighthouse, "Tower_Base", Vector3.new(10, 30, 10),
		Vector3.new(0, 75, -80), COLORS.lighthouse, MATERIALS.stone)

	-- Red stripe
	createPart(lighthouse, "Tower_Stripe", Vector3.new(10.2, 5, 10.2),
		Vector3.new(0, 80, -80), COLORS.lighthouse_red, MATERIALS.stone)

	-- Beacon room
	createPart(lighthouse, "Beacon_Room", Vector3.new(12, 6, 12),
		Vector3.new(0, 93, -80), COLORS.glass, MATERIALS.glass)

	-- Beacon light
	local beacon = createPart(lighthouse, "Beacon", Vector3.new(3, 3, 3),
		Vector3.new(0, 93, -80), Color3.fromRGB(255, 255, 200), Enum.Material.Neon)
	beacon.Shape = Enum.PartType.Ball

	local pointLight = Instance.new("PointLight")
	pointLight.Color = Color3.fromRGB(255, 240, 180)
	pointLight.Brightness = 3
	pointLight.Range = 80
	pointLight.Parent = beacon

	-- Storm Forge placeholder
	local stormForge = createPart(lighthouse, "StormForge", Vector3.new(3, 2, 3),
		Vector3.new(5, 61, -80), Color3.fromRGB(80, 60, 120), Enum.Material.Neon)
	stormForge:SetAttribute("InteractType", "CraftStation")
	stormForge:SetAttribute("StationId", "storm_forge")

	-- Campfire
	local campfire = createPart(lighthouse, "Campfire", Vector3.new(3, 0.5, 3),
		Vector3.new(-10, 60.5, -75), Color3.fromRGB(200, 100, 30), Enum.Material.Neon)
	campfire:SetAttribute("InteractType", "Campfire")
	local fireLight = Instance.new("PointLight")
	fireLight.Color = Color3.fromRGB(255, 150, 50)
	fireLight.Brightness = 2
	fireLight.Range = 25
	fireLight.Parent = campfire

	-- ============================
	-- HARBOR DISTRICT
	-- ============================
	local harbor = Instance.new("Folder")
	harbor.Name = "HarborDistrict"
	harbor.Parent = map

	-- Pier
	createPart(harbor, "Pier", Vector3.new(80, 1, 8),
		Vector3.new(0, 1.5, 130), COLORS.pier, MATERIALS.wood)

	-- Pier posts
	for i = 0, 7 do
		createPart(harbor, "PierPost_" .. i, Vector3.new(1, 5, 1),
			Vector3.new(-35 + i * 10, -1, 130), COLORS.pier, MATERIALS.wood)
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
	createBuilding(harbor, "fish_market", Vector3.new(50, 0, 110),
		Vector3.new(12, 6, 8), 7, nil, {
			InteractType = "NPC",
			NPCId = "fishmonger",
		})

	-- Boathouse
	createBuilding(harbor, "boathouse", Vector3.new(55, 0, 125),
		Vector3.new(12, 5, 10), 6, nil, nil)

	-- Dock
	local dock = createPart(harbor, "Dock", Vector3.new(15, 1, 20),
		Vector3.new(60, 1, 135), COLORS.pier, MATERIALS.wood)
	dock:SetAttribute("InteractType", "CraftStation")
	dock:SetAttribute("StationId", "boat_workshop")

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

	-- Blacksmith
	local blacksmith = createBuilding(mainStreet, "blacksmith", Vector3.new(-25, 0, 35),
		Vector3.new(12, 6, 10), 8, nil, {
			InteractType = "CraftStation",
			StationId = "anvil",
			RestorableBuilding = true,
		})

	-- Town Hall
	createBuilding(mainStreet, "town_hall", Vector3.new(0, 0, 35),
		Vector3.new(16, 6, 12), 10, nil, nil)

	-- Tavern
	local tavern = createBuilding(mainStreet, "tavern", Vector3.new(-50, 0, 50),
		Vector3.new(14, 6, 10), 8, nil, {
			InteractType = "NPC",
			NPCId = "barkeep",
			RestorableBuilding = true,
		})

	-- Stove inside tavern
	local stove = createPart(tavern, "Stove", Vector3.new(2, 2, 2),
		Vector3.new(-50, 1, 50), Color3.fromRGB(60, 60, 60), MATERIALS.metal)
	stove:SetAttribute("InteractType", "CraftStation")
	stove:SetAttribute("StationId", "stove")

	-- Clinic
	local clinic = createBuilding(mainStreet, "clinic", Vector3.new(-25, 0, 50),
		Vector3.new(12, 6, 10), 8, nil, {
			InteractType = "CraftStation",
			StationId = "medical_table",
			RestorableBuilding = true,
		})

	-- Garage
	createBuilding(mainStreet, "garage", Vector3.new(0, 0, 50),
		Vector3.new(14, 6, 12), 7, COLORS.metal, nil)

	-- Street lamps
	for i = -3, 3 do
		local lampPost = createPart(mainStreet, "Lamp_" .. i, Vector3.new(0.5, 8, 0.5),
			Vector3.new(i * 25, 4, 42), COLORS.metal, MATERIALS.metal)

		local lampLight = Instance.new("PointLight")
		lampLight.Color = Color3.fromRGB(255, 230, 180)
		lampLight.Brightness = 1
		lampLight.Range = 20
		lampLight.Parent = lampPost
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
		local houseFolder = createBuilding(residential, house.id, house.pos, house.size, 8, nil, {
			InteractType = "Building",
			BuildingId = house.id,
			Claimable = true,
		})
	end

	-- Watchtower extension
	createPart(residential, "Watchtower", Vector3.new(4, 15, 4),
		Vector3.new(-80, 35.5, -30), COLORS.stone_wall, MATERIALS.stone)

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

	-- Near lighthouse
	createResourceNode(resources, "rock_deposit", Vector3.new(20, 60.5, -90), resourceSystem)
	createResourceNode(resources, "driftwood", Vector3.new(-20, 60.5, -70), resourceSystem)

	-- ============================
	-- SPAWN POINT
	-- ============================
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(25, 1, 105)
	spawn.Color = Color3.fromRGB(100, 200, 100)
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.5
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Parent = map

	-- ============================
	-- AMBIENT LIGHTING
	-- ============================
	-- Set up initial calm weather lighting
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 14 -- Afternoon
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(40, 45, 55)
	Lighting.OutdoorAmbient = Color3.fromRGB(90, 100, 115)
	Lighting.FogEnd = 1000
	Lighting.FogColor = Color3.fromRGB(180, 195, 210)

	print("[MapGenerator] Stormhaven generated!")
	print("  - Terrain pieces: ground, cliffs, beach, ocean")
	print("  - Buildings: 6 houses, 6 shops/services, lighthouse")
	print("  - Resource nodes: " .. tostring(resourceSystem and #resourceSystem.nodes or "N/A"))

	return map
end

return MapGenerator
