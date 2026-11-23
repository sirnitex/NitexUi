# Changelog

## [0.28.2]
- Nameplates > Health Colors: threat % has its own section at the bottom of the page.
- Threat % sits right where the mob name ends, in the same font and size as the name ("| 100%").
- New option "Colour the number": green at 100%, then yellow and orange, red at 0%. Values the game keeps secret are shown without colour.
- The number box used by Databars is now a shared widget (`W.NumberBox`).

## [0.27.0]
- Nameplates > Health Colors: new threat colour "Tank: another tank has aggro" (off-tank, on by default). Same method as EllesmereUI: the mob's target has the tank role, or (when the game hides it) another tank in the group is tanking the mob, folded with Blizzard's C_CurveUtil so secret values are never read.

## [0.26.0]
- Nameplates > Health Colors: new option "Show threat % by the name" (off by default). Shows "| 100%" after the name; 100% = you have aggro. Updates on Blizzard's threat events only, follows "Only in groups".

## [0.25.3]
- Performance pass (no visible changes):
  - Nameplates > Health Colors: threat and quest events are only registered while those colours are on. Quest log bursts cause one repaint instead of many; raid roster changes only repaint when you join or leave a group.
  - Nameplates > Border: a target change only touches the old and the new target plate (was every plate on screen); layout and colour are skipped when unchanged.
  - Interface > Minimap: one GetChildren() call per scan instead of one per child.
  - Interface > Character Panel: UNIT_INVENTORY_CHANGED for the player only.
  - Global Settings > Fonts: a burst of ADDON_LOADED events (login) runs one font pass.
  - Forever > Reminders: aura changes in combat are ignored (the row is hidden there anyway); spell names are cached.
  - Forever rows and pixel helpers: size and layout are not re-applied when nothing changed.

## [0.25.2]
- Databars: width and height are typed in (whole numbers, Enter to apply, Esc to undo). Width 50 up to the full screen width, height 10 to 100. The bar is now exactly the width you set.

## [0.25.1]
- Forever: Flight Timer removed (other addons such as InFlight already ship flight times).

## [0.25.0]
- New page Forever (only on the Forever client), five modules, all off by default:
  - Flight Timer: a bar in Blizzard's cast bar style counts down while you fly, with the destination underneath. Each route is learned the first time you fly it; until then the bar shows the time so far. Flight time also shows when you hover a flight point on the taxi map. Test bar, Shift + drag, reset and "Forget learned routes".
  - Camping: a message when a campfire is nearby and you have no camp buffs, and 5 minutes before Camp Benefits run out.
  - Reminders: icons for class buffs you know but are missing (Arcane Intellect, Mage/Ice/Frost Armor, Fortitude, Mark of the Wild, Blessing, Aura, Demon Armor, Lightning Shield, Aspect, ...), weapon buffs (poisons, imbues) and Well Fed. Only out of combat.
  - Weapon Skills: your skill in weapon tooltips (red if not learned), a message when an equipped weapon's skill is maxed, and a hint when it is far below the maximum.
  - Ammo & Reagents: icons with how much ammo and class reagents you carry, red when low, and a list of low items at vendors.
- Core: player-only unit events (`ns:RegisterPlayerEvent`), shown in `/nitex status`.

## [0.24.0]
- New Interface > Databars (module, off by default): a small bar in Blizzard's tooltip style with FPS, latency, durability, gold, free bag slots, item level and clock. Each element has its own switch. Clicks open the character panel, bags or calendar.
- Databars size: width, height and font size.
- Databars position: move it in Blizzard's Edit Mode (Blizzard's own highlight), or with Shift + drag at any time. Reset button puts it back at the top centre.

## [0.23.0]
- Options window restructured. Sidebar order: General, Global Settings, Interface, Unit Frames, Nameplates, Damage Meters, Quality of Life.
- About is now a tab under General (sidebar shows only the seven pages).
- Sidebar: "Modules" group label above the module pages.
- Pages with only one section no longer show a lone sub-tab bar.

## [0.22.3]
- Damage Meters: snapping beside a window matches its height, snapping above or below matches its width. The other size is kept.

## [0.22.2]
- Damage Meters: DPS/HPS under 1000 is shown as a whole number (121 instead of 120.81176470588).

## [0.22.1]
- Damage Meters: fixed a Lua error in combat with "Hide rank" (secret values). In combat the name is shown without the small elite/faction icon until combat ends.

## [0.22.0]
- New page Damage Meters (module, off by default) for Blizzard's own damage meter: snap windows to each other (same width and height, edge to edge), hide the rank number, and short numbers (1.5M instead of 1500K).

## [0.21.0]
- Interface > General: while the micro menu is hidden, the queue status eye can be moved with Shift + drag. The spot is saved per profile; new "Reset eye position" button.

## [0.20.0]
- New Interface > Tooltip (module, off by default): hide the health bar under unit tooltips, and class-coloured player names.

## [0.19.0]
- Character Panel: shorter enchant text ("Enchant Helm - " removed, stat names abbreviated) and narrower text, so the left and right columns no longer run into each other.
- Character Panel (Retail): red "Missing enchant" on items that can be enchanted but are not (head, shoulder, chest, legs, feet, rings, weapons; max level only). Own switch.

## [0.18.1]
- Unit Frames: fixed a Lua error from the Warlock soul shard bar (and other class bars) when entering or leaving combat while class resources were hidden.

## [0.18.0]
- Options window font fixed: it always fell back to the client font (a font object's SetFont returns nothing, so the check failed). Expressway is now used.
- Global Settings > Fonts no longer overrides the options window's own fonts, and Expressway can be chosen as the game font.
- New /nitex font: shows which font file the options window uses.
- Nameplates > Health Colors: UNIT_FLAGS / UNIT_FACTION are only watched while the Neutral colour (or Tapped on Forever) is on.
- Quality of Life: hiding zone text no longer waits for combat to end.
- Unit Frames: after combat only the class resources / totem frame are re-applied. Focus buffs/debuffs are faded instead of hidden if the frame is locked in combat.
- Character Panel: when your inventory changes, only slots whose item changed are read again.

## [0.17.2]
- Options window uses the Expressway font (bundled in Media/Fonts). Needs a full game restart the first time.

## [0.17.1]
- Unit Frames split into three modules with their own sub-tab and switch: Player, Target, Focus. If Unit Frames was on, all three are turned on.

## [0.17.0]
- New page Unit Frames (Retail only): hide class resources, totem frame, combat text, resting Zzz and resting glow on the player frame; hide the reputation colour on the target frame; hide buffs/debuffs on the focus frame.

## [0.16.4]
- Options reopen by themselves when combat ends, if they were open when combat started or you tried to open them during combat (same page). Toggling again during combat cancels it.

## [0.16.3]
- Options window is not available in combat: it closes when combat starts and cannot be opened until combat ends.

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
