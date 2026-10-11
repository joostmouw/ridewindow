---
status: verified_on_device
trigger: "OPEN.md punt 0a: de PLANNED-kaartjes verschijnen pas een paar seconden na een koude start; tot dan staat er alleen de kop. Gezien op de Oppo bij build 64, opnieuw genoemd bij 66."
created: 2026-10-09
updated: 2026-10-09
goal: find_and_fix
---

# PLANNED-kaartjes springen bij een koude start

## Symptoom

Op Home staat na een koude start eerst alleen de kop PLANNED (of alleen de
persoonlijke ritten); de gedeelde ritten komen er een paar seconden later bij
en het scherm springt. Waargenomen op de Oppo bij build 64 (2026-09-29,
`STATE.md`: "de gedeelde ritten komen van de server").

## Oorzaak

`rideEntriesProvider` (`lib/providers/ride_entries_provider.dart`) is bewust
synchroon en combineert vijf bronnen met `.value ?? const []` — een ontwerp dat
voorkomt dat een trage of falende cloud-aanroep de lijst gijzelt. Dat ontwerp
is goed, maar het betekent dat elke bron die géén lokale kopie heeft op een
koude start simpelweg ontbreekt tot het netwerk antwoordt:

- **Persoonlijke geplande ritten** staan in SharedPreferences
  (`PlannedRidesRepository.readLocal()`) en zijn er meteen.
- **Gedeelde ritten** komen uit `groupRidesProvider`, en die doet bij elke
  koude start twee netwerkrondgangen tegen Supabase
  (`SupabasePelotonGateway.listGroupRides()`: `group_rides` + `participants`,
  `peloton_gateway.dart:246`). Er is geen lokale cache — Drift kent alleen
  `hourly_forecast_entries`, `forecast_cache_entries`,
  `availability_grid_entries` en `sync_outbox_entries`.
- **Groepen** (`myGroupsProvider` via `visibleGroupsProvider`) doen nog eens
  drie eigen rondgangen (`peloton_gateway.dart:472`).

De gedeelde ritten en groepsnamen komen dus structureel een Supabase-retourtje
te laat. De sprong is geen timingtoeval maar een ontwerpleemte: Peloton kreeg
bij de invoering (v3.0) geen lokale laag, omdat de lijst toen alleen op de
Peloton-tab zichtbaar was. Sinds groepsritten op Home staan, is dat zichtbaar
bij elke koude start van een ingelogde gebruiker.

## Hoe goedlopende apps dit doen

WhatsApp, Instagram en Strava openen allemaal op de lokale kopie en laten de
server stil bijwerken; een kop-tot-kaartjes-sprong zie je daar alleen bij een
aller eerste installatie. Dat is precies het patroon dat Home zelf al volgt
voor het weer (`forecast_cache_entries`: openen op de cache, verversen op de
achtergrond). Overnemen dus. Bewust níét overgenomen: een
skeleton-placeholder — decoratie op een scherm dat al vol staat met weer en
tijdvakken, en het lost de sprong niet op, hij vervangt hem door een andere.

## Fixrichtingen

**A. Rij-cache in SharedPreferences (aanbevolen).** De gateway levert rauwe
rijen (`Map<String, dynamic>`) die al JSON-compatibel zijn; de rij-naar-model
mapping (`GroupRide.fromRow`, `RideParticipant.fromRow`) wordt herbruikbaar
losgetrokken. `groupRidesProvider` (en `visibleGroupsProvider`, zelfde patroon)
leest dan eerst de cache (per-user sleutel), toont die, en haalt daarna het
netwerk op: nieuwe rijen vervangen de cache en de state. Zelfde patroon als
`PlannedRidesRepository`, geen Drift-migratie nodig.

**B. Drift-tabel** (zoals `forecast_cache_entries`). SQL-querybaar, maar
overkill voor hooguit tientallen ritten, en het kost een schemamigratie.

Randvoorwaarden bij beide: de cache is per account (sleutel met uid) en wordt
gewist bij accountwissel (het D-09 "start fresh"-patroon dat
`PlannedRidesNotifier.clearAll` al kent); hij wordt alleen gelezen als er een
sessie is, zodat een uitgelogde gebruiker nooit andermans ritten uit een oude
cache ziet; en de server blijft leidend — de cache vult alleen de eerste
seconden, de eerste geslaagde refresh overschrijft hem.

## Uitgesloten, met reden

- **De opstart-reconcile** (`CloudSyncReconciler.reconcileOnStartup`): die
  synct persoonlijke `planned_rides`, en die komen al uit SharedPreferences.
  Niet het pad van dit symptoom.
