-- selene: allow(mixed_table)
-- quick colors for fills, text, images and strokes, plus copy and paste of a whole style.
const vide = require("../vide")
const Theme = require("../Theme")
const Icons = require("../Icons")
const Undo = require("../Undo")
const Watch = require("../Watch")
const Tool = require("../Tool")
const Button = require("../components/Button")
const Segmented = require("../components/Segmented")
const TextInput = require("../components/TextInput")
const Layout = require("../components/Layout")

const new = vide.create
const source = vide.source

const SWATCHES = {
	{ "ffffff", "e4e4e7", "a1a1aa", "71717a", "52525b", "3f3f46", "27272a", "18181b", "09090b", "000000" },
	{ "ef4444", "f97316", "f59e0b", "eab308", "22c55e", "14b8a6", "0ea5e9", "3b82f6", "8b5cf6", "ec4899" },
}

type Target = "fill" | "content" | "stroke"

const function isText(object: Instance): boolean
	return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
end

const function isImage(object: Instance): boolean
	return object:IsA("ImageLabel") or object:IsA("ImageButton")
end

const function read(object: GuiObject, target: Target): Color3?
	if target == "fill" then
		return object.BackgroundColor3
	elseif target == "content" then
		if isText(object) then
			return (object :: TextLabel).TextColor3
		elseif isImage(object) then
			return (object :: ImageLabel).ImageColor3
		end
		return nil
	end
	const stroke = object:FindFirstChildWhichIsA("UIStroke")
	return if stroke then stroke.Color else nil
end

const function write(object: GuiObject, target: Target, color: Color3)
	if target == "fill" then
		object.BackgroundColor3 = color
		-- a fully transparent fill would hide the change.
		if object.BackgroundTransparency >= 1 then
			object.BackgroundTransparency = 0
		end
	elseif target == "content" then
		if isText(object) then
			(object :: TextLabel).TextColor3 = color
		elseif isImage(object) then
			(object :: ImageLabel).ImageColor3 = color
		end
	else
		local stroke = object:FindFirstChildWhichIsA("UIStroke")
		if not stroke then
			const created = Instance.new("UIStroke")
			created.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			created.Parent = object
			stroke = created
		end
		(stroke :: UIStroke).Color = color
	end
end

const function capture(object: GuiObject): Tool.Style
	const corner = object:FindFirstChildWhichIsA("UICorner")
	const stroke = object:FindFirstChildWhichIsA("UIStroke")
	const style: Tool.Style = {
		background = object.BackgroundColor3,
		transparency = object.BackgroundTransparency,
		corner = if corner then corner.CornerRadius else nil,
		stroke = if stroke
			then {
				color = stroke.Color,
				thickness = stroke.Thickness,
				transparency = stroke.Transparency,
				mode = stroke.ApplyStrokeMode,
			}
			else nil,
	}
	if isText(object) then
		const text = object :: TextLabel
		style.text = { font = text.FontFace, color = text.TextColor3, size = text.TextSize }
	elseif isImage(object) then
		style.image = (object :: ImageLabel).ImageColor3
	end
	return style
end

const function paste(object: GuiObject, style: Tool.Style)
	object.BackgroundColor3 = style.background
	object.BackgroundTransparency = style.transparency
	local corner = object:FindFirstChildWhichIsA("UICorner")
	if style.corner then
		if not corner then
			corner = Instance.new("UICorner")
			corner.Parent = object
		end
		(corner :: UICorner).CornerRadius = style.corner
	elseif corner then
		corner:Destroy()
	end
	local stroke = object:FindFirstChildWhichIsA("UIStroke")
	if style.stroke then
		if not stroke then
			stroke = Instance.new("UIStroke")
			stroke.Parent = object
		end
		const target = stroke :: UIStroke
		target.Color = style.stroke.color
		target.Thickness = style.stroke.thickness
		target.Transparency = style.stroke.transparency
		target.ApplyStrokeMode = style.stroke.mode
	elseif stroke then
		stroke:Destroy()
	end
	if style.text and isText(object) then
		const text = object :: TextLabel
		text.FontFace = style.text.font
		text.TextColor3 = style.text.color
		text.TextSize = style.text.size
	elseif style.image and isImage(object) then
		(object :: ImageLabel).ImageColor3 = style.image
	end
