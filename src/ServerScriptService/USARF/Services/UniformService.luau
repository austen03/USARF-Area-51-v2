local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local USARFStorage = ReplicatedStorage:WaitForChild("USARF")
local ConfigFolder = USARFStorage:WaitForChild("Config")
local UniformConfig = require(ConfigFolder:WaitForChild("UniformConfig"))

local ServerScriptService = game:GetService("ServerScriptService")
local Services = ServerScriptService:WaitForChild("USARF"):WaitForChild("Services")
local AvatarBlacklistService = require(Services:WaitForChild("AvatarBlacklistService"))

local MorphsFolder = ServerStorage:WaitForChild("Morphs")
local UniformAssets = ServerStorage:WaitForChild("UniformAssets")
local TemplateFolder = UniformAssets:WaitForChild("Templates")

local UniformService = {}

local started = false
local connections: {RBXScriptConnection} = {}
local playerConnections: {[Player]: {RBXScriptConnection}} = {}
local applyGenerations: {[Player]: number} = {}
local originalDescriptions: {[Player]: HumanoidDescription} = {}

local ATTACHMENT_FOLDER_NAME = "USARFUniformAttachments"
local MORPH_ITEM_ATTRIBUTE = "USARFMorphItem"

local DEFAULT_PATCH_TEMPLATE = "PatchTemplate"
local DEFAULT_RANK_TAB_TEMPLATE = "RankTabTemplate"

local DEFAULT_PIXELS_PER_STUD = 250
local DEFAULT_SURFACE_LIGHT_INFLUENCE = 0
local TEST_PATCH_ALWAYS_ON_TOP = false

local DEFAULT_PART_THICKNESS = 0.01
local DEFAULT_PATCH_SURFACE_WIDTH = 0.42
local DEFAULT_PATCH_SURFACE_HEIGHT = 0.42
local DEFAULT_RANK_TAB_SURFACE_WIDTH = 0.38
local DEFAULT_RANK_TAB_SURFACE_HEIGHT = 0.18

-- Pushes SurfaceGui holders out from the R15 arm so they do not sit inside the sleeve morph.
local DEFAULT_PATCH_DEPTH_OFFSET = 0.28
local DEFAULT_RANK_TAB_DEPTH_OFFSET = 0.28

local APPLY_DELAY_SECONDS = 0.35

local BODY_PART_ALIASES: {[string]: string} = {
	Head = "Head",
	Hair = "Head",
	Hat = "Head",
	Helmet = "Head",
	Face = "Head",

	Chest = "UpperTorso",
	Torso = "UpperTorso",
	UpperTorso = "UpperTorso",
	LowerTorso = "LowerTorso",
	Waist = "LowerTorso",

	LeftArm = "LeftUpperArm",
	LeftUpperArm = "LeftUpperArm",
	LeftLowerArm = "LeftLowerArm",
	LeftHand = "LeftHand",

	RightArm = "RightUpperArm",
	RightUpperArm = "RightUpperArm",
	RightLowerArm = "RightLowerArm",
	RightHand = "RightHand",

	LeftLeg = "LeftUpperLeg",
	LeftUpperLeg = "LeftUpperLeg",
	LeftLowerLeg = "LeftLowerLeg",
	LeftFoot = "LeftFoot",

	RightLeg = "RightUpperLeg",
	RightUpperLeg = "RightUpperLeg",
	RightLowerLeg = "RightLowerLeg",
	RightFoot = "RightFoot",
}

export type PatchDefinition = {
	Template: string?,
	Texture: any?,
	Image: any?,
	AssetId: any?,
	Target: string?,
	Offset: Vector3?,
	Rotation: Vector3?,
	Scale: Vector3?,
	CFrameOffset: CFrame?,
	Face: Enum.NormalId?,
	PixelsPerStud: number?,
	ScaleType: Enum.ScaleType?,
	Size: Vector3?,
	SurfaceWidth: number?,
	SurfaceHeight: number?,
	DepthOffset: number?,
	FlipOutward: boolean?,
	AlwaysOnTop: boolean?,
}

local function configValue(teamConfig: any?, key: string, defaultValue: any): any
	if typeof(teamConfig) == "table" and teamConfig[key] ~= nil then
		return teamConfig[key]
	end

	if UniformConfig[key] ~= nil then
		return UniformConfig[key]
	end

	return defaultValue
end

local function appendConnection(connection: RBXScriptConnection)
	table.insert(connections, connection)
end

local function textureToImage(texture: any): string
	if texture == nil then
		return ""
	end

	if typeof(texture) == "number" then
		return `rbxassetid://{texture}`
	end

	local textureString = tostring(texture)
	if textureString == "" then
		return ""
	end

	if string.find(textureString, "rbxassetid://", 1, true) then
		return textureString
	end

	if tonumber(textureString) then
		return `rbxassetid://{textureString}`
	end

	return textureString
end

