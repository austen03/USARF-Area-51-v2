local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local CmdrPermissionService = require(Services:WaitForChild("CmdrPermissionService"))

local CmdrAuditService = {}

local started = false

local function safeRequire(serviceName)
	local service = Services:FindFirstChild(serviceName)

	if not service then
		return nil
	end

	local success, result = pcall(function()
		return require(service)
	end)

	if success then
		return result
	end

	warn("[CmdrAuditService] Failed to require " .. serviceName .. ":", result)
	return nil
end

local function getCaseId()
	local CaseIdService = safeRequire("CaseIdService")

	if CaseIdService then
		for _, methodName in ipairs({ "Generate", "Create", "GetNewCaseId" }) do
			if typeof(CaseIdService[methodName]) == "function" then
				local success, result = pcall(function()
					return CaseIdService[methodName]()
				end)

				if success and result then
					return result
				end
			end
		end
	end

	return "USARF-" .. string.upper(string.sub(HttpService:GenerateGUID(false), 1, 8))
end

local function stringifyArgs(args)
	if type(args) ~= "table" then
		return tostring(args or "")
	end

	local parts = {}

	for _, value in ipairs(args) do
		table.insert(parts, tostring(value))
	end

	return table.concat(parts, " ")
end

local function sendToAdminLogService(payload)
	local AdminLogService = safeRequire("AdminLogService")

	if not AdminLogService or typeof(AdminLogService.Log) ~= "function" then
		return
	end

	pcall(function()
		AdminLogService.Log({
			source = "Cmdr",
			action = "Command",
			command = payload.arguments ~= "" and payload.arguments or payload.commandName,
			result = payload.success and "Authorized" or "Denied",
			caseId = payload.caseId,
			reason = payload.reason,

			moderatorUserId = payload.executorUserId,
			moderatorUsername = payload.executorName,

			targetUserId = payload.targetUserId ~= 0 and payload.targetUserId or nil,
			targetUsername = payload.targetName ~= "" and payload.targetName or nil,
		})
	end)
end

local function sendToAuditService(payload)
	local AuditService = safeRequire("AuditService")

	if not AuditService then
		return
	end

	if typeof(AuditService.Log) == "function" then
		pcall(function()
			AuditService.Log(payload)
		end)
	elseif typeof(AuditService.Queue) == "function" then
		pcall(function()
			AuditService.Queue(payload)
		end)
	elseif typeof(AuditService.Record) == "function" then
		pcall(function()
			AuditService.Record(payload)
		end)
	end
end

local function sendToActivityExport(payload)
	local ActivityExportService = safeRequire("ActivityExportService")

	if not ActivityExportService then
		return
	end

	if typeof(ActivityExportService.QueueCmdrLog) == "function" then
		pcall(function()
			ActivityExportService.QueueCmdrLog(payload)
		end)
	elseif typeof(ActivityExportService.QueueAdminLog) == "function" then
		pcall(function()
			ActivityExportService.QueueAdminLog(payload)
		end)
	elseif typeof(ActivityExportService.Queue) == "function" then
		pcall(function()
			ActivityExportService.Queue(payload)
		end)
	end
end

local function sendToWebhook(payload)
	local WebhookService = safeRequire("WebhookService")

	if not WebhookService then
		return
	end

	if typeof(WebhookService.SendCmdrLog) == "function" then
		pcall(function()
			WebhookService.SendCmdrLog(payload)
		end)
	elseif typeof(WebhookService.SendAdminLog) == "function" then
		pcall(function()
			WebhookService.SendAdminLog(payload)
		end)
	elseif typeof(WebhookService.Send) == "function" then
		pcall(function()
			WebhookService.Send("CmdrAdmin", payload)
		end)
	end
end

function CmdrAuditService.BuildPayload(context)
	context = context or {}

	local executor = context.executor
	local levelName, levelValue, source, reserveDepartmentKey = "None", 0, "None", nil

	if executor then
		levelName, levelValue, source, reserveDepartmentKey = CmdrPermissionService.GetAdminLevel(executor)
	end

	local caseId = nil

	if context.requiresCaseId == true then
		caseId = getCaseId()
	end

	return {
		type = "CmdrAdmin",
		caseId = caseId,

		commandName = tostring(context.commandName or "unknown"),
		arguments = stringifyArgs(context.arguments),

		executorName = executor and executor.Name or "Unknown",
		executorUserId = executor and executor.UserId or 0,
		executorAdminLevel = levelName,
		executorAdminLevelValue = levelValue,
		executorAdminSource = source,

		targetName = context.target and context.target.Name or tostring(context.targetName or ""),
		targetUserId = context.target and context.target.UserId or tonumber(context.targetUserId) or 0,

		serverJobId = game.JobId,
		privateServerId = game.PrivateServerId,
		isReserveServer = CmdrPermissionService.IsReserveServer(),
		reserveDepartmentKey = reserveDepartmentKey or CmdrPermissionService.GetReserveDepartmentKey(),

		success = context.success ~= false,
		reason = tostring(context.reason or ""),
		timestamp = os.time(),
	}
end

function CmdrAuditService.Log(context)
	local payload = CmdrAuditService.BuildPayload(context)

	sendToAdminLogService(payload)
	sendToAuditService(payload)
	sendToActivityExport(payload)
	sendToWebhook(payload)

	return payload
end

function CmdrAuditService.LogCommandStart(executor, commandName, arguments, permissionContext)
	local commandConfig = permissionContext and permissionContext.commandConfig

	if commandConfig and commandConfig.Log == false then
		return nil
	end

	return CmdrAuditService.Log({
		executor = executor,
		commandName = commandName,
		arguments = arguments,
		requiresCaseId = commandConfig and commandConfig.CaseId == true,
		success = true,
		reason = "Command authorized.",
	})
end

function CmdrAuditService.LogDenied(executor, commandName, arguments, reason)
	return CmdrAuditService.Log({
		executor = executor,
		commandName = commandName,
		arguments = arguments,
		requiresCaseId = false,
		success = false,
		reason = reason or "Permission denied.",
	})
end

function CmdrAuditService.Start()
	if started then
		return
	end

	started = true
	print("[CmdrAuditService] Started")
end

return CmdrAuditService