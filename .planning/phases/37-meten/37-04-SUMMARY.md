---
phase: 37-meten
plan: 04
subsystem: database
tags: [supabase, migratie, grants, postgrest, meten, dicht-huis]
requires:
  - "37-01: migratie 0014 (usage_daily_counts + rol usage_monitor) en supabase/tests/usage_counts_test.sql"
provides:
  - "0014 live op project hcdrydlgqpnmumfupgcx; usage_monitor heeft een wachtwoord dat alleen buiten de repo staat"
  - "0015 live: migrate_account_data en delete_own_account alleen nog uitvoerbaar voor authenticated"
  - "Grantgrens live bewezen, zowel in de catalogus (testscript 19/19) als via PostgREST"
  - "~/.config/ridewindow/usage-monitor-db-url compleet (pooler-host ingevuld), klaar als secret voor 37-06"
affects: [37-05, 37-06, clubs-fase-36]
tech-stack:
  added: []
  patterns: ["elke security definer-functie: revoke all from public, anon; grant execute aan de bedoelde rol"]
key-files:
  created:
    - supabase/migrations/0015_revoke_public_execute_0001.sql
  modified:
    - .planning/workstreams/clubs/STATE.md
decisions:
  - "Afwijking: migratie 0015 neemt het PUBLIC-execute af van de twee 0001-functies; clubs-fase 36 schuift naar 0016"
  - "De pooler-hostregel in usage-monitor-db-url zet Joost zelf; Claude bewerkt geen bestand waarin een wachtwoord staat"
metrics:
  duration: "~1 sessie, met twee wachtmomenten op Joost"
  completed: 2026-10-11
  tasks: 3
  files: 2
---

# Fase 37 Plan 04: 0014 live en de grantgrens bewezen Samenvatting

0014 staat live, `usage_monitor` heeft een wachtwoord dat alleen op deze Mac staat, en de grens is op twee manieren bewezen: het testscript gaf 19 rijen met overal `ok = true`, en via de echte API krijgt de publieke app-sleutel een weigering terwijl de service-role-sleutel het dichte rooster terugkrijgt. Onderweg vond check 3.1 een oude open deur uit 0001. Die is met 0015 dichtgezet.

## Wat er gedaan is

- **Taak 1** (geen repo-commit, alles buiten de repo):
  - `~/.config/ridewindow/usage-monitor.pw`: één regel van 64 hex-tekens, rechten 600.
  - `~/.config/ridewindow/usage-monitor-setup.sql`: het eenmalige `alter role`-statement. Joost heeft het na gebruik weggegooid; het bestand bestaat niet meer.
  - `~/.config/ridewindow/usage-monitor-db-url`: de pooler-URL voor het secret van 37-06, rechten 600.
  - `git grep` vond het wachtwoord nergens in de repo. Het wachtwoord is in geen enkele uitvoer verschenen.
- **Taak 2** (checkpoint, door Joost in de SQL Editor): 0014 toegepast, wachtwoord gezet, testscript gedraaid. De eerste run faalde op check 3.1, zie de afwijking hieronder. Na 0015 is het script opnieuw gedraaid en was alles groen.
- **Taak 3**: de pooler-host `aws-0-eu-west-3.pooler.supabase.com` staat in `usage-monitor-db-url`. Die regel heeft Joost zelf vervangen met een eigen shell-commando, want een bestand met een wachtwoord erin bewerken is voor Claude geblokkeerd. Claude heeft daarna alleen gecontroleerd dat `POOLER_HOST` er niet meer in staat (zonder de inhoud te tonen) en dat de rechten 600 zijn.

## Testscript: 19 rijen, alle ok = true

| Check | Onderwerp | ok |
|---|---|---|
| 1.1 | anon mag usage_daily_counts niet uitvoeren | true |
| 1.2 | authenticated mag usage_daily_counts niet uitvoeren | true |
| 1.3 | service_role mag usage_daily_counts uitvoeren | true |
| 1.4 | usage_monitor mag usage_daily_counts uitvoeren | true |
| 2.1 | usage_monitor heeft op geen enkele tabel in public een recht | true |
| 2.2 | usage_monitor heeft geen usage op schema auth | true |
| 3.1 | usage_monitor voert geen andere security definer-functie in public uit | true (na 0015) |
| 4.1 | anon roept usage_daily_counts aan: geweigerd | true |
| 4.2 | ingelogde gebruiker roept usage_daily_counts aan: geweigerd | true |
| 5.1 | usage_monitor krijgt 7 dagen x 10 bronnen | true |
| 6.1 | tien verschillende bronnen | true |
| 6.2 | geen negatief aantal rijen | true |
| 6.3 | feedback_anoniem en accounts_* geven geen afzendertelling | true |
| 7.1 | p_days = 0 wordt geweigerd | true |
| 7.2 | p_days = 4000 wordt geweigerd | true |
| 8.1 | app_events: rows stijgt met 4 | true |
| 8.2 | app_events: distinct_senders stijgt met 2 | true |
| 8.3 | app_events: max_rows_one_sender is minstens 3 | true |
| 8.4 | feedback_anoniem: rows stijgt met 1 | true |

