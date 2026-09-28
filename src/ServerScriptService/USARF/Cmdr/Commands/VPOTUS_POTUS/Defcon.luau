return {
	Name = "defcon",
	Aliases = { "dc" },
	Description = "Set facility DEFCON level 1-5.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "integer",
			Name = "Level",
			Description = "DEFCON level 1-5.",
		},
	},
}
