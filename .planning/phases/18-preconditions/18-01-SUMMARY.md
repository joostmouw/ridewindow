---
phase: 18-preconditions
plan: 01
subsystem: infra
tags: [supabase, gdpr, google-oauth, documentation, requirements]

# Dependency graph
requires: []
provides:
  - "CLAUDE.md and PROJECT.md constraints rewritten to reflect Supabase Auth + Postgres, an explicit EUR 0/month spend ceiling, and EU-resident server-side storage for signed-in users"
  - "docs/ACCOUNTS-OPERATIONS.md — the operational reference for the two Google user caps, the free-tier pause tripwire, a support runbook, and the retention/export answer"
  - "OAUTH-PUBLISH-CHECKLIST.md corrected in place so it no longer teaches the false '100-user cap is gone after publishing' claim"
  - "PRE-08 reworded from a billing alert to the pause tripwire that actually applies on a free plan"
affects: [19-auth, 20-repository-refactor, 21-sync-migration, 22-account-backed-feedback]

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - docs/ACCOUNTS-OPERATIONS.md
  modified:
    - CLAUDE.md
    - .planning/PROJECT.md
    - .planning/REQUIREMENTS.md
    - .planning/quick/260717-no1-backlog-31-google-oauth-consent-screen-p/OAUTH-PUBLISH-CHECKLIST.md

key-decisions:
  - "CLAUDE.md's stack table gained supabase_flutter 2.16.0 as documentation only — pubspec.yaml is untouched, per this plan's scope fence (Phase 19 adds the dependency)"
  - "OAUTH-PUBLISH-CHECKLIST.md was corrected in place rather than deleted or rewritten wholesale — it remains the accurate historical record of the 2026-07-17 publish, with one line corrected and a dated note added"

patterns-established: []

requirements-completed: [PRE-01, PRE-07, PRE-08, PRE-09]

# Metrics
duration: ~25min
completed: 2026-07-25
---

# Phase 18 Plan 01: Preconditions — Constraints, Caps, Tripwire, Retention Summary

**Rewrote CLAUDE.md/PROJECT.md's three broken constraints for Supabase, wrote docs/ACCOUNTS-OPERATIONS.md as the operational reference for the two Google caps and the free-tier pause runbook, corrected a false cap claim in OAUTH-PUBLISH-CHECKLIST.md, and reworded PRE-08 from a billing alert to a pause tripwire.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-07-25T16:40:00Z
- **Completed:** 2026-07-25T17:07:00Z
- **Tasks:** 4
- **Files modified:** 5 (1 created, 4 modified)

## Accomplishments
- CLAUDE.md and `.planning/PROJECT.md` no longer claim "no backend", "no ongoing infra costs", or "data never leaves device" as current fact — all three constraints now state what is actually true from v3.0 onward, with the ⚠️ transitional markers in PROJECT.md removed
- `docs/ACCOUNTS-OPERATIONS.md` created as the four-section operational reference support-triaging a live problem needs: the two-caps distinction, the free-tier cost, a prioritized runbook, and the retention/export answer
- `OAUTH-PUBLISH-CHECKLIST.md`'s false "no 100-user cap applies anymore" claim corrected in place, with a dated historical-record note pointing to the new operational doc
- `REQUIREMENTS.md`'s PRE-08 rewritten from an unsatisfiable billing-alert ask to the pause tripwire that actually protects a free-tier project, with a one-line note explaining the rewording so the traceability table isn't silently redefined

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite the three broken constraints in CLAUDE.md and PROJECT.md (PRE-01)** - `621c94b` (docs)
2. **Task 2: Write docs/ACCOUNTS-OPERATIONS.md — the two caps, the pause tripwire, retention and export (PRE-07, PRE-08, PRE-09)** - `b6b32c9` (docs)
3. **Task 3: Correct the false cap claim in OAUTH-PUBLISH-CHECKLIST.md (PRE-07)** - `191d14f` (docs)
4. **Task 4: Reword PRE-08 in REQUIREMENTS.md from billing alert to pause tripwire (PRE-08)** - `fa7ee0e` (docs)

