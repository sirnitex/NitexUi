-- NitexUI: Forever > Reminders (Forever client only)
--
-- Out of combat, a small row of icons shows what you are missing:
--   * Class buffs you know but do not have on you (Arcane Intellect, Mage/Ice/Frost Armor,
--     Fortitude, Inner Fire, Mark of the Wild, a Blessing and an Aura, Demon Skin/Armor,
--     Lightning Shield, an Aspect, ...). A buff counts if any rank or the group version is up.
--   * A weapon buff (rogue poisons, shaman imbues) on the main hand.
--   * Well Fed (from level 10; not while you are eating).
-- Hover an icon for Blizzard's spell tooltip. Shift + drag moves the row.
--
-- Known spells: C_SpellBook.IsSpellKnown with the spell IDs below (spells this character does
-- not have are skipped). Buffs are matched by the localized spell name, so every rank counts.
-- Nothing is read in combat; the row is hidden in combat, in the air, and while dead.
-- Events while ON: UNIT_AURA / UNIT_INVENTORY_CHANGED (player only, one check per 0.5 s),
-- PLAYER_REGEN_ENABLED/DISABLED, PLAYER_ENTERING_WORLD, SPELLS_CHANGED, PLAYER_LEVEL_UP,
-- PLAYER_CONTROL_LOST/GAINED (taxi).
--
-- When the module is OFF: nothing is registered and the row is hidden.

local _, ns = ...
if not ns.isForever then return end

local M = ns:NewModule("ForeverReminders")
ns.ForeverReminders = M
local L, PP, F = ns.L, ns.PP, ns.Forever

ns.defaults.forever.reminders = {
    classBuffs = true,
    weaponBuff = true,
    wellFed = true,
    size = 32,
}

local InCombatLockdown, UnitIsDeadOrGhost, UnitOnTaxi = InCombatLockdown, UnitIsDeadOrGhost, UnitOnTaxi
local IsSpellKnown = C_SpellBook and C_SpellBook.IsSpellKnown
local GetSpellName = C_Spell and C_Spell.GetSpellName
local GetSpellTexture = C_Spell and C_Spell.GetSpellTexture
local GetSkillLineInfoByID = C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID

-- Each entry: any of `spells` counts (first known one is shown). weapon = main hand buff.
local CLASS_BUFFS = {
    MAGE = {
        { spells = { 1459, 23028 } },                    -- Arcane Intellect / Arcane Brilliance
        { spells = { 6117, 7302, 168 } },                -- Mage Armor / Ice Armor / Frost Armor
    },
    PRIEST = {
        { spells = { 1243, 21562 } },                    -- Power Word / Prayer of Fortitude
        { spells = { 588 } },                            -- Inner Fire
        { spells = { 14752, 27681 } },                   -- Divine Spirit / Prayer of Spirit
    },
    DRUID = {
        { spells = { 1126, 21849 } },                    -- Mark / Gift of the Wild
        { spells = { 16864 } },                          -- Omen of Clarity
    },
    PALADIN = {
        { spells = { 19740, 19742, 20217, 1038, 20911, 19977,     -- any Blessing
                     25782, 25894, 25898, 25895, 25899, 25890 } }, -- or Greater Blessing
        { spells = { 465, 7294, 19746, 19876, 19888, 19891, 20218 } }, -- any Aura
    },
    WARLOCK = {
        { spells = { 706, 687 } },                       -- Demon Armor / Demon Skin
    },
    SHAMAN = {
        { spells = { 324 } },                            -- Lightning Shield
        { weapon = true, spells = { 8017, 8024, 8033, 8232 } }, -- Rockbiter/Flametongue/Frostbrand/Windfury
    },
    HUNTER = {
        { spells = { 13165, 13163, 5118, 13159, 20043, 13161 } }, -- any Aspect
        { spells = { 19506 } },                          -- Trueshot Aura
    },
    ROGUE = {
        { weapon = true, skill = 40 },                   -- poisons (Poisons skill)
    },
}

local WELL_FED_SPELL, FOOD_SPELL = 19705, 433
local WELL_FED_ICON = "Interface\\Icons\\Spell_Misc_Food"
local MAIN_HAND = 16
local TEMP_ENCHANT = Enum.ItemEnchantType and Enum.ItemEnchantType.Temporary or 2
local IMBUE_ENCHANT = Enum.ItemEnchantType and Enum.ItemEnchantType.Imbue or 3

local entries -- this class's list
local row
local pending = false

local function DB() return ns.db.forever.reminders end

---------------------------------------------------------------------------
-- Checks
---------------------------------------------------------------------------
local function FirstKnown(spells)
    if not IsSpellKnown then return nil end
    for i = 1, #spells do
        if IsSpellKnown(spells[i]) then return spells[i] end
    end
end

local function HasAnyBuff(spells)
    for i = 1, #spells do
        local name = GetSpellName(spells[i])
        if name and F.GetAura(name) then return true end
    end
    return false
end

