return {
	Name = "removegold",
	Aliases = { "takegold" },
	Description = "Remove gold from a player.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Player", Description = "Target player." },
		{ Type = "number", Name = "Amount", Description = "Amount of gold to remove." },
	},
}
