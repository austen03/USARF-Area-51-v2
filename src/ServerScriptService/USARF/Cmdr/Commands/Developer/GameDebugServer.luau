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
	mode = clean(mode)

	local enabled = DebugStateService.IsGameDebugEnabled()

	if mode == "status" then
		return enabled
			and "Global game debug mode is ON."
			or "Global game debug mode is OFF."
	end

	if mode == "" or mode == "toggle" then
		enabled = DebugStateService.ToggleGameDebug(
			context.Executor
		)
	elseif mode == "on" or mode == "true" then
		enabled = DebugStateService.SetGameDebug(
			true,
			context.Executor
		)
	elseif mode == "off" or mode == "false" then
		enabled = DebugStateService.SetGameDebug(
			false,
			context.Executor
		)
	else
		return "Mode must be on, off, toggle, or status."
	end

	return enabled
		and "Global game debug mode enabled."
		or "Global game debug mode disabled."
end
