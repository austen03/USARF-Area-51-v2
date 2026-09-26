local ReplicatedStorage = game:GetService("ReplicatedStorage")

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Remotes = USARF:WaitForChild("Remotes")

local StaffAlertRemote = Remotes:WaitForChild("StaffAlert")

local function notify(payload)
	if not payload then
		return
	end

	local title = payload.title or "Staff Alert"
	local message = payload.message or "No message provided."

	if _G.USARFNotify then
		_G.USARFNotify(title, message, 6)
	end

	print(
		string.format(
			"[StaffAlert] %s | %s | %s",
			payload.severity or "Info",
			title,
			payload.caseId or "UNKNOWN"
		)
	)
end

StaffAlertRemote.OnClientEvent:Connect(notify)

print("USARF StaffAlertController initialized")