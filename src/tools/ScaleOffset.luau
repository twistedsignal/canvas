-- selene: allow(mixed_table)
-- converts Position and Size between Scale and Offset without moving anything.
const vide = require("../vide")
const Icons = require("../Icons")
const Convert = require("../Convert")
const Undo = require("../Undo")
const Watch = require("../Watch")
const Tool = require("../Tool")
const Button = require("../components/Button")
const Segmented = require("../components/Segmented")
const Layout = require("../components/Layout")

const source = vide.source

-- the parent's content box in the object's own (unscaled) pixels: its AbsoluteSize, minus
-- UIPadding, divided by any UIScale above it.
const function parentSize(object: GuiObject): Vector2?
	const parent = object.Parent
	if not parent or not parent:IsA("GuiBase2d") then
		return nil
	end
	local scale = 1
	local ancestor: Instance? = parent
	while ancestor and ancestor:IsA("GuiBase2d") do
		const uiScale = ancestor:FindFirstChildWhichIsA("UIScale")
		if uiScale then
			scale *= uiScale.Scale
		end
		ancestor = ancestor.Parent
	end
	local size = parent.AbsoluteSize / math.max(scale, 1e-6)
	const padding = parent:FindFirstChildWhichIsA("UIPadding")
	if padding then
		size -= Vector2.new(
			padding.PaddingLeft.Scale * size.X + padding.PaddingLeft.Offset + padding.PaddingRight.Scale * size.X + padding.PaddingRight.Offset,
			padding.PaddingTop.Scale * size.Y + padding.PaddingTop.Offset + padding.PaddingBottom.Scale * size.Y + padding.PaddingBottom.Offset
		)
	end
	return size
end

const function number(value: number): string
	return string.format("%.4g", value)
end

const function format(value: UDim2): string
	return `\{{number(value.X.Scale)}, {value.X.Offset}}, \{{number(value.Y.Scale)}, {value.Y.Offset}}`
end

const function ScaleOffset(context: Tool.Context): GuiObject
	const property = source("both")
	const axis = source("xy")
	const first = function(): GuiObject?
		return context.selection.objects()[1]
	end
	const version = Watch(first)

	const function convert(mode: Convert.Mode)
		const objects = context.selection.objects()
		const x, y = axis() ~= "y", axis() ~= "x"
		const position, size = property() ~= "size", property() ~= "position"
		Undo.record(if mode == "scale" then "To Scale" else "To Offset", function()
			for _, object in objects do
				const parent = parentSize(object)
				if not parent then
					continue
				end
				if position then
					object.Position = Convert.udim2(object.Position, parent, mode, x, y)
				end
				if size then
					object.Size = Convert.udim2(object.Size, parent, mode, x, y)
				end
			end
		end)
	end

	const function describe(label: string, read: (GuiObject) -> UDim2): () -> string
		return function()
			version()
			const object = first()
			return `{label}  {if object then format(read(object)) else "—"}`
		end
	end

	return Layout.column({
		Layout.row("Property", 1, {
			Segmented({
				options = { "both", "position", "size" },
				labels = { "Both", "Position", "Size" },
				value = property,
			}),
		}),
		Layout.row("Axis", 2, {
			Segmented({ options = { "xy", "x", "y" }, labels = { "X & Y", "X", "Y" }, value = axis }),
		}),
		Layout.flex(3, {
			Button({ text = "To Scale", accent = true, activated = function()
				convert("scale")
			end }),
			Button({ text = "To Offset", activated = function()
				convert("offset")
			end }),
		}, 30),
		Layout.note(
			describe("Position", function(object)
				return object.Position
			end),
			4
		),
		Layout.note(
			describe("Size", function(object)
				return object.Size
			end),
			5
		),
		Layout.note(function()
			const count = #context.selection.objects()
			return `{count} object{if count == 1 then "" else "s"} selected · Ctrl+Z to undo`
		end, 6),
	})
end

return {
	id = "scaleOffset",
	label = "Scale ↔ Offset",
	icon = Icons.scaleOffset,
	size = Vector2.new(300, 186),
	panel = ScaleOffset,
} :: Tool.Tool
