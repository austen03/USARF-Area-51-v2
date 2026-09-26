local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer

local USARFFolder = ReplicatedStorage:WaitForChild("USARF")
local ConfigFolder = USARFFolder:WaitForChild("Config")
local RemotesFolder = USARFFolder:WaitForChild("Remotes")

local Config = require(ConfigFolder:WaitForChild("CloakConfig"))
local Remote = RemotesFolder:WaitForChild(Config.RemoteName)

local debounce = false
local isCloaked = false

local function notify(message)
	if message == nil or message == "" then
		return
	end

	if _G.USARFNotify then
		_G.USARFNotify("Cloak System", message, 4, "Normal")
	end
end

local function safeInvoke(action)
	local success, result = pcall(function()
		return Remote:InvokeServer(action)
	end)

	if not success then
		warn("[CloakClient] Remote failed:", result)
		return nil
	end

	return result
end

local function refreshState()
	local result = safeInvoke("GetState")

	if result and result.Success then
		isCloaked = result.IsCloaked == true
	else
		isCloaked = false
	end
end

local function forceUncloakForMenu()
	if not isCloaked then
		return
	end

	local result = safeInvoke("ForceUncloak")
	isCloaked = false

	if result and result.Message and result.Message ~= "" then
		notify(result.Message)
	end
end

local function toggleCloak()
	if debounce then
		return
	end

	debounce = true

	local result = safeInvoke("Toggle")

	if result then
		isCloaked = result.IsCloaked == true

		if result.Message then
			notify(result.Message)
		end
	end

	task.delay(Config.CooldownSeconds or 2, function()
		debounce = false
	end)
end

local function cloakAction(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		toggleCloak()
	end

	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction(
	"USARF_ToggleCloak",
	cloakAction,
	false,
	Config.ToggleKey or Enum.KeyCode.Q
)

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
	isCloaked = false
end)

LocalPlayer:GetAttributeChangedSignal("USARF_InMenu"):Connect(function()
	if LocalPlayer:GetAttribute("USARF_InMenu") ~= false then
		forceUncloakForMenu()
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	refreshState()
end)

task.defer(function()
	task.wait(1)
	refreshState()
end)

print("[CloakClient] Loaded.")