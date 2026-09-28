return {
	Name = "riot",
	Aliases = {},
	Description = "Start/stop riot mode.",
	Group = "USARF Admin",

	Args = {
		{ Type = "boolean", Name = "Enabled", Description = "true=start, false=stop, omit=toggle.", Optional = true },
	},
}
