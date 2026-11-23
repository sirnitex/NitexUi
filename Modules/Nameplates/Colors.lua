-- NitexUI: Nameplates > Health Colors
--
-- Recolours the health bar of Blizzard's OWN enemy nameplates. No custom nameplates.
-- Priority: Tapped (Forever only) > Threat > Quest mob > Neutral (out of combat) > Classification.
-- If nothing applies, Blizzard's colour stays.
--
-- APIs (all native, all secret-checked):
--   UnitIsTapDenied(unit)                       Forever: tagged by someone else, no loot for you
--   UnitThreatSituation("player", unit)        threat status 0-3 (type only, never the raw value)
--   C_QuestLog.UnitIsRelatedToActiveQuest(unit) quest mob
--   UnitIsQuestBoss(unit)                       quest kill target
--   UnitClassification, UnitEffectiveLevel,     classification (boss tiers by effective level
--   UnitIsLieutenant (12.0+),                   vs. yours: skull / +2 = boss, lieutenant / +1 =
--   UnitHasPowerType(unit, Mana)                mini-boss), caster = has a mana pool
--
-- Taint-safe design:
--   * All API calls happen in OUR event handler. The colour is cached per health bar.
--   * One hooksecurefunc on each health bar's SetStatusBarColor re-paints our cached colour
--     whenever Blizzard paints; the hook makes no API calls, only a table lookup.
--   * Per-bar state lives in a weak table, never as keys on Blizzard's frames.
--   * Forbidden nameplates (friendly plates in instances) are never touched.
--
-- Cost while ON: a few API calls per nameplate when it appears, when its threat list
-- changes, or when your quests/role change. Events are only registered for colours that are
-- on: UNIT_FLAGS/UNIT_FACTION for Neutral (or, on Forever, Tapped), UNIT_THREAT_LIST_UPDATE/
-- GROUP_ROSTER_UPDATE for Threat / Threat %, QUEST_LOG_UPDATE for Quest (bursts merged, 0.2 s).
-- GROUP_ROSTER_UPDATE only repaints when you join or leave a group. Nothing per frame.
-- When OFF: no events. Hooks cannot be removed in WoW, so a bar hooked earlier this session
-- returns immediately on its first line until you /reload.

local _, ns = ...
local M = ns:NewModule("NameplateColors")
ns.NameplateColors = M

local next = next
local UnitThreatSituation, UnitClassification, UnitCanAttack, UnitIsPlayer =
      UnitThreatSituation, UnitClassification, UnitCanAttack, UnitIsPlayer
local issecretvalue = issecretvalue or function() return false end
local UnitIsRelatedToActiveQuest = C_QuestLog and C_QuestLog.UnitIsRelatedToActiveQuest
local UnitIsQuestBoss, UnitIsTapDenied, IsInGroup = UnitIsQuestBoss, UnitIsTapDenied, IsInGroup
local UnitIsLieutenant, UnitEffectiveLevel, UnitHasPowerType = UnitIsLieutenant, UnitEffectiveLevel or UnitLevel, UnitHasPowerType
local MANA = Enum and Enum.PowerType and Enum.PowerType.Mana
local UnitReaction, UnitIsEnemy, UnitAffectingCombat = UnitReaction, UnitIsEnemy, UnitAffectingCombat
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitGroupRolesAssigned, UnitIsUnit, IsInRaid, GetNumGroupMembers, type =
      UnitGroupRolesAssigned, UnitIsUnit, IsInRaid, GetNumGroupMembers, type
local EvalBool = C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean

---------------------------------------------------------------------------
-- Defaults
---------------------------------------------------------------------------
local function C(r, g, b) return { r, g, b } end

