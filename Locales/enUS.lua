-- NitexUI: English (default) strings

local _, ns = ...

-- Missing keys fall back to the key itself, so nothing ever errors on a nil string.
ns.L = setmetatable({}, { __index = function(_, key) return key end })
local L = ns.L

L["LOADED"] = "v%s loaded. Type /nitex for commands."
L["HELP_HEADER"] = "Commands:"
L["HELP_DEBUG"] = "toggle debug output"
L["HELP_RESET"] = "reset all settings and reload"
L["HELP_VERSION"] = "show addon version"
L["DEBUG_STATE"] = "Debug mode: %s"
L["RESET_DONE"] = "Settings reset."
