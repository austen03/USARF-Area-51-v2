local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local CmdrPermissionService = require(Services:WaitForChild("CmdrPermissionService"))

return function(context)
	local player = context.Executor
	local levelName, levelValue, source, reserveDepartmentKey = CmdrPermissionService.GetAdminLevel(player)

	return string.format(
		"Level: %s (%s) | Source: %s | Reserve Department: %s",
		levelName,
		tostring(levelValue),
		source or "None",
		reserveDepartmentKey or "None"
	)
end
