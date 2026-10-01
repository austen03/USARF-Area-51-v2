local LockdownConfig = {}

LockdownConfig.Levels = {
	[0] = {
		Name = "Normal Operations",
		ShortName = "Normal",
		NotificationType = "Success",
		RadioMessage = "Facility has returned to normal operations.",
	},

	[1] = {
		Name = "Security Alert",
		ShortName = "Security Alert",
		NotificationType = "Warning",
		RadioMessage = "Security alert is now active. Personnel should remain aware.",
	},

	[2] = {
		Name = "Partial Lockdown",
		ShortName = "Partial Lockdown",
		NotificationType = "Warning",
		RadioMessage = "Partial lockdown is now active. Restricted movement is in effect.",
	},

	[3] = {
		Name = "Full Lockdown",
		ShortName = "Full Lockdown",
		NotificationType = "Error",
		RadioMessage = "Full facility lockdown is now active. Authorized movement only.",
	},

	[4] = {
		Name = "Emergency Lockdown",
		ShortName = "Emergency Lockdown",
		NotificationType = "Error",
		RadioMessage = "Emergency lockdown is now active. All personnel follow emergency procedures.",
	},
}

LockdownConfig.DefaultDoorBehavior = {
	[0] = "Normal",
	[1] = "Normal",
	[2] = "Normal",
	[3] = "Locked",
	[4] = "Locked",
}

LockdownConfig.GlobalBypassTeams = {
	"1st Spec. Ops. A . I . G",
	"Secret Service",
	"Vice President of the United States",
	"President of the United States",
	"Federal Administration",
}

LockdownConfig.NotifyPlayers = true
LockdownConfig.SendRadioAlert = true

return LockdownConfig
