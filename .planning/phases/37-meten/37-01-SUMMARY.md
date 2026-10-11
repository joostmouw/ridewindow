---
phase: 37-meten
plan: 01
subsystem: database
tags: [supabase, postgres, security-definer, meten, dicht-huis]
requires: []
provides:
  - "public.usage_daily_counts(p_days int): totalen per Amsterdamse dag x 10 bronnen"
  - "login-rol usage_monitor (zonder wachtwoord, alleen execute op de telfunctie)"
  - "supabase/tests/usage_counts_test.sql: 19 checks, eindigt met rollback"
affects: [37-03, 37-04, 37-06, 38, 39, 40]
tech-stack:
  added: []
  patterns: ["security definer met set search_path = '' en volledig gekwalificeerde namen", "dicht rooster via generate_series x values-lijst"]
key-files:
  created:
    - supabase/migrations/0014_usage_daily_counts.sql
    - supabase/tests/usage_counts_test.sql
  modified:
    - .planning/workstreams/clubs/STATE.md
decisions:
  - "usage_daily_counts geeft p95_rows_one_sender afgerond op 2 decimalen (numeric)"
  - "Testscript geeft postgres tijdelijk lidmaatschap van usage_monitor (grant usage_monitor to postgres, teruggedraaid door rollback) zodat set role werkt op Postgres 16+"
  - "Clubs-workstream fase 36 schuift naar migratie 0015"
metrics:
  duration: "~10 min"
  completed: 2026-10-11
  tasks: 2
  files: 3
---

# Fase 37 Plan 01: Telfunctie usage_daily_counts Samenvatting

Migratie 0014 levert `public.usage_daily_counts(p_days int)`, een security definer-functie zonder zoekpad die per Amsterdamse kalenderdag en per bron (tien bronnen, dicht rooster) alleen `rows`, `distinct_senders`, `max_rows_one_sender` en `p95_rows_one_sender` teruggeeft. Daarbij komt de login-rol `usage_monitor`, die zonder wachtwoord en zonder tabelrechten wordt aangemaakt. Alleen `service_role` en `usage_monitor` mogen de functie uitvoeren.

## Wat er gebouwd is

- **Taak 1 (3f307d2):** `supabase/migrations/0014_usage_daily_counts.sql`
  - De kop verantwoordt de functie als nummer 14 (D-05). Het bijwerken van de telling in CLAUDE.md/AGENTS.md staat genoteerd voor fase 40.
  - Sectie "Ondergrens" geeft per bron aan waarom rijen verdwijnen; `group_ride_options` is de zwakste (D-06).
  - De rol is idempotent: `noinherit`, `connection limit 3`, `statement_timeout 30s` en `default_transaction_read_only = on`. Hij krijgt alleen `usage on schema public`.
  - `group_ride_options` heeft geen eigen aanmakerkolom en telt daarom de afzender via `group_rides.owner_id`.
  - Accounts worden uitgesplitst naar `accounts_google`, `accounts_email` en `accounts_overig`.
  - `p_days` buiten 1..3660 geeft `22023`.
  - In `.planning/workstreams/clubs/STATE.md` is 0014 vervangen door 0015 voor fase 36. Dat is een wijziging van één regel.
- **Taak 2 (3562e05):** `supabase/tests/usage_counts_test.sql`
  - 19 checks in acht groepen, in het patroon van `clubs_deny_test.sql`.
  - Een mislukte check geeft de fout `USAGE-TEST FAILED:`; het script eindigt altijd met `rollback`.
  - Check 8 vergelijkt alleen verschillen voor en na eigen testrijen, zodat er geen productietotalen in de uitvoer komen (D-19).

## Afwijkingen van het plan

**1. [Regel 3 - Blokkerend] Tijdelijk lidmaatschap voor `set role usage_monitor`**
- **Gevonden tijdens:** taak 2
- **Probleem:** Sinds Postgres 16 krijgt de maker van een rol alleen ADMIN en geen SET. Daardoor zou `set local role usage_monitor` als postgres in de SQL Editor falen.
- **Oplossing:** Het testscript doet `grant usage_monitor to postgres` binnen de transactie. De `rollback` aan het eind draait dat weer terug. De migratie zelf geeft dit lidmaatschap niet.
- **Commit:** 3562e05

**2. [Regel 3] Definitieregel van de expect-helper**
- `create function pg_temp.expect (p_name ...)` heeft een spatie voor het haakje. Zo telt de verify-grep alleen de 19 echte aanroepen en niet de definitie.

## Niet lokaal uitgevoerd

Er is geen lokale Postgres (geen psql/docker/supabase-CLI). De SQL is daarom alleen via de grep-gates gecontroleerd, niet uitgevoerd. De live toepassing en het draaien van het testscript gebeuren in 37-04. Aandachtspunten daarvoor:
- `percentile_cont ... filter (...)`.
- Check 2.2: of PUBLIC usage heeft op het auth-schema in Supabase. Het plan verwacht `false`.
- De grant van het lidmaatschap aan postgres.

## Bekende stubs

Geen.

## Self-Check: PASSED

- FOUND: supabase/migrations/0014_usage_daily_counts.sql
- FOUND: supabase/tests/usage_counts_test.sql
- FOUND: 3f307d2, 3562e05
