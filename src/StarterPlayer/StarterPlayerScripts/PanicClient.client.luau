local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local USARFFolder = ReplicatedStorage:WaitForChild("USARF")
local ConfigFolder = USARFFolder:WaitForChild("Config")
local RemotesFolder = USARFFolder:WaitForChild("Remotes")

local Config = require(ConfigFolder:WaitForChild("PanicConfig"))
local Remote = RemotesFolder:WaitForChild(Config.RemoteName)

local debounce = false

local function notify(message)
	if message == nil or message == "" then
		return
	end

	if _G.USARFNotify then
		_G.USARFNotify("Panic System", message, 4, "Warning", "Small")
	end
end

local function safeInvoke(action)
	local success, result = pcall(function()
		return Remote:InvokeServer(action)
	end)

	if not success then
		warn("[PanicClient] Remote failed:", result)
		return nil
	end

	return result
end

local function activatePanic()
	if debounce then
		return
	end

	debounce = true

	local result = safeInvoke("ActivatePanic")

	if result and result.Message and result.Message ~= "" then
		notify(result.Message)
	end

	task.delay(2, function()
		debounce = false
	end)
end

local function panicAction(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		activatePanic()
	end

	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction(
	"USARF_ActivatePanic",
	panicAction,
	false,
	Config.ToggleKey or Enum.KeyCode.P
)

print("[PanicClient] Loaded.")