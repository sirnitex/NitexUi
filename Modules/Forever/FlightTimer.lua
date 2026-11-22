-- NitexUI: Forever > Flight Timer (Forever client only)
--
-- A bar in Blizzard's own cast bar / mirror timer art (ui-castingbar-* atlases) that counts
-- down while you are on a flight path, with the destination underneath.
--
-- The game has no API for flight durations, so each route is learned the first time you fly
-- it: the time from take-off to landing is saved per route ("From|To") in NitexUIDB.flightTimes
-- (account-wide, kept when the module is turned off; "Forget" button on the options page).
-- Routes you have not flown yet show the time so far instead of a countdown.
--
-- Events: TAXIMAP_OPENED (start point) while on; PLAYER_CONTROL_LOST / PLAYER_CONTROL_GAINED
-- only from the moment you pick a destination until you land; PLAYER_ENTERING_WORLD (resume
-- after /reload in the air). Hooks: TakeTaxiNode, TaxiRequestEarlyLanding, the taxi map
-- tooltips (TaxiNodeOnButtonEnter, FlightMap_FlightPointPinMixin.OnMouseEnter); they return
-- at once when the module is off. No OnUpdate: one C_Timer ticker (1 s) runs only in the air;
-- the bar glides between ticks with the status bar's own interpolation.
--
-- When the module is OFF: nothing is registered, no ticker, no bar.

local _, ns = ...
if not ns.isForever then return end

local M = ns:NewModule("ForeverFlight")
ns.ForeverFlight = M
local L, PP, F = ns.L, ns.PP, ns.Forever

ns.defaults.forever.flight = {
    tooltip = true,  -- flight time in the taxi map tooltips
    unknown = true,  -- show the bar on routes that are not learned yet
}

local GetTime, floor, format = GetTime, math.floor, format
local UnitOnTaxi = UnitOnTaxi
local NumTaxiNodes, TaxiNodeName, TaxiNodeGetType = NumTaxiNodes, TaxiNodeName, TaxiNodeGetType
local INTERP = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut
local ATLAS_KNOWN = "ui-castingbar-filling-standard"
local ATLAS_LEARN = "ui-castingbar-filling-channel"

local function DB() return ns.db.forever.flight end

---------------------------------------------------------------------------
-- Learned times
---------------------------------------------------------------------------
local function GetTimeFor(from, to)
    local t = ns.root.flightTimes
    return t and from and to and t[from .. "|" .. to]
end

local function SaveTime(from, to, seconds)
    ns.root.flightTimes = ns.root.flightTimes or {}
    ns.root.flightTimes[from .. "|" .. to] = seconds
end

function M:ForgetTimes()
    ns.root.flightTimes = nil
end

function M:NumLearned()
    local n = 0
    local t = ns.root.flightTimes
    if t then for _ in next, t do n = n + 1 end end
    return n
end

---------------------------------------------------------------------------
-- Bar (created the first time it is needed)
---------------------------------------------------------------------------
local bar, ticker
local flight -- { from, to, start, duration, aborted } while in the air
local EndFlight -- defined below

local function CreateBar()
    bar = CreateFrame("Frame", "NitexUIFlightTimer", UIParent)
    bar:SetFrameStrata("MEDIUM")
    PP.Size(bar, 206, 32)
    F.MakeMovable(bar, DB, -160)

    -- Text box under the bar (Blizzard's mirror timer layout)
    local sb = CreateFrame("StatusBar", nil, bar)
    PP.Size(sb, 195, 13)
    PP.Point(sb, "TOP", bar, "TOP", 0, -2)
    sb:SetMinMaxValues(0, 1)
    sb:SetStatusBarTexture(ATLAS_KNOWN)
    bar.sb = sb

    local box = bar:CreateTexture(nil, "BACKGROUND")
    box:SetAtlas("ui-castingbar-textbox")
    box:SetPoint("TOPLEFT", sb, "TOPLEFT", 0, 0)
    box:SetPoint("BOTTOMRIGHT", sb, "BOTTOMRIGHT", 0, -14)

    local bg = sb:CreateTexture(nil, "BACKGROUND")
    bg:SetAtlas("ui-castingbar-background")
    bg:SetPoint("TOPLEFT", sb, "TOPLEFT", -1, 1)
    bg:SetPoint("BOTTOMRIGHT", sb, "BOTTOMRIGHT", 1, -1)

    local over = CreateFrame("Frame", nil, bar)
    over:SetAllPoints()
    over:SetFrameLevel(sb:GetFrameLevel() + 2)
    local border = over:CreateTexture(nil, "OVERLAY")
    border:SetAtlas("ui-castingbar-frame")
    border:SetPoint("TOPLEFT", sb, "TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", sb, "BOTTOMRIGHT", 2, -2)

    local time = over:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    time:SetPoint("RIGHT", sb, "RIGHT", -4, 0)
    bar.time = time

    local dest = over:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dest:SetPoint("TOPLEFT", sb, "BOTTOMLEFT", 4, 0)
    dest:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -4, 2)
    dest:SetWordWrap(false)
    bar.dest = dest

    bar:Hide()
    F.Place(bar)
