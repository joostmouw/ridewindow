// Central Postgres table/RPC name constants (ARCHITECTURE.md §6) — the
// single source of truth so no file hand-types these as string literals.
const kProfilesTable = 'profiles';
const kAvailabilityTable = 'availability';
const kPlannedRidesTable = 'planned_rides';
const kFeedbackTable = 'feedback';
const kMigrateAccountDataRpc = 'migrate_account_data';
const kDeleteOwnAccountRpc = 'delete_own_account';

/// Outbox entity type strings — must match SyncOutboxDao's `entity` column
/// values exactly (plain strings, not an enum, because the Drift column is
/// TEXT and this keeps encode/decode trivial).
const kOutboxEntityProfile = 'profile';
const kOutboxEntityAvailability = 'availability';
const kOutboxEntityPlannedRide = 'planned_ride';
