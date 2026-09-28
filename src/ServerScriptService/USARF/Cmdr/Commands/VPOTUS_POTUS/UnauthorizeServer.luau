local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")
local AuthorizationService = require(Services:WaitForChild("AuthorizationService"))

return function(context, target)
	local ok, message = AuthorizationService.ClearStatus(target)

	if not ok then
		return message or "Failed to clear authorization."
	end

	return target.Name .. " authorization has been cleared."
end
