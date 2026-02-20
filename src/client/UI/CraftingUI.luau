--[[
	CraftingUI.luau
	Client-side crafting interface for 99 Storms.
	Shows available recipes at the current station, ingredient requirements,
	and handles craft requests.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CraftingRecipes = require(ReplicatedStorage:WaitForChild("Shared").Config.CraftingRecipes)

local CraftingUI = {}

local screenGui = nil
local mainFrame = nil
local recipeList = nil
local detailPanel = nil
local isOpen = false
local currentStation = nil
local currentInventory = {}

-- ================================
-- INITIALIZATION
-- ================================

function CraftingUI.init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CraftingUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	-- Main frame
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "CraftingPanel"
	mainFrame.Size = UDim2.new(0, 700, 0, 450)
	mainFrame.Position = UDim2.new(0.5, -350, 0.5, -225)
	mainFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 100, 140)
	stroke.Thickness = 2
	stroke.Parent = mainFrame

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "CRAFTING"
	title.TextColor3 = Color3.fromRGB(220, 230, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseBtn"
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
		CraftingUI.close()
	end)

	-- Recipe list (left side)
	recipeList = Instance.new("ScrollingFrame")
	recipeList.Name = "RecipeList"
	recipeList.Size = UDim2.new(0.45, -10, 1, -50)
	recipeList.Position = UDim2.new(0, 10, 0, 45)
	recipeList.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	recipeList.BackgroundTransparency = 0.5
	recipeList.BorderSizePixel = 0
	recipeList.ScrollBarThickness = 4
	recipeList.CanvasSize = UDim2.new(0, 0, 0, 0)
	recipeList.Parent = mainFrame

	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 6)
	listCorner.Parent = recipeList

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 3)
	listLayout.Parent = recipeList

	-- Detail panel (right side)
	detailPanel = Instance.new("Frame")
	detailPanel.Name = "DetailPanel"
	detailPanel.Size = UDim2.new(0.55, -10, 1, -50)
	detailPanel.Position = UDim2.new(0.45, 5, 0, 45)
	detailPanel.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	detailPanel.BackgroundTransparency = 0.5
	detailPanel.BorderSizePixel = 0
	detailPanel.Parent = mainFrame

	local detailCorner = Instance.new("UICorner")
	detailCorner.CornerRadius = UDim.new(0, 6)
	detailCorner.Parent = detailPanel

	-- Default text in detail panel
	local defaultText = Instance.new("TextLabel")
	defaultText.Name = "DefaultText"
	defaultText.Size = UDim2.new(1, -20, 1, -20)
	defaultText.Position = UDim2.new(0, 10, 0, 10)
	defaultText.BackgroundTransparency = 1
	defaultText.Text = "Select a recipe to see details"
	defaultText.TextColor3 = Color3.fromRGB(120, 130, 150)
	defaultText.TextSize = 16
	defaultText.Font = Enum.Font.Gotham
	defaultText.TextWrapped = true
	defaultText.Parent = detailPanel
end

-- ================================
-- OPEN / CLOSE
-- ================================

function CraftingUI.open(stationId: string, inventory: { [string]: number }, stormNumber: number)
	currentStation = stationId
	currentInventory = inventory or {}
	isOpen = true

	-- Update title
	local stationNames = {
		workbench = "WORKBENCH",
		anvil = "BLACKSMITH ANVIL",
		stove = "TAVERN STOVE",
		medical_table = "CLINIC TABLE",
		storm_forge = "STORM FORGE",
		boat_workshop = "BOAT WORKSHOP",
		witchs_cauldron = "WITCH'S CAULDRON",
	}
	mainFrame.Title.Text = stationNames[stationId] or "CRAFTING"

	-- Populate recipe list
	CraftingUI.populateRecipes(stationId, stormNumber)

	screenGui.Enabled = true
end

function CraftingUI.close()
	isOpen = false
	currentStation = nil
	screenGui.Enabled = false
end

function CraftingUI.isOpen(): boolean
	return isOpen
end

-- ================================
-- RECIPE LIST
-- ================================

function CraftingUI.populateRecipes(stationId: string, stormNumber: number)
	-- Clear existing
	for _, child in recipeList:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local recipes = CraftingRecipes.getByStation(stationId)

	local order = 0
	for _, recipe in recipes do
		if recipe.unlockStorm <= stormNumber then
			order += 1
			CraftingUI.createRecipeButton(recipe, order)
		end
	end

	-- Update canvas size
	local layout = recipeList:FindFirstChildOfClass("UIListLayout")
	if layout then
		recipeList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end
end

