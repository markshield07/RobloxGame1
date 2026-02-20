--[[
	StormUI.luau
	Client-side UI management for 99 Storms.
	Handles the HUD, storm warnings, notifications, building info, and menus.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local StormUI = {}

-- UI references (created in init)
local screenGui = nil
local stormHUD = nil
local dayHUD = nil
local notificationFrame = nil

-- ================================
-- INITIALIZATION
-- ================================

function StormUI.init()
	-- Create the main ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "StormUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Create Day Tracker (very top center)
	dayHUD = StormUI._createDayTracker()
	dayHUD.Parent = screenGui

	-- Create Storm HUD (below day tracker)
	stormHUD = StormUI._createStormHUD()
	stormHUD.Parent = screenGui

	-- Create notification area (right side)
	notificationFrame = StormUI._createNotificationFrame()
	notificationFrame.Parent = screenGui

	-- Create player stats bar (bottom left)
	local statsBar = StormUI._createStatsBar()
	statsBar.Parent = screenGui
end

-- ================================
-- DAY TRACKER (Very Top Center)
-- ================================

function StormUI._createDayTracker(): Frame
	local frame = Instance.new("Frame")
	frame.Name = "DayTracker"
	frame.Size = UDim2.new(0, 200, 0, 40)
	frame.Position = UDim2.new(0.5, -100, 0, 5)
	frame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 200, 80)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = frame

	-- Sun/Moon icon
	local icon = Instance.new("TextLabel")
	icon.Name = "DayIcon"
	icon.Size = UDim2.new(0, 30, 1, 0)
	icon.Position = UDim2.new(0, 8, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = "DAY"
	icon.TextColor3 = Color3.fromRGB(255, 220, 100)
	icon.TextSize = 12
	icon.Font = Enum.Font.GothamBold
	icon.Parent = frame

	-- Day number
	local dayLabel = Instance.new("TextLabel")
	dayLabel.Name = "DayNumber"
	dayLabel.Size = UDim2.new(0, 60, 1, 0)
	dayLabel.Position = UDim2.new(0, 38, 0, 0)
	dayLabel.BackgroundTransparency = 1
	dayLabel.Text = "1"
	dayLabel.TextColor3 = Color3.fromRGB(255, 240, 180)
	dayLabel.TextSize = 28
	dayLabel.Font = Enum.Font.GothamBold
	dayLabel.TextXAlignment = Enum.TextXAlignment.Left
	dayLabel.Parent = frame

	-- Phase indicator
	local phaseLabel = Instance.new("TextLabel")
	phaseLabel.Name = "PhaseLabel"
	phaseLabel.Size = UDim2.new(0, 100, 1, 0)
	phaseLabel.Position = UDim2.new(1, -105, 0, 0)
	phaseLabel.BackgroundTransparency = 1
	phaseLabel.Text = "DAYTIME"
	phaseLabel.TextColor3 = Color3.fromRGB(100, 200, 120)
	phaseLabel.TextSize = 14
	phaseLabel.Font = Enum.Font.GothamBold
	phaseLabel.TextXAlignment = Enum.TextXAlignment.Right
	phaseLabel.Parent = frame

	return frame
end

-- ================================
-- STORM HUD (Top Center)
-- ================================

function StormUI._createStormHUD(): Frame
	local frame = Instance.new("Frame")
	frame.Name = "StormHUD"
	frame.Size = UDim2.new(0, 400, 0, 80)
	frame.Position = UDim2.new(0.5, -200, 0, 50)
	frame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 120, 160)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = frame

	-- Storm counter
	local stormLabel = Instance.new("TextLabel")
	stormLabel.Name = "StormCounter"
	stormLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
	stormLabel.Position = UDim2.new(0, 15, 0, 5)
	stormLabel.BackgroundTransparency = 1
	stormLabel.Text = "Storm 0 / 99"
	stormLabel.TextColor3 = Color3.fromRGB(220, 230, 255)
	stormLabel.TextSize = 22
	stormLabel.Font = Enum.Font.GothamBold
	stormLabel.TextXAlignment = Enum.TextXAlignment.Left
	stormLabel.Parent = frame

	-- State label
	local stateLabel = Instance.new("TextLabel")
	stateLabel.Name = "StateLabel"
	stateLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
	stateLabel.Position = UDim2.new(0.5, 0, 0, 5)
	stateLabel.BackgroundTransparency = 1
	stateLabel.Text = "CALM"
	stateLabel.TextColor3 = Color3.fromRGB(100, 200, 120)
	stateLabel.TextSize = 20
	stateLabel.Font = Enum.Font.GothamBold
	stateLabel.TextXAlignment = Enum.TextXAlignment.Right
	stateLabel.Parent = frame

	-- Timer
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "Timer"
	timerLabel.Size = UDim2.new(1, -30, 0.4, 0)
	timerLabel.Position = UDim2.new(0, 15, 0.55, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = ""
	timerLabel.TextColor3 = Color3.fromRGB(180, 190, 210)
	timerLabel.TextSize = 16
	timerLabel.Font = Enum.Font.Gotham
	timerLabel.TextXAlignment = Enum.TextXAlignment.Left
	timerLabel.Parent = frame

	-- Progress bar
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, -30, 0, 4)
	progressBg.Position = UDim2.new(0, 15, 1, -8)
	progressBg.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = frame

	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBg

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 2)
	progressCorner.Parent = progressBar

	return frame
