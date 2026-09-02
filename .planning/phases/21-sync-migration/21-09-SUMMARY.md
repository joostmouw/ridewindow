---
phase: 21-sync-migration
plan: 09
subsystem: verification
tags: [regression, cold-start, manual-verification, reg-03, adb]
status: complete

# Dependency graph
requires:
  - phase: 21-sync-migration
    provides: "21-08: de delete-account-flow, waarvan §6 hier de toestelverificatie is"
provides:
  - "REGRESSION-CHECKLIST-21.md — de handmatige verificatieroute voor de hele fase"
  - "MANUAL-VERIFICATION-21.md — tien device/web-sessies met de werkelijke waarnemingen"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Koude start gemeten met een sample-op-vast-tijdstip in de device-klok (`date +%s.%N` op het toestel, direct vóór `input tap` en direct vóór `screencap`), niet in de hostklok — anders zit adb's USB-latency in het getal en meet je ~0,5s te pessimistisch."
    - "Detectie van 'eerste ride slot zichtbaar' als pixelmeting (aandeel lichte pixels in de middenzone springt van 0% naar 84%), niet als oordeel over een screenshot."

key-files:
  created:
    - tools/measure_cold_start.py
  modified:
    - .planning/phases/21-sync-migration/REGRESSION-CHECKLIST-21.md
    - .planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md

key-decisions:
  - "§3 herschreven van iOS-PWA naar Android-WebAPK. De iOS-scope hoort bij v2 en CLAUDE.md legt Android-only vast voor v1/v3; een iPhone-proef eisen zou de fase blokkeren op iets dat buiten scope valt."
  - "§4 afgetekend als PASS mét genoteerde staart in plaats van als kaal vinkje. Mediaan ≈1,75–1,8s, maar in ~1 op de 4 starts is het eerste ride slot op 2,0s nog niet zichtbaar. De spreiding is de bevinding; één getal had hier alles kunnen zeggen wat je wilde horen."
  - "De `feedback`-controle uit §6 als **vervallen** genoteerd, niet als gehaald: de tabel is leeg, dus `on delete set null` viel niet te observeren."

requirements-completed: [REG-03]

# Metrics
duration: "verspreid over tien sessies, 2026-08-04 t/m 2026-09-02"
completed: 2026-09-02
---

# Phase 21 Plan 09: Regressie + handmatige verificatie Summary

**De verificatieroute van fase 21 is afgelopen — §2 t/m §6 afgetekend, de koude start geautomatiseerd gemeten, backlog #61 tegengeproefd, en de fase eindigt waar hij moest eindigen: op een echte Play-installatie.**

## Status: complete

De AAB **1.0.23 (24)** is op 2026-09-02 08:00 uitgerold naar de internal testing track
(`Latest release: 24 (1.0.23)`, "Available to internal testers") en om 08:06 vanaf Play op het
toestel geïnstalleerd. Handwerk aan beide kanten — er is geen service account, geen fastlane en geen
Play-workflow in dit project.

### AUTH-10 / D-16 — waarom die laatste installatie er werkelijk toe deed

Sinds 5 augustus draaide alles op een sideload met de upload-sleutel. Play hertekent de bundel met
zijn eigen sleutel, dus testers draaien een ánders gesigneerde app — en in dit project is precies
dát al een keer misgegaan: Calendar werkte in een sideload en was stuk vanuit Play, door een
SHA-1 die niet bij de OAuth-client stond. Vandaar dat deze twee dingen alleen vanaf een
Play-installatie tellen:

| Wat | Bewijs, 2026-09-02 |
|---|---|
| Play-gesigneerd | `installerPackageName=com.android.vending`, `versionCode=24`, in-app "Version 1.0.23 (24)" |
| Inloggen | accountkiezer → joostmouw@gmail.com, **geen `ApiException: 10`**, status naar "Synced", overleeft een koude start |
| Calendar lezen | import levert blauwe Calendar-blokken; profiel toont "Connected" |
| Calendar schrijven | `title=Fietsrit 20:00–22:00, dtstart=1788372000000` — wo 2 sep 20:00 CEST, exact het geplande venster |

