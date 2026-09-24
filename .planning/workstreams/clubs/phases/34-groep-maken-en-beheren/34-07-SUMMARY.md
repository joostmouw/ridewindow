---
phase: 34-groep-maken-en-beheren
plan: 07
subsystem: peloton-ui
tags: [flutter, riverpod, go_router, clubs, groups, deep-link, l10n]
requires:
  - "34-03: gateway.redeemGroupInvite, groupErrorTextOf, FakeGroupGateway"
  - "34-06: groepslink https://my-project-joost.web.app/#/group/<code> en de gedeelde tekst"
provides:
  - "GroupLandingScreen(code) op /group/:code"
  - "PendingInviteStore.friendKey/groupKey + saveGroup/readGroup/clearGroup"
  - "redeemPendingGroupCode(gateway) in lib/services/pending_group_join.dart"
  - "Onboarding-redirect bewaart /group- en /invite-codes"
  - "Codeveld op de Peloton-tab accepteert ook groepscodes"
affects: [34-08, 35]
tech-stack:
  added: []
  patterns:
    - "Een code uit een deep link overleeft redirect en inloggen via SharedPreferences, en wordt vóór het inwisselen gewist"
    - "Retry-future met eigen onError-luisteraar zodat een fout vóór het volgende frame niet als onafgehandeld telt"
key-files:
  created:
    - lib/services/pending_group_join.dart
    - lib/features/peloton/group_landing_screen.dart
    - test/services/pending_group_join_test.dart
    - test/app/router_pending_code_test.dart
    - test/features/group_landing_test.dart
    - test/features/peloton_code_field_test.dart
  modified:
    - lib/services/pending_invite_store.dart
    - lib/features/profile/account_section.dart
    - lib/features/peloton/buddies_tab.dart
    - lib/app/router.dart
    - lib/l10n/app_nl.arb
    - lib/l10n/app_en.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_nl.dart
    - lib/l10n/app_localizations_en.dart
decisions:
  - "34-07: groepscode heeft een eigen sleutel naast de maatjescode; maatjessleutel houdt zijn oude waarde"
  - "34-07: fout bij inwisselen na inloggen is niet stil (vol / 10 groepen moet je horen)"
  - "34-07: codeveld verklapt het soort code niet; alleen vol/10 groepen krijgt een eigen zin"
  - "34-07: landing toont uitgelogd geen groepsnaam (anon heeft geen rechten); afwijking van schets 015"
metrics:
  duration: 30min
  completed: 2026-09-24
---

# Phase 34 Plan 07: Groepslanding en bewaarde groepscode Summary

De groepslink doet het nu van begin tot eind: /group/:code toont uitgelogd "Log in en doe mee" en bewaart de code. Die code overleeft de welkomstschermen en het inloggen en wordt daarna vanzelf een aanvraag (of het groepsscherm als je al lid bent). Dezelfde code werkt ook als je hem in het codeveld op de Peloton-tab typt.

## Wat er gebouwd is

**Task 1: bewaarde code, inwisselen na inloggen, onboarding-redirect** (5dac73f RED, 12aea73 GREEN)
- `PendingInviteStore`: publieke `friendKey` (zelfde waarde `peloton.pendingInviteCode`, zodat al bewaarde codes na een update gewoon blijven werken) en `groupKey`. Daarnaast `saveGroup/readGroup/clearGroup`.
- `redeemPendingGroupCode(gateway)`: null zonder code en dan geen aanroep. Met code wordt die eerst gewist en daarna ingewisseld; fouten gaan door naar de aanroeper.
- `account_section`: na `_redeemPendingInvite()` volgt nu `_redeemPendingGroupInvite()`. Ben je lid, dan `push('/peloton/group/<id>')`. Staat er een aanvraag, dan verschijnt een snackbar "Je aanvraag voor X ligt bij de beheerders" met de actie "Bekijk". Bij een fout volgt een snackbar via `groupErrorTextOf`. Router en messenger worden via `maybeOf` vóór de eerste await opgehaald.
- Router-redirect: stuurt hij iemand naar /welcome, dan wordt een code uit `/group/<code>` of `/invite/<code>` eerst synchroon weggeschreven.

