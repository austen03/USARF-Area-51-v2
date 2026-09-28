return {
	Name = "gamedebug",
	Aliases = { "serverdebug" },
	Description = "Toggle global game debug diagnostics for this server.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "Mode",
			Description = "on, off, toggle, or status.",
			Optional = true,
			Default = "toggle",
		},
	},
}
