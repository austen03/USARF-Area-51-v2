return {
	Name = "facilitystatus",
	Aliases = { "fstatus", "status" },
	Description = "Change facility status text.",
	Group = "USARF Admin",

	Args = {
		{ Type = "facilityStatus", Name = "Status", Description = "Facility status to show." },
	},
}
