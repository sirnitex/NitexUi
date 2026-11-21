-- NitexUI: Options widgets
-- Small, flat UI building blocks made only from native frames and colour textures.
-- All geometry goes through ns.PP so every edge sits on the physical pixel grid.
-- Everything here is created once, when the options window is first opened.

local _, ns = ...
local T, PP = ns.Theme, ns.PP
local unpack = unpack

local W = {}
ns.Widgets = W

---------------------------------------------------------------------------
-- Fonts (native font objects, based on the client's own font file)
---------------------------------------------------------------------------
local FONT = GameFontHighlight:GetFont()

local function MakeFont(name, size, color)
    local f = CreateFont(name)
    f:SetFont(FONT, size, "")
    f:SetTextColor(unpack(color or T.text))
    f:SetShadowOffset(0, 0)
    return f
end

W.FontTitle  = MakeFont("NitexUIFont_Title", 17)
W.FontHeader = MakeFont("NitexUIFont_Header", 13, T.accent)
W.FontNormal = MakeFont("NitexUIFont_Normal", 12)
W.FontSmall  = MakeFont("NitexUIFont_Small", 11, T.textDim)

---------------------------------------------------------------------------
-- Primitives
---------------------------------------------------------------------------
--- Solid colour texture with Blizzard snapping disabled.
function W.Fill(parent, layer, color)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetColorTexture(unpack(color))
    PP.NoSnap(t)
    return t
end

--- Horizontal 1px line along the bottom (or top) edge of `parent`.
function W.HLine(parent, color, atTop)
    local t = W.Fill(parent, "ARTWORK", color)
    local edge = atTop and "TOP" or "BOTTOM"
    t:SetPoint(edge .. "LEFT")
    t:SetPoint(edge .. "RIGHT")
    PP.PixelHeight(t, 1)
    return t
end

--- Vertical 1px line along the right (or left) edge of `parent`.
function W.VLine(parent, color, atLeft)
    local t = W.Fill(parent, "ARTWORK", color)
    local edge = atLeft and "LEFT" or "RIGHT"
    t:SetPoint("TOP" .. edge)
    t:SetPoint("BOTTOM" .. edge)
    PP.PixelWidth(t, 1)
    return t
end

function W.Text(parent, font, text)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(font or W.FontNormal)
    fs:SetJustifyH("LEFT")
    fs:SetText(text or "")
    return fs
end

---------------------------------------------------------------------------
-- Section header: accent text with a 1px divider underneath
---------------------------------------------------------------------------
function W.Header(parent, text)
    local f = CreateFrame("Frame", nil, parent)
    PP.Height(f, 26)
    local fs = W.Text(f, W.FontHeader, text)
    fs:SetPoint("BOTTOMLEFT", 0, 7)
    W.HLine(f, T.border)
    return f
end

---------------------------------------------------------------------------
-- Paragraph of text. Height follows the wrapped text, rounded to whole pixels.
---------------------------------------------------------------------------
local function Paragraph_OnSizeChanged(self)
    PP.Height(self, self.text:GetStringHeight() + 2)
end

function W.Paragraph(parent, text, font)
    local f = CreateFrame("Frame", nil, parent)
    local fs = W.Text(f, font or W.FontSmall, text)
    fs:SetPoint("TOPLEFT")
    fs:SetPoint("TOPRIGHT")
    fs:SetJustifyV("TOP")
    fs:SetSpacing(3)
    f.text = fs
    PP.Height(f, 16)
    f:SetScript("OnSizeChanged", Paragraph_OnSizeChanged)
    return f
end

---------------------------------------------------------------------------
-- Button
---------------------------------------------------------------------------
local function Button_OnEnter(self)
    self.bg:SetColorTexture(unpack(T.elementHover))
    PP.SetBorderColor(self, T.accent)
end

local function Button_OnLeave(self)
    self.bg:SetColorTexture(unpack(T.element))
    PP.SetBorderColor(self, T.border)
end

function W.Button(parent, label, width, onClick)
    local b = CreateFrame("Button", nil, parent)
    PP.Size(b, width or 140, 26)
    b.bg = W.Fill(b, "BACKGROUND", T.element)
    b.bg:SetAllPoints()
    PP.Border(b, T.border)

    local fs = W.Text(b, W.FontNormal, label)
    fs:SetPoint("CENTER")
    fs:SetJustifyH("CENTER")

    b:SetScript("OnEnter", Button_OnEnter)
    b:SetScript("OnLeave", Button_OnLeave)
    b:SetScript("OnClick", function(self, ...)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
        onClick(self, ...)
    end)
    return b
end

---------------------------------------------------------------------------
-- Toggle switch:  [label / description ............ (o  )]
---------------------------------------------------------------------------
local TRACK_W, TRACK_H, KNOB, KNOB_PAD = 34, 18, 12, 3

local function Toggle_Refresh(self)
    local on = self.getter()
    local knob, track = self.knob, self.track
    if on then
        PP.Point(knob, "TOPLEFT", track, "TOPLEFT", TRACK_W - KNOB - KNOB_PAD, -KNOB_PAD)
        knob:SetColorTexture(1, 1, 1, 1)
        track.bg:SetColorTexture(unpack(T.accent))
    else
        PP.Point(knob, "TOPLEFT", track, "TOPLEFT", KNOB_PAD, -KNOB_PAD)
        knob:SetColorTexture(unpack(T.textDim))
        track.bg:SetColorTexture(unpack(T.element))
    end
end

local function Toggle_OnClick(self)
    local value = not self.getter()
    self.setter(value)
    PlaySound(value and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    self:Refresh()
end

local function Toggle_OnEnter(self)
    PP.SetBorderColor(self.track, T.accent)
    self.label:SetTextColor(unpack(T.accent))
end

local function Toggle_OnLeave(self)
    PP.SetBorderColor(self.track, T.border)
    self.label:SetTextColor(unpack(T.text))
end

function W.Toggle(parent, label, desc, getter, setter)
    local rowH = desc and 40 or 26
    local row = CreateFrame("Button", nil, parent)
    PP.Height(row, rowH)
    row.getter, row.setter = getter, setter

    -- Corner anchor + pixel-rounded offset keeps the track on the grid (no CENTER/RIGHT anchors).
    local track = CreateFrame("Frame", nil, row)
    PP.Size(track, TRACK_W, TRACK_H)
    PP.Point(track, "TOPRIGHT", row, "TOPRIGHT", 0, -(rowH - TRACK_H) / 2)
    track.bg = W.Fill(track, "BACKGROUND", T.element)
    track.bg:SetAllPoints()
    PP.Border(track, T.border)
    row.track = track

    local knob = W.Fill(track, "ARTWORK", T.textDim)
    PP.Size(knob, KNOB, KNOB)
    row.knob = knob

    row.label = W.Text(row, W.FontNormal, label)
    row.label:SetPoint("TOPLEFT", 0, desc and -4 or -6)
    row.label:SetPoint("RIGHT", track, "LEFT", -16, 0)

    if desc then
        local d = W.Text(row, W.FontSmall, desc)
        d:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -4)
        d:SetPoint("RIGHT", track, "LEFT", -16, 0)
    end

    row.Refresh = Toggle_Refresh
    row:SetScript("OnClick", Toggle_OnClick)
    row:SetScript("OnEnter", Toggle_OnEnter)
    row:SetScript("OnLeave", Toggle_OnLeave)
    row:Refresh()
    return row
end

---------------------------------------------------------------------------
-- Sidebar navigation tab
---------------------------------------------------------------------------
local function Tab_SetSelected(self, selected)
    self.selected = selected
    self.bar:SetShown(selected)
    self.hl:SetShown(selected)
    self.text:SetTextColor(unpack(selected and T.accent or T.text))
end

local function Tab_OnEnter(self) if not self.selected then self.hl:Show() end end
local function Tab_OnLeave(self) if not self.selected then self.hl:Hide() end end

function W.Tab(parent, label, onClick)
    local b = CreateFrame("Button", nil, parent)
    PP.Height(b, 32)

    b.hl = W.Fill(b, "BACKGROUND", T.elementHover)
    b.hl:SetAllPoints()
    b.hl:Hide()

    b.bar = W.VLine(b, T.accent, true)
    PP.PixelWidth(b.bar, 2)
    b.bar:Hide()

    b.text = W.Text(b, W.FontNormal, label)
    b.text:SetPoint("LEFT", 16, 0)

    b.SetSelected = Tab_SetSelected
    b:SetScript("OnEnter", Tab_OnEnter)
    b:SetScript("OnLeave", Tab_OnLeave)
    b:SetScript("OnClick", onClick)
    return b
end
