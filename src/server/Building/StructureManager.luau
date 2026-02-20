--[[
	StructureManager.luau
	Server-side building and fortification system.
	Tracks structural integrity of all buildings, handles damage, repairs, and claims.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StructureManager = {}
StructureManager.__index = StructureManager

-- Fortification tiers and their properties
local FORTIFICATION_TIERS = {
	{
		id = "wooden_boards",
		name = "Wooden Boards",
		maxHP = 50,
		craftItem = "wooden_boards",
		repairCost = { { "wood", 2 } },
	},
	{
		id = "reinforced_planks",
		name = "Reinforced Planks",
		maxHP = 100,
		craftItem = "reinforced_planks",
		repairCost = { { "wood", 2 }, { "iron_ore", 1 } },
	},
	{
		id = "metal_shutters",
		name = "Metal Shutters",
		maxHP = 200,
		craftItem = "metal_shutters",
		repairCost = { { "iron_ore", 2 }, { "scrap_metal", 1 } },
	},
	{
		id = "storm_glass",
		name = "Storm Glass",
		maxHP = 300,
		craftItem = "storm_glass",
		repairCost = { { "glass", 2 }, { "iron_ore", 1 } },
	},
	{
		id = "storm_crystal_barriers",
		name = "Storm Crystal Barriers",
		maxHP = 500,
		craftItem = "storm_crystal_barriers",
		repairCost = { { "storm_crystal", 1 } },
		regenerates = true,
		regenRate = 5, -- HP per second between storms
	},
}

-- Building types in Stormhaven
local BUILDING_TYPES = {
	-- Houses (claimable)
	{
		id = "cliff_house",
		name = "Cliff House",
		claimable = true,
		wallCount = 8,
		roofSections = 2,
		bonus = "High ground, good visibility",
		vulnerability = "Wind-exposed",
	},
	{
		id = "cellar_house",
		name = "Cellar House",
		claimable = true,
		wallCount = 8,
		roofSections = 2,
		bonus = "Underground shelter, flood-resistant",
		vulnerability = "Cave-in risk in earthquakes",
	},
	{
		id = "garden_house",
		name = "Garden House",
		claimable = true,
		wallCount = 8,
		roofSections = 2,
		bonus = "Farming plots, greenhouse potential",
		vulnerability = "Exposed garden",
	},
	{
		id = "watchtower_house",
		name = "Watchtower House",
		claimable = true,
		wallCount = 8,
		roofSections = 3,
		bonus = "Tallest building, radio antenna",
		vulnerability = "Lightning target",
	},
	{
		id = "workshop_house",
		name = "Workshop House",
		claimable = true,
		wallCount = 8,
		roofSections = 2,
		bonus = "Pre-built crafting stations",
		vulnerability = "Fire risk from forge",
	},
	{
		id = "seaside_cottage",
		name = "Seaside Cottage",
		claimable = true,
		wallCount = 6,
		roofSections = 1,
		bonus = "Dock access, fishing bonus",
		vulnerability = "Flood risk",
	},
	-- Shared buildings (restorable)
	{
		id = "blacksmith",
		name = "Blacksmith",
		claimable = false,
		wallCount = 6,
		roofSections = 2,
		restorationCost = { { "wood", 20 }, { "stone", 15 }, { "iron_ore", 10 } },
		unlocks = "Metal crafting (Anvil station)",
	},
	{
		id = "clinic",
		name = "Clinic",
		claimable = false,
		wallCount = 6,
		roofSections = 2,
		restorationCost = { { "wood", 15 }, { "cloth", 10 }, { "glass", 5 } },
		unlocks = "Medical crafting + respawn point",
	},
	{
		id = "general_store",
		name = "General Store",
		claimable = false,
		wallCount = 6,
		roofSections = 2,
		restorationCost = { { "wood", 15 }, { "scrap_metal", 10 } },
		unlocks = "NPC shop restocks supplies",
	},
	{
		id = "tavern",
		name = "Tavern",
		claimable = false,
		wallCount = 8,
		roofSections = 2,
		restorationCost = { { "wood", 20 }, { "cloth", 8 }, { "glass", 4 } },
		unlocks = "Food crafting (Stove) + jukebox + NPC hints",
	},
	{
		id = "church",
		name = "Church",
		claimable = false,
		wallCount = 10,
		roofSections = 3,
		restorationCost = { { "wood", 25 }, { "stone", 20 }, { "glass", 8 } },
		unlocks = "Healing aura zone + bell tower early warning",
	},
	{
		id = "dock",
		name = "Dock",
		claimable = false,
		wallCount = 4,
		roofSections = 1,
		restorationCost = { { "wood", 25 }, { "rope", 15 }, { "iron_ore", 5 } },
		unlocks = "Boat crafting (Boat Workshop) + ocean access",
	},
}

function StructureManager.new()
	local self = setmetatable({}, StructureManager)

	self.buildings = {} -- buildingId -> building state
	self.claims = {} -- playerId -> buildingId
	self.restoredBuildings = {} -- set of restored shared building IDs

	-- Initialize all buildings
	for _, buildingType in BUILDING_TYPES do
		self.buildings[buildingType.id] = {
			type = buildingType,
			walls = {}, -- wallIndex -> { fortTier, currentHP, maxHP }
			roofSections = {}, -- roofIndex -> { currentHP, maxHP }
			isRestored = not buildingType.restorationCost, -- houses start usable
			claimedBy = nil,
		}

		-- Initialize walls (all start unfortified)
		for i = 1, buildingType.wallCount do
			self.buildings[buildingType.id].walls[i] = {
				fortTier = 0, -- 0 = no fortification
				currentHP = 0,
				maxHP = 0,
			}
		end

		-- Initialize roof sections
		for i = 1, buildingType.roofSections do
			self.buildings[buildingType.id].roofSections[i] = {
				currentHP = 30, -- roofs start with base HP
				maxHP = 30,
			}
		end
	end

	return self
end

-- Claim a house for a player
function StructureManager:claimBuilding(playerId: number, buildingId: string): (boolean, string)
	local building = self.buildings[buildingId]
	if not building then
		return false, "Building not found"
	end

	if not building.type.claimable then
		return false, "This building cannot be claimed"
	end

	if building.claimedBy then
		return false, "Already claimed by another player"
	end

	-- Check if player already has a claim
	if self.claims[playerId] then
		return false, "You already have a claimed building"
	end

	building.claimedBy = playerId
	self.claims[playerId] = buildingId
	return true, "Building claimed!"
end

-- Fortify a wall section
function StructureManager:fortifyWall(buildingId: string, wallIndex: number, fortTierId: string): (boolean, string)
	local building = self.buildings[buildingId]
	if not building then
		return false, "Building not found"
	end

	local wall = building.walls[wallIndex]
	if not wall then
		return false, "Invalid wall section"
	end

	-- Find the fortification tier
	local tierData = nil
	local tierIndex = 0
	for i, tier in FORTIFICATION_TIERS do
		if tier.id == fortTierId then
			tierData = tier
			tierIndex = i
			break
		end
	end

	if not tierData then
		return false, "Invalid fortification type"
	end

	-- Must be upgrading (higher tier than current)
	if tierIndex <= wall.fortTier then
		return false, "Wall already has equal or better fortification"
	end

	wall.fortTier = tierIndex
	wall.maxHP = tierData.maxHP
	wall.currentHP = tierData.maxHP

	return true, "Wall fortified with " .. tierData.name
end

-- Apply storm damage to a building
function StructureManager:applyStormDamage(buildingId: string, damagePerWall: number, roofDamage: number)
	local building = self.buildings[buildingId]
	if not building or not building.isRestored then
		return
	end

	-- Damage walls
	for _, wall in building.walls do
		if wall.fortTier > 0 then
			wall.currentHP = math.max(0, wall.currentHP - damagePerWall)
			if wall.currentHP <= 0 then
				wall.fortTier = 0
				wall.maxHP = 0
				-- Wall destroyed — fire event for morale penalty
			end
		end
	end

	-- Damage roof
	for _, roof in building.roofSections do
		roof.currentHP = math.max(0, roof.currentHP - roofDamage)
	end
end

-- Repair a wall section
function StructureManager:repairWall(buildingId: string, wallIndex: number, repairAmount: number): boolean
	local building = self.buildings[buildingId]
	if not building then return false end

	local wall = building.walls[wallIndex]
	if not wall or wall.fortTier == 0 then return false end

	wall.currentHP = math.min(wall.maxHP, wall.currentHP + repairAmount)
	return true
end

-- Restore a shared building
function StructureManager:restoreBuilding(buildingId: string): (boolean, string)
	local building = self.buildings[buildingId]
	if not building then
		return false, "Building not found"
	end

	if building.isRestored then
		return false, "Building already restored"
	end

	if not building.type.restorationCost then
		return false, "Building doesn't need restoration"
	end

	building.isRestored = true
	self.restoredBuildings[buildingId] = true

	return true, building.type.name .. " restored! Unlocked: " .. (building.type.unlocks or "")
end

-- Check if a building has intact roof (for shelter checks)
function StructureManager:hasIntactRoof(buildingId: string): boolean
	local building = self.buildings[buildingId]
	if not building then return false end

	for _, roof in building.roofSections do
		if roof.currentHP <= 0 then
			return false
		end
	end
	return true
end

-- Regenerate storm crystal barriers between storms
function StructureManager:regenerateBarriers(deltaTime: number)
	for _, building in self.buildings do
		for _, wall in building.walls do
			if wall.fortTier == 5 then -- Storm Crystal tier
				local tierData = FORTIFICATION_TIERS[5]
				if tierData.regenerates and wall.currentHP < wall.maxHP then
					wall.currentHP = math.min(wall.maxHP, wall.currentHP + (tierData.regenRate * deltaTime))
				end
			end
		end
	end
end

-- Get building state for client replication
function StructureManager:getBuildingState(buildingId: string)
	local building = self.buildings[buildingId]
	if not building then return nil end

	local wallStates = {}
	for i, wall in building.walls do
		wallStates[i] = {
			tier = wall.fortTier,
			hp = wall.currentHP,
			maxHP = wall.maxHP,
		}
	end

	return {
		id = buildingId,
		name = building.type.name,
		isRestored = building.isRestored,
		claimedBy = building.claimedBy,
		walls = wallStates,
		hasRoof = self:hasIntactRoof(buildingId),
	}
end

-- Get all building states
function StructureManager:getAllBuildingStates()
	local states = {}
	for id, _ in self.buildings do
		states[id] = self:getBuildingState(id)
	end
	return states
end

return StructureManager
