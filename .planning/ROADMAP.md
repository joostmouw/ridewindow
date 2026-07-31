# Roadmap: RideWindow

## Overview

RideWindow builds from the inside out: a pure-Dart scoring engine with 100% unit tests, layered with a Drift + Open-Meteo data stack, wired via a Riverpod provider graph, and finally surfaced across six screens (Welcome, Onboarding, Home, Ride Detail, Profile, Availability). v1.0 shipped this as a native Android app (Play Store, internal testing track). v2.0 ported the same Dart codebase to Flutter Web/PWA to reach iOS users without an Apple Developer account. v3.0 "Accounts & Sociaal" (scoped here to milestone phases 1–2 of `.planning/milestones/v3.0-ACCOUNTS.md`) turns the two local-only, disconnected data silos (Android SharedPreferences, browser storage) into one account-backed profile: Google Sign-In, Supabase/Postgres sync of profile/availability/planned rides, a defined migration/conflict story, and account-backed feedback carrying scoring context, replacing the `mailto:` route. (Stack revised from Firebase to Supabase on 2026-07-25, before Phase 18 began — Firebase Hosting still serves the PWA.)

## Milestones

- ✅ **v1.0 Android App** - Phases 1–10 (shipped, Internal testing track live)
- ✅ **v2.0 iOS Web App (PWA)** - Phases 11–17 (shipped 2026-07-17) — see `.planning/milestones/v2.0-ROADMAP.md`
- 🚧 **v3.0 Accounts & Sociaal (phases 1–2 only)** - Phases 18–22 (in progress) — see `.planning/milestones/v3.0-ACCOUNTS.md`. Milestone phases 3–5 (friends, shared availability, ride invites, server-side push) are explicitly deferred.

## Phases

**Phase Numbering:**

- Integer phases: Planned milestone work, numbered continuously across milestones (never restarts)
- Decimal phases (e.g., 1.5, 11.1, 18.1): Urgent insertions between integers

<details>
<summary>✅ v1.0 Android App (Phases 1–10) - SHIPPED</summary>

- [x] **Phase 1: Project skeleton + test infrastructure** - Flutter project boots, locked deps, canonical lib/ tree, structural test enforcing pure-Dart domain boundary
- [x] **Phase 1.5: Scoring domain — Freezed models + ScoringEngine + SlotGenerator** - Pure-Dart domain code with 100% unit test coverage of lib/domain/
- [x] **Phase 2: Data layer — Drift + Open-Meteo** - Drift schema, OpenMeteoClient, WeatherRepository, forecast cache
- [x] **Phase 3: Riverpod providers + state graph** - Full provider graph with ProviderContainer tests and reactive recomputation
- [x] **Phase 4: UI Phase A — Onboarding + Home + Welcome** - Welcome, Onboarding (4 presets), Home (week strip + ride cards)
- [x] **Phase 5: UI Phase B — Ride Detail + Insights sheet** - Ride Detail screen + "Why this score?" insights bottom sheet
- [x] **Phase 6: UI Phase C — Profile + Availability + Tolerance sliders** - Profile screen, availability calendar, tolerance sliders, ride-length chips
- [x] **Phase 7: Location — GPS + manual city + permission state machine** - geolocator, permission_handler, city picker fallback
- [x] **Phase 8: Background refresh + Notifications** - WorkManager, flutter_local_notifications, 3 notification types
- [x] **Phase 9: Google Calendar integration** - Lazy OAuth, AutoRefreshingAuthClient, calendar.events scope
- [x] **Phase 10: Release — Internal track only** - Signed AAB, Play App Signing, privacy policy, Data Safety form, Internal testing track

</details>

<details>
<summary>✅ v2.0 iOS Web App (PWA) (Phases 11–17) - SHIPPED 2026-07-17</summary>

**Milestone Goal:** Reach iOS users cheaply via a Flutter Web/PWA build of RideWindow, deployed to Firebase Hosting, without an Apple Developer account.

