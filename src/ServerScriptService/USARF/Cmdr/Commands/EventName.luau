return {
	Name = "eventsservername",
	Aliases = { "eventname" },
	Description = "Set, clear, or inspect the event server display name.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "Name",
			Description = "New display name, clear, or status.",
			Optional = true,
			Default = "status",
		},
	},
}
