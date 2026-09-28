local ServerScriptService = game:GetService("ServerScriptService")

local ClanService = require(ServerScriptService:WaitForChild("USARF"):WaitForChild("Services"):WaitForChild("ClanService"))

return function(context, userId)
	local _, message = ClanService.StaffRemoveMember(userId, context.Executor.Name)
	return message
end
