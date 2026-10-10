-- selene: allow(mixed_table)
-- small layout helpers shared by the tool panels.
const vide = require("../vide")
const Theme = require("../Theme")

const new = vide.create

const Layout = {}

-- a vertical stack that fills its parent, with panel padding.
function Layout.column(children: { any }): Frame
	return new("Frame")({
		Name = "Column",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		new("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
		new("UIPadding")({
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 10),
		}),
		children,
	}) :: Frame
end

-- a labeled row: a muted caption on the left, controls filling the rest.
function Layout.row(label: string, layoutOrder: number, children: { any }, height: number?, labelWidth: number?): Frame
	const width = labelWidth or 64
	return new("Frame")({
		Name = label,
		Size = UDim2.new(1, 0, 0, height or Theme.CONTROL_HEIGHT),
		LayoutOrder = layoutOrder,
		BackgroundTransparency = 1,
		new("TextLabel")({
			Name = "Label",
			Size = UDim2.fromOffset(width, Theme.CONTROL_HEIGHT),
			BackgroundTransparency = 1,
			Text = label,
			TextColor3 = Theme.MUTED,
			FontFace = Theme.FONT,
			TextSize = Theme.TEXT_LABEL,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		new("Frame")({
			Name = "Controls",
			Position = UDim2.fromOffset(width, 0),
			Size = UDim2.new(1, -width, 1, 0),
			BackgroundTransparency = 1,
			children,
		}),
	}) :: Frame
end

-- a horizontal row of equally wide children.
function Layout.flex(layoutOrder: number, children: { any }, height: number?): Frame
	return new("Frame")({
		Name = "Flex",
		Size = UDim2.new(1, 0, 0, height or Theme.CONTROL_HEIGHT),
		LayoutOrder = layoutOrder,
		BackgroundTransparency = 1,
		new("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			Padding = UDim.new(0, 6),
		}),
		children,
	}) :: Frame
end

-- a line of muted text, for hints and status.
function Layout.note(text: string | () -> string, layoutOrder: number, height: number?, position: UDim2?): TextLabel
	return new("TextLabel")({
		Name = "Note",
		Size = UDim2.new(1, 0, 0, height or 16),
		Position = position,
		LayoutOrder = layoutOrder,
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Theme.SUBTLE,
		FontFace = Theme.FONT,
		TextSize = Theme.TEXT_SMALL,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}) :: TextLabel
end

return Layout
