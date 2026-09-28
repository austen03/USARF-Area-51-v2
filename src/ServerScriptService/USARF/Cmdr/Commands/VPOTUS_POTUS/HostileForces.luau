return {
	Name = "hostileforces",
	Aliases = { "hostiles", "hf" },
	Description = "Trigger hostile forces announcement.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "Message",
			Description = "Hostile forces message.",
			Optional = true,
			Default = "Hostile forces detected near the facility.",
		},
	},
}
