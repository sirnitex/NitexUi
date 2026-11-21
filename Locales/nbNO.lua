-- NitexUI: Norsk (bokmål)
-- Note: WoW has no official Norwegian client. This file is only used if
-- GetLocale() returns "nbNO" – kept here as a template for translations.

local _, ns = ...
if GetLocale() ~= "nbNO" then return end

local L = ns.L
L["LOADED"] = "v%s lastet. Skriv /nitex for innstillinger."
L["HELP_HEADER"] = "Kommandoer:"
L["HELP_DEBUG"] = "slå debug-utskrift av/på"
L["HELP_RESET"] = "nullstill alle innstillinger og last inn på nytt"
L["HELP_VERSION"] = "vis versjon"
L["DEBUG_STATE"] = "Debug-modus: %s"
L["RESET_DONE"] = "Innstillinger nullstilt."
L["CMD_OPEN"] = "åpne innstillinger"
L["CMD_HELP"] = "vis kommandoer i chat"

L["PAGE_GENERAL"] = "Generelt"
L["PAGE_GENERAL_DESC"] = "Grunninnstillinger for NitexUI."
L["PAGE_MODULES"] = "Moduler"
L["PAGE_MODULES_DESC"] = "Slå funksjoner av eller på."
L["PAGE_ABOUT"] = "Om"
L["PAGE_ABOUT_DESC"] = "Versjon og kommandoer."

L["SECTION_DEVELOPER"] = "Utvikler"
L["SECTION_DATA"] = "Data"
L["SECTION_MODULES"] = "Tilgjengelige moduler"
L["SECTION_COMMANDS"] = "Kommandoer"

L["OPT_DEBUG"] = "Debug-modus"
L["OPT_DEBUG_DESC"] = "Skriv ekstra diagnosemeldinger i chat."
L["RESET_DESC"] = "Tilbakestill alle NitexUI-innstillinger. Grensesnittet lastes på nytt."
L["RESET_CONFIRM"] = "Nullstille alle NitexUI-innstillinger og laste inn på nytt?"
L["BTN_RESET"] = "Nullstill"
L["BTN_RELOAD"] = "Last inn på nytt"
L["RELOAD_NOTE"] = "Endringer i moduler gjelder etter at grensesnittet er lastet inn på nytt."
L["ABOUT_TEXT"] = "Versjon %s\nEt lett addon bygget kun på Blizzards egne API."

L["SETTINGS_LAUNCHER_DESC"] = "NitexUI har sitt eget innstillingsvindu."
L["BTN_OPEN_OPTIONS"] = "Åpne NitexUI-innstillinger"
