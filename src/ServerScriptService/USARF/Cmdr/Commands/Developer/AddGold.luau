return {
	Name = "addgold",
	Aliases = { "givegold" },
	Description = "Add gold to a player.",
	Group = "USARF Admin",

	Args = {
		{ Type = "player", Name = "Player", Description = "Target player." },
		{ Type = "number", Name = "Amount", Description = "Amount of gold to add." },
	},
}