- [x] **Phase 11: Web Scaffolding & Build Baseline** - `web/` platform added, `flutter build web --release` (CanvasKit) works, existing UI renders/navigates with zero domain code changes, native-only plugins guarded
- [x] **Phase 12: Drift Web Persistence** - Drift's IndexedDB/wasm web backend wired and proven to survive page reload
- [x] **Phase 13: Geolocation & Manual Fallback** - Browser Geolocation API wired; manual city picker promoted to primary fallback for iOS Safari's per-session re-prompting
- [x] **Phase 14: Foreground Refresh Strategy** - On-load/on-focus/pull-to-refresh replaces WorkManager; "Last updated" label; stale-data fallback UI
- [x] **Phase 15: Google Calendar Web Integration** - Web OAuth client ID, popup-safe sign-in, "Add to calendar" verified end-to-end on the deployed domain
- [x] **Phase 16: PWA Installability & iOS Polish** - iOS meta tags, Add to Home Screen overlay, standalone-mode navigation, real-iPhone verification of install + storage durability
- [x] **Phase 17: Deployment Hardening & Firebase Hosting** - `firebase.json` routing/headers, production deploy, full Android + web regression pass

Full phase details, plans, and decisions: `.planning/milestones/v2.0-ROADMAP.md`. Requirements: `.planning/milestones/v2.0-REQUIREMENTS.md`.

</details>

### 🚧 v3.0 Accounts & Sociaal (phases 1–2 only) (In Progress)

**Milestone Goal:** Turn RideWindow's two separate data silos into one account-backed profile via Google Sign-In (Supabase Auth) and Postgres sync of profile/availability/planned rides, with a defined first-login/second-device migration story, and route feedback through that account. Scope is deliberately milestone phases 1–2 only (`.planning/milestones/v3.0-ACCOUNTS.md`) — friends, shared availability, ride invites, and server-side push (milestone phases 3–5) are deferred until this ships and testers respond.

- [x] **Phase 18: Preconditions** - Constraint revision, EU Supabase region, SHA-1 and OAuth client audit, rewritten privacy policy naming two sub-processors, Data Safety declaration, and the other release-blocking groundwork — no app code (completed 2026-07-26)
- [ ] **Phase 19: Auth** - Google Sign-In via Supabase `signInWithIdToken`, sign-out, cross-restart persistence, and a shared native/web bootstrap that reuses — rather than races — the existing Calendar integration's init gate
- [ ] **Phase 20: Repository refactor (local-only)** - Profile/availability/planned-rides persistence extracted into shared repositories, zero user-visible change, zero cloud involvement
- [ ] **Phase 21: Sync + migration** - Postgres sync of profile/availability/planned rides, an offline outbox, first-login and second-device conflict handling, row-level security, and account deletion
- [ ] **Phase 22: Account-backed feedback** - In-app feedback (signed-in or anonymous) carrying scoring context, replacing the `mailto:` flow

## Phase Details

Full phase-by-phase detail (goals, success criteria, plans) for both shipped milestones lives in their archive files:

- v1.0 Android App: see git history of this file prior to 2026-07-17 (archived inline, not yet split to a separate milestones file)
- v2.0 iOS Web App (PWA): `.planning/milestones/v2.0-ROADMAP.md`

Active milestone (v3.0 Accounts & Sociaal, phases 1–2 only) detail follows.

### Phase 18: Preconditions

