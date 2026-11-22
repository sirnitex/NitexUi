-- NitexUI: Interface > Character Panel
--
-- Shows item level, enchant and gems next to every equipped item on Blizzard's own
-- character window (no replacement frames).
--
-- Data comes only from Blizzard's API:
--   * item level / quality: C_Item.GetCurrentItemLevel / C_Item.GetItemQuality (ItemLocation)
--   * enchant + gems: C_TooltipInfo.GetInventoryItem (the same lines the item tooltip shows,
--     so enchant names and gem/empty-socket icons are exactly Blizzard's)
--
-- Work happens only while the character window is open: on open, and when equipment,
-- enchants or gems change (PLAYER_EQUIPMENT_CHANGED / UNIT_INVENTORY_CHANGED; the latter
-- only redraws slots whose item link changed).
-- These events are registered only while the window is shown. No OnUpdate, no timers.
--
-- When the module is OFF: nothing is registered or created. The OnShow/OnHide hooks on
-- the character window are installed the first time the module is turned on and cannot
-- be removed; while off they return immediately.

local _, ns = ...
local M = ns:NewModule("CharacterPanel")
ns.CharacterPanel = M
local PP = ns.PP
local L = ns.L

ns.defaults.interface = ns.defaults.interface or {}
ns.defaults.interface.character = {
    itemLevel = true,
    enchants = true,
    missingEnchant = true,
    gems = true,
}

-- slotID, Blizzard slot button name, side the text goes on ("R" = right of the slot)
local SLOTS = {
    { 1,  "CharacterHeadSlot",          "R" },
    { 2,  "CharacterNeckSlot",          "R" },
    { 3,  "CharacterShoulderSlot",      "R" },
    { 15, "CharacterBackSlot",          "R" },
    { 5,  "CharacterChestSlot",         "R" },
    { 9,  "CharacterWristSlot",         "R" },
    { 10, "CharacterHandsSlot",         "L" },
    { 6,  "CharacterWaistSlot",         "L" },
    { 7,  "CharacterLegsSlot",          "L" },
    { 8,  "CharacterFeetSlot",          "L" },
    { 11, "CharacterFinger0Slot",       "L" },
    { 12, "CharacterFinger1Slot",       "L" },
    { 13, "CharacterTrinket0Slot",      "L" },
    { 14, "CharacterTrinket1Slot",      "L" },
    { 16, "CharacterMainHandSlot",      "L" },
    { 17, "CharacterSecondaryHandSlot", "R" },
}

-- TEXT_W: the text from the left and right columns must not meet in the middle.
local TEXT_W, GAP, GEM, MAX_GEMS, ILVL_W = 118, 6, 13, 3, 30
local EMPTY_SOCKET = [[Interface\ItemSocketingFrame\UI-EmptySocket-%s]]

local C_Item, C_TooltipInfo = C_Item, C_TooltipInfo
local GetInventoryItemID, GetInventoryItemLink = GetInventoryItemID, GetInventoryItemLink
local LineType = Enum and Enum.TooltipDataLineType
local LT_ENCHANT = LineType and LineType.ItemEnchantmentPermanent
local LT_GEM = LineType and LineType.GemSocket

-- "Enchanted: %s" -> "Enchanted: " (localized by Blizzard), stripped from the enchant line.
local enchantPrefix = ENCHANTED_TOOLTIP_LINE and ENCHANTED_TOOLTIP_LINE:gsub("%%s", "")

-- Slots that can be enchanted in Midnight (Retail): head, shoulder, chest, legs
-- (spellthread / armor kit), feet, rings, weapons. The off hand only when it is a weapon.
local ENCHANTABLE = { [1] = true, [3] = true, [5] = true, [7] = true, [8] = true,
                      [11] = true, [12] = true, [16] = true, [17] = "weapon" }
local WEAPON = Enum and Enum.ItemClass and Enum.ItemClass.Weapon
local GetItemInfoInstant = C_Item.GetItemInfoInstant or GetItemInfoInstant

-- Shorter enchant text: "Enchant Helm - Empowered Hex of Leeching" -> "Empowered Hex of Leeching",
-- and long stat words abbreviated (only runs when a slot changes, never per frame).
local SHORT = {
    { "Agility", "Agi" }, { "Strength", "Str" }, { "Intellect", "Int" }, { "Stamina", "Stam" },
    { "Critical Strike", "Crit" }, { "Versatility", "Vers" }, { "Mastery", "Mast" },
    { "Avoidance", "Avoid" }, { " & ", " " },
}
local function ShortEnchant(text)
    local dash = text:find(" - ", 1, true)
    if dash then text = text:sub(dash + 3) end
    for i = 1, #SHORT do
        local s = SHORT[i]
        text = text:gsub(s[1], s[2])
    end
    return text
end

local function IsEnchantable(slotID)
    local e = ENCHANTABLE[slotID]
    if e ~= "weapon" then return e end
    local itemID = GetInventoryItemID("player", slotID)
    if not (itemID and WEAPON and GetItemInfoInstant) then return false end
    local classID = select(6, GetItemInfoInstant(itemID))
    return classID == WEAPON
end

-- Only nag about missing enchants at max level (levelling gear is rarely enchanted).
local function AtMaxLevel()
    local max = GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion()
    return not max or UnitLevel("player") >= max
end

local overlays = {} -- [slotID] = overlay frame
local hooked, watching = false, false

---------------------------------------------------------------------------
-- Overlay per slot (built the first time the window is shown with the module on)
---------------------------------------------------------------------------
local function NewText(parent, size, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
    fs:SetJustifyH(justify)
    fs:SetWordWrap(false)
    fs:SetWidth(TEXT_W) -- explicit width before any text is set (long names end in "...")
    return fs
end

local function CreateOverlay(info)
    local slot = _G[info[2]]
    if not slot then return end
    local right = info[3] == "R"
    local o = CreateFrame("Frame", nil, slot)
    o:SetFrameLevel(slot:GetFrameLevel() + 2)
    PP.Size(o, TEXT_W, slot:GetHeight())
    if right then
        PP.Point(o, "TOPLEFT", slot, "TOPRIGHT", GAP, 0)
    else
        PP.Point(o, "TOPRIGHT", slot, "TOPLEFT", -GAP, 0)
    end
    local side = right and "LEFT" or "RIGHT"
    local sign = right and 1 or -1

    o.ilvl = NewText(o, 13, side)
    o.ilvl:SetPoint("TOP" .. side, o, "TOP" .. side, 0, -3)

    o.enchant = NewText(o, 10, side)
    o.enchant:SetPoint("BOTTOM" .. side, o, "BOTTOM" .. side, 0, 3)
    o.enchant:SetTextColor(0.1, 1, 0.1)

    -- Gem icons at fixed positions after the item level (layout never anchors to text).
    o.gems = {}
    for i = 1, MAX_GEMS do
        local t = o:CreateTexture(nil, "OVERLAY")
        PP.Size(t, GEM, GEM)
        PP.Point(t, "TOP" .. side, o, "TOP" .. side, sign * (ILVL_W + (i - 1) * (GEM + 2)), -2)
        t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        t:Hide()
        o.gems[i] = t
    end

    o.slotID = info[1]
    overlays[info[1]] = o
    return o
end

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------
-- The item link holds item level bonuses, enchant and gems, so an unchanged link means
-- nothing on that slot changed and the tooltip scan can be skipped.
local function UpdateSlot(slotID, force)
    local o = overlays[slotID]
    if not o then return end
    local link = GetInventoryItemLink("player", slotID)
    if issecretvalue and issecretvalue(link) then link = nil; force = true end
    if not force and link == o.link then return end
    o.link = link
    local db = ns.db.interface.character

    o.ilvl:SetText("")
    o.enchant:SetText("")
    for i = 1, MAX_GEMS do o.gems[i]:Hide() end

    if not GetInventoryItemID("player", slotID) then o:Hide(); return end
    o:Show()

    local loc = o.loc
    if not loc then
        loc = ItemLocation:CreateFromEquipmentSlot(slotID)
        o.loc = loc
    end
    if not C_Item.DoesItemExist(loc) then return end

    if db.itemLevel then
        local ilvl = C_Item.GetCurrentItemLevel(loc)
        if ilvl and ilvl > 0 then
            o.ilvl:SetText(ilvl)
            local q = C_Item.GetItemQuality(loc)
            local r, g, b = 1, 1, 1
            if q and C_Item.GetItemQualityColor then r, g, b = C_Item.GetItemQualityColor(q) end
            o.ilvl:SetTextColor(r, g, b)
        end
    end

    if not (db.enchants or db.gems) or not (C_TooltipInfo and C_TooltipInfo.GetInventoryItem) then return end
    local data = C_TooltipInfo.GetInventoryItem("player", slotID)
    local lines = data and data.lines
    if not lines then return end

    local gemCount, hasEnchant = 0, false
    for i = 1, #lines do
        local line = lines[i]
        local t = line.type
        if db.enchants and t == LT_ENCHANT and line.leftText then
            hasEnchant = true
            local text = line.leftText
            if not (issecretvalue and issecretvalue(text)) then
                if enchantPrefix then
                    local s, e = text:find(enchantPrefix, 1, true)
                    if s == 1 then text = text:sub(e + 1) end
                end
                text = ShortEnchant(text)
            end
            o.enchant:SetTextColor(0.1, 1, 0.1)
            o.enchant:SetText(text)
        elseif db.gems and t == LT_GEM and gemCount < MAX_GEMS then
            local icon = line.gemIcon or (line.socketType and EMPTY_SOCKET:format(line.socketType))
            if icon then
                gemCount = gemCount + 1
                local tex = o.gems[gemCount]
                tex:SetTexture(icon)
                tex:Show()
            end
        end
    end

    -- Red "Missing enchant" (Retail only: the enchantable slots above are Midnight's).
    if db.enchants and db.missingEnchant and not hasEnchant and ns.isRetail
        and IsEnchantable(slotID) and AtMaxLevel() then
        o.enchant:SetTextColor(1, 0.2, 0.2)
        o.enchant:SetText(L["CP_MISSING_ENCHANT"])
    end
end

local function UpdateAll(force)
    for slotID in pairs(overlays) do UpdateSlot(slotID, force) end
end

function M:OnEquipmentChanged(_, slotID)
    if overlays[slotID] then UpdateSlot(slotID, true) end
end

-- No slot in this event: only slots whose item link changed are redrawn.
function M:OnInventoryChanged(_, unit)
    if unit == "player" then UpdateAll(false) end
end

-- Item data can arrive a moment after the window opens (first login, new item).
-- Only a slot holding that exact item is redrawn.
function M:OnItemInfo(_, itemID)
    for slotID in pairs(overlays) do
        if GetInventoryItemID("player", slotID) == itemID then UpdateSlot(slotID, true) end
    end
end

---------------------------------------------------------------------------
-- Character window open / closed
---------------------------------------------------------------------------
local function StartWatching()
    if watching then return end
    watching = true
    ns:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", M, M.OnEquipmentChanged)
    ns:RegisterEvent("UNIT_INVENTORY_CHANGED", M, M.OnInventoryChanged)
    ns:RegisterEvent("GET_ITEM_INFO_RECEIVED", M, M.OnItemInfo)
end

local function StopWatching()
    if not watching then return end
    watching = false
    ns:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED", M)
    ns:UnregisterEvent("UNIT_INVENTORY_CHANGED", M)
    ns:UnregisterEvent("GET_ITEM_INFO_RECEIVED", M)
end

local function OnPanelShow()
    if not M.enabled then return end
    if not next(overlays) then
        for i = 1, #SLOTS do CreateOverlay(SLOTS[i]) end
    end
    StartWatching()
    UpdateAll(true)
end

local function OnPanelHide()
    StopWatching()
end

--- Re-read everything (used by the options when a setting changes).
function M:Apply()
    if self.enabled and PaperDollFrame and PaperDollFrame:IsVisible() then
        OnPanelShow()
    end
end

function M:OnEnable()
    if not hooked and PaperDollFrame then
        hooked = true
        PaperDollFrame:HookScript("OnShow", OnPanelShow)
        PaperDollFrame:HookScript("OnHide", OnPanelHide)
    end
    for _, o in pairs(overlays) do o:Show() end
    self:Apply()
end

function M:OnDisable()
    StopWatching()
    for _, o in pairs(overlays) do o:Hide() end
end
