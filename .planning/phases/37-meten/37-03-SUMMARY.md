---
phase: 37-meten
plan: 03
subsystem: tooling
tags: [dart, tool, github-actions, meten, dicht-huis]
requires:
  - "37-01: public.usage_daily_counts(p_days) + rol usage_monitor"
  - "37-02: tool/src/service_role_key.dart, tool/usage/usage_rule.dart, tool/usage/usage_floors.dart"
provides:
  - "tool/usage_report.dart: lokaal rapport per bron per dag (terminal + --html), markeert uitschieters"
  - "tool/usage/usage_check.dart: toets voor de Action, exit 0 rustig / 2 uitschieter / 1 infrafout"
  - ".github/workflows/usage-watch.yml: dagelijkse wacht als usage_monitor via de pooler"
affects: [37-04, 37-05, 37-06]
tech-stack:
  added: ["dart-lang/setup-dart@6afc89df (v1.8.1) in CI"]
  patterns: ["exitcode onderscheidt uitschieter (2) van infrafout (1)", "publieke log: alleen bron en regel, nooit getallen"]
key-files:
  created:
    - tool/usage_report.dart
    - tool/usage/usage_check.dart
    - test/tool/usage_check_test.dart
    - .github/workflows/usage-watch.yml
  modified: []
decisions:
  - "Het rapport neemt de laatste dag in de telling als 'vandaag' (de functie levert een dicht rooster t/m vandaag Amsterdam); geen eigen tijdzonerekening"
  - "usage_check noemt bij een ontbrekende vloer alleen 'bron zonder vloer', niet de bronnaam"
  - "psql haalt de dag op als to_char(day, 'YYYY-MM-DD'), zodat de uitvoer niet van DateStyle afhangt"
metrics:
  duration: "~12 min"
  completed: 2026-10-11
  tasks: 2
  files: 4
---

# Fase 37 Plan 03: Lokaal rapport en dagelijkse wacht Samenvatting

De telling heeft nu twee gezichten. `dart run tool/usage_report.dart` laat Joost lokaal per bron en per dag de rijen, het aantal afzenders en de drukste afzender zien (MEET-01). `.github/workflows/usage-watch.yml` toetst elke ochtend de dag ervoor en faalt bij een uitschieter, met alleen bron en regel in de publieke log (MEET-02).

## Wat er gebouwd is

- **Taak 1** (20fe5e3): `tool/usage_report.dart`
  - Leest de sleutel via `readServiceRoleKey`. Zonder sleutel toont hij `printMissingKeyHelp()` en stopt met exit 1 (gecontroleerd met een lege HOME).
  - Roept POST `rpc/usage_daily_counts` aan met `p_days = days + 28`, begrensd op 3660. Zo heeft de regel ook voor de oudste getoonde dag een volledige basislijn.
  - Een fout van Supabase geeft alleen de status plus `message`/`hint` van PostgREST, met uitleg bij 401 en bij 404 (dan is 0014 nog niet gedraaid).
  - Per bron een blok in de volgorde van `kUsageSources`, nieuwste dag bovenaan, met `-` voor null. Vandaag krijgt het label "(vandaag, loopt nog)" en wordt niet getoetst. Een uitschieterdag krijgt `<- uitschieter (totaal)` of `<- uitschieter (één afzender)`.
  - Een vaste voetnoot noemt de ondergrens-bronnen (D-06) en zegt dat `feedback_anoniem` geen afzender heeft (F-02).
  - `--html pad` geeft dezelfde inhoud als HTML. Uitschieterdagen krijgen daar een rode achtergrond.
  - Offline gecontroleerd met een kopie in de scratchpad tegen een nep-rpc-server op localhost: een piekdag werd op beide regels gemarkeerd, en de HTML had één `class="uit"`-rij.
