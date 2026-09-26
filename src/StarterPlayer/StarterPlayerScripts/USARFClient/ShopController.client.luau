local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local CheckRiotPurchase = Remotes:WaitForChild("CheckRiotPurchase")
local PurchaseRiotWithGold = Remotes:WaitForChild("PurchaseRiotWithGold")

local RIOT_PRODUCT_ID = 1029674008
local RIOT_GOLD_COST = 2500

local GetShopItems = Remotes:WaitForChild("GetShopItems")
local GetInventory = Remotes:WaitForChild("GetInventory")
local ShopPurchase = Remotes:WaitForChild("ShopPurchase")
local GetDailyRewardStatus = Remotes:WaitForChild("GetDailyRewardStatus")
local ClaimDailyReward = Remotes:WaitForChild("ClaimDailyReward")
local UseInventoryItem = Remotes:WaitForChild("UseInventoryItem")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShopUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 50
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local uiScale = Instance.new("UIScale")
uiScale.Parent = screenGui

local selectedCategory = "Cash Items"

local goldProducts = {
	{ Name = "10 Gold", Amount = 10, ProductId = 3603695433 },
	{ Name = "25 Gold", Amount = 25, ProductId = 3603695455 },
	{ Name = "60 Gold", Amount = 60, ProductId = 3603695476 },
	{ Name = "150 Gold", Amount = 150, ProductId = 3603695490 },
}

local function formatNumber(value)
	value = tonumber(value) or 0
	return tostring(value):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function formatTime(seconds)
	seconds = math.max(0, tonumber(seconds) or 0)

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	if hours > 0 then
		return string.format("%dh %dm %ds", hours, minutes, secs)
	end

	if minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	end

	return string.format("%ds", secs)
end

local function makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function makeStroke(parent, color, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 1
	stroke.Transparency = transparency or 0.2
	stroke.Parent = parent
	return stroke
end

local function makeButtonClickable(button, zIndex)
	button.Active = true
	button.Selectable = true
	button.AutoButtonColor = true
	button.ZIndex = zIndex or 50
end

local function getScale()
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)

	if viewport.X < 1000 then
		return 0.82
	elseif viewport.X < 1200 then
		return 0.9
	end

	return 1
end

local function applyScale()
	uiScale.Scale = getScale()
end

local dailyButton = Instance.new("TextButton")
dailyButton.Name = "DailyReward"
dailyButton.AnchorPoint = Vector2.new(0, 1)
dailyButton.Position = UDim2.new(0, 24, 1, -252)
dailyButton.Size = UDim2.new(0, 220, 0, 34)
dailyButton.BackgroundColor3 = Color3.fromRGB(35, 28, 18)
dailyButton.BorderSizePixel = 0
dailyButton.Font = Enum.Font.GothamBold
dailyButton.Text = "🎁 DAILY REWARD"
dailyButton.TextColor3 = Color3.fromRGB(255, 220, 120)
dailyButton.TextSize = 13
dailyButton.Parent = screenGui
makeButtonClickable(dailyButton, 50)
makeCorner(dailyButton, 10)
makeStroke(dailyButton, Color3.fromRGB(120, 90, 40), 0.25)

local openButton = Instance.new("TextButton")
openButton.Name = "OpenShop"
openButton.AnchorPoint = Vector2.new(0, 1)
openButton.Position = UDim2.new(0, 24, 1, -214)
openButton.Size = UDim2.new(0, 220, 0, 34)
openButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
openButton.BorderSizePixel = 0
openButton.Font = Enum.Font.GothamBold
openButton.Text = "SHOP"
openButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openButton.TextSize = 14
openButton.Parent = screenGui
makeButtonClickable(openButton, 50)
makeCorner(openButton, 10)
makeStroke(openButton, Color3.fromRGB(70, 70, 70), 0.2)

local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopMain"
shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
shopFrame.Size = UDim2.new(0, 610, 0, 540)
shopFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.ZIndex = 60
shopFrame.Parent = screenGui
makeCorner(shopFrame, 14)
makeStroke(shopFrame, Color3.fromRGB(90, 90, 100), 0.15)

local shopTitle = Instance.new("TextLabel")
shopTitle.BackgroundTransparency = 1
shopTitle.Position = UDim2.new(0, 18, 0, 12)
shopTitle.Size = UDim2.new(1, -70, 0, 32)
shopTitle.Font = Enum.Font.GothamBold
shopTitle.Text = "USARF SHOP"
shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopTitle.TextSize = 20
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.ZIndex = 61
shopTitle.Parent = shopFrame

local shopClose = Instance.new("TextButton")
shopClose.Position = UDim2.new(1, -46, 0, 12)
shopClose.Size = UDim2.new(0, 32, 0, 32)
shopClose.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
shopClose.BorderSizePixel = 0
shopClose.Font = Enum.Font.GothamBold
shopClose.Text = "X"
shopClose.TextColor3 = Color3.fromRGB(255, 255, 255)
shopClose.TextSize = 14
shopClose.ZIndex = 63
shopClose.Parent = shopFrame
makeButtonClickable(shopClose, 63)
makeCorner(shopClose, 8)

local balanceLabel = Instance.new("TextLabel")
balanceLabel.BackgroundTransparency = 1
balanceLabel.Position = UDim2.new(0, 18, 0, 44)
balanceLabel.Size = UDim2.new(1, -170, 0, 24)
balanceLabel.Font = Enum.Font.Gotham
balanceLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
balanceLabel.TextSize = 14
balanceLabel.TextXAlignment = Enum.TextXAlignment.Left
balanceLabel.ZIndex = 61
balanceLabel.Parent = shopFrame

