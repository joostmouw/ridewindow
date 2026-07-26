# Console Setup Checklist

What was registered where, for accounts (Google Sign-In + Supabase). Diagnostic, not ceremonial: when sign-in breaks in six months, this file answers *"what is it supposed to be set to"* without a console archaeology session.

Runbook side — what to do when it is already broken — lives in [`ACCOUNTS-OPERATIONS.md`](ACCOUNTS-OPERATIONS.md).

**Contains no secrets.** SHA-1 fingerprints are public certificate hashes and the OAuth client ID ships inside the app. The Supabase anon key, the service role key and the keystore password are deliberately absent and must stay that way.

---

## Coordinates

| | Value | Source |
|---|---|---|
| Google Cloud project | `my-project-joost`, project number **300023366326** | `.planning/milestones/v2.0-phases/15-google-calendar-web-integration/15-02-SUMMARY.md` |
| Cloud project owner | `joostmouw@gmail.com` (Owner via IAM) | 15-02-SUMMARY.md |
| Android `applicationId` | `ridewindow.joost.amsterdam` | `android/app/build.gradle.kts:37` |
| Play Console app signing page | `https://play.google.com/console/u/0/developers/4716806605533867534/app/4975932698287804363/keymanagement` | Play Console URL |
| Supabase project ref | `hcdrydlgqpnmumfupgcx` | 18-CONTEXT.md |
| Supabase API URL | `https://hcdrydlgqpnmumfupgcx.supabase.co` | verified live, HTTP 401 without key |
| Deployed PWA origin | `https://my-project-joost.web.app` | Firebase Hosting |
| Privacy policy URL | `https://joostmouw.github.io/ridewindow/privacy-policy.html` | verified live |
| OAuth scope in use | `https://www.googleapis.com/auth/calendar.events` (Sensitive) | `lib/services/calendar_service.dart` |

> ⚠ **Wrong-project trap.** A duplicate Cloud project `my-project-joost-becc7` (project number **899027188899**) was created by accident during Phase 15 and still exists. Everything below belongs on project number **300023366326**. Registering a fingerprint on the duplicate produces an auth failure that looks like a generic sign-in error, with nothing in the console visibly wrong.

---

## 1. Supabase region and DPA (PRE-02, PRE-03)

| Item | Value | Verified |
|---|---|---|
| Primary Database region | West EU (Paris) · `eu-west-3` | ✓ read from dashboard 2026-07-26 |
| DPA requested at | Organization level — `Organization settings → Legal Documents → Request DPA` | ✓ requested 2026-07-26 |
| DPA notification address | `joostmouw@gmail.com` | ✓ 2026-07-26 |
| DPA signed by | **Joost Mouw**, as a natural person (not Fanalists) | decided 2026-07-26 |
| DPA document version | `Template Supabase Customer DPA (June 1)` | ✓ 2026-07-26 |
| DPA **executed** (PandaDoc signed) | _PENDING — see F-4_ | ✗ **not yet** |

Region cannot be changed after project creation, which is why PRE-02 requires reading it from the dashboard rather than trusting a note. If the DPA turns out to be unavailable on the free tier, record that here as an explicit finding — it changes what the privacy policy can honestly claim.

Dashboard: `https://supabase.com/dashboard/project/hcdrydlgqpnmumfupgcx/settings/general`

## 2. OAuth clients in Cloud Console (PRE-04)

### Android clients

Google's Android client form holds **one** SHA-1 per client, so two fingerprints means two clients sharing one package name. Both created 2026-07-26.

| Client name | SHA-1 | Client ID |
|---|---|---|
| `RideWindow Android (Play App Signing)` | `4F:25:B5:D3:56:F6:09:3A:9B:F7:8E:E5:78:08:66:28:62:77:24:D7` | `300023366326-icia0dj8lv4sm0nd2t7fns3ktt0s0j7v.apps.googleusercontent.com` |
| `RideWindow Android (upload key)` | `B6:19:22:8F:60:72:AB:DE:AF:38:4E:30:00:20:B0:6B:48:58:06:31` | `300023366326-vmtc8pu6fr9pa5frdodgcktjfmdrnmct.apps.googleusercontent.com` |

