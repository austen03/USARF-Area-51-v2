local UniformConfig = {}

UniformConfig.MorphFolderName = "Morphs"
UniformConfig.UniformAssetsFolderName = "UniformAssets"

UniformConfig.ApplyOnSpawn = true
UniformConfig.ApplyOnTeamChange = true

UniformConfig.RemoveOldMorphAccessories = true
UniformConfig.RemoveExistingClothing = true
UniformConfig.RemoveAvatarAccessories = true

UniformConfig.KeepAccessoryTypes = {}

UniformConfig.SnapInsigniaToSurface = true

UniformConfig.InsigniaSurfaceGap = 0.004

UniformConfig.Textures = {
	Patches = {
		USARF = "rbxassetid://96296737263493",
		USFlag = "rbxassetid://128430680903691",

		Patch108th = "rbxassetid://88203309177343",
		Patch137th = "rbxassetid://72097926817595",

		PatchAIG = "rbxassetid://91378974959668",
		PatchAlpha09 = "rbxassetid://90273570945891",
		PatchDelta01 = "rbxassetid://115113685507411",
		PatchIota12 = "rbxassetid://131268707920478",

		PatchCIA = "rbxassetid://83303192080502",
		PatchFBI = "rbxassetid://136330946357737",
		PatchFDS = "rbxassetid://130212877547930",
		PatchUSSS = "rbxassetid://86893025350295",
	},

	RankTabs = {
		MilitaryEnlisted = "rbxassetid://120650658583772",
		MilitaryNCO = "rbxassetid://116892106559252",
		MilitaryOfficer = "rbxassetid://98206174296707",
		MilitaryCommand = "rbxassetid://139764990826446",
		MilitaryGeneral = "rbxassetid://129528026039312",

		DeptPersonnel = "rbxassetid://91524564539277",
		DeptSupervisor = "rbxassetid://129770666144895",
		DeptManager = "rbxassetid://101288147579472",
		DeptExecutive = "rbxassetid://114641863693378",
		DeptAssistantDirector = "rbxassetid://107095357375127",
		DeptDirector = "rbxassetid://79353301628455",

		SpecOpsOperative = "rbxassetid://116916331182634",
		SpecOpsSquadSergeant = "rbxassetid://128940166752738",
		SpecOpsSquadExecutiveOfficer = "rbxassetid://140125143037140",
		SpecOpsSquadLeader = "rbxassetid://102304125869349",
		SpecOpsExecutiveOfficer = "rbxassetid://92374043251066",
		SpecOpsCommandingOfficer = "rbxassetid://133337268364933",
	},
}

UniformConfig.ImageRects = {
	-- Patches
	[96296737263493] = { 59, 29, 904, 732 }, -- USARF
	[128430680903691] = { 42, 323, 598, 335 }, -- USFlag
	[88203309177343] = { 67, 40, 890, 805 }, -- Patch108th
	[72097926817595] = { 41, 186, 599, 594 }, -- Patch137th
	[91378974959668] = { 42, 144, 599, 605 }, -- PatchAIG
	[90273570945891] = { 45, 145, 591, 669 }, -- PatchAlpha09
	[115113685507411] = { 45, 124, 591, 686 }, -- PatchDelta01
	[131268707920478] = { 45, 124, 591, 701 }, -- PatchIota12
	[83303192080502] = { 45, 125, 591, 700 }, -- PatchCIA
	[136330946357737] = { 44, 114, 592, 781 }, -- PatchFBI
	[130212877547930] = { 45, 103, 591, 757 }, -- PatchFDS
	[86893025350295] = { 32, 104, 617, 804 }, -- PatchUSSS

	-- Rank tabs
	[120650658583772] = { 8, 7, 652, 253 }, -- MilitaryEnlisted
	[116892106559252] = { 9, 6, 653, 270 }, -- MilitaryNCO
	[98206174296707] = { 5, 5, 653, 243 }, -- MilitaryOfficer
	[139764990826446] = { 11, 6, 653, 220 }, -- MilitaryCommand
	[129528026039312] = { 7, 8, 653, 196 }, -- MilitaryGeneral
	[91524564539277] = { 8, 8, 707, 186 }, -- DeptPersonnel
	[129770666144895] = { 8, 5, 707, 176 }, -- DeptSupervisor
	[101288147579472] = { 10, 6, 707, 172 }, -- DeptManager
	[114641863693378] = { 8, 8, 707, 182 }, -- DeptExecutive
	[107095357375127] = { 6, 4, 707, 162 }, -- DeptAssistantDirector
	[79353301628455] = { 8, 5, 707, 185 }, -- DeptDirector
	[116916331182634] = { 5, 7, 705, 185 }, -- SpecOpsOperative
	[128940166752738] = { 12, 10, 706, 176 }, -- SpecOpsSquadSergeant
	[140125143037140] = { 5, 5, 705, 167 }, -- SpecOpsSquadExecutiveOfficer
	[102304125869349] = { 11, 6, 705, 171 }, -- SpecOpsSquadLeader
	[92374043251066] = { 7, 7, 705, 160 }, -- SpecOpsExecutiveOfficer
	[133337268364933] = { 9, 5, 705, 191 }, -- SpecOpsCommandingOfficer
}

