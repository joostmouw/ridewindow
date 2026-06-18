import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/features/detail/detail_args.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/hourly_scores_provider.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/features/shared/screen_hint_overlay.dart';

const int _kDayCount = 7;
const _kHours = [6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22];

Color _scoreColor(double score) {
  if (score >= 85) return const Color(0xFF2E7D32);
  if (score >= 70) return const Color(0xFF66BB6A);
  if (score >= 50) return const Color(0xFFFFB74D);
  return const Color(0xFFEF9A9A);
}

String _tierLabel(double score) {
  if (score >= 85) return 'Perfect';
  if (score >= 70) return 'Geweldig';
  if (score >= 50) return 'Oké';
  return 'Slecht';
}

HourlyScore? _findScore(DateTime day, int hour, List<HourlyScore> scores) {
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

HourlyForecast? _findForecast(DateTime day, int hour, List<HourlyForecast> forecasts) {
  for (final f in forecasts) {
    if (f.time.year == day.year &&
        f.time.month == day.month &&
        f.time.day == day.day &&
        f.time.hour == hour) {
      return f;
    }
  }
  return null;
}

bool _isBlocked(DateTime day, int hour, Map<DateTime, BlockType> blocked) {
  final now = DateTime.now();
  final weekStart = DateTime.utc(now.year, now.month, now.day - (now.weekday - 1));
  final equiv = weekStart.add(Duration(days: day.weekday - 1));
  final key = DateTime.utc(equiv.year, equiv.month, equiv.day, hour);
  return blocked.containsKey(key);
}

String _windDirection(double? deg) {
  if (deg == null) return '?';
  const dirs = ['N', 'NO', 'O', 'ZO', 'Z', 'ZW', 'W', 'NW'];
  return dirs[((deg + 22.5) % 360 ~/ 45)];
}

// ---------------------------------------------------------------------------
// Selection state: which day column + hour range is being selected
// ---------------------------------------------------------------------------

class _Selection {
  final int dayIndex;
  final int startHour;
  final int endHour; // inclusive

  const _Selection({required this.dayIndex, required this.startHour, required this.endHour});

  bool contains(int di, int hour) =>
      di == dayIndex && hour >= startHour && hour <= endHour;

  int get count => endHour - startHour + 1;
}

// ---------------------------------------------------------------------------
// Main screen
// ---------------------------------------------------------------------------

class WeekAgendaScreen extends ConsumerStatefulWidget {
  const WeekAgendaScreen({super.key});

  @override
  ConsumerState<WeekAgendaScreen> createState() => _WeekAgendaScreenState();
}

class _WeekAgendaScreenState extends ConsumerState<WeekAgendaScreen> {
  bool _showBlocked = true;
  bool _showHints = false;
  _Selection? _selection;

  // Keys for hit-testing during drag
  final _cellKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await shouldShowHint('agenda') && mounted) {
        setState(() => _showHints = true);
      }
    });
  }

  GlobalKey _keyFor(int dayIndex, int hour) {
    final k = '${dayIndex}_$hour';
    return _cellKeys.putIfAbsent(k, () => GlobalKey());
  }

  /// Find which cell (dayIndex, hour) is at a global position.
  (int, int)? _cellAt(Offset globalPos) {
    for (final entry in _cellKeys.entries) {
      final ro = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (ro == null || !ro.attached) continue;
      final pos = ro.localToGlobal(Offset.zero);
      final size = ro.size;
      if (globalPos.dx >= pos.dx &&
          globalPos.dx <= pos.dx + size.width &&
          globalPos.dy >= pos.dy &&
          globalPos.dy <= pos.dy + size.height) {
        final parts = entry.key.split('_');
        return (int.parse(parts[0]), int.parse(parts[1]));
      }
    }
    return null;
  }

  int? _dragStartHour;
  int? _dragDayIndex;

  void _onLongPressStart(LongPressStartDetails details) {
    final hit = _cellAt(details.globalPosition);
    if (hit == null) return;
    _dragDayIndex = hit.$1;
    _dragStartHour = hit.$2;
    setState(() {
      _selection = _Selection(dayIndex: hit.$1, startHour: hit.$2, endHour: hit.$2);
    });
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_dragDayIndex == null || _dragStartHour == null) return;
    final hit = _cellAt(details.globalPosition);
    if (hit == null || hit.$1 != _dragDayIndex) return;
    final h = hit.$2;
    final lo = h < _dragStartHour! ? h : _dragStartHour!;
    final hi = h > _dragStartHour! ? h : _dragStartHour!;
    setState(() {
      _selection = _Selection(dayIndex: _dragDayIndex!, startHour: lo, endHour: hi);
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    // Selection stays visible until user acts on it or taps elsewhere
    _dragStartHour = null;
    _dragDayIndex = null;
  }

  void _clearSelection() {
    setState(() => _selection = null);
  }

  void _planSelection(List<DateTime> days, List<HourlyScore> allScores) {
    final sel = _selection;
    if (sel == null) return;
    final day = days[sel.dayIndex];
    final start = day.add(Duration(hours: sel.startHour));
    final end = day.add(Duration(hours: sel.endHour + 1));

    // Average score over selected hours
    double sum = 0;
    int count = 0;
    for (var h = sel.startHour; h <= sel.endHour; h++) {
      final s = _findScore(day, h, allScores);
      if (s != null) {
        sum += s.overall;
        count++;
      }
    }
    final avgScore = count > 0 ? sum / count : 0.0;

    ref.read(plannedRidesProvider.notifier).add(
          PlannedRide(start: start, end: end, plannedScore: avgScore),
        );
    setState(() => _selection = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rit ingepland (${sel.count}u)!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slotsState = ref.watch(slotsProvider);
    final availValue = ref.watch(availabilityProvider);
    final allScores = ref.watch(allHourlyScoresProvider);
    final weatherValue = ref.watch(weatherProvider);
    final locationAsync = ref.watch(locationProvider);
    final slots = (slotsState is SlotsLoaded) ? slotsState.slots : <RideSlot>[];
    final blockedHours = availValue.value ?? <DateTime, BlockType>{};
    final forecasts = weatherValue.value ?? <HourlyForecast>[];
    final cityName = locationAsync.value?.city ?? '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(_kDayCount, (i) => today.add(Duration(days: i)));

    final theme = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          if (_selection != null) ...[
            TextButton(
              onPressed: _clearSelection,
              child: const Text('Annuleer'),
            ),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bezet', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface)),
              Switch(
                value: _showBlocked,
                onChanged: (v) => setState(() => _showBlocked = v),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Legend + selection hint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                if (_selection == null) ...[
                  const _Dot(color: Color(0xFF2E7D32), label: 'Perfect'),
                  const SizedBox(width: 10),
                  const _Dot(color: Color(0xFF66BB6A), label: 'Geweldig'),
                  const SizedBox(width: 10),
                  const _Dot(color: Color(0xFFFFB74D), label: 'Oké'),
                  const SizedBox(width: 10),
                  const _Dot(color: Color(0xFFEF9A9A), label: 'Slecht'),
                ] else ...[
                  Icon(Icons.touch_app, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${_selection!.count} uur geselecteerd',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Grid
          Expanded(
            child: GestureDetector(
              onLongPressStart: _onLongPressStart,
              onLongPressMoveUpdate: _onLongPressMoveUpdate,
              onLongPressEnd: _onLongPressEnd,
              child: _buildGrid(context, days, today, allScores, forecasts, cityName, blockedHours),
            ),
          ),
          // Selection action bar
          if (_selection != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _planSelection(days, allScores),
                    icon: const Icon(Icons.directions_bike),
                    label: Text('Rit inplannen (${_selection!.count}u)'),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
        if (_showHints)
          ScreenHintOverlay(
            hints: agendaHints,
            onDismiss: () {
              markHintSeen('agenda');
              setState(() => _showHints = false);
            },
          ),
      ],
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<DateTime> days,
    DateTime today,
    List<HourlyScore> allScores,
    List<HourlyForecast> forecasts,
    String cityName,
    Map<DateTime, BlockType> blockedHours,
  ) {
    final theme = Theme.of(context);
    final dayFmt = DateFormat('E', 'nl_NL');

    return Column(
      children: [
        // Day headers
        SizedBox(
          height: 36,
          child: Row(
            children: [
              const SizedBox(width: 28),
              for (var di = 0; di < days.length; di++)
                Expanded(
                  child: Container(
                    color: days[di] == today ? theme.colorScheme.primaryContainer : null,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          days[di] == today ? 'Nu' : dayFmt.format(days[di]),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: days[di] == today
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${days[di].day}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: days[di] == today
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Hour rows
        for (final hour in _kHours)
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Center(
                    child: Text(
                      '$hour',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                    ),
                  ),
                ),
                for (var di = 0; di < days.length; di++)
                  Expanded(
                    child: _CellWidget(
                      key: _keyFor(di, hour),
                      day: days[di],
                      dayIndex: di,
                      hour: hour,
                      allScores: allScores,
                      forecasts: forecasts,
                      cityName: cityName,
                      blockedHours: blockedHours,
                      showBlocked: _showBlocked,
                      isToday: days[di] == today,
                      isSelected: _selection?.contains(di, hour) ?? false,
                      onTap: _selection != null ? _clearSelection : null,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Legend dot
// ---------------------------------------------------------------------------

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Single cell
// ---------------------------------------------------------------------------

class _CellWidget extends ConsumerWidget {
  const _CellWidget({
    super.key,
    required this.day,
    required this.dayIndex,
    required this.hour,
    required this.allScores,
    required this.forecasts,
    required this.cityName,
    required this.blockedHours,
    required this.showBlocked,
    required this.isToday,
    required this.isSelected,
    this.onTap,
  });

  final DateTime day;
  final int dayIndex;
  final int hour;
  final List<HourlyScore> allScores;
  final List<HourlyForecast> forecasts;
  final String cityName;
  final Map<DateTime, BlockType> blockedHours;
  final bool showBlocked;
  final bool isToday;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = _findScore(day, hour, allScores);
    final blocked = showBlocked && _isBlocked(day, hour, blockedHours);
    final color = score != null ? _scoreColor(score.overall) : const Color(0xFFE0E0E0);

    return GestureDetector(
      onTap: onTap ?? () => _showDetail(context, ref, score),
      child: Container(
        margin: const EdgeInsets.all(0.5),
        decoration: BoxDecoration(
          color: blocked ? color.withAlpha(80) : color,
          borderRadius: BorderRadius.circular(3),
          border: isSelected
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        child: blocked
            ? const Center(child: Icon(Icons.block, size: 10, color: Color(0xAAE53935)))
            : isSelected
                ? Center(
                    child: Icon(Icons.check, size: 12, color: Theme.of(context).colorScheme.primary),
                  )
                : null,
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref, HourlyScore? score) {
    final forecast = _findForecast(day, hour, forecasts);
    if (score == null && forecast == null) return;

    final dayFmt = DateFormat('EEEE d MMMM', 'nl_NL');
    final theme = Theme.of(context);
    final tierColor = score != null ? _scoreColor(score.overall) : Colors.grey;
    final tierText = score != null ? _tierLabel(score.overall) : '?';

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayFmt.format(day),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text('$hour:00 – ${hour + 1}:00', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: tierColor, borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    score != null ? '${score.overall.round()} — $tierText' : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            if (cityName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(cityName, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            if (forecast != null) ...[
              _DetailRow(icon: Icons.thermostat, label: 'Temperatuur',
                value: '${forecast.temperatureC?.round() ?? '?'}°C (voelt als ${forecast.apparentTemperatureC?.round() ?? '?'}°C)'),
              const SizedBox(height: 8),
              _DetailRow(icon: Icons.water_drop, label: 'Neerslag',
                value: '${forecast.precipitationMm?.toStringAsFixed(1) ?? '?'} mm — ${forecast.precipitationProbability?.round() ?? '?'}% kans'),
              const SizedBox(height: 8),
              _DetailRow(icon: Icons.air, label: 'Wind',
                value: forecast.windspeedKmh != null && forecast.windspeedKmh! < 5
                    ? 'Windstil'
                    : forecast.windspeedKmh != null && forecast.windspeedKmh! >= 15 && forecast.winddirectionDeg != null
                        ? '${forecast.windspeedKmh!.round()} km/h ${_windDirection(forecast.winddirectionDeg)}'
                        : '${forecast.windspeedKmh?.round() ?? '?'} km/h'),
            ],
            if (score != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text('Score-opbouw', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              _ScoreBar(label: 'Temperatuur', value: score.temperatureScore),
              const SizedBox(height: 4),
              _ScoreBar(label: 'Regen', value: score.rainScore),
              const SizedBox(height: 4),
              _ScoreBar(label: 'Wind', value: score.windScore),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final start = day.add(Duration(hours: hour));
                    ref.read(plannedRidesProvider.notifier).add(
                      PlannedRide(start: start, end: start.add(const Duration(hours: 1)), plannedScore: score.overall),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rit ingepland!')),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Inplannen'),
                ),
              ),
              const SizedBox(height: 8),
              if (forecast != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final start = day.add(Duration(hours: hour));
                      final end = start.add(const Duration(hours: 1));
                      final slot = RideSlot(
                        start: start,
                        end: end,
                        overallScore: score.overall,
                        tier: rideTierFromScore(score.overall),
                        hours: [score],
                      );
                      context.push('/detail', extra: DetailArgs(slot: slot, forecasts: [forecast]));
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Bekijk details'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, textAlign: TextAlign.end)),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation(_scoreColor(value)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '${value.round()}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
