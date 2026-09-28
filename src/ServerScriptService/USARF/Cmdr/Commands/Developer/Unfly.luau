return {
	Name = "unfly",
	Aliases = { "stopfly" },
	Description = "Disables authorized admin fly for a player.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "player",
			Name = "target",
			Description = "Player to disable fly for.",
		},
	},
}
