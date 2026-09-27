local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local NotificationService = nil
pcall(function()
	NotificationService = require(Services:WaitForChild("NotificationService"))
end)

return function(context, player)
	if not player or not player.Character then
		return "Target has no character."
	end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return "Target has no humanoid."
	end

	humanoid.Health = humanoid.MaxHealth

	if NotificationService then
		NotificationService.Notify(player, {
			Title = "Healed",
			Message = "You have been healed by staff.",
			Type = "Success",
			Duration = 4,
		})
	end

	return "Healed " .. player.Name .. "."
end
