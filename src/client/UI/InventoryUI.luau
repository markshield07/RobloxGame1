--[[
	InventoryUI.luau
	Client-side inventory display for 99 Storms.
	Shows all player items, allows using food/medical items.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local InventoryUI = {}

local screenGui = nil
local mainFrame = nil
local itemGrid = nil
local isOpen = false
local currentInventory = {}

-- Item display names and categories for better UI
local ITEM_DISPLAY = {
	wood = { name = "Wood", icon = "W", color = Color3.fromRGB(140, 100, 60) },
	stone = { name = "Stone", icon = "S", color = Color3.fromRGB(130, 125, 120) },
	rope = { name = "Rope", icon = "R", color = Color3.fromRGB(160, 140, 80) },
	cloth = { name = "Cloth", icon = "C", color = Color3.fromRGB(200, 195, 185) },
	scrap_metal = { name = "Scrap Metal", icon = "M", color = Color3.fromRGB(160, 160, 165) },
	iron_ore = { name = "Iron Ore", icon = "Fe", color = Color3.fromRGB(140, 110, 90) },
	copper_wire = { name = "Copper Wire", icon = "Cu", color = Color3.fromRGB(200, 120, 60) },
	oil = { name = "Oil", icon = "O", color = Color3.fromRGB(60, 50, 40) },
	glass = { name = "Glass", icon = "G", color = Color3.fromRGB(180, 210, 230) },
	storm_crystal = { name = "Storm Crystal", icon = "SC", color = Color3.fromRGB(120, 80, 200) },
	raw_fish = { name = "Raw Fish", icon = "F", color = Color3.fromRGB(150, 180, 200) },
	cooked_fish = { name = "Cooked Fish", icon = "CF", color = Color3.fromRGB(200, 160, 100) },
	fish_stew = { name = "Fish Stew", icon = "FS", color = Color3.fromRGB(180, 140, 80) },
	herbs = { name = "Herbs", icon = "H", color = Color3.fromRGB(80, 160, 60) },
	bandage = { name = "Bandage", icon = "B", color = Color3.fromRGB(230, 230, 230) },
	medical_kit = { name = "Med Kit", icon = "MK", color = Color3.fromRGB(200, 50, 50) },
	wooden_club = { name = "Wood Club", icon = "WC", color = Color3.fromRGB(140, 100, 60) },
	iron_sword = { name = "Iron Sword", icon = "IS", color = Color3.fromRGB(180, 180, 190) },
	storm_blade = { name = "Storm Blade", icon = "SB", color = Color3.fromRGB(100, 140, 220) },
	lantern = { name = "Lantern", icon = "L", color = Color3.fromRGB(255, 200, 80) },
	fishing_rod = { name = "Fishing Rod", icon = "FR", color = Color3.fromRGB(140, 100, 60) },
	signal_flare = { name = "Signal Flare", icon = "SF", color = Color3.fromRGB(255, 100, 50) },
	-- Building materials
	wooden_boards = { name = "Wood Boards", icon = "WB", color = Color3.fromRGB(160, 120, 70) },
	reinforced_planks = { name = "Reinforced Planks", icon = "RP", color = Color3.fromRGB(120, 140, 80) },
	metal_shutters = { name = "Metal Shutters", icon = "MS", color = Color3.fromRGB(160, 165, 170) },
	storm_glass = { name = "Storm Glass", icon = "SG", color = Color3.fromRGB(120, 180, 220) },
	storm_crystal_barriers = { name = "Crystal Barriers", icon = "CB", color = Color3.fromRGB(140, 100, 220) },
	storm_ward = { name = "Storm Ward", icon = "SW", color = Color3.fromRGB(100, 160, 200) },
	storm_salve = { name = "Storm Salve", icon = "SS", color = Color3.fromRGB(80, 160, 180) },
	herbal_tea = { name = "Herbal Tea", icon = "HT", color = Color3.fromRGB(100, 180, 80) },
	-- Rare base items
	reinforced_core = { name = "Reinforced Core", icon = "RC", color = Color3.fromRGB(220, 180, 60) },
	ancient_relic = { name = "Ancient Relic", icon = "AR", color = Color3.fromRGB(200, 160, 40) },
}

-- Items that can be "used" (consumed)
local USABLE_ITEMS = {
	raw_fish = true, cooked_fish = true, fish_stew = true,
	clam_chowder = true, herbal_tea = true, storm_feast = true,
	lobster_dinner = true, bandage = true, medical_kit = true,
	storm_salve = true, antivenom = true, signal_flare = true,
}

function InventoryUI.init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InventoryUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Background overlay
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	-- Main frame
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "InventoryPanel"
	mainFrame.Size = UDim2.new(0, 550, 0, 450)
	mainFrame.Position = UDim2.new(0.5, -275, 0.5, -225)
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
	title.Size = UDim2.new(1, 0, 0, 40)
	title.BackgroundTransparency = 1
	title.Text = "INVENTORY"
	title.TextColor3 = Color3.fromRGB(220, 230, 255)
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
		InventoryUI.close()
	end)

	-- Item grid (scrolling) — narrower to make room for sidebar
	itemGrid = Instance.new("ScrollingFrame")
	itemGrid.Name = "ItemGrid"
	itemGrid.Size = UDim2.new(1, -80, 1, -55)
	itemGrid.Position = UDim2.new(0, 10, 0, 45)
	itemGrid.BackgroundTransparency = 1
	itemGrid.BorderSizePixel = 0
	itemGrid.ScrollBarThickness = 4
	itemGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
	itemGrid.Parent = mainFrame

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 95, 0, 75)
	gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = itemGrid

	-- =============================
	-- SIDEBAR ACTION BUTTONS
	-- =============================
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 55, 1, -55)
	sidebar.Position = UDim2.new(1, -60, 0, 45)
	sidebar.BackgroundTransparency = 1
	sidebar.Parent = mainFrame

	local sidebarLayout = Instance.new("UIListLayout")
	sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sidebarLayout.Padding = UDim.new(0, 6)
	sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	sidebarLayout.Parent = sidebar

	-- Helper to create sidebar buttons
	local function createSidebarButton(name, label, icon, color, order)
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(1, 0, 0, 50)
		btn.BackgroundColor3 = color
		btn.BackgroundTransparency = 0.2
		btn.Text = ""
		btn.LayoutOrder = order
		btn.BorderSizePixel = 0
		btn.Parent = sidebar

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn

		local btnIcon = Instance.new("TextLabel")
		btnIcon.Size = UDim2.new(1, 0, 0, 28)
		btnIcon.Position = UDim2.new(0, 0, 0, 2)
		btnIcon.BackgroundTransparency = 1
		btnIcon.Text = icon
		btnIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
		btnIcon.TextSize = 18
		btnIcon.Font = Enum.Font.GothamBold
		btnIcon.Parent = btn

		local btnLabel = Instance.new("TextLabel")
		btnLabel.Size = UDim2.new(1, 0, 0, 16)
		btnLabel.Position = UDim2.new(0, 0, 0, 30)
		btnLabel.BackgroundTransparency = 1
		btnLabel.Text = label
		btnLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
		btnLabel.TextSize = 9
		btnLabel.Font = Enum.Font.Gotham
		btnLabel.Parent = btn

		return btn
	end

	-- Badges button
	local badgesBtn = createSidebarButton("BadgesBtn", "BADGES", "BDG", Color3.fromRGB(60, 40, 100), 1)
	badgesBtn.MouseButton1Click:Connect(function()
		local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if Remotes and Remotes:FindFirstChild("OpenBadges") then
			Remotes.OpenBadges:FireServer()
		end
	end)

	-- Base Status button
	local baseBtn = createSidebarButton("BaseBtn", "BASE", "BSE", Color3.fromRGB(40, 80, 50), 2)
	baseBtn.MouseButton1Click:Connect(function()
		local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if Remotes and Remotes:FindFirstChild("OpenBaseStatus") then
			Remotes.OpenBaseStatus:FireServer()
		end
	end)

	-- Class button
	local classBtn = createSidebarButton("ClassBtn", "CLASS", "CLS", Color3.fromRGB(80, 50, 40), 3)
	classBtn.MouseButton1Click:Connect(function()
		local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
		if Remotes and Remotes:FindFirstChild("OpenClassSelect") then
			Remotes.OpenClassSelect:FireServer()
		end
	end)

	-- Map/Loot button
	local mapBtn = createSidebarButton("MapBtn", "MAP", "MAP", Color3.fromRGB(40, 60, 80), 4)
	mapBtn.MouseButton1Click:Connect(function()
		-- Placeholder for minimap/loot finder
	end)