local buyGoldButton = Instance.new("TextButton")
buyGoldButton.Name = "BuyGold"
buyGoldButton.AnchorPoint = Vector2.new(1, 0)
buyGoldButton.Position = UDim2.new(1, -58, 0, 54)
buyGoldButton.Size = UDim2.new(0, 130, 0, 28)
buyGoldButton.BackgroundColor3 = Color3.fromRGB(95, 70, 30)
buyGoldButton.BorderSizePixel = 0
buyGoldButton.Font = Enum.Font.GothamBold
buyGoldButton.Text = "BUY GOLD"
buyGoldButton.TextColor3 = Color3.fromRGB(255, 230, 140)
buyGoldButton.TextSize = 12
buyGoldButton.ZIndex = 63
buyGoldButton.Parent = shopFrame
makeButtonClickable(buyGoldButton, 63)
makeCorner(buyGoldButton, 8)

local tabFrame = Instance.new("Frame")
tabFrame.Name = "Tabs"
tabFrame.Position = UDim2.new(0, 18, 0, 92)
tabFrame.Size = UDim2.new(1, -36, 0, 38)
tabFrame.BackgroundTransparency = 1
tabFrame.ZIndex = 61
tabFrame.Parent = shopFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Padding = UDim.new(0, 8)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = tabFrame

local function createTab(name, text, order)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(0, 130, 0, 34)
	button.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(220, 220, 225)
	button.TextSize = 13
	button.LayoutOrder = order
	button.ZIndex = 63
	button.Parent = tabFrame
	makeButtonClickable(button, 63)
	makeCorner(button, 9)
	return button
end

local cashTab = createTab("CashItems", "Cash Items", 1)
local goldTab = createTab("GoldItems", "Gold Items", 2)
local inventoryTab = createTab("Inventory", "Inventory", 3)

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.new(0, 18, 0, 140)
list.Size = UDim2.new(1, -36, 1, -178)
list.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.ZIndex = 61
list.ClipsDescendants = true
list.Parent = shopFrame
makeCorner(list, 10)

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingBottom = UDim.new(0, 24)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = list

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 18, 1, -32)
statusLabel.Size = UDim2.new(1, -36, 0, 22)
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
statusLabel.TextSize = 13
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Top
statusLabel.ZIndex = 61
statusLabel.Parent = shopFrame

local emptyLabel = Instance.new("TextLabel")
emptyLabel.BackgroundTransparency = 1
emptyLabel.Size = UDim2.new(1, -20, 0, 80)
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.Text = "No items available."
emptyLabel.TextColor3 = Color3.fromRGB(160, 160, 165)
emptyLabel.TextSize = 14
emptyLabel.Visible = false
emptyLabel.ZIndex = 62
emptyLabel.Parent = list

local goldFrame = Instance.new("Frame")
goldFrame.Name = "BuyGoldMain"
goldFrame.AnchorPoint = Vector2.new(0.5, 0.5)
goldFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
goldFrame.Size = UDim2.new(0, 430, 0, 310)
goldFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
goldFrame.BorderSizePixel = 0
goldFrame.Visible = false
goldFrame.ZIndex = 70
goldFrame.Parent = screenGui
makeCorner(goldFrame, 14)
makeStroke(goldFrame, Color3.fromRGB(120, 95, 45), 0.12)

local goldTitle = Instance.new("TextLabel")
goldTitle.BackgroundTransparency = 1
goldTitle.Position = UDim2.new(0, 18, 0, 12)
goldTitle.Size = UDim2.new(1, -70, 0, 32)
goldTitle.Font = Enum.Font.GothamBold
goldTitle.Text = "BUY GOLD"
goldTitle.TextColor3 = Color3.fromRGB(255, 220, 120)
goldTitle.TextSize = 20
goldTitle.TextXAlignment = Enum.TextXAlignment.Left
goldTitle.ZIndex = 71
goldTitle.Parent = goldFrame

local goldClose = Instance.new("TextButton")
goldClose.Position = UDim2.new(1, -46, 0, 12)
goldClose.Size = UDim2.new(0, 32, 0, 32)
goldClose.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
goldClose.BorderSizePixel = 0
goldClose.Font = Enum.Font.GothamBold
goldClose.Text = "X"
goldClose.TextColor3 = Color3.fromRGB(255, 255, 255)
goldClose.TextSize = 14
goldClose.ZIndex = 73
goldClose.Parent = goldFrame
makeButtonClickable(goldClose, 73)
makeCorner(goldClose, 8)

local goldSubtitle = Instance.new("TextLabel")
goldSubtitle.BackgroundTransparency = 1
goldSubtitle.Position = UDim2.new(0, 18, 0, 48)
goldSubtitle.Size = UDim2.new(1, -36, 0, 24)
goldSubtitle.Font = Enum.Font.Gotham
goldSubtitle.Text = "Gold is used for premium cosmetics and special unlocks."
goldSubtitle.TextColor3 = Color3.fromRGB(200, 200, 205)
goldSubtitle.TextSize = 13
goldSubtitle.TextXAlignment = Enum.TextXAlignment.Left
goldSubtitle.ZIndex = 71
goldSubtitle.Parent = goldFrame

local goldList = Instance.new("Frame")
goldList.Position = UDim2.new(0, 18, 0, 84)
goldList.Size = UDim2.new(1, -36, 1, -104)
goldList.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
goldList.BorderSizePixel = 0
goldList.ZIndex = 71
goldList.Parent = goldFrame
makeCorner(goldList, 10)

