---
phase: quick-260714-rrx
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/l10n/app_en.arb
  - lib/l10n/app_nl.arb
  - lib/features/shared/unplan_confirm_dialog.dart
  - lib/features/detail/ride_detail_screen.dart
  - lib/features/home/home_screen.dart
autonomous: false
requirements: []
must_haves:
  truths:
    - "User can tap the 'Planned' button on Ride Detail, see a confirm dialog, confirm, and the ride is unplanned (button flips back to green 'Plan ride')"
    - "User can cancel that confirm dialog and nothing changes"
    - "User can tap a delete icon on a planned-ride row on Home, see the same confirm dialog, confirm, and the ride disappears from the Home planned-rides list"
    - "Tapping the rest of the Home planned-ride row (not the delete icon) still navigates to Ride Detail as before"
    - "The existing Dismissible swipe-to-delete and bottom-sheet delete button on the My Rides screen (planned_rides_screen.dart) are untouched"
  artifacts:
    - path: "lib/features/shared/unplan_confirm_dialog.dart"
      provides: "showUnplanConfirmDialog(BuildContext) -> Future<bool> reusable AlertDialog helper"
    - path: "lib/features/detail/ride_detail_screen.dart"
      provides: "Planned OutlinedButton.icon with real onPressed calling the confirm dialog + remove()"
    - path: "lib/features/home/home_screen.dart"
      provides: "delete_outline IconButton on each planned-ride row calling the confirm dialog + remove()"
  key_links:
    - from: "lib/features/detail/ride_detail_screen.dart"
      to: "lib/features/shared/unplan_confirm_dialog.dart"
      via: "showUnplanConfirmDialog(context) await call inside _buildPlanRideBar onPressed"
      pattern: "showUnplanConfirmDialog\\(context\\)"
    - from: "lib/features/home/home_screen.dart"
      to: "lib/features/shared/unplan_confirm_dialog.dart"
      via: "showUnplanConfirmDialog(context) await call inside the new delete IconButton onPressed"
      pattern: "showUnplanConfirmDialog\\(context\\)"
    - from: "lib/features/shared/unplan_confirm_dialog.dart"
      to: "lib/providers/planned_rides_notifier.dart"
      via: "callers invoke ref.read(plannedRidesProvider.notifier).remove(...) after confirm returns true"
      pattern: "plannedRidesProvider\\.notifier\\)\\.remove"
---

<objective>
Add unplan/delete capability for a planned ride from two NEW locations — the "Planned" button on Ride Detail, and a delete icon on each planned-ride row on Home — both gated behind a short confirm dialog. This intentionally reverses the display-only `onPressed: null` decision made in quick-260714-qor, per explicit user request (confirmed via AskUserQuestion: both locations, with confirm dialog because these are more casual tap targets than the deliberate swipe/bottom-sheet pattern already on the My Rides screen).

Purpose: Users currently have no way to undo an accidental or outdated "Plan ride" tap except by navigating to the separate My Rides screen and using swipe-to-delete or the bottom-sheet delete button. This adds fast, safe unplan access at the two places a planned ride is most visibly surfaced.

Output: A small reusable confirm-dialog helper (`showUnplanConfirmDialog`), wired into Ride Detail's Planned button and a new delete icon on Home's planned-rides row, plus new EN/NL l10n strings for the dialog copy.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@CLAUDE.md

<!-- Locked decisions from user conversation (verbatim) -->
This intentionally REVERSES a scope decision from quick-260714-qor, where the "Planned" button
was deliberately made display-only (`onPressed: null`, no unplan). The user has now explicitly
asked for unplan/delete capability, confirmed via AskUserQuestion:
1. Where: Both Ride Detail AND Home (not just one).
2. Confirmation: Yes, a short confirm dialog before deleting (chosen over direct-delete-with-undo),
   specifically because tapping the "Planned" button / a Home list row is a more casual,
   easy-to-hit target than the existing deliberate swipe/bottom-sheet-button pattern in
   `planned_rides_screen.dart`.

Must NOT modify the existing Dismissible swipe-to-delete or bottom-sheet delete button in
`lib/features/planned/planned_rides_screen.dart` — that screen's UX stays exactly as-is. This
plan only adds delete capability to the 2 NEW locations (Ride Detail, Home).