local function standardPatches(departmentPatch)
	return {
		{
			Template = "PatchTemplate",
			Texture = departmentPatch,
			Target = "LeftUpperArm",
			Offset = Vector3.new(-0.49, 0.04, 0.01),
			Rotation = Vector3.new(0, 0, 0),
			DepthOffset = 0.02,
			SurfaceWidth = 0.30,
			SurfaceHeight = 0.30,
		},

		{
			Template = "PatchTemplate",
			Texture = UniformConfig.Textures.Patches.USARF,
			Target = "RightUpperArm",
			Offset = Vector3.new(0.49, 0.04, 0.01),
			Rotation = Vector3.new(0, 0, 0),
			DepthOffset = 0.02,
			SurfaceWidth = 0.30,
			SurfaceHeight = 0.30,
		},

		{
			Template = "PatchTemplate",
			Texture = UniformConfig.Textures.Patches.USFlag,
			Target = "RightUpperArm",
			Offset = Vector3.new(0.49, -0.18, 0.01),
			Rotation = Vector3.new(0, 0, 0),
			DepthOffset = 0.02,
			SurfaceWidth = 0.18,
			SurfaceHeight = 0.10,
		},
	}
end

local function createRankTabSettings()
	return {
		RankTabTarget = "LeftUpperArm",
		RankTabOffset = Vector3.new(-0.49, -0.18, 0.01),
		RankTabRotation = Vector3.new(0, 0, 0),
		RankTabDepthOffset = 0.02,
		RankTabSurfaceWidth = 0.22,
		RankTabSurfaceHeight = 0.14,
	}
end

local function applyRankTabSettings(config)
	local settings = createRankTabSettings()

	for key, value in pairs(settings) do
		config[key] = value
	end

	return config
end

local R = UniformConfig.Textures.RankTabs
local P = UniformConfig.Textures.Patches

