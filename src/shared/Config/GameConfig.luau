--[[
	GameConfig.luau
	Central configuration for 99 Storms.
	All balance numbers, timing, and game constants live here.
]]

local GameConfig = {}

-- General
GameConfig.GAME_NAME = "99 Storms"
GameConfig.MAX_PLAYERS = 5
GameConfig.TOTAL_STORMS = 99

-- Day Cycle (1 day = 3 real minutes)
GameConfig.DAY_DURATION = 180          -- 3 minutes per day
GameConfig.DAYTIME_DURATION = 110      -- ~1:50 of calm (explore/build/gather)
GameConfig.WARNING_DURATION = 15       -- 15 second storm warning
GameConfig.STORM_BASE_DURATION_DAY = 40 -- 40 second base storm duration per day
GameConfig.AFTERMATH_DURATION_DAY = 15  -- 15 second aftermath

-- Legacy timing (used as fallbacks)
GameConfig.CALM_DURATION = 110
GameConfig.STORM_WARNING_DURATION = 15
GameConfig.STORM_BASE_DURATION = 40
GameConfig.AFTERMATH_DURATION = 15

-- Storm outdoor exposure
GameConfig.STORM_EXPOSURE = {
	BASE_DAMAGE_PER_SECOND = 2,    -- base DPS when outside during storm
	SCALING_PER_DAY = 0.3,          -- extra DPS per day
	CREATURE_AGGRO_RANGE = 60,     -- creatures prioritize outdoor players
	SHADOW_SPAWN_CHANCE = 0.15,    -- chance per second to spawn shadow near outdoor player
}

-- Storm duration scaling (added per storm bracket)
GameConfig.STORM_DURATION_SCALING = {
	{ minStorm = 1,  maxStorm = 10,  bonusDuration = 0 },
	{ minStorm = 11, maxStorm = 25,  bonusDuration = 60 },
	{ minStorm = 26, maxStorm = 50,  bonusDuration = 120 },
	{ minStorm = 51, maxStorm = 75,  bonusDuration = 180 },
	{ minStorm = 76, maxStorm = 99,  bonusDuration = 240 },
}

-- Storm types and their unlock thresholds
GameConfig.STORM_TYPES = {
	{
		id = "thunderstorm",
		name = "Thunderstorm",
		unlockStorm = 1,
		weight = 30,
		description = "Heavy rain and lightning strikes target high points.",
	},
	{
		id = "fog",
		name = "Fog Storm",
		unlockStorm = 5,
		weight = 25,
		description = "Near-zero visibility. Listen for creatures.",
	},
	{
		id = "hurricane",
		name = "Hurricane",
		unlockStorm = 10,
		weight = 20,
		description = "Extreme wind destroys unfortified structures.",
	},
	{
		id = "hailstorm",
		name = "Hailstorm",
		unlockStorm = 20,
		weight = 15,
		description = "Constant AOE damage outdoors. Roofs matter.",
	},
	{
		id = "tornado",
		name = "Tornado",
		unlockStorm = 35,
		weight = 8,
		description = "A funnel tears through town. Get underground.",
	},
	{
		id = "tsunami",
		name = "Tsunami Warning",
		unlockStorm = 45,
		weight = 8,
		description = "Rising waters flood lower areas. Get to high ground.",
	},
	{
		id = "blood_storm",
		name = "Blood Storm",
		unlockStorm = 60,
		weight = 4,
		description = "The sky turns red. All creature types spawn.",
	},
	{
		id = "tempest_wrath",
		name = "The Tempest's Wrath",
		unlockStorm = 25,
		weight = 0, -- Special: forced on storms 25, 50, 75
		description = "The Tempest directly attacks. Boss encounter.",
	},
}

-- Boss storm numbers
GameConfig.BOSS_STORMS = { 25, 50, 75, 99 }

-- Lighthouse levels
GameConfig.LIGHTHOUSE_LEVELS = {
	{
		level = 1,
		name = "Oil Lanterns",
		radius = 15,
		fuelType = "oil",
		fuelRate = 1,
		bonus = "Basic light",
	},
	{
		level = 2,
		name = "Coal Furnace",
		radius = 25,
		fuelType = "coal",
		fuelRate = 0.8,
		bonus = "Reveals nearby storm creatures",
	},
	{
		level = 3,
		name = "Gas Generator",
		radius = 40,
		fuelType = "fuel",
		fuelRate = 0.6,
		bonus = "Slows storm creatures in radius",
	},
	{
		level = 4,
		name = "Electric Grid",
		radius = 60,
		fuelType = "electricity",
		fuelRate = 0.4,
		bonus = "Damages storm creatures + weather radar",
	},
	{
		level = 5,
		name = "Storm Crystal Core",
		radius = 80,
		fuelType = "storm_crystal",
		fuelRate = 0.2,
		bonus = "Weakens The Tempest itself",
	},
}

