local DataStoreService = game:GetService("DataStoreService")

local EconomyAnalyticsService = {}

local DATASTORE_NAME = "USARF_EconomyAnalytics_v2"
local dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

local analytics = {
	TotalCashGenerated = 0,
	TotalGoldGenerated = 0,

	TotalPaychecksIssued = 0,
	TotalDailyRewardsClaimed = 0,

	TotalShopPurchases = 0,
	TotalGoldPurchases = 0,

	TotalCashSpent = 0,
	TotalGoldSpent = 0,

	MostPurchasedItems = {},
	MostPurchasedPackages = {},

	Daily = {},
	DepartmentEarnings = {},
	DepartmentSpending = {},
}

local loaded = false

local function todayKey()
	return os.date("!%Y-%m-%d", os.time())
end

local function deepCopy(source)
	local copy = {}

	for key, value in pairs(source) do
		if typeof(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end

	return copy
end

local function getDepartmentName(player)
	if not player then
		return "Unknown"
	end

	local attrTeam = player:GetAttribute("USARF_TeamName")
	if attrTeam and attrTeam ~= "" then
		return attrTeam
	end

	if player.Team then
		return player.Team.Name
	end

	return "Unknown"
end

local function getDaily()
	local key = todayKey()

	analytics.Daily[key] = analytics.Daily[key] or {
		CashGenerated = 0,
		GoldGenerated = 0,
		CashSpent = 0,
		GoldSpent = 0,
		PaychecksIssued = 0,
		DailyRewardsClaimed = 0,
		ShopPurchases = 0,
		GoldPurchases = 0,
	}

	return analytics.Daily[key]
end

local function addDepartmentAmount(container, departmentName, amount)
	departmentName = tostring(departmentName or "Unknown")
	amount = math.max(0, tonumber(amount) or 0)

	container[departmentName] = (container[departmentName] or 0) + amount
end

local function incrementCounter(map, key)
	key = tostring(key or "Unknown")
	map[key] = (map[key] or 0) + 1
end

local function getTopMap(map, limit)
	local rows = {}

	for key, value in pairs(map or {}) do
		table.insert(rows, {
			Name = key,
			Value = value,
		})
	end

	table.sort(rows, function(a, b)
		return a.Value > b.Value
	end)

	local output = {}

	for index = 1, math.min(limit or 10, #rows) do
		table.insert(output, rows[index])
	end

	return output
end

function EconomyAnalyticsService.Load()
	if loaded then
		return
	end

	local success, result = pcall(function()
		return dataStore:GetAsync("Analytics")
	end)

	if success and typeof(result) == "table" then
		for key, value in pairs(result) do
			analytics[key] = value
		end
	end

	analytics.Daily = analytics.Daily or {}
	analytics.DepartmentEarnings = analytics.DepartmentEarnings or {}
	analytics.DepartmentSpending = analytics.DepartmentSpending or {}
	analytics.MostPurchasedItems = analytics.MostPurchasedItems or {}
	analytics.MostPurchasedPackages = analytics.MostPurchasedPackages or {}

	loaded = true

	print("[EconomyAnalyticsService] Loaded")
end

function EconomyAnalyticsService.Save()
	local success, err = pcall(function()
		dataStore:SetAsync("Analytics", analytics)
	end)

	if not success then
		warn("[EconomyAnalyticsService] Failed to save:", err)
	end
end

function EconomyAnalyticsService.GetAnalytics()
	return deepCopy(analytics)
end

function EconomyAnalyticsService.GetTodayAnalytics()
	return deepCopy(getDaily())
end

function EconomyAnalyticsService.GetDashboard()
	local today = getDaily()

	local netCash = analytics.TotalCashGenerated - analytics.TotalCashSpent
	local netGold = analytics.TotalGoldGenerated - analytics.TotalGoldSpent

	local economyHealth = "Stable"

	if netCash > 1000000 then
		economyHealth = "Inflated"
	elseif analytics.TotalCashGenerated > 0 and analytics.TotalCashSpent / analytics.TotalCashGenerated > 0.75 then
		economyHealth = "Healthy Sink"
	elseif analytics.TotalCashGenerated < 10000 then
		economyHealth = "Low Activity"
	end

	return {
		Today = deepCopy(today),

		Totals = {
			TotalCashGenerated = analytics.TotalCashGenerated,
			TotalGoldGenerated = analytics.TotalGoldGenerated,
			TotalPaychecksIssued = analytics.TotalPaychecksIssued,
			TotalDailyRewardsClaimed = analytics.TotalDailyRewardsClaimed,
			TotalShopPurchases = analytics.TotalShopPurchases,
			TotalGoldPurchases = analytics.TotalGoldPurchases,
			TotalCashSpent = analytics.TotalCashSpent,
			TotalGoldSpent = analytics.TotalGoldSpent,
			NetCash = netCash,
			NetGold = netGold,
		},

		TopEarningDepartments = getTopMap(analytics.DepartmentEarnings, 10),
		TopSpendingDepartments = getTopMap(analytics.DepartmentSpending, 10),
		MostPurchasedItems = getTopMap(analytics.MostPurchasedItems, 10),
		MostPurchasedPackages = getTopMap(analytics.MostPurchasedPackages, 10),

		EconomyHealth = economyHealth,
	}
end

function EconomyAnalyticsService.IncrementCashGenerated(amount, player)
	amount = math.max(0, tonumber(amount) or 0)

	analytics.TotalCashGenerated += amount
	getDaily().CashGenerated += amount

	if player then
		addDepartmentAmount(analytics.DepartmentEarnings, getDepartmentName(player), amount)
	end
end

function EconomyAnalyticsService.IncrementGoldGenerated(amount)
	amount = math.max(0, tonumber(amount) or 0)

	analytics.TotalGoldGenerated += amount
	getDaily().GoldGenerated += amount
end

function EconomyAnalyticsService.IncrementPaychecks(player)
	analytics.TotalPaychecksIssued += 1
	getDaily().PaychecksIssued += 1

	if player then
		incrementCounter(analytics.DepartmentEarnings, getDepartmentName(player) .. " Paychecks")
	end
end

function EconomyAnalyticsService.IncrementDailyRewards()
	analytics.TotalDailyRewardsClaimed += 1
	getDaily().DailyRewardsClaimed += 1
end

function EconomyAnalyticsService.IncrementShopPurchases()
	analytics.TotalShopPurchases += 1
	getDaily().ShopPurchases += 1
end

function EconomyAnalyticsService.IncrementGoldPurchases()
	analytics.TotalGoldPurchases += 1
	getDaily().GoldPurchases += 1
end

function EconomyAnalyticsService.IncrementCashSpent(amount, player)
	amount = math.max(0, tonumber(amount) or 0)

	analytics.TotalCashSpent += amount
	getDaily().CashSpent += amount

	if player then
		addDepartmentAmount(analytics.DepartmentSpending, getDepartmentName(player), amount)
	end
end

function EconomyAnalyticsService.IncrementGoldSpent(amount, player)
	amount = math.max(0, tonumber(amount) or 0)

	analytics.TotalGoldSpent += amount
	getDaily().GoldSpent += amount

	if player then
		addDepartmentAmount(analytics.DepartmentSpending, getDepartmentName(player), amount)
	end
end

function EconomyAnalyticsService.TrackItemPurchase(itemId)
	incrementCounter(analytics.MostPurchasedItems, itemId)
end

function EconomyAnalyticsService.TrackGoldPackage(productId)
	incrementCounter(analytics.MostPurchasedPackages, productId)
end

function EconomyAnalyticsService.Start()
	EconomyAnalyticsService.Load()

	task.spawn(function()
		while true do
			task.wait(300)
			EconomyAnalyticsService.Save()
		end
	end)

	game:BindToClose(function()
		EconomyAnalyticsService.Save()
	end)

	print("[EconomyAnalyticsService] Started")
end

return EconomyAnalyticsService