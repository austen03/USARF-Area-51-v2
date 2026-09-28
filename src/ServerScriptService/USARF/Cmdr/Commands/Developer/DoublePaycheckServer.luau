local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local NotificationService = require(Services:WaitForChild("NotificationService"))

return function(context, value)
	local current = ReplicatedStorage:GetAttribute("USARF_DoublePaycheck") == true
	local newState = value

	if newState == nil then
		newState = not current
	end

	ReplicatedStorage:SetAttribute("USARF_DoublePaycheck", newState == true)

	for _, player in ipairs(Players:GetPlayers()) do
		NotificationService.Notify(player, {
			Title = newState and "2x Paycheck Enabled" or "2x Paycheck Disabled",
			Message = newState and "Server paychecks are now doubled." or "Server paychecks are back to normal.",
			Type = newState and "Success" or "Info",
			Duration = 6,
		})
	end

	return "Server double paycheck is now " .. (newState and "ON." or "OFF.")
end
