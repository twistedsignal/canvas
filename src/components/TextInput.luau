-- selene: allow(mixed_table)
-- a single-line text box, optionally with a leading icon.
const vide = require("../vide")
const Theme = require("../Theme")

const new = vide.create

export type Props = {
	placeholder: string?,
	text: (() -> string)?,
	icon: string?,
	-- fires on every keystroke.
	changed: ((text: string) -> ())?,
	-- fires on Enter or when focus leaves.
	commit: ((text: string) -> ())?,
	mono: boolean?,
	editable: boolean?,
	size: UDim2?,
	position: UDim2?,
	layoutOrder: number?,
	name: string?,
}

const function TextInput(props: Props): Frame
	const focused = vide.source(false)
	const inset = if props.icon then 28 else 8
	local box: TextBox
	box = new("TextBox")({
		Name = "Input",
		Position = UDim2.fromOffset(inset, 0),
		Size = UDim2.new(1, -inset - 8, 1, 0),
		BackgroundTransparency = 1,
		Text = if props.text then props.text() else "",
		PlaceholderText = props.placeholder or "",
		PlaceholderColor3 = Theme.SUBTLE,
		TextColor3 = Theme.TEXT,
		FontFace = if props.mono then Theme.FONT_MONO else Theme.FONT,
		TextSize = if props.mono then 13 else Theme.TEXT_BODY,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ClearTextOnFocus = false,
		TextEditable = props.editable ~= false,
		ClipsDescendants = true,
		Focused = function()
			focused(true)
		end,
		FocusLost = function()
			focused(false)
			if props.commit then
				props.commit(box.Text)
			end
		end,
	}) :: TextBox
	if props.changed then
		const changed = props.changed
		vide.cleanup(box:GetPropertyChangedSignal("Text"):Connect(function()
			changed(box.Text)
		end))
	end
	if props.text then
		const text = props.text
		vide.effect(function()
			const value = text()
			if not focused() or props.editable == false then
				box.Text = value
			end
		end)
	end
	return new("Frame")({
		Name = props.name or "TextInput",
		Size = props.size or UDim2.new(1, 0, 0, Theme.CONTROL_HEIGHT),
		Position = props.position,
		LayoutOrder = props.layoutOrder or 0,
		BackgroundColor3 = Theme.INPUT,
		BorderSizePixel = 0,

		Theme.corner(Theme.CONTROL_RADIUS),
		new("UIStroke")({
			Color = function()
				return if focused() then Theme.ACCENT else Theme.BORDER
			end,
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		if props.icon
			then new("ImageLabel")({
				Name = "Icon",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 8, 0.5, 0),
				Size = UDim2.fromOffset(14, 14),
				BackgroundTransparency = 1,
				Image = props.icon,
				ImageColor3 = Theme.MUTED,
			})
			else nil,
		box,
	}) :: Frame
end

return TextInput
