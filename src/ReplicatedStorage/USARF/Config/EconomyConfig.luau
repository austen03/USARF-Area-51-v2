local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Config = USARF:WaitForChild("Config")

local USARFConfig = require(Config:WaitForChild("USARFConfig"))

local EconomyConfig = USARFConfig.Economy

EconomyConfig.Gamepasses = USARFConfig.Gamepasses
EconomyConfig.DevProducts = USARFConfig.DevProducts

EconomyConfig.ShopCategories = EconomyConfig.ShopCategories or {
	CashItems = "Cash Items",
	GoldItems = "Gold Items",
}

EconomyConfig.ShopItems = EconomyConfig.ShopItems or {}

EconomyConfig.DailyReward = EconomyConfig.DailyReward or {
	CooldownSeconds = 86400,
	Rewards = {},
}

return EconomyConfig