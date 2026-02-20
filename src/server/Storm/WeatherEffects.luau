--[[
	WeatherEffects.luau
	Server-side weather effect controller.
	Manages the gameplay effects of each storm type (damage, flooding, etc).
	Visual effects are handled client-side; this controls the authoritative game state.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local WeatherEffects = {}
WeatherEffects.__index = WeatherEffects

function WeatherEffects.new()
	local self = setmetatable({}, WeatherEffects)

	self.activeEffects = {}
	self.waterLevel = 0 -- base water level (studs)
	self.windDirection = Vector3.new(0, 0, 0)
	self.windStrength = 0
	self.visibility = 1.0 -- 0 = blind, 1 = full
	self.temperature = 0.5 -- 0 = freezing, 1 = hot
	self.lightningTargets = {} -- positions queued for lightning strikes

	return self
end

-- Apply effects for a given storm type and intensity
function WeatherEffects:applyStormEffects(stormType: string, intensity: number)
	self:clearEffects()

	if stormType == "thunderstorm" then
		self:applyThunderstorm(intensity)
	elseif stormType == "fog" then
		self:applyFogStorm(intensity)
	elseif stormType == "hurricane" then
		self:applyHurricane(intensity)
	elseif stormType == "hailstorm" then
		self:applyHailstorm(intensity)
	elseif stormType == "tornado" then
		self:applyTornado(intensity)
	elseif stormType == "tsunami" then
		self:applyTsunami(intensity)
	elseif stormType == "snowstorm" then
		self:applySnowstorm(intensity)
	elseif stormType == "blood_storm" then
		self:applyBloodStorm(intensity)
	elseif stormType == "tempest_wrath" then
		self:applyTempestWrath(intensity)
	end
end

function WeatherEffects:applyThunderstorm(intensity: number)
	self.visibility = math.max(0.4, 1.0 - (intensity * 0.2))
	self.windStrength = 5 * intensity
	self.windDirection = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit

	self.activeEffects = {
		rain = true,
		lightning = true,
		lightningFrequency = 3 + (intensity * 2), -- strikes per minute
		lightningDamage = 40 * intensity,
		rainReductionVisibility = 0.15 * intensity,
	}
end

function WeatherEffects:applyFogStorm(intensity: number)
	self.visibility = math.max(0.05, 0.3 - (intensity * 0.1))
	self.windStrength = 1
	self.windDirection = Vector3.new(0, 0, 0)

	self.activeEffects = {
		fog = true,
		fogDensity = 0.5 + (intensity * 0.2),
		soundDampening = 0.3 * intensity,
		creatureSilence = true, -- fog phantoms make no sound
	}
end

function WeatherEffects:applyHurricane(intensity: number)
	self.visibility = math.max(0.3, 0.7 - (intensity * 0.15))
	self.windStrength = 20 * intensity
	self.windDirection = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit

	self.activeEffects = {
		rain = true,
		extremeWind = true,
		debrisDamage = 5 * intensity, -- per second when outside
		structuralDamage = 2 * intensity, -- per second to unfortified walls
		playerPush = true,
		pushForce = 10 * intensity,
	}
end

function WeatherEffects:applyHailstorm(intensity: number)
	self.visibility = math.max(0.4, 0.8 - (intensity * 0.1))
	self.windStrength = 8 * intensity
	self.temperature = math.max(0, 0.3 - (intensity * 0.1))

	self.activeEffects = {
		hail = true,
		hailDamage = 3 * intensity, -- per second when outside without cover
		iceBuildUp = true,
		movementSlow = 0.2 * intensity, -- movement speed reduction outside
		roofDamage = 1 * intensity, -- per second to damaged roofs
	}
end

function WeatherEffects:applyTornado(intensity: number)
	self.visibility = 0.5
	self.windStrength = 30 * intensity

	self.activeEffects = {
		tornado = true,
		tornadoPath = {}, -- calculated path through the town
		tornadoDamage = 100, -- instant kill/destroy on contact
		tornadoRadius = 8 + (intensity * 3),
		tornadoSpeed = 10 + (intensity * 2),
		suctionRange = 15 + (intensity * 5),
		suctionForce = 15 * intensity,
	}
end

function WeatherEffects:applyTsunami(intensity: number)
	self.visibility = 0.6
	self.windStrength = 10

	local floodHeight = 10 + (intensity * 5) -- studs above base water level

	self.activeEffects = {
		tsunami = true,
		floodHeight = floodHeight,
		floodSpeed = 2 * intensity, -- studs per second water rises
		drownDamage = 10, -- per second while submerged
		currentStrength = 5 * intensity, -- push force in water
	}
end

function WeatherEffects:applySnowstorm(intensity: number)
	self.visibility = math.max(0.3, 0.7 - (intensity * 0.15))
	self.windStrength = 10 * intensity
	self.windDirection = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
	self.temperature = math.max(0, 0.1 - (intensity * 0.05))

	self.activeEffects = {
		snow = true,
		snowDensity = 0.6 + (intensity * 0.2),
		freezeDamage = 2 * intensity, -- per second when outside without warmth
		staminaDrainMultiplier = 1.5 + (intensity * 0.3), -- stamina drains faster
		movementSlow = 0.15 * intensity, -- movement reduction outside
		iceBuildUp = true,
	}
end

function WeatherEffects:applyBloodStorm(intensity: number)
	-- Blood storm combines elements of all storm types
	self.visibility = 0.3
	self.windStrength = 15 * intensity
	self.windDirection = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
	self.temperature = 0.2

	self.activeEffects = {
		bloodRain = true,
		lightning = true,
		lightningFrequency = 5 + (intensity * 3),
		lightningDamage = 30 * intensity,
		fog = true,
		fogDensity = 0.3,
		hail = true,
		hailDamage = 2 * intensity,
		allCreaturesSpawn = true, -- every creature type can spawn
		moraleDrainMultiplier = 2.0,
	}
end

function WeatherEffects:applyTempestWrath(intensity: number)
	-- Boss storm — The Tempest directly attacks
	self.visibility = 0.4
	self.windStrength = 25 * intensity
	self.windDirection = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit

	self.activeEffects = {
		bossStorm = true,
		rain = true,
		lightning = true,
		lightningFrequency = 8 + (intensity * 4),
		lightningDamage = 50 * intensity,
		extremeWind = true,
		pushForce = 12 * intensity,
		tempestManifest = true, -- The Tempest is physically present
		possessedObjects = true, -- town objects come alive
		structuralDamage = 3 * intensity,
	}
end

-- Queue a lightning strike at a position (called periodically during thunderstorms)
function WeatherEffects:queueLightningStrike(position: Vector3)
	table.insert(self.lightningTargets, {
		position = position,
		timestamp = tick(),
	})
end

-- Get the current flood level (for tsunami storms)
function WeatherEffects:getFloodLevel(): number
	if self.activeEffects.tsunami then
		return self.waterLevel + (self.activeEffects.floodHeight or 0)
	end
	return self.waterLevel
end

-- Check if a position is flooded
function WeatherEffects:isFlooded(position: Vector3): boolean
	return position.Y < self:getFloodLevel()
end

-- Check if a player is sheltered (under a roof with intact walls)
function WeatherEffects:isPlayerSheltered(player: Player): boolean
	-- This would raycast upward from the player to check for roof
	-- and check surrounding wall integrity
	-- Placeholder for actual implementation
	local character = player.Character
	if not character then return false end

	local head = character:FindFirstChild("Head")
	if not head then return false end

	-- Raycast upward to check for ceiling
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(head.Position, Vector3.new(0, 10, 0), rayParams)
	return result ~= nil
end

-- Clear all active effects (between storms)
function WeatherEffects:clearEffects()
	self.activeEffects = {}
	self.visibility = 1.0
	self.windStrength = 0
	self.windDirection = Vector3.new(0, 0, 0)
	self.temperature = 0.5
	self.lightningTargets = {}
end

-- Get current weather state for replication to clients
function WeatherEffects:getWeatherState()
	return {
		effects = self.activeEffects,
		visibility = self.visibility,
		windDirection = self.windDirection,
		windStrength = self.windStrength,
		temperature = self.temperature,
		floodLevel = self:getFloodLevel(),
	}
end

return WeatherEffects
