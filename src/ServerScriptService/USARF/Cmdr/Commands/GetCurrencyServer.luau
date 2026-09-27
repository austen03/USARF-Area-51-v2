local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local CurrencyService = require(Services:WaitForChild("CurrencyService"))

local function getCurrency(player, currencyName)
	if typeof(CurrencyService.GetCurrency) == "function" then
		return CurrencyService.GetCurrency(player, currencyName)
	elseif typeof(CurrencyService.Get) == "function" then
		return CurrencyService.Get(player, currencyName)
	elseif currencyName == "Cash" and typeof(CurrencyService.GetCash) == "function" then
		return CurrencyService.GetCash(player)
	elseif currencyName == "Gold" and typeof(CurrencyService.GetGold) == "function" then
		return CurrencyService.GetGold(player)
	end

	return tonumber(player:GetAttribute(currencyName)) or 0
end

return function(context, player, currency)
	currency = string.lower(tostring(currency or ""))

	local currencyName

	if currency == "cash" then
		currencyName = "Cash"
	elseif currency == "gold" then
		currencyName = "Gold"
	else
		return "Currency must be cash or gold."
	end

	local balance = getCurrency(player, currencyName)

	if currencyName == "Cash" then
		return string.format("%s Cash: $%s", player.Name, tostring(balance))
	end

	return string.format("%s Gold: %s", player.Name, tostring(balance))
end
