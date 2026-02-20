--[[
	WeatherRenderer.luau
	Client-side weather rendering with full particle effects, dynamic lighting,
	camera shake, and sound effects for 99 Storms.
	Handles visual transitions between storm states.
]]

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local WeatherRenderer = {}

-- ================================
-- STORM VISUAL PRESETS
-- ================================
local STORM_VISUALS = {
	calm = {
		clockTime = 14,
		brightness = 2.5,
		ambient = Color3.fromRGB(50, 55, 65),
		outdoorAmbient = Color3.fromRGB(100, 110, 125),
		fogEnd = 1500,
		fogColor = Color3.fromRGB(180, 195, 210),
		atmosphereDensity = 0.2,
		atmosphereColor = Color3.fromRGB(200, 210, 225),
		bloomIntensity = 0.3,
		bloomThreshold = 0.95,
		colorTint = Color3.fromRGB(255, 250, 245),
		colorBrightness = 0.02,
		colorContrast = 0.05,
		colorSaturation = 0.1,
	},

	warning = {
		clockTime = 16,
		brightness = 1.8,
		ambient = Color3.fromRGB(60, 45, 35),
		outdoorAmbient = Color3.fromRGB(100, 80, 60),
		fogEnd = 600,
		fogColor = Color3.fromRGB(150, 120, 90),
		atmosphereDensity = 0.35,
		atmosphereColor = Color3.fromRGB(200, 170, 130),
		bloomIntensity = 0.5,
		bloomThreshold = 0.8,
		colorTint = Color3.fromRGB(255, 220, 180),
		colorBrightness = -0.02,
		colorContrast = 0.1,
		colorSaturation = -0.1,
	},

	thunderstorm = {
		clockTime = 20,
		brightness = 0.5,
		ambient = Color3.fromRGB(20, 20, 30),
		outdoorAmbient = Color3.fromRGB(40, 45, 60),
		fogEnd = 300,
		fogColor = Color3.fromRGB(60, 65, 80),
		atmosphereDensity = 0.6,
		atmosphereColor = Color3.fromRGB(80, 85, 100),
		bloomIntensity = 0.8,
		bloomThreshold = 0.6,
		colorTint = Color3.fromRGB(200, 210, 255),
		colorBrightness = -0.08,
		colorContrast = 0.15,
		colorSaturation = -0.3,
	},

	fog = {
		clockTime = 6,
		brightness = 0.8,
		ambient = Color3.fromRGB(60, 60, 60),
		outdoorAmbient = Color3.fromRGB(80, 80, 80),
		fogEnd = 80,
		fogColor = Color3.fromRGB(160, 165, 170),
		atmosphereDensity = 0.9,
		atmosphereColor = Color3.fromRGB(180, 180, 185),
		bloomIntensity = 1.2,
		bloomThreshold = 0.5,
		colorTint = Color3.fromRGB(220, 225, 230),
		colorBrightness = -0.05,
		colorContrast = -0.1,
		colorSaturation = -0.5,
	},

	hurricane = {
		clockTime = 18,
		brightness = 0.3,
		ambient = Color3.fromRGB(15, 20, 25),
		outdoorAmbient = Color3.fromRGB(30, 40, 50),
		fogEnd = 150,
		fogColor = Color3.fromRGB(40, 50, 60),
		atmosphereDensity = 0.7,
		atmosphereColor = Color3.fromRGB(50, 60, 80),
		bloomIntensity = 1.0,
		bloomThreshold = 0.5,
		colorTint = Color3.fromRGB(180, 200, 230),
		colorBrightness = -0.1,
		colorContrast = 0.2,
		colorSaturation = -0.2,
	},

	hailstorm = {
		clockTime = 15,
		brightness = 0.6,
		ambient = Color3.fromRGB(30, 35, 45),
		outdoorAmbient = Color3.fromRGB(70, 80, 100),
		fogEnd = 250,
		fogColor = Color3.fromRGB(120, 130, 150),
		atmosphereDensity = 0.5,
		atmosphereColor = Color3.fromRGB(150, 160, 180),
		bloomIntensity = 0.6,
		bloomThreshold = 0.7,
		colorTint = Color3.fromRGB(210, 220, 240),
		colorBrightness = -0.04,
		colorContrast = 0.12,
		colorSaturation = -0.25,
	},

	tornado = {
		clockTime = 17,
		brightness = 0.4,
		ambient = Color3.fromRGB(25, 30, 20),
		outdoorAmbient = Color3.fromRGB(50, 60, 40),
		fogEnd = 200,
		fogColor = Color3.fromRGB(80, 90, 70),
		atmosphereDensity = 0.65,
		atmosphereColor = Color3.fromRGB(90, 100, 80),
		bloomIntensity = 0.7,
		bloomThreshold = 0.6,
		colorTint = Color3.fromRGB(200, 220, 180),
		colorBrightness = -0.06,
		colorContrast = 0.18,
		colorSaturation = -0.15,
	},

	tsunami = {
		clockTime = 12,
		brightness = 0.5,
		ambient = Color3.fromRGB(20, 30, 40),
		outdoorAmbient = Color3.fromRGB(40, 60, 80),
		fogEnd = 200,
		fogColor = Color3.fromRGB(40, 70, 100),
		atmosphereDensity = 0.55,
		atmosphereColor = Color3.fromRGB(60, 90, 120),
		bloomIntensity = 0.9,
		bloomThreshold = 0.55,
		colorTint = Color3.fromRGB(180, 210, 240),
		colorBrightness = -0.06,
		colorContrast = 0.1,
		colorSaturation = -0.15,
	},

	snowstorm = {
		clockTime = 10,
		brightness = 0.7,
		ambient = Color3.fromRGB(50, 55, 65),
		outdoorAmbient = Color3.fromRGB(90, 95, 110),
		fogEnd = 150,
		fogColor = Color3.fromRGB(200, 210, 220),
		atmosphereDensity = 0.6,
		atmosphereColor = Color3.fromRGB(210, 220, 235),
		bloomIntensity = 0.8,
		bloomThreshold = 0.6,
		colorTint = Color3.fromRGB(220, 230, 255),
		colorBrightness = -0.02,
		colorContrast = -0.05,
		colorSaturation = -0.4,
	},

	blood_storm = {
		clockTime = 21,
		brightness = 0.3,
		ambient = Color3.fromRGB(40, 10, 10),
		outdoorAmbient = Color3.fromRGB(60, 20, 20),
		fogEnd = 200,
		fogColor = Color3.fromRGB(80, 20, 20),
		atmosphereDensity = 0.7,
		atmosphereColor = Color3.fromRGB(120, 30, 30),
		bloomIntensity = 1.0,
		bloomThreshold = 0.5,
		colorTint = Color3.fromRGB(255, 150, 140),
		colorBrightness = -0.08,
		colorContrast = 0.2,
		colorSaturation = 0.1,
	},

	tempest_wrath = {
		clockTime = 22,
		brightness = 0.15,
		ambient = Color3.fromRGB(10, 10, 20),
		outdoorAmbient = Color3.fromRGB(20, 20, 40),
		fogEnd = 120,
		fogColor = Color3.fromRGB(30, 25, 50),
		atmosphereDensity = 0.85,
		atmosphereColor = Color3.fromRGB(40, 30, 70),
		bloomIntensity = 1.5,
		bloomThreshold = 0.4,
		colorTint = Color3.fromRGB(180, 160, 255),
		colorBrightness = -0.12,
		colorContrast = 0.25,
		colorSaturation = -0.1,
	},

	aftermath = {
		clockTime = 6.5,
		brightness = 1.5,
		ambient = Color3.fromRGB(60, 55, 50),
		outdoorAmbient = Color3.fromRGB(100, 95, 85),
		fogEnd = 800,
		fogColor = Color3.fromRGB(160, 155, 150),
		atmosphereDensity = 0.3,
		atmosphereColor = Color3.fromRGB(190, 185, 175),
		bloomIntensity = 0.4,
		bloomThreshold = 0.85,
		colorTint = Color3.fromRGB(255, 240, 220),
		colorBrightness = 0.0,
		colorContrast = 0.05,
		colorSaturation = 0.0,
	},
}

