local RibbonRackConfig = {}

RibbonRackConfig.Rack = {
	Name = "USARF_RibbonRack",
	MaxColumns = 3,
	RibbonWidth = 0.108,
	RibbonHeight = 0.036,
	HorizontalGap = 0,
	VerticalGap = 0,
	Depth = 0.004,
	PixelWidth = 240,
	PixelHeight = 80,
	PixelGap = 0,
	CropInsetPixels = 3,
}

RibbonRackConfig.Mount = {

	AnchorEdge = "Bottom",
	AttachmentName = "USARF_MedalMount",
	AttachmentAdjustment = CFrame.new(),
	UpperTorsoOffset = CFrame.new(0.360, 0.305, -0.630),
}

RibbonRackConfig.GoogleSheet = {
	Enabled = true,
	Url = "https://script.google.com/macros/s/AKfycbxLBXO-xrQSH-lkl_zsyMKtvv2pXHivaXR_ikCHJJhaexuVk1gq0Dljy6OF3lJD2o0u0g/exec?sheet=medals",
	CacheSeconds = 300,

	UserIdColumns = { "RobloxUserId", "UserId" },
	MedalColumns = { "Awards" },
}

RibbonRackConfig.Ownership = {

	AttributeName = "USARF_Medals",
	FolderName = "Medals",
}

RibbonRackConfig.Rendering = {
	AlwaysOnTop = false,
	LightInfluence = 0.25,
	ZOffset = 1,
}
RibbonRackConfig.Medals = {
	{
		Key = "MedalOfHonor",
		DisplayName = "Medal of Honor",
		ImageId = 71685290237082,
		ImageRect = { 50, 171, 924, 308 },
		Priority = 1,
	},
	{
		Key = "MedalOfValor",
		DisplayName = "Medal of Valor",
		ImageId = 139034837553955,
		ImageRect = { 91, 182, 840, 349 },
		Priority = 2,
	},
	{
		Key = "FoundationCross",
		DisplayName = "Foundation Cross",
		ImageId = 101970258936900,
		ImageRect = { 87, 208, 850, 228 },
		Priority = 3,
	},
	{
		Key = "CabinetCross",
		DisplayName = "Cabinet Cross (O5 Council Cross)",
		ImageId = 96125276112122,
		ImageRect = { 87, 208, 850, 228 },
		Priority = 4,
		Aliases = { "Cabinet Cross", "O5 Council Cross" },
	},
	{
		Key = "FoundationDistinguishedServiceMedal",
		DisplayName = "Foundation Distinguished Service Medal",
		ImageId = 74454088746491,
		ImageRect = { 49, 171, 925, 308 },
		Priority = 5,
	},
	{
		Key = "JusticeMedal",
		DisplayName = "Justice Medal",
		ImageId = 108870326377925,
		ImageRect = { 88, 156, 847, 373 },
		Priority = 6,
		Aliases = { "Legal Affairs Medal" },
	},
	{
		Key = "CombatMedal",
		DisplayName = "Combat Medal",
		ImageId = 109416641757141,
		ImageRect = { 90, 180, 843, 323 },
		Priority = 7,
	},
	{
		Key = "SecurityServiceMedal",
		DisplayName = "Security Service Medal",
		ImageId = 82697564051238,
		ImageRect = { 108, 219, 806, 278 },
		Priority = 8,
	},
	{
		Key = "IntelligenceMedal",
		DisplayName = "Intelligence Medal",
		ImageId = 131738560679181,
		ImageRect = { 87, 208, 849, 226 },
		Priority = 9,
	},
	{
		Key = "ScientificMedal",
		DisplayName = "Scientific Medal",
		ImageId = 83988410168921,
		ImageRect = { 87, 230, 850, 204 },
		Priority = 10,
	},
	{
		Key = "MedicalMedal",
		DisplayName = "Medical Medal",
		ImageId = 72657529291512,
		ImageRect = { 90, 174, 842, 334 },
		Priority = 11,
	},
	{
		Key = "TechnicalMedal",
		DisplayName = "Technical Medal",
		ImageId = 118867050819906,
		ImageRect = { 87, 208, 850, 226 },
		Priority = 12,
	},
	{
		Key = "ContainmentOpsMedal",
		DisplayName = "Containment Ops Medal",
		ImageId = 114309708379771,
		ImageRect = { 108, 219, 806, 278 },
		Priority = 13,
	},
	{
		Key = "AviationMedal",
		DisplayName = "Aviation Medal",
		ImageId = 129129107746796,
		ImageRect = { 108, 219, 806, 278 },
		Priority = 14,
	},
	{
		Key = "DiplomacyMedal",
		DisplayName = "Diplomacy Medal",
		ImageId = 83891162659484,
		ImageRect = { 108, 220, 807, 256 },
		Priority = 15,
	},
	{
		Key = "AdministrationMedal",
		DisplayName = "Administration Medal",
		ImageId = 73372622520399,
		ImageRect = { 109, 220, 805, 256 },
		Priority = 16,
	},
	{
		Key = "TrainingAndRecruitmentMedal",
		DisplayName = "Training & Recruitment Medal",
		ImageId = 71120829548267,
		ImageRect = { 108, 219, 806, 278 },
		Priority = 17,
		Aliases = { "Training and Recruitment Medal" },
	},
}

return RibbonRackConfig
