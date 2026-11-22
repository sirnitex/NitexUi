-- NitexUI: Damage Meters
--
-- Tweaks Blizzard's own damage meter (Blizzard_DamageMeter). No replacement meter.
--   * Snap windows: drop a window next to another one and it takes the same width and
--     height and lines up edge to edge (left, right, above or below).
--   * Hide rank: "1. Name" becomes "Name".
--   * Short numbers: 1.5M instead of 1500K, via Blizzard's native AbbreviateNumbers
--     (accepts secret values, so it also works in combat).
--
-- How (12.1.5 UI source, Blizzard_DamageMeter):
--   * Every entry gets its text from entry:UpdateName() / entry:UpdateValue(). One
--     hooksecurefunc on each entry frame rewrites the text right after Blizzard sets it.
--     Entry frames are picked up when the scroll box acquires them (OnAcquiredFrame callback,
--     removed again when the module is turned off).
--   * Snapping: HookScript OnDragStop on each session window. Uses Blizzard's own
--     StartMoving/StopMovingOrSizing; we only adjust size and anchor once, on drop.
--   * Secret values (combat): no arithmetic or comparisons on them. If the percentage
--     cannot be computed (secret in combat), it is left out until the values are readable.
--
--   * Never call a Blizzard entry method from our hooks unless every field it compares or
--     calculates with is checked with issecretvalue first (see CanFormatName).
--
-- Cost: the same work Blizzard already does per entry update (one string format). No events
-- while on (except waiting for Blizzard_DamageMeter to load), no OnUpdate.
-- When OFF: nothing registered. Hooks cannot be removed; they return on their first line.

local _, ns = ...
local M = ns:NewModule("DamageMeters")
ns.DamageMeters = M

ns.defaults.damagemeters = {
    snap = true,
    hideRank = true,
    shortNumbers = true,
}

local pairs, abs = pairs, math.abs
local issecretvalue = issecretvalue or function() return false end
local AbbreviateNumbers = AbbreviateNumbers
local Round = Round

local SNAP_DISTANCE = 20 -- UI units: how close an edge must be to snap
local SNAP_GAP = 2       -- UI units between snapped windows

local db
local active = false
local dmHooked = false
local hookedEntry = setmetatable({}, { __mode = "k" })  -- [entry frame] = true (hooks are permanent, never hook twice)
local hookedWindow = setmetatable({}, { __mode = "k" }) -- [session window] = true
local registered = {}                                    -- [scrollBox] = true while on

