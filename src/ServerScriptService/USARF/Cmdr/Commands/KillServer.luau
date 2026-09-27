return function(context, players)
	local killed = 0
	local skipped = 0

	for _, player in ipairs(players or {}) do
		if player and player.Parent then
			local character = player.Character
			local humanoid = character
				and character:FindFirstChildOfClass("Humanoid")

			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
				killed += 1
			else
				skipped += 1
			end
		else
			skipped += 1
		end
	end

	if killed == 0 then
		return "No players were killed."
	end

	if skipped > 0 then
		return string.format(
			"Killed %d player(s). Skipped %d unavailable or already-dead player(s).",
			killed,
			skipped
		)
	end

	return string.format("Killed %d player(s).", killed)
end
