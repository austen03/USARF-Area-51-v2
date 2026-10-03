local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CmdrClient = require(ReplicatedStorage:WaitForChild("CmdrClient"))

local player = Players.LocalPlayer

CmdrClient:SetActivationKeys({
	Enum.KeyCode.F2,
})

CmdrClient:SetPlaceName("AREA-51")

local function hasCmdrAccess()
	return (tonumber(player:GetAttribute("USARF_CmdrAdminLevelValue")) or 0) >= 1
		or player:GetAttribute("USARF_CmdrQA") == true
end

local function updateCmdrAccess()
	local allowed = hasCmdrAccess()

	CmdrClient:SetEnabled(allowed)

	if not allowed then
		pcall(function()
			CmdrClient:Hide()
		end)
	end
end

player:GetAttributeChangedSignal("USARF_CmdrAdminLevelValue"):Connect(updateCmdrAccess)
player:GetAttributeChangedSignal("USARF_CmdrQA"):Connect(updateCmdrAccess)
updateCmdrAccess()

local function toggleCmdr()
	if not hasCmdrAccess() then
		return
	end

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
