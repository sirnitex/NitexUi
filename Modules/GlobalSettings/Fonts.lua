-- NitexUI: Global Settings > Fonts
--
-- Changes the font (and outline) of all default game text by updating Blizzard's own
-- font objects (the ones listed by the native GetFonts()). Every FontString that
-- inherits from those objects follows automatically, so there is nothing to hook
-- and nothing that runs while you play.
--
-- Runs: once at login, again when a Blizzard load-on-demand addon adds new font
-- objects, and when you change the setting. Never per frame.

local _, ns = ...
local M = ns:NewModule("Fonts")
ns.Fonts = M

local next, type, pcall = next, type, pcall

---------------------------------------------------------------------------
-- Available fonts
-- WoW has no API that lists font files, so the list is defined here.
-- To add your own: put the .ttf/.otf in NitexUI\Media\Fonts and add a line, e.g.
--   { value = "MyFont", text = "My Font", file = [[Interface\AddOns\NitexUI\Media\Fonts\MyFont.ttf]] },
---------------------------------------------------------------------------
M.fonts = {
    { value = "FRIZQT",   text = "Friz Quadrata (default)", file = [[Fonts\FRIZQT__.TTF]] },
    { value = "ARIALN",   text = "Arial Narrow",            file = [[Fonts\ARIALN.TTF]] },
    { value = "SKURRI",   text = "Skurri",                  file = [[Fonts\SKURRI.TTF]] },
    { value = "MORPHEUS", text = "Morpheus",                file = [[Fonts\MORPHEUS.TTF]] },
}

-- Font flags. SLUG = Blizzard's GPU text renderer (very crisp; only works without shadow).
M.outlines = {
    { value = "SLUG",      text = "Slug outline",       flags = "OUTLINE, SLUG",      slug = true },
    { value = "SLUGTHICK", text = "Slug thick outline", flags = "THICKOUTLINE, SLUG", slug = true },
    { value = "OUTLINE",   text = "Outline",            flags = "OUTLINE" },
    { value = "THICK",     text = "Thick outline",      flags = "THICKOUTLINE" },
    { value = "MONO",      text = "Monochrome outline", flags = "OUTLINE, MONOCHROME" },
    { value = "NONE",      text = "None (Blizzard shadow)", flags = "" },
}

local fontByValue, outlineByValue = {}, {}
for i = 1, #M.fonts do fontByValue[M.fonts[i].value] = M.fonts[i] end
for i = 1, #M.outlines do outlineByValue[M.outlines[i].value] = M.outlines[i] end

function M.FileFor(value)
    local f = fontByValue[value] or M.fonts[1]
    return f.file
end

-- Defaults (merged into SavedVariables by Core/Database.lua)
ns.defaults.global = ns.defaults.global or {}
ns.defaults.global.fonts = {
    font = "FRIZQT",
    outline = "SLUG",
}

---------------------------------------------------------------------------
-- Apply / restore
---------------------------------------------------------------------------
-- Original state of each Blizzard font object, captured the first time we touch it,
-- so turning the feature off restores everything without a reload.
local original = {} -- [fontObject] = { file, size, flags, shadowX, shadowY }
local stamp = {}    -- [fontObject] = generation it was last updated with
local generation = 0

local function ApplyTo(obj, file, flags, slug)
    local o = original[obj]
    if not o then
        local f, size, fl = obj:GetFont()
        if not f or not size or size <= 0 then return end
        local sx, sy = obj:GetShadowOffset()
        o = { f, size, fl, sx, sy }
        original[obj] = o
    end
    if stamp[obj] == generation then return end
    stamp[obj] = generation

    if pcall(obj.SetFont, obj, file, o[2], flags) then
        if slug then
            obj:SetShadowOffset(0, 0)
        else
            obj:SetShadowOffset(o[4], o[5])
        end
    end
end

local function Restore()
    for obj, o in next, original do
        pcall(obj.SetFont, obj, o[1], o[2], o[3] or "")
        obj:SetShadowOffset(o[4], o[5])
    end
    wipe(stamp)
end

function M:Apply()
    if not self.enabled or not GetFonts then return end
    local db = ns.db.global.fonts

    local file = M.FileFor(db.font)
    local outline = outlineByValue[db.outline] or M.outlines[1]
    local list = GetFonts()
    for i = 1, #list do
        local entry = list[i]
        local obj = type(entry) == "string" and _G[entry] or entry
        if type(obj) == "table" and obj.GetFont and obj.SetFont then
            ApplyTo(obj, file, outline.flags, outline.slug)
        end
    end
end

--- Call after changing a setting: re-applies to every font object.
function M:Update()
    if not self.enabled then return end
    generation = generation + 1
    self:Apply()
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------
function M:OnInitialize()
    -- Fonts the client reads from globals when it creates text. Must be set before the
    -- world loads (here, at ADDON_LOADED); changing them later needs a relog.
    if ns:IsModuleEnabled("Fonts") then
        local file = M.FileFor(ns.db.global.fonts.font)
        STANDARD_TEXT_FONT = file
        UNIT_NAME_FONT = file
        DAMAGE_TEXT_FONT = file
    end
end

function M:OnEnable()
    generation = generation + 1
    self:Apply()
    -- Blizzard load-on-demand UI (e.g. Blizzard_Collections) can add new font objects.
    -- Only objects we have not seen yet are touched (stamp check), so this is cheap.
    ns:RegisterEvent("ADDON_LOADED", self, self.Apply)
end

function M:OnDisable()
    ns:UnregisterEvent("ADDON_LOADED", self)
    Restore()
end
