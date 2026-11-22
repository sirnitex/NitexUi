-- NitexUI: Forever > Camping (Forever client only)
--
-- Helps with Forever's campsites, using the auras Blizzard already gives you:
--   * "Campfire Nearby" appears (about 100 yards from a fire) while you have no camp buffs,
--     or they run out within 10 minutes: a message reminds you to sit at the fire for a minute.
--   * "Camp Benefits" (the hour-long camp buffs) run out in 5 minutes: a message.
-- Blizzard's own buff bar already shows the "Welcoming Campfire" countdown, so that is left alone.
--
-- The aura names are the game's English names (Locales: AURA_*). Auras are only read out of
-- combat. Events while ON: UNIT_AURA (player only, coalesced to one check per 0.5 s),
-- PLAYER_REGEN_ENABLED, PLAYER_ENTERING_WORLD. The 5-minute warning is one C_Timer timer.
--
-- When the module is OFF: nothing is registered and no timer runs.

local _, ns = ...
if not ns.isForever then return end

local M = ns:NewModule("ForeverCamping")
ns.ForeverCamping = M
local L, F = ns.L, ns.Forever

ns.defaults.forever.camping = {
    nearby = true,  -- reminder when a campfire is near and you have no camp buffs
    expire = true,  -- warning 5 minutes before the camp buffs run out
}

local GetTime, InCombatLockdown = GetTime, InCombatLockdown
local WARN_BEFORE = 300   -- seconds before Camp Benefits run out
local REFRESH_WINDOW = 600 -- camp buffs with less than this left count as "running out"

local wasNearby = false
local pending = false
local expireTimer, expireAt

local function DB() return ns.db.forever.camping end

local function CancelExpire()
    if expireTimer then expireTimer:Cancel() end
    expireTimer, expireAt = nil, nil
end

local function OnExpireSoon()
    expireTimer = nil
    if M.enabled and DB().expire then F.Notify(L["CAMP_EXPIRE"]) end
end

local function Check()
    pending = false
    if not M.enabled or InCombatLockdown() then return end
    local db = DB()
    local now = GetTime()

    local benefits = F.GetAura(L["AURA_CAMP_BENEFITS"])
    local left = benefits and benefits.expirationTime and benefits.expirationTime > 0
        and benefits.expirationTime - now

    -- Campfire close by
    local nearby = F.GetAura(L["AURA_CAMPFIRE_NEARBY"]) ~= nil
    if nearby and not wasNearby and db.nearby and (not benefits or (left and left < REFRESH_WINDOW)) then
        F.Notify(L["CAMP_NEARBY"])
    end
    wasNearby = nearby

    -- Camp buffs running out
    if db.expire and left and left > WARN_BEFORE then
        local at = benefits.expirationTime
        if at ~= expireAt then
            CancelExpire()
            expireAt = at
            expireTimer = C_Timer.NewTimer(left - WARN_BEFORE, OnExpireSoon)
        end
    elseif not left then
        CancelExpire()
    end
end

local function Queue()
    if pending or InCombatLockdown() then return end
    pending = true
    C_Timer.After(0.5, Check)
end

function M:Apply()
    if not self.enabled then return end
    if not DB().expire then CancelExpire() end
    Check()
end

function M:OnEnable()
    ns:RegisterPlayerEvent("UNIT_AURA", self, Queue)
    ns:RegisterEvent("PLAYER_REGEN_ENABLED", self, Queue)
    ns:RegisterEvent("PLAYER_ENTERING_WORLD", self, Queue)
    Queue()
end

function M:OnDisable()
    ns:UnregisterPlayerEvent("UNIT_AURA", self)
    ns:UnregisterEvent("PLAYER_REGEN_ENABLED", self)
    ns:UnregisterEvent("PLAYER_ENTERING_WORLD", self)
    CancelExpire()
    wasNearby = false
end
