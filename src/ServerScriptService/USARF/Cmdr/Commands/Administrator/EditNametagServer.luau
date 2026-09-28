local ServerScriptService = game:GetService("ServerScriptService")

local NameTagService = require(
	ServerScriptService:WaitForChild("USARF")
		:WaitForChild("Services")
		:WaitForChild("NameTagService")
)

local function clean(value)
	return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

return function(context, player, displayedName, displayedRank, color)
	displayedName = clean(displayedName)
	displayedRank = clean(displayedRank)

	if string.lower(displayedName) == "clear" then
		NameTagService.ClearNameTagOverrides(player)
		return "Cleared all nametag overrides for " .. player.Name .. "."
	end

	local changed = {}

	if displayedName ~= "" and displayedName ~= "." then
		NameTagService.SetDisplayedNameOverride(player, displayedName)
		table.insert(changed, "name")
	end

	if displayedRank ~= "" and displayedRank ~= "." then
		NameTagService.SetDisplayedRankOverride(player, displayedRank)
		table.insert(changed, "rank")
	end

	if typeof(color) == "Color3" then
		NameTagService.SetColorOverride(player, color)
		table.insert(changed, "color")
	end

	if #changed == 0 then
		return "No nametag fields were changed."
	end

	return "Updated " .. table.concat(changed, ", ") .. " nametag field(s) for " .. player.Name .. "."
end
