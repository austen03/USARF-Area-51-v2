local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer

local USARFFolder = ReplicatedStorage:WaitForChild("USARF")
local ConfigFolder = USARFFolder:WaitForChild("Config")
local RemotesFolder = USARFFolder:WaitForChild("Remotes")

local Config = require(ConfigFolder:WaitForChild("ScramblerConfig"))
local Remote = RemotesFolder:WaitForChild(Config.RemoteName)

local debounce = false
local isScrambled = false

local function notify(message)
	if message == nil or message == "" then
		return
	end

	if _G.USARFNotify then
		_G.USARFNotify("Scrambler System", message, 4, "Normal")
	end
end

local function safeInvoke(action)
	local success, result = pcall(function()
		return Remote:InvokeServer(action)
	end)

	if not success then
		warn("[ScramblerClient] Remote failed:", result)
		return nil
	end

	return result
end

local function refreshState()
	local result = safeInvoke("GetState")

	if result and result.Success then
		isScrambled = result.IsScrambled == true
	else
		isScrambled = false
	end
end

local function toggleScrambler()
	if debounce then
		return
	end

	debounce = true

	local result = safeInvoke("Toggle")

	if result then
		isScrambled = result.IsScrambled == true

		if result.Message then
			notify(result.Message)
		end
	end

	task.delay(Config.CooldownSeconds or 1.5, function()
		debounce = false
	end)
end

local function scramblerAction(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		toggleScrambler()
	end

	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction(
	"USARF_ToggleScrambler",
	scramblerAction,
	false,
	Config.ToggleKey or Enum.KeyCode.R
)

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
	isScrambled = false
end)

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	refreshState()
end)

task.defer(function()
	task.wait(1)
	refreshState()
end)

print("[ScramblerClient] Loaded.")