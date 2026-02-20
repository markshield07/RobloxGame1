--[[
	LootSystem.luau
	Server-side loot container management for 99 Storms.
	Handles searchable containers scattered across the map with randomized loot.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local LootSystem = {}
LootSystem.__index = LootSystem

function LootSystem.new()
	local self = setmetatable({}, LootSystem)

	self.containers = {} -- containerId -> { position, rarity, isLooted, respawnTimer, items }
	self.nextId = 1
	self.respawnTime = 120 -- 2 minutes (about 1 full day cycle) to respawn
	self.onContainerLooted = nil -- callback(player, containerId, items)

	return self
end

-- Register a container placed in the map
function LootSystem:registerContainer(part: BasePart, rarity: string?)
	local id = "loot_" .. self.nextId
	self.nextId += 1

	local container = {
		id = id,
		part = part,
		position = part.Position,
		rarity = rarity or "common",
		isLooted = false,
		respawnTimer = 0,
		items = {},
	}

	-- Generate initial loot
	container.items = self:generateLoot(container.rarity)

	-- Set attributes on the part for interaction detection
	part:SetAttribute("InteractType", "LootContainer")
	part:SetAttribute("ContainerId", id)
	part:SetAttribute("IsLooted", false)

	self.containers[id] = container
	return id
end

-- Generate random loot from a rarity table
function LootSystem:generateLoot(rarity: string): { { id: string, count: number } }
	local table_data = GameConfig.LOOT_TABLES[rarity]
	if not table_data then
		table_data = GameConfig.LOOT_TABLES.common
	end

	local items = {}
	-- Pick 1-3 items from the table
	local numItems = math.random(1, 3)
	local totalWeight = 0

	for _, entry in table_data do
		totalWeight += entry.weight
	end

	for _ = 1, numItems do
		local roll = math.random() * totalWeight
		local cumulative = 0

		for _, entry in table_data do
			cumulative += entry.weight
			if roll <= cumulative then
				local count = math.random(entry.min, entry.max)
				table.insert(items, { id = entry.id, count = count })
				break
			end
		end
	end

	return items
end

-- Player searches a container
function LootSystem:searchContainer(containerId: string, inventoryManager, userId: number): (boolean, string, { { id: string, count: number } }?)
	local container = self.containers[containerId]
	if not container then
		return false, "Container not found", nil
	end

	if container.isLooted then
		return false, "Already searched (respawning...)", nil
	end

	-- Collect loot
	local lootGained = {}
	for _, item in container.items do
		local added = inventoryManager:addItem(userId, item.id, item.count)
		if added > 0 then
			table.insert(lootGained, { id = item.id, count = added })
		end
	end

	-- Mark as looted
	container.isLooted = true
	container.respawnTimer = self.respawnTime

	if container.part then
		container.part:SetAttribute("IsLooted", true)
		container.part.Transparency = 0.6
	end

	if self.onContainerLooted then
		local player = game:GetService("Players"):GetPlayerByUserId(userId)
		if player then
			self.onContainerLooted(player, containerId, lootGained)
		end
	end

	-- Build loot message
	if #lootGained == 0 then
		return true, "Container was empty!", lootGained
	end

	local parts = {}
	for _, item in lootGained do
		table.insert(parts, item.count .. "x " .. item.id)
	end

	return true, "Found: " .. table.concat(parts, ", "), lootGained
end

-- Update respawn timers
function LootSystem:update(deltaTime: number)
	for _, container in self.containers do
		if container.isLooted then
			container.respawnTimer -= deltaTime
			if container.respawnTimer <= 0 then
				container.isLooted = false
				container.items = self:generateLoot(container.rarity)
				container.respawnTimer = 0

				if container.part then
					container.part:SetAttribute("IsLooted", false)
					container.part.Transparency = 0
				end
			end
		end
	end
end

-- Get all container states for client
function LootSystem:getContainerStates(): { [string]: { position: Vector3, rarity: string, isLooted: boolean } }
	local states = {}
	for id, container in self.containers do
		states[id] = {
			position = container.position,
			rarity = container.rarity,
			isLooted = container.isLooted,
		}
	end
	return states
end

return LootSystem
