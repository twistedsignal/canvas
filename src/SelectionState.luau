-- the UI instances in the Studio selection, as vide sources.
--
-- Studio's select tool doesn't know about plugin GUIs over the viewport, so a click on a Canvas
-- button also lands on the 3D view and deselects (or selects whatever is behind the window). While
-- the guard says the pointer is over Canvas, those changes are undone straight away.
const Selection = game:GetService("Selection")
const vide = require("./vide")

export type SelectionState = {
	-- selected GuiBase2d instances (GuiObjects and LayerCollectors). a selected UICorner, UIStroke
	-- or other UI component counts as its parent.
	ui: () -> { GuiBase2d },
	-- just the GuiObjects, for edits to Position, Size, colors and so on.
	objects: () -> { GuiObject },
	-- changes the selection on purpose, even while the pointer is over Canvas.
	set: (instances: { Instance }) -> (),
	-- returns true while selection changes should be reverted.
	setGuard: (guard: () -> boolean) -> (),
}

const function resolve(instance: Instance): GuiBase2d?
	if instance:IsA("GuiBase2d") then
		return instance
	end
	if instance:IsA("UIBase") then
		const parent = instance.Parent
		if parent and parent:IsA("GuiBase2d") then
			return parent
		end
	end
	return nil
end

const function same(a: { Instance }, b: { Instance }): boolean
	if #a ~= #b then
		return false
	end
	const lookup = {}
	for _, instance in a do
		lookup[instance] = true
	end
	for _, instance in b do
		if not lookup[instance] then
			return false
		end
	end
	return true
end

const SelectionState = {}

-- call inside a vide scope; the connection is cleaned up with it.
function SelectionState.create(): SelectionState
	const ui = vide.source({} :: { GuiBase2d })
	local guard: () -> boolean = function()
		return false
	end
	-- the selection as Canvas last accepted it, to restore after a stray click.
	local accepted: { Instance } = Selection:Get()

	const function refresh()
		const current = Selection:Get()
		if guard() and not same(current, accepted) then
			const restore = {}
			for _, instance in accepted do
				if instance.Parent then
					table.insert(restore, instance)
				end
			end
			accepted = restore
			Selection:Set(restore)
			return
		end
		accepted = current
		const list, seen = {}, {}
		for _, instance in current do
			const target = resolve(instance)
			if target and not seen[target] then
				seen[target] = true
				table.insert(list, target)
			end
		end
		ui(list)
	end
	refresh()
	vide.cleanup(Selection.SelectionChanged:Connect(refresh))

	const objects = vide.derive(function()
		const list = {}
		for _, target in ui() do
			if target:IsA("GuiObject") then
				table.insert(list, target)
			end
		end
		return list
	end)

	return {
		ui = ui,
		objects = objects,
		set = function(instances)
			accepted = instances
			Selection:Set(instances)
		end,
		setGuard = function(next)
			guard = next
		end,
	}
end

return SelectionState
