return {
	Name = "tools",
	Aliases = { "inventory", "viewtools" },
	Description = "View a player's equipped, Backpack, and StarterGear tools.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "Player whose tools should be listed.",
		},
	},
}
