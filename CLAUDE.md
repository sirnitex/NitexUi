# NitexUI – arbeidsregler

Disse reglene gjelder for alt arbeid på dette addonet. De er satt av eieren og skal følges uten unntak.

## 1. Lightweight og FPS-vennlig
- Ytelse går foran funksjoner. Ingenting skal kjøre oftere enn nødvendig.
- Ingen `OnUpdate`-løkker hvis et event eller en native callback kan gjøre jobben.
- Trenger noe faktisk timing: bruk `C_Timer.After` / `C_Timer.NewTicker` med fornuftig intervall, aldri per frame.
- Registrer bare events som faktisk brukes, og avregistrer dem når de ikke trengs. Bruk `RegisterUnitEvent` fremfor `RegisterEvent` når eventet gjelder én unit.
- Ikke lag nye tabeller, closures eller strenger i varme kodestier (events som fyrer ofte). Gjenbruk.
- Cache globale funksjoner som `local` øverst i filen når de brukes i varme stier.
- Ingen eksterne biblioteker (Ace3, LibStub osv.) med mindre eieren eksplisitt ber om det.

## 1b. To klienter: Retail og Forever
- Addonet skal virke på både Retail (Midnight, Interface 120105) og WoW Forever (Interface 16001). Begge bruker Mainline-API-et og "secret values".
- Én `.toc` med `## Interface: 120105, 16001`. Oppdater begge tallene ved nye patcher.
- Bruk `ns.isRetail` / `ns.isForever` bare der klientene faktisk er ulike. Guard API-er som kanskje mangler i én klient (`if C_X and C_X.Func then`).
- Retail-only modul: `if not ns.isRetail then return end` øverst i modulfilen (før `ns:NewModule`), og legg sub-taben bare til når `ns.isRetail` (se `Options/Pages/Nameplates.lua`). Retail-only valg i en felles modul: vis en forklarende tekst på Forever i stedet for bryterne.

## 1b-2. Synk til spillet (hver oppgave)
- AddOns-mappene: `G:\World of Warcraft\_retail_\Interface\AddOns\NitexUI` og `G:\World of Warcraft\_forever_\Interface\AddOns\NitexUI`. Be om tilgang med `device_request_folder_access` (begge i ett kall) hvis de ikke er koblet til.
- Fremgangsmåte: commit + push til `main` → kopier de endrede filene til en NY mappe `/mnt/user-data/outputs/sync-<tidsstempel>/` (samme relative stier) → `device_commit_files` med `force: true` til begge mappene → kontroller med `device_list_dir` (recursive) at filstørrelsene på disken er like de i repoet.
- Filer kan ikke slettes fra AddOns-mappene herfra (ingen delete-verktøy). Gamle filer som ikke står i `.toc` er ufarlige; be eieren slette dem selv. Kjent: `Modules/Example.lua` ligger igjen i begge mappene.
- Oppdater versjon i `NitexUI.toc` + ny seksjon øverst i `CHANGELOG.md` for hver levering. Hold `CLAUDE.md` (og prosjekt-dokumentet `claude/arbeidsregler.md`) oppdatert når sider/moduler endres.

## 1c. Moduler
- Alle funksjoner er egne moduler (`ns:NewModule`). **Alle moduler er AV som standard** – brukeren skrur på bare det de trenger.
- Ingen samlet "Modules"-tab. Hver modul har sin egen av/på-bryter øverst på sin side (`Options.ModuleToggle`).
- En modul som er AV skal ikke bruke systemressurser: ingen events, ingen hooks, ingen timere, ingen frames, ingen innsamlet data. Bare statiske definisjoner (lister/standardverdier) og funksjoner kan finnes i minnet.
- All oppstart skjer i `OnEnable`, aldri i filens toppnivå eller `OnInitialize` (unntak: globale verdier som må settes før verden laster, og bare hvis modulen er på).
- `OnDisable` skal avregistrere alt og frigjøre innsamlet data (`wipe`).
- Felles kjerne (f.eks. `Core/Pixel.lua`) registrerer events først når noe faktisk bruker den.
- Sjekk med `/nitex status`: med alle moduler av og vinduet ikke åpnet skal listen over events være tom.
- Implementer `OnDisable` slik at modulen kan slås av uten reload der det er mulig. Si fra når en endring krever reload.

