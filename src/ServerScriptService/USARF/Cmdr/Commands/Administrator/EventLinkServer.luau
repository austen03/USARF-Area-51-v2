local ServerScriptService = game:GetService("ServerScriptService")

local EventServerService = require(
	ServerScriptService:WaitForChild("USARF")
		:WaitForChild("Services")
		:WaitForChild("EventServerService")
)

return function()
	local link, errorMessage =
		EventServerService.GetEventLink()

	if not link then
		return tostring(errorMessage)
	end

	return table.concat({
		"Event Server Link",
		"",
		link,
		"",
		"Select and copy the link above.",
	}, "\n")
end
