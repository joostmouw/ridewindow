# Pitfalls Research: Supabase Auth + Postgres on an Already-Shipped, Two-Platform Flutter App

**Domain:** Adding `supabase_flutter` to RideWindow — Flutter 3.x, Riverpod 3.x, Drift, `google_sign_in` 7.2.0, shipped on Play Store (internal track) and as a Firebase-hosted PWA
**Researched:** 2026-07-25 (Supabase stack; supersedes `archive-firebase/PITFALLS.md`)
**Confidence:** HIGH for #1–#3 and #7–#8 (verified against live docs and the actual codebase), MEDIUM for #6 (new construction, no reference implementation here)

Pitfalls #4, #5, #9 and #10 carry over from the Firebase research largely intact — they were never Firebase-specific. #1, #2, #3, #6, #7 and #8 are new or materially changed.

---

## Critical Pitfalls

### Pitfall 1: Every Supabase Google-auth tutorial is written for `google_sign_in` 6.x — this app is on 7.2.0

**What goes wrong:**
Supabase's own official Dart reference for `signInWithIdToken` shows:

```dart
final googleUser = await googleSignIn.signIn();          // 6.x — removed in 7.x
final googleAuth = await googleUser!.authentication;      // 6.x shape
```

`pubspec.yaml` pins `google_sign_in: ^7.2.0`, whose API is a full rewrite: a `GoogleSignIn.instance` singleton, a mandatory `initialize()`, `authenticate()` for identity, and a *separate* `authorizationClient` for scopes. Copying the documented snippet produces code that does not compile, and the nearest-looking fix (adding `google_sign_in: ^6.x`) would break `lib/services/calendar_service.dart`, which is built entirely on the 7.x authorization API (`GoogleSignIn.instance.authorizationClient.authorizeScopes([...])`, lines 99 and 156).

**Why it happens:**
7.x is recent enough that the whole ecosystem of blog posts and even first-party docs still shows 6.x. The 6.x snippet is also *plausible* — it reads like normal Dart, so it survives review.

**How to avoid:**
- On 7.x the identity call is `GoogleSignIn.instance.authenticate()`, returning a `GoogleSignInAccount` whose `authentication.idToken` is what Supabase needs.
- Supabase's `signInWithIdToken` requires **both** `idToken` and `accessToken` for Google. In 7.x these come from *different* objects: the ID token from `authenticate()`, the access token from `authorizationClient`. This split does not exist in 6.x and is the single most likely place to get stuck.
- Reuse `CalendarService._sharedInitialize()` (`lib/services/calendar_service.dart:35-44`) rather than calling `GoogleSignIn.instance.initialize()` again. That method exists *because* a second concurrent `initialize()` throws `Bad state: init() has already been called` — a bug this project already fixed once (see its own comment, "Rule 1 bugfix, CAL-06 follow-up").

**Warning signs:**
- `signIn is not defined for GoogleSignIn` at compile time — you copied a 6.x snippet.
- `Bad state: init() has already been called` at runtime — you added a second init path instead of sharing the memoized one.

**Phase:** Auth (19). AUTH-05 exists precisely for this.

---

### Pitfall 2: On web, `authenticate()` throws — sign-in must be Google's own rendered button

**What goes wrong:**
`google_sign_in_web` returns `false` from `supportsAuthenticate()` and **throws** if `authenticate()` is called, because Google Identity Services only permits sign-in through UI the SDK itself renders. The web flow is: display the widget returned by `renderButton()` (from `google_sign_in/web_only.dart`) and listen to `authenticationEvents`.

This has a direct product consequence that is easy to miss until the web build is tested: **AUTH-02 asks for a sign-in row styled like the existing Google Calendar connection row, and on web that is not fully achievable.** Google's rendered button has constrained styling. Either the web account row looks different from its Android counterpart, or both platforms adopt the rendered button and the Calendar row's visual pattern is matched only approximately.

