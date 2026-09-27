return {
	Name = "ufo",
	Aliases = { "unknownflyingobject" },
	Description = "Trigger UFO announcement.",
	Group = "USARF Admin",

	Args = {
		{
			Type = "string",
			Name = "Message",
			Description = "UFO message.",
			Optional = true,
			Default = "Unidentified aerial activity detected.",
		},
	},
}
