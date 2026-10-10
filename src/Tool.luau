-- what every tool panel gets, and what it declares about itself.
const vide = require("./vide")
const SelectionState = require("./SelectionState")
const Settings = require("./Settings")

export type Style = {
	background: Color3,
	transparency: number,
	corner: UDim?,
	stroke: { color: Color3, thickness: number, transparency: number, mode: Enum.ApplyStrokeMode }?,
	text: { font: Font, color: Color3, size: number }?,
	image: Color3?,
}

export type Context = {
	plugin: Plugin,
	selection: SelectionState.SelectionState,
	settings: Settings.Store,
	-- the style copied in the Color panel. kept here so it survives closing the panel.
	style: vide.Source<Style?>,
	-- moves the window back to its default spot.
	resetPosition: () -> (),
}

export type Tool = {
	id: string,
	label: string,
	icon: string,
	-- the panel's size in pixels, below or above the bar.
	size: Vector2,
	panel: (Context) -> GuiObject,
}

return nil
