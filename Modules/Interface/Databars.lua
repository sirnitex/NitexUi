-- NitexUI: Interface > Databars
--
-- One small bar in Blizzard's tooltip style with useful numbers:
--   FPS, latency, durability, gold, free bag slots, item level and clock.
--
-- How:
--   * Look: Blizzard's own NineSlicePanelTemplate with the "TooltipDefaultLayout" layout and
--     Blizzard's tooltip colours; text uses Blizzard's GameFontHighlightSmall.
--   * Layout: the bar is split into equal slots (one per shown element), sized and anchored
--     through ns.PP. Text is centred inside its slot; nothing is anchored to a FontString.
--   * Data is event driven: UPDATE_INVENTORY_DURABILITY, PLAYER_MONEY, BAG_UPDATE_DELAYED,
--     PLAYER_AVG_ITEM_LEVEL_UPDATE. Only events for shown elements are registered.
--   * FPS, latency and clock have no event, so ONE C_Timer ticker runs every second while at
--     least one of them is shown. Each tick only calls SetFormattedText when a value changed
--     (no new strings or tables per tick).
--   * Moving: in Blizzard's Edit Mode (EventRegistry "EditMode.Enter"/"EditMode.Exit") the bar
--     gets Blizzard's own Edit Mode highlight (NineSliceUtil + "editmode-actionbar-highlight"
--     atlases) and can be dragged. Outside Edit Mode: Shift + drag. Saved per profile.
--   * Size: width, height and font size from the options. The font is Blizzard's
--     GameFontHighlightSmall file and flags, only the size changes.
-- Off: no events, no ticker; the bar (created on first enable) is hidden.

local _, ns = ...
local M = ns:NewModule("InterfaceDatabars")
ns.InterfaceDatabars = M

local L, PP = ns.L, ns.PP

ns.defaults.interface = ns.defaults.interface or {}
ns.defaults.interface.databars = {
    fps = true,
    latency = true,
    durability = true,
    gold = true,
    bags = true,
    itemLevel = false,
    clock = false,
    width = 500,
    height = 22,
    fontSize = 12,
    editMode = true, -- show in Blizzard's Edit Mode and drag it there
    -- pos = { x, y }: TOPLEFT offsets from UIParent's TOPLEFT, set by dragging. nil = top centre.
}

local TICK = 1

-- Size limits (UI units). Max width = the screen width (UIParent), checked on every Apply.
M.MIN_WIDTH, M.MIN_HEIGHT, M.MAX_HEIGHT = 50, 10, 100
function M:MaxWidth() return floor(UIParent:GetWidth()) end

local floor, max, time = math.floor, math.max, time
local GetFramerate, GetNetStats, GetMoney = GetFramerate, GetNetStats, GetMoney
local GetInventoryItemDurability = GetInventoryItemDurability
local GetAverageItemLevel = GetAverageItemLevel
local GetContainerNumFreeSlots = C_Container and C_Container.GetContainerNumFreeSlots
local BreakUpLargeNumbers = BreakUpLargeNumbers
local IsShiftKeyDown = IsShiftKeyDown
local NUM_BAG_SLOTS = NUM_BAG_SLOTS or 4

-- Label colour = Blizzard's NORMAL_FONT_COLOR (gold), value = white (font colour).
local function Fmt(label, value)
    return "|cffffd100" .. label .. "|r " .. value
end

local FMT = {
    fps        = Fmt(L["DB_FPS"], "%d"),
    latency    = Fmt(L["DB_LATENCY"], "%d ms"),
    durability = Fmt(L["DB_DURABILITY"], "|cff%s%d%%|r"),
    gold       = "%s|TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0|t",
    bags       = Fmt(L["DB_BAGS"], "%d"),
    itemLevel  = Fmt(L["DB_ITEMLEVEL"], "%d"),
}
local DUR_GOOD, DUR_MID, DUR_LOW = "ffffff", "ffd100", "ff2020"

-- Fixed order on the bar.
local ORDER = { "fps", "latency", "durability", "gold", "bags", "itemLevel", "clock" }

local bar, ticker, overlay
local slots = {}   -- [key] = slot button
local last = {}    -- [key] = last shown value
local shown = {}   -- [key] = true while the element is on the bar
local moving = false
local inEditMode = false

