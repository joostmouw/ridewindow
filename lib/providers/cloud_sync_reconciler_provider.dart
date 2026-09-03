import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/data/database/sync_outbox_entity_types.dart';
import 'package:ridewindow/data/remote/supabase_tables.dart';
import 'package:ridewindow/providers/app_database_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/services/account_sync_service.dart';
import 'package:ridewindow/services/cloud_reconcile_service.dart';
import 'package:ridewindow/services/cloud_sync_gateway.dart';
import 'package:ridewindow/services/sync_outbox_service.dart';

part 'cloud_sync_reconciler_provider.g.dart';

/// Same key/value as the private `_kLastSyncedUidKey` constant in
/// `account_section.dart` — Dart privacy is per-file, so this is an
/// intentional duplication rather than an export, matching this codebase's
/// existing convention for this exact problem (see `account_section.dart`'s
/// own header comment on `_AccountSectionHeader` duplicating
/// `profile_screen.dart`'s private `_SectionHeader` style).
const _kLastSyncedUidKey = 'account.lastSyncedUid';

/// keepAlive: true (plan 21-11) -- both production call sites
/// (`home_screen.dart:98`, `account_section.dart:317`) use a bare
/// `ref.read`, which establishes no listener. A bare `@riverpod`
/// (autoDispose by default in Riverpod 3) is disposed shortly after that
/// read returns, and `CloudSyncReconciler` stores the `Ref` it was built
/// with across `await` boundaries -- the next `_ref` access after any real
/// I/O then throws "Cannot use the Ref of cloudSyncReconcilerProvider after
/// it has been disposed." Found on a real device on 2026-08-04 (Oppo Find
/// X9 Pro, app 1.0.15+16): both `reconcileOnForeground()` and
/// `drainOutbox()` failed this way, silently swallowed by their own
/// try/catch, leaving the account row stuck on "Syncing...". Do not "tidy"
/// this back to a bare `@riverpod` -- see test/providers/
/// outbox_drain_wiring_test.dart for the regression coverage.
@Riverpod(keepAlive: true)
CloudSyncReconciler cloudSyncReconciler(Ref ref) => CloudSyncReconciler(ref);

/// Emits the current pending-outbox-row count (SYNC-06/D-06/D-07's sync
/// status indicator). Generated as `outboxPendingCountProvider` — watched
/// directly from `AccountSection._buildSignedInRow()` via
/// `ref.watch(outboxPendingCountProvider)`.
@riverpod
Stream<int> outboxPendingCount(Ref ref) =>
    ref.watch(appDatabaseProvider).syncOutboxDao.watchPendingCount();

/// Constructs the offline outbox's real production consumer (plan 21-10,
/// SYNC-05/SYNC-06) — `SyncOutboxService` bound to the app's own
/// `SyncOutboxDao`. Deliberately its own provider (rather than being built
/// inline inside `CloudSyncReconciler.drainOutbox()`) so a test can override
/// it with a fake service, matching this file's existing
/// `accountSyncServiceProvider` seam.
///
/// keepAlive: true (plan 21-11) -- same disposed-Ref failure and same
/// 2026-08-04 device date as `cloudSyncReconcilerProvider` above, plus a
/// second, quieter bug this fixes: without keepAlive, every bare
/// `_ref.read(syncOutboxServiceProvider)` constructs a *fresh*
/// `SyncOutboxService`, so 21-10's `_inFlightDrain` re-entrancy guard (an
/// instance field) never sees a second overlapping call -- two different
/// instances each think they are the only drain in flight. Do not "tidy"
/// this back to a bare `@riverpod`.
@Riverpod(keepAlive: true)
SyncOutboxService syncOutboxService(Ref ref) =>
    SyncOutboxService(ref.watch(appDatabaseProvider).syncOutboxDao);

