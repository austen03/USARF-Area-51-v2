local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local FacilityAlertService = require(Services:WaitForChild("FacilityAlertService"))
local FacilityStatusService = require(Services:WaitForChild("FacilityStatusService"))

local function joinFrom(args, index)
	local output = {}

	for i = index, #args do
		table.insert(output, args[i])
	end

	return table.concat(output, " ")
end

return {
	Name = "alert",
	Aliases = { "facilityalert", "sendalert" },
	Description = "Sends a facility alert to all players.",
	Usage = "alert [category] [title/message]",
	Category = "Facility",
	MinRank = 10,

	Run = function(context, args)
		local category = args[2] or "Facility"
		local message = joinFrom(args, 3)

		if message == "" then
			return {
				Type = "Error",
				Message = "Usage: alert [Facility/Emergency/General/Department/Update] [message]",
			}
		end

		local title = category == "Emergency" and "Emergency Alert" or "Facility Alert"

		FacilityAlertService.SendAlert(category, title, message, context.Player.Name)

		if FacilityStatusService and typeof(FacilityStatusService.SetLastEvent) == "function" then
			FacilityStatusService.SetLastEvent("Terminal alert sent: " .. message)
		end

		return {
			Type = category == "Emergency" and "Warning" or "Success",
			Message = "Alert sent under category: " .. tostring(category),
		}
	end,
}