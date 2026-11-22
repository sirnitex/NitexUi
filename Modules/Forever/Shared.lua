-- NitexUI: Forever – shared helpers (Forever client only)
--
-- Used by the Forever modules (Modules/Forever/*.lua). Nothing here registers events or
-- creates frames on its own; the helpers run only when a module that is turned on calls them.
--   F.Notify(text)                 Blizzard's raid warning frame (centre of the screen) + chat
--   F.MakeMovable(frame, getDB, y) Shift + drag; position saved as getDB().pos = { x, y }
--   F.Place(frame)                 put a movable frame at its saved spot (or top centre)
--   F.CreateIcon(parent, size)     icon button with a 1px border, count text and tooltip
--   F.LayoutRow(row, n, size, gap) lay out the first n icons of row.icons
--   F.GetAura(name)                player buff by (localized) name, call out of combat only

local _, ns = ...
if not ns.isForever then return end

local PP = ns.PP
local F = {}
ns.Forever = F

ns.defaults.forever = {}

local floor = math.floor
local IsShiftKeyDown, InCombatLockdown = IsShiftKeyDown, InCombatLockdown
local GetAuraDataBySpellName = C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName
local issecretvalue = issecretvalue or function() return false end

---------------------------------------------------------------------------
-- Messages
---------------------------------------------------------------------------
function F.Notify(text)
    if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo then
        RaidNotice_AddMessage(RaidWarningFrame, text, ChatTypeInfo["RAID_WARNING"])
    end
    ns:Print(text)
end

---------------------------------------------------------------------------
-- Moving (Shift + drag, same as Interface > Databars)
---------------------------------------------------------------------------
function F.Place(frame)
    local pos = frame.getDB().pos
    local x, y
    if pos then
        x, y = pos[1], pos[2]
    else
        x, y = floor((UIParent:GetWidth() - frame:GetWidth()) / 2 + 0.5), frame.defaultY
    end
    PP.ClearPoints(frame)
    PP.Point(frame, "TOPLEFT", UIParent, "TOPLEFT", x, y)
end

local function DragStart(self)
    local f = self.moveTarget or self
    if not IsShiftKeyDown() or InCombatLockdown() then return end
    f.moving = true
    f:StartMoving()
end

local function DragStop(self)
    local f = self.moveTarget or self
    if not f.moving then return end
    f:StopMovingOrSizing()
    f:SetUserPlaced(false) -- our SavedVariables keep the spot, not the layout cache
    f.getDB().pos = { floor(f:GetLeft() + 0.5), floor(f:GetTop() - UIParent:GetTop() + 0.5) }
    F.Place(f)
    f.moving = false
end

function F.MakeMovable(frame, getDB, defaultY)
    frame.getDB, frame.defaultY = getDB, defaultY
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", DragStart)
    frame:SetScript("OnDragStop", DragStop)
end

--- Child frames that take the mouse (icons) pass dragging on to the movable parent.
function F.PassDrag(child, target)
    child.moveTarget = target
    child:RegisterForDrag("LeftButton")
    child:SetScript("OnDragStart", DragStart)
    child:SetScript("OnDragStop", DragStop)
end

---------------------------------------------------------------------------
-- Icons
---------------------------------------------------------------------------
local BORDER = { 0, 0, 0, 1 }

local function Icon_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    if self.spellID then
        GameTooltip:SetSpellByID(self.spellID)
    elseif self.itemID then
        GameTooltip:SetItemByID(self.itemID)
    end
    if self.tipText then
        GameTooltip:AddLine(self.tipText, 1, 0.82, 0, true)
    end
    GameTooltip:Show()
end

local function Icon_OnLeave() GameTooltip:Hide() end

function F.CreateIcon(parent, size)
    local b = CreateFrame("Button", nil, parent)
    PP.Size(b, size, size)
    local tex = b:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.icon = tex
    PP.Border(b, BORDER)
    local count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -1, 1)
    b.count = count
    b:SetScript("OnEnter", Icon_OnEnter)
    b:SetScript("OnLeave", Icon_OnLeave)
    F.PassDrag(b, parent)
    return b
end

--- Places the first `n` icons of `row.icons` side by side and sizes the row to fit.
--- Skipped when nothing changed (the rows refresh on every bag/aura update).
function F.LayoutRow(row, n, size, gap)
    local icons = row.icons
    if row.layoutN == n and row.layoutSize == size and row.layoutGap == gap and row.layoutCount == #icons then return end
    row.layoutN, row.layoutSize, row.layoutGap, row.layoutCount = n, size, gap, #icons
    for i = 1, #icons do
        local b = icons[i]
        if i <= n then
            -- PP.Point with the same point name replaces the anchor: no ClearPoints needed.
            PP.Point(b, "TOPLEFT", row, "TOPLEFT", (i - 1) * (size + gap), 0)
            b:Show()
        else
            b:Hide()
        end
    end
    PP.Size(row, n > 0 and (n * size + (n - 1) * gap) or size, size)
end

---------------------------------------------------------------------------
-- Auras (called only out of combat; values are checked for secrets anyway)
---------------------------------------------------------------------------
--- Returns the aura data table, or nil. `name` is a localized spell name.
function F.GetAura(name)
    if not GetAuraDataBySpellName or not name then return nil end
    local aura = GetAuraDataBySpellName("player", name, "HELPFUL")
    if aura and issecretvalue(aura.expirationTime) then return nil end
    return aura
end