---------------------------------------------------------------------------
-- Element updates
---------------------------------------------------------------------------
local function UpdateDurability()
    local lowest
    for slot = 1, 18 do
        local cur, maxDur = GetInventoryItemDurability(slot)
        if cur and maxDur and maxDur > 0 then
            local pct = cur / maxDur * 100
            if not lowest or pct < lowest then lowest = pct end
        end
    end
    lowest = floor(lowest or 100)
    if lowest == last.durability then return end
    last.durability = lowest
    local hex = lowest < 25 and DUR_LOW or lowest < 50 and DUR_MID or DUR_GOOD
    slots.durability.text:SetFormattedText(FMT.durability, hex, lowest)
end

local function UpdateGold()
    local gold = floor(GetMoney() / 10000)
    if gold == last.gold then return end
    last.gold = gold
    slots.gold.text:SetFormattedText(FMT.gold, BreakUpLargeNumbers(gold))
end

local function UpdateBags()
    if not GetContainerNumFreeSlots then return end
    local free = 0
    for bag = 0, NUM_BAG_SLOTS do
        free = free + (GetContainerNumFreeSlots(bag) or 0)
    end
    if free == last.bags then return end
    last.bags = free
    slots.bags.text:SetFormattedText(FMT.bags, free)
end

local function UpdateItemLevel()
    local _, equipped = GetAverageItemLevel()
    local ilvl = floor(equipped or 0)
    if ilvl == last.itemLevel then return end
    last.itemLevel = ilvl
    slots.itemLevel.text:SetFormattedText(FMT.itemLevel, ilvl)
end

local function UpdateClock()
    local minute = floor(time() / 60)
    if minute == last.clock then return end
    last.clock = minute
    if GameTime_GetLocalTime then
        slots.clock.text:SetText(GameTime_GetLocalTime(true)) -- follows Blizzard's 12/24 h setting
    else
        slots.clock.text:SetText(date("%H:%M"))
    end
end

-- Runs once per second, only while FPS, latency or clock is shown.
local function Tick()
    if shown.fps then
        local fps = floor(GetFramerate() + 0.5)
        if fps ~= last.fps then
            last.fps = fps
            slots.fps.text:SetFormattedText(FMT.fps, fps)
        end
    end
    if shown.latency then
        local _, _, _, world = GetNetStats()
        if world ~= last.latency then
            last.latency = world
            slots.latency.text:SetFormattedText(FMT.latency, world or 0)
        end
    end
    if shown.clock then UpdateClock() end
end

-- Event per element (elements without one are handled by the ticker).
local EVENTS = {
    durability = { "UPDATE_INVENTORY_DURABILITY", UpdateDurability },
    gold       = { "PLAYER_MONEY", UpdateGold },
    bags       = { "BAG_UPDATE_DELAYED", UpdateBags },
    itemLevel  = { "PLAYER_AVG_ITEM_LEVEL_UPDATE", UpdateItemLevel },
}
local UPDATE = {
    durability = UpdateDurability, gold = UpdateGold, bags = UpdateBags,
    itemLevel = UpdateItemLevel, clock = UpdateClock,
}