_Note: this plan is documentation-only; no test or feat commits apply._

## Files Created/Modified
- `docs/ACCOUNTS-OPERATIONS.md` - New operational doc: two Google caps, free-tier cost, "sync stopped working" runbook, retention/export
- `CLAUDE.md` - Three constraints rewritten (No backend, Budget, Privacy); `supabase_flutter` added to the stack table
- `.planning/PROJECT.md` - Matching three constraints rewritten; ⚠️ transitional markers removed
- `.planning/REQUIREMENTS.md` - PRE-08 reworded from billing alert to pause tripwire
- `.planning/quick/260717-no1-backlog-31-google-oauth-consent-screen-p/OAUTH-PUBLISH-CHECKLIST.md` - False cap claim corrected; dated historical note added at top

## Decisions Made
- Followed the plan's interface facts exactly (Supabase project region/URL, Google Cloud project details, the two-caps wording, retention answer) rather than re-deriving anything — these were supplied as confirmed facts in the plan's `<interfaces>` block.
- Kept `OAUTH-PUBLISH-CHECKLIST.md`'s original §1–§4 and checkbox states untouched, correcting only the one false line plus a top-of-file historical note, per the plan's explicit instruction not to restructure or re-tick history.

## Deviations from Plan

None — plan executed exactly as written. One in-flight self-correction: the first draft of the OAUTH-PUBLISH-CHECKLIST.md correction note quoted the exact false phrase ("no 100-user cap applies anymore") for clarity, which would have failed the task's own acceptance grep (`returns 0`). Reworded to describe the error without repeating the literal string, verified against all Task 3 acceptance criteria before committing — not logged as a Rule 1-3 deviation since it never left a bad state committed.

## Issues Encountered

`flutter analyze` exits 1 in this worktree due to 21 pre-existing warnings / 134 pre-existing info-level lints (0 errors) — none introduced by this plan, which touched zero Dart/test files. This matches the pre-existing gap documented in `.planning/STATE.md` (BACKLOG.md #11). The plan's verification line ("flutter analyze still exits 0") does not hold as a literal exit-code check on this codebase's current baseline, but the intent — no regression from this plan's changes — is satisfied since no source file was touched.

One verification nuance: `grep -r "no 100-user cap applies anymore" .planning/` still matches `.planning/phases/18-preconditions/18-01-PLAN.md` and `18-CONTEXT.md` themselves, since those planning documents quote the false phrase while describing the correction task. The actual target file, `OAUTH-PUBLISH-CHECKLIST.md`, is clean (0 matches, verified directly). This is expected — the plan-level grep instruction is a codebase sweep that happens to also match its own task description, not a sign of unfinished work.

## User Setup Required

None — no external service configuration required. This plan is documentation-only, per its scope fence (no `pubspec.yaml`, no `lib/`, no `supabase/` changes).

## Next Phase Readiness

- PRE-01, PRE-07, PRE-08, PRE-09 requirements satisfied by this plan's written artifacts.
- Remaining Phase 18 requirements (PRE-02 through PRE-06 — Supabase project creation/verification, DPA, OAuth credential registration, privacy policy rewrite, Data Safety declaration) are console-driven work covered by this phase's other plans (18-02, 18-03, and the user's manual checklist per D-19/D-20 in `18-CONTEXT.md`).
- No blockers for Phase 19 (Auth) from this plan's output — the constraint rewrites and operational doc are ready to be referenced by future sessions so nobody re-derives the "no backend" assumption.

---
*Phase: 18-preconditions*
*Completed: 2026-07-25*

## Self-Check: PASSED

- FOUND: docs/ACCOUNTS-OPERATIONS.md
- FOUND: .planning/phases/18-preconditions/18-01-SUMMARY.md
- FOUND commit: 621c94b (Task 1)
- FOUND commit: b6b32c9 (Task 2)
- FOUND commit: 191d14f (Task 3)
- FOUND commit: fa7ee0e (Task 4)
- FOUND commit: 167350e (SUMMARY.md)
