---
phase: 15-google-calendar-web-integration
verified: 2026-07-14T13:40:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
---

# Phase 15: Google Calendar Web Integration Verification Report

**Phase Goal:** Web users can add a ride slot to Google Calendar directly from the deployed app, with sign-in surviving Safari's popup blocker and FedCM incompatibility
**Verified:** 2026-07-14T13:40:00Z
**Status:** passed
**Re-verification:** No — initial verification

**MVP mode note:** ROADMAP.md marks this phase `Mode: mvp`, but the phase Goal line is written as a technical/UX outcome, not strict `As a / I want to / so that` format (`gsd-sdk query user-story.validate` returns `valid: false`). This is a project-wide convention carried through Phases 11–14 (not introduced by this phase), and both plans explicitly reframe the goal as a user story in their `<objective>` sections. Rather than refuse verification outright (which would be inconsistent with how every other v2.0 phase was verified), I proceeded using the ROADMAP's four numbered Success Criteria as the must-haves — these are concrete, testable, and a strict superset of what a generic user-story flow table would check. Flagging as INFO for process consistency, not a phase blocker.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `CalendarService` initializes with a platform-conditional web OAuth `clientId` configured in Google Cloud Console for the Firebase Hosting domain; native Android config unchanged | ✓ VERIFIED | `web/index.html` carries `<meta name="google-signin-client_id" content="300023366326-ddo399qf5lavv48njbfpm7rg0mc8cnno.apps.googleusercontent.com">`; confirmed served live via `curl https://my-project-joost.web.app` (exact string present in response body). `lib/services/calendar_service.dart`'s Android-relevant methods (`addRideSlotToCalendar`, `getEvents`, the lazy-only semantics of `_ensureInitialized`) are behavior-preserving — the only change is delegating to a shared memoized `_sharedInitialize()` future, and `warmUpForWeb()` is only ever invoked from `main.dart`'s `kIsWeb`-gated block, so native's on-tap-only init timing (CAL-02) is unchanged. `flutter build apk --release` re-run during this verification exits 0. |
| 2 | Tapping "Add to calendar" on the deployed production URL (not localhost) opens the Google sign-in popup synchronously inside the tap handler (not blocked by Safari) and completes the OAuth consent flow | ✓ VERIFIED | `lib/main.dart` line 73-75: `if (kIsWeb) { await CalendarService.warmUpForWeb(); }` placed after `runApp()`, eagerly initializing `GoogleSignIn.instance` before any tap so `authorizeScopes()` is the first/only awaited call in the tap chain. Per task instructions, real-device manual verification is treated as valid evidence (not re-requested): 15-02-SUMMARY.md documents the flow independently confirmed by two real-iPhone-Safari testers (Jacco, Bas) plus the developer on desktop, all reporting first-tap popup success against `https://my-project-joost.web.app` (not localhost) with no retry needed. |
| 3 | A real Google Calendar event is created with the correct start/end time and weather summary, verified end-to-end in a real browser against the deployed production domain | ✓ VERIFIED | `addRideSlotToCalendar()` builds a real `Event` with `EventDateTime(dateTime: slot.start/end, timeZone: 'Europe/Amsterdam')` and `description: buildWeatherSummary(forecasts)`, inserted via `calendarApi.events.insert(event, 'primary')` — no static/stub return. 15-02-SUMMARY.md documents desktop-browser verification against the live production URL confirming a real Calendar event with correct title/time/weather description. |
| 4 | The full flow is manually verified on a real iPhone in Safari (not just desktop Chrome), given LOW research confidence on iOS popup/FedCM behavior | ✓ VERIFIED | 15-02-SUMMARY.md documents two independent real-iPhone-Safari testers, both confirming first-tap OAuth popup success (no Safari popup-block, no FedCM issue) and correct event creation against `https://my-project-joost.web.app`. Per task instructions this is accepted as valid human verification evidence. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/services/calendar_service.dart` | `warmUpForWeb()` static method, memoized, safe to call repeatedly | ✓ VERIFIED | Method exists (lines 58-69), backed by `_sharedInitialize()`/`_initFuture` memoization added as a Rule-1 bugfix for a real concurrency race found during manual testing. `addRideSlotToCalendar`/`getEvents` bodies functionally unchanged. |
| `lib/main.dart` | `kIsWeb`-gated call to `CalendarService.warmUpForWeb()` after `runApp()` | ✓ VERIFIED | Lines 69-75, correctly placed as the structural inverse of the existing `!kIsWeb` WorkManager block. |
| `web/index.html` | `google-signin-client_id` meta tag with real client ID | ✓ VERIFIED | Line 31, real value (not placeholder), and confirmed present in the actual deployed/served HTML via live `curl`. |
| `firebase.json` | Hosting config: `build/web` public dir, SPA rewrite, `*.wasm` Content-Type header | ✓ VERIFIED | All three present; confirmed live — `curl -sI https://my-project-joost.web.app/sqlite3.wasm` returns `content-type: application/wasm`, and the SPA loads with HTTP 200. |
| `.firebaserc` | Default project pointer | ✓ VERIFIED | `{"projects":{"default":"my-project-joost"}}`, matching the live deployed project. |
| `test/services/calendar_service_test.dart` | New `warmUpForWeb` test group (completes, idempotent, concurrency-safe) | ✓ VERIFIED | 3 new tests present and passing (see Spot-Checks below). |
| `test/web/index_html_meta_tag_test.dart` | Asserts real client ID present, no placeholder | ✓ VERIFIED | Present and passing. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `lib/main.dart` (`if (kIsWeb)` block) | `CalendarService.warmUpForWeb()` | Direct call after `runApp()` | ✓ WIRED | `grep -c` confirms exactly one call site, correctly gated. |
| `web/index.html` meta tag | `google_sign_in_web`'s GIS SDK bootstrap | Runtime meta-tag read (no Dart-side clientId param) | ✓ WIRED | Confirmed indirectly and directly: the manual verification popup opened correctly with no "missing client_id" error (which RESEARCH.md flagged as the specific failure symptom if this mechanism were broken) — real end-to-end proof the meta tag is being read. |
| `firebase.json` (`hosting.public`) | `flutter build web --release` output | `"public": "build/web"` | ✓ WIRED | Live deployment confirmed serving the built app (200 response, correct wasm content-type, correct HTML with real client ID). |
| Google Cloud Console Web OAuth client (Authorized JS origins) | `https://my-project-joost.web.app` | Console config, extended in 15-02 Task 3 | ✓ WIRED | Verified functionally — the OAuth popup completed successfully against this exact origin in both desktop and real-iPhone-Safari testing (an origin mismatch would have blocked the popup entirely). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|---------------------|--------|
| `web/index.html` meta tag | `google-signin-client_id` content attribute | Static asset, deployed via `firebase deploy` | Confirmed via live `curl` against the production URL — the deployed HTML byte-for-byte matches the repo's real client ID, not a build artifact discrepancy | ✓ FLOWING |
| `firebase.json` `*.wasm` header rule | Response `Content-Type` header | Firebase Hosting header rule applied at serve time | Confirmed via `curl -sI .../sqlite3.wasm` returning `content-type: application/wasm` on the live domain | ✓ FLOWING |
| `CalendarService.addRideSlotToCalendar()` | Calendar `Event` object | `RideSlot`/`HourlyForecast` passed in from the caller, real `calendarApi.events.insert()` call (no static/stub JSON return) | Confirmed by code inspection (no hardcoded empty return) plus human-verified real Calendar events created in both plans' manual checks | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Unit/regression tests for `warmUpForWeb()` + meta tag pass | `flutter test test/services/calendar_service_test.dart test/web/index_html_meta_tag_test.dart` | `10/10 passed` (re-run independently during this verification, not just trusted from SUMMARY) | ✓ PASS |
| `flutter analyze` on touched files is clean | `flutter analyze lib/services/calendar_service.dart lib/main.dart test/services/calendar_service_test.dart test/web/index_html_meta_tag_test.dart` | 1 info-level `prefer_const_constructors` hint only, zero errors/warnings | ✓ PASS |
| Android regression build still passes | `flutter build apk --release` | Re-run independently during this verification: `✓ Built build/app/outputs/flutter-apk/app-release.apk (66.3MB)`, exit 0 | ✓ PASS |
| Production Firebase Hosting URL is live and reachable | `curl -sI https://my-project-joost.web.app` | `HTTP/2 200`, `content-type: text/html` | ✓ PASS |
| Deployed HTML actually contains the real OAuth client ID (not just the local repo file) | `curl -s https://my-project-joost.web.app \| grep google-signin-client_id` | Returns the exact real client ID string | ✓ PASS |
| Deployed `sqlite3.wasm` is served with correct Content-Type | `curl -sI https://my-project-joost.web.app/sqlite3.wasm` | `content-type: application/wasm`, HTTP 200 | ✓ PASS |

