-- NitexUI: Options > Forever (Forever client only)

local _, ns = ...
if not ns.isForever then return end

local W, L, Options = ns.Widgets, ns.L, ns.Options

local function Toggle(p, getDB, key, label, desc, apply, gap)
    p:Add(W.Toggle(p, L[label], L[desc],
        function() return getDB()[key] end,
        function(v) getDB()[key] = v; if apply then apply() end end), gap)
end

local function Numbers(list)
    local items = {}
    for i = 1, #list do items[i] = { value = list[i], text = tostring(list[i]) } end
    return items
end

local ICON_SIZES = Numbers({ 24, 28, 32, 36, 40 })

---------------------------------------------------------------------------
-- Camping
---------------------------------------------------------------------------
local function BuildCamping(parent)
    local M = ns.ForeverCamping
    local function db() return ns.db.forever.camping end
    local function apply() M:Apply() end
    local p = Options.NewPage(parent)
    Options.ModuleToggle(p, "ForeverCamping", L["OPT_CAMP_ENABLE"], L["OPT_CAMP_ENABLE_DESC"])

    p:Add(W.Header(p, L["SECTION_CAMP"]), 14)
    Toggle(p, db, "nearby", "OPT_CAMP_NEARBY", "OPT_CAMP_NEARBY_DESC", apply, 10)
    Toggle(p, db, "expire", "OPT_CAMP_EXPIRE", "OPT_CAMP_EXPIRE_DESC", apply, 6)
    p:Add(W.Paragraph(p, L["CAMP_NOTE"]), 14)
    return p
end

---------------------------------------------------------------------------
-- Reminders
---------------------------------------------------------------------------
local function BuildReminders(parent)
    local M = ns.ForeverReminders
    local function db() return ns.db.forever.reminders end
    local function apply() M:Apply() end
    local p = Options.NewPage(parent)
    Options.ModuleToggle(p, "ForeverReminders", L["OPT_REMIND_ENABLE"], L["OPT_REMIND_ENABLE_DESC"])

    p:Add(W.Header(p, L["SECTION_REMIND"]), 14)
    Toggle(p, db, "classBuffs", "OPT_REMIND_CLASS", "OPT_REMIND_CLASS_DESC", apply, 10)
    Toggle(p, db, "weaponBuff", "OPT_REMIND_WEAPON", "OPT_REMIND_WEAPON_DESC", apply, 6)
    Toggle(p, db, "wellFed", "OPT_REMIND_WELLFED", "OPT_REMIND_WELLFED_DESC", apply, 6)

    p:Add(W.Header(p, L["SECTION_POSITION"]), 16)
    p:Add(W.Dropdown(p, L["OPT_ICON_SIZE"], 160, ICON_SIZES,
        function() return db().size end,
        function(v) db().size = v; apply() end), 10)
    p:Add(W.Paragraph(p, L["FOREVER_MOVE_NOTE"]), 10)
    p:Add(W.Button(p, L["OPT_RESET_POSITION"], 160, function() M:ResetPosition() end), 10)
    p:Add(W.Paragraph(p, L["REMIND_NOTE"]), 14)
    return p
end

---------------------------------------------------------------------------
-- Weapon Skills
---------------------------------------------------------------------------
local function BuildWeaponSkill(parent)
    local function db() return ns.db.forever.weaponskill end
    local p = Options.NewPage(parent)
    Options.ModuleToggle(p, "ForeverWeaponSkill", L["OPT_WSKILL_ENABLE"], L["OPT_WSKILL_ENABLE_DESC"])

    p:Add(W.Header(p, L["SECTION_WSKILL"]), 14)
    Toggle(p, db, "tooltip", "OPT_WSKILL_TOOLTIP", "OPT_WSKILL_TOOLTIP_DESC", nil, 10)
    Toggle(p, db, "maxed", "OPT_WSKILL_MAXED", "OPT_WSKILL_MAXED_DESC", nil, 6)
    Toggle(p, db, "low", "OPT_WSKILL_LOW", "OPT_WSKILL_LOW_DESC", nil, 6)
    return p
end

---------------------------------------------------------------------------
-- Ammo & Reagents
---------------------------------------------------------------------------
local REAGENT_LOW = Numbers({ 1, 3, 5, 10, 20 })
local AMMO_LOW = Numbers({ 100, 200, 400, 600, 1000 })

local function BuildReagents(parent)
    local M = ns.ForeverReagents
    local function db() return ns.db.forever.reagents end
    local function apply() M:Apply() end
    local p = Options.NewPage(parent)
    Options.ModuleToggle(p, "ForeverReagents", L["OPT_REAGENT_ENABLE"], L["OPT_REAGENT_ENABLE_DESC"])

    p:Add(W.Header(p, L["SECTION_REAGENT"]), 14)
    Toggle(p, db, "onlyLow", "OPT_REAGENT_ONLYLOW", "OPT_REAGENT_ONLYLOW_DESC", apply, 10)
    Toggle(p, db, "vendor", "OPT_REAGENT_VENDOR", "OPT_REAGENT_VENDOR_DESC", apply, 6)

    local left, right = Options.Columns(p)
    left:Add(W.Dropdown(p, L["OPT_REAGENT_LOW"], 160, REAGENT_LOW,
        function() return db().lowReagent end,
        function(v) db().lowReagent = v; apply() end))
    right:Add(W.Dropdown(p, L["OPT_AMMO_LOW"], 160, AMMO_LOW,
        function() return db().lowAmmo end,
        function(v) db().lowAmmo = v; apply() end))
    Options.EndColumns(p, left, right)

    p:Add(W.Header(p, L["SECTION_POSITION"]), 16)
    p:Add(W.Dropdown(p, L["OPT_ICON_SIZE"], 160, ICON_SIZES,
        function() return db().size end,
        function(v) db().size = v; apply() end), 10)
    p:Add(W.Paragraph(p, L["FOREVER_MOVE_NOTE"]), 10)
    p:Add(W.Button(p, L["OPT_RESET_POSITION"], 160, function() M:ResetPosition() end), 10)
    return p
end

Options:RegisterPage{
    key = "forever",
    label = L["PAGE_FOREVER"],
    desc = L["PAGE_FOREVER_DESC"],
    order = 80,
    subtabs = {
        { key = "camping",  label = L["SUB_CAMPING"],  build = BuildCamping },
        { key = "remind",   label = L["SUB_REMIND"],   build = BuildReminders },
        { key = "wskill",   label = L["SUB_WSKILL"],   build = BuildWeaponSkill },
        { key = "reagents", label = L["SUB_REAGENTS"], build = BuildReagents },
    },
}
