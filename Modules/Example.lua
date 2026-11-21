-- NitexUI: Example module
-- Copy this file to start a new module, and add it to NitexUI.toc.

local _, ns = ...
local M = ns:NewModule("Example")

function M:OnInitialize()
    -- Runs on ADDON_LOADED, after SavedVariables are available.
    ns.db.profile.example = ns.db.profile.example or { greetings = 0 }
end

function M:OnEnable()
    -- Runs on PLAYER_LOGIN.
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", self, self.OnEnteringWorld)
end

function M:OnEnteringWorld(_, isInitialLogin, isReloadingUi)
    local data = ns.db.profile.example
    data.greetings = data.greetings + 1
    ns:Debug("Example module: entering world", isInitialLogin, isReloadingUi, "count:", data.greetings)
end
