# Architecture Research: Accounts + Cloud Sync Integration (Supabase)

**Domain:** Adding Supabase Auth + Postgres sync to an existing shipped Flutter app (Riverpod 3.x + Drift + SharedPreferences, Android + Web/PWA, one codebase)
**Researched:** 2026-07-25 (stack revised from Firebase to Supabase the same day — see `archive-firebase/` for the superseded version and the rationale that survived)
**Confidence:** HIGH for codebase integration points (read directly from `lib/`), HIGH for package versions (verified live on pub.dev), MEDIUM for the offline outbox design (no reference implementation in this codebase; new construction)

Every file path below was confirmed by reading the actual RideWindow codebase (~20,400 LOC, `lib/`). Supabase is **not yet integrated** — no `supabase_flutter` in `pubspec.yaml`, no project provisioned. `firebase.json` configures Hosting only and stays that way: **the PWA keeps deploying to Firebase Hosting**; Supabase supplies Auth + Postgres only. This is greenfield wiring on top of a mature local-only app.

---

## 0. Why Supabase rather than Firebase (decision record)

The milestone was researched against Firebase first. The switch was made before Phase 18 started, on these grounds:

| Factor | Verdict |
|---|---|
| **AUTH-05** (one non-racing Google Sign-In path) | **Decisive for Supabase.** `CalendarService` already owns a memoized `GoogleSignIn.instance.initialize()` gate (`_sharedInitialize`/`_initFuture`, `lib/services/calendar_service.dart:33-44`). Supabase consumes an ID token from that *same* `GoogleSignIn` singleton via `signInWithIdToken`. `firebase_auth` insists on its own Google credential flow alongside it — the exact singleton collision that file's comments already describe fixing once. |
| **REG-03 / SYNC-07** (2s web cold start) | Favours Supabase. `supabase_flutter` is one HTTP + GoTrue client; `firebase_core` + `firebase_auth` + `cloud_firestore` is a substantially larger web payload on a budget the app is already measured against. |
| **SYNC-08** (user A cannot read user B) | Favours Supabase. Postgres RLS policies are testable with plain SQL against the real database — no emulator-vs-deployed-rules gap. |
| **SYNC-12** (batched availability write) | Favours Supabase. One row, one JSONB column — the requirement is satisfied by the data model rather than by discipline. |
| **SYNC-05** (offline edits reach the cloud later) | **Cost of Supabase.** Firestore ships an offline cache and write queue; Supabase ships neither. Mitigated by the fact that Phase 20 makes local storage the source of truth regardless — see §4a, the outbox. |
| Free-tier availability | **Cost of Supabase.** Free projects pause after 7 days with no API requests; Firebase's Spark tier does not pause. See PITFALLS.md #8. |

Sections 1, 2, 5 and the pure resolver in this document are substantially unchanged from the Firebase research — they were never Firebase-specific. Sections 3, 4 and 6 are rewritten.

---

## 1. Auth state as a Riverpod provider

