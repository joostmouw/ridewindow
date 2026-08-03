# Requirements — Milestone v3.0 Accounts & Sociaal

**Defined:** 2026-07-25
**Scope:** Phases 1–2 of `.planning/milestones/v3.0-ACCOUNTS.md` — accounts, cloud sync, account-backed feedback. Phases 3–5 (friends, shared availability, ride invites, server-side push) are deferred.
**Research:** `.planning/research/SUMMARY.md`
**Stack:** Supabase (Auth + Postgres). Revised from Firebase on 2026-07-25, before Phase 18 began — see `SUMMARY.md` §Executive Summary for the rationale and `.planning/research/archive-firebase/` for the superseded version. Firebase Hosting is unchanged and still serves the PWA.

**Guiding principle:** accounts are strictly additive. A user who never signs in must notice no change whatsoever. Nothing that works today may start requiring an account.

---

## v3.0 Requirements

### Preconditions (PRE)

Release-blocking groundwork. None of this is app code, and two items are effectively irreversible once chosen.

- [x] **PRE-01**: The three broken constraints in `CLAUDE.md` and `PROJECT.md` ("No backend", "Budget: no ongoing infra costs", "Privacy: data never leaves the device") are consciously rewritten — the budget constraint restated as an explicit spend ceiling rather than an assumed zero
- [x] **PRE-02**: The Supabase project is created in an EU region — Frankfurt, Ireland, Paris or Stockholm, *not* London or Zurich, which sit outside the EU — and the region is verified in the Supabase dashboard rather than assumed from the signup flow (the region is chosen once at creation)
- [x] **PRE-03**: Supabase's Data Processing Agreement is in effect for the project, and **both** sub-processors are named in the privacy policy — Supabase (auth, database) and Google (Firebase Hosting, Calendar). This milestone adds a second processor relationship, it does not replace the existing one
- [x] **PRE-04**: Both SHA-1 fingerprints (local release keystore *and* the Play App Signing key, taken from Play Console → App integrity) are registered on the Android OAuth client in Cloud Console, the deployed PWA origin is registered on the web OAuth client, and the **web** client ID is registered in the Supabase dashboard's Google provider settings — Supabase's auth server verifies the ID token against it
- [x] **PRE-05**: The privacy policy at the published URL is rewritten to cover server-side storage of location data and calendar-derived availability, the data categories now collected, retention, and user rights
- [x] **PRE-06**: The Play Store Data Safety declaration is updated to reflect account creation and server-side data storage, and is live at or before the release that ships accounts
- [x] **PRE-07**: The distinction between the Auth user cap (none in practice — basic scopes) and the Calendar-connect cap (100 unique lifetime grants of the unverified `calendar.events` sensitive scope) is documented explicitly, so the two are never conflated during support
- [x] **PRE-08**: On the free tier (D-01) there is no spend and therefore nothing to bill an alert on, so the requirement is reworded from a billing alert to the pause tripwire that actually protects the project: a keep-warm job exists and runs on a schedule that stays inside the 7-day inactivity window, Supabase's pause-warning email goes to an address that is actually monitored, and a "sync stopped working" runbook entry exists in `docs/ACCOUNTS-OPERATIONS.md` naming project pausing as the first thing to check. *(Reworded 2026-07-25 — the original text asked for a billing alert, which cannot be satisfied honestly on a plan with nothing to bill; the underlying intent, a tripwire rather than a spend cap, is unchanged.)*
- [x] **PRE-09**: A data retention and export answer is documented — how a GDPR Article 20 export request would actually be fulfilled manually, and what happens to data after account deletion

### Authentication (AUTH)

