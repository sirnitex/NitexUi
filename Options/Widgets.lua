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
-- Options window font: Expressway (bundled, same file ElvUI ships). Falls back to the client font.
local FONT = [[Interface\AddOns\NitexUI\Media\Fonts\Expressway.ttf]]

W.FONT_FILE = FONT

-- Font objects' SetFont returns nothing (only FontString/EditBox return success), so check
-- with GetFont: a new font object has no file until a SetFont succeeds.
local function MakeFont(name, size, color)
    local f = CreateFont(name)
    f:SetFont(FONT, size, "")
    if not f:GetFont() then f:SetFont(GameFontHighlight:GetFont(), size, "") end
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
local issecretvalue = issecretvalue or function() return false end

-- The text gets an EXPLICIT width (the frame's width) before it is measured. Measuring a
-- FontString that is only sized through anchors can happen before the layout pass, when
-- its width is still 0: the text then "wraps" after every letter and reports a huge height,
-- which pushed everything below the paragraph off the screen.
local function Paragraph_Layout(self, width)
    if not width or width <= 0 then return end
    self.text:SetWidth(width)
    local h = self.text:GetStringHeight()
    if h and not issecretvalue(h) and h > 0 then
        PP.Height(self, h + 2)
    end
end

local function Paragraph_OnSizeChanged(self, width)
    Paragraph_Layout(self, width)
end

local function Paragraph_SetText(self, text)
    self.text:SetText(text)
    Paragraph_Layout(self, self:GetWidth())
end

function W.Paragraph(parent, text, font)
    local f = CreateFrame("Frame", nil, parent)
    local fs = W.Text(f, font or W.FontSmall, text)
    fs:SetPoint("TOPLEFT")
    fs:SetJustifyV("TOP")
    fs:SetSpacing(3)
    f.text = fs
    f.SetText = Paragraph_SetText
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

---------------------------------------------------------------------------
-- Sub-tab (horizontal, inside a page):  Label
--                                        ‾‾‾‾‾ (2px accent when selected)
---------------------------------------------------------------------------
local function SubTab_SetSelected(self, selected)
    self.selected = selected
    self.bar:SetShown(selected)
    self.text:SetTextColor(unpack(selected and T.accent or T.textDim))
end

local function SubTab_OnEnter(self) if not self.selected then self.text:SetTextColor(unpack(T.text)) end end
local function SubTab_OnLeave(self) if not self.selected then self.text:SetTextColor(unpack(T.textDim)) end end

function W.SubTab(parent, label, onClick)
    local b = CreateFrame("Button", nil, parent)
    b.text = W.Text(b, W.FontNormal, label)
    b.text:SetPoint("CENTER", 0, 1)
    PP.Size(b, math.ceil(b.text:GetStringWidth()) + 28, parent:GetHeight())

    b.bar = W.HLine(b, T.accent)
    PP.PixelHeight(b.bar, 2)
    b.bar:Hide()

    b.SetSelected = SubTab_SetSelected
    b:SetScript("OnEnter", SubTab_OnEnter)
    b:SetScript("OnLeave", SubTab_OnLeave)
    b:SetScript("OnClick", onClick)
    b:SetSelected(false)
    return b
end

---------------------------------------------------------------------------
-- Dropdown
--   W.Dropdown(parent, label, width, items, getter, setter, fontFor)
--   items  = array of { value = ..., text = ... }, or a function returning one
--            (re-read on every refresh, for lists that change, e.g. profiles)
--   fontFor(value) -> font file, optional: each row (and the button) previews that font.
--   dd.placeholder = text shown when the current value matches no item.
-- The list is a plain child frame of the button; rows are created once and reused.
---------------------------------------------------------------------------
local DD_BTN_H, DD_ROW_H = 26, 24
local openList -- only one list open at a time

local function DDRow_OnClick(row)
    local dd = row.owner
    dd:Close()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    dd.setter(row.value)
    dd:Refresh()
end

local function DDRow_OnEnter(row) row.hl:Show() end
local function DDRow_OnLeave(row) row.hl:Hide() end

local function Dropdown_GetRow(self, i)
    local row = self.rows[i]
    if row then return row end
    row = CreateFrame("Button", nil, self.list)
    PP.Size(row, self.width, DD_ROW_H)
    PP.Point(row, "TOPLEFT", self.list, "TOPLEFT", 0, -1 - (i - 1) * DD_ROW_H)
    row.hl = W.Fill(row, "BACKGROUND", T.elementHover)
    row.hl:SetAllPoints()
    row.hl:Hide()
    row.check = W.Fill(row, "ARTWORK", T.accent)
    PP.Point(row.check, "TOPLEFT", row, "TOPLEFT", 0, 0)
    PP.Point(row.check, "BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    PP.PixelWidth(row.check, 2)
    row.text = W.Text(row, W.FontNormal, "")
    row.text:SetPoint("LEFT", 10, 0)
    row.owner = self
    row:SetScript("OnClick", DDRow_OnClick)
    row:SetScript("OnEnter", DDRow_OnEnter)
    row:SetScript("OnLeave", DDRow_OnLeave)
    self.rows[i] = row
    return row
end

local function Dropdown_SetItems(self, items)
    self.items = items
    for i = 1, #items do
        local item, row = items[i], self:GetRow(i)
        row.value = item.value
        row.text:SetText(item.text)
        if self.fontFor then row.text:SetFont(self.fontFor(item.value), 12, "") end
        row:Show()
    end
    for i = #items + 1, #self.rows do self.rows[i]:Hide() end
    PP.Height(self.list, math.max(#items, 1) * DD_ROW_H + 2)
end

local function Dropdown_Refresh(self)
    if self.itemsFunc then self:SetItems(self.itemsFunc()) end
    local value = self.getter()
    local text
    for i = 1, #self.items do
        local item = self.items[i]
        local selected = item.value == value
        if selected then text = item.text end
        self.rows[i].check:SetShown(selected)
    end
    self.button.text:SetText(text or self.placeholder or "")
    if self.fontFor and text then
        self.button.text:SetFont(self.fontFor(value), 12, "")
    end
end

local function Dropdown_Close(self)
    self.list:Hide()
    if openList == self.list then openList = nil end
end

--- Close whichever dropdown list is open (used when the options page scrolls).
function W.CloseDropdown()
    if openList then openList:Hide(); openList = nil end
end

local function DDButton_OnClick(button)
    local dd = button.owner
    if dd.list:IsShown() then
        dd:Close()
    else
        if openList then openList:Hide() end
        -- Pages can sit in a scroll frame, which clips its children. The open list is
        -- parented to the options window instead, so it is never cut off.
        local top = NitexUIOptionsFrame
        if top and dd.list:GetParent() ~= top then
            dd.list:SetParent(top)
            dd.list:SetFrameStrata("DIALOG")
        end
        dd:Refresh()
        dd.list:Show()
        openList = dd.list
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
    end
end

function W.Dropdown(parent, label, width, items, getter, setter, fontFor)
    local dd = CreateFrame("Frame", nil, parent)
    PP.Size(dd, width, 18 + DD_BTN_H)
    dd.width, dd.getter, dd.setter, dd.fontFor = width, getter, setter, fontFor
    if type(items) == "function" then
        dd.itemsFunc = items
        items = items()
    end

    local title = W.Text(dd, W.FontSmall, label)
    title:SetPoint("TOPLEFT")

    -- Button
    local button = CreateFrame("Button", nil, dd)
    PP.Size(button, width, DD_BTN_H)
    PP.Point(button, "TOPLEFT", dd, "TOPLEFT", 0, -18)
    button.bg = W.Fill(button, "BACKGROUND", T.element)
    button.bg:SetAllPoints()
    PP.Border(button, T.border)
    button.text = W.Text(button, W.FontNormal, "")
    button.text:SetPoint("LEFT", 10, 0)
    button.text:SetPoint("RIGHT", -24, 0)
    button.text:SetWordWrap(false)
    local arrow = W.Text(button, W.FontSmall, "v")
    arrow:SetPoint("RIGHT", -10, 0)
    button.owner = dd
    button:SetScript("OnClick", DDButton_OnClick)
    button:SetScript("OnEnter", Button_OnEnter)
    button:SetScript("OnLeave", Button_OnLeave)
    dd.button = button

    -- List (child of the button, drawn above everything in the window)
    local list = CreateFrame("Frame", nil, button)
    list:SetFrameStrata("DIALOG")
    PP.Width(list, width)
    PP.Point(list, "TOPLEFT", button, "BOTTOMLEFT", 0, -2)
    list:EnableMouse(true)
    W.Fill(list, "BACKGROUND", T.header):SetAllPoints()
    PP.Border(list, T.accentDim)
    list:Hide()
    dd.list = list

    dd.rows = {}
    dd.GetRow = Dropdown_GetRow
    dd.SetItems = Dropdown_SetItems
    dd.Refresh = Dropdown_Refresh
    dd.Close = Dropdown_Close
    dd:SetScript("OnHide", Dropdown_Close)
    dd:SetItems(items)
    dd:Refresh()
    return dd
end

---------------------------------------------------------------------------
-- Colour row:  [label ...................... [swatch] (o  )]
--   W.ColorRow(parent, label, getEnabled, setEnabled, getColor, onColorChanged)
--   getColor() returns an {r, g, b} table that is edited in place.
--   getEnabled may be nil: then the row only has a swatch.
-- Uses Blizzard's native ColorPickerFrame.
---------------------------------------------------------------------------
local SWATCH_W, SWATCH_H = 30, 16

local function ColorRow_Refresh(self)
    local c = self.getColor()
    self.swatch.fill:SetColorTexture(c[1], c[2], c[3], 1)
    if self.toggle then self.toggle:Refresh() end
end

local function OpenPicker(row)
    if not (ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow) then return end
    local c = row.getColor()
    local function Set(r, g, b)
        c[1], c[2], c[3] = r, g, b
        row:Refresh()
        row.onColorChanged()
    end
    ColorPickerFrame:SetupColorPickerAndShow({
        r = c[1], g = c[2], b = c[3],
        hasOpacity = false,
        swatchFunc = function() Set(ColorPickerFrame:GetColorRGB()) end,
        cancelFunc = function(prev) Set(prev.r, prev.g, prev.b) end,
    })
end

local function Swatch_OnEnter(self) PP.SetBorderColor(self, T.accent) end
local function Swatch_OnLeave(self) PP.SetBorderColor(self, T.border) end

function W.ColorRow(parent, label, getEnabled, setEnabled, getColor, onColorChanged)
    local row = CreateFrame("Frame", nil, parent)
    PP.Height(row, 26)
    row.getColor, row.onColorChanged = getColor, onColorChanged

    local rightEdge = row
    local rightPoint = "TOPRIGHT"
    if getEnabled then
        -- Reuse the toggle switch, without its own label.
        local toggle = W.Toggle(row, "", nil, getEnabled, function(v)
            setEnabled(v)
            onColorChanged()
        end)
        PP.Point(toggle, "TOPRIGHT", row, "TOPRIGHT", 0, 0)
        PP.Width(toggle, 34)
        row.toggle = toggle
        rightEdge, rightPoint = toggle, "TOPLEFT"
    end

    local swatch = CreateFrame("Button", nil, row)
    PP.Size(swatch, SWATCH_W, SWATCH_H)
    PP.Point(swatch, "TOPRIGHT", rightEdge, rightPoint, getEnabled and -12 or 0, -(26 - SWATCH_H) / 2)
    swatch.fill = W.Fill(swatch, "ARTWORK", T.text)
    swatch.fill:SetAllPoints()
    PP.Border(swatch, T.border)
    swatch:SetScript("OnClick", function() PlaySound(SOUNDKIT.IG_MAINMENU_OPTION); OpenPicker(row) end)
    swatch:SetScript("OnEnter", Swatch_OnEnter)
    swatch:SetScript("OnLeave", Swatch_OnLeave)
    row.swatch = swatch

    local text = W.Text(row, W.FontNormal, label)
    text:SetPoint("LEFT", 0, 0)
    text:SetPoint("RIGHT", swatch, "LEFT", -10, 0)
    text:SetWordWrap(false)

    row.Refresh = ColorRow_Refresh
    row:Refresh()
    return row
end

---------------------------------------------------------------------------
-- Text box (single line, native EditBox)
--   W.EditBox(parent, label, width) -> frame with .box (the EditBox)
-- Clicking selects all text so long strings are easy to copy (Ctrl+C) or replace (Ctrl+V).
---------------------------------------------------------------------------
local EB_H = 26

local function EB_OnFocus(self)
    self:HighlightText()
    PP.SetBorderColor(self.holder, T.accent)
end

local function EB_OnFocusLost(self)
    self:HighlightText(0, 0)
    PP.SetBorderColor(self.holder, T.border)
end

local function EB_OnEscape(self) self:ClearFocus() end

function W.EditBox(parent, label, width)
    local f = CreateFrame("Frame", nil, parent)
    PP.Size(f, width, 18 + EB_H)

    local title = W.Text(f, W.FontSmall, label)
    title:SetPoint("TOPLEFT")

    local holder = CreateFrame("Frame", nil, f)
    PP.Size(holder, width, EB_H)
    PP.Point(holder, "TOPLEFT", f, "TOPLEFT", 0, -18)
    W.Fill(holder, "BACKGROUND", T.header):SetAllPoints()
    PP.Border(holder, T.border)

    local box = CreateFrame("EditBox", nil, holder)
    box:SetPoint("TOPLEFT", 8, 0)
    box:SetPoint("BOTTOMRIGHT", -8, 0)
    box:SetFontObject(W.FontNormal)
    box:SetAutoFocus(false)
    box:SetMaxLetters(0)
    box.holder = holder
    box:SetScript("OnEditFocusGained", EB_OnFocus)
    box:SetScript("OnEditFocusLost", EB_OnFocusLost)
    box:SetScript("OnEscapePressed", EB_OnEscape)
    box:SetScript("OnEnterPressed", EB_OnEscape)

    f.box = box
    return f
end
