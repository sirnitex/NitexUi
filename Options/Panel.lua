-- NitexUI: Options window
-- Built lazily the first time it is opened. No OnUpdate, no timers, no background events.
-- All geometry goes through ns.PP so borders and lines stay pixel perfect at any UI scale.

local _, ns = ...
local T, W, L, PP = ns.Theme, ns.Widgets, ns.L, ns.PP

local Options = {}
ns.Options = Options

local WIDTH, HEIGHT = 760, 560
local HEADER_H, SIDEBAR_W, PAD = 46, 170, 24
local SUBTAB_H = 32
local CONTENT_W = WIDTH - SIDEBAR_W - PAD * 2
Options.CONTENT_W = CONTENT_W

local window
local pages, tabs = {}, {}

local registry = {} -- registered pages, sorted by order

---------------------------------------------------------------------------
-- Page helper: simple top-to-bottom layout
---------------------------------------------------------------------------
local function Page_Add(self, widget, gap, keepWidth)
    PP.Point(widget, "TOPLEFT", self.cursor, "BOTTOMLEFT", 0, -(gap or 10))
    if not keepWidth then
        PP.Width(widget, CONTENT_W)
    end
    self.cursor = widget
    self:Track(widget)
    if self.blocker then self:Depend(widget) end
    return widget
end

