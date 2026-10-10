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
