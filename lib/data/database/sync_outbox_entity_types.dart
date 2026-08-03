// Outbox entity type strings — must match SyncOutboxDao's `entity` column
// values exactly (plain strings, not an enum, because the Drift column is
// TEXT and this keeps encode/decode trivial).
//
// Deliberately NOT in `lib/data/remote/supabase_tables.dart`, even though
// plan 21-03 originally defined them there. `profile_repository.dart` and
// `availability_repository.dart` (plan 21-04) need these to build outbox
// payloads, and both files are reachable from
// `lib/platform/background_task.dart` (REG-05).
// `test/structure/background_task_no_supabase_test.dart` greps every
// reachable import line for the literal substring "supabase" — importing
// `supabase_tables.dart` fails that check purely because of the FILE NAME,
// even though its contents never touch `package:supabase_flutter`. Moving
// these three sync-only constants to a supabase-agnostic file name removes
// the false positive at its root cause instead of weakening the structure
// test.
const kOutboxEntityProfile = 'profile';
const kOutboxEntityAvailability = 'availability';
const kOutboxEntityPlannedRide = 'planned_ride';
