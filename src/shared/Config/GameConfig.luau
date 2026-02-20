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

-- Timing (seconds)
GameConfig.CALM_DURATION = 480        -- 8 minutes of calm (daytime)
GameConfig.STORM_WARNING_DURATION = 60 -- 1 minute warning siren
GameConfig.STORM_BASE_DURATION = 180   -- 3 minutes base storm duration
GameConfig.AFTERMATH_DURATION = 120    -- 2 minutes aftermath scavenging

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

-- Classes
GameConfig.CLASSES = {
	{
		id = "weatherman",
		name = "Weatherman",
		premium = false,
		price = 0,
		tagline = "I can feel it in the air...",
		abilities = {
			"Storm Sense: see storm type 30s before warning",
			"Weather Resistance: 15% reduced weather damage",
			"Barometer Craft: craft storm intensity tracker",
			"Wind Reader: less affected by wind push",
		},
	},
	{
		id = "captain",
		name = "Captain",
		premium = true,
		price = 349,
		tagline = "The sea is in my blood.",
		abilities = {
			"Master Sailor: boats 40% faster, sail in storms",
			"Net Fisher: double fishing catches",
			"Sea Legs: immune to wave/wind knockback",
			"Anchor Down: create temp safe zone on any boat",
		},
	},
	{
		id = "builder",
		name = "Builder",
		premium = true,
		price = 349,
		tagline = "This town will stand.",
		abilities = {
			"Fortify: structures have 50% more HP",
			"Quick Repair: 3x faster repairs",
			"Blueprint Vision: see structural weak points",
			"Storm Shelter: build emergency bunkers anywhere",
		},
	},
	{
		id = "keeper",
		name = "Keeper",
		premium = true,
		price = 349,
		tagline = "The light must never go out.",
		abilities = {
			"Lighthouse Bond: beam 25% wider when inside",
			"NPC Whisperer: better trades and more hints",
			"Town Management: assign NPCs to auto-tasks",
			"Beacon Craft: portable mini safe zones",
		},
	},
	{
		id = "stormchaser",
		name = "Stormchaser",
		premium = true,
		price = 499,
		tagline = "Into the eye.",
		abilities = {
			"Storm Harvest: collect Storm Crystals during storms",
			"Lightning Rod: absorb strikes to charge weapons",
			"Tempest Taunt: draw aggro from structures/allies",
			"Eye of the Storm: brief invulnerability at peak",
		},
	},
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