/// Constructs the real [AccountSyncService] (plan 21-06) with production
/// dependencies (plan 21-07): the three repositories, the two cloud-read
/// closures composed from `CloudReconcileService`'s pure row parsers plus
/// the actual `.from(...).select()...` network calls, the
/// `migrate_account_data` RPC closure, and the `account.lastSyncedUid`
/// writer. `AccountSection._runAccountSync()` reads this via `.future`
/// rather than constructing `AccountSyncService` inline, so widget tests can
/// override it with a fake service instead of needing a live Supabase
/// client (see `test/features/profile_account_section_test.dart`'s
/// `FakeAccountSyncService`).
@riverpod
Future<AccountSyncService> accountSyncService(Ref ref) async {
  final client = Supabase.instance.client;
  final reconcile = CloudReconcileService();
  final profileRepo = await ref.watch(profileRepositoryProvider.future);
  final availabilityRepo = await ref.watch(availabilityRepositoryProvider.future);
  final plannedRidesRepo = await ref.watch(plannedRidesRepositoryProvider.future);

  return AccountSyncService(
    profileRepo: profileRepo,
    availabilityRepo: availabilityRepo,
    plannedRidesRepo: plannedRidesRepo,
    readCloudProfile: (userId) async {
      final row = await client
          .from(kProfilesTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return reconcile.parseProfileRow(row);
    },
    readCloudAvailability: (userId) async {
      final row = await client
          .from(kAvailabilityTable)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return reconcile.parseAvailabilityRow(row);
    },
    migrateFn: (params) => client.rpc(kMigrateAccountDataRpc, params: params),
    writeLastSyncedUid: (userId) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastSyncedUidKey, userId);
    },
  );
}

/// Fire-and-forget foreground entry point (SYNC-04) — silently pulls a newer
/// cloud row for profile/availability and adopts it locally.
///
/// Deliberately NOT the same as `resolveAccountSync` (that stays exclusively
/// a sign-in-time concern, wired in a later plan). This never prompts; it
/// only ever adopts the cloud row when it is unambiguously newer than local
/// by more than [_noopBand], matching `resolveAccountSync`'s own 5-second
/// noop band so the two mechanisms never disagree about what counts as
/// "changed".
class CloudSyncReconciler {
  /// [gateway] is de cloudkant als vervangbare poort (backlog #60). Weglaten
  /// geeft de productie-implementatie, precies zoals `RideDetailScreen`'s
  /// `calendarServiceFactory` en `notificationServiceFactory` dat doen — dit is
  /// het bestaande DI-patroon van dit project, niet een nieuw.
  ///
  /// Zonder deze parameter was van buitenaf niet waarneembaar wát deze klasse
  /// deed, en dat is de reden dat fase 21 vijf gap-closure-plannen nodig had die
  /// stuk voor stuk pas op een toestel werden gevonden. Zie
  /// `cloud_sync_gateway.dart` voor de volledige redenering, en
  /// `test/providers/cloud_sync_reconciler_gateway_test.dart` voor wat er nu
  /// wél vast ligt.
  CloudSyncReconciler(this._ref, {CloudSyncGateway? gateway})
      : _gateway = gateway ?? const SupabaseCloudSyncGateway();

  final Ref _ref;
  final CloudSyncGateway _gateway;

  static const _noopBand = Duration(seconds: 5);

  /// Het uid waarvoor [reconcileOnStartup] deze app-start al gelopen heeft.
  /// Instantieveld op een `keepAlive`-provider, dus dit is "één keer per
  /// app-start per account".
  String? _startupReconciledUid;

  /// Opstart-reconcile (backlog #61) -- het pad dat ontbrak.
  ///
  /// Tot deze methode bestond hing de pull van geplande ritten uitsluitend aan
  /// de voorgrond-reconcile. Bij een normale login staat `lastSyncedUid` al,
  /// dus de eerste-login-migratie draait niet, en de initiële load telt niet
  /// als voorgrond-overgang: er was geen enkel pad dat bij het opstarten uit
  /// de cloud las. Een verse installatie met een geldige sessie toonde daardoor
  /// een lege PLANNED-lijst tot de gebruiker de app eenmaal wegzette -- precies
  /// het eerste wat iemand op een tweede toestel doet. Waargenomen 2026-08-07
  /// op een verse WebAPK-installatie (MANUAL-VERIFICATION-21.md, device
  /// session 7).
  ///
  /// Leunt op [_signedInUser] in plaats van op `authStateProvider.value`
  /// alleen -- zie daar. Uitgelogd zet de guard niet, zodat een aanroep ná het
  /// inloggen het alsnog kan doen.
  ///
  /// Fire-and-forget vanaf `HomeScreen.initState` en nooit geawait door de UI:
  /// §4's grens van 2 seconden tot het eerste zichtbare ride slot mag hier niet
  /// aan hangen.
  Future<void> reconcileOnStartup() async {
    final userId = _signedInUserId();
    if (userId == null) return;
    if (_startupReconciledUid == userId) return;
    _startupReconciledUid = userId;

    // Vangt zijn eigen fouten al af, dus geen tweede try/catch eromheen --
    // die zou alleen de eigen logging van die methode verduisteren.
    await reconcileOnForeground();
  }

