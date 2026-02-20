--[[
	CreatureSpawner.luau
	Server-side creature spawning and AI management.
	Handles spawn timing, counts, scaling, and creature lifecycle.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local CreatureConfig = require(ReplicatedStorage.Shared.Config.CreatureConfig)
local MathUtils = require(ReplicatedStorage.Shared.Utils.MathUtils)

local CreatureSpawner = {}
CreatureSpawner.__index = CreatureSpawner

export type CreatureInstance = {
	id: string,
	configId: string,
	name: string,
	hp: number,
	maxHP: number,
	damage: number,
	speed: number,
	behavior: string,
	position: Vector3,
	targetPlayer: Player?,
	isAlive: boolean,
	specialEffect: string?,
	model: Model?,
}

function CreatureSpawner.new()
	local self = setmetatable({}, CreatureSpawner)

	self.activeCreatures = {} :: { [string]: CreatureInstance }
	self.nextCreatureId = 1
	self.spawnTimer = 0
	self.spawnInterval = 5 -- seconds between spawn waves during storms
	self.maxActiveCreatures = 30
	self.onCreatureSpawned = nil -- callback(creature)
	self.onCreatureDefeated = nil -- callback(creature, killerPlayer)

	return self
end

-- Generate a unique ID for a creature
function CreatureSpawner:generateId(): string
	local id = "creature_" .. self.nextCreatureId
	self.nextCreatureId += 1
	return id
end

-- Get the spawn count scaled by player count and intensity
function CreatureSpawner:getScaledSpawnCount(baseMin: number, baseMax: number, intensity: number): number
	local playerCount = #Players:GetPlayers()
	local scaling = GameConfig.MULTIPLAYER_SCALING[math.clamp(playerCount, 1, 5)]
	local countMultiplier = scaling and scaling.creatureCount or 1.0

	local scaledMin = math.floor(baseMin * countMultiplier * intensity)
	local scaledMax = math.ceil(baseMax * countMultiplier * intensity)

	return math.random(math.max(1, scaledMin), math.max(1, scaledMax))
end

-- Get HP scaled by player count
function CreatureSpawner:getScaledHP(baseHP: number): number
	local playerCount = #Players:GetPlayers()
	local scaling = GameConfig.MULTIPLAYER_SCALING[math.clamp(playerCount, 1, 5)]
	local hpMultiplier = scaling and scaling.creatureHP or 1.0

	return math.floor(baseHP * hpMultiplier)
end

-- Spawn creatures for a given storm type
function CreatureSpawner:spawnStormCreatures(stormType: string, intensity: number, spawnCenter: Vector3, spawnRadius: number)
	-- Find matching creature configs
	local creaturesToSpawn = {}

	for _, config in CreatureConfig.STORM_CREATURES do
		if config.stormType == stormType then
			table.insert(creaturesToSpawn, config)
		end
	end

	-- Blood storm spawns ALL creature types
	if stormType == "blood_storm" then
		creaturesToSpawn = CreatureConfig.STORM_CREATURES
	end

	-- Tempest's Wrath also spawns all + boss mechanics
	if stormType == "tempest_wrath" then
		creaturesToSpawn = CreatureConfig.STORM_CREATURES
	end

	-- Spawn each creature type
	for _, config in creaturesToSpawn do
		local count = self:getScaledSpawnCount(
			config.spawnCount.min,
			config.spawnCount.max,
			intensity
		)

		-- Cap total active creatures
		local currentCount = 0
		for _ in self.activeCreatures do
			currentCount += 1
		end

		if currentCount >= self.maxActiveCreatures then
			break
		end

		count = math.min(count, self.maxActiveCreatures - currentCount)

		for i = 1, count do
			local spawnPos = MathUtils.randomPointInCircle(spawnCenter, spawnRadius)
			self:spawnCreature(config, spawnPos, intensity)
		end
	end
end

-- Spawn a single creature at a position
function CreatureSpawner:spawnCreature(config: any, position: Vector3, intensity: number?): CreatureInstance
	intensity = intensity or 1.0

	local creature: CreatureInstance = {
		id = self:generateId(),
		configId = config.id,
		name = config.name,
		hp = self:getScaledHP(math.floor(config.baseHP * intensity)),
		maxHP = self:getScaledHP(math.floor(config.baseHP * intensity)),
		damage = math.floor(config.damage * intensity),
		speed = config.speed,
		behavior = config.behavior,
		position = position,
		targetPlayer = nil,
		isAlive = true,
		specialEffect = config.specialEffect,
		model = nil, -- Set when visual model is created
	}

	self.activeCreatures[creature.id] = creature

	if self.onCreatureSpawned then
		self.onCreatureSpawned(creature)
	end

	return creature
end

-- Spawn zone-specific creatures (always present in their zone)
function CreatureSpawner:spawnZoneCreatures(zoneId: string, spawnPoints: { Vector3 })
	for _, config in CreatureConfig.ZONE_CREATURES do
		if config.zone == zoneId then
			-- Spawn a few creatures at random spawn points
			local count = math.random(2, 4)
			for i = 1, math.min(count, #spawnPoints) do
				local pointIndex = math.random(1, #spawnPoints)
				self:spawnCreature(config, spawnPoints[pointIndex], 1.0)
			end
		end
	end
end

-- Damage a creature
function CreatureSpawner:damageCreature(creatureId: string, damage: number, attacker: Player?): boolean
	local creature = self.activeCreatures[creatureId]
	if not creature or not creature.isAlive then
		return false
	end

	creature.hp -= damage

	if creature.hp <= 0 then
		creature.hp = 0
		creature.isAlive = false

		if self.onCreatureDefeated then
			self.onCreatureDefeated(creature, attacker)
		end

		-- Generate drops
		local drops = self:generateDrops(creature.configId)

		-- Remove from active list after a delay (for death animation)
		task.delay(2, function()
			self.activeCreatures[creatureId] = nil
		end)

		return true -- creature defeated
	end

	return false -- creature still alive
end

-- Generate item drops for a defeated creature
function CreatureSpawner:generateDrops(configId: string): { { item: string, count: number } }
	local drops = {}

	-- Find the config
	local config = nil
	for _, c in CreatureConfig.STORM_CREATURES do
		if c.id == configId then
			config = c
			break
		end
	end

	if not config then
		for _, c in CreatureConfig.ZONE_CREATURES do
			if c.id == configId then
				config = c
				break
			end
		end
	end

	if not config or not config.drops then
		return drops
	end

	for _, drop in config.drops do
		local item = drop[1]
		local count = drop[2]
		local chance = drop[3]

		if math.random() <= chance then
			table.insert(drops, { item = item, count = count })
		end
	end

	return drops
end

-- Update creature AI (called each server heartbeat)
function CreatureSpawner:update(deltaTime: number)
	for id, creature in self.activeCreatures do
		if creature.isAlive then
			self:updateCreatureAI(creature, deltaTime)
		end
	end
end

-- AI behavior per creature
function CreatureSpawner:updateCreatureAI(creature: CreatureInstance, deltaTime: number)
	local behavior = creature.behavior

	if behavior == "swarm" then
		self:behaviorSwarm(creature, deltaTime)
	elseif behavior == "divebomb" then
		self:behaviorDivebomb(creature, deltaTime)
	elseif behavior == "stalker" then
		self:behaviorStalker(creature, deltaTime)
	elseif behavior == "pack" then
		self:behaviorPack(creature, deltaTime)
	elseif behavior == "aoe_patrol" then
		self:behaviorAOEPatrol(creature, deltaTime)
	elseif behavior == "ambush_water" or behavior == "ambush" then
		self:behaviorAmbush(creature, deltaTime)
	elseif behavior == "aggressive" then
		self:behaviorAggressive(creature, deltaTime)
	elseif behavior == "territorial" then
		self:behaviorTerritorial(creature, deltaTime)
	elseif behavior == "patrol_water" then
		self:behaviorPatrolWater(creature, deltaTime)
	end
end

-- Find the nearest player to a position
function CreatureSpawner:findNearestPlayer(position: Vector3, maxRange: number?): (Player?, number)
	maxRange = maxRange or 100
	local nearestPlayer = nil
	local nearestDist = maxRange

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and rootPart then
				local dist = (rootPart.Position - position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearestPlayer = player
				end
			end
		end
	end

	return nearestPlayer, nearestDist
end

-- ================================
-- AI BEHAVIORS
-- ================================

-- Swarm: move directly toward nearest player in a group
function CreatureSpawner:behaviorSwarm(creature: CreatureInstance, deltaTime: number)
	local target, dist = self:findNearestPlayer(creature.position, 50)
	if target and target.Character then
		local targetPos = target.Character.HumanoidRootPart.Position
		local direction = (targetPos - creature.position).Unit
		creature.position += direction * creature.speed * deltaTime
		creature.targetPlayer = target
	end
end

-- Divebomb: circle above, then dive when close
function CreatureSpawner:behaviorDivebomb(creature: CreatureInstance, deltaTime: number)
	local target, dist = self:findNearestPlayer(creature.position, 80)
	if target and target.Character then
		local targetPos = target.Character.HumanoidRootPart.Position

		if dist > 20 then
			-- Circle above target
			local circleOffset = Vector3.new(
				math.cos(tick() * 2) * 15,
				20,
				math.sin(tick() * 2) * 15
			)
			local desiredPos = targetPos + circleOffset
			local direction = (desiredPos - creature.position).Unit
			creature.position += direction * creature.speed * deltaTime
		else
			-- Dive toward target
			local direction = (targetPos - creature.position).Unit
			creature.position += direction * creature.speed * 2 * deltaTime
		end

		creature.targetPlayer = target
	end
end

-- Stalker: invisible until close, then teleport behind player
function CreatureSpawner:behaviorStalker(creature: CreatureInstance, deltaTime: number)
	local target, dist = self:findNearestPlayer(creature.position, 40)
	if target and target.Character then
		local targetPos = target.Character.HumanoidRootPart.Position
		local lookDir = target.Character.HumanoidRootPart.CFrame.LookVector

		if dist > 8 then
			-- Slowly approach from behind
			local behindPos = targetPos - lookDir * 5
			local direction = (behindPos - creature.position).Unit
			creature.position += direction * (creature.speed * 0.5) * deltaTime
		end
		-- When close enough, "appear" behind the player (handled by client)

		creature.targetPlayer = target
	end
end

-- Pack: coordinate with nearby same-type creatures to surround
function CreatureSpawner:behaviorPack(creature: CreatureInstance, deltaTime: number)
	local target, dist = self:findNearestPlayer(creature.position, 60)
	if target and target.Character then
		local targetPos = target.Character.HumanoidRootPart.Position

		-- Find other pack members
		local packIndex = 0
		local packSize = 0
		for _, other in self.activeCreatures do
			if other.behavior == "pack" and other.isAlive then
				packSize += 1
				if other.id == creature.id then
					packIndex = packSize
				end
			end
		end

		-- Spread around the target in a circle
		local angle = (packIndex / math.max(packSize, 1)) * math.pi * 2
		local surroundDist = 8
		local surroundPos = targetPos + Vector3.new(
			math.cos(angle) * surroundDist,
			0,
			math.sin(angle) * surroundDist
		)

		local direction = (surroundPos - creature.position).Unit
		creature.position += direction * creature.speed * deltaTime
		creature.targetPlayer = target
	end
end

-- AOE Patrol: wander the area dealing damage to anything nearby
function CreatureSpawner:behaviorAOEPatrol(creature: CreatureInstance, deltaTime: number)
	-- Wander in a pattern
	local time = tick() + creature.position.X
	local wanderDir = Vector3.new(
		math.cos(time * 0.5),
		0,
		math.sin(time * 0.3)
	).Unit

	creature.position += wanderDir * creature.speed * deltaTime
	-- AOE damage is applied separately by the damage system
end

-- Ambush: hide in water/cover, spring when player is close
function CreatureSpawner:behaviorAmbush(creature: CreatureInstance, deltaTime: number)
	local target, dist = self:findNearestPlayer(creature.position, 15)
	if target and dist < 10 and target.Character then
		-- Spring out and attack
		local targetPos = target.Character.HumanoidRootPart.Position
		local direction = (targetPos - creature.position).Unit
		creature.position += direction * creature.speed * 2 * deltaTime
		creature.targetPlayer = target
	end
	-- Otherwise, stay hidden at spawn position
end

-- Aggressive: sprint directly at nearest player, no subtlety
function CreatureSpawner:behaviorAggressive(creature: CreatureInstance, deltaTime: number)
	local target, dist = self:findNearestPlayer(creature.position, 70)
	if target and target.Character then
		local targetPos = target.Character.HumanoidRootPart.Position
		local direction = (targetPos - creature.position).Unit
		creature.position += direction * creature.speed * deltaTime
		creature.targetPlayer = target
	end
end

-- Territorial: only attacks if player enters territory radius
function CreatureSpawner:behaviorTerritorial(creature: CreatureInstance, deltaTime: number)
	-- Store spawn position as territory center
	-- Only chase if within territory range
	local target, dist = self:findNearestPlayer(creature.position, 20)
	if target and target.Character then
		local targetPos = target.Character.HumanoidRootPart.Position
		local direction = (targetPos - creature.position).Unit
		creature.position += direction * creature.speed * deltaTime
		creature.targetPlayer = target
	end
end

-- Patrol Water: circle in water, attack boats and swimmers
function CreatureSpawner:behaviorPatrolWater(creature: CreatureInstance, deltaTime: number)
	-- Patrol in a circle pattern
	local time = tick()
	local patrolDir = Vector3.new(
		math.cos(time * 0.3),
		0,
		math.sin(time * 0.3)
	).Unit

	creature.position += patrolDir * creature.speed * deltaTime

	-- Attack nearby players in water
	local target, dist = self:findNearestPlayer(creature.position, 30)
	if target and dist < 15 and target.Character then
		local targetPos = target.Character.HumanoidRootPart.Position
		-- Only attack if player is in water (Y < water level)
		if targetPos.Y < 5 then -- approximate water level check
			local direction = (targetPos - creature.position).Unit
			creature.position += direction * creature.speed * 1.5 * deltaTime
			creature.targetPlayer = target
		end
	end
end

-- Remove all creatures (called when storm ends)
function CreatureSpawner:despawnAll()
	for id, creature in self.activeCreatures do
		creature.isAlive = false
	end

	-- Clear after brief delay for despawn animations
	task.delay(2, function()
		self.activeCreatures = {}
	end)
end

-- Get active creature count
function CreatureSpawner:getActiveCount(): number
	local count = 0
	for _, creature in self.activeCreatures do
		if creature.isAlive then
			count += 1
		end
	end
	return count
end

-- Get all creature states for replication
function CreatureSpawner:getAllCreatureStates()
	local states = {}
	for id, creature in self.activeCreatures do
		if creature.isAlive then
			states[id] = {
				id = creature.id,
				configId = creature.configId,
				name = creature.name,
				hp = creature.hp,
				maxHP = creature.maxHP,
				position = creature.position,
				behavior = creature.behavior,
				targetPlayer = creature.targetPlayer and creature.targetPlayer.UserId or nil,
			}
		end
	end
	return states
end

return CreatureSpawner
