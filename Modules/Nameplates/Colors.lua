-- NitexUI: Nameplates > Health Colors
--
-- Recolours the health bar of Blizzard's OWN enemy nameplates. No custom nameplates.
-- Priority: Threat > Quest mob > Enemy type. If nothing applies, Blizzard's colour stays.
--
-- APIs (all native, all secret-checked):
--   UnitThreatSituation("player", unit)        threat status 0-3 (type only, never the raw value)
--   C_QuestLog.UnitIsRelatedToActiveQuest(unit) quest mob
--   UnitIsQuestBoss(unit)                       quest kill target
--   UnitClassification(unit), UnitIsBossMob()   enemy type
--
-- Taint-safe design:
--   * All API calls happen in OUR event handler. The colour is cached per health bar.
--   * One hooksecurefunc on each health bar's SetStatusBarColor re-paints our cached colour
--     whenever Blizzard paints; the hook makes no API calls, only a table lookup.
--   * Per-bar state lives in a weak table, never as keys on Blizzard's frames.
--   * Forbidden nameplates (friendly plates in instances) are never touched.
--
-- Cost while ON: a few API calls per nameplate when it appears, when its threat list
-- changes, or when your quests/role change. Nothing per frame.
-- When OFF: no events. Hooks cannot be removed in WoW, so a bar hooked earlier this session
-- returns immediately on its first line until you /reload.

local _, ns = ...
local M = ns:NewModule("NameplateColors")
ns.NameplateColors = M

local next, unpack = next, unpack
local UnitThreatSituation, UnitClassification, UnitCanAttack, UnitIsPlayer =
      UnitThreatSituation, UnitClassification, UnitCanAttack, UnitIsPlayer
local issecretvalue = issecretvalue or function() return false end
local UnitIsRelatedToActiveQuest = C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest
local UnitIsQuestBoss, UnitIsBossMob = UnitIsQuestBoss, UnitIsBossMob

---------------------------------------------------------------------------
-- Defaults
---------------------------------------------------------------------------
local function C(r, g, b) return { r, g, b } end

ns.defaults.nameplates = ns.defaults.nameplates or {}
ns.defaults.nameplates.colors = {
    threat = {
        enabled = true,
        groupOnly = true,
        good    = { enabled = true, color = C(0.20, 0.80, 0.30) }, -- tank: you hold aggro.   others: (not used)
        warning = { enabled = true, color = C(1.00, 0.60, 0.10) }, -- aggro is about to change
        danger  = { enabled = true, color = C(0.95, 0.15, 0.15) }, -- tank: you lost aggro.   others: you have aggro
    },
    quest = { enabled = true, color = C(0.35, 0.75, 1.00) },
    types = {
        boss      = { enabled = true,  color = C(0.65, 0.25, 0.95) },
        rareelite = { enabled = true,  color = C(1.00, 0.82, 0.20) },
        elite     = { enabled = true,  color = C(0.95, 0.50, 0.20) },
        rare      = { enabled = true,  color = C(0.80, 0.80, 0.90) },
        normal    = { enabled = false, color = C(0.75, 0.20, 0.20) },
        trivial   = { enabled = false, color = C(0.55, 0.55, 0.55) },
    },
}

-- Order + labels used by the options page.
M.typeOrder = { "boss", "rareelite", "elite", "rare", "normal", "trivial" }
M.threatOrder = { "good", "warning", "danger" }

local classificationToType = {
    worldboss = "boss",
    rareelite = "rareelite",
    elite     = "elite",
    rare      = "rare",
    normal    = "normal",
    trivial   = "trivial",
    minus     = "trivial",
}

---------------------------------------------------------------------------
-- Player role (cached; refreshed only when the role can change)
---------------------------------------------------------------------------
local isTank = false

local function UpdateRole()
    local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned("player")
    if (not role or role == "NONE") and GetSpecialization and GetSpecializationRole then
        local spec = GetSpecialization()
        role = spec and GetSpecializationRole(spec)
    end
    isTank = role == "TANK"
end

---------------------------------------------------------------------------
-- Colour decision
---------------------------------------------------------------------------
local db -- ns.db.nameplates.colors, set in OnEnable

local function ThreatColor(status)
    local t = db.threat
    local key
    if isTank then
        if status == 3 then key = "good"
        elseif status == 2 then key = "warning"
        else key = "danger" end           -- 0/1: on the threat list, but someone else has it
    else
        if status == 3 then key = "danger"
        elseif status >= 1 then key = "warning"
        end                                -- 0: fine, no threat colour
    end
    local entry = key and t[key]
    return entry and entry.enabled and entry.color or nil
end

local function Compute(unit)
    local attackable = UnitCanAttack("player", unit)
    if issecretvalue(attackable) or not attackable then return nil end
    local player = UnitIsPlayer(unit)
    if issecretvalue(player) or player then return nil end

    -- 1. Threat
    local t = db.threat
    if t.enabled and (not t.groupOnly or IsInGroup()) then
        local status = UnitThreatSituation("player", unit)
        if status ~= nil and not issecretvalue(status) then
            local c = ThreatColor(status)
            if c then return c end
        end
    end

    -- 2. Quest mob
    if db.quest.enabled then
        local q = UnitIsRelatedToActiveQuest and UnitIsRelatedToActiveQuest(unit)
        if not issecretvalue(q) and q then return db.quest.color end
        q = UnitIsQuestBoss and UnitIsQuestBoss(unit)
        if not issecretvalue(q) and q then return db.quest.color end
    end

    -- 3. Enemy type
    local key
    local boss = UnitIsBossMob and UnitIsBossMob(unit)
    if not issecretvalue(boss) and boss then
        key = "boss"
    else
        local cls = UnitClassification(unit)
        if not issecretvalue(cls) then key = classificationToType[cls] end
    end
    local entry = key and db.types[key]
    return entry and entry.enabled and entry.color or nil