end

local function UpdateBar()
    if not flight then return end
    local elapsed = GetTime() - flight.start
    -- Landed without PLAYER_CONTROL_GAINED catching it (UnitOnTaxi was still true then).
    if not flight.preview and elapsed > 3 and not UnitOnTaxi("player") then
        EndFlight(true)
        return
    end
    local d = flight.duration
    if d then
        local left = d - elapsed
        if left < 0 then left = 0 end
        bar.sb:SetValue(left / d, INTERP)
        bar.time:SetFormattedText("%d:%02d", floor(left / 60), floor(left % 60))
    else
        bar.time:SetFormattedText("+%d:%02d", floor(elapsed / 60), floor(elapsed % 60))
    end
end

local function ShowBar()
    if not flight.duration and not DB().unknown then return end
    if not bar then CreateBar() end
    bar.sb:SetStatusBarTexture(flight.duration and ATLAS_KNOWN or ATLAS_LEARN)
    bar.sb:SetValue(1)
    if flight.duration then
        bar.dest:SetText(flight.to)
    else
        bar.dest:SetFormattedText(L["FLIGHT_LEARNING"], flight.to)
    end
    UpdateBar()
    bar:Show()
    if ticker then ticker:Cancel() end
    ticker = C_Timer.NewTicker(1, UpdateBar)
end

local function HideBar()
    if ticker then ticker:Cancel(); ticker = nil end
    if bar then bar:Hide() end
end

--- Test bar for placing it (Shift + drag). Hides itself after 20 seconds.
local previewId = 0

function M:Preview()
    if not self.enabled or (flight and not flight.preview) then return end
    previewId = previewId + 1
    local id = previewId
    flight = { from = "", to = L["FLIGHT_PREVIEW"], start = GetTime(), duration = 20, preview = true }
    ShowBar()
    C_Timer.After(20, function()
        if flight and flight.preview and id == previewId then flight = nil; HideBar() end
    end)
end

function M:ResetPosition()
    DB().pos = nil
    if bar then F.Place(bar) end
end

---------------------------------------------------------------------------
-- Flight tracking
---------------------------------------------------------------------------
local from -- name of the node the taxi map was opened at

local function FindCurrentNode()
    for i = 1, NumTaxiNodes() do
        if TaxiNodeGetType(i) == "CURRENT" then return TaxiNodeName(i) end
    end
end

local function Unwatch()
    ns:UnregisterEvent("PLAYER_CONTROL_LOST", M)
    ns:UnregisterEvent("PLAYER_CONTROL_GAINED", M)
end

function EndFlight(landed) -- local, declared above
    if flight and flight.start and landed and not flight.aborted and not flight.preview then
        local seconds = floor(GetTime() - flight.start + 0.5)
        if seconds > 5 then SaveTime(flight.from, flight.to, seconds) end
    end
    flight = nil
    ns.charDB.flight = nil
    Unwatch()
    HideBar()
end

local function StartFlight(start)
    flight.start = start
    flight.duration = GetTimeFor(flight.from, flight.to)
    ns.charDB.flight = { from = flight.from, to = flight.to, start = start }
    ShowBar()
end

function M:OnControlLost()
    if not flight or flight.start then return end
    StartFlight(GetTime())
    -- Not on a taxi after all (another loss of control): drop it quietly.
    C_Timer.After(2, function()
        if flight and flight.start and not UnitOnTaxi("player") then EndFlight(false) end
    end)
end

function M:OnControlGained()
    if flight and flight.start and not UnitOnTaxi("player") then EndFlight(true) end
end

