return {
	Name = "warn",
	Aliases = { "gamewarn", "gwarn" },
	Description = "Warn a player with an acknowledge popup.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "Player to warn.",
		},
		{
			Type = "string",
			Name = "Reason",
			Description = "Warning reason.",
		},
	},
}