**Task 2: GroupLandingScreen en het codeveld** (30ba417 RED, 6cc0bc6 GREEN)
- `GroupLandingScreen` is gebouwd naar het model van `InviteLandingScreen`, met SafeBackButton en de titel "Uitnodiging voor een groep".
  - Uitgelogd: uitleg met de knoppen "Log in en doe mee" (/profile) en "Niet nu" (/home).
  - Ingelogd: meteen inwisselen. Bij een aanvraag staat er "Je aanvraag voor ... ligt bij de beheerders" plus een hint en de knop "Naar de groep". Ben je al lid, dan `go` naar het groepsscherm. Bij een fout krijg je de zin uit `groupErrorTextOf` met "Opnieuw proberen".
  - Een `ref.listen` op `currentUserIdProvider` start het inwisselen zodra iemand inlogt terwijl het scherm openstaat, en wist de bewaarde code.
  - Analytics: alleen `kind: group_redeemed_link`, nooit de code.
- Route `/group/:code` staat naast `/invite/:code`, buiten de shell.
- `buddies_tab._redeemCode`: de maatjespoging komt eerst en is ongewijzigd. Mislukt die, dan probeert `_redeemGroupCode` de code als groepscode. Een onbekende code geeft nog steeds "Die code werkt niet. Hij kan verlopen zijn."; alleen `groupFull` en `tooManyGroups` krijgen hun eigen zin. Analytics: `kind: group_redeemed_code`.

## firebase.json

Ongewijzigd (`git diff --stat firebase.json` is leeg). De rewrite `"source": "**" -> /index.html` dekt elk pad al. Bovendien draait de app op hash-routing (`/#/group/<code>`), dus de server krijgt het pad niet eens te zien.

## Verificatie

- `flutter analyze`: 199 issues, tegen 200 op de uitgangsstand. Er zit er geen enkele in een nieuw of gewijzigd stuk code; de overige zijn bestaande infos elders.
- `flutter test`: **864 tests groen** (was 841, dus 23 nieuwe): pending_group_join 6, router_pending_code 4, group_landing 8, peloton_code_field 5.
- Acceptatie-greps: alle aantallen kloppen (friendKey 1, groupKey 4, redeemPendingGroupCode( 1, router-keys 2, SafeBackButton( 1, saveGroup 1, '/group/:code' 1, redeemGroupInvite( 1, redeemFriendInvite( 1).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Onafgehandelde fout bij "Opnieuw proberen"**
- **Found during:** Task 2
- **Issue:** Bij een retry kon de future met een fout eindigen vóór de FutureBuilder er in het volgende frame naar luisterde. De fout telde dan als onafgehandeld.
- **Fix:** `_start` koppelt een eigen `then(..., onError:)`-luisteraar; de FutureBuilder krijgt de fout nog steeds. `Future.ignore()` werkt hier niet.
- **Files modified:** lib/features/peloton/group_landing_screen.dart
- **Commit:** 6cc0bc6

**2. [Rule 3 - Blocking] Routertest bouwt de echte router**
- **Issue:** De redirect draait alleen via de Router-widget, dus `router.go` zonder gepompte app meet niets.
- **Fix:** De test pompt `MaterialApp.router` met `currentUserIdProvider` op null en de echte `routerProvider`.

**3. De test 'onboarding af' toetst meer dan het plan vroeg:** hij controleert ook dat `GroupLandingScreen` met de code wordt gebouwd.

## Known Stubs

Geen.

## Threat Flags

Geen nieuwe oppervlakte buiten het threat model. T-34-25 (normalizeInviteCode in de gateway en een foutzin), T-34-26 (dezelfde zin voor een onbekende code) en T-34-28 (alleen `kind`) zijn toegepast. T-34-27 is geaccepteerd: de code wordt na elke poging gewist.

## Self-Check: PASSED
