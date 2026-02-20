--[[
	SessionManager.luau
	Server-side session and multiplayer management for 99 Storms.
	Handles player sessions, scaling, shared state, and lobby management.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local SessionManager = {}
SessionManager.__index = SessionManager

export type SessionState = "lobby" | "starting" | "active" | "complete"

export type PlayerSession = {
	userId: number,
	playerName: string,
	classId: string,
	joinTime: number,
	stormsWeathered: number,
	creaturesDefeated: number,
	itemsCrafted: number,
	buildingsRepaired: number,
	isAlive: boolean,
	deathCount: number,
}

function SessionManager.new()
	local self = setmetatable({}, SessionManager)

	self.state = "lobby" :: SessionState
	self.playerSessions = {} :: { [number]: PlayerSession } -- userId -> session data
	self.startTime = 0
	self.gameStartDelay = 10 -- seconds after first player joins
	self.onSessionStart = nil -- callback()
	self.onPlayerJoined = nil -- callback(player)
	self.onPlayerLeft = nil -- callback(player)

	return self
end

-- Register a new player joining
function SessionManager:playerJoined(player: Player)
	local session: PlayerSession = {
		userId = player.UserId,
		playerName = player.Name,
		classId = "weatherman",
		joinTime = tick(),
		stormsWeathered = 0,
		creaturesDefeated = 0,
		itemsCrafted = 0,
		buildingsRepaired = 0,
		isAlive = true,
		deathCount = 0,
	}

	self.playerSessions[player.UserId] = session

	if self.onPlayerJoined then
		self.onPlayerJoined(player)
	end

	-- Start game countdown if this is the first player
	if self.state == "lobby" then
		self.state = "starting"
		task.delay(self.gameStartDelay, function()
			if #Players:GetPlayers() > 0 then
				self:startSession()
			else
				self.state = "lobby"
			end
		end)
	end
end

-- Handle player leaving
function SessionManager:playerLeft(player: Player)
	if self.onPlayerLeft then
		self.onPlayerLeft(player)
	end

	self.playerSessions[player.UserId] = nil

	-- If all players left during active game, pause/end
	if self.state == "active" and #Players:GetPlayers() == 0 then
		-- Game will be garbage collected, no action needed
	end
end

-- Start the game session
function SessionManager:startSession()
	self.state = "active"
	self.startTime = tick()

	if self.onSessionStart then
		self.onSessionStart()
	end
end

-- End the game session
function SessionManager:endSession()
	self.state = "complete"
end

-- Get current player count
function SessionManager:getPlayerCount(): number
	return #Players:GetPlayers()
end

-- Get difficulty scaling for current player count
function SessionManager:getDifficultyScaling()
	local count = math.clamp(self:getPlayerCount(), 1, 5)
	return GameConfig.MULTIPLAYER_SCALING[count]
end

-- Record a player death
function SessionManager:recordDeath(player: Player)
	local session = self.playerSessions[player.UserId]
	if session then
		session.deathCount += 1
		session.isAlive = false
	end
end

-- Record a player respawn
function SessionManager:recordRespawn(player: Player)
	local session = self.playerSessions[player.UserId]
	if session then
		session.isAlive = true
	end
end

-- Record a storm survived by a player
function SessionManager:recordStormSurvived(player: Player)
	local session = self.playerSessions[player.UserId]
	if session then
		session.stormsWeathered += 1
	end
end

-- Record a creature kill
function SessionManager:recordCreatureKill(player: Player)
	local session = self.playerSessions[player.UserId]
	if session then
		session.creaturesDefeated += 1
	end
end

-- Record an item crafted
function SessionManager:recordItemCrafted(player: Player)
	local session = self.playerSessions[player.UserId]
	if session then
		session.itemsCrafted += 1
	end
end

-- Set player class
function SessionManager:setPlayerClass(player: Player, classId: string)
	local session = self.playerSessions[player.UserId]
	if session then
		session.classId = classId
	end
end

-- Get session duration
function SessionManager:getSessionDuration(): number
	if self.startTime == 0 then return 0 end
	return tick() - self.startTime
end

-- Get end-of-game summary for all players
function SessionManager:getGameSummary()
	local summary = {
		duration = self:getSessionDuration(),
		totalPlayers = 0,
		players = {},
	}

	for userId, session in self.playerSessions do
		summary.totalPlayers += 1
		table.insert(summary.players, {
			name = session.playerName,
			class = session.classId,
			stormsWeathered = session.stormsWeathered,
			creaturesDefeated = session.creaturesDefeated,
			itemsCrafted = session.itemsCrafted,
			buildingsRepaired = session.buildingsRepaired,
			deaths = session.deathCount,
		})
	end

	-- Sort by storms weathered
	table.sort(summary.players, function(a, b)
		return a.stormsWeathered > b.stormsWeathered
	end)

	return summary
end

-- Get all player session states for replication
function SessionManager:getAllPlayerStates()
	local states = {}
	for userId, session in self.playerSessions do
		states[userId] = {
			name = session.playerName,
			class = session.classId,
			isAlive = session.isAlive,
			storms = session.stormsWeathered,
		}
	end
	return states
end

return SessionManager
