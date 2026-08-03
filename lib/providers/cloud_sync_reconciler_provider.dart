import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/data/remote/supabase_tables.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/services/cloud_reconcile_service.dart';

part 'cloud_sync_reconciler_provider.g.dart';

@riverpod
CloudSyncReconciler cloudSyncReconciler(Ref ref) => CloudSyncReconciler(ref);

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
}
