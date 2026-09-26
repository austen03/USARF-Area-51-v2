local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local GetBlackMarketInventory = Remotes:WaitForChild("GetBlackMarketInventory")
local EquipLoadoutItem = Remotes:WaitForChild("EquipLoadoutItem")
local UnequipLoadoutItem = Remotes:WaitForChild("UnequipLoadoutItem")
local ClearServerLifeLoadout = Remotes:WaitForChild("ClearServerLifeLoadout")
local ApplyLoadoutNow = Remotes:WaitForChild("ApplyLoadoutNow")

local PROMPT_NAME = "USARF_BlackMarketPrompt"

local SLOT_ORDER = {
	Primary = 1,
	Secondary = 2,
	Equipment = 3,
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BlackMarketUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 65
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local uiScale = Instance.new("UIScale")
uiScale.Parent = screenGui

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.fromOffset(650, 475)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(90, 90, 100)
stroke.Transparency = 0.15
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(18, 12)
title.Size = UDim2.new(1, -70, 0, 32)
title.Font = Enum.Font.GothamBold
title.Text = "BLACK MARKET"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(18, 44)
subtitle.Size = UDim2.new(1, -70, 0, 22)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "Equip one-life purchases now or save them for your next life."
subtitle.TextColor3 = Color3.fromRGB(180, 180, 185)
subtitle.TextSize = 13
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = frame

local closeButton = Instance.new("TextButton")
closeButton.Position = UDim2.new(1, -46, 0, 12)
closeButton.Size = UDim2.fromOffset(32, 32)
closeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 14
closeButton.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local loadoutBox = Instance.new("Frame")
loadoutBox.Position = UDim2.fromOffset(18, 76)
loadoutBox.Size = UDim2.new(1, -36, 0, 76)
loadoutBox.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
loadoutBox.BorderSizePixel = 0
loadoutBox.Parent = frame

local loadoutCorner = Instance.new("UICorner")
loadoutCorner.CornerRadius = UDim.new(0, 10)
loadoutCorner.Parent = loadoutBox

local loadoutLabel = Instance.new("TextLabel")
loadoutLabel.BackgroundTransparency = 1
loadoutLabel.Position = UDim2.fromOffset(12, 8)
loadoutLabel.Size = UDim2.new(1, -270, 1, -16)
loadoutLabel.Font = Enum.Font.GothamBold
loadoutLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
loadoutLabel.TextSize = 12
loadoutLabel.TextXAlignment = Enum.TextXAlignment.Left
loadoutLabel.TextYAlignment = Enum.TextYAlignment.Top
loadoutLabel.TextWrapped = true
loadoutLabel.Parent = loadoutBox

local applyButton = Instance.new("TextButton")
applyButton.Position = UDim2.new(1, -244, 1, -32)
applyButton.Size = UDim2.fromOffset(110, 24)
applyButton.BackgroundColor3 = Color3.fromRGB(45, 90, 55)
applyButton.BorderSizePixel = 0
applyButton.Font = Enum.Font.GothamBold
applyButton.Text = "APPLY SAVED"
applyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
applyButton.TextSize = 10
applyButton.Parent = loadoutBox

local applyCorner = Instance.new("UICorner")
applyCorner.CornerRadius = UDim.new(0, 7)
applyCorner.Parent = applyButton

local clearLifeButton = Instance.new("TextButton")
clearLifeButton.Position = UDim2.new(1, -124, 1, -32)
clearLifeButton.Size = UDim2.fromOffset(110, 24)
clearLifeButton.BackgroundColor3 = Color3.fromRGB(90, 55, 45)
clearLifeButton.BorderSizePixel = 0
clearLifeButton.Font = Enum.Font.GothamBold
clearLifeButton.Text = "CLEAR NEXT LIFE"
clearLifeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
clearLifeButton.TextSize = 9
clearLifeButton.Parent = loadoutBox

local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 7)
clearCorner.Parent = clearLifeButton

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(18, 164)
list.Size = UDim2.new(1, -36, 1, -208)
list.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.fromOffset(0, 0)
list.Parent = frame

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 10)
listCorner.Parent = list

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = list

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 18, 1, -34)
statusLabel.Size = UDim2.new(1, -36, 0, 22)
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
statusLabel.Parent = frame

local payload = nil
local refreshing = false

local function getScale()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)

	return math.clamp(math.min(viewport.X / 1920, viewport.Y / 1080), 0.72, 1.1)
end

local function applyScale()
	uiScale.Scale = getScale()
end

local function setButtonEnabled(button, enabled)
	button.Active = enabled
	button.Selectable = enabled
	button.AutoButtonColor = enabled
	button.TextTransparency = enabled and 0 or 0.35
	button.BackgroundTransparency = enabled and 0 or 0.25
