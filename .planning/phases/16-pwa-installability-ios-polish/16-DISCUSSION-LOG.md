# Phase 16: PWA Installability & iOS Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-17
**Phase:** 16-pwa-installability-ios-polish
**Areas discussed:** App icon & branding source, Splash-screen approach, "Add to Home Screen" overlay timing, Standalone back/close navigation

---

## App icon & branding source

User interjected before options were formally presented via AskUserQuestion, stating directly: reuse the real existing RideWindow app icon (found during codebase scouting at `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png` — calendar grid + winding road + cyclist silhouette) instead of the current default Flutter placeholder icon still in use under `web/icons/`.

**User's choice:** Use the real Android app icon as the source for all web/iOS branding artwork.
**Notes:** User's exact words: "main app logo real, deze gebruiken als logo aub."

---

## Splash-screen aanpak

| Option | Description | Selected |
|--------|-------------|----------|
| Icoon gecentreerd op merkkleur-achtergrond | RideWindow icon centered on a flat brand-color (theme_color) background | ✓ |
| Simpele witte/lege flash | Plain background, no icon, minimalist flash before app loads | |

**User's choice:** Icon centered on brand-color background.
**Notes:** None beyond the selection.

---

## "Voeg toe aan beginscherm"-overlay

| Option | Description | Selected |
|--------|-------------|----------|
| Elke sessie tot geïnstalleerd | Shows every visit until the app is actually installed as a PWA; auto-hides once `display-mode: standalone` is detected | ✓ |
| Eenmalig, dan permanent verborgen | Shows once, same persistence pattern as the existing ScreenHintOverlay (`hint_seen_*`) | |

**User's choice:** Every session until installed (not a one-time dismiss).
**Notes:** This is a deliberate departure from the existing `ScreenHintOverlay` one-time-hint pattern already used elsewhere in the app (Home, Agenda, Planned Rides) — noted explicitly in CONTEXT.md so downstream agents don't default to the familiar pattern.

---

## Terug/sluiten-navigatie in standalone-modus

| Option | Description | Selected |
|--------|-------------|----------|
| Laat de planner dit onderzoeken | No known broken screen today; research/planning generically audits go_router navigation for standalone-mode gaps | ✓ |
| Ik weet al een specifiek scherm dat kapot is | User has a concrete screen/flow in mind | |

**User's choice:** Let the planner investigate generically — no specific known-broken screen.
**Notes:** None beyond the selection.

---

## Claude's Discretion

- Exact number/matrix of iOS splash-screen device-size variants to generate — favor correctness on the real test devices used for PWA-05 verification over exhaustive historical iPhone model coverage.

## Deferred Ideas

None — discussion stayed within phase scope.