**Goal**: Every release-blocking legal and infrastructure decision for shipping accounts is made and verified before any cloud code lands — including the two choices (Supabase project region, SHA-1 registration) that are effectively irreversible or have already cost this project a broken feature once.
**Depends on**: Phase 17 (v2.0, complete)
**Requirements**: PRE-01, PRE-02, PRE-03, PRE-04, PRE-05, PRE-06, PRE-07, PRE-08, PRE-09
**Success Criteria** (what must be TRUE):

  1. `CLAUDE.md` and `PROJECT.md`'s three broken v1/v2 constraints ("No backend", "Budget: no ongoing infra costs", "Privacy: data never leaves the device") are consciously rewritten, with the budget constraint restated as an explicit spend ceiling (PRE-01)
  2. The Supabase project exists in a verified EU region — Frankfurt, Ireland, Paris or Stockholm, not London or Zurich (checked in the dashboard, not assumed) — Supabase's DPA is in effect, and the privacy policy names both sub-processors, Supabase and Google (PRE-02, PRE-03)
  3. Both SHA-1 fingerprints (local release keystore and Play App Signing key, pulled from Play Console → App integrity) are registered on the Android OAuth client in Cloud Console, the deployed PWA origin is on the web OAuth client, and the web client ID is registered in Supabase's Google provider settings (PRE-04)
  4. The published privacy policy and the Play Store Data Safety declaration both reflect server-side storage of location data and calendar-derived availability, live before or at the accounts release (PRE-05, PRE-06)
  5. The Auth-cap-vs-Calendar-cap distinction is documented explicitly, a billing alert (notification, not a spend cap) is configured, a conscious decision is recorded about Supabase's 7-day free-tier inactivity pause, and a data retention/export answer is written down (PRE-07, PRE-08, PRE-09)

**Plans**: 4 - 18-01 constraint rewrite + written answers (PRE-01/07/08/09), 18-02 privacy policy NL+EN + deletion route (PRE-03/05/06), 18-03 keep-warm workflow (PRE-08), 18-04 console setup, manual (PRE-02/03/04/06)
**Note**: PRE-02 already satisfied - Supabase project provisioned 2026-07-25 in West EU (Paris, `eu-west-3`), free tier. Plan 18-04 re-verifies it in the dashboard rather than assuming.

### Phase 19: Auth

**Goal**: Users can sign in and out with their Google account from Profile, as an optional entry point rather than a gate, with signed-in state surviving restarts on both platforms — and this is proven not to have broken the existing release build, the PWA, or Google Calendar.
**Depends on**: Phase 18
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06, AUTH-07, AUTH-08, AUTH-10, REG-01, REG-02, REG-04
**Success Criteria** (what must be TRUE):

  1. User can sign in with Google from Profile as an optional entry point, and sees signed-in identity plus a sign-out action styled like the existing Google Calendar connection row (AUTH-01, AUTH-02)
  2. Signing out leaves all local data exactly as it was, and the signed-in state survives an app restart on both Android and web (AUTH-03, AUTH-04)
  3. Native and web share one non-racing Google Sign-In bootstrap; a mismatch between the signed-in account and the Calendar-authorized account is surfaced as a warning rather than silently proceeding; and switching Google accounts on the same device leaves no data from the previous account visible (AUTH-05, AUTH-06, AUTH-07, AUTH-08)
  4. Sign-in is proven working from a real release build installed from the Play Store track, not only from a debug build (AUTH-10) — hard gate, per this project's history of Calendar shipping broken for exactly this class of reason
  5. After `supabase_flutter` is added — and after `calendar_service.dart`'s shared `initialize()` gains `serverClientId`, which puts this change directly on the working Calendar path — the Android app still builds and runs correctly as a release build on a real device, the web PWA still installs/launches/navigates correctly, and "Add to calendar" still works end-to-end on both platforms (REG-01, REG-02, REG-04). A baseline web cold-start measurement is taken here, since the entire cloud SDK payload lands in this phase (feeds REG-03)

**Plans**: 7 plans
Plans:
**Wave 1**