local goldLayout = Instance.new("UIListLayout")
goldLayout.Padding = UDim.new(0, 10)
goldLayout.SortOrder = Enum.SortOrder.LayoutOrder
goldLayout.Parent = goldList

local goldPadding = Instance.new("UIPadding")
goldPadding.PaddingTop = UDim.new(0, 10)
goldPadding.PaddingBottom = UDim.new(0, 10)
goldPadding.PaddingLeft = UDim.new(0, 10)
goldPadding.PaddingRight = UDim.new(0, 10)
goldPadding.Parent = goldList

local dailyFrame = Instance.new("Frame")
dailyFrame.Name = "DailyRewardMain"
dailyFrame.AnchorPoint = Vector2.new(0.5, 0.5)
dailyFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
dailyFrame.Size = UDim2.new(0, 500, 0, 390)
dailyFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
dailyFrame.BorderSizePixel = 0
dailyFrame.Visible = false
dailyFrame.ZIndex = 70
dailyFrame.Parent = screenGui
makeCorner(dailyFrame, 14)
makeStroke(dailyFrame, Color3.fromRGB(120, 95, 45), 0.12)

local dailyTitle = Instance.new("TextLabel")
dailyTitle.BackgroundTransparency = 1
dailyTitle.Position = UDim2.new(0, 18, 0, 12)
dailyTitle.Size = UDim2.new(1, -70, 0, 32)
dailyTitle.Font = Enum.Font.GothamBold
dailyTitle.Text = "USARF DAILY REWARD"
dailyTitle.TextColor3 = Color3.fromRGB(255, 220, 120)
dailyTitle.TextSize = 20
dailyTitle.TextXAlignment = Enum.TextXAlignment.Left
dailyTitle.ZIndex = 71
dailyTitle.Parent = dailyFrame

local dailyClose = Instance.new("TextButton")
dailyClose.Position = UDim2.new(1, -46, 0, 12)
dailyClose.Size = UDim2.new(0, 32, 0, 32)
dailyClose.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
dailyClose.BorderSizePixel = 0
dailyClose.Font = Enum.Font.GothamBold
dailyClose.Text = "X"
dailyClose.TextColor3 = Color3.fromRGB(255, 255, 255)
dailyClose.TextSize = 14
dailyClose.ZIndex = 73
dailyClose.Parent = dailyFrame
makeButtonClickable(dailyClose, 73)
makeCorner(dailyClose, 8)

local dailyInfo = Instance.new("TextLabel")
dailyInfo.BackgroundTransparency = 1
dailyInfo.Position = UDim2.new(0, 18, 0, 48)
dailyInfo.Size = UDim2.new(1, -36, 0, 26)
dailyInfo.Font = Enum.Font.Gotham
dailyInfo.TextColor3 = Color3.fromRGB(200, 200, 205)
dailyInfo.TextSize = 14
dailyInfo.TextXAlignment = Enum.TextXAlignment.Left
dailyInfo.ZIndex = 71
dailyInfo.Parent = dailyFrame

local rewardList = Instance.new("Frame")
rewardList.Position = UDim2.new(0, 18, 0, 86)
rewardList.Size = UDim2.new(1, -36, 0, 210)
rewardList.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
rewardList.BorderSizePixel = 0
rewardList.ZIndex = 71
rewardList.Parent = dailyFrame
makeCorner(rewardList, 10)

local rewardLayout = Instance.new("UIListLayout")
rewardLayout.Padding = UDim.new(0, 6)
rewardLayout.SortOrder = Enum.SortOrder.LayoutOrder
rewardLayout.Parent = rewardList

local rewardPadding = Instance.new("UIPadding")
rewardPadding.PaddingTop = UDim.new(0, 10)
rewardPadding.PaddingBottom = UDim.new(0, 10)
rewardPadding.PaddingLeft = UDim.new(0, 10)
rewardPadding.PaddingRight = UDim.new(0, 10)
rewardPadding.Parent = rewardList

local dailyStatus = Instance.new("TextLabel")
dailyStatus.BackgroundTransparency = 1
dailyStatus.Position = UDim2.new(0, 18, 0, 306)
dailyStatus.Size = UDim2.new(1, -36, 0, 24)
dailyStatus.Font = Enum.Font.Gotham
dailyStatus.TextColor3 = Color3.fromRGB(220, 220, 220)
dailyStatus.TextSize = 14
dailyStatus.TextXAlignment = Enum.TextXAlignment.Left
dailyStatus.ZIndex = 71
dailyStatus.Parent = dailyFrame

local claimButton = Instance.new("TextButton")
claimButton.Position = UDim2.new(0, 18, 1, -50)
claimButton.Size = UDim2.new(1, -36, 0, 36)
claimButton.BackgroundColor3 = Color3.fromRGB(95, 70, 30)
claimButton.BorderSizePixel = 0
claimButton.Font = Enum.Font.GothamBold
claimButton.Text = "CLAIM REWARD"
claimButton.TextColor3 = Color3.fromRGB(255, 255, 255)
claimButton.TextSize = 14
claimButton.ZIndex = 73
claimButton.Parent = dailyFrame
makeButtonClickable(claimButton, 73)
makeCorner(claimButton, 9)

local shopItems = {}
local inventory = {
	OwnedItems = {},
	Consumables = {},
	Boosts = {},
	Loadout = {
		Primary = nil,
		Secondary = nil,
		Equipment = {},
	},
	ServerLifeLoadout = {
		Primary = nil,
		Secondary = nil,
		Equipment = {},
	},
}

local currentDailyStatus = nil
local dailyCountdownRunning = false

