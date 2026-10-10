-- the island picks sensible slots, stays on screen, and grows away from its anchor.
local Snap = require("../src/Snap")

local VW, VH, W, H = 1500, 860, 160, 44
local M = Snap.MARGIN

local function slotAt(x, y, vx, vy)
	return Snap.nearest(x, y, vx or 0, vy or 0, W, H, VW, VH)
end

assert(slotAt(20, 20) == "TopLeft", "top-left corner")
assert(slotAt(VW - W - 5, VH - H - 5) == "BottomRight", "bottom-right corner")
assert(slotAt(VW / 2 - W / 2, VH - H - 40) == "Bottom", "bottom middle")
assert(slotAt(VW / 2 - W / 2, 30) == "Top", "top middle")
assert(slotAt(10, VH / 2) == "Left", "left middle")
assert(slotAt(VW - W, VH / 2) == "Right", "right middle")
-- a flick toward the right from the middle-top lands on the right corner.
assert(slotAt(VW / 2 - W / 2, 30, 6000, 0) == "TopRight", "flick right")
assert(slotAt(VW / 2 - W / 2, 30, 0, 0) == "Top", "no flick")

-- every slot sits inside the margins, for both the compact and an expanded size.
for slot in Snap.anchors do
	for _, size in { { W, H }, { 360, 340 } } do
		local x, y = Snap.topLeft(slot, size[1], size[2], VW, VH)
		assert(x >= M and y >= M, `{slot} past top-left`)
		assert(x + size[1] <= VW - M + 1e-9 and y + size[2] <= VH - M + 1e-9, `{slot} past bottom-right`)
	end
end

-- growing keeps the anchored edge still: bottom-right grows up and left.
local x1, y1 = Snap.topLeft("BottomRight", W, H, VW, VH)
local x2, y2 = Snap.topLeft("BottomRight", 360, 340, VW, VH)
assert(x1 + W == x2 + 360 and y1 + H == y2 + 340, "bottom-right keeps its corner")
local tx1, ty1 = Snap.topLeft("TopLeft", W, H, VW, VH)
local tx2, ty2 = Snap.topLeft("TopLeft", 360, 340, VW, VH)
assert(tx1 == tx2 and ty1 == ty2, "top-left keeps its corner")
local bx1 = Snap.topLeft("Bottom", W, H, VW, VH)
local bx2 = Snap.topLeft("Bottom", 360, 340, VW, VH)
assert(math.abs((bx1 + W / 2) - (bx2 + 180)) < 1e-9, "bottom stays centered")

-- an island bigger than the viewport hugs the top-left margin instead of going negative.
local cx, cy = Snap.clamp(0, 0, 2000, 1000, VW, VH)
assert(cx == M and cy == M, "oversized clamp")

-- dragging past an edge stretches a little but never leaves the screen.
local rx, ry = Snap.rubberBand(-500, VH + 500, W, H, VW, VH)
assert(rx >= 0 and rx < M, "rubber band left")
assert(ry + H <= VH and ry > VH - H - M, "rubber band bottom")
local ix, iy = Snap.rubberBand(300, 300, W, H, VW, VH)
assert(ix == 300 and iy == 300, "no rubber band inside the margins")

assert(Snap.isSlot("Bottom") and not Snap.isSlot("Middle") and not Snap.isSlot(4), "isSlot")

print("snap: ok")
