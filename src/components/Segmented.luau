-- selene: allow(mixed_table)
-- a row of mutually exclusive options.
const vide = require("../vide")
const Theme = require("../Theme")

const new = vide.create

export type Props = {
	options: { string },
	labels: { string }?,
	value: vide.Source<string>,
	size: UDim2?,
	layoutOrder: number?,
	name: string?,
}

const function Segmented(props: Props): Frame
	-- classic is Photon's: flat options split by 1px lines, the selected one blue. modern sits
	-- rounded options inside an inset track.
	const classic = Theme.STYLE == "Classic"
	const inset = if classic then 0 else 2
	const children: { any } = {
		new("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalFlex = Enum.UIFlexAlignment.Fill,
			Padding = UDim.new(0, if classic then 1 else 2),
		}),
		new("UIPadding")({
			PaddingLeft = UDim.new(0, inset),
			PaddingRight = UDim.new(0, inset),
			PaddingTop = UDim.new(0, inset),
			PaddingBottom = UDim.new(0, inset),
		}),
		Theme.corner(Theme.CONTROL_RADIUS),
		if classic then Theme.stroke(Theme.BORDER) else nil,
	}
	for index, option in props.options do
		const hovered = vide.source(false)
		const selected = function()
			return props.value() == option
		end
		table.insert(
			children,
			new("TextButton")({
				Name = option,
				Size = UDim2.fromScale(0, 1),
				LayoutOrder = index,
				BackgroundColor3 = function()
					if selected() then
						return Theme.ACTIVE
					end
					return if classic then (if hovered() then Theme.SURFACE_HOVER else Theme.SURFACE) else Theme.ACTIVE
				end,
				BackgroundTransparency = function()
					return if selected() or classic then 0 elseif hovered() then 0.6 else 1
				end,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Text = if props.labels then props.labels[index] else option,
				TextColor3 = function()
					return if selected() then Theme.TEXT else Theme.MUTED
				end,
				FontFace = Theme.FONT_BUTTON,
				TextSize = Theme.TEXT_LABEL,
				MouseEnter = function()
					hovered(true)
				end,
				MouseLeave = function()
					hovered(false)
				end,
				Activated = function()
					props.value(option)
				end,
				Theme.corner(if classic then 0 else 4),
			})
		)
	end
	return new("Frame")({
		Name = props.name or "Segmented",
		Size = props.size or UDim2.new(1, 0, 0, Theme.CONTROL_HEIGHT),
		LayoutOrder = props.layoutOrder or 0,
		BackgroundColor3 = if classic then Theme.BORDER else Theme.INPUT,
		BorderSizePixel = 0,
		ClipsDescendants = classic,
		children,
	}) :: Frame
end

return Segmented