---------------------------------------------------------------------------
-- Clicks and tooltips (Blizzard's own panels)
---------------------------------------------------------------------------
local function OpenCharacter() if ToggleCharacter then ToggleCharacter("PaperDollFrame") end end
local function OpenBags() if ToggleAllBags then ToggleAllBags() end end
local function OpenCalendar() if ToggleCalendar then ToggleCalendar() end end

local CLICK = {
    durability = OpenCharacter, itemLevel = OpenCharacter,
    gold = OpenBags, bags = OpenBags, clock = OpenCalendar,
}

local function Tooltip_gold(tt)
    tt:AddLine(MONEY or L["DB_GOLD"])
    tt:AddLine(GetMoneyString(GetMoney(), true), 1, 1, 1)
end

local function Tooltip_latency(tt)
    local _, _, home, world = GetNetStats()
    tt:AddLine(L["DB_LATENCY"])
    tt:AddDoubleLine(L["DB_LATENCY_HOME"], (home or 0) .. " ms", nil, nil, nil, 1, 1, 1)
    tt:AddDoubleLine(L["DB_LATENCY_WORLD"], (world or 0) .. " ms", nil, nil, nil, 1, 1, 1)
end

local TOOLTIP = { gold = Tooltip_gold, latency = Tooltip_latency }

local function Slot_OnEnter(self)
    local fn = TOOLTIP[self.key]
    if not fn then return end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    fn(GameTooltip)
    GameTooltip:Show()
end

local function Slot_OnLeave() GameTooltip:Hide() end

local function Slot_OnClick(self)
    if moving or inEditMode or IsShiftKeyDown() then return end -- Shift / Edit Mode is for moving
    local fn = CLICK[self.key]
    if fn then fn() end
end

---------------------------------------------------------------------------
-- Moving (Shift + drag)
---------------------------------------------------------------------------
local function Place()
    local db = ns.db.interface.databars
    local x, y
    if db.pos then
        x, y = db.pos[1], db.pos[2]
    else
        x, y = floor((UIParent:GetWidth() - bar:GetWidth()) / 2 + 0.5), -4
    end
    PP.ClearPoints(bar)
    PP.Point(bar, "TOPLEFT", UIParent, "TOPLEFT", x, y)
end

local function DragStart()
    if not inEditMode and not IsShiftKeyDown() then return end
    moving = true
    bar:StartMoving()
end

local function DragStop()
    if not moving then return end
    bar:StopMovingOrSizing()
    bar:SetUserPlaced(false) -- our SavedVariables keep the spot, not the layout cache
    ns.db.interface.databars.pos = { bar:GetLeft(), bar:GetTop() - UIParent:GetTop() }
    Place()
    moving = false
end

---------------------------------------------------------------------------
-- Blizzard's Edit Mode
---------------------------------------------------------------------------
-- Same layout Blizzard uses for its own Edit Mode selection (EditModeSystemSelectionLayout
-- is local in Blizzard_EditMode, so the table is repeated here; the art is Blizzard's).
local EDITMODE_LAYOUT = {
    TopRightCorner    = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = 8, y = 8 },
    TopLeftCorner     = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = -8, y = 8 },
    BottomLeftCorner  = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = -8, y = -8 },
    BottomRightCorner = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = 8, y = -8 },
    TopEdge    = { atlas = "_%s-NineSlice-EdgeTop" },
    BottomEdge = { atlas = "_%s-NineSlice-EdgeBottom" },
    LeftEdge   = { atlas = "!%s-NineSlice-EdgeLeft" },
    RightEdge  = { atlas = "!%s-NineSlice-EdgeRight" },
    Center     = { atlas = "%s-NineSlice-Center", x = -8, y = 8, x1 = 8, y1 = -8 },
}

local function CreateOverlay()
    overlay = CreateFrame("Frame", nil, bar, "NineSliceCodeTemplate")
    overlay:SetAllPoints()
    overlay:SetFrameLevel(bar:GetFrameLevel() + 20)
    overlay:EnableMouse(true)
    overlay:RegisterForDrag("LeftButton")
    overlay:SetScript("OnDragStart", DragStart)
    overlay:SetScript("OnDragStop", DragStop)
    if NineSliceUtil and NineSliceUtil.ApplyLayout then
        NineSliceUtil.ApplyLayout(overlay, EDITMODE_LAYOUT, "editmode-actionbar-highlight")
    end
    local label = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("CENTER")
    label:SetText(L["DB_EDITMODE_LABEL"])
    overlay:Hide()
end

local function SetEditMode(on)
    inEditMode = on and true or false
    if not bar then return end
    if inEditMode and not overlay then CreateOverlay() end
    if overlay then overlay:SetShown(inEditMode and bar:IsShown()) end
    if not inEditMode and moving then DragStop() end
end

local function OnEditModeEnter() SetEditMode(true) end
local function OnEditModeExit()  SetEditMode(false) end

local editModeRegistered = false
local function WatchEditMode(on)
    if not EventRegistry then return end
    if on and not editModeRegistered then
        editModeRegistered = true
        EventRegistry:RegisterCallback("EditMode.Enter", OnEditModeEnter, M)
        EventRegistry:RegisterCallback("EditMode.Exit", OnEditModeExit, M)
    elseif not on and editModeRegistered then
        editModeRegistered = false
        EventRegistry:UnregisterCallback("EditMode.Enter", M)
        EventRegistry:UnregisterCallback("EditMode.Exit", M)
    end
    local active = on and EditModeManagerFrame and EditModeManagerFrame.IsEditModeActive
        and EditModeManagerFrame:IsEditModeActive()
    SetEditMode(active)
