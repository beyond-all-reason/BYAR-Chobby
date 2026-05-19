-- Mirrors bar-game/common/lib_spline.lua so the lobby and game produce
-- vertex-identical tessellations of the same anchor ring.

local SplineLib = {}

local DEFAULT_SEGMENTS = 12

local function clamp01(v)
	if v < 0 then return 0 end
	if v > 1 then return 1 end
	return v
end

-- tension=0 collapses to linear; tension=1 is full Catmull-Rom. Anchor points
-- lie on the curve at any tension because t=0/t=1 coincide for both.
local function sampleSegment(p0, p1, p2, p3, t, tension)
	local lx = p1[1] + (p2[1] - p1[1]) * t
	local lz = p1[2] + (p2[2] - p1[2]) * t
	if tension <= 0 then
		return lx, lz
	end

	local t2 = t * t
	local t3 = t2 * t
	local crX = 0.5 * ((2 * p1[1])
		+ (-p0[1] + p2[1]) * t
		+ (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2
		+ (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
	local crZ = 0.5 * ((2 * p1[2])
		+ (-p0[2] + p2[2]) * t
		+ (2 * p0[2] - 5 * p1[2] + 4 * p2[2] - p3[2]) * t2
		+ (-p0[2] + 3 * p1[2] - 3 * p2[2] + p3[2]) * t3)

	if tension >= 1 then
		return crX, crZ
	end
	return lx + (crX - lx) * tension, lz + (crZ - lz) * tension
end

-- Plain polygons (no strength on any anchor) emerge vertex-identical, so
-- callers can tessellate unconditionally without a branch.
function SplineLib.TessellateRing(anchors, opts)
	local n = #anchors
	if n < 2 then
		local out = {}
		for i = 1, n do
			out[i] = { anchors[i][1], anchors[i][2] }
		end
		return out
	end

	local segments = (opts and opts.segments) or DEFAULT_SEGMENTS
	if segments < 1 then segments = 1 end

	local out = {}
	for i = 1, n do
		local iPrev = ((i - 2) % n) + 1
		local iNext = (i % n) + 1
		local iNext2 = (iNext % n) + 1
		local p0 = anchors[iPrev]
		local p1 = anchors[i]
		local p2 = anchors[iNext]
		local p3 = anchors[iNext2]

		local s1 = p1[3]; if s1 == nil then s1 = 0 end
		local s2 = p2[3]; if s2 == nil then s2 = 0 end
		local edgeTension = clamp01((clamp01(s1) + clamp01(s2)) * 0.5)

		out[#out + 1] = { p1[1], p1[2] }
		if edgeTension > 0 and n >= 3 then
			for k = 1, segments - 1 do
				local x, z = sampleSegment(p0, p1, p2, p3, k / segments, edgeTension)
				out[#out + 1] = { x, z }
			end
		end
	end
	return out
end

return SplineLib
