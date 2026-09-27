local ServerScriptService = game:GetService("ServerScriptService")

local ClanService = require(ServerScriptService:WaitForChild("USARF"):WaitForChild("Services"):WaitForChild("ClanService"))

return function(_, tag)
	local _, message = ClanService.StaffInfo(tag)
	return message
end
