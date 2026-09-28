local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local NameTagService = require(
	Services:WaitForChild("NameTagService")
)

local function clean(value)
	return tostring(value or "")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
end

local function lower(value)
	return string.lower(clean(value))
end

return function(context, player, teamText, action, rankText)
	if not player or not player.Parent then
		return "Player was not found."
	end

	teamText = clean(teamText)
	action = lower(action)
	rankText = clean(rankText)

	local teamKey, teamDisplayName =
		NameTagService.ResolveTeamForOverride(
			player,
			teamText
		)

	if not teamKey then
		return "Could not resolve that team. Use a TeamConfig key, team name, display name, or current."
	end

	if action == "set" then
		if rankText == "" then
			return "A rank value is required when using set."
		end

		local success = NameTagService.SetTeamRankOverride(
			player,
			teamKey,
			rankText
		)

		if not success then
			return "Could not set the nametag rank override."
		end

		return string.format(
			"Set %s's %s nametag rank to %q.",
			player.Name,
			teamDisplayName,
			rankText
		)
	end

	if action == "clear" then
		local cleared =
			NameTagService.ClearTeamRankOverride(
				player,
				teamKey
			)

		if not cleared then
			return string.format(
				"%s had no rank override for %s.",
				player.Name,
				teamDisplayName
			)
		end

		return string.format(
			"Cleared %s's rank override for %s.",
			player.Name,
			teamDisplayName
		)
	end

	return "Action must be set or clear."
end
