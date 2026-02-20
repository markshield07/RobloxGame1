--[[
	NPCManager.luau
	Server-side NPC management for 99 Storms.
	Handles NPC spawning, trading, dialogue, task assignment, and rescue state.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local NPCManager = {}
NPCManager.__index = NPCManager

export type NPCState = "missing" | "rescue_available" | "rescuing" | "rescued" | "active"

export type NPC = {
	id: string,
	name: string,
	role: string,
	state: NPCState,
	location: string, -- zone id or building id
	rescueZone: string?,
	rescueStorm: number?,
	dialogue: { string },
	trades: { TradeOffer }?,
	assignedTask: string?,
	dailyQuestGiven: boolean,
}

export type TradeOffer = {
	id: string,
	name: string,
	give: { { item: string, count: number } },
	receive: { { item: string, count: number } },
	stock: number, -- -1 for unlimited
}

function NPCManager.new()
	local self = setmetatable({}, NPCManager)

	self.npcs = {} :: { [string]: NPC }
	self.rescueCallbacks = {} -- npcId -> callback

	-- Initialize all NPCs
	self:initializeNPCs()

	return self
end

function NPCManager:initializeNPCs()
	-- ================================
	-- TOWN NPCs (always present)
	-- ================================

	self.npcs["fishmonger"] = {
		id = "fishmonger",
		name = "Sally the Fishmonger",
		role = "trader",
		state = "active",
		location = "fish_market",
		dialogue = {
			"Fresh fish! Well... as fresh as it gets in this cursed town.",
			"The storms bring strange things from the deep. I buy whatever you catch.",
			"Old Pete used to be the best fisher in Stormhaven. I hope he's still alive out there...",
		},
		trades = {
			{
				id = "buy_bait",
				name = "Fishing Bait",
				give = { { item = "storm_coins", count = 5 } },
				receive = { { item = "bait", count = 10 } },
				stock = -1,
			},
			{
				id = "sell_fish",
				name = "Sell Raw Fish",
				give = { { item = "raw_fish", count = 3 } },
				receive = { { item = "storm_coins", count = 2 } },
				stock = -1,
			},
			{
				id = "sell_lobster",
				name = "Sell Lobster",
				give = { { item = "lobster", count = 1 } },
				receive = { { item = "storm_coins", count = 5 } },
				stock = -1,
			},
		},
		assignedTask = nil,
		dailyQuestGiven = false,
	}

	self.npcs["shopkeeper"] = {
		id = "shopkeeper",
		name = "Harold the Shopkeeper",
		role = "trader",
		state = "active",
		location = "general_store",
		dialogue = {
			"Welcome to the Stormhaven General Store. Take what you need.",
			"Stock's running low with these storms... but I do what I can.",
			"If you restore the store properly, I can order in more supplies.",
		},
		trades = {
			{
				id = "buy_wood",
				name = "Wood Bundle",
				give = { { item = "storm_coins", count = 3 } },
				receive = { { item = "wood", count = 10 } },
				stock = 5,
			},
			{
				id = "buy_cloth",
				name = "Cloth Roll",
				give = { { item = "storm_coins", count = 4 } },
				receive = { { item = "cloth", count = 8 } },
				stock = 3,
			},
			{
				id = "buy_rope",
				name = "Rope Coil",
				give = { { item = "storm_coins", count = 3 } },
				receive = { { item = "rope", count = 6 } },
				stock = 4,
			},
			{
				id = "buy_oil",
				name = "Oil Can",
				give = { { item = "storm_coins", count = 5 } },
				receive = { { item = "oil", count = 5 } },
				stock = 3,
			},
		},
		assignedTask = nil,
		dailyQuestGiven = false,
	}

	self.npcs["barkeep"] = {
		id = "barkeep",
		name = "Maggie the Barkeep",
		role = "info_trader",
		state = "active",
		location = "tavern",
		dialogue = {
			"Pull up a chair. The storms are bad but the company's good.",
			"I hear things... whispers on the wind. The Tempest talks, you know.",
			"Before this all started, Elara used to come here every evening. She knew something was coming.",
		},
		trades = {
			{
				id = "buy_stew",
				name = "Maggie's Stew",
				give = { { item = "storm_coins", count = 4 } },
				receive = { { item = "fish_stew", count = 1 } },
				stock = 3,
			},
			{
				id = "buy_tea",
				name = "Herbal Tea",
				give = { { item = "storm_coins", count = 2 } },
				receive = { { item = "herbal_tea", count = 1 } },
				stock = 5,
			},
		},
		assignedTask = nil,
		dailyQuestGiven = false,
	}

	-- ================================
	-- RESCUE NPCs (start as missing)
	-- ================================

	self.npcs["old_pete"] = {
		id = "old_pete",
		name = "Old Pete the Fisherman",
		role = "rescue_npc",
		state = "missing",
		location = "marshlands",
		rescueZone = "marshlands",
		rescueStorm = 15,
		dialogue = {
			"(Before rescue) ...",
			"Thank the storms you found me! Those Lurkers had me cornered for days.",
			"I've fished these waters for 40 years. Let me teach you what I know.",
			"The Tempest... it wasn't always like this. Something went wrong with Elara's ritual.",
		},
		trades = {
			{
				id = "pete_deep_bait",
				name = "Pete's Deep Sea Bait",
				give = { { item = "raw_fish", count = 5 } },
				receive = { { item = "deep_sea_bait", count = 3 } },
				stock = -1,
			},
			{
				id = "pete_fishing_lesson",
				name = "Fishing Lesson (Recipe)",
				give = { { item = "storm_coins", count = 10 } },
				receive = { { item = "recipe_advanced_fishing", count = 1 } },
				stock = 1,
			},
		},
		assignedTask = nil,
		dailyQuestGiven = false,
	}

	self.npcs["marina"] = {
		id = "marina",
		name = "Marina the Biologist",
		role = "rescue_npc",
		state = "missing",
		location = "cliffs",
		rescueZone = "cliffs",
		rescueStorm = 30,
		dialogue = {
			"(Before rescue) ...",
			"I was studying the cave ecosystem when the mine collapsed. Thank you!",
			"The Tempest isn't evil — it's a guardian spirit that was corrupted.",
			"Elara's ritual was meant to summon a protector for Stormhaven. Something went terribly wrong.",
			"I can help you understand the creatures. Knowledge is your best weapon.",
		},
		trades = {
			{
				id = "marina_antivenom",
				name = "Marina's Antivenom",
				give = { { item = "herbs", count = 3 }, { item = "snake_venom", count = 1 } },
				receive = { { item = "antivenom", count = 2 } },
				stock = -1,
			},
			{
				id = "marina_creature_guide",
				name = "Creature Guide (Recipe)",
				give = { { item = "storm_coins", count = 15 } },
				receive = { { item = "recipe_taming_boost", count = 1 } },
				stock = 1,
			},
		},
		assignedTask = nil,
		dailyQuestGiven = false,
	}

	self.npcs["captain_briggs"] = {
		id = "captain_briggs",
		name = "Captain Briggs",
		role = "rescue_npc",
		state = "missing",
		location = "lighthouse_islands",
		rescueZone = "lighthouse_islands",
		rescueStorm = 50,
		dialogue = {
			"(Before rescue) ...",
			"My ship didn't stand a chance against the Maelstrom. But I survived.",
			"Two lighthouses working together — that's the key. The old keeper knew it.",
			"Elara is alive. I've seen her light in the eye of the Maelstrom. We can reach her.",
			"I'll get that second lighthouse running. You just keep the first one lit.",
		},
		trades = {
			{
				id = "briggs_boat_upgrade",
				name = "Captain's Boat Reinforcement",
				give = { { item = "iron_ore", count = 10 }, { item = "wood", count = 15 } },
				receive = { { item = "boat_armor_kit", count = 1 } },
				stock = -1,
			},
			{
				id = "briggs_navigation",
				name = "Navigation Charts",
				give = { { item = "storm_coins", count = 20 } },
				receive = { { item = "maelstrom_charts", count = 1 } },
				stock = 1,
			},
		},
		assignedTask = nil,
		dailyQuestGiven = false,
	}

	self.npcs["elara"] = {
		id = "elara",
		name = "Elara the Storm Witch",
		role = "rescue_npc",
		state = "missing",
		location = "maelstrom",
		rescueZone = "maelstrom",
		rescueStorm = 75,
		dialogue = {
			"(Before rescue) ...",
			"I never meant for this to happen. The ritual... it was supposed to protect everyone.",
			"The Tempest was my creation. A guardian spirit for Stormhaven. But I lost control.",
			"I can reverse it. But I need time — 24 more storms of channeling. Protect me.",
			"When this is over, Stormhaven will be safe again. I promise.",
		},
		trades = nil, -- Elara doesn't trade, she channels the counter-ritual
		assignedTask = nil,
		dailyQuestGiven = false,
	}
end

-- Check if a rescue mission should become available
function NPCManager:checkRescueAvailability(currentStorm: number): { string }
	local newlyAvailable = {}

	for _, rescue in GameConfig.RESCUES do
		local npc = self.npcs[rescue.id]
		if npc and npc.state == "missing" and currentStorm >= rescue.unlockStorm then
			npc.state = "rescue_available"
			table.insert(newlyAvailable, rescue.id)
		end
	end

	return newlyAvailable
end

-- Start a rescue mission
function NPCManager:startRescue(npcId: string): (boolean, string)
	local npc = self.npcs[npcId]
	if not npc then
		return false, "NPC not found."
	end

	if npc.state ~= "rescue_available" then
		return false, npc.name .. " is not available for rescue."
	end

	npc.state = "rescuing"
	return true, "Rescue mission started for " .. npc.name .. "!"
end

-- Complete a rescue mission
function NPCManager:completeRescue(npcId: string): (boolean, string)
	local npc = self.npcs[npcId]
	if not npc then
		return false, "NPC not found."
	end

	if npc.state ~= "rescuing" then
		return false, npc.name .. " is not being rescued."
	end

	npc.state = "rescued"
	npc.location = "stormhaven" -- move to town

	-- Find the rescue config for reward info
	for _, rescue in GameConfig.RESCUES do
		if rescue.id == npcId then
			return true, npc.name .. " has been rescued! " .. rescue.reward
		end
	end

	return true, npc.name .. " has been rescued!"
end

-- Get NPC dialogue (returns next line in rotation)
function NPCManager:getDialogue(npcId: string): string?
	local npc = self.npcs[npcId]
	if not npc then return nil end

	-- Filter dialogue based on state
	local availableDialogue = {}
	for _, line in npc.dialogue do
		if npc.state == "missing" and string.find(line, "Before rescue") then
			-- Skip "(Before rescue)" placeholder
		elseif npc.state ~= "missing" and not string.find(line, "Before rescue") then
			table.insert(availableDialogue, line)
		end
	end

	if #availableDialogue == 0 then return nil end

	return availableDialogue[math.random(1, #availableDialogue)]
end

-- Execute a trade
function NPCManager:executeTrade(npcId: string, tradeId: string): (boolean, string, TradeOffer?)
	local npc = self.npcs[npcId]
	if not npc then
		return false, "NPC not found.", nil
	end

	if npc.state ~= "active" and npc.state ~= "rescued" then
		return false, npc.name .. " is not available for trading.", nil
	end

	if not npc.trades then
		return false, npc.name .. " has nothing to trade.", nil
	end

	-- Find the trade
	local trade = nil
	for _, t in npc.trades do
		if t.id == tradeId then
			trade = t
			break
		end
	end

	if not trade then
		return false, "Trade not found.", nil
	end

	-- Check stock
	if trade.stock == 0 then
		return false, "Out of stock.", nil
	end

	-- Decrease stock (if not unlimited)
	if trade.stock > 0 then
		trade.stock -= 1
	end

	return true, "Trade complete!", trade
end

-- Assign an NPC to a task (Keeper class ability)
function NPCManager:assignTask(npcId: string, taskType: string): (boolean, string)
	local npc = self.npcs[npcId]
	if not npc then
		return false, "NPC not found."
	end

	if npc.state ~= "active" and npc.state ~= "rescued" then
		return false, npc.name .. " is not available for tasks."
	end

	if npc.assignedTask then
		return false, npc.name .. " is already assigned to: " .. npc.assignedTask
	end

	local validTasks = { "fishing", "gathering", "repairing", "cooking", "guarding" }
	if not table.find(validTasks, taskType) then
		return false, "Invalid task type."
	end

	npc.assignedTask = taskType
	return true, npc.name .. " assigned to " .. taskType .. "!"
end

-- Clear NPC task assignment
function NPCManager:clearTask(npcId: string)
	local npc = self.npcs[npcId]
	if npc then
		npc.assignedTask = nil
	end
end

-- Restock NPC trades (called each new calm phase)
function NPCManager:restockTrades()
	for _, npc in self.npcs do
		if npc.trades then
			for _, trade in npc.trades do
				if trade.stock ~= -1 then
					-- Restock to a reasonable amount
					trade.stock = math.random(2, 5)
				end
			end
		end
		npc.dailyQuestGiven = false
	end
end

-- Get all NPC states for client replication
function NPCManager:getAllNPCStates()
	local states = {}
	for id, npc in self.npcs do
		states[id] = {
			id = npc.id,
			name = npc.name,
			role = npc.role,
			state = npc.state,
			location = npc.location,
			hasTrades = npc.trades ~= nil and #npc.trades > 0,
			assignedTask = npc.assignedTask,
		}
	end
	return states
end

-- Get rescue mission progress
function NPCManager:getRescueProgress(): { { id: string, name: string, state: string, zone: string } }
	local progress = {}
	for _, rescue in GameConfig.RESCUES do
		local npc = self.npcs[rescue.id]
		if npc then
			table.insert(progress, {
				id = rescue.id,
				name = npc.name,
				state = npc.state,
				zone = rescue.zone,
			})
		end
	end
	return progress
end

return NPCManager
