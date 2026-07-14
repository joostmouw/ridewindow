---
phase: quick-260714-qor
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [lib/features/detail/ride_detail_screen.dart, lib/l10n/app_en.arb, lib/l10n/app_nl.arb, lib/l10n/app_localizations.dart, lib/l10n/app_localizations_en.dart, lib/l10n/app_localizations_nl.dart]
autonomous: false
requirements: [QOR-01]

must_haves:
  truths:
    - "When the current effective slot (start/end, after any Adjust Time changes) is already present in plannedRidesProvider's state, the pinned bottom bar shows a 'Planned' label with a checkmark icon in a muted/outline style — NOT the green filled 'Plan ride' CTA"
    - "When the effective slot is NOT already planned, the existing green filled 'Plan ride' CTA (built in quick task 260714-o54) is shown exactly as before — no regression"
    - "Tapping 'Plan ride' flips the button to the 'Planned' look immediately, on the same screen, without navigating away or manually refreshing — because ref.watch(plannedRidesProvider) drives the rebuild"
    - "The 'Planned' state is display-only: tapping it is a no-op (onPressed: null) — no unplan/remove behavior is added"
  artifacts:
    - path: "lib/features/detail/ride_detail_screen.dart"
      provides: "_buildPlanRideBar renders OutlinedButton.icon('Planned', check_circle_outline, disabled) when the effective slot's start/end match an entry in plannedRidesProvider state, else the unchanged FilledButton.icon('Plan ride') CTA"
      contains: "plannedButtonLabel"
    - path: "lib/l10n/app_en.arb"
      provides: "plannedButtonLabel: \"Planned\""
      contains: "plannedButtonLabel"
    - path: "lib/l10n/app_nl.arb"
      provides: "plannedButtonLabel: \"Ingepland\""
      contains: "plannedButtonLabel"
  key_links:
    - from: "lib/features/detail/ride_detail_screen.dart _buildPlanRideBar"
      to: "plannedRidesProvider"
      via: "ref.watch(plannedRidesProvider) read at the top of _buildPlanRideBar so the button reacts to state changes"
      pattern: "ref\\.watch\\(plannedRidesProvider\\)"
    - from: "lib/features/detail/ride_detail_screen.dart _buildPlanRideBar"
      to: "_effectiveSlot start/end containment check"
      via: "manual field comparison (r.start == slot.start && r.end == slot.end) — same equality pattern already used by PlannedRidesNotifier.add/remove, since PlannedRide has no operator== override"
      pattern: "r\\.start == .*&&.*r\\.end =="
---

<objective>
On the Ride Detail screen's pinned bottom bar (built in quick task 260714-o54), make the "Plan ride" button reflect whether the currently displayed effective time window is already planned: show a muted/outline "Planned" state with a checkmark instead of the green "Plan ride" CTA when the effective slot's start/end already exists in `plannedRidesProvider`'s state. Continuation of backlog #34.

Purpose: Prevent users from being unsure whether they already planned the ride window they're looking at, and give immediate visual feedback right after tapping "Plan ride" without navigating away.
Output: Updated `_buildPlanRideBar` in `ride_detail_screen.dart` with conditional rendering; new `plannedButtonLabel` l10n string (EN "Planned" / NL "Ingepland").
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

<user_clarification>
Verbatim decision from AskUserQuestion (not yet captured in any CONTEXT.md file — this quick task has no discuss-phase, so it is recorded here):

"When the ride window currently shown on Ride Detail (the 'effective slot' — start/end after any Adjust Time changes) is already present in plannedRidesProvider's state, the pinned bottom bar button should show 'Planned' text with a checkmark icon and a muted/outline style (NOT the current green filled 'Plan ride' look), instead of the normal 'Plan ride' CTA. This must be reactive — immediately after tapping 'Plan ride' (without leaving the screen or manually refreshing), the button should flip to the 'Planned' look. When the effective slot is NOT already planned, show the existing green 'Plan ride' button exactly as it is today (built in quick task 260714-o54, do not regress that work). Matching logic: two slots are the same if their start and end DateTime values match the current effective slot's start/end. Do NOT make the 'Planned' state clickable-to-unplan in this task — scope is display-only. Tapping the button while it shows 'Planned' can be a no-op or keep the tap area disabled."

Chosen option was "Knop wordt 'Planned' met vinkje" (button becomes 'Planned' with checkmark) — explicitly NOT the disabled-without-checkmark variant nor the unplan-toggle variant.
</user_clarification>

<interfaces>
**Current `_buildPlanRideBar` (lib/features/detail/ride_detail_screen.dart, ~line 741)** — built in quick task 260714-o54, pinned via `Scaffold.bottomNavigationBar: SafeArea(top: false, child: _buildPlanRideBar(context))`:

