// lib/domain/services/drag_run_counter.dart
// Pure, side-effect-free helper for the Availability screen's drag-select
// indicator (backlog #35, scoped down). Counts distinct "runs" of cells in
// a drag selection, where a run is a maximal set of same-calendar-day,
// consecutive-hour cells. Two cells on different calendar days are never
// part of the same run, even if their hour value is identical.
//
// This is a plain selection-count indicator. It makes NO claim about, and
// has NO dependency on, the ride-slot/scoring engine (lib/domain/services/
// scoring_engine.dart, slot_generator.dart) — it operates purely on the
// Set<DateTime> already produced by the Availability screen's drag handlers.

/// Counts the number of distinct same-day, consecutive-hour runs in [cells].
///
/// A "run" is a maximal group of cells that share the same calendar day
/// (year/month/day) and whose hours form a contiguous ascending sequence
/// (e.g. 9, 10, 11 is one run of 3; 9, 10, then 14 is two runs: {9,10} and
/// {14}). Cells with the same hour but on different calendar days always
/// count as separate runs — hours never "wrap" or connect across days.
///
/// Returns 0 for an empty [cells] set.
int countSelectionRuns(Set<DateTime> cells) {
  if (cells.isEmpty) return 0;

  // Group hours by calendar day (day-only key, ignoring hour/minute/etc).
  final Map<DateTime, List<int>> hoursByDay = {};
  for (final cell in cells) {
    final dayKey = DateTime(cell.year, cell.month, cell.day);
    hoursByDay.putIfAbsent(dayKey, () => []).add(cell.hour);
  }

  var runCount = 0;
  for (final hours in hoursByDay.values) {
    hours.sort();
    var previousHour = -2; // Sentinel: never adjacent to a real hour (0-23).
    for (final hour in hours) {
      if (hour != previousHour + 1) {
        runCount++;
      }
      previousHour = hour;
    }
  }
  return runCount;
}
