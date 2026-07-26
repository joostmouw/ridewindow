# Phase 20: Repository refactor (local-only) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-26
**Phase:** 20-repository-refactor-local-only
**Areas discussed:** Sleutels en dataformaat, `updatedAt`-stempeling, `PlannedRidesNotifier` sync→async, Bewijs van ongewijzigd gedrag

**Vorm van deze sessie:** de gebruiker kreeg de vier grijze gebieden als genummerde lijst (tekstmodus, Remote Control actief), vroeg vervolgens tweemaal om een aanbeveling in plaats van zelf te kiezen, en volgde die integraal ("okee ik volg jou"). De onderbouwing per keuze staat hieronder, want die is bij een gevolgd advies het enige dat later nog te toetsen valt.

---

## Sleutels en dataformaat

| Optie | Beschrijving | Gekozen |
|---|---|---|
| Ongewijzigd laten | Alle 14 prefs-sleutels en formaten letterlijk behouden; alleen de code verhuist. Nul migratie. | ✓ |
| Normaliseren tijdens de verhuizing | Sleutels/formaten meteen opschonen nu je er toch aan zit (bijv. profiel naar één blob). | |

**Aanbeveling gevolgd:** ongewijzigd laten.
**Onderbouwing:** code verplaatsen en dataformaat wijzigen tegelijk maakt een fout onvindbaar — je weet niet welke van de twee hem veroorzaakte. Bovendien is dit exact de pijplijn die op 2026-07-25 al eens gerepareerd moest worden (quick task `260725-knl`).

---

## `updatedAt` — granulariteit en stempelmoment

| Optie | Beschrijving | Gekozen |
|---|---|---|
| Eén tijdstempel per domein | `profile.updatedAt`, `availability.updatedAt`, `planned_rides.updatedAt`, gezet in het schrijfpad van de repository. | ✓ |
| Per veld | Fijnmazige tijdstempels, richting veldniveau-merge. | |

**Aanbeveling gevolgd:** één per domein, gestempeld in de repository.
**Deelvraag die fase 19 expliciet doorschoof (`19-CONTEXT.md` D-04):** mag de automatische invulling van `profile.userName` bij inloggen `updatedAt` bewegen? **Antwoord: nee.** Die schrijfactie komt van de app, niet van de gebruiker; zou hij meetellen, dan leest fase 21 elk eerste inloggen op een nieuw toestel als een echte wijziging en toont een conflictdialoog zonder conflict.
**Aanvullend vastgelegd:** een ontbrekende `updatedAt` wordt niet retroactief op "nu" gezet — dat zou elke bestaande installatie er na de update uit laten zien alsof er net iets gewijzigd is.

---

## `PlannedRidesNotifier` sync → async

| Optie | Beschrijving | Gekozen |
|---|---|---|
| Async, vorige waarde blijft staan | Async `build()` + `ref.watch(authStateProvider)`, prefs blijven vooraf ingeladen, tijdens herladen blijft de vorige lijst zichtbaar. | ✓ |
| Async met skeleton/laadstaat | Expliciete laadweergave op Home tijdens het herladen. | |
| Synchroon houden | Refactor uitstellen tot fase 21 hem echt nodig heeft. | |

**Aanbeveling gevolgd:** async, maar nooit een lege flits.
**Onderbouwing:** de bestaande lege staat betekent "er zijn geen geplande ritten". Een laadmoment dat daarop lijkt is precies de zichtbare gedragsverandering die succescriterium 1 verbiedt. Omdat de prefs al vooraf ingeladen zijn, is de async-vorm in de praktijk binnen hetzelfde frame klaar — de vorm is er voor fase 21, niet voor vandaag.

---

## Bewijs dat er niets veranderde

| Optie | Beschrijving | Gekozen |
|---|---|---|
| Suite groen + handmatige toestelcheck | 317/0 als ondergrens, plus kijken op een installatie met echte opgeslagen data. | ✓ |
| Alleen de suite groen | Vertrouwen op de geautomatiseerde tests. | |

**Aanbeveling gevolgd:** allebei.
**Onderbouwing:** de suite draait op verse, lege prefs — precies de conditie waarin een dataregressie zich niet laat zien. De toestelcheck kost twee minuten en zou het faalpatroon van juli wél hebben gevangen.
**Aanvullend vastgelegd:** REG-05 ("de isolate krijgt geen Supabase-afhankelijkheid") wordt een assertie op de importgraaf van `background_task.dart`, geen belofte in een commit-bericht.

---

## Claude's Discretion

- Bestandsindeling en klassenamen onder `lib/data/repositories/`; constructie via `@riverpod`-providers of direct in de notifiers.
- De precieze vorm van "schrijf zonder te stempelen".
- Hoe de backwards-compat-tak van `PlannedRide.fromJson` (oud `time`-formaat) mee verhuist — die blijft nodig.
- Plan-indeling: aantal plannen, volgorde, en of de drie domeinen los of samen gaan.
- Hoe "vorige waarde tijdens herladen" technisch wordt gehaald.

## Deferred Ideas

- Sleutels/formaten normaliseren — eigen klus, met eigen migratie en toestelverificatie.
- Beschikbaarheid naar de ongebruikte Drift-tabel `AvailabilityGridEntries`.
- Outbox, cloud-reads/-writes, Postgres-schema, RLS, conflictresolver — fase 21.
- `lastSyncedUid` als volwaardig eigendomsveld — fase 21 (MIG-04).
- Per-veld tijdstempels / veldniveau-merge — niet gepland.

## Bevinding tijdens het scouten

`ARCHITECTURE.md` §2 zegt "11 distinct keys" voor profiel en somt er 12 op; de code heeft er 12. Vastgelegd in CONTEXT.md D-03 zodat de planner het onderzoeksgetal niet overneemt.

## Volgorde-advies

Fase 19's plan 19-07 (Play Store-installatie + regressiechecklist) stond bij het schrijven van deze context nog open. Advies aan de gebruiker, door hem overgenomen: fase 20 pas plannen en uitvoeren als 19-07 groen is, omdat fase 20 precies de code verbouwt die 19-07 moet bewijzen.
