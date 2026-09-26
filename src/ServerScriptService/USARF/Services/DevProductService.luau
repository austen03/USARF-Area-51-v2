local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DevProductService = {}

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")

local EconomyConfig = require(Config:WaitForChild("EconomyConfig"))
local RiotConfig = require(Config:WaitForChild("RiotConfig"))

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local CurrencyService = require(Services:WaitForChild("CurrencyService"))
local NotificationService = require(Services:WaitForChild("NotificationService"))

local EconomyAnalyticsService = require(
	Services:WaitForChild("EconomyAnalyticsService")
)

local RiotService = nil
pcall(function()
	RiotService = require(Services:WaitForChild("RiotService"))
end)

local function formatNumber(value)
	value = tonumber(value) or 0
	return tostring(value):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function processGoldProduct(receiptInfo, productConfig, player)
	local success, result = CurrencyService.Add(
		player,
		productConfig.Currency,
		productConfig.Amount,
		EconomyConfig.TransactionActions.DevProduct,
		{
			ProductId = receiptInfo.ProductId,
			ProductName = productConfig.Name,
			PurchaseId = receiptInfo.PurchaseId,
		}
	)

	if not success then
		warn("[DevProductService] Failed granting product:", receiptInfo.ProductId, result)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	EconomyAnalyticsService.IncrementGoldPurchases()

	EconomyAnalyticsService.IncrementGoldGenerated(
		productConfig.Amount
	)

	EconomyAnalyticsService.TrackGoldPackage(
		receiptInfo.ProductId
	)

	CurrencyService.Save(player)

	NotificationService.Notify(player, {
		Title = "Gold Purchase Successful",
		Message = "+" .. formatNumber(productConfig.Amount) .. " Gold",
		Type = "Currency",
		Duration = 5,
	})

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function processRiotProduct(receiptInfo, player)
	if not RiotService then
		warn("[DevProductService] RiotService unavailable for riot product:", receiptInfo.ProductId)

		NotificationService.Notify(player, {
			Title = "Riot Purchase Failed",
			Message = "Riot system is currently unavailable.",
			Type = "Error",
			Duration = 6,
		})

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local success, result = RiotService.StartPurchasedRiot(player)

	if success then
		NotificationService.Notify(player, {
			Title = "Riot Started",
			Message = "Your 10 minute riot has started.",
			Type = "Success",
			Duration = 6,
		})

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	NotificationService.Notify(player, {
		Title = "Riot Unavailable",
		Message = tostring(result or "Riot could not be started."),
		Type = "Error",
		Duration = 6,
	})

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function DevProductService.ProcessReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId == RiotConfig.ProductId then
		return processRiotProduct(receiptInfo, player)
	end

	local productConfig = EconomyConfig.DevProducts[receiptInfo.ProductId]

	if not productConfig then
		warn("[DevProductService] Unknown developer product:", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return processGoldProduct(receiptInfo, productConfig, player)
end

function DevProductService.Start()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return DevProductService.ProcessReceipt(receiptInfo)
	end

	print("[DevProductService] Initialized")
end

return DevProductService