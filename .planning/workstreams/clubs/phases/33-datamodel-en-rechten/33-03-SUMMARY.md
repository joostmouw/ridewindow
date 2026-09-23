---
phase: 33-datamodel-en-rechten
plan: 03
status: complete
requirements: [CLUB-10, CLUB-17, CLUB-18, CLUB-19, CLUB-20]
completed: 2026-09-23
---

# 33-03 — Functietelling en live bewijs

## Wat er gedaan is

- **Task 1** (`7b8ea0e`): `CLAUDE.md` en `AGENTS.md` noemen nu elf server-functies, met namen;
  `PROJECT.md`, CLUB-20 en roadmap-criterium 5 hebben de noot "de telling volgt het schema".
  Telling in `supabase/migrations` = 11 unieke `create or replace function public.*`.
- **Task 2** (checkpoint, Joost, 2026-09-23):
  - `0012_groups.sql` toegepast via de SQL Editor op `hcdrydlgqpnmumfupgcx` ("Run without RLS" —
    de melding was een vals alarm: de migratie zet RLS zelf aan op regel 285–287). Controle
    achteraf met de service-role sleutel: `groups` en `group_members` geven 200,
    `group_invites` 403 (bewust: geen select voor service_role).
  - `clubs_deny_test.sql` gedraaid: **81 van 81 rijen `ok = true`**, eerste poging, geen
    herstelrondes. 0012 is sinds 33-01 ongewijzigd, dus de geteste versie is de live versie.
  - De twee onzekerheden uit 33-02 (insert in `auth.users` als postgres,
    `session_replication_role`) bleken geen probleem.

## Bewezen criteria (ROADMAP fase 33)

1. 0012 live — ja.
2. Buitenstaander en ex-lid lezen niets, gewoon lid doet geen beheerdershandeling — checks 1.x, 2.x, 4.7–4.13.
3. 31e lid en 11e groep geweigerd met `group_full` / `too_many_groups` — 5.1–5.4.
4. Opvolging en verdwijnen van een lege groep — 6.1–6.10.
5. `delete_own_account` laat geen groep zonder beheerder achter — 6.4–6.6; telling bijgewerkt.

## Deviations

- Het checkpoint liep in omgekeerde volgorde: Joost paste 0012 al toe terwijl 33-02 nog liep.
  Onschadelijk, want 33-02 wijzigde 0012 niet (herdraaien was hoe dan ook veilig).
