-- selene: allow(mixed_table)
-- turn the selection into another class, keeping children and every property that still applies.
const vide = require("../vide")
const Theme = require("../Theme")
const Icons = require("../Icons")
const ClassSearch = require("../ClassSearch")
const Reflection = require("../Reflection")
const Reclass = require("../Reclass")
const Undo = require("../Undo")
const Tool = require("../Tool")
const Button = require("../components/Button")
const TextInput = require("../components/TextInput")
const Layout = require("../components/Layout")

const new = vide.create
const source = vide.source

const ROW_HEIGHT = 24
const VISIBLE_ROWS = 6
const MAX_RESULTS = 40

-- a class's Explorer icon, sized for a row.
const function ClassIcon(className: () -> string?, position: UDim2): ImageLabel
	const icon = function(): Reflection.Icon?
		const name = className()
		return if name then Reflection.icon(name) else nil
	end
	return new("ImageLabel")({
		Name = "ClassIcon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = position,
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = function()
			const current = icon()
			return if current then current.Image else ""
		end,
		ImageRectOffset = function()
			const current = icon()
			return if current then current.ImageRectOffset else Vector2.zero
		end,
		ImageRectSize = function()
			const current = icon()
			return if current then current.ImageRectSize else Vector2.zero
		end,
	}) :: ImageLabel
end