end

---------------------------------------------------------------------------
-- Painting
---------------------------------------------------------------------------
local state = setmetatable({}, { __mode = "k" })  -- [healthBar] = { color = tbl|nil, blizz = {r,g,b,a} }
local hooked = setmetatable({}, { __mode = "k" }) -- [healthBar] = true (hooks are permanent, never hook twice)
local active = {}                                 -- [unitToken] = healthBar
local painting = false

local function Paint(bar, c)
    painting = true
    bar:SetStatusBarColor(c[1], c[2], c[3])
    painting = false
end

local function RestoreBlizzard(bar, s)
    local b = s.blizz
    if b[1] ~= nil then
        painting = true
        bar:SetStatusBarColor(b[1], b[2], b[3], b[4])
        painting = false
    end
end

-- Runs whenever Blizzard sets the bar colour. Must stay tiny: no API calls.
local function OnSetStatusBarColor(bar, r, g, b, a)
    if painting then return end
    local s = state[bar]
    if not s then return end
    local blizz = s.blizz
    blizz[1], blizz[2], blizz[3], blizz[4] = r, g, b, a
    local c = s.color
    if c then Paint(bar, c) end
end

local function GetHealthBar(plate)
    local uf = plate and plate.UnitFrame
    if not uf or uf:IsForbidden() then return nil end
    return uf.healthBar or (uf.HealthBarsContainer and uf.HealthBarsContainer.healthBar)
end

local function Update(unit, force)
    local bar = active[unit]
    if not bar then return end
    local s = state[bar]
    local c = Compute(unit)
    if c == s.color and not force then return end
    s.color = c
    if c then Paint(bar, c) else RestoreBlizzard(bar, s) end
end

local function UpdateAll(force)
    for unit in next, active do Update(unit, force) end
end
M.UpdateAll = UpdateAll

local function Attach(unit)
    local plate = C_NamePlate.GetNamePlateForUnit(unit) -- excludes forbidden plates
    local bar = GetHealthBar(plate)
    if not bar then return end
    local s = state[bar]
    if not s then
        s = { blizz = {} }
        state[bar] = s
        local b = s.blizz
        b[1], b[2], b[3], b[4] = bar:GetStatusBarColor()
    end
    if not hooked[bar] then
        hooked[bar] = true
        hooksecurefunc(bar, "SetStatusBarColor", OnSetStatusBarColor)
    end
    s.color = nil
    active[unit] = bar
    Update(unit, true)
end

local function Detach(unit)
    local bar = active[unit]
    if not bar then return end
    active[unit] = nil
    local s = state[bar]
    if s.color then
        s.color = nil
        RestoreBlizzard(bar, s)
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
function M:NAME_PLATE_UNIT_ADDED(_, unit)   Attach(unit) end
function M:NAME_PLATE_UNIT_REMOVED(_, unit) Detach(unit) end
function M:UNIT_THREAT_LIST_UPDATE(_, unit) if active[unit] then Update(unit) end end
function M:UNIT_CLASSIFICATION_CHANGED(_, unit) if active[unit] then Update(unit) end end
function M:QUEST_LOG_UPDATE() UpdateAll() end
function M:GROUP_ROSTER_UPDATE() UpdateAll() end
function M:RoleChanged() UpdateRole(); UpdateAll() end

local EVENTS = {
    NAME_PLATE_UNIT_ADDED = "NAME_PLATE_UNIT_ADDED",
    NAME_PLATE_UNIT_REMOVED = "NAME_PLATE_UNIT_REMOVED",
    UNIT_THREAT_LIST_UPDATE = "UNIT_THREAT_LIST_UPDATE",
    UNIT_CLASSIFICATION_CHANGED = "UNIT_CLASSIFICATION_CHANGED",
    QUEST_LOG_UPDATE = "QUEST_LOG_UPDATE",
    GROUP_ROSTER_UPDATE = "GROUP_ROSTER_UPDATE",
    PLAYER_ROLES_ASSIGNED = "RoleChanged",
    PLAYER_SPECIALIZATION_CHANGED = "RoleChanged",
}

function M:OnEnable()
    db = ns.db.nameplates.colors
    UpdateRole()
    for event, method in next, EVENTS do
        ns:RegisterEvent(event, self, self[method])
    end
    -- Nameplates that are already on screen.
    local plates = C_NamePlate.GetNamePlates()
    for i = 1, #plates do
        local plate = plates[i]
        local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
        if unit then Attach(unit) end
    end
end

function M:OnDisable()
    for event in next, EVENTS do
        ns:UnregisterEvent(event, self)
    end
    for unit in next, active do Detach(unit) end
    wipe(active)
    wipe(state) -- hooks left from this session now return on their first check
end
