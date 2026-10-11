---
phase: 37-meten
plan: 06
subsystem: infra
tags: [meten, github-actions, usage-watch, seintje, dicht-huis]
requires:
  - "37-03: .github/workflows/usage-watch.yml en tool/usage/"
  - "37-04: rol usage_monitor live, secretwaarde klaargezet"
  - "37-05: gemeten vloeren in usage_floors.dart"
provides:
  - "usage-watch draait op main: dagelijks 05:00 UTC en op workflow_dispatch"
  - "Bewezen faalsignaal: een rode run komt als GitHub-mail bij Joost aan"
  - "Bewezen groene run als usage_monitor via de pooler, zonder telwaarden in de publieke log"
affects: [38, 39]
tech-stack:
  added: []
  patterns: ["Runs en stappen controleren via de openbare GitHub-API (publieke repo, geen token)"]
key-files:
  created: []
  modified: []
decisions:
  - "Joost zette het secret zelf (waarde uit zijn klembord); de orchestrator vulde alleen het naamveld en startte de runs in de GitHub-UI op Joosts verzoek"
  - "De Node 20-waarschuwing van actions/checkout@v4 en de Ubuntu 26-melding zijn vervolgpunten, geen blokkade"
metrics:
  duration: "~20 min (na de push)"
  completed: 2026-10-11
  tasks: 3
  files: 0
---

# Fase 37 Plan 06: Wacht live Samenvatting

De dagelijkse wacht `usage-watch` staat op main en is twee keer bewezen. Eén keer rood zonder secret, en die mail kwam bij Joost aan. Eén keer groen als `usage_monitor` via de Supavisor-pooler, met in de publieke log geen enkele telwaarde. Daarmee is succescriterium 3 van fase 37 waar: een uitschieter (of een kapotte wacht) komt bij Joost terecht zonder dat hij hoeft te zoeken.

## Taak 1: push en de rode run (geen repo-commit)

- Push: `1e0cbdf..4335302 main -> main`, gewone push. In de 31 commits zaten geen secrets.
- Run **38166434090** (workflow_dispatch, op 4335302, zonder secret): conclusie **failure**. Volgens de openbare `/jobs`-API faalde stap 2 "USAGE_MONITOR_DB_URL ingericht? (infra)". De stappen Checkout, Dart, "Telling ophalen (infra)" en "Gisteren toetsen" werden overgeslagen, en Opruimen slaagde. De stapnaam laat dus zien dat het een infrafout is en geen uitschieter.
- Mail: Joost kreeg om 21:04 "[joostmouw/ridewindow] Run failed: Usage watch (uitschieter-seintje) - main (4335302)".

## Taak 2: secret (Joost)

Joost zette het repository-secret `USAGE_MONITOR_DB_URL` zelf. De orchestrator vulde in de GitHub-UI alleen het naamveld in; Joost plakte de waarde vanuit zijn klembord, en daarna is het klembord leeggemaakt. De waarde is nergens getoond of gelogd. De service-role-sleutel is niet naar GitHub gegaan (D-12).

## Taak 3: de groene run (geen repo-commit)

- Run **38166644227** (workflow_dispatch, op 4335302, met secret): conclusie **success** in 19 s. Alle stappen slaagden: ingericht?, Checkout, Dart (3.13.5), "Telling ophalen (infra)", "Gisteren toetsen" en Opruimen. Opnieuw gecontroleerd via de openbare API.
- Publieke log, gelezen in de browser: "Telling ophalen" toont alleen de ingeklapte run-regel en "Gisteren toetsen" alleen "geen uitschieter". Er staan nergens telwaarden in (F-01, T-37-25).
- Cron: `0 5 * * *`, dus dagelijks om 05:00 UTC (07:00 CEST).
- `.github/workflows/supabase-keep-warm.yml` is in deze fase niet gewijzigd: de laatste commit erop is `eca2906` (fase 18).

## Vervolgpunten (geen blokkade)

1. **Node 20-waarschuwing:** `actions/checkout@v4` draait op Node 20 en GitHub zet hem geforceerd op Node 24. Bij gelegenheid overstappen naar een checkout-versie die Node 24 aanspreekt, in usage-watch en ook in de andere workflows.
2. **Ubuntu 26:** `ubuntu-latest` gaat vanaf 2026-10-19 naar Ubuntu 26. psql en setup-dart moeten daar ook werken. Na die datum de eerstvolgende run van usage-watch nakijken. Faalt hij, dan komt die mail vanzelf.
3. **PWA opnieuw gedeployd:** de push raakte `lib/`, dus "Deploy web to Firebase Hosting" draaide op 4335302 (success). De PWA zegt nog steeds versie 70, maar met andere bytes dan de gereleasete 70-bundel. Bij de volgende release bumpen.

## Afwijkingen van het plan

Geen inhoudelijke. Het plan ging ervan uit dat Joost de runs zelf start. De orchestrator klikte op Joosts verzoek in de GitHub-UI; de secretwaarde bleef bij Joost.

## Threat Flags

Geen. Er is geen nieuw oppervlak bij gekomen buiten het threat-register van het plan (T-37-24 t/m T-37-27).

## Self-Check: PASSED

- Run 38166434090: failure, guard-stap failure (openbare API, opnieuw opgevraagd)
- Run 38166644227: success, alle stappen success (openbare API, opnieuw opgevraagd)
- Keep-warm ongewijzigd (git log)
