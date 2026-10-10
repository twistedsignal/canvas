-- selene: allow(mixed_table)
-- a full-viewport layer over the 3D view that holds the window and its tooltips. it passes
-- clicks through everywhere else.
const vide = require("./vide")
const Theme = require("./Theme")
const Overlay = require("./Overlay")
const SelectionState = require("./SelectionState")
const Settings = require("./Settings")
const Island = require("./Island")
const Tool = require("./Tool")
const tools = require("./tools")

const new = vide.create

export type Props = {
	plugin: Plugin,
	enabled: () -> boolean,
	settings: Settings.Store,
	-- copied styles outlive remounts after a theme change.
	style: vide.Source<Tool.Style?>,
	initialTool: string?,
	onControls: ((Island.Controls) -> ())?,
}

const function App(props: Props): Frame
	const root = new("Frame")({
		Name = "Canvas",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}) :: Frame
	-- vide.mount doesn't destroy what it built, and a theme change remounts.
	vide.cleanup(root)

	const overlay = new("Frame")({
		Name = "Overlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = Theme.OVERLAY_Z,
		Parent = root,
	}) :: Frame
	Overlay.setLayer(overlay)
	Overlay.setTooltips(function()
		return props.settings.get("tooltips") == "on"
	end)
	vide.cleanup(function()
		Overlay.setLayer(nil)
	end)

	const selection = SelectionState.create()
	const context: Tool.Context = {
		plugin = props.plugin,
		selection = selection,
		settings = props.settings,
		style = props.style,
		resetPosition = function() end,
	}

	Island({
		plugin = props.plugin,
		root = root,
		tools = tools,
		context = context,
		initialTool = props.initialTool,
		onControls = props.onControls,
		visible = function()
			return props.enabled() and (props.settings.values.visibility() == "always" or #selection.ui() > 0)
		end,
	}).Parent = root

	return root
end

return App