- [ ] **AUTH-01**: User can sign in with their Google account from the Profile screen, presented as an optional entry point rather than a gate
- [ ] **AUTH-02**: User sees their signed-in state (account identity plus a sign-out action) in Profile, using the same visual pattern as the existing Google Calendar connection row
- [ ] **AUTH-03**: User can sign out, and all data on the device remains exactly as it was — signing out never deletes local data
- [ ] **AUTH-04**: User's signed-in state survives an app restart on both Android and web
- [ ] **AUTH-05**: The app has exactly one Google Sign-In initialization path shared between authentication and the existing Calendar integration, so the two cannot race each other on cold start
- [ ] **AUTH-06**: Sign-in works on web, where `google_sign_in` cannot use `authenticate()` at all and Google's own rendered sign-in button is mandatory — a different flow from the Calendar integration's authorization-only path, and new surface with no existing analog in this codebase
- [ ] **AUTH-07**: When the signed-in account differs from the account that authorized Calendar access, the user is warned rather than having calendar events silently written under a different identity
- [ ] **AUTH-08**: When a different Google account signs in on a device, no data from the previous account remains visible
- [x] **AUTH-09**: User can delete their account, and doing so removes their stored data on the server, not only their login (Google Play policy requirement, enforced since 2024-04-15)
- [ ] **AUTH-10**: Sign-in works from a real release build installed from the Play Store track, not only from a debug build

### Cloud sync (SYNC)

- [x] **SYNC-01**: A signed-in user's profile settings (tolerances, ride-length preferences, theme, locale, location override, notification toggles) are stored in the cloud
- [x] **SYNC-02**: A signed-in user's weekly availability pattern is stored in the cloud
- [x] **SYNC-03**: A signed-in user's planned rides are stored in the cloud
- [ ] **SYNC-04**: A change made on one platform appears on the other after the app is opened or brought to the foreground
- [ ] **SYNC-05**: Changes made while offline are applied locally straight away and reach the cloud once a connection returns
- [ ] **SYNC-06**: User can see whether their data has been synced, and can tell when changes are still pending
- [ ] **SYNC-07**: The app opens and shows forecast and slots within the existing 2-second budget, without waiting on a network round-trip to the cloud
- [x] **SYNC-08**: One user cannot read or modify another user's data, verified by an automated test that asserts denial across two separate accounts, run against the deployed database's row-level security policies and not only against a local instance
- [x] **SYNC-09**: The forecast cache is not synced — it is derived data and stays local
- [x] **SYNC-10**: Calendar-imported blocked hours are not synced — they are date-specific, expire naturally, and are re-derivable by re-running the Calendar import
- [ ] **SYNC-11**: The app works correctly on web when opened in more than one tab, without data loss or stale reads
- [x] **SYNC-12**: Availability changes are written as one batched document write rather than one write per edited hour cell

### Migration and conflict handling (MIG)

- [ ] **MIG-01**: On a first sign-in where the account holds no data, the device's existing data becomes the account's data, with no prompt
- [ ] **MIG-02**: When an account already holds data and the device's local data belongs to a different (or no previous) account, the account's data wins and the device is updated — local leftovers are never pushed over it
- [ ] **MIG-03**: When an account already holds data and the same user's own device data has genuinely diverged since the last sync, the user is asked which version to keep, rather than one silently overwriting the other
- [ ] **MIG-04**: The app records when profile and availability were last changed, and which account last synced on the device — the two facts MIG-02 and MIG-03 depend on, neither of which exists today
- [x] **MIG-05**: Migration is written as a single all-or-nothing operation, so an interrupted migration cannot leave a half-populated account that later looks complete
- [x] **MIG-06**: Migration is only treated as complete once the server has confirmed the write, not when the local SDK optimistically reports success
- [x] **MIG-07**: Local data is never deleted as part of migration
- [ ] **MIG-08**: An automated test seeds realistic production-shaped local data and asserts the exact resulting cloud document shape — manual testing is insufficient here, given this app's history of silent data-format bugs

### Account-backed feedback (FB)

- [ ] **FB-01**: A signed-in user can send feedback from within the app, replacing the current `mailto:` route
- [ ] **FB-02**: Feedback automatically carries the scoring context it refers to — the score, the weather inputs behind it, and the user's own tolerance settings at that moment
- [ ] **FB-03**: A user who is not signed in can still send feedback anonymously, so feedback volume does not collapse to the signed-in minority
- [ ] **FB-04**: Feedback composed without a connection is queued and sent later rather than lost
- [ ] **FB-05**: Feedback records can be created by the client but not read or listed by it

### Regression protection (REG)

