-- swaps an instance for a new one of another class, keeping everything that still applies:
-- shared properties, attributes, tags, children and its place in the tree.
const Reflection = require("./Reflection")

const Reclass = {}

export type Preview = { kept: { string }, dropped: { string } }

-- which of the source's properties the target class keeps and which it drops.
function Reclass.preview(fromClass: string, toClass: string): Preview
	const target = {}
	for _, name in Reflection.properties(toClass) do
		target[name] = true
	end
	const kept, dropped = {}, {}
	for _, name in Reflection.properties(fromClass) do
		table.insert(if target[name] then kept else dropped, name)
	end
	table.sort(kept)
	table.sort(dropped)
	return { kept = kept, dropped = dropped }
end

-- builds the replacement and puts it where the original was. the original is unparented rather
-- than destroyed, so undo can bring it back.
function Reclass.convert(instance: Instance, className: string): Instance
	const replacement = Instance.new(className)
	for _, name in Reflection.properties(className) do
		-- a property the original doesn't have, or a value the new class won't take, is skipped.
		pcall(function()
			(replacement :: any)[name] = (instance :: any)[name]
		end)
	end
	-- script sources aren't listed with the other properties.
	if instance:IsA("LuaSourceContainer") and replacement:IsA("LuaSourceContainer") then
		pcall(function()
			(replacement :: any).Source = (instance :: any).Source
		end)
	end
	replacement.Name = instance.Name
	replacement.Archivable = instance.Archivable
	for key, value in instance:GetAttributes() do
		replacement:SetAttribute(key, value)
	end
	for _, tag in instance:GetTags() do
		replacement:AddTag(tag)
	end
	for _, child in instance:GetChildren() do
		child.Parent = replacement
	end
	const parent = instance.Parent
	instance.Parent = nil
	replacement.Parent = parent
	return replacement
end

-- the instance's top-level container: its ancestor directly under a service, like a ScreenGui
-- in StarterGui or a model in Workspace.
const function container(instance: Instance): Instance
	local current = instance
	while current.Parent and current.Parent ~= game and current.Parent.Parent ~= game do
		current = current.Parent
	end
	return current
end

-- repoints references to the originals (NextSelection*, ObjectValues, constraint parts, ...)
-- at their replacements, within each replacement's top-level container.
const function repoint(replacements: { [Instance]: Instance })
	const scanned = {}
	for _, replacement in replacements do
		const scope = container(replacement)
		if scanned[scope] then
			continue
		end
		scanned[scope] = true
		const everything = scope:GetDescendants()
		table.insert(everything, scope)
		for _, instance in everything do
			for _, name in Reflection.references(instance.ClassName) do
				pcall(function()
					const value = (instance :: any)[name]
					const swapped = value and replacements[value]
					if swapped then
						(instance :: any)[name] = swapped
					end
				end)
			end
		end
	end
end

-- reclasses several instances, keeping references between and to them. skips any that already
-- are the class. returns the replacements, in order.
function Reclass.convertAll(instances: { Instance }, className: string): { Instance }
	const replacements: { [Instance]: Instance } = {}
	const results = {}
	for _, instance in instances do
		if instance.ClassName == className or not instance.Parent then
			table.insert(results, instance)
			continue
		end
		const replacement = Reclass.convert(instance, className)
		replacements[instance] = replacement
		table.insert(results, replacement)
	end
	if next(replacements) then
		repoint(replacements)
	end
	return results
end

return Reclass