ns.defaults.nameplates = ns.defaults.nameplates or {}
ns.defaults.nameplates.colors = {
    tapped = { enabled = true, color = C(0.55, 0.55, 0.55) }, -- Forever only
    threat = {
        enabled = true,
        groupOnly = true,
        percent = false, -- "| 100%" right after the mob name (your scaled threat on that mob)
        good    = { enabled = true, color = C(0.20, 0.80, 0.30) }, -- tank: you hold aggro.   others: (not used)
        warning = { enabled = true, color = C(1.00, 0.60, 0.10) }, -- aggro is about to change
        danger  = { enabled = true, color = C(0.95, 0.15, 0.15) }, -- tank: you lost aggro.   others: you have aggro
        offtank = { enabled = true, color = C(0.19, 0.76, 0.81) }, -- tank: another tank has aggro
    },
    quest = { enabled = true, color = C(0.35, 0.75, 1.00) },
    typesVersion = 4,
    types = { -- Classification colours
        worldboss = { enabled = true, color = C(0.82, 0.70, 0.05) },
        eliteboss = { enabled = true, color = C(0.85, 0.30, 0.65) },
        elitemini = { enabled = true, color = C(0.45, 0.30, 0.80) },
        rareelite = { enabled = true, color = C(0.00, 0.75, 0.60) },
        rare      = { enabled = true, color = C(0.30, 0.75, 0.00) },
        caster    = { enabled = true, color = C(0.00, 0.50, 0.80) },
        enemy     = { enabled = true, color = C(0.80, 0.14, 0.14) }, -- every other enemy
        neutral   = { enabled = true, color = C(0.81, 0.72, 0.19) }, -- neutral, out of combat
    },
}

-- Order + labels used by the options page (also the priority, first wins).
-- Neutral is listed last but checked first: a neutral mob out of combat gets it; once it
-- fights it uses the colours above like any enemy.
M.typeOrder = { "worldboss", "eliteboss", "elitemini", "rareelite", "rare", "caster", "enemy", "neutral" }
M.threatOrder = { "good", "warning", "danger", "offtank" }

-- Profiles saved before 0.15.1 had other enemy types: replace them once with the new set.
-- 0.15.3 merged Mini Enemy into Enemy.
function M:OnInitialize()
    local c = ns.db.nameplates and ns.db.nameplates.colors
    if not c then return end
    if (c.typesVersion or 0) < 3 then
        c.types = CopyTable(ns.defaults.nameplates.colors.types)
    elseif c.typesVersion < 4 then
        c.types.minienemy = nil
    end
    c.typesVersion = 4
end

---------------------------------------------------------------------------
-- Player role (cached; refreshed only when the role can change)
---------------------------------------------------------------------------
local isTank = false
local inGroup = false -- cached; changes only on GROUP_ROSTER_UPDATE

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

local function Known(v) return v ~= nil and not issecretvalue(v) end

---------------------------------------------------------------------------
-- Off-tank (tank role only), as EllesmereUI does it:
--   1. Plain: the mob's target has the TANK role -> off-tank colour.
--   2. Secret (Midnight instances: roles and isTanking can be secret): ask the other way
--      round, "is another tank tanking this mob", with UnitDetailedThreatSituation(tank, mob)
--      and fold the answer through C_CurveUtil.EvaluateColorValueFromBoolean. The result may
--      be SECRET r,g,b: only handed to SetStatusBarColor, never compared or formatted.
--   One tank holds a mob, so the fold starts from your threat colour and flips to the
--   off-tank colour only when another tank's isTanking is true.
-- Other tanks: up to 3 group members with the TANK role, rebuilt lazily after roster/role events.
---------------------------------------------------------------------------
local tanks, tanksDirty = {}, true
local targetOf = setmetatable({}, { __index = function(t, k) local v = k .. "target"; t[k] = v; return v end })
local folds = {} -- [unitToken] = { r, g, b } reused per plate token

local function RebuildTanks()
    tanksDirty = false
    wipe(tanks)
    local prefix, count
    if IsInRaid() then prefix, count = "raid", GetNumGroupMembers()
    elseif IsInGroup() then prefix, count = "party", GetNumGroupMembers() - 1 end
    if not prefix then return end
    local n = 0
    for i = 1, count do
        if n >= 3 then break end
        local tok = prefix .. i
        if not UnitIsUnit(tok, "player") and UnitGroupRolesAssigned(tok) == "TANK" then
            n = n + 1
            tanks[n] = tok
        end
    end
end

local function OffTankFold(unit, base, ot)
    if not EvalBool then return nil end
    if tanksDirty then RebuildTanks() end
    if not tanks[1] then return nil end
    local r, g, b = base[1], base[2], base[3]
    local o1, o2, o3 = ot[1], ot[2], ot[3]
    local any = false
    for i = 1, #tanks do
        local isTanking = UnitDetailedThreatSituation(tanks[i], unit)
        if type(isTanking) == "boolean" then -- type() is allowed on secrets
            r = EvalBool(isTanking, o1, r)
            g = EvalBool(isTanking, o2, g)
            b = EvalBool(isTanking, o3, b)
            any = true
        end
    end
    if not any then return nil end
    local f = folds[unit]
    if not f then f = {}; folds[unit] = f end
    f[1], f[2], f[3] = r, g, b
    return f
