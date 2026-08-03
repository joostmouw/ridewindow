import 'package:ridewindow/domain/models/block_type.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';
import 'package:ridewindow/domain/models/user_profile.dart';
import 'package:ridewindow/domain/services/availability_key.dart';

/// Builds the exact parameter map for the `migrate_account_data` RPC (plan
/// 21-02, `supabase/migrations/0001_accounts_sync.sql`) — MIG-05/06/08's
/// canonical payload shape.
///
/// Pure Dart, no Supabase import: this file only builds a `Map`. The actual
/// `client.rpc(kMigrateAccountDataRpc, params: ...)` call lives in
/// `AccountSyncService` (this plan's Task 2), which wraps it behind an
/// injected `migrateFn` seam for testability.
///
/// **Key names match the deployed SQL function's parameter names literally**
/// (PostgREST's `rpc()` binds JSON keys to SQL parameter names verbatim,
/// including the `p_` prefix) — do not rename these without also updating
/// the deployed function.
///
/// **`p_planned_rides` uses camelCase keys** (`rideId`/`startAt`/`endAt`/
/// `plannedScore`), deliberately different from [PlannedRide.toRow]'s
/// snake_case row shape (`ride_id`/`start_at`/`end_at`/`planned_score`) —
/// the SQL function's loop body reads `ride->>'rideId'` etc. from each JSONB
/// array element, because this payload is a client-constructed JSON array
/// for one specific RPC call, not a direct table row. `user_id` is
/// deliberately omitted from each element: the SQL function derives it once,
/// for the whole call, from `auth.uid()`.
Map<String, dynamic> buildMigrationRpcParams({
  required UserProfile profile,
  required Map<DateTime, BlockType> availabilityHours,
  required List<PlannedRide> plannedRides,
}) {
  return {
    'p_temp_min_ideal_c': profile.tolerances.tempMinIdealC,
    'p_temp_max_ideal_c': profile.tolerances.tempMaxIdealC,
    'p_wind_max_ideal_kmh': profile.tolerances.windMaxIdealKmh,
    'p_rain_max_ideal_mm': profile.tolerances.rainMaxIdealMm,
    'p_allowed_durations': profile.allowedDurations,
    'p_theme': profile.theme,
    'p_locale': profile.locale,
    'p_location_override': profile.locationOverride,
    'p_user_name': profile.userName,
    'p_notif_evening_before': profile.notifEveningBefore,
    'p_notif_morning_of': profile.notifMorningOf,
    'p_notif_weekly_digest': profile.notifWeeklyDigest,
    'p_availability_recurring': toRecurringRow(availabilityHours),
    'p_planned_rides': [
      for (final r in plannedRides)
        {
          'rideId': r.rideId,
          'startAt': r.start.toIso8601String(),
          'endAt': r.end.toIso8601String(),
          'plannedScore': r.plannedScore,
        },
    ],
  };
}
