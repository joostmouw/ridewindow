---
phase: 34-groep-maken-en-beheren
plan: 05
subsystem: peloton-ui
tags: [flutter, riverpod, clubs, groups, l10n, admin]
requires:
  - "34-03: gateway (setGroupMemberRole, removeGroupMember, acceptGroupRequest, deleteGroupRequest, proposeGroupMember), groupErrorTextOf, FakeGroupGateway"
  - "34-04: GroupScreen met _MemberRow.trailingAction, SectionCard.action, GroupsSection, AppIcons.dotsThreeVertical/userPlus"
provides:
  - "⋮ per lid voor beheerders: Beheerder maken / Beheerder af / Uit de groep halen"
  - "Uitgestelde verwijdering met echte ongedaan maken (_pendingRemovals, SnackBarClosedReason.action)"
  - "Sectie Aanvragen boven Leden (alleen beheerders) met Accepteren/Afwijzen"
  - "showGroupProposeSheet (group_propose_sheet.dart): lid draagt voor, beheerder voegt toe"
  - "Tellerchip 'N aanvragen' op de groepskaart voor beheerders"
affects: [34-06, 34-08]
tech-stack:
  added: []
  patterns:
    - "ProviderContainer, gateway en messenger vóór de eerste await pakken; invalidate via de container zodat het na sluiten van het scherm niet gooit"
    - "Busy-set als veld (niet alleen knopstaat): twee tikken vóór de volgende frame doen niets dubbel; na succes blijft het id in de set"
    - "Uitkomst van een actie in een sheet als banner in de sheet, niet als snackbar erachter"
key-files:
  created:
    - lib/features/peloton/group_propose_sheet.dart
    - test/features/group_members_admin_test.dart
    - test/features/group_requests_test.dart
  modified:
    - lib/features/peloton/group_screen.dart
    - lib/features/peloton/groups_section.dart
    - lib/l10n/app_nl.arb
    - lib/l10n/app_en.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_nl.dart
    - lib/l10n/app_localizations_en.dart
decisions:
  - "34-05: eruit halen pas na sluiten snackbar; ongedaan maken verstuurt niets (opnieuw toevoegen zou joined_at en rol resetten)"
  - "34-05: aanvraagrij met knoppen onder de naam in een Wrap; naast elkaar past niet op 360 dp"
  - "34-05: na geslaagd accepteren/afwijzen blijft het aanvraag-id bezet, zodat een tweede tik niets doet"
metrics:
  duration: 30min
  completed: 2026-09-24
  tasks: 2
  files: 10
---

# Phase 34 Plan 05: Ledenbeheer, aanvragen en voordragen Summary

Een beheerder beheert nu vanaf het groepsscherm leden, rollen en aanvragen. Een gewoon lid kan een maatje voordragen en ziet verder een rustig scherm.

## Wat er staat

- **⋮ per lid** (taak 1, CLUB-07, CLUB-08): alleen een beheerder ziet achter elk lid een `PopupMenuButton` met `AppIcons.dotsThreeVertical` en de tooltip "Opties voor dit lid".
  - Achter een gewoon lid staan "Beheerder maken" en "Uit de groep halen". Achter een andere beheerder staan "Beheerder af" en "Uit de groep halen". Achter jezelf staat alleen "Beheerder af".
  - Ben je de enige beheerder en wil je jezelf degraderen, dan komt de zin van `groupErrorLastAdmin` en gaat er niets naar de gateway. Weigert de database met `last_admin` (race), dan komt dezelfde zin via `groupErrorTextOf`.
- **Uit de groep halen met echte ongedaan maken**: het lid verdwijnt meteen uit de lijst en uit het ledental (`_pendingRemovals`). Daarna staat er een snackbar "<naam> is uit de groep gehaald" met "Ongedaan maken".
  - Pas als de snackbar sluit zonder ongedaan maken, gaat `removeGroupMember` naar de database. De set wordt pas vrijgegeven als de verse lijst binnen is, zodat het lid niet even terugknippert.
  - Mislukt de verwijdering, dan komt het lid terug met de foutzin. Gateway, container en messenger worden vooraf gepakt, dus de verwijdering gaat ook door als het scherm intussen dicht is. Een doccomment legt uit waarom het uitgesteld moet.
- **Sectie Aanvragen** (taak 2, CLUB-27): alleen een beheerder die open aanvragen heeft ziet deze sectie, direct onder de hero en boven Leden.
  - Per aanvraag: naam, "via de groepslink" of "voorgedragen door X", en daaronder Afwijzen en Accepteren.
  - Een fout geeft een zin met de groepsnaam (bij `group_full`) of de naam van de aanvrager (bij `too_many_groups`).
