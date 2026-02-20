--[[
	MathUtils.luau
	Shared math utility functions for 99 Storms.
]]

local MathUtils = {}

-- Linearly interpolate between two values
function MathUtils.lerp(a: number, b: number, t: number): number
	return a + (b - a) * math.clamp(t, 0, 1)
end

-- Inverse lerp: find t given a value between a and b
function MathUtils.inverseLerp(a: number, b: number, value: number): number
	if a == b then return 0 end
	return math.clamp((value - a) / (b - a), 0, 1)
end

-- Remap a value from one range to another
function MathUtils.remap(value: number, fromMin: number, fromMax: number, toMin: number, toMax: number): number
	local t = MathUtils.inverseLerp(fromMin, fromMax, value)
	return MathUtils.lerp(toMin, toMax, t)
end

-- Smooth damp (spring-like interpolation)
function MathUtils.smoothDamp(current: number, target: number, velocity: number, smoothTime: number, deltaTime: number): (number, number)
	smoothTime = math.max(0.0001, smoothTime)
	local omega = 2 / smoothTime
	local x = omega * deltaTime
	local exp = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
	local change = current - target
	local temp = (velocity + omega * change) * deltaTime
	velocity = (velocity - omega * temp) * exp
	local result = target + (change + temp) * exp
	return result, velocity
end

-- Weighted random selection from a table of {item, weight} pairs
function MathUtils.weightedRandom(items: { { any } }, weightIndex: number?): any
	weightIndex = weightIndex or 2

	local totalWeight = 0
	for _, item in items do
		totalWeight += item[weightIndex]
	end

	if totalWeight <= 0 then
		return items[1] and items[1][1]
	end

	local roll = math.random() * totalWeight
	local cumulative = 0

	for _, item in items do
		cumulative += item[weightIndex]
		if roll <= cumulative then
			return item[1]
		end
	end

	return items[#items][1]
end

-- Distance between two Vector3 positions (horizontal only, ignoring Y)
function MathUtils.horizontalDistance(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

-- Check if a position is within a radius of another (2D, ignoring Y)
function MathUtils.isWithinRadius(position: Vector3, center: Vector3, radius: number): boolean
	return MathUtils.horizontalDistance(position, center) <= radius
end

-- Random point within a circle (for spawning)
function MathUtils.randomPointInCircle(center: Vector3, radius: number): Vector3
	local angle = math.random() * math.pi * 2
	local dist = math.sqrt(math.random()) * radius
	return Vector3.new(
		center.X + math.cos(angle) * dist,
		center.Y,
		center.Z + math.sin(angle) * dist
	)
end

-- Format seconds into M:SS display
function MathUtils.formatTime(seconds: number): string
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", mins, secs)
end

return MathUtils