Note this is *new* surface for this codebase: the existing Calendar integration never calls `authenticate()` at all — it only ever requests scope authorization. So the app has no working web sign-in path to copy.

**Why it happens:**
It is a platform restriction expressed as a runtime exception rather than a compile error, so an Android-first implementation passes every test until someone opens the PWA.

**How to avoid:**
- Branch on `GoogleSignIn.instance.supportsAuthenticate()`, not on `kIsWeb`, so the check tracks the plugin's actual capability.
- Decide the visual compromise deliberately during Phase 19's UI work rather than discovering it at test time. This is a genuine gray area for `/gsd:ui-phase`, not an implementation detail.
- Test sign-in on the deployed PWA, not `flutter run -d chrome` alone — GIS behaves differently across origins.

**Warning signs:**
- `authenticate is not supported on the web. Instead, use renderButton to create a sign-in widget.`
- Sign-in works in local Chrome but not on the deployed domain (origin not registered on the OAuth client).

**Phase:** Auth (19), AUTH-06. Flag to `/gsd:ui-phase` for the styling decision.

---

### Pitfall 3: Supabase verifies the ID token against the *web* client ID, which is a different registration from the one Calendar already uses

**What goes wrong:**
Three OAuth identifiers are involved and they are easy to conflate:

1. The **Android client ID**, bound to the app's package name + SHA-1. Google sign-in on Android works *without* explicitly passing it, which makes it feel optional — until a release build fails because only the debug SHA-1 was registered.
2. The **web client ID**, which must be passed as `serverClientId` to `GoogleSignIn.instance.initialize()` **and** registered in the Supabase dashboard's Google provider settings. Supabase's auth server uses it to verify the ID token's audience. Miss it and `signInWithIdToken` fails server-side with an audience mismatch that reads like a generic auth error.
3. The existing **Calendar** OAuth setup in the same Cloud project, which today works with `initialize()` called with *no arguments* (`calendar_service.dart:36`). Adding `serverClientId` changes that shared call — so this is a modification to a file the Firebase plan had listed as untouched, and it sits directly on the working "Add to calendar" path (REG-04).

PRE-04 requires *both* SHA-1 fingerprints — the local release keystore **and** the Play App Signing key from Play Console → App integrity. The second is the one that gets forgotten, and it is the one that matters for anything installed from the Play Store: this project has already shipped a Google integration broken for exactly this class of reason.

**Why it happens:**
Supabase's dashboard, Google Cloud Console Credentials, and the app's `initialize()` call are three separate surfaces, and nothing validates them against each other. Failures appear only on a real release build.

**How to avoid:**
- Register both SHA-1 fingerprints in Cloud Console before Phase 19 codes anything (PRE-04). Unlike the Firebase plan there is no Firebase Console fingerprint surface — one place, not two.
- Add the deployed PWA origin to the web client's Authorized JavaScript origins.
- After adding `serverClientId`, re-verify "Add to calendar" on both platforms before declaring Phase 19 done (REG-04).
- Treat AUTH-10 as the hard gate it is: sign-in proven from a Play-Store-installed release build, not a debug build.

**Warning signs:**
- Sign-in works in debug, fails after Play Store install.
- `Invalid audience` / generic 400 from the Supabase auth endpoint.
- Calendar stops working right after auth is added.

**Phase:** Preconditions (18) for the registrations; Auth (19) for the wiring.

---

### Pitfall 4: Misreading the 100-user OAuth cap as "accounts are capped at 100"

**What goes wrong:**
The 100-user lifetime cap is tied to the Cloud project's *unverified sensitive scope* usage — `calendar.events` is Sensitive — and counts unique users who have ever granted that specific scope, not unique sign-ins. Two wrong conclusions are equally easy: (a) that adding accounts caps the app at 100 users total (it does not — basic sign-in uses `openid`/`email`/`profile`, non-sensitive, and does not count), or (b) that the cap no longer applies because the consent screen shows "In production" (it does still apply — publish status and verification status are different axes, already recorded as a deliberate nuance in this project's history).

