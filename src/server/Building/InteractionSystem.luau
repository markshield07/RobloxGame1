--[[
	InteractionSystem.luau
	Server-side interaction handler for 99 Storms.
	Processes all player interactions: gathering, crafting, building, NPCs, taming.
	Acts as the central dispatcher between player actions and game systems.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InteractionSystem = {}
InteractionSystem.__index = InteractionSystem

function InteractionSystem.new()
	local self = setmetatable({}, InteractionSystem)

	-- System references (set during init)
	self.inventoryManager = nil
	self.playerCharacter = nil
	self.craftingManager = nil
	self.structureManager = nil
	self.resourceGathering = nil
	self.npcManager = nil
	self.tamingSystem = nil
	self.combatSystem = nil
	self.stormManager = nil

	-- Active gathering sessions: userId -> { nodeId, startTime, duration }
	self.gatheringSessions = {}

	return self
end

function InteractionSystem:init(systems)
	self.inventoryManager = systems.inventoryManager
	self.playerCharacter = systems.playerCharacter
	self.craftingManager = systems.craftingManager
	self.structureManager = systems.structureManager
	self.resourceGathering = systems.resourceGathering
	self.npcManager = systems.npcManager
	self.tamingSystem = systems.tamingSystem
	self.combatSystem = systems.combatSystem
	self.stormManager = systems.stormManager
end

-- ================================
-- RESOURCE GATHERING
-- ================================

function InteractionSystem:startGathering(player: Player, nodeId: string): (boolean, string, number?)
	local userId = player.UserId
	local node = self.resourceGathering.nodes[nodeId]

	if not node then return false, "Resource not found.", nil end
	if not node.isActive then return false, "Resource is depleted.", nil end

	-- Check if already gathering
	if self.gatheringSessions[userId] then
		return false, "Already gathering.", nil
	end

	-- Check tool requirement
	local hasTool = true
	if node.requiredTool then
		hasTool = self.inventoryManager:hasItem(userId, node.requiredTool)
	end

	if not hasTool then
		return false, "You need a " .. node.requiredTool .. ".", nil
	end

	-- Start gathering session
	self.gatheringSessions[userId] = {
		nodeId = nodeId,
		startTime = tick(),
		duration = node.gatherTime,
	}

	return true, "Gathering...", node.gatherTime
end

function InteractionSystem:completeGathering(player: Player): (boolean, string, { { item: string, count: number } }?)
	local userId = player.UserId
	local session = self.gatheringSessions[userId]

	if not session then return false, "Not gathering.", nil end

	local elapsed = tick() - session.startTime
	if elapsed < session.duration then
		return false, "Still gathering... (" .. math.ceil(session.duration - elapsed) .. "s)", nil
	end

	-- Complete the gather
	local node = self.resourceGathering.nodes[session.nodeId]
	local hasTool = true
	if node and node.requiredTool then
		hasTool = self.inventoryManager:hasItem(userId, node.requiredTool)
	end

	local success, msg, drops = self.resourceGathering:gather(session.nodeId, userId, hasTool)

	if success and drops then
		for _, drop in drops do
			local added = self.inventoryManager:addItem(userId, drop.item, drop.count)
			if added < drop.count then
				-- Inventory full for this item
			end
		end
	end

	self.gatheringSessions[userId] = nil
	return success, msg, drops
end

function InteractionSystem:cancelGathering(player: Player)
	self.gatheringSessions[player.UserId] = nil
end

-- ================================
-- CRAFTING
-- ================================

function InteractionSystem:craftItem(player: Player, recipeId: string, stationId: string): (boolean, string)
	local userId = player.UserId
	local state = self.playerCharacter:getState(userId)
	local classId = state and state.classId or "weatherman"
	local currentStorm = self.stormManager.currentStorm
	local inv = self.inventoryManager:getInventory(userId)

	local success, msg, resultItem, resultCount = self.craftingManager:craft(
		recipeId, stationId, currentStorm, inv, classId
	)

	if success and resultItem then
		-- Consume ingredients
		local recipe = nil
		local CraftingRecipes = require(ReplicatedStorage.Shared.Config.CraftingRecipes)
		for _, r in CraftingRecipes.RECIPES do
			if r.id == recipeId then
				recipe = r
				break
			end
		end

		if recipe then
			self.inventoryManager:consumeItems(userId, recipe.ingredients)
		end

		-- Add result
		self.inventoryManager:addItem(userId, resultItem, resultCount)
	end

	return success, msg
end

function InteractionSystem:getAvailableRecipes(player: Player, stationId: string)
	local currentStorm = self.stormManager.currentStorm
	return self.craftingManager:getStationRecipes(stationId, currentStorm)
end

-- ================================
-- BUILDING / FORTIFICATION
-- ================================

function InteractionSystem:claimHouse(player: Player, buildingId: string): (boolean, string)
	return self.structureManager:claimBuilding(player.UserId, buildingId)
end

function InteractionSystem:fortifyWall(player: Player, buildingId: string, wallIndex: number, fortTierId: string): (boolean, string)
	-- Check if player has the required fortification item
	if not self.inventoryManager:hasItem(player.UserId, fortTierId, 1) then
		return false, "You don't have " .. fortTierId
	end

	local success, msg = self.structureManager:fortifyWall(buildingId, wallIndex, fortTierId)
	if success then
		self.inventoryManager:removeItem(player.UserId, fortTierId, 1)
	end

	return success, msg
end

function InteractionSystem:repairWall(player: Player, buildingId: string, wallIndex: number): (boolean, string)
	local state = self.playerCharacter:getState(player.UserId)
	local repairAmount = 20
	if state and state.classId == "builder" then
		repairAmount = 60
	end

	local success = self.structureManager:repairWall(buildingId, wallIndex, repairAmount)
	return success, success and "Wall repaired!" or "Nothing to repair"
end

function InteractionSystem:restoreBuilding(player: Player, buildingId: string): (boolean, string)
	local building = self.structureManager.buildings[buildingId]
	if not building then return false, "Building not found" end
	if building.isRestored then return false, "Already restored" end

	local restorationCost = building.type.restorationCost
	if not restorationCost then return false, "Cannot be restored" end

	-- Check resources
	if not self.inventoryManager:hasItems(player.UserId, restorationCost) then
		return false, "Not enough resources to restore"
	end

	-- Consume resources
	self.inventoryManager:consumeItems(player.UserId, restorationCost)

	-- Restore
	local success, msg = self.structureManager:restoreBuilding(buildingId)

	-- Unlock crafting station if applicable
	if success then
		local stationMapping = {
			blacksmith = "anvil",
			tavern = "stove",
			clinic = "medical_table",
			dock = "boat_workshop",
		}
		local stationId = stationMapping[buildingId]
		if stationId then
			self.craftingManager:unlockStation(stationId)
		end
	end

	return success, msg
end

-- ================================
-- NPC INTERACTION
-- ================================

function InteractionSystem:talkToNPC(player: Player, npcId: string): (boolean, string?)
	local dialogue = self.npcManager:getDialogue(npcId)
	return dialogue ~= nil, dialogue
end

function InteractionSystem:tradeWithNPC(player: Player, npcId: string, tradeId: string): (boolean, string)
	local success, msg, trade = self.npcManager:executeTrade(npcId, tradeId)
	if not success or not trade then
		return false, msg
	end

	-- Check player has the give items
	if not self.inventoryManager:hasItems(player.UserId, trade.give) then
		return false, "You don't have the required items"
	end

	-- Execute trade
	self.inventoryManager:consumeItems(player.UserId, trade.give)
	for _, item in trade.receive do
		self.inventoryManager:addItem(player.UserId, item.item, item.count)
	end

	return true, msg
end

-- ================================
-- TAMING
-- ================================

function InteractionSystem:attemptTame(player: Player, creatureConfigId: string): (boolean, string)
	-- Find the tame config to check requirements
	local CreatureConfig = require(ReplicatedStorage.Shared.Config.CreatureConfig)
	local config = nil
	for _, t in CreatureConfig.TAMEABLE do
		if t.id == creatureConfigId then
			config = t
			break
		end
	end

	if not config then return false, "Cannot tame this creature" end

	local hasFood = self.inventoryManager:hasItem(player.UserId, config.tamingFood, 1)
	local hasWhistle = self.inventoryManager:hasItem(player.UserId, config.requiredWhistle, 1)

	local success, msg = self.tamingSystem:attemptTame(player, creatureConfigId, hasFood, hasWhistle)

	if success and hasFood then
		-- Consume the food
		self.inventoryManager:removeItem(player.UserId, config.tamingFood, 1)
	end

	return success, msg
end

-- ================================
-- FOOD / MEDICAL
-- ================================

function InteractionSystem:useItem(player: Player, itemId: string): (boolean, string)
	local userId = player.UserId

	-- Check if player has the item
	if not self.inventoryManager:hasItem(userId, itemId, 1) then
		return false, "You don't have " .. itemId
	end

	-- Try food
	local foodSuccess, foodMsg = self.playerCharacter:consumeFood(userId, itemId)
	if foodSuccess then
		self.inventoryManager:removeItem(userId, itemId, 1)
		return true, foodMsg
	end

	-- Try medical
	local medSuccess, medMsg = self.playerCharacter:useMedical(userId, itemId)
	if medSuccess then
		self.inventoryManager:removeItem(userId, itemId, 1)
		return true, medMsg
	end

	return false, "Cannot use this item"
end

-- ================================
-- COMBAT
-- ================================

function InteractionSystem:attackCreature(player: Player, creatureId: string): (boolean, string)
	local isStormActive = self.stormManager.state == "storm"
	return self.combatSystem:playerAttackCreature(player, creatureId, isStormActive)
end

-- ================================
-- LIGHTHOUSE
-- ================================

function InteractionSystem:fuelLighthouse(player: Player, fuelItem: string, count: number): (boolean, string)
	local userId = player.UserId
	if not self.inventoryManager:hasItem(userId, fuelItem, count) then
		return false, "Not enough " .. fuelItem
	end

	self.inventoryManager:removeItem(userId, fuelItem, count)
	-- TODO: Add fuel to lighthouse system
	return true, "Added " .. count .. "x " .. fuelItem .. " to the lighthouse"
end

return InteractionSystem
