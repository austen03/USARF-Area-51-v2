local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DailyRewardService = {}

local DATASTORE_NAME = "USARF_DailyRewards_v1"
local dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

local EconomyConfig = require(ReplicatedStorage.USARF.Config.EconomyConfig)

local Services = ServerScriptService.USARF.Services
local CurrencyService = require(Services.CurrencyService)
local NotificationService = require(Services.NotificationService)
local EconomyAnalyticsService = require(Services.EconomyAnalyticsService)

local DEFAULT_DAILY_REWARD = {
	CooldownSeconds = 86400,
	Rewards = {
		[1] = { Cash = 250, Gold = 0 },
		[2] = { Cash = 500, Gold = 0 },
		[3] = { Cash = 750, Gold = 0 },
		[4] = { Cash = 1000, Gold = 0 },
		[5] = { Cash = 0, Gold = 1 },
		[6] = { Cash = 0, Gold = 2 },
		[7] = { Cash = 0, Gold = 5 },
	},
}

EconomyConfig.DailyReward = EconomyConfig.DailyReward or DEFAULT_DAILY_REWARD
EconomyConfig.DailyReward.CooldownSeconds = EconomyConfig.DailyReward.CooldownSeconds or DEFAULT_DAILY_REWARD.CooldownSeconds
EconomyConfig.DailyReward.Rewards = EconomyConfig.DailyReward.Rewards or DEFAULT_DAILY_REWARD.Rewards

if #EconomyConfig.DailyReward.Rewards == 0 then
	EconomyConfig.DailyReward.Rewards = DEFAULT_DAILY_REWARD.Rewards
end

local cache = {}
local saving = {}

local function getKey(userId)
	return "Player_" .. tostring(userId)
end

local function defaultData()
	return {
		LastClaim = 0,
		Streak = 0,
	}
end

local function sanitize(data)
	if typeof(data) ~= "table" then
		data = defaultData()
	end

	data.LastClaim = tonumber(data.LastClaim) or 0
	data.Streak = tonumber(data.Streak) or 0

	return data
end

local function formatNumber(value)
	value = tonumber(value) or 0
	return tostring(value):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function formatReward(reward)
	local parts = {}

	if reward.Cash and reward.Cash > 0 then
		table.insert(parts, "+$" .. formatNumber(reward.Cash) .. " Cash")
	end

	if reward.Gold and reward.Gold > 0 then
		table.insert(parts, "+" .. formatNumber(reward.Gold) .. " Gold")
	end

	return table.concat(parts, " + ")
end

function DailyRewardService.Load(player)
	local success, result = pcall(function()
		return dataStore:GetAsync(getKey(player.UserId))
	end)

	if not success then
		warn("[DailyRewardService] Failed to load daily reward data for " .. player.Name .. ": " .. tostring(result))
		cache[player.UserId] = defaultData()
		return false
	end

	cache[player.UserId] = sanitize(result)

	task.defer(function()
		task.wait(2)

		local status = DailyRewardService.GetStatus(player)

		if status.CanClaim then
			NotificationService.Notify(player, {
				Title = "Daily Reward Available",
				Message = "Claim your Day " .. tostring(status.NextDay) .. " reward.",
				Type = "Daily",
				Duration = 6,
			})
		end
	end)

	return true
end

function DailyRewardService.Save(player)
	local data = cache[player.UserId]

	if not data or saving[player.UserId] then
		return
	end

	saving[player.UserId] = true

	local success, result = pcall(function()
		dataStore:SetAsync(getKey(player.UserId), data)
	end)

	saving[player.UserId] = nil

	if not success then
		warn("[DailyRewardService] Failed to save daily reward data for " .. player.Name .. ": " .. tostring(result))
	end
end

function DailyRewardService.GetStatus(player)
	local data = cache[player.UserId]

	if not data then
		data = defaultData()
		cache[player.UserId] = data
	end

	local now = os.time()
	local cooldown = tonumber(EconomyConfig.DailyReward.CooldownSeconds) or DEFAULT_DAILY_REWARD.CooldownSeconds

	local remaining = math.max(0, cooldown - (now - data.LastClaim))
	local canClaim = remaining <= 0

	local nextDay = data.Streak + 1
	if nextDay > 7 then
		nextDay = 1
	end

	return {
		CanClaim = canClaim,
		Remaining = remaining,
		Streak = data.Streak,
		NextDay = nextDay,
		Reward = EconomyConfig.DailyReward.Rewards[nextDay] or DEFAULT_DAILY_REWARD.Rewards[nextDay],
		Rewards = EconomyConfig.DailyReward.Rewards,
	}
end

function DailyRewardService.Claim(player)
	local data = cache[player.UserId]

	if not data then
		DailyRewardService.Load(player)
		data = cache[player.UserId]
	end

	if not data then
		return false, "Daily reward data failed to load"
	end

	local status = DailyRewardService.GetStatus(player)

	if not status.CanClaim then
		NotificationService.Notify(player, {
			Title = "Daily Reward Not Ready",
			Message = "Your next reward is still on cooldown.",
			Type = "Warning",
			Duration = 4,
		})

		return false, "Daily reward not ready yet"
	end

	local reward = status.Reward

	if not reward then
		return false, "Missing reward config"
	end

	data.Streak += 1

	if data.Streak > 7 then
		data.Streak = 1
	end

	data.LastClaim = os.time()

	if reward.Cash and reward.Cash > 0 then
		CurrencyService.Add(
			player,
			"Cash",
			reward.Cash,
			EconomyConfig.TransactionActions.DailyReward,
			{
				Day = data.Streak,
			}
		)

		EconomyAnalyticsService.IncrementCashGenerated(reward.Cash)
	end

	if reward.Gold and reward.Gold > 0 then
		CurrencyService.Add(
			player,
			"Gold",
			reward.Gold,
			EconomyConfig.TransactionActions.DailyReward,
			{
				Day = data.Streak,
			}
		)

		EconomyAnalyticsService.IncrementGoldGenerated(reward.Gold)
	end

	EconomyAnalyticsService.IncrementDailyRewards()

	DailyRewardService.Save(player)

	NotificationService.Notify(player, {
		Title = "Daily Reward Claimed",
		Message = "Day " .. tostring(data.Streak) .. " Reward: " .. formatReward(reward),
		Type = "Daily",
		Duration = 5,
	})

	return true, {
		Day = data.Streak,
		Reward = reward,
		Status = DailyRewardService.GetStatus(player),
	}
end

function DailyRewardService.Start()
	Players.PlayerAdded:Connect(function(player)
		DailyRewardService.Load(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		DailyRewardService.Save(player)
		cache[player.UserId] = nil
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			DailyRewardService.Save(player)
		end
	end)
end

return DailyRewardService