-- Classes (all free to choose)
GameConfig.CLASSES = {
	{
		id = "craftsman",
		name = "Craftsman",
		premium = false,
		price = 0,
		tagline = "I'll build us a fortress.",
		starterItems = { { "storm_crystal", 2 }, { "reinforced_planks", 5 }, { "metal_shutters", 3 }, { "iron_ore", 10 } },
		abilities = {
			"Master Builder: craft 50% faster",
			"Rare Materials: start with rare base upgrade materials",
			"Structural Insight: see building weak points",
			"Fortify Mastery: fortifications have 25% more HP",
		},
	},
	{
		id = "scout",
		name = "Scout",
		premium = false,
		price = 0,
		tagline = "I know every inch of this land.",
		starterItems = { { "lantern", 1 }, { "signal_flare", 3 }, { "herbs", 5 }, { "rope", 8 } },
		abilities = {
			"Eagle Eye: see loot containers through walls (glow)",
			"Swift Feet: 20% faster movement speed",
			"Scavenger: find 50% more items from containers",
			"Pathfinder: minimap shows nearby resources",
		},
	},
	{
		id = "medic",
		name = "Medic",
		premium = false,
		price = 0,
		tagline = "Nobody dies on my watch.",
		starterItems = { { "medical_kit", 3 }, { "bandage", 5 }, { "herbal_tea", 3 }, { "herbs", 10 } },
		abilities = {
			"Field Medic: healing items are 50% more effective",
			"Triage: revive downed teammates 2x faster",
			"Immunity: 30% resistance to poison and freeze",
			"Adrenaline: sprint doesn't drain stamina when teammate is down",
		},
	},
	{
		id = "warrior",
		name = "Warrior",
		premium = false,
		price = 0,
		tagline = "Let them come.",
		starterItems = { { "iron_sword", 1 }, { "bandage", 3 }, { "scrap_metal", 8 } },
		abilities = {
			"Battle Hardened: +25 max HP",
			"Heavy Strikes: deal 40% more damage to creatures",
			"Storm Armor: take 20% less damage from all sources",
			"Last Stand: when below 20% HP, deal double damage",
		},
	},
	{
		id = "stormchaser",
		name = "Stormchaser",
		premium = false,
		price = 0,
		tagline = "Into the eye.",
		starterItems = { { "storm_crystal", 1 }, { "storm_salve", 2 }, { "rope", 5 } },
		abilities = {
			"Storm Harvest: collect Storm Crystals during storms",
			"Lightning Rod: absorb strikes to charge weapons",
			"Tempest Taunt: draw aggro from structures/allies",
			"Eye of the Storm: brief invulnerability at peak",
		},
	},
}

-- Loot container configuration
GameConfig.LOOT_TABLES = {
	common = {
		{ id = "wood", min = 2, max = 5, weight = 30 },
		{ id = "stone", min = 2, max = 4, weight = 25 },
		{ id = "rope", min = 1, max = 3, weight = 20 },
		{ id = "cloth", min = 1, max = 3, weight = 20 },
		{ id = "raw_fish", min = 1, max = 2, weight = 15 },
		{ id = "bandage", min = 1, max = 2, weight = 10 },
	},
	uncommon = {
		{ id = "scrap_metal", min = 2, max = 5, weight = 25 },
		{ id = "iron_ore", min = 1, max = 3, weight = 20 },
		{ id = "copper_wire", min = 1, max = 3, weight = 15 },
		{ id = "oil", min = 1, max = 2, weight = 15 },
		{ id = "medical_kit", min = 1, max = 1, weight = 10 },
		{ id = "cooked_fish", min = 1, max = 2, weight = 10 },
		{ id = "wooden_boards", min = 2, max = 4, weight = 15 },
	},
	rare = {
		{ id = "storm_crystal", min = 1, max = 2, weight = 15 },
		{ id = "reinforced_planks", min = 2, max = 4, weight = 20 },
		{ id = "metal_shutters", min = 1, max = 2, weight = 15 },
		{ id = "storm_glass", min = 1, max = 2, weight = 10 },
		{ id = "storm_blade", min = 1, max = 1, weight = 5 },
		{ id = "iron_sword", min = 1, max = 1, weight = 10 },
		{ id = "storm_salve", min = 1, max = 2, weight = 10 },
		{ id = "storm_ward", min = 1, max = 1, weight = 8 },
	},
	legendary = {
		{ id = "storm_crystal_barriers", min = 1, max = 2, weight = 20 },
		{ id = "storm_crystal", min = 2, max = 4, weight = 25 },
		{ id = "reinforced_core", min = 1, max = 1, weight = 15 },
		{ id = "ancient_relic", min = 1, max = 1, weight = 10 },
		{ id = "storm_blade", min = 1, max = 1, weight = 10 },
		{ id = "storm_ward", min = 2, max = 3, weight = 15 },
	},
}

-- Base improvement rare items
GameConfig.BASE_IMPROVEMENTS = {
	reinforced_core = {
		name = "Reinforced Core",
		description = "Doubles base wall HP permanently",
		hpMultiplier = 2.0,
	},
	ancient_relic = {
		name = "Ancient Relic",
		description = "Base takes 30% less storm damage",
		damageReduction = 0.3,
	},
	storm_ward = {
		name = "Storm Ward",
		description = "Creates a protection field, reduces exposure damage near base",
		shieldRadius = 20,
	},
}

