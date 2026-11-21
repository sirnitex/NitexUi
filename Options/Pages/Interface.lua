-- NitexUI: Options > Interface
-- Changes to Blizzard's interface. Each sub-module is its own sub-tab.

local _, ns = ...
local W, L, Options = ns.Widgets, ns.L, ns.Options

---------------------------------------------------------------------------
-- Sub-tab: General
---------------------------------------------------------------------------
local function BuildGeneral(parent)
    local M = ns.InterfaceGeneral
    local db = ns.db.interface.general
    local p = Options.NewPage(parent)

    Options.ModuleToggle(p, "InterfaceGeneral", L["OPT_IFGENERAL_ENABLE"], L["OPT_IFGENERAL_ENABLE_DESC"])

    p:Add(W.Header(p, L["SECTION_HIDE_BLIZZARD"]), 14)
    p:Add(W.Toggle(p, L["OPT_HIDE_BAGBAR"], L["OPT_HIDE_BAGBAR_DESC"],
        function() return db.hideBagBar end,
        function(v) db.hideBagBar = v; M:Apply() end), 10)
    p:Add(W.Toggle(p, L["OPT_HIDE_MICROMENU"], L["OPT_HIDE_MICROMENU_DESC"],
        function() return db.hideMicroMenu end,
        function(v) db.hideMicroMenu = v; M:Apply() end), 6)

    p:Add(W.Paragraph(p, L["IFGENERAL_NOTE"]), 16)
    return p
end

---------------------------------------------------------------------------
-- Register
---------------------------------------------------------------------------
Options:RegisterPage{
    key = "interface",
    label = L["PAGE_INTERFACE"],
    desc = L["PAGE_INTERFACE_DESC"],
    order = 30,
    subtabs = {
        { key = "general", label = L["SUB_GENERAL"], build = BuildGeneral },
    },
}