end

local function clearList()
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function formatEquipment(equipment)
	local parts = {}

	if typeof(equipment) == "table" then
		for itemId, enabled in pairs(equipment) do
			if enabled == true then
				table.insert(parts, tostring(itemId))
			end
		end
	end

	table.sort(parts)

	return #parts > 0 and table.concat(parts, ", ") or "None"
end

local function updateLoadoutText()
	if not payload then
		loadoutLabel.Text = "No inventory loaded."
		return
	end

	local loadout = payload.Loadout or {}
	local life = payload.ServerLifeLoadout or {}

	loadoutLabel.Text =
		"Saved | Primary: " .. tostring(loadout.Primary or "None")
		.. " | Secondary: " .. tostring(loadout.Secondary or "None")
		.. " | Equipment: " .. formatEquipment(loadout.Equipment)
		.. "\nNext Life | Primary: " .. tostring(life.Primary or "None")
		.. " | Secondary: " .. tostring(life.Secondary or "None")
		.. " | Equipment: " .. formatEquipment(life.Equipment)
end

local function updateCanvas()
	task.defer(function()
		task.wait()
		list.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 24)
	end)
end

local function invoke(remote, ...)
	local arguments = table.pack(...)

	local success, response = pcall(function()
		return remote:InvokeServer(table.unpack(arguments, 1, arguments.n))
	end)

	if not success then
		warn("[BlackMarketController] Remote failed:", response)

		return false, {
			Success = false,
			Message = "The Black Market server did not respond.",
		}
	end

	if typeof(response) ~= "table" then
		return false, {
			Success = false,
			Message = "The Black Market returned an invalid response.",
		}
	end

	return response.Success == true, response
end

local function createEmptyLabel(text)
	local empty = Instance.new("TextLabel")
	empty.BackgroundTransparency = 1
	empty.Size = UDim2.new(1, -4, 0, 80)
	empty.Font = Enum.Font.Gotham
	empty.Text = text
	empty.TextColor3 = Color3.fromRGB(160, 160, 165)
	empty.TextSize = 14
	empty.Parent = list
end

local refresh

local function makeButton(parent, position, text, color)
	local button = Instance.new("TextButton")
	button.Position = position
	button.Size = UDim2.fromOffset(100, 28)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 10
	button.Parent = parent

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 7)
	buttonCorner.Parent = button

	return button
end

local function createItemCard(item)
	local slot = tostring(item.LoadoutSlot or "Equipment")
	local oneLife = item.IsLifeItem == true and item.Owned ~= true

	local card = Instance.new("Frame")
	card.Name = tostring(item.Id or "UnknownItem")
	card.Size = UDim2.new(1, -4, 0, 92)
	card.BackgroundColor3 = Color3.fromRGB(25, 25, 31)
	card.BorderSizePixel = 0
	card.Parent = list

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(55, 55, 65)
	cardStroke.Transparency = 0.25
	cardStroke.Parent = card

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(14, 8)
	nameLabel.Size = UDim2.new(1, -250, 0, 22)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = tostring(item.Name or item.Id)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 15
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local description = Instance.new("TextLabel")
	description.BackgroundTransparency = 1
	description.Position = UDim2.fromOffset(14, 32)
	description.Size = UDim2.new(1, -250, 0, 18)
	description.Font = Enum.Font.Gotham
	description.Text = tostring(item.Description or "")
	description.TextColor3 = Color3.fromRGB(170, 170, 180)
	description.TextSize = 12
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextTruncate = Enum.TextTruncate.AtEnd
	description.Parent = card

	local detail = Instance.new("TextLabel")
	detail.BackgroundTransparency = 1
	detail.Position = UDim2.fromOffset(14, 54)
	detail.Size = UDim2.new(1, -250, 0, 18)
	detail.Font = Enum.Font.GothamBold
	detail.TextColor3 = Color3.fromRGB(130, 205, 255)
	detail.TextSize = 12
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.Text = oneLife
		and ("Uses: x" .. tostring(item.Count or 0) .. " | Slot: " .. slot)
		or ("Permanent Unlock | Slot: " .. slot)
	detail.Parent = card

	local equipNow = makeButton(
		card,
		UDim2.new(1, -224, 0, 14),
		oneLife and "EQUIP NOW" or "EQUIP",
		Color3.fromRGB(45, 90, 55)
	)

	local equipLife = makeButton(
		card,
		UDim2.new(1, -114, 0, 14),
		"NEXT LIFE",
		Color3.fromRGB(70, 65, 115)
	)

	local unequipSaved = makeButton(
		card,
		UDim2.new(1, -224, 0, 50),
		"UNEQUIP",
		Color3.fromRGB(90, 55, 45)
	)

	local clearNext = makeButton(
		card,
		UDim2.new(1, -114, 0, 50),
		"CLEAR NEXT",
		Color3.fromRGB(75, 50, 65)
	)

	if oneLife then
		unequipSaved.Visible = false
	end

	equipNow.MouseButton1Click:Connect(function()
		setButtonEnabled(equipNow, false)
		statusLabel.Text = oneLife and "Equipping for this life..." or "Adding to saved loadout..."

		local success, response = invoke(EquipLoadoutItem, item.Id, slot, false)

		statusLabel.Text = response.Message or (success and "Item equipped." or "Equip failed.")
		setButtonEnabled(equipNow, true)
		refresh()
	end)

	equipLife.MouseButton1Click:Connect(function()
		setButtonEnabled(equipLife, false)
		statusLabel.Text = "Adding to next-life loadout..."

		local success, response = invoke(EquipLoadoutItem, item.Id, slot, true)

		statusLabel.Text = response.Message or (success and "Next-life loadout updated." or "Next-life equip failed.")
		setButtonEnabled(equipLife, true)
		refresh()
	end)

	unequipSaved.MouseButton1Click:Connect(function()
		setButtonEnabled(unequipSaved, false)
		statusLabel.Text = "Removing from saved loadout..."

		local success, response = invoke(UnequipLoadoutItem, item.Id, slot, false)

		statusLabel.Text = response.Message or (success and "Saved loadout updated." or "Unequip failed.")
		setButtonEnabled(unequipSaved, true)
		refresh()
	end)

	clearNext.MouseButton1Click:Connect(function()
		setButtonEnabled(clearNext, false)
		statusLabel.Text = "Removing from next-life loadout..."

		local success, response = invoke(UnequipLoadoutItem, item.Id, slot, true)

		statusLabel.Text = response.Message or (success and "Next-life loadout updated." or "Could not clear next-life item.")
		setButtonEnabled(clearNext, true)
		refresh()
	end)