Under Supabase the split is *cleaner* than under Firebase: sign-in identity is verified by Supabase's own auth server, and only the Calendar authorization path touches the sensitive scope. But the underlying Google consent screen is still shared, so the cap is unchanged.

**How to avoid:**
Document explicitly (PRE-07, in the revised constraints, not tribal memory): plain sign-in is not capped; the cap bites only when a user *also* taps "Connect Calendar"; it is a cumulative lifetime count, not concurrent, and is not resettable without full Google verification. Onboarding well past 100 accounts is safe; the Calendar-connecting subset must be budgeted against 100 for the project's life.

**Warning signs:** the "Google hasn't verified this app" warning escalating to a hard block; a plain sign-in failure triaged as a cap issue, or vice versa.

**Phase:** Preconditions (18), PRE-07. Note that a grant counter is explicitly deferred in REQUIREMENTS.md — there is no Google-side alert, so the number is simply unobserved for now. That is an accepted risk, not an oversight.

---

### Pitfall 5: First-login migration is not atomic, not idempotent, and can race a second device

**What goes wrong:**
"Local wins on first login" has several silent-failure shapes, and this app has a documented history of silent data-format bugs (the UTC/local `DateTime` key bug took months to surface and was invisible to manual testing):

1. **Partial writes.** Writing `profiles`, `availability` and `planned_rides` as three separate calls means an app kill or dropped connection mid-migration leaves a half-populated account that *looks* complete to a naive "does a row exist?" check on next launch — which then skips migration forever.
2. **Second-device race.** A fresh install signing in before the first device's migration completes can have its *empty* local state treated as authoritative and overwrite real data.
3. **Fire-and-forget failure.** This shape changes under Supabase. Firestore's optimistic local write reported success before reaching the server; Supabase has no such queue, so the opposite failure appears — an `await`-less cloud write simply fails and nobody notices, because the local write already succeeded and the UI already updated.

**How to avoid:**
- Write the whole first-login payload as **one Postgres transaction** via an `rpc()` call to a `plpgsql` function (MIG-05). Postgres gives a real transaction here where Firestore needed a batched write plus care about cache semantics — take the win, and do not decompose it into three table writes for convenience.
- Treat migration as complete only on the server's response to that call (MIG-06). With Supabase this is naturally true *provided the call is awaited* — so the rule is: the migration path is the one place fire-and-forget is banned.
- Never delete local data as part of migration (MIG-07). Local-only-until-confirmed is cheap insurance.
- For the second-device case, follow the resolver in ARCHITECTURE.md §5: an existing cloud row plus a `lastSyncedUid` mismatch means pull, never push.
- Add the automated test MIG-08 requires: seed realistic production-shaped local data (real weekly-grid key format, real block types) and assert the exact resulting row shape. Manual smoke testing is not sufficient here — this is the specific class of bug that already bit this project.

**Warning signs:** rows with some expected fields empty; two devices showing different availability grids after both "successfully" signed in; "my blocked hours disappeared after I signed in on a new phone".

**Phase:** Sync + migration (21). The resolver itself is buildable and unit-testable first, with no SDK.

---

### Pitfall 6: Supabase has no offline write queue — the Firestore-shaped assumption silently drops user edits

**What goes wrong:**
`supabase_flutter` persists the *session* offline; it does not persist or queue *data writes*. A `.upsert()` issued with no connection throws (or hangs to timeout). If cloud writes are fire-and-forget — which ARCHITECTURE.md §2 deliberately makes them, so the UI never blocks — the failure is swallowed entirely: the local write succeeded, the UI updated, the user saw their change, and it never reached the server. The user then opens the web app on another device and their change is missing, with no error having ever been shown on either.

This is the single largest behavioural difference from the Firebase plan and the only place the switch adds work rather than removing it. SYNC-05 does not become harder to state, it becomes something you must actually build.

**Why it happens:**
Nothing fails loudly. Every test on a good connection passes. It only manifests as "my settings didn't sync" reports weeks later — the same shape as this project's historical silent bugs.

