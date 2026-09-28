return {
	Name = "checksuspension",
	Aliases = { "suspensions", "checksus" },
	Description = "Check active suspensions for a player.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Player", Description = "Target player." },
	},
}
