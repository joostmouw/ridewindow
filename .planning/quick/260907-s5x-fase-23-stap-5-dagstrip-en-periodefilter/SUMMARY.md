---
task_id: 260907-s5x
slug: fase-23-stap-5-dagstrip-en-periodefilter
date: 2026-09-07
milestone: v4.0
phase: 23
status: complete
---

# Stap 5 — dagstrip en periodefilter rustiger (plus uitklapbare ritkaarten)

Laatste stap van fase 23, uit `.planning/sketches/001-home-hierarchie/`:
*"De dagchips verliezen hun gekleurde achtergrond; de kwaliteit van een dag
wordt een 3px onderstreping in de tierkleur. Het `SegmentedButton` wordt een
tekstrij met onderstreping. Beide houden op om met de inhoud te concurreren."*

Onderweg vroeg Joost er een feature bij, die hier meteen in meegenomen is.
498 tests groen, `flutter analyze` zonder fouten. Op de Oppo geverifieerd.

## De dagstrip: twee betekenissen die op één eigenschap zaten

Dit was de eigenlijke fout, en hij was groter dan "te veel kleur". De
achtergrondkleur van een dagchip droeg tegelijk:

- **de kwaliteit van die dag** — `perfectBg` / `acceptableBg` / `poorBg`, en
- **of hij geselecteerd was** — `primaryContainer` / `tertiaryContainer` / wit.

Eén eigenschap, twee betekenissen. Daardoor kon je aan een gekleurd blokje niet
zien of het groen was omdat de dag goed is of omdat je hem had aangetikt.

Nu zijn het twee kanalen: **kwaliteit is de onderstreping** (3px in de
tierkleur), **selectie is de vulling** (`surfaceContainer`, bewust een neutrale
tonale trap en géén tierkleur, zodat ze niet opnieuw kunnen gaan samenvallen).

Twee dingen die daaruit volgden:

- **"Vandaag" moest verhuizen.** Dat was een randje van 1px om de chip, en
  zonder vulling heeft zo'n randje niets om omheen te liggen — bovendien botste
  het met de rand die selectie aangaf. Nu draagt het weekdaglabel het: vandaag
  in de merkkleur.
- **De `AnimatedScale` van 1.08 is vervallen.** Een chip die opspringt trekt
  aandacht naar het filter terwijl het antwoord eronder staat. De haptische tik
  blijft, dus de bevestiging bij aanraken is niet weg.

## Het periodefilter: van knoppenbalk naar drie woorden

Het `SegmentedButton` stond als een volledige omrande knoppenbalk pal boven de
ritkaarten en trok evenveel aandacht als het antwoord eronder. Nu drie woorden
met een onderstreping. De iconen (zon, wolk, maan) zijn meegegaan: "Morning"
zegt al wat er staat.

**Eén ding dat ik na de eerste toestelcontrole heb teruggedraaid.** In de eerste
versie had een uitgeschakeld dagdeel géén streepje. Met alle drie aan — de
standaard, en dus wat je het vaakst ziet — was er dan nergens een onderstreping,
en las de rij als een bijschrift in plaats van als een bedienbaar filter. Uit is
nu een haarlijn in `outlineVariant`, aan een streep van 3px in `primary`. Drie
streepjes op een rij zeggen "hier valt te kiezen"; dikte en kleur zeggen welke
aan staat. Dit is de werkafspraak uit `EIGEN-GEZICHT.md` — de app mag geen
huiswerk achterlaten — toegepast op een control die te stil was geworden.

Het tikgedrag is bewust niet één-op-één overgenomen van `SegmentedButton`:
vanuit "alles aan" is een tik nu een keuze vóór dat dagdeel in plaats van het
uitzetten ervan. Anders moet je twee keer tikken om te krijgen wat je bedoelde.
Alles uitzetten valt terug op alles aan, wat `emptySelectionAllowed` eerder
opving.

## Erbij gevraagd: de kleine kaarten kunnen open

Joost, tijdens de uitvoering: *"ik wil dat je alle kleinere tijdvakken ook kan
openklikken zodat ze ook zo groot worden als het ideaal voorgestelde tijdvak."*

De compacte regel blijft de rusttoestand — drie volle balken op élke kaart is
precies waarom de lijst als één massa las — maar dicht is nu geen eindstation
meer. Tik op de weerregel en de kaart klapt open tot dezelfde balken als de
beste, met een `AnimatedSize` ertussen.

Twee details die het laten werken:

- **De tik op de kaart gaat nog steeds naar het detailscherm.** De binnenste
  `InkWell` wint de hit-test, dus de twee bijten elkaar niet.
- **De staat hangt aan `slot.start`, niet aan een index.** Een `RideSlot` heeft
  geen id en de lijst wordt bij elke weerverversing opnieuw opgebouwd; de
  begintijd overleeft dat en een index niet — anders klapt na een refresh een
  andere kaart open dan die je had aangetikt.

Nieuwe tekst in beide ARB's: `showWeatherDetails` / `hideWeatherDetails`, als
semantisch label voor de screenreader.

## Fase 23 hierna

Alle zes de stappen staan. Rest alleen nog het kleine punt uit de sweep:
**Peloton-kaarten missen hun haarlijn.**
