---
task: peloton-systeem-uit-schets-014
date: 2026-09-21
source: .planning/sketches/014-peloton-rij/gekozen.html
---

# Peloton-systeem bouwen (schets 014)

Joost koos in schets 014: **links op de Home-kaart in het blauw het peloton-lint bij een
groepsrit en één fietser als je alleen gaat; de megafoon alleen in de rolregel van je eigen
rit; meerijden is tekst zonder icoon; en een teller van fietsjes waarvan de wachtenden
doorzichtig zijn, met "3 gaan mee · 1 wacht nog" ernaast.** De rittenlijst krijgt géén
linkerkolom (bewust, 2026-09-21).

## Taken

1. **Het lint als tekening in Dart** — `lib/theme/ride_mark.dart` (nieuw).
   Het samengevoegde pad uit de schets (drie Phosphor-fietsers over elkaar met Phosphors eigen
   uitsparing) plus de enkele fietser, als `Path` in code, getekend door één widget `RideMark`.
   *Afwijking van "eigen icoonfont":* een `IconData` wordt altijd in een vierkant van
   `size × size` gelegd, en het lint is 2,3× zo breed als hoog — dat zou over de buurtekst heen
   lopen. Eén pad in Dart is diffbaar, heeft geen binair bestand en geen pubspec-regel nodig,
   en de twee merktekens delen gegarandeerd dezelfde grondlijn.
2. **`AppIcons.megaphoneSimple`** (0xe642) toevoegen.
3. **`ride_role_style.dart`** — icoon wordt optioneel: megafoon bij `organiser`, géén icoon bij
   `joined` en `solo`, zandloper bij `pending`, verbod bij `declined`. `RideRoleLine` laat de
   icoonruimte weg als er geen icoon is.
4. **`peloton_counter.dart`** (nieuw, gedeeld) — de teller: `acceptedCount` volle fietsjes +
   `pendingCount` doorzichtige, maximaal vijf plus `+n`, met de bestaande zinnen
   `ridePelotonGoing` / `ridePelotonWaiting` ernaast. Verschijnt bij élke groepsrit, niet
   alleen bij de rit die je zelf organiseert.
5. **Home** (`home_screen.dart`) — het blauwe merkteken links (lint of fietser) en de teller
   onder de rolregel.
6. **Rittenlijst** (`planned_rides_screen.dart`) — teller in plaats van de kale samenvattingszin;
   geen linkerkolom.
7. **Detail** (`ride_detail_screen.dart`) — lint in de kop van de peloton-kaart, teller boven de namen.
8. **Controle** — `flutter analyze`, en het lint bij 14/16/20 px op de Oppo bekijken.

## Grenzen

- Geen nieuwe pakketten, geen nieuwe l10n-sleutels (de bestaande zinnen blijven).
- `acceptedCount` telt de organisator niet mee; de fietsjes volgen exact de zin ernaast.
