return {
	Name = "clanretag",
	Aliases = {},
	Description = "Changes a clan's tag.",
	Group = "USARF Admin",
	Args = {
		{ Type = "string", Name = "Tag", Description = "The clan's current tag." },
		{ Type = "string", Name = "NewTag", Description = "The new 3-4 character tag." },
	},
}
