--[[
	init.client.luau
	Main client entry point for 99 Storms.
	Handles client-side rendering, UI, weather effects, and input.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

-- Wait for remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Import client modules
local WeatherRenderer = require(script.Weather.WeatherRenderer)
local StormUI = require(script.UI.StormUI)
local CameraController = require(script.Camera.CameraController)

-- ================================
-- STATE
-- ================================

local gameState = {
	stormState = "calm",
	stormType = nil,
	stormNumber = 0,
	timeRemaining = 0,
	weatherData = nil,
}

-- ================================
-- REMOTE EVENT HANDLERS
-- ================================

Remotes.StormStateChanged.OnClientEvent:Connect(function(data)
	gameState.stormState = data.state
	gameState.stormType = data.stormType
	gameState.stormNumber = data.stormNumber

	if data.stateInfo then
		gameState.timeRemaining = data.stateInfo.timeRemaining
	end

	-- Update UI
	StormUI.updateStormState(gameState)

	-- Trigger state-specific effects
	if data.state == "storm" then
		WeatherRenderer.startStorm(data.stormType, data.stateInfo.intensity)
		CameraController.setStormMode(true)
	elseif data.state == "calm" then
		WeatherRenderer.clearWeather()
		CameraController.setStormMode(false)
	elseif data.state == "aftermath" then
		WeatherRenderer.startAftermath()
	end
end)

Remotes.WeatherUpdate.OnClientEvent:Connect(function(weatherData)
	gameState.weatherData = weatherData
	WeatherRenderer.updateWeather(weatherData)
end)

Remotes.StormWarning.OnClientEvent:Connect(function(data)
	StormUI.showStormWarning(data.stormType, data.stormNumber, data.timeUntilStorm)
	-- Play warning siren sound
	-- TODO: Implement warning siren audio
end)

Remotes.LightningStrike.OnClientEvent:Connect(function(position)
	WeatherRenderer.renderLightningStrike(position)
	CameraController.screenShake(0.3, 5)
end)

Remotes.Notification.OnClientEvent:Connect(function(data)
	StormUI.showNotification(data.text, data.success)
end)

Remotes.ZoneUnlocked.OnClientEvent:Connect(function(data)
	StormUI.showZoneUnlocked(data.zoneName)
end)

Remotes.RescueAvailable.OnClientEvent:Connect(function(data)
	StormUI.showRescueAvailable(data.rescueName, data.zone)
end)

Remotes.MilestoneReached.OnClientEvent:Connect(function(data)
	StormUI.showMilestone(data.badge, data.name)
end)

Remotes.BuildingUpdate.OnClientEvent:Connect(function(buildingStates)
	StormUI.updateBuildingStates(buildingStates)
end)

-- ================================
-- GAME STATE REQUEST
-- ================================

local function requestGameState()
	local state = Remotes.GetGameState:InvokeServer()
	if state then
		gameState.stormState = state.stormState.state
		gameState.stormType = state.stormState.stormType
		gameState.stormNumber = state.stormState.stormNumber
		gameState.timeRemaining = state.stormState.timeRemaining
		gameState.weatherData = state.weather

		StormUI.updateStormState(gameState)

		if state.weather then
			WeatherRenderer.updateWeather(state.weather)
		end
	end
end

-- ================================
-- INITIALIZATION
-- ================================

local function initialize()
	print("[99 Storms Client] Initializing...")

	-- Initialize subsystems
	WeatherRenderer.init()
	StormUI.init()
	CameraController.init()

	-- Request current game state from server
	requestGameState()

	print("[99 Storms Client] Ready!")
end

-- Wait for character to load then initialize
if player.Character then
	initialize()
else
	player.CharacterAdded:Wait()
	initialize()
end

-- ================================
-- RENDER LOOP
-- ================================

RunService.RenderStepped:Connect(function(deltaTime)
	WeatherRenderer.update(deltaTime)
	CameraController.update(deltaTime)

	-- Update timer display
	if gameState.timeRemaining > 0 then
		gameState.timeRemaining = math.max(0, gameState.timeRemaining - deltaTime)
		StormUI.updateTimer(gameState.timeRemaining)
	end
end)
