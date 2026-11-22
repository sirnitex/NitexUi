# Changelog

## [0.16.2]
- Nameplates > Border: hides Blizzard's soft fill mask and the "not target" overlay while on, so the bar colour is even all the way to the border.

## [0.16.1]
- Nameplates > Border: Retail only (hidden on Forever). Border now hugs the health bar itself and the fill is flat while the module is on, so there are no gaps in the corners.

## [0.16.0]
- New module Nameplates > Border (test): replaces Blizzard's nameplate border with a 1px line, with its own colour for your target.

## [0.15.3]
- Mini Enemy colour removed: all ordinary enemies use the Enemy colour.
- New /nitex np: prints what the nameplate colours see for your target (for troubleshooting).

## [0.15.2]
- Classification Colors: new Neutral colour for neutral mobs out of combat (once they fight they use the enemy colours). UNIT_FLAGS/UNIT_FACTION now also watched on Retail so the colour switches when a neutral mob enters combat.

## [0.15.1]
- Classification Colors reworked (same idea as EllesmereUI): caster = mob with a mana pool; Elite Boss / Elite Mini by effective level vs. yours (skull or +2 = boss, lieutenant or +1 = mini-boss). New Enemy and Mini Enemy colours so ordinary mobs are coloured again. Saved type colours are reset once.

## [0.15.0]
- Nameplates > Health Colors: enemy types replaced by Classification Colors: Worldboss, Elite Boss, Elite Mini (UnitIsLieutenant), Rare Elite, Rare, Caster (Paladin-class NPCs). Old type colours in saved profiles are replaced once with the new defaults.

## [0.14.0]
- New module Interface > Character Panel: item level (quality coloured), enchant name and gem icons (empty sockets marked) next to every equipped item on Blizzard's character window. Retail and Forever.

## [0.13.1]
- Options: long pages can now be scrolled with the mouse wheel (thin scroll indicator on the right). Open dropdown lists are no longer cut off and close when you scroll.

## [0.13.0]
- New page Quality of Life (one module, a switch per feature): hide talking head (voice still plays), hide error messages, hide zone text, sell junk, repair (guild bank first optional).
- Retail only: quick sign-up in the group finder (hold Shift for the normal dialog) and accepting group invites (friends/guild only, or anyone).

## [0.12.0]
- New module Interface > Minimap: show minimap buttons only on mouseover (addon buttons and/or Blizzard buttons). No OnUpdate; uses OnEnter/OnLeave hooks and alpha only.

## [0.11.2]
- New profile now starts as a copy of the current profile. The separate Duplicate button is removed.

## [0.11.1]
- Fix: a section after two columns started under the right column when it was the taller one.

## [0.11.0]
- Profile system rebuilt in ElvUI/AceDB style, native (no libraries):
  per-character profile keys, default profile for all other characters, new/duplicate/reset/copy/delete.
- Import/export of shareable profile strings ("!NUI1!...") using Blizzard's C_EncodingUtil (CBOR + Deflate + Base64).
- Existing profiles and character choices are migrated automatically.
- New text box widget.

## [0.10.4]
- Fix (root cause): text paragraphs measured their height before they had a width and reported a huge height, pushing every widget below them off the screen. The text now gets an explicit width before it is measured.

## [0.10.3]
- Fix: widgets placed below a wrapping text paragraph were not shown (Profiles > Manage).
  Pixel helpers no longer clear and re-set anchors when only a size changes.

## [0.10.2]
- If an options page fails to build, the error is now printed in chat instead of leaving an empty page.

## [0.10.1]
- Fix: Profiles page stopped building after the character line (realm name / text height could be secret).

## [0.10.0]
- Profiles (General > Profiles): create, duplicate, copy from, delete, reset.
- Per-character profile or "Account default"; a default profile for all characters (also new ones).
- Existing settings are migrated into a profile named "Default".
- Dropdowns can now have changing item lists.

## [0.9.1]
- Minimap button now follows the minimap edge while dragging (OnUpdate only while the mouse is held).

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
