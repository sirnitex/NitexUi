-- NitexUI: Slash commands  (/nitex or /nui)

local _, ns = ...
local L = ns.L

local commands = {}

commands[""] = function()
    ns.Options:Toggle()
end

commands.help = function()
    ns:Print(L["HELP_HEADER"])
    print("  /nitex - " .. L["CMD_OPEN"])
    print("  /nitex debug - " .. L["HELP_DEBUG"])
    print("  /nitex status - " .. L["HELP_STATUS"])
    print("  /nitex reset - " .. L["HELP_RESET"])
    print("  /nitex version - " .. L["HELP_VERSION"])
    print("  /nitex np - " .. L["HELP_NP"])
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

commands.status = function()
    ns:Print(L["STATUS_HEADER"])
    local names = {}
    for name in next, ns.modules do names[#names + 1] = name end
    table.sort(names)
    for i = 1, #names do
        local on = ns:IsModuleEnabled(names[i])
        print("  " .. names[i] .. ": " .. (on and "|cff33ff66ON|r" or "|cff888888OFF|r"))
    end
    print(L["STATUS_EVENTS"])
    if ns:DumpEvents() == 0 then print("  " .. L["STATUS_NONE"]) end
end

commands.np = function()
    if ns.NameplateColors then ns.NameplateColors:Debug() end
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
