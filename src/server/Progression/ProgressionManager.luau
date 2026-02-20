--[[
	ProgressionManager.luau
	Manages player progression, milestones, zone unlocks, and save/load.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local ProgressionManager = {}
ProgressionManager.__index = ProgressionManager

local DATASTORE_NAME = "99Storms_PlayerData_v1"

-- Default player data template
local DEFAULT_DATA = {
	-- Session stats (reset each game)
	currentStorm = 0,
	classId = "weatherman",
	rescuedNPCs = {},
	claimedHouse = nil,

	-- Persistent stats (saved across sessions)
	totalStormsWeathered = 0,
	totalGamesCompleted = 0,
	totalCreaturesDefeated = 0,
	totalBuildingsRepaired = 0,
	totalFishCaught = 0,
	totalItemsCrafted = 0,
	totalAnimalsTamed = 0,
	bestStormReached = 0,
	fastestCompletion = 0, -- seconds (0 = never completed)

	-- Unlocks
	ownedClasses = { "weatherman" },
	badges = {},

	-- Currency
	stormCoins = 0,

	-- Settings
	musicVolume = 0.5,
	sfxVolume = 0.8,
}

function ProgressionManager.new()
	local self = setmetatable({}, ProgressionManager)

	self.playerData = {} -- playerId -> data table
	self.dataStore = nil
	self.milestoneCallbacks = {} -- stormNumber -> callback

	-- Attempt to get DataStore (will fail in Studio without API access)
	pcall(function()
		self.dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
	end)

	return self
end

-- Load player data from DataStore
function ProgressionManager:loadPlayerData(player: Player)
	local userId = player.UserId
	local data = nil

	if self.dataStore then
		local success, result = pcall(function()
			return self.dataStore:GetAsync("Player_" .. userId)
		end)

		if success and result then
			data = result
		end
	end

	-- Merge with defaults (handles new fields added in updates)
	if not data then
		data = {}
	end

	local mergedData = {}
	for key, defaultValue in DEFAULT_DATA do
		if data[key] ~= nil then
			mergedData[key] = data[key]
		else
			mergedData[key] = defaultValue
		end
	end

	self.playerData[userId] = mergedData
	return mergedData
end

-- Save player data to DataStore
function ProgressionManager:savePlayerData(player: Player)
	local userId = player.UserId
	local data = self.playerData[userId]

	if not data or not self.dataStore then
		return false
	end

	local success, err = pcall(function()
		self.dataStore:SetAsync("Player_" .. userId, data)
	end)

	if not success then
		warn("[ProgressionManager] Failed to save data for player " .. userId .. ": " .. tostring(err))
	end

	return success
end

-- Get player data
function ProgressionManager:getData(player: Player)
	return self.playerData[player.UserId]
end

-- Update a stat
function ProgressionManager:incrementStat(player: Player, statName: string, amount: number?)
	local data = self.playerData[player.UserId]
	if not data then return end

	amount = amount or 1
	if data[statName] ~= nil and type(data[statName]) == "number" then
		data[statName] += amount
	end
end

-- Set player class
function ProgressionManager:setClass(player: Player, classId: string): (boolean, string)
	local data = self.playerData[player.UserId]
	if not data then
		return false, "Player data not loaded"
	end

	-- Check if player owns this class
	if not table.find(data.ownedClasses, classId) then
		return false, "You don't own this class"
	end

	data.classId = classId
	return true, "Class set to " .. classId
end

-- Grant a class (from gamepass purchase)
function ProgressionManager:grantClass(player: Player, classId: string)
	local data = self.playerData[player.UserId]
	if not data then return end

	if not table.find(data.ownedClasses, classId) then
		table.insert(data.ownedClasses, classId)
	end
end

-- Record a storm survived
function ProgressionManager:onStormSurvived(player: Player, stormNumber: number)
	local data = self.playerData[player.UserId]
	if not data then return end

	data.currentStorm = stormNumber
	data.totalStormsWeathered += 1

	if stormNumber > data.bestStormReached then
		data.bestStormReached = stormNumber
	end

	-- Check milestones
	self:checkMilestones(player, stormNumber)
end

-- Record an NPC rescue
function ProgressionManager:onNPCRescued(player: Player, npcId: string)
	local data = self.playerData[player.UserId]
	if not data then return end

	if not table.find(data.rescuedNPCs, npcId) then
		table.insert(data.rescuedNPCs, npcId)
	end
end

-- Record game completion
function ProgressionManager:onGameComplete(player: Player, completionTime: number)
	local data = self.playerData[player.UserId]
	if not data then return end

	data.totalGamesCompleted += 1

	if data.fastestCompletion == 0 or completionTime < data.fastestCompletion then
		data.fastestCompletion = completionTime
	end
end

-- Check and award milestone badges
function ProgressionManager:checkMilestones(player: Player, stormNumber: number)
	local data = self.playerData[player.UserId]
	if not data then return end

	local milestones = {
		{ storm = 1,  badge = "first_storm",    name = "Storm Survivor" },
		{ storm = 10, badge = "ten_storms",      name = "Weathered" },
		{ storm = 25, badge = "first_boss",      name = "Tempest's Wrath I" },
		{ storm = 50, badge = "fifty_storms",    name = "Stormhaven Veteran" },
		{ storm = 50, badge = "second_boss",     name = "Tempest's Wrath II" },
		{ storm = 75, badge = "seventy_five",    name = "Into The Maelstrom" },
		{ storm = 75, badge = "third_boss",      name = "Tempest's Wrath III" },
		{ storm = 99, badge = "game_complete",   name = "Curse Breaker" },
	}

	for _, milestone in milestones do
		if stormNumber >= milestone.storm and not table.find(data.badges, milestone.badge) then
			table.insert(data.badges, milestone.badge)
			-- Fire badge earned event
			-- TODO: Connect to badge service
		end
	end
end

-- Check if a zone is unlocked for a player's session
function ProgressionManager:isZoneUnlocked(player: Player, zoneId: string): boolean
	local data = self.playerData[player.UserId]
	if not data then return false end

	for _, zone in GameConfig.ZONES do
		if zone.id == zoneId then
			return data.currentStorm >= zone.unlockStorm
		end
	end
	return false
end

-- Get available crafting recipes based on current storm
function ProgressionManager:getAvailableRecipes(player: Player): { string }
	local data = self.playerData[player.UserId]
	if not data then return {} end

	local CraftingRecipes = require(ReplicatedStorage.Shared.Config.CraftingRecipes)
	return CraftingRecipes.getAvailable(data.currentStorm)
end

-- Clean up player data on leave
function ProgressionManager:onPlayerLeaving(player: Player)
	self:savePlayerData(player)
	self.playerData[player.UserId] = nil
end

return ProgressionManager
