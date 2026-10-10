-- selene: allow(mixed_table)
-- browse Builder Icons. clicking one adds it to the selected text objects as RichText, so icons
-- and text can mix, or inserts a new icon label into the selection.
const vide = require("../vide")
const Theme = require("../Theme")
const Icons = require("../Icons")
const BuilderIcons = require("../BuilderIcons")
const Undo = require("../Undo")
const Tool = require("../Tool")
const TextInput = require("../components/TextInput")
const Segmented = require("../components/Segmented")
const Layout = require("../components/Layout")

const new = vide.create
const source = vide.source

const SIZE = Vector2.new(352, 362)
const CELL = 36
const GAP = 4
const COLUMNS = 8
const GRID_TOP = 66
const GRID_HEIGHT = 222
-- the font for text around icons in labels Canvas creates or converts.
const TEXT_FONT = Font.new("rbxasset://fonts/families/BuilderSans.json")

const function isText(instance: Instance): boolean
	return instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")
end

-- the icon a text object shows: from its RichText, or from its whole font for labels set up
-- with the icon font directly.
const function iconOf(text: TextLabel): (string?, BuilderIcons.Variant?)
	const whole = BuilderIcons.variantOf(text.FontFace)
	if whole then
		return text.Text, whole
	end
	if text.RichText then
		return BuilderIcons.find(text.Text)
	end
	return nil, nil
end

