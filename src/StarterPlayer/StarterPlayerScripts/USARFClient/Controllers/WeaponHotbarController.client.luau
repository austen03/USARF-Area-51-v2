local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Teams = game:GetService("Teams")

local player = Players.LocalPlayer

local MAX_SLOTS = 5

local HIDDEN_TEAM_NAMES = {
	["Loading"] = true,
	["LOADING"] = true,
	["Main Menu"] = true,
	["MainMenu"] = true,
	["Menu"] = true,
}

local SLOT_KEYS = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
}

local slotOrder = {}
local slotButtons = {}
local selectedSlot = nil

local gui = nil
local container = nil

local function hideDefaultBackpack()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
end

local function shouldShowHotbar()
	if player:GetAttribute("USARF_InMenu") == true then
		return false
	end

	if player:GetAttribute("USARF_LoadingComplete") ~= true then
		return false
	end

	if player.Team and HIDDEN_TEAM_NAMES[player.Team.Name] then
		return false
	end

	return true
end

local function updateVisibility()
	if gui then
		gui.Enabled = shouldShowHotbar()
	end
end

local function getBackpack()
	return player:FindFirstChild("Backpack") or player:WaitForChild("Backpack")
end

local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function isTool(instance)
	return instance and instance:IsA("Tool")
end

local function isHotbarTool(tool)
	if not isTool(tool) then
		return false
	end

	if tool:GetAttribute("HideFromHotbar") == true then
		return false
	end

	return true
end

local function createGui()
	local playerGui = player:WaitForChild("PlayerGui")

	local old = playerGui:FindFirstChild("USARFWeaponHotbar")
	if old then
		old:Destroy()
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "USARFWeaponHotbar"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 999996
	gui.Enabled = false
	gui.Parent = playerGui

	container = Instance.new("Frame")
	container.Name = "Container"
	container.AnchorPoint = Vector2.new(0.5, 1)
	container.Position = UDim2.new(0.5, 0, 1, -14)
	container.Size = UDim2.new(0, 360, 0, 54)
	container.BackgroundTransparency = 1
	container.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = container

	for i = 1, MAX_SLOTS do
		local button = Instance.new("TextButton")
		button.Name = "Slot" .. i
		button.Size = UDim2.new(0, 62, 0, 48)
		button.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
		button.BackgroundTransparency = 0.08
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = ""
		button.Visible = false
		button.Parent = container

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = button

		local stroke = Instance.new("UIStroke")
		stroke.Name = "Stroke"
		stroke.Color = Color3.fromRGB(80, 80, 95)
		stroke.Transparency = 0.25
		stroke.Thickness = 1
		stroke.Parent = button

		local number = Instance.new("TextLabel")
		number.Name = "Number"
		number.BackgroundTransparency = 1
		number.Position = UDim2.new(0, 6, 0, 3)
		number.Size = UDim2.new(0, 16, 0, 14)
		number.Font = Enum.Font.GothamBold
		number.TextSize = 11
		number.TextColor3 = Color3.fromRGB(180, 180, 190)
		number.Text = tostring(i)
		number.Parent = button

		local name = Instance.new("TextLabel")
		name.Name = "Name"
		name.BackgroundTransparency = 1
		name.Position = UDim2.new(0, 6, 0, 17)
		name.Size = UDim2.new(1, -12, 0, 24)
		name.Font = Enum.Font.GothamBold
		name.TextSize = 10
		name.TextWrapped = true
		name.TextColor3 = Color3.fromRGB(255, 255, 255)
		name.Text = ""
		name.Parent = button

		button.MouseButton1Click:Connect(function()
			local tool = slotOrder[i]
			if tool then
				local humanoid = getCharacter():FindFirstChildOfClass("Humanoid")
				if humanoid then
					if selectedSlot == i then
						humanoid:UnequipTools()
					else
						humanoid:EquipTool(tool)
					end
				end
			end
		end)

		slotButtons[i] = button
	end
end

