return {
	Name = "givetools",
	Aliases = {"give","givetool", "addtool" },
	Description = "Give a tool to a player.",
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
			Description = "The tool to give.",
		},
	},
}
