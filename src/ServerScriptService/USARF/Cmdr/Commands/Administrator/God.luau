return {
	Name = "god",
	Aliases = {},
	Description = "Toggle god mode for a player.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "player",
			Name = "Target",
			Description = "Player.",
		},
		{
			Type = "boolean",
			Name = "Enabled",
			Description = "true/false. Omit to toggle.",
			Optional = true,
		},
	},
}
