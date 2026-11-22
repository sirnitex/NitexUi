-- NitexUI: Options > Unit Frames (Retail only)

local _, ns = ...
if not ns.isRetail then return end
local W, L, Options = ns.Widgets, ns.L, ns.Options

local function BuildGeneral(parent)
    local M = ns.UnitFrames
    local db = ns.db.unitframes
    local p = Options.NewPage(parent)

    local function Toggle(key, label, desc, gap)
        p:Add(W.Toggle(p, L[label], desc and L[desc] or nil,
            function() return db[key] end,
            function(v) db[key] = v; M:Apply() end), gap)
    end

    Options.ModuleToggle(p, "UnitFrames", L["OPT_UF_ENABLE"], L["OPT_UF_ENABLE_DESC"])

    p:Add(W.Header(p, L["SECTION_UF_PLAYER"]), 14)
    Toggle("hideClassResources", "OPT_UF_CLASSRES",  "OPT_UF_CLASSRES_DESC", 10)
    Toggle("hideTotems",         "OPT_UF_TOTEMS",    "OPT_UF_TOTEMS_DESC", 6)
    Toggle("hideCombatText",     "OPT_UF_HITTEXT",   "OPT_UF_HITTEXT_DESC", 6)
    Toggle("hideRestZzz",        "OPT_UF_ZZZ",       nil, 6)
    Toggle("hideRestGlow",       "OPT_UF_RESTGLOW",  "OPT_UF_RESTGLOW_DESC", 6)

    p:Add(W.Header(p, L["SECTION_UF_TARGET"]), 16)
    Toggle("hideTargetRepColor", "OPT_UF_REPCOLOR",  "OPT_UF_REPCOLOR_DESC", 10)

    p:Add(W.Header(p, L["SECTION_UF_FOCUS"]), 16)
    Toggle("hideFocusAuras",     "OPT_UF_FOCUSAURAS", nil, 10)

    p:Add(W.Paragraph(p, L["UF_NOTE"]), 16)
    return p
end

Options:RegisterPage{
    key = "unitframes",
    label = L["PAGE_UF"],
    desc = L["PAGE_UF_DESC"],
    order = 37,
    subtabs = {
        { key = "general", label = L["SUB_GENERAL"], build = BuildGeneral },
    },
}
