import 'package:ridewindow/data/repositories/availability_repository.dart';
import 'package:ridewindow/data/repositories/planned_rides_repository.dart';
import 'package:ridewindow/data/repositories/profile_repository.dart';
import 'package:ridewindow/domain/models/block_type.dart';
import 'package:ridewindow/domain/models/user_profile.dart';
import 'package:ridewindow/domain/services/account_sync_resolver.dart';
import 'package:ridewindow/domain/services/migration_payload.dart';

/// A parsed cloud profile row plus its `updated_at` — the same shape
/// `CloudReconcileService.parseProfileRow()` (plan 21-04) returns.
typedef CloudProfileMeta = ({UserProfile profile, DateTime updatedAt});

/// A parsed cloud availability row plus its `updated_at` — the same shape
/// `CloudReconcileService.parseAvailabilityRow()` (plan 21-04) returns.
typedef CloudAvailabilityMeta = ({
  Map<DateTime, BlockType> hours,
  DateTime updatedAt,
});

/// The two domains the sync resolver (`account_sync_resolver.dart`) runs
/// for — never `planned_rides`, which uses a separate, non-prompting
/// union-merge strategy (plan 21-05).
enum SyncDomain { profile, availability }

/// A single domain whose sync decision could not be resolved silently and
/// needs a user choice (MIG-03's ambiguous branch). Returned by [onSignIn],
/// consumed by [AccountSyncService.resolvePrompt].
class PendingSyncPrompt {
  const PendingSyncPrompt(this.domain);
  final SyncDomain domain;
}

/// The ONE place migration/conflict logic lives (ARCHITECTURE.md §5) — wires
/// the pure sync-decision function in `account_sync_resolver.dart` to the
/// real infrastructure: repositories, the offline outbox, and the
/// `migrate_account_data` RPC.
///
/// Service only, no UI (plan 21-06's scope) — the two-button conflict
/// `AlertDialog` (D-04/D-05) is plan 21-07's job. This service resolves
/// everything it can resolve on its own (push/pull/noop) and returns a small
/// list of "this domain needs a human decision" prompts for anything it
/// can't.
///
/// **Deviation from the plan's illustrative `<interfaces>` sketch:** rather
/// than taking a `CloudReconcileService` directly (that class is
/// deliberately kept free of any network dependency per plan 21-04's own
/// testability note — it only parses already-fetched rows, it never fetches
/// them), this service takes two injected async functions,
/// [readCloudProfile]/[readCloudAvailability], matching the same
/// function-injection pattern already used for [migrateFn] and
/// [writeLastSyncedUid]. The real implementation the caller wires in (plan
/// 21-07) composes `client.from(...).select()...` with
/// `CloudReconcileService.parseProfileRow`/`parseAvailabilityRow` — this
/// service never imports `package:supabase_flutter` itself, and is fully
/// unit-testable with plain fake closures (no mockito, no live Supabase).
class AccountSyncService {
  AccountSyncService({
    required this.profileRepo,
    required this.availabilityRepo,
    required this.plannedRidesRepo,
    required this.readCloudProfile,
    required this.readCloudAvailability,
    required this.migrateFn,
    required this.writeLastSyncedUid,
  });

  final ProfileRepository profileRepo;
  final AvailabilityRepository availabilityRepo;
  final PlannedRidesRepository plannedRidesRepo;

  /// Reads the current cloud profile row for [userId] (parsed, with its
  /// `updated_at`), or `null` if no cloud row exists yet for this user.
  final Future<CloudProfileMeta?> Function(String userId) readCloudProfile;

  /// Reads the current cloud availability row for [userId], or `null` if no
  /// cloud row exists yet for this user.
  final Future<CloudAvailabilityMeta?> Function(String userId)
      readCloudAvailability;

  /// Wraps `client.rpc(kMigrateAccountDataRpc, params: ...)` — invoked
  /// exactly once, only for the genuine first-login case (MIG-05/06).
  final Future<void> Function(Map<String, dynamic> params) migrateFn;

  /// Persists `account.lastSyncedUid` for [userId].
  final Future<void> Function(String userId) writeLastSyncedUid;