- [x] 19-01-PLAN.md — Supabase bootstrap: pubspec + supabase_config.dart + Supabase.initialize() + seeded authStateProvider
- [x] 19-02-PLAN.md — Shared GoogleSignIn init gains serverClientId (AUTH-05, REG-04's sharpest gate)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 19-03-PLAN.md — Account section UI: sign-in/out, Android + web branch, wired into Profile as the first section

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 19-04-PLAN.md — Account switch detection (uid compare) + keep-or-restart dialog + local wipe
- [x] 19-05-PLAN.md — Calendar-mismatch warning on the existing Calendar row

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 19-06-PLAN.md — REGRESSION-CHECKLIST.md + release AAB build + green-suite gate

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 19-07-PLAN.md — Manual: Play Console upload + Android/iPhone-PWA verification + cold-start baseline (autonomous: false)

**UI hint**: yes

### Phase 20: Repository refactor (local-only)

**Goal**: Profile, availability, and planned-rides persistence move behind three shared repositories with zero user-visible change and zero cloud involvement — a pure regression-testable refactor that also retires the existing SharedPreferences key duplication between `ProfileNotifier`, `AvailabilityNotifier`, and `background_task.dart`, and prepares the `updatedAt`/`lastSyncedUid` fields Sync needs.
**Depends on**: Phase 19
**Requirements**: REG-05
**Success Criteria** (what must be TRUE):

  1. Profile, availability, and planned-rides screens behave identically to before the refactor for a signed-out user — no visible behavior change anywhere in the app
  2. `background_task.dart` reads profile/availability through the same repository the app uses, its three mirrored SharedPreferences key constants are gone, and it gains no Supabase dependency (REG-05)
  3. `PlannedRidesNotifier` is async and reacts to `authStateProvider` (rebuilds on sign-in/sign-out/account switch) without performing any cloud read or write yet
  4. The full existing automated test suite and `flutter build apk --release` both still pass after the refactor, with no cloud call added anywhere in this phase

**Plans**: TBD

### Phase 21: Sync + migration

**Goal**: A signed-in user's profile, availability, and planned rides live in Postgres and stay consistent across Android and web; first-login and second-device conflicts resolve to a defined, tested behavior instead of an accident; and one user's data is provably unreadable by another.
**Depends on**: Phase 20
**Requirements**: SYNC-01, SYNC-02, SYNC-03, SYNC-04, SYNC-05, SYNC-06, SYNC-07, SYNC-08, SYNC-09, SYNC-10, SYNC-11, SYNC-12, MIG-01, MIG-02, MIG-03, MIG-04, MIG-05, MIG-06, MIG-07, MIG-08, AUTH-09, REG-03
**Success Criteria** (what must be TRUE):

  1. A signed-in user's profile, availability, and planned rides are stored in Postgres; a change made on one platform appears on the other after the app is opened or foregrounded; offline edits apply locally immediately and reach the cloud once reconnected — which requires a real outbox, since Supabase queues no writes of its own; and the user can see whether their data is synced or still pending (SYNC-01, SYNC-02, SYNC-03, SYNC-04, SYNC-05, SYNC-06)
  2. The app still opens and shows forecast and slots within the existing 2-second budget without waiting on a cloud round-trip, and web cold-start time is re-measured on a real device over a real connection once startup actually performs cloud reads, with any regression past 2s treated as blocking (SYNC-07, REG-03)
  3. First sign-in on an empty account adopts the device's local data as-is; signing in where the account already holds data from a different device or account pulls the cloud state rather than overwriting it; a genuine same-account divergence prompts the user to choose which version to keep; and both a last-changed timestamp and the last-synced account are recorded so these three cases are distinguishable (MIG-01, MIG-02, MIG-03, MIG-04)
  4. Migration is written as one all-or-nothing, server-acknowledged operation — a single transaction via `rpc()`, never three separate table writes — that never deletes local data, verified by an automated test that seeds realistic production-shaped local data and asserts the exact resulting row shape (MIG-05, MIG-06, MIG-07, MIG-08)
  5. One user cannot read or write another user's data — proven by an automated deny-case test run against the deployed row-level security policies, not only a local instance; the forecast cache and calendar-imported blocks stay local and never sync; the app behaves correctly with more than one web tab open; availability writes go out as one batched row write; and deleting an account is verified to actually remove the user's rows, not merely to be declared by `on delete cascade` (SYNC-08, SYNC-09, SYNC-10, SYNC-11, SYNC-12, AUTH-09)

**Plans**: TBD
**UI hint**: yes

### Phase 22: Account-backed feedback

**Goal**: Feedback moves from a `mailto:` link to an in-app record that automatically carries the scoring context it refers to, available whether or not the user is signed in.
**Depends on**: Phase 19 (needs a signed-in user to exist; can run in parallel with Phase 20–21 or after)
**Requirements**: FB-01, FB-02, FB-03, FB-04, FB-05
**Success Criteria** (what must be TRUE):

  1. A signed-in user can send feedback from within the app, replacing the `mailto:` route (FB-01)
  2. Submitted feedback automatically carries the score, the weather inputs behind it, and the user's own tolerance settings at that moment (FB-02)
  3. A user who is not signed in can still send feedback anonymously, so feedback volume does not collapse to the signed-in minority (FB-03)
  4. Feedback composed without a connection is queued locally and sent once a connection returns, rather than lost (FB-04)
  5. Feedback rows can be created by the client but not read or listed back by it — an insert policy with no select policy at all (FB-05)

**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 1.5 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18 → 19 → 20 → 21 → 22 (Phase 22 may run in parallel with 20–21 once Phase 19 is complete, per its dependency note above)

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Project skeleton + test infrastructure | v1.0 | 3/3 | Complete | 2026-06-02 |
| 1.5. Scoring domain — Freezed models + ScoringEngine + SlotGenerator | v1.0 | 0/TBD | Not started | - |
| 2. Data layer — Drift + Open-Meteo | v1.0 | 3/3 | Complete | 2026-06-02 |
| 3. Riverpod providers + state graph | v1.0 | 4/4 | Complete | 2026-06-03 |
| 4. UI Phase A — Onboarding + Home + Welcome | v1.0 | 0/5 | Not started | - |
| 5. UI Phase B — Ride Detail + Insights sheet | v1.0 | 0/TBD | Not started | - |
| 6. UI Phase C — Profile + Availability + Tolerance sliders | v1.0 | 0/TBD | Not started | - |
| 7. Location — GPS + manual city + permission state machine | v1.0 | 0/TBD | Not started | - |
| 8. Background refresh + Notifications | v1.0 | 0/TBD | Not started | - |
| 9. Google Calendar integration | v1.0 | 0/TBD | Not started | - |
| 10. Release — Internal track only | v1.0 | 0/TBD | Not started | - |
| 11. Web Scaffolding & Build Baseline | v2.0 | 1/1 | Complete   | 2026-07-11 |
| 12. Drift Web Persistence | v2.0 | 1/1 | Complete   | 2026-07-11 |
| 13. Geolocation & Manual Fallback | v2.0 | 1/1 | Complete   | 2026-07-11 |
| 14. Foreground Refresh Strategy | v2.0 | 1/1 | Complete   | 2026-07-12 |
| 15. Google Calendar Web Integration | v2.0 | 2/2 | Complete    | 2026-07-14 |
| 16. PWA Installability & iOS Polish | v2.0 | 4/4 | Complete   | 2026-07-17 |
| 17. Deployment Hardening & Firebase Hosting | v2.0 | 1/1 | Complete   | 2026-07-17 |
| 18. Preconditions | v3.0 | 4/4 | Complete    | 2026-07-26 |
| 19. Auth | v3.0 | 6/7 | In Progress|  |
| 20. Repository refactor (local-only) | v3.0 | 1/2 | In Progress|  |
| 21. Sync + migration | v3.0 | 0/TBD | Not started | - |
| 22. Account-backed feedback | v3.0 | 0/TBD | Not started | - |

**Note:** The v1.0 progress table rows above (Phases 1, 2, 3 marked Complete; others Not started) reflect the state carried over from the v1.0 STATE.md snapshot at milestone transition — see `git log` / `.planning/STATE.md` Accumulated Context for actual v1.0 completion history (all of Phases 1–10 shipped to the Internal testing track).
