-- NitexUI: Pixel perfect helpers
--
-- Goal: every 1px line is exactly one physical screen pixel, crisp, at any UI scale.
--
-- How:
--  * One physical pixel in a region's own units = PixelUtil.GetPixelToUIUnitFactor() / region:GetEffectiveScale()
--    (the factor is Blizzard's native 768 / physicalScreenHeight).
--  * Sizes and anchor offsets are rounded to whole pixels with Blizzard's native PixelUtil,
--    so frame edges always land on the pixel grid.
--  * Our textures have Blizzard's own texture snapping disabled, so they render exactly where we put them.
--  * Borders are four textures on an overlay frame, thickness = N physical pixels.
--  * Everything is recalculated ONLY on UI_SCALE_CHANGED / DISPLAY_SIZE_CHANGED. Never per frame.
--
-- Rules for layouts that must stay pixel perfect:
--  * Use PP.Size / PP.Width / PP.Height / PP.Point for every frame that has a border or fill.
--  * Avoid CENTER / LEFT / RIGHT anchors for bordered frames (they can land on half pixels). Use corners.
--  * Never anchor layout to a FontString (its height is not a whole pixel). Use fixed-height frames.

local _, ns = ...

local PixelUtil = PixelUtil
local GetNearestPixelSize = PixelUtil.GetNearestPixelSize
local next, unpack = next, unpack

local PP = { name = "PixelPerfect" }
ns.PP = PP

-- Weak tables: if a region is ever garbage collected, it drops out by itself.
local tracked = setmetatable({}, { __mode = "k" }) -- [region] = geometry data
local borders = setmetatable({}, { __mode = "k" }) -- [borderFrame] = true

---------------------------------------------------------------------------
-- Basics
---------------------------------------------------------------------------
--- Size of one physical pixel in this region's coordinate space.
function PP.Pixel(region)
    return PixelUtil.GetPixelToUIUnitFactor() / region:GetEffectiveScale()
end

--- Turn off Blizzard's texture snapping so the texture renders exactly on our pixel-aligned rect.
function PP.NoSnap(texture)
    texture:SetSnapToPixelGrid(false)
    texture:SetTexelSnappingBias(0)
end

---------------------------------------------------------------------------
-- Tracked geometry (re-applied when the scale changes)
---------------------------------------------------------------------------
-- The scale events are only registered once something actually uses PP
-- (i.e. the options window has been opened). Until then this file costs nothing.
local listening = false
local function Listen()
    if listening then return end
    listening = true
    ns:RegisterEvent("UI_SCALE_CHANGED", PP, PP.Resnap)
    ns:RegisterEvent("DISPLAY_SIZE_CHANGED", PP, PP.Resnap)
end

local function Data(region)
    local d = tracked[region]
    if not d then
        Listen()
        d = { points = {} }
        tracked[region] = d
    end
    return d
end

-- Size and position are applied separately: changing a size never touches anchors.
local function ApplySize(region, d)
    local es = region:GetEffectiveScale()
    if d.w then region:SetWidth(GetNearestPixelSize(d.w, es)) end
    if d.h then region:SetHeight(GetNearestPixelSize(d.h, es)) end
    if d.pxW or d.pxH then
        local px = PixelUtil.GetPixelToUIUnitFactor() / es
        if d.pxW then region:SetWidth(d.pxW * px) end
        if d.pxH then region:SetHeight(d.pxH * px) end
    end
end

-- Re-sets only the anchors PP knows about. SetPoint with the same point name replaces
-- that anchor, so anchors set elsewhere with plain SetPoint are left alone.
local function ApplyPoints(region, d)
    local es = region:GetEffectiveScale()
    local px = PixelUtil.GetPixelToUIUnitFactor() / es
    for point, p in next, d.points do
        local x, y
        if p.pixels then
            x, y = p.x * px, p.y * px
        else
            x, y = GetNearestPixelSize(p.x, es), GetNearestPixelSize(p.y, es)
        end
        region:SetPoint(point, p.rel, p.relPoint, x, y)
    end
end

local function Apply(region, d)
    ApplySize(region, d)
    ApplyPoints(region, d)
end

--- Width/height in UI units, rounded to whole physical pixels.
function PP.Size(region, w, h)
    local d = Data(region)
    h = h or w
    if d.w == w and d.h == h then return end -- unchanged (scale changes go through Resnap)
    d.w, d.h = w, h
    ApplySize(region, d)
end

function PP.Width(region, w)
    local d = Data(region)
    if d.w == w then return end
    d.w = w
    ApplySize(region, d)
end

function PP.Height(region, h)
    local d = Data(region)
    if d.h == h then return end
    d.h = h
    ApplySize(region, d)
end

--- Width/height as an exact number of physical pixels (for lines and borders).
function PP.PixelWidth(region, px)
    local d = Data(region)
    d.pxW = px
    ApplySize(region, d)
end

function PP.PixelHeight(region, px)
    local d = Data(region)
    d.pxH = px
    ApplySize(region, d)
end

local function SetPointData(region, point, rel, relPoint, x, y, pixels)
    local d = Data(region)
    local p = d.points[point]
    if not p then
        p = {}
        d.points[point] = p
    end
    p.rel = rel or region:GetParent()
    p.relPoint = relPoint or point
    p.x, p.y, p.pixels = x or 0, y or 0, pixels
    local es = region:GetEffectiveScale()
    if pixels then
        local px = PixelUtil.GetPixelToUIUnitFactor() / es
        region:SetPoint(point, p.rel, p.relPoint, p.x * px, p.y * px)
    else
        region:SetPoint(point, p.rel, p.relPoint, GetNearestPixelSize(p.x, es), GetNearestPixelSize(p.y, es))
    end
end

--- Anchor with offsets in UI units, rounded to whole pixels.
--- Calling again with the same `point` updates it in place (no new table).
function PP.Point(region, point, rel, relPoint, x, y)
    SetPointData(region, point, rel, relPoint, x, y, false)
end

--- Anchor with offsets given as exact physical pixels.
function PP.PointPx(region, point, rel, relPoint, xPx, yPx)
    SetPointData(region, point, rel, relPoint, xPx, yPx, true)
end

function PP.ClearPoints(region)
    local d = tracked[region]
    if d then wipe(d.points) end
    region:ClearAllPoints()
end

---------------------------------------------------------------------------
-- Borders
---------------------------------------------------------------------------
local function SnapBorder(b)
    local px = PP.Pixel(b) * b.size
    local e = b.edges
    e[1]:SetHeight(px)
    e[2]:SetHeight(px)
    e[3]:SetWidth(px)
    e[4]:SetWidth(px)
end

--- Add a crisp border of `size` physical pixels (default 1) drawn above the frame's children.
function PP.Border(frame, color, size)
    local b = CreateFrame("Frame", nil, frame)
    b:SetAllPoints()
    b:SetFrameLevel(frame:GetFrameLevel() + 10)
    b.size = size or 1

    local e = {}
    for i = 1, 4 do
        local t = b:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(unpack(color))
        PP.NoSnap(t)
        e[i] = t
    end
    -- top / bottom span full width; left / right sit between them (no overlapping corners).
    e[1]:SetPoint("TOPLEFT");     e[1]:SetPoint("TOPRIGHT")
    e[2]:SetPoint("BOTTOMLEFT");  e[2]:SetPoint("BOTTOMRIGHT")
    e[3]:SetPoint("TOPLEFT", e[1], "BOTTOMLEFT");   e[3]:SetPoint("BOTTOMLEFT", e[2], "TOPLEFT")
    e[4]:SetPoint("TOPRIGHT", e[1], "BOTTOMRIGHT"); e[4]:SetPoint("BOTTOMRIGHT", e[2], "TOPRIGHT")
    b.edges = e

    borders[b] = true
    Listen()
    SnapBorder(b)
    frame.ppBorder = b
    return b
end

function PP.SetBorderColor(frame, color)
    local r, g, bl, a = unpack(color)
    local e = frame.ppBorder.edges
    for i = 1, 4 do e[i]:SetColorTexture(r, g, bl, a) end
end

---------------------------------------------------------------------------
-- Re-snap everything when the scale or resolution changes
---------------------------------------------------------------------------
function PP.Resnap()
    for region, d in next, tracked do Apply(region, d) end
    for b in next, borders do SnapBorder(b) end
end

