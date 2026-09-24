---
phase: 35-groepsritten
plan: 04
subsystem: ritdetail
tags: [clubs, groepsritten, ritdetail, 360dp, peloton]
requires:
  - 35-01 (RideEntry.pelotonGroup, tellingen per lid, respondToSharedRide, FakeGroupGateway met ritten)
  - 35-03 (antwoorden via respondToSharedRide op de kaart, Wrap-les)
provides:
  - DetailArgs.groupRideId en RideDetailScreen.groupRideId (Home en Ritten-tab geven het mee)
  - antwoorden op het detail via respondToSharedRide
  - groepschip, ledenlijst met drie statussen en telregel op het detail van een groepsrit
  - per venster de namen van wie kan (groeps- en gewone ritten)
affects:
  - 35-06 (toestelcheck: detail van een groepsrit in licht en donker)
tech-stack:
  added: []
  patterns:
    - "Detail zoekt eerst op rit-id, daarna op tijdvak"
    - "Naam en status in een Wrap(spaceBetween): rechts als het past, eronder als het niet past"
    - "Overflowtest per kaart: alleen RenderFlex-fouten binnen ValueKey('peloton-card') tellen"
key-files:
  created:
    - test/features/group_ride_detail_test.dart
  modified:
    - lib/features/detail/detail_args.dart
    - lib/app/router.dart
    - lib/features/detail/ride_detail_screen.dart
    - lib/features/home/home_screen.dart
    - lib/features/planned/planned_rides_screen.dart
    - lib/l10n/app_nl.arb
    - lib/l10n/app_en.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_nl.dart
    - lib/l10n/app_localizations_en.dart
decisions:
  - "35-04: detail zoekt eerst op rit-id, anders op tijdvak"
  - "35-04: ledenlijst uit de groep, ex-leden niet getoond"
  - "35-04: naam en status in een Wrap, knoppen in een Wrap"
metrics:
  duration: 30min
  completed: 2026-09-24
  tasks: 2
  files: 11
---

# Phase 35 Plan 04: Wie komt er, op het ritdetail Summary

Het ritdetail van een groepsrit toont nu:

- de groep als chip bovenaan (kenteken en naam; een tik opent het groepsscherm);
- een rij per huidig lid met "gaat mee", "kan niet" of "nog geen antwoord", waarbij de organisator als "gaat mee" telt en jij "(jij)" achter je naam krijgt;
- een telregel als "2 gaan mee · 1 kan niet · 2 nog niet".

Heeft een rit meer dan één venster, dan staat per venster wie er kan, met namen. Dat geldt ook voor gewone gedeelde ritten.

"Ik ga mee", "Kan niet", "Toch niet" (met ongedaan maken) en "Toch meegaan" werken nu ook op het detail van een groepsrit. Tikte je een rit aan terwijl er een tweede gedeelde rit op hetzelfde tijdvak staat, dan opent precies die rit.

## Wat er gebouwd is

**Task 1: rit-id naar het detail, antwoorden via respondToSharedRide (RED 74bae94, GREEN 340d99b)**
- `DetailArgs.groupRideId` (optioneel, met doccomment). `RideDetailScreen` heeft dezelfde parameter en router.dart geeft hem door.
- `_pelotonEntry` zoekt eerst de gedeelde entry met `group?.id == groupRideId`. Staat die er niet (meer), dan gaat het op tijdvak zoals voorheen.
- `_respondToRide` roept `respondToSharedRide(gateway, group, accepted:, myName:)` aan. De gateway en de profielnaam worden vóór de await opgehaald. De `_isLoading`-bewaking en het foutpad zijn niet veranderd.
- Home (`_openPlannedRideDetail`) en `RideCard._openDetail` geven het rit-id mee. De andere aanroepers van DetailArgs (tijdvakken, agenda) zijn niet aangepast.

**Task 2: chip, ledenlijst, telregel, vensters (RED 5e382ea, GREEN 42eced9)**
- `_buildGroupChip`: een `ActionChip` met `GroupCrest(size: 20)`. De naam is één regel met ellips en is hooguit de kaartbreedte min 48 breed. Tooltip "Groep openen". Een tik gaat naar `/peloton/group/<id>`.
- `_groupTally`: "gaan mee" staat er altijd. "kan niet" en "nog niet" alleen als het aantal groter is dan 0.
- `_buildGroupMemberRows`: de rijen komen uit `pelotonGroup.members`, niet uit de deelnemers. De volgorde is organisator, gaat mee, kan niet, nog geen antwoord. Binnen elke groep blijft de volgorde van de ledenlijst. Rijen van ex-leden worden niet getoond (T-35-10).
- `_buildPersonRow` is één rijwidget voor gewone en groepsritten. De statuskleur komt uit de tokens: gaat mee `rw.scorePerfect`, kan niet `colorScheme.error`, nog niet `rw.textTertiary`. Naam en status staan in een `Wrap(spaceBetween)`, zodat de status onder de naam komt als de regel niet past.
- `_buildOptionVoters`: bij `hasOpenChoice` toont dit per optie de dag en tijd (`EEE d MMM  HH:mm – HH:mm`, zoals `_WindowPicker`). Daaronder staan de namen van wie ja stemde (maxLines 2, ellips), of "Nog niemand". Namen komen uit de ledenlijst, of van de organisator of de deelnemers.
- Vijf ARB-sleutels in NL en EN met metadata; `flutter gen-l10n` gedraaid.
- Een gewone gedeelde rit ziet er uit zoals eerst (geen chip en geen telregel). Alleen de statuskleuren zijn nieuw. Een groepsrit waarvan de groep onbekend is, toont de deelnemerslijst zonder chip.

