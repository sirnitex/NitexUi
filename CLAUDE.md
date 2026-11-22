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
- Hver endring synkes til begge AddOns-mappene: `G:\World of Warcraft\_retail_\Interface\AddOns\NitexUI` og `G:\World of Warcraft\_forever_\Interface\AddOns\NitexUI`.
- Ved synk: legg filene i en NY staging-mappe hver gang (aldri gjenbruk en gammel), og kontroller etterpå med `device_list_dir` at filstørrelsene på disken er like de i repoet. En overføring kan melde "written" og likevel ha skrevet en gammel kopi.

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
- Repo: `sirnitex/NitexUi` (GitHub, branch `main`). Lokalt testes det i AddOns-mappene (se 1b). Nyeste versjon står i `NitexUI.toc` og `CHANGELOG.md`.
- Lasterekkefølge i `.toc`: Locales → Core (Init, Theme, Pixel, Utils, Database, Commands) → Modules → Options (Widgets, Panel, Pages/*).
- `Core/Init.lua`: namespace `ns`, felles event-system `ns:RegisterEvent(event, owner, func)`, modulsystem (`ns:NewModule`, `ns:SetModuleEnabled`, `OnEnable`/`OnDisable`).
- `Core/Database.lua`: profiler i ElvUI/AceDB-stil, native. `ns.db` = aktiv profil. `profileKeys` per karakter, `defaultProfile` for alle andre. Import/eksport `!NUI1!` via `C_EncodingUtil`. Bytte/kopiere/nullstille profil = `ReloadUI()`.
- Standardverdier: hver modul legger til `ns.defaults.<navn> = {...}` i sin egen fil.
- `Options/Panel.lua`: vinduet (`/nitex`). Sider registreres med `Options:RegisterPage{ key, label, order, desc, build | subtabs = {...} }`. Hjelpere: `Options.NewPage`, `page:Add(widget, gap, keepWidth)`, `Options.Columns` / `Options.EndColumns`, `Options.ModuleToggle`. Sidebygging er pakket i `SafeBuild` (feil skrives i chat).
- `Options/Widgets.lua`: `W.Header`, `W.Paragraph`, `W.Button`, `W.Toggle`, `W.Dropdown` (items kan være funksjon), `W.ColorRow`, `W.EditBox`, `W.Tab`, `W.SubTab`. Alle bruker `ns.PP`.
- Sider: General (General, Profiles) · Global Settings (Fonts) · Interface (General, Minimap, Character Panel) · Quality of Life (General) · Nameplates (Health Colors) · About.
- Moduler: `MinimapButton`, `Fonts`, `InterfaceGeneral`, `InterfaceMinimap`, `CharacterPanel`, `QualityOfLife`, `NameplateColors`. Mal: `Modules/_Template.lua`.
- Kjente fallgruver: mål aldri tekst før den har bredde (gi FontString eksplisitt `SetWidth`); gjør aldri aritmetikk på verdier som kan være hemmelige (`issecretvalue`); `PP.Point` med samme punktnavn erstatter ankeret.

## 1e. Spar bruk
- Pakk flere endringer i én runde. Synk til AddOns-mappene én gang per oppgave, ikke per liten rettelse.
- Sjekk layout og fallgruvene i 1d før noe sendes til test, så vi slipper feilsøkingsrunder.
- Korte svar. Les bare filene som trengs.

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

## 5. Pixel perfect på alle UI scales
- Alle 1px borders, linjer og outlines skal være nøyaktig én fysisk skjermpiksel, skarpe, på enhver UI scale og oppløsning.
- Bruk alltid `ns.PP` (Core/Pixel.lua): `PP.Border`, `PP.Size`/`Width`/`Height`, `PP.Point`, `PP.PixelWidth`/`PixelHeight`, og `W.Fill` (som skrur av Blizzards texture-snapping).
- Aldri `PixelUtil.SetHeight(x, 1)` for 1px-linjer: det runder 1 UI-enhet og kan gi 2px.
- Rammer med border/fyll ankres i hjørner (TOPLEFT/TOPRIGHT osv.), ikke CENTER/LEFT/RIGHT, som kan havne på halve piksler.
- Ank aldri layout til en FontString (høyden er ikke hele piksler). Bruk rammer med fast høyde.
- Omberegning skjer kun på `UI_SCALE_CHANGED` / `DISPLAY_SIZE_CHANGED`, aldri per frame.

## 6. Varsle før noe FPS-tungt
- **Hvis eieren ber om noe som krever egen matte, hyppige oppdateringer, OnUpdate, mange frames eller annet som kan koste FPS: si fra FØR det bygges.** Forklar kostnaden kort, og foreslå et lettere alternativ hvis det finnes. Vent på svar før du implementerer.
