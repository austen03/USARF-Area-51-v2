local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local USARFServer = ServerScriptService:WaitForChild("USARF")
local Services = USARFServer:WaitForChild("Services")

local AuditService = require(Services:WaitForChild("AuditService"))

local WebhookService = {}

local WEBHOOKS = {
	Activity = "",

	ActivityTeams = {
		["137mp"] = "",
		["engineering"] = "",
		["medical"] = "",
		["research"] = "",
		["rnr"] = "",
		["usaf"] = "",
		["dod"] = "",
		["cia"] = "",
		["fbi"] = "",
		["fds"] = "",
		["secret_service"] = "",
		["108th"] = "",
		["specops"] = "",
	},

	Exploit = "",
	Cmdr = "",
}

local MAX_QUEUE_SIZE = 250
local PROCESS_INTERVAL = 5

local queue = {}
local processing = false

local function trimQueue()
	while #queue > MAX_QUEUE_SIZE do
		table.remove(queue, 1)
	end
end

local function getWebhookUrl(channel, teamKey)
	if channel == "ActivityTeam" then
		return WEBHOOKS.ActivityTeams[tostring(teamKey or "")]
	end

	return WEBHOOKS[channel]
end

function WebhookService.Queue(channel, payload, options)
	options = options or {}

	local url = getWebhookUrl(channel, options.teamKey)

	if channel ~= "ActivityTeam" and WEBHOOKS[channel] == nil then
		return false, "Invalid webhook channel: " .. tostring(channel)
	end

	if channel == "ActivityTeam" and url == nil then
		return false, "Invalid activity team key: " .. tostring(options.teamKey)
	end

	if type(payload) ~= "table" then
		return false, "Payload must be a table"
	end

	local item = {
		channel = channel,
		teamKey = options.teamKey,
		payload = payload,
		queuedAt = os.time(),
		attempts = 0,
		status = "Queued",
	}

	table.insert(queue, item)
	trimQueue()

	print("[WebhookService] Queued", channel, options.teamKey or "")

	return true, item
end

function WebhookService.QueueTeamActivity(teamKey, payload)
	local success = WebhookService.Queue("ActivityTeam", payload, {
		teamKey = teamKey,
	})

	if not success then
		return WebhookService.Queue("Activity", payload)
	end

	return success
end

function WebhookService.GetQueue()
	local copy = {}

	for index, item in ipairs(queue) do
		copy[index] = item
	end

	return copy
end

local function sendItem(item)
	local url = getWebhookUrl(item.channel, item.teamKey)

	if not url or url == "" then
		item.status = "SkippedNoUrl"
		return true
	end

	item.attempts += 1
	item.status = "Sending"

	local success, result = pcall(function()
		return HttpService:PostAsync(url, HttpService:JSONEncode(item.payload), Enum.HttpContentType.ApplicationJson)
	end)

	if success then
		item.status = "Sent"
		return true
	end

	item.status = "Failed"
	item.lastError = tostring(result)

	warn("[WebhookService] Failed:", item.channel, item.teamKey or "", result)

	return false
end

local function processQueue()
	if processing then
		return
	end

	processing = true

	for index = #queue, 1, -1 do
		local item = queue[index]

		if item.status == "Queued" or item.status == "Failed" then
			local sent = sendItem(item)

			if sent then
				table.remove(queue, index)
			elseif item.attempts >= 3 then
				AuditService.Log({
					category = "Webhook",
					action = "DeliveryFailed",
					message = "Webhook failed after 3 attempts: " .. tostring(item.channel),
					severity = "Warning",
					external = false,
					metadata = item,
				})

				table.remove(queue, index)
			end
		end
	end

	processing = false
end

task.spawn(function()
	while true do
		task.wait(PROCESS_INTERVAL)
		processQueue()
	end
end)

print("USARF WebhookService initialized")

return WebhookService
