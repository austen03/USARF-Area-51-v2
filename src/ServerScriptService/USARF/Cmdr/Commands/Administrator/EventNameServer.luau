local ServerScriptService = game:GetService("ServerScriptService")

local EventServerService = require(
	ServerScriptService:WaitForChild("USARF")
		:WaitForChild("Services")
		:WaitForChild("EventServerService")
)

local function clean(value)
	return tostring(value or "")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
end

return function(context, name)
	name = clean(name)
	local lowerName = string.lower(name)

	if lowerName == "" or lowerName == "status" then
		local status = EventServerService.GetPublicStatus()

		return "Event server name: "
			.. tostring(status.name or EventServerService.GetDisplayName())
	end

	if lowerName == "clear" or lowerName == "reset" then
		local success, result =
			EventServerService.ClearDisplayName()

		return success
			and "Event server name reset to Event Server."
			or tostring(result)
	end

	local success, result =
		EventServerService.SetActiveDisplayName(name)

	if not success then
		return tostring(result)
	end

	return "Event server name set to "
		.. tostring(result)
		.. "."
end
