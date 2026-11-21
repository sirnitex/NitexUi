-- NitexUI: English (default) strings

local _, ns = ...

-- Missing keys fall back to the key itself, so nothing ever errors on a nil string.
ns.L = setmetatable({}, { __index = function(_, key) return key end })
local L = ns.L

-- Chat
L["LOADED"] = "v%s loaded. Type /nitex to open options."
L["HELP_HEADER"] = "Commands:"
L["HELP_DEBUG"] = "toggle debug output"
L["HELP_RESET"] = "reset all settings and reload"
L["HELP_VERSION"] = "show addon version"
L["DEBUG_STATE"] = "Debug mode: %s"
L["RESET_DONE"] = "Settings reset."
L["HELP_STATUS"] = "show which modules are on and every event NitexUI listens to"
L["STATUS_HEADER"] = "Modules:"
L["STATUS_EVENTS"] = "Registered events:"
L["STATUS_NONE"] = "none - NitexUI is completely idle"
L["CMD_OPEN"] = "open the options window"
L["CMD_HELP"] = "list commands in chat"

-- Options: pages
L["PAGE_GENERAL"] = "General"
L["PAGE_GENERAL_DESC"] = "Core settings for NitexUI."
L["PAGE_ABOUT"] = "About"
L["PAGE_ABOUT_DESC"] = "Version and commands."

-- Options: sections
L["SECTION_MINIMAP"] = "Minimap"
L["OPT_MINIMAP"] = "Show minimap button"
L["OPT_MINIMAP_DESC"] = "A NitexUI button on the minimap edge. Drag it to move it. Off by default."
L["MINIMAP_TIP_CLICK"] = "Click: open options"
L["MINIMAP_TIP_DRAG"] = "Drag: move around the minimap"
L["SECTION_DEVELOPER"] = "Developer"
L["SECTION_DATA"] = "Data"
L["SECTION_COMMANDS"] = "Slash commands"

-- Options: controls
L["OPT_DEBUG"] = "Debug mode"
L["OPT_DEBUG_DESC"] = "Print extra diagnostic messages to chat."
L["RESET_DESC"] = "Restore every setting in the active profile to its default. Your UI will reload."
L["RESET_CONFIRM"] = "Reset profile \"%s\" to defaults? Your UI will reload."
L["BTN_RESET"] = "Reset settings"
L["BTN_RELOAD"] = "Reload UI"
L["ABOUT_TEXT"] = "Version %s\nA lightweight interface addon built only on Blizzard's native API."

-- Global Settings
L["PAGE_GLOBAL"] = "Global Settings"
L["PAGE_GLOBAL_DESC"] = "Settings that apply to the whole game."
L["SUB_FONTS"] = "Fonts"
L["SECTION_FONT"] = "Game font"
L["SECTION_PREVIEW"] = "Preview"
L["OPT_FONTS_ENABLE"] = "Enable Fonts"
L["OPT_FONTS_ENABLE_DESC"] = "Use the font and outline below for all default game text. Off by default."
L["OPT_FONT"] = "Font"
L["OPT_OUTLINE"] = "Outline"
L["FONTS_NOTE"] = "Most text updates instantly. Unit names and floating combat text update after a reload. Slug renders text on the GPU for very crisp outlines, so text shadows are turned off while it is active."