--- Mark a widget as belonging to the page's module: dimmed while the module is off.
local function Page_Depend(self, widget)
    self.dependents[#self.dependents + 1] = widget
    return widget
end

--- Remember a widget so the page refreshes it every time it is shown.
local function Page_Track(self, widget)
    if widget.Refresh then
        self.widgets[#self.widgets + 1] = widget
    end
    return widget
end

local function Page_Refresh(self)
    for i = 1, #self.widgets do self.widgets[i]:Refresh() end
end

--- New page. With no title, layout starts at the top edge (used for sub-pages).
local function NewPage(parent, title, subtitle)
    local p = CreateFrame("Frame", nil, parent)
    p:SetAllPoints()
    p:Hide()
    p.widgets = {}
    p.dependents = {}

    -- Fixed-height title block. Layout anchors to this frame, never to a FontString,
    -- because text heights are not whole pixels.
    local top = CreateFrame("Frame", nil, p)
    PP.Point(top, "TOPLEFT", p, "TOPLEFT", PAD, title and -20 or 0)
    PP.Point(top, "TOPRIGHT", p, "TOPRIGHT", -PAD, title and -20 or 0)
    PP.Height(top, title and 38 or 1)
    if title then
        local t = W.Text(top, W.FontTitle, title)
        t:SetPoint("TOPLEFT")
        local s = W.Text(top, W.FontSmall, subtitle)
        s:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -5)
    end

    p.cursor = top
    p.Add = Page_Add
    p.Track = Page_Track
    p.Depend = Page_Depend
    p.Refresh = Page_Refresh
    return p
end
Options.NewPage = NewPage

--- Build a page, and if it fails, say so in chat (with the error) instead of failing silently.
--- Only runs when a page is opened for the first time.
local function SafeBuild(name, build, parent)
    local ok, result = xpcall(build, function(err)
        ns:Print(("|cffff5555Could not build the \"%s\" page:|r %s"):format(name, tostring(err)))
        geterrorhandler()(err)
        return err
    end, parent)
    if ok then return result end
    -- Empty placeholder so the window keeps working.
    local p = NewPage(parent)
    return p
end

---------------------------------------------------------------------------
-- Two columns below the page's current position.
--   local left, right = Options.Columns(page)
--   left:Add(widget, gap)   -- same rules as page:Add, at half width
-- Widgets added to a column are refreshed and dimmed together with the page.
---------------------------------------------------------------------------
local COLUMN_GAP = 24

local function Column_Add(self, widget, gap)
    if self.first then
        PP.Point(widget, "TOPLEFT", self.holder, "TOPLEFT", self.x, 0)
        self.first = false
    else
        PP.Point(widget, "TOPLEFT", self.cursor, "BOTTOMLEFT", 0, -(gap or 10))
        self.height = self.height + (gap or 10)
    end
    self.height = self.height + widget:GetHeight()
    PP.Width(widget, self.w)
    self.cursor = widget
    self.page:Track(widget)
    if self.page.blocker then self.page:Depend(widget) end
    return widget
end

function Options.Columns(page, gap)
    local holder = CreateFrame("Frame", nil, page)
    PP.Height(holder, 1)
    page:Add(holder, gap or 14)
    local w = math.floor((CONTENT_W - COLUMN_GAP) / 2)
    local function New(x)
        return { page = page, holder = holder, x = x, w = w, first = true, height = 0, Add = Column_Add }
    end
    return New(0), New(w + COLUMN_GAP)
end

--- Continue full-width page layout below the taller of two columns.
function Options.EndColumns(page, left, right)
    -- Heights are tracked while adding (all widgets have fixed heights), so no layout query is needed.
    page.cursor = (left.height >= right.height) and left.cursor or right.cursor
end

---------------------------------------------------------------------------
-- Module on/off switch for a page.
-- Everything added to the page after this switch belongs to the module: while the
-- module is off it is dimmed and an invisible blocker swallows clicks on it.
---------------------------------------------------------------------------
local DIM_ALPHA = 0.35

local function ModuleToggle_Update(page)
    local on = ns:IsModuleEnabled(page.moduleName)
    page.blocker:SetShown(not on)
    for i = 1, #page.dependents do
        local w = page.dependents[i]
        w:SetAlpha(on and 1 or DIM_ALPHA)
        if not on and w.Close then w:Close() end
    end
end

function Options.ModuleToggle(page, moduleName, label, desc)
    page.moduleName = moduleName

    local toggle = page:Add(W.Toggle(page, label, desc,
        function() return ns:IsModuleEnabled(moduleName) end,
        function(v)
            ns:SetModuleEnabled(moduleName, v)
            ModuleToggle_Update(page)
            page:Refresh()
        end), 18)
    toggle.isModuleToggle = true

    local blocker = CreateFrame("Frame", nil, page)
    PP.Point(blocker, "TOPLEFT", toggle, "BOTTOMLEFT", 0, 0)
    blocker:SetPoint("BOTTOMRIGHT")
    blocker:SetFrameLevel(page:GetFrameLevel() + 50)
    blocker:EnableMouse(true)
    page.blocker = blocker

    local base = page.Refresh
    page.Refresh = function(self)
        base(self)
        ModuleToggle_Update(self)
    end

    -- A thin divider separates the switch from the module's own settings.
    local divider = CreateFrame("Frame", nil, page)
    PP.Height(divider, 1)
    W.HLine(divider, T.border)
    page:Add(divider, 8)
    return toggle
end

---------------------------------------------------------------------------
-- Page with sub-tabs: title, a sub-tab bar, and lazily built sub-pages below it.
---------------------------------------------------------------------------
local function SubPages_Select(self, key)
    local info = self.subs[key]
    if not info.page then
        info.page = SafeBuild(info.label, info.build, self.area)
    end
    for k, sub in next, self.subs do
        if sub.page then sub.page:SetShown(k == key) end
        sub.tab:SetSelected(k == key)
    end
    info.page:Refresh()
    self.current = key
end

local function SubPages_Refresh(self)
    self:Select(self.current)
end

local function NewSubTabPage(parent, info)
    local p = NewPage(parent, info.label, info.desc)

    local bar = CreateFrame("Frame", nil, p)
    PP.Point(bar, "TOPLEFT", p.cursor, "BOTTOMLEFT", 0, -12)
    PP.Size(bar, CONTENT_W, SUBTAB_H)
    W.HLine(bar, T.border)

    local area = CreateFrame("Frame", nil, p)
    PP.Point(area, "TOPLEFT", bar, "BOTTOMLEFT", -PAD, 0)
    area:SetPoint("BOTTOMRIGHT")
    p.area = area

    p.subs = {}
    local prev
    for i = 1, #info.subtabs do
        local sub = info.subtabs[i]
        p.subs[sub.key] = sub
        sub.tab = W.SubTab(bar, sub.label, function()
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            p:Select(sub.key)
        end)
        if prev then
            PP.Point(sub.tab, "TOPLEFT", prev, "TOPRIGHT", 4, 0)
        else
            PP.Point(sub.tab, "TOPLEFT", bar, "TOPLEFT", 0, 0)
        end
        prev = sub.tab
    end

    p.Select = SubPages_Select
    p.Refresh = SubPages_Refresh
    p.current = info.subtabs[1].key
    return p
end

---------------------------------------------------------------------------
-- Page registry
--   Options:RegisterPage{ key, label, order, desc, build = function(parent) return page end }
--   Options:RegisterPage{ key, label, order, desc, subtabs = { { key, label, build }, ... } }
---------------------------------------------------------------------------
function Options:RegisterPage(info)
    registry[#registry + 1] = info
    table.sort(registry, function(a, b) return a.order < b.order end)
end

local function BuildPage(info, parent)
    if info.subtabs then
        return NewSubTabPage(parent, info)
    end
    return info.build(parent)
end

---------------------------------------------------------------------------
-- Built-in pages
---------------------------------------------------------------------------
StaticPopupDialogs["NITEXUI_RESET"] = {
    text = L["RESET_CONFIRM"],
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        ns:ResetProfile()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function BuildGeneralMain(parent)
    local p = NewPage(parent)

    p:Add(W.Header(p, L["SECTION_MINIMAP"]), 18)
    p:Add(W.Toggle(p, L["OPT_MINIMAP"], L["OPT_MINIMAP_DESC"],
        function() return ns:IsModuleEnabled("MinimapButton") end,
        function(v) ns:SetModuleEnabled("MinimapButton", v) end), 10)

    p:Add(W.Header(p, L["SECTION_DEVELOPER"]), 26)
    p:Add(W.Toggle(p, L["OPT_DEBUG"], L["OPT_DEBUG_DESC"],
        function() return ns.db.debug end,
        function(v) ns.db.debug = v end), 10)

    p:Add(W.Header(p, L["SECTION_DATA"]), 26)
    p:Add(W.Paragraph(p, L["RESET_DESC"]), 10)
    p:Add(W.Button(p, L["BTN_RESET"], 160, function() StaticPopup_Show("NITEXUI_RESET", ns.profileName) end), 12, true)
    return p
end

Options:RegisterPage{
    key = "general",
    label = L["PAGE_GENERAL"],
    desc = L["PAGE_GENERAL_DESC"],
    order = 10,
    subtabs = {
        { key = "main",     label = L["SUB_GENERAL"],  build = BuildGeneralMain },
        -- Options/Pages/Profiles.lua defines Options.BuildProfiles (loaded after this file).
        { key = "profiles", label = L["SUB_PROFILES"], build = function(parent) return Options.BuildProfiles(parent) end },
    },
}

Options:RegisterPage{ key = "about", label = L["PAGE_ABOUT"], order = 90, build = function(parent)
    local p = NewPage(parent, L["PAGE_ABOUT"], L["PAGE_ABOUT_DESC"])

    p:Add(W.Header(p, "|cff" .. T.accentHex .. "Nitex|rUI"), 22)
    p:Add(W.Paragraph(p, L["ABOUT_TEXT"]:format(ns.version), W.FontNormal), 10)

    p:Add(W.Header(p, L["SECTION_COMMANDS"]), 26)
    p:Add(W.Paragraph(p,
        "|cff" .. T.accentHex .. "/nitex|r  " .. L["CMD_OPEN"] .. "\n" ..
        "|cff" .. T.accentHex .. "/nitex help|r  " .. L["CMD_HELP"] .. "\n" ..
        "|cff" .. T.accentHex .. "/nitex status|r  " .. L["HELP_STATUS"] .. "\n" ..
        "|cff" .. T.accentHex .. "/nitex debug|r  " .. L["HELP_DEBUG"] .. "\n" ..
        "|cff" .. T.accentHex .. "/nitex reset|r  " .. L["HELP_RESET"], W.FontNormal), 10)
    return p
end }

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local function SelectPage(key)
    if not pages[key] then
        for i = 1, #registry do
            if registry[i].key == key then
                pages[key] = SafeBuild(registry[i].label, function(parent) return BuildPage(registry[i], parent) end, window.content)
                break
            end
        end
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

    local logo = header:CreateTexture(nil, "ARTWORK")
    logo:SetTexture([[Interface\AddOns\NitexUI\Media\NitexUI-Icon]])
    PP.Size(logo, 28, 28)
    PP.Point(logo, "TOPLEFT", header, "TOPLEFT", 12, -(HEADER_H - 28) / 2)

    local title = W.Text(header, W.FontTitle, "|cff" .. T.accentHex .. "Nitex|rUI")
    title:SetPoint("LEFT", logo, "RIGHT", 8, 0)
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
    for i = 1, #registry do
        local info = registry[i]
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
    if key and tabs[key] then SelectPage(key) end
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
        if SettingsPanel then HideUIPanel(SettingsPanel) end
        Options:Open()
    end)

    -- Guarded so a client without the modern Settings API simply skips the launcher.
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(canvas, "NitexUI")
        Settings.RegisterAddOnCategory(category)
    end
end

-- Addon compartment (the addon button by the minimap), set in the .toc
function NitexUI_OnAddonCompartmentClick()
    Options:Toggle()
end
