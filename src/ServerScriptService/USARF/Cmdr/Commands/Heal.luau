return {
	Name = "heal",
	Aliases = { "restore" },
	Description = "Heal a player to full health.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Player", Description = "Player to heal." },
	},
}
