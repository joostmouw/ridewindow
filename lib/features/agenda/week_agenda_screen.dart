// lib/features/agenda/week_agenda_screen.dart
// Week Agenda: horizontal day columns with weather quality + availability overlay.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const int _firstHour = 6;
const int _lastHour = 22;
const int _dayCount = 10;
const double _dayColumnWidth = 72.0;
const double _hourBlockHeight = 38.0;
const double _headerHeight = 56.0;
const double _hourLabelWidth = 44.0;

// Tier colors
const Color _colorPerfect = Color(0xFF2E7D32);
const Color _colorGreat = Color(0xFF66BB6A);
const Color _colorAcceptable = Color(0xFFFFB74D);
const Color _colorNoData = Color(0xFFF5F5F5);
const Color _colorBlocked = Color(0x55E53935);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Color _tierColor(RideTier tier) {
  return switch (tier) {
    Perfect() => _colorPerfect,
    Great() => _colorGreat,
    Acceptable() => _colorAcceptable,
    Poor() => const Color(0xFFEF9A9A),
  };
}

Color _scoreToColor(double score) {
  if (score >= 80) return _colorPerfect;
  if (score >= 60) return _colorGreat;
  if (score >= 40) return _colorAcceptable;
  return const Color(0xFFEF9A9A);
}

/// Check if a given hour on a given day is blocked, by projecting the weekly
/// availability pattern onto the target date.
bool _isHourBlocked(
  DateTime targetDay,
  int hour,
  Map<DateTime, BlockType> blockedHours,
) {
  final now = DateTime.now();
  final weekStart = DateTime.utc(
    now.year,
    now.month,
    now.day - (now.weekday - 1),
  );
  final equivalentDay = weekStart.add(Duration(days: targetDay.weekday - 1));
  final key = DateTime.utc(equivalentDay.year, equivalentDay.month, equivalentDay.day, hour);
  return blockedHours.containsKey(key);
}

/// Find the ride slot that covers this hour cell, if any.
RideSlot? _slotForHour(DateTime day, int hour, List<RideSlot> slots) {
  final cellStart = DateTime(day.year, day.month, day.day, hour);
  final cellEnd = cellStart.add(const Duration(hours: 1));
  for (final s in slots) {
    if (s.start.isBefore(cellEnd) && s.end.isAfter(cellStart)) {
      return s;
    }
  }
  return null;
}

