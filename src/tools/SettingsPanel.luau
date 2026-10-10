-- selene: allow(mixed_table)
-- plugin preferences, built from Settings.definitions.
const Icons = require("../Icons")
const Settings = require("../Settings")
const Tool = require("../Tool")
const Button = require("../components/Button")
const Segmented = require("../components/Segmented")
const Layout = require("../components/Layout")
const Overlay = require("../Overlay")
const VERSION = require("../Version")

const LABEL_WIDTH = 92

const function SettingsPanel(context: Tool.Context): GuiObject
	const rows = {}
	for index, definition in Settings.definitions do
		const row = Layout.row(definition.label, index, {
			Segmented({
				name = definition.key,
				options = definition.options,
				labels = definition.labels,
				value = context.settings.values[definition.key],
			}),
		}, nil, LABEL_WIDTH)
		Overlay.tooltip(row:FindFirstChild("Label") :: GuiObject, definition.description)
		table.insert(rows, row)
	end
	const count = #Settings.definitions
	return Layout.column({
		rows,
		Layout.flex(count + 1, {
			Button({
				text = "Reset position",
				activated = function()
					context.plugin:SetSetting("CanvasFree", nil)
					context.plugin:SetSetting("CanvasSlot", nil)
					context.resetPosition()
				end,
			}),
			Button({ text = "Reset settings", activated = context.settings.reset }),
		}),
		Layout.note(`Canvas v{VERSION} · hover a setting's name for details`, count + 2),
	})
end

return {
	id = "settings",
	label = "Settings",
	icon = Icons.settings,
	size = Vector2.new(400, 4 + 8 * 26 + 9 * 8 + 26 + 16 + 10),
	panel = SettingsPanel,
} :: Tool.Tool