- **Maatje voordragen / toevoegen** (CLUB-03 herzien): de sectiekop Leden heeft voor ieder lid een knop. Voor een gewoon lid heet die "Maatje voordragen", voor een beheerder "Maatje toevoegen". De knop opent `showGroupProposeSheet`.
  - De sheet volgt `friendsProvider` en `pelotonGroupProvider(groupId)` live. Wie al lid is krijgt "al lid" en wie al een aanvraag heeft "aanvraag loopt", allebei zonder knop. De rest krijgt Voordragen of Toevoegen.
  - De uitkomst of fout staat als banner in de sheet: `secondaryContainer` bij succes, `errorContainer` bij een fout, zodat het in licht en donker klopt. Is de groep vol, dan staat die banner bovenaan en zijn er geen knoppen. Zonder maatjes legt de sheet uit hoe je er een uitnodigt.
- **Teller op de groepskaart**: bij een groep waar jij beheerder bent en waar aanvragen openstaan, staat naast de chip "beheerder" een chip "N aanvragen" (`tertiaryContainer`/`onTertiaryContainer`, meervoud via ICU).

## Verificatie

- `flutter test`: **798 -> 825** geslaagd (+10 in `group_members_admin_test.dart`, +17 in `group_requests_test.dart`).
- `flutter analyze`: 0 errors, 0 warnings, 200 info-meldingen (net als na 34-04). Geen daarvan zit in een bestand van dit plan.
- Acceptatie-greps:
  - `group_screen.dart`: `SnackBarClosedReason.action` 1x, `_pendingRemovals` 8x, `AppIcons.dotsThreeVertical` 1x, `acceptGroupRequest(` 1x, `deleteGroupRequest(` 2x (intrekken plus afwijzen).
  - `group_propose_sheet.dart`: `proposeGroupMember(` 1x, `friendsProvider` 2x.
  - `groups_section.dart`: `groupOpenRequests` 1x.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Aanvraagrij liep over de rand**
- **Found during:** Taak 2
- **Issue:** avatar, naam en twee knoppen op één regel liepen over de rand, zelfs op 432 dp.
- **Fix:** naam en herkomst staan nu boven en de knoppen eronder in een `Wrap` (rechts uitgelijnd). Een extra test op 360 dp controleert dat de aanvragen en de sheet passen.
- **Commit:** e38e047

**2. [Rule 1 - Bug] Dubbel tikken op Accepteren**
- **Found during:** Taak 2
- **Issue:** de fake is zo snel dat de eerste aanroep al klaar was vóór de tweede tik, en die tweede tik kwam nog op de oude knop. Met een traag netwerk kan dat ook echt gebeuren.
- **Fix:** het aanvraag-id wordt alleen vrijgegeven als er een fout is. Na succes is de aanvraag weg en doet een tweede tik niets meer.
- **Commit:** e38e047

**3. [Rule 1 - Bug] invalidate na sluiten van het scherm**
- **Found during:** Taak 1
- **Issue:** `ref.invalidate` na een await gooit als het scherm intussen dicht is. De catch zou dan de generieke foutzin tonen, terwijl de actie gewoon gelukt was.
- **Fix:** rol wijzigen, accepteren, afwijzen en voordragen gebruiken nu een vooraf gepakte `ProviderContainer`.
- **Commit:** bd4e776, e38e047

Verder: in de EN-ARB staat de `@`-metadata ook bij de nieuwe sleutels, net als bij de bestaande. `dart format` heeft even `buddies_tab.dart` en `invite_buddies_sheet.dart` aangeraakt; die wijzigingen zijn teruggedraaid en zitten niet in een commit.

## TDD Gate Compliance

- Taak 1: `test(34-05)` f5f2ebd -> `feat(34-05)` bd4e776
- Taak 2: `test(34-05)` d0489a3 -> `feat(34-05)` e38e047

## Known Stubs

Geen. `_MemberRow.trailingAction` is nu gevuld voor beheerders.

## Niet gedaan

- Nog niet op de Oppo bekeken in licht en donker. Alle kleuren komen uit colorScheme-paren (errorContainer/onErrorContainer, secondaryContainer/onSecondaryContainer, tertiaryContainer/onTertiaryContainer, error), die in beide helderheden bij elkaar horen. De visuele check via adb blijft over voor wanneer 34-06 er ook staat (34-08).

## Threat Flags

Geen nieuwe oppervlakte. T-34-18: de UI verbergt alleen, de database weigert (0012/0013, bewezen in 34-02), en een test bewijst dat een gewoon lid geen ⋮ en geen Aanvragen ziet. T-34-19: wordt de app hard gesloten terwijl de snackbar nog staat, dan blijft het lid gewoon lid. Dat zie je na verversen. T-34-20: namen komen uit de database.

## Self-Check: PASSED

- `group_propose_sheet.dart`, `group_members_admin_test.dart` en `group_requests_test.dart` staan op schijf.
- Commits f5f2ebd, bd4e776, d0489a3 en e38e047 staan in `git log`.