  /// Wie is er ingelogd, zonder aan te nemen dat iemand anders naar
  /// `authStateProvider` luistert.
  ///
  /// Dat laatste is geen theoretisch punt: een `StreamProvider` waar niemand
  /// naar luistert, abonneert zich nooit op zijn bron, en blijft dus eeuwig
  /// `AsyncLoading` -- `.value` is dan `null` voor een gewoon ingelogde
  /// gebruiker. Gemeten in `test/providers/startup_reconcile_wiring_test.dart`.
  /// [reconcileOnForeground] kwam daar weg mee omdat het pas bij een
  /// voorgrond-overgang draait, wanneer de widgetboom die listener allang
  /// houdt. Bij `HomeScreen.initState` is er nog geen enkele build geweest en
  /// geldt die aanname niet meer.
  ///
  /// De terugval is dezelfde bron als de seed van `authState` zelf
  /// (`auth_notifier.dart`): `Supabase.initialize()` is in `main()` geawait
  /// vóór `runApp()`, dus de herstelde sessie is hier synchroon beschikbaar.
  ///
  /// Bewust géén `_ref.listen` om de provider wakker te maken: dat legt een
  /// afhankelijkheidsrand van deze provider naar `authStateProvider`, en de
  /// eerstvolgende auth-wijziging disposet dan de `Ref` die deze klasse over
  /// `await`-grenzen heen vasthoudt -- exact de fout die plan 21-11 dichtte.
  ///
  /// De try/catch dekt een niet-geïnitialiseerde Supabase (`Supabase.instance`
  /// gooit dan, binnen in de poort). Dat is de normale toestand in de
  /// testsuite, en daar is "niemand ingelogd" het juiste antwoord.
  ///
  /// De volgorde is niet vrijblijvend: eerst de provider, dán de poort. Zie de
  /// alinea's hierboven — de terugval bestaat juist voor het moment waarop nog
  /// niemand naar `authStateProvider` luistert.
  String? _signedInUserId() {
    final fromProvider = _ref.read(authStateProvider).value;
    if (fromProvider != null) return fromProvider.id;
    try {
      return _gateway.currentSessionUserId();
    } catch (error) {
      debugPrint('CloudSyncReconciler: geen auth-staat beschikbaar: $error');
      return null;
    }
  }

  /// Never awaited from the UI (SYNC-07) — called fire-and-forget from
  /// `HomeScreen.didChangeAppLifecycleState`. Wrapped in a try/catch that
  /// swallows and `debugPrint`s any error: a failed reconcile must never
  /// crash the app or surface an error to the user, matching this
  /// codebase's existing pattern for non-critical background work (e.g.
  /// `background_task.dart`'s widget-update try/catch).
  Future<void> reconcileOnForeground() async {
    // Eerst duwen, dan pas trekken (plan 21-14). De outbox bevat de *intentie*
    // van de gebruiker, de cloud bevat de laatst *overeengekomen* stand. Lees je
    // de overeengekomen stand vóórdat de intentie verstuurd is, dan gooi je die
    // intentie weg: een verwijderde rit staat in de cloud nog gewoon te wachten,
    // de union-merge zet hem lokaal terug, en de volgende cyclus pusht hem weer
    // omhoog. Op 2026-08-05 op het toestel waargenomen -- handmatig verwijderde
    // ritten kwamen bij elke sync terug.
    await drainOutbox();

    try {
      // Zelfde bron als de opstart-reconcile (zie [_signedInUser]): zonder de
      // terugval op de herstelde sessie hangt deze lezing aan de vraag of er
      // toevallig al een listener op `authStateProvider` staat.
      final userId = _signedInUserId();
      if (userId == null) return;

      final service = CloudReconcileService();

      await _reconcileProfile(service, userId);
      await _reconcileAvailability(service, userId);
      await _reconcilePlannedRides(service, userId);
    } catch (error) {
      debugPrint('CloudSyncReconciler.reconcileOnForeground failed: $error');
    }

    // Tweede drain: de merge hierboven enqueuet upserts voor ritten die alleen
    // lokaal bestaan (`result.localOnly`). Zonder deze aanroep wachten die een
    // hele cyclus. `drain()` heeft een re-entrancy-guard (21-10) en een lege
    // wachtrij is een gelogde no-op, dus dit is goedkoop.
    await drainOutbox();
  }

