# NitexUI – arbeidsregler

Satt av eieren, følges uten unntak. Detaljer om moduler, sider og nameplates: `docs/ARKITEKTUR.md` (les bare delen du trenger).

## 1. Lett og FPS-vennlig
- Ytelse foran funksjoner. Ingen `OnUpdate` hvis et event/callback kan gjøre jobben; timing via `C_Timer` med fornuftig intervall.
- Bare events som brukes; avregistrer når de ikke trengs. `RegisterUnitEvent` for én unit.
- Ingen nye tabeller/closures/strenger i varme stier. Cache globale funksjoner som `local`.
- Ingen eksterne biblioteker uten at eieren ber om det.

## 2. Retail og Forever
- Retail (Midnight, 120105) og Forever (16001), begge Mainline-API og secret values. Én `.toc`: `## Interface: 120105, 16001`.
- `ns.isRetail`/`ns.isForever` bare der klientene er ulike. Guard API-er (`if C_X and C_X.Func then`).
- Retail-only modul: `if not ns.isRetail then return end` før `ns:NewModule`, sub-tab bare når `ns.isRetail`. Retail-only valg i felles modul: forklarende tekst på Forever.

## 3. Moduler
- Alt er moduler (`ns:NewModule`), **AV som standard**, egen bryter øverst på sin side (`Options.ModuleToggle`).
- AV = ingen events, hooks, timere, frames eller innsamlet data. Oppstart i `OnEnable`; `OnDisable` avregistrerer og `wipe`-er. Slå av uten reload der det går; si fra når reload trengs.
- `/nitex status`: med alt av og vinduet ulest skal event-listen være tom.

## 4. Kun Blizzards native API
- Blizzards API, frames, templates, mixins. Style/flytt Blizzards egne frames, ikke bygg erstatninger. Ikke reimplementer det Blizzard gir.
- Ikke omgå secret values. Unngå taint: aldri overskriv Blizzard-funksjoner (bruk `hooksecurefunc`), ikke endre beskyttede frames i kamp.
- Minst mulig egen matte og automasjon. Unntak (QoL): selg junk, reparer, godta invitasjoner, rask påmelding.

## 5. Pixel perfect
- 1px = én fysisk piksel på alle UI scales. Alltid `ns.PP` (`PP.Border`, `PP.Size`, `PP.Point` …) og `W.Fill`. Aldri `PixelUtil.SetHeight(x, 1)`.
- Rammer med border/fyll ankres i hjørner. Aldri ank layout til en FontString. Omberegning bare på `UI_SCALE_CHANGED`/`DISPLAY_SIZE_CHANGED`. Unntak: nameplates (se arkitektur).

## 6. Varsle før noe FPS-tungt
- Egen matte, hyppige oppdateringer, OnUpdate, mange frames: si fra FØR det bygges, foreslå lettere alternativ, vent på svar.

## 7. Lua 5.1
- Ingen `goto`, `//`, `& | ~` (bruk `bit.*`), `table.unpack` (bruk `unpack`). Ingen Lua-tolk her: les endret kode nøye før levering.

## 8. Kjente fallgruver
- Aldri aritmetikk/sammenligning på verdier som kan være secret (`issecretvalue` først). Kall ikke Blizzard-funksjoner fra hooks hvis de regner på/sammenligner secret-felt.
- Gi FontString `SetWidth` før tekst måles. `PP.Point` med samme punktnavn erstatter ankeret.
- Hooks kan ikke fjernes: returner med en gang når av.
- Skjult forelder for Blizzard-rammer: forelder UIParent og `.unit = "player"`.
- Font-objekters `SetFont` returnerer ingenting (sjekk med `GetFont`).
- Les en fil før den åpnes for skriving i skript; sjekk størrelser etterpå.

## 9. Levering (hver oppgave, én gang)
- Repo `sirnitex/NitexUi`, branch `main`. Bump versjon i `NitexUI.toc` + ny seksjon øverst i `CHANGELOG.md`.
- Commit + push → `sh tools/stage-sync.sh [antall commits]` (kopierer endrede .toc/.lua/media og skriver JSON-listen) → `device_commit_files` med `force: true` → én `device_list_dir` på mappen med den viktigste filen, i én av klientene, for å sjekke størrelsen.
- AddOns-mapper: `G:\World of Warcraft\_retail_\Interface\AddOns\NitexUI` og `…\_forever_\…`. Mangler tilgang: `device_request_folder_access` med begge i ett kall.
- Filer kan ikke slettes herfra; be eieren (kjent: `Modules/Example.lua`).
- Oppdater `docs/ARKITEKTUR.md` når moduler/sider endres. `CLAUDE.md` og prosjektdokumentet `claude/arbeidsregler.md` bare når reglene endres.

## 10. Spar bruk
- Én økt per større oppgave; start ny økt etterpå (historikken koster ved hver forespørsel).
- Pakk endringer i én runde. Korte svar, ingen lange oppsummeringer.
- Les bare filene/delene som trengs (`grep -n`, `sed -n a,bp`), aldri hele store filer eller lange kommandoutskrifter (`| head`).
- Blizzard-kilde: sparse clone av bare mappen som trengs (se arkitektur). Gjenbruk `/tmp/wus` hvis den finnes.
- Når noe ikke virker eller «gjør som EllesmereUI»: les referansekoden målrettet før du gjetter.

## 11. Åpne oppgaver
1. Ikke testet i spillet: `/nitex font` (Expressway + OK etter full omstart), fokus-auraer i kamp, class resources, rask påmelding, talking head, Nameplates Border, Tooltip, kø-øye, Damage Meters i kamp (Complete-visning).
2. Kjent: `Modules/Interface/General.lua` venter på kampslutt. CharacterPanel-overlays blir liggende skjult etter av.