end

-- ================================
-- NOTIFICATION FRAME (Right Side)
-- ================================

function StormUI._createNotificationFrame(): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Notifications"
	frame.Size = UDim2.new(0, 350, 0, 400)
	frame.Position = UDim2.new(1, -360, 0.3, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.Parent = frame

	return frame
end

-- ================================
-- PLAYER STATS BAR (Bottom Left)
-- ================================

function StormUI._createStatsBar(): Frame
	local frame = Instance.new("Frame")
	frame.Name = "StatsBar"
	frame.Size = UDim2.new(0, 250, 0, 100)
	frame.Position = UDim2.new(0, 10, 1, -110)
	frame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	frame.BackgroundTransparency = 0.4
	frame.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	-- Health bar
	local healthLabel = Instance.new("TextLabel")
	healthLabel.Name = "HealthLabel"
	healthLabel.Size = UDim2.new(0, 60, 0, 20)
	healthLabel.Position = UDim2.new(0, 10, 0, 10)
	healthLabel.BackgroundTransparency = 1
	healthLabel.Text = "HP"
	healthLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	healthLabel.TextSize = 14
	healthLabel.Font = Enum.Font.GothamBold
	healthLabel.TextXAlignment = Enum.TextXAlignment.Left
	healthLabel.Parent = frame

	local healthBarBg = Instance.new("Frame")
	healthBarBg.Size = UDim2.new(0, 170, 0, 12)
	healthBarBg.Position = UDim2.new(0, 70, 0, 14)
	healthBarBg.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	healthBarBg.BorderSizePixel = 0
	healthBarBg.Parent = frame

	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = healthBarBg

	-- Hunger bar
	local hungerLabel = Instance.new("TextLabel")
	hungerLabel.Name = "HungerLabel"
	hungerLabel.Size = UDim2.new(0, 60, 0, 20)
	hungerLabel.Position = UDim2.new(0, 10, 0, 35)
	hungerLabel.BackgroundTransparency = 1
	hungerLabel.Text = "HUNGER"
	hungerLabel.TextColor3 = Color3.fromRGB(255, 180, 80)
	hungerLabel.TextSize = 14
	hungerLabel.Font = Enum.Font.GothamBold
	hungerLabel.TextXAlignment = Enum.TextXAlignment.Left
	hungerLabel.Parent = frame

	local hungerBarBg = Instance.new("Frame")
	hungerBarBg.Size = UDim2.new(0, 170, 0, 12)
	hungerBarBg.Position = UDim2.new(0, 70, 0, 39)
	hungerBarBg.BackgroundColor3 = Color3.fromRGB(40, 30, 15)
	hungerBarBg.BorderSizePixel = 0
	hungerBarBg.Parent = frame

	local hungerBar = Instance.new("Frame")
	hungerBar.Name = "HungerBar"
	hungerBar.Size = UDim2.new(1, 0, 1, 0)
	hungerBar.BackgroundColor3 = Color3.fromRGB(220, 160, 40)
	hungerBar.BorderSizePixel = 0
	hungerBar.Parent = hungerBarBg

	-- Morale bar
	local moraleLabel = Instance.new("TextLabel")
	moraleLabel.Name = "MoraleLabel"
	moraleLabel.Size = UDim2.new(0, 60, 0, 20)
	moraleLabel.Position = UDim2.new(0, 10, 0, 60)
	moraleLabel.BackgroundTransparency = 1
	moraleLabel.Text = "MORALE"
	moraleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	moraleLabel.TextSize = 14
	moraleLabel.Font = Enum.Font.GothamBold
	moraleLabel.TextXAlignment = Enum.TextXAlignment.Left
	moraleLabel.Parent = frame

	local moraleBarBg = Instance.new("Frame")
	moraleBarBg.Size = UDim2.new(0, 170, 0, 12)
	moraleBarBg.Position = UDim2.new(0, 70, 0, 64)
	moraleBarBg.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
	moraleBarBg.BorderSizePixel = 0
	moraleBarBg.Parent = frame

	local moraleBar = Instance.new("Frame")
	moraleBar.Name = "MoraleBar"
	moraleBar.Size = UDim2.new(1, 0, 1, 0)
	moraleBar.BackgroundColor3 = Color3.fromRGB(60, 160, 220)
	moraleBar.BorderSizePixel = 0
	moraleBar.Parent = moraleBarBg

	return frame
end

-- ================================
-- STATE UPDATES
-- ================================

local STATE_COLORS = {
	calm = Color3.fromRGB(100, 200, 120),
	warning = Color3.fromRGB(255, 200, 60),
	storm = Color3.fromRGB(255, 80, 80),
	aftermath = Color3.fromRGB(180, 160, 220),
}

local STATE_LABELS = {
	calm = "CALM",
	warning = "STORM WARNING",
	storm = "STORM",
	aftermath = "AFTERMATH",
}

function StormUI.updateStormState(gameState)
	if not stormHUD then return end

	local counter = stormHUD:FindFirstChild("StormCounter")
	local stateLabel = stormHUD:FindFirstChild("StateLabel")
	local progressBar = stormHUD:FindFirstChild("ProgressBg")

	if counter then
		counter.Text = string.format("Storm %d / 99", gameState.stormNumber or 0)
	end

	if stateLabel then
		stateLabel.Text = STATE_LABELS[gameState.stormState] or gameState.stormState
		stateLabel.TextColor3 = STATE_COLORS[gameState.stormState] or Color3.fromRGB(200, 200, 200)
	end

	if progressBar then
		local bar = progressBar:FindFirstChild("ProgressBar")
		if bar then
			local progress = (gameState.stormNumber or 0) / 99
			TweenService:Create(bar, TweenInfo.new(0.5), {
				Size = UDim2.new(progress, 0, 1, 0),
			}):Play()
		end
	end
end

function StormUI.updateTimer(timeRemaining: number)
	if not stormHUD then return end

	local timerLabel = stormHUD:FindFirstChild("Timer")
	if timerLabel then
		local minutes = math.floor(timeRemaining / 60)
		local seconds = math.floor(timeRemaining % 60)
		timerLabel.Text = string.format("%d:%02d remaining", minutes, seconds)
	end
end

-- ================================
-- NOTIFICATIONS
-- ================================

function StormUI.showNotification(text: string, isSuccess: boolean?)
	if not notificationFrame then return end

	local notification = Instance.new("Frame")
	notification.Size = UDim2.new(1, 0, 0, 40)
	notification.BackgroundColor3 = isSuccess and Color3.fromRGB(30, 60, 40) or Color3.fromRGB(60, 30, 30)
	notification.BackgroundTransparency = 0.3
	notification.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = notification

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(230, 235, 240)
	label.TextSize = 14
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = notification

	notification.Parent = notificationFrame

	-- Fade out and remove after 4 seconds
	task.delay(3, function()
		local fadeOut = TweenService:Create(notification, TweenInfo.new(1), {
			BackgroundTransparency = 1,
		})
		TweenService:Create(label, TweenInfo.new(1), {
			TextTransparency = 1,
		}):Play()
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			notification:Destroy()
		end)
	end)
