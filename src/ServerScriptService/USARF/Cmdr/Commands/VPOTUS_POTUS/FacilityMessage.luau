return {
	Name = "facilitymessage",
	Aliases = { "fmessage", "lastfacilityevent" },
	Description = "Set the facility message / last event.",
	Group = "USARF Admin",

	Args = {
		{ Type = "string", Name = "Message", Description = "Facility message." },
	},
}
