return {
	Name = "clanrename",
	Aliases = {},
	Description = "Renames a clan (same name rules as creating one, without the text filter).",
	Group = "USARF Admin",
	Args = {
		{ Type = "string", Name = "Tag", Description = "The clan's current tag." },
		{ Type = "string", Name = "NewName", Description = "The new clan name." },
	},
}
