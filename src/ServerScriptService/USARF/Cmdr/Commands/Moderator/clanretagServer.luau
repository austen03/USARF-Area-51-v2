local ServerScriptService = game:GetService("ServerScriptService")

local ClanService = require(ServerScriptService:WaitForChild("USARF"):WaitForChild("Services"):WaitForChild("ClanService"))

return function(context, tag, newTag)
	local _, message = ClanService.StaffRetag(tag, newTag, context.Executor.Name)
	return message
end
