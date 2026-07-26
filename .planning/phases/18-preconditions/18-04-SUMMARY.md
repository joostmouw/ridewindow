---
phase: 18-preconditions
plan: 04
subsystem: infra
tags: [oauth, cloud-console, play-console, supabase, data-safety, gdpr]

# Dependency graph
requires:
  - phase: 18-preconditions (plan 01)
    provides: docs/ACCOUNTS-OPERATIONS.md — the two Google caps, pause tripwire, retention/export
  - phase: 18-preconditions (plan 02)
    provides: Rewritten privacy policy with stable #verwijderen / #delete-account anchors
provides:
  - Two Android OAuth clients carrying both SHA-1 fingerprints, read back from the console
  - Supabase Google provider enabled with the web client ID, read back after reload
  - Supabase callback URL registered as an authorized redirect URI on the web client
  - Play Store Data Safety declaration rewritten for accounts and server-side storage, submitted for review
  - docs/CONSOLE-SETUP-CHECKLIST.md — what was registered where, plus ten findings
affects: [19-auth, 21-sync-migration]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Console registrations are recorded with the value observed on screen, not the value intended — every entry in the checklist was read back after saving"]

key-files:
  created: [docs/CONSOLE-SETUP-CHECKLIST.md]
  modified: [.planning/BACKLOG.md]

key-decisions:
  - "Two Android OAuth clients rather than one: Google's Android client form holds exactly one SHA-1, so both fingerprints require two clients sharing the package name. Named by which key they carry so the Play App Signing one is never mistaken for the upload key again."
  - "Nothing declared as 'Shared' in Data Safety. Google exempts transfers to a service provider processing on the developer's behalf, and the published privacy policy already frames Open-Meteo, Supabase and Google as processors. The listing now reads 'No data shared with third parties', consistent with the policy."
  - "Calendar not declared as a collected data type — the published policy states calendar-imported blocked hours never leave the device. Plan 18-04's instruction to declare 'calendar-derived availability ... stored on servers' contradicted it and was overruled in the policy's favour (F-7)."
  - "All data types declared optional, because signing in is optional and location has a manual override."
  - "Precise location not declared: the code requests LocationAccuracy.reduced."
  - "Supabase callback URL registered on the web client although outside plan scope — the live PWA that iOS testers use cannot sign in without it, and the cost was one line now versus a debugging session in Phase 21 (F-5)."
---

## What was done

Console work across Cloud Console, Supabase and Play Console, driven interactively in the user's own authenticated browser session. Every registration was read back from the console after saving; nothing here is recorded from intent.

**Supabase (PRE-02, PRE-03).** Region confirmed on the dashboard as West EU (Paris) `eu-west-3`. The DPA was found to be available on the free tier — it is not plan-gated, unlike SOC2 and ISO 27001 on the same page — and requested on the organization, to be signed by Joost Mouw as a natural person, notifications to `joostmouw@gmail.com`, document version `Template Supabase Customer DPA (June 1)`.

**Cloud Console (PRE-04).** The project had exactly one OAuth client before this phase (`RideWindow Web`), confirming the long-standing suspicion in `PROJECT.md` that the Android client was never created. Two Android clients were created for package `ridewindow.joost.amsterdam`, one per fingerprint, and both SHA-1 values were compared character by character against source after reopening each client page. The PWA origin turned out to be already registered. The consent screen was verified as genuinely "In production" (User type External), closing a gap the historical `OAUTH-PUBLISH-CHECKLIST.md` left unticked, and the OAuth user cap counter was observed at **3 of 100**.

**Data Safety (PRE-06).** The previous declaration from 21 June had become incomplete — Google added sub-questions on encryption in transit and account-creation method that the old submission did not answer. The questionnaire was completed for the accounts-era app: OAuth account creation, encrypted in transit, deletion URL pointing at the policy anchor added in plan 18-02, five data types configured individually. Verified as submitted in Publishing overview ("Changes in review", managed publishing off), not merely saved.

## Deviations

**Scope, agreed with the user before acting:** the Supabase callback URL was added as an authorized redirect URI on the web OAuth client. Not in the plan; justified in F-5.

**Instruction overruled:** the plan's Data Safety wording about calendar-derived data contradicted the published privacy policy. Recorded as F-7 and resolved in the policy's favour.

**Timing judgment surfaced to the user:** the declaration now describes account creation and server-side storage, which the shipped app does not yet do. The alternative — declaring at the moment accounts ship — was presented; the user chose to follow the plan. The safer failure mode, but it means the Store listing is stricter than current behaviour until Phase 19+ lands.

## Incomplete

**PRE-08 is partially met.** The keep-warm workflow from plan 18-03 exists but cannot run until the repository variable `SUPABASE_URL` and secret `SUPABASE_ANON_KEY` are set in GitHub. Until then every run fails at the guard step — loudly and by design, but the project is not yet protected against the 7-day pause.

**Correction on PRE-03.** An earlier reading of the DPA PDF concluded it was an unsigned template, based on its text layer showing blank signature ruling. That was wrong: the document is cryptographically signed (`/FT/Sig` with a non-empty `/V`, `/Filter/Adobe.PPKLite`, `/ByteRange` present, signing time `D:20260726054529Z`, produced by PandaDoc). PRE-03 is met. The lesson is recorded in F-4 — verify PDF signatures through the document structure, not the extracted text.

## Findings for later phases

Ten findings are recorded in `docs/CONSOLE-SETUP-CHECKLIST.md`. The three that need action outside this phase:

- **F-8** — the in-app privacy policy link in `profile_screen.dart:35` returns HTTP 404. User-visible today, one-line fix.
- **F-6** — Supabase's Client IDs field holds only the web client ID; whether that is correct depends on how `google_sign_in` is configured in Phase 21. Decide it rather than debug it.
- **F-9** — `ACCESS_FINE_LOCATION` is declared in the manifest but the code requests `LocationAccuracy.reduced`.

## Self-Check: PASSED

- FOUND: docs/CONSOLE-SETUP-CHECKLIST.md
- FOUND: both SHA-1 fingerprints recorded, labelled by key
- FOUND: web client ID and authorized origin recorded
- CONFIRMED: no anon key, service role key or keystore password in the file
- CONFIRMED: links to docs/ACCOUNTS-OPERATIONS.md
- CONFIRMED: Data Safety submission verified in Publishing overview, not assumed
- OPEN: PRE-03 (DPA execution) — recorded as blocked with reason, not ticked
