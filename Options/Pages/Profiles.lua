-- NitexUI: Options > General > Profiles
-- Native profile management (no AceDB). Every confirm uses Blizzard's StaticPopup.

local _, ns = ...
local W, L, Options = ns.Widgets, ns.L, ns.Options

local FOLLOW = "__default" -- dropdown value for "use the account default"
local DD_W = 300
local COL_W = math.floor((Options.CONTENT_W - 24) / 2) -- matches Options.Columns

---------------------------------------------------------------------------
-- Popups
---------------------------------------------------------------------------
local function EditBoxOf(popup)
    return (popup.GetEditBox and popup:GetEditBox()) or popup.editBox or popup.EditBox
end

local function CreateFromPopup(popup, data)
    local name = strtrim(EditBoxOf(popup):GetText() or "")
    if name == "" then return end
    if ns:ProfileExists(name) then
        ns:Print(L["PROFILE_EXISTS"]:format(name))
        return
    end
    ns:CreateProfile(name, data and data.copyFrom)
    ns:Print(L["PROFILE_CREATED"]:format(name))
    if data and data.page then data.page:Refresh() end
end

StaticPopupDialogs["NITEXUI_NEW_PROFILE"] = {
    text = L["POPUP_NEW_PROFILE"],
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    maxLetters = 32,
    OnShow = function(self) EditBoxOf(self):SetText(""); EditBoxOf(self):SetFocus() end,
    OnAccept = CreateFromPopup,
    EditBoxOnEnterPressed = function(editBox)
        local popup = editBox:GetParent()
        CreateFromPopup(popup, popup.data)
        popup:Hide()
    end,
    EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["NITEXUI_SWITCH_PROFILE"] = {
    text = L["POPUP_SWITCH_PROFILE"],
    button1 = YES, button2 = NO,
    OnAccept = function(_, data) ns:SetCharacterProfile(data.name) end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["NITEXUI_COPY_PROFILE"] = {
    text = L["POPUP_COPY_PROFILE"],
    button1 = YES, button2 = NO,
    OnAccept = function(_, data) ns:CopyIntoActiveProfile(data.name) end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["NITEXUI_DELETE_PROFILE"] = {
    text = L["POPUP_DELETE_PROFILE"],
    button1 = YES, button2 = NO,
    OnAccept = function(_, data)
        if ns:DeleteProfile(data.name) then
            ns:Print(L["PROFILE_DELETED"]:format(data.name))
            data.page:Refresh()
        end
    end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3, showAlert = true,
}

StaticPopupDialogs["NITEXUI_DEFAULT_RELOAD"] = {
    text = L["POPUP_DEFAULT_RELOAD"],
    button1 = YES, button2 = NO,
    OnAccept = function() ReloadUI() end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

---------------------------------------------------------------------------
-- Item lists (rebuilt every time a dropdown refreshes)
---------------------------------------------------------------------------
local function ProfileItems(excludeActive)
    local list = ns:GetProfiles()
    local items = {}
    for i = 1, #list do
        if not (excludeActive and list[i] == ns.profileName) then
            items[#items + 1] = { value = list[i], text = list[i] }
        end
    end
    return items
end

local function ActiveItems()
    local items = ProfileItems(false)
    table.insert(items, 1, { value = FOLLOW, text = L["PROFILE_FOLLOW"]:format(ns:GetDefaultProfile()) })
    return items
end

---------------------------------------------------------------------------
-- Page
---------------------------------------------------------------------------
function Options.BuildProfiles(parent)
    local p = Options.NewPage(parent)

    -- This character
    p:Add(W.Header(p, L["SECTION_THIS_CHAR"]), 18)
    -- Single line with a fixed height (no text measuring).
    local info = CreateFrame("Frame", nil, p)
    ns.PP.Height(info, 18)
    info.text = W.Text(info, W.FontNormal, "")
    info.text:SetPoint("TOPLEFT")
    info.text:SetPoint("TOPRIGHT")
    info.text:SetWordWrap(false)
    info.Refresh = function(self)
        self.text:SetText(L["PROFILE_INFO"]:format(ns:GetCharacterName(), ns.profileName))
    end
    p:Add(info, 10)

    p:Add(W.Dropdown(p, L["OPT_CHAR_PROFILE"], DD_W, ActiveItems,
        function() return ns:FollowsDefaultProfile() and FOLLOW or ns.profileName end,
        function(v)
            local follow = v == FOLLOW
            if follow == ns:FollowsDefaultProfile() and (follow or v == ns.profileName) then return end
            local name = not follow and v or nil
            StaticPopup_Show("NITEXUI_SWITCH_PROFILE", follow and L["PROFILE_FOLLOW"]:format(ns:GetDefaultProfile()) or v,
                nil, { name = name })
        end), 10, true)

    -- All characters
    p:Add(W.Header(p, L["SECTION_ALL_CHARS"]), 22)
    p:Add(W.Dropdown(p, L["OPT_DEFAULT_PROFILE"], DD_W, function() return ProfileItems(false) end,
        function() return ns:GetDefaultProfile() end,
        function(v)
            if ns:SetDefaultProfile(v) then
                StaticPopup_Show("NITEXUI_DEFAULT_RELOAD", v)
            end
            p:Refresh()
        end), 10, true)
    p:Add(W.Paragraph(p, L["DEFAULT_PROFILE_DESC"]), 8)

    -- Manage
    p:Add(W.Header(p, L["SECTION_MANAGE"]), 22)
    local left, right = Options.Columns(p, 14)

    left:Add(W.Button(p, L["BTN_NEW_PROFILE"], 160, function()
        StaticPopup_Show("NITEXUI_NEW_PROFILE", nil, nil, { page = p })
    end))
    left:Add(W.Button(p, L["BTN_DUPLICATE_PROFILE"], 160, function()
        StaticPopup_Show("NITEXUI_NEW_PROFILE", nil, nil, { page = p, copyFrom = ns.profileName })
    end), 10)
    left:Add(W.Button(p, L["BTN_RESET_PROFILE"], 160, function()
        StaticPopup_Show("NITEXUI_RESET", ns.profileName)
    end), 10)

    local copyDD = right:Add(W.Dropdown(p, L["OPT_COPY_FROM"], COL_W, function() return ProfileItems(true) end,
        function() return nil end,
        function(v) StaticPopup_Show("NITEXUI_COPY_PROFILE", v, ns.profileName, { name = v }) end))
    copyDD.placeholder = L["PROFILE_CHOOSE"]

    local deleteDD = right:Add(W.Dropdown(p, L["OPT_DELETE_PROFILE"], COL_W, function() return ProfileItems(true) end,
        function() return nil end,
        function(v) StaticPopup_Show("NITEXUI_DELETE_PROFILE", v, nil, { name = v, page = p }) end), 10)
    deleteDD.placeholder = L["PROFILE_CHOOSE"]

    Options.EndColumns(p, left, right)
    return p
end
