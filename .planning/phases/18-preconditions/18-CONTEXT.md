# Phase 18: Preconditions - Context

**Gathered:** 2026-07-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Every release-blocking legal and infrastructure decision for shipping accounts is made and **verified** before any cloud code lands. No app code, no packages added, no `pubspec.yaml` change.

Two of the decisions in this phase are effectively irreversible (Supabase project region) or have already cost this project a broken shipped feature once (SHA-1 registration). That is why this phase exists separately rather than being folded into Phase 19.

Delivers: a provisioned Supabase project, registered OAuth credentials, a rewritten privacy policy, an updated Play Data Safety declaration, a keep-warm job, and four written-down answers (constraints, cap distinction, pause tripwire, retention/export).

Explicitly NOT in this phase: `supabase_flutter`, sign-in, schema, RLS policies, the in-app delete button. All of those are Phases 19–21.

</domain>

<decisions>
## Implementation Decisions

### Hosting tier and cost (PRE-01, PRE-08)
- **D-01:** **Free tier. No Pro subscription.** User decision, stated directly: "Ik wil een gratis account" and "zo gratis en makkelijk mogelijk."
- **D-02:** PRE-01's spend ceiling is therefore **€0/month ongoing**. The one-time €25 Play Developer account remains the only spend. Exceeding €0 is a conscious future decision, not a drift.
- **D-03:** Free-tier caps (500 MB Postgres, 50k MAU) are not a practical constraint at this scale and need no monitoring. **The binding constraint is availability, not capacity.**
- **D-04:** **Accept the 7-day inactivity pause, but mitigate it** with a scheduled job that makes one API request every 3 days. Implement as a GitHub Actions cron in the existing `joostmouw/ridewindow` repo — there are no workflows there yet, so this is the first one. Roughly ten lines of YAML, no cost.
- **D-05:** **PRE-08 as written is now wrong and must be reworded during this phase.** It asks for a billing alert; on a free plan there is nothing to bill and nothing to alert on. Its real content becomes: (a) the keep-warm job exists, (b) Supabase's pause-warning email goes to an address that is actually read, (c) a written note on how to recognise and fix "sync stopped working" — restore is manual, from the dashboard.
- **D-06:** **Accepted risk, recorded rather than solved: the free tier has no automated backups.** If the hosted database is lost there is no restore point. Blast radius is limited because the device keeps its own copy and local storage remains the source of truth by design (see `ARCHITECTURE.md` §2/§4a) — but this is a real regression versus the Firebase plan and belongs in PRE-01's rewritten constraint text, not left implicit.

### Region and Cloud project (PRE-02, PRE-04)
- **D-07:** ~~Frankfurt~~ → **PRE-02 IS DONE.** Project provisioned 2026-07-25 in **West EU (Paris), `eu-west-3`**, compute NANO, status Healthy, org tier FREE. Paris was on the approved EU-proper list (Frankfurt / Ireland / Paris / Stockholm); the latency difference from NL is negligible, so this stands as-is and is not to be redone. Project URL: `https://hcdrydlgqpnmumfupgcx.supabase.co`. Verified by looking at the dashboard, per D-09.
- **D-07a:** The dashboard also confirms **"Last backup: No backups"** — D-06's accepted risk is now observed fact, not a prediction.
- **D-07b:** Project display name is currently "joostmouw's Project" under the "RideWindow" org. Cosmetic only; rename is optional and blocks nothing.
- **D-08:** Reuse the existing **`my-project-joost`** Google Cloud project rather than creating a new one. Sharing the OAuth consent screen with the Calendar integration is the entire mechanism behind AUTH-05; a separate project would defeat it. Confirmed state from `.planning/quick/260717-no1-.../OAUTH-PUBLISH-CHECKLIST.md`: consent screen is **In production**, sole scope is `calendar.events`, authorized domain is `joostmouw.github.io`.
- **D-08a:** The privacy policy URL is already fixed and registered on that consent screen: **`https://joostmouw.github.io/ridewindow/privacy-policy.html`**. PRE-05 rewrites *this* page and PRE-06's deletion route goes on *this* page (D-10/D-12). No new hosting, no URL change — changing it would mean re-editing the consent screen.
- **D-08b:** **`OAUTH-PUBLISH-CHECKLIST.md` line 47 is wrong and must be corrected as part of PRE-07.** It instructs the reader to "Confirm no 100-user cap applies anymore" after publishing. The cap is tied to *verification* status, not *publish* status, so "In production" does not remove it — `.planning/PROJECT.md` already records the correction. Leaving a document in the repo that makes exactly the error PRE-07 exists to prevent defeats the requirement. Either annotate that file or supersede it from the PRE-07 writeup, and link the two.
- **D-09:** Verification is by **looking at the console**, not by assuming from the signup flow. This applies to the region especially — it cannot be changed afterwards.