De 8.x-checks meten alleen het verschil vóór en na de eigen testrijen. Die rijen worden in het script teruggedraaid. Er staat dus geen productietotaal in deze tabel (D-19).

## Live grantgrens via PostgREST

POST naar `rpc/usage_daily_counts` met `{"p_days": 2}`:

| Aanroep | Resultaat |
|---|---|
| anon als `apikey` en `Authorization: Bearer` | HTTP 401, code `42501` |
| alleen `apikey` = anon | HTTP 401, code `42501` |
| service-role-sleutel | HTTP 200, 20 objecten, 10 unieke bronnen |

De sleutels van een object zijn `day`, `distinct_senders`, `max_rows_one_sender`, `p95_rows_one_sender`, `rows` en `source`. Alleen de vorm is gecontroleerd. Geen enkele telwaarde is getoond of opgeschreven (D-19): productiedata lezen gebeurt pas in 37-05, na Joosts akkoord. De service-role-sleutel is in een variabele gelezen en nooit getoond.

## Afwijkingen van het plan

### Automatisch opgelost

**1. [Regel 2 - Ontbrekend recht dichtgezet] Migratie 0015: PUBLIC-execute af van de 0001-functies**
- **Gevonden tijdens:** Taak 2. Bij de eerste testrun faalde check 3.1: `usage_monitor` kon `migrate_account_data` en `delete_own_account` uitvoeren.
- **Oorzaak:** Postgres geeft EXECUTE op een nieuwe functie standaard aan PUBLIC. 0001 gaf wel `grant execute ... to authenticated`, maar nam het recht van PUBLIC nooit af. Elke functie sinds 0002 doet dat wel (`revoke all ... from public, anon`). Omdat elke rol lid is van PUBLIC, konden ook `anon` en `usage_monitor` deze twee functies aanroepen.
- **Niet misbruikbaar:** beide functies stoppen met een fout als `auth.uid()` leeg is. Zonder inlog kom je dus niet verder dan die fout. Dit zet een deur dicht; er was geen lek.
- **Oplossing:** `supabase/migrations/0015_revoke_public_execute_0001.sql` neemt het recht van `public, anon` af en geeft het opnieuw aan `authenticated`. Er komt geen functie en geen recht bij, dus het aantal server-functies in CLAUDE.md blijft dertien. Joost heeft 0015 in de SQL Editor toegepast. Daarna gaf het testscript 19/19 `ok = true`.
- **Gevolg voor clubs:** de clubs-workstream had 0015 gereserveerd voor fase 36. Die schuift naar **0016**; dat staat in `.planning/workstreams/clubs/STATE.md`.
- **Bestanden:** `supabase/migrations/0015_revoke_public_execute_0001.sql`, `.planning/workstreams/clubs/STATE.md`
- **Commit:** a1bdd8b

**2. [Werkwijze] De pooler-hostregel is door Joost gezet, niet door Claude**
- Het plan liet Claude `<POOLER_HOST>` vervangen in `usage-monitor-db-url`. Dat bestand bevat het wachtwoord, en het bewerken ervan is voor Claude geblokkeerd. Joost heeft de regel met een eigen `!`-commando vervangen, zonder uitvoer. Claude heeft alleen gecontroleerd dat de placeholder weg is en dat de rechten 600 zijn.

## Wat nu

- **37-05 (nulmeting)** leest voor het eerst echte productietotalen. Dat gebeurt pas na Joosts uitdrukkelijke akkoord (D-19).
- **37-06** zet `usage-monitor-db-url` als GitHub-secret. Het bestand is daarvoor compleet.
- MEET-01 en MEET-02 blijven open tot 37-05 en 37-06 klaar zijn.

## Self-Check: PASSED

- `supabase/migrations/0015_revoke_public_execute_0001.sql`: gevonden
- Commit a1bdd8b: gevonden
- `usage-monitor-db-url`: geen `POOLER_HOST`, rechten 600; `usage-monitor-setup.sql` verwijderd
