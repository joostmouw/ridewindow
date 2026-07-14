import 'package:ridewindow/providers/availability_notifier.dart';

/// Pure fill-range logic for the two-tap range-select flow on the
/// Availability grid (RNE-01/RNE-02).
///
/// Given an [anchorKey] (the first tap that opened a pending block) and a
/// [secondTapKey] (the tap that closes it), returns the inclusive list of
/// hour keys between them on the SAME calendar day, in ascending hour order.
/// The order in which [anchorKey]/[secondTapKey] are supplied does not affect
/// the result — the range is always normalized to ascending hour order.
///
/// Hours already marked [BlockType.work] or [BlockType.calendar] in
/// [blockedHours] are deliberately skipped (not overwritten) — they remain
/// gaps in the returned range rather than being silently filled in. Hours
/// already marked [BlockType.custom] ARE included, since custom entries are
/// toggleable and are meant to be part of a range fill.
///
/// This function is day-scoped only: [anchorKey] and [secondTapKey] must
/// share the same calendar day (year/month/day). Cross-day handling (closing
/// the old anchor's block standalone and opening a new one on a different
/// day) is the caller's responsibility.
List<DateTime> computeRangeFillKeys({
  required DateTime anchorKey,
  required DateTime secondTapKey,
  required Map<DateTime, BlockType> blockedHours,
}) {
  assert(
    anchorKey.year == secondTapKey.year &&
        anchorKey.month == secondTapKey.month &&
        anchorKey.day == secondTapKey.day,
    'computeRangeFillKeys is day-scoped only — anchorKey and secondTapKey must share the same calendar day',
  );

  final startHour = anchorKey.hour < secondTapKey.hour ? anchorKey.hour : secondTapKey.hour;
  final endHour = anchorKey.hour > secondTapKey.hour ? anchorKey.hour : secondTapKey.hour;

  final result = <DateTime>[];
  for (var h = startHour; h <= endHour; h++) {
    final key = DateTime.utc(anchorKey.year, anchorKey.month, anchorKey.day, h);
    final blockType = blockedHours[key];
    if (blockType == BlockType.work || blockType == BlockType.calendar) {
      continue;
    }
    result.add(key);
  }
  return result;
}
