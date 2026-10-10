-- the icon list is complete and search ranks the obvious match first.
local BuilderIcons = require("../src/BuilderIcons")

assert(#BuilderIcons.names > 700, `only {#BuilderIcons.names} icons`)
local seen = {}
for _, name in BuilderIcons.names do
	assert(string.match(name, "^[%w%-_]+$"), `bad name {name}`)
	assert(not seen[name], `duplicate {name}`)
	seen[name] = true
end
assert(seen["house"] and seen["magnifying-glass"] and seen["x"], "common icons are present")

assert(#BuilderIcons.search("") == #BuilderIcons.names, "empty search lists everything")
assert(BuilderIcons.search("house")[1] == "house", "exact match first")
assert(BuilderIcons.search("x")[1] == "x", "short exact match first")
assert(BuilderIcons.search("magnifying glass")[1] == "magnifying-glass", "words match kebab names")
assert(BuilderIcons.search("Chevron Large Down")[1] == "chevron-large-down", "case-insensitive")

for _, name in BuilderIcons.search("arrow left") do
	assert(string.find(name, "arrow", 1, true) and string.find(name, "left", 1, true), `{name} misses a term`)
end
assert(#BuilderIcons.search("definitely-not-an-icon") == 0, "no matches")

print("builder-icons: ok")

-- RichText markup: icons mix with text, and swapping replaces only the icons.
local house = BuilderIcons.markup("house", "Regular")
local filledStar = BuilderIcons.markup("star", "Filled")
assert(string.find(house, BuilderIcons.FAMILY, 1, true) and string.find(house, 'weight="400">house</font>', 1, true), "regular markup")
assert(string.find(filledStar, 'weight="700">star</font>', 1, true), "filled markup")

local name, variant = BuilderIcons.find(`Go {house} home`)
assert(name == "house" and variant == "Regular", "find regular")
name, variant = BuilderIcons.find(filledStar)
assert(name == "star" and variant == "Filled", "find filled")
assert(BuilderIcons.find("<b>plain</b>") == nil, "no icon")

assert(BuilderIcons.place("", house, "swap") == house, "empty text gets the icon")
assert(BuilderIcons.place("Home", house, "swap") == `{house} Home`, "swap with no icon adds at the start")
assert(BuilderIcons.place(`{house} Home`, filledStar, "swap") == `{filledStar} Home`, "swap replaces the icon, keeps the text")
assert(BuilderIcons.place(`{house} and {house}`, filledStar, "swap") == `{filledStar} and {filledStar}`, "swap replaces every icon")
assert(BuilderIcons.place("Home", house, "start") == `{house} Home`, "start")
assert(BuilderIcons.place("Home", house, "end") == `Home {house}`, "end")
assert(BuilderIcons.place(`{house} Home`, filledStar, "end") == `{house} Home {filledStar}`, "end keeps existing icons")
assert(BuilderIcons.escape("a < b & c > d") == "a &lt; b &amp; c &gt; d", "escape")

print("builder-icons markup: ok")