function CraftingUI.createRecipeButton(recipe, order: number)
	-- Check if player can afford it
	local canAfford = true
	for _, ingredient in recipe.ingredients do
		local have = currentInventory[ingredient[1]] or 0
		if have < ingredient[2] then
			canAfford = false
			break
		end
	end

	local btn = Instance.new("TextButton")
	btn.Name = recipe.id
	btn.Size = UDim2.new(1, -6, 0, 35)
	btn.BackgroundColor3 = canAfford and Color3.fromRGB(35, 50, 45) or Color3.fromRGB(45, 35, 35)
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.LayoutOrder = order
	btn.Parent = recipeList

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = btn

	-- Recipe name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 8, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = recipe.name
	nameLabel.TextColor3 = canAfford and Color3.fromRGB(200, 220, 200) or Color3.fromRGB(160, 140, 140)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = btn

	-- Category tag
	local catLabel = Instance.new("TextLabel")
	catLabel.Size = UDim2.new(0.3, -8, 1, 0)
	catLabel.Position = UDim2.new(0.7, 0, 0, 0)
	catLabel.BackgroundTransparency = 1
	catLabel.Text = recipe.category
	catLabel.TextColor3 = Color3.fromRGB(120, 130, 150)
	catLabel.TextSize = 11
	catLabel.Font = Enum.Font.Gotham
	catLabel.TextXAlignment = Enum.TextXAlignment.Right
	catLabel.Parent = btn

	-- Click handler
	btn.MouseButton1Click:Connect(function()
		CraftingUI.showRecipeDetail(recipe, canAfford)
	end)
end

-- ================================
-- RECIPE DETAIL
-- ================================

function CraftingUI.showRecipeDetail(recipe, canAfford: boolean)
	-- Clear detail panel
	for _, child in detailPanel:GetChildren() do
		if not child:IsA("UICorner") then
			child:Destroy()
		end
	end

	local yPos = 10

	-- Recipe name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -20, 0, 30)
	nameLabel.Position = UDim2.new(0, 10, 0, yPos)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = recipe.name
	nameLabel.TextColor3 = Color3.fromRGB(220, 230, 255)
	nameLabel.TextSize = 20
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = detailPanel
	yPos += 35

	-- Result
	local resultLabel = Instance.new("TextLabel")
	resultLabel.Size = UDim2.new(1, -20, 0, 20)
	resultLabel.Position = UDim2.new(0, 10, 0, yPos)
	resultLabel.BackgroundTransparency = 1
	resultLabel.Text = "Produces: " .. recipe.result[2] .. "x " .. recipe.result[1]
	resultLabel.TextColor3 = Color3.fromRGB(100, 200, 120)
	resultLabel.TextSize = 14
	resultLabel.Font = Enum.Font.Gotham
	resultLabel.TextXAlignment = Enum.TextXAlignment.Left
	resultLabel.Parent = detailPanel
	yPos += 30

	-- Ingredients header
	local ingredientHeader = Instance.new("TextLabel")
	ingredientHeader.Size = UDim2.new(1, -20, 0, 20)
	ingredientHeader.Position = UDim2.new(0, 10, 0, yPos)
	ingredientHeader.BackgroundTransparency = 1
	ingredientHeader.Text = "Ingredients:"
	ingredientHeader.TextColor3 = Color3.fromRGB(180, 190, 210)
	ingredientHeader.TextSize = 14
	ingredientHeader.Font = Enum.Font.GothamBold
	ingredientHeader.TextXAlignment = Enum.TextXAlignment.Left
	ingredientHeader.Parent = detailPanel
	yPos += 22

	-- Ingredient list
	for _, ingredient in recipe.ingredients do
		local itemId = ingredient[1]
		local required = ingredient[2]
		local have = currentInventory[itemId] or 0
		local enough = have >= required

		local ingLabel = Instance.new("TextLabel")
		ingLabel.Size = UDim2.new(1, -30, 0, 18)
		ingLabel.Position = UDim2.new(0, 20, 0, yPos)
		ingLabel.BackgroundTransparency = 1
		ingLabel.Text = string.format("  %s: %d / %d", itemId, have, required)
		ingLabel.TextColor3 = enough and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(200, 80, 80)
		ingLabel.TextSize = 13
		ingLabel.Font = Enum.Font.Gotham
		ingLabel.TextXAlignment = Enum.TextXAlignment.Left
		ingLabel.Parent = detailPanel
		yPos += 20
	end

	yPos += 15

	-- Craft button
	local craftBtn = Instance.new("TextButton")
	craftBtn.Size = UDim2.new(0.6, 0, 0, 40)
	craftBtn.Position = UDim2.new(0.2, 0, 0, yPos)
	craftBtn.BackgroundColor3 = canAfford and Color3.fromRGB(40, 120, 60) or Color3.fromRGB(80, 40, 40)
	craftBtn.Text = canAfford and "CRAFT" or "NOT ENOUGH MATERIALS"
	craftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	craftBtn.TextSize = 16
	craftBtn.Font = Enum.Font.GothamBold
	craftBtn.AutoButtonColor = canAfford
	craftBtn.Parent = detailPanel

	local craftBtnCorner = Instance.new("UICorner")
	craftBtnCorner.CornerRadius = UDim.new(0, 8)
	craftBtnCorner.Parent = craftBtn

	if canAfford then
		craftBtn.MouseButton1Click:Connect(function()
			-- Send craft request to server
			local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
			if Remotes then
				Remotes.CraftItem:FireServer(recipe.id, currentStation)
			end
			-- Close after crafting (server will send result notification)
			CraftingUI.close()
		end)
	end
end

-- Update inventory reference
function CraftingUI.updateInventory(inventory: { [string]: number })
	currentInventory = inventory
end

return CraftingUI
