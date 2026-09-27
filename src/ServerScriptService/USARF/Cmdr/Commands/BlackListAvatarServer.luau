local ServerScriptService = game:GetService("ServerScriptService")

local AvatarBlacklistService = require(
	ServerScriptService:WaitForChild("USARF")
		:WaitForChild("Services")
		:WaitForChild("AvatarBlacklistService")
)

local function clean(value)
	return string.lower(
		tostring(value or "")
			:gsub("^%s+", "")
			:gsub("%s+$", "")
	)
end

return function(context, action, itemId, itemType)
	action = clean(action)
	itemType = clean(itemType)

	if action == "list" then
		local entries = AvatarBlacklistService.List()

		if #entries == 0 then
			return "The global avatar blacklist is empty."
		end

		local lines = {
			"Global Avatar Blacklist",
			"",
		}

		for _, entry in ipairs(entries) do
			local label = entry.name ~= ""
				and entry.name
				or "Unnamed item"

			table.insert(
				lines,
				string.format(
					"    %d | %s | %s | %d resolved asset(s)",
					entry.id,
					string.upper(entry.itemType),
					label,
					#entry.assetIds
				)
			)
		end

		return table.concat(lines, "\n")
	end

	if action == "clear" then
		local success, result =
			AvatarBlacklistService.Clear()

		if not success then
			return "Unable to clear avatar blacklist: "
				.. tostring(result)
		end

		return "Global avatar blacklist cleared."
	end

	if not itemId then
		return "A catalog asset or bundle ID is required."
	end

	if action == "status" then
		local entry =
			AvatarBlacklistService.GetEntry(itemId)

		if not entry then
			return tostring(itemId)
				.. " is not on the global avatar blacklist."
		end

		return string.format(
			"%d is blacklisted as a %s and resolves to %d asset(s).",
			entry.id,
			string.upper(entry.itemType),
			#entry.assetIds
		)
	end

	if action == "add" then
		local success, result =
			AvatarBlacklistService.Add(
				itemId,
				itemType
			)

		if not success then
			return tostring(result)
		end

		local entry = result.entry
		local label = entry.name ~= ""
			and (" (" .. entry.name .. ")")
			or ""

		return string.format(
			"Blacklisted %s %d%s. Resolved %d asset(s) and removed %d matching avatar item(s).",
			entry.itemType,
			entry.id,
			label,
			#entry.assetIds,
			result.removed
		)
	end

	if action == "remove" then
		local success, result =
			AvatarBlacklistService.Remove(itemId)

		if not success then
			return tostring(result)
		end

		return "Removed avatar item "
			.. tostring(result)
			.. " from the global blacklist."
	end

	return "Action must be add, remove, status, list, or clear."
end
