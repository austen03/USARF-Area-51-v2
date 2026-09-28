local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local function makeCaseId()
	local CaseIdService = require(Services:WaitForChild("CaseIdService"))

	if typeof(CaseIdService.Generate) == "function" then
		return CaseIdService.Generate()
	elseif typeof(CaseIdService.Create) == "function" then
		return CaseIdService.Create()
	elseif typeof(CaseIdService.GetNewCaseId) == "function" then
		return CaseIdService.GetNewCaseId()
	end

	return "USARF-" .. string.upper(string.sub(HttpService:GenerateGUID(false), 1, 8))
end

return function(context, player, reason)
	reason = tostring(reason or "No reason provided.")
	local caseId = makeCaseId()

	player:Kick(
		"You have been kicked from USARF Area-51.\n\nReason: "
			.. reason
			.. "\nCase: "
			.. caseId
	)

	return "Kicked player. Case: " .. caseId
end
