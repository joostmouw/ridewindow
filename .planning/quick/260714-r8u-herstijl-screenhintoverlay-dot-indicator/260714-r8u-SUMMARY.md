---
phase: quick-260714-r8u
plan: 01
subsystem: shared-ui
tags: [material-3, coach-marks, ui-polish]
dependency-graph:
  requires: []
  provides: [screen-hint-overlay-md3-cta]
  affects: [home-screen, week-agenda-screen, planned-rides-screen]
tech-stack:
  added: []
  patterns:
    - "MD3 low-emphasis action = TextButton with onSurfaceVariant/foregroundColor color roles instead of hand-rolled filled pill Container"
key-files:
  created: []
  modified:
    - lib/features/shared/screen_hint_overlay.dart
decisions:
  - "Replaced (not supplemented) bottom dot-indicator row + filled pill CTA with inline Row: onSurfaceVariant 'N/M' counter (left) + MD3 TextButton (right), per user-provided React/shadcn Popover visual reference (adapted to Flutter/MD3, not ported literally)."
  - "TextButton uses TextButton.styleFrom(foregroundColor: Colors.white) override to preserve readability against the translucent glass-morphism card background (Colors.white.withAlpha(30)), since default MD3 TextButton foreground (primary color role) would be low-contrast there."
  - "Last-step dismiss behavior (_next() -> widget.onDismiss()) left completely untouched; no 'start over'/loop-to-first-step behavior added, per explicit user rejection of that part of the reference demo."
metrics:
  duration: "~10min"
  completed: 2026-07-14
---

# Phase quick-260714-r8u Plan 01: Restyle ScreenHintOverlay CTA Summary

Replaced the coach-mark overlay's bottom dot-progress row and filled-pill "Next"/"Sluiten" button with a compact inline `{step}/{total}` `onSurfaceVariant`-colored counter plus a standard Material 3 `TextButton`, matching MD3 conventions instead of ad-hoc `Colors.white.withAlpha(...)` styling.

## What Was Built

**Task 1 (auto, committed 862c80a):** In `lib/features/shared/screen_hint_overlay.dart`:
- Deleted the entire bottom dot-indicator `Positioned(bottom: 48, left: 24, right: 24, ...)` block from the `Stack` in `build()`. The `Stack` now contains only the spotlight `Positioned.fill` painter and the conditional `_buildTooltip(...)` call.
- Replaced the `Align(alignment: Alignment.centerRight, child: Container(...filled pill...))` CTA in `_buildTooltip()` with a `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)` containing:
  - Left: `Text('${_currentStep + 1}/${widget.hints.length}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12))`
  - Right: `TextButton(onPressed: _next, style: TextButton.styleFrom(foregroundColor: Colors.white), child: Text(isLast ? s.hintDismiss : s.hintNext))`
- No l10n changes — reused existing `s.hintNext` / `s.hintDismiss` strings verbatim.
- No changes to `_SpotlightPainter`, `_ArrowPainter`, `_getTargetRect`, `_next()` internals, the icon+title+description block, the card's `BoxDecoration`, `HintItem`, `shouldShowHint`/`markHintSeen`, or the `minTop`/`maxBottom` clamp constants.

**Task 2 (checkpoint:human-verify):** NOT executed by this run — left for the user. Requires manual verification on a device/emulator across Home, Week Agenda, and Planned Rides screens (all three share this overlay via `HintItem` lists).

## Verification

`flutter analyze lib/features/shared/screen_hint_overlay.dart` — passed with 2 pre-existing info-level issues (`unnecessary_import` on line 1's `dart:ui` import, `require_trailing_commas` on the untouched `Icon(...)` call inside the icon container) — both confirmed via `git diff` to be outside this task's diff and outside its declared file scope (icon container is explicitly "do not modify" per the plan). No new issues introduced.

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- FOUND: lib/features/shared/screen_hint_overlay.dart (modified, dot-indicator block removed, CTA restyled)
- FOUND: commit 862c80a in `git log --oneline`
