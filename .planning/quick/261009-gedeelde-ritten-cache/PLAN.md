# Cache voor gedeelde ritten en groepen (fix bug 0a)

Datum: 2026-10-09. Dossier: `.planning/debug/planned-kaartjes-koude-start.md`
(diagnose + uitgesloten hypothesen). Akkoord van Joost: fix A bouwen.

## Hoe goedlopende apps dit doen

WhatsApp, Instagram en Strava openen op de lokale kopie en laten de server
stil bijwerken; een leeg-naar-vol-sprong zie je daar alleen bij een allereerste
installatie. Dat is ook precies wat Home al doet voor het weer
(`forecast_cache_entries`). We nemen dat over en wijken bewust af op één punt:
géén skeleton-placeholder — decoratie op een scherm dat al vol staat, en het
lost de sprong niet op.

## Doel

PLANNED op Home (en de Peloton-tab) opent bij een koude start direct met de
gedeelde ritten en groepen zoals die er de vorige keer uitzagen; de eerste
geslaagde Supabase-refresh overschrijft dat stil. Uitgelogd, offline en zonder
cache verandert er niets aan het huidige gedrag.

## Aanpak

1. **Serialisatie op de modellen** (`peloton.dart`, `peloton_group.dart`):
   `toJson`/`fromJson` op `GroupRide`, `RideParticipant`, `RideOption`,
   `OptionVote`, `PelotonGroup` en zijn lid-/aanvraagklassen. Datums als UTC
   ISO-8601, lezen met `.toLocal()` — zelfde conventie als `fromRow`. De
   gateway-interface blijft ongemoeid, dus alle test-fakes blijven werken.
2. **`PelotonCacheStore`** (nieuw, `lib/data/repositories/`): SharedPreferences,
   sleutels per account (`peloton_rides_cache_v1_<uid>`,
   `peloton_groups_cache_v1_<uid>`), `fetchedAt` erbij. Corrupte of oude-vorm
   JSON leest als `null` (dan gewoon netwerk, zoals vandaag). Een
   `clearAllAccounts()` voor de accountwissel.
3. **Providers** (`peloton_providers.dart`): `groupRides` en `visibleGroups`
   worden AsyncNotifiers met dezelfde naam en dezelfde levenscyclus als nu
   (autoDispose — niet keepAlive, anders ververst een langlopende app nooit
   meer). `build()`: uitgelogd → leeg (ongewijzigd); geen cache → netwerk,
   zoals vandaag, en de uitkomst gaat in de cache; wél cache → die meteen
   teruggeven én een achtergrond-refresh die bij succes state én cache
   bijwerkt, en bij een fout de cache laat staan (Peloton is additief: een
   haperend netwerk mag nooit ritten wegnemen).
4. **Accountwissel** (`account_section.dart`): in de "start fresh"-tak ook
   `PelotonCacheStore.clearAllAccounts()` — zelfde redenering als de
   planned-rides-`clearAll` daar al.

## Tests

- Store: round-trip, per-account isolatie, corrupte JSON → null.
- Modellen: toJson/fromJson round-trip inclusief opties, stemmen en leden.
- Providers: (a) zonder cache gedraagt alles zich als nu én wordt de cache
  geschreven; (b) met cache is de eerste waarde de cache en ververst de state
  daarna met gateway-data; (c) een falende refresh laat de cache staan;
  (d) uitgelogd geen gateway-aanroep, geen cache-lezing.
- Bestaande Peloton-tests moeten ongemoeid groen blijven.

## Validatie

`flutter test`, `flutter analyze` (0 errors / 0 warnings), daarna commit.
Geen release: build 66 ligt bij Google ter beoordeling, deze fix blijft op
main tot Joost anders beslist.

## Grenzen

- Geen Drift-migratie, geen gateway-interface-wijziging, geen UI-wijziging.
- De sprong bij de allereerste installatie ooit (nog geen cache) blijft
  bestaan; dat is hetzelfde als bij WhatsApp en hoort zo.
