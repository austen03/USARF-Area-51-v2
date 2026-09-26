local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local CmdrPermissionService = require(Services:WaitForChild("CmdrPermissionService"))
local CmdrAuditService = require(Services:WaitForChild("CmdrAuditService"))

local function getCommandName(context)
	return string.lower(tostring(
		context.Name
			or (context.Command and context.Command.Name)
			or context.Alias
			or ""
		))
end

local function getRawText(context)
	return tostring(
		context.RawText
			or context.Raw
			or context.Input
			or context.Name
			or ""
	)
end

return function(context)
	local executor = context.Executor

	if not executor then
		return "No command executor."
	end

	local commandName = getCommandName(context)
	local rawText = getRawText(context)

	local canRun, reason, permissionContext = CmdrPermissionService.CanRun(executor, commandName)

	if not canRun then
		CmdrAuditService.LogDenied(executor, commandName, {
			rawText,
		}, reason)

		return reason or "You do not have permission to run this command."
	end

	CmdrAuditService.LogCommandStart(executor, commandName, {
		rawText,
	}, permissionContext)

	return nil
end