### Probe Execution

Not applicable — no `scripts/*/tests/probe-*.sh` files exist in this repo and neither plan declares probe-based verification; this phase uses manual real-device checkpoints instead, which are handled under Behavioral Spot-Checks and Observable Truths above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| CAL-06 | 15-01-PLAN.md | `CalendarService` initializes with a platform-conditional web OAuth `clientId`; native config unchanged | ✓ SATISFIED | `warmUpForWeb()`, `main.dart` wiring, `web/index.html` meta tag, all confirmed live and tested. |
| CAL-07 | 15-02-PLAN.md | "Add to calendar" manually verified end-to-end against the deployed production Firebase Hosting domain (not localhost), including OAuth popup/consent in a real browser | ✓ SATISFIED | Live Firebase Hosting deploy confirmed; desktop + real iPhone Safari (two testers) manual verification documented in 15-02-SUMMARY.md. |

No orphaned requirements — REQUIREMENTS.md maps exactly CAL-06 and CAL-07 to Phase 15, and both appear in a plan's `requirements:` frontmatter field.

**Process note (not a phase-15 defect):** REQUIREMENTS.md's checkbox list and Traceability table still show CAL-06/CAL-07 (and every other v2.0 requirement, including Phases 11-14's already-completed work) as unchecked/"Pending". This is a pre-existing, repo-wide documentation-hygiene gap that predates and is unrelated to this phase's execution — confirmed via `git log` showing REQUIREMENTS.md has not been touched since it was authored, across all of Phases 11-15. Recommend a housekeeping pass across the whole v2.0 milestone rather than treating this as a Phase 15-specific gap.

