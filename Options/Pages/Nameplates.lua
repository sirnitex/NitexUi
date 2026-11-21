-- NitexUI: Options > Nameplates
-- Blizzard's own nameplates, tweaked. Each sub-module is its own sub-tab.

local _, ns = ...
local W, L, Options = ns.Widgets, ns.L, ns.Options

---------------------------------------------------------------------------
-- Sub-tab: Health Colors
---------------------------------------------------------------------------
local function BuildColors(parent)
    local M = ns.NameplateColors
    local db = ns.db.nameplates.colors
    local p = Options.NewPage(parent)

    local function Changed() M.UpdateAll(true) end

    Options.ModuleToggle(p, "NameplateColors", L["OPT_NPCOLORS_ENABLE"], L["OPT_NPCOLORS_ENABLE_DESC"])

    local left, right = Options.Columns(p, 14)

    -- Left: threat + quest
    left:Add(W.Header(p, L["SECTION_THREAT"]))
    left:Add(W.Toggle(p, L["OPT_THREAT"], nil,
        function() return db.threat.enabled end,
        function(v) db.threat.enabled = v; Changed() end), 8)
    left:Add(W.Toggle(p, L["OPT_THREAT_GROUPONLY"], nil,
        function() return db.threat.groupOnly end,
        function(v) db.threat.groupOnly = v; Changed() end), 2)
    for i = 1, #M.threatOrder do
        local key = M.threatOrder[i]
        local entry = db.threat[key]
        left:Add(W.ColorRow(p, L["THREAT_" .. key:upper()],
            function() return entry.enabled end,
            function(v) entry.enabled = v end,
            function() return entry.color end,
            Changed), i == 1 and 8 or 4)
    end

    left:Add(W.Header(p, L["SECTION_QUEST"]), 18)
    left:Add(W.ColorRow(p, L["OPT_QUEST"],
        function() return db.quest.enabled end,
        function(v) db.quest.enabled = v end,
        function() return db.quest.color end,
        Changed), 8)

    -- Right: enemy types
    right:Add(W.Header(p, L["SECTION_TYPES"]))
    for i = 1, #M.typeOrder do
        local key = M.typeOrder[i]
        local entry = db.types[key]
        right:Add(W.ColorRow(p, L["TYPE_" .. key:upper()],
            function() return entry.enabled end,
            function(v) entry.enabled = v end,
            function() return entry.color end,
            Changed), i == 1 and 8 or 4)
    end

    Options.EndColumns(p, left, right)
    p:Add(W.Paragraph(p, L["NPCOLORS_NOTE"]), 18)
    return p
end

---------------------------------------------------------------------------
-- Register
---------------------------------------------------------------------------
Options:RegisterPage{
    key = "nameplates",
    label = L["PAGE_NAMEPLATES"],
    desc = L["PAGE_NAMEPLATES_DESC"],
    order = 40,
    subtabs = {
        { key = "colors", label = L["SUB_HEALTHCOLORS"], build = BuildColors },
    },
}