-- Badge definitions
GameConfig.BADGES = {
	{ id = "first_day",      name = "First Dawn",         description = "Survive Day 1",            requirement = "day", value = 1,  icon = "D1" },
	{ id = "week_one",       name = "Week One",           description = "Survive 7 days",           requirement = "day", value = 7,  icon = "W1" },
	{ id = "fortified",      name = "Fortified",          description = "Upgrade base to Tier 2+",  requirement = "fort", value = 2, icon = "FT" },
	{ id = "scavenger",      name = "Scavenger",          description = "Search 10 loot containers", requirement = "loot", value = 10, icon = "SC" },
	{ id = "storm_veteran",  name = "Storm Veteran",      description = "Survive 25 days",          requirement = "day", value = 25, icon = "SV" },
	{ id = "iron_will",      name = "Iron Will",          description = "Survive 50 days",          requirement = "day", value = 50, icon = "IW" },
	{ id = "creature_slayer",name = "Creature Slayer",    description = "Defeat 50 creatures",      requirement = "kills", value = 50, icon = "CS" },
	{ id = "master_crafter", name = "Master Crafter",     description = "Craft 25 items",           requirement = "crafts", value = 25, icon = "MC" },
	{ id = "legendary",      name = "Legendary Survivor", description = "Survive 99 days",          requirement = "day", value = 99, icon = "LS" },
	{ id = "first_boss",     name = "Boss Slayer",        description = "Survive a Tempest's Wrath", requirement = "boss", value = 1, icon = "BS" },
}

-- Multiplayer difficulty scaling
GameConfig.MULTIPLAYER_SCALING = {
	[1] = { creatureHP = 1.0, creatureCount = 1.0, stormDuration = 1.0, resources = 1.0 },
	[2] = { creatureHP = 1.3, creatureCount = 1.2, stormDuration = 1.0, resources = 1.15 },
	[3] = { creatureHP = 1.6, creatureCount = 1.5, stormDuration = 1.1, resources = 1.3 },
	[4] = { creatureHP = 2.0, creatureCount = 1.8, stormDuration = 1.1, resources = 1.5 },
	[5] = { creatureHP = 2.5, creatureCount = 2.0, stormDuration = 1.2, resources = 1.7 },
}

-- Morale system
GameConfig.MORALE = {
	MAX = 100,
	STARTING = 80,
	STORM_DRAIN_PER_SECOND = 0.5,
	CALM_REGEN_PER_SECOND = 0.3,
	COOKED_FOOD_BOOST = 15,
	CAMPFIRE_BOOST_PER_SECOND = 0.2,
	JUKEBOX_BOOST_PER_SECOND = 0.4,
	PET_INTERACTION_BOOST = 10,
	BUILDING_DESTROYED_PENALTY = 20,
	TEAMMATE_DOWN_PENALTY = 15,
	LIGHTHOUSE_FLICKER_PENALTY = 10,
	PANIC_THRESHOLD = 10,
	PANIC_DURATION = 10,
}

-- Player stats
GameConfig.PLAYER = {
	MAX_HEALTH = 100,
	MAX_HUNGER = 100,
	HUNGER_DRAIN_PER_SECOND = 0.15,
	STARVATION_DAMAGE_PER_SECOND = 2,
	RESPAWN_TIME = 10,
	REVIVE_TIME = 5,
	BASE_MOVE_SPEED = 16,
	SPRINT_MULTIPLIER = 1.5,
	SPRINT_STAMINA_DRAIN = 2,
	MAX_STAMINA = 100,
	STAMINA_REGEN = 1.5,
}

-- Zone unlock thresholds
GameConfig.ZONES = {
	{ id = "stormhaven",         name = "Stormhaven",          unlockStorm = 0 },
	{ id = "rocky_shore",        name = "The Rocky Shore",     unlockStorm = 0 },
	{ id = "marshlands",         name = "The Marshlands",      unlockStorm = 15 },
	{ id = "cliffs",             name = "The Cliffs",          unlockStorm = 30 },
	{ id = "lighthouse_islands", name = "The Lighthouse Islands", unlockStorm = 50 },
	{ id = "maelstrom",          name = "The Maelstrom",       unlockStorm = 75 },
}

-- Rescue missions
GameConfig.RESCUES = {
	{
		id = "old_pete",
		name = "Old Pete the Fisherman",
		zone = "marshlands",
		unlockStorm = 15,
		reward = "Fishing NPC + advanced fishing recipes",
	},
	{
		id = "marina",
		name = "Marina the Biologist",
		zone = "cliffs",
		unlockStorm = 30,
		reward = "Advanced medical crafting + taming bonuses",
	},
	{
		id = "captain_briggs",
		name = "Captain Briggs",
		zone = "lighthouse_islands",
		unlockStorm = 50,
		reward = "Boat upgrades + Second Lighthouse",
	},
	{
		id = "elara",
		name = "Elara the Storm Witch",
		zone = "maelstrom",
		unlockStorm = 75,
		reward = "Counter-ritual begins (final 24 storms)",
	},
}

return GameConfig
