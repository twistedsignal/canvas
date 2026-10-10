-- plugin preferences. every setting is one of a few named options, which keeps validation and the
-- Settings panel simple: the panel is built straight from these definitions.
const vide = require("./vide")

const KEY = "CanvasSettings"

export type Definition = {
	key: string,
	label: string,
	description: string,
	options: { string },
	labels: { string }?,
	default: string,
}

const DEFINITIONS: { Definition } = {
	{
		key = "theme",
		label = "Theme",
		description = "Classic follows Photon's look. Modern is a compact floating island.",
		options = { "Classic", "Modern" },
		default = "Classic",
	},
	{
		key = "visibility",
		label = "Show",
		description = "When Canvas appears over the viewport.",
		options = { "selection", "always" },
		labels = { "With UI selected", "Always" },
		default = "selection",
	},
	{
		key = "motion",
		label = "Motion",
		description = "How the window moves, resizes and appears.",
		options = { "bouncy", "smooth", "off" },
		labels = { "Bouncy", "Smooth", "Off" },
		default = "bouncy",
	},
	{
		key = "placement",
		label = "Placement",
		description = "Snap to a corner or edge when you let go, or stay where you drop it.",
		options = { "snap", "free" },
		labels = { "Snap to edges", "Free" },
		default = "snap",
	},
	{
		key = "scale",
		label = "Size",
		description = "Scales the whole window.",
		options = { "90", "100", "110", "125" },
		labels = { "90%", "100%", "110%", "125%" },
		default = "100",
	},
	{
		key = "tooltips",
		label = "Tooltips",
		description = "Show a label when you hover a button.",
		options = { "on", "off" },
		labels = { "On", "Off" },
		default = "on",
	},
	{
		key = "collapse",
		label = "On deselect",
		description = "What happens to an open panel when nothing is selected.",
		options = { "close", "keep" },
		labels = { "Close panel", "Keep open" },
		default = "keep",
	},
	{
		key = "iconSize",
		label = "Icon size",
		description = "Size of icon labels inserted from Builder Icons.",
		options = { "16", "20", "24", "32" },
		default = "24",
	},
}

export type Store = {
	values: { [string]: vide.Source<string> },
	get: (key: string) -> string,
	number: (key: string) -> number,
	reset: () -> (),
}

const Settings = {
	definitions = DEFINITIONS,
}

const function valid(definition: Definition, value: any): boolean
	return type(value) == "string" and table.find(definition.options, value) ~= nil
end

-- loads saved settings. onChange runs after any setting changes, with its key.
function Settings.create(plugin: Plugin, onChange: ((key: string) -> ())?): Store
	const saved = plugin:GetSetting(KEY)
	const sources: { [string]: vide.Source<string> } = {}
	const values: { [string]: vide.Source<string> } = {}

	const function save()
		const data = {}
		for key, current in sources do
			data[key] = current()
		end
		plugin:SetSetting(KEY, data)
	end

	for _, definition in DEFINITIONS do
		const initial = if type(saved) == "table" and valid(definition, saved[definition.key])
			then saved[definition.key]
			else definition.default
		const current = vide.source(initial)
		sources[definition.key] = current
		-- reads like a source; writes validate, save and notify.
		values[definition.key] = function(...: string): string
			if select("#", ...) == 0 then
				return current()
			end
			const value = ...
			if valid(definition, value) and value ~= vide.untrack(current) then
				current(value)
				save()
				if onChange then
					onChange(definition.key)
				end
			end
			return value
		end :: any
	end

	return {
		values = values,
		get = function(key)
			return values[key]()
		end,
		number = function(key)
			return tonumber(values[key]()) or 0
		end,
		reset = function()
			for _, definition in DEFINITIONS do
				values[definition.key](definition.default)
			end
		end,
	}
end

return Settings
