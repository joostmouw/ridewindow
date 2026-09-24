---
phase: 34-groep-maken-en-beheren
plan: 04
subsystem: peloton-ui
tags: [flutter, riverpod, go_router, clubs, groups, l10n]
requires:
  - "34-03: modellen, gateway, providers, groupErrorTextOf, FakeGroupGateway"
provides:
  - "GroupsSection bovenaan BuddiesTab: kaarten, lege staat, aanvraagkaarten, + Nieuwe groep, info-knop"
  - "GroupScreen(groupId) op /peloton/group/:groupId: hero, ledenlijst, aanvraagstaat, niet-gevonden-staat"
  - "GroupCrest + GroupAdminChip (group_crest.dart), showGroupNameSheet, showGroupRulesSheet + GroupRulesButton"
  - "SectionCard.action (optioneel, rechts in de kop)"
  - "AppIcons: arrowsCounterClockwise, crown, dotsThreeVertical, linkSimple, pencilSimple, signOut"
affects: [34-05, 34-06, 34-07]
tech-stack:
  added: []
  patterns:
    - "messenger en router vóór de eerste await pakken, daarna pas sheet/gateway"
    - "sheets poppen met hun eigen context (shell-navigator-valkuil)"
    - "vaste merkkleur-achtergrond => vaste voorgrond (GroupCrest)"
key-files:
  created:
    - lib/features/peloton/group_crest.dart
    - lib/features/peloton/group_name_sheet.dart
    - lib/features/peloton/group_rules_sheet.dart
    - lib/features/peloton/groups_section.dart
    - lib/features/peloton/group_screen.dart
    - test/features/group_widgets_test.dart
    - test/features/peloton_groups_section_test.dart
    - test/features/group_screen_test.dart
  modified:
    - lib/theme/app_icons.dart
    - lib/features/shared/section_card.dart
    - lib/features/peloton/buddies_tab.dart
    - lib/app/router.dart
    - lib/l10n/app_nl.arb
    - lib/l10n/app_en.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_nl.dart
    - lib/l10n/app_localizations_en.dart
decisions:
  - "34-04: 10-groepengrens al in de UI vóór de sheet; database toetst daarna nog steeds"
  - "34-04: GroupAdminChip al in taak 2 in group_crest.dart, zodat tab en scherm vanaf het begin dezelfde chip delen"
  - "34-04: groepsscherm sorteert leden niet opnieuw; de volgorde komt uit PelotonGroup.fromRows"
metrics:
  duration: 35min
  completed: 2026-09-24
  tasks: 3
  files: 17
---

# Phase 34 Plan 04: Groepen zichtbaar op Peloton en het groepsscherm Summary

Ingelogd staat er nu een sectie Groepen boven Maatjes op de Peloton-tab. Elke groep krijgt een kaart met kenteken, naam, "N leden" en de chip "beheerder"; groepen met een lopende aanvraag staan eronder als "aanvraag loopt". Zonder groepen staat er de kaart "Fiets je met een vaste club?". Een groep maak je via een sheet met een naamveld (max 40, teller), en daarna kom je op het groepsscherm (`/peloton/group/:groupId`). Dat scherm toont de groep in leesstand: hero, leden met "(jij)" en de beheerder-chip, de aanvraagstaat waarin je je aanvraag kunt intrekken, en de info-knop met de zeven groepsregels (CLUB-28).

## Wat er staat

- **Bouwstenen** (taak 1): `GroupCrest` gebruikt brandLight met brandDark erop, en in donker precies omgekeerd. `showGroupNameSheet` heeft autofocus en `maxLength: kGroupNameMaxLength`, trimt de naam en zet de knop uit bij een lege naam. Via `initialName` is hij klaar voor hernoemen in plan 06. `showGroupRulesSheet` + `GroupRulesButton` volgen het bestaande info-knoppatroon (48x48, onSurfaceVariant, tooltip). `SectionCard` kreeg een optionele `action`; zonder action verandert er niets aan bestaande schermen. Zes Phosphor-codepunten staan klaar voor plannen 05/06.
- **Sectie Groepen** (taak 2): `GroupsSection` is het eerste kind in de ListView van `BuddiesTab`, en `_invalidateAll` ververst nu ook `visibleGroupsProvider`. Maken loopt zo: eerst de 10-groepengrens checken (dan een snackbar, geen sheet), dan de sheet, dan `createGroup`, invalidate, `trackEvent(kEvPelotonInvite, {'kind': 'group_created'})` (zonder naam of id) en `push` naar het groepsscherm. Een fout wordt via `groupErrorTextOf` een snackbar. Uitgelogd blijft de bestaande uitgelogde staat staan en wordt de gateway niet aangeroepen.
- **Groepsscherm** (taak 3): `GroupScreen` heeft `SafeBackButton(fallbackRoute: '/rides')` en `GroupRulesButton` in de appbar. Per lid staat er alleen een avatar met de eerste letter, de naam (of "Fietser") en de chip (CLUB-05). `_MemberRow.trailingAction` is de plek voor het ⋮-menu van plan 05. In de aanvraagstaat roept intrekken `deleteGroupRequest` aan; daarna gaat het scherm terug (of naar `/rides`) met de snackbar "Aanvraag ingetrokken". Is de groep onbekend, dan zie je een uitleg en de knop "Naar Peloton". De route staat buiten de shell en gebruikt `_slideUpTransition`.