  /// Called once, right after sign-in succeeds. [lastSyncedUid] MUST be the
  /// value read from `account.lastSyncedUid` BEFORE the caller's own
  /// account-switch handling (the existing Phase 19 flow in
  /// `account_section.dart`) had a chance to overwrite it for this sign-in —
  /// that flow already persists the new uid to the same key as part of its
  /// own firstSignIn/sameAccount/differentAccount resolution, and it MUST
  /// run before this method (a genuine account switch has to resolve
  /// keep-or-wipe before this method can trust local storage at all — see
  /// plan 21-07's ordering requirement). If this method re-read the key
  /// itself at call time, it would always see the value the switch flow
  /// just wrote (== userId), making the resolver's MIG-02 branch
  /// unreachable. Callers must capture the snapshot first and pass it in.
  ///
  /// Resolves profile and availability independently. Applies every
  /// non-prompt decision immediately. Returns the (possibly empty) list of
  /// domains that need a user choice. If the list is empty,
  /// `account.lastSyncedUid` is already (re-)written by the time this
  /// returns.
  Future<List<PendingSyncPrompt>> onSignIn(
    String userId, {
    required String? lastSyncedUid,
  }) async {
    final profileMeta = await readCloudProfile(userId);
    final availabilityMeta = await readCloudAvailability(userId);

    // MIG-05/06: genuine first login for THIS account — neither domain has
    // a cloud row yet. One atomic RPC populates all three tables from
    // current local state, rather than three independent per-domain pushes.
    if (profileMeta == null && availabilityMeta == null) {
      final profile = profileRepo.readLocal();
      final hours = availabilityRepo.readLocal();
      final rides = plannedRidesRepo.readLocal();
      await migrateFn(
        buildMigrationRpcParams(
          profile: profile,
          availabilityHours: hours,
          plannedRides: rides,
        ),
      );
      await writeLastSyncedUid(userId);
      return const [];
    }

    final prompts = <PendingSyncPrompt>[];

    final profileDecision = resolveAccountSync(
      userId: userId,
      lastSyncedUid: lastSyncedUid,
      cloudRowExists: profileMeta != null,
      cloudUpdatedAt: profileMeta?.updatedAt,
      localUpdatedAt: _localDateTime(profileRepo.readUpdatedAt()),
    );
    if (profileDecision == SyncDecision.promptUser) {
      prompts.add(const PendingSyncPrompt(SyncDomain.profile));
    } else {
      await _applyProfileDecision(profileDecision, profileMeta);
    }

    final availabilityDecision = resolveAccountSync(
      userId: userId,
      lastSyncedUid: lastSyncedUid,
      cloudRowExists: availabilityMeta != null,
      cloudUpdatedAt: availabilityMeta?.updatedAt,
      localUpdatedAt: _localDateTime(availabilityRepo.readUpdatedAt()),
    );
    if (availabilityDecision == SyncDecision.promptUser) {
      prompts.add(const PendingSyncPrompt(SyncDomain.availability));
    } else {
      await _applyAvailabilityDecision(availabilityDecision, availabilityMeta);
    }

    if (prompts.isEmpty) {
      await writeLastSyncedUid(userId);
    }
    return prompts;
  }

  /// Called by the UI (plan 21-07) after the user picks a side for a
  /// prompted domain. [keepLocal] true = pushLocalToCloud, false =
  /// pullCloudToLocal — there is no third choice at this point, the
  /// ambiguity that caused the prompt is resolved by the user's pick.
  Future<void> resolvePrompt(
    PendingSyncPrompt prompt,
    String userId, {
    required bool keepLocal,
  }) async {
    final decision =
        keepLocal ? SyncDecision.pushLocalToCloud : SyncDecision.pullCloudToLocal;
    switch (prompt.domain) {
      case SyncDomain.profile:
        final meta = await readCloudProfile(userId);
        await _applyProfileDecision(decision, meta);
      case SyncDomain.availability:
        final meta = await readCloudAvailability(userId);
        await _applyAvailabilityDecision(decision, meta);
    }
  }

  /// Called by the UI once every prompt from a given [onSignIn] call has
  /// been resolved via [resolvePrompt]. Not called by [onSignIn] itself
  /// when prompts is non-empty — the UI owns sequencing D-05's two dialogs.
  Future<void> markSynced(String userId) => writeLastSyncedUid(userId);

  /// pushLocalToCloud -> enqueue the current local state (local is already
  /// correct, it just needs to reach the cloud). pullCloudToLocal -> write
  /// the cloud data into local storage (MIG-07: this overwrites field
  /// values, it never removes/clears a key) and adopt the cloud timestamp.
  /// noop -> do nothing.
  Future<void> _applyProfileDecision(
    SyncDecision decision,
    CloudProfileMeta? meta,
  ) async {
    switch (decision) {
      case SyncDecision.pushLocalToCloud:
        await profileRepo.enqueueCurrentState();
      case SyncDecision.pullCloudToLocal:
        if (meta == null) return;
        // `enqueue: false` (backlog #57) -- dit is een pull, dus de rij staat
        // al in de cloud. Hem terugduwen bumpt alleen `updated_at` en maakt de
        // cloud kunstmatig nieuwer dan lokaal.
        await profileRepo.save(meta.profile, stamp: false, enqueue: false);
        await profileRepo.stampUpdatedAt(meta.updatedAt);
      case SyncDecision.noop:
      case SyncDecision.promptUser:
        break;
    }
  }

  /// Same shape as [_applyProfileDecision], for availability.
  Future<void> _applyAvailabilityDecision(
    SyncDecision decision,
    CloudAvailabilityMeta? meta,
  ) async {
    switch (decision) {
      case SyncDecision.pushLocalToCloud:
        await availabilityRepo.enqueueCurrentState();
      case SyncDecision.pullCloudToLocal:
        if (meta == null) return;
        // Zelfde reden als bij het profiel (backlog #57).
        await availabilityRepo.save(meta.hours, stamp: false, enqueue: false);
        await availabilityRepo.stampUpdatedAt(meta.updatedAt);
      case SyncDecision.noop:
      case SyncDecision.promptUser:
        break;
    }
  }

  DateTime? _localDateTime(int? epochMs) =>
      epochMs == null ? null : DateTime.fromMillisecondsSinceEpoch(epochMs);
}