-- ================================
-- INTERNAL STATE
-- ================================
local currentState = "calm"
local currentStormType = nil
local currentIntensity = 1.0
local particleEmitters = {}
local activeSounds = {}
local nextLightningTime = 0
local windAngle = 0
local isInitialized = false

-- Looped sound definitions (volume starts at 0, tweened per state)
local LOOPED_SOUNDS = {
	"ambient_calm", "ambient_wind",
	"rain_light", "rain_heavy",
	"wind_storm", "thunder_rumble",
}

-- Sound volume targets keyed by visual state
local SOUND_VOLUMES = {
	calm = {
		ambient_calm = 0.3, ambient_wind = 0.05,
		rain_light = 0.0, rain_heavy = 0.0,
		wind_storm = 0.0, thunder_rumble = 0.0,
	},
	warning = {
		ambient_calm = 0.15, ambient_wind = 0.2,
		rain_light = 0.15, rain_heavy = 0.0,
		wind_storm = 0.1, thunder_rumble = 0.05,
	},
	thunderstorm = {
		ambient_calm = 0.0, ambient_wind = 0.1,
		rain_light = 0.0, rain_heavy = 0.6,
		wind_storm = 0.3, thunder_rumble = 0.4,
	},
	fog = {
		ambient_calm = 0.1, ambient_wind = 0.3,
		rain_light = 0.05, rain_heavy = 0.0,
		wind_storm = 0.15, thunder_rumble = 0.0,
	},
	hurricane = {
		ambient_calm = 0.0, ambient_wind = 0.0,
		rain_light = 0.0, rain_heavy = 0.8,
		wind_storm = 0.9, thunder_rumble = 0.3,
	},
	hailstorm = {
		ambient_calm = 0.0, ambient_wind = 0.15,
		rain_light = 0.0, rain_heavy = 0.4,
		wind_storm = 0.3, thunder_rumble = 0.2,
	},
	tornado = {
		ambient_calm = 0.0, ambient_wind = 0.0,
		rain_light = 0.0, rain_heavy = 0.5,
		wind_storm = 1.0, thunder_rumble = 0.3,
	},
	tsunami = {
		ambient_calm = 0.0, ambient_wind = 0.1,
		rain_light = 0.1, rain_heavy = 0.5,
		wind_storm = 0.5, thunder_rumble = 0.2,
	},
	snowstorm = {
		ambient_calm = 0.0, ambient_wind = 0.3,
		rain_light = 0.0, rain_heavy = 0.0,
		wind_storm = 0.5, thunder_rumble = 0.0,
	},
	blood_storm = {
		ambient_calm = 0.0, ambient_wind = 0.2,
		rain_light = 0.0, rain_heavy = 0.3,
		wind_storm = 0.4, thunder_rumble = 0.5,
	},
	tempest_wrath = {
		ambient_calm = 0.0, ambient_wind = 0.0,
		rain_light = 0.0, rain_heavy = 1.0,
		wind_storm = 1.0, thunder_rumble = 0.7,
	},
	aftermath = {
		ambient_calm = 0.2, ambient_wind = 0.1,
		rain_light = 0.08, rain_heavy = 0.0,
		wind_storm = 0.05, thunder_rumble = 0.0,
	},
}

