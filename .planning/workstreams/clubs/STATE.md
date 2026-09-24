---
gsd_state_version: 1.0
milestone: v4.2
milestone_name: Clubs
current_plan: 6
status: executing
stopped_at: 35-06 wacht op groepsrit-test Joost+Jacco (build 57 live)
last_updated: "2026-09-24T14:00:00.000Z"
last_activity: 2026-09-24 -- 35-05 teller en groepschips klaar
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 17
  completed_plans: 16
  percent: 50
---

# Project State

## Current Position

Phase: 35
Plan: 6 of 6
Status: 35-06 checkpoint: wacht op groepsrit-test met Jacco
Last activity: 2026-09-24 -- 35-05 teller en groepschips klaar

## Progress

**Phases Complete:** 1/4
**Current Plan:** 35-06

## Decisions

- 33-01: groepen aanmaken via rpc create_group, niet via trigger (insert...returning-valkuil uit 0003)
- 33-01: enige beheerder die zichzelf degradeert wordt geweigerd (last_admin); opvolging alleen bij vertrek, verwijdering en account-cascade
- 33-01: participant-rij geeft op een groepsrit geen toegang; na opheffen wel weer
- 33-01: functietelling na 0012 is elf, niet acht (CLUB-20): twee triggerfuncties + create_group erbij
- 33-02: deny-test als SQL-Editor-script met pg_temp-helpers; eindcontrole telt ook het aantal checks (81)
- 34-01: aanvragen alleen via definer-rpc's; client heeft op group_join_requests alleen select/delete
- 34-01: functietelling na 0013 is dertien, niet twaalf (voordragen vraagt definer voor de namen)
- 34-01: lockvolgorde overal groep -> aanvraag -> persoon; accept op verdwenen aanvraag = not_allowed
- 34-03: groupInitials op runes, geen package:characters (alleen transitief)
- 34-03: groepslink hergebruiken als hij nog 7 dagen geldig is, anders nieuw voor 30 dagen
- 34-03: onbekende databasefout gaat door (_guard rethrow); UI toont groupErrorGeneric
- 34-04: 10-groepengrens al in de UI vóór de sheet; database toetst daarna nog
- 34-04: GroupAdminChip gedeeld in group_crest.dart; scherm sorteert leden niet opnieuw
- 34-05: lid eruit halen pas na sluiten snackbar; ongedaan maken verstuurt niets
- 34-05: aanvraagknoppen onder de naam (Wrap), past op 360 dp
- 34-05: na geslaagd accepteren/afwijzen blijft het aanvraag-id bezet
- 34-06: verlaten = bevestiging zonder ongedaan maken; terugkomen is een nieuwe aanvraag
- 34-06: dezelfde naam opslaan verstuurt niets; aanvrager krijgt geen appbar-menu
- 34-07: groepscode eigen sleutel naast maatjescode; redirect bewaart beide
- 34-07: codeveld verklapt soort code niet; alleen vol/10 groepen eigen zin
- 35-01: gedeelde ritten ontdubbelen per rit-id; RideEntry.key = ride_<id>
- 35-01: groepsrit telt over huidige leden; organisator telt als 'gaat mee'
- 35-01: respondToGroupRide = upsert zonder select; respondToSharedRide kiest
- 35-02: dubbelcheck groepsrit vóór het vensterscherm, niet erna
- 35-02: maatjespad hergebruikt alleen eigen rit zonder group_id
- 35-02: groepenfout bij openen = oud scherm, geen melding
- 35-03: groepsnaam hooguit 45% van de rolregel, zonder Flexible
- 35-03: antwoordknoppen op de ritkaart in een Wrap, rechts
- 35-04: detail zoekt eerst op rit-id, anders op tijdvak
- 35-04: ledenlijst uit de groep, ex-leden niet getoond
- 35-04: naam en status in een Wrap, knoppen in een Wrap
- 35-05: bolletje en tab delen provider en label (9+)
- 35-05: groepschips in scrollende Row, geen ListView
- 35-05: lang indrukken zonder Tooltip; hint via Semantics

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| 33-01 | 20min | 2 | 1 |
| 33-02 | 25min | 2 | 1 |
| 34-01 | 15min | 2 | 4 |
| 34-03 | 25min | 3 | 15 |
| 34-04 | 35min | 3 | 17 |
| 34-05 | 30min | 2 | 10 |
| 34-06 | 25min | 2 | 10 |
| 34-07 | 30min | 2 | 15 |
| 35-01 | 25min | 2 | 11 |
| 35-02 | 15min | 2 | 9 |
| 35-03 | 35min | 2 | 4 |
| 35-04 | 30min | 2 | 11 |
| 35-05 | 35min | 2 | 10 |

## Session Continuity

**Stopped At:** 35-05 klaar (teller en groepschips), volgende 35-06
**Resume File:** None

## Hervatten (2026-09-24 avond)

- Build **1.0.46 (57)** staat op internal en de live webapp (alpha nog 55); bevat de testerfixes #80/#81/#83.
- Build 1.0.44 (55) stond eerder op internal, alpha én de webapp. adb-check op de Oppo in
  licht/donker gedaan (`phases/35-groepsritten/screens/`), niets blokkerends.
- **Open:** Joost + Jacco (iPhone-webapp) testen een echte groepsrit op "On the Roll": uitnodigen
  met 2 vensters → rood bolletje bij Jacco → "Ik ga mee" → Joost ziet Jacco als "gaat mee".
  Bij "approved": 35-06-SUMMARY schrijven, CLUB-12..16, 25, 26 aanvinken, fase 35 afsluiten
  (`GSD_WORKSTREAM=clubs gsd-sdk query phase.complete 35`, daarna frontmatter-tellers met de hand).
- Daarna fase 36 (afronden + CLUB-29 namen bijwerken, CLUB-30 naam vragen; 0014 + checkpoint).
- Parallel: worktree `~/ridewindow-meldingen` (branch `meldingen`) werkt aan #77B/#74; mergen ná 35.