-- Profiles
L["SUB_PROFILES"] = "Profiles"
L["SECTION_THIS_CHAR"] = "This character"
L["SECTION_ALL_CHARS"] = "All characters"
L["SECTION_MANAGE"] = "Manage profiles"
L["PROFILE_INFO"] = "%s  ·  active profile: |cff33ccff%s|r"
L["OPT_CHAR_PROFILE"] = "Profile for this character"
L["PROFILE_FOLLOW"] = "Account default (%s)"
L["OPT_DEFAULT_PROFILE"] = "Default profile for all characters"
L["DEFAULT_PROFILE_DESC"] = "Every character that has not picked its own profile uses this one automatically, including new characters."
L["BTN_NEW_PROFILE"] = "New profile"
L["BTN_DUPLICATE_PROFILE"] = "Duplicate current"
L["BTN_RESET_PROFILE"] = "Reset current"
L["OPT_COPY_FROM"] = "Copy settings from"
L["OPT_DELETE_PROFILE"] = "Delete profile"
L["PROFILE_CHOOSE"] = "Choose a profile..."
L["POPUP_NEW_PROFILE"] = "Name of the new profile:"
L["POPUP_SWITCH_PROFILE"] = "Use profile \"%s\" on this character? Your UI will reload."
L["POPUP_COPY_PROFILE"] = "Copy all settings from \"%s\" into \"%s\"? Your UI will reload."
L["POPUP_DELETE_PROFILE"] = "Delete profile \"%s\"? This cannot be undone."
L["POPUP_DEFAULT_RELOAD"] = "This character uses the account default, so it will switch to \"%s\". Reload now?"
L["PROFILE_EXISTS"] = "A profile named \"%s\" already exists."
L["PROFILE_CREATED"] = "Profile \"%s\" created."
L["PROFILE_DELETED"] = "Profile \"%s\" deleted."

-- Interface
L["PAGE_INTERFACE"] = "Interface"
L["PAGE_INTERFACE_DESC"] = "Changes to Blizzard's default interface."
L["SUB_GENERAL"] = "General"
L["OPT_IFGENERAL_ENABLE"] = "Enable Interface: General"
L["OPT_IFGENERAL_ENABLE_DESC"] = "Turn on the options below. Off by default."
L["SECTION_HIDE_BLIZZARD"] = "Hide Blizzard elements"
L["OPT_HIDE_BAGBAR"] = "Hide bag bar"
L["OPT_HIDE_BAGBAR_DESC"] = "Hides the backpack and bag slot buttons. Bags still open with your keybinds."
L["OPT_HIDE_MICROMENU"] = "Hide micro menu"
L["OPT_HIDE_MICROMENU_DESC"] = "Hides the menu buttons (character, spellbook, talents ...). Keybinds still work."
L["IFGENERAL_NOTE"] = "Changes apply instantly and are undone when you turn them off. If you are in combat, they are applied as soon as combat ends."

-- Nameplates
L["PAGE_NAMEPLATES"] = "Nameplates"
L["PAGE_NAMEPLATES_DESC"] = "Blizzard's own nameplates, tweaked."
L["SUB_HEALTHCOLORS"] = "Health Colors"
L["OPT_NPCOLORS_ENABLE"] = "Enable Health Colors"
L["OPT_NPCOLORS_ENABLE_DESC"] = "Colour enemy health bars by threat, quest and enemy type. Off by default."
L["SECTION_THREAT"] = "Threat"
L["SECTION_QUEST"] = "Quest"
L["SECTION_TYPES"] = "Enemy type"
L["OPT_THREAT"] = "Threat colours"
L["OPT_THREAT_GROUPONLY"] = "Only in groups"
L["THREAT_GOOD"] = "Tank: you have aggro"
L["THREAT_WARNING"] = "Aggro is changing"
L["THREAT_DANGER"] = "Tank lost / you have aggro"
L["OPT_QUEST"] = "Quest mobs"
L["TYPE_BOSS"] = "Boss"
L["TYPE_RAREELITE"] = "Rare elite"
L["TYPE_ELITE"] = "Elite"
L["TYPE_RARE"] = "Rare"
L["TYPE_NORMAL"] = "Normal"
L["TYPE_TRIVIAL"] = "Trivial"
L["SECTION_TAPPED"] = "Tapped"
L["OPT_TAPPED"] = "Tagged by someone else"
L["NPCOLORS_NOTE_FOREVER"] = "Priority: tapped, then threat, then quest, then enemy type. Tapped always wins: you cannot loot that mob. Anything not coloured keeps Blizzard's colour. Threat follows your role. Values the game keeps secret are skipped."
L["NPCOLORS_NOTE"] = "Priority: threat, then quest, then enemy type. Anything not coloured keeps Blizzard's colour. Threat follows your role (tank or not). Values the game keeps secret are skipped."

-- Blizzard settings launcher
L["SETTINGS_LAUNCHER_DESC"] = "NitexUI has its own options window."
L["BTN_OPEN_OPTIONS"] = "Open NitexUI options"
