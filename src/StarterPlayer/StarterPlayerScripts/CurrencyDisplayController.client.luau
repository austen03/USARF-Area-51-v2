local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CurrencyDisplay"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 0
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1
uiScale.Parent = screenGui

local frame = Instance.new("Frame")
frame.Name = "Container"
frame.AnchorPoint = Vector2.new(0, 1)
frame.Size = UDim2.new(0, 220, 0, 64)
frame.Position = UDim2.new(0, 24, 1, -132)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.08
frame.BorderSizePixel = 0
frame.Active = false
frame.Selectable = false
frame.ZIndex = 1
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 60, 60)
stroke.Thickness = 1
stroke.Transparency = 0.25
stroke.Parent = frame

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "Cash"
cashLabel.BackgroundTransparency = 1
cashLabel.Position = UDim2.new(0, 14, 0, 8)
cashLabel.Size = UDim2.new(1, -28, 0, 22)
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextSize = 16
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.TextColor3 = Color3.fromRGB(95, 220, 120)
cashLabel.Text = "Cash: Loading..."
cashLabel.Active = false
cashLabel.Selectable = false
cashLabel.ZIndex = 2
cashLabel.Parent = frame

local goldLabel = Instance.new("TextLabel")
goldLabel.Name = "Gold"
goldLabel.BackgroundTransparency = 1
goldLabel.Position = UDim2.new(0, 14, 0, 34)
goldLabel.Size = UDim2.new(1, -28, 0, 22)
goldLabel.Font = Enum.Font.GothamBold
goldLabel.TextSize = 16
goldLabel.TextXAlignment = Enum.TextXAlignment.Left
goldLabel.TextColor3 = Color3.fromRGB(255, 205, 75)
goldLabel.Text = "Gold: Loading..."
goldLabel.Active = false
goldLabel.Selectable = false
goldLabel.ZIndex = 2
goldLabel.Parent = frame

local function updateVisibility()
	local inMenu = player:GetAttribute("USARF_InMenu")

	if inMenu == nil then
		inMenu = true
	end

	screenGui.Enabled = inMenu == false
end

local function formatNumber(value)
	value = tonumber(value) or 0
	return tostring(value):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function update()
	local cash = player:GetAttribute("Cash")
	local gold = player:GetAttribute("Gold")

	if cash == nil then
		cashLabel.Text = "Cash: Loading..."
	else
		cashLabel.Text = "Cash: $" .. formatNumber(cash)
	end

	if gold == nil then
		goldLabel.Text = "Gold: Loading..."
	else
		goldLabel.Text = "Gold: " .. formatNumber(gold)
	end

	updateVisibility()
end

player:GetAttributeChangedSignal("Cash"):Connect(update)
player:GetAttributeChangedSignal("Gold"):Connect(update)
player:GetAttributeChangedSignal("USARF_InMenu"):Connect(updateVisibility)

updateVisibility()

task.spawn(function()
	for _ = 1, 50 do
		update()

		if player:GetAttribute("Cash") ~= nil and player:GetAttribute("Gold") ~= nil then
			break
		end

		task.wait(0.1)
	end

	update()
end)
