local ServerScriptService = game:GetService("ServerScriptService")
local CombatRulesService = require(ServerScriptService:WaitForChild("USARF"):WaitForChild("Services"):WaitForChild("CombatRulesService"))
local function clean(value) return string.lower(tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
return function(context, mode)
	mode = clean(mode)
	if mode == "" or mode == "status" then return CombatRulesService.GetStatusText() end
	local success, result = CombatRulesService.SetMode(mode)
	if not success then return tostring(result) end
	return CombatRulesService.GetStatusText()
end
