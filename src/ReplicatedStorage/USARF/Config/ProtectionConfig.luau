local ProtectionConfig = {}

ProtectionConfig.RemoteName = "ProtectionRemote"

ProtectionConfig.MainGroupId = 6033326
ProtectionConfig.SecretServiceGroupId = 6033945

ProtectionConfig.ToggleKey = Enum.KeyCode.Y
ProtectionConfig.RefreshSeconds = 1.5

ProtectionConfig.LocationFolderName = "ProtectionLocations"
ProtectionConfig.UnknownLocationName = "Unknown Location"

ProtectionConfig.ZoneFolderName = "ProtectionZones"

ProtectionConfig.ZoneSettings = {
	DZ = {
		DisplayName = "Danger Zone",
		DefaultRadius = 25,
		MinRadius = 5,
		MaxRadius = 100,
		Height = 0.08,
		Color = Color3.fromRGB(255, 165, 40),
		Transparency = 0.72,
		Material = Enum.Material.Neon,
	},

	KZ = {
		DisplayName = "Kill Zone",
		DefaultRadius = 10,
		MinRadius = 5,
		MaxRadius = 60,
		Height = 0.1,
		Color = Color3.fromRGB(255, 45, 45),
		Transparency = 0.65,
		Material = Enum.Material.Neon,
	},
}

ProtectionConfig.AccessRules = {
	SecretService = {
		TeamNames = {
			["Secret Service"] = true,
		},
		GroupId = 6033945,
		MinimumRank = 1,
	},

	Leadership = {
		MainGroupMinimumRank = 18,
	},
}

ProtectionConfig.ZoneManagement = {
	SecretServiceOnly = true,
	SecretServiceMinimumRank = 1,
	LeadershipMinimumRank = 21,
}

ProtectionConfig.VIPRules = {
	{
		Label = "President",
		TeamKeys = {
			["President"] = true,
		},
		TeamNames = {
			["President of the United States"] = true,
		},
		MainGroupRanks = {
			[17] = true,
		},
		Priority = 100,
	},

	{
		Label = "Vice President",
		TeamKeys = {
			["VicePresident"] = true,
		},
		TeamNames = {
			["Vice President of the United States"] = true,
		},
		MainGroupRanks = {
			[16] = true,
		},
		Priority = 90,
	},

	{
		Label = "Federal Administration",
		TeamKeys = {
			["FederalAdministration"] = true,
			["PresidentialCabinet"] = true,
		},
		TeamNames = {
			["Federal Administration"] = true,
			["Presidential Cabinet"] = true,
		},
		MainGroupRanks = {
			[21] = true, -- Federal Administrator
		},
		Priority = 80,
	},
}

return ProtectionConfig