local function OnTakeTaxiNode(index)
    if not M.enabled or not from then return end
    local to = TaxiNodeName(index)
    if not to or to == "" or to == from then return end
    if flight and flight.preview then HideBar() end
    flight = { from = from, to = to }
    ns:RegisterEvent("PLAYER_CONTROL_LOST", M, M.OnControlLost)
    ns:RegisterEvent("PLAYER_CONTROL_GAINED", M, M.OnControlGained)
    -- Nothing happened (not enough money, map closed): stop waiting.
    C_Timer.After(10, function()
        if flight and not flight.start then flight = nil; Unwatch() end
    end)
end

local function OnEarlyLanding()
    if M.enabled and flight then flight.aborted = true end
end

function M:OnEnteringWorld()
    local saved = ns.charDB.flight
    if flight and flight.start then
        if not UnitOnTaxi("player") then EndFlight(false) end
        return
    end
    if saved and UnitOnTaxi("player") and saved.start <= GetTime() then
        flight = { from = saved.from, to = saved.to }
        ns:RegisterEvent("PLAYER_CONTROL_GAINED", M, M.OnControlGained)
        StartFlight(saved.start)
    else
        ns.charDB.flight = nil
    end
end

---------------------------------------------------------------------------
-- Taxi map tooltips
---------------------------------------------------------------------------
local function AddTimeLine(slotIndex)
    if not M.enabled or not DB().tooltip or not from then return end
    local seconds = GetTimeFor(from, TaxiNodeName(slotIndex))
    if seconds then
        GameTooltip:AddLine(format(L["FLIGHT_TOOLTIP"], floor(seconds / 60), seconds % 60), 1, 1, 1)
    else
        GameTooltip:AddLine(L["FLIGHT_TOOLTIP_UNKNOWN"], 0.6, 0.6, 0.6)
    end
    GameTooltip:Show()
end

local function OnTaxiButtonEnter(button)
    local index = button:GetID()
    if TaxiNodeGetType(index) == "REACHABLE" then AddTimeLine(index) end
end

local function OnPinEnter(pin)
    local data = pin.taxiNodeData
    if data and Enum.FlightPathState and data.state == Enum.FlightPathState.Reachable then
        AddTimeLine(data.slotIndex)
    end
end

local hooked, pinsHooked = false, false

local function HookFlightMap()
    if pinsHooked or not FlightMap_FlightPointPinMixin then return end
    pinsHooked = true
    -- New pins copy the hooked method from the mixin ...
    hooksecurefunc(FlightMap_FlightPointPinMixin, "OnMouseEnter", OnPinEnter)
    -- ... pins that already exist get their own hook.
    if FlightMapFrame and FlightMapFrame.EnumeratePinsByTemplate then
        for pin in FlightMapFrame:EnumeratePinsByTemplate("FlightMap_FlightPointPinTemplate") do
            hooksecurefunc(pin, "OnMouseEnter", OnPinEnter)
        end
    end
end

local function InstallHooks()
    if hooked then return end
    hooked = true
    hooksecurefunc("TakeTaxiNode", OnTakeTaxiNode)
    if TaxiRequestEarlyLanding then hooksecurefunc("TaxiRequestEarlyLanding", OnEarlyLanding) end
    if TaxiNodeOnButtonEnter then hooksecurefunc("TaxiNodeOnButtonEnter", OnTaxiButtonEnter) end
end

function M:OnTaxiMapOpened()
    from = FindCurrentNode()
    HookFlightMap()
end

function M:OnAddonLoaded(_, name)
    if name == "Blizzard_FlightMap" then
        HookFlightMap()
        ns:UnregisterEvent("ADDON_LOADED", self)
    end
end

---------------------------------------------------------------------------
-- Module
---------------------------------------------------------------------------
function M:OnEnable()
    InstallHooks()
    ns:RegisterEvent("TAXIMAP_OPENED", self, self.OnTaxiMapOpened)
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", self, self.OnEnteringWorld)
    if not pinsHooked then
        if C_AddOns.IsAddOnLoaded("Blizzard_FlightMap") then
            HookFlightMap()
        else
            ns:RegisterEvent("ADDON_LOADED", self, self.OnAddonLoaded)
        end
    end
    if UnitOnTaxi("player") then self:OnEnteringWorld() end
end

function M:OnDisable()
    ns:UnregisterEvent("TAXIMAP_OPENED", self)
    ns:UnregisterEvent("PLAYER_ENTERING_WORLD", self)
    ns:UnregisterEvent("ADDON_LOADED", self)
    Unwatch()
    flight, from = nil, nil
    ns.charDB.flight = nil
    HideBar()
end
