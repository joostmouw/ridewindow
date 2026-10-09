# SUMMARY: cache voor gedeelde ritten en groepen (bug 0a)

Datum: 2026-10-09. Plan: `PLAN.md` in deze map; dossier:
`.planning/debug/planned-kaartjes-koude-start.md`.

## Gebouwd

- **Serialisatie**: `toJson`/`fromJson` op `GroupRide`, `RideParticipant`,
  `RideOption`, `OptionVote` (`peloton.dart`) en `PelotonGroup`,
  `GroupMember`, `GroupJoinRequest` (`peloton_group.dart`). Sleutels zijn
  bewust de database-kolomnamen, zodat `fromRow` het parsen deelt; datums UTC
  schrijven, lokaal lezen, zoals `fromRow`.
- **`PelotonCacheStore`** (`lib/data/repositories/`): SharedPreferences,
  per-account sleutels (`peloton.ridesCache.<uid>`, `peloton.groupsCache.<uid>`),
  corrupte JSON leest als geen cache, `clearAllAccounts()` aangesloten op de
  "start fresh"-tak van de accountwissel (`account_section.dart`).
- **`GroupRides` en `VisibleGroups`** zijn nu AsyncNotifiers (zelfde
  providernamen, zelfde autoDispose-levenscyclus): bij een koude start is de
  kopie meteen de waarde en ververst een achtergrond-refresh state én kopie.
  Zonder cache of uitgelogd: ongewijzigd gedrag. Een mislukte refresh laat de
  kopie staan en gooit niet.

## Wat de suite ving (en dus nu vastligt)

1. **`read` vs `watch` op de gateway.** De eerste versie deed
   `ref.read(pelotonGatewayProvider)` in een hulpmethode. Daarmee verdween de
   dependency, en `updateOverrides` (wat een tweede `pumpWidget` in tests
   doet) invalideerde de provider niet meer: de tweede pomp toonde de eerste
   z'n data. Gemeten met een tijdelijke scratch-test, niet geraden.
2. **`ref` ná een async gap.** `await SharedPreferences.getInstance()` vóór
   `ref.watch(pelotonGatewayProvider)` knalde zodra een autoDispose-provider
   intussen was afgebouwd ("Cannot use the Ref after it has been disposed").
   De gateway wordt nu synchroon in `build()` gewatcht en als parameter
   doorgegeven; na de awaits raakt de code geen `ref` meer (behalve de
   `ref.mounted`-guard, het bestaande patroon uit `availability_notifier`).
3. **Drie testbestanden hadden geen SharedPreferences-mock** nodig tot nu:
   `peloton_providers_test`, `peloton_groups_providers_test`,
   `group_rides_providers_test` kregen een lege mock in `setUp`;
   `invite_group_ride_test` in zijn `_pump`. Met een commentaar waarom.

## Validatie

- `flutter test`: **1099 groen** (1087 + 12 nieuwe).
- `flutter analyze`: 0 errors, 0 warnings, 214 infos — exact de baseline.
- `dart run build_runner build --delete-conflicting-outputs`: schoon.

## Bewust niet gedaan

- **Geen release.** Build 66 ligt bij Google ter beoordeling; deze fix staat
  op main en wacht op Joosts beslissing én de toestelcontrole (koude start op
  de Oppo met gedeelde ritten: de kaartjes horen er direct te staan).
- De allereerste installatie ooit (nog geen kopie) opent nog leeg en vult zodra
  het netwerk antwoordt — zelfde gedrag als voorheen en als bij WhatsApp c.s.
- Mutatie-via-invalidatie toont kort de kopie tot de refresh landt; dat is de
  gekozen prijs van cache-eerst en is in de tests afgedekt.