end

function InventoryUI.open(inventory: { [string]: number })
	currentInventory = inventory or {}
	isOpen = true
	InventoryUI.refresh()
	screenGui.Enabled = true
end

function InventoryUI.close()
	isOpen = false
	screenGui.Enabled = false
end

function InventoryUI.toggle(inventory: { [string]: number })
	if isOpen then
		InventoryUI.close()
	else
		InventoryUI.open(inventory)
	end
end

function InventoryUI.isOpen(): boolean
	return isOpen
end

function InventoryUI.refresh()
	-- Clear existing items
	for _, child in itemGrid:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Sort items by category
	local sortedItems = {}
	for itemId, count in currentInventory do
		if count > 0 then
			table.insert(sortedItems, { id = itemId, count = count })
		end
	end
	table.sort(sortedItems, function(a, b)
		return a.id < b.id
	end)

	-- Create item slots
	for i, item in sortedItems do
		InventoryUI.createItemSlot(item.id, item.count, i)
	end

	-- Update canvas size
	local gridLayout = itemGrid:FindFirstChildOfClass("UIGridLayout")
	if gridLayout then
		itemGrid.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 10)
	end
end

function InventoryUI.createItemSlot(itemId: string, count: number, order: number)
	local display = ITEM_DISPLAY[itemId] or {
		name = itemId,
		icon = string.sub(itemId, 1, 2):upper(),
		color = Color3.fromRGB(120, 120, 120),
	}

	local slot = Instance.new("Frame")
	slot.Name = itemId
	slot.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
	slot.BorderSizePixel = 0
	slot.LayoutOrder = order
	slot.Parent = itemGrid

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 6)
	slotCorner.Parent = slot

	-- Icon/abbreviation
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(1, 0, 0, 30)
	icon.Position = UDim2.new(0, 0, 0, 2)
	icon.BackgroundTransparency = 1
	icon.Text = display.icon
	icon.TextColor3 = display.color
	icon.TextSize = 20
	icon.Font = Enum.Font.GothamBold
	icon.Parent = slot

	-- Item name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -4, 0, 16)
	nameLabel.Position = UDim2.new(0, 2, 0, 32)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = display.name
	nameLabel.TextColor3 = Color3.fromRGB(180, 190, 210)
	nameLabel.TextSize = 10
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = slot

	-- Count
	local countLabel = Instance.new("TextLabel")
	countLabel.Size = UDim2.new(1, -4, 0, 18)
	countLabel.Position = UDim2.new(0, 2, 0, 50)
	countLabel.BackgroundTransparency = 1
	countLabel.Text = "x" .. count
	countLabel.TextColor3 = Color3.fromRGB(140, 150, 170)
	countLabel.TextSize = 13
	countLabel.Font = Enum.Font.GothamBold
	countLabel.Parent = slot

	-- Use button for usable items
	if USABLE_ITEMS[itemId] then
		local useBtn = Instance.new("TextButton")
		useBtn.Size = UDim2.new(0, 30, 0, 16)
		useBtn.Position = UDim2.new(1, -33, 0, 55)
		useBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 50)
		useBtn.Text = "USE"
		useBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		useBtn.TextSize = 9
		useBtn.Font = Enum.Font.GothamBold
		useBtn.Parent = slot

		local useBtnCorner = Instance.new("UICorner")
		useBtnCorner.CornerRadius = UDim.new(0, 4)
		useBtnCorner.Parent = useBtn

		useBtn.MouseButton1Click:Connect(function()
			local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
			if Remotes then
				Remotes.UseItem:FireServer(itemId)
			end
		end)
	end
end

function InventoryUI.updateInventory(inventory: { [string]: number })
	currentInventory = inventory
	if isOpen then
		InventoryUI.refresh()
	end
end

return InventoryUI
