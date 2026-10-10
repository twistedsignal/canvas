-- ranks class names for the Reclass autocomplete. pure, so it runs under lune.
export type Class = {
	name: string,
	-- the class and its superclasses, nearest first: { "TextLabel", "GuiLabel", ..., "Instance" }.
	ancestry: { string },
}

local ClassSearch = {}

-- how many superclasses two classes share, counted from the root. TextLabel and ImageLabel share
-- GuiLabel and everything above it; TextLabel and Part only share Instance and above.
function ClassSearch.related(a: { string }, b: { string }): number
	local shared = 0
	local i, j = #a, #b
	while i >= 1 and j >= 1 and a[i] == b[j] do
		shared += 1
		i -= 1
		j -= 1
	end
	return shared
end

-- true when every letter of the query appears in order in the name ("txtlbl" matches TextLabel).
local function subsequence(name: string, query: string): boolean
	local at = 1
	for index = 1, #query do
		local found = string.find(name, string.sub(query, index, index), at, true)
		if not found then
			return false
		end
		at = found + 1
	end
	return true
end

-- whether the query starts at a word in the PascalCase name ("label" in TextLabel).
local function wordStart(name: string, query: string): boolean
	local lower = string.lower(name)
	local at = 1
	while true do
		local found = string.find(lower, query, at, true)
		if not found then
			return false
		end
		local first = string.sub(name, found, found)
		if found == 1 or string.upper(first) == first then
			return true
		end
		at = found + 1
	end
end

-- matching names, best first. with no query, lists classes closely related to `from`. with a
-- query, prefers exact, then prefix, then word, then substring, then fuzzy matches, and breaks
-- ties by how related the class is to `from`.
function ClassSearch.rank(classes: { Class }, query: string, from: { string }?, limit: number?): { string }
	local q = string.lower((string.gsub(query, "%s", "")))
	local origin = from or {}
	local scored = {}
	for _, class in classes do
		if class.name == origin[1] then
			continue
		end
		local related = ClassSearch.related(class.ancestry, origin)
		local lower = string.lower(class.name)
		local score
		if q == "" then
			-- nothing typed: siblings and cousins only, not everything that's an Instance.
			if from and related < 3 then
				continue
			end
			score = 0
		elseif lower == q then
			score = 1000
		elseif string.sub(lower, 1, #q) == q then
			score = 500
		elseif wordStart(class.name, q) then
			score = 200
		elseif string.find(lower, q, 1, true) then
			score = 100
		elseif subsequence(lower, q) then
			score = 10
		else
			continue
		end
		table.insert(scored, { name = class.name, score = score + related * 5 })
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
	local results = {}
	for index, entry in scored do
		if limit and index > limit then
			break
		end
		results[index] = entry.name
	end
	return results
end

return ClassSearch
