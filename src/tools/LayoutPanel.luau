-- selene: allow(mixed_table)
-- one-click UI components, anchor points that keep objects in place, and common layout moves.
const vide = require("../vide")
const Theme = require("../Theme")
const Icons = require("../Icons")
const Undo = require("../Undo")
const Watch = require("../Watch")
const Tool = require("../Tool")
const Button = require("../components/Button")
const Layout = require("../components/Layout")

const new = vide.create

type Component = { class: string, label: string, setup: (Instance, GuiObject) -> () }

const COMPONENTS: { Component } = {
	{
		class = "UICorner",
		label = "Corner",
		setup = function(instance)
			(instance :: UICorner).CornerRadius = UDim.new(0, 8)
		end,
	},
	{
		class = "UIStroke",
		label = "Stroke",
		setup = function(instance)
			const stroke = instance :: UIStroke
			stroke.Color = Color3.fromRGB(63, 63, 70)
			stroke.Thickness = 1
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		end,
	},
	{
		class = "UIPadding",
		label = "Padding",
		setup = function(instance)
			const padding = instance :: UIPadding
			padding.PaddingLeft = UDim.new(0, 8)
			padding.PaddingRight = UDim.new(0, 8)
			padding.PaddingTop = UDim.new(0, 8)
			padding.PaddingBottom = UDim.new(0, 8)
		end,
	},
	{
		class = "UIListLayout",
		label = "List",
		setup = function(instance)
			const list = instance :: UIListLayout
			list.SortOrder = Enum.SortOrder.LayoutOrder
			list.Padding = UDim.new(0, 8)
		end,
	},
	{
		class = "UIGridLayout",
		label = "Grid",
		setup = function(instance)
			const grid = instance :: UIGridLayout
			grid.SortOrder = Enum.SortOrder.LayoutOrder
			grid.CellSize = UDim2.fromOffset(100, 100)
			grid.CellPadding = UDim2.fromOffset(8, 8)
		end,
	},
	{
		class = "UIAspectRatioConstraint",
		label = "Aspect",
		setup = function(instance, object)
			const size = object.AbsoluteSize
			if size.Y > 0 then
				(instance :: UIAspectRatioConstraint).AspectRatio = math.round(size.X / size.Y * 1000) / 1000
			end
		end,
	},
}

-- moves the anchor without moving the object: shift Position by the anchor change times Size.
const function setAnchor(object: GuiObject, anchor: Vector2)
	const delta = anchor - object.AnchorPoint
	const size = object.Size
	const position = object.Position
	object.AnchorPoint = anchor
	object.Position = UDim2.new(
		position.X.Scale + delta.X * size.X.Scale,
		math.round(position.X.Offset + delta.X * size.X.Offset),
		position.Y.Scale + delta.Y * size.Y.Scale,
		math.round(position.Y.Offset + delta.Y * size.Y.Offset)
	)
end

