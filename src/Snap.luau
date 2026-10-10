-- where the island rests: four corners and four edge midpoints of the viewport.
-- everything works on top-left positions in pixels, so it has no Roblox dependencies.
export type Slot = "TopLeft" | "Top" | "TopRight" | "Left" | "Right" | "BottomLeft" | "Bottom" | "BottomRight"

-- each slot's anchor, as a fraction of the viewport and of the island. the island grows away
-- from it: a bottom slot grows upward and a right slot grows leftward.
local ANCHORS: { [Slot]: { x: number, y: number } } = {
	TopLeft = { x = 0, y = 0 },
	Top = { x = 0.5, y = 0 },
	TopRight = { x = 1, y = 0 },
	Left = { x = 0, y = 0.5 },
	Right = { x = 1, y = 0.5 },
	BottomLeft = { x = 0, y = 1 },
	Bottom = { x = 0.5, y = 1 },
	BottomRight = { x = 1, y = 1 },
}

local Snap = {
	MARGIN = 12,
	-- seconds of release velocity to carry forward when picking a slot, so a flick travels.
	PROJECTION = 0.15,
	DEFAULT = "Bottom" :: Slot,
	anchors = ANCHORS,
}

function Snap.isSlot(value: any): boolean
	return type(value) == "string" and ANCHORS[value :: Slot] ~= nil
end

-- the top-left position an island of size w x h sits at in this slot.
function Snap.topLeft(slot: Slot, w: number, h: number, vw: number, vh: number): (number, number)
	local anchor = ANCHORS[slot]
	local m = Snap.MARGIN
	local x = m + anchor.x * (vw - 2 * m) - anchor.x * w
	local y = m + anchor.y * (vh - 2 * m) - anchor.y * h
	return Snap.clamp(x, y, w, h, vw, vh)
end

-- keeps the island inside the viewport margins. if it's too big it hugs the top-left margin.
function Snap.clamp(x: number, y: number, w: number, h: number, vw: number, vh: number): (number, number)
	local m = Snap.MARGIN
	return math.max(m, math.min(x, vw - w - m)), math.max(m, math.min(y, vh - h - m))
end

-- the slot closest to where the island is heading. x, y is its top-left and vx, vy its velocity.
function Snap.nearest(x: number, y: number, vx: number, vy: number, w: number, h: number, vw: number, vh: number): Slot
	local cx = x + w / 2 + vx * Snap.PROJECTION
	local cy = y + h / 2 + vy * Snap.PROJECTION
	local best: Slot = Snap.DEFAULT
	local bestDistance = math.huge
	for slot, _ in ANCHORS do
		local sx, sy = Snap.topLeft(slot, w, h, vw, vh)
		local dx, dy = sx + w / 2 - cx, sy + h / 2 - cy
		local distance = dx * dx + dy * dy
		if distance < bestDistance then
			best, bestDistance = slot, distance
		end
	end
	return best
end

-- softens a position that's been dragged past the margins: it can stretch a little, but never
-- past the screen edge.
function Snap.rubberBand(x: number, y: number, w: number, h: number, vw: number, vh: number): (number, number)
	local cx, cy = Snap.clamp(x, y, w, h, vw, vh)
	local limit = Snap.MARGIN - 2
	local function soften(raw: number, clamped: number): number
		local over = raw - clamped
		return clamped + math.sign(over) * math.min(math.abs(over) * 0.3, limit)
	end
	return soften(x, cx), soften(y, cy)
end

return Snap
