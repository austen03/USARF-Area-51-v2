local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local DeveloperCommandBridge = Remotes:WaitForChild("DeveloperCommandBridge")

return function(context)
	local executor = context.Executor

	if not executor or not executor.Parent then
		return "Unable to locate the command executor."
	end

	local success, result = pcall(function()
		return DeveloperCommandBridge:InvokeClient(executor, "ToggleFreecam")
	end)

	if not success then
		return "Could not toggle freecam: " .. tostring(result)
	end

	if type(result) ~= "table" or result.success ~= true then
		return tostring(
			type(result) == "table" and result.message
				or "Freecam could not be toggled."
		)
	end

	if result.active == true then
		return "Freecam enabled. Press X to exit."
	end

	return "Freecam disabled."
end
