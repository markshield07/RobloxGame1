--[[
	StormManager.luau
	Server-side storm cycle management for 99 Storms.
	Handles storm selection, timing, phases, and difficulty scaling.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local StormManager = {}
StormManager.__index = StormManager

export type StormState = "calm" | "warning" | "storm" | "aftermath"

function StormManager.new()
	local self = setmetatable({}, StormManager)

	self.currentStorm = 0
	self.state = "calm" :: StormState
	self.stateTimer = 0
	self.currentStormType = nil
	self.stormIntensity = 1.0
	self.isRunning = false
	self.onStateChanged = nil -- callback: (newState, stormType, stormNumber)
	self.onStormComplete = nil -- callback: (stormNumber)

	return self
end

-- Get the duration for the current storm based on progression
function StormManager:getStormDuration(): number
	local baseDuration = GameConfig.STORM_BASE_DURATION
	local bonus = 0

	for _, bracket in GameConfig.STORM_DURATION_SCALING do
		if self.currentStorm >= bracket.minStorm and self.currentStorm <= bracket.maxStorm then
			bonus = bracket.bonusDuration
			break
		end
	end

	-- Apply multiplayer scaling
	local playerCount = #Players:GetPlayers()
	local scaling = GameConfig.MULTIPLAYER_SCALING[math.clamp(playerCount, 1, 5)]

	return (baseDuration + bonus) * (scaling and scaling.stormDuration or 1.0)
end

-- Select the next storm type based on progression and weights
function StormManager:selectStormType(): string
	local stormNumber = self.currentStorm + 1

	-- Check for forced boss storms
	for _, bossStorm in GameConfig.BOSS_STORMS do
		if stormNumber == bossStorm then
			return "tempest_wrath"
		end
	end

	-- Build weighted pool of available storm types
	local pool = {}
	local totalWeight = 0

	for _, stormType in GameConfig.STORM_TYPES do
		if stormType.unlockStorm <= stormNumber and stormType.weight > 0 then
			table.insert(pool, stormType)
			totalWeight += stormType.weight
		end
	end

	if #pool == 0 then
		return "thunderstorm" -- fallback
	end

	-- Weighted random selection
	local roll = math.random() * totalWeight
	local cumulative = 0

	for _, stormType in pool do
		cumulative += stormType.weight
		if roll <= cumulative then
			return stormType.id
		end
	end

	return pool[#pool].id -- fallback to last in pool
end

-- Calculate storm intensity (1.0 = base, scales up with progression)
function StormManager:calculateIntensity(): number
	local progress = self.currentStorm / GameConfig.TOTAL_STORMS
	-- Exponential curve: starts gentle, ramps hard in late game
	return 1.0 + (progress * progress * 2.0)
end

-- Advance to the next state in the storm cycle
function StormManager:advanceState()
	if self.state == "calm" then
		-- Calm -> Warning
		self.state = "warning"
		self.stateTimer = GameConfig.STORM_WARNING_DURATION
		self.currentStormType = self:selectStormType()
		self.stormIntensity = self:calculateIntensity()

		if self.onStateChanged then
			self.onStateChanged("warning", self.currentStormType, self.currentStorm + 1)
		end

	elseif self.state == "warning" then
		-- Warning -> Storm
		self.state = "storm"
		self.currentStorm += 1
		self.stateTimer = self:getStormDuration()

		if self.onStateChanged then
			self.onStateChanged("storm", self.currentStormType, self.currentStorm)
		end

	elseif self.state == "storm" then
		-- Storm -> Aftermath
		self.state = "aftermath"
		self.stateTimer = GameConfig.AFTERMATH_DURATION

		if self.onStateChanged then
			self.onStateChanged("aftermath", self.currentStormType, self.currentStorm)
		end

		if self.onStormComplete then
			self.onStormComplete(self.currentStorm)
		end

	elseif self.state == "aftermath" then
		-- Aftermath -> Calm (or game over)
		if self.currentStorm >= GameConfig.TOTAL_STORMS then
			self.state = "calm"
			self.isRunning = false
			if self.onStateChanged then
				self.onStateChanged("game_complete", nil, self.currentStorm)
			end
			return
		end

		self.state = "calm"
		self.stateTimer = GameConfig.CALM_DURATION
		self.currentStormType = nil

		if self.onStateChanged then
			self.onStateChanged("calm", nil, self.currentStorm)
		end
	end
end

-- Start the storm cycle
function StormManager:start()
	self.isRunning = true
	self.state = "calm"
	self.stateTimer = GameConfig.CALM_DURATION
	self.currentStorm = 0

	if self.onStateChanged then
		self.onStateChanged("calm", nil, 0)
	end
end

-- Update the storm cycle (call every frame/tick from server heartbeat)
function StormManager:update(deltaTime: number)
	if not self.isRunning then
		return
	end

	self.stateTimer -= deltaTime

	if self.stateTimer <= 0 then
		self:advanceState()
	end
end

-- Get current state info for replication to clients
function StormManager:getStateInfo()
	return {
		state = self.state,
		stormNumber = self.currentStorm,
		stormType = self.currentStormType,
		intensity = self.stormIntensity,
		timeRemaining = math.max(0, self.stateTimer),
		totalStorms = GameConfig.TOTAL_STORMS,
		isBossStorm = table.find(GameConfig.BOSS_STORMS, self.currentStorm) ~= nil,
	}
end

-- Check if a zone should be unlocked
function StormManager:isZoneUnlocked(zoneId: string): boolean
	for _, zone in GameConfig.ZONES do
		if zone.id == zoneId then
			return self.currentStorm >= zone.unlockStorm
		end
	end
	return false
end

-- Check if a rescue mission is available
function StormManager:isRescueAvailable(rescueId: string): boolean
	for _, rescue in GameConfig.RESCUES do
		if rescue.id == rescueId then
			return self.currentStorm >= rescue.unlockStorm
		end
	end
	return false
end

return StormManager