```
Widget _buildPlanRideBar(BuildContext context) {
  final rw = context.rw;
  return Container(
    decoration: BoxDecoration(color: rw.surface, border: Border(top: BorderSide(color: rw.borderDim))),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: FilledButton.icon(
      onPressed: () {
        final slot = _effectiveSlot;
        ref.read(plannedRidesProvider.notifier).add(
              PlannedRide(start: slot.start, end: slot.end, plannedScore: slot.overallScore),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).ridePlanned)),
        );
      },
      icon: const Icon(Icons.directions_bike),
      label: Text(S.of(context).planRide),
    ),
  );
}
```

Do NOT touch the surrounding `Container`/padding/border wiring, `Scaffold.bottomNavigationBar` assignment, or `_buildSecondaryActions` — only change what's rendered inside as the button itself.

**`_effectiveSlot` getter** (same file, ~line 85): recomputes `RideSlot` from `_start`/`_end` (the current Adjust Time values) each time it's accessed — already used by the existing `onPressed` body above. Reuse it directly; do not duplicate its logic.

**`PlannedRide`** (`lib/providers/planned_rides_notifier.dart`) is a **plain Dart class with no `operator==`/`hashCode` override** — fields `start` (DateTime), `end` (DateTime), `plannedScore` (double). `PlannedRidesNotifier.add()`/`.remove()` already do manual field comparison for equality: `state.any((r) => r.start == ride.start && r.end == ride.end)`. Reuse this exact pattern for the containment check — do not add a manual field-by-field comparison in a different style, and do not add `operator==` to `PlannedRide` (out of scope, not requested).

**`plannedRidesProvider`** (same file, Riverpod 3.x codegen, `@Riverpod(keepAlive: true)` on `PlannedRidesNotifier`) exposes `List<PlannedRide> build()`. Already imported in `ride_detail_screen.dart` via `import 'package:ridewindow/providers/planned_rides_notifier.dart';` — no new import needed. Currently only read via `ref.read(...)` inside the `onPressed` callback; this task adds a `ref.watch(plannedRidesProvider)` call so `_buildPlanRideBar` rebuilds reactively when the list changes (e.g. right after tapping "Plan ride").

**MD3 outline/muted button precedent in this same file** — the "Add to Google Calendar" secondary action (`_buildSecondaryActions`, ~line 776) uses `OutlinedButton.icon(onPressed: ..., icon: ..., label: Text(...))`. Reuse `OutlinedButton.icon` for the "Planned" state (per `.claude/skills/material-3/SKILL.md` conventions — outlined variant is the correct MD3 low-emphasis/muted choice). Passing `onPressed: null` gives the standard Material 3 disabled-outline appearance (reduced-opacity outline + text/icon) automatically — no custom color overrides needed to achieve "gedempte" (muted).

**l10n pattern**: `S.of(context)` from `package:ridewindow/l10n/app_localizations.dart`, generated by `flutter gen-l10n` from `lib/l10n/app_nl.arb` (template) and `lib/l10n/app_en.arb`. Existing neighboring keys in both files (around line 238/286): `"planRide"` / `"ridePlanned"`. Add `"plannedButtonLabel"` immediately after `"ridePlanned"` in both files: EN `"Planned"`, NL `"Ingepland"`. No `@`-metadata block needed (plain string, no placeholders, matching the style of `planRide`/`ridePlanned` themselves). After editing both `.arb` files, run `flutter gen-l10n` to regenerate the three generated files listed in `files_modified` — do not hand-edit them.