-- ================================
-- INITIALIZATION
-- ================================

function WeatherRenderer.init()
	if isInitialized then return end
	isInitialized = true

	-- Create a sound folder
	local weatherSounds = Instance.new("Folder")
	weatherSounds.Name = "WeatherSounds"
	weatherSounds.Parent = SoundService

	-- Create looped sounds (using placeholder asset IDs; replace with real assets)
	local SOUND_IDS = {
		ambient_calm  = "rbxassetid://9112854440",
		ambient_wind  = "rbxassetid://9112854440",
		rain_light    = "rbxassetid://6887746297",
		rain_heavy    = "rbxassetid://6887746297",
		wind_storm    = "rbxassetid://5765665979",
		thunder_rumble = "rbxassetid://5765665979",
	}

	for _, name in LOOPED_SOUNDS do
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = SOUND_IDS[name] or ""
		sound.Volume = 0
		sound.Looped = true
		sound.Playing = true
		sound.Parent = weatherSounds
		activeSounds[name] = sound
	end

	-- Create weather particle part (follows camera)
	WeatherRenderer._createParticles()
end

-- ================================
-- PARTICLE EFFECTS
-- ================================

function WeatherRenderer._createParticles()
	local particlePart = Instance.new("Part")
	particlePart.Name = "WeatherParticles"
	particlePart.Size = Vector3.new(1, 1, 1)
	particlePart.Transparency = 1
	particlePart.Anchored = true
	particlePart.CanCollide = false
	particlePart.CastShadow = false
	particlePart.Parent = workspace

	-- Rain
	local rain = Instance.new("ParticleEmitter")
	rain.Name = "Rain"
	rain.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	rain.Color = ColorSequence.new(Color3.fromRGB(150, 170, 200))
	rain.Size = NumberSequence.new(0.05, 0.02)
	rain.Lifetime = NumberRange.new(0.5, 1.0)
	rain.Rate = 0
	rain.Speed = NumberRange.new(60, 80)
	rain.SpreadAngle = Vector2.new(10, 10)
	rain.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0.8),
	})
	rain.Acceleration = Vector3.new(0, -60, 0)
	rain.EmissionDirection = Enum.NormalId.Top
	rain.Parent = particlePart
	particleEmitters.rain = rain

	-- Hail (white, larger)
	local hail = Instance.new("ParticleEmitter")
	hail.Name = "Hail"
	hail.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	hail.Color = ColorSequence.new(Color3.fromRGB(230, 240, 255))
	hail.Size = NumberSequence.new(0.15, 0.08)
	hail.Lifetime = NumberRange.new(0.3, 0.6)
	hail.Rate = 0
	hail.Speed = NumberRange.new(80, 120)
	hail.SpreadAngle = Vector2.new(15, 15)
	hail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 0.5),
	})
	hail.Acceleration = Vector3.new(0, -80, 0)
	hail.EmissionDirection = Enum.NormalId.Top
	hail.Parent = particlePart
	particleEmitters.hail = hail

	-- Fog wisps
	local fog = Instance.new("ParticleEmitter")
	fog.Name = "Fog"
	fog.Texture = "rbxasset://textures/particles/smoke_main.dds"
	fog.Color = ColorSequence.new(Color3.fromRGB(180, 185, 190))
	fog.Size = NumberSequence.new(15, 25)
	fog.Lifetime = NumberRange.new(5, 10)
	fog.Rate = 0
	fog.Speed = NumberRange.new(2, 5)
	fog.SpreadAngle = Vector2.new(180, 180)
	fog.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0.9),
	})
	fog.RotSpeed = NumberRange.new(-20, 20)
	fog.Rotation = NumberRange.new(0, 360)
	fog.EmissionDirection = Enum.NormalId.Top
	fog.Parent = particlePart
	particleEmitters.fog = fog

	-- Wind debris
	local debris = Instance.new("ParticleEmitter")
	debris.Name = "Debris"
	debris.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	debris.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 100, 60)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 90, 50)),
	})
	debris.Size = NumberSequence.new(0.3, 0.1)
	debris.Lifetime = NumberRange.new(1, 3)
	debris.Rate = 0
	debris.Speed = NumberRange.new(20, 50)
	debris.SpreadAngle = Vector2.new(45, 30)
	debris.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 0.7),
	})
	debris.RotSpeed = NumberRange.new(-180, 180)
	debris.Rotation = NumberRange.new(0, 360)
	debris.Acceleration = Vector3.new(0, -10, 0)
	debris.EmissionDirection = Enum.NormalId.Left
	debris.Parent = particlePart
	particleEmitters.debris = debris

	-- Blood mist
	local bloodMist = Instance.new("ParticleEmitter")
	bloodMist.Name = "BloodMist"
	bloodMist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	bloodMist.Color = ColorSequence.new(Color3.fromRGB(180, 30, 30))
	bloodMist.Size = NumberSequence.new(8, 15)
	bloodMist.Lifetime = NumberRange.new(3, 6)
	bloodMist.Rate = 0
	bloodMist.Speed = NumberRange.new(3, 8)
	bloodMist.SpreadAngle = Vector2.new(180, 180)
	bloodMist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0.9),
	})
	bloodMist.RotSpeed = NumberRange.new(-30, 30)
	bloodMist.Rotation = NumberRange.new(0, 360)
	bloodMist.EmissionDirection = Enum.NormalId.Top
	bloodMist.Parent = particlePart
	particleEmitters.bloodMist = bloodMist

	-- Storm sparks (tempest_wrath)
	local stormSparks = Instance.new("ParticleEmitter")
	stormSparks.Name = "StormSparks"
	stormSparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	stormSparks.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 150, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 40, 200)),
	})
	stormSparks.Size = NumberSequence.new(0.1, 0.3)
	stormSparks.Lifetime = NumberRange.new(0.5, 1.5)
	stormSparks.Rate = 0
	stormSparks.Speed = NumberRange.new(10, 30)
	stormSparks.SpreadAngle = Vector2.new(180, 180)
	stormSparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.0),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	stormSparks.LightEmission = 1
	stormSparks.EmissionDirection = Enum.NormalId.Top
	stormSparks.Parent = particlePart
	particleEmitters.stormSparks = stormSparks

	-- Snow particles
	local snow = Instance.new("ParticleEmitter")
	snow.Name = "Snow"
	snow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	snow.Color = ColorSequence.new(Color3.fromRGB(240, 245, 255))
	snow.Size = NumberSequence.new(0.1, 0.05)
	snow.Lifetime = NumberRange.new(2, 4)
	snow.Rate = 0
	snow.Speed = NumberRange.new(10, 25)
	snow.SpreadAngle = Vector2.new(30, 30)
	snow.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 0.7),
	})
	snow.Acceleration = Vector3.new(0, -8, 0)
	snow.RotSpeed = NumberRange.new(-60, 60)
	snow.Rotation = NumberRange.new(0, 360)
	snow.EmissionDirection = Enum.NormalId.Top
	snow.Parent = particlePart
	particleEmitters.snow = snow

	particleEmitters._part = particlePart
