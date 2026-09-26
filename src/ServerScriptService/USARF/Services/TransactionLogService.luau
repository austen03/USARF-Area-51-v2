local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local TransactionLogService = {}

local MAX_LOGS_PER_PLAYER = 100

local logs = {}
local EconomyAnalyticsService = nil

local function getUserKey(playerOrUserId)
	if typeof(playerOrUserId) == "Instance" then
		return tostring(playerOrUserId.UserId)
	end

	return tostring(playerOrUserId)
end

local function getAnalyticsService()
	if EconomyAnalyticsService then
		return EconomyAnalyticsService
	end

	local services = ServerScriptService:FindFirstChild("USARF")
		and ServerScriptService.USARF:FindFirstChild("Services")

	if not services then
		return nil
	end

	local module = services:FindFirstChild("EconomyAnalyticsService")

	if not module then
		return nil
	end

	local success, result = pcall(function()
		return require(module)
	end)

	if not success then
		warn("[TransactionLogService] EconomyAnalyticsService unavailable:", result)
		return nil
	end

	EconomyAnalyticsService = result
	return EconomyAnalyticsService
end

local function updateAnalyticsFromTransaction(player, entry)
	local analytics = getAnalyticsService()

	if not analytics then
		return
	end

	if entry.Action == "PAYCHECK" and entry.Currency == "Cash" and entry.Amount > 0 then
		analytics.IncrementCashGenerated(entry.Amount, player)
		analytics.IncrementPaychecks(player)
	end
end

function TransactionLogService.Log(player, action, currencyType, amount, balanceBefore, balanceAfter, metadata)
	if not player then
		return nil
	end

	local userKey = getUserKey(player)

	logs[userKey] = logs[userKey] or {}

	local entry = {
		Id = HttpService:GenerateGUID(false),
		UserId = player.UserId,
		Username = player.Name,
		DisplayName = player.DisplayName,

		Action = tostring(action or "UNKNOWN"),
		Currency = tostring(currencyType or "UNKNOWN"),
		Amount = tonumber(amount) or 0,

		BalanceBefore = tonumber(balanceBefore) or 0,
		BalanceAfter = tonumber(balanceAfter) or 0,

		Metadata = metadata or {},
		Timestamp = os.time(),
	}

	table.insert(logs[userKey], 1, entry)

	while #logs[userKey] > MAX_LOGS_PER_PLAYER do
		table.remove(logs[userKey])
	end

	print("[CurrencyTransaction]", HttpService:JSONEncode(entry))

	updateAnalyticsFromTransaction(player, entry)

	return entry
end

function TransactionLogService.GetRecent(playerOrUserId)
	local userKey = getUserKey(playerOrUserId)
	return logs[userKey] or {}
end

function TransactionLogService.ClearSessionLogs(playerOrUserId)
	local userKey = getUserKey(playerOrUserId)
	logs[userKey] = nil
end

return TransactionLogService