**Pre-existing broken test files (confirmed, unrelated to this task — do not fix here):** `test/features/ride_detail_screen_test.dart` (13 tests) and `test/features/detail/ride_detail_screen_calendar_test.dart` (4 tests) both currently fail 100% because they pump `RideDetailScreen` inside a bare `MaterialApp` with no `ProviderScope` ancestor and no localization delegates. This is pre-existing repo debt (already noted in quick task 260714-o54's plan and in backlog item #11) — do not extend or attempt to fix these files as part of this task. The containment check added here is a one-line lookup (`plannedRides.any((r) => r.start == slot.start && r.end == slot.end)`), so per this task's own scoping guidance a human-verify checkpoint is the right-sized verification tool, consistent with how 260714-o54 verified the same file's UI behavior.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Conditional "Planned" vs "Plan ride" rendering in the pinned bottom bar</name>
  <files>lib/features/detail/ride_detail_screen.dart, lib/l10n/app_en.arb, lib/l10n/app_nl.arb, lib/l10n/app_localizations.dart, lib/l10n/app_localizations_en.dart, lib/l10n/app_localizations_nl.dart</files>
  <action>
  In `lib/l10n/app_nl.arb`, insert `"plannedButtonLabel": "Ingepland",` immediately after the existing `"ridePlanned"` entry. In `lib/l10n/app_en.arb`, insert `"plannedButtonLabel": "Planned",` in the same relative position after `"ridePlanned"`. Run `flutter gen-l10n` from the repo root to regenerate `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_nl.dart` (do not hand-edit these three).

  In `lib/features/detail/ride_detail_screen.dart`, modify `_buildPlanRideBar(BuildContext context)`:
  - At the top of the method (before building the `Container`), add `final plannedRides = ref.watch(plannedRidesProvider);` and `final slot = _effectiveSlot;` — the `ref.watch` call is what makes the rendered state reactive to `plannedRidesProvider` changes (including right after the notifier's `.add()` call inside `onPressed`, since that triggers this widget to rebuild).
  - Compute `final isPlanned = plannedRides.any((r) => r.start == slot.start && r.end == slot.end);` — reuse the exact equality pattern already used in `PlannedRidesNotifier.add`/`.remove` (manual `start`/`end` field comparison; `PlannedRide` has no `operator==`).
  - Change the `Container`'s child to a conditional: when `isPlanned` is `true`, render `OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.check_circle_outline), label: Text(S.of(context).plannedButtonLabel))`. When `isPlanned` is `false`, render the existing `FilledButton.icon` unchanged (same `onPressed` body reading `slot` computed above instead of re-reading `_effectiveSlot` inline, same icon `Icons.directions_bike`, same label `S.of(context).planRide`, same SnackBar).
  - Do not change the surrounding `Container`'s `decoration`/`padding`, and do not touch `_buildSecondaryActions` or the `Scaffold.bottomNavigationBar` wiring.
  </action>
  <verify>
    <automated>cd /Users/joostmouw/ridewindow && flutter gen-l10n && flutter analyze lib/features/detail/ride_detail_screen.dart lib/l10n/app_localizations.dart</automated>
  </verify>
  <done>
  `flutter gen-l10n` runs clean and `S` exposes `plannedButtonLabel` in both `app_localizations_en.dart` and `app_localizations_nl.dart`. `flutter analyze` reports zero new errors/warnings on the modified files. `_buildPlanRideBar` watches `plannedRidesProvider`, computes `isPlanned` via manual start/end comparison against `_effectiveSlot`, and conditionally renders `OutlinedButton.icon` ("Planned" + check icon, disabled) or the unchanged `FilledButton.icon` ("Plan ride").
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
  The Ride Detail screen's pinned bottom bar now shows a muted/outline "Planned" button with a checkmark icon instead of the green "Plan ride" CTA whenever the currently displayed effective time window (after any Adjust Time changes) is already in your planned rides. This updates reactively — tapping "Plan ride" flips it to "Planned" immediately, on the same screen.
  </what-built>
  <how-to-verify>
  Run the app (`flutter run` on a connected device/emulator, or the release APK per usual workflow):
  1. Open a Ride Detail screen for a window you have NOT planned yet. Confirm the pinned bottom bar shows the green "Plan ride" button with the bike icon, exactly as before.
  2. Tap "Plan ride". Confirm the SnackBar confirmation still appears, AND — without leaving the screen or refreshing — the button immediately changes to a muted/outline "Planned" button with a checkmark icon.
  3. Tap the now-"Planned" button. Confirm nothing happens (no unplan, no new SnackBar, no crash) — it should feel inert.
  4. Navigate away (e.g. back to Home) and re-open the SAME ride window's Detail screen. Confirm it shows "Planned" immediately on open (no tap needed), since the effective slot's start/end is already in `plannedRidesProvider`.
  5. On a ride window that is currently showing "Planned", use the Adjust Time controls to shrink/expand the window so it no longer matches any planned start/end. Confirm the button reverts to the green "Plan ride" CTA.
  </how-to-verify>
  <resume-signal>Type "approved" or describe issues</resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| None new | Pure client-side UI state derived from data the user already entered on-device (their own planned rides list); no new external input, network call, or persisted data format change. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-quick260714qor-01 | Information Disclosure | "Planned" button state | accept | Displays only a locally-derived boolean from the user's own `plannedRidesProvider` state on their own device; nothing leaves the device, no new persisted data. |
| T-quick260714qor-02 | Tampering | containment check (`plannedRides.any(...)`) | accept | Pure comparison against already-trusted local state (`plannedRidesProvider`, populated only by the user's own on-device taps); no new untrusted input path introduced. |
</threat_model>

<verification>
Run `flutter gen-l10n && flutter analyze lib/features/detail/ride_detail_screen.dart lib/l10n/app_localizations.dart`, then complete the human-verify checkpoint above (the containment check is a one-line lookup; building fresh ProviderScope-override widget-test infrastructure for this already broken-test-file screen is disproportionate for this quick task, consistent with the precedent set in quick task 260714-o54).
</verification>

<success_criteria>
- Effective slot already planned -> pinned bar shows "Planned" + checkmark, muted/outline (`OutlinedButton.icon`, disabled)
- Effective slot not planned -> pinned bar shows the unchanged green "Plan ride" `FilledButton.icon`
- Flips to "Planned" immediately after tapping "Plan ride", same screen, no manual refresh
- Tapping "Planned" is a no-op — no unplan/remove behavior added
- `flutter analyze` and `flutter gen-l10n` pass clean; no regression to `_buildSecondaryActions` or the `Scaffold.bottomNavigationBar` wiring
</success_criteria>

<output>
Create `.planning/quick/260714-qor-ride-detail-plan-ride-knop-toont-planned/260714-qor-SUMMARY.md` when done
</output>