/// Get the hourly score for a specific hour on a specific day.
HourlyScore? _scoreForHour(DateTime day, int hour, List<HourlyScore> scores) {
  for (final s in scores) {
    if (s.time.year == day.year &&
        s.time.month == day.month &&
        s.time.day == day.day &&
        s.time.hour == hour) {
      return s;
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// WeekAgendaScreen
// ---------------------------------------------------------------------------

class WeekAgendaScreen extends ConsumerStatefulWidget {
  const WeekAgendaScreen({super.key});

  @override
  ConsumerState<WeekAgendaScreen> createState() => _WeekAgendaScreenState();
}

class _WeekAgendaScreenState extends ConsumerState<WeekAgendaScreen> {
  bool _showBlocked = true;

  @override
  Widget build(BuildContext context) {
    final slotsState = ref.watch(slotsProvider);
    final availValue = ref.watch(availabilityProvider);
    final slots = (slotsState is SlotsLoaded) ? slotsState.slots : <RideSlot>[];
    final blockedHours = availValue.value ?? <DateTime, BlockType>{};

    // Collect all hourly scores from all slots for coloring individual hours
    final allScores = <HourlyScore>[];
    for (final slot in slots) {
      allScores.addAll(slot.hours);
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(_dayCount, (i) => today.add(Duration(days: i)));

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bloktijden',
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
              ),
              Switch(
                value: _showBlocked,
                onChanged: (v) => setState(() => _showBlocked = v),
                activeTrackColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Legend
          _Legend(showBlocked: _showBlocked),
          const Divider(height: 1),
          // Grid
          Expanded(
            child: _AgendaGrid(
              days: days,
              today: today,
              slots: slots,
              allScores: allScores,
              blockedHours: blockedHours,
              showBlocked: _showBlocked,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _Legend
// ---------------------------------------------------------------------------

class _Legend extends StatelessWidget {
  const _Legend({required this.showBlocked});

  final bool showBlocked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const _LegendDot(color: _colorPerfect, label: 'Perfect'),
          const SizedBox(width: 12),
          const _LegendDot(color: _colorGreat, label: 'Geweldig'),
          const SizedBox(width: 12),
          const _LegendDot(color: _colorAcceptable, label: 'Oké'),
          if (showBlocked) ...[
            const SizedBox(width: 12),
            const _LegendDot(color: Color(0xFFE53935), label: 'Bezet'),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _AgendaGrid — fixed hour labels + horizontally scrolling day columns
// ---------------------------------------------------------------------------

class _AgendaGrid extends StatelessWidget {
  const _AgendaGrid({
    required this.days,
    required this.today,
    required this.slots,
    required this.allScores,
    required this.blockedHours,
    required this.showBlocked,
  });

  final List<DateTime> days;
  final DateTime today;
  final List<RideSlot> slots;
  final List<HourlyScore> allScores;
  final Map<DateTime, BlockType> blockedHours;
  final bool showBlocked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Fixed hour labels on the left
        SizedBox(
          width: _hourLabelWidth,
          child: Column(
            children: [
              SizedBox(height: _headerHeight),
              for (int h = _firstHour; h <= _lastHour; h++)
                SizedBox(
                  height: _hourBlockHeight,
                  child: Center(
                    child: Text(
                      '${h.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Horizontally scrollable day columns
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final day in days)
                  _DayColumn(
                    day: day,
                    isToday: day == today,
                    slots: slots,
                    allScores: allScores,
                    blockedHours: blockedHours,
                    showBlocked: showBlocked,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _DayColumn — one vertical column per day
// ---------------------------------------------------------------------------

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.isToday,
    required this.slots,
    required this.allScores,
    required this.blockedHours,
    required this.showBlocked,
  });

  final DateTime day;
  final bool isToday;
  final List<RideSlot> slots;
  final List<HourlyScore> allScores;
  final Map<DateTime, BlockType> blockedHours;
  final bool showBlocked;

  static final _dayFmt = DateFormat('EEE', 'nl_NL');

  @override
  Widget build(BuildContext context) {
    final dayLabel = isToday ? 'Vandaag' : _dayFmt.format(day);
    final dateLabel = '${day.day}/${day.month}';

    return SizedBox(
      width: _dayColumnWidth,
      child: Column(
        children: [
          // Day header
          Container(
            height: _headerHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF666666),
                  ),
                ),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          // Hour blocks
          for (int h = _firstHour; h <= _lastHour; h++)
            _HourBlock(
              day: day,
              hour: h,
              slots: slots,
              allScores: allScores,
              blockedHours: blockedHours,
              showBlocked: showBlocked,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HourBlock — single cell showing weather quality + optional blocked overlay
// ---------------------------------------------------------------------------

class _HourBlock extends StatelessWidget {
  const _HourBlock({
    required this.day,
    required this.hour,
    required this.slots,
    required this.allScores,
    required this.blockedHours,
    required this.showBlocked,
  });

  final DateTime day;
  final int hour;
  final List<RideSlot> slots;
  final List<HourlyScore> allScores;
  final Map<DateTime, BlockType> blockedHours;
  final bool showBlocked;

  @override
  Widget build(BuildContext context) {
    final slot = _slotForHour(day, hour, slots);
    final blocked = _isHourBlocked(day, hour, blockedHours);

    // Determine background color based on weather quality
    Color bgColor;
    String? label;

    if (slot != null) {
      // This hour is part of a ride slot — color by tier
      bgColor = _tierColor(slot.tier);
      // Show score on the first hour of the slot
      if (slot.start.hour == hour) {
        label = '${slot.overallScore.round()}';
      }
    } else {
      // Check hourly scores for weather coloring even outside slots
      final score = _scoreForHour(day, hour, allScores);
      if (score != null) {
        bgColor = _scoreToColor(score.overall);
      } else {
        bgColor = _colorNoData;
      }
    }

    return Container(
      width: _dayColumnWidth,
      height: _hourBlockHeight,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: slot != null
            ? Border.all(color: _tierColor(slot.tier), width: 1.5)
            : null,
      ),
      child: Stack(
        children: [
          // Score label
          if (label != null)
            Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          // Blocked overlay (diagonal stripes effect via icon)
          if (showBlocked && blocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: _colorBlocked,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(
                    Icons.block,
                    size: 16,
                    color: Color(0xAAE53935),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
