--[[
	WeatherRenderer.luau
	Client-side weather visual effects for 99 Storms.
	Handles rain, fog, lightning, wind, hail, and other atmospheric effects.
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local WeatherRenderer = {}

-- Internal state
local currentEffects = {}
local particleEmitters = {}
local atmosphereEffect = nil
local bloomEffect = nil
local colorCorrectionEffect = nil
local blurEffect = nil
local isStormActive = false
local stormIntensity = 1.0

-- ================================
-- INITIALIZATION
-- ================================

function WeatherRenderer.init()
	-- Create lighting effects if they don't exist
	atmosphereEffect = Lighting:FindFirstChild("StormAtmosphere")
	if not atmosphereEffect then
		atmosphereEffect = Instance.new("Atmosphere")
		atmosphereEffect.Name = "StormAtmosphere"
		atmosphereEffect.Density = 0
		atmosphereEffect.Offset = 0
		atmosphereEffect.Color = Color3.fromRGB(180, 190, 200)
		atmosphereEffect.Decay = Color3.fromRGB(120, 130, 140)
		atmosphereEffect.Glare = 0
		atmosphereEffect.Haze = 0
		atmosphereEffect.Parent = Lighting
	end

	bloomEffect = Lighting:FindFirstChild("StormBloom")
	if not bloomEffect then
		bloomEffect = Instance.new("BloomEffect")
		bloomEffect.Name = "StormBloom"
		bloomEffect.Intensity = 0
		bloomEffect.Size = 24
		bloomEffect.Threshold = 1
		bloomEffect.Enabled = false
		bloomEffect.Parent = Lighting
	end

	colorCorrectionEffect = Lighting:FindFirstChild("StormColorCorrection")
	if not colorCorrectionEffect then
		colorCorrectionEffect = Instance.new("ColorCorrectionEffect")
		colorCorrectionEffect.Name = "StormColorCorrection"
		colorCorrectionEffect.Brightness = 0
		colorCorrectionEffect.Contrast = 0
		colorCorrectionEffect.Saturation = 0
		colorCorrectionEffect.TintColor = Color3.fromRGB(255, 255, 255)
		colorCorrectionEffect.Enabled = false
		colorCorrectionEffect.Parent = Lighting
	end

	blurEffect = Lighting:FindFirstChild("StormBlur")
	if not blurEffect then
		blurEffect = Instance.new("BlurEffect")
		blurEffect.Name = "StormBlur"
		blurEffect.Size = 0
		blurEffect.Enabled = false
		blurEffect.Parent = Lighting
	end
end

-- ================================
-- STORM VISUAL PRESETS
-- ================================

local STORM_PRESETS = {
	thunderstorm = {
		ambientBrightness = -0.1,
		contrast = 0.15,
		saturation = -0.2,
		tintColor = Color3.fromRGB(180, 190, 210),
		atmosphereDensity = 0.3,
		atmosphereHaze = 3,
		fogColor = Color3.fromRGB(100, 110, 130),
		clockTime = 0, -- midnight feel
	},
	fog = {
		ambientBrightness = -0.05,
		contrast = -0.1,
		saturation = -0.4,
		tintColor = Color3.fromRGB(200, 200, 210),
		atmosphereDensity = 0.8,
		atmosphereHaze = 10,
		fogColor = Color3.fromRGB(160, 165, 175),
		blurSize = 6,
		clockTime = 3,
	},
	hurricane = {
		ambientBrightness = -0.15,
		contrast = 0.2,
		saturation = -0.1,
		tintColor = Color3.fromRGB(170, 180, 200),
		atmosphereDensity = 0.4,
		atmosphereHaze = 5,
		fogColor = Color3.fromRGB(90, 100, 120),
		clockTime = 1,
	},
	hailstorm = {
		ambientBrightness = -0.05,
		contrast = 0.1,
		saturation = -0.3,
		tintColor = Color3.fromRGB(200, 210, 230),
		atmosphereDensity = 0.35,
		atmosphereHaze = 4,
		fogColor = Color3.fromRGB(180, 190, 210),
		clockTime = 2,
	},
	tornado = {
		ambientBrightness = -0.2,
		contrast = 0.25,
		saturation = -0.15,
		tintColor = Color3.fromRGB(150, 170, 130),
		atmosphereDensity = 0.5,
		atmosphereHaze = 6,
		fogColor = Color3.fromRGB(80, 90, 70),
		clockTime = 18,
	},
	tsunami = {
		ambientBrightness = -0.1,
		contrast = 0.15,
		saturation = 0.1,
		tintColor = Color3.fromRGB(170, 200, 210),
		atmosphereDensity = 0.3,
		atmosphereHaze = 3,
		fogColor = Color3.fromRGB(100, 140, 160),
		clockTime = 22,
	},
	blood_storm = {
		ambientBrightness = -0.2,
		contrast = 0.3,
		saturation = 0.2,
		tintColor = Color3.fromRGB(255, 150, 150),
		atmosphereDensity = 0.5,
		atmosphereHaze = 5,
		fogColor = Color3.fromRGB(120, 50, 50),
		clockTime = 0,
	},
	tempest_wrath = {
		ambientBrightness = -0.25,
		contrast = 0.35,
		saturation = -0.1,
		tintColor = Color3.fromRGB(160, 170, 220),
		atmosphereDensity = 0.6,
		atmosphereHaze = 7,
		fogColor = Color3.fromRGB(60, 70, 100),
		clockTime = 0,
	},
}

local CALM_PRESET = {
	ambientBrightness = 0,
	contrast = 0,
	saturation = 0,
	tintColor = Color3.fromRGB(255, 255, 255),
	atmosphereDensity = 0.15,
	atmosphereHaze = 0,
	fogColor = Color3.fromRGB(180, 195, 210),
	blurSize = 0,
	clockTime = 14, -- afternoon
}

-- ================================
-- WEATHER TRANSITIONS
-- ================================

local function tweenLighting(preset, duration: number)
	duration = duration or 2.0

	-- Tween color correction
	colorCorrectionEffect.Enabled = true
	TweenService:Create(colorCorrectionEffect, TweenInfo.new(duration), {
		Brightness = preset.ambientBrightness or 0,
		Contrast = preset.contrast or 0,
		Saturation = preset.saturation or 0,
		TintColor = preset.tintColor or Color3.fromRGB(255, 255, 255),
	}):Play()

	-- Tween atmosphere
	TweenService:Create(atmosphereEffect, TweenInfo.new(duration), {
		Density = preset.atmosphereDensity or 0,
		Haze = preset.atmosphereHaze or 0,
		Color = preset.fogColor or Color3.fromRGB(180, 195, 210),
	}):Play()

	-- Tween blur (fog storms)
	if preset.blurSize and preset.blurSize > 0 then
		blurEffect.Enabled = true
		TweenService:Create(blurEffect, TweenInfo.new(duration), {
			Size = preset.blurSize,
		}):Play()
	else
		TweenService:Create(blurEffect, TweenInfo.new(duration), {
			Size = 0,
		}):Play()
		task.delay(duration, function()
			if not isStormActive then
				blurEffect.Enabled = false
			end
		end)
	end

	-- Tween clock time
	if preset.clockTime then
		TweenService:Create(Lighting, TweenInfo.new(duration * 2), {
			ClockTime = preset.clockTime,
		}):Play()
	end
end

-- ================================
-- PUBLIC API
-- ================================

function WeatherRenderer.startStorm(stormType: string, intensity: number)
	isStormActive = true
	stormIntensity = intensity or 1.0

	local preset = STORM_PRESETS[stormType]
	if preset then
		tweenLighting(preset, 3.0) -- 3 second transition into storm
	end

	-- TODO: Spawn rain/hail/fog particle emitters based on storm type
	-- TODO: Start wind sound effects
	-- TODO: Start ambient storm sounds
end

function WeatherRenderer.clearWeather()
	isStormActive = false
	stormIntensity = 1.0
	tweenLighting(CALM_PRESET, 5.0) -- 5 second transition to calm

	-- TODO: Fade out particle emitters
	-- TODO: Stop storm sounds
end

function WeatherRenderer.startAftermath()
	-- Slightly overcast, but calm
	local aftermathPreset = {
		ambientBrightness = -0.03,
		contrast = 0.05,
		saturation = -0.05,
		tintColor = Color3.fromRGB(230, 235, 240),
		atmosphereDensity = 0.2,
		atmosphereHaze = 1,
		fogColor = Color3.fromRGB(170, 180, 195),
		blurSize = 0,
		clockTime = 7, -- early morning feel
	}
	tweenLighting(aftermathPreset, 3.0)
end

function WeatherRenderer.updateWeather(weatherData)
	-- Update ongoing weather effects based on server data
	if weatherData.effects then
		currentEffects = weatherData.effects
	end

	-- TODO: Update particle emitter rates based on intensity
	-- TODO: Update wind audio panning based on windDirection
end

function WeatherRenderer.renderLightningStrike(position: Vector3)
	-- Flash effect
	bloomEffect.Enabled = true
	bloomEffect.Intensity = 1
	bloomEffect.Threshold = 0.8

	-- Quick flash tween
	local flashTween = TweenService:Create(bloomEffect, TweenInfo.new(0.05), {
		Intensity = 3,
	})
	flashTween:Play()

	task.delay(0.1, function()
		local fadeTween = TweenService:Create(bloomEffect, TweenInfo.new(0.4), {
			Intensity = 0,
		})
		fadeTween:Play()

		task.delay(0.5, function()
			if not isStormActive then
				bloomEffect.Enabled = false
			end
		end)
	end)

	-- TODO: Spawn lightning bolt visual at position
	-- TODO: Spawn impact particle effect
	-- TODO: Play thunder sound with distance-based delay
end

function WeatherRenderer.update(deltaTime: number)
	if not isStormActive then return end

	-- TODO: Update particle positions relative to camera
	-- TODO: Animate rain/hail/fog particles
	-- TODO: Check for lightning timing and trigger strikes
end

return WeatherRenderer