UniformConfig.Teams = {
	["108th Infantry Regiment"] = applyRankTabSettings({
		Folder = "108th",
		GroupId = 6075919,
		Fallback = "Private",

		RankMap = {
			[1] = "Private",
			[2] = "Specialist",
			[3] = "Corporal",
			[4] = "Sergeant",
			[5] = "SergeantMajor",
			[6] = "Lieutenant",
			[7] = "Captain",
			[8] = "Major",
			[9] = "Colonel",
			[10] = "General",
		},

		Patches = standardPatches(P.Patch108th),

		RankTabs = {
			GroupId = 6075919,
			Default = R.MilitaryEnlisted,

			[1] = R.MilitaryEnlisted,
			[2] = R.MilitaryEnlisted,
			[3] = R.MilitaryNCO,
			[4] = R.MilitaryNCO,
			[5] = R.MilitaryNCO,
			[6] = R.MilitaryOfficer,
			[7] = R.MilitaryOfficer,
			[8] = R.MilitaryCommand,
			[9] = R.MilitaryCommand,
			[10] = R.MilitaryGeneral,
		},
	}),

	["137th MP"] = applyRankTabSettings({
		Folder = "MP",
		GroupId = 8068762,
		Fallback = "Private",

		RankMap = {
			[1] = "Private",
			[2] = "Specialist",
			[3] = "Corporal",
			[4] = "Sergeant",
			[5] = "Lieutenant",
			[6] = "Captain",
			[7] = "Major",
			[8] = "Colonel",
		},

		Patches = standardPatches(P.Patch137th),

		RankTabs = {
			GroupId = 8068762,
			Default = R.MilitaryEnlisted,

			[1] = R.MilitaryEnlisted,
			[2] = R.MilitaryEnlisted,
			[3] = R.MilitaryNCO,
			[4] = R.MilitaryNCO,
			[5] = R.MilitaryOfficer,
			[6] = R.MilitaryOfficer,
			[7] = R.MilitaryCommand,
			[8] = R.MilitaryGeneral,
		},
	}),

	["1st Spec Ops A.I.G."] = {
		Folder = "TFs",

		GroupId = 6075911,
		Fallback = "",

		Variants = {
			{
				Name = "AIGCommand",
				GroupId = 6075911,
				MinimumRank = 8,

				RankMap = {
					[8] = "XO",
					[9] = "CO",
				},

				Patches = standardPatches(P.PatchAIG),

				RankTabs = {
					GroupId = 6075911,
					Default = R.SpecOpsExecutiveOfficer,

					[8] = R.SpecOpsExecutiveOfficer,
					[9] = R.SpecOpsCommandingOfficer,
				},
			},

			{
				Name = "Delta01",
				GroupId = 35249280,
				MinimumRank = 1,

				RankMap = {
					[1] = "D1",
					[2] = "D1 TFS",
					[3] = "D1 TFXO",
					[4] = "D1 TFL",
				},

				Patches = standardPatches(P.PatchDelta01),

				RankTabs = {
					GroupId = 35249280,
					Default = R.SpecOpsOperative,

					[1] = R.SpecOpsOperative,
					[2] = R.SpecOpsSquadSergeant,
					[3] = R.SpecOpsSquadExecutiveOfficer,
					[4] = R.SpecOpsSquadLeader,
				},
			},

			{
				Name = "Iota12",
				GroupId = 35249273,
				MinimumRank = 1,

				RankMap = {
					[1] = "I12",
					[2] = "I12 TFS",
					[3] = "I12 TFXO",
					[4] = "I12 TFL",
				},

				Patches = standardPatches(P.PatchIota12),

				RankTabs = {
					GroupId = 35249273,
					Default = R.SpecOpsOperative,

					[1] = R.SpecOpsOperative,
					[2] = R.SpecOpsSquadSergeant,
					[3] = R.SpecOpsSquadExecutiveOfficer,
					[4] = R.SpecOpsSquadLeader,
				},
			},

			{
				Name = "Alpha09",
				GroupId = 35249250,
				MinimumRank = 1,

				RankMap = {
					[1] = "A09",
					[2] = "A09 TFS",
					[3] = "A09 TFXO",
					[4] = "A09 TFL",
				},

				Patches = standardPatches(P.PatchAlpha09),

				RankTabs = {
					GroupId = 35249250,
					Default = R.SpecOpsOperative,

					[1] = R.SpecOpsOperative,
					[2] = R.SpecOpsSquadSergeant,
					[3] = R.SpecOpsSquadExecutiveOfficer,
					[4] = R.SpecOpsSquadLeader,
				},
			},
		},

		RankTabTarget = "LeftUpperArm",
		RankTabOffset = Vector3.new(-0.49, -0.18, 0.01),
		RankTabRotation = Vector3.new(0, 0, 0),
		RankTabDepthOffset = 0.02,
		RankTabSurfaceWidth = 0.22,
		RankTabSurfaceHeight = 0.14,
	},

	["CIA"] = applyRankTabSettings({
		Folder = "CIA",
		GroupId = 6033914,
		Fallback = "Default",

		Patches = standardPatches(P.PatchCIA),

		RankTabs = {
			GroupId = 6033914,
			Default = R.DeptPersonnel,

			[1] = R.DeptPersonnel,
			[2] = R.DeptSupervisor,
			[3] = R.DeptManager,
			[4] = R.DeptExecutive,
			[5] = R.DeptAssistantDirector,
			[255] = R.DeptDirector,
		},

		RankTabOffset = Vector3.new(-0.49, -0.18, 0.02),
	}),

	["FBI"] = applyRankTabSettings({
		Folder = "FBI",
		GroupId = 6033902,
		Fallback = "Default",

		Patches = standardPatches(P.PatchFBI),

		RankTabs = {
			GroupId = 6033902,
			Default = R.DeptPersonnel,

			[1] = R.DeptPersonnel,
			[2] = R.DeptSupervisor,
			[3] = R.DeptManager,
			[4] = R.DeptExecutive,
			[5] = R.DeptAssistantDirector,
			[255] = R.DeptDirector,
		},

		RankTabOffset = Vector3.new(-0.49, -0.18, 0.02),
	}),

	["Secret Service"] = applyRankTabSettings({
		Folder = "USSS",
		GroupId = 6033945,
		Fallback = "AIT",

		RankMap = {
			[1] = "AIT",
			[2] = "Agent",
			[3] = "CAT",
			[4] = "Special Agent",
			[5] = "SIAC",
			[6] = "COO",
			[7] = "DD",
			[8] = "Director",
		},

		Patches = standardPatches(P.PatchUSSS),

		RankTabs = {
			GroupId = 6033945,
			Default = R.DeptPersonnel,

			[1] = R.DeptPersonnel,
			[2] = R.DeptPersonnel,
			[3] = R.DeptSupervisor,
			[4] = R.DeptSupervisor,
			[5] = R.DeptManager,
			[6] = R.DeptExecutive,
			[7] = R.DeptAssistantDirector,
			[8] = R.DeptDirector,
		},

		RankTabOffset = Vector3.new(-0.49, -0.18, 0.02),
	}),
}

return UniformConfig
