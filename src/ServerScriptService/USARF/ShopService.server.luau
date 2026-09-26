local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARFReplicated = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARFReplicated:WaitForChild("Remotes")
local Config = USARFReplicated:WaitForChild("Config")

local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local PurchaseService = require(Services:WaitForChild("PurchaseService"))
local InventoryService = require(Services:WaitForChild("InventoryService"))
local DailyRewardService = require(Services:WaitForChild("DailyRewardService"))
local NotificationService = require(Services:WaitForChild("NotificationService"))

local function getOrCreateRemoteFunction(name)
	local remote = Remotes:FindFirstChild(name)

	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = Remotes
	end

	return remote
end

local UseInventoryItem = getOrCreateRemoteFunction("UseInventoryItem")

local function getItem(itemId)
	for _, item in ipairs(EconomyConfig.ShopItems or {}) do
		if item.Id == itemId then
			return item
		end
	end

	return nil
end

local function notify(player, title, message, notificationType)
	NotificationService.Notify(player, {
		Title = title,
		Message = message,
		Type = notificationType or "Info",
		Duration = 4,
	})
end

local function useItem(player, itemId)
	local item = getItem(itemId)

	if not item then
		return {
			Success = false,
			Message = "Item does not exist.",
		}
	end

	local count = InventoryService.GetConsumableCount(player, itemId)

	if count <= 0 and not InventoryService.HasItem(player, itemId) then
		return {
			Success = false,
			Message = "You do not own this item.",
		}
	end

	if item.Effect == "Clearance" then
		local clearance = tonumber(item.ClearanceLevel) or 4

		player:SetAttribute("USARF_TemporaryClearance", clearance)

		if count > 0 then
			InventoryService.UseConsumable(player, itemId, 1)
		end

		InventoryService.Save(player)

		notify(player, "L4 Clearance Activated", "Temporary SC-" .. tostring(clearance) .. " access activated for this life.", "Shop")

		return {
			Success = true,
			Message = "Temporary SC-" .. tostring(clearance) .. " access activated.",
			Inventory = InventoryService.GetInventory(player),
		}
	end

	if item.Effect == "RadioAccess" then
		player:SetAttribute("USARF_TemporaryRadioAccess", true)
		player:SetAttribute("USARF_RadioAccessRefresh", os.clock())

		if count > 0 then
			InventoryService.UseConsumable(player, itemId, 1)
		end

		InventoryService.Save(player)

		notify(player, "Radio Access Activated", "Temporary GENERAL radio read access activated.", "Shop")

		return {
			Success = true,
			Message = "Temporary radio access activated.",
			Inventory = InventoryService.GetInventory(player),
		}
	end

	return {
		Success = false,
		Message = "This item cannot be activated here.",
	}
end

Remotes.GetShopItems.OnServerInvoke = function(player)
	print("[ShopService] GetShopItems requested by", player.Name, "Items:", #EconomyConfig.ShopItems)
	return EconomyConfig.ShopItems
end

Remotes.GetInventory.OnServerInvoke = function(player)
	return InventoryService.GetInventory(player)
end

Remotes.ShopPurchase.OnServerInvoke = function(player, itemId)
	return PurchaseService.Purchase(player, itemId)
end

Remotes.GetDailyRewardStatus.OnServerInvoke = function(player)
	return DailyRewardService.GetStatus(player)
end

Remotes.ClaimDailyReward.OnServerInvoke = function(player)
	return DailyRewardService.Claim(player)
end

UseInventoryItem.OnServerInvoke = function(player, itemId)
	return useItem(player, itemId)
end

print("[ShopService] Initialized")