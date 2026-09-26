local WeaponHUDController = {}

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local context = nil
local hudGui = nil
local ammoLabel = nil
local reserveLabel = nil
local statusLabel = nil
local weaponNameLabel = nil

local crosshairGui = nil
local crosshairParts = {}
local currentCrosshairGap = 7

local function getHumanoid()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function createWeaponHud()
	local playerGui = player:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("USARFWeaponHUD")
	if old then
		old:Destroy()
	end

	hudGui = Instance.new("ScreenGui")
	hudGui.Name = "USARFWeaponHUD"
	hudGui.IgnoreGuiInset = true
	hudGui.ResetOnSpawn = false
	hudGui.DisplayOrder = 999998
	hudGui.Enabled = true
	hudGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -92)
	panel.Size = UDim2.new(0, 235, 0, 108)
	panel.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Parent = hudGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 80, 95)
	stroke.Transparency = 0.25
	stroke.Thickness = 1
	stroke.Parent = panel

	weaponNameLabel = Instance.new("TextLabel")
	weaponNameLabel.BackgroundTransparency = 1
	weaponNameLabel.Position = UDim2.new(0, 16, 0, 12)
	weaponNameLabel.Size = UDim2.new(1, -32, 0, 22)
	weaponNameLabel.Font = Enum.Font.GothamBold
	weaponNameLabel.TextSize = 15
	weaponNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	weaponNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	weaponNameLabel.Parent = panel

	ammoLabel = Instance.new("TextLabel")
	ammoLabel.BackgroundTransparency = 1
	ammoLabel.Position = UDim2.new(0, 16, 0, 40)
	ammoLabel.Size = UDim2.new(0, 90, 0, 38)
	ammoLabel.Font = Enum.Font.GothamBold
	ammoLabel.TextSize = 34
	ammoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	ammoLabel.TextXAlignment = Enum.TextXAlignment.Left
	ammoLabel.Parent = panel

	reserveLabel = Instance.new("TextLabel")
	reserveLabel.BackgroundTransparency = 1
	reserveLabel.Position = UDim2.new(0, 108, 0, 49)
	reserveLabel.Size = UDim2.new(0, 110, 0, 24)
	reserveLabel.Font = Enum.Font.GothamBold
	reserveLabel.TextSize = 18
	reserveLabel.TextColor3 = Color3.fromRGB(185, 185, 195)
	reserveLabel.TextXAlignment = Enum.TextXAlignment.Left
	reserveLabel.Parent = panel

	statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundTransparency = 1
	statusLabel.Position = UDim2.new(0, 16, 1, -28)
	statusLabel.Size = UDim2.new(1, -32, 0, 18)
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 12
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Parent = panel
end

local function createCrosshair()
	local playerGui = player:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("USARFWeaponCrosshair")
	if old then
		old:Destroy()
	end

	crosshairGui = Instance.new("ScreenGui")
	crosshairGui.Name = "USARFWeaponCrosshair"
	crosshairGui.IgnoreGuiInset = true
	crosshairGui.ResetOnSpawn = false
	crosshairGui.DisplayOrder = 999997
	crosshairGui.Enabled = true
	crosshairGui.Parent = playerGui

	local center = Instance.new("Frame")
	center.Name = "Center"
	center.AnchorPoint = Vector2.new(0.5, 0.5)
	center.Position = UDim2.fromScale(0.5, 0.5)
	center.Size = UDim2.fromOffset(1, 1)
	center.BackgroundTransparency = 1
	center.Parent = crosshairGui

	local crosshairConfig = context.Config.Crosshair or {}
	local thickness = crosshairConfig.Thickness or 2
	local length = crosshairConfig.Length or 8

	local function makeLine(name)
		local line = Instance.new("Frame")
		line.Name = name
		line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		line.BorderSizePixel = 0
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Parent = center

		return line
	end

	crosshairParts.Top = makeLine("Top")
	crosshairParts.Bottom = makeLine("Bottom")
	crosshairParts.Left = makeLine("Left")
	crosshairParts.Right = makeLine("Right")

	crosshairParts.Top.Size = UDim2.fromOffset(thickness, length)
	crosshairParts.Bottom.Size = UDim2.fromOffset(thickness, length)
	crosshairParts.Left.Size = UDim2.fromOffset(length, thickness)
	crosshairParts.Right.Size = UDim2.fromOffset(length, thickness)

	if crosshairConfig.Dot ~= false then
		local dot = Instance.new("Frame")
		dot.Name = "Dot"
		dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		dot.BorderSizePixel = 0
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromOffset(0, 0)
		dot.Size = UDim2.fromOffset(3, 3)
		dot.Parent = center

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = dot

		crosshairParts.Dot = dot
	end
end

