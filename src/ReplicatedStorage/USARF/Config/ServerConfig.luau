local MainMenuConfig = {}

MainMenuConfig.Title = "USARF"
MainMenuConfig.Subtitle = "AREA 51 COMPLEX"
MainMenuConfig.BuildText = "AREA 51 v2"

MainMenuConfig.BackgroundImage = ""
MainMenuConfig.AccentColor = Color3.fromRGB(60, 145, 255)

--- Can see and join all reserve servers regardless of being in department groups -- 
MainMenuConfig.ReservedServerAdmin = {
	MainGroupId = 6033326,
	MinRank = 19,
}

MainMenuConfig.DepartmentImages = {
	TestSubject = "rbxassetid://0",
	PMC = "rbxassetid://0",

	FacilityPersonnel = "rbxassetid://132875185875954",
	EngineeringTechnical = "rbxassetid://134367190620147",
	MedicalDivision = "rbxassetid://134681763943624",
	ResearchDivision = "rbxassetid://109725087816455",
	RulesRegulations = "rbxassetid://122403734411510",
	UnitedStatesAirForce = "rbxassetid://129443692153077",
	DepartmentOfDefense = "rbxassetid://96781210362772",
	EXTECH = "rbxassetid://112124298792428",

	Infantry108 = "rbxassetid://132304973261678",
	MP137 = "rbxassetid://124327560124394",
	SpecOpsAIG = "rbxassetid://94629800154493",
	SecretService = "rbxassetid://87840236830441",

	CentralIntelligenceAgency = "rbxassetid://100607996645765",
	FederalBureauInvestigation = "rbxassetid://109703331412993",
	FederalDefenseService = "rbxassetid://115235124506997",

	FederalAdministration = "rbxassetid://127573802927340",
	PresidentialCabinet = "rbxassetid://132975674881392",
	VicePresident = "rbxassetid://105122404187431",
	President = "rbxassetid://105122404187431",
}

MainMenuConfig.DepartmentColors = {
	TestSubject = Color3.fromRGB(180, 180, 180),
	PMC = Color3.fromRGB(180, 120, 60),

	FacilityPersonnel = Color3.fromRGB(60, 145, 255),
	EngineeringTechnical = Color3.fromRGB(255, 170, 60),
	MedicalDivision = Color3.fromRGB(80, 190, 255),
	ResearchDivision = Color3.fromRGB(170, 100, 255),
	RulesRegulations = Color3.fromRGB(255, 215, 90),
	UnitedStatesAirForce = Color3.fromRGB(80, 160, 255),
	DepartmentOfDefense = Color3.fromRGB(40, 90, 180),
	EXTECH = Color3.fromRGB(120, 220, 255),

	Infantry108 = Color3.fromRGB(80, 180, 90),
	MP137 = Color3.fromRGB(70, 130, 255),
	SpecOpsAIG = Color3.fromRGB(255, 80, 80),
	SecretService = Color3.fromRGB(255, 215, 90),

	CentralIntelligenceAgency = Color3.fromRGB(120, 80, 180),
	FederalBureauInvestigation = Color3.fromRGB(60, 120, 220),
	FederalDefenseService = Color3.fromRGB(220, 70, 70),

	FederalAdministration = Color3.fromRGB(255, 215, 90),
	PresidentialCabinet = Color3.fromRGB(255, 200, 80),
	VicePresident = Color3.fromRGB(255, 230, 120),
	President = Color3.fromRGB(255, 245, 160),
}


