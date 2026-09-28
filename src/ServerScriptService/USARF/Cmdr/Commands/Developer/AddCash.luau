return {
	Name = "addcash",
	Aliases = { "givecash" },
	Description = "Add cash to a player.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Player", Description = "Target player." },
		{ Type = "number", Name = "Amount", Description = "Amount of cash to add." },
	},
}
