local USARFConfig = {}

USARFConfig.Groups = {
	Main = 6033326,
	Moderation = 8647541,
	Developer = 6773540,

	EngineeringTechnical = 6075931,
	MedicalDivision = 6075925,
	ResearchDivision = 6034021,
	RulesRegulations = 6075941,

	UnitedStatesAirForce = 6773526,
	DepartmentOfDefense = 6773532,

	Infantry108 = 6075919,
	SpecOpsAIG = 6075911,
	MP137 = 8068762,
	SecretService = 6033945,

	CentralIntelligenceAgency = 6033914,
	FederalBureauInvestigation = 6033902,
	FederalDefenseService = 35312413,
}

USARFConfig.Gamepasses = {
	BoomBox = 10618250,
	Minigun = 10528500,
	MP5 = 10528490,
	["Glock-17"] = 10528478,
	PMC = 1868058877,
	DoublePaycheck = 10528509,
	StolenKeycard = 10528460,
}

USARFConfig.DevProducts = {
	[3603695433] = {
		Name = "10 Gold",
		Currency = "Gold",
		Amount = 10,
	},

	[3603695455] = {
		Name = "25 Gold",
		Currency = "Gold",
		Amount = 25,
	},

	[3603695476] = {
		Name = "60 Gold",
		Currency = "Gold",
		Amount = 60,
	},

	[3603695490] = {
		Name = "150 Gold",
		Currency = "Gold",
		Amount = 150,
	},
}

USARFConfig.Categories = {
	{
		key = "test_subject",
		name = "Test Subject",
		order = 1,
	},
	{
		key = "pmc",
		name = "Private Military Contractor",
		order = 2,
	},
	{
		key = "civil",
		name = "Civil Departments",
		order = 3,
	},
	{
		key = "combative",
		name = "Combative Departments",
		order = 4,
	},
	{
		key = "intelligence",
		name = "Intelligence Departments",
		order = 5,
	},
	{
		key = "government",
		name = "Governmental Departments",
		order = 6,
	},
}