### Account deletion route (PRE-06)
- **D-10:** Phase 18 delivers a **deletion-request route on the existing hosted privacy policy page** — an email address with a fixed subject line is sufficient at this scale. No web form to build, no backend.
- **D-11:** The **in-app delete button stays in Phase 21** (AUTH-09), where there is actually data to delete. Splitting it this way means Phase 18 satisfies Google's "must work even after uninstall" expectation without blocking on code.
- **D-12:** The deletion URL declared in the Data Safety form is this privacy-policy section.

### Privacy policy (PRE-05, PRE-03)
- **D-13:** **Dutch and English, on one page**, at the existing hosted URL. Rationale weighed explicitly: testers are Dutch, but the Play reviewer reads English — dropping English is the only genuinely risky cut. Maintaining both costs the user nothing because Claude writes it, and the document changes roughly once a year.
- **D-14:** Claude drafts the text. **Stated limitation, accepted by the user: this is a legal document and Claude is not a lawyer.** At this scale (a few dozen testers, non-commercial) a carefully self-written policy is normal practice, and the residual risk is the user's.
- **D-15:** The policy must name **two sub-processors, not one** — Supabase (auth, database, Frankfurt) *and* Google (Firebase Hosting, Calendar). The Firebase relationship is not replaced by this milestone, it is added to. This is a change from the Firebase-era plan, where there was only one.

### Retention and export (PRE-09)
- **D-16:** Account deletion removes the user's rows **immediately**, via `on delete cascade` from `auth.users` (schema detail lands in Phase 21; the *answer* is fixed here).
- **D-17:** Feedback rows **survive deletion but are de-identified** (`user_id` set to null, per `on delete set null`). The policy text must say this explicitly — it is the one place where something outlives the account.
- **D-18:** GDPR Article 20 export is a **documented manual process**: query the three tables from the Supabase dashboard, export JSON, send within one month. The in-app export button remains deferred (already recorded in REQUIREMENTS.md "Future Requirements").

### Work split — the phase's actual shape
- **D-19:** The plan should be organised around **who can do each task**, because most of this phase is console clicking that Claude cannot do:
  - **Claude can do:** privacy policy text (NL+EN), the constraint rewrite in `CLAUDE.md` and `PROJECT.md` (PRE-01), the Auth-cap-vs-Calendar-cap writeup (PRE-07), the retention/export writeup (PRE-09), the keep-warm GitHub Actions workflow (D-04), and the PRE-08 rewording (D-05).
  - **Only the user can do:** create the Supabase project in Frankfurt, accept the DPA, register both SHA-1 fingerprints in Cloud Console, add the PWA origin to the web OAuth client, paste the web client ID into Supabase's Google provider settings, publish the privacy policy, and submit the Data Safety form.
- **D-20:** Planning should keep these two stacks as separate plans so the user's manual work is one short, ordered checklist rather than scattered through Claude's tasks.

### Claude's Discretion
- Exact wording of the privacy policy, the constraint rewrites, and the PRE-07/PRE-09 writeups.
- The keep-warm workflow's schedule, endpoint, and secret handling (the anon key is public by design, so a repo secret is tidiness rather than security).
- How the manual checklist is formatted and ordered.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and scope
- `.planning/REQUIREMENTS.md` — PRE-01…PRE-09 are this phase's requirements. Note PRE-08's text is superseded by D-05 above and must be rewritten *as part of this phase*.
- `.planning/ROADMAP.md` §"Phase 18: Preconditions" — goal and the five success criteria.
- `.planning/milestones/v3.0-ACCOUNTS.md` — milestone scope; §"Stackstatus" records the Supabase decision and §"Hosting blijft Firebase" the two-sub-processor consequence.