end

function WeatherRenderer._setParticleRates(stormType, intensity)
	local rates = {
		rain = 0, hail = 0, fog = 0, debris = 0, bloodMist = 0, stormSparks = 0, snow = 0,
	}

	if stormType == "thunderstorm" then
		rates.rain = 200 * intensity
	elseif stormType == "fog" then
		rates.fog = 5 * intensity
	elseif stormType == "hurricane" then
		rates.rain = 300 * intensity
		rates.debris = 30 * intensity
	elseif stormType == "hailstorm" then
		rates.hail = 150 * intensity
		rates.rain = 80 * intensity
	elseif stormType == "tornado" then
		rates.rain = 100 * intensity
		rates.debris = 60 * intensity
	elseif stormType == "tsunami" then
		rates.rain = 150 * intensity
		rates.fog = 3 * intensity
	elseif stormType == "snowstorm" then
		rates.snow = 250 * intensity
		rates.fog = 2 * intensity
	elseif stormType == "blood_storm" then
		rates.rain = 80 * intensity
		rates.bloodMist = 8 * intensity
	elseif stormType == "tempest_wrath" then
		rates.rain = 400 * intensity
		rates.debris = 40 * intensity
		rates.stormSparks = 30 * intensity
	end

	-- Warning state: softer particles
	if currentState == "warning" then
		for k, v in rates do
			rates[k] = v * 0.3
		end
		rates.rain = math.max(rates.rain, 30)
	end

	-- Aftermath: light drizzle
	if currentState == "aftermath" then
		rates = { rain = 20, hail = 0, fog = 1, debris = 0, bloodMist = 0, stormSparks = 0, snow = 0 }
	end

	for name, rate in rates do
		if particleEmitters[name] then
			particleEmitters[name].Rate = rate
		end
	end
