--[[
	InputHandler.luau
	Client-side input handling for 99 Storms.
	Manages keybinds, interaction prompts, and mobile controls.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local InputHandler = {}

-- Keybinds
local KEYBINDS = {
	interact = Enum.KeyCode.E,
	inventory = Enum.KeyCode.Tab,
	craft = Enum.KeyCode.C,
	map = Enum.KeyCode.M,
	photoMode = Enum.KeyCode.P,
	flashlight = Enum.KeyCode.F,
	sprint = Enum.KeyCode.LeftShift,
	emoteWheel = Enum.KeyCode.T,
	signalFlare = Enum.KeyCode.G,
	whistle = Enum.KeyCode.V,
}

-- State
local isSprinting = false
local currentInteractable = nil
local isInventoryOpen = false
local isCraftMenuOpen = false
local isMapOpen = false

-- ================================
-- INITIALIZATION
-- ================================

function InputHandler.init()
	-- Key press handling
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		InputHandler._onKeyDown(input)
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		InputHandler._onKeyUp(input)
	end)

	-- Mobile touch controls
	if UserInputService.TouchEnabled then
		InputHandler._setupMobileControls()
	end
end

-- ================================
-- KEY HANDLERS
-- ================================

function InputHandler._onKeyDown(input: InputObject)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	local key = input.KeyCode

	if key == KEYBINDS.interact then
		InputHandler._interact()
	elseif key == KEYBINDS.inventory then
		InputHandler._toggleInventory()
	elseif key == KEYBINDS.craft then
		InputHandler._toggleCraftMenu()
	elseif key == KEYBINDS.map then
		InputHandler._toggleMap()
	elseif key == KEYBINDS.flashlight then
		InputHandler._toggleFlashlight()
	elseif key == KEYBINDS.sprint then
		isSprinting = true
		InputHandler._updateSprint()
	elseif key == KEYBINDS.signalFlare then
		InputHandler._useSignalFlare()
	elseif key == KEYBINDS.whistle then
		InputHandler._useWhistle()
	end
end

function InputHandler._onKeyUp(input: InputObject)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	if input.KeyCode == KEYBINDS.sprint then
		isSprinting = false
		InputHandler._updateSprint()
	end
end

-- ================================
-- ACTIONS
-- ================================

function InputHandler._interact()
	if not currentInteractable then return end

	-- Send interaction to server based on interactable type
	local interactType = currentInteractable:GetAttribute("InteractType")

	if interactType == "CraftStation" then
		local stationId = currentInteractable:GetAttribute("StationId")
		-- Open crafting UI for this station
		-- TODO: Open craft menu with station filter
	elseif interactType == "Building" then
		local buildingId = currentInteractable:GetAttribute("BuildingId")
		-- Open building interaction menu
		-- TODO: Show claim/fortify/repair options
	elseif interactType == "NPC" then
		local npcId = currentInteractable:GetAttribute("NPCId")
		-- Open NPC dialogue
		-- TODO: Show dialogue/trade UI
	elseif interactType == "Resource" then
		-- Gather resource
		-- TODO: Send gather request to server
	elseif interactType == "Tame" then
		local creatureId = currentInteractable:GetAttribute("CreatureId")
		Remotes.TameAttempt:FireServer(creatureId)
	end
end

function InputHandler._toggleInventory()
	isInventoryOpen = not isInventoryOpen
	-- TODO: Show/hide inventory UI
end

function InputHandler._toggleCraftMenu()
	isCraftMenuOpen = not isCraftMenuOpen
	-- TODO: Show/hide crafting UI
end

function InputHandler._toggleMap()
	isMapOpen = not isMapOpen
	-- TODO: Show/hide map UI
end

function InputHandler._toggleFlashlight()
	local character = player.Character
	if not character then return end

	-- TODO: Toggle flashlight tool
end

function InputHandler._updateSprint()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	if isSprinting then
		humanoid.WalkSpeed = 24 -- sprint speed
	else
		humanoid.WalkSpeed = 16 -- normal speed
	end
end

function InputHandler._useSignalFlare()
	-- TODO: Check inventory for signal flares, fire one
end

function InputHandler._useWhistle()
	-- TODO: Check for whistle in inventory, play taming interaction
end

-- ================================
-- INTERACTION DETECTION
-- ================================

function InputHandler.setInteractable(object: Instance?)
	currentInteractable = object
	-- TODO: Show/hide interaction prompt UI
end

-- ================================
-- MOBILE CONTROLS
-- ================================

function InputHandler._setupMobileControls()
	-- TODO: Create virtual buttons for mobile
	-- Interact button, inventory, craft menu, etc.
end

return InputHandler