**How to avoid:**
- Build the Drift-backed outbox in ARCHITECTURE.md §4a, and land it *with* the first cloud write, never after. A cloud write path without an outbox is the bug.
- Coalesce per entity key and make every write an idempotent upsert, so replay is always safe and ordering never matters.
- Drive SYNC-06's synced/pending indicator directly off outbox contents — one source of truth, no separate state that can disagree.
- Resist scope creep into a sync engine: no backoff schedules, no connectivity listeners, no background draining in this milestone. Drain on sign-in, on foreground, and after a successful write.
- **Multi-tab (SYNC-11) needs its own check.** The outbox lives in Drift, and Drift's web backend already has multi-tab characteristics established in v2.0 Phase 12 — verify what that phase actually concluded before assuming two tabs can share an outbox safely. Do not assume; this was a real constraint under Firestore too, just for different reasons.

**Warning signs:** any `unawaited(...)` cloud call outside the outbox; a "synced" indicator driven by a boolean flag rather than by pending rows; sync tested only on wifi.

**Phase:** Sync + migration (21), SYNC-05/06/11.

---

### Pitfall 7: RLS is off by default, and the anon key is public

**What goes wrong:**
A Postgres table created without `enable row level security` is readable and writable by anyone holding the anon key — and the anon key ships inside the app bundle and the web JS. It is *designed* to be public; RLS is the only thing standing between it and the data. Creating tables in the dashboard's SQL editor without RLS, intending to "add policies once it works", means every intermediate deploy is fully exposed.

The subtler version: RLS enabled but a policy written as `using (true)`, or `using (auth.uid() is not null)` — which reads like "must be logged in" and *is* satisfied by any logged-in user, i.e. every user can read every other user's data. Authenticated is not authorized.

**How to avoid:**
- `enable row level security` in the **same migration** that creates each table, with the policy. Never separate them.
- Policies compare `auth.uid() = user_id`, and every write policy needs `with check` as well as `using` — `using` alone governs which rows are visible to modify, not what values may be written.
- `feedback` gets an insert policy and **no select policy at all** (FB-05). With RLS on, absence of a select policy denies all client reads; the dashboard's service role bypasses RLS, which is how the developer reads it.
- SYNC-08 demands the deny case be *proven* by an automated test across two real accounts against the deployed database, not asserted. Postgres makes this straightforward — sign in as A, attempt to select B's row, assert zero rows.

**Warning signs:** a table listed as "Unrestricted" in the dashboard's table view; any policy containing `true`; a security test that only asserts the allow case.

**Phase:** Sync + migration (21) for the policies; the deny-case test is a phase-completion gate.

---

### Pitfall 8: Free-tier projects pause after 7 days of inactivity, and budget alerts do not cap spend

**What goes wrong:**
A Supabase free-tier project pauses after 7 days with no incoming API requests. Paused means unreachable — every tester's app fails to sync until the project is manually restored from the dashboard, and projects left paused long enough are eventually deleted. For an app with a handful of testers and irregular use, a quiet fortnight is entirely plausible. Firebase's Spark tier has no equivalent behaviour, so this is a risk the switch introduces.

The second half is unchanged from the Firebase analysis and still applies to whatever billing surface is used: a budget alert is a **notification**, not a spend cap. Configuring one and believing spend is bounded is the mistake.

**How to avoid:**
- Decide consciously in Phase 18 (this is PRE-01's spend ceiling and PRE-08's tripwire): accept the pause risk while testers are active, keep a scheduled ping to keep the project warm, or budget for Pro. Whichever is chosen, write down what happens when a tester reports "sync stopped working" so it is triaged in minutes rather than days.
- Supabase emails before pausing. Make sure that address is one that gets read.
- Restore is manual and from the dashboard — note this in the runbook, because it will be needed at the least convenient moment.

**Warning signs:** "the app can't sign in" reports clustered after a quiet period; a pause-warning email in a filtered inbox.

