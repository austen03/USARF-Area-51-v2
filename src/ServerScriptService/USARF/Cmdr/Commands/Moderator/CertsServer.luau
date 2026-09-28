local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local CertificationService = require(Services:WaitForChild("CertificationService"))

return function(context, player)
	if not player or not player.Parent then
		return "Player not found."
	end

	CertificationService.Refresh(player)

	local certifications, source = CertificationService.Get(player)

	if source == "Unavailable" then
		return `Couldn't load certifications for {player.Name}: the Discord bot and the sheet are both unreachable.`
	end

	if #certifications == 0 then
		return `{player.Name} has no certifications (source: {source}).`
	end

	return `{player.Name}: {table.concat(certifications, ", ")} (source: {source})`
end
