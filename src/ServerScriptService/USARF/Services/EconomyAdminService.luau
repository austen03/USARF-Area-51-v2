local ServerScriptService = game:GetService("ServerScriptService")

local EconomyAdminService = {}

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local CurrencyService = require(Services:WaitForChild("CurrencyService"))
local NotificationService = require(Services:WaitForChild("NotificationService"))

local EconomyConfig = require(
	game:GetService("ReplicatedStorage"):WaitForChild("USARF"):WaitForChild("Config"):WaitForChild("EconomyConfig")
)

local function makeMetadata(actor, reason)
	return {
		ActorUserId = actor and actor.UserId or 0,
		ActorName = actor and actor.Name or "System",
		Reason = reason or "No reason provided",
	}
end

local function notify(target, title, message)
	NotificationService.Notify(target, {
		Title = title,
		Message = message,
		Type = "Currency",
		Duration = 5,
	})
end

function EconomyAdminService.AddCash(actor, target, amount, reason)
	local success, balance = CurrencyService.Add(
		target,
		"Cash",
		amount,
		EconomyConfig.TransactionActions.AdminAdd,
		makeMetadata(actor, reason)
	)

	if success then
		notify(target, "Cash Added", "+$" .. tostring(amount) .. " Cash")
	end

	return success, balance
end

function EconomyAdminService.RemoveCash(actor, target, amount, reason)
	local success, balance = CurrencyService.Remove(
		target,
		"Cash",
		amount,
		EconomyConfig.TransactionActions.AdminRemove,
		makeMetadata(actor, reason)
	)

	if success then
		notify(target, "Cash Removed", "-$" .. tostring(amount) .. " Cash")
	end

	return success, balance
end

function EconomyAdminService.SetCash(actor, target, amount, reason)
	local success, balance = CurrencyService.Set(
		target,
		"Cash",
		amount,
		EconomyConfig.TransactionActions.AdminSet,
		makeMetadata(actor, reason)
	)

	if success then
		notify(target, "Cash Updated", "Cash set to $" .. tostring(amount))
	end

	return success, balance
end

function EconomyAdminService.AddGold(actor, target, amount, reason)
	local success, balance = CurrencyService.Add(
		target,
		"Gold",
		amount,
		EconomyConfig.TransactionActions.AdminAdd,
		makeMetadata(actor, reason)
	)

	if success then
		notify(target, "Gold Added", "+" .. tostring(amount) .. " Gold")
	end

	return success, balance
end

function EconomyAdminService.RemoveGold(actor, target, amount, reason)
	local success, balance = CurrencyService.Remove(
		target,
		"Gold",
		amount,
		EconomyConfig.TransactionActions.AdminRemove,
		makeMetadata(actor, reason)
	)

	if success then
		notify(target, "Gold Removed", "-" .. tostring(amount) .. " Gold")
	end

	return success, balance
end

function EconomyAdminService.SetGold(actor, target, amount, reason)
	local success, balance = CurrencyService.Set(
		target,
		"Gold",
		amount,
		EconomyConfig.TransactionActions.AdminSet,
		makeMetadata(actor, reason)
	)

	if success then
		notify(target, "Gold Updated", "Gold set to " .. tostring(amount))
	end

	return success, balance
end

function EconomyAdminService.GetBalance(target)
	return CurrencyService.GetBalance(target)
end

return EconomyAdminService