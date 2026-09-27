return {
	Name = "clandelete",
	Aliases = { "deleteclan" },
	Description = "Deletes a clan by its tag and removes all of its members.",
	Group = "USARF Admin",
	Args = {
		{ Type = "string", Name = "Tag", Description = "The clan's tag, e.g. MAN." },
	},
}