USARFConfig.Teams = {
	Loading = {
		displayName = "Loading",
		teamName = "Loading",
		category = nil,
		spawnKey = "TestSubject",
		trackActivity = false,
		suspendable = false,
		hidden = true,
		requirements = {
			type = "open",
		},
	},

	TestSubject = {
		displayName = "Test Subject",
		teamName = "Test Subject",
		category = "test_subject",
		spawnKey = "TestSubject",
		trackActivity = false,
		suspendable = false,
		requirements = {
			type = "open",
		},
	},

	PMC = {
		displayName = "Private Military Contractor",
		teamName = "PMC",
		category = "pmc",
		spawnKey = "PMC",
		trackActivity = false,
		suspendable = false,
		requirements = {
			type = "gamepass",
			gamepassId = USARFConfig.Gamepasses.PMC,
		},
	},

	FacilityPersonnel = {
		displayName = "Facility Personnel",
		teamName = "Facility Personnel",
		category = "civil",
		spawnKey = "FacilityPersonnel",
		trackActivity = false,
		suspendable = true,
		suspensionGroup = "civil",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.Main,
			minRank = 3,
		},
	},

	EngineeringTechnical = {
		displayName = "Engineering & Technical",
		teamName = "Engineering & Technical",
		category = "civil",
		spawnKey = "EngineeringTechnical",
		trackActivity = true,
		suspendable = true,
		suspensionGroup = "civil",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.EngineeringTechnical,
			minRank = 1,
		},
	},

	MedicalDivision = {
		displayName = "Medical Division",
		teamName = "Medical Division",
		category = "civil",
		spawnKey = "MedicalDivision",
		trackActivity = true,
		suspendable = true,
		suspensionGroup = "civil",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.MedicalDivision,
			minRank = 1,
		},
	},

	ResearchDivision = {
		displayName = "Research Division",
		teamName = "Research Division",
		category = "civil",
		spawnKey = "ResearchDivision",
		trackActivity = true,
		suspendable = true,
		suspensionGroup = "civil",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.ResearchDivision,
			minRank = 1,
		},
	},

	RulesRegulations = {
		displayName = "Rules & Regulations",
		teamName = "Rules & Regulations",
		category = "civil",
		spawnKey = "RulesRegulations",
		trackActivity = true,
		suspendable = true,
		suspensionGroup = "civil",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.RulesRegulations,
			minRank = 1,
		},
	},

	UnitedStatesAirForce = {
		displayName = "United States Air Force",
		teamName = "United States Air Force",
		category = "civil",
		spawnKey = "UnitedStatesAirForce",
		trackActivity = false,
		suspendable = true,
		suspensionGroup = "civil",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.UnitedStatesAirForce,
			minRank = 1,
		},
	},

	DepartmentOfDefense = {
		displayName = "Department of Defense",
		teamName = "Department of Defense",
		category = "civil",
		spawnKey = "DepartmentOfDefense",
		trackActivity = false,
		suspendable = true,
		suspensionGroup = "civil",
		requirements = {
			type = "groupAny",
			rules = {
				{
					groupId = USARFConfig.Groups.DepartmentOfDefense,
					exactRank = 1,
				},
				{
					groupId = USARFConfig.Groups.DepartmentOfDefense,
					minRank = 4,
				},
			},
		},
	},

	EXTECH = {
		displayName = "EXTECH",
		teamName = "EXTECH",
		category = "civil",
		spawnKey = "EXTECH",
		trackActivity = false,
		suspendable = true,
		suspensionGroup = "civil",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.Developer,
			minRank = 2,
		},
	},

	Infantry108 = {
		displayName = "108th Infantry Regiment",
		teamName = "108th Infantry Regiment",
		category = "combative",
		spawnKey = "Infantry108",
		trackActivity = true,
		suspendable = true,
		suspensionGroup = "combative",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.Infantry108,
			minRank = 1,
		},
	},

	MP137 = {
		displayName = "137th Military Police Company",
		teamName = "137th Military Police Company",
		category = "combative",
		spawnKey = "MP137",
		trackActivity = true,
		suspendable = true,
		suspensionGroup = "combative",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.MP137,
			minRank = 1,
		},
	},

	SpecOpsAIG = {
		displayName = "1st Spec. Ops. A.I.G",
		teamName = "1st Spec. Ops. A . I . G",
		category = "combative",
		spawnKey = "SpecOpsAIG",
		trackActivity = true,
		suspendable = true,
		suspensionGroup = "combative",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.SpecOpsAIG,
			minRank = 1,
		},
	},

	SecretService = {
		displayName = "Secret Service",
		teamName = "Secret Service",
		category = "combative",
		spawnKey = "SecretService",
		trackActivity = true,
		suspendable = true,
		suspensionGroup = "combative",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.SecretService,
			minRank = 1,
		},
	},

	FederalDefenseService = {
		displayName = "Federal Defense Service",
		teamName = "Federal Defense Service",
		category = "intelligence",
		spawnKey = "FederalDefenseService",
		trackActivity = true,
		suspendable = true,
		suspensionGroup = "intelligence",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.FederalDefenseService,
			minRank = 1,
		},
	},

	CentralIntelligenceAgency = {
		displayName = "Central Intelligence Agency",
		teamName = "Central Intelligence Agency",
		category = "intelligence",
		spawnKey = "CentralIntelligenceAgency",
		trackActivity = true,
		suspendable = true,
		suspensionGroup = "intelligence",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.CentralIntelligenceAgency,
			minRank = 1,
		},
	},

	FederalBureauInvestigation = {
		displayName = "Federal Bureau of Investigation",
		teamName = "Federal Bureau of Investigation",
		category = "intelligence",
		spawnKey = "FederalBureauInvestigation",
		trackActivity = true,
		suspendable = true,
		suspensionGroup = "intelligence",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.FederalBureauInvestigation,
			minRank = 1,
		},
	},

	FederalAdministration = {
		displayName = "Federal Administration",
		teamName = "Federal Administration",
		category = "government",
		spawnKey = "FederalAdministration",
		trackActivity = false,
		suspendable = false,
		suspensionGroup = "facility",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.Main,
			minRank = 21,
		},
	},

	PresidentialCabinet = {
		displayName = "Presidential Cabinet",
		teamName = "Presidential Cabinet",
		category = "government",
		spawnKey = "PresidentialCabinet",
		trackActivity = false,
		suspendable = false,
		suspensionGroup = "facility",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.Main,
			minRank = 15,
		},
	},

	VicePresident = {
		displayName = "Vice President of the United States",
		teamName = "Vice President of the United States",
		category = "government",
		spawnKey = "VicePresident",
		trackActivity = false,
		suspendable = false,
		suspensionGroup = "facility",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.Main,
			minRank = 16,
		},
	},

	President = {
		displayName = "President of the United States",
		teamName = "President of the United States",
		category = "government",
		spawnKey = "President",
		trackActivity = false,
		suspendable = false,
		suspensionGroup = "facility",
		requirements = {
			type = "group",
			groupId = USARFConfig.Groups.Main,
			minRank = 17,
		},
	},
}