## 1d. Arkitektur (les dette før du endrer noe)
- Repo: `sirnitex/NitexUi` (GitHub, branch `main`). Nyeste versjon står i `NitexUI.toc` og `CHANGELOG.md`.
- Lasterekkefølge i `.toc`: Locales → Core (Init, Theme, Pixel, Utils, Database, Commands) → Modules → Options (Widgets, Panel, Pages/*). Nye filer må legges inn i `.toc`.
- `Core/Init.lua`: namespace `ns`, felles event-system `ns:RegisterEvent(event, owner, func)` (handler får `(owner, event, ...)`), modulsystem (`ns:NewModule`, `ns:SetModuleEnabled`, `OnInitialize`/`OnEnable`/`OnDisable`).
- `Core/Database.lua`: profiler i ElvUI/AceDB-stil, native. `ns.db` = aktiv profil. `ns.CopyDefaults` fyller inn manglende nøkler fra `ns.defaults` (sletter aldri gamle). Endres strukturen på lagrede data: lag migrering i modulens `OnInitialize` med et versjonsfelt (eksempel: `typesVersion` i `Modules/Nameplates/Colors.lua`). Import/eksport `!NUI1!` via `C_EncodingUtil`.
- Standardverdier: hver modul legger til `ns.defaults.<navn> = {...}` i sin egen fil. Brytere inne i en modul kan godt stå på som standard; selve modulen er alltid AV.
- `Core/Commands.lua`: `/nitex` (eller `/nui`) + `status`, `debug`, `reset`, `version`, `np` (viser hva nameplate-fargene ser for target – bruk den til feilsøking i stedet for å gjette), `font` (viser fontfilen vinduet bruker).
- `Options/Panel.lua`: vinduet. Sider: `Options:RegisterPage{ key, label, order, desc, build | subtabs = {...} }`. Hjelpere: `Options.NewPage`, `page:Add(widget, gap, keepWidth)`, `Options.Columns` / `Options.EndColumns`, `Options.ModuleToggle`. Sidebygging er pakket i `SafeBuild` (feil skrives i chat).
  - Sub-sider ligger i en ScrollFrame (musehjul, tynn indikator). Høyden måles fra toppen til `page.cursor` når siden vises, så alt må legges til via `page:Add` / `EndColumns` for at scroll skal stemme.
  - Vinduet er ikke tilgjengelig i kamp: lukkes på `PLAYER_REGEN_DISABLED` og åpnes igjen etter kamp hvis det var åpent eller noen prøvde å åpne det (eventene er bare registrert når det trengs).
  - Rekkefølge (order): General 10 · Global Settings 20 · Interface 30 · Quality of Life 35 · Unit Frames 37 · Nameplates 40 · Damage Meters 45 · About 90.
- `Options/Widgets.lua`: `W.Header`, `W.Paragraph`, `W.Button`, `W.Toggle`, `W.Dropdown` (items kan være funksjon; åpen liste flyttes til vinduet så den ikke klippes, `W.CloseDropdown()`), `W.ColorRow` (getEnabled kan være nil = bare fargeknapp), `W.EditBox`, `W.Tab`, `W.SubTab`. Alle bruker `ns.PP`.
- Sider og moduler (modulnavn i parentes):
  - General (General, Profiles) – minimap-knappen (`MinimapButton`).
  - Global Settings: Fonts (`Fonts`).
  - Interface: General – skjul bag-bar/mikromeny (`InterfaceGeneral`); mens mikromenyen er skjult kan kø-øyet (`QueueStatusButton`) flyttes med Shift + dra (StartMoving, posisjon i `queueEyePos`, settes tilbake fra hook på `QueueStatusButton:UpdatePosition`) · Minimap – knapper kun ved mouseover, via alpha og OnEnter/OnLeave-hooks (`InterfaceMinimap`) · Character Panel – ilvl/enchant (forkortet)/gems i Blizzards karaktervindu via `C_Item` + `C_TooltipInfo`, oppdateres bare mens vinduet er åpent (`CharacterPanel`). Retail: rød «Missing enchant» på slots i `ENCHANTABLE` (Midnight: hode, skulder, bryst, bein, føtter, ringer, våpen) på maks nivå. Tekstbredde 118 så kolonnene ikke møtes. · Tooltip (`InterfaceTooltip`) – skjul HP-bar (hook på `GameTooltip.StatusBar:SetWatch`, Hide), klassefargede spillernavn (`TooltipDataProcessor.AddTooltipPostCall` for Unit, linje 1 i GameTooltip, guid sjekkes for secret).
  - Quality of Life: General (`QualityOfLife`) – skjul talking head (alpha 0, stemmen spilles), feilmeldinger, sonetekst; selg junk; reparer (guild først); Retail: rask påmelding i group finder (Shift = vanlig dialog), godta invitasjoner (venner/guild eller alle).
  - Unit Frames, kun Retail, én modul per fane: Player (`UnitFramesPlayer`) · Target (`UnitFramesTarget`) · Focus (`UnitFramesFocus`). Alle i `Modules/UnitFrames.lua`, felles innstillinger i `ns.db.unitframes`. Player: skjul class resources (hidden parent; druid/monk/mage med alpha), TotemFrame, HitIndicator, PlayerRestLoop (Zzz), hvile-glød (hook på `PlayerFrame_UpdateStatus`, vertex-alpha 0 mens man hviler); target: `ReputationColor` alpha 0; focus: aura-containeren skjules via hook på `FocusFrame:ConfigureAuraContainer`.
  - Nameplates: Health Colors (`NameplateColors`) · Border, kun Retail (`NameplateBorder`).
  - Damage Meters (`DamageMeters`, `Modules/DamageMeters.lua`) – Blizzards `Blizzard_DamageMeter`. Snap: HookScript OnDragStop på sesjonsvinduene (vindu 1 styres av Edit Mode, bare de andre kan flyttes) → samme størrelse og kant i kant. Rank/tall: hooksecurefunc på hver entrys `UpdateName`/`UpdateValue` (entries fanges via scrollboxens `OnAcquiredFrame`-callback, fjernes når av). Tall via `AbbreviateNumbers` (tar secret values). Verdiene er secret i kamp: ingen aritmetikk/sammenligning – prosent utelates da. Kall aldri Blizzards egne oppdaterings-/refresh-funksjoner fra vår kode i kamp (de regner på secrets). Det gjelder også små hjelpefunksjoner: `GetFormattedSourceNameText` sammenligner `sourceDisplayType` (secret i kamp) og ga 1271 feil i 0.22.0 – sjekk hvert felt med `issecretvalue` før et Blizzard-kall fra en hook.
- Mal for nye moduler: `Modules/_Template.lua`.
- Kjente fallgruver: mål aldri tekst før den har bredde (gi FontString eksplisitt `SetWidth`); gjør aldri aritmetikk/sammenligning på verdier som kan være hemmelige (`issecretvalue` først); `PP.Point` med samme punktnavn erstatter ankeret; hooks (`hooksecurefunc`/`HookScript`) kan ikke fjernes – la dem returnere med en gang når modulen er av, og si fra om det; en skjult forelder for Blizzard-rammer må selv ha en forelder (UIParent) og `.unit = "player"`, for class bars slår opp `GetParent():GetParent().unit` også mens de er skjult.

## 1d-2. Nameplates (Midnight) – det vi vet
- Vi endrer bare Blizzards egne nameplates. Struktur: `plate.UnitFrame.HealthBarsContainer.healthBar`. Hent plate med `C_NamePlate.GetNamePlateForUnit(unit)` (gir ikke forbidden-plater). Rør aldri `IsForbidden()`-rammer.
- Forbidden/låste plater (vennlige i instanser, og mobs som ikke kan angripes) kan ingen addon endre. Det er forventet, ikke en feil.
- Farge: cache farge per bar og mal den på nytt fra en `hooksecurefunc(bar, "SetStatusBarColor", ...)` som ikke kaller API-er. Klassifisering (samme logikk som EllesmereUI): worldboss → elite boss (skalle eller ≥ +2 effektive nivåer, ikke lieutenant) → elite mini (`UnitIsLieutenant` eller +1) → rare elite → rare → caster (`UnitHasPowerType(unit, Enum.PowerType.Mana)`) → enemy. Nøytral (reaction 4 / angripbar men ikke fiendtlig) får egen farge utenfor kamp. Prioritet: tapped (Forever) > threat > quest > nøytral > klassifisering.
- Kant: Blizzard-kunst som må skjules for en ren 1px-kant: `healthBar.bgTexture`, `healthBar.selectedBorder`, `healthBar.deselectedOverlay`, `HealthBarsContainer.border` (alpha 0) og `healthBar.MaskTexture` (Hide – myk avrundet maske). Flatt fyll (`WHITE8X8`) mens på, original atlas/fil lagres og settes tilbake. Linjene festes til `healthBar`, tykkelse = 1 fysisk piksel ved platens skala (måles ved NAME_PLATE_UNIT_ADDED og target-bytte); Blizzards texture-snapping står PÅ her fordi plate-skalaen endres med avstand.
- Blizzards egen UI-kildekode for gjeldende patch: `Gethe/wow-ui-source` (sparse clone, f.eks. `Interface/AddOns/Blizzard_UnitFrame`). Bruk den for eksakte frame-navn før du gjetter. BetterBlizzFrames (`Bodify/BetterBlizzFrames`) er god referanse for unit frames.
- Referanser (kun til å lese logikk, aldri kopiere kode – EllesmereUI er "all rights reserved"): `EllesmereGaming/EllesmereUI` (`EllesmereUINameplates/EUI_Nameplates_Colors.lua`) og `Bodify/BetterBlizzPlates` (`retail/BetterBlizzPlates.lua`). Kan klones lesbart med `git clone --depth 1`.

## 1e. Spar bruk
- Pakk flere endringer i én runde. Synk til AddOns-mappene én gang per oppgave, ikke per liten rettelse.
- Sjekk layout og fallgruvene i 1d før noe sendes til test, så vi slipper feilsøkingsrunder.
- Når eieren sier "gjør som EllesmereUI" eller noe ikke virker: les referansekoden / bruk `/nitex np`-lignende feilsøking før du gjetter.
- Korte svar. Les bare filene som trengs.
- Ingen Lua-tolk i arbeidsmiljøet: les gjennom endret kode nøye før levering.
- Ved skripting av filendringer: les filen FØR den åpnes for skriving (å åpne med "w" tømmer den – det har ødelagt locale-filene én gang). Sjekk filstørrelser etterpå.

## 2. Lua-versjon
- Kun Lua 5.1, slik WoW-klienten bruker. Ingen `goto`, ingen heltallsdivisjon `//`, ingen bit-operatorer `& | ~` (bruk `bit.band` osv.), ingen `table.unpack` (bruk `unpack`).

## 3. Kun Blizzards native API
- Bruk Blizzards egne API-er, frames, templates og mixins (`C_*`-namespaces, `CreateFrame`, `hooksecurefunc`, `EventRegistry`, osv.).
- Foretrekk å style/flytte Blizzards eksisterende frames fremfor å bygge egne erstatninger.
- Ikke reimplementer noe Blizzard allerede gir ferdig (f.eks. ferdig beregnede verdier, formaterte tall, farger, timere).
- Respekter Midnight-restriksjonene: ikke prøv å omgå "secret values" eller beskyttede kampdata.
- Unngå taint: ikke overskriv Blizzard-funksjoner, bruk `hooksecurefunc`. Ikke endre beskyttede frames i kamp (`InCombatLockdown()`).

## 4. Minst mulig egen matte og automasjon
- Ingen egne beregninger når API-et kan gi svaret.
- Ingen automatisering som spillet ikke selv legger opp til.
- Unntak eieren har bedt om (Quality of Life): selg junk, reparer, godta gruppeinvitasjoner, rask påmelding i group finder. Bruk Blizzards egne funksjoner for dem.

## 5. Pixel perfect på alle UI scales
- Alle 1px borders, linjer og outlines skal være nøyaktig én fysisk skjermpiksel, skarpe, på enhver UI scale og oppløsning.
- Bruk alltid `ns.PP` (Core/Pixel.lua): `PP.Border`, `PP.Size`/`Width`/`Height`, `PP.Point`, `PP.PixelWidth`/`PixelHeight`, og `W.Fill` (som skrur av Blizzards texture-snapping).
- Aldri `PixelUtil.SetHeight(x, 1)` for 1px-linjer: det runder 1 UI-enhet og kan gi 2px.
- Rammer med border/fyll ankres i hjørner (TOPLEFT/TOPRIGHT osv.), ikke CENTER/LEFT/RIGHT, som kan havne på halve piksler.
- Ank aldri layout til en FontString (høyden er ikke hele piksler). Bruk rammer med fast høyde.
- Omberegning skjer kun på `UI_SCALE_CHANGED` / `DISPLAY_SIZE_CHANGED`, aldri per frame.
- Unntak: nameplates endrer skala med avstand. Der beholdes Blizzards texture-snapping, og tykkelsen måles når platen dukker opp / target byttes (se 1d-2). Ikke OnUpdate.

## 6. Varsle før noe FPS-tungt
- **Hvis eieren ber om noe som krever egen matte, hyppige oppdateringer, OnUpdate, mange frames eller annet som kan koste FPS: si fra FØR det bygges.** Forklar kostnaden kort, og foreslå et lettere alternativ hvis det finnes. Vent på svar før du implementerer.

## 7. Åpne oppgaver (start her neste økt)
1. **Test i spillet (0.18.0):** `/nitex font` skal vise Expressway + OK (krever full omstart av spillet første gang). Fokus-auraer i kamp (blir de tonet ut uten feilmeldinger?), class resources, rask påmelding, talking head, Nameplates Border etter maske-fix.
2. Løst 22. nov (0.18.0): fonten (Font-objektets `SetFont` returnerer ingenting, så fallback slo alltid inn; Fonts-modulen overstyrte også `NitexUIFont_*` via `GetFonts()`), og kodegjennomgangen (flag-events i Colors, kampventing i QoL/UnitFrames, CharacterPanel sammenligner item-link per slot).
3. Kjent, ikke endret: `Modules/Interface/General.lua` venter fortsatt på kampslutt (bag-bar/mikromeny kan være beskyttet). Overlay-rammene i CharacterPanel blir liggende (skjult) etter at modulen slås av; rammer kan ikke slettes i WoW.
