-- NitexUI: module template (NOT loaded – not listed in NitexUI.toc)
-- Copy this file to start a new module, rename it, and add it to NitexUI.toc.
-- Modules are OFF by default. Give the module an on/off switch on its options page
-- with Options.ModuleToggle(page, "ModuleName", label, desc).

local _, ns = ...
local M = ns:NewModule("Template")

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

function M:OnDisable()
    -- Runs when the user switches the module off. Undo what OnEnable did.
    ns:UnregisterEvent("PLAYER_ENTERING_WORLD", self)
end
