return {
	Name = "blacklistavatar",
	Aliases = {
		"blacklistaccessory",
		"avatarblacklist",
		"blacklistavataritem",
	},
	Description = "Manage globally blocked avatar assets and bundles.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "Action",
			Description = "add, remove, status, list, or clear.",
		},
		{
			Type = "integer",
			Name = "ItemId",
			Description = "Catalog asset or bundle ID.",
			Optional = true,
		},
		{
			Type = "string",
			Name = "ItemType",
			Description = "auto, asset, or bundle.",
			Optional = true,
			Default = "auto",
		},
	},
}
