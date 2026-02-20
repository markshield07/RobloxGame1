--[[
	ClassSelectionUI.luau
	Full-screen class selection at game start.
	Players choose from free classes, each with unique starter items and abilities.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local ClassSelectionUI = {}

local screenGui = nil
local mainFrame = nil
local isOpen = false
local selectedClass = nil
local onClassSelected = nil -- callback

local CLASS_COLORS = {
	craftsman = Color3.fromRGB(200, 160, 60),
	scout = Color3.fromRGB(60, 180, 100),
	medic = Color3.fromRGB(200, 80, 80),
	warrior = Color3.fromRGB(140, 100, 200),
	stormchaser = Color3.fromRGB(80, 160, 220),
}

function ClassSelectionUI.init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ClassSelectionUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10
	screenGui.Enabled = false
	screenGui.Parent = playerGui
end

function ClassSelectionUI.open(callback)
	onClassSelected = callback
	isOpen = true
	selectedClass = nil

	-- Clear previous content
	if mainFrame then mainFrame:Destroy() end

	-- Dark overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.3
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	-- Main container
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "ClassSelection"
	mainFrame.Size = UDim2.new(0, 750, 0, 480)
	mainFrame.Position = UDim2.new(0.5, -375, 0.5, -240)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 130, 180)
	stroke.Thickness = 2
	stroke.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 50)
	title.BackgroundTransparency = 1
	title.Text = "CHOOSE YOUR CLASS"
	title.TextColor3 = Color3.fromRGB(255, 240, 180)
	title.TextSize = 28
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, 0, 0, 20)
	subtitle.Position = UDim2.new(0, 0, 0, 42)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Each class has unique abilities and starter items"
	subtitle.TextColor3 = Color3.fromRGB(160, 170, 190)
	subtitle.TextSize = 13
	subtitle.Font = Enum.Font.Gotham
	subtitle.Parent = mainFrame

	-- Class cards container
	local cardsFrame = Instance.new("Frame")
	cardsFrame.Name = "Cards"
	cardsFrame.Size = UDim2.new(1, -20, 0, 340)
	cardsFrame.Position = UDim2.new(0, 10, 0, 70)
	cardsFrame.BackgroundTransparency = 1
	cardsFrame.Parent = mainFrame

	local cardsLayout = Instance.new("UIListLayout")
	cardsLayout.FillDirection = Enum.FillDirection.Horizontal
	cardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardsLayout.Padding = UDim.new(0, 8)
	cardsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cardsLayout.Parent = cardsFrame

	-- Create class cards
	for i, class in GameConfig.CLASSES do
		ClassSelectionUI._createClassCard(cardsFrame, class, i)
	end

	-- Confirm button
	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Name = "ConfirmBtn"
	confirmBtn.Size = UDim2.new(0, 200, 0, 45)
	confirmBtn.Position = UDim2.new(0.5, -100, 1, -55)
	confirmBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 50)
	confirmBtn.Text = "SELECT CLASS"
	confirmBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
	confirmBtn.TextSize = 18
	confirmBtn.Font = Enum.Font.GothamBold
	confirmBtn.Parent = mainFrame

	local confirmCorner = Instance.new("UICorner")
	confirmCorner.CornerRadius = UDim.new(0, 8)
	confirmCorner.Parent = confirmBtn

	confirmBtn.MouseButton1Click:Connect(function()
		if selectedClass then
			ClassSelectionUI.close()
			if onClassSelected then
				onClassSelected(selectedClass)
			end
		end
	end)

	screenGui.Enabled = true
end

