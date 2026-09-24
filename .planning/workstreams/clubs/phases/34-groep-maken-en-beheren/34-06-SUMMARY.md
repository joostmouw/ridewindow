---
phase: 34-groep-maken-en-beheren
plan: 06
subsystem: peloton-ui
tags: [flutter, riverpod, clubs, groups, l10n, share, dialogs]
requires:
  - "34-03: gateway (groupInviteCode, replaceGroupInvite, renameGroup, leaveGroup, deleteGroup), groupErrorTextOf, FakeGroupGateway"
  - "34-04: GroupScreen, showGroupNameSheet"
  - "34-05: GroupScreen met ledenbeheer en aanvragen"
provides:
  - "group_link.dart: kGroupLinkBase + groupLinkFor(code)"
  - "group_dialogs.dart: showLeaveGroupDialog, showDisbandGroupDialog"
  - "Deel de groepslink in de hero voor ieder lid"
  - "Appbar-⋮ op het groepsscherm: Naam wijzigen, Link vervangen, Groep verlaten, Groep opheffen (beheerder) / Groep verlaten (lid)"
affects: [34-07, 34-08, 35]
tech-stack:
  added: []
  patterns:
    - "Bevestiging zonder ongedaan maken als er geen weg terug is (verlaten), met de gevolgen in de dialoogtekst"
    - "Na een handeling die het scherm sluit: messenger, router en container vóór de eerste await"
key-files:
  created:
    - lib/features/peloton/group_link.dart
    - lib/features/peloton/group_dialogs.dart
    - test/features/group_menu_test.dart
  modified:
    - lib/features/peloton/group_screen.dart
    - lib/l10n/app_nl.arb
    - lib/l10n/app_en.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_nl.dart
    - lib/l10n/app_localizations_en.dart
    - test/features/group_members_admin_test.dart
decisions:
  - "34-06: verlaten = bevestiging zonder ongedaan maken; terugkomen is een nieuwe aanvraag"
  - "34-06: dezelfde naam opslaan verstuurt niets; hernoemen geeft geen snackbar, de appbar toont de nieuwe naam"
  - "34-06: aanvrager krijgt geen appbar-menu; intrekken staat al op het scherm"
metrics:
  duration: 25min
  completed: 2026-09-24
  tasks: 2
  files: 10
---

# Phase 34 Plan 06: Groepslink en appbar-menu Summary

Ieder lid deelt nu de groepslink vanuit de hero. Een beheerder hernoemt de groep, vervangt de link en heft de groep op vanuit het appbar-menu. Verlaten en opheffen zeggen vooraf in gewone taal wat er gebeurt.

## Wat er staat

- **Deel de groepslink** (taak 1, CLUB-02 deel "delen"): een volle-breedte `FilledButton.tonalIcon` met `AppIcons.shareNetwork` onder het ledental. Leden en beheerders zien hem, wie alleen een aanvraag heeft niet.
  - Het deelmenu krijgt tekst, link en code: "Fiets mee met {groep} in Ridewindow: https://my-project-joost.web.app/#/group/{code} ... Of vul code {code} in ... Een beheerder van de groep laat je erin."
  - Analytics: alleen `{'kind': 'group_link_created'}`, nooit de code, de naam of het id (T-34-22).
  - `group_link.dart` heeft `kGroupLinkBase` met een doccomment. Die verwijst naar `kInviteLinkBase` (zelfde domein, zelfde `/#/`) en zegt dat de live PWA `/group` pas kent na de uitrol in fase 36.
