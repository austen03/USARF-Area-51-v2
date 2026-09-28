return {
	Name = "eventserver",
	Aliases = { "eventmode" },
	Description = "Create, disable, or inspect the reserved event server.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "Mode",
			Description = "on, off, or status.",
			Optional = true,
			Default = "status",
		},
	},
}