## Verificatie

- `flutter test`: **776 -> 798** geslaagd (+6 bouwstenen, +10 sectie, +6 groepsscherm).
- `flutter analyze`: 0 errors, 0 warnings. Het totaal staat op 200 info-meldingen, net als na 34-03, en geen daarvan zit in een bestand van dit plan.
- `back_affordance_test`, `no_em_dash_test` en `profile_screen_test` (bestaande SectionCard) zijn groen, net als `peloton_withdraw_test` en `peloton_options_test`.
- Acceptatie-greps: 6 iconen, `Widget? action` 1x, `maxLength: kGroupNameMaxLength` 1x, route 1x, `SafeBackButton(` 1x, `GroupRulesButton()` 1x in zowel sectie als scherm, 0 keer e-mail in group_screen, `GroupsSection()` op regel 137 vóór `pelotonFriends` op regel 139. `"groupRule` telt 8 per ARB: de 7 regels plus `groupRulesTitle`, die ook op het patroon past.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] GroupAdminChip eerder aangemaakt dan gepland**
- **Found during:** Taak 2
- **Issue:** volgens het plan zou de chip pas in taak 3 in `group_crest.dart` komen, maar de groepskaarten in taak 2 hadden hem al nodig.
- **Fix:** de chip meteen in taak 2 in `group_crest.dart` gezet. Tab en scherm gebruiken dezelfde widget, zoals het plan bedoelde.
- **Commit:** 5c322cf

**2. [Rule 1 - Bug] Dubbele keys in de regelsheet**
- **Found during:** Taak 1
- **Issue:** zeven regelrijen met dezelfde `ValueKey('group-rule')` gaven een assert "Duplicate keys found".
- **Fix:** de keys zijn nu `group-rule-$i` en de test zoekt op het voorvoegsel.
- **Commit:** db4fc7f

Verder niets bijzonders. Er zijn geen .g.dart-bestanden geregenereerd; `dart format` liep alleen over de bestanden van dit plan, en de diff in `buddies_tab.dart` bestaat alleen uit toevoegingen.

## TDD Gate Compliance

- Taak 1: `test(34-04)` cd3a104 -> `feat(34-04)` db4fc7f
- Taak 2: `test(34-04)` e41a6fa -> `feat(34-04)` 5c322cf
- Taak 3: `test(34-04)` 7dfa3bf -> `feat(34-04)` 91d589f

## Known Stubs

- `_MemberRow.trailingAction` in `group_screen.dart` is altijd null. Dat is bewust: plan 05 zet hier het ⋮-menu per lid. Beheerknoppen, het appbar-menu en de groepslink komen in plannen 05 en 06; het plan vraagt hier alleen de leesstand.

## Niet gedaan

- Nog niet op de Oppo bekeken in licht en donker. De kleuren zijn wel in tests vastgelegd (crest) of komen uit theme-tokens (chip, tekst). Een visuele check via adb blijft over voor wanneer 34-05/06 er ook staan.

## Threat Flags

Geen nieuwe oppervlakte. T-34-15: het scherm toont per lid alleen label en rol. T-34-16: bij groep maken gaat alleen `{'kind': 'group_created'}` mee als analytics.

## Self-Check: PASSED

- Alle aangemaakte bestanden staan op schijf.
- Commits cd3a104, db4fc7f, e41a6fa, 5c322cf, 7dfa3bf en 91d589f staan in `git log`.
