---
phase: 18-preconditions
plan: 02
subsystem: infra
tags: [privacy-policy, gdpr, supabase, github-pages, html]

# Dependency graph
requires:
  - phase: 18-preconditions (plan 01)
    provides: Supabase project provisioned in EU (Paris, eu-west-3), Google Cloud project reuse confirmed
provides:
  - Rewritten bilingual (NL/EN) privacy policy at the unchanged published URL, describing server-side storage, two named sub-processors, EU residency, deletion route, and GDPR rights
affects: [19-auth, 21-sync-migration]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Single self-contained HTML file with two full-language <section> blocks (lang=nl / lang=en) and a top anchor nav, no build step, served by GitHub Pages from docs/"]

key-files:
  created: []
  modified: [docs/privacy-policy.html]

key-decisions:
  - "Task 1 and Task 2 were committed together in a single commit — both modify the same file, and Task 2's deletion section builds directly on Task 1's rewritten structure (same headings, same language sections), so splitting the diff after the fact would not produce a meaningful separation"
  - "Used Paris/eu-west-3 (per 18-CONTEXT.md D-07, the actual provisioned region) rather than the Frankfurt reference in D-15's original wording — D-07 is the later, verified-in-dashboard decision and supersedes it"
  - "Deletion mailto: subject lines differ by language (verwijder mijn account / delete my account) but share the same mailto:joost@fanalists.com?subject= prefix, satisfying both language sections independently"

patterns-established:
  - "Bilingual legal/policy pages on this project: full parallel content per language inside anchored <section lang=\"..\"> blocks on one page, not separate pages or a machine translation of a shorter original"

requirements-completed: [PRE-03, PRE-05, PRE-06]

# Metrics
duration: 20min
completed: 2026-07-25
---

# Phase 18 Plan 02: Privacy Policy Rewrite Summary

**Rewrote docs/privacy-policy.html (NL+EN, same URL) to disclose server-side storage on Supabase (EU/Paris), name Google and Supabase as sub-processors alongside Open-Meteo, and add a `mailto:`-based account-deletion route usable after uninstalling the app.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-07-25T16:52:00Z
- **Completed:** 2026-07-25T17:12:04Z
- **Tasks:** 2 (committed together, see Deviations)
- **Files modified:** 1

## Accomplishments
- Removed all four now-false claims ("data stays on your device", "no account or login required", "no server-side storage of any user data", "no data shared with third parties") and the "uninstalling removes all data" line
- Added parallel Dutch and English sections on the same page (`#nl` / `#en`, `lang="nl"` / `lang="en"`, anchor nav at top) — both complete, neither a summary of the other
- Disclosed exactly what stays on-device (forecast cache, calendar-imported blocked hours) versus what is stored server-side only for signed-in users (profile settings, weekly availability, planned rides), in Supabase EU West (Paris, `eu-west-3`)
- Named three sub-processors with stated purpose each: Open-Meteo (forecast), Supabase (auth + database, EU), Google (Firebase Hosting, Calendar API, Sign-In)
- Added a deletion section with a stable HTML `id` in each language (`#verwijderen` / `#delete-account`) for a future Play Console deep link, a `mailto:` link with a pre-filled, language-specific subject line, and explicit statements of what is/isn't deleted, the one-month response window, and that de-identified feedback survives deletion
- Stated GDPR rights (access, portability, erasure) with the one-month response window in both languages
- Kept the file self-contained (no external stylesheets/fonts/scripts), same file path, contact address unchanged

## Task Commits

Both tasks were implemented as a single coherent rewrite of the same file and committed together:

1. **Task 1 + Task 2: Rewrite docs/privacy-policy.html (NL+EN) with server-side storage disclosure and deletion route** - `6f65f3c` (docs)

**Plan metadata:** (this commit, added after self-check)

## Files Created/Modified
- `docs/privacy-policy.html` - Full bilingual rewrite: server-side storage disclosure, three named sub-processors, EU residency (Paris/eu-west-3), GDPR rights, and account-deletion request route with stable anchor IDs

## Decisions Made
- Combined Task 1 and Task 2 into one commit — see `key-decisions` in frontmatter for rationale (same file, Task 2 builds on Task 1's structure)
- Used Paris/`eu-west-3` (the actually-provisioned region per plan 18-01/D-07) rather than the Frankfurt reference that appears in an earlier context note (D-15) — the later, dashboard-verified decision takes precedence and the plan's own `<interfaces>` table already specifies Paris

## Deviations from Plan

**1. [Process note, not a Rule 1-4 deviation] Tasks 1 and 2 committed together instead of as two separate commits**
- **Found during:** Task 2
- **Reason:** Both tasks modify the identical file (`docs/privacy-policy.html`), and the plan's own text for Task 2 ("as rewritten in Task 1") assumes Task 1's structure is already in place. The full rewrite was authored as one internally-consistent document to satisfy every acceptance criterion for both tasks at once; retroactively splitting the diff into two commits would require either reverting and redoing the work in two passes (introducing an intermediate, incomplete-looking state) or manufacturing an artificial split that doesn't reflect how the content was actually produced.
- **Impact:** All acceptance criteria for both Task 1 and Task 2 were verified independently against the final file (see Self-Check below) before committing. No functional impact — this affects only commit granularity, not correctness or scope.

None of Rules 1–4 were triggered — no bugs found, no missing critical functionality beyond what the plan specified, no blocking issues, no architectural changes.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required. Publishing/verifying the page is live at `https://joostmouw.github.io/ridewindow/privacy-policy.html` is explicitly out of scope for this plan (deferred to plan 18-04 per the plan's own `<verification>` section).

## Next Phase Readiness
- The privacy policy content is ready for plan 18-04's Play Store Data Safety declaration and live-URL verification work
- The deletion section's stable anchor IDs (`#verwijderen` / `#delete-account`) are ready to be referenced as a deep link from the Play Console Data Safety form
- No blockers for Phase 19 (Auth) or Phase 21 (Sync + migration), which this policy's disclosures anticipate

---
*Phase: 18-preconditions*
*Completed: 2026-07-25*

## Self-Check: PASSED

- FOUND: docs/privacy-policy.html
- FOUND: .planning/phases/18-preconditions/18-02-SUMMARY.md
- FOUND commit: 6f65f3c
- FOUND commit: cf75d40 (SUMMARY commit)