De de-installatie die hieraan voorafging wiste de lokale Drift-database en de Calendar-OAuth-grant.
Die prijs was vooraf benoemd en bewust betaald: het D-03-bewijs stond al vast en de lokale data was
nog slechts testdata.

Twee dingen die deze sessie bevestigde en géén PASS zijn: backlog **#58** reproduceert vanaf een
Play-build (het event heet "Fietsrit" terwijl de app op Engels staat), en de Calendar-rij in Profiel
ververst zijn status pas na een koude start, omdat `_checkCalendarConnection()` alleen in
`initState()` draait — dezelfde keten als backlog #56.

Volledig uitgeschreven in `MANUAL-VERIFICATION-21.md`, device session 10.

## Wat er wél is afgetekend

| Sectie | Uitkomst |
|---|---|
| §2 — auth-rondgang inclusief uitlog (D-12) | PASS, 2026-08-07 |
| §3 — PWA-installatie als echte WebAPK, standalone, agenda-event | PASS, 2026-08-07 |
| §4 — koude start (REG-03) | PASS met genoteerde staart, 2026-09-01 |
| §5 — SYNC-11 multi-tab | PASS, 2026-08-07 |
| §5a — outbox drain (SYNC-05) | PASS |
| §5b/§5c — één rit blijft één rit, verwijderd blijft verwijderd | PASS, 2026-08-05 |
| §6 — account verwijderen (AUTH-09) | PASS app-kant én Supabase-kant, 2026-09-01 |
| Backlog #61 — tegenproef | PASS aan beide kanten, 2026-09-01 |
| §0/§2 — Play-upload, Play-installatie, AUTH-10 | PASS, 2026-09-02 |

Drie vinkjes in de checklist staan bewust nog open, elk met de reden erbij in plaats van
weggewerkt: het reparatiepad van 21-13 is niet meer uit te lokken (de niet-canonieke rijen bestaan
niet meer — alleen unit-tests dekken het), de dashboardcontrole op de verwijderde rij van §5c is
alleen indirect gedekt, en `feedback`'s `on delete set null` verviel bij gebrek aan rijen. Dat zijn
grenzen aan wat er te observeren viel, geen uitvoeringsgaten.

## §4 — het getal, en waarom het geen enkel getal is

| Meetmoment na de tik | Ride slot zichtbaar |
|---|---|
| 1,52s | 0 / 6 |
| 1,77s | 3 / 6 |
| 1,93s | 5 / 6 |
| 2,03s | 9 / 12 |
| 2,28s | 6 / 6 |

Mediaan ≈ 1,75–1,8s, nooit vóór 1,55s, altijd binnen 2,3s. De typische koude start haalt de grens van 2 seconden ruim, maar in ongeveer één op de vier starts niet.

## BLOCKER die blijft staan

**Fase 19 heeft zijn eigen basislijn nooit gemeten** — plan 19-07 is niet afgerond. REG-03 vraagt om een vóór/ná-vergelijking, en die bestaat dus niet. Wat hier gemeten is bewijst de grens in absolute zin, meer niet. Dit hoort bij het afsluiten van de milestone opnieuw op tafel, niet stilletjes te verdwijnen.

## Vier keer bijna een bevinding uit de meetopstelling

Deze fase heeft meer tijd verloren aan meetfouten dan aan echte bugs. Vastgelegd zodat de volgende keer sneller gaat:

1. **Flutter-web publiceert zijn semantics-boom pas** nadat je Flutters "Enable accessibility"-knop hebt aangetikt. Daarvóór ziet `uiautomator` één node en lijkt élk scherm leeg. Gebruik op een koude start een screenshot; die is passief.
2. **Android's task snapshot** toont tijdens de launch-animatie hoe de app er bij het afsluiten uitzag. Dat gaf vier metingen van 0,06s — fysiek onmogelijk, en volstrekt geloofwaardig ogend.
3. **`screenrecord` is op dit toestel geblokkeerd door policy**, niet door een padprobleem. `screencap` mag wél naar dezelfde map schrijven.
4. **"1 test gefaald" is geen diagnose.** De suite stond maandenlang genoteerd als "441/1, die ene is de bekende notificatietest". Op 2026-09-01 bleek die ene een heel andere te zijn: `app_version_test.dart`, die een echte versie-mismatch aanwees. Zie quick 260901-r92.
