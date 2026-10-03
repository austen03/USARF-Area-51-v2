local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local function setCoreGui()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end)

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	end)
end

local function setChatLayout()
	pcall(function()
		TextChatService.ChatWindowConfiguration.Enabled = false
		TextChatService.ChannelTabsConfiguration.Enabled = false
		TextChatService.ChatInputBarConfiguration.Enabled = true
		TextChatService.BubbleChatConfiguration.Enabled = true
	end)
end

setCoreGui()
setChatLayout()

task.spawn(function()
	while true do
		setCoreGui()
		setChatLayout()
		task.wait(2)
	end
end)

print("[CoreGuiController] Loaded")
