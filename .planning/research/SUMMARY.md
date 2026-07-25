# Project Research Summary

**Project:** RideWindow
**Domain:** Adding optional accounts + cloud sync + account-backed feedback to a shipped, offline-first, two-platform Flutter app (Android native + Web/PWA)
**Researched:** 2026-07-25
**Confidence:** MEDIUM-HIGH

> **Note on coverage:** three of four research dimensions completed (FEATURES, ARCHITECTURE, PITFALLS). `STACK.md` was not produced — the researcher hit a session limit before writing. The gap is small: ARCHITECTURE.md verified package versions live against pub.dev on 2026-07-25, and PITFALLS.md covers the `google_sign_in` 7.x / `firebase_auth` integration question that STACK.md's highest-risk item would have been. Remaining stack gap is noted under **Gaps to Address**.

## Executive Summary

This is not a feature addition — it is an architecture change to a live product with real users on two platforms. RideWindow currently keeps all user data (weekly availability, tolerances, planned rides) in SharedPreferences on Android and in browser storage on the web, as two disconnected silos with no backup. v3.0 phases 1–2 add Firebase Auth (Google Sign-In only) and Firestore to make those one account-backed profile, and route feedback through that account so score calibration can finally tie "this felt wrong" to that user's own tolerance settings.

The research converges strongly on one shape: **accounts must be strictly additive.** No first-run gate, no core feature behind auth, no local data deleted on sign-out. Sign-in lives as a soft entry point in Profile, mirroring the existing "Google Calendar: Connected / Disconnect" row that already shipped. An existing user who never signs in should notice nothing changed. This is not just UX preference — it is regression-prevention for a shipped Play Store product.

The dominant risk is not Firebase itself but the collision with what is already there. `google_sign_in` 7.x exposes a single static `GoogleSignIn.instance` with a one-time `initialize()`, and `CalendarService` already owns that singleton behind a memoized init guard added to fix exactly this class of bug once before. Adding a second, independent init path for Auth reintroduces it. On web the picture is worse: Firebase's recommended web sign-in is a *different* code path (`signInWithPopup`) from the GIS flow Calendar uses, so a naive implementation gives users two Google account pickers that can resolve to two different accounts — signing them into the app as one identity while writing calendar events under another. Beyond that, three release-blocking preconditions are real work, not paperwork: the Firestore database region is chosen once and is not migratable, `FirebaseAuth.currentUser.delete()` does not delete the user's Firestore documents (a silent GDPR erasure violation), and the Play Store Data Safety declaration is a separate artifact from the privacy policy page.

## Key Findings

### Recommended Stack

Verified live on pub.dev 2026-07-25 (all published ~11 days prior), to be re-confirmed against whatever `flutterfire configure` pins at implementation time:

**Core additions:**
- `firebase_core` ^4.12.1 — Firebase initialization; must complete in `main()` before any provider reads auth state
- `firebase_auth` ^6.5.6 — Google Sign-In authentication
- `cloud_firestore` ^6.7.1 — profile, availability, planned rides, feedback