function WeaponHUDController.Update()
	if not context or not hudGui then
		return
	end

	local state = context.State
	local config = context.Config

	hudGui.Enabled = state.Equipped

	if weaponNameLabel then
		weaponNameLabel.Text = config.Name or context.Tool.Name
	end

	if ammoLabel then
		ammoLabel.Text = tostring(context.Ammo)
		ammoLabel.TextColor3 = context.Ammo <= 0 and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(255, 255, 255)
	end

	if reserveLabel then
		reserveLabel.Text = "/ " .. tostring(context.Reserve)
	end

	if statusLabel then
		if state.Reloading then
			statusLabel.Text = "RELOADING..."
			statusLabel.TextColor3 = Color3.fromRGB(255, 190, 80)
		elseif context.Ammo <= 0 then
			statusLabel.Text = "EMPTY - PRESS R"
			statusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
		elseif state.Aiming then
			statusLabel.Text = "AIMING"
			statusLabel.TextColor3 = Color3.fromRGB(108, 190, 255)
		else
			statusLabel.Text = context.CurrentFireMode or "SEMI"
			statusLabel.TextColor3 = Color3.fromRGB(108, 211, 126)
		end
	end
end

local function getTargetCrosshairGap()
	local state = context.State
	local crosshairConfig = context.Config.Crosshair or {}

	if state.Reloading or state.Sprinting then
		return crosshairConfig.SprintingGap or 26
	end

	if state.Aiming then
		return 2
	end

	if state.Crouching then
		return crosshairConfig.CrouchingGap or 5
	end

	if state.Firing then
		return crosshairConfig.FiringGap or 18
	end

	local humanoid = getHumanoid()
	if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
		return crosshairConfig.MovingGap or 12
	end

	return crosshairConfig.BaseGap or 7
end

function WeaponHUDController.RenderStep(deltaTime)
	if not context or not crosshairGui then
		return
	end

	local state = context.State
	local crosshairConfig = context.Config.Crosshair or {}

	crosshairGui.Enabled = state.Equipped and crosshairConfig.Enabled ~= false

	if not crosshairGui.Enabled then
		return
	end

	local targetGap = getTargetCrosshairGap()
	currentCrosshairGap += (targetGap - currentCrosshairGap) * math.clamp(deltaTime * 16, 0, 1)

	local gap = currentCrosshairGap
	local length = crosshairConfig.Length or 8

	if crosshairParts.Top then
		crosshairParts.Top.Position = UDim2.fromOffset(0, -gap - length / 2)
	end

	if crosshairParts.Bottom then
		crosshairParts.Bottom.Position = UDim2.fromOffset(0, gap + length / 2)
	end

	if crosshairParts.Left then
		crosshairParts.Left.Position = UDim2.fromOffset(-gap - length / 2, 0)
	end

	if crosshairParts.Right then
		crosshairParts.Right.Position = UDim2.fromOffset(gap + length / 2, 0)
	end
end

function WeaponHUDController.ShowHitmarker(payload)
	payload = payload or {}

	local hitPosition = payload.HitPosition
	if typeof(hitPosition) ~= "Vector3" then
		return
	end

	local markerPart = Instance.new("Part")
	markerPart.Name = "USARF_WorldHitmarker"
	markerPart.Anchored = true
	markerPart.CanCollide = false
	markerPart.CanTouch = false
	markerPart.CanQuery = false
	markerPart.Transparency = 1
	markerPart.Size = Vector3.new(0.2, 0.2, 0.2)
	markerPart.CFrame = CFrame.new(hitPosition)
	markerPart.Parent = workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Adornee = markerPart
	billboard.Size = UDim2.new(0, 80, 0, 80)
	billboard.AlwaysOnTop = true
	billboard.StudsOffset = Vector3.new(0, 0.25, 0)
	billboard.Parent = markerPart

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = payload.Headshot and 34 or 30
	label.TextColor3 = payload.Headshot and Color3.fromRGB(255, 210, 90) or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.2
	label.Text = payload.Headshot and "✦" or "X"
	label.Parent = billboard

	task.spawn(function()
		for i = 1, 14 do
			if not markerPart.Parent then
				return
			end

			billboard.StudsOffset += Vector3.new(0, 0.025, 0)
			label.TextTransparency = i / 14
			label.TextStrokeTransparency = 0.2 + (i / 14)
			task.wait(0.02)
		end

		if markerPart then
			markerPart:Destroy()
		end
	end)
end

function WeaponHUDController.Start(newContext)
	context = newContext

	createWeaponHud()
	createCrosshair()
	WeaponHUDController.Update()
end

function WeaponHUDController.Stop()
	if hudGui then
		hudGui.Enabled = false
	end

	if crosshairGui then
		crosshairGui.Enabled = false
	end
end

return WeaponHUDController