local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GamepassService = {}

local EconomyConfig = require(ReplicatedStorage.USARF.Config.EconomyConfig)

local ownershipCache = {}
local checkingCache = {}

local function getGamepassId(gamepassName)
	return EconomyConfig.Gamepasses[gamepassName]
end

local function ensurePlayerCache(player)
	ownershipCache[player.UserId] = ownershipCache[player.UserId] or {}
	checkingCache[player.UserId] = checkingCache[player.UserId] or {}
end

function GamepassService.Has(player, gamepassName)
	if not player then
		return false
	end

	local gamepassId = getGamepassId(gamepassName)

	if not gamepassId then
		warn("[GamepassService] Missing gamepass config:", gamepassName)
		return false
	end

	ensurePlayerCache(player)

	if ownershipCache[player.UserId][gamepassName] ~= nil then
		return ownershipCache[player.UserId][gamepassName]
	end

	if checkingCache[player.UserId][gamepassName] then
		return false
	end

	checkingCache[player.UserId][gamepassName] = true

	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)

	checkingCache[player.UserId][gamepassName] = nil

	if not success then
		warn("[GamepassService] Failed checking " .. gamepassName .. " for " .. player.Name .. ": " .. tostring(result))
		ownershipCache[player.UserId][gamepassName] = false
		return false
	end

	ownershipCache[player.UserId][gamepassName] = result == true
	return ownershipCache[player.UserId][gamepassName]
end

function GamepassService.Refresh(player, gamepassName)
	if not player then
		return false
	end

	ensurePlayerCache(player)

	if gamepassName then
		ownershipCache[player.UserId][gamepassName] = nil
		return GamepassService.Has(player, gamepassName)
	end

	ownershipCache[player.UserId] = {}
	checkingCache[player.UserId] = {}

	return true
end

function GamepassService.GetAll(player)
	if not player then
		return {}
	end

	ensurePlayerCache(player)

	local result = {}

	for gamepassName in pairs(EconomyConfig.Gamepasses) do
		result[gamepassName] = GamepassService.Has(player, gamepassName)
	end

	return result
end

function GamepassService.Start()
	Players.PlayerRemoving:Connect(function(player)
		ownershipCache[player.UserId] = nil
		checkingCache[player.UserId] = nil
	end)

	print("[GamepassService] Initialized")
end

return GamepassService