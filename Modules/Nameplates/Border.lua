-- NitexUI: Nameplates > Border
--
-- Replaces the border of Blizzard's OWN nameplate health bar with a thin 1px line.
--
-- How (Midnight nameplates):
--   * Blizzard's frame/background art (healthBar.bgTexture) and target highlight
--     (healthBar.selectedBorder) are set to alpha 0. A dark background replaces bgTexture.
--   * Four line textures are added around HealthBarsContainer, drawn just outside it.
--   * Line thickness = one physical pixel for the plate's scale at the moment the plate
--     appears or the target changes. Blizzard's own texture snapping is left ON here (unlike
--     the options window) because nameplates change scale with distance; snapping keeps the
--     line on the pixel grid without any per-frame work.
--   * Your target gets its own border colour (optional), so the target is still easy to see.
--
--   * The bar's fill texture is swapped for a flat one while ON (Blizzard's fill has rounded
--     corners, which leave gaps against a square border). The original is put back when OFF.
--   * The fill's soft mask and the "not target" overlay are hidden while ON (they made the
--     bar look lighter towards the edges).
--   * Lines are anchored to the health bar itself, so the fill meets the border exactly.
--
-- Retail only. Events (only while ON): NAME_PLATE_UNIT_ADDED, NAME_PLATE_UNIT_REMOVED, PLAYER_TARGET_CHANGED.
-- Forbidden nameplates (friendly plates in instances) are never touched.
-- When OFF: no events; every plate gets Blizzard's border back. Lines already created stay
-- hidden in memory until /reload (textures cannot be destroyed).

local _, ns = ...
if not ns.isRetail then return end -- Retail (Midnight) nameplates only

local M = ns:NewModule("NameplateBorder")
ns.NameplateBorder = M

local next = next
local UnitIsUnit = UnitIsUnit
local GetPixelToUIUnitFactor = PixelUtil.GetPixelToUIUnitFactor

ns.defaults.nameplates = ns.defaults.nameplates or {}
ns.defaults.nameplates.border = {
    color = { 0, 0, 0 },
    target = { enabled = true, color = { 1, 1, 1 } },
    background = 0.4, -- alpha of the dark background behind the bar
}

local db
local skins = setmetatable({}, { __mode = "k" }) -- [HealthBarsContainer] = skin data
local active = {}                                -- [unitToken] = skin data

---------------------------------------------------------------------------
-- Skin
---------------------------------------------------------------------------
local function GetContainer(plate)
    local uf = plate and plate.UnitFrame
    if not uf or uf:IsForbidden() then return nil end
    local c = uf.HealthBarsContainer
    if not c or not c.healthBar then return nil end
    return c
end

local function NewLine(c)
    local t = c:CreateTexture(nil, "OVERLAY", nil, 7)
    t:SetColorTexture(0, 0, 0, 1)
    return t
end

local FLAT = [[Interface\Buttons\WHITE8X8]]

local function CreateSkin(c)
    local s = { container = c, bar = c.healthBar }
    s.top, s.bottom, s.left, s.right = NewLine(c), NewLine(c), NewLine(c), NewLine(c)
    -- Background replacing Blizzard's bgTexture (drawn under the bar's fill).
    s.bg = c.healthBar:CreateTexture(nil, "BACKGROUND", nil, -8)
    s.bg:SetAllPoints(c.healthBar)
    skins[c] = s
    return s
end

--- Thickness = 1 physical pixel at the plate's current scale. Lines sit just outside the bar.
local function Layout(s)
    local c = s.bar
    local px = GetPixelToUIUnitFactor() / c:GetEffectiveScale()
    local top, bottom, left, right = s.top, s.bottom, s.left, s.right
    top:ClearAllPoints()
    top:SetPoint("BOTTOMLEFT", c, "TOPLEFT", -px, 0)
    top:SetPoint("BOTTOMRIGHT", c, "TOPRIGHT", px, 0)
    top:SetHeight(px)
    bottom:ClearAllPoints()
    bottom:SetPoint("TOPLEFT", c, "BOTTOMLEFT", -px, 0)
    bottom:SetPoint("TOPRIGHT", c, "BOTTOMRIGHT", px, 0)
    bottom:SetHeight(px)
    left:ClearAllPoints()
    left:SetPoint("TOPRIGHT", c, "TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMRIGHT", c, "BOTTOMLEFT", 0, 0)
    left:SetWidth(px)
    right:ClearAllPoints()
    right:SetPoint("TOPLEFT", c, "TOPRIGHT", 0, 0)
    right:SetPoint("BOTTOMLEFT", c, "BOTTOMRIGHT", 0, 0)
    right:SetWidth(px)