<!-- Planner's judgment call on the "shared helper vs duplication" question the user left open -->
Decision: build ONE small shared helper, `showUnplanConfirmDialog(BuildContext)`, in
`lib/features/shared/unplan_confirm_dialog.dart`, that ONLY shows the AlertDialog and returns
`Future<bool>` (true = confirmed delete, false = cancelled). It does NOT itself call
`.remove()` or show the SnackBar — those two side effects differ slightly per call site
(Ride Detail rebuilds `_effectiveSlot`; Home already has the `PlannedRide` object in hand) and
forcing them into the shared helper would require passing `WidgetRef` + `PlannedRide` through a
UI-only helper, which is an awkward coupling. Sharing just the dialog avoids UI duplication
(title/message/button styling/error color) while keeping each call site's remove-and-notify
logic simple and local, matching the existing code style in both files.

<interfaces>
From lib/providers/planned_rides_notifier.dart (already exists, do not modify):
```dart
class PlannedRide {
  PlannedRide({required this.start, required this.end, required this.plannedScore});
  final DateTime start;
  final DateTime end;
  final double plannedScore;
  int get durationHours => end.difference(start).inHours;
}

@Riverpod(keepAlive: true)
class PlannedRidesNotifier extends _$PlannedRidesNotifier {
  void remove(PlannedRide ride); // matches by start/end field equality only (NOT plannedScore)
}
```
`remove()` matches by `r.start == ride.start && r.end == ride.end` — the passed-in `PlannedRide`
instance does NOT need to be the exact same object from the list, only matching start/end. This
is the "field-equality matching pattern" referenced throughout this plan — reuse it exactly,
do not invent an alternative (e.g. do not add `operator==` to `PlannedRide`).