USARFConfig.TeamAliases = {
	["Loading"] = "Loading",

	["Test Subject"] = "TestSubject",

	["PMC"] = "PMC",
	["Private Military Contractor"] = "PMC",
	["Private Military Company"] = "PMC",

	["Facility Personnel"] = "FacilityPersonnel",
	["Engineering & Technical"] = "EngineeringTechnical",
	["Medical Division"] = "MedicalDivision",
	["Medical"] = "MedicalDivision",
	["Research Division"] = "ResearchDivision",
	["Research"] = "ResearchDivision",
	["Rules & Regulations"] = "RulesRegulations",
	["United States Air Force"] = "UnitedStatesAirForce",
	["USAF"] = "UnitedStatesAirForce",
	["Department of Defense"] = "DepartmentOfDefense",
	["DoD"] = "DepartmentOfDefense",
	["EXTECH"] = "EXTECH",

	["108th Infantry Regiment"] = "Infantry108",
	["108th Infantry"] = "Infantry108",
	["137th Military Police Company"] = "MP137",
	["137th MP"] = "MP137",
	["1st Spec. Ops. A.I.G"] = "SpecOpsAIG",
	["1st Spec. Ops. A . I . G"] = "SpecOpsAIG",
	["1st Spec Ops A.I.G"] = "SpecOpsAIG",
	["Secret Service"] = "SecretService",

	["Federal Defense Service"] = "FederalDefenseService",
	["FDS"] = "FederalDefenseService",
	["Central Intelligence Agency"] = "CentralIntelligenceAgency",
	["CIA"] = "CentralIntelligenceAgency",
	["Federal Bureau of Investigation"] = "FederalBureauInvestigation",
	["FBI"] = "FederalBureauInvestigation",

	["Federal Administration"] = "FederalAdministration",
	["Presidential Cabinet"] = "PresidentialCabinet",
	["Vice President of the United States"] = "VicePresident",
	["Vice President"] = "VicePresident",
	["President of the United States"] = "President",
	["President"] = "President",
}

USARFConfig.Clearance = {
	MainGroupId = USARFConfig.Groups.Main,

	TeamOverride = {
		President = 10,
		VicePresident = 10,
	},

	RankMap = {

		{ minRank = 21, clearance = 11 },
		{ exactRank = 18, clearance = 9 },
		{ exactRank = 17, clearance = 10 },
		{ exactRank = 16, clearance = 10 },
		{ exactRank = 15, clearance = 9 },
		{ exactRank = 13, clearance = 8 },
		{ exactRank = 11, clearance = 7 },
		{ exactRank = 10, clearance = 6 },
		{ exactRank = 8, clearance = 5 },
		{ exactRank = 7, clearance = 4 },
		{ exactRank = 5, clearance = 3 },
		{ exactRank = 4, clearance = 2 },
		{ exactRank = 3, clearance = 1 },
	},
}

