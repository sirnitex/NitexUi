-- NitexUI: Interface > Tooltip
--
-- Small changes to Blizzard's own GameTooltip:
--   * Hide the health bar under unit tooltips.
--   * Class-coloured names for players.
--
-- How (12.1.5 UI source, Blizzard_GameTooltip / Blizzard_SharedXMLGame):
--   * Health bar: Blizzard shows GameTooltip.StatusBar from StatusBar:SetWatch(guid).
--     One hooksecurefunc on SetWatch hides it again right away. A hidden bar also stops
--     its OnUpdate, so this saves a little work instead of costing any.
--   * Names: one TooltipDataProcessor post-call for unit tooltips recolours line 1 after
--     Blizzard has built the tooltip. Only GameTooltip, only players. The guid is checked
--     for secret values first.
-- No events, no OnUpdate, no frames. The hooks are installed the first time an option is
-- used; they cannot be removed, so while off they return on their first line.

local _, ns = ...
local M = ns:NewModule("InterfaceTooltip")
ns.InterfaceTooltip = M

ns.defaults.interface = ns.defaults.interface or {}
ns.defaults.interface.tooltip = {
    hideHealthBar = true,
    classColorNames = true,
}

local issecretvalue = issecretvalue or function() return false end
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local GUIDIsPlayer = C_PlayerInfo and C_PlayerInfo.GUIDIsPlayer
local GetClassColor = C_ClassColor and C_ClassColor.GetClassColor

local hideBar, classNames = false, false
local barHooked, namesHooked = false, false

---------------------------------------------------------------------------
-- Health bar
---------------------------------------------------------------------------
local function OnSetWatch(bar)
    if hideBar then bar:Hide() end
end

local function ApplyHealthBar(on)
    local bar = GameTooltip and GameTooltip.StatusBar
    if not bar then return end
    hideBar = on
    if on and not barHooked and bar.SetWatch then
        barHooked = true
        hooksecurefunc(bar, "SetWatch", OnSetWatch)
    end
    if on then bar:Hide() end
    -- Off: Blizzard shows the bar again on the next unit tooltip.
end

---------------------------------------------------------------------------
-- Class-coloured names
---------------------------------------------------------------------------
local function OnUnitTooltip(tooltip, data)
    if not classNames or tooltip ~= GameTooltip or not data then return end
    local guid = data.guid
    if not guid or issecretvalue(guid) then return end
    if GUIDIsPlayer and not GUIDIsPlayer(guid) then return end
    local _, classFile = GetPlayerInfoByGUID(guid)
    if not classFile or issecretvalue(classFile) then return end
    local color = GetClassColor and GetClassColor(classFile)
    local line = GameTooltipTextLeft1
    if color and line then line:SetTextColor(color.r, color.g, color.b) end
end

local function ApplyClassNames(on)
    classNames = on
    if on and not namesHooked and TooltipDataProcessor and Enum.TooltipDataType then
        namesHooked = true
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnUnitTooltip)
    end
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------
--- Bring everything in line with the settings. Off = Blizzard's look on the next tooltip.
function M:Apply()
    local db = ns.db.interface.tooltip
    local on = self.enabled
    ApplyHealthBar(on and db.hideHealthBar or false)
    ApplyClassNames(on and db.classColorNames or false)
end

function M:OnEnable()  self:Apply() end
function M:OnDisable() self:Apply() end