end

-- ================================
-- LIGHTNING
-- ================================

function WeatherRenderer._triggerLightning()
	local savedBrightness = Lighting.Brightness

	task.spawn(function()
		-- Flash 1
		Lighting.Brightness = 5
		task.wait(0.05)
		Lighting.Brightness = savedBrightness
		task.wait(0.1)
		-- Flash 2
		Lighting.Brightness = 3
		task.wait(0.03)
		Lighting.Brightness = savedBrightness

		-- Delayed thunder
		task.wait(0.5 + math.random() * 2)
		WeatherRenderer._playOneShot(0.5 + math.random() * 0.5)
	end)
end

function WeatherRenderer.renderLightningStrike(position: Vector3)
	WeatherRenderer._triggerLightning()

	-- Create a brief bolt visual at the position
	task.spawn(function()
		local bolt = Instance.new("Part")
		bolt.Name = "LightningBolt"
		bolt.Size = Vector3.new(1, 100, 1)
		bolt.Position = position + Vector3.new(0, 50, 0)
		bolt.Color = Color3.fromRGB(200, 220, 255)
		bolt.Material = Enum.Material.Neon
		bolt.Anchored = true
		bolt.CanCollide = false
		bolt.CastShadow = false
		bolt.Transparency = 0.2
		bolt.Parent = workspace

		local light = Instance.new("PointLight")
		light.Brightness = 5
		light.Range = 60
		light.Color = Color3.fromRGB(200, 220, 255)
		light.Parent = bolt

		-- Quick fade out
		task.wait(0.1)
		local tween = TweenService:Create(bolt, TweenInfo.new(0.3), { Transparency = 1 })
		tween:Play()
		tween.Completed:Wait()
		bolt:Destroy()
	end)