const function ReclassPanel(context: Tool.Context): GuiObject
	const selected = context.selection.all
	const query = source("")
	-- a class picked from the list; typing again goes back to the best match.
	const chosen = source(nil :: string?)
	local box: TextBox? = nil

	-- the class the selection starts as, or nil when it's mixed.
	const fromClass = function(): string?
		const list = selected()
		const first = list[1]
		if not first then
			return nil
		end
		for _, instance in list do
			if instance.ClassName ~= first.ClassName then
				return nil
			end
		end
		return first.ClassName
	end
	const fromAncestry = vide.derive(function(): { string }?
		const list = selected()
		return if list[1] then Reflection.ancestry(list[1].ClassName) else nil
	end)

	const results = vide.derive(function()
		return ClassSearch.rank(Reflection.classes(), query(), fromAncestry(), MAX_RESULTS)
	end)
	const target = function(): string?
		return chosen() or results()[1]
	end

	const preview = vide.derive(function(): Reclass.Preview?
		const from, to = fromClass(), target()
		return if from and to then Reclass.preview(from, to) else nil
	end)

	const function choose(name: string)
		chosen(name)
		query(name)
		if box then
			box.Text = name
		end
	end

	const function reclass()
		const className = target()
		const list = selected()
		if not className or #list == 0 then
			return
		end
		Undo.record(`Reclass to {className}`, function()
			context.selection.set(Reclass.convertAll(list, className))
		end)
	end

	const rows = vide.indexes(results, function(name: () -> string, index: number)
		const hovered = source(false)
		const isTarget = function()
			return target() == name()
		end
		return new("TextButton")({
			Name = `Row{index}`,
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
			LayoutOrder = index,
			BackgroundColor3 = function()
				return if isTarget() then Theme.ACTIVE else Theme.SURFACE_HOVER
			end,
			BackgroundTransparency = function()
				return if isTarget() or hovered() then 0 else 1
			end,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			MouseEnter = function()
				hovered(true)
			end,
			MouseLeave = function()
				hovered(false)
			end,
			Activated = function()
				choose(name())
			end,
			Theme.corner(Theme.CONTROL_RADIUS),
			ClassIcon(name, UDim2.new(0, 6, 0.5, 0)),
			new("TextLabel")({
				Name = "ClassName",
				Position = UDim2.fromOffset(30, 0),
				Size = UDim2.new(1, -110, 1, 0),
				BackgroundTransparency = 1,
				Text = name,
				TextColor3 = function()
					return if isTarget() then Theme.TEXT else Theme.MUTED
				end,
				FontFace = Theme.FONT,
				TextSize = Theme.TEXT_BODY,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			new("TextLabel")({
				Name = "Kept",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -8, 0, 0),
				Size = UDim2.new(0, 80, 1, 0),
				BackgroundTransparency = 1,
				Text = function()
					const from = fromClass()
					if not from then
						return ""
					end
					return `keeps {#Reclass.preview(from, name()).kept}`
				end,
				TextColor3 = function()
					return if isTarget() then Theme.TEXT else Theme.SUBTLE
				end,
				FontFace = Theme.FONT,
				TextSize = Theme.TEXT_SMALL,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
		})
	end)

	return Layout.column({
		Layout.row("From", 1, {
			ClassIcon(fromClass, UDim2.fromScale(0, 0.5)),
			new("TextLabel")({
				Name = "From",
				Position = UDim2.fromOffset(22, 0),
				Size = UDim2.new(1, -22, 1, 0),
				BackgroundTransparency = 1,
				Text = function()
					const list = selected()
					if #list == 0 then
						return "Nothing selected"
					end
					const from = fromClass()
					const count = if #list > 1 then ` ×{#list}` else ""
					return if from then `{from}{count}` else `{#list} objects of mixed classes`
				end,
				TextColor3 = Theme.TEXT,
				FontFace = Theme.FONT,
				TextSize = Theme.TEXT_BODY,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
		}),
		Layout.row("To", 2, {
			new("Frame")({
				Name = "Target",
				Size = UDim2.fromOffset(Theme.CONTROL_HEIGHT, Theme.CONTROL_HEIGHT),
				BackgroundColor3 = Theme.INPUT,
				Theme.corner(Theme.CONTROL_RADIUS),
				Theme.stroke(Theme.BORDER),
				ClassIcon(target, UDim2.new(0.5, -8, 0.5, 0)),
			}),
			TextInput({
				name = "Search",
				placeholder = "Class name · Tab completes · Enter reclasses",
				position = UDim2.fromOffset(Theme.CONTROL_HEIGHT + 6, 0),
				size = UDim2.new(1, -Theme.CONTROL_HEIGHT - 6, 1, 0),
				text = query,
				box = function(instance)
					box = instance
				end,
				changed = function(text)
					if string.find(text, "\t", 1, true) then
						-- Tab completes to the highlighted class.
						const completed = target() or string.gsub(text, "\t", "")
						choose(completed)
						return
					end
					if text ~= chosen() then
						chosen(nil)
					end
					query(text)
				end,
				commit = function(_, enterPressed)
					if enterPressed then
						reclass()
					end
				end,
			}),
		}),
		new("ScrollingFrame")({
			Name = "Suggestions",
			Size = UDim2.new(1, 0, 0, ROW_HEIGHT * VISIBLE_ROWS),
			LayoutOrder = 3,
			BackgroundColor3 = Theme.INPUT,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.SUBTLE,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			Theme.corner(Theme.CONTROL_RADIUS),
			Theme.stroke(Theme.BORDER),
			new("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
			new("UIPadding")({ PaddingRight = UDim.new(0, 6) }),
			rows,
		}),
		Layout.note(function()
			const current = preview()
			if not current then
				return if target() then "Keeps children, attributes, tags and shared properties" else "No class matches"
			end
			return `Keeps {#current.kept} properties, plus children, attributes and tags`
		end, 4),
		Layout.note(function()
			const current = preview()
			if not current or #current.dropped == 0 then
				return ""
			end
			return `Drops {table.concat(current.dropped, ", ")}`
		end, 5),
		Button({
			name = "Reclass",
			text = function()
				const className = target()
				return if className then `Reclass to {className}` else "Reclass"
			end,
			accent = true,
			layoutOrder = 6,
			size = UDim2.new(1, 0, 0, 30),
			enabled = function()
				const className = target()
				if not className then
					return false
				end
				for _, instance in selected() do
					if instance.ClassName ~= className then
						return true
					end
				end
				return false
			end,
			activated = reclass,
		}),
	})
end

return {
	id = "reclass",
	label = "Reclass",
	icon = Icons.reclass,
	size = Vector2.new(360, 4 + 26 + 26 + ROW_HEIGHT * VISIBLE_ROWS + 16 + 16 + 30 + 8 * 5 + 10),
	panel = ReclassPanel,
} :: Tool.Tool