  /// Drains the offline outbox (SYNC-05/SYNC-06, plan 21-10) using the real
  /// Supabase send closures, composed here (never inside
  /// `sync_outbox_service.dart` itself, which stays cloud-SDK-free) from
  /// `supabase_tables.dart`'s table-name constants. Called from
  /// [reconcileOnForeground] above, and separately by
  /// `AccountSection._runAccountSync` right after `AccountSyncService` has
  /// finished a sign-in (including once every conflict prompt is resolved)
  /// — an enqueue made during sign-in must not sit until the next foreground
  /// event.
  ///
  /// This was the exact gap found on a real device on 2026-08-04 (see
  /// `MANUAL-VERIFICATION-21.md`, "Device session" section): `drain()` was
  /// thoroughly unit-tested but had no production caller anywhere, so the
  /// outbox was write-only. Never throws — same "a background sync failure
  /// must never crash or block the UI" reasoning as `reconcileOnForeground`
  /// and `AccountSection._runAccountSync`'s own try/catch, and a failed
  /// drain always leaves its rows pending for the next attempt (never
  /// silently drops them — that's `SyncOutboxService.drain()`'s own
  /// contract).
  ///
  /// Plan 21-11: de `Supabase.instance.client`-lookup hoort binnen de
  /// `upsertFn`/`deleteFn`-closures thuis, niet als eerste statement van deze
  /// methode. `Supabase.instance` gooit wanneer Supabase niet geïnitialiseerd
  /// is (altijd waar in deze testsuite, met opzet — zie de header van
  /// test/providers/outbox_drain_wiring_test.dart), en met de lookup bovenaan
  /// deze methode gebeurde die throw vóórdat
  /// `_ref.read(syncOutboxServiceProvider)` ooit bereikt werd, wat de echte
  /// disposed-Ref-bug maskeerde. Sinds backlog #60 zit die lookup in
  /// [SupabaseCloudSyncGateway] en is hij daar een getter per aanroep, om
  /// exact dezelfde reden — de eis is dus niet verdwenen, alleen verhuisd.
  Future<void> drainOutbox() async {
    try {
      final outbox = _ref.read(syncOutboxServiceProvider);

      await outbox.drain(
        upsertFn: (entity, entityKey, payload) async {
          final table = _tableForEntity(entity);
          if (table == null) return;
          await _gateway.upsertRow(table, payload);
        },
        deleteFn: (entity, entityKey) async {
          // Only `planned_rides` ever enqueues a delete today (plan 21-05)
          // — profile/availability are single-row-per-user blobs that are
          // only ever upserted. The compound filter lives in `entityKey`
          // itself (`'$userId:$rideId'`, see
          // `PlannedRidesRepository.remove()`), never in the payload —
          // deletes always send `'{}'` as the payload.
          if (entity != kOutboxEntityPlannedRide) return;
          final separator = entityKey.indexOf(':');
          if (separator < 0) return;
          final userId = entityKey.substring(0, separator);
          final rideId = entityKey.substring(separator + 1);
          await _gateway.deletePlannedRide(userId: userId, rideId: rideId);
        },
      );
    } catch (error) {
      debugPrint('CloudSyncReconciler.drainOutbox failed: $error');
    }
  }

  /// Maps an outbox `entity` string to its Postgres table name for the
  /// upsert path. `null` for an unrecognized entity — `upsertFn` treats that
  /// as a no-op rather than throwing, since a corrupt/future entity string
  /// must never crash the drain for every other pending row.
  String? _tableForEntity(String entity) {
    switch (entity) {
      case kOutboxEntityProfile:
        return kProfilesTable;
      case kOutboxEntityAvailability:
        return kAvailabilityTable;
      case kOutboxEntityPlannedRide:
        return kPlannedRidesTable;
      default:
        return null;
    }
  }

