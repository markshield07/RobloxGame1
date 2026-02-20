--[[
	init.server.luau
	Main server entry point for 99 Storms.
	Initializes ALL server-side systems, wires them together,
	generates the map, and runs the game loop.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

-- Import ALL server systems
local StormManager = require(script.Storm.StormManager)
local WeatherEffects = require(script.Storm.WeatherEffects)
local StructureManager = require(script.Building.StructureManager)
local ResourceGathering = require(script.Building.ResourceGathering)
local InteractionSystem = require(script.Building.InteractionSystem)
local MapGenerator = require(script.Building.MapGenerator)
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
		-- Storm
		"StormStateChanged", "WeatherUpdate", "LightningStrike", "StormWarning",
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
		-- Misc
		"Notification", "InventoryUpdate", "UseCampfire",
	}

	for _, name in events do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remoteFolder
	end

	local functions = {
		"GetGameState", "GetBuildingState", "GetInventory", "GetRecipes",
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
local stormManager = StormManager.new()
local weatherEffects = WeatherEffects.new()
local structureManager = StructureManager.new()
local resourceGathering = ResourceGathering.new()
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

-- Track creature models
local creatureModels = {} -- creatureId -> Model

-- ================================
-- STORM CALLBACKS
-- ================================

stormManager.onStateChanged = function(newState, stormType, stormNumber)
	print(string.format("[99 Storms] State: %s | Storm: %s | #%d", newState, tostring(stormType), stormNumber))

	-- Broadcast state change
	remotes.StormStateChanged:FireAllClients({
		state = newState,
		stormType = stormType,
		stormNumber = stormNumber,
		stateInfo = stormManager:getStateInfo(),
	})

	-- Weather effects
	if newState == "storm" and stormType then
		weatherEffects:applyStormEffects(stormType, stormManager.stormIntensity)
		remotes.WeatherUpdate:FireAllClients(weatherEffects:getWeatherState())

		-- Spawn storm creatures
		local spawnCenter = Vector3.new(0, 0, 50) -- town center
		creatureSpawner:spawnStormCreatures(stormType, stormManager.stormIntensity, spawnCenter, 120)

		-- Create models for spawned creatures
		for id, creature in creatureSpawner.activeCreatures do
			if not creatureModels[id] then
				local model = CreatureModelFactory.create(creature.configId, creature.position, id)
				model:SetAttribute("ConfigId", creature.configId)
				creatureModels[id] = model
			end
		end
	elseif newState == "calm" then
		weatherEffects:clearEffects()
		remotes.WeatherUpdate:FireAllClients(weatherEffects:getWeatherState())
		-- Despawn storm creatures
		creatureSpawner:despawnAll()
		for id, model in creatureModels do
			CreatureModelFactory.destroy(model)
		end
		creatureModels = {}
		-- Restock NPC trades
		npcManager:restockTrades()
	elseif newState == "aftermath" then
		weatherEffects:clearEffects()
		remotes.WeatherUpdate:FireAllClients(weatherEffects:getWeatherState())
		-- Despawn storm creatures
		creatureSpawner:despawnAll()
		for id, model in creatureModels do
			CreatureModelFactory.destroy(model)
		end
		creatureModels = {}
	end

	-- Warning siren
	if newState == "warning" then
		remotes.StormWarning:FireAllClients({
			stormType = stormType,
			stormNumber = stormNumber,
			timeUntilStorm = GameConfig.STORM_WARNING_DURATION,
		})
	end

	-- Zone/rescue unlocks on aftermath
	if newState == "aftermath" then
		for _, zone in GameConfig.ZONES do
			if stormNumber == zone.unlockStorm and zone.unlockStorm > 0 then
				remotes.ZoneUnlocked:FireAllClients({ zoneId = zone.id, zoneName = zone.name })
			end
		end
		local newRescues = npcManager:checkRescueAvailability(stormNumber)
		for _, rescueId in newRescues do
			for _, rescue in GameConfig.RESCUES do
				if rescue.id == rescueId then
					remotes.RescueAvailable:FireAllClients({ rescueId = rescue.id, rescueName = rescue.name, zone = rescue.zone })
				end
			end
		end
	end

	-- Game complete
	if newState == "game_complete" then
		print("[99 Storms] GAME COMPLETE!")
		for _, player in Players:GetPlayers() do
			progressionManager:onGameComplete(player, sessionManager:getSessionDuration())
		end
		remotes.Notification:FireAllClients({ text = "CURSE BROKEN! Stormhaven is free!", success = true })
	end
end

stormManager.onStormComplete = function(stormNumber)
	for _, player in Players:GetPlayers() do
		progressionManager:onStormSurvived(player, stormNumber)
		sessionManager:recordStormSurvived(player)
	end

	-- Storm damage to structures
	local intensity = stormManager.stormIntensity
	for buildingId, _ in structureManager.buildings do
		structureManager:applyStormDamage(buildingId, 10 * intensity, 5 * intensity)
	end
	remotes.BuildingUpdate:FireAllClients(structureManager:getAllBuildingStates())
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
	-- Destroy model
	local model = creatureModels[creature.id]
	if model then
		CreatureModelFactory.destroy(model)
		creatureModels[creature.id] = nil
	end
	remotes.CreatureDefeated:FireAllClients({ id = creature.id, name = creature.name })
	if killerPlayer then
		sessionManager:recordCreatureKill(killerPlayer)
		progressionManager:incrementStat(killerPlayer, "totalCreaturesDefeated")
	end
end

-- ================================
-- PLAYER CHARACTER CALLBACKS
-- ================================

playerCharacter.onPlayerDied = function(userId, source)
	local player = Players:GetPlayerByUserId(userId)
	if player then
		sessionManager:recordDeath(player)
		remotes.Notification:FireClient(player, { text = "You were defeated by " .. (source or "unknown") .. "! Respawning...", success = false })
		-- Morale penalty for teammates
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
		-- Auto-complete after gather time
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

-- Crafting station open
remotes.OpenCraftStation.OnServerEvent:Connect(function(player, stationId)
	local recipes = interactionSystem:getAvailableRecipes(player, stationId)
	local inv = inventoryManager:getInventory(player.UserId)
	remotes.CraftStationData:FireClient(player, {
		stationId = stationId,
		recipes = recipes,
		inventory = inv,
		stormNumber = stormManager.currentStorm,
	})
end)

-- Craft item
remotes.CraftItem.OnServerEvent:Connect(function(player, recipeId, stationId)
	local success, msg = interactionSystem:craftItem(player, recipeId, stationId)
	remotes.Notification:FireClient(player, { text = msg, success = success })
	if success then
		sessionManager:recordItemCrafted(player)
		progressionManager:incrementStat(player, "totalItemsCrafted")
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
	if success then remotes.BuildingUpdate:FireAllClients(structureManager:getAllBuildingStates()) end
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
		-- Send full NPC data for the dialogue UI
		local npcStates = npcManager:getAllNPCStates()
		local npcState = npcStates[npcId]
		local npcName = npcState and npcState.name or npcId

		-- Get trade data if NPC is active/rescued
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

-- Class selection
remotes.SelectClass.OnServerEvent:Connect(function(player, classId)
	local success, msg = progressionManager:setClass(player, classId)
	if success then
		sessionManager:setPlayerClass(player, classId)
		-- Reinit player character with new class
		playerCharacter:initPlayer(player.UserId, classId)
	end
	remotes.Notification:FireClient(player, { text = msg, success = success })
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
		stormState = stormManager:getStateInfo(),
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
	return craftingManager:getStationRecipes(stationId or "workbench", stormManager.currentStorm)
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
	playerCharacter:initPlayer(player.UserId, "weatherman")
	sessionManager:playerJoined(player)

	-- Send initial inventory
	task.delay(2, function()
		if player.Parent then
			remotes.InventoryUpdate:FireClient(player, inventoryManager:getInventory(player.UserId))
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
end)

-- ================================
-- GAME START
-- ================================

local gameStarted = false

sessionManager.onSessionStart = function()
	if not gameStarted then
		gameStarted = true
		print("[99 Storms] Game starting!")
		stormManager:start()
	end
end

-- ================================
-- MAIN GAME LOOP
-- ================================

local STATS_BROADCAST_INTERVAL = 1 -- broadcast player stats every second
local statsBroadcastTimer = 0
local CREATURE_ATTACK_INTERVAL = 2 -- creatures attack every 2 seconds
local creatureAttackTimer = 0

RunService.Heartbeat:Connect(function(deltaTime)
	-- Storm cycle
	stormManager:update(deltaTime)

	-- Resource respawns
	resourceGathering:update(deltaTime)

	-- Player character systems (hunger, morale, stamina, effects)
	local isStormActive = stormManager.state == "storm"
	playerCharacter:update(deltaTime, isStormActive)

	-- Creature AI
	if isStormActive then
		creatureSpawner:update(deltaTime)

		-- Update creature model positions
		for id, creature in creatureSpawner.activeCreatures do
			if creature.isAlive and creatureModels[id] then
				CreatureModelFactory.updatePosition(creatureModels[id], creature.position)
				CreatureModelFactory.updateHealthBar(creatureModels[id], creature.hp, creature.maxHP)
			end
		end

		-- Creature attacks
		creatureAttackTimer += deltaTime
		if creatureAttackTimer >= CREATURE_ATTACK_INTERVAL then
			creatureAttackTimer = 0
			combatSystem:updateCreatureAttacks(deltaTime)
		end

		-- Weather damage (hail, hurricane debris, etc.)
		local effects = weatherEffects.activeEffects
		if effects.hailDamage then
			combatSystem:applyWeatherDamage(effects.hailDamage, "hail", deltaTime)
		end
		if effects.debrisDamage then
			combatSystem:applyWeatherDamage(effects.debrisDamage, "wind", deltaTime)
		end
	end

	-- Regenerate barriers during calm
	if stormManager.state == "calm" then
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
