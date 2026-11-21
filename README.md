# NitexUI

Et UI-addon for World of Warcraft Retail (Midnight, Interface 120105) og WoW Forever (Interface 16001).
Begge klientene bruker samme moderne API, så én `.toc` dekker begge.

## Installasjon (utvikling)

Legg (eller symlink) mappen `NitexUI` i:

```
World of Warcraft\_retail_\Interface\AddOns\NitexUI
```

eller for Forever:

```
World of Warcraft\_forever_\Interface\AddOns\NitexUI
```

Mappenavnet **må** være `NitexUI` – samme som `.toc`-filen.

Tips: klon repoet et annet sted og lag en symlink, så slipper du å kopiere:

```powershell
# Windows (PowerShell som administrator)
New-Item -ItemType SymbolicLink -Path "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\NitexUI" -Target "C:\Dev\NitexUI"
```

Etter endringer: `/reload` i spillet.

## Struktur

```
NitexUI.toc        Metadata og lasterekkefølge
Locales/           Tekststrenger (enUS er standard)
Core/Init.lua      Namespace, event-system, modulsystem, oppstart
Core/Utils.lua     Print/Debug og hjelpefunksjoner
Core/Database.lua  SavedVariables med standardverdier
Core/Theme.lua     Fargetema (aksent #33ccff)
Core/Pixel.lua     Pixel perfect-hjelpere (borders, størrelser, ankere)
Core/Commands.lua  /nitex og /nui
Options/           Innstillingsvinduet (widgets + panel)
Modules/           Én fil per funksjon – start fra _Template.lua (alle moduler er AV som standard)
  GlobalSettings/Fonts.lua   Font og outline for hele spillet
Options/Pages/     Innstillingssider som moduler registrerer
Media/Fonts/       Egne fonter (.ttf/.otf) – se Modules/GlobalSettings/Fonts.lua
Media/             Teksturer, fonter, lyder
```

## Ny modul

1. Kopier `Modules/_Template.lua` til `Modules/MinModul.lua`
2. Endre navnet i `ns:NewModule("MinModul")`, og skriv `OnEnable` / `OnDisable`
3. Legg filen til i `NitexUI.toc`
4. Lag innstillingssiden i `Options/Pages/` og start den med `Options.ModuleToggle(page, "MinModul", ...)`

## Kommandoer

| Kommando | Funksjon |
|---|---|
| `/nitex` | Åpne innstillinger |
| `/nitex help` | Vis kommandoer i chat |
| `/nitex status` | Vis moduler og alle events NitexUI lytter på |
| `/nitex debug` | Debug-utskrift av/på |
| `/nitex reset` | Nullstill innstillinger |
| `/nitex version` | Vis versjon |

## Anbefalt oppsett

- VS Code med utvidelsene **Lua** (sumneko) og **WoW API** (Ketho) – gir autofullføring for hele WoW-API-et
- In-game: `/console scriptErrors 1`, eller addonene **BugSack** + **BugGrabber** for å fange feil
- `/fstack` og `/etrace` for å inspisere frames og events