end

-- Returns colour, isFold (a fold must always be repainted: same table, new values).
local function TankThreat(unit, status)
    local t = db.threat
    local ot = t.offtank
    if not ot.enabled then return ThreatColor(status) end
    if status < 2 then -- you are not tanking it
        local role = UnitGroupRolesAssigned(targetOf[unit])
        if not issecretvalue(role) and role == "TANK" then return ot.color end
    end
    local base = ThreatColor(status)
    if base then
        local f = OffTankFold(unit, base, ot.color)
        if f then return f, true end
    end
    return base
end

-- Boss tiers come from the mob's effective level compared to yours (handles level scaling
-- and Chromie Time): a skull (-1) or 2+ levels above = boss, 1 above or a lieutenant = mini-boss.
local function BossTier(unit, cls)
    if cls ~= "elite" and cls ~= "rareelite" and cls ~= "worldboss" then return nil end
    local lvl, my = UnitEffectiveLevel(unit), UnitEffectiveLevel("player")
    if not (Known(lvl) and Known(my)) then return nil end
    local skull = lvl == -1
    if not (skull or lvl >= my + 1) then return nil end
    local lieutenant = not skull and UnitIsLieutenant and UnitIsLieutenant(unit)
    if Known(lieutenant) and lieutenant then return "elitemini" end
    if skull or lvl >= my + 2 then return "eliteboss" end
    return "elitemini"
end

local function Classify(unit)
    local cls = UnitClassification(unit)
    if not Known(cls) then return nil end
    if cls == "worldboss" then return "worldboss" end

    local tier = BossTier(unit, cls)
    if tier then return tier end

    if cls == "rareelite" then return "rareelite" end
    if cls == "rare" then return "rare" end

    -- Caster = the mob has a mana pool.
    if MANA and UnitHasPowerType then
        local mana = UnitHasPowerType(unit, MANA)
        if Known(mana) and mana then return "caster" end
    end

    return "enemy"
end

local function Compute(unit)
    local attackable = UnitCanAttack("player", unit)
    if issecretvalue(attackable) or not attackable then return nil end
    local player = UnitIsPlayer(unit)
    if issecretvalue(player) or player then return nil end

    -- 0. Tapped by someone else (Forever only): always wins, you cannot loot it.
    if ns.isForever and db.tapped.enabled and UnitIsTapDenied then
        local tapped = UnitIsTapDenied(unit)
        if not issecretvalue(tapped) and tapped then return db.tapped.color end
    end

    -- 1. Threat
    local t = db.threat
    if t.enabled and (not t.groupOnly or inGroup) then
        local status = UnitThreatSituation("player", unit)
        if status ~= nil and not issecretvalue(status) then
            local c, fold
            if isTank then c, fold = TankThreat(unit, status) else c = ThreatColor(status) end
            if c then return c, fold end
        end
    end

    -- 2. Quest mob
    if db.quest.enabled then
        local q = UnitIsRelatedToActiveQuest and UnitIsRelatedToActiveQuest(unit)
        if not issecretvalue(q) and q then return db.quest.color end
        q = UnitIsQuestBoss and UnitIsQuestBoss(unit)
        if not issecretvalue(q) and q then return db.quest.color end
    end

    -- 3. Neutral mob, out of combat (reaction 4, or attackable without being hostile)
    local n = db.types.neutral
    if n and n.enabled then
        local reaction = UnitReaction(unit, "player")
        local neutral = Known(reaction) and reaction == 4
        if not neutral then
            local enemy = UnitIsEnemy(unit, "player")
            neutral = Known(enemy) and not enemy
        end
        if neutral then
            local fighting = UnitAffectingCombat(unit)
            if Known(fighting) and not fighting then return n.color end
        end
    end

    -- 4. Classification (priority = M.typeOrder)
    local key = Classify(unit)
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

