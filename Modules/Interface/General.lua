-- NitexUI: Interface > General
--
-- Hides Blizzard interface elements (bag bar, micro menu).
--
-- How: the Blizzard frame is moved under a hidden parent frame. That hides it and all
-- its children with no hooks, no events and no per-frame work, and the original parent
-- is restored when the option or the module is turned off (no reload needed).
-- Changes are never made in combat; they wait until combat ends.
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

function M:OnCombatEnded()
    ns:UnregisterEvent("PLAYER_REGEN_ENABLED", self)
    self:Apply()
end

--- Bring every target in line with the current settings.
function M:Apply()
    -- Off and nothing to restore: do nothing at all.
    if not self.enabled and not next(originalParent) then return end
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
end

function M:OnEnable()
    self:Apply()
end

function M:OnDisable()
    -- self.enabled is already false here, so Apply restores everything.
    self:Apply()
end
