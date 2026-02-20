--[[
	PlayerCharacter.luau
	Server-side player character state manager for 99 Storms.
	Handles health, hunger, morale, stamina, and status effects.
	Runs authoritative simulation — client only displays values.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local PlayerCharacter = {}
PlayerCharacter.__index = PlayerCharacter

export type StatusEffect = {
	id: string,
	name: string,
	duration: number, -- remaining seconds
	tickRate: number, -- seconds between ticks
	tickTimer: number,
	onTick: ((state: PlayerState) -> ())?,
	onExpire: ((state: PlayerState) -> ())?,
}

export type PlayerState = {
	userId: number,
	health: number,
	maxHealth: number,
	hunger: number,
	maxHunger: number,
	morale: number,
	maxMorale: number,
	stamina: number,
	maxStamina: number,
	isSprinting: boolean,
	isSheltered: boolean,
	isPanicking: boolean,
	panicTimer: number,
	isDead: boolean,
	respawnTimer: number,
	statusEffects: { [string]: StatusEffect },
	classId: string,
	weatherResistance: number, -- 0-1 multiplier on weather damage
}

function PlayerCharacter.new()
	local self = setmetatable({}, PlayerCharacter)

	self.states = {} :: { [number]: PlayerState } -- userId -> state
	self.onPlayerDied = nil -- callback(userId)
	self.onPlayerRespawned = nil -- callback(userId)
	self.onStateChanged = nil -- callback(userId, state)

	return self
end

-- Initialize state for a new player
function PlayerCharacter:initPlayer(userId: number, classId: string?)
	local cfg = GameConfig.PLAYER

	-- Calculate class bonuses
	local weatherResistance = 0
	if classId == "weatherman" then
		weatherResistance = 0.15
	elseif classId == "stormchaser" then
		weatherResistance = 0.10
	end

	local state: PlayerState = {
		userId = userId,
		health = cfg.MAX_HEALTH,
		maxHealth = cfg.MAX_HEALTH,
		hunger = cfg.MAX_HUNGER,
		maxHunger = cfg.MAX_HUNGER,
		morale = GameConfig.MORALE.STARTING,
		maxMorale = GameConfig.MORALE.MAX,
		stamina = cfg.MAX_STAMINA,
		maxStamina = cfg.MAX_STAMINA,
		isSprinting = false,
		isSheltered = false,
		isPanicking = false,
		panicTimer = 0,
		isDead = false,
		respawnTimer = 0,
		statusEffects = {},
		classId = classId or "weatherman",
		weatherResistance = weatherResistance,
	}

	self.states[userId] = state
	return state
end

-- Get player state
function PlayerCharacter:getState(userId: number): PlayerState?
	return self.states[userId]
end

-- Main update tick — call from Heartbeat
function PlayerCharacter:update(deltaTime: number, isStormActive: boolean)
	for userId, state in self.states do
		if state.isDead then
			self:updateDead(state, deltaTime)
		else
			self:updateAlive(state, deltaTime, isStormActive)
		end

		-- Update status effects
		self:updateStatusEffects(state, deltaTime)
	end
end

function PlayerCharacter:updateAlive(state: PlayerState, deltaTime: number, isStormActive: boolean)
	local cfg = GameConfig.PLAYER
	local moraleCfg = GameConfig.MORALE

	-- ====== HUNGER ======
	state.hunger = math.max(0, state.hunger - cfg.HUNGER_DRAIN_PER_SECOND * deltaTime)

	-- Starvation damage
	if state.hunger <= 0 then
		self:damage(state, cfg.STARVATION_DAMAGE_PER_SECOND * deltaTime, "starvation")
	end

	-- ====== STAMINA ======
	if state.isSprinting then
		state.stamina = math.max(0, state.stamina - cfg.SPRINT_STAMINA_DRAIN * deltaTime)
		if state.stamina <= 0 then
			state.isSprinting = false
		end
	else
		state.stamina = math.min(state.maxStamina, state.stamina + cfg.STAMINA_REGEN * deltaTime)
	end

	-- ====== MORALE ======
	if isStormActive then
		local drainRate = moraleCfg.STORM_DRAIN_PER_SECOND
		if state.isSheltered then
			drainRate = drainRate * 0.3 -- 70% reduction when sheltered
		end
		state.morale = math.max(0, state.morale - drainRate * deltaTime)
	else
		-- Calm regen
		local regenRate = moraleCfg.CALM_REGEN_PER_SECOND
		if state.isSheltered then
			regenRate = regenRate + moraleCfg.CAMPFIRE_BOOST_PER_SECOND
		end
		state.morale = math.min(state.maxMorale, state.morale + regenRate * deltaTime)
	end

	-- Panic check
	if state.morale <= moraleCfg.PANIC_THRESHOLD and not state.isPanicking then
		state.isPanicking = true
		state.panicTimer = moraleCfg.PANIC_DURATION
	end

	if state.isPanicking then
		state.panicTimer -= deltaTime
		if state.panicTimer <= 0 then
			state.isPanicking = false
			state.panicTimer = 0
		end
	end

	-- ====== APPLY TO CHARACTER ======
	self:syncToCharacter(state)
end

function PlayerCharacter:updateDead(state: PlayerState, deltaTime: number)
	state.respawnTimer -= deltaTime
	if state.respawnTimer <= 0 then
		self:respawn(state)
	end
end

-- ====== DAMAGE / HEALING ======

function PlayerCharacter:damage(state: PlayerState, amount: number, source: string?)
	if state.isDead then return end

	-- Apply weather resistance for weather damage
	if source == "weather" or source == "lightning" or source == "hail" or source == "wind" then
		amount = amount * (1 - state.weatherResistance)
	end

	state.health = math.max(0, state.health - amount)

	if state.health <= 0 then
		self:kill(state, source)
	end
end

function PlayerCharacter:heal(state: PlayerState, amount: number)
	if state.isDead then return end
	state.health = math.min(state.maxHealth, state.health + amount)
end

function PlayerCharacter:feed(state: PlayerState, hungerAmount: number, moraleBoost: number?)
	if state.isDead then return end
	state.hunger = math.min(state.maxHunger, state.hunger + hungerAmount)
	if moraleBoost then
		state.morale = math.min(state.maxMorale, state.morale + moraleBoost)
	end
end

function PlayerCharacter:kill(state: PlayerState, source: string?)
	state.isDead = true
	state.health = 0
	state.respawnTimer = GameConfig.PLAYER.RESPAWN_TIME

	-- Morale penalty for everyone
	if self.onPlayerDied then
		self.onPlayerDied(state.userId, source)
	end
end

function PlayerCharacter:respawn(state: PlayerState)
	state.isDead = false
	state.health = state.maxHealth * 0.5 -- respawn at half health
	state.hunger = math.max(state.hunger, state.maxHunger * 0.3)
	state.respawnTimer = 0

	if self.onPlayerRespawned then
		self.onPlayerRespawned(state.userId)
	end
end

-- Revive a downed player (teammate action)
function PlayerCharacter:revive(state: PlayerState, reviveHealthPercent: number?)
	reviveHealthPercent = reviveHealthPercent or 0.3
	state.isDead = false
	state.health = state.maxHealth * reviveHealthPercent
	state.respawnTimer = 0

	if self.onPlayerRespawned then
		self.onPlayerRespawned(state.userId)
	end
end

-- ====== STATUS EFFECTS ======

function PlayerCharacter:applyEffect(userId: number, effect: StatusEffect)
	local state = self.states[userId]
	if not state then return end

	-- Overwrite existing effect of same ID
	state.statusEffects[effect.id] = effect
end

function PlayerCharacter:removeEffect(userId: number, effectId: string)
	local state = self.states[userId]
	if not state then return end

	local effect = state.statusEffects[effectId]
	if effect and effect.onExpire then
		effect.onExpire(state)
	end

	state.statusEffects[effectId] = nil
end

function PlayerCharacter:updateStatusEffects(state: PlayerState, deltaTime: number)
	local toRemove = {}

	for id, effect in state.statusEffects do
		effect.duration -= deltaTime
		effect.tickTimer -= deltaTime

		if effect.tickTimer <= 0 then
			effect.tickTimer = effect.tickRate
			if effect.onTick then
				effect.onTick(state)
			end
		end

		if effect.duration <= 0 then
			table.insert(toRemove, id)
		end
	end

	for _, id in toRemove do
		self:removeEffect(state.userId, id)
	end
end

-- ====== COMMON STATUS EFFECTS ======

function PlayerCharacter:applyPoison(userId: number, duration: number, dps: number)
	self:applyEffect(userId, {
		id = "poison",
		name = "Poisoned",
		duration = duration,
		tickRate = 1,
		tickTimer = 1,
		onTick = function(state)
			self:damage(state, dps, "poison")
		end,
		onExpire = nil,
	})
end

function PlayerCharacter:applyFreeze(userId: number, duration: number)
	self:applyEffect(userId, {
		id = "freeze",
		name = "Frozen",
		duration = duration,
		tickRate = 999,
		tickTimer = 999,
		onTick = nil,
		onExpire = nil,
	})
	-- Freeze slows movement — handled in syncToCharacter
end

function PlayerCharacter:applyBurn(userId: number, duration: number, dps: number)
	self:applyEffect(userId, {
		id = "burn",
		name = "Burning",
		duration = duration,
		tickRate = 0.5,
		tickTimer = 0.5,
		onTick = function(state)
			self:damage(state, dps, "burn")
		end,
		onExpire = nil,
	})
end

-- ====== SPRINT ======

function PlayerCharacter:setSprinting(userId: number, sprinting: boolean)
	local state = self.states[userId]
	if not state then return end
	state.isSprinting = sprinting and state.stamina > 0
end

-- ====== SHELTER ======

function PlayerCharacter:setSheltered(userId: number, sheltered: boolean)
	local state = self.states[userId]
	if not state then return end
	state.isSheltered = sheltered
end

-- ====== SYNC TO ROBLOX CHARACTER ======

function PlayerCharacter:syncToCharacter(state: PlayerState)
	local player = Players:GetPlayerByUserId(state.userId)
	if not player or not player.Character then return end

	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- Sync health
	humanoid.MaxHealth = state.maxHealth
	humanoid.Health = state.health

	-- Sync movement speed
	local baseSpeed = GameConfig.PLAYER.BASE_MOVE_SPEED

	if state.isSprinting and state.stamina > 0 then
		baseSpeed = baseSpeed * GameConfig.PLAYER.SPRINT_MULTIPLIER
	end

	-- Apply status effect modifiers
	if state.statusEffects["freeze"] then
		baseSpeed = baseSpeed * 0.4 -- 60% slow
	end

	if state.isPanicking then
		baseSpeed = baseSpeed * 0.7 -- panic slow
	end

	humanoid.WalkSpeed = baseSpeed
end

-- ====== FOOD ITEMS ======
-- Returns: { hunger: number, health: number, morale: number }

local FOOD_VALUES = {
	cooked_fish =     { hunger = 25, health = 0,  morale = 5 },
	fish_stew =       { hunger = 40, health = 10, morale = 10 },
	clam_chowder =    { hunger = 35, health = 5,  morale = 8 },
	herbal_tea =      { hunger = 5,  health = 5,  morale = 20 },
	storm_feast =     { hunger = 60, health = 20, morale = 25 },
	lobster_dinner =  { hunger = 50, health = 10, morale = 15 },
	raw_fish =        { hunger = 10, health = 0,  morale = -5 },
}

function PlayerCharacter:consumeFood(userId: number, foodId: string): (boolean, string)
	local state = self.states[userId]
	if not state then return false, "Player not found" end
	if state.isDead then return false, "Cannot eat while dead" end

	local food = FOOD_VALUES[foodId]
	if not food then return false, "Not a food item" end

	self:feed(state, food.hunger, food.morale)
	if food.health > 0 then
		self:heal(state, food.health)
	end

	return true, "Consumed " .. foodId
end

-- ====== MEDICAL ITEMS ======

local MEDICAL_VALUES = {
	bandage =     { health = 20 },
	medical_kit = { health = 50 },
	storm_salve = { health = 40, cureAll = true },
	antivenom =   { health = 10, cures = { "poison" } },
}

function PlayerCharacter:useMedical(userId: number, itemId: string): (boolean, string)
	local state = self.states[userId]
	if not state then return false, "Player not found" end
	if state.isDead then return false, "Cannot use while dead" end

	local med = MEDICAL_VALUES[itemId]
	if not med then return false, "Not a medical item" end

	self:heal(state, med.health)

	if med.cureAll then
		for effectId, _ in state.statusEffects do
			self:removeEffect(userId, effectId)
		end
	elseif med.cures then
		for _, effectId in med.cures do
			self:removeEffect(userId, effectId)
		end
	end

	return true, "Used " .. itemId
end

-- ====== GET STATE FOR CLIENT ======

function PlayerCharacter:getClientState(userId: number)
	local state = self.states[userId]
	if not state then return nil end

	local effects = {}
	for id, effect in state.statusEffects do
		effects[id] = {
			name = effect.name,
			duration = effect.duration,
		}
	end

	return {
		health = state.health,
		maxHealth = state.maxHealth,
		hunger = state.hunger,
		maxHunger = state.maxHunger,
		morale = state.morale,
		maxMorale = state.maxMorale,
		stamina = state.stamina,
		maxStamina = state.maxStamina,
		isSheltered = state.isSheltered,
		isPanicking = state.isPanicking,
		isDead = state.isDead,
		respawnTimer = state.respawnTimer,
		statusEffects = effects,
	}
end

-- Clean up
function PlayerCharacter:removePlayer(userId: number)
	self.states[userId] = nil
end

return PlayerCharacter
