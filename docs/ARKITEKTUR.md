# NitexUI – arkitektur og moduldetaljer

Les bare delen du trenger. Reglene står i `CLAUDE.md`.

## Kjerne
- Lasterekkefølge i `.toc`: Locales → Core (Init, Theme, Pixel, Utils, Database, Commands) → Modules → Options (Widgets, Panel, Pages/*). Nye filer må inn i `.toc`.
- `Core/Init.lua`: namespace `ns`, `ns:RegisterEvent(event, owner, func)` (handler får `(owner, event, ...)`), modulsystem (`ns:NewModule`, `ns:SetModuleEnabled`, `OnInitialize`/`OnEnable`/`OnDisable`).
- `Core/Database.lua`: profiler (AceDB-stil, native). `ns.db` = aktiv profil. `ns.CopyDefaults` fyller inn manglende nøkler (sletter aldri). Endret datastruktur → migrering i modulens `OnInitialize` med versjonsfelt (eks. `typesVersion` i `Modules/Nameplates/Colors.lua`). Import/eksport `!NUI1!` via `C_EncodingUtil`.
- Standardverdier: `ns.defaults.<navn> = {...}` i modulens egen fil.
- `Core/Commands.lua`: `/nitex` (`/nui`) + `status`, `debug`, `reset`, `version`, `np` (nameplate-farger for target), `font` (fontfilen vinduet bruker).
- Mal for nye moduler: `Modules/_Template.lua`.

## Innstillingsvinduet
- `Options/Panel.lua`: `Options:RegisterPage{ key, label, order, desc, build | subtabs = {...} }`. Hjelpere: `Options.NewPage`, `page:Add(widget, gap, keepWidth)`, `Options.Columns`/`Options.EndColumns`, `Options.ModuleToggle`. Sidebygging i `SafeBuild`.
  - Sub-sider i ScrollFrame; høyden måles til `page.cursor`, så alt må legges til via `page:Add`/`EndColumns`.
  - Ikke tilgjengelig i kamp (lukkes på `PLAYER_REGEN_DISABLED`, åpnes igjen etter kamp).
  - Order: General 10 · Global Settings 20 · Interface 30 · Quality of Life 35 · Unit Frames 37 · Nameplates 40 · Damage Meters 45 · About 90.
- `Options/Widgets.lua`: `W.Header`, `W.Paragraph`, `W.Button(parent, label, width, onClick)`, `W.Toggle`, `W.Dropdown`, `W.ColorRow`, `W.EditBox`, `W.Tab`, `W.SubTab`. Font: Expressway (`W.FONT_FILE`); font-objektets `SetFont` returnerer ingenting – sjekk med `GetFont`.

## Sider og moduler (modulnavn i parentes)
- General: minimap-knappen (`MinimapButton`), Profiles.
- Global Settings: Fonts (`Fonts`) – endrer Blizzards font-objekter fra `GetFonts()`, hopper over `NitexUIFont_*`.
- Interface:
  - General (`InterfaceGeneral`): skjul bag-bar/mikromeny (hidden parent, venter på kampslutt). Mens mikromenyen er skjult: kø-øyet (`QueueStatusButton`) flyttes med Shift + dra (StartMoving, posisjon i `queueEyePos`, settes tilbake fra hook på `QueueStatusButton:UpdatePosition`).
  - Minimap (`InterfaceMinimap`): knapper kun ved mouseover (alpha + OnEnter/OnLeave-hooks).
  - Character Panel (`CharacterPanel`): ilvl/enchant (forkortet)/gems via `C_Item` + `C_TooltipInfo`, bare mens vinduet er åpent; slot oppdateres bare når item-linken endres. Retail: rød «Missing enchant» for `ENCHANTABLE` (Midnight: hode, skulder, bryst, bein, føtter, ringer, våpen) på maks nivå. Tekstbredde 118.
  - Tooltip (`InterfaceTooltip`): skjul HP-bar (hook på `GameTooltip.StatusBar:SetWatch` → Hide), klassefargede spillernavn (`TooltipDataProcessor.AddTooltipPostCall` for Unit, linje 1, guid sjekkes for secret).
- Quality of Life (`QualityOfLife`): skjul talking head (alpha 0), feilmeldinger, sonetekst; selg junk; reparer (guild først); Retail: rask påmelding i group finder (Shift = vanlig dialog), godta invitasjoner.
- Unit Frames, kun Retail (`UnitFramesPlayer`/`Target`/`Focus`, alt i `Modules/UnitFrames.lua`, `ns.db.unitframes`): player – class resources (hidden parent med UIParent som forelder og `.unit = "player"`; druid/monk/mage med alpha), TotemFrame, HitIndicator, Zzz, hvile-glød (hook på `PlayerFrame_UpdateStatus`); target – `ReputationColor` alpha 0; focus – aura-container skjules via hook på `FocusFrame:ConfigureAuraContainer` (alpha i kamp hvis beskyttet). Etter kamp gjøres bare reparenting på nytt.
- Nameplates: Health Colors (`NameplateColors`), Border, kun Retail (`NameplateBorder`). Se under.
- Damage Meters (`DamageMeters`): Blizzards `Blizzard_DamageMeter`. Snap via HookScript OnDragStop på sesjonsvinduene (vindu 1 = Edit Mode) – ved siden av = samme høyde, over/under = samme bredde. Rank/tall: hooksecurefunc på hver entrys `UpdateName`/`UpdateValue` (entries fanges via scrollboxens `OnAcquiredFrame`, fjernes når av). Tall via `AbbreviateNumbers` med Blizzards breakpoints + ett trinn for hele tall under 1000. Verdiene er secret i kamp: ingen aritmetikk/sammenligning, prosent utelates da. Blizzard-hjelpefunksjoner kalles bare når alle feltene de sammenligner er sjekket med `issecretvalue` (`GetFormattedSourceNameText` ga 1271 feil i 0.22.0).

## Nameplates (Midnight) – det vi vet
- Bare Blizzards egne plates: `plate.UnitFrame.HealthBarsContainer.healthBar`. Hent med `C_NamePlate.GetNamePlateForUnit(unit)`. Rør aldri `IsForbidden()`-rammer; låste plater kan ikke endres (forventet).
- Farge: cache per bar, mal på nytt fra `hooksecurefunc(bar, "SetStatusBarColor", ...)` uten API-kall. Klassifisering (som EllesmereUI): worldboss → elite boss (skalle eller ≥ +2, ikke lieutenant) → elite mini (`UnitIsLieutenant` eller +1) → rare elite → rare → caster (mana) → enemy. Nøytral egen farge utenfor kamp. Prioritet: tapped (Forever) > threat > quest > nøytral > klassifisering. `UNIT_FLAGS`/`UNIT_FACTION` bare når nøytral/tapped er på.
- Kant: skjul `healthBar.bgTexture`, `selectedBorder`, `deselectedOverlay`, `HealthBarsContainer.border` (alpha 0) og `healthBar.MaskTexture` (Hide). Flatt fyll mens på, original settes tilbake. 1 fysisk piksel målt ved NAME_PLATE_UNIT_ADDED og target-bytte; Blizzards snapping står PÅ her.

## Referanser
- Blizzards UI-kildekode: `Gethe/wow-ui-source`. Bruk sparse clone med bare mappen du trenger (`git clone --depth 1 --filter=blob:none --sparse` + `git sparse-checkout set Interface/AddOns/<Mappe>`). Aldri `git grep` over hele repoet (henter alt).
- Unit frames: `Bodify/BetterBlizzFrames`. Nameplates: `EllesmereGaming/EllesmereUI` (kun lese logikk, aldri kopiere – "all rights reserved") og `Bodify/BetterBlizzPlates`.

## Vurdert og droppet
- Scrolling i quest trackeren (22. nov): Blizzards tracker bygger bare quests som får plass, så scrolling krever at alt bygges + taint-risiko for quest-item-knapper. EllesmereUI har det bare som en helt egen tracker (Forever-only), som strider mot regel 3.
