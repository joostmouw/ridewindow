---
quick_id: 260919-f0a
slug: a-locatie-volgt-de-fietser
status: complete
date: 2026-09-19
commits:
  - 351e0f4
origin: tester in Aruba — "licht van 01:32 tot 13:29"
diagnosis: https://claude.ai/artifact/Kvof7uzvxx43EUFicVDTPX
---

# Quick 260919-f0a — A: de locatie volgt de fietser

## De melding en wat er werkelijk speelde

Een tester in Aruba zag op de daglichtbalk `licht van 01:32 tot 13:29`. De zonneberekening
was niet stuk: `sunTimes()` gedraaid met het toestel op Aruba-tijd en Amsterdamse
coördinaten geeft `01:21–13:46`. De app rekende de zon uit voor Amsterdam en tekende hem op
de klok van Aruba.

Drie onafhankelijke oorzaken. Deze taak repareert er drie van de vier genummerde punten;
de tijdas zelf blijft bewust staan.

| | Wat | Status |
|---|---|---|
| 1 | Mislukte GPS viel stilzwijgend terug op Amsterdam | gerepareerd |
| 2 | Achtergrondtaak kende GPS niet en overschreef de verse cache | gerepareerd |
| 3 | `utc_offset_seconds` wordt opgevraagd en weggegooid | **blijft liggen**, nu wel zichtbaar gemaakt |
| 4 | Stedenlijst hield op bij de Nederlandse grens | gerepareerd |

## Wat er gebouwd is

**`LastKnownLocationStore`** — drie sleutels onder `location.*`, bewust buiten `profile.*`.
Dat laatste wordt naar Supabase gesynct en waar dít toestel is hoort niet op een ander
toestel terug te komen. Geen Flutter-afhankelijkheid, zodat de WorkManager-isolate hem leest.

**De keten** in `location_provider.dart` wordt `override → GPS → laatst bekend → Amsterdam`.
`LocationData` krijgt een `source`, zodat de UI het verschil tussen *gemeten* en *aangenomen*
kan zien in plaats van het te raden.

**`resolveBackgroundLocation()`** is uit `callbackDispatcher` gelicht zodat hij zonder
WorkManager te testen is, en leest dezelfde laatst bekende positie.

**De waarschuwing op Home** verschijnt als de plek een gok is, of als de klok van dit toestel
meer dan drie uur afwijkt van de zonnetijd van de getoonde lengtegraad. Die drempel is geen
willekeur: Nederland zit 's zomers 1,7 uur van zijn eigen zonnetijd af, dus alles onder de
drie uur zou zomertijd aanzien voor een reis.

**`kNlCities` → `kCities`**, dertien plaatsen erbij voor BE, IT, GB en US — de vier andere
landen van de gesloten test. De oude naam klopte niet meer.

## Waarom fout 3 blijft liggen

De hele tijdas op de locatie zetten raakt de vensterberekening, de beschikbaarheidskalender,
de daglichtbalk én de notificaties, en maakt de 7×24-kalender dubbelzinnig: is jouw
dinsdagochtend die van jou of die van de bestemming? Joost koos richting A. De waarschuwing
is de eerlijke tussenstand: de app doet geen alsof.

## Verificatie

- `flutter analyze`: schoon
- `flutter test`: 595/595 groen (21 nieuwe)
- Drie widget-tests renderen Home werkelijk en toetsen dat de banner verschijnt bij een gok,
  verschijnt bij een vreemde klok, en zwijgt bij een gemeten positie

## Niet met eigen ogen gezien

Niets op de Oppo gedraaid. De banner is in een gerenderd scherm bewezen, niet op glas. En het
echte geval — een toestel dat wérkelijk in een andere tijdzone staat — is alleen na te bootsen
door de klok van een toestel te verzetten.