### Anti-Patterns Found

None in the files this phase modified (`lib/services/calendar_service.dart`, `lib/main.dart`, `web/index.html`, `firebase.json`, `.firebaserc`, `.gitignore`, both test files). No `TBD`/`FIXME`/`XXX`/`HACK` markers, no stub returns, no empty handlers. The one string match for "placeholder" in `web/index.html` is Flutter's own boilerplate comment about `$FLUTTER_BASE_HREF`, unrelated to this phase.

**Notable limitation (WARNING, human-decision item — already known and tracked, not newly discovered):** The Google OAuth consent screen for the Web OAuth client remains in "Testing" publish status. Per 15-02-SUMMARY.md's own "Issues Encountered" section, both real-device testers hit Google's "Access blocked: this app has not completed Google's verification process" screen on their first attempt and had to be manually added as OAuth consent-screen test users before the flow would proceed. This means the phase's literal goal statement — "**Web users** can add a ride slot to Google Calendar directly from the deployed app" — is currently true only for developer- and tester-allowlisted Google accounts, not for the general public visiting the production URL. This was an explicit, in-session decision by the developer during phase execution (tracked as backlog item #31, first logged in 15-01-SUMMARY.md and reconfirmed in 15-02-SUMMARY.md), and none of the ROADMAP's four numbered Success Criteria for this phase require public consent-screen verification — so this does not fail any stated must-have and does not block phase completion. Checked all later-phase ROADMAP entries (Phase 16 PWA, Phase 17 Deploy) for a match: neither mentions OAuth consent-screen publishing, so this cannot be deferred to a specific later phase per Step 9b's evidence requirement. Surfacing this explicitly so it doesn't get lost — recommend adding a dedicated backlog/future-phase item for publishing or verifying the OAuth consent screen before this feature is promoted to real end users.

### Human Verification Required

None. Both plans' human-verification checkpoints (Chrome/localhost popup+event creation in 15-01, desktop+real-iPhone-Safari production verification in 15-02) were already performed live by the developer and two independent testers, as instructed, and are accepted as valid evidence per this verification's task brief.

### Gaps Summary

No gaps against the ROADMAP's four stated Success Criteria. All four are independently re-verified in this session (not merely re-read from SUMMARY.md): tests re-run (10/10 pass), `flutter analyze` re-run (clean), `flutter build apk --release` re-run (exit 0), and the production Firebase Hosting URL independently re-checked live via `curl` (HTTP 200, correct client ID present in served HTML, correct wasm Content-Type header) — all matching what the SUMMARYs claimed. The one open item worth developer attention is the OAuth consent screen's Testing-mode restriction (see Anti-Patterns section above), which is a known, already-tracked limitation (backlog item #31) rather than a phase-blocking gap.

---

*Verified: 2026-07-14T13:40:00Z*
*Verifier: Claude (gsd-verifier)*
