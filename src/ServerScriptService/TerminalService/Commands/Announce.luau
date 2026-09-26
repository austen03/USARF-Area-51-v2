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
	Name = "announce",
	Aliases = { "announcement", "broadcast" },
	Description = "Creates a general facility announcement.",
	Usage = "announce [message]",
	Category = "Facility",
	MinRank = 13,

	Run = function(context, args)
		local message = joinFrom(args, 2)

		if message == "" then
			return {
				Type = "Error",
				Message = "Usage: announce [message]",
			}
		end

		FacilityAlertService.SendAlert("Facility", "Facility Announcement", message, context.Player.Name)

		if FacilityStatusService and typeof(FacilityStatusService.SetLastEvent) == "function" then
			FacilityStatusService.SetLastEvent("Terminal announcement: " .. message)
		end

		return {
			Type = "Success",
			Message = "Facility announcement sent.",
		}
	end,
}