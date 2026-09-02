---
phase: 21-sync-migration
plan: 09
subsystem: verification
tags: [regression, cold-start, manual-verification, reg-03, adb]
status: incomplete

# Dependency graph
requires:
  - phase: 21-sync-migration
    provides: "21-08: de delete-account-flow, waarvan §6 hier de toestelverificatie is"
provides:
  - "REGRESSION-CHECKLIST-21.md — de handmatige verificatieroute voor de hele fase"
  - "MANUAL-VERIFICATION-21.md — negen device/web-sessies met de werkelijke waarnemingen"
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
duration: "verspreid over negen sessies, 2026-08-04 t/m 2026-09-01"
completed: null
---

# Phase 21 Plan 09: Regressie + handmatige verificatie Summary

**De verificatieroute van fase 21 is grotendeels afgelopen — §2 t/m §6 zijn afgetekend, de koude start is geautomatiseerd gemeten, en backlog #61 is op het toestel tegengeproefd. Eén ding staat nog open: de afsluitende Play-installatie.**

## Status: incomplete

Wat nog moet gebeuren voordat dit plan dicht kan — nog **één** ding:

> **De app één keer via Play installeren op het toestel**, zodat de fase eindigt op de
> distributieroute die gebruikers krijgen. Dat vereist eerst deïnstalleren van de sideload (andere
> handtekening), en dat wist de lokale data én de Calendar-OAuth-grant. Let na installatie specifiek
> op **inloggen** en **Google Calendar** — dat is wat een Play-gesigneerde build bewijst en een
> sideload niet kan (AUTH-10; Calendar is in dit project al eens precies zo stukgegaan).

Afgerond op 2026-09-02 08:00: de AAB **1.0.23 (24)** is geüpload en uitgerold naar de internal
testing track. Geverifieerd in de Console: `Latest release: 24 (1.0.23)`, "Available to internal
testers". Dat was handwerk — er is geen service account, geen fastlane en geen Play-workflow in dit
project.

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
