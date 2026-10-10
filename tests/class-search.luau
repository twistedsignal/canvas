-- Reclass autocomplete puts the obvious class first and favours related classes.
local ClassSearch = require("../src/ClassSearch")

local function class(...)
	return { name = (...), ancestry = { ... } }
end
local GUI = { "GuiObject", "GuiBase2d", "GuiBase", "Instance", "Object" }
local function gui(name, ...)
	local ancestry = { name, ... }
	for _, ancestor in GUI do
		table.insert(ancestry, ancestor)
	end
	return { name = name, ancestry = ancestry }
end

local classes = {
	gui("TextLabel", "GuiLabel"),
	gui("ImageLabel", "GuiLabel"),
	gui("TextButton", "GuiButton"),
	gui("ImageButton", "GuiButton"),
	gui("TextBox"),
	gui("Frame"),
	gui("ScrollingFrame"),
	class("Part", "FormFactorPart", "BasePart", "PVInstance", "Instance", "Object"),
	class("Folder", "Instance", "Object"),
	class("UICorner", "UIComponent", "UIBase", "Instance", "Object"),
	class("TextChatMessageProperties", "Instance", "Object"),
}
local textLabel = classes[1].ancestry

assert(ClassSearch.related(textLabel, classes[2].ancestry) == 6, "TextLabel and ImageLabel share GuiLabel and up")
assert(ClassSearch.related(textLabel, classes[6].ancestry) == 5, "TextLabel and Frame share GuiObject and up")
assert(ClassSearch.related(textLabel, classes[8].ancestry) == 2, "TextLabel and Part share Instance and Object")

local none = ClassSearch.rank(classes, "", textLabel)
assert(none[1] == "ImageLabel", `closest sibling first, got {none[1]}`)
assert(not table.find(none, "TextLabel"), "the source class is left out")
assert(not table.find(none, "Part") and not table.find(none, "Folder"), "unrelated classes are left out with no query")
assert(table.find(none, "Frame"), "other GuiObjects are suggested")

assert(ClassSearch.rank(classes, "frame", textLabel)[1] == "Frame", "exact match first")
assert(ClassSearch.rank(classes, "Image", textLabel)[1] == "ImageLabel", "prefix match, related first")
assert(ClassSearch.rank(classes, "button", textLabel)[1] == "TextButton", "word match")
local text = ClassSearch.rank(classes, "text", textLabel)
assert(text[1] == "TextBox" or text[1] == "TextButton", `related prefix matches beat unrelated ones, got {text[1]}`)
assert(table.find(text, "TextChatMessageProperties") == #text, "unrelated text class ranks last")
assert(ClassSearch.rank(classes, "imglbl", textLabel)[1] == "ImageLabel", "fuzzy match")
assert(#ClassSearch.rank(classes, "zzz", textLabel) == 0, "no matches")
assert(#ClassSearch.rank(classes, "e", textLabel, 3) == 3, "limit")
assert(#ClassSearch.rank(classes, "", nil) == #classes, "no origin lists everything")

print("class-search: ok")
