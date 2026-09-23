---
phase: 34-groep-maken-en-beheren
plan: 01
subsystem: database
tags: [supabase, rls, plpgsql, clubs, groups]
requires:
  - "0012_groups.sql (live): is_group_member, guard_group_member_insert, ensure_group_admin"
provides:
  - "group_join_requests + policies (select/delete) en grants"
  - "redeem_group_invite -> table(group_id, group_name, status) met 'member' | 'requested'"
  - "propose_group_member(p_group_id, p_user_id) -> 'member' | 'requested'"
  - "accept_group_request(p_request_id) -> void"
  - "groups_select_member_or_requester, group_invites_select_member, group_invites_insert_member"
affects: [34-02 deny-tests + toepassen, PelotonGateway groepsmethoden, /group/:code landing]
tech-stack:
  added: []
  patterns: ["schrijven alleen via security definer rpc", "lockvolgorde groep -> aanvraag -> persoon"]
key-files:
  created:
    - supabase/migrations/0013_group_join_requests.sql
  modified:
    - CLAUDE.md
    - AGENTS.md
    - .planning/PROJECT.md
decisions:
  - "34-01: aanvragen alleen via definer-rpc's; authenticated heeft op group_join_requests alleen select/delete (namen uit de database)"
  - "34-01: functietelling na 0013 is dertien, niet twaalf: voordragen vraagt een definer-functie voor de namen"
  - "34-01: redeem lockt de groepsrij vóór de idempotente checks; lockvolgorde overal groep -> aanvraag -> persoon"
  - "34-01: accept op een verdwenen of niet-eigen aanvraag geeft not_allowed (verklapt geen id)"
metrics:
  duration: 15min
  completed: 2026-09-23
  tasks: 2
  files: 4
---

# Phase 34 Plan 01: Migratie 0013 aanvragen en voordragen Summary

Migratie 0013 legt de herziening van Joost vast: de groepslink en een voordracht door een gewoon lid leveren een aanvraag op in `group_join_requests`; alleen een beheerder maakt lid (via `accept_group_request` of door zelf voor te dragen), en elke weg naar lidmaatschap loopt door de 30/10-guard uit 0012.

## Wat er gebouwd is

- **Task 1 (cd0809f)** `supabase/migrations/0013_group_join_requests.sql`, transactioneel en herdraaibaar:
  - tabel `group_join_requests` (unique `(group_id, user_id)`, `proposed_by` null = via link, namen door de database ingevuld), RLS met select/delete voor aanvrager, voordrager en beheerder; geen insert/update-policy of -grant;
  - `groups_select_member_or_requester` vervangt `groups_select_member`; `group_invites_select_member` en `group_invites_insert_member` vervangen de admin-varianten; intrekken blijft admin;
  - `redeem_group_invite` (drop + create, nieuw returntype met `status`), `propose_group_member`, `accept_group_request`, allemaal security definer met `set search_path = public, pg_temp`, revoke van public/anon, execute voor authenticated;
  - nieuwe foutsleutels `not_member`, `not_friend`, `not_allowed`, `too_many_requests`; kop met keuzes a-g en een controle-footer (policytellingen 3/4/3/2, "Verwacht: 13 rijen").
- **Task 2 (9c97f48)**: CLAUDE.md ("thirteen of them today", acht rpc's), AGENTS.md ("Dertien vandaag" met de volledige lijst) en PROJECT.md (zin over fase 34) noemen dezelfde dertien functies als de kop van 0013.

Alle acceptatiechecks uit het plan geslaagd (begin/commit 2, too_many_requests 3, not_allowed 5, not_friend 2, not_member 2, security definer 6, insert-policy op group_members niet genoemd, telling over alle migraties 13).

## Deviations from Plan

**1. [Rule 1 - Race] Groepslock in redeem vóór de idempotente checks**
- Het plan zette "al lid" en "al aangevraagd" vóór de lock. Dan kan iemand die net geaccepteerd wordt tegelijk nog een aanvraag krijgen. De lock (die meteen de naam leest) komt nu direct na het opzoeken van de code; de volgorde van de meldingen (group_full vóór too_many_groups vóór too_many_requests) is ongewijzigd. Een opgeheven groep tussen code-lookup en lock geeft `invite_invalid`.

**2. [Rule 1 - Deadlock] Lockvolgorde in accept_group_request**
- Accept leest de aanvraag eerst zonder lock, controleert beheerder, lockt dan de groep en leest de aanvraag opnieuw `for update`. Zo is de volgorde gelijk aan die van een beheerder die voordraagt (guard lockt groep, dan delete van de aanvraag) en kunnen die twee elkaar niet deadlocken. Is de aanvraag tussendoor verdwenen, dan `not_allowed`.

**3. [Rule 2] unique_violation-vangnet ook in de admin-tak van propose**
- Tegelijk geaccepteerd en toegevoegd geeft dan gewoon 'member' in plaats van een fout.

Geen extra functies en geen wijziging aan 0012-triggers nodig.

## Aandachtspunten voor plan 02 (niet uitgevoerd hier)

- 0013 is **niet toegepast**; dat doet Joost in plan 02 na de deny-tests.
- `clubs_deny_test.sql` uit fase 33 verwacht dat een gewoon lid geen groepslink ziet/maakt en dat de link direct lid maakt; die checks moeten in plan 02 omgedraaid worden.
- Verdwijnt het account van een voordrager, dan wordt `proposed_by` null (lijkt "via link"), maar `proposed_by_name` blijft staan; de app kan daar op terugvallen.

## Threat Flags

Geen nieuw oppervlak buiten het threat model (T-34-01..07 gedekt).

## Self-Check: PASSED

- FOUND: supabase/migrations/0013_group_join_requests.sql
- FOUND: cd0809f, 9c97f48
