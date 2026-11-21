-- NitexUI: Norsk (bokmål)
-- Note: WoW has no official Norwegian client. This file is only used if
-- GetLocale() returns "nbNO" – kept here as a template for translations.

local _, ns = ...
if GetLocale() ~= "nbNO" then return end

local L = ns.L
L["LOADED"] = "v%s lastet. Skriv /nitex for kommandoer."
L["HELP_HEADER"] = "Kommandoer:"
L["HELP_DEBUG"] = "slå debug-utskrift av/på"
L["HELP_RESET"] = "nullstill alle innstillinger og last inn på nytt"
L["HELP_VERSION"] = "vis versjon"
L["DEBUG_STATE"] = "Debug-modus: %s"
L["RESET_DONE"] = "Innstillinger nullstilt."