local function getOrCreateAttachmentFolder(character: Model): Folder
	local existing = character:FindFirstChild(ATTACHMENT_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = ATTACHMENT_FOLDER_NAME
	folder.Parent = character

	return folder
end

local function clearAttachmentFolder(character: Model)
	local existing = character:FindFirstChild(ATTACHMENT_FOLDER_NAME)
	if existing then
		existing:Destroy()
	end
end

local function removeOldMorphItems(character: Model)
	for _, child in character:GetChildren() do
		if child:GetAttribute(MORPH_ITEM_ATTRIBUTE) then
			child:Destroy()
		end
	end
end

local function removeExistingClothing(character: Model)
	for _, child in character:GetChildren() do
		if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") then
			child:Destroy()
		end
	end
end

local function removeAvatarAccessories(character: Model)
	for _, child in character:GetChildren() do
		if child:IsA("Accessory") and not child:GetAttribute(MORPH_ITEM_ATTRIBUTE) then
			child:Destroy()
		end
	end
end

local function markMorphItem(instance: Instance)
	instance:SetAttribute(MORPH_ITEM_ATTRIBUTE, true)

	for _, descendant in instance:GetDescendants() do
		descendant:SetAttribute(MORPH_ITEM_ATTRIBUTE, true)
	end
end

local function applyClothingObject(character: Model, clothingObject: Instance)
	if clothingObject:IsA("Shirt") or clothingObject:IsA("Pants") or clothingObject:IsA("ShirtGraphic") then
		local clone = clothingObject:Clone()
		markMorphItem(clone)
		clone.Parent = character
	end
end

local function applyClothing(character: Model, morphModel: Instance, teamConfig: any)
	local clothingSource = morphModel:FindFirstChild("Clothing")

	if clothingSource then
		for _, child in clothingSource:GetChildren() do
			applyClothingObject(character, child)
		end
	end

	local configuredClothing = if typeof(teamConfig) == "table" then teamConfig.Clothing else nil

	if typeof(configuredClothing) == "table" then
		local shirtId = configuredClothing.Shirt or configuredClothing.ShirtTemplate
		local pantsId = configuredClothing.Pants or configuredClothing.PantsTemplate
		local graphicId = configuredClothing.ShirtGraphic or configuredClothing.Graphic

		if shirtId then
			local shirt = Instance.new("Shirt")
			shirt.ShirtTemplate = textureToImage(shirtId)
			markMorphItem(shirt)
			shirt.Parent = character
		end

		if pantsId then
			local pants = Instance.new("Pants")
			pants.PantsTemplate = textureToImage(pantsId)
			markMorphItem(pants)
			pants.Parent = character
		end

		if graphicId then
			local shirtGraphic = Instance.new("ShirtGraphic")
			shirtGraphic.Graphic = textureToImage(graphicId)
			markMorphItem(shirtGraphic)
			shirtGraphic.Parent = character
		end
	end
end

local function findTemplate(templateName: string?): Instance?
	local resolvedName = templateName or DEFAULT_PATCH_TEMPLATE
	return TemplateFolder:FindFirstChild(resolvedName)
end

local function getHolderPart(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end

	if not instance:IsA("Model") then
		return nil
	end

	if instance.PrimaryPart then
		return instance.PrimaryPart
	end

	local middle = instance:FindFirstChild("Middle", true)

	if middle and middle:IsA("BasePart") then
		instance.PrimaryPart = middle
		return middle
	end

	local firstPart = instance:FindFirstChildWhichIsA("BasePart", true)

	if firstPart then
		instance.PrimaryPart = firstPart
		return firstPart
	end

	return nil
end

local function configureInvisibleParts(instance: Instance)
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.Massless = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.CastShadow = false
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			descendant.Transparency = 1
		end
	end

	if instance:IsA("BasePart") then
		instance.Anchored = false
		instance.Massless = true
		instance.CanCollide = false
		instance.CanTouch = false
		instance.CanQuery = false
		instance.CastShadow = false
	end
end

local function configurePhysicalParts(instance: Instance)
	configureInvisibleParts(instance)

	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
		end
	end

	if instance:IsA("BasePart") then
		instance.Transparency = 1
	end
end

local function chooseOutsideFace(targetPartName: string?, offset: Vector3?, explicitFace: Enum.NormalId?): Enum.NormalId
	if explicitFace then
		return explicitFace
	end

	if offset then
		if offset.X < 0 then
			return Enum.NormalId.Left
		elseif offset.X > 0 then
			return Enum.NormalId.Right
		end
	end

	if targetPartName and string.find(targetPartName, "Left") then
		return Enum.NormalId.Left
	end

	return Enum.NormalId.Right
end

local function getSurfaceGuis(holderPart: BasePart): {SurfaceGui}
	local surfaceGuis: {SurfaceGui} = {}

	for _, child in holderPart:GetChildren() do
		if child:IsA("SurfaceGui") then
			table.insert(surfaceGuis, child)
		end
	end

	return surfaceGuis
end

local function getOrCreateImageLabel(surfaceGui: SurfaceGui): ImageLabel
	local imageLabel = surfaceGui:FindFirstChildWhichIsA("ImageLabel", true)

	if imageLabel then
		return imageLabel
	end

	imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "ImageLabel"
	imageLabel.Parent = surfaceGui

	return imageLabel
end

local function configureImageLabel(imageLabel: ImageLabel, image: string, patchInfo: PatchDefinition)
	imageLabel.Visible = true
	imageLabel.Image = image
	imageLabel.ImageTransparency = 0
	imageLabel.BackgroundTransparency = 1
	imageLabel.BorderSizePixel = 0
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.Position = UDim2.fromScale(0.5, 0.5)
	imageLabel.Size = UDim2.fromScale(1, 1)
	imageLabel.ScaleType = patchInfo.ScaleType or Enum.ScaleType.Stretch
	imageLabel.ZIndex = 1
end

local function configureSurfaceGuis(holderPart: BasePart, patchInfo: PatchDefinition)
	local image = textureToImage(patchInfo.Texture or patchInfo.Image or patchInfo.AssetId)
	local surfaceGuis = getSurfaceGuis(holderPart)

	if #surfaceGuis == 0 then
		local surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Name = "SurfaceGui"
		surfaceGui.Parent = holderPart
		table.insert(surfaceGuis, surfaceGui)
	end

	for _, surfaceGui in surfaceGuis do
		if surfaceGui.Parent ~= holderPart then
			surfaceGui.Parent = holderPart
		end

		surfaceGui.Adornee = holderPart
		surfaceGui.Enabled = true
		surfaceGui.AlwaysOnTop = if patchInfo.AlwaysOnTop ~= nil then patchInfo.AlwaysOnTop else TEST_PATCH_ALWAYS_ON_TOP
		surfaceGui.LightInfluence = DEFAULT_SURFACE_LIGHT_INFLUENCE
		surfaceGui.PixelsPerStud = math.max(patchInfo.PixelsPerStud or DEFAULT_PIXELS_PER_STUD, DEFAULT_PIXELS_PER_STUD)
		surfaceGui.Face = Enum.NormalId.Front
		surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud

		local imageLabel = getOrCreateImageLabel(surfaceGui)
		configureImageLabel(imageLabel, image, patchInfo)
	end
end

local function getScaleComponent(scale: Vector3?, axis: string): number
	if not scale then
		return 1
	end

	if axis == "X" then
		return scale.X
	elseif axis == "Y" then
		return scale.Y
	end

	return scale.Z
end

local function getDefaultSurfaceSize(defaultTemplateName: string): (number, number)
	if defaultTemplateName == DEFAULT_RANK_TAB_TEMPLATE then
		return DEFAULT_RANK_TAB_SURFACE_WIDTH, DEFAULT_RANK_TAB_SURFACE_HEIGHT
	end

	return DEFAULT_PATCH_SURFACE_WIDTH, DEFAULT_PATCH_SURFACE_HEIGHT
end

local function scaleHolderPart(holderPart: BasePart, patchInfo: PatchDefinition, defaultTemplateName: string)
	if patchInfo.Size then
		holderPart.Size = patchInfo.Size
		return
	end

	local defaultWidth, defaultHeight = getDefaultSurfaceSize(defaultTemplateName)
	local scale = patchInfo.Scale
	local width = patchInfo.SurfaceWidth or defaultWidth
	local height = patchInfo.SurfaceHeight or defaultHeight

	holderPart.Size = Vector3.new(
		math.max(width * getScaleComponent(scale, "X"), DEFAULT_PART_THICKNESS),
		math.max(height * getScaleComponent(scale, "Y"), DEFAULT_PART_THICKNESS),
		math.max(DEFAULT_PART_THICKNESS * getScaleComponent(scale, "Z"), DEFAULT_PART_THICKNESS)
	)
end

local function getOutwardLocalVector(face: Enum.NormalId): Vector3
	if face == Enum.NormalId.Left then
		return Vector3.new(-1, 0, 0)
	elseif face == Enum.NormalId.Right then
		return Vector3.new(1, 0, 0)
	elseif face == Enum.NormalId.Front then
		return Vector3.new(0, 0, -1)
	elseif face == Enum.NormalId.Back then
		return Vector3.new(0, 0, 1)
	elseif face == Enum.NormalId.Top then
		return Vector3.new(0, 1, 0)
	end

	return Vector3.new(0, -1, 0)
end

local function getRollRadians(rotation: Vector3?): number
	if not rotation then
		return 0
	end

	return math.rad(rotation.Z)
end

local function getCharacterOutwardWorld(targetPart: BasePart): Vector3?
	local character = targetPart.Parent

	if not character then
		return nil
	end

	local torso = character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("LowerTorso")
		or character:FindFirstChild("HumanoidRootPart")

	if not torso or not torso:IsA("BasePart") then
		return nil
	end

	local outward = targetPart.Position - torso.Position
	local vertical = torso.CFrame.UpVector * outward:Dot(torso.CFrame.UpVector)
	outward -= vertical

	if outward.Magnitude < 0.001 then
		return nil
	end

	return outward.Unit
end

local function getCorrectedOutwardLocal(targetPart: BasePart, outwardLocal: Vector3, patchInfo: PatchDefinition): Vector3
	if patchInfo.FlipOutward then
		return -outwardLocal
	end

	if patchInfo.Face then
		return outwardLocal
	end

	local outwardWorld = targetPart.CFrame:VectorToWorldSpace(outwardLocal)
	local characterOutwardWorld = getCharacterOutwardWorld(targetPart)

	if characterOutwardWorld and outwardWorld:Dot(characterOutwardWorld) < 0 then
		return -outwardLocal
	end

	return outwardLocal
end

local function getDepthOffset(patchInfo: PatchDefinition, defaultTemplateName: string): number
	if patchInfo.DepthOffset ~= nil then
		return patchInfo.DepthOffset
	end

	if defaultTemplateName == DEFAULT_RANK_TAB_TEMPLATE then
		return DEFAULT_RANK_TAB_DEPTH_OFFSET
	end

	return DEFAULT_PATCH_DEPTH_OFFSET
end

local function getPlacementCFrame(targetPart: BasePart, patchInfo: PatchDefinition, targetPartName: string?, defaultTemplateName: string): CFrame
	if patchInfo.CFrameOffset then
		return targetPart.CFrame * patchInfo.CFrameOffset
	end

	local offset = patchInfo.Offset or Vector3.zero
	local face = chooseOutsideFace(targetPartName or targetPart.Name, offset, patchInfo.Face)
	local outwardLocal = getCorrectedOutwardLocal(targetPart, getOutwardLocalVector(face), patchInfo)
	local depthOffset = getDepthOffset(patchInfo, defaultTemplateName)

	local finalOffset = offset + outwardLocal * depthOffset
	local outwardWorld = targetPart.CFrame:VectorToWorldSpace(outwardLocal)
	local upWorld = targetPart.CFrame.UpVector

	if math.abs(outwardWorld:Dot(upWorld)) > 0.98 then
		upWorld = targetPart.CFrame.RightVector
	end

	local position = (targetPart.CFrame * CFrame.new(finalOffset)).Position

	return CFrame.lookAt(position, position + outwardWorld, upWorld) * CFrame.Angles(0, 0, getRollRadians(patchInfo.Rotation))
end

local function weldHolderToTarget(holderPart: BasePart, targetPart: BasePart)
	for _, child in holderPart:GetChildren() do
		if child:IsA("WeldConstraint") and child.Name == "USARFUniformWeld" then
			child:Destroy()
		end
	end

	local weld = Instance.new("WeldConstraint")
	weld.Name = "USARFUniformWeld"
	weld.Part0 = targetPart
	weld.Part1 = holderPart
	weld.Parent = holderPart
end

local function attachSurfaceGuiTemplate(character: Model, patchInfo: PatchDefinition, defaultTemplateName: string, attachmentName: string): Instance?
	local targetPartName = patchInfo.Target

	if not targetPartName or targetPartName == "" then
		warn(`USARF UniformService: missing Target for {attachmentName}`)
		return nil
	end

	local targetPart = character:FindFirstChild(targetPartName)

	if not targetPart or not targetPart:IsA("BasePart") then
		warn(`USARF UniformService: could not find R15 target part {targetPartName} for {attachmentName}`)
		return nil
	end

	local template = findTemplate(patchInfo.Template or defaultTemplateName)

	if not template then
		warn(`USARF UniformService: missing template {patchInfo.Template or defaultTemplateName} for {attachmentName}`)
		return nil
	end

	local clone = template:Clone()
	clone.Name = attachmentName
	markMorphItem(clone)

	local holderPart = getHolderPart(clone)

	if not holderPart then
		clone:Destroy()
		warn(`USARF UniformService: template {template.Name} has no BasePart/Middle holder`)
		return nil
	end

	configurePhysicalParts(clone)
	scaleHolderPart(holderPart, patchInfo, defaultTemplateName)
	configureSurfaceGuis(holderPart, patchInfo)

	local folder = getOrCreateAttachmentFolder(character)
	clone.Parent = folder

	local placement = getPlacementCFrame(targetPart, patchInfo, targetPartName, defaultTemplateName)

	if clone:IsA("Model") then
		clone:PivotTo(placement)
	else
		holderPart.CFrame = placement
	end

	weldHolderToTarget(holderPart, targetPart)

	return clone
end

local function normalizePatchDefinition(value: any, textureLookup: {[any]: any}?, defaults: PatchDefinition?): PatchDefinition?
	if typeof(value) ~= "table" then
		return nil
	end

	local patchInfo: any = {}

	if defaults then
		for key, defaultValue in defaults do
			patchInfo[key] = defaultValue
		end
	end

	for key, patchValue in value do
		patchInfo[key] = patchValue
	end

	if patchInfo.Texture == nil and patchInfo.Image == nil and patchInfo.AssetId == nil then
		local textureKey = value.TextureKey or value.Patch or value.Rank or value.Name

		if textureLookup and textureKey ~= nil then
			local resolvedTexture = textureLookup[textureKey]

			if typeof(resolvedTexture) == "table" then
				patchInfo.Texture = resolvedTexture.Texture or resolvedTexture.Image or resolvedTexture.AssetId
			else
				patchInfo.Texture = resolvedTexture
			end
		end
	end

	return patchInfo :: PatchDefinition
end

local function attachConfiguredPatches(character: Model, patches: any, textureLookup: {[any]: any}?)
	if typeof(patches) ~= "table" then
		return
	end

	for key, patchDefinition in patches do
		local patchInfo = normalizePatchDefinition(patchDefinition, textureLookup, {
			Template = DEFAULT_PATCH_TEMPLATE,
			DepthOffset = DEFAULT_PATCH_DEPTH_OFFSET,
		})

		if patchInfo then
			attachSurfaceGuiTemplate(character, patchInfo, DEFAULT_PATCH_TEMPLATE, `Patch_{tostring(key)}`)
		end
	end
end

local function getPlayerRankForUniform(player: Player?, groupId: any): number
	if not player or not groupId then
		return 0
	end

	local rank = 0

	local success = pcall(function()
		rank = player:GetRankInGroupAsync(groupId)
	end)

	if not success then
		return 0
	end

	return rank
end

local function getRankTabTexture(player: Player?, teamConfig: any, rankTabs: any): any
	if typeof(rankTabs) ~= "table" then
		return rankTabs
	end

	local groupId = rankTabs.GroupId or rankTabs.GroupID or teamConfig.GroupId or teamConfig.GroupID
	local rank = getPlayerRankForUniform(player, groupId)

	return rankTabs[rank]
		or rankTabs[tostring(rank)]
		or rankTabs.Default
		or rankTabs.Texture
		or rankTabs.Image
		or rankTabs.AssetId
end

local function attachConfiguredRankTabs(character: Model, teamConfig: any, rankTabs: any, textureLookup: {[any]: any}?, player: Player?)
	if rankTabs == nil then
		return
	end

	local rankTabDefaults: PatchDefinition = {
		Template = teamConfig.RankTabTemplate or DEFAULT_RANK_TAB_TEMPLATE,
		Target = teamConfig.RankTabTarget,
		Offset = teamConfig.RankTabOffset,
		Rotation = teamConfig.RankTabRotation,
		Scale = teamConfig.RankTabScale,
		CFrameOffset = teamConfig.RankTabCFrameOffset,
		SurfaceWidth = teamConfig.RankTabSurfaceWidth,
		SurfaceHeight = teamConfig.RankTabSurfaceHeight,
		DepthOffset = teamConfig.RankTabDepthOffset or DEFAULT_RANK_TAB_DEPTH_OFFSET,
		FlipOutward = teamConfig.RankTabFlipOutward,
	}

	if typeof(rankTabs) ~= "table" or rankTabs.GroupId or rankTabs.GroupID or rankTabs.Default or rankTabs.Texture or rankTabs.Image or rankTabs.AssetId then
		local rankTabTexture = getRankTabTexture(player, teamConfig, rankTabs)

		if rankTabTexture then
			local rankTabInfo: any = {}

			for key, defaultValue in rankTabDefaults do
				rankTabInfo[key] = defaultValue
			end

			rankTabInfo.Texture = rankTabTexture

			attachSurfaceGuiTemplate(character, rankTabInfo, DEFAULT_RANK_TAB_TEMPLATE, "RankTab")
		end

		return
	end

	for key, rankTabDefinition in rankTabs do
		if key ~= "GroupId" and key ~= "GroupID" and key ~= "Default" then
			local rankTabInfo: any = nil

			if typeof(rankTabDefinition) == "table" then
				rankTabInfo = normalizePatchDefinition(rankTabDefinition, textureLookup, rankTabDefaults)
			elseif rankTabDefinition ~= nil then
				rankTabInfo = {}

				for defaultKey, defaultValue in rankTabDefaults do
					rankTabInfo[defaultKey] = defaultValue
				end

				rankTabInfo.Texture = rankTabDefinition
			end

			if rankTabInfo then
				attachSurfaceGuiTemplate(character, rankTabInfo, DEFAULT_RANK_TAB_TEMPLATE, `RankTab_{tostring(key)}`)
			end
		end
	end
end

local function resolveTeamConfig(player: Player, requestedTeam: any?): any?
	local teams = UniformConfig.Teams or UniformConfig.TeamConfigs or UniformConfig.Uniforms

	if typeof(teams) ~= "table" then
		return nil
	end

	if requestedTeam ~= nil and teams[requestedTeam] then
		return teams[requestedTeam]
	end

	if player.Team and teams[player.Team.Name] then
		return teams[player.Team.Name]
	end

	if player.TeamColor and teams[player.TeamColor.Name] then
		return teams[player.TeamColor.Name]
	end

	return nil
end

local function resolveRankMapValue(rankMap: any, rank: number): any
	if typeof(rankMap) ~= "table" then
		return nil
	end

	return rankMap[rank] or rankMap[tostring(rank)]
end

local function shallowCopy(source: any): any
	local copy = {}

	if typeof(source) ~= "table" then
		return copy
	end

	for key, value in source do
		copy[key] = value
	end

	return copy
end

local function variantMatchesPlayer(player: Player, variant: any): boolean
	if typeof(variant) ~= "table" then
		return false
	end

	local groupId = variant.GroupId or variant.GroupID

	if not groupId then
		return false
	end

	local rank = getPlayerRankForUniform(player, groupId)

	if rank <= 0 and variant.AllowNonMember ~= true then
		return false
	end

	local minimumRank = tonumber(variant.MinimumRank or variant.MinRank)
	local maximumRank = tonumber(variant.MaximumRank or variant.MaxRank)

	if minimumRank and rank < minimumRank then
		return false
	end

	if maximumRank and rank > maximumRank then
		return false
	end

	local allowedRanks = variant.AllowedRanks

	if typeof(allowedRanks) == "table" then
		local isAllowed = allowedRanks[rank] == true
			or allowedRanks[tostring(rank)] == true
			or table.find(allowedRanks, rank) ~= nil
			or table.find(allowedRanks, tostring(rank)) ~= nil

		if not isAllowed then
			return false
		end
	end

	-- When a variant supplies a RankMap, only ranks represented by that map
	-- select the variant unless AllowUnmappedRanks is explicitly enabled.
	-- This keeps the A.I.G. command variant limited to ranks 8 and 9, while
	-- task-force variants remain limited to their configured ranks 1 through 4.
	if typeof(variant.RankMap) == "table"
		and variant.AllowUnmappedRanks ~= true
		and resolveRankMapValue(variant.RankMap, rank) == nil
	then
		return false
	end

	return true
end

local function resolveActiveTeamConfig(player: Player, baseTeamConfig: any): any
	if typeof(baseTeamConfig) ~= "table" then
		return baseTeamConfig
	end

	local variants = baseTeamConfig.Variants

	if typeof(variants) ~= "table" then
		return baseTeamConfig
	end

	for _, variant in variants do
		if variantMatchesPlayer(player, variant) then
			local resolvedConfig = shallowCopy(baseTeamConfig)

			for key, value in variant do
				resolvedConfig[key] = value
			end

			resolvedConfig.Variants = nil
			resolvedConfig.ActiveVariantName = variant.Name

			return resolvedConfig
		end
	end

	return baseTeamConfig
end

local function resolveMorphName(player: Player, teamConfig: any): string?
	if typeof(teamConfig) ~= "table" then
		return nil
	end

	local explicitMorph = teamConfig.Morph or teamConfig.MorphName

	if explicitMorph then
		return tostring(explicitMorph)
	end

	local groupId = teamConfig.GroupId or teamConfig.GroupID

	if groupId then
		local rank = 0

		pcall(function()
			rank = player:GetRankInGroupAsync(groupId)
		end)

		local mappedRank = resolveRankMapValue(teamConfig.RankMap, rank)

		if typeof(mappedRank) == "table" then
			local mappedMorph = mappedRank.Morph or mappedRank.MorphName or mappedRank.Name or mappedRank.Folder

			if mappedMorph then
				return tostring(mappedMorph)
			end
		elseif mappedRank then
			return tostring(mappedRank)
		end
	end

	if teamConfig.Fallback then
		return tostring(teamConfig.Fallback)
	end

	return nil
end

local function resolveMorphModel(player: Player, teamConfig: any): Instance?
	if typeof(teamConfig) ~= "table" then
		return nil
	end

	local folderName = teamConfig.Folder or teamConfig.MorphFolder

	if not folderName then
		return nil
	end

	local teamMorphFolder = MorphsFolder:FindFirstChild(tostring(folderName))

	if not teamMorphFolder then
		warn(`USARF UniformService: morph folder {tostring(folderName)} was not found`)
		return nil
	end

	local morphName = resolveMorphName(player, teamConfig)

	if not morphName then
		warn(`USARF UniformService: no morph name could be resolved for {player.Name}`)
		return nil
	end

	local rankFolderOrModel = teamMorphFolder:FindFirstChild(morphName)

	if not rankFolderOrModel then
		warn(`USARF UniformService: morph {tostring(folderName)}/{morphName} was not found`)
		return nil
	end

	return rankFolderOrModel
end

local function stripNumberSuffix(name: string): string
	return string.gsub(name, "%d+$", "")
end

local function getConfiguredTargetName(morphPiece: Instance): string?
	local attributeTarget = morphPiece:GetAttribute("Target")
		or morphPiece:GetAttribute("TargetPart")
		or morphPiece:GetAttribute("BodyPart")

	if typeof(attributeTarget) == "string" and attributeTarget ~= "" then
		return attributeTarget
	end

	local targetValue = morphPiece:FindFirstChild("Target")
		or morphPiece:FindFirstChild("TargetPart")
		or morphPiece:FindFirstChild("BodyPart")

	if targetValue and targetValue:IsA("StringValue") and targetValue.Value ~= "" then
		return targetValue.Value
	end

	return nil
end

local function inferBodyPartName(morphPieceName: string): string?
	local strippedName = stripNumberSuffix(morphPieceName)
	return BODY_PART_ALIASES[morphPieceName] or BODY_PART_ALIASES[strippedName]
end

local function resolveBodyPart(character: Model, morphPiece: Instance): BasePart?
	local configuredTarget = getConfiguredTargetName(morphPiece)
	local targetName = configuredTarget or inferBodyPartName(morphPiece.Name)

	if targetName then
		local target = character:FindFirstChild(targetName)

		if target and target:IsA("BasePart") then
			return target
		end
	end

	return nil
end

local function setModelPartsForMorph(morphItem: Instance)
	for _, descendant in morphItem:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			descendant.CastShadow = false

			if descendant.Name == "Middle" then
				descendant.Transparency = 1
			end
		end
	end
end

local function weldMorphModelToBodyPart(morphItem: Instance, targetPart: BasePart)
	local holderPart = getHolderPart(morphItem)

	if not holderPart then
		return
	end

	setModelPartsForMorph(morphItem)

	if morphItem:IsA("Model") then
		morphItem:PivotTo(targetPart.CFrame)
	else
		holderPart.CFrame = targetPart.CFrame
	end

	for _, part in morphItem:GetDescendants() do
		if part:IsA("BasePart") and part ~= holderPart then
			local internalWeld = Instance.new("WeldConstraint")
			internalWeld.Name = "USARFMorphInternalWeld"
			internalWeld.Part0 = holderPart
			internalWeld.Part1 = part
			internalWeld.Parent = part
		end
	end

	local bodyWeld = Instance.new("WeldConstraint")
	bodyWeld.Name = "USARFMorphBodyWeld"
	bodyWeld.Part0 = targetPart
	bodyWeld.Part1 = holderPart
	bodyWeld.Parent = holderPart
end

local function applyMorphPiece(character: Model, humanoid: Humanoid, morphPiece: Instance)
	if morphPiece.Name == "Clothing" then
		return
	end

	if morphPiece:IsA("Humanoid") then
		return
	end

	local clone = morphPiece:Clone()
	markMorphItem(clone)

	if clone:IsA("Accessory") then
		humanoid:AddAccessory(clone)
		return
	end

	local targetPart = resolveBodyPart(character, clone)
	clone.Parent = character

	if targetPart then
		weldMorphModelToBodyPart(clone, targetPart)
	else
		setModelPartsForMorph(clone)
	end
end

local function getMorphPartsContainer(rankFolderOrModel: Instance): Instance
	local nestedMorph = rankFolderOrModel:FindFirstChild("Morph")

	if nestedMorph then
		return nestedMorph
	end

	return rankFolderOrModel
end

local function applyMorphItems(character: Model, humanoid: Humanoid, rankFolderOrModel: Instance)
	local morphPartsContainer = getMorphPartsContainer(rankFolderOrModel)

	for _, child in morphPartsContainer:GetChildren() do
		if child.Name ~= "Clothing" then
			applyMorphPiece(character, humanoid, child)
		end
	end
end

local function getHumanoid(character: Model): Humanoid?
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		return humanoid
	end

	local waited = character:WaitForChild("Humanoid", 10)

	if waited and waited:IsA("Humanoid") then
		return waited
	end

	return nil
end

local function getOriginalDescription(player: Player): HumanoidDescription?
	local cached = originalDescriptions[player]

	if cached then
		return cached:Clone()
	end

	local description: HumanoidDescription? = nil
	local success, result = pcall(function()
		return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
	end)

	if success and result and result:IsA("HumanoidDescription") then
		description = result
		originalDescriptions[player] = result:Clone()
	else
		warn(`USARF UniformService: could not load original avatar description for {player.Name}`)
	end

	return if description then description:Clone() else nil
end

local function restoreOriginalAppearance(player: Player, character: Model): boolean
	local humanoid = getHumanoid(character)

	if not humanoid then
		return false
	end

	clearAttachmentFolder(character)
	removeOldMorphItems(character)

	local description = getOriginalDescription(player)

	if not description then
		character:SetAttribute("USARFUniformApplied", nil)
		character:SetAttribute("USARFUniformMorph", nil)
		character:SetAttribute("USARFUniformVariant", nil)
		return false
	end

	local success, errorMessage = pcall(function()
		humanoid:ApplyDescriptionResetAsync(description)
	end)

	if not success then
		success, errorMessage = pcall(function()
			humanoid:ApplyDescriptionAsync(description)
		end)
	end

	description:Destroy()

	if not success then
		warn(`USARF UniformService: failed to restore original avatar for {player.Name}: {tostring(errorMessage)}`)
		return false
	end

	character:SetAttribute("USARFUniformApplied", nil)
	character:SetAttribute("USARFUniformMorph", nil)
	character:SetAttribute("USARFUniformVariant", nil)
	AvatarBlacklistService.FilterCharacter(character)

	return true
end

function UniformService.ClearUniformAttachments(character: Model)
	clearAttachmentFolder(character)
end

function UniformService.ClearMorph(character: Model)
	clearAttachmentFolder(character)
	removeOldMorphItems(character)
	character:SetAttribute("USARFUniformApplied", nil)
	character:SetAttribute("USARFUniformMorph", nil)
	character:SetAttribute("USARFUniformVariant", nil)
end

function UniformService.ClearPlayerUniform(player: Player, restoreAvatar: boolean?)
	local character = player.Character

	if not character then
		return
	end

	if restoreAvatar == false then
		UniformService.ClearMorph(character)
		return
	end

	restoreOriginalAppearance(player, character)
end

function UniformService.AttachPatch(character: Model, patchInfo: PatchDefinition, attachmentName: string?): Instance?
	return attachSurfaceGuiTemplate(character, patchInfo, DEFAULT_PATCH_TEMPLATE, attachmentName or "Patch")
end

function UniformService.AttachRankTab(character: Model, rankTabInfo: PatchDefinition, attachmentName: string?): Instance?
	return attachSurfaceGuiTemplate(character, rankTabInfo, DEFAULT_RANK_TAB_TEMPLATE, attachmentName or "RankTab")
end

function UniformService.ApplyUniform(player: Player, requestedTeam: any?)
	local character = player.Character

	if not character then
		return
	end

	-- Restore the player's canonical Roblox avatar before deciding whether the
	-- newly selected team needs a uniform. This gives unconfigured teams, such
	-- as Test Subject, their original clothing and accessories back.
	restoreOriginalAppearance(player, character)

	local teamConfig = resolveTeamConfig(player, requestedTeam)

	if not teamConfig then
		return
	end

	local humanoid = getHumanoid(character)

	if not humanoid then
		warn(`USARF UniformService: could not apply uniform to {player.Name}; Humanoid missing`)
		return
	end

	teamConfig = resolveActiveTeamConfig(player, teamConfig)

	local morphModel = resolveMorphModel(player, teamConfig)

	if not morphModel then
		return
	end

	if configValue(teamConfig, "RemoveExistingClothing", true) then
		removeExistingClothing(character)
	end

	if configValue(teamConfig, "RemoveAvatarAccessories", true) then
		removeAvatarAccessories(character)
	end

	applyClothing(character, morphModel, teamConfig)
	applyMorphItems(character, humanoid, morphModel)

	local textures = UniformConfig.Textures or {}

	attachConfiguredPatches(character, teamConfig.Patches, textures.Patches)
	attachConfiguredRankTabs(character, teamConfig, teamConfig.RankTabs, textures.RankTabs, player)

	character:SetAttribute("USARFUniformApplied", true)
	character:SetAttribute("USARFUniformMorph", morphModel.Name)
	character:SetAttribute("USARFUniformVariant", teamConfig.ActiveVariantName)
	AvatarBlacklistService.FilterCharacter(character)
end

function UniformService.ApplyUniformToCharacter(character: Model, teamConfig: any)
	local humanoid = getHumanoid(character)

	if not humanoid then
		warn(`USARF UniformService: could not apply uniform to {character.Name}; Humanoid missing`)
		return
	end

	local morphModel: Instance? = nil

	if typeof(teamConfig) == "table" and typeof(teamConfig.MorphModel) == "Instance" then
		if teamConfig.MorphModel:IsA("Model") or teamConfig.MorphModel:IsA("Folder") then
			morphModel = teamConfig.MorphModel
		end
	end

	UniformService.ClearMorph(character)

	if configValue(teamConfig, "RemoveExistingClothing", true) then
		removeExistingClothing(character)
	end

	if configValue(teamConfig, "RemoveAvatarAccessories", true) then
		removeAvatarAccessories(character)
	end

	if morphModel then
		applyClothing(character, morphModel, teamConfig)
		applyMorphItems(character, humanoid, morphModel)
		character:SetAttribute("USARFUniformMorph", morphModel.Name)
	elseif typeof(teamConfig) == "table" and teamConfig.Clothing then
		local emptyMorphSource = Instance.new("Folder")
		applyClothing(character, emptyMorphSource, teamConfig)
		emptyMorphSource:Destroy()
	end

	local textures = UniformConfig.Textures or {}

	attachConfiguredPatches(character, teamConfig.Patches, textures.Patches)
	attachConfiguredRankTabs(character, teamConfig, teamConfig.RankTabs, textures.RankTabs, nil)

	character:SetAttribute("USARFUniformApplied", true)
	AvatarBlacklistService.FilterCharacter(character)
end

local function invalidatePendingApply(player: Player): number
	local nextGeneration = (applyGenerations[player] or 0) + 1
	applyGenerations[player] = nextGeneration
	return nextGeneration
end

local function applyUniformDeferred(player: Player)
	local generation = invalidatePendingApply(player)

	task.defer(function()
		task.wait(APPLY_DELAY_SECONDS)

		if player.Parent ~= Players then
			return
		end

		if applyGenerations[player] ~= generation then
			return
		end

		if not player.Character then
			return
		end

		UniformService.ApplyUniform(player)
	end)
end

local function handleTeamChanged(player: Player)
	-- Cancel any delayed application from the previous team and immediately
	-- clear the old morph before the menu or spawn system does anything else.
	invalidatePendingApply(player)
	UniformService.ClearPlayerUniform(player)

	local teamConfig = resolveTeamConfig(player, nil)

	if teamConfig and configValue(teamConfig, "ApplyOnTeamChange", true) then
		applyUniformDeferred(player)
	end
end

local function disconnectPlayerConnections(player: Player)
	local existingConnections = playerConnections[player]

	if not existingConnections then
		return
	end

	for _, connection in existingConnections do
		connection:Disconnect()
	end

	playerConnections[player] = nil
end

local function connectPlayer(player: Player)
	disconnectPlayerConnections(player)

	local newConnections: {RBXScriptConnection} = {}

	table.insert(newConnections, player.CharacterAdded:Connect(function(character)
		invalidatePendingApply(player)
		UniformService.ClearMorph(character)

		local teamConfig = resolveTeamConfig(player, nil)

		if teamConfig and configValue(teamConfig, "ApplyOnSpawn", true) then
			applyUniformDeferred(player)
		end
	end))

	table.insert(newConnections, player:GetPropertyChangedSignal("Team"):Connect(function()
		handleTeamChanged(player)
	end))

	table.insert(newConnections, player:GetPropertyChangedSignal("TeamColor"):Connect(function()
		handleTeamChanged(player)
	end))

	playerConnections[player] = newConnections

	local teamConfig = resolveTeamConfig(player, nil)

	if teamConfig and configValue(teamConfig, "ApplyOnSpawn", true) and player.Character then
		applyUniformDeferred(player)
	elseif player.Character then
		UniformService.ClearPlayerUniform(player)
	end
end

function UniformService.Start()
	if started then
		return
	end

	started = true

	appendConnection(Players.PlayerAdded:Connect(connectPlayer))

	appendConnection(Players.PlayerRemoving:Connect(function(player)
		invalidatePendingApply(player)
		disconnectPlayerConnections(player)
		UniformService.ClearPlayerUniform(player, false)
		originalDescriptions[player] = nil
		applyGenerations[player] = nil
	end))

	for _, player in Players:GetPlayers() do
		connectPlayer(player)
	end

	print("[USARF] UniformService initialized")
end

function UniformService.Stop()
	for _, connection in connections do
		connection:Disconnect()
	end

	connections = {}

	for player in playerConnections do
		invalidatePendingApply(player)
		disconnectPlayerConnections(player)
	end

	applyGenerations = {}
	originalDescriptions = {}
	started = false
end

return UniformService