# Changelog

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
