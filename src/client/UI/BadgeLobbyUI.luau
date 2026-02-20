--[[
	BadgeLobbyUI.luau
	Pre-game lobby display showing player badges, highest day survived,
	and class. Can also be opened mid-game from inventory sidebar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local BadgeLobbyUI = {}

local screenGui = nil
local mainFrame = nil
local isOpen = false

local BADGE_COLORS = {
	first_day = Color3.fromRGB(100, 180, 100),
	week_one = Color3.fromRGB(80, 160, 200),
	fortified = Color3.fromRGB(200, 160, 60),
	scavenger = Color3.fromRGB(160, 120, 80),
	storm_veteran = Color3.fromRGB(100, 80, 200),
	iron_will = Color3.fromRGB(180, 180, 200),
	creature_slayer = Color3.fromRGB(200, 60, 60),
	master_crafter = Color3.fromRGB(60, 200, 160),
	legendary = Color3.fromRGB(255, 200, 60),
	first_boss = Color3.fromRGB(200, 50, 100),
}

function BadgeLobbyUI.init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BadgeLobbyUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 8
	screenGui.Enabled = false
	screenGui.Parent = playerGui
end

function BadgeLobbyUI.open(playerData)
	if isOpen then
		BadgeLobbyUI.close()
		return
	end
	isOpen = true
	playerData = playerData or {}

	-- Clean up previous
	for _, child in screenGui:GetChildren() do
		child:Destroy()
	end

	-- Overlay
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	-- Main panel
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "BadgePanel"
	mainFrame.Size = UDim2.new(0, 600, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -300, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 80, 180)
	stroke.Thickness = 2
	stroke.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "PLAYER PROFILE"
	title.TextColor3 = Color3.fromRGB(220, 200, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = mainFrame

	local closeBtnCorner = Instance.new("UICorner")
	closeBtnCorner.CornerRadius = UDim.new(0, 6)
	closeBtnCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		BadgeLobbyUI.close()
	end)

	-- Player stats summary
	local statsFrame = Instance.new("Frame")
	statsFrame.Size = UDim2.new(1, -20, 0, 80)
	statsFrame.Position = UDim2.new(0, 10, 0, 45)
	statsFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
	statsFrame.BorderSizePixel = 0
	statsFrame.Parent = mainFrame

	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 8)
	statsCorner.Parent = statsFrame

	-- Best Day Survived
	local bestDayLabel = Instance.new("TextLabel")
	bestDayLabel.Size = UDim2.new(0.33, 0, 1, 0)
	bestDayLabel.Position = UDim2.new(0, 0, 0, 0)
	bestDayLabel.BackgroundTransparency = 1
	bestDayLabel.Text = "BEST DAY\n" .. tostring(playerData.bestStormReached or 0)
	bestDayLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	bestDayLabel.TextSize = 16
	bestDayLabel.Font = Enum.Font.GothamBold
	bestDayLabel.Parent = statsFrame

	-- Total Storms
	local totalLabel = Instance.new("TextLabel")
	totalLabel.Size = UDim2.new(0.33, 0, 1, 0)
	totalLabel.Position = UDim2.new(0.33, 0, 0, 0)
	totalLabel.BackgroundTransparency = 1
	totalLabel.Text = "STORMS SURVIVED\n" .. tostring(playerData.totalStormsWeathered or 0)
	totalLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	totalLabel.TextSize = 16
	totalLabel.Font = Enum.Font.GothamBold
	totalLabel.Parent = statsFrame

	-- Creatures Defeated
	local killsLabel = Instance.new("TextLabel")
	killsLabel.Size = UDim2.new(0.34, 0, 1, 0)
	killsLabel.Position = UDim2.new(0.66, 0, 0, 0)
	killsLabel.BackgroundTransparency = 1
	killsLabel.Text = "CREATURES SLAIN\n" .. tostring(playerData.totalCreaturesDefeated or 0)
	killsLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	killsLabel.TextSize = 16
	killsLabel.Font = Enum.Font.GothamBold
	killsLabel.Parent = statsFrame

	-- Badges section header
	local badgeHeader = Instance.new("TextLabel")
	badgeHeader.Size = UDim2.new(1, -20, 0, 30)
	badgeHeader.Position = UDim2.new(0, 10, 0, 135)
	badgeHeader.BackgroundTransparency = 1
	badgeHeader.Text = "BADGES"
	badgeHeader.TextColor3 = Color3.fromRGB(200, 180, 240)
	badgeHeader.TextSize = 18
	badgeHeader.Font = Enum.Font.GothamBold
	badgeHeader.TextXAlignment = Enum.TextXAlignment.Left
	badgeHeader.Parent = mainFrame

	-- Badge grid
	local badgeGrid = Instance.new("ScrollingFrame")
	badgeGrid.Size = UDim2.new(1, -20, 0, 320)
	badgeGrid.Position = UDim2.new(0, 10, 0, 165)
	badgeGrid.BackgroundTransparency = 1
	badgeGrid.BorderSizePixel = 0
	badgeGrid.ScrollBarThickness = 4
	badgeGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
	badgeGrid.Parent = mainFrame

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 130, 0, 90)
	gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = badgeGrid

	-- Create badge cards
	local earnedBadges = playerData.badges or {}

	for i, badge in GameConfig.BADGES do
		local isEarned = table.find(earnedBadges, badge.id) ~= nil
		BadgeLobbyUI._createBadgeCard(badgeGrid, badge, isEarned, i)
	end

	-- Update canvas size
	task.defer(function()
		badgeGrid.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 10)
	end)

	screenGui.Enabled = true
