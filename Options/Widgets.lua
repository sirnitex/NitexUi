-- NitexUI: Options widgets
-- Small, flat UI building blocks made only from native frames and colour textures.
-- Everything here is created once when the options window is first opened.

local _, ns = ...
local T = ns.Theme
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
function W.Fill(parent, layer, color)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetColorTexture(unpack(color))
    return t
end

--- 1 physical pixel border on all four sides.
function W.AddBorder(frame, color)
    color = color or T.border
    local b = {}
    for i = 1, 4 do
        b[i] = frame:CreateTexture(nil, "BORDER")
        b[i]:SetColorTexture(unpack(color))
    end
    b[1]:SetPoint("TOPLEFT");    b[1]:SetPoint("TOPRIGHT");    PixelUtil.SetHeight(b[1], 1)
    b[2]:SetPoint("BOTTOMLEFT"); b[2]:SetPoint("BOTTOMRIGHT"); PixelUtil.SetHeight(b[2], 1)
    b[3]:SetPoint("TOPLEFT");    b[3]:SetPoint("BOTTOMLEFT");  PixelUtil.SetWidth(b[3], 1)
    b[4]:SetPoint("TOPRIGHT");   b[4]:SetPoint("BOTTOMRIGHT"); PixelUtil.SetWidth(b[4], 1)
    frame.borders = b
end

function W.SetBorderColor(frame, color)
    local r, g, b, a = unpack(color)
    for i = 1, 4 do frame.borders[i]:SetColorTexture(r, g, b, a) end
end

function W.Text(parent, font, text)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(font or W.FontNormal)
    fs:SetJustifyH("LEFT")
    fs:SetText(text or "")
    return fs
end

---------------------------------------------------------------------------
-- Section header: accent text with a thin divider underneath
---------------------------------------------------------------------------
function W.Header(parent, text)
    local f = CreateFrame("Frame", nil, parent)
    f:SetHeight(26)
    local fs = W.Text(f, W.FontHeader, text)
    fs:SetPoint("BOTTOMLEFT", 0, 7)
    local line = W.Fill(f, "ARTWORK", T.border)
    line:SetPoint("BOTTOMLEFT")
    line:SetPoint("BOTTOMRIGHT")
    PixelUtil.SetHeight(line, 1)
    return f
end

---------------------------------------------------------------------------
-- Paragraph of dimmed text
---------------------------------------------------------------------------
function W.Paragraph(parent, text, font)
    local f = CreateFrame("Frame", nil, parent)
    local fs = W.Text(f, font or W.FontSmall, text)
    fs:SetPoint("TOPLEFT")
    fs:SetPoint("TOPRIGHT")
    fs:SetJustifyV("TOP")
    fs:SetSpacing(3)
    f.text = fs
    -- Height follows the wrapped text; refreshed when the frame is sized.
    f:SetHeight(16)
    f:SetScript("OnSizeChanged", function(self)
        local h = self.text:GetStringHeight() + 2
        if math.abs(self:GetHeight() - h) > 0.5 then self:SetHeight(h) end
    end)
    return f
end

---------------------------------------------------------------------------
-- Button
---------------------------------------------------------------------------
local function Button_OnEnter(self)
    self.bg:SetColorTexture(unpack(T.elementHover))
    W.SetBorderColor(self, T.accent)
end

local function Button_OnLeave(self)
    self.bg:SetColorTexture(unpack(T.element))
    W.SetBorderColor(self, T.border)
end

function W.Button(parent, label, width, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width or 140, 26)
    b.bg = W.Fill(b, "BACKGROUND", T.element)
    b.bg:SetAllPoints()
    W.AddBorder(b)

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
local function Toggle_Refresh(self)
    local on = self.getter()
    local knob, track = self.knob, self.track
    knob:ClearAllPoints()
    if on then
        knob:SetPoint("RIGHT", track, "RIGHT", -3, 0)
        knob:SetColorTexture(1, 1, 1, 1)
        track.bg:SetColorTexture(unpack(T.accent))
    else
        knob:SetPoint("LEFT", track, "LEFT", 3, 0)
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
    W.SetBorderColor(self.track, T.accent)
    self.label:SetTextColor(unpack(T.accent))
end

local function Toggle_OnLeave(self)
    W.SetBorderColor(self.track, T.border)
    self.label:SetTextColor(unpack(T.text))
end

function W.Toggle(parent, label, desc, getter, setter)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(desc and 40 or 26)
    row.getter, row.setter = getter, setter

    local track = CreateFrame("Frame", nil, row)
    track:SetSize(34, 18)
    track:SetPoint("RIGHT")
    track.bg = W.Fill(track, "BACKGROUND", T.element)
    track.bg:SetAllPoints()
    W.AddBorder(track)
    row.track = track

    local knob = track:CreateTexture(nil, "ARTWORK")
    knob:SetSize(12, 12)
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
    b:SetHeight(32)

    b.hl = W.Fill(b, "BACKGROUND", T.elementHover)
    b.hl:SetAllPoints()
    b.hl:Hide()

    b.bar = W.Fill(b, "ARTWORK", T.accent)
    b.bar:SetPoint("TOPLEFT")
    b.bar:SetPoint("BOTTOMLEFT")
    PixelUtil.SetWidth(b.bar, 2)
    b.bar:Hide()

    b.text = W.Text(b, W.FontNormal, label)
    b.text:SetPoint("LEFT", 16, 0)

    b.SetSelected = Tab_SetSelected
    b:SetScript("OnEnter", Tab_OnEnter)
    b:SetScript("OnLeave", Tab_OnLeave)
    b:SetScript("OnClick", onClick)
    return b
end
