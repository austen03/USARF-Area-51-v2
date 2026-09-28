return {
	Name = "removetools",
	Aliases = { "removetool", "takepermtool", "taketool" },
	Description = "Remove a tool from a player.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "player",
			Name = "Target",
			Description = "Target player.",
		},
		{
			Type = "tool",
			Name = "Tool",
			Description = "The tool to remove.",
		},
	},
}
