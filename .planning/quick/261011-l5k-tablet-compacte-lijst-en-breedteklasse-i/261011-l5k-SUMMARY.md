---
phase: quick-261011-l5k
plan: 01
status: complete
subsystem: home, analytics
tags: [tablet, adaptief, home, analytics, privacy]
requires: [quick-261011-jru, quick-261011-kb9]
provides: [FilledScoreBadge, onScoreFill, compacte rijen op expanded, vastgezette filterkop, window_class op app_open]
affects: [lib/features/home/home_screen.dart, lib/main.dart, docs/privacy-policy.html]
tech-stack:
  added: []
  patterns: [PinnedHeaderSliver voor een kop die zijn eigen hoogte meet, tekstkleur per vulling via WCAG-contrast]
key-files:
  created:
    - lib/features/home/filled_score_badge.dart
    - test/features/home_compact_rows_test.dart
    - .planning/sketches/017-tablet-compacte-lijst/README.md
  modified:
    - lib/features/home/home_screen.dart
    - test/features/home_hover_test.dart
    - lib/core/analytics_events.dart
    - lib/main.dart
    - test/services/analytics_service_test.dart
    - docs/privacy-policy.html
    - .planning/sketches/MANIFEST.md
decisions:
  - "Compacte rij alleen vanaf expanded; medium en telefoon houden de grote kaarten"
  - "Beste keuze als tekstlabel rechtsonder in de compacte rij, geen pil"
  - "Scrollable.ensureVisible blijft bij pijl naar de eerste rij; de test bewijst dat de rij onder de vastgezette kop komt"
  - "window_class alleen als klassenaam op app_open, via de bestaande toestemmingssloten"
metrics:
  duration: "~7 min"
  completed: 2026-10-11
  tasks: 3
  files: 10
---

# Quick 261011-l5k: tablet compacte lijst en breedteklasse op app_open

Vanaf 840 dp toont Home rijen van ~64 px zoals Gmail. Elke rij heeft een gevuld scorebolletje van 44 px (tekst wit of zwart op basis van het WCAG-contrast), dag + tijd, een weerregel en de duur, en geen knoppen. De filterkop blijft in een PinnedHeaderSliver staan. app_open draagt nu `window_class` (compact|medium|expanded|large), alleen met toestemming. Het privacybeleid zegt dat er in NL en EN bij.

## Commits

| Taak | Commit | Wat |
|------|--------|-----|
| 1 | 746a376 | FilledScoreBadge + onScoreFill, `_slotWeather`/`_weatherSummaryText`, `_buildCompactRow`, vastgezette filterkop, 10 nieuwe tests |
| 2 | 75788f6 | `kPropWindowClass` + `appOpenProps()`, `_recordAppOpen` leest de breedte uit View, 6 nieuwe tests, privacybeleid |
| 3 | 7edaa88 | Schets 017 gearchiveerd, MANIFEST-rij 017 |

## Verificatie

- `flutter test` (alles): **1150 geslaagd, 0 mislukt** (1134 + 10 in home_compact_rows_test + 6 in de groep 'breedteklasse op app_open').
- `flutter analyze`: **0 errors, 0 warnings, 214 infos**, gelijk aan de nulmeting.
- `git diff --stat lib/l10n` is leeg: geen nieuwe ARB-strings.
- `grep -rn '[=!]= WindowSizeClass.expanded' lib` is leeg.
- Niet gepusht, geen versiebump, geen build.

## Hoe het uitpakte

- **ensureVisible-variant:** de bestaande `Scrollable.ensureVisible(_firstCardKey…)` is gebleven. De test toont eerst alle 12 vensters, loopt met de pijl naar de laatste rij en scrolt de lijst omlaag. Daarna controleert hij dat de eerste rij echt uit beeld is. Na pijl omhoog tot de eerste rij ligt de bovenkant van die rij op of onder de onderkant van `home_pinned_filters`. De vervanging door `animateTo(0)` was dus niet nodig.
- **Blokweergave op expanded is bewust ongewijzigd.** `_buildBlocksSliver`/`_buildBlockCard` hebben al een eigen tik voor expanded. Compacte blokken vragen een eigen ontwerp (restpunt hieronder).
- **Beleidscorrectie voor signed_in:** `signed_in` ging al mee op app_open maar stond niet in het privacybeleid. De nieuwe zin noemt het nu, samen met de schermgrootteklasse, in NL en EN. De datum is bijgewerkt naar 11 oktober 2026. Het beleid gaat pas live op GitHub Pages na een push door Joost.
- **Geplande ritten op expanded** staan nu boven de vastgezette kop en scrollen weg, net als de banners. Op telefoon en medium is de volgorde van de slivers precies zoals hij was.

## Deviations from Plan

**1. [Rule 1 - Bestaande test pinde een aanname die nu bewust niet meer klopt] home_hover_test predicate versmald**
- **Gevonden tijdens:** Taak 1
- **Probleem:** home_hover_test.dart ging ervan uit dat de dagchips de *enige* InkWells met `hoverOverlay(cs)` zijn, en verwachtte er precies 7. Het plan schrijft `hoverColor: hoverOverlay(cs)` ook op de compacte rij voor, dus de test vond er 9 (7 chips + 2 rijen in beeld).
- **Fix:** de predicate sluit InkWells met een key `compact_row_*` uit. De test controleert verder ongewijzigd de cursor, de hover en de tik op een dagchip, in licht en in donker.
- **Bestanden:** test/features/home_hover_test.dart
- **Commit:** 746a376

Verder is het plan uitgevoerd zoals geschreven.

## Restpunten (deferred)

- **Compacte blokweergave op expanded:** Vensters/Blokken → Blokken toont op tablet nog de grote blokkaarten. Dat vraagt een eigen schets.
- **Geen visuele controle gedaan:** niet in Chrome (`flutter build web`) en niet op een echte tablet. De vorm, de vastgezette kop en het contrast zijn alleen in widgettests en met de contrastberekening bewezen. Een blik op 1280x800 in licht en donker is nog nodig. Bij een webbuild daarna ⌘⇧R.
- **Hover op de compacte rij** is niet apart getest. Hij gebruikt dezelfde `hoverOverlay` als de dagchips.
- **Canvas 017:** de README noemt alleen artboard A. Welke andere artboards er op het canvas stonden is niet vastgelegd, want de link is niet geopend.

## Threat Flags

Geen. `window_class` valt onder T-l5k-01/02/03 en is daar gemitigeerd. sanitizeProps blijft het laatste slot, en de tests dekken nee, wachtkamer en ja. Er zijn geen nieuwe endpoints of nieuwe gebeurtenissen; `kKnownAnalyticsEvents` is ongewijzigd.

## Self-Check: PASSED

- lib/features/home/filled_score_badge.dart: FOUND
- test/features/home_compact_rows_test.dart: FOUND
- .planning/sketches/017-tablet-compacte-lijst/README.md: FOUND
- Commits 746a376, 75788f6, 7edaa88: FOUND in git log
