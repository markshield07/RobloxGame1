--[[
	init.server.luau
	Main server entry point for 99 Storms.
	Initializes all server-side systems and manages the game loop.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to be available
local Shared = ReplicatedStorage:WaitForChild("Shared")

-- Import server systems
local StormManager = require(script.Storm.StormManager)
local WeatherEffects = require(script.Storm.WeatherEffects)
local StructureManager = require(script.Building.StructureManager)
local ProgressionManager = require(script.Progression.ProgressionManager)

-- Create RemoteEvents for client-server communication
local function createRemotes()
	local remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = ReplicatedStorage

	local events = {
		-- Storm events
		"StormStateChanged",   -- Server -> Client: storm phase changes
		"WeatherUpdate",       -- Server -> Client: weather effect data
		"LightningStrike",     -- Server -> Client: lightning strike at position

		-- Building events
		"ClaimBuilding",       -- Client -> Server: player claims a house
		"FortifyWall",         -- Client -> Server: player fortifies a wall
		"RepairWall",          -- Client -> Server: player repairs a wall
		"RestoreBuilding",     -- Client -> Server: player restores shared building
		"BuildingUpdate",      -- Server -> Client: building state changes

		-- Crafting events
		"CraftItem",           -- Client -> Server: player crafts an item
		"CraftResult",         -- Server -> Client: crafting success/failure

		-- Player events
		"SelectClass",         -- Client -> Server: class selection
		"PlayerStats",         -- Server -> Client: hunger, morale, HP updates
		"MoraleChange",        -- Server -> Client: morale change notification

		-- Progression events
		"MilestoneReached",    -- Server -> Client: milestone/badge unlocked
		"ZoneUnlocked",        -- Server -> Client: new zone accessible
		"RescueAvailable",     -- Server -> Client: rescue mission available

		-- Creature events
		"CreatureSpawn",       -- Server -> Client: creature spawned
		"CreatureDefeated",    -- Server -> Client: creature killed
		"TameAttempt",         -- Client -> Server: player tries to tame
		"TameResult",          -- Server -> Client: taming success/failure

		-- UI events
		"StormWarning",        -- Server -> Client: storm warning siren
		"Notification",        -- Server -> Client: general notification text
	}

	for _, eventName in events do
		local remote = Instance.new("RemoteEvent")
		remote.Name = eventName
		remote.Parent = remoteFolder
	end

	-- RemoteFunctions (request-response)
	local functions = {
		"GetGameState",        -- Client -> Server: request full game state
		"GetBuildingState",    -- Client -> Server: request building data
		"GetInventory",        -- Client -> Server: request player inventory
		"GetRecipes",          -- Client -> Server: request available recipes
	}

	for _, funcName in functions do
		local remote = Instance.new("RemoteFunction")
		remote.Name = funcName
		remote.Parent = remoteFolder
	end

	return remoteFolder
end

-- ================================
-- INITIALIZE SYSTEMS
-- ================================

print("[99 Storms] Initializing server...")

local remotes = createRemotes()
local stormManager = StormManager.new()
local weatherEffects = WeatherEffects.new()
local structureManager = StructureManager.new()
local progressionManager = ProgressionManager.new()

-- ================================
-- STORM CALLBACKS
-- ================================

stormManager.onStateChanged = function(newState, stormType, stormNumber)
	print(string.format("[99 Storms] State: %s | Storm: %s | Number: %d", newState, tostring(stormType), stormNumber))

	-- Broadcast to all clients
	remotes.StormStateChanged:FireAllClients({
		state = newState,
		stormType = stormType,
		stormNumber = stormNumber,
		stateInfo = stormManager:getStateInfo(),
	})

	-- Apply weather effects during storms
	if newState == "storm" and stormType then
		weatherEffects:applyStormEffects(stormType, stormManager.stormIntensity)
		remotes.WeatherUpdate:FireAllClients(weatherEffects:getWeatherState())
	elseif newState == "calm" or newState == "aftermath" then
		weatherEffects:clearEffects()
		remotes.WeatherUpdate:FireAllClients(weatherEffects:getWeatherState())
	end

	-- Warning siren
	if newState == "warning" then
		remotes.StormWarning:FireAllClients({
			stormType = stormType,
			stormNumber = stormNumber,
			timeUntilStorm = GameConfig.STORM_WARNING_DURATION,
		})
	end

	-- Check zone unlocks
	if newState == "aftermath" then
		for _, zone in GameConfig.ZONES do
			if stormNumber == zone.unlockStorm and zone.unlockStorm > 0 then
				remotes.ZoneUnlocked:FireAllClients({
					zoneId = zone.id,
					zoneName = zone.name,
				})
			end
		end

		-- Check rescue availability
		for _, rescue in GameConfig.RESCUES do
			if stormNumber == rescue.unlockStorm then
				remotes.RescueAvailable:FireAllClients({
					rescueId = rescue.id,
					rescueName = rescue.name,
					zone = rescue.zone,
				})
			end
		end
	end

	-- Game complete
	if newState == "game_complete" then
		print("[99 Storms] GAME COMPLETE! All 99 storms survived!")
		for _, player in Players:GetPlayers() do
			progressionManager:onGameComplete(player, 0) -- TODO: track actual time
		end
	end
end

stormManager.onStormComplete = function(stormNumber)
	-- Update all players' progression
	for _, player in Players:GetPlayers() do
		progressionManager:onStormSurvived(player, stormNumber)
	end

	-- Apply storm damage to structures
	local intensity = stormManager.stormIntensity
	local damagePerWall = 10 * intensity
	local roofDamage = 5 * intensity

	for buildingId, _ in structureManager.buildings do
		structureManager:applyStormDamage(buildingId, damagePerWall, roofDamage)
	end

	-- Broadcast updated building states
	remotes.BuildingUpdate:FireAllClients(structureManager:getAllBuildingStates())
end

-- ================================
-- REMOTE EVENT HANDLERS
-- ================================

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

-- Building claims
remotes.ClaimBuilding.OnServerEvent:Connect(function(player, buildingId)
	local success, message = structureManager:claimBuilding(player.UserId, buildingId)
	remotes.Notification:FireClient(player, { text = message, success = success })
	if success then
		remotes.BuildingUpdate:FireAllClients(structureManager:getAllBuildingStates())
	end
end)

-- Wall fortification
remotes.FortifyWall.OnServerEvent:Connect(function(player, buildingId, wallIndex, fortTierId)
	local success, message = structureManager:fortifyWall(buildingId, wallIndex, fortTierId)
	remotes.Notification:FireClient(player, { text = message, success = success })
	if success then
		remotes.BuildingUpdate:FireAllClients(structureManager:getAllBuildingStates())
	end
end)

-- Wall repair
remotes.RepairWall.OnServerEvent:Connect(function(player, buildingId, wallIndex)
	local repairAmount = 20 -- base repair amount, modified by class
	local data = progressionManager:getData(player)
	if data and data.classId == "builder" then
		repairAmount = 60 -- Builder class 3x repair
	end

	structureManager:repairWall(buildingId, wallIndex, repairAmount)
	remotes.BuildingUpdate:FireAllClients(structureManager:getAllBuildingStates())
end)

-- Building restoration
remotes.RestoreBuilding.OnServerEvent:Connect(function(player, buildingId)
	local success, message = structureManager:restoreBuilding(buildingId)
	remotes.Notification:FireClient(player, { text = message, success = success })
	if success then
		remotes.BuildingUpdate:FireAllClients(structureManager:getAllBuildingStates())
	end
end)

-- Class selection
remotes.SelectClass.OnServerEvent:Connect(function(player, classId)
	local success, message = progressionManager:setClass(player, classId)
	remotes.Notification:FireClient(player, { text = message, success = success })
end)

-- RemoteFunction handlers
remotes.GetGameState.OnServerInvoke = function(player)
	return {
		stormState = stormManager:getStateInfo(),
		weather = weatherEffects:getWeatherState(),
		buildings = structureManager:getAllBuildingStates(),
		playerData = progressionManager:getData(player),
	}
end

remotes.GetBuildingState.OnServerInvoke = function(player, buildingId)
	return structureManager:getBuildingState(buildingId)
end

-- ================================
-- PLAYER CONNECTIONS
-- ================================

Players.PlayerAdded:Connect(function(player)
	print("[99 Storms] Player joined: " .. player.Name)
	progressionManager:loadPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	print("[99 Storms] Player left: " .. player.Name)
	progressionManager:onPlayerLeaving(player)
end)

-- ================================
-- GAME LOOP
-- ================================

-- Start the storm cycle when enough players join
local gameStarted = false

local function tryStartGame()
	if gameStarted then return end

	local playerCount = #Players:GetPlayers()
	if playerCount >= 1 then
		gameStarted = true
		print("[99 Storms] Game starting with " .. playerCount .. " players!")
		stormManager:start()
	end
end

Players.PlayerAdded:Connect(function()
	-- Start game 10 seconds after first player joins
	task.delay(10, tryStartGame)
end)

-- Main game loop
RunService.Heartbeat:Connect(function(deltaTime)
	-- Update storm cycle
	stormManager:update(deltaTime)

	-- Regenerate storm crystal barriers during calm
	if stormManager.state == "calm" then
		structureManager:regenerateBarriers(deltaTime)
	end
end)

print("[99 Storms] Server initialized. Waiting for players...")
