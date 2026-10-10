-- Scale and Offset conversions keep the same pixel size and survive round trips.
local Convert = require("../src/Convert")

local function pixels(scale, offset, parent)
	return scale * parent + offset
end

for _, case in { { 0.5, 10, 400 }, { 0, 250, 800 }, { 0.25, -12, 333 }, { 1, 0, 1080 } } do
	local scale, offset, parent = case[1], case[2], case[3]
	local s, o = Convert.toScale(scale, offset, parent)
	assert(o == 0, "toScale clears offset")
	assert(math.abs(pixels(s, o, parent) - pixels(scale, offset, parent)) < 1e-3, "toScale keeps pixels")
	local s2, o2 = Convert.toOffset(s, o, parent)
	assert(s2 == 0, "toOffset clears scale")
	assert(o2 == math.round(pixels(scale, offset, parent)), "round trip keeps pixels")
end

-- whole-pixel offsets come back exactly.
local s137, o137 = Convert.toScale(0, 137, 640)
local s, o = Convert.toOffset(s137, o137, 640)
assert(s == 0 and o == 137, "137px round trip")

-- no tiny float noise in scale results.
local tidy = Convert.toScale(0, 120, 400)
assert(tidy == 0.3, `expected 0.3, got {tidy}`)

-- a zero-size parent leaves values alone instead of dividing by zero.
local zs, zo = Convert.toScale(0.5, 10, 0)
assert(zs == 0.5 and zo == 10, "zero parent toScale")
local os_, oo = Convert.toOffset(0.5, 10, 0)
assert(os_ == 0.5 and oo == 10, "zero parent toOffset")

print("convert: ok")