- **Taak 2** (RED 6bab6ba, GREEN b3bdca9): `tool/usage/usage_check.dart`, de tests en de workflow
  - `usage_check.dart` gebruikt alleen `dart:io` en relatieve imports, met een eigen mini-parser voor `--csv` en `--day`. Een ongeldige datum zoals 2026-02-31 wordt geweigerd.
  - Exitcodes: 0 geeft `geen uitschieter`. 2 geeft één `::error::uitschieter: ...`-regel per uitschieter. 1 geeft `::error::infrafout: <reden>`.
  - Een onverwachte uitzondering noemt alleen het type.
  - Buiten de repo gedraaid (kopie van `tool/usage/` in een tempmap) werkt het zonder pub get.
  - De workflow draait om 05:00 UTC en is ook met de hand te starten (`workflow_dispatch`).
    - Rechten: `permissions: contents: read`, `timeout-minutes: 10`.
    - Een guard-stap meldt een infrafout als het secret ontbreekt. Het secret gaat via `env:` mee, niet inline.
    - setup-dart is vastgepind op `6afc89df92d6eb3834022f73cd65adc8cdfcb92d` (v1 = v1.8.1).
    - Stap "Telling ophalen (infra)": psql haalt `usage_daily_counts(30)` op naar `$RUNNER_TEMP/counts.csv`. Bij een fout meldt hij een infrafout en toont hij psql.err.
    - De toetsstap draait vanuit `$RUNNER_TEMP` met `DAY` = gisteren in Amsterdam.
    - Een `always()`-stap wist het CSV- en het foutbestand.
    - Er is geen artifact, geen job summary, geen issue en geen `set -x`. `supabase-keep-warm.yml` is ongewijzigd.

## Verificatie

- `flutter test test/tool/`: **45 tests geslaagd** (36 uit 37-02 + 9 nieuw), 0 overgeslagen.
- `dart analyze tool`: geen issues.
- De workflow is geldige YAML (Ruby YAML). Buiten commentaar komen `service_role`, `upload-artifact`, `GITHUB_STEP_SUMMARY`, `issues:` en `set -x` niet voor.
- De tests controleren dat de fixture-getallen (777, 913, 98765, 4321) nooit in de uitvoer staan. Bij een rustige dag staat er helemaal geen getal van drie of meer cijfers in.
- Niet live gedraaid: 0014 staat nog niet in productie (37-04 wacht op Joost). De live run volgt in 37-05/37-06.

## Afwijkingen van het plan

Geen inhoudelijke afwijkingen. Kleine aanvullingen:
- Het rapport stopt met exit 1 en een uitleg als de telling leeg is. Dat hoort niet te kunnen, omdat de functie een dicht rooster levert.
- Kan de regel niet draaien (een bron zonder vloer), dan meldt het rapport dat bovenaan en toont het de tabel toch.
- Extra tests: een ontbrekend CSV-bestand en een ongeldige `--day` geven allebei een infrafout.
- De psql-select zet de dag om met `to_char(day, 'YYYY-MM-DD')`, zodat het formaat niet van de DateStyle van de server afhangt.

## Hoe goedlopende apps het doen

Gevolgd zoals in het plan beschreven (Stripe Radar / budget alerts, Sentry spike protection, Dependabot): het signaal is de faalmail van GitHub, de details staan alleen lokaal.

## TDD Gate Compliance

Taak 2: `test(37-03)` 6bab6ba (9 tests faalden, want het script bestond nog niet), daarna `feat(37-03)` b3bdca9 (alles groen).

## Bekende stubs

Geen.

## Threat Flags

Geen nieuwe oppervlakte buiten het threat model. Het nieuwe workflowbestand en de rpc-aanroep vallen onder T-37-11 t/m T-37-16.

## Self-Check: PASSED

- FOUND: tool/usage_report.dart, tool/usage/usage_check.dart, test/tool/usage_check_test.dart, .github/workflows/usage-watch.yml
- FOUND: 20fe5e3, 6bab6ba, b3bdca9
