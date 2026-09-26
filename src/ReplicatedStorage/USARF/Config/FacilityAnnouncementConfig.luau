local FacilityAnnouncementConfig = {}

FacilityAnnouncementConfig.AnnouncementsPath = {
	"Map",
	"Announcements",
}

FacilityAnnouncementConfig.DefconFolderName = "defcon"

FacilityAnnouncementConfig.SoundDurations = {
	BreachAnnouncement = 31.368,
	Code1 = 2.498,
	HostileForcesAnnouncement = 4.911,
	LockdownOff = 4.545,
	LockdownOn = 5.538,
	UFOAnnouncement = 4.18,

	["2"] = 3.187,
	["3"] = 3.448,
	["4"] = 3.553,
	["5"] = 7.341,
}

FacilityAnnouncementConfig.LockdownAudio = {
	[0] = {
		DefconSound = "5",
		AnnouncementSound = "LockdownOff",
	},

	[1] = {
		DefconSound = "4",
		AnnouncementSound = nil,
	},

	[2] = {
		DefconSound = "3",
		AnnouncementSound = "LockdownOn",
	},

	[3] = {
		DefconSound = "2",
		AnnouncementSound = "LockdownOn",
	},

	[4] = {
		DefconSound = nil,
		AnnouncementSound = "LockdownOn",
	},
}

FacilityAnnouncementConfig.EventAudio = {
	Breach = "BreachAnnouncement",
	HostileForces = "HostileForcesAnnouncement",
	UFO = "UFOAnnouncement",
	Code1 = "Code1",
}

FacilityAnnouncementConfig.PlayDefconBeforeAnnouncement = true
FacilityAnnouncementConfig.DelayBetweenSounds = 0.75
FacilityAnnouncementConfig.MinimumRepeatDelay = 3

return FacilityAnnouncementConfig