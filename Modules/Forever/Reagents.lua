-- NitexUI: Forever > Ammo & Reagents (Forever client only)
--
-- A small row of item icons with how many you carry of your class reagents (Arcane Powder,
-- candles, Ankhs, seeds, powders, Soul Shards, ...) and your ammo (if your class uses ammo).
-- The number turns red when you are low. Reagents you have never carried on this character
-- are not shown, so you only see what you use. At a vendor, a chat line lists what is low.
--
-- Counts: C_Item.GetItemCount / GetInventoryItemCount (ammo slot). Events while ON:
-- BAG_UPDATE_DELAYED, UNIT_INVENTORY_CHANGED (player only), PLAYER_ENTERING_WORLD,
-- MERCHANT_SHOW (only with the vendor option). Shift + drag moves the row.
--
-- When the module is OFF: nothing is registered, the row is hidden and the list of
-- reagents seen on this character is wiped.

local _, ns = ...
if not ns.isForever then return end

local M = ns:NewModule("ForeverReagents")
ns.ForeverReagents = M
local L, PP, F = ns.L, ns.PP, ns.Forever

ns.defaults.forever.reagents = {
    lowReagent = 5,
    lowAmmo = 200,
    onlyLow = false,
    vendor = true,
    size = 28,
}

local GetItemCount = C_Item and C_Item.GetItemCount
local GetItemIcon = C_Item and C_Item.GetItemIconByID
local UnitUsesAmmo = UnitUsesAmmo
local AMMO_SLOT = INVSLOT_AMMO or 0

local CLASS_REAGENTS = {
    MAGE    = { 17020, 17031, 17032, 17056 },        -- Arcane Powder, Rune of Teleportation/Portals, Light Feather
    PRIEST  = { 17028, 17029, 17056 },               -- Holy/Sacred Candle, Light Feather
    PALADIN = { 21177, 17033 },                      -- Symbol of Kings/Divinity
    SHAMAN  = { 17030 },                             -- Ankh
    DRUID   = { 17021, 17026, 17034, 17035, 17036, 17037, 17038 }, -- Berries, Thornroot, seeds
    ROGUE   = { 5140, 5530 },                        -- Flash/Blinding Powder
    WARLOCK = { 6265 },                              -- Soul Shard
}

local reagents -- this class's list
local row
local pending = false

local function DB() return ns.db.forever.reagents end

local function Seen()
    ns.charDB.reagentsSeen = ns.charDB.reagentsSeen or {}
    return ns.charDB.reagentsSeen
end

local function AmmoItem()
    if not UnitUsesAmmo or not UnitUsesAmmo("player") then return nil end
    local id = GetInventoryItemID("player", AMMO_SLOT)
    if not id then return nil end
    return id, GetInventoryItemCount("player", AMMO_SLOT) or 0
end

---------------------------------------------------------------------------
-- Row
---------------------------------------------------------------------------
local function CreateRow()
    row = CreateFrame("Frame", "NitexUIReagents", UIParent)
    row:SetFrameStrata("MEDIUM")
    row.icons = {}
    PP.Size(row, 28, 28)
    F.MakeMovable(row, DB, -250)
    row:Hide()
end

local function SetIcon(n, itemID, count, low)
    local size = DB().size
    local b = row.icons[n]
    if not b then
        b = F.CreateIcon(row, size)
        row.icons[n] = b
    end
    PP.Size(b, size, size)
    b.icon:SetTexture(GetItemIcon(itemID))
    b.itemID, b.spellID, b.tipText = itemID, nil, nil
    b.count:SetText(count)
    if low then b.count:SetTextColor(1, 0.25, 0.25) else b.count:SetTextColor(1, 1, 1) end
    b.icon:SetDesaturated(count == 0)
end

local function Update()
    pending = false
    if not M.enabled then return end
    if not row then CreateRow() end
    local db = DB()
    local n = 0

    local ammoID, ammo = AmmoItem()
    if ammoID then
        local low = ammo <= db.lowAmmo
        if low or not db.onlyLow then
            n = n + 1
            SetIcon(n, ammoID, ammo, low)
        end
    end

    if reagents then
        local seen = Seen()
        for i = 1, #reagents do
            local id = reagents[i]
            local count = GetItemCount(id)
            if count > 0 then seen[id] = true end
            if seen[id] then
                local low = count <= db.lowReagent
                if low or not db.onlyLow then
                    n = n + 1
                    SetIcon(n, id, count, low)
                end
            end
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
    C_Timer.After(0.5, Update)
end

function M:OnMerchantShow()
    if not DB().vendor then return end
    local db = DB()
    local ammoID, ammo = AmmoItem()
    if ammoID and ammo <= db.lowAmmo then
        ns:Print(format(L["REAGENT_LOW"], C_Item.GetItemNameByID(ammoID) or "?", ammo))
    end
    if not reagents then return end
    local seen = Seen()
    for i = 1, #reagents do
        local id = reagents[i]
        local count = GetItemCount(id)
        if seen[id] and count <= db.lowReagent then
            ns:Print(format(L["REAGENT_LOW"], C_Item.GetItemNameByID(id) or "?", count))
        end
    end
end

function M:Apply()
    if not self.enabled then return end
    if DB().vendor then
        ns:RegisterEvent("MERCHANT_SHOW", self, self.OnMerchantShow)
    else
        ns:UnregisterEvent("MERCHANT_SHOW", self)
    end
    Update()
end

function M:ResetPosition()
    DB().pos = nil
    if row then F.Place(row) end
end

function M:OnEnable()
    local _, class = UnitClass("player")
    reagents = CLASS_REAGENTS[class]
    ns:RegisterEvent("BAG_UPDATE_DELAYED", self, Queue)
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", self, Queue)
    ns:RegisterPlayerEvent("UNIT_INVENTORY_CHANGED", self, Queue)
    self:Apply()
end

function M:OnDisable()
    ns:UnregisterEvent("BAG_UPDATE_DELAYED", self)
    ns:UnregisterEvent("PLAYER_ENTERING_WORLD", self)
    ns:UnregisterEvent("MERCHANT_SHOW", self)
    ns:UnregisterPlayerEvent("UNIT_INVENTORY_CHANGED", self)
    ns.charDB.reagentsSeen = nil
    reagents = nil
    if row then row:Hide() end
end
