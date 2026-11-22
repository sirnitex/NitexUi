-- NitexUI: Forever > Weapon Skills (Forever client only)
--
-- Forever has Classic weapon skills. Blizzard already prints every skill-up in chat, so this
-- module only adds what the game does not show:
--   * Weapon tooltips: your skill with that weapon type ("Swords 145 / 150"), red if you have
--     not learned it (visit a weapon master).
--   * A message when an equipped weapon's skill reaches its maximum for your level.
--   * A message when you equip a weapon whose skill is far below the maximum.
--
-- Skill data: C_SkillInfo.GetSkillLineInfoByID (weapon subclass -> skill line below).
-- Events while ON: SKILL_LINES_CHANGED, PLAYER_EQUIPMENT_CHANGED. Tooltip: one
-- TooltipDataProcessor post-call (cannot be removed; returns at once when off).
--
-- When the module is OFF: nothing is registered and the cache is wiped.

local _, ns = ...
if not ns.isForever then return end

local M = ns:NewModule("ForeverWeaponSkill")
ns.ForeverWeaponSkill = M
local L, F = ns.L, ns.Forever

ns.defaults.forever.weaponskill = {
    tooltip = true,
    maxed = true,
    low = true,
}

local GetSkill = C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID
local GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant
local GetInventoryItemID = GetInventoryItemID
local issecretvalue = issecretvalue or function() return false end
local WEAPON_CLASS = Enum.ItemClass and Enum.ItemClass.Weapon or 2
local LOW_GAP = 50 -- "far below": this many points under the maximum
local SLOTS = { 16, 17, 18 }

-- Weapon subclass -> skill line ID (Classic IDs)
local SKILL = {
    [0] = 44,   -- One-Handed Axes  -> Axes
    [1] = 172,  -- Two-Handed Axes
    [2] = 45,   -- Bows
    [3] = 46,   -- Guns
    [4] = 54,   -- One-Handed Maces -> Maces
    [5] = 160,  -- Two-Handed Maces
    [6] = 229,  -- Polearms
    [7] = 43,   -- One-Handed Swords -> Swords
    [8] = 55,   -- Two-Handed Swords
    [10] = 136, -- Staves
    [13] = 473, -- Fist Weapons
    [15] = 173, -- Daggers
    [16] = 176, -- Thrown
    [18] = 226, -- Crossbows
    [19] = 228, -- Wands
}

local ranks = {}   -- [skillID] = last rank seen (equipped weapons only)
local warned = {}  -- [skillID] = true once the "low" message was shown this session

local function DB() return ns.db.forever.weaponskill end

local function SkillForItem(item)
    if not item or not GetItemInfoInstant then return nil end
    local _, _, _, _, _, classID, subclassID = GetItemInfoInstant(item)
    if classID ~= WEAPON_CLASS then return nil end
    return SKILL[subclassID]
end

---------------------------------------------------------------------------
-- Tooltip
---------------------------------------------------------------------------
local function OnItemTooltip(tooltip, data)
    if not M.enabled or not DB().tooltip or not GetSkill then return end
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
    local id = data and data.id
    if not id or issecretvalue(id) then return end
    local skillID = SkillForItem(id)
    if not skillID then return end
    local info = GetSkill(skillID)
    if info and info.rank and info.rank > 0 then
        local r, g, b = 1, 1, 1
        if info.rank >= info.maxRank then r, g, b = 0.4, 1, 0.4 end
        tooltip:AddLine(format(L["WSKILL_TOOLTIP"], info.name, info.rank, info.maxRank), r, g, b)
    else
        tooltip:AddLine(L["WSKILL_UNLEARNED"], 1, 0.25, 0.25)
    end
end

local hooked = false
local function HookTooltip()
    if hooked or not TooltipDataProcessor or not Enum.TooltipDataType then return end
    hooked = true
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
end

---------------------------------------------------------------------------
-- Equipped weapons
---------------------------------------------------------------------------
local function Scan(announce)
    if not GetSkill then return end
    local db = DB()
    for i = 1, #SLOTS do
        local skillID = SkillForItem(GetInventoryItemID("player", SLOTS[i]))
        local info = skillID and GetSkill(skillID)
        if info and info.rank and info.maxRank and info.maxRank > 0 then
            local old = ranks[skillID]
            if announce and db.maxed and old and old < info.maxRank and info.rank >= info.maxRank then
                F.Notify(format(L["WSKILL_MAXED"], info.name, info.rank, info.maxRank))
            end
            if announce and db.low and not warned[skillID] and info.rank + LOW_GAP <= info.maxRank then
                warned[skillID] = true
                ns:Print(format(L["WSKILL_LOW"], info.name, info.rank, info.maxRank))
            end
            ranks[skillID] = info.rank
        end
    end
end

function M:OnSkillsChanged() Scan(true) end

function M:OnEquipmentChanged(_, slot)
    if slot == 16 or slot == 17 or slot == 18 then Scan(true) end
end

function M:OnEnable()
    HookTooltip()
    ns:RegisterEvent("SKILL_LINES_CHANGED", self, self.OnSkillsChanged)
    ns:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", self, self.OnEquipmentChanged)
    Scan(true) -- maxed needs an earlier rank, so at login only the "low" hint can show
end

function M:OnDisable()
    ns:UnregisterEvent("SKILL_LINES_CHANGED", self)
    ns:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED", self)
    wipe(ranks)
    wipe(warned)
end
