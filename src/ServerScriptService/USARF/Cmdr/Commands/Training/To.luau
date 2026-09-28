return {
	Name = "to",
	Aliases = { "go", "teleport" },
	Description = "Teleport to a player.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Target", Description = "Player to teleport to." },
	},
}