local function getItemById(itemId)
	for _, item in ipairs(shopItems) do
		if item.Id == itemId then
			return item
		end
	end

	return nil
end

local function isOwned(itemId)
	return inventory.OwnedItems and inventory.OwnedItems[itemId] == true
end

local function getConsumableCount(itemId)
	return tonumber(inventory.Consumables and inventory.Consumables[itemId]) or 0
end

local function getBoostRemaining(boostKey)
	local endsAt = tonumber(inventory.Boosts and inventory.Boosts[boostKey]) or 0
	return math.max(0, endsAt - os.time())
end

local function updateVisibility()
	local inMenu = player:GetAttribute("USARF_InMenu")

	if inMenu == nil then
		inMenu = true
	end

	local visible = inMenu == false

	dailyButton.Visible = visible
	openButton.Visible = visible

	if not visible then
		shopFrame.Visible = false
		dailyFrame.Visible = false
		goldFrame.Visible = false
	end
end

local function updateBalance()
	local cash = player:GetAttribute("Cash") or 0
	local gold = player:GetAttribute("Gold") or 0

	balanceLabel.Text = "Cash: $" .. formatNumber(cash) .. "   |   Gold: " .. formatNumber(gold)
end

local function updateTabs()
	local tabs = {
		["Cash Items"] = cashTab,
		["Gold Items"] = goldTab,
		Inventory = inventoryTab,
	}

	for category, button in pairs(tabs) do
		local selected = selectedCategory == category

		if selected then
			if category == "Cash Items" then
				button.BackgroundColor3 = Color3.fromRGB(45, 90, 55)
			elseif category == "Gold Items" then
				button.BackgroundColor3 = Color3.fromRGB(95, 70, 30)
			else
				button.BackgroundColor3 = Color3.fromRGB(70, 65, 115)
			end

			button.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			button.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
			button.TextColor3 = Color3.fromRGB(220, 220, 225)
		end
	end
end

local function updateCanvas()
	task.defer(function()
		task.wait()

		local height = layout.AbsoluteContentSize.Y + padding.PaddingTop.Offset + padding.PaddingBottom.Offset + 36
		list.CanvasSize = UDim2.new(0, 0, 0, height)
	end)
end

-- "Remaining" labels on shop cards for active timed boosts, ticked every second by the
-- countdown loop at the bottom of this script.
local boostCountdowns = {}

local function clearShopItems()
	table.clear(boostCountdowns)

	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function clearRewardRows()
	for _, child in ipairs(rewardList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function createGoldProductRow(product)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 42)
	row.BackgroundColor3 = Color3.fromRGB(25, 25, 31)
	row.BorderSizePixel = 0
	row.ZIndex = 72
	row.Parent = goldList
	makeCorner(row, 8)
	makeStroke(row, Color3.fromRGB(65, 55, 35), 0.35)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 14, 0, 0)
	label.Size = UDim2.new(1, -130, 1, 0)
	label.Font = Enum.Font.GothamBold
	label.Text = product.Name
	label.TextColor3 = Color3.fromRGB(255, 220, 120)
	label.TextSize = 15
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 73
	label.Parent = row

	local buyButton = Instance.new("TextButton")
	buyButton.Position = UDim2.new(1, -104, 0.5, -14)
	buyButton.Size = UDim2.new(0, 90, 0, 28)
	buyButton.BackgroundColor3 = Color3.fromRGB(95, 70, 30)
	buyButton.BorderSizePixel = 0
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Text = "BUY"
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextSize = 12
	buyButton.ZIndex = 74
	buyButton.Parent = row
	makeButtonClickable(buyButton, 74)
	makeCorner(buyButton, 7)

	buyButton.MouseButton1Click:Connect(function()
		MarketplaceService:PromptProductPurchase(player, product.ProductId)
	end)
end

for _, product in ipairs(goldProducts) do
	createGoldProductRow(product)
end

local function createRewardRow(day, reward, isNext)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 24)
	row.BackgroundColor3 = isNext and Color3.fromRGB(45, 35, 18) or Color3.fromRGB(22, 22, 27)
	row.BorderSizePixel = 0
	row.LayoutOrder = day
	row.ZIndex = 72
	row.Parent = rewardList
	makeCorner(row, 6)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.new(0, 10, 0, 0)
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextColor3 = isNext and Color3.fromRGB(255, 220, 120) or Color3.fromRGB(220, 220, 225)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 73

	local parts = {}

	if reward.Cash and reward.Cash > 0 then
		table.insert(parts, "$" .. formatNumber(reward.Cash) .. " Cash")
	end

	if reward.Gold and reward.Gold > 0 then
		table.insert(parts, formatNumber(reward.Gold) .. " Gold")
	end

	label.Text = "Day " .. day .. "  -  " .. table.concat(parts, " + ")
	label.Parent = row
end

local function setClaimButtonReady(ready)
	if ready then
		claimButton.Text = "CLAIM REWARD"
		claimButton.BackgroundColor3 = Color3.fromRGB(95, 70, 30)
		claimButton.AutoButtonColor = true
		claimButton.Active = true
	else
		claimButton.Text = "NOT READY"
		claimButton.BackgroundColor3 = Color3.fromRGB(65, 65, 70)
		claimButton.AutoButtonColor = false
		claimButton.Active = true
	end
end

