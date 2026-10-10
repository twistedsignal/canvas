-- the tools on the island, in bar order.
const Tool = require("./Tool")

return table.freeze({
	require("@self/IconsPanel"),
	require("@self/ScaleOffset"),
	require("@self/LayoutPanel"),
	require("@self/ColorPanel"),
	require("@self/ReclassPanel"),
	require("@self/SettingsPanel"),
}) :: { Tool.Tool }
