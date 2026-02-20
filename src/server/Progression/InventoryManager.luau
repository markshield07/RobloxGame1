--[[
	InventoryManager.luau
	Server-authoritative inventory system for 99 Storms.
	Tracks all player items, handles add/remove/transfer, and validates quantities.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InventoryManager = {}
InventoryManager.__index = InventoryManager

-- Maximum stack sizes per item category
local MAX_STACKS = {
	-- Resources
	wood = 99, stone = 99, rope = 99, cloth = 99, scrap_metal = 99,
	iron_ore = 99, copper_wire = 99, oil = 99, glass = 99, fuel = 99,
	storm_crystal = 50, coal = 99,

	-- Food raw
	raw_fish = 30, clam = 30, crab_shell = 30, lobster = 20,
	herbs = 30, eggs = 20, vegetables = 30, seaweed = 30,
	bread = 20, frog_legs = 20, bait = 30, deep_sea_bait = 15,

	-- Food cooked
	cooked_fish = 15, fish_stew = 10, clam_chowder = 10,
	herbal_tea = 10, storm_feast = 5, lobster_dinner = 10,

	-- Medical
	bandage = 15, medical_kit = 10, antivenom = 10, storm_salve = 8,

	-- Weapons (single equip)
	wooden_club = 1, iron_sword = 1, storm_blade = 1,
	slingshot = 1, crossbow = 1, storm_bow = 1,
	harpoon = 1, storm_harpoon = 1, storm_cannon = 1,

	-- Tools (single equip)
	fishing_rod = 1, deep_sea_rod = 1,
	iron_pickaxe = 1, reinforced_hammer = 1, storm_hammer = 1,
	lantern = 1, fog_piercer = 1, whistle = 1, upgraded_whistle = 1, storm_whistle = 1,
	portable_beacon = 3,

	-- Building materials
	wooden_boards = 30, reinforced_planks = 20, metal_shutters = 15,
	storm_glass = 10, storm_crystal_barriers = 8,
	wooden_fence = 10, sandbags = 20, lightning_rod = 5,
	fog_horn = 3, bear_trap = 10, bed = 1,

	-- Survival gear (single equip)
	raincoat = 1, rubber_boots = 1, storm_goggles = 1,
	insulated_jacket = 1, lightning_vest = 1, storm_ward = 5,

	-- Vehicles
	raft = 1, rowboat = 1, sailboat = 1, storm_vessel = 1,

	-- Signal / consumable
	signal_flare = 10, tempest_lure = 3,

	-- Creature drops
	ectoplasm = 30, wolf_pelt = 10, frost_fang = 10,
	lurker_hide = 10, snake_venom = 15, snake_skin = 10,
	bat_wing = 20, guano = 20, rare_mineral = 10,
	chitin = 15, shark_tooth = 10, abyssal_scale = 10,
	feathers = 20,

	-- Special / quest
	boat_armor_kit = 1, maelstrom_charts = 1,
	recipe_advanced_fishing = 1, recipe_taming_boost = 1,

	-- Currency
	storm_coins = 9999,
}

local DEFAULT_MAX_STACK = 20
local MAX_INVENTORY_SLOTS = 40

function InventoryManager.new()
	local self = setmetatable({}, InventoryManager)

	self.inventories = {} -- userId -> { [itemId] = count }
	self.onItemChanged = nil -- callback(userId, itemId, newCount, delta)

	return self
end

-- Initialize inventory for a player
function InventoryManager:initPlayer(userId: number)
	if not self.inventories[userId] then
		self.inventories[userId] = {}
	end
end

-- Give starting items to a new player
function InventoryManager:giveStarterKit(userId: number)
	self:initPlayer(userId)
	self:addItem(userId, "wood", 10)
	self:addItem(userId, "stone", 5)
	self:addItem(userId, "rope", 3)
	self:addItem(userId, "cloth", 3)
	self:addItem(userId, "raw_fish", 2)
	self:addItem(userId, "bandage", 2)
end

-- Get max stack size for an item
function InventoryManager:getMaxStack(itemId: string): number
	return MAX_STACKS[itemId] or DEFAULT_MAX_STACK
end

-- Get how many of an item a player has
function InventoryManager:getItemCount(userId: number, itemId: string): number
	local inv = self.inventories[userId]
	if not inv then return 0 end
	return inv[itemId] or 0
end

-- Get the full inventory table for a player
function InventoryManager:getInventory(userId: number): { [string]: number }
	return self.inventories[userId] or {}
end

-- Count how many unique item slots are used
function InventoryManager:getUsedSlots(userId: number): number
	local inv = self.inventories[userId]
	if not inv then return 0 end

	local count = 0
	for _, qty in inv do
		if qty > 0 then
			count += 1
		end
	end
	return count
end

-- Check if inventory has room for a new item type
function InventoryManager:hasRoom(userId: number, itemId: string): boolean
	local inv = self.inventories[userId]
	if not inv then return true end

	-- If player already has this item, check stack
	if inv[itemId] and inv[itemId] > 0 then
		return inv[itemId] < self:getMaxStack(itemId)
	end

	-- Otherwise check slot count
	return self:getUsedSlots(userId) < MAX_INVENTORY_SLOTS
end

-- Add items to a player's inventory
-- Returns: actual amount added (may be less than requested if stack is full)
function InventoryManager:addItem(userId: number, itemId: string, count: number): number
	self:initPlayer(userId)
	local inv = self.inventories[userId]

	local maxStack = self:getMaxStack(itemId)
	local current = inv[itemId] or 0
	local spaceLeft = maxStack - current
	local toAdd = math.min(count, spaceLeft)

	if toAdd <= 0 then return 0 end

	-- Check slot limit for new items
	if current == 0 and self:getUsedSlots(userId) >= MAX_INVENTORY_SLOTS then
		return 0
	end

	inv[itemId] = current + toAdd

	if self.onItemChanged then
		self.onItemChanged(userId, itemId, inv[itemId], toAdd)
	end

	return toAdd
end

-- Remove items from a player's inventory
-- Returns: actual amount removed (may be less if player doesn't have enough)
function InventoryManager:removeItem(userId: number, itemId: string, count: number): number
	local inv = self.inventories[userId]
	if not inv then return 0 end

	local current = inv[itemId] or 0
	local toRemove = math.min(count, current)

	if toRemove <= 0 then return 0 end

	inv[itemId] = current - toRemove

	-- Clean up zero entries
	if inv[itemId] <= 0 then
		inv[itemId] = nil
	end

	if self.onItemChanged then
		self.onItemChanged(userId, itemId, inv[itemId] or 0, -toRemove)
	end

	return toRemove
end

-- Check if player has at least X of an item
function InventoryManager:hasItem(userId: number, itemId: string, count: number?): boolean
	count = count or 1
	return self:getItemCount(userId, itemId) >= count
end

-- Check if player has ALL items in a list: { {itemId, count}, ... }
function InventoryManager:hasItems(userId: number, items: { { string | number } }): boolean
	for _, entry in items do
		local itemId = entry[1] :: string
		local count = entry[2] :: number
		if not self:hasItem(userId, itemId, count) then
			return false
		end
	end
	return true
end

-- Consume multiple items at once (for crafting)
-- Returns: true if all consumed, false if any were missing (no partial consume)
function InventoryManager:consumeItems(userId: number, items: { { string | number } }): boolean
	-- Verify all items available first
	if not self:hasItems(userId, items) then
		return false
	end

	-- Consume all
	for _, entry in items do
		self:removeItem(userId, entry[1] :: string, entry[2] :: number)
	end

	return true
end

-- Transfer item from one player to another
function InventoryManager:transferItem(fromUserId: number, toUserId: number, itemId: string, count: number): (boolean, string)
	if not self:hasItem(fromUserId, itemId, count) then
		return false, "You don't have enough " .. itemId
	end

	if not self:hasRoom(toUserId, itemId) then
		return false, "Recipient's inventory is full"
	end

	local removed = self:removeItem(fromUserId, itemId, count)
	local added = self:addItem(toUserId, itemId, removed)

	-- If not all could be added, return the remainder
	if added < removed then
		self:addItem(fromUserId, itemId, removed - added)
		return true, "Transferred " .. added .. "x " .. itemId .. " (partial — inventory full)"
	end

	return true, "Transferred " .. added .. "x " .. itemId
end

-- Serialize inventory for DataStore save
function InventoryManager:serialize(userId: number): { [string]: number }
	return self:getInventory(userId)
end

-- Load inventory from DataStore
function InventoryManager:deserialize(userId: number, data: { [string]: number })
	self:initPlayer(userId)
	if data then
		self.inventories[userId] = data
	end
end

-- Clean up when player leaves
function InventoryManager:removePlayer(userId: number)
	self.inventories[userId] = nil
end

return InventoryManager
