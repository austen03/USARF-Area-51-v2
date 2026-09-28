return {
	Name = "track",
	Aliases = { "locate" },
	Description = "Track another player on screen.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "player",
			Name = "Target",
			Description = "Player to track.",
		},
	},
}
