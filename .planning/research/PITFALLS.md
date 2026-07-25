# Pitfalls Research: Firebase Auth + Firestore on an Already-Shipped, Two-Platform Flutter App

**Domain:** Adding accounts/cloud sync (Firebase Auth + Firestore) to a live Android app (Play Store) and live Flutter Web/PWA, both already using `google_sign_in` 7.2.0 for Google Calendar.
**Researched:** 2026-07-25
**Confidence:** MEDIUM-HIGH (Firebase/FlutterFire mechanics verified against official docs and current GitHub issues; RideWindow-specific facts verified directly against the codebase and project memory; a few claims about exact Firestore SDK size/minSdk numbers should be re-verified against the FlutterFire version pinned at implementation time)

This file supersedes generic Firebase-tutorial advice. Every pitfall below is specific to layering Auth+Firestore on top of the *existing* `CalendarService` singleton pattern, the existing unverified OAuth consent screen, the existing SharedPreferences/Drift data, and the two live deployments (Android release APK/AAB + `my-project-joost.web.app`).

---

## Critical Pitfalls

### Pitfall 1: `firebase_auth`'s Google provider fights the existing `GoogleSignIn.instance` singleton on native

**What goes wrong:**
`CalendarService` already owns `GoogleSignIn.instance` through a memoized `_sharedInitialize()` future, guarded because `GoogleSignIn.instance.initialize()` throws `"Bad state: init() has already been called"` if invoked a second time while the first call is in flight. If an `AuthService` is added that calls `GoogleSignIn.instance.initialize()` (or `.authenticate()`, which requires `initialize()` to have run) independently — its own try/catch, its own "have I initialized" bool — the app now has two independent gatekeepers racing for the same static singleton. Concretely: a cold start where `main.dart`'s Calendar warmup and a "restore session on launch" Auth check both fire in the first frame will intermittently throw that `Bad state` error on whichever call loses the race, which reads to the user as "sign-in randomly fails on some launches."

**Why it happens:**
`google_sign_in` 7.x moved from a per-call API to a single static `GoogleSignIn.instance` with an explicit one-time `initialize()`. This is a correct but easy-to-miss architectural change: every piece of code that touches Google Sign-In in the app must now share *one* initialization path, not each own its own. The existing `CalendarService._sharedInitialize()` pattern exists precisely because this bit the team once already (see code comments referencing "Rule 1 bugfix, CAL-06 follow-up").

**How to avoid:**
Do not create a second, independent GoogleSignIn init path for Auth. Either (a) extend `CalendarService`'s existing `_sharedInitialize()`/`_initFuture` mechanism into a small shared `GoogleAuthBootstrap` class that both `CalendarService` and the new `AuthService` call into, or (b) have `AuthService.signIn()` explicitly `await CalendarService.warmUpForWeb()`-equivalent (a shared `ensureGoogleSignInReady()`) before touching `GoogleSignIn.instance` itself. On native, the recommended FlutterFire pattern is: `GoogleSignIn.instance.authenticate()` → take `idToken` from `GoogleSignInAuthentication` → `GoogleAuthProvider.credential(idToken: ...)` → `FirebaseAuth.instance.signInWithCredential(...)`. That flow re-uses the *same* `GoogleSignIn.instance` the Calendar feature already initializes — it must go through the shared init guard, not a fresh one.

**Warning signs:**
- Intermittent `Bad state: init() has already been called` in crash logs, especially on cold start.
- Sign-in succeeds on some launches and silently fails (caught, swallowed) on others.
- Users report having to "try again" to sign in, with no clear cause.

**Phase to address:**
Auth phase (implementation), but the shared-singleton refactor should happen *before* any Auth sign-in code is written — treat it as a small precondition task inside the Auth phase, not a fix-it-later item.

---

### Pitfall 2: On web, `firebase_auth`'s correct flow is a *completely different* code path than the existing `GoogleSignIn.instance` Calendar flow

**What goes wrong:**
On Flutter Web, `google_sign_in`'s implicit `signIn()` flow (the one that would otherwise bridge into `firebase_auth` via `GoogleAuthProvider.credential`) is deprecated and does not reliably return an `idToken` — Firebase's own docs and the FlutterFire team recommend `FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())` on web instead, which is a *Firebase JS SDK* OAuth popup, not the `google_sign_in`/GIS flow the app already uses for Calendar (`GoogleSignIn.instance.authorizationClient.authorizeScopes(...)`, warmed by `CalendarService.warmUpForWeb()`). Implemented naively, the web app ends up with **two separate Google sign-in UIs**: a Firebase popup for "Sign in to RideWindow" and a distinct `GoogleSignIn`/GIS popup for "Connect Calendar" — each capable of resolving to a *different* Google account if the user has multiple sessions in the browser, silently decoupling "who is signed into the app" from "whose calendar gets written to."

**Why it happens:**
`google_sign_in` on web is built on Google Identity Services (GIS), which is designed for authorization (scopes), not authentication tokens suitable for Firebase credential exchange — this is a known, documented gap, not an implementation bug. Firebase's web SDK has its own, separate OAuth popup flow for exactly this reason. Because the existing web-only `warmUpForWeb()` eager-init exists specifically to make the *Calendar* popup pass Safari's popup-blocker synchronicity requirement, it's tempting to assume the same singleton should drive Auth too — it should not, on web.

