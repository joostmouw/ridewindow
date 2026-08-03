import 'package:ridewindow/domain/models/block_type.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';
import 'package:ridewindow/domain/models/user_profile.dart';
import 'package:ridewindow/domain/services/availability_key.dart';

/// Read-only parsing of a pulled cloud row into domain shapes, used only by
/// the foreground reconciler ([CloudSyncReconciler] in
/// `cloud_sync_reconciler_provider.dart`) — never by anything reachable from
/// `lib/platform/background_task.dart`.
///
/// **Design note (plan 21-04, Task 2):** the `<interfaces>` sketch in the
/// plan has this class hold a `SupabaseClient` and call
/// `.from(...).select().eq(...).maybeSingle()` itself. Mocking that fluent
/// chain with mockito is a known-heavy surface — unlike `http.Client` in
/// `test/data/repositories/weather_repository_test.dart` (a small interface
/// `@GenerateMocks` handles cleanly), `PostgrestFilterBuilder`'s chained
/// calls return specific generic builder types that don't reduce to a small
/// mockable seam. Per the plan's own fallback instruction, this class
/// instead takes the already-fetched `Map<String, dynamic>?` row as a plain
/// parameter and does only the parsing (`UserProfile.fromRow`/
/// `fromRecurringJson` + `DateTime.parse`) — the row-shape correctness is
/// already proven by Task 1's round-trip tests. The actual
/// `.from(...).select()...` network call lives in `CloudSyncReconciler`
/// (Task 3), exercised by the manual regression checklist rather than an
/// automated mock.
class CloudReconcileService {
  /// Parses a pulled `public.profiles` row, or returns `null` if [row] is
  /// `null` (no row for this user yet).
  ({UserProfile profile, DateTime updatedAt})? parseProfileRow(
    Map<String, dynamic>? row,
  ) {
    if (row == null) return null;
    return (
      profile: UserProfile.fromRow(row),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  /// Parses a pulled `public.availability` row, or returns `null` if [row]
  /// is `null` (no row for this user yet).
  ({Map<DateTime, BlockType> hours, DateTime updatedAt})? parseAvailabilityRow(
    Map<String, dynamic>? row,
  ) {
    if (row == null) return null;
    return (
      hours: fromRecurringJson(row['recurring'] as Map<String, dynamic>),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  /// Parses a pulled `public.planned_rides` result set (plan 21-05,
  /// SYNC-03). Unlike [parseProfileRow]/[parseAvailabilityRow] this takes a
  /// `List`, not a nullable single row — `planned_rides` is a growable list
  /// of independent rows, not a single mutable blob, so there is no
  /// `updated_at` comparison here; the caller (`CloudSyncReconciler`) applies
  /// a union merge instead, per plan 21-05's objective. An empty/missing
  /// cloud result set is simply an empty list, not a "no data yet" sentinel.
  List<PlannedRide> parsePlannedRidesRows(List<Map<String, dynamic>> rows) =>
      rows.map(PlannedRide.fromRow).toList();

  /// Pure union-merge algorithm for planned rides (plan 21-05, SYNC-03) —
  /// any ride present on either side ends up in [merged] (sorted by start).
  /// [localOnly] is exactly the rides the caller still needs to push to the
  /// cloud (present locally, absent from [cloud]) — `merged` deliberately
  /// does not distinguish that on its own, since a ride either exists or it
  /// doesn't, with no mutable state to diverge on.
  ///
  /// Kept as a plain method with no `SupabaseClient`/outbox dependency so
  /// the merge behavior itself is unit-testable directly against fake
  /// local/cloud inputs — the actual network read and outbox enqueue calls
  /// live in `CloudSyncReconciler.reconcilePlannedRides` (Task 3's
  /// unverified-by-automated-test seam, same split as `parseProfileRow`/
  /// `parseAvailabilityRow` vs. the real `.from(...).select()` call).
  ({List<PlannedRide> merged, List<PlannedRide> localOnly}) mergePlannedRides({
    required List<PlannedRide> local,
    required List<PlannedRide> cloud,
  }) {
    final cloudIds = cloud.map((r) => r.rideId).toSet();
    final localOnly =
        local.where((r) => !cloudIds.contains(r.rideId)).toList();

    final mergedMap = <String, PlannedRide>{
      for (final r in local) r.rideId: r,
    };
    for (final ride in cloud) {
      mergedMap.putIfAbsent(ride.rideId, () => ride);
    }
    final merged = mergedMap.values.toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    return (merged: merged, localOnly: localOnly);
  }
}
