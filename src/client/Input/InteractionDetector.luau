--[[
	InteractionDetector.luau
	Client-side proximity interaction detector.
	Detects nearby interactable objects and shows interaction prompts.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local InteractionDetector = {}

local INTERACT_RANGE = 10 -- studs
local currentTarget = nil
local promptGui = nil
local isGathering = false

function InteractionDetector.init()
	-- Create the interaction prompt UI
	promptGui = Instance.new("BillboardGui")
	promptGui.Name = "InteractionPrompt"
	promptGui.Size = UDim2.new(0, 200, 0, 50)
	promptGui.StudsOffset = Vector3.new(0, 3, 0)
	promptGui.AlwaysOnTop = true
	promptGui.Enabled = false
	promptGui.MaxDistance = INTERACT_RANGE

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	bg.BackgroundTransparency = 0.3
	bg.BorderSizePixel = 0
	bg.Parent = promptGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = bg

	local label = Instance.new("TextLabel")
	label.Name = "PromptLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "[E] Interact"
	label.TextColor3 = Color3.fromRGB(255, 255, 100)
	label.TextSize = 14
	label.Font = Enum.Font.GothamBold
	label.Parent = bg

	-- Input listener for E key
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.E then
			InteractionDetector.interact()
		end
	end)
end

function InteractionDetector.update(deltaTime: number)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local playerPos = rootPart.Position
	local closestTarget = nil
	local closestDist = INTERACT_RANGE

	-- Scan for interactable objects
	local stormhaven = workspace:FindFirstChild("Stormhaven")
	if not stormhaven then return end

	for _, descendant in stormhaven:GetDescendants() do
		if descendant:IsA("BasePart") and descendant:GetAttribute("InteractType") then
			local dist = (descendant.Position - playerPos).Magnitude
			if dist < closestDist then
				closestDist = dist
				closestTarget = descendant
			end
		end
	end

	-- Also check creatures
	for _, model in workspace:GetChildren() do
		if model.Name:match("^Creature_") then
			local body = model:FindFirstChild("Body")
			if body then
				local dist = (body.Position - playerPos).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestTarget = body
				end
			end
		end
	end

	-- Update prompt
	if closestTarget ~= currentTarget then
		currentTarget = closestTarget
		InteractionDetector.updatePrompt()
	end
end

function InteractionDetector.updatePrompt()
	if not currentTarget then
		promptGui.Enabled = false
		if promptGui.Parent then
			promptGui.Parent = nil
		end
		return
	end

	local interactType = currentTarget:GetAttribute("InteractType")
	local label = promptGui:FindFirstChild("PromptLabel", true)

	if interactType == "CraftStation" then
		local stationId = currentTarget:GetAttribute("StationId") or "unknown"
		label.Text = "[E] Use " .. stationId
	elseif interactType == "Resource" then
		local nodeType = currentTarget:GetAttribute("NodeType") or "resource"
		label.Text = "[E] Gather " .. nodeType
	elseif interactType == "Building" then
		local buildingId = currentTarget:GetAttribute("BuildingId") or "building"
		if currentTarget:GetAttribute("Claimable") then
			label.Text = "[E] Claim " .. buildingId
		elseif currentTarget:GetAttribute("RestorableBuilding") then
			label.Text = "[E] Restore " .. buildingId
		else
			label.Text = "[E] Inspect " .. buildingId
		end
	elseif interactType == "NPC" then
		local npcId = currentTarget:GetAttribute("NPCId") or "NPC"
		label.Text = "[E] Talk to " .. npcId
	elseif interactType == "Creature" then
		label.Text = "[Left Click] Attack"
	elseif interactType == "Campfire" then
		label.Text = "[E] Sit by campfire"
	else
		label.Text = "[E] Interact"
	end

	promptGui.Parent = currentTarget
	promptGui.Enabled = true
end

function InteractionDetector.interact()
	if not currentTarget then return end

	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	local interactType = currentTarget:GetAttribute("InteractType")

	if interactType == "CraftStation" then
		local stationId = currentTarget:GetAttribute("StationId")
		-- Request inventory from server, then open crafting UI
		Remotes.OpenCraftStation:FireServer(stationId)

	elseif interactType == "Resource" then
		local nodeId = currentTarget:GetAttribute("NodeId")
		if nodeId then
			Remotes.GatherResource:FireServer(nodeId)
		end

	elseif interactType == "Building" then
		local buildingId = currentTarget:GetAttribute("BuildingId")
		if currentTarget:GetAttribute("Claimable") then
			Remotes.ClaimBuilding:FireServer(buildingId)
		elseif currentTarget:GetAttribute("RestorableBuilding") then
			Remotes.RestoreBuilding:FireServer(buildingId)
		end

	elseif interactType == "NPC" then
		local npcId = currentTarget:GetAttribute("NPCId")
		Remotes.TalkToNPC:FireServer(npcId)

	elseif interactType == "Creature" then
		local creatureId = currentTarget:GetAttribute("CreatureId")
		if creatureId then
			Remotes.AttackCreature:FireServer(creatureId)
		end

	elseif interactType == "Campfire" then
		-- Morale boost
		Remotes.UseCampfire:FireServer()
	end
end

function InteractionDetector.getCurrentTarget()
	return currentTarget
end

return InteractionDetector
