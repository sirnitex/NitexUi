-- NitexUI: Minimap button
--
-- A classic round minimap button built only from native frames and Blizzard's own
-- minimap textures (no LibDBIcon). Left-click opens the options window.
--
-- Dragging uses Blizzard's StartMoving (no OnUpdate). When you let go, the angle from
-- the minimap centre is worked out once and the button snaps back onto the ring.
--
-- When OFF: the button is hidden (created only the first time the module is turned on);
-- no events, no hooks, nothing runs.

local _, ns = ...
local M = ns:NewModule("MinimapButton")

ns.defaults.minimap = { angle = 225 } -- degrees, 0 = right, counter-clockwise

local ICON = [[Interface\AddOns\NitexUI\Media\NitexUI-Icon]]
local button

local function UpdatePosition()
    local angle = math.rad(ns.db.minimap.angle)
    local radius = Minimap:GetWidth() / 2 + 6
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function OnDragStart(self)
    GameTooltip:Hide()
    self:StartMoving()
end

local function OnDragStop(self)
    self:StopMovingOrSizing()
    -- One-off: angle from the minimap centre to where the button was dropped.
    local mx, my = Minimap:GetCenter()
    local bx, by = self:GetCenter()
    if mx and bx then
        ns.db.minimap.angle = math.deg(math.atan2(by - my, bx - mx))
    end
    UpdatePosition()
end

local function OnClick()
    ns.Options:Toggle()
end

local function OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff" .. ns.Theme.accentHex .. "Nitex|rUI")
    GameTooltip:AddLine(ns.L["MINIMAP_TIP_CLICK"], 1, 1, 1)
    GameTooltip:AddLine(ns.L["MINIMAP_TIP_DRAG"], 1, 1, 1)
    GameTooltip:Show()
end

local function OnLeave()
    GameTooltip:Hide()
end

local function Create()
    button = CreateFrame("Button", "NitexUIMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:SetMovable(true)
    button:SetDontSavePosition(true)
    button:SetClampedToScreen(true)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture([[Interface\Minimap\UI-Minimap-ZoomButton-Highlight]])

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture([[Interface\Minimap\UI-Minimap-Background]])
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON)
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 7, -5)
    local mask = button:CreateMaskTexture()
    mask:SetTexture([[Interface\CharacterFrame\TempPortraitAlphaMask]], "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture([[Interface\Minimap\MiniMap-TrackingBorder]])
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    button:SetScript("OnClick", OnClick)
    button:SetScript("OnDragStart", OnDragStart)
    button:SetScript("OnDragStop", OnDragStop)
    button:SetScript("OnEnter", OnEnter)
    button:SetScript("OnLeave", OnLeave)
end

function M:OnEnable()
    if not button then Create() end
    UpdatePosition()
    button:Show()
end

function M:OnDisable()
    if button then button:Hide() end
end
