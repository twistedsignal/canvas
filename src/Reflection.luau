-- what Studio knows about classes: which ones can be created, what they inherit from, which
-- properties hold their data, and the icons the Explorer shows for them.
const ReflectionService = game:GetService("ReflectionService")
const StudioService = game:GetService("StudioService")
const ClassSearch = require("./ClassSearch")

export type Icon = { Image: string, ImageRectOffset: Vector2, ImageRectSize: Vector2 }

const Reflection = {}

local classList: { ClassSearch.Class }? = nil
const superclasses: { [string]: string? } = {}
const properties: { [string]: { string } } = {}
const icons: { [string]: Icon } = {}

-- every class Instance.new can make, minus deprecated ones, with its ancestry.
function Reflection.classes(): { ClassSearch.Class }
	if classList then
		return classList
	end
	const all = ReflectionService:GetClasses()
	const creatable = {}
	for _, info in all do
		superclasses[info.Name] = info.Superclass
	end
	for _, info in all do
		const permits = info.Permits
		const deprecated = info.Display and info.Display.DeprecationMessage
		if permits and permits.New ~= nil and not deprecated then
			table.insert(creatable, { name = info.Name, ancestry = Reflection.ancestry(info.Name) })
		end
	end
	table.sort(creatable, function(a, b)
		return a.name < b.name
	end)
	classList = creatable
	return creatable
end

function Reflection.ancestry(className: string): { string }
	if next(superclasses) == nil then
		Reflection.classes()
	end
	const chain = {}
	local current: string? = className
	while current do
		table.insert(chain, current)
		current = superclasses[current]
	end
	return chain
end

function Reflection.isCreatable(className: string): boolean
	for _, class in Reflection.classes() do
		if class.name == className then
			return true
		end
	end
	return false
end

-- the properties that carry an instance's data: writable, saved with the place and not
-- deprecated. skips Parent, which reclassing handles itself.
function Reflection.properties(className: string): { string }
	const cached = properties[className]
	if cached then
		return cached
	end
	const list = {}
	const ok, result = pcall(ReflectionService.GetPropertiesOfClass, ReflectionService, className)
	if ok then
		for _, property in result do
			const permits = property.Permits
			const deprecated = property.Display and property.Display.DeprecationMessage
			if
				property.Serialized
				and permits
				and permits.Write ~= nil
				and permits.Read ~= nil
				and not deprecated
				and property.Name ~= "Parent"
			then
				table.insert(list, property.Name)
			end
		end
	end
	properties[className] = list
	return list
end

-- properties that point at other instances (NextSelectionLeft, ObjectValue.Value, Part0, ...),
-- saved or not, for repointing references after a reclass.
const references: { [string]: { string } } = {}
function Reflection.references(className: string): { string }
	const cached = references[className]
	if cached then
		return cached
	end
	const list = {}
	const ok, result = pcall(ReflectionService.GetPropertiesOfClass, ReflectionService, className)
	if ok then
		for _, property in result do
			const permits = property.Permits
			if
				property.Type
				and property.Type.ScriptType == "Instance"
				and permits
				and permits.Write ~= nil
				and permits.Read ~= nil
				and not (property.Display and property.Display.DeprecationMessage)
				and property.Name ~= "Parent"
			then
				table.insert(list, property.Name)
			end
		end
	end
	references[className] = list
	return list
end

-- the Explorer icon for a class.
function Reflection.icon(className: string): Icon
	const cached = icons[className]
	if cached then
		return cached
	end
	const ok, result = pcall(StudioService.GetClassIcon, StudioService, className)
	const icon = if ok and result
		then result :: Icon
		else { Image = "", ImageRectOffset = Vector2.zero, ImageRectSize = Vector2.zero }
	icons[className] = icon
	return icon
end

return Reflection
