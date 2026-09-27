return {
	Name = "clip",
	Aliases = { "unnoclip" },
	Description = "Disables authorized admin noclip for a player.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "player",
			Name = "target",
			Description = "Player to disable noclip for.",
		},
	},
}
