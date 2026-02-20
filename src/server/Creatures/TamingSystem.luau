--[[
	TamingSystem.luau
	Server-side animal taming system for 99 Storms.
	Handles taming progress, companion management, and abilities.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreatureConfig = require(ReplicatedStorage.Shared.Config.CreatureConfig)

local TamingSystem = {}
TamingSystem.__index = TamingSystem

export type TamedAnimal = {
	id: string,
	configId: string,
	name: string,
	customName: string?,
	ownerId: number, -- player UserId
	health: number,
	maxHealth: number,
	abilityType: string,
	isActive: boolean,
}

export type TamingProgress = {
	configId: string,
	playerId: number,
	sessionsCompleted: number,
	sessionsRequired: number,
	lastFeedTime: number,
}

function TamingSystem.new()
	local self = setmetatable({}, TamingSystem)

	self.tamedAnimals = {} :: { [string]: TamedAnimal } -- animalId -> TamedAnimal
	self.tamingProgress = {} :: { [string]: TamingProgress } -- "playerId_configId" -> TamingProgress
	self.playerCompanions = {} :: { [number]: { string } } -- playerId -> list of animal IDs
	self.maxCompanionsPerPlayer = 3
	self.nextAnimalId = 1

	return self
end

-- Start or continue taming an animal
function TamingSystem:attemptTame(player: Player, creatureConfigId: string, hasRequiredFood: boolean, hasRequiredWhistle: boolean): (boolean, string)
	-- Find the tameable config
	local config = nil
	for _, tameable in CreatureConfig.TAMEABLE do
		if tameable.id == creatureConfigId then
			config = tameable
			break
		end
	end

	if not config then
		return false, "This creature cannot be tamed."
	end

	-- Check whistle requirement
	if not hasRequiredWhistle then
		return false, "You need a " .. config.requiredWhistle .. " to tame this creature."
	end

	-- Check food requirement
	if not hasRequiredFood then
		return false, "You need " .. config.tamingFood .. " to feed this creature."
	end

	-- Check if player already has max companions
	local companions = self.playerCompanions[player.UserId] or {}
	if #companions >= self.maxCompanionsPerPlayer then
		return false, "You already have the maximum number of companions (" .. self.maxCompanionsPerPlayer .. ")."
	end

	-- Check/create taming progress
	local progressKey = player.UserId .. "_" .. creatureConfigId
	local progress = self.tamingProgress[progressKey]

	if not progress then
		progress = {
			configId = creatureConfigId,
			playerId = player.UserId,
			sessionsCompleted = 0,
			sessionsRequired = config.tamingSessions,
			lastFeedTime = 0,
		}
		self.tamingProgress[progressKey] = progress
	end

	-- Check cooldown between feeding sessions
	local now = tick()
	local cooldown = config.tamingTime -- seconds between sessions
	if (now - progress.lastFeedTime) < cooldown and progress.sessionsCompleted > 0 then
		local remaining = math.ceil(cooldown - (now - progress.lastFeedTime))
		return false, "This creature needs time. Try again in " .. remaining .. " seconds."
	end

	-- Advance taming progress
	progress.sessionsCompleted += 1
	progress.lastFeedTime = now

	if progress.sessionsCompleted >= progress.sessionsRequired then
		-- Taming complete!
		local animal = self:createTamedAnimal(player, config)
		self.tamingProgress[progressKey] = nil -- clear progress

		return true, config.name .. " has been tamed! Named: " .. animal.name
	else
		local remaining = progress.sessionsRequired - progress.sessionsCompleted
		return true, config.name .. " is warming up to you! " .. remaining .. " more sessions needed."
	end
end

-- Create a tamed animal for a player
function TamingSystem:createTamedAnimal(player: Player, config: any): TamedAnimal
	local animalId = "animal_" .. self.nextAnimalId
	self.nextAnimalId += 1

	local animal: TamedAnimal = {
		id = animalId,
		configId = config.id,
		name = config.name,
		customName = nil,
		ownerId = player.UserId,
		health = 100,
		maxHealth = 100,
		abilityType = config.abilityType,
		isActive = true,
	}

	self.tamedAnimals[animalId] = animal

	-- Add to player's companion list
	if not self.playerCompanions[player.UserId] then
		self.playerCompanions[player.UserId] = {}
	end
	table.insert(self.playerCompanions[player.UserId], animalId)

	return animal
end

-- Rename a tamed animal
function TamingSystem:renameAnimal(player: Player, animalId: string, newName: string): (boolean, string)
	local animal = self.tamedAnimals[animalId]
	if not animal then
		return false, "Animal not found."
	end

	if animal.ownerId ~= player.UserId then
		return false, "This is not your animal."
	end

	-- Basic name validation
	if #newName < 1 or #newName > 20 then
		return false, "Name must be 1-20 characters."
	end

	animal.customName = newName
	return true, "Renamed to " .. newName .. "!"
end

-- Get a player's tamed animals
function TamingSystem:getPlayerAnimals(player: Player): { TamedAnimal }
	local animals = {}
	local companionIds = self.playerCompanions[player.UserId] or {}

	for _, animalId in companionIds do
		local animal = self.tamedAnimals[animalId]
		if animal then
			table.insert(animals, animal)
		end
	end

	return animals
end

-- Activate a companion ability
function TamingSystem:useAbility(player: Player, animalId: string): (boolean, string, any?)
	local animal = self.tamedAnimals[animalId]
	if not animal then
		return false, "Animal not found.", nil
	end

	if animal.ownerId ~= player.UserId then
		return false, "This is not your animal.", nil
	end

	if not animal.isActive then
		return false, animal.name .. " is resting.", nil
	end

	local abilityType = animal.abilityType

	if abilityType == "scout" then
		-- Reveal nearby map area
		return true, animal.name .. " scouted the area!", { type = "reveal_map", radius = 50 }

	elseif abilityType == "gather" then
		-- Auto-collect nearby resources
		return true, animal.name .. " is gathering resources!", { type = "auto_gather", duration = 30 }

	elseif abilityType == "combat_companion" or abilityType == "combat_companion_water" or abilityType == "combat_companion_elite" then
		-- Combat pet attacks nearby enemies
		return true, animal.name .. " is ready to fight!", { type = "combat_mode" }

	elseif abilityType == "storm_scout" then
		-- Reveal storm type early
		return true, animal.name .. " senses the next storm!", { type = "storm_reveal" }

	elseif abilityType == "mount_water" then
		-- Mount for water travel
		return true, "Riding " .. animal.name .. "!", { type = "mount" }

	elseif abilityType == "passive" then
		return true, animal.name .. "'s passive ability is active.", { type = "passive" }
	end

	return false, "Unknown ability.", nil
end

-- Damage a tamed animal (during storms, creature attacks)
function TamingSystem:damageAnimal(animalId: string, damage: number): boolean
	local animal = self.tamedAnimals[animalId]
	if not animal or not animal.isActive then
		return false
	end

	animal.health -= damage
	if animal.health <= 0 then
		animal.health = 0
		animal.isActive = false
		-- Animal goes to "resting" state, heals over time
		task.delay(60, function() -- 1 minute rest time
			if self.tamedAnimals[animalId] then
				animal.health = animal.maxHealth
				animal.isActive = true
			end
		end)
		return true -- animal was knocked out
	end

	return false
end

-- Heal a tamed animal
function TamingSystem:healAnimal(animalId: string, healAmount: number)
	local animal = self.tamedAnimals[animalId]
	if not animal then return end

	animal.health = math.min(animal.maxHealth, animal.health + healAmount)
end

-- Clean up when player leaves
function TamingSystem:onPlayerLeaving(playerId: number)
	-- Remove player's companions
	local companionIds = self.playerCompanions[playerId] or {}
	for _, animalId in companionIds do
		self.tamedAnimals[animalId] = nil
	end
	self.playerCompanions[playerId] = nil

	-- Remove taming progress
	for key, progress in self.tamingProgress do
		if progress.playerId == playerId then
			self.tamingProgress[key] = nil
		end
	end
end

return TamingSystem
