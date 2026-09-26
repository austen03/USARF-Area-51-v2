local FacilityStatusConfig = {}

FacilityStatusConfig.TeamCategories = {
	["Test Subject"] = "TestSubjects",
	["Private Military Company"] = "PMC",

	["Facility Personnel"] = "Civil",
	["Engineering & Technical"] = "Civil",
	["Medical"] = "Civil",
	["Research"] = "Civil",
	["Rules & Regulations"] = "Civil",
	
	["USAF"] = "Protection",
	["DoD"] = "Protection",
	["108th Infantry"] = "Combative",
	["137th MP"] = "Combative",
	["1st Spec Ops A.I.G"] = "Combative",

	["CIA"] = "Intelligence",
	["FBI"] = "Intelligence",
	["FDS"] = "Intelligence",

	["Secret Service"] = "Protection",

	["Presidential Cabinet"] = "Leadership",
	["Vice President"] = "Leadership",
	["President"] = "Leadership",
}

FacilityStatusConfig.DefaultValues = {
	AlertLevel = "Normal",
	LastFacilityEvent = "Facility systems online.",
}

return FacilityStatusConfig