**How to avoid:**
Branch explicitly on `kIsWeb`: native uses the shared `GoogleSignIn.instance` → `signInWithCredential` path (Pitfall 1); web uses `FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())` directly, independent of `CalendarService`'s `GoogleSignIn.instance`. After a successful web Auth sign-in, if the user later taps "Connect Calendar," explicitly check that the email `FirebaseAuth.instance.currentUser?.email` matches the account chosen in the subsequent `GoogleSignIn` popup and surface a clear warning/re-prompt if they diverge, rather than silently writing calendar events under a different Google identity than the signed-in account. Also register the Firebase Auth web client ID as an *authorized* JS origin (Cloud Console) and verify whether it's the same or a different OAuth 2.0 Web client than the one already hardcoded in `web/index.html`'s `<meta name="google-signin-client_id">` — expect it to default to a *new*, Firebase-auto-provisioned Web client unless configured otherwise (see Pitfall 3).

**Warning signs:**
- Two distinct Google account-picker popups appear for what the user perceives as one "sign in" action.
- `FirebaseAuth.instance.currentUser.email` differs from the Google account that authorized Calendar scopes.
- "Add to calendar" silently uses the wrong Google account after Auth sign-in.

**Phase to address:**
Auth phase. The web-vs-native branch and the identity-consistency check should be a named implementation task and an explicit manual test case ("sign in with account A, connect Calendar with account B — verify the app warns, not silently proceeds") before phase sign-off.

---

### Pitfall 3: Firebase Auth silently provisions its own OAuth client(s) and SHA-1 registration path, separate from the one already set up for Calendar

**What goes wrong:**
This project has already been bitten once by SHA-1/OAuth-client mismatches: the Calendar import feature shipped broken because the release-keystore SHA-1 wasn't registered for the Cloud-Console-created OAuth client, and the fix required registering *two* SHA-1s — the local release keystore's, and separately the Play App Signing key's (Play re-signs the AAB with its own key, so the SHA-1 in `key.properties` is not the SHA-1 that matters in production). Enabling the Google provider in the Firebase Console auto-creates its own Web OAuth client under **Firebase Console → Authentication → Sign-in method**, and Android SHA-1 fingerprints for *Firebase* are registered separately, under **Firebase Console → Project Settings → Your apps → Add fingerprint**, which re-downloads `google-services.json`. This is a *third*, independent configuration surface from the Cloud Console **Credentials** page where the existing Calendar OAuth client and its SHA-1 already live. It is easy to register the SHA-1 in one place and assume it covers both.

**Why it happens:**
Firebase and raw Google Cloud OAuth share one underlying Cloud project but expose separate consoles/UI for credential management, and neither UI cross-links to the other's fingerprint list. A developer who has already been through the Calendar SHA-1 pain reasonably assumes "SHA-1 is registered" is a single fact about the project — it is not; each OAuth client tracks its own fingerprint list.

**How to avoid:**
Treat this as a checklist, not a one-time action: register **both** SHA-1s (debug keystore for local testing, release/Play-App-Signing key for production) in **both** places — Firebase Console's app fingerprints *and* (if a distinct Cloud Console OAuth client is auto-created for Firebase Auth) the Credentials page — before the first release-build smoke test. Pull the actual Play App Signing SHA-1 from Play Console → App integrity → App signing key certificate, not from the local `key.properties` keystore, exactly as the Calendar fix already documented. After registration, the *only* trustworthy verification is a real release-build (`flutter build apk --release`, installed via `adb install -r`, not a fresh install to preserve local data) sign-in test — Firebase Console showing a fingerprint as "saved" does not confirm it is wired to the correct OAuth client.

**Warning signs:**
- Google Sign-In (Auth) works in debug builds but fails silently or with an opaque error ("Error 10", `DEVELOPER_ERROR`, or a bare "oid" error matching the earlier Calendar bug) in the release AAB from Play Console.
- Works for the developer's own installed debug build, fails for a tester's Play Store install.

**Phase to address:**
Preconditions phase, as an explicit named task alongside "Google Cloud OAuth verification" — do the SHA-1/client audit for Auth at the same time the Calendar OAuth setup gets its final Cloud Console pass, since both touch the same project and the failure mode (release-build-only breakage) is identical and easy to conflate.

---

### Pitfall 4: Misreading the 100-user OAuth cap as "accounts are capped at 100" instead of "sensitive-scope grants are capped at 100, lifetime, per project"