function ClassSelectionUI._createClassCard(parent, classData, order)
	local color = CLASS_COLORS[classData.id] or Color3.fromRGB(100, 100, 100)

	local card = Instance.new("TextButton")
	card.Name = classData.id
	card.Size = UDim2.new(0, 138, 1, 0)
	card.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
	card.BorderSizePixel = 0
	card.Text = ""
	card.LayoutOrder = order
	card.AutoButtonColor = false
	card.Parent = parent

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Name = "CardStroke"
	cardStroke.Color = Color3.fromRGB(60, 70, 90)
	cardStroke.Thickness = 1
	cardStroke.Parent = card

	-- Color bar at top
	local colorBar = Instance.new("Frame")
	colorBar.Size = UDim2.new(1, 0, 0, 4)
	colorBar.BackgroundColor3 = color
	colorBar.BorderSizePixel = 0
	colorBar.Parent = card

	-- Class name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 24)
	nameLabel.Position = UDim2.new(0, 5, 0, 12)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = classData.name
	nameLabel.TextColor3 = color
	nameLabel.TextSize = 17
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	-- Tagline
	local tagline = Instance.new("TextLabel")
	tagline.Size = UDim2.new(1, -10, 0, 16)
	tagline.Position = UDim2.new(0, 5, 0, 36)
	tagline.BackgroundTransparency = 1
	tagline.Text = '"' .. classData.tagline .. '"'
	tagline.TextColor3 = Color3.fromRGB(150, 155, 170)
	tagline.TextSize = 10
	tagline.Font = Enum.Font.GothamMedium
	tagline.TextXAlignment = Enum.TextXAlignment.Left
	tagline.Parent = card

	-- Abilities list
	local abilitiesFrame = Instance.new("Frame")
	abilitiesFrame.Size = UDim2.new(1, -10, 0, 180)
	abilitiesFrame.Position = UDim2.new(0, 5, 0, 60)
	abilitiesFrame.BackgroundTransparency = 1
	abilitiesFrame.Parent = card

	local abLayout = Instance.new("UIListLayout")
	abLayout.SortOrder = Enum.SortOrder.LayoutOrder
	abLayout.Padding = UDim.new(0, 4)
	abLayout.Parent = abilitiesFrame

	for j, ability in classData.abilities do
		local abLabel = Instance.new("TextLabel")
		abLabel.Size = UDim2.new(1, 0, 0, 14)
		abLabel.BackgroundTransparency = 1
		abLabel.Text = ability
		abLabel.TextColor3 = Color3.fromRGB(170, 175, 190)
		abLabel.TextSize = 9
		abLabel.Font = Enum.Font.Gotham
		abLabel.TextXAlignment = Enum.TextXAlignment.Left
		abLabel.TextWrapped = true
		abLabel.LayoutOrder = j
		abLabel.Parent = abilitiesFrame
	end

	-- Starter items label
	if classData.starterItems then
		local starterLabel = Instance.new("TextLabel")
		starterLabel.Size = UDim2.new(1, -10, 0, 14)
		starterLabel.Position = UDim2.new(0, 5, 1, -50)
		starterLabel.BackgroundTransparency = 1
		starterLabel.Text = "STARTER ITEMS:"
		starterLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
		starterLabel.TextSize = 9
		starterLabel.Font = Enum.Font.GothamBold
		starterLabel.TextXAlignment = Enum.TextXAlignment.Left
		starterLabel.Parent = card

		local items = {}
		for _, item in classData.starterItems do
			table.insert(items, item[2] .. "x " .. item[1]:gsub("_", " "))
		end
		local itemsLabel = Instance.new("TextLabel")
		itemsLabel.Size = UDim2.new(1, -10, 0, 30)
		itemsLabel.Position = UDim2.new(0, 5, 1, -36)
		itemsLabel.BackgroundTransparency = 1
		itemsLabel.Text = table.concat(items, ", ")
		itemsLabel.TextColor3 = Color3.fromRGB(150, 160, 180)
		itemsLabel.TextSize = 8
		itemsLabel.Font = Enum.Font.Gotham
		itemsLabel.TextXAlignment = Enum.TextXAlignment.Left
		itemsLabel.TextWrapped = true
		itemsLabel.Parent = card
	end

	-- Click to select
	card.MouseButton1Click:Connect(function()
		selectedClass = classData.id

		-- Update all cards' visual state
		for _, sibling in parent:GetChildren() do
			if sibling:IsA("TextButton") then
				local sibStroke = sibling:FindFirstChild("CardStroke")
				if sibStroke then
					if sibling.Name == classData.id then
						sibStroke.Color = color
						sibStroke.Thickness = 2
						sibling.BackgroundColor3 = Color3.fromRGB(35, 40, 60)
					else
						sibStroke.Color = Color3.fromRGB(60, 70, 90)
						sibStroke.Thickness = 1
						sibling.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
					end
				end
			end
		end

		-- Update confirm button
		local confirmBtn = mainFrame:FindFirstChild("ConfirmBtn")
		if confirmBtn then
			confirmBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 70)
			confirmBtn.Text = "PLAY AS " .. classData.name:upper()
			confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end)
end

function ClassSelectionUI.close()
	isOpen = false
	screenGui.Enabled = false
	-- Clean up
	for _, child in screenGui:GetChildren() do
		child:Destroy()
	end
	mainFrame = nil
end

function ClassSelectionUI.isOpen()
	return isOpen
end

return ClassSelectionUI
