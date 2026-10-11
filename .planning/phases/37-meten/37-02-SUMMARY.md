---
phase: 37-meten
plan: 02
subsystem: tooling
tags: [dart, tool, meten, dicht-huis, uitschieterregel]
requires: []
provides:
  - "tool/src/service_role_key.dart: readServiceRoleKey, firstKey, serviceRoleKeyPattern, stringArg, intArg, printMissingKeyHelp"
  - "tool/usage/usage_rule.dart: DayCount (+fromJson), parseCountsCsv, median, OutlierRule, Outlier, UsageConfigError, findOutliers"
  - "tool/usage/usage_floors.dart: kUsageSources, kSenderlessSources, kFloorTotal, kFloorSender"
affects: [37-03, 37-04, 37-05]
tech-stack:
  added: []
  patterns: ["standalone Dart-bibliotheek zonder package:-imports voor een kale runner", "meldingen zonder getallen of invoerinhoud"]
key-files:
  created:
    - tool/src/service_role_key.dart
    - tool/usage/usage_rule.dart
    - tool/usage/usage_floors.dart
    - test/tool/service_role_key_test.dart
    - test/tool/usage_rule_test.dart
  modified:
    - tool/analytics_report.dart
decisions:
  - "Of een bron een afzendervloer nodig heeft, volgt uit de data (max_rows_one_sender niet null), niet uit een lijst"
  - "findOutliers controleert vloeren voor elke bron in de invoer, ook voor bronnen die op de toetsdag ontbreken"
  - "parseCountsCsv weigert bronnamen buiten [a-z_]+ en noemt in fouten alleen het regelnummer"
metrics:
  duration: "~8 min"
  completed: 2026-10-11
  tasks: 2
  files: 6
---

# Fase 37 Plan 02: Gedeelde sleutelmodule en uitschieterregel Samenvatting

De code die de service-role-sleutel leest, staat nu op één plek: `tool/src/service_role_key.dart`. `analytics_report.dart` gebruikt die module en gedraagt zich verder hetzelfde. De uitschieterregel uit D-15/D-16 is een losse Dart-bibliotheek in `tool/usage/`, zonder `package:`-imports, zodat zowel het lokale rapport (37-03) als de GitHub Action hem kunnen draaien.

## Wat er gebouwd is

- **Taak 1** (RED 44e5ab6, GREEN 53777bf): `service_role_key.dart`
  - De volgorde is ongewijzigd: eerst `--key`, dan `SUPABASE_SERVICE_ROLE_KEY`, dan `~/.config/ridewindow/supabase-service-role.key`.
  - De vormcontrole en de uitleg over het lek van 2026-09-19 zijn meeverhuisd.
  - Het hulptekstblok staat nu in `printMissingKeyHelp()`.
  - `analytics_report.dart` is 91 regels korter. Getest met een lege HOME: hij meldt "Geen bruikbare service-role sleutel gevonden." en stopt met exit 1.
- **Taak 2** (RED 7744a04, GREEN 7cd2679): `usage_rule.dart` en `usage_floors.dart`
  - `findOutliers` neemt de mediaan over de 28 kalenderdagen vóór de toetsdag; ontbrekende dagen tellen als 0. Per bron en per regel komt er hoogstens één `Outlier`.
  - `Outlier.message` noemt alleen bron en regel, zonder cijfers.
  - Een bron zonder vloer, of een ontbrekende toetsdag, geeft een `UsageConfigError`, ook zonder getallen. Zo is een configuratiefout in de log te onderscheiden van een uitschieter.
  - `parseCountsCsv` leest de psql-CSV. Bij een fout noemt hij alleen het regelnummer, nooit de inhoud; dat kan een psql-fout met een verbindingsstring zijn.
  - De vloeren zijn beginwaarden tot de nulmeting (37-05). De kop van het bestand legt uit waarom ze in de repo staan en dat ze openbaar zijn (T-37-10, geaccepteerd).

## Verificatie

- `flutter test test/tool/`: **36 tests geslaagd** (11 sleutel + 25 regel), 0 overgeslagen. De consistentietest tegen migratie 0014 draait echt, want 0014 bestaat al.
- `dart analyze tool`: geen issues.
- Geen `package:`-import in `tool/usage/`.

## Afwijkingen van het plan

Geen inhoudelijke afwijkingen. Een paar kleine aanvullingen bovenop `<behavior>`, allemaal in de geest van T-37-07/T-37-08:
- `parseCountsCsv` weigert bronnamen buiten `[a-z_]+`. Een verdwaalde psql-regel kan zo nooit als bron in een melding terechtkomen.
- Extra tests:
  - een bestand zonder sleutelvormige regel geeft null;
  - een bron met afzender maar zonder afzendervloer geeft `UsageConfigError`;
  - de standaardvloeren dekken alle tien de bronnen;
  - in `UsageConfigError` staat geen cijfer.

## TDD Gate Compliance

Beide taken hebben een `test(...)`-commit gevolgd door een `feat(...)`-commit. De RED-runs faalden zoals verwacht, omdat de bibliotheek nog ontbrak.

## Bekende stubs

Geen. De vloeren zijn bewust beginwaarden; 37-05 vervangt ze.

## Self-Check: PASSED

- FOUND: tool/src/service_role_key.dart, tool/usage/usage_rule.dart, tool/usage/usage_floors.dart, test/tool/service_role_key_test.dart, test/tool/usage_rule_test.dart
- FOUND: 44e5ab6, 53777bf, 7744a04, 7cd2679