---------------------------------------------------------------------------
-- Number formatting
---------------------------------------------------------------------------
local abbrevOptions -- { config = <cached Blizzard config> } or nil (= Blizzard's defaults)

local function Abbr(v)
    return AbbreviateNumbers(v, abbrevOptions)
end

-- "Has a value" without comparing a secret: a secret is always a real value.
local function Has(v) return issecretvalue(v) or v ~= nil end
-- A readable true (never true for a secret).
local function IsTrue(v) return not issecretvalue(v) and v == true end

local NUM = Enum and Enum.DamageMeterNumbers

-- Same rules as Blizzard's GetEntryValueText, with AbbreviateNumbers instead of
-- AbbreviateLargeNumbers.
local function ValueText(e)
    local dtype = e:GetNumberDisplayType()
    if not (dtype and NUM) then return nil end

    local value, vps = e.value, e.valuePerSecond
    local vpsPrimary = IsTrue(e.showsValuePerSecondAsPrimary)

    local main
    if Has(vps) and vpsPrimary then main = vps
    elseif Has(value) then main = value
    else main = 0 end

    if dtype == NUM.Minimal then
        return DAMAGE_METER_ENTRY_FORMAT_MINIMAL:format(Abbr(main))
    end

    local paren
    if Has(value) and vpsPrimary then paren = value
    elseif IsTrue(e.suppressValuePerSecond) then paren = nil
    elseif Has(vps) then paren = vps
    else paren = 0 end

    local pct
    if dtype == NUM.Complete then
        local total = e.sessionTotalValue
        if not issecretvalue(value) and not issecretvalue(total) then
            if value and total and total > 0 then pct = Round(value / total * 100) else pct = 0 end
        end
    end

    if paren ~= nil and pct then
        return DAMAGE_METER_ENTRY_FORMAT_COMPLETE:format(Abbr(main), Abbr(paren), pct)
    elseif pct then
        return DAMAGE_METER_ENTRY_FORMAT_COMPLETE_NO_PARENTHESIS:format(Abbr(main), pct)
    elseif paren ~= nil then
        return DAMAGE_METER_ENTRY_FORMAT_COMPACT:format(Abbr(main), Abbr(paren))
    end
    return DAMAGE_METER_ENTRY_FORMAT_MINIMAL:format(Abbr(main))
end

local function IsDeathRecap(e)
    local id = e.deathRecapID
    return issecretvalue(id) or (id ~= nil and id ~= 0)
end

---------------------------------------------------------------------------
-- Entry hooks
---------------------------------------------------------------------------
-- Blizzard's GetFormattedSourceNameText compares classification, isClassColorDesired,
-- sourceDisplayType and factionGroup. Those can be secret in combat, and comparing them from
-- our (tainted) hook errors. So it is only called when all four are readable; otherwise the
-- plain name is used (without the small elite/faction icon until the values are readable).
local function CanFormatName(e)
    return not (issecretvalue(e.classification) or issecretvalue(e.isClassColorDesired)
        or issecretvalue(e.sourceDisplayType) or issecretvalue(e.factionGroup))
end

local function OnUpdateName(e)
    if not (active and db.hideRank) then return end
    if not e.GetFormattedSourceNameText or IsDeathRecap(e) or not Has(e.sourceName) then return end
    if CanFormatName(e) then
        e:GetName():SetText(e:GetFormattedSourceNameText())
    else
        e:GetName():SetText(e.sourceName)
    end
end

local function OnUpdateValue(e)
    if not (active and db.shortNumbers) or IsDeathRecap(e) then return end
    local text = ValueText(e)
    if text then e:GetValue():SetText(text) end
end

local function Reformat(e)
    OnUpdateName(e)
    OnUpdateValue(e)
end

local function HookEntry(e)
    if not e or hookedEntry[e] then return end
    hookedEntry[e] = true
    hooksecurefunc(e, "UpdateName", OnUpdateName)
    hooksecurefunc(e, "UpdateValue", OnUpdateValue)
end

local function OnAcquired(_, frame)
    if not active then return end
    HookEntry(frame)
    Reformat(frame)
end

local function Register(scrollBox)
    if not scrollBox or registered[scrollBox] then return end
    registered[scrollBox] = true
    scrollBox:RegisterCallback(ScrollBoxListMixin.Event.OnAcquiredFrame, OnAcquired, M)
    scrollBox:ForEachFrame(HookEntry)
end

local function UnregisterAll()
    for scrollBox in pairs(registered) do
        scrollBox:UnregisterCallback(ScrollBoxListMixin.Event.OnAcquiredFrame, M)
    end
    wipe(registered)
end

---------------------------------------------------------------------------
-- Snapping
---------------------------------------------------------------------------
-- On drop: find the closest edge of another shown window within SNAP_DISTANCE, then take
-- that window's size and line up with it. All session windows share one parent (DamageMeter),
-- so their edges are in the same coordinate space.
local function Snap(w)
    local l, r, t, b = w:GetLeft(), w:GetRight(), w:GetTop(), w:GetBottom()
    if not l then return end
    local best, x, y, width, height = SNAP_DISTANCE

    for _, data in pairs(DamageMeter.windowDataList) do
        local o = data.sessionWindow
        if o and o ~= w and o:IsShown() then
            local ol, or_, ot, ob = o:GetLeft(), o:GetRight(), o:GetTop(), o:GetBottom()
            if ol then
                local ow, oh = or_ - ol, ot - ob
                if t > ob and b < ot then -- side by side
                    local d = abs(l - or_)
                    if d < best then best, x, y, width, height = d, or_ + SNAP_GAP, ot, ow, oh end
                    d = abs(r - ol)
                    if d < best then best, x, y, width, height = d, ol - SNAP_GAP - ow, ot, ow, oh end
                end
                if r > ol and l < or_ then -- stacked
                    local d = abs(t - ob)
                    if d < best then best, x, y, width, height = d, ol, ob - SNAP_GAP, ow, oh end
                    d = abs(b - ot)
                    if d < best then best, x, y, width, height = d, ol, ot + SNAP_GAP + oh, ow, oh end
                end
            end
        end
    end

    if not x then return end
    w:ClearAllPoints()
    w:SetSize(width, height)
    w:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
end

local function OnWindowDragStop(w)
    if not (active and db.snap) or InCombatLockdown() then return end
    if w == DamageMeter:GetPrimarySessionWindow() or not w:IsMovable() then return end
    Snap(w)
end

---------------------------------------------------------------------------
-- Windows
---------------------------------------------------------------------------
local function SetupWindow(w)
    if not w then return end
    if not hookedWindow[w] then
        hookedWindow[w] = true
        w:HookScript("OnDragStop", OnWindowDragStop)
    end
    Register(w:GetScrollBox())
    local source = w.GetSourceWindow and w:GetSourceWindow()
    if source then Register(source:GetScrollBox()) end
    HookEntry(w.GetLocalPlayerEntry and w:GetLocalPlayerEntry())
end

local function OnSetupSessionWindow(_, _, windowData)
    if active and windowData then SetupWindow(windowData.sessionWindow) end
end

-- Re-apply (or undo) the text on every entry that is on screen now.
local function RefreshEntries()
    for e in pairs(hookedEntry) do
        if active then
            Reformat(e)
        else
            if e.nameText then e:GetName():SetText(e.nameText) end -- Blizzard's cached name
            if not InCombatLockdown() then e:UpdateValue() end    -- values are readable out of combat
        end
    end
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------
function M:Apply()
    if not DamageMeter or not DamageMeter.windowDataList then return end
    db = ns.db.damagemeters
    active = self.enabled and true or false

    if active then
        if not abbrevOptions and CreateAbbreviateConfig and C_StringUtil and C_StringUtil.GetDefaultAbbreviationBreakpoints then
            local ok, config = pcall(CreateAbbreviateConfig, C_StringUtil.GetDefaultAbbreviationBreakpoints())
            if ok and config then abbrevOptions = { config = config } end
        end
        if not dmHooked then
            dmHooked = true
            hooksecurefunc(DamageMeter, "SetupSessionWindow", OnSetupSessionWindow)
        end
        for _, data in pairs(DamageMeter.windowDataList) do SetupWindow(data.sessionWindow) end
    else
        UnregisterAll()
    end
    RefreshEntries()
end

function M:OnAddonLoaded(_, name)
    if name ~= "Blizzard_DamageMeter" then return end
    ns:UnregisterEvent("ADDON_LOADED", self)
    self:Apply()
end

function M:OnEnable()
    if DamageMeter and DamageMeter.windowDataList then
        self:Apply()
    else
        ns:RegisterEvent("ADDON_LOADED", self, self.OnAddonLoaded)
    end
end

function M:OnDisable()
    ns:UnregisterEvent("ADDON_LOADED", self)
    self:Apply() -- removes the scroll box callbacks; the per-entry hooks return at once
end
