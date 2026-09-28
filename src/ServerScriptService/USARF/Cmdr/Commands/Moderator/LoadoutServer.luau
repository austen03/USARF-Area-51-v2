local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")

local UniformService = require(Services:WaitForChild("UniformService"))

local function isEmpty(loadout)
	return not loadout.Cleared and not loadout.Division and not loadout.Class and not loadout.SubClass
end

-- Returns the player's new loadout for the action, or false to leave it unchanged.
local function buildLoadout(current, action, value, className)
	local loadout = if current then table.clone(current) else {}

	if action == "setDivision" then
		-- Sub classes belong to a division, so a new division starts without one.
		if loadout.Division ~= value then
			loadout.SubClass = nil
		end

		loadout.Cleared = nil
		loadout.Division = value
		loadout.Class = className
	elseif action == "setClass" then
		loadout.Cleared = nil
		loadout.Class = value
	elseif action == "setSubClass" then
		loadout.SubClass = value
	elseif action == "clear" then
		loadout = { Cleared = true }
	elseif action == "clearClass" then
		loadout.Class = nil
	elseif action == "clearSubClass" then
		loadout.SubClass = nil
	elseif action == "default" then
		return nil
	elseif action == "apply" then
		return false
	end

	-- Nothing left to override: fall back to the normal team/rank uniform.
	return if isEmpty(loadout) then nil else loadout
end

local function describe(action, value, className)
	if action == "setDivision" then
		return if className then `wearing {value} / {className}` else `division set to {value} (class by rank)`
	elseif action == "setClass" then
		return `class set to {value}`
	elseif action == "setSubClass" then
		return `sub class set to {value}`
	elseif action == "clear" then
		return "uniform cleared"
	elseif action == "clearClass" then
		return "class back to their rank's uniform"
	elseif action == "clearSubClass" then
		return "sub class cleared"
	elseif action == "default" then
		return "back to their default uniform"
	end

	return "loadout re-applied"
end

return function(context, players, action, value, className)
	local changed = {}
	local failures = {}

	for _, player in ipairs(players) do
		if player and player.Parent then
			local loadout = buildLoadout(UniformService.GetLoadout(player), action, value, className)
			local success, errorMessage

			if loadout == false then
				success = UniformService.ReapplyUniform(player)
				errorMessage = if success then nil else "no character"
			else
				success, errorMessage = UniformService.SetLoadout(player, loadout)
			end

			if success then
				table.insert(changed, player.Name)
			else
				table.insert(failures, `{player.Name}: {errorMessage}`)
			end
		end
	end

	local lines = {}

	if #changed > 0 then
		table.insert(lines, `{table.concat(changed, ", ")} - {describe(action, value, className)}.`)
	end

	for _, failure in ipairs(failures) do
		table.insert(lines, `Failed for {failure}`)
	end

	if #lines == 0 then
		return "No players were changed."
	end

	return table.concat(lines, "\n")
end