USARFConfig.Radio = {
	MaxMessagesPerChannel = 75,

	BlockedTeams = {
		TestSubject = true,
		PMC = true,
		Loading = true,
	},

	RedactedViewerMainRank = 16,
	RedactedViewerModRank = 2,

	SendCooldownSeconds = 1.25,
	DuplicateCooldownSeconds = 6,
	MaxMessageLength = 180,

	Channels = {
		{
			key = "alerts",
			name = "ALERTS",
			readOnly = true,
			everyoneWithRadio = true,
		},

		{
			key = "general",
			name = "GENERAL",
			everyoneWithRadio = true,
		},

		{
			key = "combative",
			name = "COMBATIVE",
			teamKeys = {
				"Infantry108",
				"MP137",
				"SpecOpsAIG",
				"SecretService",
				"FederalDefenseService",
			},
		},

		{
			key = "intelligence",
			name = "INTELLIGENCE",
			teamKeys = {
				"CentralIntelligenceAgency",
				"FederalBureauInvestigation",
				"FederalDefenseService",
			},
		},

		{
			key = "protection",
			name = "PROTECTION",
			teamKeys = {
				"SecretService",
				"President",
				"VicePresident",
				"PresidentialCabinet",
			},
		},

		{
			key = "command",
			name = "COMMAND",
			minMainRank = 12,
		},

		{
			key = "leadership",
			name = "LEADERSHIP",
			minMainRank = 16,
		},

		{
			key = "moderation",
			name = "MODERATION",
			modRankExactly = 2,
			altMainRank = 19,
		},
		{
			key = "staffalerts",
			name = "STAFF ALERTS",
			readOnly = true,
			modRankExactly = 2,
			altMainRank = 18,
		},
	},

	TeamAbbreviations = {
		Loading = { abv = "LOAD", redacted = false },
		TestSubject = { abv = "TS", redacted = false },
		PMC = { abv = "PMC", redacted = false },

		Infantry108 = { abv = "INF", redacted = false },
		MP137 = { abv = "MPC", redacted = false },
		SpecOpsAIG = { abv = "SPEC OPS", redacted = false },

		CentralIntelligenceAgency = { abv = "CIA", redacted = true },
		FederalBureauInvestigation = { abv = "FBI", redacted = true },
		FederalDefenseService = { abv = "FDS", redacted = true },
		SecretService = { abv = "USSS", redacted = true },

		DepartmentOfDefense = { abv = "DOD", redacted = false },
		EXTECH = { abv = "EXTECH", redacted = false },
		EngineeringTechnical = { abv = "E&T", redacted = false },
		FacilityPersonnel = { abv = "FP", redacted = false },
		FederalAdministration = { abv = "!", redacted = false },
		MedicalDivision = { abv = "MD", redacted = false },
		ResearchDivision = { abv = "RD", redacted = false },
		RulesRegulations = { abv = "R&R", redacted = false },
		UnitedStatesAirForce = { abv = "USAF", redacted = false },

		President = { abv = "POTUS", redacted = false },
		VicePresident = { abv = "VPOTUS", redacted = false },
		PresidentialCabinet = { abv = "PC", redacted = false },
	},
}

