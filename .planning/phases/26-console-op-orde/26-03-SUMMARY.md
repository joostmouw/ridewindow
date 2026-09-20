---
phase: 26-console-op-orde
plan: 03
subsystem: infra
tags: [play-console, testers, google-groups, landen, con-02, con-03, con-04]

requires: []
provides:
  - "Geverifieerd: het feedback-adres joost@fanalists.com staat al in het gepubliceerde privacybeleid, in beide talen"
  - "Beide beslissingen (adres, groep) uitgewerkt met advies, en zes Console-stappen klaar voor Joost"
affects: [28-feedbackstroom, 30-werving, 32-aanvraag-en-productie]

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - .planning/phases/26-console-op-orde/26-03-SUMMARY.md
  modified: []

key-decisions:
  - "Geen van de Console-instellingen aangeraakt: Google Groups en Play Console zijn hier UI-only, en het onderzoek (A3) bevestigt dat er geen scriptpad bestaat"
  - "Als advies bij Taak 1 option-a (joost@fanalists.com hergebruiken) en bij Taak 2 option-a (de 9 adressen migreren), maar de keuze is expliciet aan Joost"
  - "De verificatie-deadline van 30 september is geen bijzaak meer maar prikt: hij valt binnen tien dagen"

requirements-completed: []

duration: "~15 min"
completed: 2026-09-20
---

# Fase 26 Plan 03: CON-02/03/04 Summary

**Landen, feedback-adres en Google Group klaargezet voor Joost; het adres blijkt al publiek in het privacybeleid, en de ontwikkelaarsverificatie van 30 september komt in zicht.**

## Performance

- **Duration:** ~15 min
- **Tasks:** 3 (twee beslissingspunten uitgewerkt, zes Console-stappen klaargezet)
- **Files modified:** 1 (deze SUMMARY)

## Wat er uitgevoerd is

**Taak 1 — feedback-adres (CON-03), beslissing bij Joost.** De grond is
geverifieerd: `docs/privacy-policy.html` publiceert `joost@fanalists.com`
al op vier plekken (account-verwijdering en Contact, in het Nederlands
én het Engels). Advies: option-a, hetzelfde adres hergebruiken — één
adres voor de hele app, en het staat al in het beleid dat Google ziet.
Wie een derde adres naast het beleid zet, fragmenteert net wat fase 28
juist gaat samenvoegen.

**Taak 2 — Google Group (CON-04), beslissing bij Joost.** Huidige stand
volgens HANDOFF.json: 9 handmatig ingevoerde adressen in de lijst "First
Testers RideWindow", geen group. Advies: option-a, de 9 adressen
migreren — niemand hoeft zich opnieuw aan te melden en de testers
dragen automatisch over. De prijs is dat Joost alle 9 met de hand aan
de nieuwe group toevoegt op groups.google.com.

**Taak 3 — zes Console-stappen klaar.** Zie hieronder. Tweedracht-punten
uit het onderzoek meegenomen:

- **Pitfall 3:** "Select all countries/regions" op de gesloten test wordt
  standaard de basislijn waar productie later mee sync't. Bewust meenemen
  in de planning van fase 32; hier is het geen actie maar een vlag.
- **Pitfall 4:** de **Android developer verification heeft als deadline
  30 september 2026** — dat is over tien dagen. Afdwinging begint in
  Brazilië, Indonesië, Singapore en Thailand (globaal pas in 2027). De
  meeste accounts zijn automatisch geregistreerd; de check is vijf
  minuten op Play Console Home, en zodra CON-02 alle landen opent, kan
  een gemiste verificatie precies de testers raken die de werving fase 30
  moet opleveren.

## Wat Joost doet (resume-signals)

1. **Beide beslissingen typen:** option-a of een ander adres (Taak 1), en
   option-a of option-b voor de group (Taak 2).
2. **groups.google.com:** de tester-group aanmaken (naar zijn keuze met de
   9 adressen als leden) en het group-e-mailadres noteren.
3. **Play Console, Closed testing → Alpha → Testers:** de group koppelen
   via "Choose testers" (naar keuze naast of in plaats van de handmatige
   lijst).
4. **Zelfde tab, Feedback channel:** het bevestigde adres plakken.
5. **Countries/regions tab:** "Select all countries/regions".
6. **Play Console Home:** checken of er een
   ontwikkelaarsverificatie-actiepunt staat (deadline 30 september).
7. **De opt-in-link die op het Testers-tabblad verschijnt** kopiëren en
   melden; hij moet uitkomen op een aanmeldpagina die Ridewindow noemt.

## Wat nog open is (de waarheden van dit plan)

- Countries/regions staat nog op BE/IT/NL/UK/US
- Feedback channel is nog leeg
- Er is nog geen Google Group gekoppeld en dus nog geen enkele stabiele link

## Deviations from Plan

Geen. De twee beslissingen zijn beslissingspunten gebleven en niet
stilzwijgens met de adviezen ingevuld; de Console-stappen zijn ongewijzigd
overgenomen met de twee vlaggen (productie-sync, verificatie-deadline) die
het onderzoek al voorschreef.

## Self-Check: PASSED

- Het adres staat letterlijk op vier plekken in `docs/privacy-policy.html`
  (regels 68, 97, 141, 169), geverifieerd met grep
- requirements-completed bewust leeg: geen van CON-02/03/04 is stelbaar
  zonder Console-toegang
