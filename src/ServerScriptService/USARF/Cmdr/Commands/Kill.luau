return {
	Name = "kill",
	Aliases = { "slay" },
	Description = "Kill one or more players.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "players",
			Name = "Players",
			Description = "Player or group of players to kill.",
		},
	},
}
