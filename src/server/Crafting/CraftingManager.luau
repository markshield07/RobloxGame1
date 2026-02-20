--[[
	CraftingManager.luau
	Server-side crafting system for 99 Storms.
	Validates crafting requests, checks ingredients, and produces items.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CraftingRecipes = require(ReplicatedStorage.Shared.Config.CraftingRecipes)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local CraftingManager = {}
CraftingManager.__index = CraftingManager

function CraftingManager.new()
	local self = setmetatable({}, CraftingManager)

	-- Track which crafting stations are available (restored buildings)
	self.availableStations = {
		workbench = true, -- always available (Harbormaster's Office)
		anvil = false,    -- requires Blacksmith restoration
		stove = false,    -- requires Tavern restoration
		medical_table = false, -- requires Clinic restoration
		storm_forge = false,   -- requires Lighthouse upgrade
		boat_workshop = false, -- requires Dock restoration
		witchs_cauldron = false, -- found in Marshlands
	}

	self.onItemCrafted = nil -- callback(player, recipeId, resultItem, resultCount)

	return self
end

-- Unlock a crafting station (called when a building is restored)
function CraftingManager:unlockStation(stationId: string)
	if self.availableStations[stationId] ~= nil then
		self.availableStations[stationId] = true
	end
end

-- Check if a station is available
function CraftingManager:isStationAvailable(stationId: string): boolean
	return self.availableStations[stationId] == true
end

-- Get available recipes for a station at the current storm number
function CraftingManager:getStationRecipes(stationId: string, currentStorm: number): { any }
	if not self:isStationAvailable(stationId) then
		return {}
	end

	local stationRecipes = CraftingRecipes.getByStation(stationId)
	local available = {}

	for _, recipe in stationRecipes do
		if recipe.unlockStorm <= currentStorm then
			table.insert(available, recipe)
		end
	end

	return available
end

-- Attempt to craft an item
-- Returns: success, message, resultItem, resultCount
function CraftingManager:craft(
	recipeId: string,
	stationId: string,
	currentStorm: number,
	playerInventory: { [string]: number }, -- item -> count
	classId: string?
): (boolean, string, string?, number?)

	-- Find the recipe
	local recipe = nil
	for _, r in CraftingRecipes.RECIPES do
		if r.id == recipeId then
			recipe = r
			break
		end
	end

	if not recipe then
		return false, "Recipe not found.", nil, nil
	end

	-- Check station match
	if recipe.station ~= stationId then
		return false, "Wrong crafting station. This recipe requires: " .. recipe.station, nil, nil
	end

	-- Check station availability
	if not self:isStationAvailable(stationId) then
		return false, "This crafting station is not yet available. Restore the building first.", nil, nil
	end

	-- Check storm unlock
	if recipe.unlockStorm > currentStorm then
		return false, "This recipe unlocks at Storm " .. recipe.unlockStorm .. ".", nil, nil
	end

	-- Check ingredients
	for _, ingredient in recipe.ingredients do
		local itemId = ingredient[1]
		local required = ingredient[2]
		local have = playerInventory[itemId] or 0

		if have < required then
			return false, "Not enough " .. itemId .. " (need " .. required .. ", have " .. have .. ").", nil, nil
		end
	end

	-- Apply class bonuses
	local bonusCount = 0
	if classId == "builder" and recipe.category == "building" then
		-- Builder gets 25% chance of bonus output on building items
		if math.random() < 0.25 then
			bonusCount = 1
		end
	elseif classId == "keeper" and recipe.category == "food" then
		-- Keeper gets 25% chance of bonus output on food items
		if math.random() < 0.25 then
			bonusCount = 1
		end
	end

	-- Consume ingredients (caller handles actual inventory deduction)
	-- Return success with the items to consume and produce
	local resultItem = recipe.result[1]
	local resultCount = recipe.result[2] + bonusCount

	if self.onItemCrafted then
		self.onItemCrafted(recipeId, resultItem, resultCount)
	end

	local bonusMsg = bonusCount > 0 and " (Bonus: +" .. bonusCount .. "!)" or ""
	return true, "Crafted " .. resultCount .. "x " .. recipe.name .. "!" .. bonusMsg, resultItem, resultCount
end

-- Get all recipes grouped by category for a given storm progression
function CraftingManager:getRecipesByCategory(currentStorm: number): { [string]: { any } }
	local categorized = {}
	local available = CraftingRecipes.getAvailable(currentStorm)

	for _, recipe in available do
		if not categorized[recipe.category] then
			categorized[recipe.category] = {}
		end
		table.insert(categorized[recipe.category], recipe)
	end

	return categorized
end

-- Check what the player CAN craft with their current inventory
function CraftingManager:getAffordableRecipes(
	currentStorm: number,
	playerInventory: { [string]: number }
): { any }
	local affordable = {}
	local available = CraftingRecipes.getAvailable(currentStorm)

	for _, recipe in available do
		-- Check station availability
		if self:isStationAvailable(recipe.station) then
			-- Check all ingredients
			local canAfford = true
			for _, ingredient in recipe.ingredients do
				local have = playerInventory[ingredient[1]] or 0
				if have < ingredient[2] then
					canAfford = false
					break
				end
			end

			if canAfford then
				table.insert(affordable, recipe)
			end
		end
	end

	return affordable
end

return CraftingManager
