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
L["HELP_STATUS"] = "vis hvilke moduler som er på og alle events NitexUI lytter på"
L["STATUS_HEADER"] = "Moduler:"
L["STATUS_EVENTS"] = "Registrerte events:"
L["STATUS_NONE"] = "ingen - NitexUI gjør ingenting"
L["CMD_OPEN"] = "åpne innstillinger"
L["CMD_HELP"] = "vis kommandoer i chat"

L["PAGE_GENERAL"] = "Generelt"
L["PAGE_GENERAL_DESC"] = "Grunninnstillinger for NitexUI."
L["PAGE_ABOUT"] = "Om"
L["PAGE_ABOUT_DESC"] = "Versjon og kommandoer."

L["SECTION_DEVELOPER"] = "Utvikler"
L["SECTION_DATA"] = "Data"
L["SECTION_COMMANDS"] = "Kommandoer"

L["OPT_DEBUG"] = "Debug-modus"
L["OPT_DEBUG_DESC"] = "Skriv ekstra diagnosemeldinger i chat."
L["RESET_DESC"] = "Tilbakestill alle NitexUI-innstillinger. Grensesnittet lastes på nytt."
L["RESET_CONFIRM"] = "Nullstille alle NitexUI-innstillinger og laste inn på nytt?"
L["BTN_RESET"] = "Nullstill"
L["BTN_RELOAD"] = "Last inn på nytt"
L["ABOUT_TEXT"] = "Versjon %s\nEt lett addon bygget kun på Blizzards egne API."

L["PAGE_GLOBAL"] = "Globale innstillinger"
L["PAGE_GLOBAL_DESC"] = "Innstillinger som gjelder hele spillet."
L["SUB_FONTS"] = "Fonter"
L["SECTION_FONT"] = "Spillfont"
L["SECTION_PREVIEW"] = "Forhåndsvisning"
L["OPT_FONTS_ENABLE"] = "Slå på Fonter"
L["OPT_FONTS_ENABLE_DESC"] = "Bruk fonten og outline under for all standardtekst i spillet. Av som standard."
L["OPT_FONT"] = "Font"
L["OPT_OUTLINE"] = "Outline"
L["FONTS_NOTE"] = "Det meste oppdateres med en gang. Navn over enheter og kamptekst oppdateres etter /reload. Slug tegner teksten på skjermkortet for veldig skarpe outlines, så skygge er av mens Slug er på."

L["PAGE_INTERFACE"] = "Grensesnitt"
L["PAGE_INTERFACE_DESC"] = "Endringer i Blizzards standard grensesnitt."
L["SUB_GENERAL"] = "Generelt"
L["OPT_IFGENERAL_ENABLE"] = "Slå på Grensesnitt: Generelt"
L["OPT_IFGENERAL_ENABLE_DESC"] = "Slå på valgene under. Av som standard."
L["SECTION_HIDE_BLIZZARD"] = "Skjul Blizzard-elementer"
L["OPT_HIDE_BAGBAR"] = "Skjul bag-bar"
L["OPT_HIDE_BAGBAR_DESC"] = "Skjuler ryggsekken og bag-knappene. Bagene åpnes fortsatt med hurtigtaster."
L["OPT_HIDE_MICROMENU"] = "Skjul mikro-meny"
L["OPT_HIDE_MICROMENU_DESC"] = "Skjuler menyknappene (karakter, spellbook, talenter ...). Hurtigtaster virker fortsatt."
L["IFGENERAL_NOTE"] = "Endringer gjelder med en gang og angres når du slår dem av. Er du i kamp, brukes de så snart kampen er over."

L["SETTINGS_LAUNCHER_DESC"] = "NitexUI har sitt eget innstillingsvindu."
L["BTN_OPEN_OPTIONS"] = "Åpne NitexUI-innstillinger"