end

-- ================================
-- SOUND HELPERS
-- ================================

function WeatherRenderer._playOneShot(volume)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://5765665979"
	sound.Volume = volume or 0.7
	sound.Looped = false
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function WeatherRenderer._transitionSounds(targetKey)
	local targets = SOUND_VOLUMES[targetKey] or SOUND_VOLUMES.calm
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	for name, targetVolume in targets do
		local sound = activeSounds[name]
		if sound then
			TweenService:Create(sound, tweenInfo, { Volume = targetVolume }):Play()
		end
	end
end

-- ================================
-- LIGHTING TRANSITIONS
-- ================================

function WeatherRenderer._transitionLighting(preset, duration)
	duration = duration or 5
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

	-- Core lighting
	TweenService:Create(Lighting, tweenInfo, {
		ClockTime = preset.clockTime,
		Brightness = preset.brightness,
		Ambient = preset.ambient,
		OutdoorAmbient = preset.outdoorAmbient,
		FogEnd = preset.fogEnd,
		FogColor = preset.fogColor,
	}):Play()

	-- Atmosphere
	local atmo = Lighting:FindFirstChild("DefaultAtmosphere")
	if atmo then
		TweenService:Create(atmo, tweenInfo, {
			Density = preset.atmosphereDensity,
			Color = preset.atmosphereColor,
		}):Play()
	end

	-- Bloom
	local bloom = Lighting:FindFirstChild("DefaultBloom")
	if bloom then
		TweenService:Create(bloom, tweenInfo, {
			Intensity = preset.bloomIntensity,
			Threshold = preset.bloomThreshold,
		}):Play()
	end

	-- Color correction
	local cc = Lighting:FindFirstChild("DefaultCC")
	if cc then
		TweenService:Create(cc, tweenInfo, {
			TintColor = preset.colorTint,
			Brightness = preset.colorBrightness,
			Contrast = preset.colorContrast,
			Saturation = preset.colorSaturation,
		}):Play()
	end
end

-- ================================
-- PUBLIC API
-- ================================