  Future<void> _reconcileProfile(
    CloudReconcileService service,
    String userId,
  ) async {
    final profileRepo = await _ref.read(profileRepositoryProvider.future);
    final row = await _gateway.readProfileRow(userId);
    final cloudProfile = service.parseProfileRow(row);
    if (cloudProfile == null) return;

    final localMs = profileRepo.readUpdatedAt();
    final local =
        localMs == null ? null : DateTime.fromMillisecondsSinceEpoch(localMs);
    if (local == null || cloudProfile.updatedAt.difference(local) > _noopBand) {
      // `enqueue: false` (backlog #57): deze rij komt uit de cloud, dus hem
      // terugduwen is niet alleen overbodig maar schadelijk -- de
      // `before update`-trigger zet `updated_at` op nu, waarna de volgende
      // koude start de cloud opnieuw als nieuwer ziet en dezelfde adoptie
      // uitvoert. Een lus die zichzelf voedt.
      await profileRepo.save(cloudProfile.profile, stamp: false, enqueue: false);
      await profileRepo.stampUpdatedAt(cloudProfile.updatedAt);
      _ref.invalidate(profileProvider);
    }
  }

  Future<void> _reconcileAvailability(
    CloudReconcileService service,
    String userId,
  ) async {
    final availabilityRepo =
        await _ref.read(availabilityRepositoryProvider.future);
    final row = await _gateway.readAvailabilityRow(userId);
    final cloudAvailability = service.parseAvailabilityRow(row);
    if (cloudAvailability == null) return;

    final localMs = availabilityRepo.readUpdatedAt();
    final local =
        localMs == null ? null : DateTime.fromMillisecondsSinceEpoch(localMs);
    if (local == null ||
        cloudAvailability.updatedAt.difference(local) > _noopBand) {
      // Zelfde lus als bij het profiel hierboven (backlog #57).
      await availabilityRepo.save(
        cloudAvailability.hours,
        stamp: false,
        enqueue: false,
      );
      await availabilityRepo.stampUpdatedAt(cloudAvailability.updatedAt);
      _ref.invalidate(availabilityProvider);
    }
  }

  /// Leest `public.planned_rides` voor [userId].
  ///
  /// Stond hier oorspronkelijk (en niet op [CloudReconcileService], zie de
  /// doc-comment van `parsePlannedRidesRows`) omdat de echte
  /// `.from(...).select()...`-aanroep de door tests onbereikbare naad was. Sinds
  /// backlog #60 is die naad [CloudSyncGateway] en is dit een gewone
  /// doorgeefmethode — bewust behouden zodat `_reconcilePlannedRides` dezelfde
  /// vorm houdt als `_reconcileProfile`/`_reconcileAvailability`.
  Future<List<Map<String, dynamic>>> readCloudPlannedRides(String userId) =>
      _gateway.readPlannedRideRows(userId);

  /// Union-merge foreground reconcile for planned rides (plan 21-05,
  /// SYNC-03) — deliberately NOT the timestamp-comparison path
  /// `_reconcileProfile`/`_reconcileAvailability` use, since `planned_rides`
  /// is a growable list of independent rows, not a single mutable blob (see
  /// this plan's objective). Pushes any local-only ride up to the cloud and
  /// pulls in any cloud-only ride, without ever deleting a ride from either
  /// side as a side effect.
  Future<void> _reconcilePlannedRides(
    CloudReconcileService service,
    String userId,
  ) async {
    final repo = await _ref.read(plannedRidesRepositoryProvider.future);
    final allCloudRows = await readCloudPlannedRides(userId);
    final local = repo.readLocal();

    // Rijen met een niet-canonieke sleutel worden uit de cloud verwijderd én
    // hier buiten beschouwing gelaten, zodat de merge de lokale kopie als
    // `localOnly` ziet en hem opnieuw pusht -- nu mét de juiste sleutel en het
    // juiste tijdstip. Zouden ze in `cloudRows` blijven staan, dan denkt de
    // merge dat de rit al in de cloud staat en duwt niemand hem terug.
    final cloudRows =
        await _repairNonCanonicalRideIds(allCloudRows, userId, local);

    final cloudRides = service.parsePlannedRidesRows(cloudRows);

    final result = service.mergePlannedRides(local: local, cloud: cloudRides);

    for (final ride in result.localOnly) {
      await repo.enqueueUpsert(ride);
    }

    final localIds = local.map((r) => r.rideId).toSet();
    final mergedIds = result.merged.map((r) => r.rideId).toSet();
    if (result.merged.length != local.length || !localIds.containsAll(mergedIds)) {
      await repo.save(result.merged, stamp: false);
      _ref.invalidate(plannedRidesProvider);
    }
  }

