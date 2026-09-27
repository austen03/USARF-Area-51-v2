return {
	Name = "breach",
	Aliases = { "containmentbreach" },
	Description = "Trigger breach announcement.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "Message",
			Description = "Breach message.",
			Optional = true,
			Default = "Containment breach detected.",
		},
	},
}
