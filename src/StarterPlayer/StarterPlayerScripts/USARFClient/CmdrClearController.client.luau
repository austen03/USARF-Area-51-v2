local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remoteFolder = ReplicatedStorage:WaitForChild("USARF_Remotes", 10)
if not remoteFolder then
	warn("[CmdrClearController] Missing USARF_Remotes")
	return
end

local remote = remoteFolder:WaitForChild("CmdrClearOutput", 10)
if not remote then
	warn("[CmdrClearController] Missing CmdrClearOutput")
	return
end

local function isEntryRelated(instance)
	local current = instance

	while current do
		if current.Name == "Entry" then
			return true
		end

		current = current.Parent
	end

	return false
end

local function isAutocompleteRelated(instance)
	local current = instance

	while current do
		if current.Name == "Autocomplete" then
			return true
		end

		current = current.Parent
	end

	return false
end

local function clearScrollingFrame(scrollingFrame)
	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:IsA("GuiObject")
			and not child:IsA("UIListLayout")
			and not child:IsA("UIPadding")
			and not child:IsA("UICorner")
			and not child:IsA("UIStroke")
			and not isEntryRelated(child)
			and not isAutocompleteRelated(child)
		then
			child:Destroy()
		end
	end

	scrollingFrame.CanvasPosition = Vector2.new(0, 0)
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
end

local function clearCmdrOutput()
	local cmdrGui = playerGui:FindFirstChild("Cmdr")
	if not cmdrGui then
		return
	end

	for _, descendant in ipairs(cmdrGui:GetDescendants()) do
		if descendant:IsA("ScrollingFrame")
			and descendant.Name ~= "Autocomplete"
			and not isEntryRelated(descendant)
			and not isAutocompleteRelated(descendant)
		then
			clearScrollingFrame(descendant)
		end
	end
end

remote.OnClientEvent:Connect(clearCmdrOutput)

print("[CmdrClearController] Loaded")