-- NitexUI: Options > Quality of Life

local _, ns = ...
local W, L, Options = ns.Widgets, ns.L, ns.Options

local function BuildGeneral(parent)
    local M = ns.QualityOfLife
    local db = ns.db.qol
    local p = Options.NewPage(parent)

    local function Toggle(key, label, desc, gap)
        p:Add(W.Toggle(p, L[label], L[desc],
            function() return db[key] end,
            function(v) db[key] = v; M:Apply() end), gap)
    end

    Options.ModuleToggle(p, "QualityOfLife", L["OPT_QOL_ENABLE"], L["OPT_QOL_ENABLE_DESC"])

    p:Add(W.Header(p, L["SECTION_QOL_HIDE"]), 14)
    Toggle("hideTalkingHead", "OPT_QOL_TALKINGHEAD", "OPT_QOL_TALKINGHEAD_DESC", 10)
    Toggle("hideErrors",      "OPT_QOL_ERRORS",      "OPT_QOL_ERRORS_DESC", 6)
    Toggle("hideZoneText",    "OPT_QOL_ZONETEXT",    "OPT_QOL_ZONETEXT_DESC", 6)

    p:Add(W.Header(p, L["SECTION_QOL_VENDOR"]), 16)
    Toggle("sellJunk",         "OPT_QOL_SELLJUNK",    "OPT_QOL_SELLJUNK_DESC", 10)
    Toggle("autoRepair",       "OPT_QOL_REPAIR",      "OPT_QOL_REPAIR_DESC", 6)
    Toggle("repairGuildFirst", "OPT_QOL_REPAIRGUILD", "OPT_QOL_REPAIRGUILD_DESC", 6)

    p:Add(W.Header(p, L["SECTION_QOL_GROUP"]), 16)
    if ns.isRetail then
        Toggle("quickSignup",       "OPT_QOL_QUICKSIGNUP",   "OPT_QOL_QUICKSIGNUP_DESC", 10)
        Toggle("autoAcceptInvite",  "OPT_QOL_ACCEPTINVITE",  "OPT_QOL_ACCEPTINVITE_DESC", 6)
        Toggle("inviteFriendsOnly", "OPT_QOL_INVITEFRIENDS", "OPT_QOL_INVITEFRIENDS_DESC", 6)
    else
        p:Add(W.Paragraph(p, L["QOL_RETAIL_ONLY"]), 10)
    end
    return p
end

Options:RegisterPage{
    key = "qol",
    label = L["PAGE_QOL"],
    desc = L["PAGE_QOL_DESC"],
    order = 70,
    subtabs = {
        { key = "general", label = L["SUB_GENERAL"], build = BuildGeneral },
    },
}
