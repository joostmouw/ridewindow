import 'package:ridewindow/domain/models/block_type.dart';
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
}
