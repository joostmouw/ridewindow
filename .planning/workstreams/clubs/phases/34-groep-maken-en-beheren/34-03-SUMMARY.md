---
phase: 34-groep-maken-en-beheren
plan: 03
subsystem: peloton-datalaag
tags: [flutter, riverpod, supabase, clubs, groups, l10n]
requires:
  - "0012_groups.sql + 0013_group_join_requests.sql (live, 34-02)"
provides:
  - "lib/domain/models/peloton_group.dart: PelotonGroup, GroupMember, GroupJoinRequest, GroupRole, GroupJoinStatus, GroupError, GroupException, groupInitials, grensconstanten"
  - "PelotonGateway: listGroups, createGroup, renameGroup, deleteGroup, setGroupMemberRole, removeGroupMember, leaveGroup, proposeGroupMember, acceptGroupRequest, deleteGroupRequest, groupInviteCode, replaceGroupInvite, redeemGroupInvite"
  - "providers: visibleGroupsProvider, myGroupsProvider, myPendingGroupsProvider, pelotonGroupProvider(groupId)"
  - "groupErrorText / groupErrorTextOf + 13 groupError-teksten NL/EN"
  - "test/helpers/fake_group_gateway.dart: FakeGroupGateway voor de widgettests van 34-04..07"
affects: [34-04, 34-05, 34-06, 34-07]
tech-stack:
  added: []
  patterns:
    - "_guard: PostgrestException -> GroupException via GroupError.fromPostgres, onbekend -> rethrow"
    - "listGroups in drie vaste rondgangen met expliciete kolommen"
    - "afgeleide providers uit visibleGroups, geen tweede netwerkronde"
key-files:
  created:
    - lib/domain/models/peloton_group.dart
    - lib/features/peloton/group_error_text.dart
    - test/helpers/fake_group_gateway.dart
    - test/domain/models/peloton_group_test.dart
    - test/providers/peloton_groups_providers_test.dart
    - test/features/group_error_text_test.dart
  modified:
    - lib/data/remote/supabase_tables.dart
    - lib/services/peloton_gateway.dart
    - lib/providers/peloton_providers.dart
    - lib/providers/peloton_providers.g.dart
    - lib/l10n/app_nl.arb
    - lib/l10n/app_en.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_nl.dart
    - lib/l10n/app_localizations_en.dart
decisions:
  - "34-03: groupInitials splitst grafemen zelf op runes; package:characters is alleen transitief en lib/domain importeert niets buiten pubspec"
  - "34-03: groepslink hergebruiken zolang hij nog 7 dagen geldig is, anders nieuw voor 30 dagen"
  - "34-03: onbekende databasefouten gaan ongewijzigd door (_guard rethrow); de UI maakt er via groupErrorTextOf de generieke zin van"
metrics:
  duration: 25min
  completed: 2026-09-23
  tasks: 3
  files: 15
---

# Phase 34 Plan 03: Datalaag voor groepen en aanvragen Summary

De app kent nu groepen, leden en aanvragen als plain-Dart-modellen, heeft een gatewaymethode voor elke groepshandeling uit 0012 + 0013 (voordragen en accepteren alleen via rpc, nooit een client-insert in `group_members`), providers die lid en aanvraag splitsen en uitgelogd niets ophalen, en een enkele functie die elke databasefoutsleutel een gewone NL/EN-zin maakt.

## Wat er staat

- **Modellen** (`peloton_group.dart`): `GroupMember` draagt alleen naam, rol en `joined_at` (CLUB-05). `PelotonGroup.fromRows` sorteert leden (beheerders, dan `joinedAt`, dan `userId`) en aanvragen (`createdAt`). `successorIfLeaving` spiegelt `ensure_group_admin`; `isPendingFor` en `openRequests` voeden straks de landing en de sectie Aanvragen. Grenzen: 30 leden, 10 groepen, 30 open aanvragen, 40 tekens in de UI.
- **Gateway**: `listGroups` doet drie vaste selects met expliciete kolommen. Alle groepsmethoden lopen door `_guard`, die bekende sleutels (P0001 en 23514) als `GroupException` gooit. `groupInviteCode` hergebruikt een link die nog minstens 7 dagen geldig is, anders een nieuwe (30 dagen, `created_by = _uid`, zonder `.select()`). `redeemGroupInvite` geeft `(groupId, groupName, status)`.
- **Providers**: `visibleGroups` (uitgelogd leeg, geen gateway-aanroep, op naam zonder hoofdletters), `myGroups`, `myPendingGroups` en `pelotonGroup(groupId)`, afgeleid zonder tweede netwerkronde.
- **Foutteksten**: 13 `groupError*`-sleutels in beide ARB-bestanden. `groupErrorText` is een exhaustieve switch; `groupErrorTextOf` is voor catch-takken (GroupException wordt de eigen zin, de rest `groupErrorGeneric`).
- **FakeGroupGateway**: in-memory groepen met dezelfde regels als de database (create maakt je beheerder; een beheerder die voordraagt maakt direct lid, een lid maakt een aanvraag; accept maakt lid; vertrek/verwijdering met opvolging, het laatste lid heft de groep op; `last_admin` bij het degraderen van de enige beheerder), een `calls`-log, `failWith` per methode, `redeemStatus` en `inviteCodes`.

