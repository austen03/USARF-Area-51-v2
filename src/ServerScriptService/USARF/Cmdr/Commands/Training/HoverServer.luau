local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local DeveloperCommandBridge = Remotes:WaitForChild("DeveloperCommandBridge")

local function formatDistance(value)
	value = tonumber(value) or 0
	return string.format("%.1f studs", value)
end

return function(context)
	local executor = context.Executor

	if not executor or not executor.Parent then
		return "Unable to locate the command executor."
	end

	local success, result = pcall(function()
		return DeveloperCommandBridge:InvokeClient(executor, "GetHoveredPlayer")
	end)

	if not success then
		return "Could not inspect your mouse target: " .. tostring(result)
	end

	if type(result) ~= "table" or result.success ~= true then
		return tostring(
			type(result) == "table" and result.message
				or "Your mouse is not hovering over a player."
		)
	end

	return table.concat({
		"Target",
		"",
		"Username",
		tostring(result.username or "Unknown"),
		"",
		"Display Name",
		tostring(result.displayName or "Unknown"),
		"",
		"UserId",
		tostring(result.userId or 0),
		"",
		"Team",
		tostring(result.team or "No Team"),
		"",
		"Distance",
		formatDistance(result.distance),
	}, "\n")
end