- [ ] **REG-01**: The existing Android app continues to build and run correctly as a release build after `supabase_flutter` is added, verified on a real device
- [ ] **REG-02**: The existing web PWA continues to install, launch in standalone mode, and navigate correctly after `supabase_flutter` is added, verified on a real iPhone
- [ ] **REG-03**: Web cold-start time is re-measured on a real device over a real mobile connection once the full cloud stack has landed, and a regression past the 2-second budget is treated as blocking — the expectation that `supabase_flutter` is lighter than the Firebase SDKs is reasoned, not measured
- [ ] **REG-04**: The existing Google Calendar integration continues to work end-to-end on both platforms after authentication is added
- [ ] **REG-05**: The Android background refresh task continues to work, and gains no Supabase dependency

---

## Future Requirements (deferred)

Valuable, but deliberately not in this milestone.

- **In-app JSON data export** — GDPR Article 20 is satisfied at this scale by the documented manual process in PRE-09. An in-app export button would also resolve BACKLOG #4 and double as a user-facing backup; revisit once sync is live and the serialization already exists.
- **"Your feedback" history screen with developer replies** — worth building once there is enough submitted feedback to make a history meaningful.
- **Live cross-device sync via Supabase Realtime** — deliberately deferred in favour of fetch-on-foreground (SYNC-04). Adds cost and multi-tab complexity; revisit as a separate measurable step once sync is proven. Note this is the one capability Firestore would have provided for free, and it is deliberately not being bought.
- **Calendar-scope grant counter** — there is no Google-side alert before the 100-user cap is hit. If tracking is wanted it must be built; not scoped now.
- **Server-side notifications** — milestone phase 5. Would require the background isolate to gain a Supabase dependency, explicitly avoided in REG-05.

## Out of Scope

Explicit exclusions, with reasoning, to prevent re-adding.

- **Friends, shared availability, ride invites** — milestone phases 3–4. They need a network effect that does not exist yet; building them now produces an empty feature skeleton. Reassess after phases 1–2 ship and testers respond.
- **Any authentication method other than Google Sign-In** — `google_sign_in` is already in the app, and this avoids password management, email verification, and password reset entirely. Accepted limitation: anyone unwilling to use a Google account cannot participate.
- **Custom account recovery** — Google already owns identity recovery for Google accounts. A parallel recovery flow duplicates effort and is a weaker security surface. Local data survives regardless of account access, which is the real safety net.
- **Third-party feedback/bug-report SDK** (Instabug, Shake) — they capture generic device and session data, not the domain-specific score-and-tolerance context that is the whole point here, and they add a new data-processing relationship immediately after tightening the privacy story.
- **CRDT or operational-transform merge engine** — wildly disproportionate for a small single-user settings blob. Field-level last-write-wins plus the MIG-03 prompt is sufficient.
- **Automatic union-merge of two devices' availability grids** — actively wrong for this data shape. Availability is exclusionary (blocked vs open), not additive; unioning two schedules produces a schedule more available than either user intended.
- **Real-time collaborative UI** (presence, live editing indicators) — no collaborative use case exists; this is single-user data.
- **Full support-ticket system** (statuses, assignment, SLAs) — overkill for a solo developer and a few dozen testers.
- **Self-service GDPR consent portal** — disproportionate at this scale. The real obligations are a correct privacy policy, honouring deletion, and honouring export.
- **Supabase Edge Functions / any server-side code beyond SQL** — the milestone breaks "no backend" for managed Auth and Postgres only. The one exception is a single `plpgsql` function invoked via `rpc()` to make first-login migration a real transaction (MIG-05/06); that is schema, not a service.
- **Syncing the forecast cache** — derived data (SYNC-09).
- **A general offline sync engine** — SYNC-05 is met by a small coalescing outbox drained on sign-in, foreground, and after a successful write. Backoff schedules, connectivity listeners and background draining are explicitly not in scope.

---

## Traceability

Filled by the roadmapper. Phases 18–22 continue the numbering from v2.0 (last phase was 17); see `.planning/ROADMAP.md` for full phase detail.

