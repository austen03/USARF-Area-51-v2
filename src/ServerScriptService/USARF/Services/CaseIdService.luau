local HttpService = game:GetService("HttpService")

local CaseIdService = {}

function CaseIdService.Generate(prefix)
	prefix = prefix or "USARF"

	local guid = HttpService:GenerateGUID(false)
	guid = guid:gsub("-", "")
	guid = string.upper(string.sub(guid, 1, 8))

	return prefix .. "-" .. guid
end

return CaseIdService