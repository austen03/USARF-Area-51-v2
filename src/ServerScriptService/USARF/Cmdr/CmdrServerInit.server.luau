local ServerScriptService = game:GetService("ServerScriptService")

local Cmdr = require(ServerScriptService:WaitForChild("Cmdr"))

local USARFServer = ServerScriptService:WaitForChild("USARF")
local CmdrFolder = USARFServer:WaitForChild("Cmdr")
local ConfigFolder = USARFServer:WaitForChild("Config")

local CmdrAdminConfig = require(ConfigFolder:WaitForChild("CmdrAdminConfig"))

-- Register the permission hook first so it is always active, even if anything below errors.
Cmdr.Registry:RegisterHook(
	"BeforeRun",
	require(CmdrFolder:WaitForChild("Hooks"):WaitForChild("BeforeRun"))
)

-- Default Cmdr commands disabled.
-- Cmdr:RegisterDefaultCommands()

-- Cmdr 1.13: call methods on Cmdr.Registry directly (Cmdr:Method() still works but prints a deprecation warning).
Cmdr.Registry:RegisterTypesIn(CmdrFolder:WaitForChild("Types"))
Cmdr.Registry:RegisterCommandsIn(CmdrFolder:WaitForChild("Commands"))
Cmdr.Registry:RegisterCommandsIn(CmdrFolder:WaitForChild("ClanCommands"))

local function normalizeCommandName(name)
	return string.lower(tostring(name or ""))
end

local function getDisplayGroup(commandName)
	local commandConfig = CmdrAdminConfig.Commands[normalizeCommandName(commandName)]
		or CmdrAdminConfig.Commands.Default

	if commandConfig and commandConfig.DisplayGroup then
		return commandConfig.DisplayGroup
	end

	if commandConfig and commandConfig.MainServerLevel then
		return CmdrAdminConfig.DisplayGroups[commandConfig.MainServerLevel]
			or commandConfig.MainServerLevel
	end

	return "Moderator"
end

local function applyCommandGroups()
	-- Cmdr 1.13 made Registry.Commands private; GetCommands() is the public replacement.
	local commands = Cmdr.Registry:GetCommands()

	for _, commandObject in ipairs(commands) do
		if type(commandObject) == "table" then
			commandObject.Group = getDisplayGroup(commandObject.Name)
		end
	end
end

applyCommandGroups()

print("[USARF Cmdr] Initialized with USARF-only commands")