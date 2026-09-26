local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CmdrClient = require(
	ReplicatedStorage:WaitForChild("CmdrClient")
)

CmdrClient:SetActivationKeys({
	Enum.KeyCode.F2,
})

local function toggleCmdr()
	local success = pcall(function()
		if typeof(CmdrClient.Toggle) == "function" then
			CmdrClient:Toggle()
		elseif typeof(CmdrClient.Show) == "function" then
			CmdrClient:Show()
		elseif CmdrClient.CmdrInterface and typeof(CmdrClient.CmdrInterface.Toggle) == "function" then
			CmdrClient.CmdrInterface:Toggle()
		elseif CmdrClient.CmdrInterface and typeof(CmdrClient.CmdrInterface.Show) == "function" then
			CmdrClient.CmdrInterface:Show()
		end
	end)

	if not success then
		warn("[CmdrClientInit] Failed to toggle Cmdr.")
	end
end

_G.USARFToggleCmdr = toggleCmdr
_G.USARFOpenCmdr = toggleCmdr

print("[USARF CmdrClientInit] Initialized")