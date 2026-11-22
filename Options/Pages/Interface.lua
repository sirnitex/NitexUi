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
    p:Add(W.Toggle(p, L["OPT_MOVE_QUEUEEYE"], L["OPT_MOVE_QUEUEEYE_DESC"],
        function() return db.moveQueueEye end,
        function(v) db.moveQueueEye = v; M:Apply() end), 6)
    p:Add(W.Button(p, L["OPT_RESET_QUEUEEYE"], 160, function() M:ResetQueueEye() end), 8)

    p:Add(W.Paragraph(p, L["IFGENERAL_NOTE"]), 16)
    return p
end

---------------------------------------------------------------------------
-- Sub-tab: Minimap
---------------------------------------------------------------------------
local function BuildMinimap(parent)
    local M = ns.InterfaceMinimap
    local db = ns.db.interface.minimap
    local p = Options.NewPage(parent)

    Options.ModuleToggle(p, "InterfaceMinimap", L["OPT_IFMINIMAP_ENABLE"], L["OPT_IFMINIMAP_ENABLE_DESC"])

    p:Add(W.Header(p, L["SECTION_MINIMAP_BUTTONS"]), 14)
    p:Add(W.Toggle(p, L["OPT_MM_MOUSEOVER"], L["OPT_MM_MOUSEOVER_DESC"],
        function() return db.mouseoverButtons end,
        function(v) db.mouseoverButtons = v; M:Apply() end), 10)
    p:Add(W.Toggle(p, L["OPT_MM_ADDONS"], L["OPT_MM_ADDONS_DESC"],
        function() return db.includeAddons end,
        function(v) db.includeAddons = v; M:Apply() end), 6)
    p:Add(W.Toggle(p, L["OPT_MM_BLIZZARD"], L["OPT_MM_BLIZZARD_DESC"],
        function() return db.includeBlizzard end,
        function(v) db.includeBlizzard = v; M:Apply() end), 6)

    p:Add(W.Paragraph(p, L["IFMINIMAP_NOTE"]), 16)
    return p
end

---------------------------------------------------------------------------
-- Sub-tab: Character Panel
---------------------------------------------------------------------------
local function BuildCharacter(parent)
    local M = ns.CharacterPanel
    local db = ns.db.interface.character
    local p = Options.NewPage(parent)

    Options.ModuleToggle(p, "CharacterPanel", L["OPT_IFCHAR_ENABLE"], L["OPT_IFCHAR_ENABLE_DESC"])

    p:Add(W.Header(p, L["SECTION_CHAR_SHOW"]), 14)
    p:Add(W.Toggle(p, L["OPT_CHAR_ILVL"], L["OPT_CHAR_ILVL_DESC"],
        function() return db.itemLevel end,
        function(v) db.itemLevel = v; M:Apply() end), 10)
    p:Add(W.Toggle(p, L["OPT_CHAR_ENCHANTS"], L["OPT_CHAR_ENCHANTS_DESC"],
        function() return db.enchants end,
        function(v) db.enchants = v; M:Apply() end), 6)
    if ns.isRetail then
        p:Add(W.Toggle(p, L["OPT_CHAR_MISSING"], L["OPT_CHAR_MISSING_DESC"],
            function() return db.missingEnchant end,
            function(v) db.missingEnchant = v; M:Apply() end), 6)
    end
    p:Add(W.Toggle(p, L["OPT_CHAR_GEMS"], L["OPT_CHAR_GEMS_DESC"],
        function() return db.gems end,
        function(v) db.gems = v; M:Apply() end), 6)

    p:Add(W.Paragraph(p, L["IFCHAR_NOTE"]), 16)
    return p
end

---------------------------------------------------------------------------
-- Sub-tab: Tooltip
---------------------------------------------------------------------------
local function BuildTooltip(parent)
    local M = ns.InterfaceTooltip
    local db = ns.db.interface.tooltip
    local p = Options.NewPage(parent)

    Options.ModuleToggle(p, "InterfaceTooltip", L["OPT_IFTOOLTIP_ENABLE"], L["OPT_IFTOOLTIP_ENABLE_DESC"])

    p:Add(W.Header(p, L["SECTION_TOOLTIP"]), 14)
    p:Add(W.Toggle(p, L["OPT_TT_HIDEHEALTH"], L["OPT_TT_HIDEHEALTH_DESC"],
        function() return db.hideHealthBar end,
        function(v) db.hideHealthBar = v; M:Apply() end), 10)
    p:Add(W.Toggle(p, L["OPT_TT_CLASSNAMES"], L["OPT_TT_CLASSNAMES_DESC"],
        function() return db.classColorNames end,
        function(v) db.classColorNames = v; M:Apply() end), 6)

    p:Add(W.Paragraph(p, L["IFTOOLTIP_NOTE"]), 16)
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
        { key = "minimap", label = L["SUB_MINIMAP"], build = BuildMinimap },
        { key = "character", label = L["SUB_CHARACTER"], build = BuildCharacter },
        { key = "tooltip", label = L["SUB_TOOLTIP"], build = BuildTooltip },
    },
}