const function LayoutPanel(context: Tool.Context): GuiObject
	const objects = context.selection.objects
	const first = function(): GuiObject?
		return objects()[1]
	end
	const version = Watch(first)

	const function has(class: string): boolean
		version()
		const object = first()
		return object ~= nil and object:FindFirstChildWhichIsA(class) ~= nil
	end

	-- adds the component to everything missing it, or removes it if everything has it.
	const function toggle(component: Component)
		const list = objects()
		local all = #list > 0
		for _, object in list do
			if not object:FindFirstChildWhichIsA(component.class) then
				all = false
			end
		end
		Undo.record(`{if all then "Remove" else "Add"} {component.class}`, function()
			for _, object in list do
				const existing = object:FindFirstChildWhichIsA(component.class)
				if all and existing then
					existing:Destroy()
				elseif not existing then
					const instance = Instance.new(component.class)
					component.setup(instance, object)
					instance.Parent = object
				end
			end
		end)
	end

	const function each(name: string, edit: (GuiObject) -> ()): () -> ()
		return function()
			const list = objects()
			Undo.record(name, function()
				for _, object in list do
					edit(object)
				end
			end)
		end
	end

	const componentButtons = {}
	for index, component in COMPONENTS do
		table.insert(
			componentButtons,
			Button({
				text = component.label,
				layoutOrder = index,
				size = UDim2.fromScale(1, 1),
				active = function()
					return has(component.class)
				end,
				activated = function()
					toggle(component)
				end,
			})
		)
	end

	const anchorDots = {}
	for row = 0, 2 do
		for column = 0, 2 do
			const anchor = Vector2.new(column / 2, row / 2)
			const hovered = vide.source(false)
			const current = function()
				version()
				const object = first()
				return object ~= nil and object.AnchorPoint:FuzzyEq(anchor, 1e-3)
			end
			table.insert(
				anchorDots,
				new("TextButton")({
					Name = `Anchor{column}{row}`,
					LayoutOrder = row * 3 + column,
					BackgroundTransparency = function()
						return if hovered() then 0 else 1
					end,
					BackgroundColor3 = Theme.SURFACE_HOVER,
					Text = "",
					AutoButtonColor = false,
					MouseEnter = function()
						hovered(true)
					end,
					MouseLeave = function()
						hovered(false)
					end,
					Activated = each("Set AnchorPoint", function(object)
						setAnchor(object, anchor)
					end),
					Theme.corner(4),
					new("Frame")({
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = function()
							return if current() then UDim2.fromOffset(8, 8) else UDim2.fromOffset(5, 5)
						end,
						BackgroundColor3 = function()
							return if current() then Theme.ACCENT else Theme.ICON
						end,
						Theme.corner(4),
					}),
				})
			)
		end
	end

	return Layout.column({
		new("Frame")({
			Name = "Components",
			Size = UDim2.new(1, 0, 0, 2 * Theme.CONTROL_HEIGHT + 6),
			LayoutOrder = 1,
			BackgroundTransparency = 1,
			new("UIGridLayout")({
				CellSize = UDim2.new(1 / 3, -4, 0, Theme.CONTROL_HEIGHT),
				CellPadding = UDim2.fromOffset(6, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			componentButtons,
		}),
		Layout.row("Anchor", 2, {
			new("Frame")({
				Name = "Picker",
				Size = UDim2.fromOffset(72, 72),
				BackgroundColor3 = Theme.INPUT,
				Theme.corner(Theme.CONTROL_RADIUS),
				Theme.stroke(Theme.BORDER),
				new("UIGridLayout")({
					CellSize = UDim2.fromOffset(22, 22),
					CellPadding = UDim2.fromOffset(1, 1),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				new("UIPadding")({ PaddingLeft = UDim.new(0, 2), PaddingTop = UDim.new(0, 2) }),
				anchorDots,
			}),
			new("Frame")({
				Name = "Moves",
				Position = UDim2.fromOffset(84, 0),
				Size = UDim2.new(1, -84, 1, 0),
				BackgroundTransparency = 1,
				new("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }),
				Button({
					text = "Center in parent",
					layoutOrder = 1,
					size = UDim2.new(1, 0, 0, 21),
					activated = each("Center in parent", function(object)
						object.AnchorPoint = Vector2.new(0.5, 0.5)
						object.Position = UDim2.fromScale(0.5, 0.5)
					end),
				}),
				Button({
					text = "Fill parent",
					layoutOrder = 2,
					size = UDim2.new(1, 0, 0, 21),
					activated = each("Fill parent", function(object)
						object.AnchorPoint = Vector2.zero
						object.Position = UDim2.new()
						object.Size = UDim2.fromScale(1, 1)
					end),
				}),
				Button({
					text = function()
						version()
						const object = first()
						return if object and object.AutomaticSize ~= Enum.AutomaticSize.None
							then "Auto size: on"
							else "Auto size: off"
					end,
					name = "AutoSize",
					layoutOrder = 3,
					size = UDim2.new(1, 0, 0, 21),
					activated = function()
						const object = first()
						const on = object ~= nil and object.AutomaticSize == Enum.AutomaticSize.None
						each("Toggle AutomaticSize", function(target)
							target.AutomaticSize = if on then Enum.AutomaticSize.XY else Enum.AutomaticSize.None
						end)()
					end,
				}),
			}),
		}, 72),
		Layout.note("Click a component again to remove it", 3),
	})
end

return {
	id = "layout",
	label = "Layout",
	icon = Icons.layout,
	size = Vector2.new(300, 180),
	panel = LayoutPanel,
} :: Tool.Tool
