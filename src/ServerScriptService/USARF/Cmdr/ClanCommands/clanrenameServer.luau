local ServerScriptService = game:GetService("ServerScriptService")

local ClanService = require(ServerScriptService:WaitForChild("USARF"):WaitForChild("Services"):WaitForChild("ClanService"))

return function(context, tag, newName)
	local _, message = ClanService.StaffRename(tag, newName, context.Executor.Name)
	return message
end