## Verificatie

- `flutter test`: **744 -> 776** geslaagd (+23 model, +4 providers, +5 foutteksten).
- `flutter analyze`: 0 errors en 0 warnings; geen meldingen in de bestanden van dit plan. De 200 info-lints die er al stonden zitten elders en vallen buiten dit plan.
- `test/structure/no_flutter_imports_test.dart` en `no_em_dash_test.dart` groen.
- Acceptatie-greps: 7 klassen/enums, 8 tabelconstanten, 27 gatewaytreffers (minimaal 26), 0 `kGroupMembersTable).insert`, `GroupError.fromPostgres` aanwezig, 11 providertreffers in `.g.dart`, 13 `groupError`-sleutels per ARB, 0 `default:`.
- Geen wijziging in `supabase/`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `package:characters` vervangen door een eigen grafeemsplitsing op runes**
- **Found during:** Task 1
- **Issue:** `import 'package:characters/characters.dart'` gaf `depend_on_referenced_packages` (het pakket is alleen transitief aanwezig). Het plan zei: lukt het niet zonder pubspec, gebruik dan runes en meld het.
- **Fix:** `_graphemes` op runes, die combinerende accenten, ZWJ-reeksen, huidskleur, variatiekiezers, tag-tekens, keycaps en vlagparen samenhoudt. Tests voor een losse emoji, een ZWJ-emoji (fietsster), een vlaggenpaar, e met combinerend accent en een Ö.
- **Commit:** 6f67db0

**2. [Rule 1 - Bug] build_runner herschreef drie ongerelateerde `.g.dart`-bestanden**
- **Found during:** Task 2
- **Issue:** `analytics_provider.g.dart`, `slots_notifier.g.dart` en `unit_prefs_provider.g.dart` kregen elk een regel gewijzigd.
- **Fix:** die drie teruggezet; alleen `peloton_providers.g.dart` is gecommit.

**3. [Rule 1 - Bug] `dart format` herschikte bestaande gatewaymethoden**
- **Found during:** Task 2
- **Issue:** de formatter herschreef `proposeOptions` en `chooseOption`, die niet bij dit plan horen.
- **Fix:** de oorspronkelijke tekst van die methoden teruggezet. De diff op `peloton_gateway.dart` bevat alleen toevoegingen.

**Scope-kanttekening:** in de fake heft het vertrek van het laatste lid de groep op. Dat volgt `ensure_group_admin` sectie 3 in 0012, dus de widgettests zien hetzelfde als de database.

## TDD Gate Compliance

- Task 1: `test(34-03)` e3273c5 -> `feat(34-03)` 6f67db0
- Task 2: `feat(34-03)` 482c566 (gateway, nodig om de fake te compileren) -> `test(34-03)` ae19aa4 -> `feat(34-03)` f7a9828 (providers)
- Task 3: `test(34-03)` 7e379ff -> `feat(34-03)` e460176

## Known Stubs

Geen. Er is nog geen UI; plannen 04 t/m 07 bouwen op deze contracten.

## Threat Flags

Geen nieuwe oppervlakte buiten het threat register. T-34-10 (geen client-insert in `group_members`), T-34-11 (expliciete kolommen), T-34-12 (ruwe servertekst nooit getoond, onbekend wordt generiek) en T-34-13 (`generateInviteCode`, `created_by = _uid`) zijn verwerkt.

## Self-Check: PASSED

- Alle aangemaakte bestanden staan op schijf.
- Commits e3273c5, 6f67db0, 482c566, ae19aa4, f7a9828, 7e379ff en e460176 staan in `git log`.
