--[[
	CombatSystem.luau
	Server-side combat system for 99 Storms.
	Handles player attacks on creatures, creature attacks on players,
	weapon damage calculation, and hit detection.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local CombatSystem = {}
CombatSystem.__index = CombatSystem

-- Weapon damage values
local WEAPON_STATS = {
	-- Melee
	wooden_club =    { damage = 10, range = 5,  speed = 1.0, type = "melee" },
	iron_sword =     { damage = 20, range = 6,  speed = 1.2, type = "melee" },
	storm_blade =    { damage = 35, range = 7,  speed = 1.0, type = "melee", bonus = "lightning_proc" },
	harpoon =        { damage = 25, range = 8,  speed = 0.8, type = "melee" },
	storm_harpoon =  { damage = 40, range = 9,  speed = 0.8, type = "melee", bonus = "lightning_proc" },

	-- Ranged
	slingshot =      { damage = 8,  range = 30, speed = 1.5, type = "ranged", ammo = "stone" },
	crossbow =       { damage = 18, range = 40, speed = 0.8, type = "ranged", ammo = "bolt" },
	storm_bow =      { damage = 30, range = 45, speed = 1.0, type = "ranged", ammo = "storm_arrow", bonus = "chain_lightning" },
	storm_cannon =   { damage = 50, range = 50, speed = 0.5, type = "ranged", ammo = "storm_crystal", bonus = "aoe_blast" },

	-- Unarmed
	fists =          { damage = 5,  range = 4,  speed = 1.5, type = "melee" },
}

-- Class combat bonuses
local CLASS_BONUSES = {
	weatherman =   { damageMultiplier = 1.0, defenseMultiplier = 1.0 },
	captain =      { damageMultiplier = 1.0, defenseMultiplier = 1.1, waterDamageBonus = 1.3 },
	builder =      { damageMultiplier = 0.9, defenseMultiplier = 1.2 },
	keeper =       { damageMultiplier = 0.9, defenseMultiplier = 1.0, healingBonus = 1.3 },
	stormchaser =  { damageMultiplier = 1.3, defenseMultiplier = 0.9, stormDamageBonus = 1.5 },
}

function CombatSystem.new()
	local self = setmetatable({}, CombatSystem)

	-- References to other systems (set during init)
	self.creatureSpawner = nil
	self.playerCharacter = nil
	self.inventoryManager = nil

	self.attackCooldowns = {} -- userId -> timestamp of last attack
	self.onPlayerHitCreature = nil -- callback(player, creature, damage)
	self.onCreatureHitPlayer = nil -- callback(creature, player, damage)
	self.onCreatureDefeated = nil -- callback(creature, player, drops)

	return self
end

-- Wire up references to other systems
function CombatSystem:init(creatureSpawner, playerCharacter, inventoryManager)
	self.creatureSpawner = creatureSpawner
	self.playerCharacter = playerCharacter
	self.inventoryManager = inventoryManager
end

-- Get weapon stats for equipped weapon (or fists)
function CombatSystem:getWeaponStats(userId: number): any
	if not self.inventoryManager then
		return WEAPON_STATS.fists
	end

	-- Check what weapons the player has (use the best one they own)
	local inv = self.inventoryManager:getInventory(userId)
	local bestWeapon = "fists"
	local bestDamage = 0

	for itemId, count in inv do
		if count > 0 and WEAPON_STATS[itemId] then
			if WEAPON_STATS[itemId].damage > bestDamage then
				bestDamage = WEAPON_STATS[itemId].damage
				bestWeapon = itemId
			end
		end
	end

	return WEAPON_STATS[bestWeapon], bestWeapon
end

-- Calculate final damage from player to creature
function CombatSystem:calculatePlayerDamage(userId: number, classId: string, weaponId: string?, isStormActive: boolean?): number
	local weapon = WEAPON_STATS[weaponId or "fists"] or WEAPON_STATS.fists
	local classBonus = CLASS_BONUSES[classId] or CLASS_BONUSES.weatherman

	local damage = weapon.damage * classBonus.damageMultiplier

	-- Storm damage bonus for Stormchaser during storms
	if isStormActive and classId == "stormchaser" and classBonus.stormDamageBonus then
		damage = damage * classBonus.stormDamageBonus
	end

	-- Lightning proc (storm weapons have a chance to deal bonus damage)
	if weapon.bonus == "lightning_proc" then
		if math.random() < 0.2 then -- 20% chance
			damage = damage * 1.5
		end
	end

	return math.floor(damage)
end

-- Player attacks a creature
function CombatSystem:playerAttackCreature(player: Player, creatureId: string, isStormActive: boolean?): (boolean, string)
	if not self.creatureSpawner or not self.playerCharacter then
		return false, "Combat system not initialized"
	end

	local userId = player.UserId

	-- Check cooldown
	local now = tick()
	local lastAttack = self.attackCooldowns[userId] or 0
	local weaponStats, weaponId = self:getWeaponStats(userId)
	local cooldown = 1 / (weaponStats.speed or 1)

	if (now - lastAttack) < cooldown then
		return false, "Attack on cooldown"
	end

	-- Check range
	local creature = self.creatureSpawner.activeCreatures[creatureId]
	if not creature or not creature.isAlive then
		return false, "Invalid target"
	end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false, "No character"
	end

	local playerPos = character.HumanoidRootPart.Position
	local dist = (playerPos - creature.position).Magnitude

	if dist > weaponStats.range then
		return false, "Out of range"
	end

	-- Check ammo for ranged weapons
	if weaponStats.type == "ranged" and weaponStats.ammo then
		if not self.inventoryManager:hasItem(userId, weaponStats.ammo, 1) then
			return false, "No ammo (" .. weaponStats.ammo .. ")"
		end
		self.inventoryManager:removeItem(userId, weaponStats.ammo, 1)
	end

	-- Calculate and apply damage
	local state = self.playerCharacter:getState(userId)
	local classId = state and state.classId or "weatherman"
	local damage = self:calculatePlayerDamage(userId, classId, weaponId, isStormActive)

	self.attackCooldowns[userId] = now

	local defeated = self.creatureSpawner:damageCreature(creatureId, damage, player)

	if self.onPlayerHitCreature then
		self.onPlayerHitCreature(player, creature, damage)
	end

	if defeated then
		-- Generate and give drops
		local drops = self.creatureSpawner:generateDrops(creature.configId)
		for _, drop in drops do
			self.inventoryManager:addItem(userId, drop.item, drop.count)
		end

		if self.onCreatureDefeated then
			self.onCreatureDefeated(creature, player, drops)
		end

		return true, creature.name .. " defeated! (" .. damage .. " damage)"
	end

	return true, "Hit " .. creature.name .. " for " .. damage .. " damage (HP: " .. creature.hp .. "/" .. creature.maxHP .. ")"
end

-- Creature attacks a player (called from creature AI update)
function CombatSystem:creatureAttackPlayer(creatureId: string, player: Player)
	if not self.creatureSpawner or not self.playerCharacter then return end

	local creature = self.creatureSpawner.activeCreatures[creatureId]
	if not creature or not creature.isAlive then return end

	local state = self.playerCharacter:getState(player.UserId)
	if not state or state.isDead then return end

	-- Calculate creature damage with class defense
	local classBonus = CLASS_BONUSES[state.classId] or CLASS_BONUSES.weatherman
	local damage = math.floor(creature.damage / classBonus.defenseMultiplier)

	-- Apply damage
	self.playerCharacter:damage(state, damage, "creature")

	-- Apply special effects
	if creature.specialEffect == "poison" then
		self.playerCharacter:applyPoison(player.UserId, 8, 3)
	elseif creature.specialEffect == "freeze_slow" then
		self.playerCharacter:applyFreeze(player.UserId, 4)
	elseif creature.specialEffect == "stun" then
		-- Brief stun — handled via status effect
		self.playerCharacter:applyEffect(player.UserId, {
			id = "stun",
			name = "Stunned",
			duration = 1.5,
			tickRate = 999,
			tickTimer = 999,
		})
	elseif creature.specialEffect == "grab" then
		-- Tide horror grab — pull player toward creature
		self.playerCharacter:applyEffect(player.UserId, {
			id = "grabbed",
			name = "Grabbed",
			duration = 2,
			tickRate = 0.5,
			tickTimer = 0.5,
			onTick = function(s)
				self.playerCharacter:damage(s, 5, "grab")
			end,
		})
	end

	if self.onCreatureHitPlayer then
		self.onCreatureHitPlayer(creature, player, damage)
	end
end

-- Apply weather damage to all non-sheltered players
function CombatSystem:applyWeatherDamage(damagePerSecond: number, damageType: string, deltaTime: number)
	if not self.playerCharacter then return end

	for _, player in Players:GetPlayers() do
		local state = self.playerCharacter:getState(player.UserId)
		if state and not state.isDead and not state.isSheltered then
			self.playerCharacter:damage(state, damagePerSecond * deltaTime, damageType)
		end
	end
end

-- Apply lightning strike damage to a specific position
function CombatSystem:applyLightningStrike(position: Vector3, radius: number, damage: number)
	if not self.playerCharacter then return end

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character and character:FindFirstChild("HumanoidRootPart") then
			local dist = (character.HumanoidRootPart.Position - position).Magnitude
			if dist <= radius then
				local state = self.playerCharacter:getState(player.UserId)
				if state and not state.isDead then
					-- Damage falls off with distance
					local falloff = 1 - (dist / radius)
					self.playerCharacter:damage(state, damage * falloff, "lightning")
				end
			end
		end
	end
end

-- Update creature melee attacks (called from game loop)
function CombatSystem:updateCreatureAttacks(deltaTime: number)
	if not self.creatureSpawner then return end

	for _, creature in self.creatureSpawner.activeCreatures do
		if creature.isAlive and creature.targetPlayer then
			local player = creature.targetPlayer
			local character = player.Character
			if character and character:FindFirstChild("HumanoidRootPart") then
				local dist = (character.HumanoidRootPart.Position - creature.position).Magnitude
				-- Attack if within melee range
				if dist <= 6 then
					self:creatureAttackPlayer(creature.id, player)
				end
			end
		end
	end
end

return CombatSystem