MainMenuConfig.DepartmentDescriptions = {
	TestSubject = "Enter the facility as a Test Subject. Follow instructions, survive experiments, and avoid restricted zones.",
	PMC = "Operate as a Private Military Contractor with limited facility access and independent objectives.",

	FacilityPersonnel = "Support day-to-day facility operations, logistics, and general personnel movement.",
	EngineeringTechnical = "Maintain power, lighting, doors, containment systems, and emergency infrastructure.",
	MedicalDivision = "Provide medical treatment, emergency response, and triage support during facility incidents.",
	ResearchDivision = "Conduct experiments, document findings, and coordinate with security during containment operations.",
	RulesRegulations = "Monitor personnel conduct, enforce regulations, and support disciplinary oversight.",
	UnitedStatesAirForce = "Support airfield operations, aviation security, and federal military coordination.",
	DepartmentOfDefense = "Coordinate defense policy, operational readiness, and federal military activity.",
	EXTECH = "Handle advanced technical systems, experimental assets, and specialized development operations.",

	Infantry108 = "Respond to threats, secure combat zones, and protect facility personnel during emergencies.",
	MP137 = "Maintain order, guard restricted zones, and support military police operations.",
	SpecOpsAIG = "Conduct high-risk operations, rapid response missions, and advanced security actions.",
	SecretService = "Protect executive leadership and secure high-value personnel movements.",

	CentralIntelligenceAgency = "Conduct intelligence operations, investigations, and classified information gathering.",
	FederalBureauInvestigation = "Investigate internal threats, criminal activity, and security breaches.",
	FederalDefenseService = "Respond to federal security threats and support intelligence-led protection operations.",

	FederalAdministration = "Oversee federal operations, facility command structure, and administrative authority.",
	PresidentialCabinet = "Support executive leadership and coordinate government-level facility decisions.",
	VicePresident = "Assist executive operations and provide senior leadership oversight.",
	President = "Lead federal authority across the facility and direct major operational decisions.",
}

MainMenuConfig.ServerSections = {
	{
		Title = "Public Servers",
		Servers = {
			{
				Name = "Current Server",
				Description = "Main Area 51 operations server.",
				Status = "Available",
				AccessLabel = "Public Access",
				Locked = false,
				Reserved = false,
			},
		},
	},

	{
		Title = "Department Reserved Servers",
		Servers = {
			{
				Key = "medical_operations",
				Name = "Medical Operations",
				Description = "Reserved server for Medical Division operations.",
				Status = "Available",
				AccessLabel = "Medical Access",
				Locked = false,
				Reserved = true,
				GroupId = 6075925,
				MinRank = 1,
				PlaceId = game.PlaceId,
			},

			{
				Key = "research_operations",
				Name = "Research Operations",
				Description = "Reserved server for Research Division operations.",
				Status = "Available",
				AccessLabel = "Research Access",
				Locked = false,
				Reserved = true,
				GroupId = 6034021,
				MinRank = 1,
				PlaceId = game.PlaceId,
			},

			{
				Key = "engineering_operations",
				Name = "Engineering Operations",
				Description = "Reserved server for Engineering & Technical operations.",
				Status = "Available",
				AccessLabel = "Engineering Access",
				Locked = false,
				Reserved = true,
				GroupId = 6075931,
				MinRank = 1,
				PlaceId = game.PlaceId,
			},

			{
				Key = "facility_security",
				Name = "Security Operations",
				Description = "Reserved server for combative department operations.",
				Status = "Available",
				AccessLabel = "Security Access",
				Locked = false,
				Reserved = true,
				Groups = {
					{ GroupId = 6075919, MinRank = 1 },
					{ GroupId = 8068762, MinRank = 1 },
					{ GroupId = 6075911, MinRank = 1 },
					{ GroupId = 6033945, MinRank = 1 },
				},
				PlaceId = game.PlaceId,
			},

			{
				Key = "facility_intelligence",
				Name = "Intelligence Operations",
				Description = "Reserved server for intelligence department operations.",
				Status = "Available",
				AccessLabel = "Intelligence Access",
				Locked = false,
				Reserved = true,
				Groups = {
					{ GroupId = 6033914, MinRank = 1 },
					{ GroupId = 6033902, MinRank = 1 },
					{ GroupId = 35312413, MinRank = 1 },
				},
				PlaceId = game.PlaceId,
			},
		},
	},
}

return MainMenuConfig