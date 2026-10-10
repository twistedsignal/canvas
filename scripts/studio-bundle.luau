--[[
	Turns build/Canvas.rbxm into Luau chunks that rebuild the plugin under workspace.Canvas,
	so it can be installed through the Studio MCP's execute_luau (or the command bar) and then
	saved or published with Save as Local Plugin... / Publish as Plugin...

		lune run scripts/studio-bundle.luau build/Canvas.rbxm build/studio-install.luau

	Writes studio-install.luau, plus studio-install-2.luau and so on when the sources are too
	big for one call. Run them in order; the first one replaces any existing workspace.Canvas.
	Also writes the same tree as JSON (studio-install.json) for installers that fetch it over HTTP.
]]
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local input = process.args[1] or "build/Canvas.rbxm"
local output = process.args[2] or "build/studio-install.luau"
-- execute_luau payloads above this are split across several chunks.
local CHUNK_LIMIT = 150000

local root = roblox.deserializeModel(fs.readFile(input))[1]
assert(root, `{input} has no root instance`)

local function quote(text: string): string
	local level = 0
	while string.find(text, "]" .. string.rep("=", level) .. "]", 1, true) do
		level += 1
	end
	local equals = string.rep("=", level)
	-- a long string drops one leading newline, so add one to keep sources exact.
	return `[{equals}[\n{text}]{equals}]`
end

local entries = {}
local function walk(instance, path: { string })
	local entry = { path = table.clone(path), class = instance.ClassName, source = nil :: string? }
	if instance:IsA("LuaSourceContainer") then
		entry.source = instance.Source
	end
	table.insert(entries, entry)
	for _, child in instance:GetChildren() do
		local childPath = table.clone(path)
		table.insert(childPath, child.Name)
		walk(child, childPath)
	end
end
walk(root, { root.Name })

local HEADER = [[
local function at(path, class)
	local parent = workspace
	for index, name in path do
		local child = parent:FindFirstChild(name)
		if not child then
			child = Instance.new(if index == #path then class else "Folder")
			child.Name = name
			child.Parent = parent
		end
		parent = child
	end
	return parent
end
local count = 0
]]

local chunks = {}
local current = { HEADER }
local size = #HEADER
local function flush()
	table.insert(current, "return `created or updated {count} instances under workspace`\n")
	table.insert(chunks, table.concat(current))
end
table.insert(current, `local old = workspace:FindFirstChild("{root.Name}")\nif old then old:Destroy() end\n`)

for _, entry in entries do
	local names = {}
	for _, name in entry.path do
		table.insert(names, string.format("%q", name))
	end
	local line = `do local instance = at(\{{table.concat(names, ", ")}}, "{entry.class}")`
	if entry.source then
		line ..= `\ninstance.Source = {quote(entry.source)}`
	end
	line ..= "\ncount += 1 end\n"
	if size + #line > CHUNK_LIMIT and #current > 1 then
		flush()
		current = { HEADER }
		size = #HEADER
	end
	table.insert(current, line)
	size += #line
end
flush()

local base = string.gsub(output, "%.luau$", "")
for index, chunk in chunks do
	local path = if index == 1 then output else `{base}-{index}.luau`
	fs.writeFile(path, chunk)
	print(`Wrote {path} ({#chunk} bytes)`)
end

local manifest = {}
for _, entry in entries do
	table.insert(manifest, { path = entry.path, class = entry.class, source = entry.source })
end
local json = string.gsub(output, "%.luau$", ".json")
fs.writeFile(json, serde.encode("json", manifest))
print(`Wrote {json}`)
