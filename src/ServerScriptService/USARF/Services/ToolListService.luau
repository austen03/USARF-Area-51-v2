local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolListService = {}

local started = false

local USARF = ReplicatedStorage:WaitForChild("USARF")
local Shared = USARF:WaitForChild("Shared")

local TOOL_LIST_FOLDER_NAME = "CmdrToolNames"

local function getOrCreateToolListFolder()
	local folder = Shared:FindFirstChild(TOOL_LIST_FOLDER_NAME)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = TOOL_LIST_FOLDER_NAME
		folder.Parent = Shared
	end

	return folder
end

local function getToolsFolder()
	return ServerStorage:FindFirstChild("Tools")
end

local function rebuildToolList()
	local listFolder = getOrCreateToolListFolder()
	listFolder:ClearAllChildren()

	local toolsFolder = getToolsFolder()

	if not toolsFolder then
		warn("[ToolListService] Missing ServerStorage.Tools")
		return
	end

	local seen = {}
	local names = {}

	for _, descendant in ipairs(toolsFolder:GetDescendants()) do
		if descendant:IsA("Tool") and not seen[descendant.Name] then
			seen[descendant.Name] = true
			table.insert(names, descendant.Name)
		end
	end

	table.sort(names)

	for _, toolName in ipairs(names) do
		local value = Instance.new("StringValue")
		value.Name = toolName
		value.Value = toolName
		value.Parent = listFolder
	end

	print("[ToolListService] Synced " .. tostring(#names) .. " tools for Cmdr autocomplete.")
end

function ToolListService.Refresh()
	rebuildToolList()
end

function ToolListService.Start()
	if started then
		return
	end

	started = true

	rebuildToolList()

	local toolsFolder = getToolsFolder()
	if toolsFolder then
		toolsFolder.DescendantAdded:Connect(function()
			task.wait(0.1)
			rebuildToolList()
		end)

		toolsFolder.DescendantRemoving:Connect(function()
			task.wait(0.1)
			rebuildToolList()
		end)
	end

	print("[ToolListService] Started")
end

return ToolListService