---
phase: 26-console-op-orde
plan: 02
subsystem: infra
tags: [play-console, release-route, adb, con-01, oppo]

requires: []
provides:
  - "Geverifieerde toestelstaat van de Oppo: sideload 44, en het pakket zit opnieuw in user 0 én user 10"
  - "Console- en toestelstappen voor Joost, verbatim uit het plan, met de feiten die sinds het plan veranderden"
affects: [30-werving, 31-de-veertien-dagen]

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - .planning/phases/26-console-op-orde/26-02-SUMMARY.md
  modified: []

key-decisions:
  - "Taak 2 (de wipe) niet uitgevoerd: hij hangt aan de keuze in Taak 1, en dat is Joost's beslissing over zijn eigen toestel"
  - "De promotie-stap (Taak 3, stap 4) niet als open werk genoteerd maar als al-gebeurd: 26-01 constateerde op 2026-09-17 in de Console dat build 42 Active staat op de gesloten test sinds 2026-09-10 23:24"
  - "Build 45 erbij genoteerd als context: dezelfde CON-01-route geldt ongewijzigd voor hem zodra hij op internal staat"

requirements-completed: []

duration: "~15 min"
completed: 2026-09-20
---

# Fase 26 Plan 02: CON-01 Summary

**Uitgevoerd tot waar de hand van Joost begint: de Oppo draait een sideload van 44, het pakket zit opnieuw in het kloonprofiel, en de wipe wacht op zijn keuze.**

## Performance

- **Duration:** ~15 min
- **Tasks:** 3 (Taak 1 beslissing gelegd bij Joost, Taak 2 bewust niet uitgevoerd, Taak 3 stappen klaargezet)
- **Files modified:** 1 (deze SUMMARY)

## Wat er uitgevoerd is

**Taak 1 — beslissingspunt, gelegd bij Joost.** Wipen en uit Play herinstalleren
(option-a, aanbevolen: lage prijs, want profiel, week en ritten komen terug uit
Supabase, bewezen in MIG-02) of uitschuiven (option-b, maar CON-01 blijft dan
onbewezen en blokkeert de rest van de fase). Zonder zijn keuze gaat Taak 2 niet aan.

**Taak 2 — niet uitgevoerd, wél de toestelstaat vastgelegd** (alleen lezen, via adb):

| Vondst | Bewijs |
|---|---|
| Oppo aangesloten | `adb devices`: 3B15AD01LEN00000 |
| Huidige installatie is de sideload van 20 september | `versionCode=44`, `versionName=1.0.33`, `installerPackageName=null`, `firstInstallTime=2026-09-19 23:31:57` |
| **Het pakket zit in user 0 én user 10** | `pm list packages --user 10` en `--user 0` noemen het allebei |
| Kloonprofiel-gevaar is terug | De spookrecord-toestand van de 2026-08-incident-klasse: user 10 houdt de pakketnaam bezet. De uninstall-volgorde in Taak 2 dekt beide, en dat is nu geen theorie meer |

**Taak 3 — klaargezet, met twee feiten die sinds het plan veranderden:**

1. **De review-uitkomst en de promotie lijken al beantwoord.** 26-01 heeft op
   2026-09-17 rechtstreeks in de Console vastgesteld dat build 42 **Active**
   staat op Closed testing — Alpha sinds 2026-09-10 23:24, "Available to
   selected testers". Taak 3, stap 1 wordt dus bevestigen in plaats van
   ontdekken, en stap 4 (promoten) is vermoedelijk al gebeurd. Wat Joost
   wél rapporteert: of de gesloten release van die avond via **Add from
   library** ging (Pitfall 1: de exact geteste bundel hergebruiken) of via
   een verse upload. Dat laatste is niet meer terug te draaien, maar moet
   wel weten we voor de keer erop.
2. **Build 45 (1.0.34+45) is vandaag gebouwd** en wacht op de
   service-accountsleutel voor de internal-upload. Zodra hij op internal
   staat, geldt CON-01 ongewijzigd voor 45: eerst door Joost getest vanaf
   een Play-installatie, dán pas promoten naar de gesloten test.

## Wat Joost doet (resume-signals)

Naar het plan, in deze volgorde:

1. **Type option-a of option-b** voor de wipe. Kiest hij a, dan draait de
   volgende sessie (of hij zelf) de uninstall-volgorde:

   ```
   adb shell pm uninstall --user 0 ridewindow.joost.amsterdam
   adb shell pm list packages --user 10 | grep ridewindow
   adb shell pm uninstall --user 10 ridewindow.joost.amsterdam
   adb shell pm list packages | grep ridewindow      # moet leeg zijn
   ```

   (Gewone `adb uninstall` faalt op user 10 met `DELETE_FAILED_INTERNAL_ERROR`;
   `--user 10` is het commando dat in 2026-08 werkte. `adb` staat niet op
   PATH: `~/Library/Android/sdk/platform-tools/adb`.)

2. **Console:** Release → Testing → Closed testing → Alpha → Releases: de
   review-status van 42 bevestigen (verwacht: live/actief), en noteren hoe
   de release van 23:15-23:24 tot stand kwam (Add from library of verse upload).

3. **Oppo:** via de internal-opt-in-link installeren, dan verifiëren:

   ```
   adb shell dumpsys package ridewindow.joost.amsterdam | grep installerPackageName
   # verwacht: com.android.vending
   ```

4. **Koude start:** de korte intro (~2,47 s) zien opstartarten, en melden of
   profiel, week en ritten uit de cloud terugkomen.

## Wat nog open is (de CON-01-waarheden)

- De Oppo draait de rit nog vanuit een sideload: `installerPackageName=null`
  in plaats van `com.android.vending`
- De korte intro is nooit waargenomen op een Play-geïnstalleerde build
- Build 45 volgt dezelfde route zodra hij op internal staat

## Deviations from Plan

Geen taak overgeslagen of verzonnen; Taak 2 is expliciet uitgesteld omdat de
optie-gate van Taak 1 dat voorschrijft, en dat staat zo in het plan. De
45-context is toevoeging, geen vervanging van de planstappen.

## Self-Check: PASSED

- Toestelstaat vastgelegd vóór en niet ná een wijziging (er is geen wijziging gedaan)
- Alle adb-commando's in deze SUMMARY zijn dezelfde als die STATE.md voor het
  kloonprofiel-incident voorschrijft
- requirements-completed bewust leeg: geen van de vier waarheden uit het plan
  is zonder Joost's rapportage te bewijzen