end

function StormUI.showStormWarning(stormType: string, stormNumber: number, timeUntilStorm: number)
	-- Large center warning
	if not screenGui then return end

	local warningFrame = Instance.new("Frame")
	warningFrame.Name = "StormWarning"
	warningFrame.Size = UDim2.new(0, 500, 0, 120)
	warningFrame.Position = UDim2.new(0.5, -250, 0.3, 0)
	warningFrame.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
	warningFrame.BackgroundTransparency = 0.2
	warningFrame.BorderSizePixel = 0
	warningFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = warningFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 100, 100)
	stroke.Thickness = 2
	stroke.Parent = warningFrame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.5, 0)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "STORM WARNING"
	title.TextColor3 = Color3.fromRGB(255, 200, 200)
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.Parent = warningFrame

	local details = Instance.new("TextLabel")
	details.Size = UDim2.new(1, 0, 0.4, 0)
	details.Position = UDim2.new(0, 0, 0.5, 0)
	details.BackgroundTransparency = 1
	details.Text = string.format("Storm #%d — %s approaching", stormNumber, stormType or "Unknown")
	details.TextColor3 = Color3.fromRGB(220, 180, 180)
	details.TextSize = 18
	details.Font = Enum.Font.Gotham
	details.Parent = warningFrame

	-- Fade out after warning duration
	task.delay(5, function()
		local fadeOut = TweenService:Create(warningFrame, TweenInfo.new(2), {
			BackgroundTransparency = 1,
		})
		TweenService:Create(title, TweenInfo.new(2), { TextTransparency = 1 }):Play()
		TweenService:Create(details, TweenInfo.new(2), { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, TweenInfo.new(2), { Transparency = 1 }):Play()
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			warningFrame:Destroy()
		end)
	end)
