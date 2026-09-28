return {
	Name = "init",
	Aliases = {},
	Description = "Edits or runs your personal command init script.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "action",
			Description = "edit or run",
		},
	},
}
