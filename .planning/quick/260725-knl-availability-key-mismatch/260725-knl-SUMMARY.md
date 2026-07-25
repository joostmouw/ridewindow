---
id: 260725-knl
slug: availability-key-mismatch
status: complete
date: 2026-07-25
commits:
  - 70403ea fix — geblokkeerde uren werken weer door in de app
  - 93efbf8 fix — dedup symmetrisch, verlopen vensters weg, stabiele volgorde
tests: 306 passing / 0 failing (baseline was 282 / 2)
---

# Samenvatting 260725-knl

## Wat er gebeurd is

Alle zes de geplande items zijn doorgevoerd, plus de dedup-drempel en de twee
al maanden falende tests op vervolgverzoek. De testsuite gaat van **282/2 naar
306/0** — voor het eerst volledig groen.

### Taak 1 — canonieke sleutel, gedeelde lookup, migratie ✅

`lib/domain/services/availability_key.dart` is nu de enige plek waar een
uur-sleutel ontstaat. `canonicalHourKey()` levert altijd een lokale
`DateTime(y,m,d,h)`; voor een UTC-invoer worden de UTC-*componenten* overgenomen
zonder zone-conversie, want oude grid-sleutels stempelden een lokale wandkloktijd
als UTC.

Het recurrence-model is expliciet gemaakt in `BlockedHours`:
- `work` en `custom` → terugkerend weekpatroon, match op weekdag + uur
- `calendar` → datum-specifiek, verloopt vanzelf

Dat vervangt de oude normalisatie via `blockedHours.keys.first` — de
insertion-order van een `LinkedHashMap`, dus willekeurig.

De drie uit elkaar gelopen kopieën van de blocked-lookup (`availability_filter`,
`week_agenda_screen._isBlocked`, en de directe `blocked[key]`-lookups in
`availability_screen`) lopen nu allemaal door dezelfde index.

Migratie zit in `AvailabilityNotifier.build()`: bestaande installs met gemengde
sleutels komen bij het inlezen meteen goed. Bij een botsing wint het sterkste
type (work > calendar > custom).

### Taak 2 — seedPreset merget ✅

Een preset-chip ververst alleen nog de `work`-entries. Handmatige en
geïmporteerde blokken blijven staan. Twee nieuwe tests dekken dit af.

### Taak 3 — dedup, cut-off, sortering ✅

- `_overlapRatio` deelt door de duur van het **kortste** slot. Het geval van de
  tester-schermfoto is aantoonbaar opgelost: bij een bewaard venster van 19:00–21:00
  en een kandidaat van 17:00–22:00 is de ratio nu 2/2 = 1.0 (was 2/5 = 0.4), dus
  het lange venster valt weg.
- `notBefore` op `SlotGenerator.generate()`, gevoed door de nieuwe `nowProvider`
  in `SlotsNotifier` en door `DateTime.now()` in de background task. Verlopen
  vensters verdwijnen daarmee uit Home, Agenda én de home-screen widget in één
  keer.
- Home sorteert op `(tier, start)`.

---

## De 2 falende tests: hypothese was fout, echte oorzaak gevonden en opgelost

Het plan verwachtte dat de symmetrie-fix in `_overlapRatio` deze twee groen zou
maken. Dat gebeurde niet — de getallen bleven exact gelijk (74 → 104).

De echte oorzaak is gemeten met de toleranties constant en alleen de toegestane
duren gevarieerd:

| allowedDurations | ruwe slots | dedup (`> 0.5`) | dedup (`>= 0.5`) |
|---|---|---|---|
| `[2]` | 105 | **105** | 54 |
| `[3]` | 98 | 49 | 49 |
| `[2, 3]` | 203 | 76 | 49 |
| `[2, 3, 5]` | 287 | 48 | 36 |

Beide tests wisselden tegelijk van toleranties **en** van `allowedDurations`
(`[2,3]` → `[2]`). De sprong 74 → 104 kwam volledig van die tweede wijziging.

Daaronder lag een echte bug, groter dan het geval op de schermfoto: **bij
`allowedDurations: [2]` dedupte er niets.** Twee aangrenzende 2-uursvensters
delen precies 1 uur — 0.5 van het kortste venster — en de drempel was `> 0.5`.
Een gebruiker die alleen ritten van 2 uur toestaat kreeg op Home elk
uur-verschoven venster los: ~15 vrijwel identieke kaarten per dag. Met `>= 0.5`
wordt dat 7,7 per dag.

De tests zijn daarna op hun werkelijke oorzaak gerepareerd: `allowedDurations`
blijft nu gelijk. Omdat de fixtures vlak zijn (elk uur exact dezelfde waarden)
verlagen strengere toleranties alle scores even hard en blijft het aantal slots
gelijk — de assertie kijkt daarom naar de score zelf, wat het directe bewijs is
dat `SlotsNotifier` op de nieuwe toleranties hercomputed heeft.

---

## Aanpassingen aan bestaande tests

Vier testbestanden legden de oude, kapotte conventie vast en zijn meeveranderd:

- `range_fill_test.dart`, `availability_notifier_test.dart`,
  `availability_screen_test.dart`: `DateTime.utc(...)`-fixtures naar de canonieke
  lokale vorm (43 plekken). Dit is fixture-drift, geen verzwakking — ze testten
  de sleutel-smaak die nu juist de bug was.
- `availability_notifier_test.dart`: de test met de naam "seedPreset vervangt de
  map" is hernoemd en aangevuld met twee tests voor het merge-gedrag.
- `slots_notifier_test.dart` en `integration_test.dart`: elke `ProviderContainer`
  krijgt `nowProvider.overrideWithValue(baseTime)`, anders knipt de nieuwe
  cut-off de historische fixtures compleet weg.

## Buiten scope gehouden

Audit-item 6 (bevroren score op Home vs. actuele op Rides) en audit-item 7 (de
niet-aangesloten notificatie-toggles) zijn niet aangeraakt, conform de opdracht.