local function renderDailyStatus(status)
	currentDailyStatus = status
	clearRewardRows()

	local rewards =
		status
		and status.Rewards
		or {
			[1] = { Cash = 250, Gold = 0 },
			[2] = { Cash = 500, Gold = 0 },
			[3] = { Cash = 750, Gold = 0 },
			[4] = { Cash = 1000, Gold = 0 },
			[5] = { Cash = 0, Gold = 1 },
			[6] = { Cash = 0, Gold = 2 },
			[7] = { Cash = 0, Gold = 5 },
		}

	for day = 1, 7 do
		createRewardRow(day, rewards[day] or {}, status and status.NextDay == day)
	end

	if not status then
		dailyInfo.Text = "Unable to load daily reward status."
		dailyStatus.Text = ""
		setClaimButtonReady(false)
		return
	end

	dailyInfo.Text = "Current Streak: " .. tostring(status.Streak or 0) .. "   |   Next Reward: Day " .. tostring(status.NextDay or 1)

	if status.CanClaim then
		dailyStatus.Text = "Your daily reward is ready to claim."
		setClaimButtonReady(true)
	else
		dailyStatus.Text = "Next reward available in: " .. formatTime(status.Remaining or 0)
		setClaimButtonReady(false)
	end
end

local function refreshDaily()
	local success, result = pcall(function()
		return GetDailyRewardStatus:InvokeServer()
	end)

	if success and typeof(result) == "table" then
		renderDailyStatus(result)
	else
		renderDailyStatus(nil)
	end
end

local function startDailyCountdown()
	if dailyCountdownRunning then
		return
	end

	dailyCountdownRunning = true

	task.spawn(function()
		while dailyFrame.Visible do
			if currentDailyStatus and not currentDailyStatus.CanClaim then
				currentDailyStatus.Remaining = math.max(0, (currentDailyStatus.Remaining or 0) - 1)

				if currentDailyStatus.Remaining <= 0 then
					refreshDaily()
				else
					dailyStatus.Text = "Next reward available in: " .. formatTime(currentDailyStatus.Remaining)
				end
			end

			task.wait(1)
		end

		dailyCountdownRunning = false
	end)
end

local function createRiotCard()
	local card = Instance.new("Frame")
	card.Name = "RiotPurchase"
	card.Size = UDim2.new(1, -4, 0, 118)
	card.BackgroundColor3 = Color3.fromRGB(35, 18, 18)
	card.BorderSizePixel = 0
	card.ZIndex = 62
	card.Parent = list
	makeCorner(card, 10)
	makeStroke(card, Color3.fromRGB(160, 60, 60), 0.15)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.new(0, 14, 0, 10)
	nameLabel.Size = UDim2.new(1, -28, 0, 24)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = "10 Minute Test Subject Riot"
	nameLabel.TextColor3 = Color3.fromRGB(255, 110, 110)
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 63
	nameLabel.Parent = card

	local description = Instance.new("TextLabel")
	description.BackgroundTransparency = 1
	description.Position = UDim2.new(0, 14, 0, 42)
	description.Size = UDim2.new(1, -28, 0, 44)
	description.Font = Enum.Font.Gotham
	description.Text = "Starts a facility riot. Test Subjects receive weapons and temporary SC-4 access during the riot."
	description.TextColor3 = Color3.fromRGB(220, 190, 190)
	description.TextSize = 12
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.ZIndex = 63
	description.Parent = card

	local robuxButton = Instance.new("TextButton")
	robuxButton.Position = UDim2.new(1, -224, 1, -38)
	robuxButton.Size = UDim2.new(0, 100, 0, 30)
	robuxButton.BackgroundColor3 = Color3.fromRGB(65, 45, 90)
	robuxButton.BorderSizePixel = 0
	robuxButton.Font = Enum.Font.GothamBold
	robuxButton.Text = "ROBUX"
	robuxButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	robuxButton.TextSize = 12
	robuxButton.ZIndex = 64
	robuxButton.Parent = card
	makeButtonClickable(robuxButton, 64)
	makeCorner(robuxButton, 8)

	local goldButton = Instance.new("TextButton")
	goldButton.Position = UDim2.new(1, -114, 1, -38)
	goldButton.Size = UDim2.new(0, 100, 0, 30)
	goldButton.BackgroundColor3 = Color3.fromRGB(95, 70, 30)
	goldButton.BorderSizePixel = 0
	goldButton.Font = Enum.Font.GothamBold
	goldButton.Text = formatNumber(RIOT_GOLD_COST) .. " GOLD"
	goldButton.TextColor3 = Color3.fromRGB(255, 230, 140)
	goldButton.TextSize = 12
	goldButton.ZIndex = 64
	goldButton.Parent = card
	makeButtonClickable(goldButton, 64)
	makeCorner(goldButton, 8)

	robuxButton.MouseButton1Click:Connect(function()
		robuxButton.Text = "..."

		local success, result = pcall(function()
			return CheckRiotPurchase:InvokeServer()
		end)

		if success and typeof(result) == "table" and result.CanPurchase == true then
			statusLabel.Text = "Opening riot purchase..."
			robuxButton.Text = "ROBUX"
			MarketplaceService:PromptProductPurchase(player, RIOT_PRODUCT_ID)
		else
			statusLabel.Text = success and typeof(result) == "table" and result.Message or "Riot purchase unavailable."
			robuxButton.Text = "ROBUX"
		end
	end)

	goldButton.MouseButton1Click:Connect(function()
		goldButton.Text = "..."

		local success, result = pcall(function()
			return PurchaseRiotWithGold:InvokeServer()
		end)

		if success and typeof(result) == "table" and result.Success == true then
			statusLabel.Text = result.Message or "Riot purchased."
			updateBalance()
		else
			statusLabel.Text = success and typeof(result) == "table" and result.Message or "Gold riot purchase failed."
		end

		goldButton.Text = formatNumber(RIOT_GOLD_COST) .. " GOLD"
	end)
