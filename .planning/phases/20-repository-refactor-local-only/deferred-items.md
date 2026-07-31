# Deferred Items — Phase 20

Out-of-scope discoveries during plan execution, logged not fixed, per the executor's
scope-boundary rule (only auto-fix issues directly caused by the current task's changes).

## 20-01: Date-boundary bug in notification_service_test.dart (pre-existing, unrelated)

**Found during:** Task 4 full-suite verification (`flutter test`).

**Symptom:** `test/platform/notification_service_test.dart` — `scheduleEveningBefore
tijdberekening: 19:00 de dag voor slotDay` fails with `Expected: <8> Actual: <7>` (month
mismatch) whenever the suite runs on the **last calendar day of a month**.

**Root cause:** The test computes `slotDay = tomorrow` and then asserts
`scheduled.day == slotDay.day - 1` as a raw integer subtraction, not a `DateTime`
subtraction. When `tomorrow` is the 1st of a month (i.e. today is the last day of the
previous month), `slotDay.day - 1 == 0`, which never matches the correctly-computed
`scheduled.day` (the actual last day of the current month). This is a latent test bug
triggered by wall-clock date, not by any code under test.

**Scope:** `test/platform/notification_service_test.dart` is not in this plan's `files`
list and was not touched by any of the four tasks (BlockType move, AvailabilityRepository,
AvailabilityNotifier slim-down, repository tests) — all scoped to the availability domain.
Confirmed pre-existing by inspecting the test's date arithmetic; it would fail on any
last-day-of-month run regardless of this plan's changes.

**Action taken:** None — left as-is per scope boundary. `flutter test` run for this plan:
329 passed / 1 failed (the plan's floor of "at least 317 passed" is met; the single failure
is this unrelated date-boundary bug).

**Suggested fix (future quick task):** Replace `slotDay.day - 1` with proper `DateTime`
arithmetic, e.g. compare against
`DateTime(slotDay.year, slotDay.month, slotDay.day).subtract(const Duration(days: 1))`.
