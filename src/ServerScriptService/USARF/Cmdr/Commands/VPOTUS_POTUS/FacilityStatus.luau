return {
	Name = "facilitystatus",
	Aliases = { "fstatus", "status" },
	Description = "Change facility status text.",
	Group = "USARF Admin",

	Args = {
		{ Type = "string", Name = "Status", Description = "normal, secure, alert, lockdown, breach, riot, hostileforces, ufo, code1, maintenance, evacuation." },
	},
}
