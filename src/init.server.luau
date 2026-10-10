const CoreGui = game:GetService("CoreGui")
const RunService = game:GetService("RunService")

if not RunService:IsEdit() then
	return
end

const vide = require("@self/vide")
const App = require("@self/App")
const Icons = require("@self/Icons")
const Theme = require("@self/Theme")
const Settings = require("@self/Settings")
const Tool = require("@self/Tool")

const ENABLED_KEY = "CanvasEnabled"

const toolbar = plugin:CreateToolbar("Canvas")
const button = toolbar:CreateButton("Canvas", "Show the Canvas toolkit whenever UI is selected", Icons.plugin)
button.ClickableWhenViewportHidden = true

const enabled = vide.source(plugin:GetSetting(ENABLED_KEY) ~= false)
button:SetActive(enabled())

-- the window floats over the viewport instead of living in a dock widget.
const gui = Instance.new("ScreenGui")
gui.Name = "Canvas"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 10000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

-- dev builds (Canvas-dev.rbxm from scripts/dev.bash) expose the window to the command bar.
const dev = string.find(plugin.Name, "dev", 1, true) ~= nil
const style = vide.source(nil :: Tool.Style?)

local unmount: (() -> ())? = nil
local settings: Settings.Store

const function mount(initialTool: string?)
	if unmount then
		unmount()
	end
	Theme.use(settings.get("theme") :: Theme.Name)
	unmount = vide.mount(function()
		return App({
			plugin = plugin,
			enabled = enabled,
			settings = settings,
			style = style,
			initialTool = initialTool,
			onControls = if dev
				then function(controls)
					-- selene: allow(global_usage)
					const globals = shared :: any
					globals.CanvasDev = { active = controls.active, slot = controls.slot, settings = settings }
				end
				else nil,
		})
	end, gui)
end

-- components read the theme when they're built, so a new theme rebuilds the UI and reopens
-- Settings, where the change was made.
settings = Settings.create(plugin, function(key)
	if key == "theme" then
		task.defer(mount, "settings")
	end
end)
mount()

button.Click:Connect(function()
	enabled(not enabled())
	button:SetActive(enabled())
	plugin:SetSetting(ENABLED_KEY, enabled())
end)

plugin.Unloading:Connect(function()
	if unmount then
		unmount()
		unmount = nil
	end
	gui:Destroy()
end)