end

refresh = function()
	if refreshing then
		return
	end

	refreshing = true

	local success, result = invoke(GetBlackMarketInventory)

	if success then
		payload = result
	else
		payload = nil
	end

	updateLoadoutText()
	clearList()

	if not payload then
		statusLabel.Text = result.Message or "Could not load Black Market inventory."
		createEmptyLabel("The Black Market inventory is currently unavailable.")
		updateCanvas()
		refreshing = false
		return
	end

	local items = {}

	for _, item in ipairs(payload.OwnedItems or {}) do
		table.insert(items, item)
	end

	for _, item in ipairs(payload.Consumables or {}) do
		table.insert(items, item)
	end

	table.sort(items, function(a, b)
		local orderA = SLOT_ORDER[a.LoadoutSlot] or 99
		local orderB = SLOT_ORDER[b.LoadoutSlot] or 99

		if orderA == orderB then
			return tostring(a.Name or a.Id) < tostring(b.Name or b.Id)
		end

		return orderA < orderB
	end)

	if #items == 0 then
		createEmptyLabel("No owned weapons or loadout equipment yet.")
	else
		for _, item in ipairs(items) do
			createItemCard(item)
		end
	end

	updateCanvas()
	refreshing = false
end

closeButton.MouseButton1Click:Connect(function()
	frame.Visible = false
end)

applyButton.MouseButton1Click:Connect(function()
	setButtonEnabled(applyButton, false)
	statusLabel.Text = "Applying permanent saved loadout..."

	local success, response = invoke(ApplyLoadoutNow)

	statusLabel.Text = response.Message or (success and "Saved loadout applied." or "Could not apply saved loadout.")
	setButtonEnabled(applyButton, true)
	refresh()
end)

clearLifeButton.MouseButton1Click:Connect(function()
	setButtonEnabled(clearLifeButton, false)
	statusLabel.Text = "Clearing next-life loadout..."

	local success, response = invoke(ClearServerLifeLoadout)

	statusLabel.Text = response.Message or (success and "Next-life loadout cleared." or "Could not clear next-life loadout.")
	setButtonEnabled(clearLifeButton, true)
	refresh()
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
	if triggeringPlayer ~= player or prompt.Name ~= PROMPT_NAME then
		return
	end

	frame.Visible = true
	statusLabel.Text = ""
	refresh()
end)

player:GetAttributeChangedSignal("USARF_InMenu"):Connect(function()
	if player:GetAttribute("USARF_InMenu") == true then
		frame.Visible = false
	end
end)

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale)
end

applyScale()

print("[BlackMarketController] Initialized")