- **Appbar-⋮** (tooltip "Groepsopties"): een beheerder ziet Naam wijzigen, Link vervangen, Groep verlaten en Groep opheffen, in die volgorde. Opheffen staat in `colorScheme.error`. Een gewoon lid ziet alleen Groep verlaten, een aanvrager ziet geen menu.
  - **Link vervangen** (CLUB-09): `replaceGroupInvite`, daarna een snackbar "Nieuwe link gemaakt. De oude werkt niet meer." met de actie Delen. Die deelt de nieuwe code zonder een tweede aanroep naar de server.
  - **Naam wijzigen** (CLUB-09): dezelfde sheet als maken (max 40, teller) met de huidige naam al ingevuld en de knop Opslaan. Sla je dezelfde naam op, dan gaat er niets naar de server.
  - **Groep verlaten** (CLUB-06): eerst een bevestiging. De tekst hangt af van de situatie:
    - Gewoon lid: "Terugkomen gaat met een nieuwe aanvraag."
    - Enige beheerder: de dialoog noemt het langst zittende lid als nieuwe beheerder (`successorIfLeaving`).
    - Laatste lid: "De groep en de link verdwijnen dan."
    - Daarna worden groepen en groepsritten ververst, het scherm gaat terug en er komt een snackbar "{groep} verlaten".
  - **Groep opheffen** (CLUB-11): de bevestiging noemt het ledental (meervoud via ICU), zegt dat ritten met antwoorden blijven zonder groepslabel en dat je het niet kunt terugdraaien. Daarna verversen, terug, en een snackbar "{groep} is opgeheven".
- In `group_dialogs.dart` legt een doccomment de keuze vast: verlaten krijgt een bevestiging zonder ongedaan maken, opheffen een bevestiging, en eruit halen ongedaan maken (plan 05). Beide dialogen poppen met hun eigen `dialogContext`.

## Verificatie

- `flutter test`: **825 -> 841** geslaagd (+16 in `group_menu_test.dart`).
- `flutter analyze`: 0 errors, 0 warnings, 200 info-meldingen, net als na 34-05. Geen daarvan zit in een bestand van dit plan.
- Acceptatie-greps:
  - `group_link.dart`: `kGroupLinkBase = 'https://my-project-joost.web.app/#/group'` 1x.
  - `group_screen.dart`: `groupLinkFor(` 2x, `'kind': 'group_link_created'` 1x, `leaveGroup(|deleteGroup(|renameGroup(|replaceGroupInvite(` 4x, `groupRidesProvider` 1x.
  - `group_dialogs.dart`: beide `Future<bool>`-functies staan erin.
- Er staat geen em-dash in de nieuwe ARB-teksten.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Bestaande test zag het nieuwe appbar-⋮ als lidmenu**
- **Found during:** Taak 1
- **Issue:** `group_members_admin_test.dart` "gewoon lid: geen ⋮ in de ledenlijst" zocht `AppIcons.dotsThreeVertical` in het hele scherm. Het appbar-menu voor ieder lid is bewust, dus die test faalde.
- **Fix:** de test kijkt nu alleen in de ledenrijen en naar de tooltip "Opties voor dit lid". De bedoeling van de test blijft hetzelfde.
- **Commit:** c52d5f3

Verder zijn er drie extra tests bovenop de behavior-lijst: een aanvrager heeft geen menu, dezelfde naam opslaan doet niets, en een mislukte opheffing laat het scherm staan met de foutzin.

## TDD Gate Compliance

- Taak 1: `test(34-06)` 349127f -> `feat(34-06)` c52d5f3
- Taak 2: `test(34-06)` f4cbc36 -> `feat(34-06)` a9900ee

## Known Stubs

Geen. De landing `/group/:code` komt in 34-07. Tot dan (en op de live PWA tot fase 36) opent een gedeelde groepslink de app, maar niet de landing. De code in de deeltekst geeft wie de link krijgt alvast een route.

## Niet gedaan

- Nog niet op de Oppo bekeken in licht en donker. Alle kleuren komen uit colorScheme (`error` voor Opheffen en de bevestigknoppen, tonal voor de deelknop). De visuele check via adb staat voor 34-08.
- CLUB-02 staat nog open, want de landing die een aanvraag maakt komt in 34-07. CLUB-06, CLUB-09 en CLUB-11 zijn afgevinkt.

## Threat Flags

Geen nieuwe oppervlakte:
- T-34-21: de link geeft alleen een aanvraag, en vervangen trekt alle oude codes in.
- T-34-22: de analytics bevatten alleen `kind`.
- T-34-23: een bevestiging met de gevolgen erin.
- T-34-24: een gewoon lid ziet het beheerdersmenu niet (getest), en RLS weigert de handeling toch.

## Self-Check: PASSED

- `group_link.dart`, `group_dialogs.dart` en `group_menu_test.dart` staan op schijf.
- Commits 349127f, c52d5f3, f4cbc36 en a9900ee staan in `git log`.
