local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local FacilityLockdownService = require(Services:WaitForChild("FacilityLockdownService"))
local FacilityStatusService = require(Services:WaitForChild("FacilityStatusService"))

local function joinFrom(args, index)
	local output = {}

	for i = index, #args do
		table.insert(output, args[i])
	end

	return table.concat(output, " ")
end

return {
	Name = "lockdown",
	Aliases = { "ld", "lockdownlevel", "ldlevel" },
	Description = "Sets the facility lockdown level.",
	Usage = "lockdown [0-4] [reason]",
	Category = "Facility",
	MinRank = 11,

	Run = function(context, args)
		local level = tonumber(args[2])

		if not level then
			return {
				Type = "Error",
				Message = "Usage: lockdown [0-4] [reason]",
			}
		end

		level = math.clamp(math.floor(level), 0, 4)

		local reason = joinFrom(args, 3)

		if reason == "" then
			reason = "Changed from terminal."
		end

		local state = FacilityLockdownService.SetLevel(level, context.Player, reason)

		if FacilityStatusService and typeof(FacilityStatusService.SetLastEvent) == "function" then
			FacilityStatusService.SetLastEvent("Terminal lockdown level changed to " .. tostring(level))
		end

		return {
			Type = level > 0 and "Warning" or "Success",
			Message = "Lockdown level set to " .. tostring(state.Level) .. ". Active: " .. tostring(state.Active),
		}
	end,
}