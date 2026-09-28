local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local CurrencyService = require(Services:WaitForChild("CurrencyService"))
local NotificationService = require(Services:WaitForChild("NotificationService"))

local function makeCaseId()
	local CaseIdService = require(Services:WaitForChild("CaseIdService"))

	if typeof(CaseIdService.Generate) == "function" then
		return CaseIdService.Generate()
	elseif typeof(CaseIdService.Create) == "function" then
		return CaseIdService.Create()
	elseif typeof(CaseIdService.GetNewCaseId) == "function" then
		return CaseIdService.GetNewCaseId()
	end

	return "USARF-" .. string.upper(string.sub(HttpService:GenerateGUID(false), 1, 8))
end

local function removeCurrency(player, currencyName, amount)
	if typeof(CurrencyService.RemoveCurrency) == "function" then
		return CurrencyService.RemoveCurrency(player, currencyName, amount)
	elseif typeof(CurrencyService.Remove) == "function" then
		return CurrencyService.Remove(player, currencyName, amount)
	elseif typeof(CurrencyService.RemoveCash) == "function" then
		return CurrencyService.RemoveCash(player, amount)
	end

	local current = tonumber(player:GetAttribute(currencyName)) or 0
	local newValue = math.max(0, current - amount)
	player:SetAttribute(currencyName, newValue)
	return true, newValue
end

return function(context, player, amount)
	amount = math.floor(tonumber(amount) or 0)

	if amount <= 0 then
		return "Amount must be greater than 0."
	end

	local caseId = makeCaseId()
	local ok, balance = removeCurrency(player, "Cash", amount)

	if ok == false then
		return "Failed to remove cash."
	end

	balance = balance or player:GetAttribute("Cash") or "?"

	NotificationService.Notify(player, {
		Title = "Cash Removed",
		Message = "$" .. tostring(amount) .. " Cash has been removed from your account.\nCase: " .. caseId,
		Type = "Warning",
		Duration = 6,
	})

	return string.format("Removed $%s Cash. New Balance: $%s | Case: %s", amount, tostring(balance), caseId)
end
