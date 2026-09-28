return {
	Name = "fly",
	Aliases = { "adminfly" },
	Description = "Enables authorized admin fly for a player.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "player",
			Name = "target",
			Description = "Player to enable fly for.",
		},

		{
			Type = "number",
			Name = "speed",
			Description = "Optional fly speed.",
			Optional = true,
			Default = 70,
		},
	},
}