**Deliberately not added:** `firebase_ui_auth` (the account UI is one row in an existing screen, not a flow worth a dependency), any offline-sync helper package (Firestore's own offline persistence is sufficient), any third-party feedback/bug-report SDK (Instabug, Shake — they capture generic device/session data, not the domain-specific score+tolerance context that is the entire point here, and they add a new data-processing relationship immediately after tightening the privacy story).

**Already present, reused:** `google_sign_in` 7.2.0 (native credential flow), `shared_preferences`, `drift` (forecast cache — explicitly does *not* sync).

### Expected Features

**Must have (table stakes):**
- Soft "Sign in with Google" entry in Profile — never a first-run gate
- App stays fully usable, forever, signed out
- Signed-in state UI (avatar, email, sign out) reusing the Calendar-connection row pattern
- Automatic silent sync with a passive "last synced" signal — no mandatory Sync button
- Local writes apply immediately and work offline; sync follows
- **Sign-out never deletes local data**
- Account-scoped provider reset on account switch (otherwise account B sees account A's cached availability — a data-leak-adjacent bug)
- **Account deletion path** — hard Google Play policy requirement since 2024-04-15, in-app or via linked web page
- Explicit, non-silent handling when a signed-in account already holds cloud data

**Should have (differentiators):**
- Feedback auto-attaches score, weather inputs, and the user's own tolerance values — this is *why* accounts are worth building, per the milestone's own rationale
- Reusing the existing Calendar OAuth session so Calendar-connected users get sign-in without a second consent prompt
- In-app JSON data export (satisfies GDPR Art. 20 self-service, doubles as backup, resolves BACKLOG #4)

**Defer (v3.x+):**
- "Your feedback" history screen with developer-reply field
- In-app export if a documented manual process ships first
- Friends, shared availability, ride invites, server-side push (phases 3–5, explicitly out)

### Architecture Approach

One repository per data domain with an *optional* cloud sink injected — not two parallel implementations. There is no behavioral divergence between local-only and local+cloud to justify polymorphism, only an additive step; Riverpod already provides the test seam (override with a fake Firestore, not a fake repository). The conflict decision is extracted into a **pure function with no SDK types**, unit-testable before any Firebase wiring exists.

**Major components:**
1. `authStateProvider` (`@Riverpod(keepAlive: true)`, `Stream<User?>`) — every downstream notifier watches it in `build()`, which is what guarantees no stale cross-account state
2. `ProfileRepository` / `AvailabilityRepository` / `PlannedRidesRepository` — plain Dart classes constructible from both a provider and the WorkManager isolate; they absorb the SharedPreferences key duplication that currently exists in three places
3. `account_sync_resolver.dart` — pure decision function (`pushLocalToCloud` / `pullCloudToLocal` / `promptUser` / `noop`)
4. `AccountSyncService.onSignIn` — the single orchestrator; notifiers get no migration branches of their own
5. Firestore shapes: `users/{uid}` (profile), `users/{uid}/availability/current` (recurring map keyed `"weekday-hour"`), `users/{uid}/plannedRides/{id}` (subcollection — an array field would rewrite the whole history on every add), `feedback/{id}` (top-level, write-only from client)

**Two prerequisites the code does not have today:** no `updatedAt` timestamp is written anywhere, and there is no `account.lastSyncedUid` key. Both are required before *any* conflict decision is possible. **`BlockType.calendar` entries deliberately do not sync** — date-specific, self-expiring, re-derivable by re-running Import from Calendar.

**Background sync is explicitly OUT.** The WorkManager isolate reads profile/availability read-only and writes only a device-local cache timestamp. It has nothing to push, so it gets no Firebase dependency.

### Critical Pitfalls

1. **`GoogleSignIn.instance` double-init on native** — `CalendarService` already guards this singleton behind a memoized future after being bitten once. Extend that guard into a shared bootstrap; do not create a second init path. Symptom: intermittent `Bad state: init() has already been called` on cold start, reading to users as "sign-in randomly fails."
2. **Two Google account pickers on web** — Firebase's web flow (`signInWithPopup`) is a different path from Calendar's GIS flow. Branch on `kIsWeb`, and after web sign-in compare `FirebaseAuth.currentUser?.email` against the Calendar-authorized account and warn on mismatch rather than silently writing events under a different identity.
3. **SHA-1 registered in one console, not both** — this project already shipped Calendar broken for exactly this reason. Firebase Console app fingerprints and Cloud Console Credentials are separate surfaces; both need debug *and* Play App Signing SHA-1s. Only a real release-build sign-in test proves it.
4. **Migration that is not atomic, idempotent, or server-acknowledged** — Firestore's optimistic local writes make "succeeded" and "reached the server" feel identical on a good connection. Write the payload as one transaction, never clear local data on migration, and gate "done" on a server-acknowledged read. Given this app's history of silent data-format bugs (the UTC/local key mismatch went unnoticed for months), an automated test asserting the exact written document shape is non-negotiable — manual testing will not catch this.
5. **Security rules that check `auth != null` instead of `auth.uid == uid`** — the former lets any signed-in user read any other user's availability. Rules also do not cascade to subcollections. Ship a deny-case emulator test (can A read B?), not just an allow-case one.
6. **GDPR preconditions treated as a writing task** — Firestore region is chosen once and cannot be migrated; `currentUser.delete()` leaves Firestore documents orphaned forever with no error; Play Store Data Safety is a separate artifact from the privacy policy page.

## Contradictions Between Research Dimensions

Three points where the researchers disagree. These are **decisions for the plan phase**, not settled findings — flagged rather than silently reconciled.

| Question | FEATURES.md says | ARCHITECTURE.md / PITFALLS.md say | Assessment |
|---|---|---|---|
| **Second-device conflict** | Show a one-time binary chooser whenever the cloud doc is non-empty ("keep this device" vs "keep account data") | ARCHITECTURE's resolver silently pulls cloud when a *different* uid last synced on this device, and only prompts when the same account genuinely diverged. PITFALLS accepts "detect and refuse to overwrite, adopt cloud state" as a legitimate phase-1 stopgap | **All three agree blind local-wins over a populated cloud doc is a data-loss bug.** They differ on whether the user is asked or the cloud silently wins. ARCHITECTURE's version is more precise because it uses `lastSyncedUid` to distinguish "someone else's leftover local data" from "my own diverged data" — a distinction FEATURES misses. Recommend ARCHITECTURE's resolver, with the chooser reserved for the genuinely ambiguous same-account case. |
| **Live `.snapshots()` listeners** | Silent automatic sync is table stakes | ARCHITECTURE makes cross-device listeners build step 7 ("Android and web become one app"). PITFALLS #8 warns listeners are the main runaway-cost vector and recommends one-time `get()` for phase 1 | **Genuine conflict.** Cross-device live sync is the milestone's stated value ("web and Android become one app") but is also the most expensive pattern and the least critical for "accounts work at all." Recommend shipping `get()`-on-foreground first and adding listeners as a separate, measurable step — matching ARCHITECTURE's own ordering, which already puts listeners last. |
| **Feedback without an account** | Anonymous fallback is table stakes — the goal is calibration volume, not exclusivity | ARCHITECTURE gates the Firestore write on being signed in, per the milestone brief | **Scope call for the user.** FEATURES' argument is sound (most users won't sign in at launch; gating feedback loses the data you built this for), but it widens phase 2 and needs a security rule allowing unauthenticated writes. Raise explicitly during requirements. |
| **Availability write granularity** | Per-cell field writes for sane conflict granularity | PITFALLS: one document, written whole and debounced, to avoid write amplification | **Reconcilable, not a real conflict.** ARCHITECTURE's model already does both: one document containing a sparse `recurring` map with per-cell keys. Fields are individually addressable for merge purposes; the write is one debounced document write. No decision needed. |

## Implications for Roadmap

Research supports **five phases**, ordered by what unblocks what rather than by user-facing feature grouping. Numbering continues from v2.0 (last phase was 17).

### Phase 18: Preconditions
**Rationale:** Three constraints in `CLAUDE.md` are broken by this milestone and must be consciously revised before the first line of code. Two configuration decisions (Firestore region, SHA-1 registration) are effectively irreversible or have already burned this project once. Nothing here is code.
**Delivers:** Revised `CLAUDE.md`/`PROJECT.md` constraints with an explicit spend ceiling; Firestore database created in an EU region; Firebase Data Processing Terms accepted; SHA-1 audit across both Firebase Console and Cloud Console for debug + Play App Signing keys; documented separation of "Auth cap" (none) vs "Calendar-connect cap" (100 lifetime); Cloud Billing budget alert; rewritten privacy policy; updated Play Store Data Safety declaration.
**Avoids:** Pitfalls 3, 4, 9.
**Note:** The privacy policy rewrite is legal work with a real lead time. It blocks *release*, not the code — start it here, do not let it block phases 19–21.

### Phase 19: Auth
**Rationale:** Verifiable end-to-end on its own (sign in, see state change, sign out) before touching a single existing notifier or any user data. Isolates the highest-risk integration — the `GoogleSignIn.instance` collision — from data-migration bugs.
**Delivers:** Firebase wiring (`flutterfire configure`, `firebase_options.dart`, `google-services.json`, Gradle plugin, `Firebase.initializeApp()`); shared Google Sign-In bootstrap extending `CalendarService`'s existing guard; `authStateProvider`; account section in Profile; `kIsWeb` branch for web `signInWithPopup` plus the Auth/Calendar identity-mismatch warning.
**Avoids:** Pitfalls 1, 2, 10.
**Hard gate:** release-build (not debug) sign-in test on a real device, plus a cold-start stress test for the init race.

### Phase 20: Repository refactor (local-only)
**Rationale:** A pure refactor with zero user-visible change and zero Firebase involvement — safe to land and regression-test independently. It also fixes real existing debt: SharedPreferences keys are currently duplicated across `ProfileNotifier`, `AvailabilityNotifier`, and `background_task.dart`, which has a code comment admitting the mirroring.
**Delivers:** Three repositories with `cloud: null`; notifiers become thin; `background_task.dart` drops its mirrored key constants; new `updatedAt` and `account.lastSyncedUid` keys; `PlannedRidesNotifier` converted to async and made auth-reactive.
**Implements:** Architecture components 2.

### Phase 21: Sync + migration
**Rationale:** The heart of the milestone, and the phase where the "no backend" constraint is actually broken. The pure resolver should be built and unit-tested *first within this phase* — it decides the milestone's own stated open design question with no infrastructure required.
**Delivers:** `account_sync_resolver.dart` + unit tests; Firestore document read/write in the repositories; `firestore.rules` with deny-case emulator tests; `AccountSyncService.onSignIn`; the conflict prompt UI; account deletion including recursive Firestore document cleanup; pending-sync indicator.
**Avoids:** Pitfalls 5, 6, 7, 8.
**Hard gates:** automated test asserting exact Firestore document shape from production-shaped local data; deny-case rules test against *deployed* rules; two-account cross-read test; multi-tab test on real iPhone Safari; verified that account deletion removes Firestore documents, not just the Auth user.

### Phase 22: Account-backed feedback
**Rationale:** Milestone phase 2. Depends only on Auth existing; can run in parallel with 20–21 or after. Low cost — the score, weather inputs, and tolerance values are already live in app state at the moment "Send feedback" is tapped.
**Delivers:** `feedback_dialog.dart` rewritten from `mailto:` to a Firestore write carrying scoring context; feedback security rules (create-only, no client read).
**Open:** whether signed-out users can submit anonymously (see Contradictions).

### Phase Ordering Rationale

- Preconditions first because the Firestore region is unmigratable and the SHA-1 mistake has already cost this project once — both are cheap now and expensive later.
- Auth before any data work so the `GoogleSignIn` singleton collision surfaces in isolation, not tangled with migration bugs.
- The repository refactor sits between Auth and Sync deliberately: it is the only phase that is pure groundwork with no new failure surface, and doing it before cloud writes means the cloud sink is added to *one* place per domain instead of scattered call sites.
- Live cross-device listeners are last within Sync, per both the cost warning and the observation that they are the easiest thing to verify manually once everything else is solid.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 19 (Auth):** the `google_sign_in` 7.x + `firebase_auth` wiring on web is the single least-settled technical question and the one STACK.md would have covered. Verify the current FlutterFire recommendation against live docs at plan time.
- **Phase 21 (Sync):** Firestore web persistence configuration alongside Drift's existing IndexedDB usage — the multi-tab manager API and cache sizing need current-docs verification, and the v2.0 Safari eviction risk is now compounded rather than merely carried forward.

Phases with standard patterns (research can be skipped):
- **Phase 20 (Repository refactor):** mechanical, fully specified by ARCHITECTURE.md against real file paths.
- **Phase 22 (Feedback):** a single Firestore write; the context data already exists in app state.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Versions verified live on pub.dev 2026-07-25, but via ARCHITECTURE.md rather than a dedicated stack pass; no independent review of transitive/Gradle implications |
| Features | MEDIUM | Compliance claims (Play account-deletion policy, GDPR Art. 20) verified against official sources; consumer account-UX patterns are synthesized from precedent, no authoritative spec exists |
| Architecture | HIGH | Every file path confirmed by reading the actual codebase; Firestore shapes derived from the real in-memory models, not invented |
| Pitfalls | MEDIUM-HIGH | Firebase mechanics verified against official docs and current GitHub issues; exact SDK size/minSdk figures should be re-checked against the version pinned at implementation |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **No dedicated STACK.md.** Versions and the "do not add" list are captured above, but no independent pass was made on Gradle/AGP/Kotlin version implications of the Firebase Android SDKs, `minSdk` floor, or APK/web-bundle size impact. PITFALLS #10 flags all three as risks. Handle during Phase 19 planning: check `minSdk` before implementation, and build with only `firebase_core` added first to isolate build-time regressions.
- **Anonymous feedback is an open scope question** — decide during requirements, not implementation.
- **Web cold-start budget.** The app has a documented 2s cold-start constraint; the Firebase JS SDK adds real bundle weight. No measurement exists. Must be re-measured on a real device over real cellular after Phase 19, and a miss treated as blocking.
- **Calendar-scope grant counter.** The 100-user cap has no Google-side dashboard alert. If tracking is wanted, it needs to be built as a Firestore counter — decide whether that is in scope.

## Sources

### Primary (HIGH confidence)
- RideWindow codebase read directly 2026-07-25 — `lib/providers/*`, `lib/domain/services/availability_key.dart`, `lib/services/calendar_service.dart`, `lib/platform/background_task.dart`, `lib/main.dart`, `lib/app/router.dart`, `lib/features/profile/feedback_dialog.dart`, `pubspec.yaml`, `firebase.json`, `android/app/build.gradle.kts`
- pub.dev package pages fetched 2026-07-25 — `firebase_core` 4.12.1, `firebase_auth` 6.5.6, `cloud_firestore` 6.7.1
- [Firebase: Federated auth (Flutter)](https://firebase.google.com/docs/auth/flutter/federated-auth) — native vs web sign-in flows
- [Firestore: Access data offline](https://firebase.google.com/docs/firestore/manage-data/enable-offline) — offline persistence, last-write-wins, web persistence is opt-in
- [Google Play: app account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111) — enforced 2024-04-15
- [Google: sensitive scope verification](https://developers.google.com/identity/protocols/oauth2/production-readiness/sensitive-scope-verification) — 100-user lifetime cap semantics
- [Firebase/Google Cloud: insecure rules](https://firebase.google.com/docs/rules/insecure-rules) — test-mode expiry, `auth != null` insufficiency, non-cascading subcollections

### Secondary (MEDIUM confidence)
- flutter/flutter#70695, firebase/flutterfire#12034, #9929, #3561 — client-ID conflicts when adding Firebase config alongside existing `google_sign_in`; multi-tab persistence API and failure modes
- GDPR Art. 20 reference sources (Clarip, GDPR Local) — consistent across multiple legal references on format, scope, one-month deadline
- Consumer account/sync UX patterns (Todoist, Duolingo, Google Keep, Notion) — pattern-based, no authoritative spec

### Tertiary (LOW confidence)
- Chrome Sync reconciliation behaviour — support-community threads, used only to illustrate "don't blindly overwrite synced data," not as an implementation model

---
*Research completed: 2026-07-25*
*Ready for roadmap: yes — with three scope questions flagged under Contradictions*
