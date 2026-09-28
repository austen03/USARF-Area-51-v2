local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService
	:WaitForChild("USARF")
	:WaitForChild("Services")

local LeaderboardService = require(
	Services:WaitForChild("LeaderboardService")
)

local function clean(value)
	return string.lower(
		tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
	)
end

return function(context, mode)
	local player = context.Executor

	if not player or not player.Parent then
		return "Unable to locate the command executor."
	end

	mode = clean(mode)

	local current = player:GetAttribute("USARF_HideFromLeaderboard") == true
	local nextValue = current

	if mode == "" or mode == "toggle" then
		nextValue = not current
	elseif mode == "on" or mode == "true" or mode == "hide" then
		nextValue = true
	elseif mode == "off" or mode == "false" or mode == "show" then
		nextValue = false
	elseif mode == "status" then
		return current
			and "You are currently hidden from the leaderboard."
			or "You are currently visible on the leaderboard."
	else
		return "Mode must be on, off, toggle, or status."
	end

	player:SetAttribute("USARF_HideFromLeaderboard", nextValue)
	LeaderboardService.Broadcast()

	if nextValue then
		return "You are now hidden from the leaderboard. Moderators can still see you."
	end

	return "You are now visible on the leaderboard."
end
