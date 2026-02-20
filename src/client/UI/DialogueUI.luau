--[[
	DialogueUI.luau
	Client-side NPC dialogue and trading interface for 99 Storms.
	Shows dialogue text with typewriter effect and trade options.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DialogueUI = {}

local screenGui = nil
local dialogueFrame = nil
local nameLabel = nil
local textLabel = nil
local tradePanel = nil
local isOpen = false
local currentNPCId = nil
local typewriterThread = nil

-- ================================
-- INITIALIZATION
-- ================================

function DialogueUI.init()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DialogueUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Dialogue frame at bottom of screen
	dialogueFrame = Instance.new("Frame")
	dialogueFrame.Name = "DialogueFrame"
	dialogueFrame.Size = UDim2.new(0.6, 0, 0, 140)
	dialogueFrame.Position = UDim2.new(0.2, 0, 1, -160)
	dialogueFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	dialogueFrame.BackgroundTransparency = 0.1
	dialogueFrame.BorderSizePixel = 0
	dialogueFrame.Parent = screenGui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 12)
	frameCorner.Parent = dialogueFrame

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Color = Color3.fromRGB(80, 100, 140)
	frameStroke.Thickness = 2
	frameStroke.Parent = dialogueFrame

	-- NPC name
	nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NPCName"
	nameLabel.Size = UDim2.new(0.5, 0, 0, 28)
	nameLabel.Position = UDim2.new(0, 15, 0, 8)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "NPC Name"
	nameLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	nameLabel.TextSize = 18
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = dialogueFrame

	-- Dialogue text
	textLabel = Instance.new("TextLabel")
	textLabel.Name = "DialogueText"
	textLabel.Size = UDim2.new(1, -30, 0, 70)
	textLabel.Position = UDim2.new(0, 15, 0, 38)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = ""
	textLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
	textLabel.TextSize = 15
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.Parent = dialogueFrame

	-- Close hint
	local closeHint = Instance.new("TextLabel")
	closeHint.Name = "CloseHint"
	closeHint.Size = UDim2.new(1, -20, 0, 20)
	closeHint.Position = UDim2.new(0, 10, 1, -25)
	closeHint.BackgroundTransparency = 1
	closeHint.Text = "[E] Continue  |  [C] Close"
	closeHint.TextColor3 = Color3.fromRGB(120, 130, 150)
	closeHint.TextSize = 12
	closeHint.Font = Enum.Font.Gotham
	closeHint.Parent = dialogueFrame

	-- Trade panel (right side, hidden by default)
	tradePanel = Instance.new("Frame")
	tradePanel.Name = "TradePanel"
	tradePanel.Size = UDim2.new(0, 250, 0, 300)
	tradePanel.Position = UDim2.new(1, 10, 1, -320)
	tradePanel.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	tradePanel.BackgroundTransparency = 0.1
	tradePanel.BorderSizePixel = 0
	tradePanel.Visible = false
	tradePanel.Parent = dialogueFrame

	local tradePanelCorner = Instance.new("UICorner")
	tradePanelCorner.CornerRadius = UDim.new(0, 10)
	tradePanelCorner.Parent = tradePanel

	local tradePanelStroke = Instance.new("UIStroke")
	tradePanelStroke.Color = Color3.fromRGB(80, 100, 140)
	tradePanelStroke.Thickness = 2
	tradePanelStroke.Parent = tradePanel

	local tradeTitle = Instance.new("TextLabel")
	tradeTitle.Name = "TradeTitle"
	tradeTitle.Size = UDim2.new(1, 0, 0, 30)
	tradeTitle.BackgroundTransparency = 1
	tradeTitle.Text = "TRADES"
	tradeTitle.TextColor3 = Color3.fromRGB(220, 230, 255)
	tradeTitle.TextSize = 16
	tradeTitle.Font = Enum.Font.GothamBold
	tradeTitle.Parent = tradePanel

	local tradeList = Instance.new("ScrollingFrame")
	tradeList.Name = "TradeList"
	tradeList.Size = UDim2.new(1, -10, 1, -35)
	tradeList.Position = UDim2.new(0, 5, 0, 30)
	tradeList.BackgroundTransparency = 1
	tradeList.BorderSizePixel = 0
	tradeList.ScrollBarThickness = 3
	tradeList.CanvasSize = UDim2.new(0, 0, 0, 0)
	tradeList.Parent = tradePanel

	local tradeLayout = Instance.new("UIListLayout")
	tradeLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tradeLayout.Padding = UDim.new(0, 4)
	tradeLayout.Parent = tradeList
end

-- ================================
-- TYPEWRITER EFFECT
-- ================================

local function typewrite(text, speed)
	speed = speed or 0.03

	if typewriterThread then
		task.cancel(typewriterThread)
	end

	textLabel.Text = ""

	typewriterThread = task.spawn(function()
		for i = 1, #text do
			if not isOpen then break end
			textLabel.Text = string.sub(text, 1, i)
			task.wait(speed)
		end
		typewriterThread = nil
	end)
end

-- ================================
-- OPEN / CLOSE
-- ================================

function DialogueUI.open(npcId: string, npcName: string, dialogueText: string, trades: any?)
	currentNPCId = npcId
	isOpen = true

	nameLabel.Text = npcName or npcId
	typewrite(dialogueText or "...")

	-- Show trades if available
	if trades and #trades > 0 then
		DialogueUI._populateTrades(trades)
		tradePanel.Visible = true
	else
		tradePanel.Visible = false
	end

	screenGui.Enabled = true

	-- Slide in animation
	dialogueFrame.Position = UDim2.new(0.2, 0, 1, 20)
	local tween = TweenService:Create(dialogueFrame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.2, 0, 1, -160) })
	tween:Play()