**Phase:** Preconditions (18), PRE-01 and PRE-08.

---

### Pitfall 9: Shipping accounts without the GDPR preconditions actually in place, not just acknowledged

**What goes wrong:**
Once location data and calendar-derived availability leave the device, Joost becomes a data controller; Supabase becomes a processor. Treating this as "rewrite the privacy policy text" understates it — these are separate, verifiable pieces of work across three consoles:

1. **EU data residency.** The Supabase project region is chosen at creation. Available EU regions: `eu-central-1` (Frankfurt), `eu-west-1` (Ireland), `eu-west-2` (London), `eu-west-3` (Paris), `eu-central-2` (Zurich), `eu-north-1` (Stockholm). Note London and Zurich are outside the EU proper — for an EU/GDPR posture prefer Frankfurt, Ireland, Paris or Stockholm. Verify in the dashboard; do not assume from the signup flow.
2. **Data Processing Agreement.** Supabase's DPA must actually be in effect for the project, and the privacy policy must name Supabase as a sub-processor — **in addition to Google**, which remains a sub-processor for Hosting and Calendar. This project now has two, where the Firebase plan had one.
3. **Right to erasure.** Structurally better here than under Firebase: `on delete cascade` from `auth.users` means deleting the auth user removes the rows. But this must be *verified*, not assumed from the DDL — confirm the rows are actually gone afterwards, and note that `feedback` uses `on delete set null` by design, so anonymised feedback survives deletion and the retention answer must say so.
4. **Right to export.** Must be *possible* to fulfil — a documented manual process is acceptable at this scale (PRE-09); an in-app export button is explicitly deferred.
5. **Play Store Data Safety.** Currently declares device-only handling. Must be updated to declare account creation and server-side storage, live before or at the accounts release. Play Console can flag apps whose behaviour contradicts their declaration, and this is a distinct artifact from the privacy policy page — easy to update one and forget the other.

**Why it happens:**
"Rewrite the privacy policy" scopes as a single writing task; the operational pieces are scattered across the Supabase dashboard, Google Cloud Console and Play Console and appear on no single checklist by default.

**How to avoid:** treat PRE-02 through PRE-06 and PRE-09 as a literal checklist with checkboxes, verified by looking at each console — which is exactly what Phase 18 is for.

**Warning signs:** account deletion "tested" by confirming the session is gone without checking the tables; privacy policy updated but Data Safety form still showing the old declaration; nobody has looked at which region the project was created in.

**Phase:** Preconditions (18). The deletion *implementation* is Phase 21 (AUTH-09), but its GDPR verification gates the milestone's release.

---

### Pitfall 10: Adding `supabase_flutter` regresses the live Android app or live PWA in ways the existing checklist won't catch

**What goes wrong:**
Two shipped surfaces are at risk the moment the dependency lands: the Play Store release build and the deployed PWA. The specific hazards here are narrower than Firebase's (no Gradle plugin, no `google-services.json`, no `minSdkVersion` pressure from native Firebase SDKs), but they are not zero:

- `Supabase.initialize()` added to `main()` sits on the cold-start path in front of everything, including the existing parallel `tzFuture`/`prefsFuture` block. Getting it wrong delays first paint on a 2-second budget (SYNC-07, REG-03).
- `supabase_flutter` depends on `app_links` and `url_launcher`, which register platform handlers. `url_launcher` is already in the app; `app_links` is new and touches deep-link/intent handling on Android — worth a look at whether it changes anything about how the app is launched.
- It also depends on `shared_preferences` for session persistence — the same store the app uses for all its own data. No conflict expected (different key namespace), but it means clearing app data now signs the user out too.
- Web payload growth is smaller than Firebase's would have been, but REG-03 still requires it be *measured* on a real device over a real connection, not assumed.

**How to avoid:**
Run the regression checks as explicit phase-completion gates, not as an afterthought: release-build APK on a real device (REG-01), PWA install + standalone launch + navigation on a real iPhone (REG-02), "Add to calendar" end-to-end on both platforms (REG-04), background refresh still working with no Supabase in the isolate (REG-05), and cold-start re-measured (REG-03).

