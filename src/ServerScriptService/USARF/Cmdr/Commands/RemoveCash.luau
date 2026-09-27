return {
	Name = "removecash",
	Aliases = { "takecash" },
	Description = "Remove cash from a player.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Player", Description = "Target player." },
		{ Type = "number", Name = "Amount", Description = "Amount of cash to remove." },
	},
}
