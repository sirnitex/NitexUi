-- NitexUI: Minimap button
--
-- A classic round minimap button built only from native frames and Blizzard's own
-- minimap textures (no LibDBIcon). Left-click opens the options window.
--
-- Dragging keeps the button on the minimap edge: an OnUpdate script is attached ONLY while
-- the mouse button is held, reads the cursor angle from the minimap centre and places the
-- button on the ring. It is removed the moment you let go, so nothing runs otherwise.
--
-- When OFF: the button is hidden (created only the first time the module is turned on);
-- no events, no hooks, nothing runs.

local _, ns = ...
local M = ns:NewModule("MinimapButton")

ns.defaults.minimap = { angle = 225 } -- degrees, 0 = right, counter-clockwise

local ICON = [[Interface\AddOns\NitexUI\Media\NitexUI-Icon]]
local button

local GetCursorPosition, atan2, deg, rad, cos, sin = GetCursorPosition, math.atan2, math.deg, math.rad, math.cos, math.sin

local function UpdatePosition()
    local angle = rad(ns.db.minimap.angle)
    local radius = Minimap:GetWidth() / 2 + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", cos(angle) * radius, sin(angle) * radius)
end

-- Runs only while dragging.
local function OnDragUpdate()
    local mx, my = Minimap:GetCenter()
    if not mx then return end
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    ns.db.minimap.angle = deg(atan2(cy / scale - my, cx / scale - mx))
    UpdatePosition()
end

local function OnDragStart(self)
    GameTooltip:Hide()
    self:LockHighlight()
    self:SetScript("OnUpdate", OnDragUpdate)
end

local function OnDragStop(self)
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
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
