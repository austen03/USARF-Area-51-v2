local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local FacilityAnnouncementService = require(Services:WaitForChild("FacilityAnnouncementService"))
local FacilityStatusService = require(Services:WaitForChild("FacilityStatusService"))

return {
	Name = "event",
	Aliases = { "facilityevent" },
	Description = "Plays a configured facility event announcement.",
	Usage = "event [eventName]",
	Category = "Facility",
	MinRank = 13,

	Run = function(context, args)
		local eventName = args[2]

		if not eventName then
			return {
				Type = "Error",
				Message = "Usage: event [eventName]",
			}
		end

		local success = FacilityAnnouncementService.PlayEvent(eventName, 3)

		if not success then
			return {
				Type = "Error",
				Message = "Unknown event audio config: " .. tostring(eventName),
			}
		end

		if FacilityStatusService and typeof(FacilityStatusService.SetLastEvent) == "function" then
			FacilityStatusService.SetLastEvent("Terminal played facility event: " .. tostring(eventName))
		end

		return {
			Type = "Success",
			Message = "Facility event announcement queued: " .. tostring(eventName),
		}
	end,
}