- **De 500 ms spotlight-timer** in `HomeScreen.initState`: stuurt alleen de
  hint-overlay, raakt PLANNED niet.
- **`.value ?? const []` in `rideEntriesProvider` zelf**: dat is de juiste
  keuze (een offline of uitgelogde gebruiker mag zijn eigen ritten niet
  kwijtraken) en blijft staan; de fix zit in de bronnen, niet in de combiner.

## Beslissing die bij Joost ligt

~~Fix A bouwen of parkeren.~~ **Joost koos op 2026-10-09: bouwen.**

## Oplossing (2026-10-09)

Fix A gebouwd in quick `261009-gedeelde-ritten-cache`:

- `GroupRide`, `RideParticipant`, `RideOption`, `OptionVote`, `PelotonGroup`,
  `GroupMember` en `GroupJoinRequest` kregen `toJson`/`fromJson` met dezelfde
  sleutels als de database-rijen, zodat `fromRow` het parsen blijft doen.
- Nieuwe `PelotonCacheStore` (SharedPreferences, per account gesleuteld,
  corrupte JSON leest als geen cache, `clearAllAccounts()` voor de
  accountwissel-"start fresh"-tak).
- `groupRides` en `visibleGroups` werden AsyncNotifiers: cache eerst, dan een
  achtergrond-refresh die state én kopie bijwerkt; een mislukte refresh laat
  de kopie staan. Uitgelogd, offline en zonder cache ongewijzigd.

**Twee valkuilen die de suite ving, en de les eruit:**

1. `ref.read(pelotonGatewayProvider)` in plaats van `watch` brak stil de
   invalidatieketen: `ProviderScope.updateOverrides` (wat een tweede
   `pumpWidget` in tests doet) invalidates alleen watchers. De gateway wordt
   nu synchroon in `build()` gewatcht, vóór de eerste `await`.
2. `ref` aan het netwerk ná een async gap (`await
   SharedPreferences.getInstance()` en pas daarna `ref.watch`) knalt bij een
   autoDispose-provider die intussen is afgebouwd ("Cannot use the Ref after
   it has been disposed"). Dezelfde les als de stille-takken-sweep: na elke
   `await` staat er een andere wereld.

**Verificatie:** suite 1099 groen (12 nieuwe tests: store round-trips,
per-account isolatie, corrupte JSON, cache-eerst-ververst, falende refresh
blijft staan, uitgelogd raakt niets); analyze op baseline (0/0/214).

## Toestelverificatie (2026-10-11, build 1.0.56 (67) op de Oppo)

Via Play bijgewerkt (geen sideload), daarna **offline** een koude start gedaan
met wifi en data uit. Dat is de scherpste proef: een geslaagde netwerkrefresh
kan de cache niet maskeren.

**Wat werkt.** De Peloton-tab toont de groepen (Dawon, 3 leden; On the Roll,
4 leden) en Home opent met de volledige gecachte lijst. Zonder de fix was hier
niets of een foutmelding te zien geweest. De cache-route is dus bewezen op een
echt toestel, niet alleen in tests.

**Wat dezelfde proef blootlegde: de maatjeslijst heeft géén cache.** In
dezelfde offline sessie staat onder GROUPS een correcte lijst en onder BUDDIES
"Try again" met het netwerk-icoon. Oorzaak: `friends` in
`peloton_providers.dart` is nog een gewone functionele provider
(`return ref.watch(pelotonGatewayProvider).listFriends();`), precies de vorm
die `groupRides` en `visibleGroups` vóór deze fix hadden.

**Waarom dit de moeite is om vast te leggen.** Het is dezelfde fout, in
hetzelfde bestand, op hetzelfde scherm, en de fix maakte hem zichtbaarder dan
hij was: eerst faalde de hele tab offline, nu faalt alleen dit blok. Wie alleen
naar "werken de groepen offline?" kijkt, mist het. Dit is de werkregel "loop de
hele app na bij een wijziging" in het klein: een patroon dat je op één plek
aanbrengt, breng je overal aan waar het speelt.

**Niet onderzocht, dus niet beweren:** of `pendingRideInvites`, `rideEntries` en
de bolletjestellers offline hetzelfde doen. Ze leunen op `groupRides` (nu
gecachet), dus vermoedelijk niet, maar dat is niet gemeten.

**Openstaand:** de maatjeslijst dezelfde behandeling geven (Friend-model
serialiseren, store-methoden, provider om) is klein en dezelfde vorm. Besluit
op 2026-10-11: eerst Joost, want het bepaalt of 67 of 68 de eerste
productie-build wordt. Er is geen haast: de productietrack is nog leeg, dus er
staat nog niets publiek.