-- Threat % right after the mob name, same font and size as the name: "| 100%".
-- The percentage is secret in Retail: handed straight to SetFormattedText, never compared.
local function GetPercentText(s)
    local fs = s.pct
    if fs then return fs end
    local uf = s.uf
    if not (uf and uf.name) then return nil end
    fs = uf:CreateFontString(nil, "OVERLAY")
    fs:SetTextColor(1, 1, 1)
    s.pct = fs
    return fs
end

-- Same font as the name, placed where the name's text ends (the name can be wider than its
-- text and centred). Only re-done when the name's font or text width changes.
local function FollowName(s, fs)
    local name = s.uf.name
    local path, size, flags = name:GetFont()
    if path and not issecretvalue(size) and (size ~= s.pctSize or path ~= s.pctPath) then
        local obj = name:GetFontObject()
        if obj then fs:SetFontObject(obj) end
        fs:SetFont(path, size, flags)
        s.pctSize, s.pctPath = size, path
    end
    local w, nw = name:GetStringWidth(), name:GetWidth()
    if issecretvalue(w) or issecretvalue(nw) then
        if s.pctW ~= false then
            s.pctW = false
            fs:ClearAllPoints()
            fs:SetPoint("LEFT", name, "RIGHT", 2, 0)
        end
        return
    end
    if nw > 0 and w > nw then w = nw end
    if w == s.pctW then return end
    s.pctW = w
    fs:ClearAllPoints()
    local j = name:GetJustifyH()
    if j == "LEFT" then
        fs:SetPoint("LEFT", name, "LEFT", w + 2, 0)
    elseif j == "RIGHT" then
        fs:SetPoint("LEFT", name, "RIGHT", 2, 0)
    else
        fs:SetPoint("LEFT", name, "CENTER", w / 2 + 2, 0)
    end
end

local function UpdatePercent(unit)
    local bar = active[unit]
    if not bar then return end
    local s = state[bar]
    local t = db.threat
    local pct
    if t.percent and (not t.groupOnly or inGroup) then
        local _, _, p = UnitDetailedThreatSituation("player", unit)
        pct = p
    end
    if issecretvalue(pct) or pct then
        local fs = GetPercentText(s)
        if fs then
            FollowName(s, fs)
            fs:SetFormattedText("|| %.0f%%", pct) -- "||" = a literal "|" in WoW text
            fs:Show()
        end
    elseif s.pct then
        s.pct:Hide()
    end
end

local function Update(unit, force)
    local bar = active[unit]
    if not bar then return end
    local s = state[bar]
    local c, fold = Compute(unit)
    if c == s.color and not force and not fold then return end
    s.color = c
    if c then Paint(bar, c) else RestoreBlizzard(bar, s) end
end

local function UpdateAll(force)
    for unit in next, active do Update(unit, force); UpdatePercent(unit) end
end

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
    s.uf = plate.UnitFrame
    s.pctW = nil -- new mob: measure the name again
    s.color = nil
    active[unit] = bar
    Update(unit, true)
    UpdatePercent(unit)
end

local function Detach(unit)
    local bar = active[unit]
    if not bar then return end
    active[unit] = nil
    local s = state[bar]
    if s.pct then s.pct:Hide() end
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
function M:UNIT_THREAT_LIST_UPDATE(_, unit) if active[unit] then Update(unit); UpdatePercent(unit) end end
function M:UNIT_CLASSIFICATION_CHANGED(_, unit) if active[unit] then Update(unit) end end
function M:UnitChanged(_, unit) if active[unit] then Update(unit) end end
-- QUEST_LOG_UPDATE comes in bursts (several per quest objective): one repaint per burst.
local questPending = false
local function QuestRepaint()
    questPending = false
    if M.enabled then UpdateAll() end
end
function M:QUEST_LOG_UPDATE()
    if questPending then return end
    questPending = true
    C_Timer.After(0.2, QuestRepaint)
end

-- Fires for every roster change in a raid; only joining/leaving a group changes our colours.
function M:GROUP_ROSTER_UPDATE()
    tanksDirty = true
    local g = IsInGroup()
    if g == inGroup then return end
    inGroup = g
    UpdateAll()
end
function M:RoleChanged() tanksDirty = true; UpdateRole(); UpdateAll() end

