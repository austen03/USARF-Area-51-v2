local ServerScriptService = game:GetService("ServerScriptService")

local EconomyProfileService = {}

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local CurrencyService = require(Services:WaitForChild("CurrencyService"))
local InventoryService = require(Services:WaitForChild("InventoryService"))
local TransactionLogService = require(Services:WaitForChild("TransactionLogService"))
local GamepassService = require(Services:WaitForChild("GamepassService"))
local EconomyAnalyticsService = require(Services:WaitForChild("EconomyAnalyticsService"))

function EconomyProfileService.GetProfile(player)
	if not player then
		return nil
	end

	local balance = CurrencyService.GetBalance(player)
	local inventory = InventoryService.GetInventory(player)
	local transactions = TransactionLogService.GetRecent(player)
	local gamepasses = GamepassService.GetAll(player)

	return {
		UserId = player.UserId,
		Username = player.Name,
		DisplayName = player.DisplayName,

		Currency = {
			Cash = balance.Cash,
			Gold = balance.Gold,
		},

		Inventory = inventory,

		Gamepasses = gamepasses,

		RecentTransactions = transactions,
	}
end

function EconomyProfileService.GetAnalytics()
	return EconomyAnalyticsService.GetAnalytics()
end

return EconomyProfileService