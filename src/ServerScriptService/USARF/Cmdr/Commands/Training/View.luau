return {
	Name = "view",
	Aliases = { "spectate" },
	Description = "Spectate another player.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "player",
			Name = "Target",
			Description = "Who to spectate.",
		},
	},
}