end

local renderShopItems

local function createItemCard(item)
	local card = Instance.new("Frame")
	card.Name = item.Id
	card.Size = UDim2.new(1, -4, 0, 96)
	card.BackgroundColor3 = Color3.fromRGB(25, 25, 31)
	card.BorderSizePixel = 0
	card.ZIndex = 62
	card.Parent = list
	makeCorner(card, 10)
	makeStroke(card, Color3.fromRGB(55, 55, 65), 0.25)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.new(0, 14, 0, 10)
	nameLabel.Size = UDim2.new(1, -150, 0, 24)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = item.Name or item.Id
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 63
	nameLabel.Parent = card

	local categoryLabel = Instance.new("TextLabel")
	categoryLabel.BackgroundTransparency = 1
	categoryLabel.Position = UDim2.new(0, 14, 0, 32)
	categoryLabel.Size = UDim2.new(1, -150, 0, 16)
	categoryLabel.Font = Enum.Font.Gotham
	categoryLabel.Text = tostring(item.ItemType or item.Category or "Item")
	categoryLabel.TextColor3 = Color3.fromRGB(135, 135, 145)
	categoryLabel.TextSize = 11
	categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
	categoryLabel.ZIndex = 63
	categoryLabel.Parent = card

	local description = Instance.new("TextLabel")
	description.BackgroundTransparency = 1
	description.Position = UDim2.new(0, 14, 0, 49)
	description.Size = UDim2.new(1, -150, 0, 18)
	description.Font = Enum.Font.Gotham
	description.Text = item.Description or ""
	description.TextColor3 = Color3.fromRGB(180, 180, 185)
	description.TextSize = 12
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextTruncate = Enum.TextTruncate.AtEnd
	description.ZIndex = 63
	description.Parent = card

	local price = Instance.new("TextLabel")
	price.BackgroundTransparency = 1
	price.Position = UDim2.new(0, 14, 0, 70)
	price.Size = UDim2.new(1, -150, 0, 18)
	price.Font = Enum.Font.GothamBold
	price.TextSize = 13
	price.TextXAlignment = Enum.TextXAlignment.Left
	price.ZIndex = 63

	if item.Currency == "Gold" then
		price.TextColor3 = Color3.fromRGB(255, 205, 75)
		price.Text = "Gold: " .. formatNumber(item.Price)
	else
		price.TextColor3 = Color3.fromRGB(95, 220, 120)
		price.Text = "Cash: $" .. formatNumber(item.Price)
	end

	price.Parent = card

	local purchaseButton = Instance.new("TextButton")
	purchaseButton.Position = UDim2.new(1, -118, 0.5, -18)
	purchaseButton.Size = UDim2.new(0, 100, 0, 36)
	purchaseButton.BackgroundColor3 = item.Currency == "Gold" and Color3.fromRGB(95, 70, 30) or Color3.fromRGB(45, 90, 55)
	purchaseButton.BorderSizePixel = 0
	purchaseButton.Font = Enum.Font.GothamBold
	purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	purchaseButton.TextSize = 13
	purchaseButton.ZIndex = 64
	purchaseButton.Parent = card
	makeButtonClickable(purchaseButton, 64)
	makeCorner(purchaseButton, 8)

	local owned = isOwned(item.Id)
	local consumableCount = getConsumableCount(item.Id)
	local boostKey = item.Effect or item.Id
	local boostRemaining = getBoostRemaining(boostKey)

	if item.ItemType == "Permanent" or item.ItemType == "Unlock" then
		if owned then
			purchaseButton.Text = "OWNED"
			purchaseButton.BackgroundColor3 = Color3.fromRGB(70, 70, 75)
			purchaseButton.AutoButtonColor = false
		else
			purchaseButton.Text = "BUY"
		end
	elseif item.ItemType == "TimedBoost" and boostRemaining > 0 then
		purchaseButton.Text = "ACTIVE"
		price.Text = "Remaining: " .. formatTime(boostRemaining)

		table.insert(boostCountdowns, {
			Label = price,
			BoostKey = boostKey,
		})
	else
		purchaseButton.Text = "BUY"

		if consumableCount > 0 then
			price.Text = price.Text .. "   |   Owned: x" .. tostring(consumableCount)
		end
	end

	purchaseButton.MouseButton1Click:Connect(function()
		if purchaseButton.Text == "OWNED" then
			return
		end

		purchaseButton.Text = "..."
		statusLabel.Text = "Purchasing " .. tostring(item.Name or item.Id) .. "..."

		local success, result = ShopPurchase:InvokeServer(item.Id)

		if success then
			statusLabel.Text = "Purchased " .. tostring(item.Name or item.Id) .. "."

			if typeof(result) == "table" and result.Inventory then
				inventory = result.Inventory
				inventory.OwnedItems = inventory.OwnedItems or {}
				inventory.Consumables = inventory.Consumables or {}
				inventory.Boosts = inventory.Boosts or {}
			else
				if item.ItemType == "Permanent" or item.ItemType == "Unlock" then
					inventory.OwnedItems[item.Id] = true
				end
			end

			updateBalance()

			if item.Effect == "RadioAccess" then
				player:SetAttribute("USARF_RadioAccessRefreshClient", os.clock())
			end

			renderShopItems()
		else
			statusLabel.Text = tostring(result or "Purchase failed.")
			renderShopItems()
		end
	end)
end

