-- Names of the morphs available to the `loadout` command.
--
-- Morphs live in ServerStorage, which the client cannot see, so UniformService
-- publishes just their names here. The Cmdr types read this for autocomplete;
-- the server always validates against ServerStorage itself.
--
-- ReplicatedStorage.USARFUniformIndex
-- 	<Division>/Classes/<Class>
-- 	<Division>/SubClasses/<SubClass>

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local INDEX_NAME = "USARFUniformIndex"
local ORDER_ATTRIBUTE = "Order"

local UniformLoadoutIndex = {}

local function getOrderedNames(folder: Instance?): {string}
	if not folder then
		return {}
	end

	local children = folder:GetChildren()

	table.sort(children, function(a, b)
		local orderA = a:GetAttribute(ORDER_ATTRIBUTE) or math.huge
		local orderB = b:GetAttribute(ORDER_ATTRIBUTE) or math.huge

		if orderA ~= orderB then
			return orderA < orderB
		end

		return a.Name < b.Name
	end)

	local names = {}

	for _, child in children do
		table.insert(names, child.Name)
	end

	return names
end

local function makeFolder(name: string, parent: Instance, order: number): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute(ORDER_ATTRIBUTE, order)
	folder.Parent = parent
	return folder
end

-- divisions: ordered list of { Name = string, Classes = {string}, SubClasses = {string} }
function UniformLoadoutIndex.Publish(divisions: {any})
	assert(RunService:IsServer(), "UniformLoadoutIndex.Publish is server-only")

	local existing = ReplicatedStorage:FindFirstChild(INDEX_NAME)
	if existing then
		existing:Destroy()
	end

	local index = Instance.new("Folder")
	index.Name = INDEX_NAME

	for divisionOrder, division in divisions do
		local divisionFolder = makeFolder(division.Name, index, divisionOrder)
		local classesFolder = makeFolder("Classes", divisionFolder, 1)
		local subClassesFolder = makeFolder("SubClasses", divisionFolder, 2)

		for order, className in division.Classes do
			makeFolder(className, classesFolder, order)
		end

		for order, subClassName in division.SubClasses do
			makeFolder(subClassName, subClassesFolder, order)
		end
	end

	index.Parent = ReplicatedStorage
end

local function getDivisionSection(divisionName: string?, sectionName: string): Instance?
	local index = ReplicatedStorage:FindFirstChild(INDEX_NAME)
	local division = if index and divisionName then index:FindFirstChild(divisionName) else nil
	return if division then division:FindFirstChild(sectionName) else nil
end

function UniformLoadoutIndex.GetDivisions(): {string}
	return getOrderedNames(ReplicatedStorage:FindFirstChild(INDEX_NAME))
end

function UniformLoadoutIndex.GetClasses(divisionName: string?): {string}
	return getOrderedNames(getDivisionSection(divisionName, "Classes"))
end

function UniformLoadoutIndex.GetSubClasses(divisionName: string?): {string}
	return getOrderedNames(getDivisionSection(divisionName, "SubClasses"))
end

return UniformLoadoutIndex
