local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local FacilityAnnouncementService = require(Services:WaitForChild("FacilityAnnouncementService"))

return function(context)
	FacilityAnnouncementService.StopAll()

	return "Facility announcement audio stopped."
end
