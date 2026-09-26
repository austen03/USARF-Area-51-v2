local LockdownVisualConfig = {}

LockdownVisualConfig.AmbientLightTag = "USARF_AmbientLight"
LockdownVisualConfig.EmergencyLightTag = "USARF_EmergencyLight"
LockdownVisualConfig.DefconTag = "USARF_DefconPanel"

LockdownVisualConfig.Levels = {
	[0] = {
		Defcon = 5,

		AmbientColor = Color3.fromRGB(254, 243, 187),
		AmbientBrightness = 0.8,
		AmbientRange = 20,

		EmergencyEnabled = false,
		EmergencyColor = Color3.fromRGB(255, 248, 220),
		EmergencyBrightness = 0.45,
		EmergencyRange = 16,

		Flashing = false,
	},

	[1] = {
		Defcon = 4,

		AmbientColor = Color3.fromRGB(254, 243, 187),
		AmbientBrightness = 0.75,
		AmbientRange = 20,

		EmergencyEnabled = true,
		EmergencyColor = Color3.fromRGB(255, 215, 90),
		EmergencyBrightness = 1.0,
		EmergencyRange = 18,

		Flashing = false,
	},

	[2] = {
		Defcon = 3,

		AmbientColor = Color3.fromRGB(230, 210, 170),
		AmbientBrightness = 0.65,
		AmbientRange = 18,

		EmergencyEnabled = true,
		EmergencyColor = Color3.fromRGB(255, 150, 35),
		EmergencyBrightness = 2,
		EmergencyRange = 20,

		Flashing = true,
		FlashSpeed = 1.5,
		EmergencyOffTransparency = 0.6,
	},

	[3] = {
		Defcon = 2,

		AmbientColor = Color3.fromRGB(210, 190, 160),
		AmbientBrightness = 0.55,
		AmbientRange = 18,

		EmergencyEnabled = true,
		EmergencyColor = Color3.fromRGB(255, 45, 45),
		EmergencyBrightness = 2.5,
		EmergencyRange = 24,

		Flashing = true,
		FlashSpeed = 0.55,
		EmergencyOffTransparency = 0.65,
	},

	[4] = {
		Defcon = 1,

		AmbientColor = Color3.fromRGB(160, 140, 190),
		AmbientBrightness = 0.25,
		AmbientRange = 18,

		EmergencyEnabled = true,
		EmergencyColor = Color3.fromRGB(180,0,255),
		EmergencyBrightness = 4,
		EmergencyRange = 26,

		Flashing = true,
		FlashSpeed = 0.25,
		EmergencyOffTransparency = 0.7,
	},
}

return LockdownVisualConfig