## Verificatie

- `group_ride_detail_test.dart`: 25 tests. Ze dekken:
  - welke rit het detail opent: r1, r2, zonder id, en een id dat niet bestaat;
  - accepteren, weigeren, afzeggen met ongedaan maken, en toch meegaan, allemaal via `respondToGroupRide`;
  - dat de Ritten-tab `groupRideId` meegeeft;
  - de chip, de rijen met drie statussen, de volgorde en de telregel;
  - het weglaten van nullen in de telregel en het verbergen van ex-leden;
  - de rij "(jij)" als je niet de organisator bent, en de tik op de chip;
  - de statuskleuren in licht en donker;
  - een gewone rit, en een groepsrit met een onbekende groep;
  - de vensters bij een groeps- en een gewone rit;
  - 360 dp met lange namen (40 tekens groep, 30 tekens lid) bij tekstschaal 1.0 donker, 1.3 en 2.0, zowel als organisator als met de antwoordknoppen.
- De 360-dp-test telt alleen overflowfouten binnen `ValueKey('peloton-card')`. Een mutatiecheck (de Wrap in de rij teruggezet naar een Row) liet alle vijf de 360-dp-tests falen. De test vangt dus echt wat hij moet vangen.
- Volledige `flutter test`: **953 geslaagd** (dat waren er 928 na 35-03; 25 zijn nieuw).
- `flutter analyze`: 0 errors, 0 warnings, 198 infos, gelijk aan 35-03. Er komen geen infos bij in de bestanden van dit plan.
- `git diff --stat lib/platform/ supabase/` is leeg. Er is geen dart format over hele bestanden gedraaid. In home_screen.dart en planned_rides_screen.dart is alleen de ene aanroep aangepast.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Antwoordknoppen op het detail in een Wrap**
- **Found during:** Task 2 (360-dp-test met r2 als pending)
- **Issue:** "Kan niet" en "Ik ga mee" stonden in een Row. Dat is dezelfde overloop die 35-03 op de ritkaart vond bij tekstschaal 1.3 en 2.0.
- **Fix:** een `Wrap(alignment: end, spacing: 8)` binnen `SizedBox(width: double.infinity)`, zoals op de ritkaart.
- **Files modified:** lib/features/detail/ride_detail_screen.dart
- **Commit:** 42eced9

**2. [Rule 1 - Bug] Naam en status in een Wrap in plaats van naast elkaar in een Row**
- **Found during:** Task 2
- **Issue:** de status stond als niet-flexibele Text rechts in de Row. Met "nog geen antwoord" en tekstschaal 2.0 past dat niet op 360 dp.
- **Fix:** `Wrap(spaceBetween)` in de Expanded: de status staat rechts als het past en onder de naam als het niet past. De naam is één regel met ellips.

**3. Home gebruikt `ride.group?.id`, niet `entry.group?.id`**
- In `_openPlannedRideDetail(RideEntry ride)` heet de variabele `ride`. De grep uit de acceptatiecriteria (`groupRideId: entry.group?.id`) geeft daardoor 0 in home_screen.dart en 1 in planned_rides_screen.dart. De key_link-patroon `groupRideId: ` klopt in beide bestanden. De parameter is niet hernoemd, om de diff klein te houden.

**4. Testharnas zonder `package:riverpod`-import**
- `List<Override>` vroeg een import uit `riverpod/misc.dart`, en dat gaf een `depend_on_referenced_packages`-info. Daarom een helper `_scope(fake, child)` die de ProviderScope zelf bouwt.

## Opmerking voor de toestelcheck (35-06)

- Op het detail van een groepsrit staan nu twee samenvattingen onder elkaar: de PelotonCounter ("2 gaan mee · 2 wachten nog", met fietsjes) en de nieuwe telregel ("2 gaan mee · 1 kan niet · 2 nog niet"). Het plan vraagt dat zo. Op het toestel bekijken of dat dubbel voelt. Zo ja, dan kan de tekst van de counter op een groepsrit weg en blijven alleen de fietsjes staan.
- Contrast van `rw.scorePerfect` (#66BB6A donker, #2E7D32 licht) en `colorScheme.error` in bodySmall, in beide helderheden meten via adb.

## TDD Gate Compliance

Beide taken hebben een aparte RED-commit (test) en GREEN-commit (feat): 74bae94 → 340d99b en 5e382ea → 42eced9. In RED faalde Task 1 op compilatie (de parameter bestond nog niet). Bij Task 2 faalden 14 van de 16 nieuwe tests. De twee die al slaagden (gewone rit, onbekende groep) bewaken dat de kaart daar niet verandert.

## Requirements

CLUB-14, CLUB-15 en CLUB-16 zijn op het detail geregeld, maar nog niet afgevinkt. De teller (05) en de toestelcheck (06) volgen nog.

## Known Stubs

Geen.

## Self-Check: PASSED
