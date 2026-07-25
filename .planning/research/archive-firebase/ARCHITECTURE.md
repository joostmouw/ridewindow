# Architecture Research: Accounts + Cloud Sync Integration

**Domain:** Adding Firebase Auth + Firestore sync to an existing shipped Flutter app (Riverpod 3.x + Drift + SharedPreferences, Android + Web/PWA, one codebase)
**Researched:** 2026-07-25
**Confidence:** HIGH (all integration points read directly from `lib/`; package versions verified live on pub.dev; Riverpod/Firestore behavior verified against official docs)

This is not generic Firebase advice. Every file path below was confirmed by reading the actual RideWindow codebase (~20,400 LOC, `lib/`). Firebase Auth/Firestore are **not yet integrated** — no `google-services.json`, no `firebase_options.dart`, no Firebase packages in `pubspec.yaml`, `firebase.json` only configures Hosting today. This is greenfield wiring on top of a mature local-only app.

---

## 1. Auth state as a Riverpod provider

**Idiomatic Riverpod 3.x shape** (matches the codebase's existing function-provider idiom, e.g. `openMeteoClientProvider` / `weatherRepositoryProvider` in `lib/providers/app_database_provider.dart`):

```dart
// lib/providers/auth_notifier.dart (NEW)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

/// Streams the signed-in FirebaseAuth user. keepAlive: the router redirect
/// and every downstream data provider depend on this — it must not be
/// disposed and re-subscribed every time its listener count drops to zero.
@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) {
  return FirebaseAuth.instance.authStateChanges();
}

/// Convenience derived provider — most call sites only need the uid.
@riverpod
String? currentUserId(Ref ref) {
  return ref.watch(authStateProvider).value?.uid;
}
```

Use `@Riverpod(keepAlive: true)` (function form, `Stream<User?>` return), not `StreamProvider` (legacy syntax still works but the codebase never uses it) and not `StateProvider`/`StateNotifierProvider` (explicitly legacy in Riverpod 3.0 per `CLAUDE.md`). This is the same pattern already used for `routerProvider` and `appDatabaseProvider` (`@Riverpod(keepAlive: true)` top-level function), so it fits house style exactly.

**How downstream providers react without stale-data leaks between accounts:**

The codebase already has the reactive-rebuild wiring proven in `lib/providers/location_provider.dart`, which does `await ref.watch(profileProvider.future)` inside its own `build()` — when the watched provider's data changes, Riverpod discards the old state and reruns `build()` from scratch. Apply the identical pattern with `authStateProvider`:

| Notifier | File | Change |
|---|---|---|
| `ProfileNotifier` | `lib/providers/profile_notifier.dart` | `build()` adds `final uid = ref.watch(authStateProvider).value?.uid;` as its first line, before reading SharedPreferences. |
| `AvailabilityNotifier` | `lib/providers/availability_notifier.dart` | Same — `build()` watches `authStateProvider` first. |
| `PlannedRidesNotifier` | `lib/providers/planned_rides_notifier.dart` | **Must change more.** It is `@Riverpod(keepAlive: true)` and currently **synchronous**, reading via `ref.read(sharedPrefsProvider)` (a one-shot read, not reactive to anything). It needs to become `Future<List<PlannedRide>> build() async` and `ref.watch(authStateProvider)` so an account switch forces a rebuild — today, nothing would clear it on sign-out/switch. |

Because these are plain `@riverpod` (auto-dispose by default in Riverpod 3.0 — `AutoDisposeNotifier` was unified into `Notifier`) except `PlannedRidesNotifier` and the router/database which are explicitly `keepAlive`, watching `authStateProvider` inside `build()` is what prevents leaks: **any** auth emission (sign-in, sign-out, or a different Google account signing in) invalidates the dependency graph and reruns `build()`, so in-memory state can never silently keep showing account A's data after account B signs in.

**Sign-out is not "wipe local data."** The app must keep working exactly as v1.0/v2.0 did for a signed-out user (accounts are additive). On `authState` → `null`, `build()` should fall back to plain local SharedPreferences reads with no cloud involvement — never clear the on-device cache.

**The actual leak risk is account A → account B on the same device**, because SharedPreferences today holds no ownership tag — any data written while A was signed in is still sitting in SharedPreferences when B signs in on the same phone/browser. This is solved by the sync resolver in section 5, not by the provider layer alone — the provider layer's job is only to guarantee `build()` reruns; deciding *what* the rerun does with pre-existing local data is the resolver's job.

---

## 2. Repository seam

**Actual current call sites** (verified via `grep -rn "SharedPreferences.getInstance\|prefs\."`, not assumed):

| File | Pattern | Notes |
|---|---|---|
| `lib/providers/profile_notifier.dart` | `SharedPreferences.getInstance()` called fresh in `build()` + **8 separate mutator methods** (`updateTolerances`, `toggleDuration`, `setLocale`, `setTheme`, `setLocationOverride`, `setUserName`, `setNotifEveningBefore`, `setNotifMorningOf`, `setNotifWeeklyDigest`), each doing its own read-instance → write-key → `state = AsyncData(...)`. | 11 distinct SharedPreferences keys (`profile.tempMinIdealC`, `profile.tempMaxIdealC`, `profile.windMaxIdealKmh`, `profile.rainMaxIdealMm`, `profile.allowedDurations`, `profile.theme`, `profile.locationOverride`, `profile.userName`, `profile.locale`, `profile.notifEveningBefore`, `profile.notifMorningOf`, `profile.notifWeeklyDigest`). |
| `lib/providers/availability_notifier.dart` | `SharedPreferences.getInstance()` in `build()` and in the single private `_persist()` used by all 5 mutators (`toggleCustomHour`, `setCustomHours`, `seedPreset`, `importCalendarBlocks`, `clearAll`). | One key: `availability.blockedHours`, format `"<ISO8601>|<blocktype>"` string list. Already funnels through one `_persist()` — best of the three. |
| `lib/providers/planned_rides_notifier.dart` | Uses `ref.read(sharedPrefsProvider)` (the app-wide `Provider<SharedPreferences>` defined in `lib/app/router.dart`), **not** `SharedPreferences.getInstance()` directly — an existing inconsistency versus the other two notifiers. | One key: `planned_rides`, JSON-encoded list. |
| `lib/platform/background_task.dart` | Its own **third, independent copy** of the SharedPreferences key strings (`_kTempMin`, `_kTempMax`, `_kWindMax`, `_kRainMax`, `_kDurations`, and the literal string `'availability.blockedHours'`), with a code comment admitting it: *"gespiegeld van ProfileNotifier"* (mirrored from ProfileNotifier). Runs in the WorkManager isolate — **cannot use Riverpod**, must take a `SharedPreferences` instance directly. | Read-only for profile/availability; only writes `weather.lastRefreshed`. This duplication already exists today and is a real bug-risk (add a profile field, forget to mirror it here) — the repository seam is a chance to fix it, not just to add cloud sync. |

**Recommendation: one repository per data domain, with an optional cloud sink injected — not two parallel implementations (LocalOnly vs LocalPlusCloud).**

Why not interface + two implementations: a `LocalPlusCloudProfileRepository` would have to re-implement 100% of `LocalProfileRepository`'s SharedPreferences logic and then add cloud calls on top — there is no behavioral divergence to justify polymorphism, only an additive step. For a solo dev, that's two files to keep in sync for zero benefit. Riverpod already gives you the seam you'd normally use polymorphism for: override the provider in tests with a fake `FirebaseFirestore` (e.g. `fake_cloud_firestore` package), not a fake repository class.

Concrete shape:

```dart
// lib/data/repositories/profile_repository.dart (NEW)
// Plain Dart class — no Riverpod, no BuildContext — so it can be constructed
// both from a @riverpod provider AND from background_task.dart's isolate.
class ProfileRepository {
  ProfileRepository(this._prefs, {FirebaseFirestore? cloud, this.uid})
      : _cloud = cloud;

  final SharedPreferences _prefs;
  final FirebaseFirestore? _cloud; // null when signed out — cloud writes become no-ops
  final String? uid;

  static const _keyTempMin = 'profile.tempMinIdealC';
  // ...all 11 keys, moved here from ProfileNotifier and background_task.dart —
  // single source of truth, used by both.

  Future<UserProfile> readLocal() { /* exact logic moved from ProfileNotifier.build() */ }

  Future<void> writeLocal(UserProfile profile) async {
    // writes all 11 keys + a new 'profile.updatedAt' timestamp (see §5 — this
    // key does not exist today and must be added for conflict resolution).
  }

  Future<void> writeCloud(UserProfile profile) async {
    if (_cloud == null || uid == null) return; // signed-out: silent no-op
    await _cloud.doc('users/$uid').set(profile.toFirestore(), SetOptions(merge: true));
  }

  Future<void> save(UserProfile profile) async {
    await writeLocal(profile);
    unawaited(writeCloud(profile)); // fire-and-forget — see §4
  }
}
```

Same shape for `AvailabilityRepository` (`lib/data/repositories/availability_repository.dart`, NEW) and `PlannedRidesRepository` (`lib/data/repositories/planned_rides_repository.dart`, NEW). `background_task.dart` switches from its mirrored key constants to `ProfileRepository(prefs).readLocal()` / `AvailabilityRepository(prefs).readLocal()` — read-only, no `cloud` argument needed since the isolate never touches Firestore (§4). This is a strict simplification of the isolate file, not an addition.

`ProfileNotifier` / `AvailabilityNotifier` / `PlannedRidesNotifier` become thin: `build()` calls `repository.readLocal()` (optionally reconciled against cloud per §5), and every mutator becomes `await repository.save(next); state = AsyncData(next);` instead of hand-rolling SharedPreferences calls inline.

---

## 3. Firestore document model

Derived from the **actual** models read in `lib/providers/profile_notifier.dart`, `lib/providers/availability_notifier.dart`, `lib/domain/services/availability_key.dart`, and `lib/providers/planned_rides_notifier.dart` — not invented.

### `users/{uid}` — profile (single document)

```jsonc
// users/{uid}
{
  "tolerances": { "tempMinIdealC": 12.0, "tempMaxIdealC": 26.0, "windMaxIdealKmh": 15.0, "rainMaxIdealMm": 0.5 },
  "allowedDurations": [2, 3, 5],
  "theme": "system",
  "locale": "nl",
  "locationOverride": "Amsterdam",   // nullable
  "userName": "Joost",               // nullable
  "notifEveningBefore": false,
  "notifMorningOf": false,
  "notifWeeklyDigest": false,
  "updatedAt": <server timestamp>,   // NEW field, needed for §5 conflict resolution
  "email": "joost.mouw@...",         // denormalized from FirebaseAuth for admin visibility
  "createdAt": <server timestamp>
}
```
Maps 1:1 onto `UserProfile` in `profile_notifier.dart`. Trivially small (well under Firestore's 1 MiB/doc limit — this document will be a few hundred bytes). One write per profile mutation; recommend `SetOptions(merge: true)` per field group so a tolerance change doesn't require re-sending `notifWeeklyDigest` etc.

### `users/{uid}/availability/current` — weekly pattern (single document, subcollection for future extensibility)

This is the important one — it must match the **actual** in-memory week-pattern model already built by `lib/domain/services/availability_key.dart`'s `BlockedHours` class, not the raw SharedPreferences string-list format. `BlockedHours` already splits blocked hours into exactly two buckets:

- **`_recurring`**: `Map<int, BlockType>` keyed by `weekday(1-7) * 24 + hour(0-23)` — this is `BlockType.work` and `BlockType.custom`, i.e. the actual weekly template ("every Tuesday 09–17 is work").
- **`_exact`**: `Map<DateTime, BlockType>` keyed by canonical date+hour — this is `BlockType.calendar` only, i.e. one-off imports from a specific Google Calendar event on a specific date.

Firestore shape mirrors this split directly:

```jsonc
// users/{uid}/availability/current
{
  "recurring": {
    "1-9": "work", "1-10": "work", "1-11": "work", /* ... up to 168 possible "weekday-hour" keys */
    "6-14": "custom"
  },
  "version": 1,
  "updatedAt": <server timestamp>
}
```
Max 168 entries (`7 days × 24 hours`), each key ~4 chars + value ~6 chars → worst case a few KB, nowhere near the 1 MiB limit even if every hour of every day were individually blocked.

**Deliberate exclusion — `BlockType.calendar` (`_exact`) entries do NOT sync.** They are date-specific, expire naturally as weeks roll over, and are trivially re-derivable on any device by re-running the existing "Import from Calendar" button (`_importFromCalendar` in `lib/features/availability/availability_screen.dart`, which calls `CalendarService().getEvents(...)`) against the same Google account's calendar. Syncing them would mean an unbounded, ever-growing map of past-dated keys sitting in the cloud doc forever with no natural cleanup path — the same "don't sync derived data" principle CLAUDE.md already applies to the Drift forecast cache. Flag this explicitly to the roadmapper/planner as a deliberate scope cut, not an oversight.

Firestore-key note: Firestore map keys cannot contain `/` but `weekday-hour` strings like `"1-9"` are safe. Alternative considered: a 168-length array indexed by `weekday*24+hour` — rejected because sparse map keys are self-documenting and cheaper to diff/merge than a mostly-empty array.

### `users/{uid}/plannedRides/{rideId}` — subcollection, not an array field

`PlannedRide` (`lib/providers/planned_rides_notifier.dart`) has `start`, `end`, `plannedScore`. Unlike profile/availability, this list **grows over the user's lifetime with the app** (every planned ride is appended; today's local code doesn't even prune past rides from storage — `build()` filters them out of the returned `state` but only rewrites SharedPreferences on the next `add()`/`remove()` call). Embedding this as an array field on the `users/{uid}` doc would mean **rewriting the entire ride history on every single add/remove** — bad for both the 1 MiB ceiling over years of use and for Firestore write cost (each write bills for the whole document). Use a subcollection instead:

```jsonc
// users/{uid}/plannedRides/{rideId}
{
  "start": <timestamp>,
  "end": <timestamp>,
  "plannedScore": 87.5,
  "createdAt": <server timestamp>
}
```
`rideId`: use a deterministic id derived from `start.toIso8601String()` (sanitized, e.g. replace `:` with `-`) rather than Firestore's random auto-id — this makes `add()` naturally idempotent (matches the existing local dedup check `state.any((r) => r.start == ride.start && r.end == ride.end)`) and makes `remove()` a direct `.doc(id).delete()` instead of a query. One read per ride shown, one write per add/remove — matches the granularity of today's local mutations far better than a monolithic array would.

### `feedback/{feedbackId}` — top-level collection, not a user subcollection (Phase 2, not Phase 1)

Not asked for in Phase 1 scope, but the milestone's stated purpose for accounts explicitly includes replacing `lib/features/profile/feedback_dialog.dart`'s `mailto:` flow (see `buildFeedbackMailtoUri`) with an account-backed record. Recommend **top-level** `feedback` collection (not `users/{uid}/feedback/{id}`) with a `userId` field, because the actual reader of this data is Joost via the Firebase console/admin tooling, not the submitting user browsing their own feedback back — a top-level collection is what you scan/filter across all users; a subcollection would require a collection-group query for the same result with more setup.

```jsonc
// feedback/{feedbackId}
{
  "userId": "<uid>",
  "rating": 4,               // 1-5, mirrors _rating in feedback_dialog.dart
  "comment": "felt colder than the score suggested",
  "createdAt": <server timestamp>,
  "context": {
    "tolerances": { "tempMinIdealC": 12.0, "tempMaxIdealC": 26.0, "windMaxIdealKmh": 15.0, "rainMaxIdealMm": 0.5 },
    "forecastSummary": "~14°C, droog, 18km/u wind",   // CalendarService.buildWeatherSummary() already produces this exact string shape — reuse it
    "appVersion": "1.0.11+12",
    "platform": "android"     // or "web"
  }
}
```
Security rule: `allow create: if request.auth.uid == request.resource.data.userId;` and no client-side `read`/`list` at all (Joost reads via console). Small per-document (well under limits); write-only from the client keeps this cheap and simple.

---

## 4. Sync trigger points — background sync is explicitly **OUT** for this milestone

Confirmed from `lib/platform/background_task.dart`'s own doc comment: *"Draait volledig isolate-safe: geen Riverpod, geen foreground-staat"* (runs fully isolate-safe: no Riverpod, no foreground state). The WorkManager callback isolate today touches exactly two things: Drift (forecast cache — explicitly excluded from sync per the milestone brief) and SharedPreferences for (a) read-only profile/availability values used to compute the next slot for the home-screen widget, and (b) one write of `weather.lastRefreshed`, a device-local cache timestamp that has no cloud meaning. **The isolate never writes user data that needs to sync.** There is therefore nothing for it to push, and no reason to give it a Firebase dependency.

Explicit answer: **no Firebase initialization inside `callbackDispatcher()`/`_runWeatherRefresh()` in this milestone.** Adding `Firebase.initializeApp()` to that isolate would require its own per-isolate init (Firebase plugin state does not cross isolate boundaries) purely to read data it already gets correctly from local SharedPreferences — there is no write to push. If a future milestone needs the background isolate to push (e.g. server-side notifications, phase 5 of `v3.0-ACCOUNTS.md`), that is a deliberately separate, later piece of work, not something to build speculatively now.

Where sync **does** happen:

| Trigger | What | Where |
|---|---|---|
| **Sign-in** (once, `authStateChanges` transitions `null → User`) | Run the migration/conflict resolver (§5): decide push-local, pull-cloud, or prompt. | New `AccountSyncService.onSignIn(uid)`, called from wherever the "Sign in with Google" button lives (likely `lib/features/profile/profile_screen.dart`, an Account section — no dedicated sign-in screen needed for 6-screen scope). |
| **Every local write** (profile toggle, availability cell tap, ride planned/unplanned) | Local write happens first and unconditionally (app must work identically offline/signed-out); a cloud write is fired **after**, fire-and-forget, only if `authStateProvider` currently resolves to a user. | `ProfileRepository.save()` / `AvailabilityRepository.save()` / `PlannedRidesRepository.add()`/`remove()` per §2. This is genuinely "sync on every write" — appropriate here because these are tiny, infrequent, user-initiated mutations (a settings toggle, not a high-frequency stream), so per-write Firestore cost is negligible and there is no batching benefit worth the added complexity. |
| **App start (foreground, both platforms)** | `authStateProvider` resolves before/alongside the existing cold-start weather fetch; if signed in, the two rebuilt notifiers (`ProfileNotifier`, `AvailabilityNotifier`) read local **and** attach a Firestore snapshot listener (`.snapshots()`) for that document. **Do not block the 2-second cold-start budget on a Firestore round-trip** — return the local read immediately from `build()`, let the cloud listener update `state` asynchronously if/when it disagrees (same eventually-consistent pattern the app already uses for weather refresh). | `ProfileNotifier.build()` / `AvailabilityNotifier.build()`. |
| **Cross-device live update while foregrounded** | Firestore's `.snapshots()` listener is the mechanism that gives cross-device sync "for free" without polling or WorkManager on either platform — if the web PWA is open and Android writes an availability change, Firestore pushes it to the open web tab in real time. This directly satisfies "Android and web become one app" from the milestone brief with zero new background-execution surface. | Same providers, via `ref.listen`/stream subscription inside the repository's cloud read path. |
| **Web page load / foreground refresh** | No change needed beyond the above — web already has no `workmanager` and refreshes weather on load/focus (`kIsWeb` branch in `lib/main.dart`); the Firestore listener piggybacks on the same "app came to foreground" moment. | `lib/main.dart` (already branches on `kIsWeb`, no new branch needed for this). |
| **Android background (WorkManager isolate)** | **Out of scope, see above.** | N/A — deliberately unchanged `lib/platform/background_task.dart`. |

---

## 5. Migration path — first-login and second-device conflict as a dedicated, testable seam

**The concrete gap found while reading the code: neither `ProfileNotifier` nor `AvailabilityNotifier` currently stamps a "last modified" time anywhere.** `profile_notifier.dart`'s 8 mutators and `availability_notifier.dart`'s `_persist()` write straight to their value keys with no timestamp key at all. This must be added — it is the prerequisite for *any* conflict decision (LWW or otherwise), not an optional nice-to-have. Add `profile.updatedAt` and `availability.updatedAt` (epoch-ms ints, mirroring the existing `weather.lastRefreshed` pattern already in `background_task.dart`) written by `ProfileRepository.writeLocal()` / `AvailabilityRepository.writeLocal()` on every save.

**Second required new key: `account.lastSyncedUid`.** Today SharedPreferences has no concept of "which account does this local data belong to." Without it, the app cannot distinguish "this is a first login and this local data is genuinely mine" from "a different Google account just signed in on this device and this local data belongs to whoever was signed in before" — the exact scenario the milestone's open design question is about. Store the uid after every successful resolved sync; compare it on the next sign-in.

**The seam — a pure, testable resolver function, not scattered conditionals:**

```dart
// lib/domain/services/account_sync_resolver.dart (NEW)
// Pure function: no Firebase SDK, no SharedPreferences — takes plain values,
// returns a decision. Fully unit-testable without mocks, same spirit as the
// existing pure functions in availability_key.dart (canonicalHourKey, etc).

enum SyncDecision { pushLocalToCloud, pullCloudToLocal, promptUser, noop }

SyncDecision resolveAccountSync({
  required String uid,
  required String? lastSyncedUid,     // from local 'account.lastSyncedUid'
  required bool cloudDocExists,
  required DateTime? cloudUpdatedAt,
  required DateTime? localUpdatedAt,  // from local 'profile.updatedAt' / 'availability.updatedAt'
}) {
  final sameDeviceSameAccount = lastSyncedUid == uid;

  if (!cloudDocExists) {
    // Empty account — the only case where "local wins" is unconditionally
    // correct, per the milestone's accepted decision.
    return SyncDecision.pushLocalToCloud;
  }

  if (!sameDeviceSameAccount) {
    // A DIFFERENT account (or no prior account) was last synced on this
    // device. Local SharedPreferences data is not provably this user's —
    // do not push it over the existing cloud doc. Cloud wins silently;
    // local device state gets overwritten by the pull in §4.
    return SyncDecision.pullCloudToLocal;
  }

  // Same account, same device, cloud doc already exists (e.g. re-login after
  // sign-out, or a second device that has ALSO synced this uid before): this
  // is the genuine two-writers-diverged case. Timestamps decide when they're
  // unambiguous; ambiguity is surfaced to the user rather than guessed.
  if (localUpdatedAt == null || cloudUpdatedAt == null) return SyncDecision.promptUser;
  final delta = localUpdatedAt.difference(cloudUpdatedAt).abs();
  if (delta < const Duration(seconds: 5)) return SyncDecision.noop; // already in sync
  return localUpdatedAt.isAfter(cloudUpdatedAt)
      ? SyncDecision.pushLocalToCloud
      : SyncDecision.pullCloudToLocal;
}
```

```dart
// lib/services/account_sync_service.dart (NEW)
// Orchestrator — owns the Firebase/SharedPreferences calls, delegates the
// actual decision to the pure resolver above, then applies it and shows the
// prompt dialog if promptUser is returned. This is the ONE place the
// migration/conflict logic lives — ProfileNotifier and AvailabilityNotifier
// never need their own migration branches.
class AccountSyncService {
  Future<void> onSignIn(String uid) async {
    // 1. read local profile.updatedAt / availability.updatedAt + account.lastSyncedUid
    // 2. read cloud users/{uid} + users/{uid}/availability/current (existence + updatedAt)
    // 3. call resolveAccountSync() for each domain (profile, availability can
    //    genuinely diverge independently — e.g. profile synced before but
    //    availability never touched on this device)
    // 4. apply: push (repository.writeCloud), pull (repository.writeLocal from
    //    cloud snapshot), or show a two-button dialog ("Use this device's data" /
    //    "Use data from the cloud") and apply the user's choice
    // 5. write account.lastSyncedUid = uid locally
  }
}
```

`AccountSyncService.onSignIn` is the single sign-in trigger point named in §4. Because `resolveAccountSync` takes no SDK types, `gsd-planner` can scope a task purely around this function with a plain unit test file (`test/domain/services/account_sync_resolver_test.dart`) before any Firebase wiring exists at all — genuinely buildable and testable in isolation, first.

---

## 6. New vs modified — explicit file list

### New files

| File | Purpose |
|---|---|
| `lib/firebase_options.dart` | Generated by `flutterfire configure` against the existing `my-project-joost` Firebase project. |
| `android/app/google-services.json` | Generated alongside `firebase_options.dart`; Android build needs the `com.google.gms.google-services` Gradle plugin added to `android/app/build.gradle.kts` and `android/build.gradle.kts` (currently absent — verified, only `com.android.application` is registered). |
| `lib/providers/auth_notifier.dart` (+ `.g.dart`) | `authStateProvider`, `currentUserIdProvider` (§1). |
| `lib/services/account_sync_service.dart` | Sign-in orchestrator (§5). |
| `lib/domain/services/account_sync_resolver.dart` | Pure conflict-decision function (§5) — build and unit-test this first, needs no Firebase. |
| `lib/data/repositories/profile_repository.dart` | Extracted local+cloud profile persistence (§2). |
| `lib/data/repositories/availability_repository.dart` | Extracted local+cloud availability persistence (§2). |
| `lib/data/repositories/planned_rides_repository.dart` | Extracted local+cloud planned-rides persistence (§2). |
| `lib/data/remote/firestore_paths.dart` | Central Firestore path/key constants (`users/{uid}`, `users/{uid}/availability/current`, `users/{uid}/plannedRides/{id}`, `feedback/{id}`) — same centralizing role `availability_key.dart` already plays for local keys. |
| `firestore.rules` | New — `firebase.json` currently has only a `hosting` block; needs a `firestore` block added pointing at this file. |
| Account UI (small) — likely a new widget under `lib/features/profile/`, e.g. `account_section.dart` | Sign-in/sign-out button + signed-in email display. No new *screen*/route needed — fits inside the existing `/profile` route (`lib/features/profile/profile_screen.dart`), same placement pattern as the existing Calendar-connect UI. |
| `test/domain/services/account_sync_resolver_test.dart` | Unit tests for §5's pure resolver. |

### Modified files

| File | Change |
|---|---|
| `pubspec.yaml` | Add `firebase_core` (verified latest: `^4.12.1`), `firebase_auth` (`^6.5.6`), `cloud_firestore` (`^6.7.1`) — all verified live on pub.dev 2026-07-25, published 11 days prior. Confirm against `flutterfire configure`'s pinned versions at implementation time, as FlutterFire ships frequently. |
| `lib/main.dart` | Add `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` early in `main()`, before/alongside the existing parallel `tzFuture`/`prefsFuture` block — must complete before any provider reads `authStateProvider`. Does **not** touch the existing `kIsWeb`-gated WorkManager/CalendarService warmup branches (§4 — no isolate change). |
| `lib/providers/profile_notifier.dart` | `build()` gains `ref.watch(authStateProvider)`; internals delegate to `ProfileRepository` instead of inline `SharedPreferences` calls. |
| `lib/providers/availability_notifier.dart` | Same — watches `authStateProvider`; delegates to `AvailabilityRepository`. |
| `lib/providers/planned_rides_notifier.dart` | Changes from sync `build()` + `ref.read(sharedPrefsProvider)` to async `build()` + `ref.watch(authStateProvider)`; delegates to `PlannedRidesRepository`. |
| `lib/platform/background_task.dart` | Its 3 mirrored SharedPreferences key constants (`_kTempMin` etc., the literal `'availability.blockedHours'`) are deleted; it calls `ProfileRepository(prefs).readLocal()` / `AvailabilityRepository(prefs).readLocal()` instead — a net simplification, zero Firebase added to the isolate (§4). |
| `lib/features/profile/profile_screen.dart` | Adds the account section (sign-in/out button, signed-in state). |
| `lib/features/profile/feedback_dialog.dart` | Phase 2 (not Phase 1 per `v3.0-ACCOUNTS.md`'s own fasering) — replaces `buildFeedbackMailtoUri`/`launchUrl(mailto:)` with a Firestore write to `feedback/{feedbackId}` per §3, still gated on the user being signed in (feedback requires an account per the milestone brief). |
| `firebase.json` | Add a `"firestore"` block (rules + indexes file paths) alongside the existing `"hosting"` block. |
| `android/build.gradle.kts`, `android/app/build.gradle.kts` | Add Google Services Gradle plugin classpath/plugin id. |
| `CLAUDE.md` | Constraints table already flags "No backend" and "Budget" as under revision — this work is what resolves that; update once shipped, per the milestone's own instruction to revise constraints *before* the first line of code. |

### Explicitly unchanged (verified, not guessed)

- `lib/data/database/**` (Drift, forecast cache) — untouched, per the milestone brief's own instruction that derived data must not sync.
- `lib/services/calendar_service.dart` — untouched. It already owns its own `GoogleSignIn.instance` lifecycle (lazy on native via `CAL-02`, eager on web via `warmUpForWeb()`/`CAL-06`) independent of Firebase Auth's own Google credential flow. **Important nuance for the planner:** Firebase Auth's Google sign-in and this file's existing Calendar OAuth both go through `GoogleSignIn.instance` (a singleton in `google_sign_in` 7.x) — the new auth flow must share, not duplicate, `CalendarService`'s `_sharedInitialize()`/`_initFuture` memoization pattern, or the same "`Bad state: init() has already been called`" class of bug this file's own comments describe fixing once already (Rule 1 bugfix, CAL-06 follow-up) will resurface. This is a real integration risk worth its own task, not an aside.
- `lib/app/router.dart` — the `sharedPrefsProvider` definition and onboarding redirect logic stay as-is; no route changes needed for Phase 1 (account UI lives inside the existing `/profile` route).

---

## 7. Suggested build order

Ordered by actual dependency, not by the milestone brief's phase numbering (which groups by user-facing feature, not by what unblocks what):

1. **`account_sync_resolver.dart` + its unit tests.** Zero dependencies — pure Dart, no Firebase SDK, no repository, no UI. Gets the hardest design question (the milestone's own stated "open design question") decided and tested before any infrastructure exists.
2. **Firebase project wiring**: `flutterfire configure`, `firebase_options.dart`, `google-services.json`, Gradle plugin, `pubspec.yaml` deps, `Firebase.initializeApp()` in `main.dart`. Unblocks everything else; no app behavior changes yet.
3. **`authStateProvider`** (+ `currentUserIdProvider`) and the account UI section in `profile_screen.dart` (sign-in/sign-out button only — no data sync wired yet). Verifiable end-to-end on its own: can sign in/out and see the state change, before touching a single existing notifier.
4. **`ProfileRepository` + `AvailabilityRepository` + `PlannedRidesRepository`**, refactoring the three existing notifiers and `background_task.dart` to use them — **local-only behavior first**, no cloud sink wired yet (`cloud: null` everywhere). This is a pure refactor with no user-visible change and is where the SharedPreferences key duplication between `ProfileNotifier`/`AvailabilityNotifier`/`background_task.dart` gets fixed — safe to land and regression-test independently of Firebase.
5. **Firestore document read/write** wired into the repositories from step 4 (§3 shapes), gated on `authStateProvider` resolving to a user, plus `firestore.rules`.
6. **`AccountSyncService.onSignIn`**, wiring the step-1 resolver to the step-2/5 infrastructure — this is where "first login" and "second device" actually become real, testable behaviors instead of a pure function in isolation.
7. **Live cross-device sync** (Firestore `.snapshots()` listeners inside the repositories, §4) — last, because it's the least critical for "accounts work at all" and the easiest to verify manually once 1–6 are solid (open the app on two devices, confirm a change on one shows on the other while both are foregrounded).
8. **Feedback-to-Firestore** (`feedback_dialog.dart` rewrite) — Phase 2 per the milestone's own fasering table; depends on steps 2–3 (needs a signed-in user) but nothing else on this list, so it can run in parallel with steps 4–7 if useful, or simply after Phase 1 ships as the milestone brief already scopes it.

Steps 1–4 have no Firebase dependency and are safe, regression-testable groundwork. Steps 5–7 are where the actual "no backend" constraint gets broken and need the privacy-policy rewrite (a hard release blocker per `PROJECT.md`) to be done in parallel, not after.

---

## Sources

- Codebase (read directly, 2026-07-25): `lib/providers/profile_notifier.dart`, `lib/providers/availability_notifier.dart`, `lib/providers/planned_rides_notifier.dart`, `lib/providers/location_provider.dart`, `lib/providers/gps_permission_notifier.dart`, `lib/providers/app_database_provider.dart`, `lib/domain/services/availability_key.dart`, `lib/providers/availability_presets.dart`, `lib/features/availability/availability_screen.dart`, `lib/platform/background_task.dart`, `lib/services/calendar_service.dart`, `lib/app/router.dart`, `lib/main.dart`, `lib/features/profile/feedback_dialog.dart`, `pubspec.yaml`, `firebase.json`, `.firebaserc`, `android/app/build.gradle.kts`, `.planning/PROJECT.md`, `.planning/milestones/v3.0-ACCOUNTS.md`, `CLAUDE.md`.
- [FlutterFire — Social Authentication (Google Sign-In credential flow)](https://firebase.flutter.dev/docs/auth/social/) — HIGH confidence, official docs.
- [Firebase — Federated identity and social sign-in (Flutter)](https://firebase.google.com/docs/auth/flutter/federated-auth) — HIGH confidence, official docs.
- [Firestore — Access data offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline) — HIGH confidence, official docs; confirms web persistence is opt-in (`enablePersistence`) unlike Android/iOS where it is on by default.
- pub.dev package pages fetched directly 2026-07-25: `firebase_core` 4.12.1, `firebase_auth` 6.5.6, `cloud_firestore` 6.7.1 (all published ~11 days prior) — HIGH confidence, verified live, not from training data.
- Firestore 1 MiB per-document limit and per-document write billing — well-established platform limits, HIGH confidence (standard Firestore documentation knowledge, consistent across all sources checked).

---
*Architecture research for: RideWindow v3.0 Accounts & Sociaal, Phase 1–2 scope*
*Researched: 2026-07-25*
