-- Scale and Offset conversion for one UDim axis, given the parent's size in pixels on that axis.
local Convert = {}

-- removes float noise like 0.30000000000000004 without losing useful precision.
local function tidy(value: number): number
	return math.round(value * 1e6) / 1e6
end

-- the same pixel size expressed entirely as Scale.
function Convert.toScale(scale: number, offset: number, parent: number): (number, number)
	if parent <= 0 then
		return scale, offset
	end
	return tidy((scale * parent + offset) / parent), 0
end

-- the same pixel size expressed entirely as Offset, rounded to whole pixels.
function Convert.toOffset(scale: number, offset: number, parent: number): (number, number)
	if parent <= 0 then
		return scale, offset
	end
	return 0, math.round(scale * parent + offset)
end

export type Mode = "scale" | "offset"

function Convert.udim(value: UDim, parent: number, mode: Mode): UDim
	local scale, offset = (if mode == "scale" then Convert.toScale else Convert.toOffset)(value.Scale, value.Offset, parent)
	return UDim.new(scale, offset)
end

-- converts the chosen axes of a UDim2. parent is the parent's content size in pixels.
function Convert.udim2(value: UDim2, parent: Vector2, mode: Mode, x: boolean, y: boolean): UDim2
	return UDim2.new(
		if x then Convert.udim(value.X, parent.X, mode) else value.X,
		if y then Convert.udim(value.Y, parent.Y, mode) else value.Y
	)
end

return Convert
