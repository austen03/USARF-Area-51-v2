return {
	Name = "defcon",
	Aliases = { "dc" },
	Description = "Set facility DEFCON level 1-5.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "defconLevel",
			Name = "Level",
			Description = "DEFCON level: 5 normal, 4 security alert, 3 partial, 2 full, 1 emergency lockdown.",
		},
	},
}
