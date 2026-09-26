local ServerScriptService = game:GetService("ServerScriptService")

local USARF = ServerScriptService:WaitForChild("USARF")
local Services = USARF:WaitForChild("Services")

local GamepassService = require(Services:WaitForChild("GamepassService"))
local EconomyAnalyticsService = require(Services:WaitForChild("EconomyAnalyticsService"))
local InventoryService = require(Services:WaitForChild("InventoryService"))
local CurrencyService = require(Services:WaitForChild("CurrencyService"))
local DailyRewardService = require(Services:WaitForChild("DailyRewardService"))
local DevProductService = require(Services:WaitForChild("DevProductService"))
local FacilityLockdownService = require(Services:WaitForChild("FacilityLockdownService"))

local function start(name, service)
	local success, result = pcall(function()
		service.Start()
	end)

	if success then
		print("[CurrencyRunner] Started " .. name)
	else
		warn("[CurrencyRunner] Failed to start " .. name .. ": " .. tostring(result))
	end
end

start("GamepassService", GamepassService)
start("EconomyAnalyticsService", EconomyAnalyticsService)
start("InventoryService", InventoryService)
start("CurrencyService", CurrencyService)
start("DailyRewardService", DailyRewardService)
start("DevProductService", DevProductService)
start("FacilityLockdownService", FacilityLockdownService)