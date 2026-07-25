# Coherentie-audit RideWindow — 2026-07-25

Doorloop van de app op onsamenhangende features en dingen die niet (goed) werken.
Alles hieronder is geverifieerd in de code; waar een claim uit een test of een
schermfoto komt staat dat erbij.

**Testsuite-baseline op moment van audit:** `flutter test` → **282 passing / 2 failing**
(exit 0 op de suite-runner, "Some tests failed" onderaan). De 2 falende tests zijn
géén flakiness — zie bevinding B3, ze leggen een echte bug bloot.

---

## A. Kapot — feature doet niets van wat hij belooft

### A1. Geblokkeerde uren filteren geen enkel ride-slot (KRITIEK)

De hele "edit my schedule"-feature heeft geen effect op wat de app voorstelt.

Oorzaak: er lopen twee onverenigbare `DateTime`-smaken door elkaar als sleutel in
`Map<DateTime, BlockType>`.

| Waar | Sleutel-constructie | `isUtc` |
|---|---|---|
| Grid-cellen | `DateTime.utc(...)` — `availability_screen.dart:860` | `true` |
| Range-fill (twee-tik) | `DateTime.utc(...)` — `range_fill.dart:39` | `true` |
| Calendar-import | `DateTime.utc(...)` — `availability_screen.dart:816` | `true` |
| Presets | `DateTime(...)` — `availability_presets.dart:38` | `false` |
| Weerdata (Open-Meteo, `timezone=auto`) | `DateTime.parse("2026-07-25T09:00")` | `false` |
| Filter-lookup | `DateTime(...)` — `availability_filter.dart:62` | `false` |
| Agenda-lookup | `DateTime(...)` — `week_agenda_screen.dart:73,82` | `false` |

Dart vergelijkt in `DateTime.==` óók `isUtc`. Geverifieerd op dit systeem (offset +2):

```
DateTime.utc(2026,7,27,9) == DateTime(2026,7,27,9)  → false
{DateTime.utc(2026,7,27,9): x}.containsKey(DateTime(2026,7,27,9))  → false
```

Gevolg: elk uur dat de gebruiker in het grid blokkeert (custom óf agenda-import)
krijgt een UTC-sleutel, terwijl `AvailabilityFilter` met lokale slot-tijden zoekt.
De lookup faalt altijd. **Blokkeren doet niets.**

De reactieve bedrading is wél in orde — `SlotsNotifier` doet `ref.watch(availabilityProvider)`
(`slots_notifier.dart:64`) en Home, Agenda en de home-screen widget kijken mee. Er is
dus geen refresh-probleem; alleen de sleutels matchen niet.

### A2. Preset-chips lijken niets te doen, maar filteren wél

Spiegelbeeld van A1: `buildPreset()` seedt lokale sleutels, het grid kleurt op
UTC-sleutels. Na het tikken op "Weekends only" blijft het grid dus leeg —
terwijl de work-blokken op Home wél slots wegfilteren (lokaal matcht lokaal).
Zichtbaar effect en werkelijk effect staan los van elkaar.

Geldt ook voor de preset die onboarding seedt (`onboarding_screen.dart:78-81`).

### A3. De drie notificatie-toggles in Profile schedulen niets

`notifEveningBefore`, `notifMorningOf` en `notifWeeklyDigest` staan als
`SwitchListTile` in Profile (`profile_screen.dart:390-418`), worden persistent
opgeslagen in `UserProfile`, en doen verder **niets**.

`_scheduleNotificationsIfPermitted()` (`profile_screen.dart:60-84`) vraagt alleen
`POST_NOTIFICATIONS` op en waarschuwt over `SCHEDULE_EXACT_ALARM`. De methode sluit
af met een eigen comment:

> `// Verdere scheduling vindt plaats via SlotsNotifier data in de toekomst (Phase 8 scope: permissie-flow)`

Bewijs dat er niets gepland wordt: `scheduleMorningOf()` en `scheduleWeeklyDigest()`
in `notification_service.dart` hebben **nul aanroepers** in de hele codebase.
`scheduleEveningBefore()` heeft er precies één (`ride_detail_screen.dart:888`) en dat
is de handmatige herinnering per rit — niet de profielinstelling. De background task
(`background_task.dart`) stuurt geen enkele notificatie; die update alleen de widget.

De gebruiker zet dus drie schakelaars aan, geeft notificatiepermissie, en krijgt nooit iets.

### A4. Background task / home-screen widget heeft dezelfde blokkade-bug

