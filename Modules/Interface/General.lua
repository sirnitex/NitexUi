-- NitexUI: Interface > General
--
-- Hides Blizzard interface elements (bag bar, micro menu).
--
-- How: the Blizzard frame is moved under a hidden parent frame. That hides it and all
-- its children with no hooks, no events and no per-frame work, and the original parent
-- is restored when the option or the module is turned off (no reload needed).
-- Changes are never made in combat; they wait until combat ends.
--
-- Queue status eye: while the micro menu is hidden, the eye (QueueStatusButton) can be
-- moved with Shift + drag. Blizzard's own StartMoving/StopMovingOrSizing does the moving;
-- the position is saved and put back from a hooksecurefunc on QueueStatusButton:UpdatePosition
-- (Blizzard re-anchors it when the micro menu layout changes). No events, no OnUpdate.
--
-- When the module is OFF: nothing is registered, hooked or created.

local _, ns = ...
local M = ns:NewModule("InterfaceGeneral")
ns.InterfaceGeneral = M

-- Defaults (merged into SavedVariables by Core/Database.lua)
ns.defaults.interface = ns.defaults.interface or {}
ns.defaults.interface.general = {
    hideBagBar = false,
    hideMicroMenu = false,
    moveQueueEye = true,  -- Shift + drag the queue eye while the micro menu is hidden
    -- queueEyePos = { point, relativePoint, x, y } relative to UIParent, set by dragging
}

-- Blizzard frames this module can hide. `get` is a function so a missing frame
-- (other client / future patch) is simply skipped.
local targets = {
    { key = "hideBagBar",    get = function() return BagsBar end },
    { key = "hideMicroMenu", get = function() return MicroMenu end }, -- buttons only; the queue (LFG) eye stays
}

local hiddenParent      -- created the first time something is hidden
local originalParent = {} -- [frame] = parent before we moved it

local function HideFrame(frame)
    if originalParent[frame] then return end
    if not hiddenParent then
        hiddenParent = CreateFrame("Frame")
        hiddenParent:Hide()
    end
    originalParent[frame] = frame:GetParent()
    frame:SetParent(hiddenParent)
end

local function RestoreFrame(frame)
    local parent = originalParent[frame]
    if not parent then return end
    frame:SetParent(parent)
    originalParent[frame] = nil
end

---------------------------------------------------------------------------
-- Queue status eye
---------------------------------------------------------------------------
local eyeActive, eyeHooked, moving = false, false, false
local blizz = {} -- Blizzard's last anchor for the eye: point, relativeTo, relativePoint, x, y

local function SaveBlizzardAnchor(eye)
    local p, rel, rp, x, y = eye:GetPoint(1)
    if p then blizz[1], blizz[2], blizz[3], blizz[4], blizz[5] = p, rel, rp, x, y end
end

local function PlaceEye(eye)
    local pos = ns.db.interface.general.queueEyePos
    if not pos then return end
    eye:ClearAllPoints()
    eye:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

-- Runs after Blizzard re-anchors the eye. Remember Blizzard's spot, then use ours.
local function OnUpdatePosition(eye)
    SaveBlizzardAnchor(eye)
    if eyeActive then PlaceEye(eye) end
end

local function OnDragStart(eye)
    if not eyeActive or not IsShiftKeyDown() then return end
    moving = true
    eye:StartMoving()
end

local function OnDragStop(eye)
    if not moving then return end
    moving = false
    eye:StopMovingOrSizing()
    eye:SetUserPlaced(false) -- our SavedVariables keep the spot, not the layout cache
    local p, _, rp, x, y = eye:GetPoint(1)
    if p then
        ns.db.interface.general.queueEyePos = { p, rp, x, y }
        PlaceEye(eye)
    end
end

local function ApplyEye(on)
    local eye = QueueStatusButton
    if not eye then return end
    if on == eyeActive then
        if on then PlaceEye(eye) end
        return
    end
    eyeActive = on
    if on then
        if not eyeHooked then
            eyeHooked = true
            if eye.UpdatePosition then hooksecurefunc(eye, "UpdatePosition", OnUpdatePosition) end
            eye:HookScript("OnDragStart", OnDragStart)
            eye:HookScript("OnDragStop", OnDragStop)
        end
        if not blizz[1] then SaveBlizzardAnchor(eye) end
        eye:SetMovable(true)
        eye:SetClampedToScreen(true)
        eye:RegisterForDrag("LeftButton")
        PlaceEye(eye)
    else
        if moving then moving = false; eye:StopMovingOrSizing() end
        eye:RegisterForDrag()
        eye:SetMovable(false)
        eye:SetClampedToScreen(false)
        if blizz[1] then
            eye:ClearAllPoints()
            eye:SetPoint(blizz[1], blizz[2], blizz[3], blizz[4], blizz[5])
        end
    end
end

--- Options: forget the saved spot and put the eye back where Blizzard had it.
function M:ResetQueueEye()
    ns.db.interface.general.queueEyePos = nil
    local eye = QueueStatusButton
    if eye and blizz[1] and not InCombatLockdown() then
        eye:ClearAllPoints()
        eye:SetPoint(blizz[1], blizz[2], blizz[3], blizz[4], blizz[5])
    end
end

function M:OnCombatEnded()
    ns:UnregisterEvent("PLAYER_REGEN_ENABLED", self)
    self:Apply()
end

--- Bring every target in line with the current settings.
function M:Apply()
    -- Off and nothing to restore: do nothing at all.
    if not self.enabled and not next(originalParent) and not eyeActive then return end
    if InCombatLockdown() then
        ns:RegisterEvent("PLAYER_REGEN_ENABLED", self, self.OnCombatEnded)
        return
    end
    local db = ns.db.interface.general
    for i = 1, #targets do
        local t = targets[i]
        local frame = t.get()
        if frame then
            if self.enabled and db[t.key] then
                HideFrame(frame)
            else
                RestoreFrame(frame)
            end
        end
    end
    ApplyEye(self.enabled and db.hideMicroMenu and db.moveQueueEye or false)
end

function M:OnEnable()
    self:Apply()
end

function M:OnDisable()
    -- self.enabled is already false here, so Apply restores everything.
    self:Apply()
end
