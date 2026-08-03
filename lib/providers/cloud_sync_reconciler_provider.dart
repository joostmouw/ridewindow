import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/data/remote/supabase_tables.dart';
import 'package:ridewindow/providers/app_database_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/services/account_sync_service.dart';
import 'package:ridewindow/services/cloud_reconcile_service.dart';

part 'cloud_sync_reconciler_provider.g.dart';

/// Same key/value as the private `_kLastSyncedUidKey` constant in
/// `account_section.dart` — Dart privacy is per-file, so this is an
/// intentional duplication rather than an export, matching this codebase's
/// existing convention for this exact problem (see `account_section.dart`'s
/// own header comment on `_AccountSectionHeader` duplicating
/// `profile_screen.dart`'s private `_SectionHeader` style).
const _kLastSyncedUidKey = 'account.lastSyncedUid';

@riverpod
CloudSyncReconciler cloudSyncReconciler(Ref ref) => CloudSyncReconciler(ref);

/// Emits the current pending-outbox-row count (SYNC-06/D-06/D-07's sync
/// status indicator). Generated as `outboxPendingCountProvider` — watched
/// directly from `AccountSection._buildSignedInRow()` via
/// `ref.watch(outboxPendingCountProvider)`.
@riverpod
Stream<int> outboxPendingCount(Ref ref) =>
    ref.watch(appDatabaseProvider).syncOutboxDao.watchPendingCount();

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
    final cloudRows = await readCloudPlannedRides(client, userId);
    final cloudRides = service.parsePlannedRidesRows(cloudRows);
    final local = repo.readLocal();

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
}