const function IconsPanel(context: Tool.Context): GuiObject
	const query = source("")
	const variant = source("Regular")
	const placement = source("swap")
	const picked = source("")
	const hovered = source("")
	const results = vide.derive(function()
		return BuilderIcons.search(query())
	end)
	const font = function(): Font
		return BuilderIcons.font(variant() :: BuilderIcons.Variant)
	end

	-- when a different text object is selected, show the icon it already uses. only on a new
	-- target, so it doesn't undo a Regular/Filled choice made since.
	local synced: Instance? = nil
	vide.effect(function()
		local first: TextLabel? = nil
		for _, target in context.selection.ui() do
			if isText(target) then
				first = target :: TextLabel
				break
			end
		end
		if first == synced then
			return
		end
		synced = first
		if not first then
			return
		end
		const name, used = iconOf(first)
		if name and used then
			vide.untrack(function()
				picked(name)
				variant(used)
			end)
		end
	end)

	-- the new RichText for a text object with the icon placed in it.
	const function withIcon(text: TextLabel, markup: string): string
		local current: string
		const whole = BuilderIcons.variantOf(text.FontFace)
		if whole then
			-- the whole label used the icon font; turn its icon into markup and use a text font.
			text.FontFace = TEXT_FONT
			current = BuilderIcons.markup(text.Text, whole)
		elseif text.RichText then
			current = text.Text
		else
			current = BuilderIcons.escape(text.Text)
		end
		return BuilderIcons.place(current, markup, placement() :: BuilderIcons.Placement)
	end

	const function apply(name: string)
		picked(name)
		const targets = context.selection.ui()
		const texts = {}
		for _, target in targets do
			if isText(target) then
				table.insert(texts, target)
			end
		end
		const markup = BuilderIcons.markup(name, variant() :: BuilderIcons.Variant)
		const iconSize = context.settings.number("iconSize")
		if #texts > 0 then
			Undo.record("Add icon", function()
				for _, target in texts do
					const text = target :: TextLabel
					text.Text = withIcon(text, markup)
					text.RichText = true
				end
			end)
			return
		end
		const parent = targets[1]
		if not parent then
			return
		end
		Undo.record("Insert icon", function()
			const label = Instance.new("TextLabel")
			label.Name = name
			label.Size = UDim2.fromOffset(iconSize, iconSize)
			label.BackgroundTransparency = 1
			label.FontFace = TEXT_FONT
			label.RichText = true
			label.Text = markup
			label.TextSize = iconSize
			label.TextColor3 = Color3.new(1, 1, 1)
			label.Parent = parent
			context.selection.set({ label })
		end)
	end

	-- the grid only creates buttons for the rows in view and reuses them while scrolling.
	const scroller = new("ScrollingFrame")({
		Name = "Grid",
		Position = UDim2.fromOffset(0, GRID_TOP),
		Size = UDim2.new(1, 0, 0, GRID_HEIGHT),
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.SUBTLE,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = function()
			const rows = math.ceil(#results() / COLUMNS)
			return UDim2.fromOffset(0, math.max(0, rows * (CELL + GAP) - GAP))
		end,
	}) :: ScrollingFrame

	const pool: { { button: TextButton, name: string? } } = {}
	const visibleRows = math.ceil(GRID_HEIGHT / (CELL + GAP)) + 1
	for index = 1, visibleRows * COLUMNS do
		const slot = { button = nil :: any, name = nil :: string? }
		slot.button = new("TextButton")({
			Name = `Cell{index}`,
			Size = UDim2.fromOffset(CELL, CELL),
			BackgroundColor3 = Theme.SURFACE_HOVER,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			FontFace = font,
			TextSize = 22,
			TextColor3 = Theme.ICON_HOVER,
			Visible = false,
			Parent = scroller,
			MouseEnter = function()
				if slot.name then
					hovered(slot.name)
					slot.button.BackgroundTransparency = 0
				end
			end,
			MouseLeave = function()
				hovered("")
				slot.button.BackgroundTransparency = 1
			end,
			Activated = function()
				if slot.name then
					apply(slot.name)
				end
			end,
			Theme.corner(Theme.CONTROL_RADIUS),
			new("UIStroke")({
				Color = Theme.ACCENT,
				Thickness = 1.5,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Enabled = false,
			}),
		}) :: TextButton
		table.insert(pool, slot)
	end
	-- bumps after every re-layout so the picked outline follows its icon.
	const cellsChanged = source(0)

	const function layout()
		const list = results()
		const firstRow = math.floor(scroller.CanvasPosition.Y / (CELL + GAP))
		for index, slot in pool do
			const at = firstRow * COLUMNS + index
			const name = list[at]
			slot.name = name
			slot.button.Visible = name ~= nil
			if name then
				const row = (at - 1) // COLUMNS
				const column = (at - 1) % COLUMNS
				slot.button.Position = UDim2.fromOffset(column * (CELL + GAP), row * (CELL + GAP))
				slot.button.Text = name
			end
		end
		cellsChanged(cellsChanged() + 1)
	end
	vide.effect(function()
		results()
		vide.untrack(function()
			scroller.CanvasPosition = Vector2.zero
			layout()
		end)
	end)
	vide.cleanup(scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		vide.untrack(layout)
	end))
	-- outline the picked icon.
	vide.effect(function()
		cellsChanged()
		const current = picked()
		for _, slot in pool do
			const stroke = slot.button:FindFirstChildWhichIsA("UIStroke")
			if stroke then
				stroke.Enabled = slot.name ~= nil and slot.name == current
			end
		end
	end)

	const status = function(): string
		const count = #results()
		const targets = context.selection.ui()
		local texts = 0
		for _, target in targets do
			if isText(target) then
				texts += 1
			end
		end
		const action = if texts > 0
			then `Click to add to {texts} text object{if texts == 1 then "" else "s"}`
			else `Click to insert into {if targets[1] then targets[1].Name else "the selection"}`
		return `{count} icon{if count == 1 then "" else "s"} · {action}`
	end

	return Layout.column({
		new("Frame")({
			Name = "Body",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,

			TextInput({
				name = "Search",
				placeholder = "Search icons",
				icon = Icons.search,
				changed = query,
				size = UDim2.new(1, -128, 0, Theme.CONTROL_HEIGHT),
			}),
			new("Frame")({
				Name = "Variant",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromOffset(120, Theme.CONTROL_HEIGHT),
				BackgroundTransparency = 1,
				Segmented({ options = { "Regular", "Filled" }, value = variant }),
			}),
			new("Frame")({
				Name = "Placement",
				Position = UDim2.fromOffset(0, 32),
				Size = UDim2.new(1, 0, 0, Theme.CONTROL_HEIGHT),
				BackgroundTransparency = 1,
				Layout.row("In text", 0, {
					Segmented({
						options = { "swap", "start", "end" },
						labels = { "Swap icon", "Add at start", "Add at end" },
						value = placement,
					}),
				}),
			}),
			scroller,
			TextInput({
				name = "Name",
				placeholder = "Hover or pick an icon to see its name",
				icon = Icons.copy,
				mono = true,
				editable = false,
				position = UDim2.fromOffset(0, GRID_TOP + GRID_HEIGHT + 8),
				text = function()
					const name = hovered()
					return if name ~= "" then name else picked()
				end,
				size = UDim2.new(1, 0, 0, Theme.CONTROL_HEIGHT),
			}),
			Layout.note(status, 0, nil, UDim2.fromOffset(2, GRID_TOP + GRID_HEIGHT + 14 + Theme.CONTROL_HEIGHT)),
		}),
	})
end

return {
	id = "icons",
	label = "Builder Icons",
	icon = Icons.icons,
	size = SIZE,
	panel = IconsPanel,
} :: Tool.Tool
