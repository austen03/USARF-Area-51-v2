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

local function addCurrency(player, currencyName, amount)
	if typeof(CurrencyService.AddCurrency) == "function" then
		return CurrencyService.AddCurrency(player, currencyName, amount)
	elseif typeof(CurrencyService.Add) == "function" then
		return CurrencyService.Add(player, currencyName, amount)
	elseif typeof(CurrencyService.AddGold) == "function" then
		return CurrencyService.AddGold(player, amount)
	end

	player:SetAttribute(currencyName, (tonumber(player:GetAttribute(currencyName)) or 0) + amount)
	return true, player:GetAttribute(currencyName)
end

return function(context, player, amount)
	amount = math.floor(tonumber(amount) or 0)

	if amount <= 0 then
		return "Amount must be greater than 0."
	end

	local caseId = makeCaseId()
	local ok, balance = addCurrency(player, "Gold", amount)

	if ok == false then
		return "Failed to add gold."
	end

	balance = balance or player:GetAttribute("Gold") or "?"

	NotificationService.Notify(player, {
		Title = "Gold Added",
		Message = tostring(amount) .. " Gold has been added to your account.\nCase: " .. caseId,
		Type = "Success",
		Duration = 6,
	})

	return string.format("Added %s Gold. New Balance: %s Gold | Case: %s", amount, tostring(balance), caseId)
end