end

function DialogueUI.close()
	if not isOpen then return end

	isOpen = false
	currentNPCId = nil

	if typewriterThread then
		task.cancel(typewriterThread)
		typewriterThread = nil
	end

	-- Slide out animation
	local tween = TweenService:Create(dialogueFrame,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.2, 0, 1, 20) })
	tween:Play()
	tween.Completed:Wait()

	screenGui.Enabled = false
end

function DialogueUI.isOpen(): boolean
	return isOpen
end

-- ================================
-- TRADES
-- ================================

function DialogueUI._populateTrades(trades)
	local tradeList = tradePanel:FindFirstChild("TradeList")
	if not tradeList then return end

	-- Clear existing
	for _, child in tradeList:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for i, trade in trades do
		local btn = Instance.new("TextButton")
		btn.Name = trade.id or ("trade_" .. i)
		btn.Size = UDim2.new(1, -6, 0, 50)
		btn.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.LayoutOrder = i
		btn.Parent = tradeList

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn

		-- Trade name
		local tradeName = Instance.new("TextLabel")
		tradeName.Size = UDim2.new(1, -8, 0, 20)
		tradeName.Position = UDim2.new(0, 4, 0, 2)
		tradeName.BackgroundTransparency = 1
		tradeName.Text = trade.name or trade.id
		tradeName.TextColor3 = Color3.fromRGB(200, 220, 255)
		tradeName.TextSize = 13
		tradeName.Font = Enum.Font.GothamBold
		tradeName.TextXAlignment = Enum.TextXAlignment.Left
		tradeName.Parent = btn

		-- Cost display
		local costText = ""
		if trade.give then
			for _, item in trade.give do
				costText = costText .. item.count .. "x " .. item.item .. " "
			end
		end

		local costLabel = Instance.new("TextLabel")
		costLabel.Size = UDim2.new(1, -8, 0, 14)
		costLabel.Position = UDim2.new(0, 4, 0, 22)
		costLabel.BackgroundTransparency = 1
		costLabel.Text = "Cost: " .. costText
		costLabel.TextColor3 = Color3.fromRGB(200, 120, 120)
		costLabel.TextSize = 11
		costLabel.Font = Enum.Font.Gotham
		costLabel.TextXAlignment = Enum.TextXAlignment.Left
		costLabel.Parent = btn

		-- Stock display
		local stockText = trade.stock == -1 and "Unlimited" or ("Stock: " .. trade.stock)
		local stockLabel = Instance.new("TextLabel")
		stockLabel.Size = UDim2.new(1, -8, 0, 14)
		stockLabel.Position = UDim2.new(0, 4, 0, 36)
		stockLabel.BackgroundTransparency = 1
		stockLabel.Text = stockText
		stockLabel.TextColor3 = Color3.fromRGB(120, 150, 120)
		stockLabel.TextSize = 10
		stockLabel.Font = Enum.Font.Gotham
		stockLabel.TextXAlignment = Enum.TextXAlignment.Left
		stockLabel.Parent = btn

		-- Click handler
		btn.MouseButton1Click:Connect(function()
			local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
			if Remotes and currentNPCId then
				Remotes.TradeWithNPC:FireServer(currentNPCId, trade.id)
			end
		end)
	end

	-- Update canvas size
	local layout = tradeList:FindFirstChildOfClass("UIListLayout")
	if layout then
		tradeList.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
	end
end

return DialogueUI