**Note on AUTH-09:** although its REQ-ID prefix is AUTH, it is mapped to Phase 21 (Sync + migration) rather than Phase 19 (Auth). Account deletion cannot remove "stored data on the server" before there are rows to delete — that capability, and its verification, only becomes real once Phase 21 creates the schema. Phase 19 ships sign-in/out only; there is nothing server-side yet for AUTH-09 to delete. Under Supabase this requirement is largely satisfied by `on delete cascade` from `auth.users` rather than by a client-side cleanup routine — but the deletion must still be *verified* to have removed the rows, not assumed from the schema definition.

**Note on REG-01/02/03/04/05:** distributed across phases by which phase's work actually creates the regression risk, per research (`PITFALLS.md` #10, `SUMMARY.md`): REG-01/02/04 land in Phase 19 (Auth), where `supabase_flutter` is added and where the Calendar-identity-mismatch risk lives — note that under Supabase, Phase 19 must also *modify* `lib/services/calendar_service.dart` to pass `serverClientId`, which puts the change directly on the working "Add to calendar" path and makes REG-04 a sharper gate than it was under the Firebase plan. REG-05 lands in Phase 20 (Repository refactor), the phase that actually touches `background_task.dart`.

REG-03 remains bound to Phase 21 as the blocking gate, pairing with SYNC-07, but its phase rationale changed with the stack: there is no second SDK landing in Phase 21 the way `cloud_firestore` would have. The entire web payload arrives in Phase 19, so a baseline cold-start measurement should be taken there; Phase 21 re-measures once startup actually performs cloud reads, and owns the pass/fail decision.

| REQ-ID | Phase | Status |
|--------|-------|--------|
| PRE-01 | Phase 18 | Complete |
| PRE-02 | Phase 18 | Complete |
| PRE-03 | Phase 18 | Complete |
| PRE-04 | Phase 18 | Complete |
| PRE-05 | Phase 18 | Complete |
| PRE-06 | Phase 18 | Complete |
| PRE-07 | Phase 18 | Complete |
| PRE-08 | Phase 18 | Complete |
| PRE-09 | Phase 18 | Complete |
| AUTH-01 | Phase 19 | Pending |
| AUTH-02 | Phase 19 | Pending |
| AUTH-03 | Phase 19 | Pending |
| AUTH-04 | Phase 19 | Pending |
| AUTH-05 | Phase 19 | Pending |
| AUTH-06 | Phase 19 | Pending |
| AUTH-07 | Phase 19 | Pending |
| AUTH-08 | Phase 19 | Pending |
| AUTH-09 | Phase 21 | Complete |
| AUTH-10 | Phase 19 | Pending |
| SYNC-01 | Phase 21 | Complete |
| SYNC-02 | Phase 21 | Complete |
| SYNC-03 | Phase 21 | Complete |
| SYNC-04 | Phase 21 | Pending |
| SYNC-05 | Phase 21 | Pending |
| SYNC-06 | Phase 21 | Pending |
| SYNC-07 | Phase 21 | Pending |
| SYNC-08 | Phase 21 | Complete |
| SYNC-09 | Phase 21 | Complete |
| SYNC-10 | Phase 21 | Complete |
| SYNC-11 | Phase 21 | Pending |
| SYNC-12 | Phase 21 | Complete |
| MIG-01 | Phase 21 | Pending |
| MIG-02 | Phase 21 | Pending |
| MIG-03 | Phase 21 | Pending |
| MIG-04 | Phase 21 | Pending |
| MIG-05 | Phase 21 | Complete |
| MIG-06 | Phase 21 | Complete |
| MIG-07 | Phase 21 | Complete |
| MIG-08 | Phase 21 | Pending |
| FB-01 | Phase 22 | Pending |
| FB-02 | Phase 22 | Pending |
| FB-03 | Phase 22 | Pending |
| FB-04 | Phase 22 | Pending |
| FB-05 | Phase 22 | Pending |
| REG-01 | Phase 19 | Pending |
| REG-02 | Phase 19 | Pending |
| REG-03 | Phase 21 | Pending |
| REG-04 | Phase 19 | Pending |
| REG-05 | Phase 20 | Pending |

**Coverage:** 49/49 v3.0 requirements mapped. No orphans, no duplicates.

---
*Requirements defined: 2026-07-25 — milestone v3.0 Accounts & Sociaal*
*Traceability filled: 2026-07-25 — roadmap Phases 18–22*
