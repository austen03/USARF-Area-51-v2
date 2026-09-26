-- USARF Ribbon Rack configuration
-- Priority 1 is the highest-precedence ribbon (top-left of the rack).

local RibbonRackConfig = {}

RibbonRackConfig.Rack = {
	Name = "USARF_RibbonRack",
	MaxColumns = 3,
	-- Ribbons touch edge to edge (no gaps) so the rack reads as one solid bar.
	-- Sized so three columns fill the plate area beside the name tape (0.34 studs).
	RibbonWidth = 0.108,
	RibbonHeight = 0.036,
	HorizontalGap = 0,
	VerticalGap = 0,
	Depth = 0.020,

	-- SurfaceGui resolution for each ribbon.
	PixelWidth = 240,
	PixelHeight = 80,
	PixelGap = 0,

	-- Pixels trimmed from each edge of a ribbon's ImageRect to hide the images'
	-- slightly soft/rounded edges where neighbouring ribbons meet.
	CropInsetPixels = 3,
}

RibbonRackConfig.Mount = {
	-- "Bottom": the mount point is the rack's BOTTOM-CENTER and new rows stack upward.
	-- "Top": the mount point is the TOP-CENTER and new rows stack downward.
	AnchorEdge = "Bottom",

	-- Add an Attachment with this name to a vest if you want a custom fit.
	-- Its WorldCFrame is treated as the rack's AnchorEdge center.
	AttachmentName = "USARF_MedalMount",
	AttachmentAdjustment = CFrame.new(),

	-- Rack anchor point relative to UpperTorso. Measured against the 108th/MP
	-- "condor" vest: the flat plate area beside the name tape, between the tape's
	-- edge (x 0.19) and the plate's edge (x ~0.54), from the tape's bottom
	-- (y 0.30) up to ~0.55, resting on the plate surface (z -0.61 to -0.62).
	-- The bottom row lines up with the bottom of the name tape; six rows
	-- (all 17 ribbons) fit before reaching the plate's top corner.
	UpperTorsoOffset = CFrame.new(0.360, 0.305, -0.630),
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
--
-- ImageRect = { x, y, width, height }: where the ribbon sits inside its image, in
-- pixels. The images are 1023x682 with transparent padding around the ribbon, so
-- this crop is what lets each ribbon fill its slot. If you change an ImageId,
-- update its ImageRect too (or remove it to show the whole image).
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
