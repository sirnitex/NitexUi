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
L["CMD_OPEN"] = "open the options window"
L["CMD_HELP"] = "list commands in chat"

-- Options: pages
L["PAGE_GENERAL"] = "General"
L["PAGE_GENERAL_DESC"] = "Core settings for NitexUI."
L["PAGE_MODULES"] = "Modules"
L["PAGE_MODULES_DESC"] = "Turn individual features on or off."
L["PAGE_ABOUT"] = "About"
L["PAGE_ABOUT_DESC"] = "Version and commands."

-- Options: sections
L["SECTION_DEVELOPER"] = "Developer"
L["SECTION_DATA"] = "Data"
L["SECTION_MODULES"] = "Available modules"
L["SECTION_COMMANDS"] = "Slash commands"

-- Options: controls
L["OPT_DEBUG"] = "Debug mode"
L["OPT_DEBUG_DESC"] = "Print extra diagnostic messages to chat."
L["RESET_DESC"] = "Restore every NitexUI setting to its default. Your UI will reload."
L["RESET_CONFIRM"] = "Reset all NitexUI settings and reload the UI?"
L["BTN_RESET"] = "Reset settings"
L["BTN_RELOAD"] = "Reload UI"
L["RELOAD_NOTE"] = "Module changes take effect after a UI reload."
L["ABOUT_TEXT"] = "Version %s\nA lightweight interface addon built only on Blizzard's native API."

-- Global Settings
L["PAGE_GLOBAL"] = "Global Settings"
L["PAGE_GLOBAL_DESC"] = "Settings that apply to the whole game."
L["SUB_FONTS"] = "Fonts"
L["SECTION_FONT"] = "Game font"
L["SECTION_PREVIEW"] = "Preview"
L["OPT_FONTS_ENABLE"] = "Replace game fonts"
L["OPT_FONTS_ENABLE_DESC"] = "Use the font and outline below for all default Blizzard text."
L["OPT_FONT"] = "Font"
L["OPT_OUTLINE"] = "Outline"
L["FONTS_NOTE"] = "Most text updates instantly. Unit names and floating combat text update after a reload. Slug renders text on the GPU for very crisp outlines, so text shadows are turned off while it is active."

-- Blizzard settings launcher
L["SETTINGS_LAUNCHER_DESC"] = "NitexUI has its own options window."
L["BTN_OPEN_OPTIONS"] = "Open NitexUI options"
