local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PurchaseService = {}

local EconomyConfig = require(ReplicatedStorage.USARF.Config.EconomyConfig)

local USARF = ServerScriptService:WaitForChild("USARF")
local Services = USARF:WaitForChild("Services")

local CurrencyService = require(Services:WaitForChild("CurrencyService"))
local InventoryService = require(Services:WaitForChild("InventoryService"))
local NotificationService = require(Services:WaitForChild("NotificationService"))
local EconomyAnalyticsService = require(Services:WaitForChild("EconomyAnalyticsService"))

local function getItem(itemId)
	for _, item in ipairs(EconomyConfig.ShopItems or {}) do
		if item.Id == itemId then
			return item
		end
	end

	return nil
end

local function formatNumber(value)
	value = tonumber(value) or 0
	return tostring(value):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function formatPrice(item)
	if item.Currency == "Cash" then
		return "$" .. formatNumber(item.Price) .. " Cash"
	end

	if item.Currency == "Gold" then
		return formatNumber(item.Price) .. " Gold"
	end

	return formatNumber(item.Price) .. " " .. tostring(item.Currency)
end

local function notify(player, title, message, notificationType)
	NotificationService.Notify(player, {
		Title = title,
		Message = message,
		Type = notificationType or "Info",
		Duration = 4,
	})
end

local function isPermanentItem(item)
	return item.ItemType == "Permanent" or item.ItemType == "Unlock"
end

local function isLifeItem(item)
	return item.ItemType == "LifeItem"
end

local function isConsumableItem(item)
	return item.ItemType == "Consumable"
end

local function isTimedBoostItem(item)
	return item.ItemType == "TimedBoost"
end

local function refreshAppliedAttributes(player, item)
	if not player or not item then
		return
	end

	if item.Effect == "RadioAccess" then
		player:SetAttribute("USARF_TemporaryRadioAccess", true)
		player:SetAttribute("USARF_RadioAccessRefresh", os.clock())
	end

	if item.Effect == "Clearance" then
		player:SetAttribute("USARF_TemporaryClearance", tonumber(item.ClearanceLevel) or 4)
	end

	if item.Effect == "GoldNametag" then
		player:SetAttribute("USARF_GoldNametag", true)
	end
end

local function applyLifeEffect(player, item)
	refreshAppliedAttributes(player, item)

	if item.Effect == "RadioAccess" then
		return true, "Radio Access activated for this life."
	end

	if item.Effect == "Clearance" then
		return true, "SC-" .. tostring(tonumber(item.ClearanceLevel) or 4) .. " clearance activated for this life."
	end

	return InventoryService.AddConsumable(player, item.Id, tonumber(item.Quantity) or 1)
end

local function grantPackageItems(player, item)
	for _, packageItemId in ipairs(item.PackageItems or {}) do
		InventoryService.GrantItem(player, packageItemId)

		local packageItem = getItem(packageItemId)
		refreshAppliedAttributes(player, packageItem)
	end
end

local function grantPurchasedItem(player, item)
	if isPermanentItem(item) then
		InventoryService.GrantItem(player, item.Id)
		refreshAppliedAttributes(player, item)
		grantPackageItems(player, item)

		return true, "Permanent item unlocked."
	end

	if isLifeItem(item) then
		return applyLifeEffect(player, item)
	end

	if isConsumableItem(item) then
		local quantity = tonumber(item.Quantity) or 1
		return InventoryService.AddConsumable(player, item.Id, quantity)
	end

	if isTimedBoostItem(item) then
		local boostKey = item.Effect or item.Id
		local duration = tonumber(item.DurationSeconds) or 300

		return InventoryService.AddBoost(
			player,
			boostKey,
			duration,
			item.Stackable == true
		)
	end

	InventoryService.GrantItem(player, item.Id)
	refreshAppliedAttributes(player, item)

	return true, "Item granted."
end

function PurchaseService.Purchase(player, itemId)
	local item = getItem(itemId)

	if not item then
		notify(player, "Purchase Failed", "Item does not exist.", "Error")
		return false, "Item does not exist"
	end

	if item.Enabled ~= true then
		notify(player, "Purchase Failed", "This item is currently disabled.", "Warning")
		return false, "Item disabled"
	end

	if isPermanentItem(item) and InventoryService.HasItem(player, item.Id) then
		notify(player, "Already Owned", "You already own " .. item.Name .. ".", "Info")
		return false, "Already owned"
	end

	if not CurrencyService.CanAfford(player, item.Currency, item.Price) then
		notify(player, "Purchase Failed", "Insufficient funds.", "Error")
		return false, "Insufficient funds"
	end

	local success, result = CurrencyService.Remove(
		player,
		item.Currency,
		item.Price,
		EconomyConfig.TransactionActions.ShopPurchase,
		{
			ItemId = item.Id,
			ItemName = item.Name,
			Category = item.Category,
			Price = item.Price,
			Currency = item.Currency,
			ItemType = item.ItemType,
			Effect = item.Effect,
		}
	)

	if not success then
		notify(player, "Purchase Failed", tostring(result or "Failed removing currency."), "Error")
		return false, "Failed removing currency"
	end

	local granted, grantResult = grantPurchasedItem(player, item)

	if not granted then
		CurrencyService.Add(
			player,
			item.Currency,
			item.Price,
			EconomyConfig.TransactionActions.Refund,
			{
				ItemId = item.Id,
				ItemName = item.Name,
				Reason = tostring(grantResult or "Grant failed"),
			}
		)

		notify(player, "Purchase Failed", "Failed granting item. Currency refunded.", "Error")
		return false, "Failed granting item"
	end

	InventoryService.Save(player)

	EconomyAnalyticsService.IncrementShopPurchases()
	EconomyAnalyticsService.TrackItemPurchase(item.Id)

	if item.Currency == "Cash" then
		EconomyAnalyticsService.IncrementCashSpent(item.Price, player)
	elseif item.Currency == "Gold" then
		EconomyAnalyticsService.IncrementGoldSpent(item.Price, player)
	end

	local message = item.Name .. " purchased for " .. formatPrice(item) .. "."

	if isLifeItem(item) and item.Effect then
		message = tostring(grantResult or item.Name .. " activated for this life.")
	elseif isLifeItem(item) and item.ToolName then
		message = item.Name .. " added to your Black Market inventory. Equip it now or save it for your next life."
	elseif isLifeItem(item) then
		message = item.Name .. " added to your Black Market inventory."
	elseif isTimedBoostItem(item) then
		local minutes = math.floor((item.DurationSeconds or 0) / 60)
		message = item.Name .. " activated for " .. tostring(minutes) .. " minute(s)."
	elseif isConsumableItem(item) then
		message = item.Name .. " added to your inventory."
	elseif item.PackageItems then
		message = item.Name .. " unlocked."
	elseif item.Effect == "GoldNametag" then
		message = "Gold Nametag unlocked and enabled."
	end

	notify(player, "Purchase Successful", message, "Shop")

	return true, {
		Item = item,
		Inventory = InventoryService.GetInventory(player),
	}
end

return PurchaseService