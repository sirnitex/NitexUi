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