end

function BadgeLobbyUI._createBadgeCard(parent, badge, isEarned, order)
	local color = BADGE_COLORS[badge.id] or Color3.fromRGB(100, 100, 120)

	local card = Instance.new("Frame")
	card.Name = badge.id
	card.BackgroundColor3 = isEarned and Color3.fromRGB(35, 40, 55) or Color3.fromRGB(25, 28, 38)
	card.BackgroundTransparency = isEarned and 0 or 0.3
	card.BorderSizePixel = 0
	card.LayoutOrder = order
	card.Parent = parent

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 6)
	cardCorner.Parent = card

	if isEarned then
		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = color
		cardStroke.Thickness = 2
		cardStroke.Parent = card
	end

	-- Badge icon
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0, 32)
	icon.Position = UDim2.new(0, 0, 0, 5)
	icon.BackgroundTransparency = 1
	icon.Text = badge.icon or "?"
	icon.TextColor3 = isEarned and color or Color3.fromRGB(80, 80, 90)
	icon.TextSize = 22
	icon.Font = Enum.Font.GothamBold
	icon.Parent = card

	-- Badge name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -6, 0, 16)
	nameLabel.Position = UDim2.new(0, 3, 0, 38)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = badge.name
	nameLabel.TextColor3 = isEarned and Color3.fromRGB(220, 225, 240) or Color3.fromRGB(90, 95, 110)
	nameLabel.TextSize = 10
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -6, 0, 24)
	descLabel.Position = UDim2.new(0, 3, 0, 55)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = badge.description
	descLabel.TextColor3 = isEarned and Color3.fromRGB(160, 165, 180) or Color3.fromRGB(70, 75, 85)
	descLabel.TextSize = 9
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextWrapped = true
	descLabel.Parent = card

	-- Locked overlay
	if not isEarned then
		local lockedLabel = Instance.new("TextLabel")
		lockedLabel.Size = UDim2.new(1, 0, 0, 12)
		lockedLabel.Position = UDim2.new(0, 0, 1, -14)
		lockedLabel.BackgroundTransparency = 1
		lockedLabel.Text = "LOCKED"
		lockedLabel.TextColor3 = Color3.fromRGB(80, 80, 90)
		lockedLabel.TextSize = 8
		lockedLabel.Font = Enum.Font.GothamBold
		lockedLabel.Parent = card
	end
end

function BadgeLobbyUI.close()
	isOpen = false
	screenGui.Enabled = false
	for _, child in screenGui:GetChildren() do
		child:Destroy()
	end
	mainFrame = nil
end

function BadgeLobbyUI.isOpen()
	return isOpen
end

return BadgeLobbyUI
