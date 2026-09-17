---
phase: 26-console-op-orde
plan: 01
subsystem: docs
tags: [changelog, versie-consistentie, play-console]

requires: []
provides:
  - "docs/testers/changelog.md — per-build changelog vanaf build 41 (PROOF-01)"
  - "Geverifieerde CON-06-claim: PWA, privacybeleid en GitHub main staan alle drie op 1.0.31+42 / Ridewindow"
affects: []

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - docs/testers/changelog.md
  modified: []

key-decisions:
  - "De changelog verwijst naar de implementatiecommits (c3bd44f, 5aff9d7) in plaats van de release-notitiecommit 9414a9c die het plan noemde — 9414a9c is een docs-commit voor 1.0.29+30, niet de daglichtcode zelf"
  - "Build 42's track-status is ingevuld als 'actief op Closed testing Alpha sinds 2026-09-10 23:24' na directe verificatie in Play Console, niet als aanname"

requirements-completed: [CON-06, PROOF-01]

duration: "~15 min"
completed: 2026-09-17
---

# Phase 26 Plan 01: CON-06-verificatie en testerschangelog Summary

Bewees met vier read-only checks dat versie en naam overal gelijk zijn, en legde
`docs/testers/changelog.md` aan met build 41 en 42 op basis van de echte git-historie.

**Duur:** ~15 min · **Taken:** 2 · **Bestanden:** 1 aangemaakt

## Taak 1 — CON-06 geverifieerd (geen wijziging nodig)

Alle vier checks geslaagd, dus conform Pitfall 5 is er niets opnieuw gedeployed of gepusht:

| Check | Resultaat |
|---|---|
| `curl https://my-project-joost.web.app/version.json` | `"version":"1.0.31"`, `"build_number":"42"` ✓ |
| `diff` live GitHub Pages-privacybeleid vs. `docs/privacy-policy.html` | leeg — identiek; live pagina bevat "Ridewindow" (10×) ✓ |
| `git show origin/main:pubspec.yaml` | `version: 1.0.31+42` ✓ |
| `git show origin/main:lib/core/app_version.dart` | `kAppVersionName = '1.0.31'`, `kAppBuildNumber = '42'` ✓ |

STATE.md's claim klopte dus, maar is nu bewezen in plaats van aangenomen — inclusief
dat het op de **gepushte** origin/main staat, niet alleen lokaal.

## Taak 2 — docs/testers/changelog.md aangelegd (PROOF-01)

Twee blokken, elk met datum, track, inhoud en opgeloste feedback. Alle zes genoemde
commit-hashes zijn tegen `git show` gecontroleerd voordat ze zijn opgeschreven.

- **Build 42 (1.0.31+42)** — naam Ridewindow overal (`a28886f`), intro twee keer zo kort
  (`059e352`). Geen testerfeedback; eigen keuze.
- **Build 41 (1.0.30+41)** — daglicht telt mee in de score (`c3bd44f` zonstand,
  `5aff9d7` aftrek + balk + regel + schuif), de vier oordeelnamen, Peloton-introductie
  (`36b56f0`). **Feedback opgelost: Ingrid, 2026-09-09 → backlog #68** — de eerste
  testerfeedback die tot een uitgeleverde wijziging leidde.

## Deviations from Plan

**[Correctie — feitelijke onjuistheid in het plan] Verkeerde commit voor het daglicht**
Gevonden bij: Taak 2 | Het plan schreef `9414a9c` voor "daylight now counts in the score",
maar dat is `docs(release): notities voor 1.0.29+30` — een documentatiecommit, niet de
implementatie. | Opgelost door `git log --grep` op daglicht: de echte commits zijn
`c3bd44f` (zonstand, lokaal berekend en geijkt) en `5aff9d7` (de aftrek aangesloten, plus
balk, regel en schuif). Beide bevestigd als voorouder van build 41 via
`git merge-base --is-ancestor`. | Bestanden: docs/testers/changelog.md | Commit: bdc83d0

**[Volgorde] Track-status van build 42 ingevuld vanuit eigen Console-verificatie**
Het plan liet dit veld afhangen van Plan 26-02 Taak 3. Die status is tijdens deze sessie
rechtstreeks in Play Console vastgesteld (build 42 is **Active** op Closed testing — Alpha,
"Available to selected testers", uitgerold 2026-09-10 23:24), dus het veld is concreet
ingevuld in plaats van generiek gelaten.

**Totaal:** 2 afwijkingen, beide feitencorrecties die het plan nauwkeuriger maken.
**Impact:** de changelog verwijst naar commits die daadwerkelijk de beschreven wijziging
bevatten — precies wat PROOF-01 als bewijsmateriaal bruikbaar maakt.

## Issues Encountered

Geen.

## Next Phase Readiness

CON-06 en PROOF-01 zijn af. De changelog is bedoeld als levend document: elke volgende
build krijgt er een blok bij op het moment van bouwen, niet achteraf.

## Self-Check: PASSED

- `test -f docs/testers/changelog.md` ✓
- bevat "Build 41", "Build 42", "Ingrid", "#68" ✓
- alle zes hashes resolven via `git show -s` ✓
- commit bdc83d0 aanwezig ✓
