local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Controllers = USARFServer:WaitForChild("Controllers")

local TeamController = require(Controllers:WaitForChild("TeamController"))

local function clearTools(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
		or player:FindFirstChild("Backpack")

	if backpack then
		for _, child in ipairs(backpack:GetChildren()) do
			if child:IsA("Tool") then
				child:Destroy()
			end
		end
	end

	local character = player.Character

	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				child:Destroy()
			end
		end
	end
end

return function(context)
	local player = context.Executor

	if not player or not player.Parent then
		return "Unable to locate the command executor."
	end

	clearTools(player)

	local success, message = TeamController.SendPlayerToMenu(
		player,
		"Returned to menu by administration command",
		{
			refreshReason = "cmdr_menu_command",
			forceReload = true,
		}
	)

	if not success then
		return "Could not return to menu: " .. tostring(message or "Unknown error")
	end

	return "Returned to the main menu."
end
