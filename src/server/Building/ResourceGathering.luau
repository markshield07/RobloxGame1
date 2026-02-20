--[[
	ResourceGathering.luau
	Server-side resource gathering system.
	Manages resource nodes, gathering actions, respawn timers, and tool requirements.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ResourceGathering = {}
ResourceGathering.__index = ResourceGathering

export type ResourceNode = {
	id: string,
	nodeType: string,
	position: Vector3,
	currentYield: number,
	maxYield: number,
	respawnTime: number,
	respawnTimer: number,
	requiredTool: string?,
	gatherTime: number, -- seconds to gather
	drops: { { item: string, count: number, chance: number } },
	model: Model?,
	isActive: boolean,
}

-- Resource node type definitions
local NODE_TYPES = {
	driftwood = {
		name = "Driftwood",
		maxYield = 5,
		respawnTime = 120,
		gatherTime = 2,
		requiredTool = nil,
		drops = { { item = "wood", count = 3, chance = 1.0 }, { item = "rope", count = 1, chance = 0.3 } },
	},
	rock_deposit = {
		name = "Rock Deposit",
		maxYield = 4,
		respawnTime = 150,
		gatherTime = 3,
		requiredTool = nil,
		drops = { { item = "stone", count = 3, chance = 1.0 }, { item = "scrap_metal", count = 1, chance = 0.2 } },
	},
	iron_vein = {
		name = "Iron Vein",
		maxYield = 3,
		respawnTime = 200,
		gatherTime = 4,
		requiredTool = "iron_pickaxe",
		drops = { { item = "iron_ore", count = 2, chance = 1.0 }, { item = "rare_mineral", count = 1, chance = 0.1 } },
	},
	copper_deposit = {
		name = "Copper Deposit",
		maxYield = 3,
		respawnTime = 200,
		gatherTime = 4,
		requiredTool = "iron_pickaxe",
		drops = { { item = "copper_wire", count = 2, chance = 1.0 } },
	},
	scrap_pile = {
		name = "Scrap Pile",
		maxYield = 4,
		respawnTime = 100,
		gatherTime = 2,
		requiredTool = nil,
		drops = {
			{ item = "scrap_metal", count = 2, chance = 1.0 },
			{ item = "cloth", count = 1, chance = 0.4 },
			{ item = "glass", count = 1, chance = 0.2 },
			{ item = "copper_wire", count = 1, chance = 0.15 },
		},
	},
	fishing_spot = {
		name = "Fishing Spot",
		maxYield = 8,
		respawnTime = 60,
		gatherTime = 5,
		requiredTool = "fishing_rod",
		drops = {
			{ item = "raw_fish", count = 1, chance = 1.0 },
			{ item = "clam", count = 1, chance = 0.3 },
			{ item = "seaweed", count = 1, chance = 0.2 },
		},
	},
	tide_pool = {
		name = "Tide Pool",
		maxYield = 3,
		respawnTime = 90,
		gatherTime = 2,
		requiredTool = nil,
		drops = {
			{ item = "clam", count = 2, chance = 1.0 },
			{ item = "crab_shell", count = 1, chance = 0.4 },
			{ item = "seaweed", count = 1, chance = 0.5 },
		},
	},
	herb_patch = {
		name = "Herb Patch",
		maxYield = 4,
		respawnTime = 120,
		gatherTime = 2,
		requiredTool = nil,
		drops = { { item = "herbs", count = 2, chance = 1.0 } },
	},
	bird_nest = {
		name = "Seabird Nest",
		maxYield = 2,
		respawnTime = 180,
		gatherTime = 3,
		requiredTool = nil,
		drops = {
			{ item = "feathers", count = 3, chance = 1.0 },
			{ item = "eggs", count = 1, chance = 0.5 },
		},
	},
	oil_barrel = {
		name = "Oil Barrel",
		maxYield = 2,
		respawnTime = 240,
		gatherTime = 3,
		requiredTool = nil,
		drops = { { item = "oil", count = 3, chance = 1.0 }, { item = "fuel", count = 1, chance = 0.3 } },
	},
	cloth_source = {
		name = "Cloth Scraps",
		maxYield = 3,
		respawnTime = 100,
		gatherTime = 1.5,
		requiredTool = nil,
		drops = { { item = "cloth", count = 2, chance = 1.0 }, { item = "rope", count = 1, chance = 0.3 } },
	},
	crystal_deposit = {
		name = "Storm Crystal Deposit",
		maxYield = 2,
		respawnTime = 300,
		gatherTime = 6,
		requiredTool = "storm_pickaxe",
		drops = { { item = "storm_crystal", count = 1, chance = 1.0 } },
	},
	farm_plot = {
		name = "Farm Plot",
		maxYield = 6,
		respawnTime = 90,
		gatherTime = 2,
		requiredTool = nil,
		drops = { { item = "vegetables", count = 2, chance = 1.0 } },
	},
}

function ResourceGathering.new()
	local self = setmetatable({}, ResourceGathering)

	self.nodes = {} :: { [string]: ResourceNode }
	self.nextNodeId = 1
	self.onResourceGathered = nil -- callback(player, nodeId, drops)

	return self
end

-- Register a resource node in the world
function ResourceGathering:registerNode(nodeType: string, position: Vector3, model: Model?): string
	local typeDef = NODE_TYPES[nodeType]
	if not typeDef then
		warn("[ResourceGathering] Unknown node type: " .. nodeType)
		return ""
	end

	local id = "node_" .. self.nextNodeId
	self.nextNodeId += 1

	local node: ResourceNode = {
		id = id,
		nodeType = nodeType,
		position = position,
		currentYield = typeDef.maxYield,
		maxYield = typeDef.maxYield,
		respawnTime = typeDef.respawnTime,
		respawnTimer = 0,
		requiredTool = typeDef.requiredTool,
		gatherTime = typeDef.gatherTime,
		drops = typeDef.drops,
		model = model,
		isActive = true,
	}

	self.nodes[id] = node
	return id
end

-- Attempt to gather from a node
function ResourceGathering:gather(nodeId: string, userId: number, hasTool: boolean): (boolean, string, { { item: string, count: number } }?)
	local node = self.nodes[nodeId]
	if not node then
		return false, "Resource not found.", nil
	end

	if not node.isActive then
		return false, "This resource is depleted. Wait for it to respawn.", nil
	end

	if node.currentYield <= 0 then
		node.isActive = false
		node.respawnTimer = node.respawnTime
		return false, "Resource depleted.", nil
	end

	-- Check tool requirement
	if node.requiredTool and not hasTool then
		return false, "You need a " .. node.requiredTool .. " to gather this.", nil
	end

	-- Gather
	node.currentYield -= 1

	-- Roll drops
	local drops = {}
	for _, drop in node.drops do
		if math.random() <= drop.chance then
			table.insert(drops, { item = drop.item, count = drop.count })
		end
	end

	-- If yield is now 0, start respawn timer
	if node.currentYield <= 0 then
		node.isActive = false
		node.respawnTimer = node.respawnTime
		-- Visual: hide model
		if node.model then
			node.model:SetAttribute("Depleted", true)
		end
	end

	if self.onResourceGathered then
		self.onResourceGathered(userId, nodeId, drops)
	end

	local typeDef = NODE_TYPES[node.nodeType]
	local name = typeDef and typeDef.name or node.nodeType
	return true, "Gathered from " .. name .. " (" .. node.currentYield .. " remaining)", drops
end

-- Update respawn timers (called each Heartbeat)
function ResourceGathering:update(deltaTime: number)
	for _, node in self.nodes do
		if not node.isActive and node.respawnTimer > 0 then
			node.respawnTimer -= deltaTime
			if node.respawnTimer <= 0 then
				-- Respawn
				node.isActive = true
				node.currentYield = node.maxYield
				node.respawnTimer = 0
				-- Visual: show model
				if node.model then
					node.model:SetAttribute("Depleted", false)
				end
			end
		end
	end
end

-- Get all active nodes near a position (for client UI)
function ResourceGathering:getNodesNear(position: Vector3, radius: number): { ResourceNode }
	local nearby = {}
	for _, node in self.nodes do
		if node.isActive then
			local dist = (node.position - position).Magnitude
			if dist <= radius then
				table.insert(nearby, node)
			end
		end
	end
	return nearby
end

-- Get node state for client
function ResourceGathering:getNodeState(nodeId: string)
	local node = self.nodes[nodeId]
	if not node then return nil end

	local typeDef = NODE_TYPES[node.nodeType]
	return {
		id = node.id,
		name = typeDef and typeDef.name or node.nodeType,
		nodeType = node.nodeType,
		position = node.position,
		isActive = node.isActive,
		yield = node.currentYield,
		maxYield = node.maxYield,
		requiredTool = node.requiredTool,
		gatherTime = node.gatherTime,
	}
end

-- Get all node types (for documentation)
function ResourceGathering.getNodeTypes()
	return NODE_TYPES
end

return ResourceGathering