**What goes wrong:**
The existing 100-user lifetime cap is tied to the Cloud project's *unverified sensitive/restricted scope* usage (`calendar.events` is Sensitive) — it counts unique users who have ever granted that specific scope consent, not unique app sign-ins. Two wrong conclusions are both easy to reach: (a) assuming adding Firebase Auth to the same project *also* becomes capped at 100 total accounts (it is not — basic Google sign-in uses `openid`/`email`/`profile`, which are non-sensitive, non-restricted scopes and do not count against the cap), or (b) assuming the cap doesn't apply at all anymore because "In production" publish status was already verified in Cloud Console (it does still apply — publish status and verification status are different axes, and this was already recorded as a deliberate nuance in this project's history).

**Why it happens:**
Google's own UI language conflates "publish status" (Testing/In production) with "verification status" (unverified/verified) in ways that read as synonymous but are not. The cap is enforced per Cloud project's OAuth consent screen for the specific sensitive/restricted scopes an unverified app requests — Firebase Auth and raw `google_sign_in`/Calendar both draw from the *same* consent screen because they're the same Cloud project.

**How to avoid:**
Document explicitly (in the revised `CLAUDE.md`/`PROJECT.md` constraints, not just tribal memory) that: (1) plain Firebase Auth sign-in is *not* capped by the 100-user limit as long as it requests only basic scopes; (2) the cap only bites the moment a signed-in user *also* taps "Connect Calendar" and grants `calendar.events`; (3) the cap is a cumulative lifetime count of unique users who have ever granted that scope, not concurrent users, and is not resettable without full Google verification. Practically: it's safe to onboard well beyond 100 total *accounts*, but the *Calendar-connecting* subset of users should be tracked and budgeted against 100 for the life of the project unless verification is pursued later. Consider surfacing a soft warning in the app (or at minimum tracking a counter in Firestore) once Calendar-connect grants approach the cap, since there is no Google-side dashboard alert for it.

**Warning signs:**
- New users suddenly seeing the "Google hasn't verified this app" warning escalate to a hard block, once the 100th unique Calendar-scope grant is crossed.
- Confusing a plain sign-in failure with a cap issue (or vice versa) during support triage.

**Phase to address:**
Preconditions phase — this belongs in the constraint-revision writeup, explicitly separating "Auth cap" (none, practically) from "Calendar-connect cap" (100 lifetime, real). Track the cumulative Calendar-scope-grant count from the Sync/Migration phase onward as a cheap Firestore counter, so it's visible before it becomes a support incident.

---

### Pitfall 5: First-login migration writes are not atomic, not idempotent, and can race a second device

**What goes wrong:**
"Local wins" migration on first login sounds simple but has several silent-failure shapes specific to this app's history of silent data-format bugs: (1) **Partial writes** — if the migration writes `profile`, `availability`, and `tolerances` as separate Firestore `set()` calls rather than one batched/transactional write, an app kill or network drop mid-migration leaves a half-populated cloud profile that looks "done" (account exists, some data exists) but is actually corrupt; a naive "has the user doc been created?" check on next launch would then skip migration entirely, believing it already ran. (2) **Second-device race** — a user who installs the app fresh on a second device and signs in before the first device's migration has completed (or while the first device is offline with a queued migration write) can have the second device's *empty* local state get treated as authoritative, overwriting the first device's real data — this is explicitly flagged as an open design question in the milestone doc, not yet decided. (3) **Offline-at-first-login** — if the device is offline exactly at first login, Firestore's offline write queue accepts the migration write locally and reports success to the app immediately (optimistic write), but it has not actually reached the server; if local SharedPreferences are cleared once the app "thinks" migration succeeded, and the write later fails to sync (e.g., app uninstalled before reconnecting), the data is gone with no error ever surfaced.

**Why it happens:**
Firestore's SDK is deliberately optimistic (local writes resolve immediately for good UX), which is exactly the behavior that makes "write succeeded" and "write reached the server" feel identical during development on a good connection — the gap only appears under real offline/flaky conditions, which is precisely the condition class that produced this app's earlier UTC/local `DateTime` key bug (silent, took months to surface).

**How to avoid:**
- Write the entire migration payload (profile + availability + tolerances + a `migratedFrom` marker with app version and timestamp) as a **single Firestore transaction or batched write**, never field-by-field.
- Do not delete/clear local SharedPreferences data on migration — keep it as a fallback until a subsequent app session confirms the cloud document is present and matches expected shape. Local-only-until-confirmed is cheap insurance.
- Gate "migration complete" on an explicit **server-acknowledged** write, not the SDK's optimistic local resolution — e.g., a follow-up `get()` with `Source.server` (bypassing cache) or listening for the pending-writes flag on the snapshot to clear, before marking migration done locally.
- For the second-device race: at minimum, detect it — if a login occurs and a remote profile document *already exists* with a `migratedFrom` marker from a different device/install, do not blindly apply "local wins"; surface an explicit choice to the user (or, as a stopgap for phase 1, refuse to overwrite and just adopt the cloud state, deferring true conflict resolution to a later phase — but this must be a conscious decision, not the accidental default of whichever write lands last).
- Given this app's specific history: add an automated test that seeds a realistic production-shaped local dataset (real weekly-grid key format, real block types) and asserts the exact document shape written to Firestore, not just "migration ran without throwing." A manual on-device smoke test is not sufficient here — the DateTime key bug was invisible to manual testing for months.

**Warning signs:**
- Firestore documents with only some of the expected fields present (a `profile` field but empty `availability`).
- Two devices for the same account showing different availability grids after both have "successfully" signed in.
- Users reporting "my blocked hours disappeared" after signing in on a new phone.

**Phase to address:**
Migration phase for the write itself; the second-device conflict detection is explicitly called out in `PROJECT.md` as an open design question that must be resolved (even if the phase-1 resolution is "detect and refuse to overwrite," not full conflict-merge UI) before Migration phase sign-off, not deferred silently.

---

### Pitfall 6: Firestore's web offline persistence and Drift's `sqlite3.wasm` persistence compete for the same browser storage, and multi-tab breaks by default

**What goes wrong:**
The web PWA already persists data via Drift's IndexedDB/wasm backend (`sqlite3.wasm`, confirmed present in `web/`). Adding Firestore's own offline cache (`persistentLocalCache`, also IndexedDB-backed) puts two independent persistence engines writing to browser storage under the same origin. Two separate failure modes: (1) **Storage pressure/eviction** — browsers apply storage quotas and eviction policies per-origin, and Safari in particular aggressively evicts IndexedDB data for web content not opened in 7 days *when not installed as a PWA*; doubling the persisted footprint (Drift's forecast cache + Firestore's local cache) increases the odds of hitting eviction thresholds, and there is no cross-engine coordination — Firestore doesn't know Drift already claimed storage, and vice versa. (2) **Multi-tab default failure** — Firestore's default web persistence uses a *single-tab exclusive lock*; opening the app in a second browser tab (very plausible for a PWA also usable in-browser) causes the second tab to fail to acquire the persistence lock and silently fall back to memory-only cache (data lost on tab close, and worse, that tab may not see writes made by the first tab until reconnect) unless `persistentMultipleTabManager()` is explicitly configured.

**Why it happens:**
Both engines are designed as if they were the only persistent store in the origin — this is a correct assumption in isolation and a wrong one only in combination. Firestore's multi-tab default is single-tab specifically because naive multi-tab writes to the same local cache without coordination cause worse bugs (which is why it fails closed rather than silently corrupting).

**How to avoid:**
- Explicitly configure Firestore web persistence with `persistentLocalCache(tabManager: persistentMultipleTabManager())` (the current, non-deprecated API — avoid `enableMultiTabIndexedDbPersistence()`, which is deprecated) so a user with the PWA installed *and* a browser tab open behaves correctly, since this is a realistic RideWindow usage pattern.
- Do not assume Firestore's offline cache replaces the "stale-data-with-offline-banner" pattern already built for weather/Drift — the availability/profile sync should surface its own "pending sync" indicator when Firestore's `hasPendingWrites` is true, reusing the same UX language already established rather than inventing a second offline-affordance vocabulary.
- Test explicitly on iOS Safari (both installed-PWA and plain-tab modes) given the project's own prior note that Drift's web storage-eviction risk was "accepted, not yet observed in practice" for v2.0 — that risk is now compounded, not just carried forward, and should be re-evaluated rather than re-accepted by default.
- Consider capping Firestore's local cache size explicitly (`CACHE_SIZE_UNLIMITED` is the SDK default and is the wrong choice for a small-data app sharing storage with Drift) — an explicit, modest cache size limit avoids Firestore's cache silently growing to dominate the shared storage quota.

**Warning signs:**
- Availability data reverting or appearing stale in one browser tab after being edited in another.
- Data loss after a long period of the PWA not being opened, correlated with Safari ITP eviction windows.
- Console warnings about failing to acquire the persistence lock.

**Phase to address:**
Sync phase — the persistence configuration (multi-tab manager, cache size) is implementation detail that must be decided before the sync provider ships, and the Safari eviction re-test should be an explicit verification step (real iPhone Safari, both installed and tab modes), not assumed carried-over from the v2.0 Drift-only test.

---

### Pitfall 7: Security rules shipped as test-mode, or "logged in" mistaken for "authorized"

**What goes wrong:**
Firebase's default "Start in test mode" Firestore setup ships `allow read, write: if true`, which auto-expires after 30 days — a project that goes quiet after initial setup (very plausible on an evenings-and-weekends solo cadence) can silently flip from wide-open to fully-locked, breaking the app in production with no code change. The more subtle, common mistake even by developers who know to avoid test mode: writing `allow read, write: if request.auth != null` on the users collection, which correctly blocks anonymous access but allows **any signed-in user to read or write any other signed-in user's document** — full profile/availability enumeration across the user base, not just "logged in required." A second subtlety: Firestore rules do **not cascade** to subcollections — a rule scoped to `/users/{uid}` does not automatically protect `/users/{uid}/feedback/{feedbackId}` unless that subcollection has its own explicit `match` block, which is easy to forget when feedback (phase 2) is added after the users/availability rules (phase 1) already "work."

**Why it happens:**
The Firebase emulator and Rules Playground both make `auth != null` *feel* sufficient because ad-hoc manual testing is almost always done as a single logged-in user probing their own data — the enumeration gap only shows up when specifically testing "can user A read user B's doc," which isn't the default manual-QA instinct.

**How to avoid:**
For this app's shape (`/users/{uid}/profile`, `/users/{uid}/availability`, `/users/{uid}/feedback`, etc.), the minimum correct rule is ownership-scoped by UID match, not just presence of auth:
```
match /databases/{database}/documents {
  match /users/{uid} {
    allow read, write: if request.auth != null && request.auth.uid == uid;

    match /{subcollection=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```
Write an automated rules-unit-test suite (`@firebase/rules-unit-testing` via the Firestore emulator) that explicitly asserts user A **cannot** read/write user B's documents — a "deny" test, not just an "allow" test — since the allow case is the one developers reflexively verify and the deny case is the one that actually matters. Re-run this test suite against the *deployed* rules (`firebase deploy --only firestore:rules` then a live smoke check), not just the emulator, since emulator-pass/production-fail gaps are usually caused by rules referencing `get()`/`exists()` against document shapes that differ between hand-seeded emulator fixtures and what the real migration code actually writes (see Pitfall 5).

**Warning signs:**
- Rules deploy succeeds with no errors, but a manual test with two separate test accounts shows account B can read account A's availability grid.
- Firestore Console shows a banner that test-mode rules will expire soon (if test mode was ever used, even briefly, during setup).

**Phase to address:**
Sync phase — rules must ship alongside the first real Firestore read/write, not as a follow-up hardening pass. The deny-case automated test belongs in the same phase's verification steps, not deferred.

---

### Pitfall 8: Free-tier assumptions break down from write patterns, not data volume, and budget alerts don't cap spend

**What goes wrong:**
For a solo project with a handful of testers, storage volume will never approach the free tier's limits — the actual risk is *operation count* from access patterns that feel harmless at small scale: (1) A live `snapshot()` listener on the availability document (natural choice for "sync instantly across devices") re-fires a read on every write from *any* device, including the device that made the write — if the availability grid syncs *per hour-cell toggle* rather than as one batched document write, dragging across 20 cells during editing is 20 writes × N active listeners, not 1. (2) Listening screens that stay mounted (e.g., a Home screen `StreamProvider` that's never disposed) keep charging for every downstream change indefinitely, including changes irrelevant to what's currently rendered. (3) `App Check` (reCAPTCHA/Play Integrity attestation) protects against abusive automated clients hitting the Firestore/Auth backend *directly*, bypassing the Flutter app entirely — it does **not** protect against the app's own legitimate-but-inefficient usage pattern (an open listener, an unbatched write-per-keystroke). Budget alerts in Cloud Billing are **notification-only**: they email the account owner at spend thresholds but do not throttle or disable anything — the only actual hard stop is a Cloud Function triggered by the budget's Pub/Sub topic that calls the Billing API to disable billing, which is a deliberate extra build step, not a default.

