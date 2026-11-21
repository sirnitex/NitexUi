-- NitexUI: Slash commands  (/nitex or /nui)

local _, ns = ...
local L = ns.L

local commands = {}

commands.help = function()
    ns:Print(L["HELP_HEADER"])
    print("  /nitex debug  - " .. L["HELP_DEBUG"])
    print("  /nitex reset  - " .. L["HELP_RESET"])
    print("  /nitex version - " .. L["HELP_VERSION"])
end

commands.debug = function()
    ns.db.debug = not ns.db.debug
    ns:Print(L["DEBUG_STATE"]:format(ns.db.debug and "ON" or "OFF"))
end

commands.reset = function()
    ns:ResetDatabase()
    ns:Print(L["RESET_DONE"])
    ReloadUI()
end

commands.version = function()
    ns:Print(ns.version)
end

SLASH_NITEXUI1 = "/nitex"
SLASH_NITEXUI2 = "/nui"
SlashCmdList.NITEXUI = function(msg)
    local cmd, rest = (msg or ""):trim():match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()
    local func = commands[cmd] or commands.help
    func(rest)
end
