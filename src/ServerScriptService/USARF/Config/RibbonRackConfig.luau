-- USARF Ribbon Rack configuration
-- Priority 1 is the highest-precedence ribbon (top-left of the rack).

local RibbonRackConfig = {}

RibbonRackConfig.Rack = {
	Name = "USARF_RibbonRack",
	MaxColumns = 3,
	RibbonWidth = 0.205,
	RibbonHeight = 0.060,
	HorizontalGap = 0.008,
	VerticalGap = 0.008,
	Depth = 0.020,

	-- SurfaceGui resolution for each ribbon.
	PixelWidth = 256,
	PixelHeight = 72,
	PixelGap = 6,
}

RibbonRackConfig.Mount = {
	-- Add an Attachment with this name to a vest if you want a custom fit.
	-- Its WorldCFrame is treated as the TOP-CENTER of the rack.
	AttachmentName = "USARF_MedalMount",
	AttachmentAdjustment = CFrame.new(),

	-- Initial fit derived from Test Medal Morph.rbxm.
	-- This is also the TOP-CENTER of the rack, relative to UpperTorso.
	UpperTorsoTopCenterOffset = CFrame.new(0.450, 0.500, -0.760),
}

-- Permanent source of medals: the "medals" tab of the A51 In-game Systems sheet.
-- Columns: Roblox Username | Roblox UserId | Medals: (multi-select dropdown, which
-- arrives as a comma-separated list, e.g. "Medal of Honor, Combat Medal").
-- The sheet web app renames "Medals:" to "Awards", so both are accepted.
RibbonRackConfig.GoogleSheet = {
	Enabled = true,
	Url = "https://script.google.com/macros/s/AKfycbxLBXO-xrQSH-lkl_zsyMKtvv2pXHivaXR_ikCHJJhaexuVk1gq0Dljy6OF3lJD2o0u0g/exec?sheet=medals",
	CacheSeconds = 300,

	-- Matched ignoring case, spaces and punctuation.
	UserIdColumns = { "RobloxUserId", "UserId" },
	MedalColumns = { "Medals", "Awards", "Ribbons" },
}

-- Temporary, in-server medals (testing / live grants). These are added on top
-- of the sheet and are lost when the player leaves.
RibbonRackConfig.Ownership = {
	-- JSON array, for example:
	-- player:SetAttribute("USARF_Medals", '["MedalOfHonor","CombatMedal"]')
	AttributeName = "USARF_Medals",

	-- Optional alternative: a Folder under Player containing enabled BoolValues.
	FolderName = "Medals",
}

RibbonRackConfig.Rendering = {
	AlwaysOnTop = false,
	LightInfluence = 0.25,
	ZOffset = 1,
}

RibbonRackConfig.Testing = {
	-- Leave false in production. Set true temporarily to show every configured
	-- ribbon on every player while testing in Studio.
	GrantAllInStudio = false,
}

-- Medal names in the sheet are matched against Key, DisplayName and Aliases,
-- ignoring case, spaces and punctuation ("medal of honor" = "MedalOfHonor").
RibbonRackConfig.Medals = {
	{
		Key = "MedalOfHonor",
		DisplayName = "Medal of Honor",
		ImageId = 71685290237082,
		Priority = 1,
	},
	{
		Key = "MedalOfValor",
		DisplayName = "Medal of Valor",
		ImageId = 139034837553955,
		Priority = 2,
	},
	{
		Key = "FoundationCross",
		DisplayName = "Foundation Cross",
		ImageId = 101970258936900,
		Priority = 3,
	},
	{
		Key = "CabinetCross",
		DisplayName = "Cabinet Cross (O5 Council Cross)",
		ImageId = 96125276112122,
		Priority = 4,
		Aliases = { "Cabinet Cross", "O5 Council Cross" },
	},
	{
		Key = "FoundationDistinguishedServiceMedal",
		DisplayName = "Foundation Distinguished Service Medal",
		ImageId = 74454088746491,
		Priority = 5,
	},
	{
		Key = "JusticeMedal",
		DisplayName = "Justice Medal",
		ImageId = 108870326377925,
		Priority = 6,
		Aliases = { "Legal Affairs Medal" },
	},
	{
		Key = "CombatMedal",
		DisplayName = "Combat Medal",
		ImageId = 109416641757141,
		Priority = 7,
	},
	{
		Key = "SecurityServiceMedal",
		DisplayName = "Security Service Medal",
		ImageId = 103089204669598,
		Priority = 8,
		-- A second ID was supplied with the same name. Swap to this ID if it is
		-- the intended version: 82697564051238
		AlternateImageIds = { 82697564051238 },
	},
	{
		Key = "IntelligenceMedal",
		DisplayName = "Intelligence Medal",
		ImageId = 131738560679181,
		Priority = 9,
	},
	{
		Key = "ScientificMedal",
		DisplayName = "Scientific Medal",
		ImageId = 83988410168921,
		Priority = 10,
	},
	{
		Key = "MedicalMedal",
		DisplayName = "Medical Medal",
		ImageId = 72657529291512,
		Priority = 11,
	},
	{
		Key = "TechnicalMedal",
		DisplayName = "Technical Medal",
		ImageId = 118867050819906,
		Priority = 12,
	},
	{
		Key = "ContainmentOpsMedal",
		DisplayName = "Containment Ops Medal",
		ImageId = 114309708379771,
		Priority = 13,
	},
	{
		Key = "AviationMedal",
		DisplayName = "Aviation Medal",
		ImageId = 129129107746796,
		Priority = 14,
	},
	{
		Key = "DiplomacyMedal",
		DisplayName = "Diplomacy Medal",
		ImageId = 83891162659484,
		Priority = 15,
	},
	{
		Key = "AdministrationMedal",
		DisplayName = "Administration Medal",
		ImageId = 73372622520399,
		Priority = 16,
	},
	{
		Key = "TrainingAndRecruitmentMedal",
		DisplayName = "Training & Recruitment Medal",
		ImageId = 71120829548267,
		Priority = 17,
		Aliases = { "Training and Recruitment Medal" },
	},
}

return RibbonRackConfig
