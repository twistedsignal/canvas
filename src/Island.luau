-- selene: allow(mixed_table)
-- the floating window. compact by default; a tool button grows it into that tool's panel. drag
-- it to move it, and it springs to the nearest corner or edge of the viewport.
--
-- Modern is an island: a :: grip and borderless buttons, with the bar flipping to the bottom when
-- it sits at the bottom of the screen. Classic follows Photon's layout: a header with the logo,
-- title and tab buttons, always at the top, that you drag the window by.
const RunService = game:GetService("RunService")
const UserInputService = game:GetService("UserInputService")
const vide = require("./vide")
const Theme = require("./Theme")
const Icons = require("./Icons")
const Spring = require("./Spring")
const Snap = require("./Snap")
const Overlay = require("./Overlay")
const Tool = require("./Tool")
const IconButton = require("./components/IconButton")

const new = vide.create
const source = vide.source
const cleanup = vide.cleanup

const SLOT_KEY = "CanvasSlot"
const FREE_KEY = "CanvasFree"
const GAP = 4
const CLASSIC_GAP = 6
const CLASSIC_TITLE_WIDTH = 64
-- spring settings per Motion option. position and size share them so the anchored edge stays
-- put while the window morphs.
const MOTION = {
	bouncy = { frequency = 3.6, damping = 0.72 },
	smooth = { frequency = 4.2, damping = 1 },
}
-- while dragging, follow the cursor closely but still smoothly.
const DRAG_FREQUENCY = 14
-- how far back to look when measuring release velocity.
const VELOCITY_WINDOW = 0.08

export type Props = {
	plugin: Plugin,
	-- whether the selection and settings want the window shown.
	visible: () -> boolean,
	root: Frame,
	tools: { Tool.Tool },
	context: Tool.Context,
	-- a panel to open right away, used to reopen Settings after a theme change.
	initialTool: string?,
	-- dev builds get the island's state for testing from the command bar.
	onControls: ((Controls) -> ())?,
}

export type Controls = {
	active: vide.Source<string?>,
	slot: vide.Source<Snap.Slot>,
}

