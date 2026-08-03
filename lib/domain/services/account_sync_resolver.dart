// lib/domain/services/account_sync_resolver.dart
// Pure, SDK-free decision function: the cloud-aware superset of
// `resolveAccountSwitch` (lib/domain/services/account_switch_resolver.dart,
// Phase 19's local-only resolver, which stays exactly as-is and is composed
// with, not replaced by, this function).
//
// Where `resolveAccountSwitch` only ever compares two locally known uids,
// `resolveAccountSync` additionally knows whether a cloud row exists for this
// account and, if so, when it and the local copy were each last updated. It
// is the single place MIG-01/02/03 (ARCHITECTURE.md §5) get turned into one
// of four concrete decisions. It is called once per domain (profile,
// availability) by `AccountSyncService`, not yet built as of this plan --
// see ARCHITECTURE.md §7 build order. It is explicitly NOT called for
// `planned_rides`, which uses a separate, non-prompting union-merge strategy
// (plan 21-05) because MIG-04 names only profile and availability as the
// domains whose divergence is tracked and prompted on.
//
// Zero imports beyond dart:core, matching the pure-function convention in
// `account_switch_resolver.dart` and `availability_key.dart`.

/// The four possible outcomes of comparing a user's local data against the
/// cloud's data (existence + timestamps) for a single domain (profile or
/// availability).
enum SyncDecision {
  /// Local data should be written to the cloud.
  pushLocalToCloud,

  /// Cloud data should be written to local storage.
  pullCloudToLocal,

  /// Both sides have diverged in a way that cannot be resolved silently --
  /// ask the user which copy to keep.
  promptUser,

  /// Nothing to do -- local and cloud are close enough in time to be
  /// considered the same write.
  noop,
}

/// Decides what should happen to a single domain's data (profile or
/// availability) given the signed-in [userId], the locally stored
/// `account.lastSyncedUid` ([lastSyncedUid]), whether a cloud row exists for
/// this domain ([cloudRowExists]), and the last-updated timestamps on each
/// side ([cloudUpdatedAt], [localUpdatedAt]).
///
/// This function is domain-agnostic: it takes generic timestamps, not a
/// `UserProfile` or an availability map. Callers invoke it once per domain.
///
/// Note on `lastSyncedUid == null`: `sameDeviceSameAccount` is `false`
/// whenever [lastSyncedUid] is `null` (a `String? == String` comparison),
/// which correctly falls into the MIG-02 branch (pull cloud) rather than
/// MIG-01 -- because MIG-01 is gated on `!cloudRowExists`, not on
/// [lastSyncedUid]. A device with no local sync record but a cloud row that
/// already exists is exactly the "second device" case (MIG-02), not "first
/// login" (MIG-01). This is intentional.
SyncDecision resolveAccountSync({
  required String userId,
  required String? lastSyncedUid,
  required bool cloudRowExists,
  required DateTime? cloudUpdatedAt,
  required DateTime? localUpdatedAt,
}) {
  final sameDeviceSameAccount = lastSyncedUid == userId;

  // MIG-01: empty account -- local wins unconditionally, no prompt.
  if (!cloudRowExists) return SyncDecision.pushLocalToCloud;

  // MIG-02: a different (or no) account last synced here. Local data is not
  // provably this user's -- never push it over the existing cloud row.
  if (!sameDeviceSameAccount) return SyncDecision.pullCloudToLocal;

  // MIG-03: same account, same device, cloud row exists -- the genuine
  // two-writers-diverged case. Timestamps decide when unambiguous;
  // ambiguity is surfaced to the user rather than guessed.
  if (localUpdatedAt == null || cloudUpdatedAt == null) {
    return SyncDecision.promptUser;
  }
  final delta = localUpdatedAt.difference(cloudUpdatedAt).abs();
  if (delta < const Duration(seconds: 5)) return SyncDecision.noop;
  return localUpdatedAt.isAfter(cloudUpdatedAt)
      ? SyncDecision.pushLocalToCloud
      : SyncDecision.pullCloudToLocal;
}
