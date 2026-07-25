# Phase 17: Deployment Hardening & Firebase Hosting - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-17
**Phase:** 17-deployment-hardening-firebase-hosting
**Areas discussed:** None selected — user deferred to Claude's discretion

---

## Gray Areas Presented (not individually discussed)

| Area | Description | Selected |
|------|-------------|----------|
| Deploy-proces | Manual `firebase deploy` vs GitHub Actions CI/CD | |
| Domein | Keep `my-project-joost.web.app` vs custom domain | |
| Regressie-aanpak | Manual checklist vs automated test suite + smoke test | |
| Geen van deze | Trust Claude's discretion | ✓ |

**User's choice:** "Geen van deze — ik vertrouw op Claude's discretie" (None of these — I trust Claude's discretion)
**Notes:** User chose not to discuss any of the three presented gray areas and asked to proceed directly to research/planning.

---

## Claude's Discretion

All three presented gray areas were deferred to Claude's judgment and resolved in CONTEXT.md:
- Deploy process → continue manual `firebase deploy` (matches Phase 15 pattern, side-project pace)
- Domain → keep free `my-project-joost.web.app` URL (avoids re-registering OAuth origins)
- Regression method → automated test suite + manual real-device smoke test (mirrors Phase 16's PWA-05 verification bar)

## Deferred Ideas

- CI/CD (GitHub Actions auto-deploy) — noted for a future backlog item if deploy frequency increases
- Custom domain — noted for a future backlog item