`background_task.dart:145-156` leest `availability.blockedHours` opnieuw in en voert
dezelfde pipeline uit — inclusief dezelfde sleutel-mismatch uit A1. De widget kan dus
een "volgend beste slot" tonen in een uur dat de gebruiker geblokkeerd heeft.

---

## B. Onsamenhangend — dezelfde data, ander gedrag per scherm

### B1. Geplande rit toont een andere score op Home dan op Rides

- **Home** (`home_screen.dart:582`): `ScoreBadge(tier: rideTierFromScore(ride.plannedScore))`
  — de score zoals die was op het moment van plannen, bevroren.
- **Rides** (`planned_rides_screen.dart:233, 500`): berekent `currentScore` uit de
  actuele forecast en toont zelfs een delta t.o.v. `plannedScore`.

Dezelfde rit kan dus "Perfect" zijn op Home en "Acceptable" op Rides. Ook
`_openPlannedRideDetail()` (`home_screen.dart:633-639`) valt terug op de bevroren
score als het slot niet meer in de huidige slots-lijst zit.

### B2. Drie losse implementaties van dezelfde "is dit uur geblokkeerd"-vraag

1. `availability_filter.dart:49` — `_isHourBlocked()`
2. `week_agenda_screen.dart:71` — `_isBlocked()` (bijna-identieke kopie)
3. `availability_screen.dart:546` — directe `blocked[key]` lookup, zónder normalisatie

