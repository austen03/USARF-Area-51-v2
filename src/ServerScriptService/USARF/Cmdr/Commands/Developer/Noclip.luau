return {
	Name = "noclip",
	Aliases = { "nc" },
	Description = "Enables authorized admin noclip for a player.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "player",
			Name = "target",
			Description = "Player to enable noclip for.",
		},
	},
}
