local StarterGui = game:GetService("StarterGui")

local function setCoreGui()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end)

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)
end

setCoreGui()

task.spawn(function()
	while true do
		setCoreGui()
		task.wait(2)
	end
end)

print("[CoreGuiController] Loaded")