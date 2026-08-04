# Accounts Operations

Operational reference for running RideWindow's accounts (Google Sign-In + Supabase). This is a doc to consult while triaging a live problem, not a design record — for the "why", see `.planning/phases/18-preconditions/18-CONTEXT.md` and `.planning/research/PITFALLS.md` (#4, #8, #9).

## 1. Two different Google user caps

There are **two separate caps** on this Google Cloud project (`my-project-joost`). Do not conflate them — a plain sign-in failure and a cap failure look different and must be triaged differently.

**Auth / sign-in cap: none in practice.** Basic sign-in requests `openid`, `email`, `profile`. These are neither Sensitive nor Restricted scopes and do not count toward any Google cap. Any number of users can sign in.

**Calendar-connect cap: 100 unique users, lifetime, cumulative.** The `calendar.events` scope is a **Sensitive** scope. Because this app has not gone through Google's formal verification process, Google caps the number of *unique* Google accounts that have *ever* granted that scope at 100, for the lifetime of the project. This is:
- Not concurrent — it never resets.
- Not resettable — short of a full Google verification pass, which this project deliberately does not pursue.
- Cumulative — every distinct account that has ever tapped "Connect Calendar" and granted the scope counts, even if they later disconnect.

**The trap: this cap follows verification status, not publish status.** The OAuth consent screen shows "In production" (verified 2026-07-17 in Cloud Console). That only means the app is publicly reachable — it does **not** mean the app is Google-verified, and it does **not** remove the 100-user cap. `OAUTH-PUBLISH-CHECKLIST.md` from the original publish work said otherwise ("Confirm no 100-user cap applies anymore") — that line was wrong and has been corrected in place, with a pointer back to this document.

**The counter is currently unobserved.** Google provides no dashboard or alert for how many unique users have granted `calendar.events` so far. Building a tracker is explicitly deferred (see `REQUIREMENTS.md` "Future Requirements"). If a support report ever mentions Calendar connection failing with a Google-side error (not a plain OAuth "access denied"), treat "we may be near or past 100" as a live hypothesis, not a first assumption — a plain sign-in failure is far more common and unrelated to this cap entirely.

## 2. Free tier: what it costs you

RideWindow's Supabase project runs on the **free tier**, chosen deliberately (`Ik wil gratis en makkelijk mogelijk`). That comes with two consequences worth remembering before they matter:

**No automated backups.** The dashboard states this directly: "Last backup: No backups." If the hosted Postgres database is lost, there is no restore point on Supabase's side. The blast radius is limited because the device (Android app / browser) keeps its own local copy via Drift, and local storage remains the source of truth by design — but a hosted-only loss (e.g. a second device that has never synced) is not recoverable.

**Pauses after 7 days without API traffic.** A free-tier Supabase project goes to sleep if it receives no API requests for 7 consecutive days. While paused, the project is unreachable — sync fails for every tester until it is manually restored. Supabase sends a warning email before pausing; that address must be one that is actually read.

**Mitigation: the keep-warm job (plan 18-03).** A scheduled GitHub Actions workflow makes one API request every 3 days, well inside the 7-day window, to keep the project active without any tester needing to open the app. This is a **mitigation, not a guarantee** — if the workflow itself silently stops running (GitHub Actions outage, repo permissions change, workflow file accidentally deleted), the pause risk returns unnoticed. See the runbook below for what to check.

**Restore is manual.** If a project does pause, there is no automated restore. It must be reactivated by hand from the Supabase dashboard.

## 3. Runbook: "sync stopped working"

A tester reports that sync isn't working, or data isn't appearing on their other device. Check in this order — cheapest and most likely first:

1. **Is the project paused?** Open the Supabase dashboard for this project. If it shows a paused/inactive state, this is almost certainly the cause after any quiet period (few active testers, low traffic). Fix: click restore/resume in the dashboard. This is the fastest check and the most likely cause — start here.
2. **Is the keep-warm workflow failing?** Check the Actions tab on `github.com/joostmouw/ridewindow` for the keep-warm cron job. A red/failing run history means the project may have been left unprotected against the 7-day pause even if it hasn't paused yet. Fix: re-run the workflow manually (this also serves as an immediate keep-alive) and investigate why it started failing.
3. **Usual auth/credential causes.** If the project is active and the keep-warm job is green, fall back to the ordinary causes: expired/rotated Supabase anon key, a mismatched OAuth client ID in Supabase's Google provider settings, or a device-side connectivity issue. These are the least likely explanation on a project that has otherwise been stable, which is why they come last, not first.

**Sync is now live (Phase 21).** Signed-in accounts sync `profiles`, `availability`, and `planned_rides` to this project via an offline outbox, with first-login migration handled by the `migrate_account_data()` RPC (see §4 above for the deletion counterpart, `delete_own_account()`). For the phase's real-device manual verification record — including the cold-start budget re-measurement, cross-device propagation, multi-tab safety, and the account-deletion proof — see `.planning/phases/21-sync-migration/REGRESSION-CHECKLIST-21.md` and `.planning/phases/21-sync-migration/MANUAL-VERIFICATION-21.md`.

## 4. Retention, deletion and export

**What actually triggers deletion.** A signed-in client cannot call `auth.admin.deleteUser()` directly — that admin API needs the service-role key, which never ships to the client. Instead, the app calls `supabase.rpc('delete_own_account')`, a `security definer` `plpgsql` function (`supabase/migrations/0001_accounts_sync.sql`) that derives the target row *only* from `auth.uid()` (never a client-supplied parameter, which would otherwise let a signed-in user delete someone else's account under `security definer` privilege) and runs `delete from auth.users where id = auth.uid()`. This is the real trigger AUTH-09 relies on — the mechanism below is what happens automatically once that row is gone, not an alternative to it.

**What deletion removes.** Deleting a user's account removes their rows immediately, via `on delete cascade` from `auth.users`. This applies to `profiles`, `availability`, and `planned_rides` (or the equivalent tables landed in Phase 21) — once the auth user is deleted, Postgres removes the dependent rows as part of the same operation, not on a delayed job.

**What survives, de-identified.** `feedback` rows are the one exception: they use `on delete set null`, so a deleted user's feedback rows survive with `user_id` set to `null`. The content of the feedback (score, weather inputs, tolerance settings at the time) is retained; the link back to the person is not. This must be stated plainly to anyone asking "is my data really gone" — the honest answer is "your rows are gone; your anonymised feedback text may remain."

**GDPR Article 20 export — manual process.** There is no in-app export button (deliberately deferred). To fulfil a request:
1. Confirm the requester's identity matches the account (their signed-in email).
2. In the Supabase dashboard's table editor or SQL editor, query the three tables (`profiles`, `availability`, `planned_rides`) filtered to that user's `auth.uid()`.
3. Export the result as JSON.
4. Send it to the requester.
5. **Deadline: within one month of the request**, per GDPR Article 20. Do not let this slip past 30 days — start the export the same week the request arrives.
