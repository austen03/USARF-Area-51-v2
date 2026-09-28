return {
	Name = "explode",
	Aliases = {},
	Description = "Create a small explosion at a player.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "player",
			Name = "Target",
			Description = "Player to explode.",
		},
		{
			Type = "number",
			Name = "Power",
			Description = "Explosion blast pressure.",
			Optional = true,
			Default = 10,
		},
		{
			Type = "number",
			Name = "Radius",
			Description = "Blast radius.",
			Optional = true,
			Default = 5,
		},
	},
}