end

---------------------------------------------------------------------------
-- Frames (created the first time the module is turned on)
---------------------------------------------------------------------------
local function CreateSlot(key)
    local b = CreateFrame("Button", nil, bar)
    b.key = key
    b:RegisterForClicks("LeftButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnClick", Slot_OnClick)
    b:SetScript("OnEnter", Slot_OnEnter)
    b:SetScript("OnLeave", Slot_OnLeave)
    b:SetScript("OnDragStart", DragStart)
    b:SetScript("OnDragStop", DragStop)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER")
    fs:SetWordWrap(false)
    b.text = fs
    slots[key] = b
    return b
end

local function CreateBar()
    bar = CreateFrame("Frame", "NitexUIDatabar", UIParent)
    bar:SetFrameStrata("MEDIUM")
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", DragStart)
    bar:SetScript("OnDragStop", DragStop)

    -- Blizzard's tooltip look.
    local ns9 = CreateFrame("Frame", nil, bar, "NineSlicePanelTemplate")
    ns9:SetAllPoints()
    ns9:SetFrameLevel(bar:GetFrameLevel())
    if NineSliceUtil and NineSliceUtil.ApplyLayoutByName then
        NineSliceUtil.ApplyLayoutByName(ns9, "TooltipDefaultLayout")
    end
    local bg = TOOLTIP_DEFAULT_BACKGROUND_COLOR
    if bg and ns9.SetCenterColor then ns9:SetCenterColor(bg.r, bg.g, bg.b, 0.85) end
    local bc = TOOLTIP_DEFAULT_COLOR
    if bc and ns9.SetBorderColor then ns9:SetBorderColor(bc.r, bc.g, bc.b, 1) end
    bar.NineSlice = ns9

    for i = 1, #ORDER do CreateSlot(ORDER[i]) end
end

---------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------
local function StopAll()
    if ticker then ticker:Cancel(); ticker = nil end
    for _, e in next, EVENTS do ns:UnregisterEvent(e[1], M) end
    WatchEditMode(false)
    wipe(shown)
    wipe(last)
end

--- Bring the bar in line with the settings.
function M:Apply()
    StopAll()
    if not self.enabled then
        if bar then
            if moving then moving = false; bar:StopMovingOrSizing() end
            bar:Hide()
        end
        return
    end

    if not bar then CreateBar() end
    local db = ns.db.interface.databars

    local count = 0
    for i = 1, #ORDER do
        if db[ORDER[i]] then count = count + 1 end
    end
    if count == 0 then bar:Hide(); return end

    -- Exact width: equal slots, the first `extra` slots get one more unit.
    local barW = max(self.MIN_WIDTH, math.min(db.width, self:MaxWidth()))
    local barH = max(self.MIN_HEIGHT, math.min(db.height, self.MAX_HEIGHT))
    local slotW = floor(barW / count)
    local extra = barW - slotW * count
    PP.Size(bar, barW, barH)
    local fontFile, _, fontFlags = GameFontHighlightSmall:GetFont()

    local n, x = 0, 0
    for i = 1, #ORDER do
        local key = ORDER[i]
        local slot = slots[key]
        if db[key] then
            shown[key] = true
            local w = n < extra and slotW + 1 or slotW
            PP.Size(slot, w, barH)
            if fontFile then slot.text:SetFont(fontFile, db.fontSize, fontFlags or "") end
            PP.Point(slot, "TOPLEFT", bar, "TOPLEFT", x, 0)
            n, x = n + 1, x + w
            slot:Show()
            local e = EVENTS[key]
            if e then ns:RegisterEvent(e[1], self, e[2]) end
            last[key] = nil
            if UPDATE[key] then UPDATE[key]() end
        else
            slot:Hide()
        end
    end

    if shown.fps or shown.latency or shown.clock then
        Tick()
        ticker = C_Timer.NewTicker(TICK, Tick)
    end

    Place()
    bar:Show()
    WatchEditMode(db.editMode)
end

--- Options: forget the saved spot and put the bar back at the top centre.
function M:ResetPosition()
    ns.db.interface.databars.pos = nil
    if bar and self.enabled then Place() end
end

function M:OnEnable()  self:Apply() end
function M:OnDisable() self:Apply() end
