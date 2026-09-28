local CmdrAdminConfig = {}

CmdrAdminConfig.Levels = {
	None = 0,
	Training = 1,
	VPOTUS_POTUS = 2,
	Moderator = 3,
	Administrator = 4,
	Developer = 5,
	Owner = 6,
}

CmdrAdminConfig.LevelLabels = {
	[0] = "None",
	[1] = "Training",
	[2] = "VPOTUS_POTUS",
	[3] = "Moderator",
	[4] = "Administrator",
	[5] = "Developer",
	[6] = "Owner",
}

CmdrAdminConfig.DisplayGroups = {
	None = "None",
	Training = "Training",
	VPOTUS_POTUS = "VPOTUS | POTUS",
	Moderator = "Moderator",
	Administrator = "Administrator",
	Developer = "Developer",
	Owner = "Owner",
}

CmdrAdminConfig.Groups = {
	Main = 6033326,
	Moderation = 8647541,
	Developer = 6773540,
}

CmdrAdminConfig.GoogleSheet = {
	Enabled = false,
	Url = "https://script.google.com/macros/s/AKfycbxLBXO-xrQSH-lkl_zsyMKtvv2pXHivaXR_ikCHJJhaexuVk1gq0Dljy6OF3lJD2o0u0g/exec?sheet=ranks",
	CacheSeconds = 300,
}

CmdrAdminConfig.MainServerRanks = {
	MainGroup = {
		GroupId = 6033326,

		ExactRanks = {
			[255] = "Owner",
			[20] = "Administrator",
			[19] = "Administrator",
			[18] = "Developer",
			[17] = "VPOTUS_POTUS",
			[16] = "VPOTUS_POTUS",
		},
	},

	ModerationGroup = {
		GroupId = 8647541,

		ExactRanks = {
			[2] = "Moderator",
		},
	},

	DeveloperGroup = {
		GroupId = 6773540,

		MinimumRanks = {
			{
				Rank = 4,
				Level = "Developer",
			},
		},
	},
}

CmdrAdminConfig.ReserveServers = {
	Enabled = true,

	Departments = {
		ResearchDivision = {
			DisplayName = "Research Division",
			GroupId = 6034021,
			MinimumRank = 5,
			GrantedLevel = "Training",
		},

		EngineeringTechnical = {
			DisplayName = "Engineering & Technical",
			GroupId = 6075931,
			MinimumRank = 5,
			GrantedLevel = "Training",
		},

		MedicalDivision = {
			DisplayName = "Medical Division",
			GroupId = 6075925,
			MinimumRank = 5,
			GrantedLevel = "Training",
		},

		RulesRegulations = {
			DisplayName = "Rules & Regulations",
			GroupId = 6075941,
			MinimumRank = 6,
			GrantedLevel = "Training",
		},

		Infantry108 = {
			DisplayName = "108th Infantry Regiment",
			GroupId = 6075919,
			MinimumRank = 6,
			GrantedLevel = "Training",
		},

		MP137 = {
			DisplayName = "137th Military Police Company",
			GroupId = 8068762,
			MinimumRank = 5,
			GrantedLevel = "Training",
		},

		SpecOpsAIG = {
			DisplayName = "1st Spec. Ops. A.I.G",
			GroupId = 6075911,
			MinimumRank = 5,
			GrantedLevel = "Training",
		},

		SecretService = {
			DisplayName = "Secret Service",
			GroupId = 6033945,
			MinimumRank = 5,
			GrantedLevel = "Training",
		},

		CentralIntelligenceAgency = {
			DisplayName = "Central Intelligence Agency",
			GroupId = 6033914,
			MinimumRank = 5,
			GrantedLevel = "Training",
		},

		FederalBureauInvestigation = {
			DisplayName = "Federal Bureau of Investigation",
			GroupId = 6033902,
			MinimumRank = 5,
			GrantedLevel = "Training",
		},

		FederalDefenseService = {
			DisplayName = "Federal Defense Service",
			GroupId = 35312413,
			MinimumRank = 5,
			GrantedLevel = "Training",
		},
	},
}

CmdrAdminConfig.Commands = {
	Default = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	help = {
		MainServerLevel = "Training",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = false,
		CaseId = false,
	},

	clear = {
		MainServerLevel = "Training",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = false,
		CaseId = false,
	},

	tp = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	to = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	bring = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	give = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	givetools = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	removetools = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	heal = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	view = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	unview = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	track = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	untrack = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	announce = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	radio = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	radiosystemmessage = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	rsm = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	modmode = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	kick = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = true,
	},

	warn = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = true,
	},

	ban = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = true,
	},

	case = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	cases = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	checksuspension = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	suspend = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = true,
	},

	unsuspend = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = true,
	},

	badges = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	badge = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	lockdown = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	defcon = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	breach = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	breachee = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	containee = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	riot = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	hostileforces = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	ufo = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	code1 = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	facilitystatus = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	facilitymessage = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	init = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = false,
		CaseId = false,
	},

	refresh = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	respawn = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	god = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	explode = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	visibility = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	invisible = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	visible = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	unban = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = true,
	},

	caseremove = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = true,
	},

	addcash = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = true,
	},

	removecash = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = true,
	},

	addgold = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = true,
	},

	removegold = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = true,
	},

	getcurrency = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = false,
		CaseId = false,
	},

	doublepaycheck = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	weapontest = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = false,
		CaseId = false,
	},

	logs = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	chatlogs = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	radiologs = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	exploitlogs = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	cmdrlevel = {
		MainServerLevel = "Training",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = false,
		CaseId = false,
	},

	authorize = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	auth = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	unauthorize = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	unauth = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	clearauth = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	team = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	loadout = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	certs = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = false,
		CaseId = false,
	},

	fly = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	unfly = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	noclip = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	clip = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	menu = {
		MainServerLevel = "Training",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	tools = {
		MainServerLevel = "Training",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = true,
		CaseId = false,
	},

	uptime = {
		MainServerLevel = "Training",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = false,
		CaseId = false,
	},

	kill = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	hideme = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	hover = {
		MainServerLevel = "Training",
		DisplayGroup = "Training",
		TrainingReserveLevel = "Training",
		ReserveOnlyTraining = true,
		Log = false,
		CaseId = false,
	},

	blink = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	freecam = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	btools = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	editnametag = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	rank = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	globalannounce = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	joinplayer = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	gamedebug = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	devmode = {
		MainServerLevel = "Developer",
		DisplayGroup = "Developer",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	eventserver = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	eventsservername = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	eventlink = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = false,
		CaseId = false,
	},

	lockteam = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	teamkill = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	blacklistavatar = {
		MainServerLevel = "Administrator",
		DisplayGroup = "Administrator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	mutevoice = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	nukecode = {
		MainServerLevel = "VPOTUS_POTUS",
		DisplayGroup = "VPOTUS | POTUS",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = false,
		CaseId = false,
	},

	clandelete = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	clanrename = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	clanretag = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	clanremove = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = true,
		CaseId = false,
	},

	claninfo = {
		MainServerLevel = "Moderator",
		DisplayGroup = "Moderator",
		TrainingReserveLevel = nil,
		ReserveOnlyTraining = false,
		Log = false,
		CaseId = false,
	},
}

return CmdrAdminConfig
