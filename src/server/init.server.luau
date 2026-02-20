--[[
	init.server.luau
	Main server entry point for 99 Storms.
	Initializes ALL server-side systems, wires them together,
	generates the map, and runs the game loop.
	Uses DayCycleManager for day-based progression (1 day = 3 min).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

-- Import ALL server systems
local DayCycleManager = require(script.Storm.DayCycleManager)
local StormManager = require(script.Storm.StormManager)
local WeatherEffects = require(script.Storm.WeatherEffects)
local StructureManager = require(script.Building.StructureManager)
local ResourceGathering = require(script.Building.ResourceGathering)
local InteractionSystem = require(script.Building.InteractionSystem)
local MapGenerator = require(script.Building.MapGenerator)
local LootSystem = require(script.Building.LootSystem)
local CreatureSpawner = require(script.Creatures.CreatureSpawner)
local CreatureModelFactory = require(script.Creatures.CreatureModelFactory)
local CombatSystem = require(script.Creatures.CombatSystem)
local TamingSystem = require(script.Creatures.TamingSystem)
local CraftingManager = require(script.Crafting.CraftingManager)
local NPCManager = require(script.NPCs.NPCManager)
local ProgressionManager = require(script.Progression.ProgressionManager)
local InventoryManager = require(script.Progression.InventoryManager)
local PlayerCharacter = require(script.Progression.PlayerCharacter)
local SessionManager = require(script.Multiplayer.SessionManager)

-- ================================
-- CREATE REMOTES
-- ================================

local function createRemotes()
	local remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = ReplicatedStorage

	local events = {
		-- Storm / Day Cycle
		"StormStateChanged", "WeatherUpdate", "LightningStrike", "StormWarning",
		"DayStateChanged",
		-- Building
		"ClaimBuilding", "FortifyWall", "RepairWall", "RestoreBuilding", "BuildingUpdate",
		-- Crafting
		"CraftItem", "OpenCraftStation", "CraftStationData",
		-- Player
		"SelectClass", "PlayerStats", "MoraleChange", "UseItem",
		-- Progression
		"MilestoneReached", "ZoneUnlocked", "RescueAvailable",
		-- Creatures
		"CreatureSpawn", "CreatureDefeated", "CreatureUpdate",
		"AttackCreature", "TameAttempt", "TameResult",
		-- Resources
		"GatherResource", "GatherComplete",
		-- NPCs
		"TalkToNPC", "NPCDialogue",
		-- Loot
		"SearchLoot", "LootResult",
		-- UI controls
		"OpenBadges", "OpenBaseStatus", "OpenClassSelect",
		-- Misc
		"Notification", "InventoryUpdate", "UseCampfire",
		-- Class selection
		"ClassSelected", "ShowClassSelection", "ShowBadges",
	}

	for _, name in events do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remoteFolder
	end

	local functions = {
		"GetGameState", "GetBuildingState", "GetInventory", "GetRecipes",
		"GetPlayerProfile",
	}

	for _, name in functions do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = remoteFolder
	end

	return remoteFolder
end

-- ================================
-- INITIALIZE ALL SYSTEMS
-- ================================

print("[99 Storms] Initializing server...")

local remotes = createRemotes()

-- Core systems
local dayCycleManager = DayCycleManager.new()
local stormManager = StormManager.new() -- kept as fallback reference
local weatherEffects = WeatherEffects.new()
local structureManager = StructureManager.new()
local resourceGathering = ResourceGathering.new()
local lootSystem = LootSystem.new()
local creatureSpawner = CreatureSpawner.new()
local combatSystem = CombatSystem.new()
local tamingSystem = TamingSystem.new()
local craftingManager = CraftingManager.new()
local npcManager = NPCManager.new()
local progressionManager = ProgressionManager.new()
local inventoryManager = InventoryManager.new()
local playerCharacter = PlayerCharacter.new()
local sessionManager = SessionManager.new()
local interactionSystem = InteractionSystem.new()

-- Track which players have selected a class this session
local playerClassSelected = {} -- userId -> true

-- Wire up cross-system references
combatSystem:init(creatureSpawner, playerCharacter, inventoryManager)
interactionSystem:init({
	inventoryManager = inventoryManager,
	playerCharacter = playerCharacter,
	craftingManager = craftingManager,
	structureManager = structureManager,
	resourceGathering = resourceGathering,
	npcManager = npcManager,
	tamingSystem = tamingSystem,
	combatSystem = combatSystem,
	stormManager = stormManager,
})

-- Generate the greybox map
print("[99 Storms] Generating Stormhaven...")
local stormhavenMap = MapGenerator.generate(resourceGathering)

-- Register loot containers from map
local lootFolder = stormhavenMap:FindFirstChild("LootContainers")
if lootFolder then
	for _, part in lootFolder:GetChildren() do
		if part:IsA("BasePart") then
			local rarity = part:GetAttribute("Rarity") or "common"
			lootSystem:registerContainer(part, rarity)
		end
	end
	print("[99 Storms] Registered " .. #lootFolder:GetChildren() .. " loot containers")
end

-- Track creature models
local creatureModels = {} -- creatureId -> Model

-- ================================
-- DAY CYCLE CALLBACKS
-- ================================

dayCycleManager.onDayChanged = function(dayNumber)
	print(string.format("[99 Storms] === DAY %d ===", dayNumber))

	-- Broadcast day change to all clients
	remotes.DayStateChanged:FireAllClients(dayCycleManager:getStateInfo())

	-- Track day survived for all players
	for _, player in Players:GetPlayers() do
		progressionManager:onDaySurvived(player, dayNumber)
	end

	-- Restock NPC trades each new day
	npcManager:restockTrades()
end

dayCycleManager.onPhaseChanged = function(phase, dayNumber, intensity)
	print(string.format("[99 Storms] Phase: %s | Day: %d | Intensity: %.2f", phase, dayNumber, intensity))

	-- Keep stormManager in sync for any systems that reference it
	stormManager.currentStorm = dayNumber
	stormManager.stormIntensity = intensity

	-- Broadcast day state to clients
	remotes.DayStateChanged:FireAllClients(dayCycleManager:getStateInfo())

	if phase == "warning" then
		local stormType = dayCycleManager:selectStormType()
		-- Store for use during storm phase
		dayCycleManager._pendingStormType = stormType

		remotes.StormWarning:FireAllClients({
			stormType = stormType,
			stormNumber = dayNumber,
			timeUntilStorm = GameConfig.WARNING_DURATION,
		})

		-- Broadcast as storm state for existing UI
		remotes.StormStateChanged:FireAllClients({
			state = "warning",
			stormType = stormType,
			stormNumber = dayNumber,
			stateInfo = {
				state = "warning",
				stormNumber = dayNumber,
				stormType = stormType,
				intensity = intensity,
				timeRemaining = GameConfig.WARNING_DURATION,
				totalStorms = GameConfig.TOTAL_STORMS,
			},
		})

	elseif phase == "storm" then
		local stormType = dayCycleManager._pendingStormType or dayCycleManager:selectStormType()

		-- Apply weather effects
		weatherEffects:applyStormEffects(stormType, intensity)
		remotes.WeatherUpdate:FireAllClients(weatherEffects:getWeatherState())

		-- Spawn creatures
		local spawnCenter = Vector3.new(0, 0, 50)
		creatureSpawner:spawnStormCreatures(stormType, intensity, spawnCenter, 120)

		-- Create models
		for id, creature in creatureSpawner.activeCreatures do
			if not creatureModels[id] then
				local model = CreatureModelFactory.create(creature.configId, creature.position, id)
				model:SetAttribute("ConfigId", creature.configId)
				creatureModels[id] = model
			end
		end

		-- Broadcast state
		remotes.StormStateChanged:FireAllClients({
			state = "storm",
			stormType = stormType,
			stormNumber = dayNumber,
			stateInfo = {
				state = "storm",
				stormNumber = dayNumber,
				stormType = stormType,
				intensity = intensity,
				timeRemaining = dayCycleManager:getStormDuration(),
				totalStorms = GameConfig.TOTAL_STORMS,
			},
		})

	elseif phase == "aftermath" then
		weatherEffects:clearEffects()
		remotes.WeatherUpdate:FireAllClients(weatherEffects:getWeatherState())

		-- Despawn creatures
		creatureSpawner:despawnAll()
		for id, model in creatureModels do
			CreatureModelFactory.destroy(model)
		end
		creatureModels = {}

		-- Storm damage to structures (scales with day/intensity)
		for buildingId, _ in structureManager.buildings do
			structureManager:applyStormDamage(buildingId, 10 * intensity, 5 * intensity)
		end
		remotes.BuildingUpdate:FireAllClients(structureManager:getAllBuildingStates())

		-- Record storm survived
		for _, player in Players:GetPlayers() do
			progressionManager:onStormSurvived(player, dayNumber)
			sessionManager:recordStormSurvived(player)
		end

		-- Zone/rescue unlocks
		for _, zone in GameConfig.ZONES do
			if dayNumber == zone.unlockStorm and zone.unlockStorm > 0 then
				remotes.ZoneUnlocked:FireAllClients({ zoneId = zone.id, zoneName = zone.name })
			end
		end

		local newRescues = npcManager:checkRescueAvailability(dayNumber)
		for _, rescueId in newRescues do
			for _, rescue in GameConfig.RESCUES do
				if rescue.id == rescueId then
					remotes.RescueAvailable:FireAllClients({ rescueId = rescue.id, rescueName = rescue.name, zone = rescue.zone })
				end
			end
		end

		-- Broadcast state
		remotes.StormStateChanged:FireAllClients({
			state = "aftermath",
			stormType = dayCycleManager._pendingStormType,
			stormNumber = dayNumber,
			stateInfo = {
				state = "aftermath",
				stormNumber = dayNumber,
				intensity = intensity,
				timeRemaining = GameConfig.AFTERMATH_DURATION_DAY,
				totalStorms = GameConfig.TOTAL_STORMS,
			},
		})

	elseif phase == "daytime" then
		weatherEffects:clearEffects()
		remotes.WeatherUpdate:FireAllClients(weatherEffects:getWeatherState())

		-- Despawn any leftover creatures
		creatureSpawner:despawnAll()
		for id, model in creatureModels do
			CreatureModelFactory.destroy(model)
		end
		creatureModels = {}

		remotes.StormStateChanged:FireAllClients({
			state = "calm",
			stormType = nil,
			stormNumber = dayNumber,
			stateInfo = {
				state = "calm",
				stormNumber = dayNumber,
				intensity = intensity,
				timeRemaining = GameConfig.DAYTIME_DURATION,
				totalStorms = GameConfig.TOTAL_STORMS,
			},
		})

	elseif phase == "game_complete" then
		print("[99 Storms] GAME COMPLETE! All 99 days survived!")
		for _, player in Players:GetPlayers() do
			progressionManager:onGameComplete(player, sessionManager:getSessionDuration())
		end
		remotes.Notification:FireAllClients({ text = "CURSE BROKEN! You survived all 99 days!", success = true })
	end
end

-- ================================
-- CREATURE CALLBACKS
-- ================================

creatureSpawner.onCreatureSpawned = function(creature)
	remotes.CreatureSpawn:FireAllClients({
		id = creature.id, configId = creature.configId,
		name = creature.name, position = creature.position,
	})
end

creatureSpawner.onCreatureDefeated = function(creature, killerPlayer)
	local model = creatureModels[creature.id]
	if model then
		CreatureModelFactory.destroy(model)
		creatureModels[creature.id] = nil
	end
	remotes.CreatureDefeated:FireAllClients({ id = creature.id, name = creature.name })
	if killerPlayer then
		sessionManager:recordCreatureKill(killerPlayer)
		progressionManager:incrementStat(killerPlayer, "totalCreaturesDefeated")
		progressionManager:checkAllBadges(killerPlayer)
	end
end

-- ================================
-- PLAYER CHARACTER CALLBACKS
-- ================================

playerCharacter.onPlayerDied = function(userId, source)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		sessionManager:recordDeath(player)
		remotes.Notification:FireClient(player, { text = "You were defeated by " .. (source or "the storm") .. "! Respawning...", success = false })
		for _, otherPlayer in Players:GetPlayers() do
			if otherPlayer.UserId ~= userId then
				local state = playerCharacter:getState(otherPlayer.UserId)
				if state then
					state.morale = math.max(0, state.morale - GameConfig.MORALE.TEAMMATE_DOWN_PENALTY)
				end
			end
		end
	end
end

playerCharacter.onPlayerRespawned = function(userId)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		remotes.Notification:FireClient(player, { text = "You have respawned.", success = true })
	end
end

-- ================================
-- REMOTE EVENT HANDLERS
-- ================================

-- Resource gathering
remotes.GatherResource.OnServerEvent:Connect(function(player, nodeId)
	local success, msg, gatherTime = interactionSystem:startGathering(player, nodeId)
	if success then
		remotes.Notification:FireClient(player, { text = msg, success = true })
		task.delay(gatherTime or 2, function()
			local gSuccess, gMsg, drops = interactionSystem:completeGathering(player)
			remotes.Notification:FireClient(player, { text = gMsg, success = gSuccess })
			if gSuccess then
				remotes.InventoryUpdate:FireClient(player, inventoryManager:getInventory(player.UserId))
			end
		end)
	else
		remotes.Notification:FireClient(player, { text = msg, success = false })
	end
end)

-- Loot container search
remotes.SearchLoot.OnServerEvent:Connect(function(player, containerId)
	local success, msg, items = lootSystem:searchContainer(containerId, inventoryManager, player.UserId)
	remotes.Notification:FireClient(player, { text = msg, success = success })
	if success then
		progressionManager:onLootSearched(player)
		remotes.InventoryUpdate:FireClient(player, inventoryManager:getInventory(player.UserId))
	end
end)

-- Crafting station open
remotes.OpenCraftStation.OnServerEvent:Connect(function(player, stationId)
	local recipes = interactionSystem:getAvailableRecipes(player, stationId)
	local inv = inventoryManager:getInventory(player.UserId)
	remotes.CraftStationData:FireClient(player, {
		stationId = stationId,
		recipes = recipes,
		inventory = inv,
		stormNumber = dayCycleManager.currentDay,
	})
end)

-- Craft item
remotes.CraftItem.OnServerEvent:Connect(function(player, recipeId, stationId)
	local success, msg = interactionSystem:craftItem(player, recipeId, stationId)
	remotes.Notification:FireClient(player, { text = msg, success = success })
	if success then
		sessionManager:recordItemCrafted(player)
		progressionManager:incrementStat(player, "totalItemsCrafted")
		progressionManager:checkAllBadges(player)
		remotes.InventoryUpdate:FireClient(player, inventoryManager:getInventory(player.UserId))
	end
end)

-- Building claims
remotes.ClaimBuilding.OnServerEvent:Connect(function(player, buildingId)
	local success, msg = interactionSystem:claimHouse(player, buildingId)
	remotes.Notification:FireClient(player, { text = msg, success = success })
	if success then remotes.BuildingUpdate:FireAllClients(structureManager:getAllBuildingStates()) end
end)

-- Wall fortification
remotes.FortifyWall.OnServerEvent:Connect(function(player, buildingId, wallIndex, fortTierId)
	local success, msg = interactionSystem:fortifyWall(player, buildingId, wallIndex, fortTierId)
	remotes.Notification:FireClient(player, { text = msg, success = success })
	if success then
		-- Track fort tier for badges
		progressionManager:onFortUpgraded(player, fortTierId or 1)
		remotes.BuildingUpdate:FireAllClients(structureManager:getAllBuildingStates())
	end
end)

-- Wall repair
remotes.RepairWall.OnServerEvent:Connect(function(player, buildingId, wallIndex)
	local success, msg = interactionSystem:repairWall(player, buildingId, wallIndex)
	remotes.Notification:FireClient(player, { text = msg, success = success })
	if success then remotes.BuildingUpdate:FireAllClients(structureManager:getAllBuildingStates()) end
end)

-- Building restoration
remotes.RestoreBuilding.OnServerEvent:Connect(function(player, buildingId)
	local success, msg = interactionSystem:restoreBuilding(player, buildingId)
	remotes.Notification:FireClient(player, { text = msg, success = success })
	if success then remotes.BuildingUpdate:FireAllClients(structureManager:getAllBuildingStates()) end
end)

-- Attack creature
remotes.AttackCreature.OnServerEvent:Connect(function(player, creatureId)
	local success, msg = interactionSystem:attackCreature(player, creatureId)
	remotes.Notification:FireClient(player, { text = msg, success = success })
end)

-- Tame creature
remotes.TameAttempt.OnServerEvent:Connect(function(player, creatureConfigId)
	local success, msg = interactionSystem:attemptTame(player, creatureConfigId)
	remotes.Notification:FireClient(player, { text = msg, success = success })
	if success then
		remotes.InventoryUpdate:FireClient(player, inventoryManager:getInventory(player.UserId))
	end
end)

-- Use item (food/medical)
remotes.UseItem.OnServerEvent:Connect(function(player, itemId)
	local success, msg = interactionSystem:useItem(player, itemId)
	remotes.Notification:FireClient(player, { text = msg, success = success })
	if success then
		remotes.InventoryUpdate:FireClient(player, inventoryManager:getInventory(player.UserId))
	end
end)

-- Talk to NPC
remotes.TalkToNPC.OnServerEvent:Connect(function(player, npcId)
	local success, dialogue = interactionSystem:talkToNPC(player, npcId)
	if success and dialogue then
		local npcStates = npcManager:getAllNPCStates()
		local npcState = npcStates[npcId]
		local npcName = npcState and npcState.name or npcId

		local trades = nil
		local npcData = npcManager.npcs[npcId]
		if npcData and (npcData.state == "active" or npcData.state == "rescued") and npcData.trades then
			trades = npcData.trades
		end

		remotes.NPCDialogue:FireClient(player, {
			npcId = npcId,
			npcName = npcName,
			text = dialogue,
			trades = trades,
		})
	end
end)

-- Trade with NPC
local tradeWithNPCRemote = remotes:FindFirstChild("TradeWithNPC")
if not tradeWithNPCRemote then
	tradeWithNPCRemote = Instance.new("RemoteEvent")
	tradeWithNPCRemote.Name = "TradeWithNPC"
	tradeWithNPCRemote.Parent = remotes
end

tradeWithNPCRemote.OnServerEvent:Connect(function(player, npcId, tradeId)
	local success, msg = interactionSystem:tradeWithNPC(player, npcId, tradeId)
	remotes.Notification:FireClient(player, { text = msg, success = success })
	if success then
		remotes.InventoryUpdate:FireClient(player, inventoryManager:getInventory(player.UserId))
	end
end)

-- Class selection (from class picker UI)
remotes.ClassSelected.OnServerEvent:Connect(function(player, classId)
	-- Validate class exists
	local validClass = false
	for _, class in GameConfig.CLASSES do
		if class.id == classId then
			validClass = true
			break
		end
	end

	if not validClass then
		remotes.Notification:FireClient(player, { text = "Invalid class", success = false })
		return
	end

	local success, msg = progressionManager:setClass(player, classId)
	if success then
		sessionManager:setPlayerClass(player, classId)
		playerCharacter:initPlayer(player.UserId, classId)

		-- Give class starter items (only on first selection per session)
		if not playerClassSelected[player.UserId] then
			playerClassSelected[player.UserId] = true
			inventoryManager:giveClassItems(player.UserId, classId)
		end

		remotes.InventoryUpdate:FireClient(player, inventoryManager:getInventory(player.UserId))
	end
	remotes.Notification:FireClient(player, { text = msg or ("Class set to " .. classId), success = success })
end)

-- Legacy class selection (kept for compatibility)
remotes.SelectClass.OnServerEvent:Connect(function(player, classId)
	remotes.ClassSelected.OnServerEvent:Fire(player, classId)
end)

-- Open badges panel (server sends player profile data)
remotes.OpenBadges.OnServerEvent:Connect(function(player)
	local data = progressionManager:getData(player)
	remotes.ShowBadges:FireClient(player, data)
end)

-- Campfire
remotes.UseCampfire.OnServerEvent:Connect(function(player)
	local state = playerCharacter:getState(player.UserId)
	if state then
		state.morale = math.min(state.maxMorale, state.morale + 15)
		remotes.Notification:FireClient(player, { text = "The warmth of the fire lifts your spirits.", success = true })
	end
end)

-- RemoteFunctions
remotes.GetGameState.OnServerInvoke = function(player)
	return {
		stormState = {
			state = dayCycleManager.phase == "daytime" and "calm" or dayCycleManager.phase,
			stormNumber = dayCycleManager.currentDay,
			stormType = dayCycleManager._pendingStormType,
			intensity = dayCycleManager:getIntensity(),
			timeRemaining = math.max(0, dayCycleManager.phaseTimer),
			totalStorms = GameConfig.TOTAL_STORMS,
		},
		dayState = dayCycleManager:getStateInfo(),
		weather = weatherEffects:getWeatherState(),
		buildings = structureManager:getAllBuildingStates(),
		playerData = progressionManager:getData(player),
		inventory = inventoryManager:getInventory(player.UserId),
	}
end

remotes.GetBuildingState.OnServerInvoke = function(player, buildingId)
	return structureManager:getBuildingState(buildingId)
end

remotes.GetInventory.OnServerInvoke = function(player)
	return inventoryManager:getInventory(player.UserId)
end

remotes.GetRecipes.OnServerInvoke = function(player, stationId)
	return craftingManager:getStationRecipes(stationId or "workbench", dayCycleManager.currentDay)
end

remotes.GetPlayerProfile.OnServerInvoke = function(player)
	return progressionManager:getData(player)
end

-- ================================
-- PLAYER CONNECTIONS
-- ================================

Players.PlayerAdded:Connect(function(player)
	print("[99 Storms] Player joined: " .. player.Name)

	-- Init all player systems
	progressionManager:loadPlayerData(player)
	inventoryManager:initPlayer(player.UserId)
	inventoryManager:giveStarterKit(player.UserId)
	playerCharacter:initPlayer(player.UserId, "craftsman")
	sessionManager:playerJoined(player)
	playerClassSelected[player.UserId] = false

	-- Send initial data after a brief delay
	task.delay(2, function()
		if player.Parent then
			remotes.InventoryUpdate:FireClient(player, inventoryManager:getInventory(player.UserId))
			remotes.DayStateChanged:FireClient(player, dayCycleManager:getStateInfo())
			-- Prompt class selection
			remotes.ShowClassSelection:FireClient(player)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	print("[99 Storms] Player left: " .. player.Name)
	progressionManager:onPlayerLeaving(player)
	inventoryManager:removePlayer(player.UserId)
	playerCharacter:removePlayer(player.UserId)
	tamingSystem:onPlayerLeaving(player.UserId)
	sessionManager:playerLeft(player)
	playerClassSelected[player.UserId] = nil
end)

-- ================================
-- GAME START
-- ================================

local gameStarted = false

sessionManager.onSessionStart = function()
	if not gameStarted then
		gameStarted = true
		print("[99 Storms] Game starting! Day cycle begins.")
		dayCycleManager:start()
	end
end

-- ================================
-- MAIN GAME LOOP
-- ================================

local STATS_BROADCAST_INTERVAL = 1
local statsBroadcastTimer = 0
local CREATURE_ATTACK_INTERVAL = 2
local creatureAttackTimer = 0
local EXPOSURE_TICK_INTERVAL = 1
local exposureTimer = 0

RunService.Heartbeat:Connect(function(deltaTime)
	-- Day cycle (replaces stormManager:update)
	dayCycleManager:update(deltaTime)

	-- Resource and loot respawns
	resourceGathering:update(deltaTime)
	lootSystem:update(deltaTime)

	-- Player character systems
	local isStormActive = dayCycleManager.phase == "storm"
	playerCharacter:update(deltaTime, isStormActive)

	-- Creature AI during storms
	if isStormActive then
		creatureSpawner:update(deltaTime)

		for id, creature in creatureSpawner.activeCreatures do
			if creature.isAlive and creatureModels[id] then
				CreatureModelFactory.updatePosition(creatureModels[id], creature.position)
				CreatureModelFactory.updateHealthBar(creatureModels[id], creature.hp, creature.maxHP)
			end
		end

		creatureAttackTimer += deltaTime
		if creatureAttackTimer >= CREATURE_ATTACK_INTERVAL then
			creatureAttackTimer = 0
			combatSystem:updateCreatureAttacks(deltaTime)
		end

		-- Weather damage (hail, debris, etc.)
		local effects = weatherEffects.activeEffects
		if effects.hailDamage then
			combatSystem:applyWeatherDamage(effects.hailDamage, "hail", deltaTime)
		end
		if effects.debrisDamage then
			combatSystem:applyWeatherDamage(effects.debrisDamage, "wind", deltaTime)
		end

		-- === STORM EXPOSURE DAMAGE (outdoor players) ===
		exposureTimer += deltaTime
		if exposureTimer >= EXPOSURE_TICK_INTERVAL then
			exposureTimer = 0
			local exposureDPS = dayCycleManager:getExposureDamage()

			for _, player in Players:GetPlayers() do
				local state = playerCharacter:getState(player.UserId)
				if state and not state.isDead and not state.isSheltered then
					-- Player is OUTSIDE during storm — take exposure damage
					playerCharacter:damage(state, exposureDPS * EXPOSURE_TICK_INTERVAL, "storm_exposure")

					-- Occasional warning
					if math.random() < 0.2 then
						remotes.Notification:FireClient(player, {
							text = "The storm is tearing at you! Get inside!",
							success = false,
						})
					end
				end
			end
		end
	else
		exposureTimer = 0
	end

	-- Regenerate barriers during daytime
	if dayCycleManager.phase == "daytime" then
		structureManager:regenerateBarriers(deltaTime)
	end

	-- Shelter detection for all players
	for _, player in Players:GetPlayers() do
		local isSheltered = weatherEffects:isPlayerSheltered(player)
		playerCharacter:setSheltered(player.UserId, isSheltered)
	end

	-- Broadcast player stats periodically
	statsBroadcastTimer += deltaTime
	if statsBroadcastTimer >= STATS_BROADCAST_INTERVAL then
		statsBroadcastTimer = 0
		for _, player in Players:GetPlayers() do
			local state = playerCharacter:getClientState(player.UserId)
			if state then
				remotes.PlayerStats:FireClient(player, state)
			end
		end
	end
end)

print("[99 Storms] Server initialized. Stormhaven generated. Waiting for players...")
