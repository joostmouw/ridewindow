---
gsd_state_version: 1.0
milestone: v4.2
milestone_name: Clubs
current_plan: 34-07
status: executing
stopped_at: 34-06 klaar (groepslink en appbar-menu, 841 tests), volgende 34-07
last_updated: "2026-09-24T15:00:00.000Z"
last_activity: 2026-09-24 -- 34-06 groepslink, naam, verlaten, opheffen
progress:
  total_phases: 4
  completed_phases: 1
  total_plans: 11
  completed_plans: 9
  percent: 82
---

# Project State

## Current Position

Phase: 34
Plan: 7 of 8
Status: link en appbar-menu staan; volgende 34-07 landing
Last activity: 2026-09-24 -- 34-06 groepslink, naam, verlaten, opheffen

## Progress

**Phases Complete:** 1/4
**Current Plan:** 34-07

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

## Session Continuity

**Stopped At:** 34-06 klaar (groepslink en appbar-menu), volgende 34-07
**Resume File:** None
