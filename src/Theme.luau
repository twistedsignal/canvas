const vide = require("./vide")

export type Name = "Classic" | "Modern"

-- the values that change between themes. components read them from Theme when they're built,
-- so switching themes remounts the UI (see init.server.luau).
type Palette = {
	STYLE: Name,
	-- window body and the classic header strip
	BAR: Color3,
	HEADER: Color3,
	BORDER: Color3,
	-- controls inside panels
	SURFACE: Color3,
	SURFACE_HOVER: Color3,
	SURFACE_STROKE: number,
	INPUT: Color3,
	ACTIVE: Color3,
	ACCENT: Color3,
	ACCENT_BORDER: Color3,
	ICON: Color3,
	ICON_HOVER: Color3,
	TEXT: Color3,
	MUTED: Color3,
	SUBTLE: Color3,
	ROW: Color3,
	ROW_ALT: Color3,

	FONT: Font,
	FONT_BOLD: Font,
	FONT_BUTTON: Font,
	TEXT_SMALL: number,
	TEXT_LABEL: number,
	TEXT_BODY: number,

	RADIUS: number,
	CONTROL_RADIUS: number,
}

const BUILDER = "rbxasset://fonts/families/BuilderSans.json"
const SOURCE_SANS = "rbxasset://fonts/families/SourceSansPro.json"

const PALETTES: { [Name]: Palette } = {
	-- follows Photon: its header, colors, bordered buttons and square edges.
	Classic = {
		STYLE = "Classic",
		BAR = Color3.fromRGB(25, 26, 31),
		HEADER = Color3.fromRGB(20, 21, 25),
		BORDER = Color3.fromRGB(38, 40, 48),
		SURFACE = Color3.fromRGB(47, 50, 62),
		SURFACE_HOVER = Color3.fromRGB(55, 58, 70),
		SURFACE_STROKE = 0,
		INPUT = Color3.fromRGB(21, 22, 27),
		ACTIVE = Color3.fromRGB(57, 98, 255),
		ACCENT = Color3.fromRGB(57, 98, 255),
		ACCENT_BORDER = Color3.fromRGB(39, 70, 196),
		ICON = Color3.fromRGB(170, 174, 188),
		ICON_HOVER = Color3.fromRGB(232, 235, 245),
		TEXT = Color3.fromRGB(232, 235, 245),
		MUTED = Color3.fromRGB(170, 174, 188),
		SUBTLE = Color3.fromRGB(118, 122, 138),
		ROW = Color3.fromRGB(24, 25, 30),
		ROW_ALT = Color3.fromRGB(28, 29, 35),

		FONT = Font.new(SOURCE_SANS, Enum.FontWeight.Regular),
		FONT_BOLD = Font.new(SOURCE_SANS, Enum.FontWeight.Bold),
		FONT_BUTTON = Font.new(SOURCE_SANS, Enum.FontWeight.SemiBold),
		TEXT_SMALL = 14,
		TEXT_LABEL = 15,
		TEXT_BODY = 15,

		RADIUS = 0,
		CONTROL_RADIUS = 4,
	},
	-- the floating island: rounded, borderless buttons, Builder Sans.
	Modern = {
		STYLE = "Modern",
		BAR = Color3.fromRGB(24, 25, 26),
		HEADER = Color3.fromRGB(24, 25, 26),
		BORDER = Color3.fromRGB(44, 46, 49),
		SURFACE = Color3.fromRGB(33, 35, 37),
		SURFACE_HOVER = Color3.fromRGB(42, 44, 47),
		SURFACE_STROKE = 0.3,
		INPUT = Color3.fromRGB(18, 19, 20),
		ACTIVE = Color3.fromRGB(52, 55, 59),
		ACCENT = Color3.fromRGB(64, 132, 255),
		ACCENT_BORDER = Color3.fromRGB(44, 104, 214),
		ICON = Color3.fromRGB(138, 141, 145),
		ICON_HOVER = Color3.fromRGB(205, 208, 212),
		TEXT = Color3.fromRGB(228, 230, 233),
		MUTED = Color3.fromRGB(138, 141, 145),
		SUBTLE = Color3.fromRGB(92, 95, 99),
		ROW = Color3.fromRGB(24, 25, 26),
		ROW_ALT = Color3.fromRGB(28, 29, 31),

		FONT = Font.new(BUILDER, Enum.FontWeight.Medium),
		FONT_BOLD = Font.new(BUILDER, Enum.FontWeight.Bold),
		FONT_BUTTON = Font.new(BUILDER, Enum.FontWeight.Medium),
		TEXT_SMALL = 12,
		TEXT_LABEL = 13,
		TEXT_BODY = 14,

		RADIUS = 12,
		CONTROL_RADIUS = 6,
	},
}

const Theme = {
	FONT_MONO = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular),

	-- modern bar
	BAR_HEIGHT = 44,
	BUTTON_SIZE = 32,
	GRIP_WIDTH = 30,
	PADDING = 6,
	-- classic header
	HEADER_HEIGHT = 46,

	CONTROL_HEIGHT = 26,
	OVERLAY_Z = 50,
} :: Palette & {
	FONT_MONO: Font,
	BAR_HEIGHT: number,
	BUTTON_SIZE: number,
	GRIP_WIDTH: number,
	PADDING: number,
	HEADER_HEIGHT: number,
	CONTROL_HEIGHT: number,
	OVERLAY_Z: number,
	[string]: any,
}

-- switches the palette. call before mounting the UI.
function Theme.use(name: Name)
	for key, value in PALETTES[name] or PALETTES.Classic do
		(Theme :: any)[key] = value
	end
end

function Theme.stroke(color: Color3, transparency: number?)
	return vide.create("UIStroke")({
		Color = color,
		Thickness = 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Theme.corner(radius: number)
	return vide.create("UICorner")({ CornerRadius = UDim.new(0, radius) })
end

function Theme.hover(color: Color3): Color3
	return color:Lerp(Color3.new(1, 1, 1), 0.06)
end

Theme.use("Classic")

return Theme
