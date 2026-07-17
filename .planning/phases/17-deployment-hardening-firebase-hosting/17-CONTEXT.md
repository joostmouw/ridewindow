# Phase 17: Deployment Hardening & Firebase Hosting - Context

**Gathered:** 2026-07-17
**Status:** Ready for planning

<domain>
## Phase Boundary

The Flutter web build is deployed to a stable, production Firebase Hosting URL with correct client-side routing (`go_router` deep links and page refresh don't 404) and correct asset headers (`sqlite3.wasm` served as `application/wasm`). The existing Android app remains fully unaffected — confirmed via a full regression pass after all web-platform additions (Phases 11–16). This phase does not add new user-facing features; it hardens and formalizes what Phase 15 already stood up preliminarily.

</domain>

<decisions>
## Implementation Decisions

### Deploy process
- **Claude's Discretion:** User explicitly deferred this to Claude's judgment. Continue with manual `firebase deploy` (the pattern already established in Phase 15-02) — no GitHub Actions CI/CD in this phase. This matches the project's side-project pace and "no ongoing infra costs" constraint from PROJECT.md; CI/CD adds maintenance surface with no clear payoff yet for a solo dev shipping infrequently. If the user wants automated deploys later, that's a new backlog item, not part of DEPLOY-01/02/03.

### Domain
- **Claude's Discretion:** User explicitly deferred this to Claude's judgment. Keep the free `https://my-project-joost.web.app` Firebase-provided URL as the stable production URL for DEPLOY-02 — no custom domain purchase/setup in this phase. This URL is already registered as an Authorized JavaScript origin on the Web OAuth client (Phase 15-02); introducing a custom domain here would require re-doing that OAuth origin registration and is out of scope for "hardening" the existing setup.

### Regression pass method (DEPLOY-03)
- **Claude's Discretion:** User explicitly deferred this to Claude's judgment. Combine both signals rather than picking one exclusively:
  1. Run the existing automated Flutter test suite as a baseline correctness check (fast, catches obvious breakage).
  2. Follow with a manual smoke-test checklist on a real Android device/emulator for `flutter build apk` + core flows (forecast, slots, availability, Calendar) — mirrors the real-device verification bar already set by PWA-05 in Phase 16. A test-suite pass alone is not sufficient per this project's established pattern of requiring manual verification for platform-level claims.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & requirements
- `.planning/ROADMAP.md` §"Phase 17: Deployment Hardening & Firebase Hosting" — phase goal, success criteria, requirements list (DEPLOY-01..03)
- `.planning/REQUIREMENTS.md` §DEPLOY-01 through DEPLOY-03 — exact requirement wording and traceability table

### Existing deployment scaffold (already in place, verify not recreate)
- `firebase.json` — already configures `build/web` as the Hosting public directory, `**` → `/index.html` rewrite rule, and a `**/*.wasm` → `Content-Type: application/wasm` header rule. Appears to already satisfy DEPLOY-01's literal requirement; the planner should verify this against a real deploy + direct-URL-load + page-refresh test rather than assume it's correct from the file alone.
- `.firebaserc` — `"default": "my-project-joost"` Firebase project already configured.
- `.planning/phases/15-google-calendar-web-integration/15-02-SUMMARY.md` and `15-02-PLAN.md` — record of the preliminary Phase 15 deploy (first-ever deploy in this repo, done to satisfy CAL-07's real-domain OAuth verification requirement). Explains why the hosting scaffold already exists and already has one production origin registered for Calendar OAuth.

### PWA assets (must be included in the final deploy)
- `.planning/phases/16-pwa-installability-ios-polish/` — Phase 16 (icons, splash, manifest, standalone navigation) shipped after the Phase 15 preliminary deploy. The Phase 17 deploy MUST include these changes — the currently-live `my-project-joost.web.app` build predates Phase 16 and does not yet reflect the branded PWA assets.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `firebase.json` / `.firebaserc` — hosting config and project binding already exist; this phase verifies/deploys against them rather than creating from scratch.
- Existing Flutter test suite (`test/`) — baseline regression signal for DEPLOY-03, per Claude's Discretion above.

### Established Patterns
- Manual `firebase deploy` from local machine (Phase 15-02) — no CI/CD exists in this repo; continuing this pattern per Claude's Discretion above.
- Real-device manual verification as the final proof bar for platform-level claims (Phase 16's PWA-05 real-iPhone verification) — same bar applied to DEPLOY-03's Android regression pass.

### Integration Points
- `firebase.json` — verify/extend if any gaps are found during a real deploy test (e.g., caching headers, additional MIME types).
- Local build pipeline: `flutter build web --release` (CanvasKit, per WEB-02 from Phase 11) then `firebase deploy`.
- `flutter build apk` — the Android regression build command, unchanged since v1.0.

</code_context>

<specifics>
## Specific Ideas

None beyond what's captured in Decisions — the user deferred all three gray areas (deploy process, domain, regression method) to Claude's discretion rather than specifying preferences.

</specifics>

<deferred>
## Deferred Ideas

- **CI/CD (GitHub Actions auto-deploy on push)** — considered and explicitly deferred, not part of this phase. Could be a future backlog item if deploy frequency increases.
- **Custom domain** — considered and explicitly deferred, not part of this phase. Would require re-registering OAuth authorized origins if added later.

### Reviewed Todos (not folded)
None — no pending todos matched this phase (`todo.match-phase 17` returned zero matches).

</deferred>

---

*Phase: 17-deployment-hardening-firebase-hosting*
*Context gathered: 2026-07-17*
