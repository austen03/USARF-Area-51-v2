return {
	Name = "hideme",
	Aliases = { "hideleaderboard" },
	Description = "Toggle whether you appear on the custom leaderboard.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "Mode",
			Description = "Optional: on, off, toggle, or status.",
			Optional = true,
		},
	},
}