Ze zijn uit elkaar gaan lopen (#3 kent de weekdag-normalisatie niet). Elke fix moet
nu op drie plekken, wat precies is hoe A1/A2 konden ontstaan.

### B3. Dedup laat overlappende dubbele slots staan — zichtbaar in de app

`_overlapRatio(a, b)` (`slot_generator.dart:184-192`) deelt door **b's** duur, niet
door die van het kortste slot. De docstring van `dedup()` (regel 114) claimt:

> "Two slots significantly overlap when >50% of the shorter slot's hours are shared."

Dat is niet wat de code doet. `kept.any((p) => _overlapRatio(p, slot) > 0.5)` meet de
fractie van de *kandidaat*. Gevolg: als eerst een kort slot bewaard wordt (hogere
score), en daarna een lang slot langskomt dat dat korte slot volledig bevat, is de
ratio `2/5 = 0.4` → het lange slot blijft óók staan.

**Dit is zichtbaar op de schermfoto van de tester** (`IMG_2991.jpg`): "Wednesday
17:00 – 22:00 · 5u — Perfect" met daaronder "Wednesday 19:00 – 21:00 · 2u — Perfect".
Het tweede venster ligt volledig binnen het eerste.

Dit is ook de oorzaak van de 2 falende tests. Beide asserteren "strengere toleranties
→ minder slots":

- `test/providers/integration_test.dart:228` → `Expected: a value less than <74>, Actual: <104>`
- `test/providers/slots_notifier_test.dart:210` → `Expected: not <5>, Actual: <5>`

Strenger instellen levert dus *méér* voorstellen op. Dat is geen kapotte test — dat is
de app die zich onlogisch gedraagt, en de test die dat correct betrapt.

### B4. Kaartvolgorde op Home is niet stabiel

`home_screen.dart:733`: `slots.sort((a, b) => _tierOrder(a.tier).compareTo(_tierOrder(b.tier)))`.
Dart's `List.sort` is expliciet **niet stabiel**. Binnen dezelfde tier is de volgorde
daarmee ongedefinieerd en kan hij per rebuild wisselen — de tijd-sortering die
`SlotGenerator` erin stopte gaat verloren. Ook inhoudelijk vreemd: een venster van
zaterdag kan boven een venster van vandaag staan, en de "best choice"-badge hangt aan
`index == 0` van die instabiele volgorde.

### B5. Geen enkele afkapping op "nu" — verlopen vensters blijven staan

Er staat nergens in de pipeline een `now`-cutoff. Grep over `lib/domain`, `lib/providers`
en `lib/data` levert alleen `DateTime.now()` op in de cache-TTL en in het opschonen van
geplande ritten — niet in scoring, slot-generatie of filtering.

Open-Meteo levert de hele huidige dag vanaf 00:00. Gevolg: 's avonds staan de ochtend-
en middagvensters van diezelfde dag nog gewoon in de lijst, op Home, in de Agenda en in
de home-screen widget (`filtered.firstOrNull` in `background_task.dart` kan een verlopen
slot zijn). Bekend als backlog #18/#19, maar het raakt meer schermen dan daar vermeld.

---

## C. Data-integriteit

### C1. Een preset-chip wist stilletjes handmatige en agenda-blokken

`seedPreset()` (`availability_notifier.dart:79-82`) doet `_persist(preset)` — het
vervángt de volledige map. Alles wat de gebruiker handmatig blokkeerde en alles wat uit
Google Calendar geïmporteerd is, is weg. Er is geen waarschuwing en geen undo.

Merk op dat `importCalendarBlocks()` (regel 87-100) het wél goed doet: die verwijdert
gericht alleen de bestaande `calendar`-entries en laat work/custom staan.

### C2. Weekdag-normalisatie hangt aan een willekeurige map-entry

`availability_filter.dart:58` en `week_agenda_screen.dart:78` bepalen de referentieweek
via `blockedHours.keys.first`. Dat is de insertion-order van een `LinkedHashMap`, gevuld
in de volgorde waarin SharedPreferences de strings teruggeeft — dus willekeurig. Zodra
er blokken uit meerdere kalenderweken in de map staan (custom uit deze week + een
calendar-import uit volgende week) wordt naar de verkeerde week genormaliseerd.

Daar komt bij dat de huidige normalisatie *alles* wekelijks laat terugkeren. Een
eenmalige agenda-afspraak van dinsdag blokkeert daarmee elke dinsdag, voor altijd.

### C3. Bestaande installs hebben al een vervuilde store

Beta-testers draaien 1.0.5+6 en hebben nu al beide sleutel-smaken in
`availability.blockedHours` staan. `_persist()` schrijft `toIso8601String()`, wat de
smaak bewaart (`...Z` vs. zonder), en `build()` leest dat 1-op-1 terug. Elke fix moet
dus bij het inlezen normaliseren, anders blijven hun bestaande blokken kapot.

### C4. Geplande ritten worden alleen bij app-start opgeschoond

`PlannedRidesNotifier` is `@Riverpod(keepAlive: true)` en filtert verlopen ritten
uitsluitend in `build()` (`planned_rides_notifier.dart:60-65`). In een sessie die over
middernacht heen loopt blijft de rit van gisteren op Home staan.

---

## Voorgestelde aanpak

Volgorde is bewust: 1 lost het grootste deel op en maakt 2-4 pas veilig testbaar.

| # | Fix | Raakt | Effort |
|---|-----|-------|--------|
| 1 | **Eén canonieke sleutel + één gedeelde lookup.** Kies lokale `DateTime(y,m,d,h)` als canoniek (dat is wat Open-Meteo levert en waar alles tegen gescoord wordt). Introduceer één helper-module met `canonicalHourKey()` en `isHourBlocked()`; laat `availability_filter`, `week_agenda_screen` en `availability_screen` daar allemaal doorheen. Normaliseer in `AvailabilityNotifier.build()` bij het inlezen, zodat bestaande installs meteen goed komen. | A1, A2, A4, B2, C2, C3 | M |
| 2 | **Model expliciet maken:** grid = terugkerend weekpatroon (weekdag+uur), Calendar-import = datum-specifiek en verloopt vanzelf. Nu is dat een impliciete bijwerking van de normalisatie. | C2 | S/M |
| 3 | **`seedPreset` laten mergen** i.p.v. vervangen: alleen `work`-entries verversen, `custom` en `calendar` met rust laten. | C1 | S |
| 4 | **Dedup symmetrisch maken** — deel door de duur van het kórtste slot, conform de eigen docstring. Verifieer daarna dat de 2 falende tests groen worden (dat is de bedoelde assertie). | B3 | S |
| 5 | **`now`-cutoff** toevoegen op één plek in de pipeline, zodat Home, Agenda én widget hetzelfde doen. | B5 | S |
| 6 | **Geplande ritten één bron van waarheid geven:** Home laat de actuele score zien, net als Rides. Overweeg tegelijk C4 (opschonen bij datumwissel i.p.v. alleen bij start). | B1, C4 | S |
| 7 | **Notificaties: kiezen.** Óf de drie toggles daadwerkelijk aansluiten op de background task (die berekent het volgende beste slot al — daar is de scheduling-hook), óf ze uit de UI halen tot ze werken. Nu belooft de app iets dat niet gebeurt. | A3 | M (aansluiten) / S (verbergen) |
| 8 | **Stabiele sortering op Home:** sorteer op `(tier, start)` i.p.v. alleen tier. | B4 | XS |

Fixes 1-3 zijn de "edit my schedule"-opdracht. 4-8 zijn losse, onafhankelijke items.

---

*Opgesteld: 2026-07-25*