end

local function Colour(s, unit)
    local col = db.color
    if db.target.enabled and unit and UnitIsUnit(unit, "target") then col = db.target.color end
    local r, g, b = col[1], col[2], col[3]
    s.top:SetColorTexture(r, g, b, 1)
    s.bottom:SetColorTexture(r, g, b, 1)
    s.left:SetColorTexture(r, g, b, 1)
    s.right:SetColorTexture(r, g, b, 1)
end

-- Blizzard art that clashes with a square 1px border:
--   bgTexture / selectedBorder / container.border: the default frame and target highlight
--   MaskTexture: soft rounded mask on the fill (made the edges look lighter)
--   deselectedOverlay: shading drawn over plates that are not your target
local function SetBlizzard(s, shown)
    local a = shown and 1 or 0
    local bar = s.bar
    if bar.bgTexture then bar.bgTexture:SetAlpha(a) end
    if bar.selectedBorder then bar.selectedBorder:SetAlpha(a) end
    if bar.deselectedOverlay then bar.deselectedOverlay:SetAlpha(a) end
    if s.container.border then s.container.border:SetAlpha(a) end
    if bar.MaskTexture then bar.MaskTexture:SetShown(shown) end
end

-- Flat fill while ON; Blizzard's own fill (atlas or file) restored when OFF.
local function SetFlatFill(s, on)
    local tex = s.bar:GetStatusBarTexture()
    if not tex then return end
    if on then
        if not s.fillSaved then
            s.fillAtlas, s.fillFile = tex:GetAtlas(), tex:GetTexture()
            s.fillSaved = true
        end
        tex:SetTexture(FLAT)
    elseif s.fillSaved then
        if s.fillAtlas then tex:SetAtlas(s.fillAtlas) elseif s.fillFile then tex:SetTexture(s.fillFile) end
        s.fillSaved = nil
    end
end

local function ShowSkin(s, on)
    s.top:SetShown(on); s.bottom:SetShown(on); s.left:SetShown(on); s.right:SetShown(on)
    s.bg:SetShown(on)
    SetBlizzard(s, not on)
    SetFlatFill(s, on)
end

---------------------------------------------------------------------------
-- Plates
---------------------------------------------------------------------------
local function Attach(unit)
    local c = GetContainer(C_NamePlate.GetNamePlateForUnit(unit))
    if not c then return end
    local s = skins[c] or CreateSkin(c)
    s.bg:SetColorTexture(0, 0, 0, db.background)
    Layout(s)
    Colour(s, unit)
    ShowSkin(s, true)
    active[unit] = s
end

local function Detach(unit)
    local s = active[unit]
    if not s then return end
    active[unit] = nil
    ShowSkin(s, false)
end

function M:NAME_PLATE_UNIT_ADDED(_, unit)   Attach(unit) end
function M:NAME_PLATE_UNIT_REMOVED(_, unit) Detach(unit) end

-- The target's plate grows (selected scale): re-measure the pixel and recolour.
function M:PLAYER_TARGET_CHANGED()
    for unit, s in next, active do
        Layout(s)
        Colour(s, unit)
    end
end

--- Re-apply colours/background to every plate on screen (used by the options).
function M:Refresh()
    if not self.enabled then return end
    for unit, s in next, active do
        s.bg:SetColorTexture(0, 0, 0, db.background)
        Colour(s, unit)
    end
end

local EVENTS = { "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "PLAYER_TARGET_CHANGED" }

function M:OnEnable()
    db = ns.db.nameplates.border
    for i = 1, #EVENTS do ns:RegisterEvent(EVENTS[i], self, self[EVENTS[i]]) end
    local plates = C_NamePlate.GetNamePlates()
    for i = 1, #plates do
        local plate = plates[i]
        local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
        if unit then Attach(unit) end
    end
end

function M:OnDisable()
    for i = 1, #EVENTS do ns:UnregisterEvent(EVENTS[i], self) end
    for unit in next, active do Detach(unit) end
    wipe(active)
end
