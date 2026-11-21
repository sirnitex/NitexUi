-- NitexUI: Options window
-- Built lazily the first time it is opened. No OnUpdate, no timers, no background events.

local addonName, ns = ...
local T, W, L = ns.Theme, ns.Widgets, ns.L

local Options = {}
ns.Options = Options

local WIDTH, HEIGHT = 700, 460
local HEADER_H, SIDEBAR_W, PAD = 46, 160, 24

local window
local pages, tabs, tabOrder = {}, {}, {}

---------------------------------------------------------------------------
-- Page helper: simple top-to-bottom layout
---------------------------------------------------------------------------
local function Page_Add(self, widget, gap, keepWidth)
    widget:SetPoint("TOPLEFT", self.cursor, "BOTTOMLEFT", 0, -(gap or 10))
    if not keepWidth then
        widget:SetPoint("RIGHT", self, "RIGHT", -PAD, 0)
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

    local t = W.Text(p, W.FontTitle, title)
    t:SetPoint("TOPLEFT", PAD, -22)
    local s = W.Text(p, W.FontSmall, subtitle)
    s:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -5)

    p.cursor = s
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

local function Build()
    local f = CreateFrame("Frame", "NitexUIOptionsFrame", UIParent)
    f:SetSize(WIDTH, HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetDontSavePosition(true)
    f:EnableMouse(true)
    f:Hide()

    W.Fill(f, "BACKGROUND", T.bg):SetAllPoints()
    W.AddBorder(f)

    -- Header / title bar (drag handle)
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(HEADER_H)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    W.Fill(header, "BACKGROUND", T.header):SetAllPoints()

    local title = W.Text(header, W.FontTitle, "|cff" .. T.accentHex .. "Nitex|rUI")
    title:SetPoint("LEFT", 18, 0)
    local version = W.Text(header, W.FontSmall, "v" .. ns.version)
    version:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 8, 1)

    local accentLine = W.Fill(header, "ARTWORK", T.accentDim)
    accentLine:SetPoint("BOTTOMLEFT")
    accentLine:SetPoint("BOTTOMRIGHT")
    PixelUtil.SetHeight(accentLine, 1)

    -- Close button
    local close = CreateFrame("Button", nil, header)
    close:SetSize(HEADER_H - 12, HEADER_H - 12)
    close:SetPoint("RIGHT", -8, 0)
    close.text = W.Text(close, W.FontTitle, "x")
    close.text:SetPoint("CENTER", 0, 1)
    close.text:SetTextColor(unpack(T.textDim))
    close:SetScript("OnEnter", function(self) self.text:SetTextColor(unpack(T.accent)) end)
    close:SetScript("OnLeave", function(self) self.text:SetTextColor(unpack(T.textDim)) end)
    close:SetScript("OnClick", function() f:Hide() end)

    -- Sidebar
    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -1)
    sidebar:SetPoint("BOTTOMLEFT", 1, 1)
    sidebar:SetWidth(SIDEBAR_W)
    W.Fill(sidebar, "BACKGROUND", T.sidebar):SetAllPoints()
    local divider = W.Fill(sidebar, "BORDER", T.border)
    divider:SetPoint("TOPRIGHT")
    divider:SetPoint("BOTTOMRIGHT")
    PixelUtil.SetWidth(divider, 1)

    local prev
    for i = 1, #tabOrder do
        local info = tabOrder[i]
        local tab = W.Tab(sidebar, info.label, function()
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            SelectPage(info.key)
        end)
        if prev then
            tab:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -2)
        else
            tab:SetPoint("TOPLEFT", 0, -12)
        end
        tab:SetPoint("RIGHT", -1, 0)
        tabs[info.key] = tab
        prev = tab
    end

    local footer = W.Text(sidebar, W.FontSmall, "/nitex")
    footer:SetPoint("BOTTOMLEFT", 16, 12)

    -- Content area
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 0)
    content:SetPoint("BOTTOMRIGHT", -1, 1)
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
    local btn = W.Button(canvas, L["BTN_OPEN_OPTIONS"], 180, function()
        HideUIPanel(SettingsPanel)
        Options:Open()
    end)
    btn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -14)

    local category = Settings.RegisterCanvasLayoutCategory(canvas, "NitexUI")
    Settings.RegisterAddOnCategory(category)
end

-- Addon compartment (the addon button by the minimap), set in the .toc
function NitexUI_OnAddonCompartmentClick()
    Options:Toggle()
end