**Why it happens:**
Firestore's pricing model (cost scales with read/write *operations*, not stored bytes) is counter-intuitive coming from a local-SQLite mental model (Drift) where the only cost is disk space — a solo dev optimizing for "did the write succeed" during development has no natural signal that the *pattern* of writes is what will eventually cost money, since at 1-5 testers everything is invisibly inside the free tier regardless of pattern quality.

**How to avoid:**
- Model the availability grid as **one document per user, written as a whole (debounced/batched)**, not one write per cell toggle — consistent with how it's likely already modeled in Drift, and directly avoids the write-amplification risk.
- Prefer one-time `get()` reads over live `snapshot()` listeners wherever real-time cross-device sync isn't the actual requirement for phase 1 (a "pull to refresh" or on-load fetch, matching the pattern already used for weather refresh on web, is cheaper and simpler than a listener architecture that phase 1's scope doesn't need).
- Set a Cloud Billing budget alert (a few euros threshold) at project setup, understanding explicitly that it is a notification, not a cap — treat it as an early-warning tripwire to check the pattern, not a safety net.
- Defer App Check to when/if the app has a public-enough surface to be worth bot-hardening — it's not a substitute for correct client-side write patterns and shouldn't be treated as the primary cost control for a project this size.

**Warning signs:**
- Firestore usage dashboard showing read/write counts far exceeding the number of testers × plausible actions.
- A budget alert email arriving despite "nothing changed" — almost always an open listener or a write-per-keystroke pattern, not a legitimate new feature's cost.

