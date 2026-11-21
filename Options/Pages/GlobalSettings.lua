-- NitexUI: Options > Global Settings
-- Settings that affect the whole game. Each feature is its own sub-tab.

local _, ns = ...
local T, W, L, PP, Options = ns.Theme, ns.Widgets, ns.L, ns.PP, ns.Options

local SAMPLE = "The quick brown fox jumps over the lazy dog  0123456789"

---------------------------------------------------------------------------
-- Sub-tab: Fonts
---------------------------------------------------------------------------
local function BuildFonts(parent)
    local Fonts = ns.Fonts
    local db = ns.db.global.fonts
    local p = Options.NewPage(parent)

    p:Add(W.Header(p, L["SECTION_FONT"]), 18)
    p:Add(W.Toggle(p, L["OPT_FONTS_ENABLE"], L["OPT_FONTS_ENABLE_DESC"],
        function() return db.enabled end,
        function(v) db.enabled = v; Fonts:Update() end), 10)

    -- Font + outline side by side
    local colW = math.floor((Options.CONTENT_W - 24) / 2)
    local fontDD = W.Dropdown(p, L["OPT_FONT"], colW, Fonts.fonts,
        function() return db.font end,
        function(v) db.font = v; Fonts:Update() end,
        Fonts.FileFor)
    p:Add(fontDD, 14, true)

    local outlineDD = W.Dropdown(p, L["OPT_OUTLINE"], colW, Fonts.outlines,
        function() return db.outline end,
        function(v) db.outline = v; Fonts:Update() end)
    PP.Point(outlineDD, "TOPLEFT", fontDD, "TOPRIGHT", 24, 0)
    p:Track(outlineDD)

    -- Preview box: uses the real font objects, so it shows exactly what the game will show.
    p:Add(W.Header(p, L["SECTION_PREVIEW"]), 26)
    local box = CreateFrame("Frame", nil, p)
    PP.Height(box, 64)
    W.Fill(box, "BACKGROUND", T.header):SetAllPoints()
    PP.Border(box, T.border)
    local line1 = box:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    line1:SetPoint("TOPLEFT", 12, -12)
    line1:SetText(SAMPLE)
    local line2 = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    line2:SetPoint("TOPLEFT", line1, "BOTTOMLEFT", 0, -8)
    line2:SetText(SAMPLE)
    p:Add(box, 10)

    p:Add(W.Paragraph(p, L["FONTS_NOTE"]), 12)
    p:Add(W.Button(p, L["BTN_RELOAD"], 140, function() ReloadUI() end), 10, true)
    return p
end

---------------------------------------------------------------------------
-- Register
---------------------------------------------------------------------------
Options:RegisterPage{
    key = "global",
    label = L["PAGE_GLOBAL"],
    desc = L["PAGE_GLOBAL_DESC"],
    order = 20,
    subtabs = {
        { key = "fonts", label = L["SUB_FONTS"], build = BuildFonts },
    },
}
