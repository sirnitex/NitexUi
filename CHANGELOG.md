# Changelog

## [0.9.0]
- Optional minimap button (General > Minimap), native, no LibDBIcon. Off by default. Drag to move around the minimap edge.

## [0.8.2]
- Addon icon/logo: used in the addon list, the minimap addon compartment and the options window title bar.
- Branding/ holds the SVG source and PNGs for CurseForge/Wago (not packaged).

## [0.8.1]
- Forever: mobs tagged by another player (UnitIsTapDenied) get the tapped colour with top priority.

## [0.8.0]
- Nameplates page with sub-tabs. First sub-module: Health Colors.
- Health Colors recolours Blizzard's own enemy nameplates: threat (role-aware) > quest mob > enemy type.
  Taint-safe: API calls in our event handler, colour cached per bar, painted from a per-bar SetStatusBarColor hook.
- New widgets: colour row with Blizzard's colour picker; two-column page layout.

## [0.7.0]
- Interface page with sub-tabs. First sub-module: General.
- Interface: General can hide the bag bar and the micro menu (moved under a hidden parent; restored live when turned off, deferred until combat ends).

## [0.6.1]
- Modules that are off use no resources: Fonts frees its captured data when switched off.
- Pixel perfect core registers its scale events only once something uses it.
- New /nitex status: shows module state and every event NitexUI is listening to.

## [0.6.0]
- Removed the Modules tab. Each module now has its own on/off switch at the top of its page.
- All modules are OFF by default; turning one on or off works live (no reload) where possible.
- Settings of a module that is off are dimmed and cannot be clicked.
- Example module renamed to Modules/_Template.lua and no longer loaded.

## [0.5.0]
- Global Settings page with sub-tabs. First sub-tab: Fonts.
- Fonts module: replace the font of all default game text via Blizzard's font objects (GetFonts), with Slug outline as default. Restores originals when turned off.
- Options window now uses a page registry so modules can add their own pages and sub-tabs.
- New widgets: dropdown (with font preview) and sub-tabs.

## [0.4.0]
- WoW Forever support (Interface 16001) in the same .toc as Retail.
- Client flavour flags ns.isRetail / ns.isForever; guards for Settings API and metadata.

## [0.3.0]
- Pixel perfect system (Core/Pixel.lua): 1px borders and lines are exactly one physical pixel at any UI scale.
- Options window rebuilt on the pixel perfect helpers.

## [0.2.0]
- Options window (/nitex): dark theme with #33ccff accent, General / Modules / About pages.
- Launcher in Blizzard Settings (Esc > Options > AddOns) and in the addon compartment by the minimap.

## [0.1.0]
- Initial project structure: core, event system, modules, SavedVariables, slash commands, locales.