Package name on both: `ridewindow.joost.amsterdam`. **Both read back from the console after creation** — each client page was reopened and its SHA-1 compared character by character against the source value. The Play App Signing fingerprint is the one that matters for Store installs; the upload key covers locally-built release APKs.

The local fingerprint above is from `/Users/joostmouw/upload-keystore.jks`, alias `upload`, read on 2026-07-25 with `keytool -list -v`. Its SHA-256 is `2F:F3:88:0F:DA:C5:D5:82:7D:79:DB:4E:61:62:A8:59:D5:74:60:75:D9:E1:2A:80:66:88:1F:D2:CE:5D:A8:92`.

**Both fingerprints are required, not either.** An app installed from the Play Store is signed with Google's key, not the local keystore. Registering only the local one yields a feature that works perfectly in testing and fails for every real user — this has already cost this project one shipped, broken feature (Calendar, Phase 9).

### Web client

| Item | Value |
|---|---|
| Client ID | `300023366326-ddo399qf5lavv48njbfpm7rg0mc8cnno.apps.googleusercontent.com` |
| Created | Phase 15-01 (v2.0), for web Calendar OAuth |
| Wired into | `web/index.html:47` as `<meta name="google-signin-client_id">` |
| Client name in console | `RideWindow Web`, created 13 July 2026 |
| Authorized JavaScript origins | `http://localhost:5000` and `https://my-project-joost.web.app` | ✓ both already present 2026-07-26 |
| Authorized redirect URIs | `https://hcdrydlgqpnmumfupgcx.supabase.co/auth/v1/callback` | ✓ added and read back 2026-07-26, see F-5 |

Credentials page: `https://console.cloud.google.com/apis/credentials?project=my-project-joost`

## 3. Supabase Google provider and consent screen (PRE-04)

| Item | Value | Verified |
|---|---|---|
| Google provider enabled | **Yes** | ✓ enabled 2026-07-26 |
| Client ID configured in Supabase | `300023366326-ddo399qf5lavv48njbfpm7rg0mc8cnno.apps.googleusercontent.com` (web client) | ✓ saved and read back after reload 2026-07-26 |
| Client Secret in Supabase | empty — not needed for the `signInWithIdToken` path, see F-5 | — |
| Supabase callback URL | `https://hcdrydlgqpnmumfupgcx.supabase.co/auth/v1/callback` | ✓ read 2026-07-26 |
| Consent screen publish status | **In production**, User type External | ✓ **proven** in console 2026-07-26 |
| OAuth user cap consumed | **3 of 100** users | ✓ read 2026-07-26 |

With the `signInWithIdToken` flow the app obtains a Google ID token on the device and hands it to Supabase, whose auth server verifies the token's **audience** against the web client ID configured here. Without it, sign-in fails server-side with an audience error that reads like a generic auth failure. See `.planning/research/PITFALLS.md` #3.

Providers page: `https://supabase.com/dashboard/project/hcdrydlgqpnmumfupgcx/auth/providers`

## 4. Privacy policy and Data Safety (PRE-05, PRE-06)

| Item | Value | Verified |
|---|---|---|
| Policy live at published URL | Yes — HTTP 200, byte-identical to `docs/privacy-policy.html` | ✓ 2026-07-25 |
| Dutch and English sections both render | Yes — 14 `<h2>` sections per language | ✓ 2026-07-25 |
| Deletion anchors resolve | Yes — `#verwijderen` and `#delete-account` both present | ✓ 2026-07-25 |
| Old device-only claims removed | Yes — no surviving "data stays on your device" promise; the phrase appears only as a section heading scoping what genuinely remains local | ✓ 2026-07-25 |
| Data Safety form submitted | **Yes** — verified in Publishing overview as "Changes in review", managed publishing off | ✓ 2026-07-26 |
| Deletion URL declared in form | `https://joostmouw.github.io/ridewindow/privacy-policy.html#verwijderen` | ✓ 2026-07-26 |

### Data Safety answers as declared (2026-07-26)

Google added sub-questions after the previous 21 June declaration, which is why the form reopened as incomplete rather than merely editable.

