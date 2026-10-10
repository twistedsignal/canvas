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
