-- the UI instances in the Studio selection, as vide sources.
const Selection = game:GetService("Selection")
const vide = require("./vide")

export type SelectionState = {
	-- selected GuiBase2d instances (GuiObjects and LayerCollectors). a selected UICorner, UIStroke
	-- or other UI component counts as its parent.
	ui: () -> { GuiBase2d },
	-- just the GuiObjects, for edits to Position, Size, colors and so on.
	objects: () -> { GuiObject },
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

const SelectionState = {}

-- call inside a vide scope; the connection is cleaned up with it.
function SelectionState.create(): SelectionState
	const ui = vide.source({} :: { GuiBase2d })
	const function refresh()
		const list, seen = {}, {}
		for _, instance in Selection:Get() do
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

	return { ui = ui, objects = objects }
end

return SelectionState