**Phase:** REG-01/02/04 in Auth (19), REG-05 in the repository refactor (20), REG-03 in Sync (21) — each in the phase whose work creates the risk.

---

## "Looks Done But Isn't" Checklist

- Sign-in works — on Android debug. Not verified on a Play-Store release build (AUTH-10) or the deployed PWA (AUTH-06).
- Sync works — on wifi. No outbox, so every offline edit is silently lost (Pitfall 6).
- Security "works" — the allow case passes. The deny case across two accounts was never tested (SYNC-08).
- Account deletion "works" — the session is gone. Nobody looked at whether the rows are (AUTH-09).
- Migration "works" — on a device with no prior data. The second-device and account-switch cases were never exercised (MIG-02, MIG-03).
- Privacy policy rewritten — Data Safety form still declares device-only storage (PRE-06).
- Region "is EU" — assumed from the signup flow, never checked in the dashboard (PRE-02).
- Calendar still works — tested before `serverClientId` was added to the shared `initialize()` (Pitfall 3, REG-04).

## Pitfall-to-Phase Mapping

| Pitfall | Phase | Requirements |
|---|---|---|
| 1 — `google_sign_in` 6.x vs 7.x | 19 Auth | AUTH-05 |
| 2 — web `authenticate()` throws | 19 Auth | AUTH-06, AUTH-02 |
| 3 — three OAuth client IDs, two SHA-1s | 18 Pre / 19 Auth | PRE-04, AUTH-10, REG-04 |
| 4 — 100-user sensitive-scope cap | 18 Pre | PRE-07 |
| 5 — migration atomicity + races | 21 Sync | MIG-05/06/07/08 |
| 6 — no offline write queue | 21 Sync | SYNC-05/06/11 |
| 7 — RLS off by default, anon key public | 21 Sync | SYNC-08, FB-05 |
| 8 — free-tier pausing, alerts ≠ caps | 18 Pre | PRE-01, PRE-08 |
| 9 — GDPR preconditions | 18 Pre | PRE-02/03/05/06/09, AUTH-09 |
| 10 — regression on two shipped surfaces | 19/20/21 | REG-01…05 |

---

## Sources

- Codebase (read directly, 2026-07-25): `lib/services/calendar_service.dart` (lines 33–44, 99, 156 — the memoized init gate and the authorization-only Calendar flow), `lib/main.dart`, `lib/platform/background_task.dart`, `pubspec.yaml`.
- [pub.dev — supabase_flutter](https://pub.dev/packages/supabase_flutter) — v2.16.0, dependencies incl. `app_links`, `url_launcher`, `shared_preferences`. HIGH confidence, fetched live.
- [Supabase Docs — signInWithIdToken (Dart)](https://supabase.com/docs/reference/dart/auth-signinwithidtoken) — HIGH confidence for the API contract; its sample code is `google_sign_in` 6.x, which is the substance of Pitfall 1.
- [Supabase Docs — Regions](https://supabase.com/docs/guides/platform/regions) — HIGH confidence.
- [google_sign_in on pub.dev](https://pub.dev/packages/google_sign_in) and [google_sign_in_web API docs](https://pub.dev/documentation/google_sign_in_web/latest/) — `supportsAuthentication` false on web, `authenticate()` throws, `renderButton()` required. HIGH confidence.
- Supabase free-tier pause-after-7-days-inactivity: MEDIUM-HIGH confidence — consistent across multiple secondary sources checked 2026-07-25; confirm current policy in the dashboard during Phase 18 rather than trusting this note.
- Superseded Firebase pitfalls retained at `.planning/research/archive-firebase/PITFALLS.md`.

---
*Pitfalls research for: RideWindow v3.0 Accounts & Sociaal, Phase 1–2 scope*
*Researched: 2026-07-25 — Supabase stack*