**Phase to address:**
Sync phase — the "one document, batched writes, no unnecessary listeners" decision is an architecture choice that must be made when the sync provider is designed, not retrofitted. Budget alert setup belongs in the Preconditions phase alongside the rest of the Cloud project configuration.

---

### Pitfall 9: Shipping accounts without the GDPR preconditions actually in place, not just acknowledged

**What goes wrong:**
Once location data and calendar-derived availability leave the device and land in Firestore, Joost becomes a data controller under GDPR (Google/Firebase is the processor). The milestone doc already names this correctly as a release blocker in principle, but the concrete failure mode is treating it as "we'll rewrite the privacy policy text" when it is actually several separate, verifiable pieces of work: (1) **EU data residency** — the Firestore *database* region is chosen once, at creation, and is not migratable afterward without recreating the whole database; if the existing Firebase project's Firestore database doesn't exist yet, the region (an EU multi-region, e.g. `eur3`) must be chosen deliberately now, not defaulted to a US region by clicking through setup quickly. (2) **Data Processing Agreement** — Google's Firebase Data Processing Terms must actually be in effect for the project (this is a Firebase Console setting/acceptance, not automatic), and the privacy policy must name Google/Firebase as a sub-processor. (3) **Right to erasure** — deleting a Firebase Auth user (`FirebaseAuth.instance.currentUser.delete()`) does **not** delete the user's Firestore documents; without an explicit cleanup step (client-triggered batch delete of `/users/{uid}/**` on account deletion, since this project has deliberately avoided a backend/Cloud Functions layer so far), "delete my account" silently leaves orphaned personal data in Firestore forever — a direct GDPR violation, and a particularly bad one because it's invisible (no error, no user-facing sign it failed). (4) **Right to export** — must be *possible* to fulfill (a JSON export endpoint or, at minimum-viable scale, a documented manual process), not necessarily built as a self-service UI button for phase 1, but the plan for how a request would be honored must exist before launch. (5) **Play Store Data Safety section** — currently declares device-only data handling (per the existing shipped privacy posture); this must be updated to declare account creation, server-side storage of location-derived and calendar-derived data, and the Google Firebase sub-processor, *before or at* the release that ships accounts — Play Console can flag/suspend apps whose actual behavior doesn't match their Data Safety declaration, and this is a distinct artifact from the privacy policy page, easy to update one and forget the other.

**Why it happens:**
"Rewrite the privacy policy" is legal-sounding work that's easy to scope as a single writing task; the operational pieces (region choice, DPA acceptance, actual working deletion, Data Safety form) are scattered across three different consoles (Firebase, Google Cloud, Play Console) and don't surface as a single checklist anywhere by default.

**How to avoid:**
Before the first release that ships accounts, verify as a concrete checklist (not a prose paragraph):
- [ ] Firestore database region confirmed EU (checked in Firebase Console, not assumed).
- [ ] Firebase's Data Processing Terms accepted for the project.
- [ ] Privacy policy rewritten (legal-reviewed if feasible, or at minimum using an EU-focused generator/template that names Google/Firebase, data categories now collected, retention, and rights) and republished at the existing linked URL.
- [ ] Account deletion flow implemented and *tested* to confirm Firestore documents are actually gone afterward (not just the Auth user) — a batch/recursive delete of the user's document tree, run client-side at delete time given no Cloud Functions layer exists.
- [ ] A documented (even if manual, for phase 1 scale) path to fulfill a data export request.
- [ ] Play Store Data Safety section updated to reflect account creation and server-side data storage, submitted and live before/at the accounts release.
- [ ] Retention policy decided and stated (e.g., data deleted N days after account deletion is confirmed, or immediately) — must be a real answer, not left implicit.

**Warning signs:**
- "Delete my account" tested only by checking `FirebaseAuth.instance.currentUser == null` afterward, without checking the Firestore console for the user's leftover documents.
- Privacy policy updated but Play Console Data Safety form left showing the old (device-only) declaration.
- No one has actually checked which Firestore region the database was created in.