end

const function ColorPanel(context: Tool.Context): GuiObject
	const target = source("fill")
	const objects = context.selection.objects
	const first = function(): GuiObject?
		return objects()[1]
	end
	const version = Watch(first)
	const copiedFrom = source("")

	const current = function(): Color3?
		version()
		const object = first()
		return if object then read(object, target() :: Target) else nil
	end

	const function apply(color: Color3)
		const list = objects()
		const which = target() :: Target
		Undo.record("Set color", function()
			for _, object in list do
				write(object, which, color)
			end
		end)
	end

	const rows = {}
	for rowIndex, row in SWATCHES do
		const cells = {}
		for index, hex in row do
			const color = Color3.fromHex(hex)
			const hovered = source(false)
			table.insert(
				cells,
				new("TextButton")({
					Name = hex,
					LayoutOrder = index,
					Size = UDim2.fromScale(0, 1),
					BackgroundColor3 = color,
					Text = "",
					AutoButtonColor = false,
					MouseEnter = function()
						hovered(true)
					end,
					MouseLeave = function()
						hovered(false)
					end,
					Activated = function()
						apply(color)
					end,
					Theme.corner(5),
					new("UIStroke")({
						Color = function()
							const now = current()
							return if hovered() or (now and now:ToHex() == string.upper(hex))
								then Theme.TEXT
								else Theme.BORDER
						end,
						Thickness = 1,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				})
			)
		end
		table.insert(rows, Layout.flex(rowIndex + 1, cells, 22))
	end

	return Layout.column({
		Layout.row("Apply to", 1, {
			Segmented({
				options = { "fill", "content", "stroke" },
				labels = { "Fill", "Text / Image", "Stroke" },
				value = target,
			}),
		}),
		rows,
		Layout.row("Hex", 4, {
			new("Frame")({
				Name = "Preview",
				Size = UDim2.fromOffset(Theme.CONTROL_HEIGHT, Theme.CONTROL_HEIGHT),
				BackgroundColor3 = function()
					return current() or Theme.INPUT
				end,
				Theme.corner(Theme.CONTROL_RADIUS),
				Theme.stroke(Theme.BORDER),
			}),
			TextInput({
				name = "Hex",
				placeholder = "#ffffff",
				mono = true,
				position = UDim2.fromOffset(Theme.CONTROL_HEIGHT + 6, 0),
				size = UDim2.new(1, -Theme.CONTROL_HEIGHT - 6, 1, 0),
				text = function()
					const color = current()
					return if color then `#{string.lower(color:ToHex())}` else ""
				end,
				commit = function(text)
					const hex = string.gsub(text, "[^%x]", "")
					if #hex == 6 or #hex == 3 then
						const ok, color = pcall(Color3.fromHex, hex)
						if ok then
							apply(color)
						end
					end
				end,
			}),
		}),
		Layout.flex(5, {
			Button({
				text = "Copy style",
				enabled = function()
					return first() ~= nil
				end,
				activated = function()
					const object = first()
					if object then
						context.style(capture(object))
						copiedFrom(object.Name)
					end
				end,
			}),
			Button({
				text = "Paste style",
				enabled = function()
					return context.style() ~= nil and first() ~= nil
				end,
				activated = function()
					const style = context.style()
					const list = objects()
					if style then
						Undo.record("Paste style", function()
							for _, object in list do
								paste(object, style)
							end
						end)
					end
				end,
			}),
		}),
		Layout.note(function()
			if copiedFrom() ~= "" then
				return `Copied fill, corner, stroke and text style from {copiedFrom()}`
			end
			return if context.style() then "A style is ready to paste" else "Copy a style from one object, paste onto others"
		end, 6),
	})
end

return {
	id = "color",
	label = "Color & Style",
	icon = Icons.color,
	size = Vector2.new(300, 194),
	panel = ColorPanel,
} :: Tool.Tool
