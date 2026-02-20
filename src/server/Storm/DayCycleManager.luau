--[[
	DayCycleManager.luau
	Tracks the day/night cycle for 99 Storms.
	1 day = 3 real minutes. Each day brings a storm that gets worse.
	Cycle: Daytime → Warning → Storm → Aftermath → next day
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local DayCycleManager = {}
DayCycleManager.__index = DayCycleManager

export type DayPhase = "daytime" | "warning" | "storm" | "aftermath"

function DayCycleManager.new()
	local self = setmetatable({}, DayCycleManager)

	self.currentDay = 0
	self.phase = "daytime" :: DayPhase
	self.phaseTimer = 0
	self.totalTime = 0 -- total elapsed game time
	self.isRunning = false
	self.bestDay = 0

	-- Callbacks
	self.onDayChanged = nil -- (dayNumber)
	self.onPhaseChanged = nil -- (phase, dayNumber, stormIntensity)

	return self
end

-- Get storm duration for current day (scales up)
function DayCycleManager:getStormDuration(): number
	local base = GameConfig.STORM_BASE_DURATION_DAY
	-- Storm gets longer: +2 seconds per day, capped at 90 seconds
	local bonus = math.min(self.currentDay * 2, 50)
	return base + bonus
end

-- Get storm intensity for current day
function DayCycleManager:getIntensity(): number
	-- Starts at 1.0, increases by 0.05 per day
	-- Day 1: 1.05, Day 10: 1.5, Day 25: 2.25, Day 50: 3.5, Day 99: 5.95
	return 1.0 + (self.currentDay * 0.05)
end

-- Select storm type based on day number
function DayCycleManager:selectStormType(): string
	-- Boss storms at days 25, 50, 75, 99
	for _, bossDay in GameConfig.BOSS_STORMS do
		if self.currentDay == bossDay then
			return "tempest_wrath"
		end
	end

	-- Build weighted pool
	local pool = {}
	local totalWeight = 0

	for _, stormType in GameConfig.STORM_TYPES do
		if stormType.unlockStorm <= self.currentDay and stormType.weight > 0 then
			table.insert(pool, stormType)
			totalWeight += stormType.weight
		end
	end

	if #pool == 0 then
		return "thunderstorm"
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, stormType in pool do
		cumulative += stormType.weight
		if roll <= cumulative then
			return stormType.id
		end
	end

	return pool[#pool].id
end

-- Start the day cycle
function DayCycleManager:start()
	self.isRunning = true
	self.currentDay = 1
	self.phase = "daytime"
	self.phaseTimer = GameConfig.DAYTIME_DURATION
	self.totalTime = 0

	if self.onDayChanged then
		self.onDayChanged(self.currentDay)
	end
	if self.onPhaseChanged then
		self.onPhaseChanged("daytime", self.currentDay, self:getIntensity())
	end
end

-- Advance to next phase
function DayCycleManager:advancePhase()
	if self.phase == "daytime" then
		self.phase = "warning"
		self.phaseTimer = GameConfig.WARNING_DURATION

		if self.onPhaseChanged then
			self.onPhaseChanged("warning", self.currentDay, self:getIntensity())
		end

	elseif self.phase == "warning" then
		self.phase = "storm"
		self.phaseTimer = self:getStormDuration()

		if self.onPhaseChanged then
			self.onPhaseChanged("storm", self.currentDay, self:getIntensity())
		end

	elseif self.phase == "storm" then
		self.phase = "aftermath"
		self.phaseTimer = GameConfig.AFTERMATH_DURATION_DAY

		if self.onPhaseChanged then
			self.onPhaseChanged("aftermath", self.currentDay, self:getIntensity())
		end

	elseif self.phase == "aftermath" then
		-- Next day
		self.currentDay += 1
		if self.currentDay > self.bestDay then
			self.bestDay = self.currentDay
		end

		if self.currentDay > GameConfig.TOTAL_STORMS then
			self.isRunning = false
			if self.onPhaseChanged then
				self.onPhaseChanged("game_complete", self.currentDay - 1, self:getIntensity())
			end
			return
		end

		self.phase = "daytime"
		self.phaseTimer = GameConfig.DAYTIME_DURATION

		if self.onDayChanged then
			self.onDayChanged(self.currentDay)
		end
		if self.onPhaseChanged then
			self.onPhaseChanged("daytime", self.currentDay, self:getIntensity())
		end
	end
end

-- Update (call from Heartbeat)
function DayCycleManager:update(deltaTime: number)
	if not self.isRunning then return end

	self.totalTime += deltaTime
	self.phaseTimer -= deltaTime

	if self.phaseTimer <= 0 then
		self:advancePhase()
	end
end

-- Get outdoor exposure damage for current day
function DayCycleManager:getExposureDamage(): number
	if self.phase ~= "storm" then return 0 end
	local cfg = GameConfig.STORM_EXPOSURE
	return cfg.BASE_DAMAGE_PER_SECOND + (self.currentDay * cfg.SCALING_PER_DAY)
end

-- Get state for replication
function DayCycleManager:getStateInfo()
	return {
		currentDay = self.currentDay,
		phase = self.phase,
		timeRemaining = math.max(0, self.phaseTimer),
		intensity = self:getIntensity(),
		totalTime = self.totalTime,
		bestDay = self.bestDay,
	}
end

return DayCycleManager