local function getAllTools()
	local tools = {}
	local seen = {}

	local backpack = getBackpack()
	local character = player.Character

	local function scan(parent)
		if not parent then
			return
		end

		for _, child in ipairs(parent:GetChildren()) do
			if isHotbarTool(child) and not seen[child] then
				seen[child] = true
				table.insert(tools, child)
			end
		end
	end

	scan(backpack)
	scan(character)

	table.sort(tools, function(a, b)
		return a.Name < b.Name
	end)

	return tools
end

local function rebuildSlots()
	local existing = {}

	for _, tool in ipairs(slotOrder) do
		if tool and tool.Parent and isHotbarTool(tool) then
			table.insert(existing, tool)
		end
	end

	for _, tool in ipairs(getAllTools()) do
		local alreadyAdded = false

		for _, existingTool in ipairs(existing) do
			if existingTool == tool then
				alreadyAdded = true
				break
			end
		end

		if not alreadyAdded then
			table.insert(existing, tool)
		end
	end

	slotOrder = {}

	for i = 1, MAX_SLOTS do
		slotOrder[i] = existing[i]
	end
end

local function updateSelectedSlot()
	selectedSlot = nil

	local character = player.Character
	if not character then
		return
	end

	for i, tool in ipairs(slotOrder) do
		if tool and tool.Parent == character then
			selectedSlot = i
			return
		end
	end
end

local function updateGui()
	if not gui then
		return
	end

	updateVisibility()

	rebuildSlots()
	updateSelectedSlot()

	for i = 1, MAX_SLOTS do
		local button = slotButtons[i]
		local tool = slotOrder[i]

		if button then
			local nameLabel = button:FindFirstChild("Name")
			local stroke = button:FindFirstChild("Stroke")

			button.Visible = true

			if nameLabel then
				nameLabel.Text = tool and tool.Name or ""
			end

			if stroke then
				if selectedSlot == i then
					stroke.Color = Color3.fromRGB(108, 99, 255)
					stroke.Transparency = 0
					stroke.Thickness = 2
				else
					stroke.Color = Color3.fromRGB(80, 80, 95)
					stroke.Transparency = 0.25
					stroke.Thickness = 1
				end
			end

			button.BackgroundTransparency = selectedSlot == i and 0 or 0.08
		end
	end
end

local function equipSlot(slot)
	if not shouldShowHotbar() then
		return
	end

	local tool = slotOrder[slot]
	if not tool then
		return
	end

	local humanoid = getCharacter():FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if selectedSlot == slot then
		humanoid:UnequipTools()
	else
		humanoid:EquipTool(tool)
	end

	task.defer(updateGui)
end

local function connectRefreshSignals()
	local function connectCharacter(character)
		character.ChildAdded:Connect(function()
			task.defer(updateGui)
		end)

		character.ChildRemoved:Connect(function()
			task.defer(updateGui)
		end)

		task.defer(updateGui)
	end

	local backpack = getBackpack()

	backpack.ChildAdded:Connect(function()
		task.defer(updateGui)
	end)

	backpack.ChildRemoved:Connect(function()
		task.defer(updateGui)
	end)

	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		connectCharacter(character)
	end)

	player:GetPropertyChangedSignal("Team"):Connect(function()
		task.defer(updateGui)
	end)

	player:GetAttributeChangedSignal("USARF_InMenu"):Connect(function()
		task.defer(updateGui)
	end)

	player:GetAttributeChangedSignal("USARF_LoadingComplete"):Connect(function()
		task.defer(updateGui)
	end)

	if player.Character then
		connectCharacter(player.Character)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	local slot = SLOT_KEYS[input.KeyCode]
	if slot then
		equipSlot(slot)
	end
end)

hideDefaultBackpack()
createGui()
connectRefreshSignals()
updateGui()

task.spawn(function()
	while true do
		hideDefaultBackpack()
		updateGui()
		task.wait(0.4)
	end
end)

print("[WeaponHotbarController] Loaded")