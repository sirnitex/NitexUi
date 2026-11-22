-- NitexUI: Interface > Minimap
--
-- Minimap buttons are shown only while the mouse is over the minimap (or over one of the
-- buttons). Covers addon buttons (LibDBIcon and other named buttons on the minimap) and,
-- optionally, Blizzard's own minimap buttons.
--
-- How: buttons are faded with SetAlpha(0) / SetAlpha(1). Show/Hide is never touched, so
-- addons keep full control over their own buttons and nothing is taint-sensitive (alpha
-- may be changed in combat). Hover is detected with HookScript on OnEnter/OnLeave of the
-- minimap and each button – these only fire when the cursor crosses a frame edge.
-- No OnUpdate, no events. New addon buttons are picked up when the minimap is entered
-- (cheap child-count check) and once a few seconds after enabling.
--
-- When the module is OFF: nothing is created or hooked. Hooks cannot be removed once set,
-- so after turning it off they stay but return immediately.

local _, ns = ...
local M = ns:NewModule("InterfaceMinimap")
ns.InterfaceMinimap = M

ns.defaults.interface = ns.defaults.interface or {}
ns.defaults.interface.minimap = {
    mouseoverButtons = false,
    includeAddons = true,
    includeBlizzard = true,
}

-- Blizzard minimap buttons. Functions, so a frame missing in one client is skipped.
-- Info elements (clock, zone text, mail/crafting indicator) are left alone on purpose.
-- The zoom buttons already show only on mouseover by default.
local blizzard = {
    function() return AddonCompartmentFrame end,
    function() return ExpansionLandingPageMinimapButton end,
    function() return MinimapCluster and MinimapCluster.Tracking end,
    function() return GameTimeFrame end,
}

local Minimap = Minimap
local select, type, pairs = select, type, pairs

local managed = {}                               -- [frame] = true, faded with the minimap
local hooked  = setmetatable({}, { __mode = "k" }) -- frames that already carry our hooks
local isBlizzard = {}                            -- [frame] = true for the list above
local active = false
local shown = true
local lastChildCount = -1

local function SetShownAll(state)
    shown = state
    local a = state and 1 or 0
    for f in pairs(managed) do f:SetAlpha(a) end
end

-- Geometric checks, so moving from the minimap onto a button (or back) is not a "leave".
local function IsOverAny()
    if Minimap:IsMouseOver() then return true end
    for f in pairs(managed) do
        if f:IsVisible() and f:IsMouseOver() then return true end
    end
    return false
end

local ScanAddonButtons -- forward

local function OnEnter()
    if not active then return end
    ScanAddonButtons()
    if not shown then SetShownAll(true) end
end

local function OnLeave()
    if not active or not shown then return end
    if not IsOverAny() then SetShownAll(false) end
end

local function Manage(f)
    if managed[f] then return end
    managed[f] = true
    if not hooked[f] then
        hooked[f] = true
        f:HookScript("OnEnter", OnEnter)
        f:HookScript("OnLeave", OnLeave)
    end
    f:SetAlpha(shown and 1 or 0)
end

local function IsAddonButton(f)
    if isBlizzard[f] or f == Minimap.ZoomIn or f == Minimap.ZoomOut then return false end
    if f:GetObjectType() ~= "Button" then return false end
    local name = f:GetName()
    if type(name) ~= "string" then return false end
    -- Map pins (gathering/notes addons) are not buttons to hide.
    if name:find("Pin") then return false end
    return true
end

function ScanAddonButtons()
    if not ns.db.interface.minimap.includeAddons then return end
    local n = Minimap:GetNumChildren()
    if n == lastChildCount then return end
    lastChildCount = n
    for i = 1, n do
        local f = select(i, Minimap:GetChildren())
        if f and not managed[f] and IsAddonButton(f) then Manage(f) end
    end
end

--- Bring everything in line with the current settings.
function M:Apply()
    local db = ns.db.interface.minimap

    -- Restore every button to fully visible and forget them.
    for f in pairs(managed) do f:SetAlpha(1) end
    wipe(managed)
    wipe(isBlizzard)
    lastChildCount = -1
    shown = true
    active = self.enabled and db.mouseoverButtons or false
    if not active then return end

    for i = 1, #blizzard do
        local f = blizzard[i]()
        if f then isBlizzard[f] = true end
    end

    if not hooked[Minimap] then
        hooked[Minimap] = true
        Minimap:HookScript("OnEnter", OnEnter)
        Minimap:HookScript("OnLeave", OnLeave)
    end

    if db.includeBlizzard then
        for f in pairs(isBlizzard) do Manage(f) end
    end
    ScanAddonButtons()
    SetShownAll(IsOverAny())

    -- Catch addon buttons created a little after login.
    if not self.lateScan then
        self.lateScan = true
        C_Timer.After(3, function()
            self.lateScan = nil
            if active then
                ScanAddonButtons()
                if not IsOverAny() then SetShownAll(false) end
            end
        end)
    end
end

function M:OnEnable()
    self:Apply()
end

function M:OnDisable()
    -- self.enabled is already false here, so Apply restores everything.
    self:Apply()
end