USARFConfig.Economy = {
	PaycheckInterval = 300,
	AutoSaveInterval = 120,

	AFK = {
		Enabled = true,

		IdleSeconds = 180,
		CheckInterval = 1,
		MoveThreshold = 0.75,

		ClientActivityTimeout = 180,
		ClientInputClearsAFK = true,
		CameraMovementClearsAFK = true,

		SkipPaycheck = true,
		SkipPaycheckInMenu = true,
		SkipPaycheckIfSuspicious = true,

		SuspiciousMacroDetection = true,
		RepeatedTinyMoveWindow = 90,
		TinyMoveMin = 0.05,
		TinyMoveMax = 0.65,
		TinyMoveCountThreshold = 45,
		CameraStillRequired = true,

		MarkSuspiciousAsAFK = true,
	},

	TeamPaychecks = {
		TestSubject = 10,
		PMC = 25,

		FacilityPersonnel = 35,
		EngineeringTechnical = 45,
		MedicalDivision = 45,
		ResearchDivision = 45,
		RulesRegulations = 40,

		Infantry108 = 55,
		MP137 = 55,
		SpecOpsAIG = 65,

		CentralIntelligenceAgency = 60,
		FederalBureauInvestigation = 60,
		FederalDefenseService = 60,

		SecretService = 70,
		UnitedStatesAirForce = 65,
		DepartmentOfDefense = 70,

		PresidentialCabinet = 90,
		VicePresident = 100,
		President = 125,
		FederalAdministration = 100,
	},

	TransactionActions = {
		Paycheck = "PAYCHECK",
		DailyReward = "DAILY_REWARD",
		ShopPurchase = "SHOP_PURCHASE",
		AdminAdd = "ADMIN_ADD",
		AdminRemove = "ADMIN_REMOVE",
		AdminSet = "ADMIN_SET",
		DevProduct = "DEV_PRODUCT",
		GamepassBonus = "GAMEPASS_BONUS",
		Refund = "REFUND",
		System = "SYSTEM",
	},

	ShopCategories = {
		CashItems = "Cash Items",
		GoldItems = "Gold Items",
	},

	ShopItems = {
		{
			Id = "cash_medkit",
			Name = "Medkit",
			Description = "Permanent medical kit. Equip through Black Market.",
			Currency = "Cash",
			Price = 500,
			Category = "Cash Items",
			Enabled = true,
			ItemType = "Permanent",
			ToolName = "Medkit",
			LoadoutSlot = "Equipment",
		},

		{
			Id = "cash_glock17_life",
			Name = "Glock 17",
			Description = "One-life sidearm. Equip through Black Market.",
			Currency = "Cash",
			Price = 1500,
			Category = "Cash Items",
			Enabled = true,
			ItemType = "LifeItem",
			ToolName = "Glock 17",
			LoadoutSlot = "Secondary",
		},

		{
			Id = "cash_radio_access_life",
			Name = "Radio Access",
			Description = "One-life access to GENERAL radio.",
			Currency = "Cash",
			Price = 1000,
			Category = "Cash Items",
			Enabled = true,
			ItemType = "LifeItem",
			Effect = "RadioAccess",
			Quantity = 1,
		},

		{
			Id = "cash_l4_clearance_life",
			Name = "L4 Clearance",
			Description = "One-life temporary SC-4 clearance.",
			Currency = "Cash",
			Price = 2500,
			Category = "Cash Items",
			Enabled = true,
			ItemType = "LifeItem",
			Effect = "Clearance",
			ClearanceLevel = 4,
			Quantity = 1,
		},

		{
			Id = "cash_speed_boost_15",
			Name = "Speed Boost",
			Description = "15 minute temporary speed boost.",
			Currency = "Cash",
			Price = 1250,
			Category = "Cash Items",
			Enabled = true,
			ItemType = "TimedBoost",
			Effect = "SpeedBoost",
			DurationSeconds = 900,
			Stackable = true,
		},

		{
			Id = "cash_double_pay_30",
			Name = "Double Cash Boost",
			Description = "30 minute temporary double paycheck boost.",
			Currency = "Cash",
			Price = 2000,
			Category = "Cash Items",
			Enabled = true,
			ItemType = "TimedBoost",
			Effect = "DoublePay",
			DurationSeconds = 1800,
			Stackable = true,
		},

		{
			Id = "gold_nametag",
			Name = "Gold Nametag",
			Description = "Permanent gold nametag cosmetic.",
			Currency = "Gold",
			Price = 100,
			Category = "Gold Items",
			Enabled = true,
			ItemType = "Permanent",
			Effect = "GoldNametag",
		},

		{
			Id = "gold_perm_glock17",
			Name = "Permanent Glock 17",
			Description = "Permanent Glock 17. Equip through Black Market.",
			Currency = "Gold",
			Price = 150,
			Category = "Gold Items",
			Enabled = true,
			ItemType = "Permanent",
			ToolName = "Glock 17",
			LoadoutSlot = "Secondary",
		},

		{
			Id = "gold_perm_mp5",
			Name = "Permanent MP5",
			Description = "Permanent MP5. Equip through Black Market.",
			Currency = "Gold",
			Price = 350,
			Category = "Gold Items",
			Enabled = true,
			ItemType = "Permanent",
			ToolName = "MP5",
			LoadoutSlot = "Primary",
		},

		{
			Id = "gold_perm_ak47",
			Name = "Permanent AK-47",
			Description = "Permanent AK-47. Equip through Black Market.",
			Currency = "Gold",
			Price = 500,
			Category = "Gold Items",
			Enabled = true,
			ItemType = "Permanent",
			ToolName = "AK-47",
			LoadoutSlot = "Primary",
		},

		{
			Id = "gold_elite_contractor",
			Name = "Elite Contractor Package",
			Description = "Permanent PMC package: Glock 17, Medkit, and Riot Shield.",
			Currency = "Gold",
			Price = 300,
			Category = "Gold Items",
			Enabled = true,
			ItemType = "Permanent",
			PackageItems = {
				"gold_perm_glock17",
				"cash_medkit",
				"gold_riot_shield",
			},
		},

		{
			Id = "gold_armory_license",
			Name = "Armory License",
			Description = "Permanent armory access package.",
			Currency = "Gold",
			Price = 750,
			Category = "Gold Items",
			Enabled = true,
			ItemType = "Permanent",
			PackageItems = {
				"gold_perm_glock17",
				"gold_perm_mp5",
				"cash_medkit",
				"gold_riot_shield",
			},
		},

		{
			Id = "gold_riot_shield",
			Name = "Riot Shield",
			Description = "Permanent riot shield. Equip through Black Market.",
			Currency = "Gold",
			Price = 125,
			Category = "Gold Items",
			Enabled = true,
			ItemType = "Permanent",
			ToolName = "Riot Shield",
			LoadoutSlot = "Equipment",
		},
	},
}

