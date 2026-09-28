local function getToolNames(container)
	local names = {}

	if not container then
		return names
	end

	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") then
			table.insert(names, child.Name)
		end
	end

	table.sort(names, function(a, b)
		return string.lower(a) < string.lower(b)
	end)

	return names
end

local function formatSection(title, names)
	if #names == 0 then
		return title .. " (0)\n    None"
	end

	local lines = {
		string.format("%s (%d)", title, #names),
	}

	for _, name in ipairs(names) do
		table.insert(lines, "    " .. name)
	end

	return table.concat(lines, "\n")
end

return function(context, player)
	if not player or not player.Parent then
		return "Player was not found."
	end

	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
		or player:FindFirstChild("Backpack")
	local starterGear = player:FindFirstChild("StarterGear")

	local equippedTools = getToolNames(character)
	local backpackTools = getToolNames(backpack)
	local starterTools = getToolNames(starterGear)

	local total = #equippedTools + #backpackTools + #starterTools

	return table.concat({
		"══════════════════════════════════════",
		"USARF Player Tools",
		"══════════════════════════════════════",
		"",
		"Player: " .. player.Name,
		"Total tool entries: " .. tostring(total),
		"",
		formatSection("Equipped", equippedTools),
		"",
		formatSection("Backpack", backpackTools),
		"",
		formatSection("StarterGear", starterTools),
	}, "\n")
end
