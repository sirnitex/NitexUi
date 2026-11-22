-- NitexUI: Unit Frames (Retail only)
--
-- Small changes to Blizzard's own player, target and focus frames.
--   Player: hide class resources, totem frame, combat text (hit indicator), resting "Zzz",
--           resting glow.
--   Target: hide the reputation colour strip behind the name.
--   Focus:  hide buffs/debuffs.
--
-- How (frame names from Blizzard's 12.1.5 UI source):
--   * Class resources + TotemFrame: moved under a hidden parent (same technique as
--     Interface > General); original parent restored when turned off. Druid combo points,
--     Monk chi and Mage arcane charges are faded with alpha instead, as they move between
--     forms/specs. Reparenting waits until combat ends.
--   * Combat text, Zzz, reputation colour: alpha 0 (Blizzard keeps showing/hiding them).
--   * Resting glow: one hooksecurefunc on PlayerFrame_UpdateStatus (event driven, not per
--     frame) sets the glow's vertex alpha to 0 while resting. The combat glow is untouched.
--   * Focus auras: one hooksecurefunc on FocusFrame:ConfigureAuraContainer hides the aura
--     container after Blizzard shows it.
-- No events, no OnUpdate. Hooks are installed the first time an option is used and return
-- immediately when off (hooks cannot be removed).

local _, ns = ...
if not ns.isRetail then return end

local M = ns:NewModule("UnitFrames")
ns.UnitFrames = M

ns.defaults.unitframes = {
    hideClassResources = false,
    hideTotems = false,
    hideCombatText = false,
    hideRestZzz = false,
    hideRestGlow = false,
    hideTargetRepColor = false,
    hideFocusAuras = false,
}

local db

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local hiddenParent
local originalParent = {}

local function Reparent(frame, hide)
    if not frame then return end
    if hide then
        if originalParent[frame] then return end
        if not hiddenParent then
            hiddenParent = CreateFrame("Frame")
            hiddenParent:Hide()
        end
        originalParent[frame] = frame:GetParent()
        frame:SetParent(hiddenParent)
    elseif originalParent[frame] then
        frame:SetParent(originalParent[frame])
        originalParent[frame] = nil
    end
end

local faded = {} -- [frame] = mouse was enabled before we faded it

local function Fade(frame, hide)
    if not frame then return end
    if hide then
        if faded[frame] ~= nil then return end
        faded[frame] = frame.IsMouseEnabled and frame:IsMouseEnabled() or false
        frame:SetAlpha(0)
        if frame.EnableMouse then frame:EnableMouse(false) end
    elseif faded[frame] ~= nil then
        frame:SetAlpha(1)
        if frame.EnableMouse then frame:EnableMouse(faded[frame]) end
        faded[frame] = nil
    end
end

local function PlayerMain()
    local c = PlayerFrame and PlayerFrame.PlayerFrameContent
    return c and c.PlayerFrameContentMain
end

local function PlayerContextual()
    local c = PlayerFrame and PlayerFrame.PlayerFrameContent
    return c and c.PlayerFrameContentContextual
end

---------------------------------------------------------------------------
-- Player
---------------------------------------------------------------------------
-- Resource bars that are reparented / faded. Functions: a frame missing in a patch is skipped.
local REPARENT_RESOURCES = {
    function() return RogueComboPointBarFrame end,
    function() return PaladinPowerBarFrame end,
    function() return WarlockPowerFrame end,
    function() return RuneFrame end,
    function() return EssencePlayerFrame end,
}
local FADE_RESOURCES = {
    function() return DruidComboPointBarFrame end,
    function() return MonkHarmonyBarFrame end,
    function() return MageArcaneChargesFrame end,
}

local function ApplyReparented(on) -- needs out of combat
    local hide = on and db.hideClassResources
    for i = 1, #REPARENT_RESOURCES do Reparent(REPARENT_RESOURCES[i](), hide) end
    Reparent(TotemFrame, on and db.hideTotems)
end

local function ApplyFaded(on)
    local hide = on and db.hideClassResources
    for i = 1, #FADE_RESOURCES do Fade(FADE_RESOURCES[i](), hide) end

    local main, ctx = PlayerMain(), PlayerContextual()
    if main and main.HitIndicator then main.HitIndicator:SetAlpha((on and db.hideCombatText) and 0 or 1) end
    if ctx and ctx.PlayerRestLoop then ctx.PlayerRestLoop:SetAlpha((on and db.hideRestZzz) and 0 or 1) end
end

-- Resting glow: Blizzard colours StatusTexture yellow when resting (red in combat) and
-- pulses its alpha. A vertex alpha of 0 hides the resting one; the next status update
-- (combat, leaving the inn) sets its own colour again.
local restGlowActive, restGlowHooked = false, false

local function OnUpdateStatus()
    if not restGlowActive or not IsResting() then return end
    local main = PlayerMain()
    local glow = main and main.StatusTexture
    if glow then glow:SetVertexColor(1.0, 0.88, 0.25, 0) end
end

local function ApplyRestGlow(on)
    restGlowActive = on and db.hideRestGlow or false
    if restGlowActive and not restGlowHooked and PlayerFrame_UpdateStatus then
        restGlowHooked = true
        hooksecurefunc("PlayerFrame_UpdateStatus", OnUpdateStatus)
    end
    if PlayerFrame_UpdateStatus then PlayerFrame_UpdateStatus() end -- repaint now (either way)
end

---------------------------------------------------------------------------
-- Target / Focus
---------------------------------------------------------------------------
local function ApplyTargetRep(on)
    local main = TargetFrame and TargetFrame.TargetFrameContent and TargetFrame.TargetFrameContent.TargetFrameContentMain
    local rep = main and main.ReputationColor
    if rep then rep:SetAlpha((on and db.hideTargetRepColor) and 0 or 1) end
end

local focusActive, focusHooked = false, false

local function OnFocusConfigure(self)
    if focusActive then self:GetAuraContainer():Hide() end
end

local function ApplyFocusAuras(on)
    if not (FocusFrame and FocusFrame.GetAuraContainer) then return end
    focusActive = on and db.hideFocusAuras or false
    if focusActive and not focusHooked then
        focusHooked = true
        hooksecurefunc(FocusFrame, "ConfigureAuraContainer", OnFocusConfigure)
    end
    if focusActive then
        FocusFrame:GetAuraContainer():Hide()
    elseif focusHooked and FocusFrame.unit and UnitExists(FocusFrame.unit) then
        FocusFrame:GetAuraContainer():Show() -- Blizzard keeps it updated from here
    end
end

---------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------
function M:OnCombatEnded()
    ns:UnregisterEvent("PLAYER_REGEN_ENABLED", self)
    self:Apply()
end

--- Bring everything in line with the current settings. Off = everything restored.
function M:Apply()
    db = ns.db.unitframes
    local on = self.enabled
    ApplyFaded(on)
    ApplyRestGlow(on)
    ApplyTargetRep(on)
    ApplyFocusAuras(on)
    if InCombatLockdown() then
        ns:RegisterEvent("PLAYER_REGEN_ENABLED", self, self.OnCombatEnded)
    else
        ApplyReparented(on)
    end
end

function M:OnEnable()
    self:Apply()
end

function M:OnDisable()
    self:Apply()
end