  /// Herstelt rijen in `public.planned_rides` waarvan de opgeslagen `ride_id`
  /// niet gelijk is aan de canonieke sleutel die uit hun eigen `start_at`
  /// volgt (plan 21-13).
  ///
  /// Vóór 21-13 schreef `PlannedRide.toRow` een offsetloze string, die Postgres
  /// in de sessiezone las. Zulke rijen dragen dus zowel een verkeerde sleutel
  /// als een tijdstip dat met de lokale offset verschoven is. Ze blijven anders
  /// bij elke pull terugkomen als extra kopie, dus opruimen is geen luxe.
  ///
  /// Bewust hier en niet in een aparte migratiestap: dit is een gewone
  /// reconcile die toevallig opmerkt dat een rij verkeerd gesleuteld is. **Dit
  /// mag weg zodra geen enkel toestel nog een rij van vóór 21-13 kan hebben** --
  /// laat het geen permanente steiger worden.
  ///
  /// Een fout hier mag de rest van de reconcile nooit blokkeren; de rijen staan
  /// er de volgende foreground gewoon nog.
  /// Geeft de rijen terug die de merge mag gebruiken: alles met een canonieke
  /// sleutel, plus rijen waarvan het verwijderen mislukte (die blijven immers
  /// gewoon bestaan).
  Future<List<Map<String, dynamic>>> _repairNonCanonicalRideIds(
    List<Map<String, dynamic>> cloudRows,
    String userId,
    List<PlannedRide> local,
  ) async {
    final keep = <Map<String, dynamic>>[];

    for (final row in cloudRows) {
      final storedId = row['ride_id'] as String?;
      if (storedId == null) {
        keep.add(row);
        continue;
      }

      final parsed = PlannedRide.fromRow(row);
      if (storedId == parsed.rideId) {
        keep.add(row);
        continue;
      }

      // Een rij van vóór 21-13 draagt zowel een verkeerde sleutel als een
      // tijdstip dat met de lokale offset verschoven is, omdat de offsetloze
      // string in de sessiezone werd gelezen. De lokale lijst is daarom de
      // betrouwbare bron, niet deze rij. Bestaat er geen lokale tegenhanger,
      // dan is er niets om op terug te vallen -- dat wordt luid gelogd in
      // plaats van stil weggegooid.
      final hasLocalCounterpart = local.any(
        (r) => r.rideId == parsed.rideId || r.rideId == storedId,
      );

      try {
        await _gateway.deletePlannedRide(userId: userId, rideId: storedId);

        if (hasLocalCounterpart) {
          debugPrint(
            'CloudSyncReconciler: planned_rides-sleutel $storedId is niet '
            'canoniek, rij verwijderd -- de lokale kopie wordt opnieuw gepusht',
          );
        } else {
          debugPrint(
            'CloudSyncReconciler: planned_rides-rij $storedId verwijderd '
            'ZONDER lokale tegenhanger. Inhoud: ${row['start_at']} - '
            '${row['end_at']}, score ${row['planned_score']}. Deze rit had een '
            'verschoven tijdstip en is niet te herstellen zonder lokale bron.',
          );
        }
      } catch (error) {
        // Verwijderen mislukt: de rij bestaat nog, dus hij hoort nog wél in de
        // merge thuis. Volgende foreground opnieuw proberen.
        debugPrint(
          'CloudSyncReconciler: herstel van planned_rides-sleutel $storedId '
          'mislukt: $error',
        );
        keep.add(row);
      }
    }

    return keep;
  }
}