local EVENTS = {
    NAME_PLATE_UNIT_ADDED = "NAME_PLATE_UNIT_ADDED",
    NAME_PLATE_UNIT_REMOVED = "NAME_PLATE_UNIT_REMOVED",
    UNIT_CLASSIFICATION_CHANGED = "UNIT_CLASSIFICATION_CHANGED",
    PLAYER_ROLES_ASSIGNED = "RoleChanged",
    PLAYER_SPECIALIZATION_CHANGED = "RoleChanged",
}

-- Events only a colour that is on needs. `on` = registered now.
--   flags:  Neutral (a neutral mob entering combat) or, on Forever, Tapped (a mob turning grey)
--   threat: threat colours;  quest: quest mob colour
local OPTIONAL = {
    { on = false, events = { UNIT_FACTION = "UnitChanged", UNIT_FLAGS = "UnitChanged" },
      want = function() return (db.types.neutral and db.types.neutral.enabled) or (ns.isForever and db.tapped.enabled) end },
    { on = false, events = { UNIT_THREAT_LIST_UPDATE = "UNIT_THREAT_LIST_UPDATE", GROUP_ROSTER_UPDATE = "GROUP_ROSTER_UPDATE" },
      want = function() return db.threat.enabled or db.threat.percent end },
    { on = false, events = { QUEST_LOG_UPDATE = "QUEST_LOG_UPDATE" },
      want = function() return db.quest.enabled end },
}

local function RefreshOptionalEvents()
    inGroup = IsInGroup() -- GROUP_ROSTER_UPDATE is not watched while threat is off
    for i = 1, #OPTIONAL do
        local o = OPTIONAL[i]
        local want = (M.enabled and db and o.want()) and true or false
        if want ~= o.on then
            o.on = want
            for event, method in next, o.events do
                if want then ns:RegisterEvent(event, M, M[method]) else ns:UnregisterEvent(event, M) end
            end
        end
    end
end

--- Used by the options after any colour change: re-paints and adds/removes optional events.
function M.UpdateAll(force)
    RefreshOptionalEvents()
    UpdateAll(force)
end

function M:OnEnable()
    db = ns.db.nameplates.colors
    UpdateRole()
    for event, method in next, EVENTS do
        ns:RegisterEvent(event, self, self[method])
    end
    RefreshOptionalEvents()
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
    RefreshOptionalEvents() -- self.enabled is false here: removes them
    for unit in next, active do Detach(unit) end
    wipe(active)
    wipe(folds)
    wipe(tanks); tanksDirty = true
    wipe(state) -- hooks left from this session now return on their first check
end

---------------------------------------------------------------------------
-- /nitex np : what the module sees for your current target (for troubleshooting)
---------------------------------------------------------------------------
local function Show(v)
    if v == nil then return "nil" end
    if issecretvalue(v) then return "|cffff8800secret|r" end
    return tostring(v)
end

function M:Debug()
    local unit = "target"
    local P = function(...) ns:Print(...) end
    P("Nameplate colours: module", self.enabled and "ON" or "OFF")
    if not UnitExists(unit) then P("No target.") return end
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    P("Blizzard plate:", plate and "yes" or "no (forbidden or none)")
    local bar = GetHealthBar(plate)
    P("Health bar:", bar and "yes" or "no", "| visible:", bar and Show(bar:IsVisible()) or "-")
    local token = plate and (plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit))
    P("Token:", Show(token), "| tracked:", token and active[token] and "yes" or "no")
    P("CanAttack:", Show(UnitCanAttack("player", unit)), "| Reaction:", Show(UnitReaction(unit, "player")),
      "| IsEnemy:", Show(UnitIsEnemy(unit, "player")), "| InCombat:", Show(UnitAffectingCombat(unit)))
    P("Classification:", Show(UnitClassification(unit)), "| Level:", Show(UnitEffectiveLevel(unit)),
      "| Mana:", Show(MANA and UnitHasPowerType and UnitHasPowerType(unit, MANA)))
    if self.enabled and db then
        local c, fold = Compute(unit)
        if fold then P("Our colour: off-tank fold (may be secret)")
        else P("Our colour:", c and ("%.2f %.2f %.2f"):format(c[1], c[2], c[3]) or "none (Blizzard's)") end
    end
    if bar then
        local r, g, b = bar:GetStatusBarColor()
        P("Bar colour now:", Show(r), Show(g), Show(b))
    end
end