**Idiomatic Riverpod 3.x shape** (matches the codebase's existing function-provider idiom, e.g. `openMeteoClientProvider` / `weatherRepositoryProvider` in `lib/providers/app_database_provider.dart`):

```dart
// lib/providers/auth_notifier.dart (NEW)
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_notifier.g.dart';

/// Streams the signed-in Supabase user. keepAlive: every downstream data
/// provider depends on this — it must not be disposed and re-subscribed
/// every time its listener count drops to zero.
///
/// Note the shape difference from FirebaseAuth.authStateChanges(): Supabase
/// emits AuthState (event + session), not User?. Map it down so call sites
/// stay ignorant of the SDK type.
@Riverpod(keepAlive: true)
Stream<User?> authState(Ref ref) {
  final client = Supabase.instance.client;
  return client.auth.onAuthStateChange.map((s) => s.session?.user);
}

/// Convenience derived provider — most call sites only need the id.
@riverpod
String? currentUserId(Ref ref) => ref.watch(authStateProvider).value?.id;
```

Two Supabase-specific traps for the planner:

1. **`onAuthStateChange` does not replay a synchronous initial value the way `authStateChanges()` does.** The restored session is available synchronously at `client.auth.currentSession` right after `Supabase.initialize()` completes. The provider must seed from `currentSession` and then merge the stream, or a cold start signs the user out visually for a frame. This directly affects AUTH-04 (state survives restart).
2. **Supabase's `User.id` is a Supabase UUID, not the Google account id.** `account.lastSyncedUid` (§5) stores that UUID. The Google identity is available under `user.userMetadata` / `user.identities` and is what AUTH-07 compares against the Calendar-authorized account.

**How downstream providers react without stale-data leaks between accounts** — unchanged from the original research, and still correct. The codebase already has the reactive-rebuild wiring proven in `lib/providers/location_provider.dart`, which does `await ref.watch(profileProvider.future)` inside its own `build()`.

| Notifier | File | Change |
|---|---|---|
| `ProfileNotifier` | `lib/providers/profile_notifier.dart` | `build()` adds `ref.watch(authStateProvider)` as its first line, before reading SharedPreferences. |
| `AvailabilityNotifier` | `lib/providers/availability_notifier.dart` | Same. |
| `PlannedRidesNotifier` | `lib/providers/planned_rides_notifier.dart` | **Must change more.** It is `@Riverpod(keepAlive: true)` and currently **synchronous**, reading via `ref.read(sharedPrefsProvider)` (a one-shot read, reactive to nothing). It needs `Future<List<PlannedRide>> build() async` + `ref.watch(authStateProvider)` so an account switch forces a rebuild — today nothing clears it on sign-out/switch. |

**Sign-out is not "wipe local data."** The app must keep working exactly as v1.0/v2.0 did for a signed-out user (accounts are additive, per the guiding principle in REQUIREMENTS.md). On `authState` → `null`, `build()` falls back to plain local reads with no cloud involvement — never clear the on-device cache. This is AUTH-03.

**The actual leak risk is account A → account B on the same device**, because SharedPreferences holds no ownership tag today. Solved by the resolver in §5, not by the provider layer — the provider layer only guarantees `build()` reruns.

---

## 2. Repository seam

**Actual current call sites** (verified via grep, not assumed) — unchanged by the stack switch:

| File | Pattern | Notes |
|---|---|---|
| `lib/providers/profile_notifier.dart` | `SharedPreferences.getInstance()` fresh in `build()` + **8 separate mutator methods**, each doing read-instance → write-key → `state = AsyncData(...)`. | 11 distinct keys (`profile.tempMinIdealC`, `profile.tempMaxIdealC`, `profile.windMaxIdealKmh`, `profile.rainMaxIdealMm`, `profile.allowedDurations`, `profile.theme`, `profile.locationOverride`, `profile.userName`, `profile.locale`, `profile.notifEveningBefore`, `profile.notifMorningOf`, `profile.notifWeeklyDigest`). |
| `lib/providers/availability_notifier.dart` | `SharedPreferences.getInstance()` in `build()` and in the single private `_persist()` used by all 5 mutators. | One key: `availability.blockedHours`, format `"<ISO8601>\|<blocktype>"` string list. Already funnels through one `_persist()` — best of the three. |
| `lib/providers/planned_rides_notifier.dart` | Uses `ref.read(sharedPrefsProvider)` (the app-wide provider in `lib/app/router.dart`), **not** `SharedPreferences.getInstance()` — an existing inconsistency. | One key: `planned_rides`, JSON-encoded list. |
| `lib/platform/background_task.dart` | Its own **third, independent copy** of the key strings, with a comment admitting it: *"gespiegeld van ProfileNotifier"*. Runs in the WorkManager isolate — **cannot use Riverpod**, must take a `SharedPreferences` instance directly. | Read-only for profile/availability; only writes `weather.lastRefreshed`. This duplication is a real bug-risk today (add a profile field, forget to mirror it) — the seam fixes it. |

**Recommendation: one repository per data domain, with an optional cloud sink injected — not two parallel implementations.**

There is no behavioural divergence between "local" and "local + cloud" to justify polymorphism, only an additive step. Riverpod already gives the test seam: override the provider with a fake `SupabaseClient` rather than a fake repository class.

```dart
// lib/data/repositories/profile_repository.dart (NEW)
// Plain Dart class — no Riverpod, no BuildContext — so it can be constructed
// both from a @riverpod provider AND from background_task.dart's isolate.
class ProfileRepository {
  ProfileRepository(this._prefs, {SupabaseClient? cloud, this.userId})
      : _cloud = cloud;

  final SharedPreferences _prefs;
  final SupabaseClient? _cloud; // null when signed out — cloud writes are no-ops
  final String? userId;

  static const _keyTempMin = 'profile.tempMinIdealC';
  // ...all 11 keys, moved here from ProfileNotifier and background_task.dart —
  // single source of truth, used by both.

  Future<UserProfile> readLocal() { /* exact logic moved from ProfileNotifier.build() */ }

  Future<void> writeLocal(UserProfile p) async {
    // all 11 keys + a new 'profile.updatedAt' (see §5 — does not exist today)
  }

  Future<void> writeCloud(UserProfile p) async {
    if (_cloud == null || userId == null) return; // signed-out: silent no-op
    await _cloud.from('profiles').upsert(p.toRow(userId!));
  }

  Future<void> save(UserProfile p) async {
    await writeLocal(p);          // always, unconditionally, first
    await _outbox.enqueue(...);   // §4a — replaces Firestore's implicit queue
  }
}
```

Same shape for `AvailabilityRepository` and `PlannedRidesRepository`. `background_task.dart` switches from its mirrored key constants to `ProfileRepository(prefs).readLocal()` — read-only, no `cloud` argument, so the isolate never gains a Supabase dependency (REG-05). This is a strict simplification of the isolate file.

`ProfileNotifier` / `AvailabilityNotifier` / `PlannedRidesNotifier` become thin: `build()` calls `repository.readLocal()`, and every mutator becomes `await repository.save(next); state = AsyncData(next);`.

---

## 3. Postgres schema

Derived from the **actual** models in `lib/providers/profile_notifier.dart`, `lib/providers/availability_notifier.dart`, `lib/domain/services/availability_key.dart`, and `lib/providers/planned_rides_notifier.dart`.

Design note: the app is already a SQLite app (Drift). Mirroring local tables to Postgres tables is a far smaller conceptual jump than the document model was, and lets `updated_at` be enforced by a trigger rather than by client discipline.

### `profiles` — one row per user

```sql
create table public.profiles (
  user_id            uuid primary key references auth.users(id) on delete cascade,
  temp_min_ideal_c   real not null,
  temp_max_ideal_c   real not null,
  wind_max_ideal_kmh real not null,
  rain_max_ideal_mm  real not null,
  allowed_durations  int[] not null default '{}',
  theme              text not null default 'system',
  locale             text,
  location_override  text,
  user_name          text,
  notif_evening_before boolean not null default false,
  notif_morning_of     boolean not null default false,
  notif_weekly_digest  boolean not null default false,
  updated_at         timestamptz not null default now(),
  created_at         timestamptz not null default now()
);
```

`on delete cascade` from `auth.users` is what makes AUTH-09 (account deletion removes stored data, not just the login) structurally true rather than a client-side cleanup routine that can half-fail. This is a genuine advantage over the Firebase plan, which needed client-side deletion of each collection.

Columns rather than a single JSON blob: the fields are a known, fixed set, and column-level typing catches the class of silent data-format bug MIG-08 exists to guard against.

### `availability` — one row per user, JSONB weekly pattern

Must match the **actual** in-memory model built by `lib/domain/services/availability_key.dart`'s `BlockedHours`, which already splits blocked hours into two buckets:

- **`_recurring`**: `Map<int, BlockType>` keyed by `weekday(1-7) * 24 + hour(0-23)` — `BlockType.work` and `BlockType.custom`, the weekly template.
- **`_exact`**: `Map<DateTime, BlockType>` keyed by canonical date+hour — `BlockType.calendar` only, one-off Google Calendar imports.

```sql
create table public.availability (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  recurring  jsonb not null default '{}'::jsonb,  -- {"1-9":"work","6-14":"custom"}
  version    int not null default 1,
  updated_at timestamptz not null default now()
);
```

One row, one column, one write — SYNC-12 is satisfied by the schema itself. Max 168 entries (7×24), a few KB worst case.

**Deliberate exclusion — `BlockType.calendar` (`_exact`) entries do NOT sync** (SYNC-10). They are date-specific, expire naturally as weeks roll over, and are re-derivable by re-running the existing "Import from Calendar" button (`_importFromCalendar` in `lib/features/availability/availability_screen.dart`). Syncing them means an unbounded, ever-growing map of past-dated keys with no cleanup path — the same "don't sync derived data" principle already applied to the Drift forecast cache (SYNC-09).

### `planned_rides` — one row per ride

```sql
create table public.planned_rides (
  user_id       uuid not null references auth.users(id) on delete cascade,
  ride_id       text not null,          -- deterministic, derived from start
  start_at      timestamptz not null,
  end_at        timestamptz not null,
  planned_score real not null,
  created_at    timestamptz not null default now(),
  primary key (user_id, ride_id)
);
```

A table rather than an array column on `profiles`: this list grows over the user's lifetime, and a row per ride means add/remove are single-row operations instead of rewriting the whole history.

`ride_id`: derive deterministically from `start.toIso8601String()` (sanitized). This makes `add()` naturally idempotent — matching the existing local dedup check `state.any((r) => r.start == ride.start && r.end == ride.end)` — and makes upsert-on-retry safe, which the outbox (§4a) depends on.

### `feedback` — insert-only from the client

```sql
create table public.feedback (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete set null,  -- NULL = anonymous (FB-03)
  rating      int,
  comment     text,
  context     jsonb,     -- score, weather inputs, tolerances, app version, platform (FB-02)
  created_at  timestamptz not null default now()
);
```

`on delete set null` rather than `cascade`: deleting an account must not silently destroy the feedback record the developer is acting on, but it must stop identifying the user. Note this in the retention answer (PRE-09).

### RLS policies — the whole of SYNC-08

```sql
alter table public.profiles      enable row level security;
alter table public.availability  enable row level security;
alter table public.planned_rides enable row level security;
alter table public.feedback      enable row level security;

create policy "own profile" on public.profiles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
-- identical shape for availability and planned_rides

-- Feedback: create but never read or list (FB-05)
create policy "insert own feedback" on public.feedback
  for insert with check (user_id is null or auth.uid() = user_id);
-- deliberately NO select policy — with RLS on and no select policy, reads
-- return zero rows for every client. Joost reads via the Supabase dashboard,
-- which uses the service role and bypasses RLS.
```

`enable row level security` is the line that matters. A table without it is world-readable through the anon key. Every table above must be created *with* RLS in the same migration, never "we'll add policies later" — see PITFALLS.md #7.

---

## 4. Sync trigger points

Confirmed from `lib/platform/background_task.dart`'s own doc comment: *"Draait volledig isolate-safe: geen Riverpod, geen foreground-staat"*. The WorkManager isolate touches Drift (forecast cache — excluded from sync) and SharedPreferences for read-only profile/availability plus one write of `weather.lastRefreshed`, a device-local cache timestamp with no cloud meaning. **The isolate never writes user data that needs to sync**, so there is nothing to push and no reason to give it Supabase (REG-05).

| Trigger | What | Where |
|---|---|---|
| **Sign-in** (`onAuthStateChange` → signedIn) | Run the migration/conflict resolver (§5): push-local, pull-cloud, or prompt. | New `AccountSyncService.onSignIn(userId)`, called from the account section in `lib/features/profile/profile_screen.dart`. |
| **Every local write** | Local write happens first and unconditionally; the cloud write is enqueued in the outbox (§4a) and drained if online and signed in. | `ProfileRepository.save()` / `AvailabilityRepository.save()` / `PlannedRidesRepository.add()`/`remove()`. |
| **App start / foreground** (both platforms) | Return the local read immediately from `build()` — **never block the 2s cold-start budget on a network round-trip** (SYNC-07). Then fetch the cloud rows asynchronously and reconcile. | `ProfileNotifier.build()` / `AvailabilityNotifier.build()`, plus the existing foreground hook. |
| **Web page load / focus** | No new mechanism — web already refreshes weather on load/focus (`kIsWeb` branch in `lib/main.dart`); the cloud fetch piggybacks on that same moment. | `lib/main.dart` (already branches on `kIsWeb`). |
| **Android background (WorkManager isolate)** | **Out of scope.** Deliberately unchanged. | N/A — `lib/platform/background_task.dart` (REG-05). |

**Cross-device propagation is fetch-on-foreground, not realtime.** SYNC-04 is written as "appears on the other after the app is opened or brought to the foreground", and realtime listeners are explicitly deferred in REQUIREMENTS.md. This is the one place where Firestore's `.snapshots()` would have given something for free that Supabase Realtime would need to be wired for — and the requirement deliberately does not ask for it. Supabase Realtime remains available for a later milestone without schema changes.

### 4a. The outbox — SYNC-05 without Firestore's queue

This is the one piece of genuinely new construction the stack switch forces. Firestore queues offline writes implicitly; Supabase does not.

The app already has Drift, and Phase 20 already makes local storage the source of truth. So the outbox is a Drift table, not new infrastructure:

```dart
// lib/data/database/tables/sync_outbox.dart (NEW)
// id | entity ('profile'|'availability'|'planned_ride') | entity_key
//    | payload (JSON) | queued_at | attempts | last_error
```

Rules that keep this small rather than a sync engine:

- **Coalesce per entity key.** Toggling a tolerance slider five times leaves *one* pending row for `profile`, not five. The payload is the whole current entity, not a delta — so replaying the newest row is always correct and ordering between entities never matters.
- **Every cloud write is an upsert keyed by `user_id` (+ `ride_id`).** Combined with coalescing, replay is idempotent, which is what makes "retry on reconnect" safe without transaction bookkeeping.
- **Drain on: successful sign-in, app foreground, and after any successful cloud write.** No timer, no background isolate, no connectivity listener in this milestone — those are the parts that turn an outbox into a sync engine.
- **The outbox is the source of SYNC-06** ("user can see whether data is synced"): pending rows exist ⇒ show pending; empty ⇒ show synced. No separate state to maintain.
- **Never block the UI on it.** The local write already succeeded; the outbox is what happens afterwards.

Deliberately out: exponential backoff schedules, conflict detection inside the outbox (§5 owns conflict, and only at sign-in), and partial-field merges.

---

## 5. Migration path — first-login and second-device conflict

Unchanged by the stack switch. This section was never Firebase-specific and remains the highest-value part of the research.

**The concrete gap found while reading the code: neither `ProfileNotifier` nor `AvailabilityNotifier` stamps a "last modified" time anywhere.** `profile_notifier.dart`'s 8 mutators and `availability_notifier.dart`'s `_persist()` write straight to their value keys with no timestamp. This must be added — it is the prerequisite for *any* conflict decision. Add `profile.updatedAt` and `availability.updatedAt` (epoch-ms ints, mirroring the existing `weather.lastRefreshed` pattern in `background_task.dart`), written by the repositories on every save. This is MIG-04.

**Second required new key: `account.lastSyncedUid`.** SharedPreferences today has no concept of "which account does this local data belong to." Without it the app cannot distinguish "first login, this local data is genuinely mine" from "a different Google account just signed in on this device". Store the Supabase user UUID after every successful resolved sync; compare on the next sign-in.

**The seam — a pure, testable resolver, not scattered conditionals:**

```dart
// lib/domain/services/account_sync_resolver.dart (NEW)
// Pure function: no Supabase SDK, no SharedPreferences — plain values in,
// decision out. Fully unit-testable without mocks, same spirit as the
// existing pure functions in availability_key.dart.

enum SyncDecision { pushLocalToCloud, pullCloudToLocal, promptUser, noop }

SyncDecision resolveAccountSync({
  required String userId,
  required String? lastSyncedUid,     // local 'account.lastSyncedUid'
  required bool cloudRowExists,
  required DateTime? cloudUpdatedAt,
  required DateTime? localUpdatedAt,
}) {
  final sameDeviceSameAccount = lastSyncedUid == userId;

  // MIG-01: empty account — local wins unconditionally, no prompt.
  if (!cloudRowExists) return SyncDecision.pushLocalToCloud;

  // MIG-02: a different (or no) account last synced here. Local data is not
  // provably this user's — never push it over the existing cloud row.
  if (!sameDeviceSameAccount) return SyncDecision.pullCloudToLocal;

  // MIG-03: same account, same device, cloud row exists — the genuine
  // two-writers-diverged case. Timestamps decide when unambiguous;
  // ambiguity is surfaced to the user rather than guessed.
  if (localUpdatedAt == null || cloudUpdatedAt == null) return SyncDecision.promptUser;
  final delta = localUpdatedAt.difference(cloudUpdatedAt).abs();
  if (delta < const Duration(seconds: 5)) return SyncDecision.noop;
  return localUpdatedAt.isAfter(cloudUpdatedAt)
      ? SyncDecision.pushLocalToCloud
      : SyncDecision.pullCloudToLocal;
}
```

```dart
// lib/services/account_sync_service.dart (NEW)
// Orchestrator — owns the Supabase/SharedPreferences calls, delegates the
// decision to the pure resolver, applies it, shows the prompt if needed.
// The ONE place migration/conflict logic lives.
class AccountSyncService {
  Future<void> onSignIn(String userId) async {
    // 1. read local profile.updatedAt / availability.updatedAt + account.lastSyncedUid
    // 2. read cloud rows (existence + updated_at)
    // 3. call resolveAccountSync() per domain (profile and availability can
    //    diverge independently)
    // 4. apply: push, pull, or a two-button dialog, then apply the choice
    // 5. write account.lastSyncedUid = userId locally
  }
}
```

**MIG-05/06 (all-or-nothing, server-acknowledged) is materially easier on Postgres.** Wrap the first-login push in a single `rpc()` call to a `plpgsql` function that writes `profiles`, `availability` and `planned_rides` inside one transaction. It either commits or it doesn't, and the client only learns of success from the server's response — there is no optimistic local-SDK acknowledgement to mistake for a durable write, which was the specific hazard MIG-06 was written against. Firestore needed a batched write plus care about its offline cache reporting success; Postgres gives a real transaction.

Because `resolveAccountSync` takes no SDK types, it can be built and unit-tested (`test/domain/services/account_sync_resolver_test.dart`) before any Supabase wiring exists.

---

## 6. New vs modified — explicit file list

### New files

| File | Purpose |
|---|---|
| `lib/providers/auth_notifier.dart` (+ `.g.dart`) | `authStateProvider`, `currentUserIdProvider` (§1). |
| `lib/services/account_sync_service.dart` | Sign-in orchestrator (§5). |
| `lib/domain/services/account_sync_resolver.dart` | Pure conflict-decision function (§5) — build and unit-test first, needs no SDK. |
| `lib/data/repositories/profile_repository.dart` | Extracted local+cloud profile persistence (§2). |
| `lib/data/repositories/availability_repository.dart` | Extracted local+cloud availability persistence (§2). |
| `lib/data/repositories/planned_rides_repository.dart` | Extracted local+cloud planned-rides persistence (§2). |
| `lib/data/remote/supabase_tables.dart` | Central table/column name constants — same centralizing role `availability_key.dart` plays for local keys. |
| `lib/data/database/tables/sync_outbox.dart` (+ Drift migration) | The offline outbox (§4a). Drift schema version bump required. |
| `supabase/migrations/*.sql` | Schema + RLS policies (§3), version-controlled. `supabase` CLI project dir, new. |
| `supabase/tests/rls_test.sql` (or a Dart integration test) | SYNC-08 deny-case proof across two real accounts. |
| Account UI — `lib/features/profile/account_section.dart` | Sign-in/out + signed-in identity. No new route; lives inside the existing `/profile` screen, same placement pattern as the Calendar-connect UI. |
| `test/domain/services/account_sync_resolver_test.dart` | Unit tests for §5. |

### Modified files

| File | Change |
|---|---|
| `pubspec.yaml` | Add `supabase_flutter` (verified live on pub.dev 2026-07-25: **2.16.0**, publisher supabase.io, 975 likes, published 18 days prior). No Gradle plugin needed — unlike Firebase, there is no `google-services.json` and no `com.google.gms.google-services` classpath. |
| `lib/main.dart` | `await Supabase.initialize(url:, anonKey:)` early in `main()`, alongside the existing parallel `tzFuture`/`prefsFuture` block — must complete before any provider reads `authStateProvider`. Does not touch the `kIsWeb`-gated WorkManager/CalendarService warmup branches. |
| `lib/services/calendar_service.dart` | **Now modified, where the Firebase plan left it untouched.** `_sharedInitialize()` must pass `serverClientId` to `GoogleSignIn.instance.initialize()` — Supabase's auth server verifies the ID token against the *web* client ID. The memoized `_initFuture` gate is reused as-is; auth and Calendar share it rather than duplicating it (AUTH-05). |
| `lib/providers/profile_notifier.dart` | `build()` gains `ref.watch(authStateProvider)`; delegates to `ProfileRepository`. |
| `lib/providers/availability_notifier.dart` | Same. |
| `lib/providers/planned_rides_notifier.dart` | Sync → async `build()`, `ref.watch(authStateProvider)`, delegates to `PlannedRidesRepository`. |
| `lib/platform/background_task.dart` | 3 mirrored key constants deleted; calls the repositories' `readLocal()`. Zero Supabase in the isolate (REG-05). |
| `lib/features/profile/profile_screen.dart` | Adds the account section. |
| `lib/features/profile/feedback_dialog.dart` | Phase 22 — replaces `buildFeedbackMailtoUri`/`launchUrl(mailto:)` with a `feedback` insert (§3), working signed-in *or* anonymous (FB-03). |
| `CLAUDE.md`, `.planning/PROJECT.md` | The three broken constraints (PRE-01). Note the stack table also needs `supabase_flutter` added. |

### Explicitly unchanged (verified)

- `lib/data/database/**` (Drift forecast cache) — untouched except for the new outbox table; derived data does not sync (SYNC-09).
- `firebase.json` / `.firebaserc` — **Hosting stays on Firebase.** No `firestore` block is ever added. The privacy policy names both Google (Hosting, Calendar) and Supabase (Auth, database) as sub-processors (PRE-03).
- `lib/app/router.dart` — `sharedPrefsProvider` and the onboarding redirect stay as-is; no route changes (account UI lives in `/profile`).

---

## 7. Suggested build order

Ordered by actual dependency, not by phase numbering:

1. **`account_sync_resolver.dart` + unit tests.** Zero dependencies — pure Dart. Gets the hardest design question decided and tested before any infrastructure exists.
2. **Supabase project + schema + RLS migration.** EU region (PRE-02), tables and policies from §3 in one migration. No app code. Verifiable with `psql`/dashboard before Flutter touches it.
3. **`supabase_flutter` + `Supabase.initialize()` + `authStateProvider` + the account section in `profile_screen.dart`** — sign-in/out only, no data sync. Verifiable end-to-end on its own, on both platforms, before touching a single existing notifier. This is where AUTH-10's release-build gate applies.
4. **The three repositories**, refactoring the notifiers and `background_task.dart` — **local-only, `cloud: null` everywhere.** Pure refactor, no user-visible change, no Supabase involvement. This is Phase 20 and is where the SharedPreferences key duplication dies.
5. **Cloud read/write** wired into the repositories, gated on `authStateProvider`, plus the outbox (§4a).
6. **`AccountSyncService.onSignIn`** — wires step 1's resolver to step 2/5's infrastructure. First-login and second-device become real, testable behaviours.
7. **Feedback insert** (`feedback_dialog.dart`) — depends on steps 2–3 only, so it can run in parallel with 4–6 or after.

Steps 1 and 4 have no Supabase dependency and are safe groundwork. Steps 2, 5 and 6 are where "no backend" actually breaks and need the privacy-policy rewrite done in parallel, not after (PRE-05, a hard release blocker).

---

## Sources

- Codebase (read directly, 2026-07-25): `lib/services/calendar_service.dart`, `lib/providers/profile_notifier.dart`, `lib/providers/availability_notifier.dart`, `lib/providers/planned_rides_notifier.dart`, `lib/providers/location_provider.dart`, `lib/providers/app_database_provider.dart`, `lib/domain/services/availability_key.dart`, `lib/features/availability/availability_screen.dart`, `lib/platform/background_task.dart`, `lib/app/router.dart`, `lib/main.dart`, `lib/features/profile/feedback_dialog.dart`, `pubspec.yaml`, `firebase.json`.
- [pub.dev — supabase_flutter](https://pub.dev/packages/supabase_flutter) — fetched live 2026-07-25: v2.16.0, publisher supabase.io, 975 likes. HIGH confidence.
- [Supabase Docs — Flutter signInWithIdToken](https://supabase.com/docs/reference/dart/auth-signinwithidtoken) — HIGH confidence, official. Note: its sample uses the `google_sign_in` **6.x** API; this project is on 7.2.0 — see PITFALLS.md #1.
- [Supabase Docs — Regions](https://supabase.com/docs/guides/platform/regions) — EU regions available: `eu-west-1` (Ireland), `eu-west-2` (London), `eu-west-3` (Paris), `eu-central-1` (Frankfurt), `eu-central-2` (Zurich), `eu-north-1` (Stockholm). HIGH confidence.
- [Supabase blog — Flutter authentication](https://supabase.com/blog/flutter-authentication) — MEDIUM confidence (tutorial, 6.x-era API).
- Superseded Firebase research retained at `.planning/research/archive-firebase/`.

---
*Architecture research for: RideWindow v3.0 Accounts & Sociaal, Phase 1–2 scope*
*Researched: 2026-07-25 — Supabase stack*
