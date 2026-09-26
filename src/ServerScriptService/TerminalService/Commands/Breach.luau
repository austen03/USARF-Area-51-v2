local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Shared = USARF:WaitForChild("Shared")
local FacilityState = Shared:WaitForChild("FacilityState")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local FacilityAlertService = require(Services:WaitForChild("FacilityAlertService"))
local FacilityStatusService = require(Services:WaitForChild("FacilityStatusService"))

local BreachValue = FacilityState:FindFirstChild("breach")

if not BreachValue then
	BreachValue = Instance.new("BoolValue")
	BreachValue.Name = "breach"
	BreachValue.Value = false
	BreachValue.Parent = FacilityState
end

local function parseBool(value)
	value = string.lower(tostring(value or ""))

	if value == "true" or value == "on" or value == "yes" or value == "1" then
		return true
	end

	if value == "false" or value == "off" or value == "no" or value == "0" then
		return false
	end

	return nil
end

return {
	Name = "breach",
	Aliases = { "containment", "containmentbreach" },
	Description = "Enables or disables containment breach state.",
	Usage = "breach [true/false]",
	Category = "Facility",
	MinRank = 10,

	Run = function(context, args)
		local value = parseBool(args[2])

		if value == nil then
			return {
				Type = "Error",
				Message = "Usage: breach [true/false]",
			}
		end

		BreachValue.Value = value

		if value then
			FacilityAlertService.SendAlert("Emergency", "Containment Breach", "Containment breach protocol has been activated.", context.Player.Name)
			FacilityStatusService.SetLastEvent("Containment breach activated from terminal.")
		else
			FacilityAlertService.SendAlert("Facility", "Containment Restored", "Containment breach protocol has been cleared.", context.Player.Name)
			FacilityStatusService.SetLastEvent("Containment breach cleared from terminal.")
		end

		return {
			Type = value and "Warning" or "Success",
			Message = "Breach state changed to " .. tostring(value) .. ".",
		}
	end,
}