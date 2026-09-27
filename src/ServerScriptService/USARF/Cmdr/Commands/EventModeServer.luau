local ServerScriptService = game:GetService("ServerScriptService")

local EventServerService = require(
	ServerScriptService:WaitForChild("USARF")
		:WaitForChild("Services")
		:WaitForChild("EventServerService")
)

local function clean(value)
	return string.lower(
		tostring(value or "")
			:gsub("^%s+", "")
			:gsub("%s+$", "")
	)
end

return function(context, mode)
	mode = clean(mode)

	if mode == "" or mode == "status" then
		local status = EventServerService.GetPublicStatus()

		if status.enabled ~= true then
			return "Event server is OFF."
		end

		return string.format(
			"Event server is ON | Name: %s | State: %s | Players: %d/%d",
			tostring(status.name or "Event Server"),
			tostring(status.state or "ready"),
			tonumber(status.playerCount) or 0,
			tonumber(status.maxPlayers) or 0
		)
	end

	if mode == "on" then
		local success, message =
			EventServerService.CreateReservedEventServer(
				context.Executor
			)

		return tostring(message)
	end

	if mode == "off" then
		local success, message =
			EventServerService.DisableActiveEventServer(
				context.Executor
			)

		return tostring(message)
	end

	return "Mode must be on, off, or status."
end
