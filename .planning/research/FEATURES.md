# Feature Research

**Domain:** Optional user accounts + cloud sync + account-backed feedback, added to an existing shipped offline-first consumer mobile/web app (RideWindow, Flutter, Android + Web PWA)
**Researched:** 2026-07-25
**Confidence:** HIGH for GDPR/Play Store compliance and Firestore sync mechanics (official docs/policy pages verified); MEDIUM for UX-pattern claims (verified against multiple credible sources, no single authoritative "spec" exists for consumer account UX); MEDIUM for the second-device migration recommendation (synthesized from real-world patterns, not a documented standard).

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Optional sign-in entry point in Profile ("Sign in with Google to sync") | App already works fully offline for existing users; a first-run gate would break a working product for no functional reason | LOW | Reuse existing `google_sign_in` 7.2.0 instance already wired for Calendar — do not force a second, separate sign-in prompt |
| App remains fully usable, forever, without signing in | Core value (score + slots) has never required an account; regressing this breaks the existing Play Store product | LOW | No feature should be hidden behind auth except sync itself and (optionally) reply-enabled feedback |
| Signed-in state UI: avatar + display name/email + explicit "Sign out" row in Profile | Universal pattern (every app with optional Google accounts: Duolingo, Todoist, Keep, YouTube) | LOW | Mirror the existing "Google Calendar: Connected / Disconnect" row pattern already shipped in Profile (BACKLOG #36) — same visual language, new row |
| Automatic, silent background sync once signed in (no mandatory "Sync now" button) | Consumer apps (Notion, Todoist, Google Keep) sync silently; a manual-only sync model reads as broken/dated | LOW–MEDIUM | Firestore snapshot listeners + offline persistence give this close to free once local data model is wired to Firestore |
| Some passive "synced" signal (e.g. small "Last synced HH:MM" or checkmark) | Users need reassurance data isn't lost, but do not need a prominent/animated indicator for single-user settings data | LOW | Can reuse the existing "Last updated" stale-data UI pattern already built for weather refresh in v2.0 |
| App keeps working fully offline after sign-in, with local writes applied immediately (optimistic) | Users already rely on offline use (v1.0 Android, no connectivity assumptions); regressing this is a functional break, not just UX polish | LOW–MEDIUM | Firestore's offline queue + local Drift cache both already exist; requires a defined "local write now, sync when online" flow |
| Signing out does NOT delete local device data | Every mainstream app leaves local cache/state intact on sign-out (Spotify, Gmail, Notion); silently wiping settings on sign-out would be a serious regression from today's always-local behaviour | LOW | Local Drift data + settings stay exactly as before; only the sync/account link is removed. App falls back to today's fully-offline mode. |
| In-app or web account-deletion path | **Google Play policy, hard requirement**, enforced since 2024-04-15: any app that lets a user create an in-app account must let them request deletion, in-app or via a linked web page usable even after uninstall | LOW–MEDIUM | Existing hosted privacy-policy page (GitHub Pages) is the natural home for a "Delete my account" web form; an in-app "Delete account" action is stronger UX but the web fallback alone is policy-compliant |
| Documented, honorable data-export/portability path (GDPR Art. 20) | EU users' personal data (location-derived + availability) is now processed server-side, making the developer a data controller; Article 20 gives users a right to a machine-readable copy of data they provided | LOW (process) / MEDIUM (in-app button) | At this scale, a documented manual process (email the data as JSON within one month of request) is legally sufficient; does not require an in-app button on day one, though one is cheap to add (see Differentiators) |
| Non-silent, explicit choice when a signed-in account already has cloud data that conflicts with local device data | Silent overwrite in either direction risks real data loss the user never agreed to — this is the exact "second device" scenario the milestone flags as open | MEDIUM | See dedicated recommendation below. Table stakes = the user is asked once, not that a sophisticated merge algorithm exists |
| Account-scoped provider/state reset on account switch (sign out → sign in as a different Google account) | Without this, a device could show the previous account's cached availability/tolerances under the new account's identity — a data-leak-adjacent bug, not just a UX rough edge | LOW–MEDIUM | Riverpod providers holding profile/availability/tolerances must be invalidated on auth-state change, not only on cold app restart |
| Feedback still submittable in some form without a network connection at the moment of tapping "Send" | Feedback is often filed right after a ride, which may be outdoors with poor signal | LOW | Queue the Firestore write like any other offline-tolerant write; do not require live connectivity to compose feedback |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Feedback automatically attaches the exact scoring context (score, temp/rain/wind inputs, slot time) and the user's own current tolerance-slider values | This is the actual point of adding accounts, per the milestone rationale: calibrate the score against a specific user's own tolerances, not anonymous text. No generic bug-report SDK captures this — it's domain-specific plumbing only RideWindow can do | LOW–MEDIUM | Pure plumbing: the score/weather objects and tolerance values already exist in app state at the moment "Send feedback" is tapped; just attach them to the Firestore doc instead of discarding them |
| "Your feedback" history screen — a flat list of the user's own past submissions, each showing what was captured and any developer reply | Gives signed-in users a sense the feedback went somewhere, without building a full support-ticket system | MEDIUM | Simple Firestore query filtered by `uid`; a single optional `developerReply` text field per doc is enough for a lightweight two-way thread |
| In-app "Export my data" (JSON download) | Satisfies GDPR Art. 20 in a genuinely self-service way and doubles as a real backup mechanism independent of cloud sync — directly resolves BACKLOG #4 ("Settings export/import") as a side effect | LOW–MEDIUM | Reuse whatever serialization already backs the Firestore sync payload; write it to a downloadable file (web) / share sheet (Android) |
| Anonymous feedback submission for users who choose not to sign in (light nudge, not a hard gate) | Preserves feedback volume — the actual goal is calibration data, not exclusivity — while still steering toward sign-in for a reply channel | LOW | "Sign in to include your settings & get a reply" primary CTA + "Send anonymously" secondary action, both writing to the same Firestore collection |
| Granular field-level sync writes for the availability grid (per hour-cell) instead of whole-blob overwrite | Makes Firestore's default last-write-wins conflict resolution behave sanely across two devices — only truly simultaneous edits to the *same* hour cell can conflict, and losing that edge case gracefully is fine | MEDIUM | Requires modelling availability as a map/document with per-cell (or per-day) fields, not a single serialized blob field |
| Reusing the existing Calendar OAuth session for sign-in (single consent, not two separate Google prompts) | Users who already connected Calendar (BACKLOG #36) get sign-in "for free" — no redundant permission dialog | LOW–MEDIUM | Feed the same `GoogleSignIn` ID token into `FirebaseAuth.signInWithCredential`; verify scope/consent overlap doesn't trigger a second consent screen |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|------------------|-------------|
| Gating the app (or any core screen) behind sign-in at first run | "Feels more like a real product with accounts" | Directly breaks the constraint that the app must keep working fully offline; punishes existing installed-base users on update for no functional gain | Soft entry point in Profile only, exactly as scoped |
| Real-time collaborative sync UI (presence indicators, live cursors, "X is editing") | Looks impressive, borrowed from docs/collab tools | No collaborative use case exists here — availability and tolerances are single-user data; this is pure over-engineering for phase 1–2 | Silent background sync + a passive last-synced label |
| Custom CRDT / operational-transform merge engine for conflict resolution | Seems like the "correct" solution to sync conflicts | Wildly disproportionate for a small, low-concurrency, single-user settings dataset; Firestore's built-in last-write-wins at the field level, combined with granular writes, is sufficient | Field-level Firestore writes + last-write-wins; explicit one-time chooser only for the true first-cloud-data-conflict case |
| Silent automatic "union merge" of two devices' availability grids | Sounds safe — "just combine both schedules" | Actively wrong for this data shape: availability is exclusionary (blocked vs open), not additive; unioning two different weekly schedules produces a schedule that is more "available" than either device's user actually intended | Binary "keep this device" vs "keep synced account data" chooser (see recommendation) |
| Secondary/backup auth method (email+password, magic link, Apple Sign-In) added "just in case Google fails" | Feels like a safety net | Directly contradicts the already-accepted decision to keep auth to Google-only for the shortest path; each method adds password-reset flows, email verification, and GDPR-relevant credential storage the project explicitly avoided | Accept the limitation; local data survives regardless of auth-provider issues (see below), which is the actual safety net |
| Custom account-recovery flow (security questions, backup codes, support-driven identity verification) | Feels necessary for "what if the user loses access" | Google/Firebase already owns identity recovery for its own accounts; a bespoke parallel recovery flow duplicates effort and is a weaker security surface than Google's own | Document in the privacy policy that account recovery follows Google's own account-recovery process; local data is never destroyed by sign-out or lost account access |
| Third-party bug-reporting/feedback SDK (Instabug, Shake) with screenshot annotation, session replay, console-log capture | Looks like the "professional" feedback solution, minimal code to add | Built for teams triaging many bug reports from a large user base with a support process; adds a paid vendor + a new third-party data-processing relationship right after tightening the privacy story for GDPR; captures generic device/session data instead of the domain-specific score/tolerance context that actually matters here | A single Firestore collection with the domain-specific context (score, weather inputs, tolerances) attached — smaller, cheaper, and a better fit for the stated calibration goal |
| Full support-ticket system (statuses: open/in-progress/resolved, assignment, SLAs) | Feels like "proper" customer support | Enormous overkill for a solo developer and a beta cohort of a few dozen testers | Flat "your submissions" list + an optional developer-reply field per submission |
| Full self-service GDPR/consent-management portal (rectification workflows, granular consent toggles per processing purpose, audit logs) | Sounds like "doing GDPR properly" | Disproportionate for the actual scale and risk profile (a hobby app, EU users numbering in the dozens/hundreds); the real legal obligations at this scale are: a correct privacy policy, honor deletion requests, honor export requests | Privacy policy rewrite (already flagged as release-blocking) + account-deletion path + documented export process — covers the real obligations |

## Second-Device Migration Conflict — Recommendation

This directly answers the milestone's open design question: *"a second login on another device that already holds local data — 'local wins' must not blindly overwrite the cloud there."*

**The deciding signal is not "which device number is this," it's "does the cloud account already hold data."**

- **Case A — First sign-in ever, cloud account is empty.** Local device data becomes the source of truth silently, no prompt. This is the already-accepted "local wins" decision, and it is correct here because there is nothing in the cloud to lose.
- **Case B — Sign-in where the cloud account already holds non-empty data** (this is what "second device" actually means in practice — it doesn't matter whether it's literally a second physical device, a reinstall, or the web PWA signing into an account that Android already synced). Blind "local wins" here would silently overwrite Device A's already-synced cloud data with whatever Device B happened to have locally — a real, silent data-loss bug. **Show a single one-time binary chooser: "Keep the data from this device" vs. "Keep your synced account data."** Default the recommended choice to "keep account data" (it's presumably already the more complete/authoritative record), but let the user pick local if they know better.

**Why a binary chooser and not a field-level merge UI:** RideWindow's synced data (weekly availability grid, three tolerance sliders, ride-length preference, notification toggles) is a small settings blob, not a document with independently meaningful sections a user would want to reason about piece-by-piece. A field-level merge screen ("keep availability from device A, keep tolerances from device B") is the kind of complexity that belongs in a document-editing app, not a settings sync. It is real but avoidable engineering and design cost for a case that, once handled by the binary chooser, only recurs on the rare occasion someone actually signs into a second surface with meaningfully different local data.

**Why not silent automatic merge:** see the "silent union merge" anti-feature above — for this specific exclusionary (block/unblock) data shape, an automatic merge produces a schedule the user did not actually choose, which is a worse failure mode than asking once.

**Detection rule for implementation:** on sign-in, before writing anything, read the user's Firestore profile document. If it does not exist (or is a known "empty/default" shape), this is Case A — write local data, no prompt. If it exists and is non-default, this is Case B — show the chooser before writing anything. This single existence check correctly generalizes across "second device," "reinstall after signing out," and "return after a long absence" without needing per-device tracking.

**Complexity:** MEDIUM. Requires: (1) a defined "empty/default" shape for the cloud profile document so Case A vs B can be detected reliably, (2) a one-time modal/dialog UI component, (3) care that the chooser is shown exactly once per genuine conflict, not on every subsequent app open.

## GDPR & Play Store Compliance Callout

Two obligations are genuinely non-negotiable once accounts + server-side personal data ship, both verified against current policy sources:

1. **Google Play account-deletion requirement** (enforced since 2024-04-15): any app allowing in-app account creation must provide account deletion, in-app and/or via a linked web page usable without reinstalling. Non-compliance risks store removal. This is a release blocker for this milestone, not a nice-to-have.
2. **GDPR Article 20 (data portability)**: EU users have a right to a machine-readable export of data they provided (JSON/CSV), deliverable within one month of request. At this scale a documented manual process is legally sufficient; an in-app export button is a cheap, strong differentiator that also resolves BACKLOG #4.

Both obligations are satisfied by roughly the same feature: a Firestore-doc delete (+ `FirebaseAuth` user delete) for deletion, and a JSON serialization of that same document for export. Building them together is more efficient than treating them as separate work.

## Feature Dependencies

```
Sign-in (Google, via Firebase Auth)
    └──requires──> Existing google_sign_in 7.2.0 integration (already shipped for Calendar)
    └──enables───> Cloud sync (profile + availability)
    └──enables───> Account-backed feedback (uid-scoped submissions, reply channel)
    └──enables───> Account deletion / data export (needs an authenticated identity to scope the delete/export to)

Cloud sync (profile + availability)
    └──requires──> Sign-in
    └──requires──> Firestore data model for availability (per-cell/day fields, not a single blob) — needed for sane conflict granularity
    └──enables───> Second-device conflict chooser (only meaningful once sync exists)
    └──conflicts-with──> Naive "local wins" reused unconditionally on every sign-in (must be gated by the empty/non-empty cloud-document check)

Second-device conflict chooser
    └──requires──> Cloud sync
    └──requires──> A defined "empty/default" cloud profile shape (to detect Case A vs Case B)

Account-backed feedback
    └──requires──> Sign-in (for the account-scoped, reply-enabled path)
    └──enhances──> Existing scoring/tolerance state (Profile sliders, Ride Detail score breakdown) — attaches automatically, no new domain logic
    └──replaces──> BACKLOG #33's mailto: link (kept only as an anonymous fallback for signed-out users)

Account deletion + data export
    └──requires──> Sign-in
    └──requires──> A single Firestore document shape that both actions can operate on (delete it / serialize it)

Sign-out
    └──must NOT trigger──> Local data deletion (local Drift storage is untouched; only the account link is removed)
```

### Dependency Notes

- **Cloud sync requires a Firestore data model for availability that is NOT a single serialized blob field:** the whole second-device conflict story, and the practical usefulness of Firestore's default last-write-wins, depend on the availability grid being represented as individually-addressable fields (per hour cell or per day), not one opaque JSON string field. This is a prerequisite decision, not an afterthought — it belongs in an early sync-phase task.
- **Second-device conflict chooser requires cloud sync to exist first**, obviously, but more specifically requires the "is the cloud profile document empty or already populated" check to be reliable — this needs a defined default/empty shape decided during data-model design, not left implicit.
- **Account-backed feedback enhances, rather than requires new development on, existing scoring/tolerance state** — the score breakdown (temp/rain/wind bars) and the tolerance sliders already exist as live app state at the point a user would tap "Send feedback." This keeps feedback's true implementation cost low; the cost is in the Firestore plumbing and the optional history screen, not in sourcing the context data.
- **Sign-out conflicts with (must prevent) local data deletion:** this is worth stating explicitly as a non-goal because "clean sign-out" intuitively suggests clearing state, which is the wrong behaviour for an app whose whole pre-accounts identity was "everything lives safely on your device."

## MVP Definition

### Launch With (v3.0 phases 1–2, per milestone scope)

- [ ] Soft "Sign in with Google" entry point in Profile (not a first-run gate) — essential to preserve the existing offline-first product for current users
- [ ] Signed-in state UI (avatar, name/email, sign out) reusing the existing Calendar-connection row pattern — essential, near-zero new design cost
- [ ] Automatic silent sync of profile + availability to Firestore, offline-tolerant, with a passive last-synced indicator — this is the entire point of phase 1
- [ ] Empty-cloud-account detection + silent local-wins write (Case A) — essential, already an accepted decision
- [ ] Non-empty-cloud-account detection + one-time binary chooser (Case B) — essential; this is what makes "local wins" safe rather than a data-loss bug
- [ ] Sign-out that preserves all local data and simply drops the sync link — essential regression-prevention
- [ ] Account deletion path (in-app and/or linked web page) — essential, Google Play policy compliance, hard release blocker
- [ ] Account-backed feedback: signed-in submissions carry score/weather/tolerance context automatically, replacing the mailto: flow for signed-in users — this is phase 2's whole purpose
- [ ] Anonymous feedback fallback for signed-out users (keeps today's mailto:-equivalent value without forcing sign-in) — essential to not regress feedback volume for the not-signed-in majority at launch

### Add After Validation (v3.x, post phases 1–2)

- [ ] In-app "Export my data" (JSON) — cheap, high-value GDPR + backup differentiator, not release-blocking if a documented manual export process exists
- [ ] "Your feedback" history screen with developer-reply field — meaningful once there's enough submitted feedback to make a history worth showing
- [ ] Granular field-level availability writes if the initial data model shipped coarser than ideal — revisit once real sync conflicts (or their absence) are observed in practice

### Future Consideration (deferred milestone phases 3–5, per v3.0-ACCOUNTS.md)

- [ ] Friends / shared availability, ride invites, server-side push notifications — explicitly deferred; need a real user base to be worth building, per the milestone's own risk callout
- [ ] Any collaborative/multi-user conflict UI — no use case until phase 3+ introduces genuinely shared data

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Soft sign-in entry point + signed-in state UI | HIGH | LOW | P1 |
| Automatic silent cloud sync (profile + availability) | HIGH | MEDIUM | P1 |
| Empty-account silent local-wins migration | HIGH | LOW | P1 |
| Non-empty-account conflict chooser | HIGH | MEDIUM | P1 |
| Sign-out preserving local data | HIGH | LOW | P1 |
| Account deletion (in-app or linked web) | HIGH (compliance) | LOW–MEDIUM | P1 |
| Account-backed feedback with automatic score/tolerance context | HIGH | LOW–MEDIUM | P1 |
| Anonymous feedback fallback for signed-out users | MEDIUM | LOW | P1 |
| In-app data export (JSON) | MEDIUM | LOW–MEDIUM | P2 |
| "Your feedback" history + developer reply | MEDIUM | MEDIUM | P2 |
| Granular per-cell availability sync fields | MEDIUM (mostly invisible to users, but avoids bad conflicts) | MEDIUM | P2 (should be decided at data-model time even if some polish ships later) |
| Third-party bug-reporting SDK | LOW (for this domain) | MEDIUM (new vendor) | Not planned |
| Secondary auth methods | LOW | HIGH | Not planned |
| Full support-ticket system | LOW (at this scale) | HIGH | Not planned |

**Priority key:**
- P1: Must have for v3.0 phases 1–2 launch
- P2: Should have, add once phase 1–2 is live and stable
- Not planned: anti-features, explicitly excluded

## Reference Apps for Account/Sync/Feedback UX Patterns

RideWindow has no direct competitor with an equivalent account+sync+feedback feature set, so the useful comparison is against apps that solved the same *kind* of problem (optional accounts on top of an already-working local app; personal-settings sync; lightweight feedback), not cycling-weather competitors.

| Pattern | Reference app(s) | Behaviour observed | Our approach |
|---------|-------------------|---------------------|--------------|
| Optional sign-in, soft entry point, app fully usable without it | Todoist, Duolingo (delays credential prompts until needed), Google Keep | Sign-in lives in a settings/profile area; core functionality never gated | Same — Profile-only entry point, no first-run gate |
| Silent background sync with a passive status indicator | Google Keep, Notion, Todoist | No "sync now" button required as primary path; small "synced"/"last edited" signal only | Same — reuse existing "last updated" stale-data pattern from v2.0 weather refresh |
| Explicit conflict handling on account data that already exists elsewhere | Chrome Sync (reconciles/merges browser data across devices when signing in with existing data on both sides, rather than blind overwrite) | Chrome does not silently let a freshly-signed-in device destroy existing synced data; it reconciles | Directionally same principle, but implemented as a simple one-time binary chooser rather than Chrome's much more complex per-item reconciliation (disproportionate for RideWindow's small settings dataset) |
| Feedback with automatically attached technical context | Instabug, Shake (Shakebug) | Auto-capture device/OS/app-version/logs on every report, no manual typing required | Same principle, applied to domain-specific context (score, weather inputs, tolerances) instead of generic device/session data — a better fit for a scoring-calibration goal than a generic bug-report SDK |

## Sources

- [Understanding Google Play's app account deletion requirements — Play Console Help (official)](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en) — HIGH confidence, official policy source
- [Google Play Store Policy Changes 2024 — Bugfender](https://bugfender.com/blog/google-play-store-policy-changes-2024/) — MEDIUM confidence, corroborates enforcement timeline
- [Right to Data Portability under GDPR Article 20 — Clarip](https://www.clarip.com/data-privacy/gdpr-data-portability/) and [GDPR Local](https://gdprlocal.com/right-to-data-portability/) — MEDIUM confidence, consistent across multiple legal-reference sources on format/scope/deadline requirements
- [Access data offline — Firestore official docs (Firebase/Google)](https://firebase.google.com/docs/firestore/manage-data/enable-offline) — HIGH confidence, official documentation on offline persistence and last-write-wins conflict behaviour
- [Offline-first support — Flutter official docs](https://docs.flutter.dev/app-architecture/design-patterns/offline-first) — HIGH confidence, official Flutter architecture guidance, directly applicable given the project's stack
- [Instabug-Android — GitHub / official docs](https://github.com/Instabug/Instabug-Android) and [Shakebug](https://www.shakebug.com/) — MEDIUM confidence, vendor documentation used to characterize the "automatic context capture" pattern in feedback tooling (used here as an anti-feature comparison, not a recommendation to adopt)
- Chrome Sync merge/reconciliation behaviour — MEDIUM/LOW confidence, drawn from Google support community threads rather than an authoritative Chrome sync spec; used only to illustrate the "don't blindly overwrite existing synced data" principle, not as an implementation model
- Existing project documents: `.planning/PROJECT.md`, `.planning/milestones/v3.0-ACCOUNTS.md`, `.planning/BACKLOG.md` (items #4, #12, #33, #36, #41, #43, #47) — used to ground recommendations in already-shipped patterns (e.g., the Calendar-connection row in Profile) and already-accepted decisions (Google-only auth, local-wins-on-empty-account)

---
*Feature research for: Optional accounts, cloud sync, and account-backed feedback in RideWindow (v3.0 milestone, phases 1–2)*
*Researched: 2026-07-25*