### Stack research (Supabase — read these, not the archive)
- `.planning/research/SUMMARY.md` — synthesis; §0-equivalent "Executive Summary" carries the Firebase→Supabase rationale.
- `.planning/research/ARCHITECTURE.md` §0 — the stack decision record. §3 — the schema this phase's region/DPA choices will host.
- `.planning/research/PITFALLS.md` **#3** (three OAuth client IDs, two SHA-1s), **#4** (the 100-user cap distinction → PRE-07), **#8** (free-tier pausing, alerts ≠ caps → PRE-01/PRE-08), **#9** (the GDPR checklist → PRE-02/03/05/06/09). These four are this phase's substance.
- `.planning/research/archive-firebase/` — **superseded. Do not plan from these.** Retained only for the decision trail.

### Project constraints being rewritten (PRE-01)
- `CLAUDE.md` §Constraints — "No backend", "Budget", "Privacy" are the three lines this phase edits.
- `.planning/PROJECT.md` §Constraints — same three, already marked ⚠️ with a pointer to PRE-01.

### Existing production surfaces this phase touches
- `.planning/BACKLOG.md` — check before adding anything new; the deletion route may already have an entry.
- `https://joostmouw.github.io/ridewindow/privacy-policy.html` — the live policy page. Rewritten by PRE-05; carries PRE-06's deletion route. Registered on the OAuth consent screen, so the URL must not change.
- `.planning/quick/260717-no1-backlog-31-google-oauth-consent-screen-p/OAUTH-PUBLISH-CHECKLIST.md` — prior OAuth work. Source of truth for the consent-screen state, **but its line 47 states the 100-user cap is gone after publishing, which is false.** PRE-07 must correct or supersede it (D-08b).
- `.planning/PROJECT.md` §Current State — already carries the correct version of the cap nuance; use that wording as the basis for PRE-07 rather than rewriting from scratch.
- The Play Console listing (see `.planning/STATE.md` §Project Reference for app ID and version).

</canonical_refs>

<code_context>
## Existing Code Insights

This phase writes no app code. The code facts below matter only because they constrain the *console* setup.

### Integration points that dictate the credential setup
- `lib/services/calendar_service.dart:36` — `GoogleSignIn.instance.initialize()` is currently called **with no arguments**. Phase 19 must add `serverClientId`, which is why the web client ID has to be registered in Supabase during *this* phase. The credential work here is what unblocks that.
- `lib/services/calendar_service.dart:33-44` — the memoized `_sharedInitialize()`/`_initFuture` gate. Nothing in Phase 18 touches it, but it is the reason `my-project-joost` must be reused (D-08).
- `pubspec.yaml:49-51` — `google_sign_in ^7.2.0`, `extension_google_sign_in_as_googleapis_auth ^3.0.0`, `googleapis ^16.0.0`. Unchanged by this phase; listed so the planner does not add `supabase_flutter` early.

### Established patterns
- The existing Calendar OAuth setup already proves the shape of this work: a Cloud Console client, a consent screen, and a fingerprint that must match the *signing* key rather than the debug key. Phase 18 repeats that pattern for sign-in.

### Repo facts relevant to D-04
- Remote is `https://github.com/joostmouw/ridewindow.git`; `.github/workflows/` does not exist yet. The keep-warm cron will be the first workflow in this repo.

</code_context>

<specifics>
## Specific Ideas

- User's framing, verbatim: **"Ik wil gratis en makkelijk mogelijk."** Read this as a standing preference for the whole milestone, not just this phase — prefer the option with fewer moving parts and no recurring cost, and say so when a cheaper option carries a real risk (as with the missing backups, D-06).
- The user asked mid-discussion "Waar gaat dit over?" about the phase itself. Plans and summaries for this phase should explain *why* a step exists in plain language, not only *what* to do — especially for the console steps, which are the ones that look like bureaucracy and are actually the irreversible ones.

</specifics>

<deferred>
## Deferred Ideas

- **In-app "Delete account" button** — Phase 21, AUTH-09. Phase 18 ships only the request route (D-11).
- **In-app JSON data export** — already deferred in REQUIREMENTS.md "Future Requirements"; PRE-09 is satisfied by the manual process (D-18).
- **Calendar-scope grant counter** — no Google-side alert exists before the 100-user cap; explicitly deferred in REQUIREMENTS.md. PRE-07 documents the distinction only, it does not build tracking.
- **Paid Supabase Pro / automated backups** — declined for now (D-01, D-06). Revisit only if the app leaves the tester stage.

</deferred>

---

*Phase: 18-Preconditions*
*Context gathered: 2026-07-25*
