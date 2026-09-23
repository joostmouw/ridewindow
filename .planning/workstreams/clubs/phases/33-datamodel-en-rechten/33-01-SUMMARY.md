---
phase: 33-datamodel-en-rechten
plan: 01
subsystem: database
tags: [supabase, postgres, rls, plpgsql, clubs]

requires:
  - phase: v3.0 Peloton (0002, 0003, 0010)
    provides: group_rides, group_ride_participants, friendships, is_ride_member, set_updated_at
provides:
  - "supabase/migrations/0012_groups.sql: groups, group_members, group_invites, group_rides.group_id"
  - "is_group_member(uuid, boolean) helper; is_ride_member vervangen (groepsrit volgt huidig lidmaatschap)"
  - "rpc create_group(p_name) returns uuid; rpc redeem_group_invite(p_code) returns table(group_id, group_name)"
  - "triggers group_members_guard_insert (30/10-grens, naam, joined_at) en group_members_ensure_admin (opvolging, lege groep weg, last_admin)"
  - "foutsleutels P0001: not_authenticated, group_name_invalid, invite_invalid, group_full, too_many_groups, last_admin"
affects: [33-02 deny-test, 33-03 toepassen, 34, 35]

tech-stack:
  added: []
  patterns:
    - "Kolomgrants als tweede slot naast RLS: insert (group_id, user_id), update (role), update (name)"
    - "Rijlock op de ouderrij + advisory lock per user in een before-insert-trigger voor race-vrije tellingen"
    - "Atomisch aanmaken via rpc in plaats van after-insert-trigger, om de insert-returning-valkuil (0003) te ontlopen"

key-files:
  created:
    - supabase/migrations/0012_groups.sql
  modified: []

key-decisions:
  - "Aanmaken via rpc create_group, niet via trigger op groups (insert...returning-valkuil uit 0003; een created_by-tak liet een vertrokken maker de groep zien)"
  - "Enige beheerder die zichzelf degradeert wordt geweigerd (last_admin); opvolging alleen bij vertrek, verwijdering en account-cascade"
  - "Participant-rij geeft op een groepsrit geen toegang; na opheffen (group_id null) wel weer"
  - "Functietelling na 0012 is elf, niet acht: grenzen/opvolging vragen twee triggerfuncties en atomisch aanmaken create_group"
  - "Triggerfuncties revoken ook authenticated (Supabase default grant); service_role krijgt select op groups/group_members, niet op group_invites"

requirements-completed: [CLUB-10, CLUB-17, CLUB-18, CLUB-19, CLUB-20]

duration: 20min
completed: 2026-09-23
---

# Phase 33 Plan 01: Datamodel en rechten (0012_groups.sql) Summary

**Eén transactionele, herdraaibare migratie met groepen, lidmaatschap en groepslinks, met RLS, kolomgrants, race-vrije 30/10-grenzen, automatische beheerder-opvolging en de rpc's create_group en redeem_group_invite. De migratie is nog niet uitgevoerd.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-09-23
- **Tasks:** 2/2
- **Files modified:** 1 (787 regels)

## Accomplishments
- Kop verantwoordt keuzes a-g, inclusief de telling van elf server-functies en waarom dat meer is dan de "acht" uit CLUB-20.
- Drie nieuwe tabellen plus `group_rides.group_id`, 13 policies, kolomgrants, `anon` krijgt niets.
- `is_ride_member` herschreven: eigenaar, participant (alleen als group_id null is), of huidig groepslid. Opties en stemmen uit 0010 erven dit vanzelf.
- Trigger voor de grenzen (`for update` op de groep + `pg_advisory_xact_lock` per user) en een trigger voor opvolging die ook bij een account-cascade afgaat, dus `delete_own_account` hoeft niet te veranderen.
- Controle-footer met verwachte policies (3/4/3/4/5), grants en een pg_proc-query die 11 rijen verwacht; verwijst naar `supabase/tests/clubs_deny_test.sql`.

## Task Commits

1. **Task 1: Kop, tabellen, helpers, RLS en grants** - `5ca21fa` (feat)
2. **Task 2: Triggerfuncties en rpc's** - `c30d2f1` (feat)

## Files Created/Modified
- `supabase/migrations/0012_groups.sql` - volledig Clubs-datamodel en rechtenlaag

## Decisions Made
Zie key-decisions hierboven. Verder:
- `redeem_group_invite` vangt `unique_violation` af in een exception-blok, voor het geval dat hetzelfde account de link twee keer tegelijk inwisselt. De lidcheck vooraf staat buiten de advisory lock, dus die race bestaat echt. Er wordt geen `on conflict` gebruikt.
- `display_name` wordt gezet met `new.display_name := (select ...)` in plaats van `select ... into new.x`. Dat geeft netjes null als er geen profiel is.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical] Race bij dubbel inwisselen in redeem_group_invite**
- **Found during:** Task 2
- **Issue:** De expliciete lidcheck en de insert zijn niet atomisch. Twee gelijktijdige aanroepen van hetzelfde account zouden elk de check halen, en de tweede zou dan een ruwe 23505 geven.
- **Fix:** De insert staat in een `begin ... exception when unique_violation then null; end;`-blok. Het resultaat is gewoon "je bent lid".
- **Commit:** c30d2f1

**2. [Rule 2 - Missing critical] Triggerfuncties ook bij authenticated ingetrokken**
- **Found during:** Task 2
- **Issue:** Supabase geeft nieuwe functies standaard execute aan authenticated. Het plan noemde alleen `public, anon`.
- **Fix:** `revoke all ... from public, anon, authenticated` op guard_group_member_insert en ensure_group_admin. Er komen geen extra grants bij, dus de acceptatietelling van 4 blijft kloppen.
- **Commit:** c30d2f1

## Issues Encountered
- Er zijn hier geen Postgres, psql, Supabase CLI of SQL-parser. De SQL is alleen door lezen gecontroleerd en niet uitgevoerd. Bewezen wordt hij in 33-02 (deny-test) en 33-03, waar Joost 0012 in de SQL Editor draait.

## Known Stubs
Geen.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: info-disclosure (laag) | supabase/migrations/0012_groups.sql | De guard-trigger draait vóór de RLS with check. Een niet-beheerder die een group_id kent (een uuid, niet te raden) en een insert probeert, kan `group_full` terugkrijgen in plaats van een RLS-fout, en houdt heel even een rijlock op de groep vast. Geaccepteerd. |
| threat_flag: spoofing (laag, bestaand patroon) | supabase/migrations/0012_groups.sql | `group_ride_participants_insert_self_group` laat de client `display_name` op zijn eigen participant-rij zetten, net als het bestaande `_insert_owner`-pad. Alleen de naam op group_members komt uit de database. |

## Next Phase Readiness
- 33-02 kan de deny-test schrijven tegen de exacte namen en foutsleutels uit dit contract.
- 33-03: Joost past 0012 toe in de SQL Editor en draait daarna de footer-queries.

## Self-Check: PASSED
- FOUND: supabase/migrations/0012_groups.sql
- FOUND: 5ca21fa
- FOUND: c30d2f1