const function Island(props: Props): CanvasGroup
	const root = props.root
	const tools = props.tools
	const settings = props.context.settings
	const classic = Theme.STYLE == "Classic"

	const savedSlot = props.plugin:GetSetting(SLOT_KEY)
	const slot = source((if Snap.isSlot(savedSlot) then savedSlot else Snap.DEFAULT) :: Snap.Slot)
	-- with Free placement, where the window's anchor sits, as a fraction of the viewport.
	const savedFree = props.plugin:GetSetting(FREE_KEY)
	local free: Vector2? = if type(savedFree) == "table" and type(savedFree.x) == "number" and type(savedFree.y) == "number"
		then Vector2.new(math.clamp(savedFree.x, 0, 1), math.clamp(savedFree.y, 0, 1))
		else nil
	const active = source(nil :: string?)
	local dragging = false

	const toolsById: { [string]: Tool.Tool } = {}
	for _, tool in tools do
		toolsById[tool.id] = tool
	end

	const headerHeight = if classic then Theme.HEADER_HEIGHT else Theme.BAR_HEIGHT
	const headerWidth = if classic
		then 12 + 18 + 8 + CLASSIC_TITLE_WIDTH + 16 + #tools * Theme.BUTTON_SIZE + (#tools - 1) * CLASSIC_GAP + 12
		else 2 * Theme.PADDING + Theme.GRIP_WIDTH + #tools * (Theme.BUTTON_SIZE + GAP)
	const compact = Vector2.new(headerWidth, headerHeight)

	const function scale(): number
		return settings.number("scale") / 100
	end

	const function targetSize(): Vector2
		const id = active()
		const tool = if id then toolsById[id] else nil
		if not tool then
			return compact
		end
		return Vector2.new(math.max(headerWidth, tool.size.X), headerHeight + tool.size.Y)
	end

	const function viewport(): Vector2
		return root.AbsoluteSize
	end

	const anchor = function(): Vector2
		const a = Snap.anchors[slot()]
		return Vector2.new(a.x, a.y)
	end

	-- the modern bar moves to the bottom at bottom slots, so panels open upward.
	const headerAtBottom = function(): boolean
		return not classic and Snap.anchors[slot()].y == 1
	end

	-- top-left on screen for an unscaled window size.
	const function restingPosition(size: Vector2): Vector2
		const view = viewport()
		const s = size * scale()
		if free and settings.get("placement") == "free" then
			const a = Snap.anchors[slot()]
			const x, y = Snap.clamp(free.X * view.X - a.x * s.X, free.Y * view.Y - a.y * s.Y, s.X, s.Y, view.X, view.Y)
			return Vector2.new(x, y)
		end
		const x, y = Snap.topLeft(slot(), s.X, s.Y, view.X, view.Y)
		return Vector2.new(x, y)
	end

	const position = Spring.new(restingPosition(compact), MOTION.bouncy.frequency, MOTION.bouncy.damping)
	const size = Spring.new(compact, MOTION.bouncy.frequency, MOTION.bouncy.damping)
	-- x is visibility (0 hidden, 1 shown); y is unused.
	const shown = Spring.new(Vector2.zero, 4, 0.9)
	-- x is the open panel's opacity.
	const fade = Spring.new(Vector2.zero, 5, 1)

	const function applyMotion()
		const motion = MOTION[settings.get("motion")] or MOTION.smooth
		size.frequency, size.damping = motion.frequency, motion.damping
		if not dragging then
			position.frequency, position.damping = motion.frequency, motion.damping
		end
	end

	const function retarget()
		vide.untrack(function()
			applyMotion()
			const goal = targetSize()
			size:target(goal)
			if not dragging then
				position:target(restingPosition(goal))
			end
		end)
	end

	const function startDrag(input: InputObject)
		dragging = true
		const origin = root.AbsolutePosition
		const grab = Vector2.new(input.Position.X, input.Position.Y) - origin - position.position
		const samples: { { time: number, at: Vector2 } } = {}
		position.frequency, position.damping = DRAG_FREQUENCY, 1
		Overlay.drag(input, function(mouse)
			const view = viewport()
			const current = size.position * scale()
			const raw = mouse - origin - grab
			const x, y = Snap.rubberBand(raw.X, raw.Y, current.X, current.Y, view.X, view.Y)
			position:target(Vector2.new(x, y))
			const now = os.clock()
			table.insert(samples, { time = now, at = raw })
			while #samples > 2 and now - samples[1].time > VELOCITY_WINDOW do
				table.remove(samples, 1)
			end
		end, function()
			dragging = false
			const view = viewport()
			const goal = targetSize() * scale()
			if settings.get("placement") == "free" then
				-- stay where it was dropped; the nearest slot only decides which way it grows.
				const at = position.goal
				const x, y = Snap.clamp(at.X, at.Y, goal.X, goal.Y, view.X, view.Y)
				const next = Snap.nearest(x, y, 0, 0, goal.X, goal.Y, view.X, view.Y)
				const a = Snap.anchors[next]
				free = Vector2.new((x + a.x * goal.X) / view.X, (y + a.y * goal.Y) / view.Y)
				props.plugin:SetSetting(FREE_KEY, { x = free.X, y = free.Y })
				position.velocity = Vector2.zero
				slot(next)
				retarget()
				return
			end
			local velocity = Vector2.zero
			const last, oldest = samples[#samples], samples[1]
			if last and oldest and os.clock() - last.time < VELOCITY_WINDOW then
				const elapsed = last.time - oldest.time
				if elapsed > 1 / 120 then
					velocity = (last.at - oldest.at) / elapsed
				end
			end
			position.velocity = velocity
			const at = position.position
			slot(Snap.nearest(at.X, at.Y, velocity.X, velocity.Y, goal.X, goal.Y, view.X, view.Y))
			retarget()
		end)
	end

	const function onDragInput(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			startDrag(input)
		end
	end

	const buttons = {}
	for index, tool in tools do
		table.insert(
			buttons,
			IconButton({
				icon = tool.icon,
				label = tool.label,
				layoutOrder = index,
				active = function()
					return active() == tool.id
				end,
				activated = function()
					active(if active() == tool.id then nil else tool.id)
				end,
			})
		)
	end

	local header: GuiObject
	if classic then
		-- the header's background is the drag handle; the tab buttons sit on top of it.
		header = new("TextButton")({
			Name = "Header",
			Size = UDim2.new(1, 0, 0, headerHeight),
			BackgroundColor3 = Theme.HEADER,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 2,
			InputBegan = onDragInput,
			new("ImageLabel")({
				Name = "Logo",
				Position = UDim2.new(0, 12, 0.5, -9),
				Size = UDim2.fromOffset(18, 18),
				BackgroundTransparency = 1,
				Image = Icons.plugin,
				ScaleType = Enum.ScaleType.Fit,
			}),
			new("TextLabel")({
				Name = "Title",
				Position = UDim2.fromOffset(38, 0),
				Size = UDim2.new(0, CLASSIC_TITLE_WIDTH, 1, 0),
				BackgroundTransparency = 1,
				Text = "Canvas",
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.TEXT,
				FontFace = Theme.FONT_BOLD,
				TextSize = 18,
			}),
			new("Frame")({
				Name = "Tabs",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(#tools * Theme.BUTTON_SIZE + (#tools - 1) * CLASSIC_GAP, Theme.BUTTON_SIZE),
				BackgroundTransparency = 1,
				new("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, CLASSIC_GAP),
				}),
				buttons,
			}),
		}) :: TextButton
	else
		-- grip: four dots, like the :: in the mockup.
		const dots = {}
		for _, offset in { Vector2.new(-4, -4), Vector2.new(4, -4), Vector2.new(-4, 4), Vector2.new(4, 4) } do
			table.insert(
				dots,
				new("Frame")({
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, offset.X, 0.5, offset.Y),
					Size = UDim2.fromOffset(4, 4),
					BackgroundColor3 = Theme.ICON,
					BorderSizePixel = 0,
					Theme.corner(2),
				})
			)
		end
		const grip = new("TextButton")({
			Name = "Grip",
			Size = UDim2.fromOffset(Theme.GRIP_WIDTH, Theme.BUTTON_SIZE),
			LayoutOrder = 0,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			InputBegan = onDragInput,
			dots,
		}) :: TextButton
		Overlay.tooltip(grip, "Drag to move")
		header = new("Frame")({
			Name = "Bar",
			AnchorPoint = function()
				return Vector2.new(anchor().X, if headerAtBottom() then 1 else 0)
			end,
			Position = function()
				return UDim2.fromScale(anchor().X, if headerAtBottom() then 1 else 0)
			end,
			Size = UDim2.fromOffset(headerWidth, Theme.BAR_HEIGHT),
			BackgroundTransparency = 1,
			ZIndex = 2,
			new("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, GAP),
			}),
			new("UIPadding")({ PaddingLeft = UDim.new(0, Theme.PADDING), PaddingRight = UDim.new(0, Theme.PADDING) }),
			grip,
			buttons,
		}) :: Frame
	end

	const uiScale = new("UIScale")({ Scale = 0.9 }) :: UIScale
	const island = new("CanvasGroup")({
		Name = "Island",
		BackgroundColor3 = Theme.BAR,
		BorderSizePixel = 0,
		Active = true,
		Visible = false,
		GroupTransparency = 1,
		Theme.corner(Theme.RADIUS),
		Theme.stroke(Theme.BORDER),
		uiScale,
		header,
	}) :: CanvasGroup

	-- the open panel. it's rebuilt whenever the active tool changes and destroyed once the
	-- window finishes collapsing.
	local panel: CanvasGroup? = nil
	local panelContent: GuiObject? = nil
	local destroyPanel: (() -> ())? = nil

	const function removePanel()
		if destroyPanel then
			destroyPanel()
		end
		destroyPanel, panel, panelContent = nil, nil, nil
	end
	cleanup(removePanel)

	const function placePanel()
		if not panel then
			return
		end
		const x = if classic then 0 else anchor().X
		if headerAtBottom() then
			panel.AnchorPoint = Vector2.new(x, 1)
			panel.Position = UDim2.new(x, 0, 1, -headerHeight)
		else
			panel.AnchorPoint = Vector2.new(x, 0)
			panel.Position = UDim2.new(x, 0, 0, headerHeight)
		end
	end

	const function openPanel(tool: Tool.Tool)
		removePanel()
		destroyPanel = vide.root(function(destroy)
			const content = tool.panel(props.context)
			const group = new("CanvasGroup")({
				Name = "Panel",
				Size = if classic then UDim2.new(1, 0, 0, tool.size.Y) else UDim2.fromOffset(tool.size.X, tool.size.Y),
				BackgroundTransparency = 1,
				GroupTransparency = 1,
				Parent = island,
				content,
			}) :: CanvasGroup
			cleanup(group)
			panel, panelContent = group, content
			return destroy
		end)
		placePanel()
		fade:snap(Vector2.zero)
		fade:target(Vector2.new(1, 0))
	end

	vide.effect(function()
		const id = active()
		vide.untrack(function()
			if id then
				openPanel(toolsById[id])
			else
				fade:target(Vector2.zero)
			end
			retarget()
		end)
	end)

	vide.effect(function()
		const current = slot()
		vide.untrack(function()
			props.plugin:SetSetting(SLOT_KEY, current)
			placePanel()
			retarget()
		end)
	end)

	-- settings that move or resize the window.
	vide.effect(function()
		settings.values.scale()
		settings.values.motion()
		if settings.values.placement() == "snap" then
			free = nil
			props.plugin:SetSetting(FREE_KEY, nil)
		end
		retarget()
	end)

	vide.effect(function()
		const selected = #props.context.selection.ui()
		vide.untrack(function()
			if selected == 0 and settings.get("collapse") == "close" then
				active(nil)
			end
		end)
	end)

	vide.effect(function()
		const visible = props.visible()
		vide.untrack(function()
			if visible and shown.position.X < 0.01 then
				-- reappear where it belongs, even if the viewport changed while hidden.
				const goal = targetSize()
				size:snap(goal)
				position:snap(restingPosition(goal))
			end
			shown:target(Vector2.new(if visible then 1 else 0, 0))
		end)
	end)

	cleanup(root:GetPropertyChangedSignal("AbsoluteSize"):Connect(retarget))

	-- clicks on the window also reach Studio's select tool behind it. tell the selection to undo
	-- changes while the pointer is over the window: it's inside the window's bounds, it moved over
	-- the window a moment ago (in case the mouse location is off), or the window is being dragged.
	local pointerAt = 0
	const function touch()
		pointerAt = os.clock()
	end
	cleanup(island.MouseEnter:Connect(touch))
	cleanup(island.InputBegan:Connect(touch))
	cleanup(island.InputChanged:Connect(touch))
	cleanup(island.MouseLeave:Connect(function()
		pointerAt = 0
	end))
	props.context.selection.setGuard(function()
		if dragging then
			return true
		end
		if not island.Visible then
			return false
		end
		const mouse = UserInputService:GetMouseLocation()
		const from, to = island.AbsolutePosition, island.AbsolutePosition + island.AbsoluteSize
		if mouse.X >= from.X and mouse.X <= to.X and mouse.Y >= from.Y and mouse.Y <= to.Y then
			return true
		end
		return os.clock() - pointerAt < 1
	end)

	cleanup(UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Escape and active() then
			active(nil)
		end
	end))

	-- what render last wrote, so it only touches instances when something changed. comparing
	-- against this, rather than asking whether the springs moved, also covers Motion: Off, where
	-- every spring jumps to its goal and never reports movement.
	local applied: { [string]: any } = {}
	const function render(dt: number)
		if settings.get("motion") == "off" then
			-- no animation: jump straight to every goal, except while following the cursor.
			if not dragging then
				position:snap(position.goal)
			end
			size:snap(size.goal)
			shown:snap(shown.goal)
			fade:snap(fade.goal)
		end
		position:step(dt)
		size:step(dt)
		shown:step(dt)
		const fading = fade:step(dt)
		const opacity = math.clamp(fade.position.X, 0, 1)
		if panel and not active() and not fading and opacity < 0.01 then
			removePanel()
		end

		const k = scale()
		const a = anchor()
		const s = size.position
		const p = position.position
		const visible = shown.position.X
		if
			applied.k == k
			and applied.a == a
			and applied.s == s
			and applied.p == p
			and applied.visible == visible
			and applied.goal == shown.goal.X
			and applied.panel == panel
			and applied.opacity == opacity
			and applied.bottom == headerAtBottom()
		then
			return
		end
		applied = {
			k = k,
			a = a,
			s = s,
			p = p,
			visible = visible,
			goal = shown.goal.X,
			panel = panel,
			opacity = opacity,
			bottom = headerAtBottom(),
		}

		const visibility = math.clamp(visible, 0, 1)
		island.AnchorPoint = a
		island.Position = UDim2.fromOffset(math.round(p.X + a.X * s.X * k), math.round(p.Y + a.Y * s.Y * k))
		island.Size = UDim2.fromOffset(math.round(s.X), math.round(s.Y))
		island.GroupTransparency = 1 - visibility
		island.Visible = visibility > 0.01 or shown.goal.X > 0
		uiScale.Scale = k * (0.9 + 0.1 * visible)
		if panel and panelContent then
			panel.GroupTransparency = 1 - opacity
			const direction = if headerAtBottom() then 1 else -1
			panelContent.Position = UDim2.fromOffset(0, math.round((1 - opacity) * 10 * direction))
		end
	end
	cleanup(RunService.Heartbeat:Connect(render))
	render(0)

	props.context.resetPosition = function()
		free = nil
		slot(Snap.DEFAULT)
		retarget()
	end

	if props.initialTool and toolsById[props.initialTool] then
		active(props.initialTool)
	end

	if props.onControls then
		props.onControls({ active = active, slot = slot })
	end

	return island
end

return Island
