# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v2.0 — iOS Web App (PWA)

**Shipped:** 2026-07-17
**Phases:** 7 (Phases 11–17) | **Plans:** 11 | **Tasks:** 25

### What Was Built
- Flutter Web platform scaffolded (`flutter create --platforms web .`) reusing the entire existing Dart codebase with zero domain/UI code changes; native-only plugins (`workmanager`, `home_widget`) guarded behind `kIsWeb`
- Drift local persistence ported to web via `DriftWebOptions`/`sqlite3.wasm`, proven to survive full page reload
- Browser Geolocation API wired, with the manual city picker promoted to a primary (not rare-fallback) path for iOS Safari's per-session permission re-prompting
- Foreground refresh strategy (on-load, on-focus, pull-to-refresh, "Last updated" label, stale-data-with-offline-banner) replacing WorkManager, which has no web support
- Google Calendar "Add to calendar" working end-to-end on web via OAuth, verified on real iPhone Safari by two independent testers
- Full PWA installability polish: branded icons/splash, standalone-mode navigation with no dead ends, "Add to Home Screen" overlay, verified on a real iPhone
- Production deploy hardened: live at a stable Firebase Hosting HTTPS URL with curl-proven SPA routing and `sqlite3.wasm` headers, Android app confirmed unaffected by all web additions

### What Worked
- Reusing the v1.0 native Dart codebase with a platform-seam approach (swap Drift backend, geolocation, refresh trigger, OAuth client per platform) meant zero domain/UI rewrites — the "one codebase, two platforms" bet paid off exactly as planned
- Requiring real-device/real-browser manual verification (not just a successful build) caught real issues early — e.g. Phase 15's GoogleSignIn concurrency race was found via manual testing, not automated tests
- Treating "deployment hardening" as its own phase (17) rather than assuming Phase 15's preliminary deploy was production-ready surfaced no actual config gaps, but it did surface a stale, under-documented automated-test baseline that would have gone unnoticed otherwise

### What Was Inefficient
- REQUIREMENTS.md's traceability table drifted out of sync with actual phase completion across the whole milestone (Phases 11–14 and 17 all still showed "Pending" despite being shipped and dated Complete in ROADMAP.md) — this had to be manually reconciled against each phase's `requirements-completed` frontmatter at milestone close instead of being caught incrementally
- 11 quick-task backlog items were flagged by the pre-close audit tool as "missing" status despite each having a fully committed PLAN.md + SUMMARY.md — a tracking/audit-tool false positive that cost a verification pass to confirm was not real unfinished work

### Patterns Established
- `kIsWeb`-gated platform seams (persistence backend, refresh trigger, native-plugin guards) as the standard way to add a second platform to an existing Flutter codebase without touching domain/UI code
- Human-check verification items (browser click-through, physical-device smoke test) are explicitly allowed to remain PENDING after automated execution completes, rather than blocking the plan — the orchestrator hands them to the user directly afterward

### Key Lessons
1. When a phase's automated executor cannot perform browser or physical-device checks, have it clearly flag those as PENDING HUMAN VERIFICATION in SUMMARY.md with the exact test steps copied verbatim, rather than either faking completion or blocking the whole plan
2. Update REQUIREMENTS.md's traceability table as each phase completes, not just at milestone close — a full-milestone reconciliation pass is avoidable busywork
3. Audit-tool "missing" flags on quick tasks should be spot-checked against actual git history (PLAN.md/SUMMARY.md existence + commits) before assuming they represent real gaps

### Cost Observations
- Sessions: spanned 2026-07-11 → 2026-07-17 (6 days)
- Notable: Phase 17's fully-automated portion (build, deploy, curl-verify, test baseline, APK build) completed in ~25 min via a single worktree-isolated executor agent

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | multiple | 10 (1–10) | Initial native Android build-out |
| v2.0 | ~6 days | 7 (11–17) | Ported existing codebase to a second platform (Web/PWA) via platform-seam swaps instead of a rewrite; introduced explicit "pending human verification" handling for browser/device checks the executor can't perform itself |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v2.0 | 215 passing / 69 failing (13 files, pre-existing gap, tracked as BACKLOG #11) | not tracked | 0 (reused firebase-tools already installed in Phase 15) |

### Top Lessons (Verified Across Milestones)

1. Platform-seam architecture (swap the platform-coupled layer, keep domain/UI untouched) is the efficient way to add a second platform to an existing Flutter app — validated in v2.0
