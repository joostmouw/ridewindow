// lib/domain/services/account_switch_resolver.dart
// Pure, SDK-free decision function: given the signed-in Supabase uid and the
// locally stored `account.lastSyncedUid`, decide whether this device has ever
// seen this account before, and if it has seen a *different* one.
//
// This is deliberately the scaled-down, local-only half of what
// ARCHITECTURE.md §5 calls `resolveAccountSync` -- that full resolver also
// compares cloud row existence and updated_at timestamps, neither of which
// exist until Phase 21 creates the schema. This function takes exactly two
// inputs and returns exactly three outcomes; no Supabase SDK, no
// SharedPreferences, matching the existing pure-function convention in
// `lib/domain/services/availability_key.dart`.

/// The three possible outcomes of comparing the newly signed-in uid against
/// the last uid this device synced with.
enum AccountSwitchDecision {
  /// No prior local record exists -- never prompt.
  firstSignIn,

  /// The same account signed in again -- never prompt.
  sameAccount,

  /// A different account than last time signed in -- must prompt the user to
  /// keep the device's local data or start fresh.
  differentAccount,
}

/// Compares [signedInUid] (the account that just signed in) against
/// [lastSyncedUid] (the locally stored `account.lastSyncedUid`, or `null` if
/// no account has ever synced on this device) and returns the resulting
/// [AccountSwitchDecision].
///
/// An empty-string [lastSyncedUid] is treated as [AccountSwitchDecision.differentAccount],
/// not [AccountSwitchDecision.firstSignIn] -- a defensive case (e.g. a
/// corrupted write) where a value, even an empty one, was actually stored
/// must never be silently treated as "no prior account".
AccountSwitchDecision resolveAccountSwitch({
  required String signedInUid,
  required String? lastSyncedUid,
}) {
  if (lastSyncedUid == null) return AccountSwitchDecision.firstSignIn;
  if (lastSyncedUid == signedInUid) return AccountSwitchDecision.sameAccount;
  return AccountSwitchDecision.differentAccount;
}
