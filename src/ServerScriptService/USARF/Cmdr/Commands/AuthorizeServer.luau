local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")
local AuthorizationService = require(Services:WaitForChild("AuthorizationService"))

return function(context, target)
	local ok, message = AuthorizationService.SetAuthorized(target, true)

	if not ok then
		return message or "Failed to authorize target."
	end

	return target.Name .. " has been authorized."
end