function WeatherRenderer.setState(state: string, stormType: string?, intensity: number?)
	currentState = state
	currentStormType = stormType
	currentIntensity = intensity or 1.0

	if state == "calm" then
		WeatherRenderer._transitionLighting(STORM_VISUALS.calm, 8)
		WeatherRenderer._setParticleRates(nil, 0)
		WeatherRenderer._transitionSounds("calm")

	elseif state == "warning" then
		WeatherRenderer._transitionLighting(STORM_VISUALS.warning, 5)
		WeatherRenderer._setParticleRates(stormType, currentIntensity)
		WeatherRenderer._transitionSounds("warning")
		-- Play warning siren
		WeatherRenderer._playOneShot(0.4)

	elseif state == "storm" then
		local visualKey = stormType or "thunderstorm"
		local preset = STORM_VISUALS[visualKey] or STORM_VISUALS.thunderstorm
		local transitionTime = 3

		if stormType == "tempest_wrath" then
			transitionTime = 2
			task.spawn(function()
				task.wait(1)
				WeatherRenderer._triggerLightning()
				task.wait(0.5)
				WeatherRenderer._triggerLightning()
			end)
		end

		WeatherRenderer._transitionLighting(preset, transitionTime)
		WeatherRenderer._setParticleRates(stormType, currentIntensity)
		WeatherRenderer._transitionSounds(visualKey)

		-- Schedule lightning
		if stormType == "thunderstorm" or stormType == "hurricane" or stormType == "tempest_wrath" then
			nextLightningTime = tick() + math.random(3, 8)
		end

	elseif state == "aftermath" then
		WeatherRenderer._transitionLighting(STORM_VISUALS.aftermath, 6)
		WeatherRenderer._setParticleRates(nil, 0.2)
		WeatherRenderer._transitionSounds("aftermath")
	end
end

-- Backwards-compatible API
function WeatherRenderer.startStorm(stormType: string, intensity: number)
	WeatherRenderer.setState("storm", stormType, intensity)
end

function WeatherRenderer.clearWeather()
	WeatherRenderer.setState("calm")
end

function WeatherRenderer.startAftermath()
	WeatherRenderer.setState("aftermath")
end

function WeatherRenderer.updateWeather(weatherData)
	-- Update intensity dynamically
	if weatherData and weatherData.effects then
		currentIntensity = weatherData.effects.intensity or currentIntensity
	end
end

-- ================================
-- FLOOD EFFECT
-- ================================

function WeatherRenderer.setFloodLevel(level: number)
	local stormhaven = workspace:FindFirstChild("Stormhaven")
	if not stormhaven then return end

	local terrain = stormhaven:FindFirstChild("Terrain")
	if not terrain then return end

	local ocean = terrain:FindFirstChild("Ocean")
	if ocean then
		local targetY = -1 + level
		local tweenInfo = TweenInfo.new(5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
		TweenService:Create(ocean, tweenInfo, {
			Position = Vector3.new(ocean.Position.X, targetY, ocean.Position.Z),
		}):Play()
	end
end

-- ================================
-- PER-FRAME UPDATE
-- ================================

function WeatherRenderer.update(deltaTime: number)
	-- Move particle emitter above camera
	local camera = workspace.CurrentCamera
	if camera and particleEmitters._part then
		particleEmitters._part.Position = camera.CFrame.Position + Vector3.new(0, 30, 0)
	end

	-- Slowly rotate wind direction
	windAngle += deltaTime * 0.1
	if particleEmitters.debris then
		local windDir = CFrame.Angles(0, windAngle, 0) * Vector3.new(1, 0, 0)
		particleEmitters.debris.Acceleration = windDir * 15 + Vector3.new(0, -10, 0)
	end

	-- Lightning timing during storms
	if currentState == "storm" and (currentStormType == "thunderstorm" or currentStormType == "hurricane" or currentStormType == "tempest_wrath") then
		if tick() >= nextLightningTime then
			WeatherRenderer._triggerLightning()

			local baseInterval = 8
			if currentStormType == "tempest_wrath" then
				baseInterval = 3
			elseif currentStormType == "hurricane" then
				baseInterval = 5
			end
			nextLightningTime = tick() + baseInterval + (math.random() - 0.5) * baseInterval
		end
	end

	-- Fog pulse
	if currentState == "storm" and currentStormType == "fog" then
		local pulse = math.sin(tick() * 0.3) * 20
		Lighting.FogEnd = 80 + pulse
	end
end

-- ================================
-- CLEANUP
-- ================================

function WeatherRenderer.cleanup()
	WeatherRenderer._transitionLighting(STORM_VISUALS.calm, 2)

	for name, emitter in particleEmitters do
		if typeof(emitter) == "Instance" and emitter:IsA("ParticleEmitter") then
			emitter.Rate = 0
		end
	end

	for _, sound in activeSounds do
		sound:Stop()
	end
end

return WeatherRenderer
