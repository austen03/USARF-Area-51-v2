local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_FOLDER_NAME = "USARF_Remotes"
local REMOTE_NAME = "CmdrClearOutput"

local function getRemote()
	local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)

	if not folder then
		folder = Instance.new("Folder")
		folder.Name = REMOTE_FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	local remote = folder:FindFirstChild(REMOTE_NAME)

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = REMOTE_NAME
		remote.Parent = folder
	end

	return remote
end

return function(context)
	local executor = context.Executor

	if executor then
		getRemote():FireClient(executor)
	end

	return nil
end
