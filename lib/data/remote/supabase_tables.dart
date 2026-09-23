// Central Postgres table/RPC name constants (ARCHITECTURE.md §6) — the
// single source of truth so no file hand-types these as string literals.
const kProfilesTable = 'profiles';
const kAvailabilityTable = 'availability';
const kPlannedRidesTable = 'planned_rides';
const kFeedbackTable = 'feedback';
const kAppEventsTable = 'app_events';
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
// Slice 2 van epic #65, migratie 0010_group_ride_options.sql.
const kGroupRideOptionsTable = 'group_ride_options';
const kGroupRideOptionVotesTable = 'group_ride_option_votes';
const kRedeemFriendInviteRpc = 'redeem_friend_invite';
const kFriendProfilesRpc = 'friend_profiles';

// Clubs (v4.2), migraties 0012 en 0013.
const kGroupsTable = 'groups';
const kGroupMembersTable = 'group_members';
const kGroupInvitesTable = 'group_invites';
const kGroupJoinRequestsTable = 'group_join_requests';
const kCreateGroupRpc = 'create_group';
const kRedeemGroupInviteRpc = 'redeem_group_invite';
const kProposeGroupMemberRpc = 'propose_group_member';
const kAcceptGroupRequestRpc = 'accept_group_request';
