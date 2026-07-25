# Roadmap: RideWindow

## Overview

RideWindow builds from the inside out: a pure-Dart scoring engine with 100% unit tests, layered with a Drift + Open-Meteo data stack, wired via a Riverpod provider graph, and finally surfaced across six screens (Welcome, Onboarding, Home, Ride Detail, Profile, Availability). v1.0 shipped this as a native Android app (Play Store, internal testing track). v2.0 ports the same Dart codebase to Flutter Web/PWA to reach iOS users without an Apple Developer account — swapping platform-coupled seams (Drift storage backend, geolocation, background refresh, Calendar OAuth) while keeping domain/UI code untouched, then hardening for iOS Safari's PWA quirks and deploying to Firebase Hosting.

## Milestones

- ✅ **v1.0 Android App** - Phases 1–10 (shipped, Internal testing track live)
- ✅ **v2.0 iOS Web App (PWA)** - Phases 11–17 (shipped 2026-07-17) — see `.planning/milestones/v2.0-ROADMAP.md`
- 📋 **v3.0 Accounts & Sociaal** - gepland, nog niet ingepland — zie `.planning/milestones/v3.0-ACCOUNTS.md`

## Phases

**Phase Numbering:**

- Integer phases: Planned milestone work, numbered continuously across milestones (never restarts)
- Decimal phases (e.g., 1.5, 11.1): Urgent insertions between integers

<details>
<summary>✅ v1.0 Android App (Phases 1–10) - SHIPPED</summary>

- [x] **Phase 1: Project skeleton + test infrastructure** - Flutter project boots, locked deps, canonical lib/ tree, structural test enforcing pure-Dart domain boundary
- [x] **Phase 1.5: Scoring domain — Freezed models + ScoringEngine + SlotGenerator** - Pure-Dart domain code with 100% unit test coverage of lib/domain/
- [x] **Phase 2: Data layer — Drift + Open-Meteo** - Drift schema, OpenMeteoClient, WeatherRepository, forecast cache
- [x] **Phase 3: Riverpod providers + state graph** - Full provider graph with ProviderContainer tests and reactive recomputation
- [x] **Phase 4: UI Phase A — Onboarding + Home + Welcome** - Welcome, Onboarding (4 presets), Home (week strip + ride cards)
- [x] **Phase 5: UI Phase B — Ride Detail + Insights sheet** - Ride Detail screen + "Why this score?" insights bottom sheet
- [x] **Phase 6: UI Phase C — Profile + Availability + Tolerance sliders** - Profile screen, availability calendar, tolerance sliders, ride-length chips
- [x] **Phase 7: Location — GPS + manual city + permission state machine** - geolocator, permission_handler, city picker fallback
- [x] **Phase 8: Background refresh + Notifications** - WorkManager, flutter_local_notifications, 3 notification types
- [x] **Phase 9: Google Calendar integration** - Lazy OAuth, AutoRefreshingAuthClient, calendar.events scope
- [x] **Phase 10: Release — Internal track only** - Signed AAB, Play App Signing, privacy policy, Data Safety form, Internal testing track

</details>

<details>
<summary>✅ v2.0 iOS Web App (PWA) (Phases 11–17) - SHIPPED 2026-07-17</summary>

**Milestone Goal:** Reach iOS users cheaply via a Flutter Web/PWA build of RideWindow, deployed to Firebase Hosting, without an Apple Developer account.

- [x] **Phase 11: Web Scaffolding & Build Baseline** - `web/` platform added, `flutter build web --release` (CanvasKit) works, existing UI renders/navigates with zero domain code changes, native-only plugins guarded
- [x] **Phase 12: Drift Web Persistence** - Drift's IndexedDB/wasm web backend wired and proven to survive page reload
- [x] **Phase 13: Geolocation & Manual Fallback** - Browser Geolocation API wired; manual city picker promoted to primary fallback for iOS Safari's per-session re-prompting
- [x] **Phase 14: Foreground Refresh Strategy** - On-load/on-focus/pull-to-refresh replaces WorkManager; "Last updated" label; stale-data fallback UI
- [x] **Phase 15: Google Calendar Web Integration** - Web OAuth client ID, popup-safe sign-in, "Add to calendar" verified end-to-end on the deployed domain
- [x] **Phase 16: PWA Installability & iOS Polish** - iOS meta tags, Add to Home Screen overlay, standalone-mode navigation, real-iPhone verification of install + storage durability
- [x] **Phase 17: Deployment Hardening & Firebase Hosting** - `firebase.json` routing/headers, production deploy, full Android + web regression pass

Full phase details, plans, and decisions: `.planning/milestones/v2.0-ROADMAP.md`. Requirements: `.planning/milestones/v2.0-REQUIREMENTS.md`.

</details>

## Phase Details

Full phase-by-phase detail (goals, success criteria, plans) for both shipped milestones lives in their archive files:
- v1.0 Android App: see git history of this file prior to 2026-07-17 (archived inline, not yet split to a separate milestones file)
- v2.0 iOS Web App (PWA): `.planning/milestones/v2.0-ROADMAP.md`

This project has no active/planned milestone yet — run `/gsd:new-milestone` to scope v2.1+.

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 1.5 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Project skeleton + test infrastructure | v1.0 | 3/3 | Complete | 2026-06-02 |
| 1.5. Scoring domain — Freezed models + ScoringEngine + SlotGenerator | v1.0 | 0/TBD | Not started | - |
| 2. Data layer — Drift + Open-Meteo | v1.0 | 3/3 | Complete | 2026-06-02 |
| 3. Riverpod providers + state graph | v1.0 | 4/4 | Complete | 2026-06-03 |
| 4. UI Phase A — Onboarding + Home + Welcome | v1.0 | 0/5 | Not started | - |
| 5. UI Phase B — Ride Detail + Insights sheet | v1.0 | 0/TBD | Not started | - |
| 6. UI Phase C — Profile + Availability + Tolerance sliders | v1.0 | 0/TBD | Not started | - |
| 7. Location — GPS + manual city + permission state machine | v1.0 | 0/TBD | Not started | - |
| 8. Background refresh + Notifications | v1.0 | 0/TBD | Not started | - |
| 9. Google Calendar integration | v1.0 | 0/TBD | Not started | - |
| 10. Release — Internal track only | v1.0 | 0/TBD | Not started | - |
| 11. Web Scaffolding & Build Baseline | v2.0 | 1/1 | Complete   | 2026-07-11 |
| 12. Drift Web Persistence | v2.0 | 1/1 | Complete   | 2026-07-11 |
| 13. Geolocation & Manual Fallback | v2.0 | 1/1 | Complete   | 2026-07-11 |
| 14. Foreground Refresh Strategy | v2.0 | 1/1 | Complete   | 2026-07-12 |
| 15. Google Calendar Web Integration | v2.0 | 2/2 | Complete    | 2026-07-14 |
| 16. PWA Installability & iOS Polish | v2.0 | 4/4 | Complete   | 2026-07-17 |
| 17. Deployment Hardening & Firebase Hosting | v2.0 | 1/1 | Complete   | 2026-07-17 |

**Note:** The v1.0 progress table rows above (Phases 1, 2, 3 marked Complete; others Not started) reflect the state carried over from the v1.0 STATE.md snapshot at milestone transition — see `git log` / `.planning/STATE.md` Accumulated Context for actual v1.0 completion history (all of Phases 1–10 shipped to the Internal testing track).
