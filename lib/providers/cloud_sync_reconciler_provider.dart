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
  CloudSyncReconciler(this._ref);
  final Ref _ref;

  static const _noopBand = Duration(seconds: 5);

  /// Never awaited from the UI (SYNC-07) — called fire-and-forget from
  /// `HomeScreen.didChangeAppLifecycleState`. Wrapped in a try/catch that
  /// swallows and `debugPrint`s any error: a failed reconcile must never
  /// crash the app or surface an error to the user, matching this
  /// codebase's existing pattern for non-critical background work (e.g.
  /// `background_task.dart`'s widget-update try/catch).
  Future<void> reconcileOnForeground() async {
    try {
      final user = _ref.read(authStateProvider).value;
      if (user == null) return;

      final client = Supabase.instance.client;
      final service = CloudReconcileService();

      await _reconcileProfile(client, service, user.id);
      await _reconcileAvailability(client, service, user.id);
      await _reconcilePlannedRides(client, service, user.id);
    } catch (error) {
      debugPrint('CloudSyncReconciler.reconcileOnForeground failed: $error');
    }

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
  /// Plan 21-11: the `Supabase.instance.client` lookup deliberately lives
  /// inside the `upsertFn`/`deleteFn` closures below, not as this method's
  /// first statement. `Supabase.instance` throws when Supabase has not been
  /// initialised (always true in this test suite, by design — see
  /// test/providers/outbox_drain_wiring_test.dart's header comment), and
  /// with the lookup at the top of this method that throw happened before
  /// `_ref.read(syncOutboxServiceProvider)` was ever reached, silently
  /// masking the real disposed-Ref bug this method also had. Moving it into
  /// the closures means the method runs (and is testable) even without an
  /// initialised Supabase, since the closures are only invoked once there is
  /// a row to send — on a real device Supabase is always initialised long
  /// before any drain.
  Future<void> drainOutbox() async {
    try {
      final outbox = _ref.read(syncOutboxServiceProvider);

      await outbox.drain(
        upsertFn: (entity, entityKey, payload) async {
          final table = _tableForEntity(entity);
          if (table == null) return;
          await Supabase.instance.client.from(table).upsert(payload);
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
          await Supabase.instance.client
              .from(kPlannedRidesTable)
              .delete()
              .eq('user_id', userId)
              .eq('ride_id', rideId);
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
    SupabaseClient client,
    CloudReconcileService service,
    String userId,
  ) async {
    final profileRepo = await _ref.read(profileRepositoryProvider.future);
    final row = await client
        .from(kProfilesTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    final cloudProfile = service.parseProfileRow(row);
    if (cloudProfile == null) return;

    final localMs = profileRepo.readUpdatedAt();
    final local =
        localMs == null ? null : DateTime.fromMillisecondsSinceEpoch(localMs);
    if (local == null || cloudProfile.updatedAt.difference(local) > _noopBand) {
      await profileRepo.save(cloudProfile.profile, stamp: false);
      await profileRepo.stampUpdatedAt(cloudProfile.updatedAt);
      _ref.invalidate(profileProvider);
    }
  }

  Future<void> _reconcileAvailability(
    SupabaseClient client,
    CloudReconcileService service,
    String userId,
  ) async {
    final availabilityRepo =
        await _ref.read(availabilityRepositoryProvider.future);
    final row = await client
        .from(kAvailabilityTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    final cloudAvailability = service.parseAvailabilityRow(row);
    if (cloudAvailability == null) return;

    final localMs = availabilityRepo.readUpdatedAt();
    final local =
        localMs == null ? null : DateTime.fromMillisecondsSinceEpoch(localMs);
    if (local == null ||
        cloudAvailability.updatedAt.difference(local) > _noopBand) {
      await availabilityRepo.save(cloudAvailability.hours, stamp: false);
      await availabilityRepo.stampUpdatedAt(cloudAvailability.updatedAt);
      _ref.invalidate(availabilityProvider);
    }
  }

  /// Reads `public.planned_rides` for [userId] — kept on [CloudSyncReconciler]
  /// rather than [CloudReconcileService] (see that class's `parsePlannedRidesRows`
  /// doc comment) because the actual `.from(...).select()...` network call is
  /// the unverified-by-automated-test seam, matching `_reconcileProfile`/
  /// `_reconcileAvailability`'s own shape.
  Future<List<Map<String, dynamic>>> readCloudPlannedRides(
    SupabaseClient client,
    String userId,
  ) async {
    final rows =
        await client.from(kPlannedRidesTable).select().eq('user_id', userId);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// Union-merge foreground reconcile for planned rides (plan 21-05,
  /// SYNC-03) — deliberately NOT the timestamp-comparison path
  /// `_reconcileProfile`/`_reconcileAvailability` use, since `planned_rides`
  /// is a growable list of independent rows, not a single mutable blob (see
  /// this plan's objective). Pushes any local-only ride up to the cloud and
  /// pulls in any cloud-only ride, without ever deleting a ride from either
  /// side as a side effect.
  Future<void> _reconcilePlannedRides(
    SupabaseClient client,
    CloudReconcileService service,
    String userId,
  ) async {
    final repo = await _ref.read(plannedRidesRepositoryProvider.future);
    final allCloudRows = await readCloudPlannedRides(client, userId);
    final local = repo.readLocal();

    // Rijen met een niet-canonieke sleutel worden uit de cloud verwijderd én
    // hier buiten beschouwing gelaten, zodat de merge de lokale kopie als
    // `localOnly` ziet en hem opnieuw pusht -- nu mét de juiste sleutel en het
    // juiste tijdstip. Zouden ze in `cloudRows` blijven staan, dan denkt de
    // merge dat de rit al in de cloud staat en duwt niemand hem terug.
    final cloudRows =
        await _repairNonCanonicalRideIds(client, allCloudRows, userId, local);

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
    SupabaseClient client,
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
        await client
            .from(kPlannedRidesTable)
            .delete()
            .eq('user_id', userId)
            .eq('ride_id', storedId);

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