USARFConfig.Admin = {
	Levels = {
		None = 0,
		Training = 1,
		VPOTUS_POTUS = 2,
		Moderator = 3,
		Administrator = 4,
		Developer = 5,
		Owner = 6,
	},

	LevelLabels = {
		[0] = "None",
		[1] = "Training",
		[2] = "VPOTUS_POTUS",
		[3] = "Moderator",
		[4] = "Administrator",
		[5] = "Developer",
		[6] = "Owner",
	},

	MainServerRanks = {
		MainGroup = {
			GroupId = USARFConfig.Groups.Main,

			ExactRanks = {
				[255] = "Owner", -- Federal Overseer
				[22] = "Administrator", -- Federal Manager
				[21] = "Administrator", -- Federal Administrator
				[20] = "Developer", -- A51 v2 Developer
				[18] = "Developer",
				[17] = "VPOTUS_POTUS",
				[16] = "VPOTUS_POTUS",
			},
		},

		ModerationGroup = {
			GroupId = USARFConfig.Groups.Moderation,

			ExactRanks = {
				[2] = "Moderator",
			},
		},

		DeveloperGroup = {
			GroupId = USARFConfig.Groups.Developer,

			MinimumRanks = {
				{
					Rank = 3,
					Level = "Developer",
				},
			},
		},
	},
}

function USARFConfig.GetTeamKeyFromName(teamName)
	teamName = tostring(teamName or "")

	if USARFConfig.Teams[teamName] then
		return teamName
	end

	return USARFConfig.TeamAliases[teamName]
end

function USARFConfig.GetTeamDataFromName(teamName)
	local teamKey = USARFConfig.GetTeamKeyFromName(teamName)

	if not teamKey then
		return nil, nil
	end

	return teamKey, USARFConfig.Teams[teamKey]
end

function USARFConfig.GetTeamData(teamKey)
	return USARFConfig.Teams[teamKey]
end

function USARFConfig.GetCategory(categoryKey)
	for _, category in ipairs(USARFConfig.Categories) do
		if category.key == categoryKey then
			return category
		end
	end

	return nil
end

return USARFConfig
