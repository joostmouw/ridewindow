// lib/features/agenda/week_agenda_screen.dart
// Week Agenda: 10-day time grid with blocked hours and ride slot overlays.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const double _cellWidth = 56.0;
const double _cellHeight = 52.0;
const double _hourLabelWidth = 44.0;
const double _headerHeight = 52.0;
const int _firstHour = 6;
const int _lastHour = 22;
const int _dayCount = 10;

const Color _colorPerfect = Color(0xFF2E7D32);
const Color _colorGreat = Color(0xFF81C784);
const Color _colorAcceptable = Color(0xFFFFB74D);
const Color _colorBlocked = Color(0xFFE0E0E0);
const Color _colorFree = Colors.white;
const Color _colorBorder = Color(0xFFF0F0F0);
const Color _colorTodayText = Color(0xFF2E7D32);
const Color _colorNormalDayText = Color(0xFF666666);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns the set of blocked hours (as integers) for [targetDay] by
/// projecting the current week's pattern onto [targetDay]'s weekday.
Set<int> _blockedHoursForDay(
  DateTime targetDay,
  Map<DateTime, BlockType> blockedHours,
) {
  final now = DateTime.now();
  final weekStart = DateTime.utc(
    now.year,
    now.month,
    now.day - (now.weekday - 1),
  );
  final equivalentDay = weekStart.add(Duration(days: targetDay.weekday - 1));

  final result = <int>{};
  for (final entry in blockedHours.entries) {
    final k = entry.key;
    if (k.year == equivalentDay.year &&
        k.month == equivalentDay.month &&
        k.day == equivalentDay.day) {
      result.add(k.hour);
    }
  }
  return result;
}

/// Returns the first slot overlapping the cell [cellStart, cellStart+1h),
/// or null if none.
RideSlot? _overlappingSlot(DateTime cellStart, List<RideSlot> slots) {
  final cellEnd = cellStart.add(const Duration(hours: 1));
  for (final s in slots) {
    if (s.start.isBefore(cellEnd) && s.end.isAfter(cellStart)) {
      return s;
    }
  }
  return null;
}

Color _tierColor(RideTier tier) {
  return switch (tier) {
    Perfect() => _colorPerfect,
    Great() => _colorGreat,
    Acceptable() => _colorAcceptable,
    Poor() => _colorBlocked,
  };
}

// ---------------------------------------------------------------------------
// WeekAgendaScreen
// ---------------------------------------------------------------------------

class WeekAgendaScreen extends ConsumerWidget {
  const WeekAgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsState = ref.watch(slotsProvider);
    final availValue = ref.watch(availabilityProvider);

    final slots = (slotsState is SlotsLoaded) ? slotsState.slots : <RideSlot>[];
    final blockedHours = availValue.value ?? <DateTime, BlockType>{};

    final now = DateTime.now();
    // Build list of 10 days starting from today.
    final days = List.generate(
      _dayCount,
      (i) => DateTime(now.year, now.month, now.day + i),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: Column(
        children: [
          Expanded(
            child: _AgendaGrid(
              days: days,
              slots: slots,
              blockedHours: blockedHours,
              today: DateTime(now.year, now.month, now.day),
            ),
          ),
          const _Legend(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AgendaGrid: scrollable time grid
// ---------------------------------------------------------------------------

class _AgendaGrid extends StatelessWidget {
  const _AgendaGrid({
    required this.days,
    required this.slots,
    required this.blockedHours,
    required this.today,
  });

  final List<DateTime> days;
  final List<RideSlot> slots;
  final Map<DateTime, BlockType> blockedHours;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    // Layout:
    // Row
    //   ├── Fixed hour-label column (scrolls vertically with outer scroll)
    //   └── Expanded: SingleChildScrollView(horizontal)
    //         └── Column
    //               ├── Day header row
    //               └── Grid rows (06-22)
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed left column: corner + hour labels
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Corner spacer aligned with day header row
              const SizedBox(width: _hourLabelWidth, height: _headerHeight),
              for (int h = _firstHour; h <= _lastHour; h++)
                _HourLabel(hour: h),
            ],
          ),
          // Horizontally scrolling area: header + cells
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day header row
                  _DayHeaderRow(days: days, today: today),
                  // Cell rows for each hour
                  for (int h = _firstHour; h <= _lastHour; h++)
                    Row(
                      children: [
                        for (final day in days)
                          _GridCell(
                            day: day,
                            hour: h,
                            slots: slots,
                            blockedHoursForDay:
                                _blockedHoursForDay(day, blockedHours),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _DayHeaderRow
// ---------------------------------------------------------------------------

class _DayHeaderRow extends StatelessWidget {
  const _DayHeaderRow({required this.days, required this.today});

  final List<DateTime> days;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          for (final day in days)
            _DayHeaderCell(day: day, today: today),
        ],
      ),
    );
  }
}

class _DayHeaderCell extends StatelessWidget {
  const _DayHeaderCell({required this.day, required this.today});

  final DateTime day;
  final DateTime today;

  static const _weekdayLabels = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];

  @override
  Widget build(BuildContext context) {
    final isToday = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    final color = isToday ? _colorTodayText : _colorNormalDayText;
    // weekday: 1=Mon ... 7=Sun
    final label = _weekdayLabels[day.weekday - 1];

    return SizedBox(
      width: _cellWidth,
      height: _headerHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HourLabel
// ---------------------------------------------------------------------------

class _HourLabel extends StatelessWidget {
  const _HourLabel({required this.hour});

  final int hour;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _hourLabelWidth,
      height: _cellHeight,
      child: Center(
        child: Text(
          '${hour.toString().padLeft(2, '0')}:00',
          style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GridCell
// ---------------------------------------------------------------------------

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.day,
    required this.hour,
    required this.slots,
    required this.blockedHoursForDay,
  });

  final DateTime day;
  final int hour;
  final List<RideSlot> slots;
  final Set<int> blockedHoursForDay;

  @override
  Widget build(BuildContext context) {
    // Use UTC key to match AvailabilityNotifier storage format.
    final cellStart = DateTime.utc(day.year, day.month, day.day, hour);

    final isBlocked = blockedHoursForDay.contains(hour);
    final overlap = _overlappingSlot(cellStart, slots);

    Color bgColor;
    if (overlap != null) {
      bgColor = _tierColor(overlap.tier);
    } else if (isBlocked) {
      bgColor = _colorBlocked;
    } else {
      bgColor = _colorFree;
    }

    return Container(
      width: _cellWidth,
      height: _cellHeight,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: _colorBorder, width: 0.5),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _Legend
// ---------------------------------------------------------------------------

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(color: _colorFree, label: 'Vrij', bordered: true),
          SizedBox(width: 16),
          _LegendItem(color: _colorBlocked, label: 'Geblokkeerd'),
          SizedBox(width: 16),
          _LegendItem(color: _colorPerfect, label: 'Rijvenster'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.bordered = false,
  });

  final Color color;
  final String label;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: bordered ? const Color(0xFFCCCCCC) : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