From lib/l10n/app_en.arb (existing, reuse as-is — do not rename or touch):
```
"cancel": "Cancel"            // generic Cancel button label, already used elsewhere in the app
"rideRemoved": "Ride removed" // post-delete SnackBar text, already used in planned_rides_screen.dart
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add l10n strings for the unplan confirm dialog</name>
  <files>lib/l10n/app_en.arb, lib/l10n/app_nl.arb</files>
  <action>
Add three new keys to both ARB files, inserted directly after the existing "ridesDeleteRide" entry
(en: line 310, nl: line 397) to keep them grouped with the other ride-removal strings:
`unplanConfirmTitle`, `unplanConfirmMessage`, `unplanConfirmAction`.

EN values: unplanConfirmTitle = "Unplan this ride?", unplanConfirmMessage = "This will remove
it from your planned rides. You can plan it again anytime.", unplanConfirmAction = "Unplan".

NL values: unplanConfirmTitle = "Rit uitplannen?", unplanConfirmMessage = "Dit verwijdert de rit
uit je geplande ritten. Je kunt hem altijd opnieuw plannen.", unplanConfirmAction = "Uitplannen".

Do NOT add a new "cancel" string — the existing top-level `"cancel": "Cancel"` / `"cancel":
"Annuleer"` key (en line 175 / nl line 201) is reused for the dialog's Cancel action. Do NOT
touch `rideRemoved` (en line 306 / nl line 388) — reuse it as-is for the post-delete SnackBar.

After editing both files, run `flutter gen-l10n` from the project root to regenerate
`app_localizations*.dart` so `S.of(context).unplanConfirmTitle` etc. are available to the
Dart compiler in Task 2/3.
  </action>
  <verify>
    <automated>grep -c "unplanConfirmTitle\|unplanConfirmMessage\|unplanConfirmAction" lib/l10n/app_en.arb lib/l10n/app_nl.arb</automated>
  </verify>
  <done>Both ARB files contain all 3 new keys with EN/NL values; `flutter gen-l10n` completes without error; generated `S` class exposes the 3 new getters.</done>
</task>

<task type="auto">
  <name>Task 2: Create shared confirm dialog and wire it into Ride Detail's Planned button</name>
  <files>lib/features/shared/unplan_confirm_dialog.dart, lib/features/detail/ride_detail_screen.dart</files>
  <action>
Create `lib/features/shared/unplan_confirm_dialog.dart` exporting one top-level function:
`Future<bool> showUnplanConfirmDialog(BuildContext context)`. It calls `showDialog<bool>` with
an `AlertDialog` per the MD3 skill's Dialog conventions (`.claude/skills/material-3/SKILL.md`):
title = `S.of(context).unplanConfirmTitle`, content = `S.of(context).unplanConfirmMessage`,
actions = a `TextButton` labelled `S.of(context).cancel` that pops `false`, and a `TextButton`
labelled `S.of(context).unplanConfirmAction` styled with `foregroundColor:
Theme.of(context).colorScheme.error` (per D-material-3 destructive-action convention already
used in `planned_rides_screen.dart`'s bottom-sheet delete button) that pops `true`. Return
`result ?? false` so a dismissed-by-tapping-outside dialog behaves as "cancelled".

In `ride_detail_screen.dart`, import the new helper. In `_buildPlanRideBar` (the `isPlanned`
branch, currently `OutlinedButton.icon(onPressed: null, ...)`), replace `onPressed: null` with
an async handler: await `showUnplanConfirmDialog(context)`; if the result is `true`, call
`ref.read(plannedRidesProvider.notifier).remove(PlannedRide(start: slot.start, end: slot.end,
plannedScore: slot.overallScore))` — constructing a fresh `PlannedRide` with the current
`_effectiveSlot`'s start/end is sufficient because `.remove()` matches on start/end only (see
`<interfaces>`), reusing the exact same field-equality approach as the existing `isPlanned`
check just above it in the same method. After removing, guard with `if (context.mounted)` and
show `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:
Text(S.of(context).rideRemoved)))`. Do not create a new SnackBar string. The button already
reactively flips back to the green "Plan ride" `FilledButton.icon` afterward because
`_buildPlanRideBar` calls `ref.watch(plannedRidesProvider)`. On cancel (result `false`), do
nothing further — the dialog closing is the only visible change.
  </action>
  <verify>
    <automated>grep -c "showUnplanConfirmDialog" lib/features/detail/ride_detail_screen.dart lib/features/shared/unplan_confirm_dialog.dart</automated>
  </verify>
  <done>Tapping "Planned" on Ride Detail opens the confirm AlertDialog; confirming removes the ride and shows the "Ride removed" SnackBar with the button flipping to "Plan ride"; cancelling closes the dialog with no state change.</done>
</task>

<task type="auto">
  <name>Task 3: Add delete icon to Home's planned-ride row using the shared dialog</name>
  <files>lib/features/home/home_screen.dart</files>
  <action>
Import `showUnplanConfirmDialog` from `lib/features/shared/unplan_confirm_dialog.dart`. In
`_buildPlannedRidesSliver`, inside the `Row` for each planned ride (which currently ends with
`ScoreBadge(tier: rideTierFromScore(ride.plannedScore))`), add `const SizedBox(width: 4)`
followed by an `IconButton(icon: const Icon(Icons.delete_outline), color:
Theme.of(context).colorScheme.error, onPressed: () async { ... })` after the `ScoreBadge`. The
default Material 3 `IconButton` already provides the ~48dp minimum touch target (per
`.claude/skills/material-3/SKILL.md` touch-target guidance) — do not shrink it with a custom
`iconSize`/`constraints` override, and keep the `SizedBox(width: 4)` spacer so it does not
visually crowd the `ScoreBadge`.

The `onPressed` handler: await `showUnplanConfirmDialog(context)`; if `true`, call
`ref.read(plannedRidesProvider.notifier).remove(ride)` (the loop variable `ride` is already the
exact `PlannedRide` instance being displayed — no need to reconstruct one, unlike Task 2), then
guard with `if (context.mounted)` and show the same `SnackBar(content:
Text(S.of(context).rideRemoved))`. Do NOT wrap the new `IconButton` in the outer `InkWell` — it
must be its own separate tappable widget inside the `Row` so tapping delete does not also
trigger `onTap: () => _openPlannedRideDetail(ride)` on the row's `InkWell`. Confirm this by
inspection: `IconButton` in Flutter internally uses its own gesture detector and, placed inside
an `InkWell`'s child tree, correctly intercepts its own taps without also bubbling to the
parent `InkWell` — no additional stop-propagation code is needed.
  </action>
  <verify>
    <automated>grep -c "showUnplanConfirmDialog\|Icons.delete_outline" lib/features/home/home_screen.dart</automated>
  </verify>
  <done>Each planned-ride row on Home shows a delete icon next to the ScoreBadge; tapping it opens the confirm dialog; confirming removes the ride from the Home list and shows the "Ride removed" SnackBar; tapping elsewhere on the row still navigates to Ride Detail; the delete icon has an adequate MD3 touch target and does not visually crowd the ScoreBadge.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
Confirm dialog before unplanning a ride, wired into two places: the "Planned" button on Ride
Detail, and a new delete icon on each planned-ride row on Home. Both share one dialog helper and
reuse the existing "Ride removed" SnackBar. The My Rides screen's swipe-to-delete and bottom-sheet
delete button are unchanged.
  </what-built>
  <how-to-verify>
    1. Run `flutter run` (or use an existing debug build) and plan a ride from Home or the Agenda.
    2. On Home, find the ride under "Planned rides" — confirm you see a delete icon next to the
       score badge, with visible spacing (not crowding the badge).
    3. Tap the delete icon — a dialog should appear asking to confirm unplanning. Tap Cancel —
       dialog closes, the ride is still listed.
    4. Tap the delete icon again, confirm — the ride disappears from Home's planned rides list
       and a "Ride removed" SnackBar appears.
    5. Tap elsewhere on a (different, still-planned) row — it should still navigate to Ride Detail
       as before.
    6. Plan a ride again, open its Ride Detail screen. Confirm the bottom bar shows the "Planned"
       button (checkmark icon). Tap it — the same confirm dialog appears.
    7. Confirm — the button should flip back to the green "Plan ride" button, and a "Ride removed"
       SnackBar appears.
    8. Navigate to the My Rides screen (via Home's "See all" or nav) and confirm its swipe-to-delete
       and bottom-sheet delete button still work exactly as before (unchanged).
    9. Verify NL locale: switch device/app language to Dutch and repeat steps 3-4 or 6-7, confirming
       the dialog text is in Dutch ("Rit uitplannen?" / "Uitplannen").
  </how-to-verify>
  <resume-signal>Type "approved" or describe issues</resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| User tap -> local state mutation | All input is a local UI gesture; no network or untrusted data crosses this boundary. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-rrx-01 | Repudiation/UX | Ride Detail "Planned" button, Home delete icon | mitigate | Both destructive actions are gated behind `showUnplanConfirmDialog` (AlertDialog with explicit Cancel/Unplan), preventing accidental data loss from a casual tap — this is the entire purpose of this plan. |
| T-rrx-02 | Tampering | `_buildPlannedRidesSliver` new IconButton nested inside existing `InkWell` | accept | Flutter's gesture arena correctly scopes `IconButton` taps to itself when nested inside an `InkWell`'s child tree; no custom gesture-recognizer code needed, verified via existing framework behavior, not a new risk surface. |
</threat_model>

<verification>
- `flutter analyze` reports no new errors in the 5 modified/created files.
- `flutter gen-l10n` completes cleanly and the 3 new `S.of(context)` getters resolve at compile time in both `ride_detail_screen.dart` and `home_screen.dart`.
- Manual checkpoint (Task 4) confirms both entry points, both languages, and the untouched My Rides screen.
</verification>

<success_criteria>
- Ride Detail's "Planned" button and Home's planned-ride delete icon both open the same confirm dialog and, on confirm, remove the ride and show the existing "Ride removed" SnackBar.
- Cancelling the dialog from either location leaves state unchanged.
- `planned_rides_screen.dart`'s existing Dismissible and bottom-sheet delete button are byte-for-byte unmodified.
- New l10n strings exist in both `app_en.arb` and `app_nl.arb`, generated successfully via `flutter gen-l10n`.
</success_criteria>

<output>
Create `.planning/quick/260714-rrx-unplan-delete-geplande-rit-vanaf-ride-de/260714-rrx-SUMMARY.md` when done
</output>
