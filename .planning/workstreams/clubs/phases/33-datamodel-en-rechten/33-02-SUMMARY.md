---
phase: 33-datamodel-en-rechten
plan: 02
subsystem: database
tags: [supabase, postgres, rls, deny-test, clubs]

requires:
  - phase: 33-01
    provides: 0012_groups.sql (groups, group_members, group_invites, create_group, redeem_group_invite, triggers)
provides:
  - "supabase/tests/clubs_deny_test.sql: 81 checks als SQL-Editor-script, één transactie, eindigt met rollback"
affects: [33-03 toepassen en draaien]

tech-stack:
  added: []
  patterns:
    - "pg_temp.try_value/try_exec/try_rows: dynamische SQL in een eigen subtransactie, geeft 'ok', telling, P0001-sleutel of SQLSTATE terug"
    - "Echte auth.users-rijen voor wie triggers/FK/delete_own_account nodig heeft; replica alleen voor bulk-seed"
    - "Eindcontrole met twee sloten: mislukte checks bij naam, en het totaal (81) moet kloppen"

key-files:
  created:
    - supabase/tests/clubs_deny_test.sql
  modified: []

key-decisions:
  - "Verwachte fouten lopen via drie pg_temp-helpers in plaats van losse begin/exception-blokken per check; alleen 2.14 staat inline om het returning-into-patroon letterlijk te tonen"
  - "Eindcontrole telt ook het aantal checks (81), zodat een check die stil wegvalt niet als geslaagd telt"
  - "5.6 draait als C zelf (via de select-policy) in plaats van als postgres: dat is precies wat de app na create_group doet"

requirements-completed: [CLUB-17, CLUB-18, CLUB-10, CLUB-19]

duration: 25min
completed: 2026-09-23
---

# Phase 33 Plan 02: Deny-test voor Clubs Summary

**`supabase/tests/clubs_deny_test.sql`: één plakbaar SQL-Editor-script met 81 checks voor 0012. Het dekt een buitenstaander, een lid, een beheerder en een ex-lid, de 30/10-grenzen, opvolging (ook via `delete_own_account()`) en het opheffen van een groep. Het eindigt altijd met `rollback`. Of het slaagt, blijkt pas in 33-03.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-09-23
- **Tasks:** 2/2
- **Files:** 1 (769 regels)

## Accomplishments
- De kop legt uit wat er bewezen wordt (CLUB-17/18/10/19/11), hoe je het draait, hoe je het resultaat leest (81 rijen, elke `ok = true`) en hoe het werkt. Ook staat er welke ids en codes de testcast gebruikt.
- A t/m E en P, Q, R zijn echte rijen in `auth.users`. Daardoor lopen de FK's, de guard- en opvolgingstriggers en de cascade van `delete_own_account` echt. Replica staat alleen aan bij de seed met vaste `joined_at`, bij de 30 opvulleden en bij de negen extra groepen van B.
- De checks zijn doorlopend genummerd van 1.1 tot 7.5 (plus 4.5b), in dezelfde volgorde als in de tabel.
- Slaagt niet alles, dan geeft het script `CLUBS DENY-TEST FAILED: <naam> (want x, got y); ...`. Het meldt het ook als het aantal checks niet 81 is.

## Task Commits

1. **Task 1: Raamwerk, seed, secties 1-3 (43 checks)** - `d9814ac` (test)
2. **Task 2: Secties 4-7 en eindcontrole (38 checks)** - `70852e5` (test)

## Files Created/Modified
- `supabase/tests/clubs_deny_test.sql` - deny- en positieve tests voor 0012

## Decisions Made
Zie key-decisions. Kleinere keuzes:
- Nieuwe code `GRPMBRA2` voor 2.6 (een lid probeert een link te maken). Die voldoet aan de regex. Zo gaat de weigering over RLS en niet over de check-constraint.
- 4.5 is opgesplitst in 4.5 (tweede keer inwisselen = ok) en 4.5b (C staat maar één keer in G, gecontroleerd als postgres). 3.7, 6.7, 6.11 en 7.2 combineren elk twee feiten in één expect. De check-naam zegt dat (bijvoorbeeld `'Dirk|true'`, `'0|0'`).
- Gecontroleerd tegen 0012 zoals het er nu staat: een RLS insert-check loopt vóór de check-constraints (3.3 geeft 23514 omdat A beheerder is). Een kolomrecht wordt gecontroleerd vóór de trigger (3.5 geeft 42501). Een `stable` helper in de with-check ziet de rij van vóór de update, dus 3.11 en 6.8 geven `last_admin` uit de after-trigger en geen 42501.

## Deviations from Plan

None - plan executed as written. 0012 is niet gewijzigd: bij het doorlopen van elke check tegen de migratie kwam geen check naar boven die met 0012 zoals geschreven niet kan slagen.

## Issues Encountered
- Er is hier geen Postgres. Het script is alleen op papier tegen 0012 gecontroleerd. Het echte oordeel komt in 33-03, als Joost het in de SQL Editor draait.
- Wat alleen de live database kan bevestigen: dat `postgres` in de SQL Editor `insert into auth.users` met alleen id/aud/role/email mag doen, en dat `session_replication_role` daar te zetten is. Het tweede gebeurde al in `rls_deny_test.sql`. Het eerste is gangbaar, maar in dit project nog niet gedaan. Gaat het daar mis, dan zie je een fout zonder het voorvoegsel `CLUBS DENY-TEST FAILED`. Dan zit de fout in de seed, niet in 0012.

## Known Stubs
Geen.

## Next Phase Readiness
- 33-03: pas eerst 0012 toe en plak dan `supabase/tests/clubs_deny_test.sql` als nieuwe query. Verwacht: 81 rijen, alle `ok = true`.

## Self-Check: PASSED
- FOUND: supabase/tests/clubs_deny_test.sql
- FOUND: d9814ac
- FOUND: 70852e5
