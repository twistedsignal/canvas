-- Roblox's Builder Icons font, which ships with Studio. Each icon is a ligature: a TextLabel with
-- this font and Text = "house" draws the house icon.
local Names = require("@self/Names")

export type Variant = "Regular" | "Filled"

local FAMILY = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"

local BuilderIcons = {
	names = Names,
	FAMILY = FAMILY,
}

-- Filled icons are the family's Bold weight.
function BuilderIcons.font(variant: Variant): Font
	return Font.new(FAMILY, if variant == "Filled" then Enum.FontWeight.Bold else Enum.FontWeight.Regular)
end

function BuilderIcons.variantOf(font: Font): Variant?
	if font.Family ~= FAMILY then
		return nil
	end
	return if font.Weight == Enum.FontWeight.Bold then "Filled" else "Regular"
end

export type Placement = "swap" | "start" | "end"

local WEIGHTS = { Regular = "400", Filled = "700" }
-- the family path with Lua pattern characters escaped.
local FAMILY_PATTERN = string.gsub(FAMILY, "%W", "%%%0")
local TAG_PATTERN = `<font family="{FAMILY_PATTERN}" weight="(%w+)">([%w%-_]+)</font>`

-- RichText for one icon. it only changes the font around the icon's name, so it can sit in the
-- middle of ordinary text.
function BuilderIcons.markup(name: string, variant: Variant): string
	return `<font family="{FAMILY}" weight="{WEIGHTS[variant] or WEIGHTS.Regular}">{name}</font>`
end

-- the first icon in a RichText string, if any.
function BuilderIcons.find(text: string): (string?, Variant?)
	local weight, name = string.match(text, TAG_PATTERN)
	if not name then
		return nil, nil
	end
	return name, if weight == "700" or string.lower(weight) == "bold" then "Filled" else "Regular"
end

-- escapes plain text so it reads the same once RichText is turned on.
function BuilderIcons.escape(text: string): string
	return (string.gsub(string.gsub(string.gsub(text, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"))
end

-- puts an icon into RichText. "swap" replaces the icons already there, or adds it at the start
-- when there are none; "start" and "end" add it next to the existing text.
function BuilderIcons.place(text: string, markup: string, placement: Placement): string
	if placement == "swap" then
		local swapped, count = string.gsub(text, TAG_PATTERN, function()
			return markup
		end)
		if count > 0 then
			return swapped
		end
		placement = "start"
	end
	if text == "" then
		return markup
	end
	return if placement == "start" then `{markup} {text}` else `{text} {markup}`
end

-- names that contain every word of the query, best matches first: exact, then prefix, then names
-- whose words start with the query's words, then anything else.
function BuilderIcons.search(query: string): { string }
	local terms = {}
	for term in string.gmatch(string.lower(query), "[^%s%-_]+") do
		table.insert(terms, term)
	end
	if #terms == 0 then
		return table.clone(Names)
	end
	local joined = table.concat(terms, "-")
	local scored: { { name: string, score: number } } = {}
	for _, name in Names do
		local score = 0
		local matched = true
		for _, term in terms do
			local at = string.find(name, term, 1, true)
			if not at then
				matched = false
				break
			end
			if at == 1 or string.sub(name, at - 1, at - 1) == "-" then
				score += 1
			end
		end
		if matched then
			if name == joined then
				score += 100
			elseif string.sub(name, 1, #joined) == joined then
				score += 10
			end
			table.insert(scored, { name = name, score = score })
		end
	end
	table.sort(scored, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		if #a.name ~= #b.name then
			return #a.name < #b.name
		end
		return a.name < b.name
	end)
	local results = table.create(#scored)
	for index, entry in scored do
		results[index] = entry.name
	end
	return results
end

return BuilderIcons
