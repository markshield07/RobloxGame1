--[[
	init.client.luau
	Main client entry point for 99 Storms.
	Handles client-side rendering, UI, weather effects, input, and interaction.
	Connects all client subsystems and handles all RemoteEvent communication.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Wait for remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Import client modules
local WeatherRenderer = require(script.Weather.WeatherRenderer)
local StormUI = require(script.UI.StormUI)
local CraftingUI = require(script.UI.CraftingUI)
local InventoryUI = require(script.UI.InventoryUI)
local CameraController = require(script.Camera.CameraController)
local InteractionDetector = require(script.Input.InteractionDetector)
local DialogueUI = require(script.UI.DialogueUI)
local ClassSelectionUI = require(script.UI.ClassSelectionUI)
local BadgeLobbyUI = require(script.UI.BadgeLobbyUI)

-- ================================
-- STATE
-- ================================

local gameState = {
	stormState = "calm",
	stormType = nil,
	stormNumber = 0,
	timeRemaining = 0,
	weatherData = nil,
	inventory = {},
	playerStats = nil,
	currentDay = 1,
	dayPhase = "daytime",
	dayTimeRemaining = 0,
}

-- ================================
-- STORM REMOTE HANDLERS
-- ================================

Remotes.StormStateChanged.OnClientEvent:Connect(function(data)
	gameState.stormState = data.state
	gameState.stormType = data.stormType
	gameState.stormNumber = data.stormNumber

	if data.stateInfo then
		gameState.timeRemaining = data.stateInfo.timeRemaining
	end

	-- Update storm UI
	StormUI.updateStormState(gameState)

	-- Trigger state-specific effects
	if data.state == "storm" then
		WeatherRenderer.setState("storm", data.stormType, data.stateInfo and data.stateInfo.intensity or 1.0)
		CameraController.setStormMode(true)
		CameraController.screenShake(0.5, 3)
	elseif data.state == "warning" then
		WeatherRenderer.setState("warning", data.stormType, 1.0)
		CameraController.setStormMode(false)
	elseif data.state == "calm" then
		WeatherRenderer.setState("calm")
		CameraController.setStormMode(false)
	elseif data.state == "aftermath" then
		WeatherRenderer.setState("aftermath")
		CameraController.setStormMode(false)
	end
end)

Remotes.WeatherUpdate.OnClientEvent:Connect(function(weatherData)
	gameState.weatherData = weatherData
	WeatherRenderer.updateWeather(weatherData)
end)

Remotes.StormWarning.OnClientEvent:Connect(function(data)
	StormUI.showStormWarning(data.stormType, data.stormNumber, data.timeUntilStorm)
end)

Remotes.LightningStrike.OnClientEvent:Connect(function(position)
	WeatherRenderer.renderLightningStrike(position)
	CameraController.screenShake(0.3, 5)
end)

-- ================================
-- DAY CYCLE HANDLER
-- ================================

Remotes.DayStateChanged.OnClientEvent:Connect(function(dayInfo)
	gameState.currentDay = dayInfo.currentDay or 1
	gameState.dayPhase = dayInfo.phase or "daytime"
	gameState.dayTimeRemaining = dayInfo.timeRemaining or 0

	-- Update the day tracker UI
	StormUI.updateDayState(dayInfo)
end)

-- ================================
-- NOTIFICATION / PROGRESSION HANDLERS
-- ================================

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
-- CLASS SELECTION HANDLER
-- ================================

Remotes.ShowClassSelection.OnClientEvent:Connect(function()
	ClassSelectionUI.open(function(classId)
		Remotes.ClassSelected:FireServer(classId)
	end)
end)

-- ================================
-- BADGE DISPLAY HANDLER
-- ================================

Remotes.ShowBadges.OnClientEvent:Connect(function(playerData)
	BadgeLobbyUI.open(playerData)
end)

-- ================================
-- INVENTORY HANDLERS
-- ================================

Remotes.InventoryUpdate.OnClientEvent:Connect(function(inventory)
	gameState.inventory = inventory or {}
	InventoryUI.updateInventory(gameState.inventory)
	CraftingUI.updateInventory(gameState.inventory)
end)

-- ================================
-- PLAYER STATS HANDLER
-- ================================

Remotes.PlayerStats.OnClientEvent:Connect(function(stats)
	gameState.playerStats = stats
	StormUI.updatePlayerStats(stats)
end)

-- ================================
-- CRAFTING STATION HANDLER
-- ================================

Remotes.CraftStationData.OnClientEvent:Connect(function(data)
	gameState.inventory = data.inventory or gameState.inventory
	CraftingUI.open(data.stationId, data.inventory, data.stormNumber or gameState.stormNumber)
end)

-- ================================
-- NPC DIALOGUE HANDLER
-- ================================

Remotes.NPCDialogue.OnClientEvent:Connect(function(data)
	if data.npcName and data.text then
		DialogueUI.open(data.npcId, data.npcName, data.text, data.trades)
	else
		local text = (data.npcId or "NPC") .. ": " .. (data.text or "...")
		StormUI.showNotification(text, true)
	end
end)

-- ================================
-- GATHER COMPLETE HANDLER
-- ================================

Remotes.GatherComplete.OnClientEvent:Connect(function(data)
	if data then
		StormUI.showNotification(data.text or "Gathering complete!", data.success ~= false)
	end
end)

-- ================================
-- CREATURE EVENTS
-- ================================

Remotes.CreatureDefeated.OnClientEvent:Connect(function(data)
	StormUI.showNotification(data.name .. " defeated!", true)
end)

-- ================================
-- INPUT HANDLING
-- ================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Block gameplay input while class selection or badges are open
	if ClassSelectionUI.isOpen() or BadgeLobbyUI.isOpen() then return end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		local key = input.KeyCode

		-- Tab: toggle inventory
		if key == Enum.KeyCode.Tab then
			if CraftingUI.isOpen() then
				CraftingUI.close()
			end
			InventoryUI.toggle(gameState.inventory)

		-- B: open badges
		elseif key == Enum.KeyCode.B then
			if BadgeLobbyUI.isOpen() then
				BadgeLobbyUI.close()
			else
				Remotes.OpenBadges:FireServer()
			end

		-- C: close any open UI
		elseif key == Enum.KeyCode.C then
			if DialogueUI.isOpen() then
				DialogueUI.close()
			elseif CraftingUI.isOpen() then
				CraftingUI.close()
			elseif InventoryUI.isOpen() then
				InventoryUI.close()
			elseif BadgeLobbyUI.isOpen() then
				BadgeLobbyUI.close()
			end

		-- E: interact (also handles loot containers)
		elseif key == Enum.KeyCode.E then
			local target = InteractionDetector.getCurrentTarget()
			if target then
				local interactType = target:GetAttribute("InteractType")
				if interactType == "LootContainer" then
					local containerId = target:GetAttribute("ContainerId")
					local isLooted = target:GetAttribute("IsLooted")
					if containerId and not isLooted then
						Remotes.SearchLoot:FireServer(containerId)
					elseif isLooted then
						StormUI.showNotification("Already searched. It will respawn soon.", false)
					end
				end
			end

		-- P: photo mode
		elseif key == Enum.KeyCode.P then
			CameraController.togglePhotoMode()

		-- Left Shift: sprint
		elseif key == Enum.KeyCode.LeftShift then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = 24
				end
			end

		-- G: signal flare
		elseif key == Enum.KeyCode.G then
			if gameState.inventory.signal_flare and gameState.inventory.signal_flare > 0 then
				Remotes.UseItem:FireServer("signal_flare")
			end

		-- V: whistle for taming
		elseif key == Enum.KeyCode.V then
			local target = InteractionDetector.getCurrentTarget()
			if target and target:GetAttribute("InteractType") == "Creature" then
				local creatureId = target:GetAttribute("CreatureId")
				if creatureId then
					Remotes.TameAttempt:FireServer(creatureId)
				end
			end
		end

	-- Left mouse click: attack nearby creature
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		local target = InteractionDetector.getCurrentTarget()
		if target and target:GetAttribute("InteractType") == "Creature" then
			local creatureId = target:GetAttribute("CreatureId")
			if creatureId then
				Remotes.AttackCreature:FireServer(creatureId)
			end
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.LeftShift then
			local character = player.Character
			if character then
				local humanoid = character:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = 16
				end
			end
		end
	end
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
		gameState.inventory = state.inventory or {}

		-- Day state
		if state.dayState then
			gameState.currentDay = state.dayState.currentDay or 1
			gameState.dayPhase = state.dayState.phase or "daytime"
			gameState.dayTimeRemaining = state.dayState.timeRemaining or 0
			StormUI.updateDayState(state.dayState)
		end

		StormUI.updateStormState(gameState)
		InventoryUI.updateInventory(gameState.inventory)
		CraftingUI.updateInventory(gameState.inventory)

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

	-- Initialize all subsystems
	WeatherRenderer.init()
	StormUI.init()
	CameraController.init()
	CraftingUI.init()
	InventoryUI.init()
	InteractionDetector.init()
	DialogueUI.init()
	ClassSelectionUI.init()
	BadgeLobbyUI.init()

	-- Request current game state from server
	requestGameState()

	print("[99 Storms Client] All systems ready!")
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
	-- Weather visuals
	WeatherRenderer.update(deltaTime)

	-- Camera effects (storm sway, shake)
	CameraController.update(deltaTime)

	-- Interaction detection (scans for nearby interactable objects)
	InteractionDetector.update(deltaTime)

	-- Update timer display
	if gameState.timeRemaining > 0 then
		gameState.timeRemaining = math.max(0, gameState.timeRemaining - deltaTime)
		StormUI.updateTimer(gameState.timeRemaining)
	end

	-- Update day timer
	if gameState.dayTimeRemaining > 0 then
		gameState.dayTimeRemaining = math.max(0, gameState.dayTimeRemaining - deltaTime)
	end
end)
