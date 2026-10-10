-- selene: allow(mixed_table)
-- tooltips and drag capture render here, above the island and outside its clipping.
const vide = require("./vide")
const Theme = require("./Theme")

const new = vide.create

local layer: Frame? = nil
local tooltipsEnabled: () -> boolean = function()
	return true
end

const Overlay = {}

function Overlay.setLayer(frame: Frame?)
	layer = frame
end

-- tooltips only show while this returns true.
function Overlay.setTooltips(enabled: () -> boolean)
	tooltipsEnabled = enabled
end

function Overlay.layer(): Frame
	assert(layer, "Canvas overlay layer is not mounted")
	return layer
end

-- tracks the mouse until the button is released, even when it leaves the dragged control.
-- positions are in screen space.
function Overlay.drag(press: InputObject, onMove: (position: Vector2) -> (), onEnd: (() -> ())?)
	local done = false
	local capture: TextButton? = nil
	local connection: RBXScriptConnection? = nil
	const function finish()
		if done then
			return
		end
		done = true
		if connection then
			connection:Disconnect()
		end
		if capture then
			capture:Destroy()
		end
		if onEnd then
			onEnd()
		end
	end
	-- the capture appears after mouse-down, so it may never see that press end. watch the
	-- original input too.
	connection = press:GetPropertyChangedSignal("UserInputState"):Connect(function()
		if press.UserInputState == Enum.UserInputState.End or press.UserInputState == Enum.UserInputState.Cancel then
			finish()
		end
	end)
	capture = new("TextButton")({
		Name = "DragCapture",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 1000,
		Parent = Overlay.layer(),
		InputChanged = function(input: InputObject)
			if not done and input.UserInputType == Enum.UserInputType.MouseMovement then
				onMove(Vector2.new(input.Position.X, input.Position.Y))
			end
		end,
		InputEnded = function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				finish()
			end
		end,
	}) :: TextButton
end

-- shows a small label next to a control after a short hover. call inside a vide scope.
function Overlay.tooltip(target: GuiObject, text: string | () -> string)
	const visible = vide.source(false)
	const position = vide.source(UDim2.new())
	local token = 0
	const label = new("TextLabel")({
		Name = "Tooltip",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = position,
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.SURFACE,
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = Theme.TEXT,
		FontFace = Theme.FONT,
		TextSize = Theme.TEXT_SMALL,
		Visible = visible,
		ZIndex = Theme.OVERLAY_Z,
		Parent = Overlay.layer(),
		Theme.corner(Theme.CONTROL_RADIUS),
		Theme.stroke(Theme.BORDER),
		new("UIPadding")({ PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
	})
	vide.cleanup(label)
	const function hide()
		token += 1
		visible(false)
	end
	vide.cleanup(target.MouseEnter:Connect(function()
		token += 1
		const mine = token
		task.delay(0.45, function()
			if token ~= mine or not target:IsDescendantOf(game) or not tooltipsEnabled() then
				return
			end
			const at = target.AbsolutePosition - Overlay.layer().AbsolutePosition
			const above = at.Y > 40
			label.AnchorPoint = Vector2.new(0.5, if above then 1 else 0)
			position(UDim2.fromOffset(
				at.X + target.AbsoluteSize.X / 2,
				if above then at.Y - 8 else at.Y + target.AbsoluteSize.Y + 8
			))
			visible(true)
		end)
	end))
	vide.cleanup(target.MouseLeave:Connect(hide))
	vide.cleanup(target.AncestryChanged:Connect(hide))
	vide.cleanup(hide)
end

return Overlay
