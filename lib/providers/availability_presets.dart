// lib/providers/availability_presets.dart
// Pure Dart — geen riverpod_annotation, geen Flutter imports.
// Geen part directive.

import 'package:ridewindow/providers/availability_notifier.dart';

enum AvailabilityPreset {
  eveningsAndWeekends,
  morningsAndWeekends,
  weekendsOnly,
  custom,
}

/// Bouwt een `Map<DateTime, BlockType>` van work-geblokkeerde uren voor [preset].
///
/// [weekStart] moet een maandag zijn (weekday == DateTime.monday).
/// Uren die NIET in de map staan zijn vrij.
/// Presets seeden uitsluitend [BlockType.work] entries.
Map<DateTime, BlockType> buildPreset(
  AvailabilityPreset preset,
  DateTime weekStart,
) {
  assert(
    weekStart.weekday == DateTime.monday,
    'weekStart moet een maandag zijn, was: ${weekStart.weekday}',
  );

  if (preset == AvailabilityPreset.custom) return {};

  final result = <DateTime, BlockType>{};

  for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
    final day = weekStart.add(Duration(days: dayOffset));
    final isWeekend = day.weekday == DateTime.saturday ||
        day.weekday == DateTime.sunday;

    for (var hour = 0; hour < 24; hour++) {
      final dt = DateTime(day.year, day.month, day.day, hour);
      final isWork = _isWorkHour(preset, isWeekend, hour);
      if (isWork) {
        result[dt] = BlockType.work;
      }
    }
  }

  return result;
}

/// Retourneert true als dit uur work-geblokkeerd moet zijn voor [preset].
bool _isWorkHour(AvailabilityPreset preset, bool isWeekend, int hour) {
  switch (preset) {
    case AvailabilityPreset.eveningsAndWeekends:
      // Vrij: ma-vr 17:00-23:00 (uur 17 t/m 22) + za/zo alle uren
      if (isWeekend) return false;
      if (hour >= 17 && hour <= 22) return false;
      return true;

    case AvailabilityPreset.morningsAndWeekends:
      // Vrij: ma-vr 06:00-09:00 (uur 6, 7, 8) + za/zo alle uren
      if (isWeekend) return false;
      if (hour >= 6 && hour <= 8) return false;
      return true;

    case AvailabilityPreset.weekendsOnly:
      // Vrij: za/zo alle uren
      if (isWeekend) return false;
      return true;

    case AvailabilityPreset.custom:
      return false;
  }
}