local function createInventoryCard(title, subtitle, detail, color)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -4, 0, 74)
	card.BackgroundColor3 = Color3.fromRGB(25, 25, 31)
	card.BorderSizePixel = 0
	card.ZIndex = 62
	card.Parent = list
	makeCorner(card, 10)
	makeStroke(card, Color3.fromRGB(55, 55, 65), 0.25)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.new(0, 14, 0, 8)
	titleLabel.Size = UDim2.new(1, -28, 0, 22)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = title
	titleLabel.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 15
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 63
	titleLabel.Parent = card

	local subLabel = Instance.new("TextLabel")
	subLabel.BackgroundTransparency = 1
	subLabel.Position = UDim2.new(0, 14, 0, 31)
	subLabel.Size = UDim2.new(1, -28, 0, 18)
	subLabel.Font = Enum.Font.Gotham
	subLabel.Text = subtitle or ""
	subLabel.TextColor3 = Color3.fromRGB(175, 175, 185)
	subLabel.TextSize = 12
	subLabel.TextXAlignment = Enum.TextXAlignment.Left
	subLabel.ZIndex = 63
	subLabel.Parent = card

	local detailLabel = Instance.new("TextLabel")
	detailLabel.BackgroundTransparency = 1
	detailLabel.Position = UDim2.new(0, 14, 0, 50)
	detailLabel.Size = UDim2.new(1, -28, 0, 18)
	detailLabel.Font = Enum.Font.GothamBold
	detailLabel.Text = detail or ""
	detailLabel.TextColor3 = Color3.fromRGB(130, 205, 255)
	detailLabel.TextSize = 12
	detailLabel.TextXAlignment = Enum.TextXAlignment.Left
	detailLabel.ZIndex = 63
	detailLabel.Parent = card
end

local function renderInventory()
	clearShopItems()
	updateTabs()

	local count = 0

	for itemId, owned in pairs(inventory.OwnedItems or {}) do
		if owned == true then
			local item = getItemById(itemId)
			count += 1

			createInventoryCard(
				item and item.Name or itemId,
				item and (item.Description or "Permanent unlock") or "Permanent unlock",
				"OWNED",
				item and item.Currency == "Gold" and Color3.fromRGB(255, 205, 75) or Color3.fromRGB(255, 255, 255)
			)
		end
	end

	for itemId, amount in pairs(inventory.Consumables or {}) do
		amount = tonumber(amount) or 0

		if amount > 0 then
			local item = getItemById(itemId)

			count += 1

			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, -4, 0, 74)
			card.BackgroundColor3 = Color3.fromRGB(25, 25, 31)
			card.BorderSizePixel = 0
			card.ZIndex = 62
			card.Parent = list

			makeCorner(card, 10)
			makeStroke(card, Color3.fromRGB(55, 55, 65), 0.25)

			local title = Instance.new("TextLabel")
			title.BackgroundTransparency = 1
			title.Position = UDim2.new(0, 14, 0, 8)
			title.Size = UDim2.new(1, -130, 0, 22)
			title.Font = Enum.Font.GothamBold
			title.Text = item and item.Name or itemId
			title.TextColor3 = Color3.fromRGB(95, 220, 120)
			title.TextSize = 15
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Parent = card

			local desc = Instance.new("TextLabel")
			desc.BackgroundTransparency = 1
			desc.Position = UDim2.new(0, 14, 0, 30)
			desc.Size = UDim2.new(1, -130, 0, 18)
			desc.Font = Enum.Font.Gotham
			desc.Text = item and (item.Description or "") or ""
			desc.TextColor3 = Color3.fromRGB(180, 180, 185)
			desc.TextSize = 12
			desc.TextXAlignment = Enum.TextXAlignment.Left
			desc.Parent = card

			local qty = Instance.new("TextLabel")
			qty.BackgroundTransparency = 1
			qty.Position = UDim2.new(0, 14, 0, 50)
			qty.Size = UDim2.new(1, -130, 0, 18)
			qty.Font = Enum.Font.GothamBold
			qty.Text = "Quantity: x" .. tostring(amount)
			qty.TextColor3 = Color3.fromRGB(130, 205, 255)
			qty.TextSize = 12
			qty.TextXAlignment = Enum.TextXAlignment.Left
			qty.Parent = card

			if item and (item.Effect == "Clearance" or item.Effect == "RadioAccess") then
				local activateButton = Instance.new("TextButton")
				activateButton.Position = UDim2.new(1, -114, 0.5, -15)
				activateButton.Size = UDim2.new(0, 100, 0, 30)
				activateButton.BackgroundColor3 = Color3.fromRGB(45, 90, 55)
				activateButton.BorderSizePixel = 0
				activateButton.Font = Enum.Font.GothamBold
				activateButton.Text = "ACTIVATE"
				activateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
				activateButton.TextSize = 12
				activateButton.Parent = card

				makeCorner(activateButton, 8)

				activateButton.MouseButton1Click:Connect(function()
					activateButton.Text = "..."

					local success, result = pcall(function()
						return UseInventoryItem:InvokeServer(item.Id)
					end)

					if success and result and result.Success then
						statusLabel.Text = result.Message or "Activated."

						if result.Inventory then
							inventory = result.Inventory
						end

						refreshShop()
					else
						statusLabel.Text =
							(result and result.Message)
							or "Activation failed."

						activateButton.Text = "ACTIVATE"
					end
				end)
			end
		end
	end

	for boostKey, endsAt in pairs(inventory.Boosts or {}) do
		local remaining = math.max(0, tonumber(endsAt) - os.time())

		if remaining > 0 then
			count += 1

			createInventoryCard(
				boostKey,
				"Active temporary boost",
				"Remaining: " .. formatTime(remaining),
				Color3.fromRGB(255, 220, 120)
			)
		end
	end

	emptyLabel.Visible = count == 0
	emptyLabel.Text = "No owned items yet."

	updateCanvas()
