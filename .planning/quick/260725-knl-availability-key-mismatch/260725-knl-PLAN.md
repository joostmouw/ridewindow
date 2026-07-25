---
id: 260725-knl
slug: availability-key-mismatch
description: Fix de beschikbaarheids-pipeline — geblokkeerde uren werken niet door in de app
date: 2026-07-25
status: in-progress
source: .planning/AUDIT-COHERENCE-260725.md
---

# Quick Task 260725-knl: beschikbaarheids-pipeline repareren

Volledige diagnose: `.planning/AUDIT-COHERENCE-260725.md` (audit-items A1, A2, A4, B2,
B3, B4, B5, C1, C2, C3).

**Kern:** grid-cellen, range-fill en calendar-import maken `DateTime.utc(...)`-sleutels,
terwijl presets, de Open-Meteo forecast-tijden en alle lookups lokale `DateTime`
gebruiken. Dart's `DateTime.==` vergelijkt ook `isUtc`, dus `containsKey()` faalt altijd
en blokkeren doet niets.

**Buiten scope (bewust):** audit-item 6 (bevroren score op Home vs actuele op Rides) en
audit-item 7 (de niet-aangesloten notificatie-toggles).

---

## Taak 1 — Canonieke sleutel + één gedeelde lookup

**Files:** `lib/domain/services/availability_key.dart` (nieuw),
`lib/domain/services/availability_filter.dart`,
`lib/providers/availability_notifier.dart`,
`lib/providers/availability_presets.dart`,
`lib/domain/services/range_fill.dart`,
`lib/features/availability/availability_screen.dart`,
`lib/features/agenda/week_agenda_screen.dart`,
`lib/platform/background_task.dart`

**Action:**
- Nieuwe module met `canonicalHourKey()` (lokale `DateTime(y,m,d,h)`), `blockTypeAt()`
  en `isHourBlocked()`, plus een `BlockedHours`-index voor herhaalde lookups.
- Recurrence-model expliciet maken: `work` en `custom` zijn een **terugkerend
  weekpatroon** (weekdag+uur), `calendar` is **datum-specifiek** en verloopt vanzelf.
  Dit vervangt de normalisatie via `blockedHours.keys.first` (insertion-order van een
  `LinkedHashMap` = willekeurig).
- De drie uit elkaar gelopen kopieën van de blocked-lookup vervangen door de gedeelde
  module.
- Alle schrijfpaden op de canonieke sleutel zetten (`_cellKey`, range-fill,
  calendar-import).
- **Migratie:** `AvailabilityNotifier.build()` normaliseert bij het inlezen, zodat de
  gemengde sleutels die al in SharedPreferences van beta-testers staan meteen goed
  komen. Bij een botsing wint het sterkste type (work > calendar > custom).

**Verify:** `flutter test test/domain/services/` groen; nieuwe unit-tests voor
`canonicalHourKey`, het weekpatroon en de migratie.

**Done:** een uur blokkeren in het grid filtert het overeenkomstige slot op Home.

---

## Taak 2 — seedPreset mergen in plaats van vervangen

**Files:** `lib/providers/availability_notifier.dart`

**Action:** alleen `work`-entries verversen; `custom` en `calendar` blijven staan. Volgt
het patroon dat `importCalendarBlocks()` al gebruikt.

**Verify:** unit-test — preset seeden na handmatige blokken laat die blokken intact.

**Done:** een preset-chip wist geen gebruikersdata meer.

---

## Taak 3 — Dedup symmetrisch, now-cutoff, stabiele sortering

**Files:** `lib/domain/services/slot_generator.dart`, `lib/providers/slots_notifier.dart`,
`lib/platform/background_task.dart`, `lib/features/home/home_screen.dart`

**Action:**
- `_overlapRatio` delen door de duur van het **kortste** slot, conform de eigen
  docstring. Verwachting: de 2 al maanden falende tests worden hierdoor groen.
- `notBefore`-parameter op `SlotGenerator.generate()` zodat verlopen vensters verdwijnen
  uit Home, Agenda en de home-screen widget. Default `null` zodat bestaande
  test-fixtures met vaste datums blijven werken; beide app-callers geven `DateTime.now()`.
- Home sorteert op `(tier, start)` in plaats van alleen tier — `List.sort` is in Dart
  niet stabiel.

**Verify:** `flutter test` — minimaal de baseline 282/2, verwachting 284/0.

**Done:** geen overlappende dubbele vensters meer, geen verlopen vensters, stabiele
kaartvolgorde.
