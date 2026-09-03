// Central Postgres table/RPC name constants (ARCHITECTURE.md §6) — the
// single source of truth so no file hand-types these as string literals.
const kProfilesTable = 'profiles';
const kAvailabilityTable = 'availability';
const kPlannedRidesTable = 'planned_rides';
const kFeedbackTable = 'feedback';
const kMigrateAccountDataRpc = 'migrate_account_data';
const kDeleteOwnAccountRpc = 'delete_own_account';

// Outbox entity type strings moved to
// lib/data/database/sync_outbox_entity_types.dart (plan 21-04) — see that
// file's doc comment for why they can no longer live here: repositories
// reachable from lib/platform/background_task.dart (REG-05) need them, and
// this file's own NAME contains "supabase", which breaks
// test/structure/background_task_no_supabase_test.dart's substring check
// even though this file's contents never import package:supabase_flutter.

// Peloton (epic #62, migratie 0002_peloton.sql).
const kFriendshipsTable = 'friendships';
const kFriendInvitesTable = 'friend_invites';
const kGroupRidesTable = 'group_rides';
const kGroupRideParticipantsTable = 'group_ride_participants';
const kRedeemFriendInviteRpc = 'redeem_friend_invite';
const kFriendProfilesRpc = 'friend_profiles';
