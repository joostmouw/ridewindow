# Phase 15: Google Calendar Web Integration - Research

**Researched:** 2026-07-12
**Domain:** Flutter Web OAuth (google_sign_in 7.x / google_sign_in_web), Google Identity Services, Safari popup-blocking, FedCM
**Confidence:** LOW-MEDIUM (matches the phase's own stated LOW-confidence flag; see Assumptions Log and Open Questions)

## Summary

The existing `CalendarService` (`lib/services/calendar_service.dart`, built in Phase 9, Android-only so far) never calls `GoogleSignIn.instance.authenticate()`. It goes straight to `GoogleSignIn.instance.authorizationClient.authorizeScopes([CalendarApi.calendarEventsScope])`. This turns out to matter a great deal for the web port: `google_sign_in_web` 1.1.3 explicitly does **not** support `authenticate()` on web (`supportsAuthentication` returns `false`, calling it throws) because the underlying Google Identity Services (GIS) SDK only allows sign-in through its own rendered UI (`renderButton()`) or FedCM — but `authorizeScopes()` is a *separate* code path. On the web, scope authorization is implemented via Google's `google.accounts.oauth2` **token client** (`initTokenClient()` / `requestAccessToken()`), which is architecturally distinct from GIS identity/FedCM sign-in: it opens its own popup, handles account picking + consent together, and does not require a prior FedCM-based "who is this user" step. This is genuinely good news for CAL-06/CAL-07 — it suggests the existing scope-only, no-`authenticate()` pattern may port to web with **no code change to the sign-in flow itself**, only (a) a platform-conditional OAuth Web client ID and (b) making sure the popup opens synchronously inside the tap handler.

The two real risks are: (1) Safari's popup blocker, which only allows `window.open()`-derived popups when they are triggered synchronously within a user gesture's call stack — any `await` (including `GoogleSignIn.instance.initialize()`) placed *before* the call that opens the popup breaks this chain on Safari/iOS, even though it works fine on Chrome; and (2) whether `GoogleSignIn.instance.authorizationClient.authorizeScopes()` (called on the singleton, not on a `GoogleSignInAccount`) behaves correctly on web without any prior sign-in step — official docs say this "depends on platform and current application state" and do not document the web behavior explicitly. This is the core unknown research could not fully resolve without running the code in a real browser, which is exactly why the phase's success criteria mandate manual verification in real Safari.

FedCM itself is very unlikely to be the actual blocker here: Safari has **no planned FedCM implementation** (Apple's stated focus is passkeys instead), and FedCM only governs the identity/One-Tap sign-in flow, which this feature does not use. The relevant compatibility surface is the OAuth2 token-client popup, not FedCM.

**Primary recommendation:** Add a Web OAuth client (Google Cloud Console) scoped to the Firebase Hosting domain; configure it via the `google-signin-client_id` meta tag in `web/index.html` (the documented mechanism) using build-time templating or a `kIsWeb`/`isWebPlatform`-conditional value; keep `CalendarService`'s scope-only flow as-is architecturally, but restructure `_ensureInitialized()` so the `authorizeScopes()` call is reachable without an `await` gap between the tap and the popup-opening call on web; and treat criterion 4 (real iPhone Safari) as a hard gate, not a formality, because this is the one thing training data and documentation cannot verify.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CAL-06 | `CalendarService` initializes with a platform-conditional web OAuth `clientId` (from Google Cloud Console) on web; native config unchanged on Android | See Architecture Patterns > Pattern 1 (reuse `isWebPlatform` seam) and Code Examples (meta tag vs `initialize(clientId:)`); Open Question 3 on client ID scoping |
| CAL-07 | "Add to calendar" is manually verified end-to-end against the deployed production Firebase Hosting domain (not just localhost), including the OAuth popup/consent flow in a real browser | See Pitfall 1 (synchronous-gesture requirement), Pitfall 4 (unverified `authorizeScopes()` web behavior), Pitfall 5 (phase-ordering gap re: needing a real deploy before Phase 17), and Environment Availability (Firebase CLI not installed) |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| OAuth client ID selection (native vs web) | Browser / Client (Flutter Web build) | — | Purely a build/runtime config concern; no backend exists (CLAUDE.md: "no backend, pure client-side") |
| Sign-in popup / consent UI | Browser / Client | — | `google_sign_in_web` renders its own popup via GIS SDK; Flutter has no control over popup mechanics beyond gesture timing |
| Calendar event creation (`CalendarApi.events.insert`) | Browser / Client | — | `googleapis` Dart client issues an authenticated `fetch`/XHR directly from the browser to `www.googleapis.com/calendar/v3` (CORS-enabled for Bearer-token requests); no proxy/backend involved |
| Access token storage/lifecycle | Browser / Client (in-memory, `GoogleSignInClientAuthorization`) | — | No refresh on web (token expires after 3600s); app must re-request, not persist long-lived tokens |
| Hosting domain / OAuth origin allowlist | CDN / Static (Firebase Hosting) | Browser / Client | Google Cloud Console's "Authorized JavaScript origins" must match the exact Firebase Hosting domain the popup runs from |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `google_sign_in` | 7.2.0 (already pinned in `pubspec.yaml`) | Cross-platform OAuth sign-in/authorization facade | Already the project's chosen package (CLAUDE.md); no alternative needed |
| `google_sign_in_web` | 1.1.3 (transitive, resolved in `pubspec.lock`) [VERIFIED: pubspec.lock] | Web platform implementation, GIS-SDK-backed | Endorsed federated plugin — automatically pulled in, do not add directly unless `renderButton()`/`web_only.dart` is imported |
| `extension_google_sign_in_as_googleapis_auth` | 3.0.0 (already pinned) | Bridges `GoogleSignInClientAuthorization` → `AuthClient` for `googleapis` | Listed as supporting the `web` platform tag on pub.dev [CITED: pub.dev package page] |
| `googleapis` (calendar/v3) | 16.0.0 (already pinned) | Typed Calendar API client | Pure-Dart HTTP client; Google's Calendar API v3 REST endpoint is CORS-enabled for authenticated (Bearer-token) requests from a browser, confirmed by Google's own official JavaScript quickstart pattern (`fetch(...).headers.Authorization = 'Bearer ' + token`) [CITED: developers.google.com/workspace/calendar/api/quickstart/js] |

**No new packages are required for this phase.** All three Google-auth packages are already installed and were used to build the Android flow in Phase 9. This phase is a **configuration and platform-branching** problem, not a new-dependency problem.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `authorizeScopes()`-only flow (current pattern) | `authenticate()` + `renderButton()` + `authenticationEvents` (the documented "normal" web sign-in flow) | Would require a visible GIS-rendered button widget (can't be triggered from an arbitrary app button) and pulls in FedCM-adjacent code paths for a feature that only needs Calendar *authorization*, not identity. Only fall back to this if the scope-only flow proves unreliable in real-Safari testing (see Open Questions). |
| Client-side-only OAuth (current architecture) | Server-side OAuth (authorization code flow via a backend) | Rejected — project has no backend (CLAUDE.md constraint: "No backend: Pure client-side") and this would be new infrastructure disproportionate to the feature |

**Installation:** None — no `pubspec.yaml` changes needed.

## Package Legitimacy Audit

No new external packages are being installed in this phase. `google_sign_in`, `google_sign_in_web`, `extension_google_sign_in_as_googleapis_auth`, and `googleapis` were already vetted and shipped in Phase 9/10 (Android). Slopcheck was not re-run since no new packages are proposed; if the planner discovers a genuine need for an additional package (e.g., a polyfill), it must go through the Package Legitimacy Gate at that time.

**Packages removed due to slopcheck [SLOP] verdict:** none (N/A — no new packages)
**Packages flagged as suspicious [SUS]:** none (N/A — no new packages)

## Architecture Patterns

### System Architecture Diagram

```
User taps "Add to calendar" (Ride Detail screen)
        │  (must stay synchronous — see Pitfall 1)
        ▼
CalendarService.addRideSlotToCalendar()
        │
        ├─ kIsWeb / isWebPlatform? ──▶ Web OAuth client ID
        │                              (from web/index.html meta tag,
        │                               injected per-environment)
        │
        ├─ NOT web ────────────────▶ Native (Android) client ID
        │                              (google-services / SHA-1 — UNCHANGED)
        │
        ▼
GoogleSignIn.instance.authorizationClient.authorizeScopes(
    [CalendarApi.calendarEventsScope])
        │
        │  Web: google.accounts.oauth2 token-client popup
        │       (account picker + consent, GIS SDK, NOT FedCM)
        │  Android: native account chooser (Google Play Services)
        ▼
GoogleSignInClientAuthorization (access token, in-memory only)
        │
        ▼
authorization.authClient(scopes: [...])   (extension_google_sign_in_as_googleapis_auth)
        │
        ▼
CalendarApi(client).events.insert(event, 'primary')
        │
        │  Direct browser fetch to www.googleapis.com/calendar/v3/...
        │  with `Authorization: Bearer <token>` header (CORS-enabled)
        ▼
Real Google Calendar event created on user's primary calendar
```

### Recommended Project Structure

No new files are strictly required. The existing single-file `CalendarService` can absorb the platform branch:

```
lib/
├── services/
│   └── calendar_service.dart   # add kIsWeb/isWebPlatform branch for clientId
├── core/
│   └── platform_info.dart      # ALREADY EXISTS (Phase 13) — reuse isWebPlatform, do not re-invent kIsWeb branching
web/
└── index.html                  # add <meta name="google-signin-client_id" ...> (web-only client ID)
```

### Pattern 1: Reuse the project's existing `isWebPlatform` testability seam

**What:** `lib/core/platform_info.dart` (built in Phase 13, Plan 01) already exports `isWebPlatform` specifically so that `kIsWeb`-gated behavior stays testable under `flutter test` (a compile-time-constant `kIsWeb` is always `false` under the Dart VM test runner and can never be toggled at runtime).
**When to use:** Any place `CalendarService` needs to branch on web vs native (e.g., choosing which client ID string to pass, or whether to log a web-specific diagnostic).
**Example:**
```dart
// Source: lib/core/platform_info.dart (existing project pattern, Phase 13)
import 'package:ridewindow/core/platform_info.dart';

if (isWebPlatform) {
  // web-specific behavior
} else {
  // native (Android) behavior — UNCHANGED
}
```
**Established precedent:** `lib/providers/gps_permission_notifier.dart` already uses this exact pattern to guard `openAppSettings()` on web (LOC-07). The planner should follow this precedent rather than importing `kIsWeb` directly in `CalendarService`.

### Pattern 2: Preserve the synchronous-gesture call chain

**What:** Safari (and Firefox, more leniently) requires the code path from the user's `onTap`/`onPressed` handler to the call that actually opens the popup (`requestAccessToken()` under the hood) to have no unresolved `await` in between, or the browser treats the resulting popup as programmatic and blocks it. Chrome is much more forgiving of this, which is why the existing Android-first codebase has never surfaced this issue.
**When to use:** The tap handler currently in `ride_detail_screen.dart`:
```dart
Future<void> _addToCalendar() async {
  setState(() => _isLoading = true);   // OK — synchronous, no await yet
  try {
    await widget.calendarServiceFactory().addRideSlotToCalendar(
      widget.slot, widget.forecasts,
    );
```
`addRideSlotToCalendar()` itself currently does:
```dart
Future<void> _ensureInitialized() async {
  if (_initialized) return;
  await GoogleSignIn.instance.initialize();   // <-- an await BEFORE authorizeScopes()
  _initialized = true;
}
...
await _ensureInitialized();                    // <-- another await gap
authorization = await GoogleSignIn.instance.authorizationClient
    .authorizeScopes([CalendarApi.calendarEventsScope]);  // <-- the actual popup call
```
On the **first** tap of a session, `_ensureInitialized()` performs a real `await GoogleSignIn.instance.initialize()` before the popup-opening call, which is exactly the async gap Safari's popup blocker is known to reject (see Pitfall 1). Subsequent taps (after `_initialized` is already `true`) do not have this gap, matching the documented Safari behavior that "the first click attempt is blocked, but subsequent clicks are not" [CITED: multiple cross-referenced Safari/GIS popup-blocking reports, see Sources].
**Recommendation:** Initialize `GoogleSignIn.instance` **eagerly at app startup** (once, off the critical tap path) on web — e.g., in `main.dart` alongside the existing `kIsWeb` guards — so that by the time the user taps "Add to calendar," `_initialized` is already `true` and `authorizeScopes()` is the very first (and only) awaited call in the tap handler's chain. This removes the async gap without changing the native (Android) code path, where `GoogleSignIn.instance.initialize()` is comparatively cheap and lazy-init was a deliberate choice (CAL-02, see file header comment: "GoogleSignIn.instance wordt uitsluitend lazy gebruikt... nooit aangemaakt bij app-start"). This is a genuine tension between the CAL-02 decision (native) and the Safari popup-timing requirement (web) that the planner must explicitly resolve, most likely by making eager-init web-only via `isWebPlatform`.

### Anti-Patterns to Avoid
- **Awaiting anything (network call, `Future.delayed`, a second frame, a dialog) between the tap handler and `authorizeScopes()` on web:** breaks Safari's synchronous-gesture requirement even if it works fine in Chrome during dev testing on a laptop.
- **Testing only in desktop Chrome and calling it done:** the phase's own success criteria (point 4) explicitly call this out — desktop Chrome's popup blocker is far more permissive than mobile Safari's, and FedCM/GIS behavior differs meaningfully between them.
- **Adding the Web client ID directly into source-controlled `web/index.html` as a hardcoded literal without checking whether it needs to differ between local dev and production Firebase Hosting origins:** Google Cloud Console's "Authorized JavaScript origins" is an *exact-match* allowlist per origin (scheme+host+port); a client ID authorized only for the production Firebase Hosting domain will fail silently (or with a console error) when tested from `localhost`, and vice versa. Decide explicitly whether one Web client ID with multiple authorized origins (`localhost:PORT` + the production domain) is used, or two separate client IDs — the former is simpler and is what Google's own quickstart docs assume.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Detecting "is this popup being blocked by Safari" | Custom `window.open()` return-value polling / timeout heuristics | Rely on `google_sign_in_web`'s existing `GoogleSignInException` surfaced through `authorizeScopes()`'s `catch` clause (already handled in `CalendarService` for the `canceled` code) | The plugin already surfaces failures as `GoogleSignInException`; a homegrown popup-blocked detector would duplicate logic the plugin's JS interop layer already owns, and would need constant tuning per-browser |
| Platform-conditional client ID wiring | A custom `dart:html`/`dart:js_interop` shim to inject the meta tag at runtime | The documented `<meta name="google-signin-client_id" content="...">` tag in `web/index.html`, combined with the project's existing `isWebPlatform` seam for any Dart-side branching (e.g., passing `clientId:` to `initialize()` only for non-web platforms) | This is the officially documented integration path for `google_sign_in_web`; runtime injection would be unsupported and fragile across `google_sign_in_web` releases |

**Key insight:** Nearly everything this phase needs already exists in the project (the `isWebPlatform` seam, the scope-only `CalendarService` pattern, the `googleapis` client). The actual work is narrow: one Cloud Console client ID, one meta tag / conditional `clientId:` parameter, one reordering of `await`s to preserve the synchronous gesture chain, and thorough real-device verification.

## Common Pitfalls

### Pitfall 1: Async gap before the popup call breaks Safari on first tap only
**What goes wrong:** The sign-in popup opens fine in Chrome, and even opens fine in Safari on the *second* tap of a session, lulling a developer testing quickly into believing it works — but the *first* tap in a fresh session is silently blocked (or shows Safari's small "popup blocked" banner) because of the `await GoogleSignIn.instance.initialize()` gap inside `_ensureInitialized()`.
**Why it happens:** Safari's popup blocker inspects whether the JS call stack that invoked `window.open()` traces back synchronously to a trusted user-gesture event (click/tap). Any `await` — even one that resolves near-instantly — breaks that synchronous chain from Safari's perspective. [CITED: cross-referenced across GitHub issues flutter/flutter#54768, flutter/flutter#81447, google/google-api-javascript-client#925, and general Chrome/Safari popup-blocking documentation]
**How to avoid:** Move `GoogleSignIn.instance.initialize()` to run once eagerly at app startup on web (off the tap's call chain), per Pattern 2 above, so `authorizeScopes()` is the first awaited call triggered directly by the tap.
**Warning signs:** Manual test passes in desktop Chrome; manual test passes on iPhone Safari *only after the second tap in a session*; a support report of "nothing happens" on first-time users on iPhone.

### Pitfall 2: FedCM is a red herring for this specific feature, but the phase description names it — don't over-invest
**What goes wrong:** Time gets spent building FedCM-specific fallback/opt-out code (`use_fedcm_for_prompt`, `fedcm`/`fedcm_auto` handling in `google_identity_services_web`) because the phase description explicitly flags "FedCM incompatibility," when in fact FedCM governs the *identity* (`authenticate()`/One Tap/`renderButton()`) flow, not the OAuth2 *scope authorization* token-client popup this feature actually uses.
**Why it happens:** Google's own docs and the broader ecosystem conflate "Google Identity Services" (the umbrella SDK, used for both flows) with "FedCM" (a subset used specifically for federated *identity*). Safari's total lack of FedCM support is real and well-documented (Apple has stated no FedCM implementation is planned, favoring passkeys instead) [CITED: multiple cross-referenced sources], but it does not block `authorizeScopes()`'s popup-based OAuth2 token flow, which is a separate, older, still-popup-based mechanism.
**How to avoid:** Confirm during Task 1 of planning that `CalendarService` still never calls `authenticate()`. If a future requirement needs to *identify* the signed-in user (not just get Calendar write access), that would be the point to revisit FedCM — not for this phase's CAL-06/CAL-07 scope.
**Warning signs:** Any task in the plan that mentions `use_fedcm_for_prompt`, `renderButton()`, or `authenticationEvents` — these belong to the identity flow this feature does not use.

### Pitfall 3: Cross-Origin-Opener-Policy (COOP) headers can silently break the popup↔opener handshake once deployed
**What goes wrong:** The OAuth popup opens, the user completes consent, but the app never receives the result — the popup either hangs or the promise never resolves, because the hosting environment sent a restrictive `Cross-Origin-Opener-Policy: same-origin` header that blocks `window.postMessage`/`window.opener` access between the popup and the main app window.
**Why it happens:** This is a well-documented class of bug for Firebase-hosted (and other) apps using any popup-based Google OAuth flow — not unique to Firebase Auth specifically, but to the general popup-opener communication pattern GIS's token client also relies on. [CITED: multiple cross-referenced sources re: Firebase Hosting + `Cross-Origin-Opener-Policy` + Google auth popups]
**How to avoid:** No `firebase.json` exists yet in this repo (Firebase Hosting config is formally Phase 17's job — see Open Questions below on the phase-ordering gap). If the preliminary/staging deploy used to satisfy CAL-07's "real production domain" requirement ships any COOP header, verify it is `same-origin-allow-popups` (or absent) rather than the stricter `same-origin`. This is currently `[ASSUMED]` risk, not confirmed against this project's actual (not-yet-created) `firebase.json`.
**Warning signs:** The popup opens and the user can interact with it, but the app's `await authorizeScopes(...)` never resolves or resolves with an unexplained cancellation.

### Pitfall 4: `GoogleSignIn.instance.authorizationClient` (not scoped to a `GoogleSignInAccount`) has undocumented web behavior
**What goes wrong:** The existing `CalendarService` calls `authorizeScopes()` on the bare singleton (`GoogleSignIn.instance.authorizationClient`), not on a `GoogleSignInAccount`-scoped client obtained after `authenticate()`. The official `google_sign_in` API docs state that when obtained this way, "the request will not be limited to a specific user, and the behavior will depend on the platform and the current application state" — and web-specific behavior for this exact call pattern is not documented anywhere found during this research.
**Why it happens:** `google_sign_in`'s README example for `RequestScopes` shows `user.authorizationClient.authorizeScopes(scopes)` — i.e., scoped to an already-signed-in `user`, which implies a prior `authenticate()`/lightweight-authentication step. This project's pattern deliberately skips that step (by design, per CAL-02's lazy-init decision), and it is unverified whether the bare-singleton call still triggers Google's popup-based "account selection, sign-in, and consent" flow on web the same way `google.accounts.oauth2.requestAccessToken()` does when called directly from JS (which does not require a prior identity step, per Google's own token-model docs).
**How to avoid:** This is precisely why the phase's success criteria mandate real-browser and real-iPhone-Safari verification rather than treating this as a documentation-verified fact. If manual testing shows the bare-singleton `authorizeScopes()` call does *not* prompt for sign-in on web (e.g., it silently no-ops or throws expecting a prior `authenticate()`), the fallback is to add a minimal `authenticate()`/`renderButton()` step ahead of it — accepting the FedCM-adjacent code path only if forced to.
**Warning signs:** `authorizeScopes()` throws an unexpected exception on web, or resolves without ever showing a popup, on a browser with no prior Google session state.

### Pitfall 5: Phase ordering gap — CAL-07 requires a "deployed production domain" that formally doesn't exist until Phase 17
**What goes wrong:** CAL-07 (and success criteria 2–4) require testing against "the deployed production URL (not localhost)" of the Firebase Hosting domain. But `DEPLOY-01`/`DEPLOY-02` (creating `firebase.json` and running `firebase deploy` for the first time) are Phase 17 requirements, which formally comes *after* Phase 15 and Phase 16 in the roadmap (`Phase 17 depends on Phase 16 depends on Phase 15`). No `firebase.json`, `.firebaserc`, or Firebase project currently exists in this repo, and the Firebase CLI is not installed on this machine [VERIFIED: `find`/`command -v firebase` both returned nothing].
**Why it happens:** The roadmap sequences "hardening" (Phase 17) after the features that need to be tested against a live domain (Phase 15, 16) — a reasonable content order for planning docs, but not a reasonable *execution* order for a requirement that says "not localhost."
**How to avoid:** The planner must include a lightweight, **non-hardened** preliminary deployment step inside Phase 15 (e.g., `firebase init hosting` with a minimal config, or `firebase hosting:channel:deploy preview-cal` for a temporary preview channel URL) purely to obtain a real HTTPS domain to register in Google Cloud Console's "Authorized JavaScript origins" and to satisfy CAL-07's manual-verification requirement. Phase 17 can then formalize/harden the same `firebase.json` (rewrite rules, headers, `sqlite3.wasm` content-type from PERS-07, etc.) without re-doing the Calendar-specific OAuth origin registration. This should be flagged explicitly to the user/planner as a cross-phase dependency, not silently worked around.
**Warning signs:** Attempting to satisfy CAL-07 by testing only against `flutter run -d chrome`'s localhost dev server and calling it "production" verification — this would not actually prove anything about the Firebase Hosting domain's OAuth origin registration or COOP headers.

## Code Examples

### Existing scope-authorization pattern (verified working on Android, Phase 9)
```dart
// Source: lib/services/calendar_service.dart (this repo, lines 33-46)
await _ensureInitialized();

final GoogleSignInClientAuthorization authorization;
try {
  authorization = await GoogleSignIn.instance.authorizationClient
      .authorizeScopes([CalendarApi.calendarEventsScope]);
} on GoogleSignInException catch (e) {
  if (e.code == GoogleSignInExceptionCode.canceled) {
    throw Exception('Aanmelden geannuleerd');
  }
  rethrow;
}
```

### Documented `initialize()` signature (accepts clientId/serverClientId)
```dart
// Source: raw.githubusercontent.com/flutter/packages google_sign_in README (Setup > Initialization)
final GoogleSignIn signIn = GoogleSignIn.instance;
unawaited(
  signIn.initialize(clientId: clientId, serverClientId: serverClientId).then((_) {
    signIn.authenticationEvents
        .listen(_handleAuthenticationEvent)
        .onError(_handleAuthenticationError);
    signIn.attemptLightweightAuthentication();
  }),
);
```
Note: on web, the documented/primary mechanism for the client ID is the `<meta name="google-signin-client_id" ...>` tag in `web/index.html`, not the `clientId:` parameter — but the parameter is also accepted by `initialize()` across platforms per the unified README. The planner should decide (and the discuss-phase should confirm) whether to use the meta tag, the `initialize(clientId:)` parameter, or both — this was not resolved by documentation alone. `[ASSUMED — needs verification against actual google_sign_in_web 1.1.3 source or a real test]`

### Web client ID meta tag (documented mechanism)
```html
<!-- Source: google_sign_in_web README, Integration section -->
<meta name="google-signin-client_id" content="YOUR_WEB_OAUTH_CLIENT_ID.apps.googleusercontent.com">
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Google Sign-In JavaScript Platform Library (`gapi.auth2`) | Google Identity Services (GIS) SDK | `google_sign_in_web` 0.12.0 migration [CITED: pub.dev changelog] | The old library is deprecated; `google_sign_in_web` already made this switch, so the project inherits GIS by default via 1.1.3 |
| `GoogleSignIn.signIn()` (pre-7.0 combined auth) | Separate `authenticate()` (identity) vs `authorizationClient.authorizeScopes()` (authorization) | `google_sign_in` 7.0.0 [VERIFIED: pubspec.lock — already on 7.2.0] | This project already reflects the current API; no migration needed for this phase |
| Google Sign-In identity flow without FedCM | FedCM-based sign-in (mandatory Aug 2025 per Google's platform library deprecation notice) | `google_sign_in_web` 0.12.1 enabled FedCM opt-in; broader Google Sign-In JS library made FedCM mandatory Aug 2025 [CITED: pub.dev changelog + WebSearch cross-reference] | Only relevant to the `authenticate()`/`renderButton()` flow, which `CalendarService` does not use (see Pitfall 2) |

**Deprecated/outdated:**
- `gapi.auth2` / legacy Google Sign-In JS library: fully superseded by GIS; not used anywhere in this codebase already.
- `GoogleSignIn.instance.signIn()` (pre-7.x combined call): does not exist in the 7.2.0 API surface already in use.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `GoogleSignIn.instance.authorizationClient.authorizeScopes()` called on the bare singleton (no prior `authenticate()`) triggers a full account-selection + consent popup on web, the same way it does on Android | Summary, Pitfall 4 | High — if false, the entire "no code change to the sign-in flow" recommendation collapses and a `renderButton()`/`authenticate()` step must be added, changing UI and pulling in FedCM-adjacent code |
| A2 | Moving `GoogleSignIn.instance.initialize()` to eager app-startup (web-only) fully resolves the Safari first-tap popup-block issue, without introducing a different async gap | Pattern 2, Pitfall 1 | Medium — if some other async work still intervenes (e.g., Riverpod provider resolution before the tap handler fires), the popup could still be blocked; must be verified on real Safari, not assumed |
| A3 | The Web OAuth client ID should be delivered via the `<meta name="google-signin-client_id">` tag (rather than or in addition to `initialize(clientId:)`) — exact precedence/interaction between the two on `google_sign_in_web` 1.1.3 was not confirmed from source | Code Examples | Low-Medium — wrong mechanism means the OAuth popup fails with a "missing client_id" style error; easy to detect and fix during Task 1 testing, but wastes a planning cycle if unaddressed upfront |
| A4 | A restrictive default `Cross-Origin-Opener-Policy` header from a to-be-created Firebase Hosting config could block the popup↔opener handshake for this app's non-Firebase-Auth OAuth flow, the same way it's documented to for Firebase Auth's popup flow | Pitfall 3 | Medium — if this project's eventual `firebase.json` (Phase 17, or the preliminary deploy this phase needs) omits any COOP header or uses Firebase's actual default (not independently confirmed), the risk may not materialize at all; needs to be checked once a real deploy exists |
| A5 | Google Calendar API v3 (`www.googleapis.com/calendar/v3/...`) is CORS-enabled for authenticated Bearer-token requests initiated directly from a browser (no proxy needed) | Standard Stack, Architecture Diagram | Low — Google's own official JS quickstart demonstrates this pattern directly, but was not independently re-verified with a live CORS preflight test against this project's specific origin |

## Open Questions

1. **Does the existing scope-only (`authorizeScopes()` without `authenticate()`) pattern actually work on web at all, unmodified?**
   - What we know: It works on Android (shipped in Phase 9). Official docs describe the "expected" web flow as `authenticate()`/`renderButton()` + `authorizationClient.authorizeScopes()` on the resulting `GoogleSignInAccount`, not the bare singleton.
   - What's unclear: Whether the bare-singleton call on web independently triggers Google's OAuth2 token-client popup (which handles account selection/consent by itself, per Google's JS token-model docs) or requires a prior identity step that this codebase currently skips.
   - Recommendation: Task 1 of the plan should be a minimal spike — get the existing `CalendarService` running under `flutter run -d chrome` with a real Web OAuth client ID configured, and observe actual behavior, before designing any larger platform-branching structure around an assumption that may be wrong.

2. **Where exactly should the preliminary "real domain" deployment for CAL-07 live, and does it conflict with Phase 17's later `firebase.json` work?**
   - What we know: No Firebase project/config exists yet in this repo; Firebase CLI isn't installed on this dev machine; DEPLOY-01/02 are formally Phase 17.
   - What's unclear: Whether the user wants a throwaway Firebase preview channel, a real (even if unpolished) `firebase.json` created early and then refined in Phase 17, or something else (e.g., a temporary ngrok/Cloudflare tunnel over `flutter run`'s dev server, which would NOT satisfy "not localhost" in spirit even if technically a public HTTPS URL).
   - Recommendation: Surface this explicitly to the user during `/gsd:discuss-phase` rather than silently deciding — this is a genuine scope/sequencing decision, not a pure technical unknown.

3. **Should the same Web OAuth client ID cover both local dev (`localhost:PORT`) and the production Firebase Hosting domain, or should they be separate?**
   - What we know: Google Cloud Console's "Authorized JavaScript origins" is an exact-match allowlist and supports multiple origins per client ID (this is exactly what the `google_sign_in_web` README's `localhost` + `localhost:7357` example demonstrates).
   - What's unclear: Whether the user's Google Cloud project (already used for the Android OAuth client in Phase 9) has any organizational policy or preference for separating dev/prod credentials.
   - Recommendation: Default to one Web client ID with both origins registered (simpler, matches documented pattern) unless the user's existing Google Cloud Console setup suggests otherwise — confirm in discuss-phase.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Firebase CLI (`firebase`) | Preliminary/production deploy needed to satisfy CAL-07 | ✗ | — | `npm install -g firebase-tools` (verify package on npmjs.com first) or use `dart pub global activate` alternatives; no viable way to satisfy CAL-07 without some form of real HTTPS deploy — this is a blocking gap for that specific criterion |
| Google Cloud Console access (existing project from Phase 9) | Creating the Web OAuth client ID | Not verifiable from this environment (requires user's browser/account session) | — | None — this is inherently a manual, human-driven step; plan should include a `checkpoint:human-verify` or equivalent task |
| Real iPhone running Safari | Success criterion 4 (mandatory manual verification) | Not verifiable from this environment | — | None — this is explicitly called out in the phase description as unavoidable manual work |
| Chrome/desktop browser for initial dev-loop testing | Task-level iteration before real-device testing | Assumed available (standard dev machine) | — | — |

**Missing dependencies with no fallback:**
- Firebase CLI / an actual deployed HTTPS domain — blocks CAL-07 criterion 2-4 until resolved (see Open Question 2 and Pitfall 5).
- Real iPhone + Safari — blocks success criterion 4; inherently manual, no automated substitute exists (BrowserStack/Sauce Labs-style real-device cloud testing is a possible paid fallback if no physical device is available, but was not requested and is out of scope to assume).

**Missing dependencies with fallback:**
- None identified — both gaps above are hard blockers requiring explicit human action, not technical alternatives.

## Sources

### Primary (HIGH confidence)
- `pubspec.lock` (this repo) — confirmed exact resolved versions: `google_sign_in` 7.2.0, `google_sign_in_web` 1.1.3, `googleapis` 16.0.0, `extension_google_sign_in_as_googleapis_auth` 3.0.0 [VERIFIED: local file read]
- `lib/services/calendar_service.dart`, `lib/features/detail/ride_detail_screen.dart`, `lib/features/availability/availability_screen.dart`, `lib/core/platform_info.dart` (this repo) — actual existing implementation and established patterns [VERIFIED: local file read]
- `.planning/phases/13-geolocation-manual-fallback/13-01-PLAN.md` (this repo) — precedent for `isWebPlatform` pattern [VERIFIED: local file read]
- https://raw.githubusercontent.com/flutter/packages/main/packages/google_sign_in/google_sign_in/README.md — `initialize()`, `authenticate()`, `authorizationClient.authorizeScopes()` API and platform-conditional patterns [CITED]
- https://raw.githubusercontent.com/flutter/packages/main/packages/google_sign_in/google_sign_in_web/README.md — web client ID meta-tag setup, `supportsAuthentication` = false, FedCM/renderButton notes [CITED]
- https://raw.githubusercontent.com/flutter/packages/main/packages/google_sign_in/google_sign_in_web/CHANGELOG.md and .../google_sign_in/CHANGELOG.md — version history, FedCM opt-in (0.12.1), 7.0.0 breaking changes [CITED]
- https://developers.google.com/workspace/calendar/api/quickstart/js — official pattern for Bearer-token `fetch()` calls to Calendar API v3 from the browser, confirming CORS support [CITED]

### Secondary (MEDIUM confidence)
- Cross-referenced WebSearch results (2+ sources agreeing) on: Safari FedCM non-support ("no FedCM implementation planned... focusing on passkeys"), Safari synchronous-user-gesture popup requirement, and Firebase Hosting + COOP header interference with OAuth popups [multiple WebSearch queries, see below]
- https://github.com/flutter/flutter/issues/54768 — Safari/Firefox popup-blocker-on-first-interaction report for `google_sign_in_web` [CITED, unresolved/status unclear]
- https://github.com/google/google-api-javascript-client/issues/925 — Safari/iOS blocking Google Drive Picker auth popup, same underlying popup-blocking class of issue [CITED]
- https://github.com/flutter/flutter/issues/154218 — post-upgrade `popup_closed` error report on `google_sign_in` 6.2.1 web [CITED, illustrative of general fragility, not directly 7.x-confirmed]

### Tertiary (LOW confidence)
- General claim that a to-be-created `firebase.json` might send a COOP header that breaks the popup handshake — extrapolated from Firebase Auth-specific reports, not confirmed against this project's (nonexistent) hosting config [flagged in Assumptions Log as A4]
- Whether `authorizeScopes()` on the bare `GoogleSignIn.instance` singleton works unmodified on web — no direct source found either confirming or denying this; flagged as A1 and Open Question 1, the single most important thing for the planner to de-risk early (e.g., via a Task 1 spike)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages, all versions confirmed directly from `pubspec.lock`
- Architecture: MEDIUM — the scope-only pattern's web viability (A1) is the load-bearing unknown; everything else (CORS, client ID mechanism, project structure) is well-documented
- Pitfalls: MEDIUM-HIGH — Safari popup-gesture timing (Pitfall 1) and the FedCM-is-a-red-herring finding (Pitfall 2) are well-supported by cross-referenced sources; COOP (Pitfall 3) and the bare-singleton authorizeScopes behavior (Pitfall 4) are honestly flagged as unverified

**Research date:** 2026-07-12
**Valid until:** ~14 days (fast-moving area — Google's FedCM mandate timeline and `google_sign_in_web` are both under active change; re-verify package versions before planning if this research is consumed more than 2 weeks after this date)
