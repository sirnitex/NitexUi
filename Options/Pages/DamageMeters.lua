-- NitexUI: Options > Damage Meters

local _, ns = ...
local W, L, Options = ns.Widgets, ns.L, ns.Options

local function BuildGeneral(parent)
    local M = ns.DamageMeters
    local db = ns.db.damagemeters
    local p = Options.NewPage(parent)

    local function Toggle(key, label, desc, gap)
        p:Add(W.Toggle(p, L[label], L[desc],
            function() return db[key] end,
            function(v) db[key] = v; M:Apply() end), gap)
    end

    Options.ModuleToggle(p, "DamageMeters", L["OPT_DM_ENABLE"], L["OPT_DM_ENABLE_DESC"])

    p:Add(W.Header(p, L["SECTION_DM_WINDOWS"]), 14)
    Toggle("snap", "OPT_DM_SNAP", "OPT_DM_SNAP_DESC", 10)

    p:Add(W.Header(p, L["SECTION_DM_TEXT"]), 16)
    Toggle("hideRank",     "OPT_DM_HIDERANK", "OPT_DM_HIDERANK_DESC", 10)
    Toggle("shortNumbers", "OPT_DM_NUMBERS",  "OPT_DM_NUMBERS_DESC", 6)

    p:Add(W.Paragraph(p, L["DM_NOTE"]), 16)
    return p
end

Options:RegisterPage{
    key = "damagemeters",
    label = L["PAGE_DM"],
    desc = L["PAGE_DM_DESC"],
    order = 60,
    subtabs = {
        { key = "general", label = L["SUB_GENERAL"], build = BuildGeneral },
    },
}
