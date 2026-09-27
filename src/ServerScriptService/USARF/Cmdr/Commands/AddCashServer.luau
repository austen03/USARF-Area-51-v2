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
	elseif typeof(CurrencyService.AddCash) == "function" then
		return CurrencyService.AddCash(player, amount)
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
	local ok, balance = addCurrency(player, "Cash", amount)

	if ok == false then
		return "Failed to add cash."
	end

	balance = balance or player:GetAttribute("Cash") or "?"

	NotificationService.Notify(player, {
		Title = "Cash Added",
		Message = "$" .. tostring(amount) .. " Cash has been added to your account.\nCase: " .. caseId,
		Type = "Success",
		Duration = 6,
	})

	return string.format("Added $%s Cash. New Balance: $%s | Case: %s", amount, tostring(balance), caseId)
end
