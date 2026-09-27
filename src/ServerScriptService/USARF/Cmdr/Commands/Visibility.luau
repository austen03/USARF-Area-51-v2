return {
	Name = "visibility",
	Aliases = { "invisible", "visible" },
	Description = "Toggle a player's visibility.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "player",
			Name = "Target",
			Description = "Player.",
		},
		{
			Type = "boolean",
			Name = "Invisible",
			Description = "true=invisible, false=visible.",
			Optional = true,
		},
	},
}
