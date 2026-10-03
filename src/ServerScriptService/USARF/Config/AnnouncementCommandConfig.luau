local Config = {}

Config.GROUP_MAIN = 6033326
Config.GROUP_SECONDARY = 8647541
Config.GROUP_DEVELOPER = 6773540

Config.GoogleSheets = {
	Enabled = true,
	Url = "https://script.google.com/macros/s/AKfycbxLBXO-xrQSH-lkl_zsyMKtvv2pXHivaXR_ikCHJJhaexuVk1gq0Dljy6OF3lJD2o0u0g/exec?sheet=ranks",
	CacheSeconds = 60,
}

Config.ScopeStyle = {
	server = {
		DisplayName = "Server Announcement",
		Icon = "📢",
		Type = "Info",
		Color = Color3.fromRGB(56, 132, 255),
	},

	global = {
		DisplayName = "Global Announcement",
		Icon = "📢",
		Type = "Info",
		Color = Color3.fromRGB(56, 132, 255),
	},

	moderation = {
		DisplayName = "Moderation Announcement",
		Icon = "🛡️",
		Type = "Warning",
		Color = Color3.fromRGB(127, 61, 156),
	},

	developer = {
		DisplayName = "Developer Announcement",
		Icon = "🛠️",
		Type = "Info",
		Color = Color3.fromRGB(154, 108, 255),
	},

	event = {
		DisplayName = "Event Announcement",
		Icon = "🎉",
		Type = "Info",
		Color = Color3.fromRGB(255, 179, 71),
	},

	team = {
		DisplayName = "Team Announcement",
		Icon = "📣",
		Type = "Info",
		Color = Color3.fromRGB(0, 199, 137),
	},

	facility = {
		DisplayName = "Facility Announcement",
		Icon = "📌",
		Type = "Warning",
		Color = Color3.fromRGB(242, 99, 123),
	},

	security = {
		DisplayName = "Security Announcement",
		Icon = "🚨",
		Type = "Emergency",
		Color = Color3.fromRGB(129, 169, 255),
	},
}

Config.MaskAllowedRanks = {
	[21] = true,
	[22] = true,
	[255] = true,
}

local serverRanks = {
	[Config.GROUP_MAIN] = {

		[16] = true,
		[17] = true,
		[18] = true,
		[21] = true,
		[22] = true,
		[255] = true,
	},

	[Config.GROUP_SECONDARY] = {
		[2] = true,
		[3] = true,
		[4] = true,
		[5] = true,
		[6] = true,
		[255] = true,
	},
}

Config.AllowedRanks = {
	server = serverRanks,
	global = serverRanks,

	moderation = {
		[Config.GROUP_SECONDARY] = {
			[2] = true,
			[3] = true,
			[4] = true,
			[5] = true,
			[6] = true,
			[255] = true,
		},
	},

	developer = {
		[Config.GROUP_MAIN] = {
			[18] = true,
			[21] = true,
			[22] = true,
			[255] = true,
		},

		[Config.GROUP_DEVELOPER] = {
			[3] = true,
			[4] = true,
			[5] = true,
			[6] = true,
			[7] = true,
			[8] = true,
			[254] = true,
			[255] = true,
		},
	},

	event = {
		[Config.GROUP_MAIN] = {
			[15] = true,
			[16] = true,
			[17] = true,
			[18] = true,
			[20] = true,
			[21] = true,
			[22] = true,
			[255] = true,
		},

		[Config.GROUP_SECONDARY] = {
			[2] = true,
			[3] = true,
			[4] = true,
			[5] = true,
			[6] = true,
			[255] = true,
		},
	},

	team = {
		[Config.GROUP_MAIN] = {
			[13] = true,
			[15] = true,
			[16] = true,
			[17] = true,
			[18] = true,
			[20] = true,
			[21] = true,
			[22] = true,
			[255] = true,
		},

		[Config.GROUP_SECONDARY] = {
			[2] = true,
			[3] = true,
			[4] = true,
			[5] = true,
			[6] = true,
			[255] = true,
		},
	},

	facility = {
		[Config.GROUP_MAIN] = {
			[16] = true,
			[17] = true,
			[18] = true,
			[21] = true,
			[22] = true,
			[255] = true,
		},
	},

	security = {
		[Config.GROUP_MAIN] = {
			[15] = true,
			[16] = true,
			[17] = true,
			[18] = true,
			[21] = true,
			[22] = true,
			[255] = true,
		},
	},
}

Config.ScopeMinimumAdminLevel = {
	server = 2,
	global = 4,
	moderation = 3,
	developer = 5,
	event = 4,
	team = 3,
	facility = 4,
	security = 3,
}

Config.GlobalTopic = "USARF_GlobalAnnouncement_v1"
Config.GlobalMessageVersion = 1
Config.GlobalDedupeSeconds = 120

return Config
