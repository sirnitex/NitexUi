-- NitexUI: Options > Unit Frames (Retail only)
-- One sub-tab per frame, each its own module with its own switch.

local _, ns = ...
if not ns.isRetail then return end
local W, L, Options = ns.Widgets, ns.L, ns.Options

local function NewToggler(p, M)
    local db = ns.db.unitframes
    return function(key, label, desc, gap)
        p:Add(W.Toggle(p, L[label], desc and L[desc] or nil,
            function() return db[key] end,
            function(v) db[key] = v; M:Apply() end), gap)
    end
end

local function BuildPlayer(parent)
    local p = Options.NewPage(parent)
    local Toggle = NewToggler(p, ns.UnitFrames.player)
    Options.ModuleToggle(p, "UnitFramesPlayer", L["OPT_UF_PLAYER_ENABLE"], L["OPT_UF_ENABLE_DESC"])
    p:Add(W.Header(p, L["SECTION_UF_HIDE"]), 14)
    Toggle("hideClassResources", "OPT_UF_CLASSRES",  "OPT_UF_CLASSRES_DESC", 10)
    Toggle("hideTotems",         "OPT_UF_TOTEMS",    "OPT_UF_TOTEMS_DESC", 6)
    Toggle("hideCombatText",     "OPT_UF_HITTEXT",   "OPT_UF_HITTEXT_DESC", 6)
    Toggle("hideRestZzz",        "OPT_UF_ZZZ",       nil, 6)
    Toggle("hideRestGlow",       "OPT_UF_RESTGLOW",  "OPT_UF_RESTGLOW_DESC", 6)
    p:Add(W.Paragraph(p, L["UF_NOTE"]), 16)
    return p
end

local function BuildTarget(parent)
    local p = Options.NewPage(parent)
    local Toggle = NewToggler(p, ns.UnitFrames.target)
    Options.ModuleToggle(p, "UnitFramesTarget", L["OPT_UF_TARGET_ENABLE"], L["OPT_UF_ENABLE_DESC"])
    p:Add(W.Header(p, L["SECTION_UF_HIDE"]), 14)
    Toggle("hideTargetRepColor", "OPT_UF_REPCOLOR", "OPT_UF_REPCOLOR_DESC", 10)
    return p
end

local function BuildFocus(parent)
    local p = Options.NewPage(parent)
    local Toggle = NewToggler(p, ns.UnitFrames.focus)
    Options.ModuleToggle(p, "UnitFramesFocus", L["OPT_UF_FOCUS_ENABLE"], L["OPT_UF_ENABLE_DESC"])
    p:Add(W.Header(p, L["SECTION_UF_HIDE"]), 14)
    Toggle("hideFocusAuras", "OPT_UF_FOCUSAURAS", nil, 10)
    return p
end

Options:RegisterPage{
    key = "unitframes",
    label = L["PAGE_UF"],
    desc = L["PAGE_UF_DESC"],
    order = 40,
    subtabs = {
        { key = "player", label = L["SUB_UF_PLAYER"], build = BuildPlayer },
        { key = "target", label = L["SUB_UF_TARGET"], build = BuildTarget },
        { key = "focus",  label = L["SUB_UF_FOCUS"],  build = BuildFocus },
    },
}