**Phase to address:**
Preconditions phase, explicitly, as release-blocking requirements tracked with their own checkboxes (as `PROJECT.md` already frames it) — not folded into the Auth or Sync phases where they're easy to treat as "someone else's later problem." The account-deletion *implementation* itself is a Sync/Migration-phase engineering task, but its GDPR verification (does the data actually disappear) belongs in Preconditions' definition of done for the whole milestone before release.

---

### Pitfall 10: Adding `firebase_core`/`firebase_auth`/`cloud_firestore` regresses the live Android app or live PWA in ways the existing regression checklist won't catch by default

**What goes wrong:**
This app has an established, working regression discipline (`flutter build apk --release` + manual smoke test on Android; redeploy + curl-verify SPA rewrite and wasm headers on web) from the v2.0 milestone — but that checklist was written for the plugins already in the app, and Firebase's Android SDKs introduce failure surfaces the existing checklist doesn't cover: (1) Firebase Android SDKs pull in Google Play Services BoM dependencies that can force Gradle/Kotlin/AGP version bumps beyond what's currently pinned (Kotlin 17/JVM target, `compileSdk 36` currently set) — a version conflict here fails the *build*, which is at least loud, but a resolved-but-untested version combination can pass the build and fail only at runtime on specific Android versions. (2) Firebase Auth and Firestore both carry their own `minSdkVersion` floor (historically 23 for modern Firebase Android SDKs) — must be checked against whatever `flutter.minSdkVersion` currently resolves to for this app, since it's not explicitly overridden in `build.gradle.kts` today. (3) `firebase_core`'s Android auto-initialization happens via a manifest-merged `ContentProvider` — this executes at process start, before `main()`, which is a different timing regime than the app's existing WorkManager isolate-reinit pattern; if any future background task needs Firebase (not phase 1's scope, but a real risk for phase 5/server-push), the existing "re-initialize Riverpod/Drift inside the WorkManager callback" pattern will need an equivalent Firebase re-init step, and this is easy to miss because it won't fail until that later feature is built. (4) On web, the Firebase JS SDK bundles add real payload weight to the PWA — this directly risks the documented "forecast + slots within 2s of cold start" performance constraint and the already-hard-won PWA install/update behavior on iOS Safari; this must be re-measured, not assumed acceptable by extrapolation from native.

**Why it happens:**
The existing regression checklist was built and validated against the *specific* plugin set present at v2.0 — it's a real, working discipline, but it isn't automatically forward-compatible with a fundamentally different class of dependency (a full backend SDK, not a thin device-API plugin like `geolocator` or `workmanager`).

**How to avoid:**
Explicitly extend the existing regression checklist rather than assuming it already covers this:
- Confirm `minSdk` compatibility with the pinned Firebase SDK versions before implementation, not after a failed build.
- Run a full `flutter build apk --release` and real-device smoke test immediately after adding just `firebase_core` (before any Auth/Firestore code), to isolate build-time regressions from feature-code bugs.
- Re-measure web cold-start timing after the Firebase JS SDK is added (a simple manual "time to first slot rendered" check on a real iPhone over real cellular, not just localhost/Wi-Fi) against the 2s constraint, and treat a miss as a blocking issue, not a "note it and move on."
- Re-run the v2.0 PWA install/update verification on a real iPhone once Firebase web assets are in the bundle, since added JS payload can change install-prompt timing and Safari's update-check cadence for installed PWAs.
- If/when server-side push (phase 5) is eventually built, revisit the WorkManager-isolate-reinit pattern explicitly for Firebase — flagged here so it isn't rediscovered the hard way later.

**Warning signs:**
- Release build succeeds locally but fails on Play Console's pre-launch report or for testers on older Android versions.
- Web app's Lighthouse/manual cold-start time visibly regresses after the Firebase SDK lands, even though "the feature works."
- PWA install prompt behavior on iPhone Safari changes silently (stops appearing, or appears at a different time) after the JS bundle grows.

**Phase to address:**
Auth phase (for the `firebase_core` addition specifically — test its impact in isolation first) and Sync phase (for the full Firestore payload); the extended regression checklist itself should be written once, at the start of implementation, and reused across both phases rather than improvised per-phase.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|-----------------|------------------|
| Skip second-device conflict resolution, always apply "local wins" blindly | Ships phase 1 faster, avoids conflict-UI design work | Silent data loss the first time a real user logs in on a second device with existing local data | Never as silent default — acceptable only if "detect and refuse to overwrite, adopt cloud state" is the explicit phase-1 behavior, with true merge deferred |
| Use a live Firestore `snapshot()` listener everywhere "to be safe" | Feels more "real-time," less code branching | Read/write amplification, harder-to-predict cost, more surface for the multi-tab persistence issue (Pitfall 6) | Only for screens where instant cross-device reflection is an actual phase-1 requirement, not by default |
| Defer the account-deletion Firestore cleanup ("we'll add it later") | One less feature to build before launch | GDPR erasure-right violation the moment the first account-deletion request occurs | Never — must exist, even as a manual/documented process, before release |
| Skip rules-unit-tests, rely on manual single-account testing | Faster to ship the first sync feature | Enumeration vulnerability invisible until someone specifically probes cross-account access (Pitfall 7) | Never for the initial ruleset; acceptable to skip for genuinely low-risk rule *changes* later, once the deny-case suite exists |
| Leave Firestore local cache size unbounded (SDK default) | Nothing to configure, works immediately | Compounds storage pressure with Drift's existing IndexedDB usage on web (Pitfall 6) | Acceptable short-term for native-only testing; must be revisited before web ships sync |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|-----------------|-------------------|
| `google_sign_in` 7.x + `firebase_auth` (native) | Two independent `GoogleSignIn.instance.initialize()` call sites racing | Route through the existing shared `_sharedInitialize()`/memoized-future pattern; extend it, don't duplicate it |
| `google_sign_in` + `firebase_auth` (web) | Using `google_sign_in`'s (deprecated) implicit flow to bridge into `signInWithCredential` | Use `FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())` on web; keep it separate from the Calendar `GoogleSignIn.instance` flow |
| Firebase Console Google provider + Cloud Console Calendar OAuth client | Assuming one SHA-1 registration covers both | Register SHA-1s (debug + release/Play-signing) in both Firebase Console (app fingerprints) and Cloud Console (Credentials), independently |
| Firestore web persistence + Drift `sqlite3.wasm` | Enabling default single-tab Firestore persistence in a PWA users open in multiple tabs | Configure `persistentLocalCache(tabManager: persistentMultipleTabManager())` explicitly |
| Firestore security rules + subcollections | Assuming a rule on `/users/{uid}` protects `/users/{uid}/feedback` automatically | Add an explicit `match /{subcollection=**}` (or per-subcollection) rule; rules don't cascade |
| Firebase Auth account deletion | Calling `currentUser.delete()` and considering the user's data gone | Explicitly delete the user's Firestore document tree as part of the same deletion flow |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|-----------------|
| One Firestore write per availability-grid cell toggle | Rapid, bursty write counts during editing sessions; approaches free-tier write quota faster than tester count would suggest | Debounce/batch the whole grid as one document write | Noticeable in Firestore usage dashboard even at ~10 testers actively editing |
| Long-lived `snapshot()` listeners on screens that don't need real-time updates | Read counts far exceeding plausible user actions | Prefer one-time `get()` for phase-1 scope; reserve listeners for genuinely real-time needs | Grows silently; surfaces as an unexpected budget alert |
| Unbounded Firestore local cache competing with Drift's IndexedDB on web | Slower page loads, storage-quota warnings in browser dev tools, occasional eviction-related data gaps | Set an explicit, modest Firestore cache size limit | More likely on iOS Safari (tighter storage/eviction policy) than desktop Chrome |
| Firebase web SDK payload added to PWA bundle without re-measuring cold start | "2s cold start" constraint quietly regresses | Re-measure on a real device after adding `firebase_core`/`cloud_firestore` web assets | Immediate — first bundle build after the dependency is added |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| `allow read, write: if request.auth != null` on user-scoped collections | Any signed-in user can read/write any other user's profile and availability (enumeration + tampering) | Require `request.auth.uid == uid` (or equivalent ownership field match), not just presence of auth |
| Rules not extended to subcollections | Feedback (phase 2) or future subcollections left wide open despite the parent doc being "protected" | Explicit `match /{subcollection=**}` under each user, or per-subcollection rules, tested for denial |
| No deny-case rules tests | Enumeration bug ships and is discovered by a curious tester, not by CI | Firestore emulator rules-unit-tests asserting cross-account denial, run in CI before each rules deploy |
| Test-mode rules left past the 30-day auto-expiry | App breaks in production with a hard-to-diagnose "permission denied" wave, unrelated to any code change | Never use test mode past initial local setup; deploy scoped rules before the first real user's data lands |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-------------------|
| Two separate Google account pickers (Auth popup vs Calendar popup) with no identity-consistency check | User can end up signed into the app as one Google account while Calendar events are written under another, with no warning | Compare `FirebaseAuth.instance.currentUser.email` against the Calendar-authorized account and warn on mismatch |
| Silent optimistic writes with no "pending sync" indicator | Users editing availability offline (train, poor connection) believe changes are saved when they're only locally queued | Surface a "pending sync" state using `hasPendingWrites`, consistent with the existing offline-banner pattern used for weather |
| Migration happening invisibly on first login with no confirmation | User has no way to know whether their local data actually made it to the cloud before, say, switching devices | Show an explicit "your data is backed up" confirmation only after a server-acknowledged write, not on optimistic success |

## "Looks Done But Isn't" Checklist

- [ ] **Sign-in works:** Often only tested in debug builds — verify against a real Play Store release build/AAB with correctly-registered SHA-1s (both keystore and Play App Signing key).
- [ ] **Migration "succeeded":** Often only checked via "no exception thrown" — verify the actual Firestore document shape matches expectations using representative production-shaped data, and verify the write reached the server (not just the local optimistic cache).
- [ ] **Account deletion:** Often only removes the Firebase Auth user — verify the user's Firestore documents are actually gone afterward by checking the Firestore console, not just app-side auth state.
- [ ] **Security rules "pass":** Often only tested with a single account against its own data — verify with a second test account that cross-account reads/writes are denied, both in the emulator and against deployed production rules.
- [ ] **Offline sync "works":** Often only tested on a good connection with a brief airplane-mode toggle — verify a multi-day offline period followed by reconnect actually syncs, and that the user sees a pending-state indicator throughout.
- [ ] **Privacy policy "updated":** Often only the policy page text is changed — verify the Play Store Data Safety section is separately updated and live, and that the Firestore database region is confirmed EU.
- [ ] **Regression checklist "passed":** Often re-run unchanged from v2.0 — verify it now also covers `minSdk` compatibility, release-build sign-in, and re-measured web cold-start timing.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|----------------|------------------|
| Partial/corrupt migration write reaches a live user | MEDIUM | Detect via a `migratedFrom`/schema-version marker; write a one-off repair script/Cloud Function-free client migration that re-derives cloud state from local data if local data is still present, or prompt the affected user directly if not |
| Enumeration vulnerability shipped in security rules | LOW–MEDIUM | Deploy corrected rules immediately (rules changes are fast to push); audit Firestore access logs for evidence of cross-account reads during the exposure window; notify affected users if evidence of actual access is found (GDPR breach-notification consideration) |
| 100-user OAuth cap hit unexpectedly for Calendar-connect | LOW | Not user-data-destructive — new Calendar-connect attempts fail with the "unverified app" hard block; existing connected users unaffected; pursue Google verification if growth continues, or communicate the limitation |
| Runaway Firestore costs from an inefficient listener/write pattern | LOW | Identify and fix the pattern (usually one specific screen/provider); costs stop accruing immediately once fixed; Blaze plan has no historical "undo," but exposure is typically small at this project's scale if caught within days via budget alerts |
| Account-deletion request discovered to have left orphaned Firestore data | MEDIUM | Manually locate and delete the orphaned document tree by UID; implement and test the missing cleanup step before any further deletion requests |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-------------------|----------------|
| Native `GoogleSignIn.instance` double-init collision | Auth | Cold-start stress test (rapid repeated launches) shows no `Bad state` errors |
| Web Auth-popup vs Calendar-popup identity mismatch | Auth | Manual test: sign in as account A, connect Calendar as account B, confirm the app warns |
| SHA-1 / OAuth client misconfiguration across Firebase Console and Cloud Console | Preconditions | Real release-build (AAB) sign-in test, not just debug build |
| 100-user cap conflated between Auth and Calendar-connect | Preconditions | Constraint doc explicitly states the distinction; a Calendar-connect-grant counter exists |
| Non-atomic / non-idempotent migration writes | Migration | Automated test with production-shaped data asserts exact Firestore document shape; server-ack (not optimistic) gating verified |
| Second-device migration race | Migration | Explicit test: sign in on device B with existing local data while device A's account already has cloud data; confirm defined (not accidental) behavior |
| Firestore web persistence vs Drift IndexedDB contention, multi-tab default | Sync | Multi-tab manual test on real iPhone Safari (installed PWA + browser tab simultaneously); no data loss or stale reads |
| Security rules enumeration / missing subcollection coverage | Sync | Automated Firestore emulator rules-unit-tests include cross-account deny cases; re-verified against deployed production rules |
| Runaway cost from write/listener pattern | Sync | Firestore usage dashboard reviewed against expected tester-count × action baseline before wider rollout |
| GDPR preconditions (region, DPA, deletion, export, Data Safety form) | Preconditions | All six checklist items in Pitfall 9 confirmed complete before the accounts release ships |
| Android/web regression from `firebase_core`+ SDKs | Auth (core addition) / Sync (full payload) | Extended regression checklist run: release-build install, minSdk check, real-device web cold-start re-measure, PWA install re-check |

## Sources

- [Firebase: Federated Auth (Flutter, Google Sign-In)](https://firebase.google.com/docs/auth/flutter/federated-auth) — current recommended `GoogleSignIn.instance.authenticate()` → credential → `signInWithCredential` pattern for native; `signInWithPopup`/`signInWithRedirect` for web
- [google_sign_in on pub.dev](https://pub.dev/packages/google_sign_in) — 7.x singleton/`initialize()` semantics
- [flutter/flutter#70695 — google_sign_in fails after adding google-services.json](https://github.com/flutter/flutter/issues/70695) — client-ID conflict behavior when Firebase config is added alongside existing `google_sign_in` usage
- [firebase/flutterfire#12034 — deprecated multi-tab persistence API](https://github.com/firebase/flutterfire/issues/12034) and [firebase/flutterfire#9929 / #3561 — Firestore web multi-tab persistence failures](https://github.com/firebase/flutterfire) — current `persistentLocalCache`/`persistentMultipleTabManager()` API and known multi-tab failure modes
- [Firestore: Enable offline data](https://firebase.google.com/docs/firestore/manage-data/enable-offline) — offline cache and multi-tab behavior
- [Google: Sensitive scope verification](https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification) and [Cloud Platform Console Help FAQ](https://support.google.com/cloud/answer/13463817) — 100-user lifetime cap scope, tied to unverified sensitive/restricted scope grants, per Cloud project
- [Fix insecure Firestore rules (Google Cloud docs)](https://cloud.google.com/firestore/docs/security/insecure-rules) / [Avoid insecure rules (Firebase docs)](https://firebase.google.com/docs/rules/insecure-rules) — test-mode expiry, `auth != null` insufficiency, non-cascading subcollection rules
- [Firebase: Data Processing and Security Terms](https://firebase.google.com/terms/data-processing-terms) and [GDPR and Google Cloud](https://cloud.google.com/privacy/gdpr) — controller/processor split, DPA requirement
- [Google Play: Provide information for the Data safety section](https://support.google.com/googleplay/android-developer/answer/10787469) and [Firebase: Prepare for Google Play's data disclosure requirements](https://firebase.google.com/docs/android/play-data-disclosure) — Data Safety declaration obligations when adding Firebase data collection
- RideWindow codebase: `lib/services/calendar_service.dart` (existing `GoogleSignIn.instance` singleton/warmup pattern), `pubspec.yaml`, `android/app/build.gradle.kts`, `firebase.json`, `web/index.html` (existing OAuth web client ID, PWA/wasm setup)
- RideWindow project memory: `project_availability_fix.md` (silent UTC/local `DateTime` key bug, release-build `run-as` limitation), `project_calendar_import.md` (SHA-1/OAuth client registration failure, release vs Play-signing key distinction)
- `.planning/PROJECT.md` and `.planning/milestones/v3.0-ACCOUNTS.md` — current constraints under revision, 100-user cap nuance already recorded, open second-device conflict design question

---
*Pitfalls research for: Firebase Auth + Firestore added to a shipped, two-platform (Android + Flutter Web/PWA) Flutter app already using `google_sign_in` 7.2.0*
*Researched: 2026-07-25*
