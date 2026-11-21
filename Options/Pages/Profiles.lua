-- NitexUI: Options > General > Profiles  (ElvUI-style, native)
--
--   Profiles       active profile for this character + default profile for all other characters
--   Manage         new, duplicate, reset, copy from, delete
--   Import/Export  shareable profile strings (Blizzard's C_EncodingUtil)
--
-- Every destructive action asks first with Blizzard's StaticPopup.

local _, ns = ...
local W, L, Options = ns.Widgets, ns.L, ns.Options

local FOLLOW = "__default" -- dropdown value for "use the default profile"
local COL_W = math.floor((Options.CONTENT_W - 24) / 2) -- matches Options.Columns
local page -- the built page, refreshed after changes

local function Refresh() if page then page:Refresh() end end

---------------------------------------------------------------------------
-- Popups
---------------------------------------------------------------------------
local function EditBoxOf(popup)
    return (popup.GetEditBox and popup:GetEditBox()) or popup.editBox or popup.EditBox
end

local function NewFromPopup(popup, data)
    local name = EditBoxOf(popup):GetText()
    local created = ns:NewProfile(name, data and data.copyFrom)
    if created then
        ns:Print(L["PROFILE_CREATED"]:format(created))
        Refresh()
    else
        ns:Print(L["PROFILE_BAD_NAME"])
    end
end

local POPUP = { timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3 }
local function Popup(key, t)
    for k, v in next, POPUP do if t[k] == nil then t[k] = v end end
    StaticPopupDialogs[key] = t
end

Popup("NITEXUI_NEW_PROFILE", {
    text = L["POPUP_NEW_PROFILE"],
    button1 = ACCEPT, button2 = CANCEL,
    hasEditBox = true, maxLetters = 32,
    OnShow = function(self) EditBoxOf(self):SetText(""); EditBoxOf(self):SetFocus() end,
    OnAccept = NewFromPopup,
    EditBoxOnEnterPressed = function(editBox)
        local popup = editBox:GetParent()
        NewFromPopup(popup, popup.data)
        popup:Hide()
    end,
    EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
})

Popup("NITEXUI_SWITCH_PROFILE", {
    text = L["POPUP_SWITCH_PROFILE"], button1 = YES, button2 = NO,
    OnAccept = function(_, data) ns:SetProfile(data.name) end,
})

Popup("NITEXUI_COPY_PROFILE", {
    text = L["POPUP_COPY_PROFILE"], button1 = YES, button2 = NO,
    OnAccept = function(_, data) ns:CopyProfile(data.name) end,
})

Popup("NITEXUI_DELETE_PROFILE", {
    text = L["POPUP_DELETE_PROFILE"], button1 = YES, button2 = NO, showAlert = true,
    OnAccept = function(_, data)
        if ns:DeleteProfile(data.name) then
            ns:Print(L["PROFILE_DELETED"]:format(data.name))
            Refresh()
        end
    end,
})

Popup("NITEXUI_DEFAULT_RELOAD", {
    text = L["POPUP_DEFAULT_RELOAD"], button1 = YES, button2 = NO,
    OnAccept = function() ReloadUI() end,
})

Popup("NITEXUI_IMPORTED", {
    text = L["POPUP_IMPORTED"], button1 = YES, button2 = NO,
    OnAccept = function(_, data) ns:SetProfile(data.name) end,
})

---------------------------------------------------------------------------
-- Item lists (rebuilt each time a dropdown refreshes)
---------------------------------------------------------------------------
local function ProfileItems(excludeActive)
    local list, items = ns:GetProfiles(), {}
    for i = 1, #list do
        if not (excludeActive and list[i] == ns:GetCurrentProfile()) then
            items[#items + 1] = { value = list[i], text = list[i] }
        end
    end
    return items
end

local function CharItems()
    local items = ProfileItems(false)
    table.insert(items, 1, { value = FOLLOW, text = L["PROFILE_FOLLOW"]:format(ns:GetDefaultProfile()) })
    return items
end

local function AllItems() return ProfileItems(false) end
local function OtherItems() return ProfileItems(true) end

---------------------------------------------------------------------------
-- Page
---------------------------------------------------------------------------
function Options.BuildProfiles(parent)
    local p = Options.NewPage(parent)
    page = p

    -- 1. Profiles -----------------------------------------------------------
    p:Add(W.Header(p, L["SECTION_PROFILES"]), 18)
    local l1, r1 = Options.Columns(p, 10)

    l1:Add(W.Dropdown(p, L["OPT_CHAR_PROFILE"]:format(ns:GetCharacterKey()), COL_W, CharItems,
        function() return ns:FollowsDefaultProfile() and FOLLOW or ns:GetCurrentProfile() end,
        function(v)
            local follow = v == FOLLOW
            if follow and ns:FollowsDefaultProfile() then return end
            if not follow and not ns:FollowsDefaultProfile() and v == ns:GetCurrentProfile() then return end
            local label = follow and L["PROFILE_FOLLOW"]:format(ns:GetDefaultProfile()) or v
            StaticPopup_Show("NITEXUI_SWITCH_PROFILE", label, nil, { name = not follow and v or nil })
        end))

    r1:Add(W.Dropdown(p, L["OPT_DEFAULT_PROFILE"], COL_W, AllItems,
        function() return ns:GetDefaultProfile() end,
        function(v)
            if ns:SetDefaultProfile(v) then StaticPopup_Show("NITEXUI_DEFAULT_RELOAD", v) end
            Refresh()
        end))
    Options.EndColumns(p, l1, r1)

    -- 2. Manage -------------------------------------------------------------
    p:Add(W.Header(p, L["SECTION_MANAGE"]), 22)
    local l2, r2 = Options.Columns(p, 10)

    l2:Add(W.Button(p, L["BTN_NEW_PROFILE"], COL_W, function()
        StaticPopup_Show("NITEXUI_NEW_PROFILE")
    end))
    l2:Add(W.Button(p, L["BTN_DUPLICATE_PROFILE"], COL_W, function()
        StaticPopup_Show("NITEXUI_NEW_PROFILE", nil, nil, { copyFrom = ns:GetCurrentProfile() })
    end), 8)
    l2:Add(W.Button(p, L["BTN_RESET_PROFILE"], COL_W, function()
        StaticPopup_Show("NITEXUI_RESET", ns:GetCurrentProfile())
    end), 8)

    local copyDD = r2:Add(W.Dropdown(p, L["OPT_COPY_FROM"], COL_W, OtherItems,
        function() return nil end,
        function(v) StaticPopup_Show("NITEXUI_COPY_PROFILE", v, ns:GetCurrentProfile(), { name = v }) end))
    copyDD.placeholder = L["PROFILE_CHOOSE"]

    local deleteDD = r2:Add(W.Dropdown(p, L["OPT_DELETE_PROFILE"], COL_W, OtherItems,
        function() return nil end,
        function(v) StaticPopup_Show("NITEXUI_DELETE_PROFILE", v, nil, { name = v }) end), 8)
    deleteDD.placeholder = L["PROFILE_CHOOSE"]
    Options.EndColumns(p, l2, r2)

    -- 3. Import / Export ----------------------------------------------------
    p:Add(W.Header(p, L["SECTION_IMPORT_EXPORT"]), 22)
    local l3, r3 = Options.Columns(p, 10)

    local exportBox = l3:Add(W.EditBox(p, L["OPT_EXPORT"]:format(ns:GetCurrentProfile()), COL_W))
    l3:Add(W.Button(p, L["BTN_EXPORT"], COL_W, function()
        local str, err = ns:ExportProfile()
        if not str then
            ns:Print(L["EXPORT_FAILED"]:format(err or "?"))
            return
        end
        exportBox.box:SetText(str)
        exportBox.box:SetFocus() -- selects everything: press Ctrl+C
        ns:Print(L["EXPORT_DONE"])
    end), 8)

    local importBox = r3:Add(W.EditBox(p, L["OPT_IMPORT"], COL_W))
    r3:Add(W.Button(p, L["BTN_IMPORT"], COL_W, function()
        local name, err = ns:ImportProfile(importBox.box:GetText())
        if not name then
            ns:Print(L["IMPORT_FAILED"]:format(err or "?"))
            return
        end
        importBox.box:SetText("")
        importBox.box:ClearFocus()
        Refresh()
        StaticPopup_Show("NITEXUI_IMPORTED", name, nil, { name = name })
    end), 8)
    Options.EndColumns(p, l3, r3)

    if not ns:CanImportExport() then
        exportBox:SetAlpha(0.35)
        importBox:SetAlpha(0.35)
    end
    return p
end
