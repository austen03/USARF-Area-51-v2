local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")
local FacilityAlertRemote = Remotes:WaitForChild("FacilityAlert")

local function receiveAlert(payload)
	if type(payload) ~= "table" then
		return
	end

	local title = payload.title or "Facility Alert"
	local body = payload.body or "No message provided."
	local category = payload.category or "Facility"
	local priority = payload.priority or "Normal"

	if _G.USARFNotify then
		if priority == "Emergency" then
			_G.USARFNotify("🚨 Emergency Alert", title .. " - " .. body, 12, "Emergency")
		else
			_G.USARFNotify(category .. " Alert", title .. " - " .. body, 6, "Normal")
		end
	end

	if _G.USARFAddAnnouncement then
		_G.USARFAddAnnouncement(payload)
	end

	if _G.USARFRadioMessage then
		_G.USARFRadioMessage({
			channel = "Facility",
			sender = "FACILITY ALERT",
			message = title .. ": " .. body,
			priority = priority,
			category = category,
		})
	end
end

FacilityAlertRemote.OnClientEvent:Connect(receiveAlert)

print("USARF FacilityAlertController initialized")