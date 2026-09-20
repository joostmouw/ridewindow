---
phase: 27-wervingsonderzoek
plan: 01
subsystem: docs
tags: [recruitment, planning, wervingsonderzoek, testers]

# Dependency graph
requires: []
provides:
  - Sourced 8-row comparison of all 7 WERV-01-named recruitment channels plus r/TestersCommunity
  - Motivated 2-3 channel choice (eigen kring, fiets-Facebookgroep, r/AndroidClosedTesting as backstop), re-derived from the matrix under D-01/D-02/D-12
  - Explicit LinkedIn-out decision, answering success criterion 2
  - D-13/D-10/D-11 arithmetic (2 + 8 + 5 = 15) documented as the binding target for Phase 30
  - BACKLOG.md #76 — deferred LinkedIn launch post
affects: [27-02, 30-wervingsplan]

# Tech tracking
tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - .planning/phases/27-wervingsonderzoek/27-KANALEN.md
  modified:
    - .planning/BACKLOG.md

key-decisions:
  - "LinkedIn (post and vacature) excluded from the recruitment mix per D-01 — Joost posts only once the app is in production, which is after the closed test"
  - "Chosen mix in priority order (D-12): eigen kring (conversion) -> fiets-Facebookgroep -> r/AndroidClosedTesting as thresholded backstop"
  - "r/TestersCommunity evaluated but not chosen — a second reciprocal channel is redundant at a gap of 5, not the 20-35 opt-ins it was designed for"
  - "Target arithmetic restated: 2 opted-in + 8 conversions from own circle + ~5 external = 15"

requirements-completed: [WERV-01]

# Metrics
duration: 4min
completed: 2026-09-20
---

# Phase 27 Plan 1: Kanalenvergelijking Summary

**Sourced 8-row comparison of all 7 named recruitment channels plus r/TestersCommunity, re-deriving the D-12 mix (eigen kring -> fiets-Facebookgroep -> r/AndroidClosedTesting backstop) instead of copying 27-RESEARCH.md's superseded LinkedIn-first recommendation.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-09-20T11:12:19Z
- **Completed:** 2026-09-20T11:16:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Built `27-KANALEN.md` with a sourced, 8-row comparison table covering all 7 WERV-01-named channels (eigen LinkedIn-post, LinkedIn-vacature, Strava-clubs, NTFU-toerclubs, fiets-Facebookgroepen, collega's, r/AndroidClosedTesting) plus r/TestersCommunity, each with a filled Bron and Uitkomst cell
- Corrected the two rows RESEARCH.md got wrong before D-01/D-02/D-12 existed (LinkedIn-post's Uitkomst, and NTFU/fiets-Facebookgroepen's Doorlooptijd for "no warm contact")
- Derived the D-12 channel mix from the matrix (not copied from RESEARCH.md's now-superseded recommendation) and wrote the "Gekozen kanalen" section explicitly ruling LinkedIn out with D-01's reasoning
- Stated the D-13/D-10/D-11 arithmetic plainly (2 + 8 + 5 = 15) and explained why this replaces the withdrawn two-reciprocal-channel requirement
- Recorded the deferred LinkedIn launch post as BACKLOG.md #76, so it isn't lost

## Task Commits

Each task was committed atomically:

1. **Task 1: Build the sourced 8-row channel comparison table** - `2c73685` (docs)
2. **Task 2: Derive the D-12 channel mix and record the deferred LinkedIn launch post** - `bb95717` (docs)

**Plan metadata:** pending (docs: complete plan)

## Files Created/Modified
- `.planning/phases/27-wervingsonderzoek/27-KANALEN.md` - 8-row sourced channel comparison table + "Gekozen kanalen" section with the D-12 mix, LinkedIn-out reasoning, and the D-13/D-10/D-11 arithmetic
- `.planning/BACKLOG.md` - New #76 row: deferred LinkedIn launch post (post-production, D-01)

## Decisions Made
None new — this plan re-derives and documents decisions already made in `27-CONTEXT.md` (D-01, D-02, D-03 revised, D-04, D-09 through D-13). No architectural or scope decisions were made independently during execution.

## Deviations from Plan

None - plan executed exactly as written. Both tasks' automated verification checks passed on first run.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. This plan produces planning documents only.

## Next Phase Readiness

`27-KANALEN.md` and BACKLOG.md #76 are ready for `27-02-PLAN.md` (WERV-02: verzendklare teksten per gekozen kanaal, eerst als HTML getoond). The chosen mix (eigen kring, fiets-Facebookgroep, r/AndroidClosedTesting backstop) and the D-13/D-10/D-11 arithmetic are the concrete inputs plan 02 and Phase 30 need. Open item carried forward per D-08: the current self-promotion rules for r/AndroidClosedTesting must be manually re-verified immediately before drafting/posting that channel's text, since RESEARCH.md's Reddit data was not independently fetchable.

---
*Phase: 27-wervingsonderzoek*
*Completed: 2026-09-20*

## Self-Check: PASSED

- FOUND: `.planning/phases/27-wervingsonderzoek/27-KANALEN.md`
- FOUND: `.planning/phases/27-wervingsonderzoek/27-01-SUMMARY.md`
- FOUND: BACKLOG.md #76 row
- FOUND: commit `2c73685`
- FOUND: commit `bb95717`