end

function renderShopItems()
	updateTabs()
	clearShopItems()

	if selectedCategory == "Inventory" then
		renderInventory()
		return
	end

	local count = 0

	if selectedCategory == "Gold Items" then
		count += 1
		createRiotCard()
	end

	for _, item in ipairs(shopItems) do
		if item.Enabled and item.Category == selectedCategory then
			count += 1
			createItemCard(item)
		end
	end

	emptyLabel.Visible = count == 0
	emptyLabel.Text = "No items available in this category."

	updateCanvas()
end

function refreshShop()
	updateBalance()

	local successItems, resultItems = pcall(function()
		return GetShopItems:InvokeServer()
	end)

	if successItems and typeof(resultItems) == "table" then
		shopItems = resultItems
	else
		shopItems = {}
		statusLabel.Text = "Failed to load shop items."
	end

	local successInventory, resultInventory = pcall(function()
		return GetInventory:InvokeServer()
	end)

	if successInventory and typeof(resultInventory) == "table" then
		inventory = resultInventory
	else
		inventory = {}
	end

	inventory.OwnedItems = inventory.OwnedItems or {}
	inventory.Consumables = inventory.Consumables or {}
	inventory.Boosts = inventory.Boosts or {}
	inventory.Loadout = inventory.Loadout or { Primary = nil, Secondary = nil, Equipment = {} }
	inventory.ServerLifeLoadout = inventory.ServerLifeLoadout or { Primary = nil, Secondary = nil, Equipment = {} }

	renderShopItems()
end

cashTab.MouseButton1Click:Connect(function()
	selectedCategory = "Cash Items"
	statusLabel.Text = ""
	renderShopItems()
end)

goldTab.MouseButton1Click:Connect(function()
	selectedCategory = "Gold Items"
	statusLabel.Text = ""
	renderShopItems()
end)

inventoryTab.MouseButton1Click:Connect(function()
	selectedCategory = "Inventory"
	statusLabel.Text = "Owned items are equipped at the Black Market dealer."
	renderShopItems()
end)

buyGoldButton.MouseButton1Click:Connect(function()
	goldFrame.Visible = true
	shopFrame.Visible = false
	dailyFrame.Visible = false
end)

openButton.MouseButton1Click:Connect(function()
	shopFrame.Visible = not shopFrame.Visible
	dailyFrame.Visible = false
	goldFrame.Visible = false

	if shopFrame.Visible then
		statusLabel.Text = ""
		refreshShop()
	end
end)

dailyButton.MouseButton1Click:Connect(function()
	dailyFrame.Visible = not dailyFrame.Visible
	shopFrame.Visible = false
	goldFrame.Visible = false

	if dailyFrame.Visible then
		refreshDaily()
		startDailyCountdown()
	end
end)

shopClose.MouseButton1Click:Connect(function()
	shopFrame.Visible = false
end)

dailyClose.MouseButton1Click:Connect(function()
	dailyFrame.Visible = false
end)

goldClose.MouseButton1Click:Connect(function()
	goldFrame.Visible = false
	shopFrame.Visible = true
	refreshShop()
end)

claimButton.MouseButton1Click:Connect(function()
	if not currentDailyStatus or not currentDailyStatus.CanClaim then
		return
	end

	claimButton.Text = "CLAIMING..."

	local remoteSuccess, success, result = pcall(function()
		return ClaimDailyReward:InvokeServer()
	end)

	if remoteSuccess and success then
		local reward = result.Reward or {}
		local messageParts = {}

		if reward.Cash and reward.Cash > 0 then
			table.insert(messageParts, "+$" .. formatNumber(reward.Cash) .. " Cash")
		end

		if reward.Gold and reward.Gold > 0 then
			table.insert(messageParts, "+" .. formatNumber(reward.Gold) .. " Gold")
		end

		dailyStatus.Text = "Claimed Day " .. tostring(result.Day or "?") .. ": " .. table.concat(messageParts, " + ")
		updateBalance()

		task.wait(0.5)
		refreshDaily()
	elseif remoteSuccess then
		dailyStatus.Text = tostring(success or "Failed to claim daily reward.")
		refreshDaily()
	else
		dailyStatus.Text = tostring(success or "Failed to claim daily reward.")
		refreshDaily()
	end
end)

player:GetAttributeChangedSignal("Cash"):Connect(updateBalance)
player:GetAttributeChangedSignal("Gold"):Connect(updateBalance)
player:GetAttributeChangedSignal("USARF_InMenu"):Connect(updateVisibility)

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale)
end

task.spawn(function()
	while true do
		if shopFrame.Visible then
			if selectedCategory == "Inventory" then
				renderInventory()
			elseif #boostCountdowns > 0 then
				-- Tick the countdown text in place (re-rendering every second would reset the
				-- scroll position and any in-progress purchase). Re-render once a boost ends so
				-- its card switches back to BUY.
				local anyExpired = false

				for _, countdown in ipairs(boostCountdowns) do
					local remaining = getBoostRemaining(countdown.BoostKey)

					if remaining > 0 then
						countdown.Label.Text = "Remaining: " .. formatTime(remaining)
					else
						anyExpired = true
					end
				end

				if anyExpired then
					renderShopItems()
				end
			end
		end

		task.wait(1)
	end
end)

applyScale()
updateBalance()
updateVisibility()

print("[ShopController] Initialized")