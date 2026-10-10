-- selene: allow(mixed_table)
-- a square button with a Lucide icon: borderless in Modern, a Photon-style tab in Classic.
const vide = require("../vide")
const Theme = require("../Theme")
const Overlay = require("../Overlay")

const new = vide.create

export type Props = {
	icon: string,
	label: string,
	activated: () -> (),
	active: (() -> boolean)?,
	size: number?,
	iconSize: number?,
	layoutOrder: number?,
}

-- Photon's tab button: a bordered square with a blue line under the active one.
const function ClassicIconButton(props: Props, active: () -> boolean): ImageButton
	const size = props.size or Theme.BUTTON_SIZE
	const iconSize = props.iconSize or 20
	const hovered = vide.source(false)
	return new("ImageButton")({
		Name = props.label,
		Size = UDim2.fromOffset(size, size),
		LayoutOrder = props.layoutOrder or 0,
		BackgroundColor3 = function()
			const base = if active() then Theme.SURFACE else Theme.ROW_ALT
			return if hovered() then Theme.hover(base) else base
		end,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Image = "",
		MouseEnter = function()
			hovered(true)
		end,
		MouseLeave = function()
			hovered(false)
		end,
		Activated = function()
			props.activated()
		end,

		Theme.stroke(Theme.BORDER),
		new("ImageLabel")({
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(iconSize, iconSize),
			BackgroundTransparency = 1,
			Image = props.icon,
			ImageColor3 = function()
				return if active() or hovered() then Theme.TEXT else Theme.MUTED
			end,
		}),
		new("Frame")({
			Name = "Indicator",
			Position = UDim2.new(0, 0, 1, -3),
			Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = Theme.ACCENT,
			BorderSizePixel = 0,
			Visible = active,
		}),
	}) :: ImageButton
end

const function IconButton(props: Props): ImageButton
	const active = props.active or function()
		return false
	end
	if Theme.STYLE == "Classic" then
		const button = ClassicIconButton(props, active)
		Overlay.tooltip(button, props.label)
		return button
	end
	const size = props.size or Theme.BUTTON_SIZE
	const iconSize = props.iconSize or 18
	const hovered = vide.source(false)
	const button = new("ImageButton")({
		Name = props.label,
		Size = UDim2.fromOffset(size, size),
		LayoutOrder = props.layoutOrder or 0,
		BackgroundColor3 = function()
			return if active() then Theme.ACTIVE else Theme.SURFACE_HOVER
		end,
		BackgroundTransparency = function()
			return if active() or hovered() then 0 else 1
		end,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Image = "",
		MouseEnter = function()
			hovered(true)
		end,
		MouseLeave = function()
			hovered(false)
		end,
		Activated = function()
			props.activated()
		end,

		Theme.corner(8),
		new("ImageLabel")({
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(iconSize, iconSize),
			BackgroundTransparency = 1,
			Image = props.icon,
			ImageColor3 = function()
				return if active() or hovered() then Theme.ICON_HOVER else Theme.ICON
			end,
		}),
	}) :: ImageButton
	Overlay.tooltip(button, props.label)
	return button
end

return IconButton
