--[[
	GameTypes.luau
	Shared type definitions for 99 Storms.
	Used by both client and server for type safety.
]]

local GameTypes = {}

-- Storm state enumeration
export type StormState = "calm" | "warning" | "storm" | "aftermath" | "game_complete"

-- Storm type identifiers
export type StormTypeId = "thunderstorm" | "fog" | "hurricane" | "hailstorm" | "tornado" | "tsunami" | "blood_storm" | "tempest_wrath"

-- Class identifiers
export type ClassId = "weatherman" | "captain" | "builder" | "keeper" | "stormchaser"

-- Zone identifiers
export type ZoneId = "stormhaven" | "rocky_shore" | "marshlands" | "cliffs" | "lighthouse_islands" | "maelstrom"

-- Creature behavior types
export type CreatureBehavior = "swarm" | "divebomb" | "stalker" | "pack" | "aoe_patrol" | "ambush_water" | "aggressive" | "ambush" | "territorial" | "patrol_water"

-- Fortification tier levels
export type FortTier = 0 | 1 | 2 | 3 | 4 | 5

-- Crafting station identifiers
export type CraftStationId = "workbench" | "anvil" | "stove" | "medical_table" | "storm_forge" | "boat_workshop" | "witchs_cauldron"

-- Item category
export type ItemCategory = "weapons" | "tools" | "building" | "food" | "medical" | "survival" | "vehicles" | "resources"

-- Inventory item
export type InventoryItem = {
	id: string,
	name: string,
	category: ItemCategory,
	count: number,
	maxStack: number,
}

-- Player state (replicated to client)
export type PlayerState = {
	health: number,
	maxHealth: number,
	hunger: number,
	maxHunger: number,
	morale: number,
	maxMorale: number,
	stamina: number,
	maxStamina: number,
	classId: ClassId,
	isSheltered: boolean,
	isPanicking: boolean,
}

-- Storm info (replicated to client)
export type StormInfo = {
	state: StormState,
	stormNumber: number,
	stormType: StormTypeId?,
	intensity: number,
	timeRemaining: number,
	totalStorms: number,
	isBossStorm: boolean,
}

-- Weather state (replicated to client)
export type WeatherState = {
	effects: { [string]: any },
	visibility: number,
	windDirection: Vector3,
	windStrength: number,
	temperature: number,
	floodLevel: number,
}

-- Building wall state
export type WallState = {
	tier: FortTier,
	hp: number,
	maxHP: number,
}

-- Building state (replicated to client)
export type BuildingState = {
	id: string,
	name: string,
	isRestored: boolean,
	claimedBy: number?, -- player UserId
	walls: { WallState },
	hasRoof: boolean,
}

-- Notification data
export type NotificationData = {
	text: string,
	success: boolean?,
	duration: number?,
}

-- NPC data
export type NPCData = {
	id: string,
	name: string,
	role: string,
	isRescued: boolean,
	location: ZoneId,
	trades: { TradeOffer }?,
}

-- Trade offer from an NPC
export type TradeOffer = {
	give: { { item: string, count: number } },
	receive: { { item: string, count: number } },
}

-- Tamed creature data
export type TamedCreature = {
	id: string,
	name: string,
	customName: string?,
	abilityType: string,
	health: number,
	maxHealth: number,
}

return GameTypes
