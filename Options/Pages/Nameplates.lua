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

    -- Right: tapped (Forever only) + enemy types
    if ns.isForever then
        right:Add(W.Header(p, L["SECTION_TAPPED"]))
        right:Add(W.ColorRow(p, L["OPT_TAPPED"],
            function() return db.tapped.enabled end,
            function(v) db.tapped.enabled = v end,
            function() return db.tapped.color end,
            Changed), 8)
        right:Add(W.Header(p, L["SECTION_TYPES"]), 18)
    else
        right:Add(W.Header(p, L["SECTION_TYPES"]))
    end
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
    p:Add(W.Paragraph(p, ns.isForever and L["NPCOLORS_NOTE_FOREVER"] or L["NPCOLORS_NOTE"]), 18)

    -- Threat % (own section, below everything else)
    local t = db.threat
    p:Add(W.Header(p, L["SECTION_THREAT_PERCENT"]), 18)
    p:Add(W.Toggle(p, L["OPT_THREAT_PERCENT"], L["OPT_THREAT_PERCENT_DESC"],
        function() return t.percent end,
        function(v) t.percent = v; Changed() end), 8)
    return p
end

---------------------------------------------------------------------------
-- Sub-tab: Border
---------------------------------------------------------------------------
local function BuildBorder(parent)
    local M = ns.NameplateBorder
    local db = ns.db.nameplates.border
    local p = Options.NewPage(parent)
    local function Changed() M:Refresh() end

    Options.ModuleToggle(p, "NameplateBorder", L["OPT_NPBORDER_ENABLE"], L["OPT_NPBORDER_ENABLE_DESC"])

    p:Add(W.Header(p, L["SECTION_NPBORDER"]), 14)
    p:Add(W.ColorRow(p, L["OPT_NPBORDER_COLOR"], nil, nil,
        function() return db.color end, Changed), 8)
    p:Add(W.ColorRow(p, L["OPT_NPBORDER_TARGET"],
        function() return db.target.enabled end,
        function(v) db.target.enabled = v end,
        function() return db.target.color end, Changed), 4)

    p:Add(W.Paragraph(p, L["NPBORDER_NOTE"]), 16)
    return p
end

---------------------------------------------------------------------------
-- Register
---------------------------------------------------------------------------
local subtabs = {
    { key = "colors", label = L["SUB_HEALTHCOLORS"], build = BuildColors },
}
-- Border: Retail (Midnight) nameplates only.
if ns.isRetail then
    subtabs[#subtabs + 1] = { key = "border", label = L["SUB_NPBORDER"], build = BuildBorder }
end

Options:RegisterPage{
    key = "nameplates",
    label = L["PAGE_NAMEPLATES"],
    desc = L["PAGE_NAMEPLATES_DESC"],
    order = 50,
    subtabs = subtabs,
}
