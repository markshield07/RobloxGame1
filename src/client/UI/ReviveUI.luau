--[[
	ReviveUI.luau
	Death/downed screen overlay.
	Shows a countdown timer, teammate revive prompt, and Robux self-revive button.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ReviveUI = {}

local screenGui = nil
local mainFrame = nil
local timerLabel = nil
local isOpen = false
local downedTimer = 0

function ReviveUI.init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ReviveUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 20
	screenGui.Enabled = false
	screenGui.Parent = playerGui
end

function ReviveUI.show(downedDuration: number, robuxCost: number)
	if isOpen then return end
	isOpen = true
	downedTimer = downedDuration

	-- Clean up previous
	for _, child in screenGui:GetChildren() do
		child:Destroy()
	end

	-- Dark overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "DeathOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
	overlay.BackgroundTransparency = 0.4
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	-- Vignette effect (red edges)
	local vignette = Instance.new("ImageLabel")
	vignette.Name = "Vignette"
	vignette.Size = UDim2.new(1, 0, 1, 0)
	vignette.BackgroundTransparency = 1
	vignette.ImageColor3 = Color3.fromRGB(150, 0, 0)
	vignette.ImageTransparency = 0.5
	vignette.ScaleType = Enum.ScaleType.Stretch
	vignette.Parent = screenGui

	-- Main container
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "RevivePanel"
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
	mainFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 10)
	mainFrame.BackgroundTransparency = 0.3
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(180, 40, 40)
	stroke.Thickness = 2
	stroke.Parent = mainFrame

	-- "YOU ARE DOWN" title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.Position = UDim2.new(0, 0, 0, 15)
	title.BackgroundTransparency = 1
	title.Text = "YOU ARE DOWN"
	title.TextColor3 = Color3.fromRGB(255, 60, 60)
	title.TextSize = 32
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	-- Timer display
	timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(1, 0, 0, 40)
	timerLabel.Position = UDim2.new(0, 0, 0, 65)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = string.format("Respawn in %d seconds...", downedDuration)
	timerLabel.TextColor3 = Color3.fromRGB(200, 180, 180)
	timerLabel.TextSize = 18
	timerLabel.Font = Enum.Font.Gotham
	timerLabel.Parent = mainFrame

	-- "Waiting for teammate" message
	local teammateLabel = Instance.new("TextLabel")
	teammateLabel.Size = UDim2.new(1, 0, 0, 30)
	teammateLabel.Position = UDim2.new(0, 0, 0, 110)
	teammateLabel.BackgroundTransparency = 1
	teammateLabel.Text = "A teammate can revive you with a Medical Kit"
	teammateLabel.TextColor3 = Color3.fromRGB(150, 200, 150)
	teammateLabel.TextSize = 14
	teammateLabel.Font = Enum.Font.Gotham
	teammateLabel.Parent = mainFrame

	-- OR separator
	local orLabel = Instance.new("TextLabel")
	orLabel.Size = UDim2.new(1, 0, 0, 20)
	orLabel.Position = UDim2.new(0, 0, 0, 155)
	orLabel.BackgroundTransparency = 1
	orLabel.Text = "— OR —"
	orLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
	orLabel.TextSize = 14
	orLabel.Font = Enum.Font.GothamBold
	orLabel.Parent = mainFrame

	-- Robux self-revive button
	local reviveBtn = Instance.new("TextButton")
	reviveBtn.Name = "RobuxReviveBtn"
	reviveBtn.Size = UDim2.new(0, 250, 0, 50)
	reviveBtn.Position = UDim2.new(0.5, -125, 0, 190)
	reviveBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 60)
	reviveBtn.Text = string.format("REVIVE NOW (R$ %d)", robuxCost)
	reviveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	reviveBtn.TextSize = 18
	reviveBtn.Font = Enum.Font.GothamBold
	reviveBtn.Parent = mainFrame

	local reviveBtnCorner = Instance.new("UICorner")
	reviveBtnCorner.CornerRadius = UDim.new(0, 8)
	reviveBtnCorner.Parent = reviveBtn

	reviveBtn.MouseButton1Click:Connect(function()
		local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if Remotes and Remotes:FindFirstChild("RobuxRevive") then
			Remotes.RobuxRevive:FireServer()
		end
	end)

	-- Tip text
	local tipLabel = Instance.new("TextLabel")
	tipLabel.Size = UDim2.new(1, -20, 0, 20)
	tipLabel.Position = UDim2.new(0, 10, 1, -30)
	tipLabel.BackgroundTransparency = 1
	tipLabel.Text = "You will respawn at base with low HP if timer runs out"
	tipLabel.TextColor3 = Color3.fromRGB(100, 100, 110)
	tipLabel.TextSize = 11
	tipLabel.Font = Enum.Font.Gotham
	tipLabel.Parent = mainFrame

	screenGui.Enabled = true
end

function ReviveUI.updateTimer(remaining: number)
	downedTimer = remaining
	if timerLabel then
		timerLabel.Text = string.format("Respawn in %d seconds...", math.ceil(remaining))
	end
end

function ReviveUI.close()
	isOpen = false
	screenGui.Enabled = false
	for _, child in screenGui:GetChildren() do
		child:Destroy()
	end
	mainFrame = nil
	timerLabel = nil
end

function ReviveUI.isOpen(): boolean
	return isOpen
end

return ReviveUI
