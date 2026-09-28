return {
	Name = "devmode",
	Aliases = { "developermode" },
	Description = "Toggle developer diagnostics mode.",
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