end

function StormUI.showZoneUnlocked(zoneName: string)
	StormUI.showNotification("NEW ZONE UNLOCKED: " .. zoneName, true)
end

function StormUI.showRescueAvailable(rescueName: string, zone: string)
	StormUI.showNotification("RESCUE MISSION: " .. rescueName .. " needs help in " .. zone, true)
end

function StormUI.showMilestone(badge: string, name: string)
	StormUI.showNotification("BADGE EARNED: " .. name, true)
end

function StormUI.updateBuildingStates(buildingStates)
	-- TODO: Update building info panel if open
end

-- ================================
-- DAY TRACKER UPDATES
-- ================================

local PHASE_COLORS = {
	daytime = Color3.fromRGB(100, 200, 120),
	warning = Color3.fromRGB(255, 200, 60),
	storm = Color3.fromRGB(255, 80, 80),
	aftermath = Color3.fromRGB(180, 160, 220),
}

local PHASE_LABELS = {
	daytime = "DAYTIME",
	warning = "WARNING",
	storm = "STORM",
	aftermath = "AFTERMATH",
}

function StormUI.updateDayState(dayInfo)
	if not dayHUD then return end

	local dayNumber = dayHUD:FindFirstChild("DayNumber")
	local phaseLabel = dayHUD:FindFirstChild("PhaseLabel")
	local dayIcon = dayHUD:FindFirstChild("DayIcon")

	if dayNumber then
		dayNumber.Text = tostring(dayInfo.currentDay or 1)
	end

	local phase = dayInfo.phase or "daytime"

	if phaseLabel then
		phaseLabel.Text = PHASE_LABELS[phase] or phase:upper()
		phaseLabel.TextColor3 = PHASE_COLORS[phase] or Color3.fromRGB(200, 200, 200)
	end

	-- Pulse effect on storm
	if dayIcon then
		if phase == "storm" then
			dayIcon.TextColor3 = Color3.fromRGB(255, 80, 80)
		else
			dayIcon.TextColor3 = Color3.fromRGB(255, 220, 100)
		end
	end

	-- Update stroke color based on phase
	local stroke = dayHUD:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = PHASE_COLORS[phase] or Color3.fromRGB(255, 200, 80)
	end
end

-- ================================
-- PLAYER STATS UPDATE
-- ================================

function StormUI.updatePlayerStats(stats)
	if not screenGui then return end

	local statsBar = screenGui:FindFirstChild("StatsBar")
	if not statsBar then return end

	-- Update health bar
	local healthBarBg = statsBar:FindFirstChild("HealthLabel")
	if healthBarBg then
		local parent = healthBarBg.Parent
		-- Find the health bar frame (child of bg frame)
		for _, child in parent:GetChildren() do
			if child:IsA("Frame") and child.Name ~= "StatsBar" then
				local bar = child:FindFirstChild("HealthBar")
				if bar and stats.maxHealth and stats.maxHealth > 0 then
					bar.Size = UDim2.new(stats.health / stats.maxHealth, 0, 1, 0)
				end
			end
		end
	end

	-- Update hunger bar
	for _, child in statsBar:GetChildren() do
		if child:IsA("Frame") then
			local hungerBar = child:FindFirstChild("HungerBar")
			if hungerBar and stats.maxHunger and stats.maxHunger > 0 then
				hungerBar.Size = UDim2.new(stats.hunger / stats.maxHunger, 0, 1, 0)
			end
			local moraleBar = child:FindFirstChild("MoraleBar")
			if moraleBar and stats.maxMorale and stats.maxMorale > 0 then
				moraleBar.Size = UDim2.new(stats.morale / stats.maxMorale, 0, 1, 0)
			end
		end
	end
end

return StormUI
