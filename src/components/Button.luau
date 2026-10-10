-- selene: allow(mixed_table)
-- a small text button for panels.
const vide = require("../vide")
const Theme = require("../Theme")

const new = vide.create

export type Props = {
	text: string | () -> string,
	activated: () -> (),
	size: UDim2?,
	active: (() -> boolean)?,
	accent: boolean?,
	enabled: (() -> boolean)?,
	layoutOrder: number?,
	name: string?,
}

const function Button(props: Props): TextButton
	const hovered = vide.source(false)
	const active = props.active or function()
		return false
	end
	const enabled = props.enabled or function()
		return true
	end
	return new("TextButton")({
		Name = props.name or (if type(props.text) == "string" then props.text else "Button"),
		Size = props.size or UDim2.new(1, 0, 0, Theme.CONTROL_HEIGHT),
		LayoutOrder = props.layoutOrder or 0,
		BackgroundColor3 = function()
			const base = if props.accent or (active() and Theme.STYLE == "Classic") then Theme.ACCENT
				elseif active() then Theme.ACTIVE
				else Theme.SURFACE
			return if hovered() and enabled() then Theme.hover(base) else base
		end,
		BackgroundTransparency = function()
			return if enabled() then 0 else 0.5
		end,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = props.text,
		TextColor3 = function()
			if active() or props.accent then
				return Theme.TEXT
			end
			-- classic buttons read like Photon's: bright text on a filled button.
			return if not enabled() then Theme.SUBTLE elseif Theme.STYLE == "Classic" then Theme.TEXT else Theme.MUTED
		end,
		FontFace = Theme.FONT_BUTTON,
		TextSize = Theme.TEXT_BODY,
		TextTruncate = Enum.TextTruncate.AtEnd,
		MouseEnter = function()
			hovered(true)
		end,
		MouseLeave = function()
			hovered(false)
		end,
		Activated = function()
			if enabled() then
				props.activated()
			end
		end,

		Theme.corner(Theme.CONTROL_RADIUS),
		new("UIStroke")({
			Color = function()
				return if props.accent or (active() and Theme.STYLE == "Classic") then Theme.ACCENT_BORDER else Theme.BORDER
			end,
			Transparency = Theme.SURFACE_STROKE,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	}) :: TextButton
end

return Button
