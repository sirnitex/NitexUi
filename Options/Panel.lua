-- NitexUI: Options window
-- Built lazily the first time it is opened. No OnUpdate, no timers, no background events.
-- All geometry goes through ns.PP so borders and lines stay pixel perfect at any UI scale.

local _, ns = ...
local T, W, L, PP = ns.Theme, ns.Widgets, ns.L, ns.PP

local Options = {}
ns.Options = Options

local WIDTH, HEIGHT = 700, 460
local HEADER_H, SIDEBAR_W, PAD = 46, 160, 24
local CONTENT_W = WIDTH - SIDEBAR_W - PAD * 2

local window
local pages, tabs, tabOrder = {}, {}, {}

---------------------------------------------------------------------------
-- Page helper: simple top-to-bottom layout
---------------------------------------------------------------------------
local function Page_Add(self, widget, gap, keepWidth)
    PP.Point(widget, "TOPLEFT", self.cursor, "BOTTOMLEFT", 0, -(gap or 10))
    if not keepWidth then
        PP.Width(widget, CONTENT_W)
    end
    self.cursor = widget
    if widget.Refresh then
        self.widgets[#self.widgets + 1] = widget
    end
    return widget
end

local function Page_Refresh(self)
    for i = 1, #self.widgets do self.widgets[i]:Refresh() end
end

local function NewPage(parent, title, subtitle)
    local p = CreateFrame("Frame", nil, parent)
    p:SetAllPoints()
    p:Hide()
    p.widgets = {}

    -- Fixed-height title block. Layout anchors to this frame, never to a FontString,
    -- because text heights are not whole pixels.
    local top = CreateFrame("Frame", nil, p)
    PP.Point(top, "TOPLEFT", p, "TOPLEFT", PAD, -20)
    PP.Point(top, "TOPRIGHT", p, "TOPRIGHT", -PAD, -20)
    PP.Height(top, 38)
    local t = W.Text(top, W.FontTitle, title)
    t:SetPoint("TOPLEFT")
    local s = W.Text(top, W.FontSmall, subtitle)
    s:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -5)

    p.cursor = top
    p.Add = Page_Add
    p.Refresh = Page_Refresh
    return p
end

