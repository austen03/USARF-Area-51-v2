return {
	Name = "getcurrency",
	Aliases = { "currency", "viewcurrency", "seecurrency" },
	Description = "View a player's currency.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Player", Description = "Target player." },
		{ Type = "currency", Name = "Currency", Description = "cash or gold." },
	},
}