| Question | Answer | Basis |
|---|---|---|
| Encrypted in transit | **Yes** | every endpoint in `lib/` is HTTPS; no plain `http://` anywhere |
| Account creation methods | **OAuth** | Google Sign-In; email+password deliberately not declared, see F-10 |
| Partial deletion without account deletion | **No** | `ACCOUNTS-OPERATIONS.md` §4 documents only account deletion and manual export; claiming otherwise would promise a route that does not exist |
| Location — precise | **Not declared** | `location_provider.dart` requests `LocationAccuracy.reduced`; see F-9 |
| Location — approximate | Collected, not shared, not ephemeral, optional, App functionality | coordinates go to Open-Meteo; manual location override is stored server-side |
| Personal info — Name | Collected, not shared, not ephemeral, optional, App functionality | `profile.userName` is a profile setting and syncs when signed in |
| Personal info — Email address | Collected, not shared, not ephemeral, optional, Account management | account identity from Google Sign-In |
| Personal info — User IDs | Collected, not shared, not ephemeral, optional, Account management | Supabase auth UUID |
| App activity — Other user-generated content | Collected, not shared, not ephemeral, optional, App functionality | weekly availability pattern and planned rides |
| Calendar | **Not declared** | calendar-imported blocked hours never leave the device, see F-7 |

**Why nothing is declared as "Shared".** Google exempts transfers to a service provider processing on the developer's behalf. The published privacy policy lists Open-Meteo, Supabase and Google under *"Wie namens ons gegevens verwerkt"* — processors, not recipients. Declaring "Shared" would have put a "shares data with third parties" label on the Store listing that directly contradicts the policy. The resulting listing reads **"No data shared with third parties"**.

**Why everything is "optional".** Signing in is optional and the policy states the app works fully without an account; location has a manual override for users who deny the permission.

The Data Safety declaration must state: an account is created; location data and calendar-derived availability are collected and **stored on servers** (the current declaration says device-only); data is encrypted in transit; users can request deletion. It must be **submitted**, not merely edited.

Play Console: app → Policy and programmes → App content → Data safety.

---

## Findings

_Recorded rather than omitted — findings are the most valuable thing this file carries._

**F-7 (resolved in favour of the policy). Plan 18-04 and the published privacy policy contradicted each other about calendar data.** The plan instructed that Data Safety declare "location data and calendar-derived availability are collected and stored on servers". The policy rewritten in plan 18-02 and published states the opposite under *"Wat op je toestel blijft"*: calendar-imported blocked hours "worden nooit naar een server gestuurd". The policy is published and is the promise to users; the plan text predates 18-02's execution. **Calendar was therefore not declared.** If Phase 21 ever syncs calendar-derived hours server-side, both the policy and this declaration must change together.

**F-8 (open, user-visible bug). The in-app privacy policy link is dead.** `lib/features/profile/profile_screen.dart:35` points at `https://joostmouw.github.io/ridewindow-privacy/`, which returns **HTTP 404** — a repo that does not exist. The correct URL, and the one registered on the Store listing and the OAuth consent screen, is `https://joostmouw.github.io/ridewindow/privacy-policy.html`. Every tester tapping "Privacybeleid" in Profile currently gets a 404. This predates accounts and is a one-line fix, but it is the kind of defect that reads as negligence in a privacy context.

**F-9 (open, permission hygiene). `ACCESS_FINE_LOCATION` is declared but never used.** `AndroidManifest.xml` declares both `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION`, while `lib/providers/location_provider.dart` requests `LocationAccuracy.reduced`. The fine-location permission is therefore over-broad, and on Android 12+ it makes the system show users a precise/approximate toggle for a choice the app does not act on. Dropping the fine permission would match the declared Data Safety answer (approximate only) to the manifest.

**F-10 (open, decision for Phase 19+). Email+password was considered and deliberately not declared.** Supabase Auth supports it natively, and the strongest argument for it is the **iOS PWA**: an OAuth redirect out of a home-screen-installed standalone PWA is fragile on iOS, and the Google web flow additionally needs a client secret that can no longer be read back (see F-5). The cost is outbound email — Supabase's built-in mailer is rate-limited and development-only, so real use needs custom SMTP, which adds a **third sub-processor** to a privacy policy that currently names exactly three. Not declared in Data Safety; if it ships, add "Username and password" to the account-creation answer and a mail provider to the policy.

