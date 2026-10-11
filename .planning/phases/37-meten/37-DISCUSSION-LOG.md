# Phase 37: Meten - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-11
**Phase:** 37-meten
**Areas discussed:** Telling, Waar je het ziet, Seintje bij uitschieter, Uitschieterregel, Nulmeting

Joost vroeg bij de gebiedskeuze "wat is jouw voorstel hier?". Claude toonde een voorstel als
pagina (https://claude.ai/artifact/U3q4VHt43GnAq18PQftTqi); Joost: "doe maar wat jij zou aanraden!"

---

## Telling

| Option | Description | Selected |
|--------|-------------|----------|
| security definer-functie met alleen totalen | Leest ook auth.users en invite-tabellen; execute alleen service_role + usage_monitor | ✓ |
| Select-grants voor service_role op elke tabel | Ruwe codes leesbaar, auth.users nog steeds niet | |
| Eigen teltabel via triggers | Schrijft mee op elk insert-pad; hoort bij fase 38 | |

## Waar je het ziet

| Option | Description | Selected |
|--------|-------------|----------|
| Lokaal script `tool/usage_report.dart` | Zelfde sleutelpatroon als analytics_report | ✓ |
| Getallen in GitHub-summary | Repo is publiek | |
| Scherm in de app | Vraagt leespad voor authenticated | |
| Dashboard-view | Komt neer op zelf een query schrijven | |

## Seintje bij uitschieter

| Option | Description | Selected |
|--------|-------------|----------|
| Dagelijkse Action die faalt, zonder getallen | psql als usage_monitor via pooler; GitHub mailt | ✓ |
| GitHub-issue | Publiek; aanvaller ziet of hij opgemerkt is | |
| pg_cron | Kan Joost niet bereiken | |

## Uitschieterregel

| Option | Description | Selected |
|--------|-------------|----------|
| 5× mediaan 28 dagen én vloer, óf één afzender boven vloer | Vangt zowel volume als één pompend toestel | ✓ |

## Nulmeting

| Option | Description | Selected |
|--------|-------------|----------|
| Historie + één zware Oppo-sessie | Drukste echte dag en bovengrens van één toestel | ✓ |
| Alleen historie | Mist wat één toestel maximaal doet | |

## Claude's Discretion

Alle vijf gebieden.

## Deferred Ideas

- device_id/afzender op feedback → fase 38
- Mislukte inwisselpogingen tellen → fase 39
- Functietelling in CLAUDE.md/AGENTS.md → fase 40
