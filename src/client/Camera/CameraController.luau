--[[
	CameraController.luau
	Client-side camera system for 99 Storms.
	Handles screen shake, storm camera effects, and photo mode.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CameraController = {}

-- Internal state
local camera = workspace.CurrentCamera
local isStormMode = false
local shakeIntensity = 0
local shakeDuration = 0
local shakeTimer = 0
local windSway = Vector3.new(0, 0, 0)
local isPhotoMode = false
local originalCameraType = nil

-- ================================
-- INITIALIZATION
-- ================================

function CameraController.init()
	camera = workspace.CurrentCamera

	-- Listen for photo mode toggle (P key)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.P then
			CameraController.togglePhotoMode()
		end
	end)
end

-- ================================
-- SCREEN SHAKE
-- ================================

function CameraController.screenShake(duration: number, intensity: number)
	shakeDuration = duration
	shakeIntensity = intensity
	shakeTimer = 0
end

local function applyScreenShake(deltaTime: number): CFrame
	if shakeDuration <= 0 then
		return CFrame.new()
	end

	shakeTimer += deltaTime

	if shakeTimer >= shakeDuration then
		shakeDuration = 0
		shakeIntensity = 0
		shakeTimer = 0
		return CFrame.new()
	end

	-- Decay over time
	local progress = shakeTimer / shakeDuration
	local currentIntensity = shakeIntensity * (1 - progress)

	local offsetX = (math.random() - 0.5) * 2 * currentIntensity * 0.01
	local offsetY = (math.random() - 0.5) * 2 * currentIntensity * 0.01
	local rotation = (math.random() - 0.5) * currentIntensity * 0.002

	return CFrame.new(offsetX, offsetY, 0) * CFrame.Angles(0, 0, rotation)
end

-- ================================
-- STORM CAMERA EFFECTS
-- ================================

function CameraController.setStormMode(enabled: boolean)
	isStormMode = enabled

	if not enabled then
		windSway = Vector3.new(0, 0, 0)
	end
end

local function applyStormEffects(deltaTime: number): CFrame
	if not isStormMode then
		return CFrame.new()
	end

	-- Gentle swaying during storms
	local time = tick()
	local swayX = math.sin(time * 0.5) * 0.002
	local swayY = math.sin(time * 0.3) * 0.001

	return CFrame.Angles(swayX, swayY, 0)
end

-- ================================
-- PHOTO MODE
-- ================================

function CameraController.togglePhotoMode()
	isPhotoMode = not isPhotoMode

	if isPhotoMode then
		-- Store original camera type and switch to scriptable
		originalCameraType = camera.CameraType
		camera.CameraType = Enum.CameraType.Scriptable

		-- TODO: Show photo mode UI (filters, frames, controls)
		-- TODO: Hide game HUD
	else
		-- Restore original camera
		if originalCameraType then
			camera.CameraType = originalCameraType
		else
			camera.CameraType = Enum.CameraType.Custom
		end

		-- TODO: Hide photo mode UI
		-- TODO: Show game HUD
	end
end

-- ================================
-- UPDATE LOOP
-- ================================

function CameraController.update(deltaTime: number)
	if isPhotoMode then
		-- Photo mode camera controls
		CameraController._updatePhotoMode(deltaTime)
		return
	end

	-- Apply camera effects
	local shakeCF = applyScreenShake(deltaTime)
	local stormCF = applyStormEffects(deltaTime)

	-- Apply combined offset to camera
	-- Note: This modifies the camera CFrame additively
	if shakeCF ~= CFrame.new() or stormCF ~= CFrame.new() then
		camera.CFrame = camera.CFrame * shakeCF * stormCF
	end
end

function CameraController._updatePhotoMode(deltaTime: number)
	-- Free camera controls for photo mode
	local moveSpeed = 20 * deltaTime

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		camera.CFrame = camera.CFrame * CFrame.new(0, 0, -moveSpeed)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		camera.CFrame = camera.CFrame * CFrame.new(0, 0, moveSpeed)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		camera.CFrame = camera.CFrame * CFrame.new(-moveSpeed, 0, 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		camera.CFrame = camera.CFrame * CFrame.new(moveSpeed, 0, 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.E) then
		camera.CFrame = camera.CFrame * CFrame.new(0, moveSpeed, 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
		camera.CFrame = camera.CFrame * CFrame.new(0, -moveSpeed, 0)
	end
end

return CameraController
