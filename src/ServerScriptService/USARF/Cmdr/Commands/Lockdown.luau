return {
	Name = "lockdown",
	Aliases = { "ld" },
	Description = "Set facility lockdown level 0-4.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "integer",
			Name = "Level",
			Description = "0 normal, 1 security alert, 2 partial, 3 full, 4 emergency.",
		},
	},
}