---------------------------------------------------------------------------
-- Pages
---------------------------------------------------------------------------
StaticPopupDialogs["NITEXUI_RESET"] = {
    text = L["RESET_CONFIRM"],
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        ns:ResetDatabase()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local builders = {}

builders.general = function(parent)
    local p = NewPage(parent, L["PAGE_GENERAL"], L["PAGE_GENERAL_DESC"])

    p:Add(W.Header(p, L["SECTION_DEVELOPER"]), 22)
    p:Add(W.Toggle(p, L["OPT_DEBUG"], L["OPT_DEBUG_DESC"],
        function() return ns.db.debug end,
        function(v) ns.db.debug = v end), 10)

    p:Add(W.Header(p, L["SECTION_DATA"]), 26)
    p:Add(W.Paragraph(p, L["RESET_DESC"]), 10)
    p:Add(W.Button(p, L["BTN_RESET"], 160, function() StaticPopup_Show("NITEXUI_RESET") end), 12, true)

    return p
end

builders.modules = function(parent)
    local p = NewPage(parent, L["PAGE_MODULES"], L["PAGE_MODULES_DESC"])
    p:Add(W.Header(p, L["SECTION_MODULES"]), 22)

    local names = {}
    for name in next, ns.modules do names[#names + 1] = name end
    table.sort(names)

    for i = 1, #names do
        local name = names[i]
        p:Add(W.Toggle(p, name, nil,
            function() return ns.db.modules[name] ~= false end,
            function(v) ns.db.modules[name] = v end), i == 1 and 10 or 4)
    end

    p:Add(W.Paragraph(p, L["RELOAD_NOTE"]), 18)
    p:Add(W.Button(p, L["BTN_RELOAD"], 140, function() ReloadUI() end), 10, true)
    return p
end

builders.about = function(parent)
    local p = NewPage(parent, L["PAGE_ABOUT"], L["PAGE_ABOUT_DESC"])

    p:Add(W.Header(p, "|cff" .. T.accentHex .. "Nitex|rUI"), 22)
    p:Add(W.Paragraph(p, L["ABOUT_TEXT"]:format(ns.version), W.FontNormal), 10)

    p:Add(W.Header(p, L["SECTION_COMMANDS"]), 26)
    p:Add(W.Paragraph(p,
        "|cff" .. T.accentHex .. "/nitex|r  " .. L["CMD_OPEN"] .. "\n" ..
        "|cff" .. T.accentHex .. "/nitex help|r  " .. L["CMD_HELP"] .. "\n" ..
        "|cff" .. T.accentHex .. "/nitex debug|r  " .. L["HELP_DEBUG"] .. "\n" ..
        "|cff" .. T.accentHex .. "/nitex reset|r  " .. L["HELP_RESET"], W.FontNormal), 10)
    return p
end

tabOrder = {
    { key = "general", label = L["PAGE_GENERAL"] },
    { key = "modules", label = L["PAGE_MODULES"] },
    { key = "about",   label = L["PAGE_ABOUT"] },
}

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local function SelectPage(key)
    if not pages[key] then
        pages[key] = builders[key](window.content)
    end
    for k, page in next, pages do page:SetShown(k == key) end
    for k, tab in next, tabs do tab:SetSelected(k == key) end
    pages[key]:Refresh()
    window.current = key
end

--- Place the window centred, snapped to whole pixels (TOPLEFT anchor, never CENTER).
local function CenterWindow(f)
    PP.ClearPoints(f)
    PP.Point(f, "TOPLEFT", UIParent, "TOPLEFT",
        (UIParent:GetWidth() - f:GetWidth()) / 2,
        -(UIParent:GetHeight() - f:GetHeight()) / 2)
end

local function Build()
    local f = CreateFrame("Frame", "NitexUIOptionsFrame", UIParent)
    PP.Size(f, WIDTH, HEIGHT)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetDontSavePosition(true)
    f:EnableMouse(true)
    f:Hide()
    CenterWindow(f)

    W.Fill(f, "BACKGROUND", T.bg):SetAllPoints()
    PP.Border(f, T.border)

    -- Header / title bar (drag handle)
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    PP.Height(header, HEADER_H)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        -- Re-anchor on whole pixels where the user dropped it.
        local left, top = f:GetLeft(), f:GetTop()
        PP.ClearPoints(f)
        PP.Point(f, "TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    end)
    W.Fill(header, "BACKGROUND", T.header):SetAllPoints()
    W.HLine(header, T.accentDim)

    local title = W.Text(header, W.FontTitle, "|cff" .. T.accentHex .. "Nitex|rUI")
    title:SetPoint("LEFT", 18, 0)
    local version = W.Text(header, W.FontSmall, "v" .. ns.version)
    version:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 8, 1)

    -- Close button
    local close = CreateFrame("Button", nil, header)
    PP.Size(close, HEADER_H - 12, HEADER_H - 12)
    PP.Point(close, "TOPRIGHT", header, "TOPRIGHT", -6, -6)
    close.text = W.Text(close, W.FontTitle, "x")
    close.text:SetPoint("CENTER", 0, 1)
    close.text:SetTextColor(unpack(T.textDim))
    close:SetScript("OnEnter", function(self) self.text:SetTextColor(unpack(T.accent)) end)
    close:SetScript("OnLeave", function(self) self.text:SetTextColor(unpack(T.textDim)) end)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Sidebar
    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
    sidebar:SetPoint("BOTTOMLEFT")
    PP.Width(sidebar, SIDEBAR_W)
    W.Fill(sidebar, "BACKGROUND", T.sidebar):SetAllPoints()

    local prev
    for i = 1, #tabOrder do
        local info = tabOrder[i]
        local tab = W.Tab(sidebar, info.label, function()
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            SelectPage(info.key)
        end)
        if prev then
            PP.Point(tab, "TOPLEFT", prev, "BOTTOMLEFT", 0, -2)
            PP.Point(tab, "TOPRIGHT", prev, "BOTTOMRIGHT", 0, -2)
        else
            PP.Point(tab, "TOPLEFT", sidebar, "TOPLEFT", 0, -12)
            PP.Point(tab, "TOPRIGHT", sidebar, "TOPRIGHT", 0, -12)
        end
        tabs[info.key] = tab
        prev = tab
    end

    local footer = W.Text(sidebar, W.FontSmall, "/nitex")
    footer:SetPoint("BOTTOMLEFT", 16, 12)

    -- Content area
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT")
    content:SetPoint("BOTTOMRIGHT")
    W.VLine(content, T.border, true) -- divider between sidebar and content
    f.content = content

    f:SetScript("OnShow", function() PlaySound(SOUNDKIT.IG_MAINMENU_OPEN) end)
    f:SetScript("OnHide", function() PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE) end)

    -- Close with Escape (native)
    tinsert(UISpecialFrames, "NitexUIOptionsFrame")

    window = f
    SelectPage("general")
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
function Options:Open(key)
    if not window then Build() end
    window:Show()
    window:Raise()
    if key and builders[key] then SelectPage(key) end
end

function Options:Toggle()
    if window and window:IsShown() then
        window:Hide()
    else
        self:Open()
    end
end

---------------------------------------------------------------------------
-- Blizzard Settings (Esc > Options > AddOns > NitexUI)
-- Only a tiny launcher page; the real window is still built on demand.
---------------------------------------------------------------------------
do
    local canvas = CreateFrame("Frame")
    local title = W.Text(canvas, W.FontTitle, "|cff" .. T.accentHex .. "Nitex|rUI")
    title:SetPoint("TOPLEFT", 16, -16)
    local desc = W.Text(canvas, W.FontSmall, L["SETTINGS_LAUNCHER_DESC"])
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)

    -- Native Blizzard button here, since this page lives inside Blizzard's own Settings panel.
    local btn = CreateFrame("Button", nil, canvas, "UIPanelButtonTemplate")
    btn:SetSize(200, 26)
    btn:SetText(L["BTN_OPEN_OPTIONS"])
    btn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -14)
    btn:SetScript("OnClick", function()
        HideUIPanel(SettingsPanel)
        Options:Open()
    end)

    local category = Settings.RegisterCanvasLayoutCategory(canvas, "NitexUI")
    Settings.RegisterAddOnCategory(category)
end

-- Addon compartment (the addon button by the minimap), set in the .toc
function NitexUI_OnAddonCompartmentClick()
    Options:Toggle()
end
