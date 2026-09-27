local ServerScriptService = game:GetService("ServerScriptService")

local ClanService = require(ServerScriptService:WaitForChild("USARF"):WaitForChild("Services"):WaitForChild("ClanService"))

return function(context, tag)
	local _, message = ClanService.StaffDelete(tag, context.Executor.Name)
	return message
end
