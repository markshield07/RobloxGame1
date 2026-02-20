--[[
	CraftingRecipes.luau
	All crafting recipes for 99 Storms.
	Organized by crafting station.
]]

local CraftingRecipes = {}

-- Recipe format:
-- { id, name, station, ingredients = {{item, count}}, result = {item, count}, unlockStorm }

CraftingRecipes.RECIPES = {

	-- =====================
	-- WORKBENCH (Basic)
	-- =====================
	{
		id = "wooden_club",
		name = "Driftwood Club",
		station = "workbench",
		category = "weapons",
		ingredients = { { "wood", 5 }, { "rope", 2 } },
		result = { "wooden_club", 1 },
		unlockStorm = 0,
	},
	{
		id = "fishing_rod",
		name = "Fishing Rod",
		station = "workbench",
		category = "tools",
		ingredients = { { "wood", 3 }, { "rope", 3 }, { "scrap_metal", 1 } },
		result = { "fishing_rod", 1 },
		unlockStorm = 0,
	},
	{
		id = "lantern",
		name = "Lantern",
		station = "workbench",
		category = "tools",
		ingredients = { { "scrap_metal", 3 }, { "glass", 1 }, { "oil", 2 } },
		result = { "lantern", 1 },
		unlockStorm = 0,
	},
	{
		id = "whistle",
		name = "Taming Whistle",
		station = "workbench",
		category = "tools",
		ingredients = { { "wood", 2 }, { "scrap_metal", 1 } },
		result = { "whistle", 1 },
		unlockStorm = 0,
	},
	{
		id = "wooden_fence",
		name = "Wooden Fence",
		station = "workbench",
		category = "building",
		ingredients = { { "wood", 8 }, { "rope", 2 } },
		result = { "wooden_fence", 1 },
		unlockStorm = 0,
	},
	{
		id = "wooden_boards",
		name = "Wooden Boards (Fortification)",
		station = "workbench",
		category = "building",
		ingredients = { { "wood", 4 } },
		result = { "wooden_boards", 2 },
		unlockStorm = 0,
	},
	{
		id = "sandbags",
		name = "Sandbags",
		station = "workbench",
		category = "building",
		ingredients = { { "cloth", 3 }, { "stone", 5 } },
		result = { "sandbags", 3 },
		unlockStorm = 0,
	},
	{
		id = "slingshot",
		name = "Slingshot",
		station = "workbench",
		category = "weapons",
		ingredients = { { "wood", 3 }, { "rope", 2 }, { "stone", 5 } },
		result = { "slingshot", 1 },
		unlockStorm = 0,
	},
	{
		id = "raincoat",
		name = "Raincoat",
		station = "workbench",
		category = "survival",
		ingredients = { { "cloth", 6 }, { "rope", 2 }, { "oil", 1 } },
		result = { "raincoat", 1 },
		unlockStorm = 0,
	},
	{
		id = "signal_flare",
		name = "Signal Flare",
		station = "workbench",
		category = "tools",
		ingredients = { { "scrap_metal", 2 }, { "oil", 3 } },
		result = { "signal_flare", 3 },
		unlockStorm = 0,
	},
	{
		id = "bed",
		name = "Bed",
		station = "workbench",
		category = "building",
		ingredients = { { "wood", 5 }, { "cloth", 5 } },
		result = { "bed", 1 },
		unlockStorm = 0,
	},
	{
		id = "lightning_rod",
		name = "Lightning Rod",
		station = "workbench",
		category = "building",
		ingredients = { { "scrap_metal", 5 }, { "copper_wire", 2 } },
		result = { "lightning_rod", 1 },
		unlockStorm = 5,
	},

	-- =====================
	-- ANVIL (Blacksmith)
	-- =====================
	{
		id = "iron_sword",
		name = "Iron Sword",
		station = "anvil",
		category = "weapons",
		ingredients = { { "iron_ore", 5 }, { "wood", 2 }, { "rope", 1 } },
		result = { "iron_sword", 1 },
		unlockStorm = 10,
	},
	{
		id = "iron_pickaxe",
		name = "Iron Pickaxe",
		station = "anvil",
		category = "tools",
		ingredients = { { "iron_ore", 4 }, { "wood", 3 } },
		result = { "iron_pickaxe", 1 },
		unlockStorm = 10,
	},
	{
		id = "reinforced_hammer",
		name = "Reinforced Hammer",
		station = "anvil",
		category = "tools",
		ingredients = { { "iron_ore", 3 }, { "wood", 2 }, { "stone", 3 } },
		result = { "reinforced_hammer", 1 },
		unlockStorm = 10,
	},
	{
		id = "crossbow",
		name = "Crossbow",
		station = "anvil",
		category = "weapons",
		ingredients = { { "iron_ore", 4 }, { "wood", 5 }, { "rope", 3 } },
		result = { "crossbow", 1 },
		unlockStorm = 15,
	},
	{
		id = "metal_shutters",
		name = "Metal Shutters (Fortification)",
		station = "anvil",
		category = "building",
		ingredients = { { "iron_ore", 6 }, { "scrap_metal", 3 } },
		result = { "metal_shutters", 2 },
		unlockStorm = 10,
	},
	{
		id = "reinforced_planks",
		name = "Reinforced Planks (Fortification)",
		station = "anvil",
		category = "building",
		ingredients = { { "wood", 4 }, { "iron_ore", 2 } },
		result = { "reinforced_planks", 2 },
		unlockStorm = 10,
	},
	{
		id = "harpoon",
		name = "Harpoon",
		station = "anvil",
		category = "weapons",
		ingredients = { { "iron_ore", 5 }, { "wood", 4 }, { "rope", 3 } },
		result = { "harpoon", 1 },
		unlockStorm = 20,
	},
	{
		id = "storm_shutters",
		name = "Storm Glass (Fortification)",
		station = "anvil",
		category = "building",
		ingredients = { { "glass", 6 }, { "iron_ore", 4 }, { "copper_wire", 2 } },
		result = { "storm_glass", 2 },
		unlockStorm = 25,
	},
	{
		id = "rubber_boots",
		name = "Rubber Boots",
		station = "anvil",
		category = "survival",
		ingredients = { { "scrap_metal", 2 }, { "oil", 4 }, { "cloth", 3 } },
		result = { "rubber_boots", 1 },
		unlockStorm = 15,
	},
	{
		id = "storm_goggles",
		name = "Storm Goggles",
		station = "anvil",
		category = "survival",
		ingredients = { { "glass", 2 }, { "scrap_metal", 3 }, { "cloth", 2 } },
		result = { "storm_goggles", 1 },
		unlockStorm = 10,
	},
	{
		id = "fog_horn",
		name = "Fog Horn",
		station = "anvil",
		category = "building",
		ingredients = { { "iron_ore", 4 }, { "copper_wire", 3 } },
		result = { "fog_horn", 1 },
		unlockStorm = 15,
	},
	{
		id = "bear_trap",
		name = "Bear Trap",
		station = "anvil",
		category = "building",
		ingredients = { { "iron_ore", 5 }, { "scrap_metal", 3 } },
		result = { "bear_trap", 2 },
		unlockStorm = 15,
	},

	-- =====================
	-- STOVE (Tavern)
	-- =====================
	{
		id = "cooked_fish",
		name = "Cooked Fish",
		station = "stove",
		category = "food",
		ingredients = { { "raw_fish", 1 } },
		result = { "cooked_fish", 1 },
		unlockStorm = 0,
	},
	{
		id = "fish_stew",
		name = "Fish Stew",
		station = "stove",
		category = "food",
		ingredients = { { "raw_fish", 2 }, { "herbs", 1 }, { "clam", 1 } },
		result = { "fish_stew", 1 },
		unlockStorm = 5,
	},
	{
		id = "clam_chowder",
		name = "Clam Chowder",
		station = "stove",
		category = "food",
		ingredients = { { "clam", 3 }, { "herbs", 1 }, { "vegetables", 1 } },
		result = { "clam_chowder", 1 },
		unlockStorm = 10,
	},
	{
		id = "herbal_tea",
		name = "Herbal Tea",
		station = "stove",
		category = "food",
		ingredients = { { "herbs", 3 } },
		result = { "herbal_tea", 1 },
		unlockStorm = 5,
	},
	{
		id = "storm_feast",
		name = "Storm Feast (Group)",
		station = "stove",
		category = "food",
		ingredients = { { "raw_fish", 3 }, { "clam", 2 }, { "vegetables", 2 }, { "herbs", 2 }, { "eggs", 2 } },
		result = { "storm_feast", 1 },
		unlockStorm = 20,
	},
	{
		id = "lobster_dinner",
		name = "Lobster Dinner",
		station = "stove",
		category = "food",
		ingredients = { { "lobster", 1 }, { "herbs", 1 }, { "vegetables", 1 } },
		result = { "lobster_dinner", 1 },
		unlockStorm = 15,
	},

	-- =====================
	-- MEDICAL TABLE (Clinic)
	-- =====================
	{
		id = "bandage",
		name = "Bandage",
		station = "medical_table",
		category = "medical",
		ingredients = { { "cloth", 3 } },
		result = { "bandage", 2 },
		unlockStorm = 0,
	},
	{
		id = "medical_kit",
		name = "Medical Kit",
		station = "medical_table",
		category = "medical",
		ingredients = { { "cloth", 4 }, { "herbs", 3 }, { "scrap_metal", 1 } },
		result = { "medical_kit", 1 },
		unlockStorm = 10,
	},
	{
		id = "antivenom",
		name = "Antivenom",
		station = "medical_table",
		category = "medical",
		ingredients = { { "snake_venom", 2 }, { "herbs", 3 } },
		result = { "antivenom", 1 },
		unlockStorm = 15,
	},
	{
		id = "insulated_jacket",
		name = "Insulated Jacket",
		station = "medical_table",
		category = "survival",
		ingredients = { { "cloth", 6 }, { "feathers", 4 }, { "rope", 2 } },
		result = { "insulated_jacket", 1 },
		unlockStorm = 20,
	},

	-- =====================
	-- STORM FORGE (Lighthouse)
	-- =====================
	{
		id = "storm_blade",
		name = "Storm Blade",
		station = "storm_forge",
		category = "weapons",
		ingredients = { { "iron_ore", 5 }, { "storm_crystal", 3 } },
		result = { "storm_blade", 1 },
		unlockStorm = 25,
	},
	{
		id = "storm_bow",
		name = "Storm Bow",
		station = "storm_forge",
		category = "weapons",
		ingredients = { { "wood", 4 }, { "storm_crystal", 3 }, { "rope", 2 } },
		result = { "storm_bow", 1 },
		unlockStorm = 25,
	},
	{
		id = "storm_crystal_barriers",
		name = "Storm Crystal Barriers",
		station = "storm_forge",
		category = "building",
		ingredients = { { "storm_crystal", 5 }, { "iron_ore", 3 }, { "glass", 2 } },
		result = { "storm_crystal_barriers", 2 },
		unlockStorm = 50,
	},
	{
		id = "storm_salve",
		name = "Storm Salve",
		station = "storm_forge",
		category = "medical",
		ingredients = { { "storm_crystal", 2 }, { "herbs", 3 } },
		result = { "storm_salve", 1 },
		unlockStorm = 25,
	},
	{
		id = "lightning_vest",
		name = "Lightning Vest",
		station = "storm_forge",
		category = "survival",
		ingredients = { { "storm_crystal", 4 }, { "cloth", 4 }, { "copper_wire", 3 } },
		result = { "lightning_vest", 1 },
		unlockStorm = 35,
	},
	{
		id = "portable_beacon",
		name = "Portable Beacon",
		station = "storm_forge",
		category = "tools",
		ingredients = { { "storm_crystal", 3 }, { "iron_ore", 2 }, { "glass", 2 } },
		result = { "portable_beacon", 1 },
		unlockStorm = 30,
	},
	{
		id = "storm_cannon",
		name = "Storm Cannon",
		station = "storm_forge",
		category = "weapons",
		ingredients = { { "storm_crystal", 6 }, { "iron_ore", 5 }, { "copper_wire", 4 } },
		result = { "storm_cannon", 1 },
		unlockStorm = 60,
	},
	{
		id = "storm_harpoon",
		name = "Storm Harpoon",
		station = "storm_forge",
		category = "weapons",
		ingredients = { { "storm_crystal", 4 }, { "iron_ore", 5 }, { "rope", 3 } },
		result = { "storm_harpoon", 1 },
		unlockStorm = 45,
	},

	-- =====================
	-- BOAT WORKSHOP (Dock)
	-- =====================
	{
		id = "raft",
		name = "Raft",
		station = "boat_workshop",
		category = "vehicles",
		ingredients = { { "wood", 10 }, { "rope", 5 } },
		result = { "raft", 1 },
		unlockStorm = 10,
	},
	{
		id = "rowboat",
		name = "Rowboat",
		station = "boat_workshop",
		category = "vehicles",
		ingredients = { { "wood", 15 }, { "iron_ore", 3 }, { "rope", 4 } },
		result = { "rowboat", 1 },
		unlockStorm = 20,
	},
	{
		id = "sailboat",
		name = "Sailboat",
		station = "boat_workshop",
		category = "vehicles",
		ingredients = { { "wood", 20 }, { "cloth", 10 }, { "iron_ore", 5 }, { "rope", 6 } },
		result = { "sailboat", 1 },
		unlockStorm = 35,
	},
	{
		id = "storm_vessel",
		name = "Storm Vessel",
		station = "boat_workshop",
		category = "vehicles",
		ingredients = { { "wood", 25 }, { "iron_ore", 10 }, { "storm_crystal", 5 }, { "cloth", 8 } },
		result = { "storm_vessel", 1 },
		unlockStorm = 60,
	},
	{
		id = "deep_sea_rod",
		name = "Deep Sea Rod",
		station = "boat_workshop",
		category = "tools",
		ingredients = { { "iron_ore", 4 }, { "rope", 4 }, { "storm_crystal", 1 } },
		result = { "deep_sea_rod", 1 },
		unlockStorm = 30,
	},

	-- =====================
	-- WITCH'S CAULDRON (Marshlands)
	-- =====================
	{
		id = "fog_piercer",
		name = "Fog Piercer Lantern",
		station = "witchs_cauldron",
		category = "tools",
		ingredients = { { "lantern", 1 }, { "herbs", 5 }, { "frog_legs", 3 } },
		result = { "fog_piercer", 1 },
		unlockStorm = 15,
	},
	{
		id = "storm_ward",
		name = "Storm Ward Potion",
		station = "witchs_cauldron",
		category = "survival",
		ingredients = { { "herbs", 4 }, { "snake_venom", 1 }, { "storm_crystal", 1 } },
		result = { "storm_ward", 1 },
		unlockStorm = 25,
	},
	{
		id = "tempest_lure",
		name = "Tempest Lure",
		station = "witchs_cauldron",
		category = "tools",
		ingredients = { { "storm_crystal", 3 }, { "herbs", 3 }, { "frog_legs", 2 } },
		result = { "tempest_lure", 1 },
		unlockStorm = 40,
	},
}

-- Helper: get recipes by station
function CraftingRecipes.getByStation(stationId: string)
	local result = {}
	for _, recipe in CraftingRecipes.RECIPES do
		if recipe.station == stationId then
			table.insert(result, recipe)
		end
	end
	return result
end

-- Helper: get recipes by category
function CraftingRecipes.getByCategory(categoryId: string)
	local result = {}
	for _, recipe in CraftingRecipes.RECIPES do
		if recipe.category == categoryId then
			table.insert(result, recipe)
		end
	end
	return result
end

-- Helper: get recipes available at a given storm number
function CraftingRecipes.getAvailable(currentStorm: number)
	local result = {}
	for _, recipe in CraftingRecipes.RECIPES do
		if recipe.unlockStorm <= currentStorm then
			table.insert(result, recipe)
		end
	end
	return result
end

return CraftingRecipes