**F-6 (open, for Phase 21). Supabase's Client IDs field currently holds only the web client ID.** The field accepts a comma-separated list "for Web, OAuth, Android apps, One Tap, and Chrome extensions". Which value the ID token actually carries as its audience depends on how `google_sign_in` is configured: pass the **web** client ID as `serverClientId` and the audience is the web client ID (matching what is configured now); omit it and the audience is the **Android** client ID, which Supabase would then reject. Either configure `serverClientId` in the app, or add both Android client IDs to this field. Decide it in Phase 21 rather than debugging an "audience mismatch" that reads like a generic auth failure.

**F-1 (resolved 2026-07-26). The Android OAuth client did not exist — confirmed, then created.** Before this phase the project had exactly one OAuth client (`RideWindow Web`), verifying the suspicion recorded below. Two Android clients now exist; see the table above. Original evidence: `.planning/PROJECT.md` states that `my-project-joost` is a fresh project backing web Calendar OAuth, "not the (never-completed) Phase 9 Android OAuth project — Android's own Calendar OAuth client still needs equivalent Cloud Console setup if that native feature is to work in production." Corroborating evidence in the repo: there is no `google-services.json` anywhere in `android/`, and no Android OAuth client ID appears in `lib/`, `android/`, or any planning document. Expect to **create** the Android client rather than edit one. Confirm on the Credentials page and record the outcome here.

**F-4 (open, blocks PRE-03). The DPA is not self-service — it has a lead time.** Clicking *Request DPA* does not execute anything. Supabase prepares a **PandaDoc** document and emails a signing link within 24 hours; the DPA is only executed once that document is signed. Requested 2026-07-26 to `joostmouw@gmail.com`. **PRE-03 stays open until the PandaDoc is signed** — a signature request is not a data processing agreement. Do not treat accounts as launch-ready before then: from 2026-07-26 the app has a processor (Supabase) holding user data with no executed processing agreement, which is the gap PRE-03 exists to close.

**F-5 (open). The Google web client has no Authorized redirect URIs, which the PWA sign-in flow will need.** Supabase's Google provider panel states its callback URL `https://hcdrydlgqpnmumfupgcx.supabase.co/auth/v1/callback` must be registered "when using Sign-in with Google on the web using OAuth". The web client's redirect URI list is currently empty. This does not affect the native Android `signInWithIdToken` path — that flow verifies the ID token's audience and needs no redirect URI — but RideWindow ships a live PWA at `https://my-project-joost.web.app` that iOS testers use, and browser sign-in there will fail without it. Registering it now is one line and costs nothing; discovering it during Phase 21 costs a debugging session. **Second-order caveat:** the web OAuth flow also needs the client *secret* in Supabase, and Cloud Console states "Viewing and downloading client secrets is no longer available" — the existing secret (`****CpdM`, created 13 July 2026) cannot be read back, so a new secret must be generated if that flow is implemented.

**F-2 (resolved 2026-07-26). Consent screen is genuinely "In production".** Verified by reading `Google Auth Platform → Audience` directly, closing the gap left by `OAUTH-PUBLISH-CHECKLIST.md`, whose final verification steps were never ticked. User type: External. The same page shows the OAuth user cap counter at **3 of 100** — live confirmation of the cap described in `ACCOUNTS-OPERATIONS.md` §1, and a reminder that it is cumulative and never resets.

**F-3 (resolved 2026-07-26). The DPA is available on the free tier — it is not plan-gated.** `Organization settings → Legal Documents` states "All organizations can sign our Data Processing Addendum ('DPA') as part of their GDPR compliance", with a **Request DPA** action. The contrast on the same page is the evidence: SOC2 Type 2 and ISO 27001 are gated behind "Upgrade to Team", the DPA is not. A Transfer Impact Assessment (TIA) is also available to all organizations there — not required by PRE-03, but relevant to the same GDPR story, since Supabase is US-incorporated even though this project's data sits in `eu-west-3`.

---

Last updated: 2026-07-25 · Phase 18 (Preconditions), plan 18-04
