# NitexUI

Et UI-addon for World of Warcraft Retail (Midnight, Interface 120105).

## Installasjon (utvikling)

Legg (eller symlink) mappen `NitexUI` i:

```
World of Warcraft\_retail_\Interface\AddOns\NitexUI
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
Core/Commands.lua  /nitex og /nui
Options/           Innstillingsvinduet (widgets + panel)
Modules/           Én fil per funksjon – start fra Example.lua
Media/             Teksturer, fonter, lyder
```

## Ny modul

1. Kopier `Modules/Example.lua` til `Modules/MinModul.lua`
2. Endre navnet i `ns:NewModule("MinModul")`
3. Legg filen til nederst i `NitexUI.toc`

## Kommandoer

| Kommando | Funksjon |
|---|---|
| `/nitex` | Åpne innstillinger |
| `/nitex help` | Vis kommandoer i chat |
| `/nitex debug` | Debug-utskrift av/på |
| `/nitex reset` | Nullstill innstillinger |
| `/nitex version` | Vis versjon |

## Anbefalt oppsett

- VS Code med utvidelsene **Lua** (sumneko) og **WoW API** (Ketho) – gir autofullføring for hele WoW-API-et
- In-game: `/console scriptErrors 1`, eller addonene **BugSack** + **BugGrabber** for å fange feil
- `/fstack` og `/etrace` for å inspisere frames og events
