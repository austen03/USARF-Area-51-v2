local ServerScriptService = game:GetService("ServerScriptService")

local DebugStateService = require(
	ServerScriptService:WaitForChild("USARF")
		:WaitForChild("Services")
		:WaitForChild("DebugStateService")
)

local function clean(value)
	return string.lower(
		tostring(value or "")
			:gsub("^%s+", "")
			:gsub("%s+$", "")
	)
end

return function(context, mode)
	local player = context.Executor
	mode = clean(mode)

	local enabled =
		DebugStateService.IsDevModeEnabled(player)

	if mode == "status" then
		return enabled
			and "Developer mode is ON."
			or "Developer mode is OFF."
	end

	if mode == "" or mode == "toggle" then
		enabled =
			DebugStateService.ToggleDevMode(player)
	elseif mode == "on" or mode == "true" then
		enabled =
			DebugStateService.SetDevMode(player, true)
	elseif mode == "off" or mode == "false" then
		enabled =
			DebugStateService.SetDevMode(player, false)
	else
		return "Mode must be on, off, toggle, or status."
	end

	return enabled
		and "Developer mode enabled."
		or "Developer mode disabled."
end