local function HasWeaponBuff()
    if not GetInventoryItemID("player", MAIN_HAND) then return true end -- nothing to buff
    if C_Item and C_Item.GetWeaponEnchantInfo and Enum.WeaponSlot then
        local list = C_Item.GetWeaponEnchantInfo(Enum.WeaponSlot.MainHand)
        for i = 1, #list do
            local e = list[i]
            if e.hasEnchant and (e.enchantType == TEMP_ENCHANT or e.enchantType == IMBUE_ENCHANT) then
                return true
            end
        end
        return false
    end
    return GetWeaponEnchantInfo and GetWeaponEnchantInfo() and true or false
end

local function KnowsWeaponBuff(entry)
    if entry.skill then
        local info = GetSkillLineInfoByID and GetSkillLineInfoByID(entry.skill)
        return info and info.rank and info.rank > 0
    end
    return FirstKnown(entry.spells) ~= nil
end

---------------------------------------------------------------------------
-- Icon row
---------------------------------------------------------------------------
local function CreateRow()
    row = CreateFrame("Frame", "NitexUIReminders", UIParent)
    row:SetFrameStrata("MEDIUM")
    row.icons = {}
    PP.Size(row, 32, 32)
    F.MakeMovable(row, DB, -210)
    row:Hide()
end

local function SetIcon(n, texture, spellID, tip)
    local size = DB().size
    local b = row.icons[n]
    if not b then
        b = F.CreateIcon(row, size)
        row.icons[n] = b
    end
    PP.Size(b, size, size)
    b.icon:SetTexture(texture)
    b.spellID, b.itemID, b.tipText = spellID, nil, tip
    b.count:SetText("")
end

local function Hide()
    if row then row:Hide() end
end

local function Check()
    pending = false
    if not M.enabled then return end
    if InCombatLockdown() or UnitIsDeadOrGhost("player") or UnitOnTaxi("player") then
        Hide()
        return
    end
    if not row then CreateRow() end
    local db = DB()
    local n = 0

    if entries then
        for i = 1, #entries do
            local e = entries[i]
            if e.weapon then
                if db.weaponBuff and KnowsWeaponBuff(e) and not HasWeaponBuff() then
                    n = n + 1
                    local id = e.spells and FirstKnown(e.spells)
                    SetIcon(n, GetInventoryItemTexture("player", MAIN_HAND), id, L["REMIND_WEAPON"])
                end
            elseif db.classBuffs then
                local id = FirstKnown(e.spells)
                if id and not HasAnyBuff(e.spells) then
                    n = n + 1
                    SetIcon(n, GetSpellTexture(id), id, nil)
                end
            end
        end
    end

    if db.wellFed and UnitLevel("player") >= 10 then
        local fed = GetSpellName(WELL_FED_SPELL) or L["AURA_WELL_FED"]
        local food = GetSpellName(FOOD_SPELL) or L["AURA_FOOD"]
        if not F.GetAura(fed) and not F.GetAura(food) then
            n = n + 1
            SetIcon(n, WELL_FED_ICON, nil, L["REMIND_WELLFED"])
        end
    end

    F.LayoutRow(row, n, db.size, 4)
    if n > 0 then
        if not row.placed then F.Place(row); row.placed = true end
        row:Show()
    else
        row:Hide()
    end
end

local function Queue()
    if pending then return end
    pending = true
    C_Timer.After(0.5, Check)
end

function M:OnCombat() Hide() end

function M:Apply()
    if not self.enabled then return end
    if row then F.Place(row) end
    Check()
end

function M:ResetPosition()
    DB().pos = nil
    if row then F.Place(row) end
end

function M:OnEnable()
    local _, class = UnitClass("player")
    entries = CLASS_BUFFS[class]
    ns:RegisterPlayerEvent("UNIT_AURA", self, Queue)
    ns:RegisterPlayerEvent("UNIT_INVENTORY_CHANGED", self, Queue)
    ns:RegisterEvent("PLAYER_REGEN_ENABLED", self, Queue)
    ns:RegisterEvent("PLAYER_REGEN_DISABLED", self, self.OnCombat)
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", self, Queue)
    ns:RegisterEvent("SPELLS_CHANGED", self, Queue)
    ns:RegisterEvent("PLAYER_LEVEL_UP", self, Queue)
    ns:RegisterEvent("PLAYER_CONTROL_LOST", self, Queue)
    ns:RegisterEvent("PLAYER_CONTROL_GAINED", self, Queue)
    Queue()
end

function M:OnDisable()
    ns:UnregisterPlayerEvent("UNIT_AURA", self)
    ns:UnregisterPlayerEvent("UNIT_INVENTORY_CHANGED", self)
    ns:UnregisterEvent("PLAYER_REGEN_ENABLED", self)
    ns:UnregisterEvent("PLAYER_REGEN_DISABLED", self)
    ns:UnregisterEvent("PLAYER_ENTERING_WORLD", self)
    ns:UnregisterEvent("SPELLS_CHANGED", self)
    ns:UnregisterEvent("PLAYER_LEVEL_UP", self)
    ns:UnregisterEvent("PLAYER_CONTROL_LOST", self)
    ns:UnregisterEvent("PLAYER_CONTROL_GAINED", self)
    entries = nil
    Hide()
end
