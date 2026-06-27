// AVAIL-01, AVAIL-02, AVAIL-03: 7x24 interactief rooster
// D-06-04: ConsumerStatefulWidget - drag state + alle persistent state in AvailabilityNotifier
// D-06-05: huidige week, maandag als startdag
// D-06-06: BlockType.work is niet toggelbaar
// BACKLOG-15: drag-to-select + rij/kolom-header taps + full-width grid + legenda + rider profile

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/services/calendar_service.dart';
import 'package:ridewindow/theme/app_theme.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  ConsumerState<AvailabilityScreen> createState() =>
      _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  // Import state
  bool _isImporting = false;

  // Drag state
  bool _isDragging = false;
  bool _dragBlocking = true;
  final Set<DateTime> _draggedCells = {};

  List<String> _dagLabels(BuildContext context) {
    final s = S.of(context);
    return [s.dayShortMon, s.dayShortTue, s.dayShortWed, s.dayShortThu, s.dayShortFri, s.dayShortSat, s.dayShortSun];
  }

  final GlobalKey _gridKey = GlobalKey();

  // Dynamische cel-afmetingen (berekend in build)
  double _cellWidth = 0;
  double _cellHeight = 0;
  static const double _headerWidth = 36;
  static const double _headerHeight = 28;

  @override
  Widget build(BuildContext context) {
    final availValue = ref.watch(availabilityProvider);
    return availValue.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).availabilityTitle),
          leading: const BackButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).availabilityTitle),
          leading: const BackButton(),
        ),
        body: Center(child: Text('Error: $e')),
      ),
      data: (blockedHours) {
        final now = DateTime.now();
        final weekStart =
            now.subtract(Duration(days: now.weekday - DateTime.monday));
        return _buildGrid(context, blockedHours, weekStart);
      },
    );
  }

  Widget _buildGrid(
    BuildContext context,
    Map<DateTime, BlockType> blockedHours,
    DateTime weekStart,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).availabilityTitle),
        leading: const BackButton(),
        actions: [
          _isImporting
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.event),
                  tooltip: S.of(context).importFromCalendar,
                  onPressed: () => _importFromCalendar(weekStart),
                ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Bereken celgrootte op basis van beschikbare breedte
          _cellWidth = (constraints.maxWidth - _headerWidth) / 7;
          // Hoogte: beschikbare hoogte minus legenda/profiel ruimte, gedeeld door 24 uur + header
          final availableHeight = constraints.maxHeight - 140; // ruimte voor legenda + profiel
          _cellHeight = (availableHeight - _headerHeight) / 24;
          // Minimum celgrootte
          if (_cellHeight < 16) _cellHeight = 16;

          return Column(
            children: [
              // Grid
              Expanded(
                child: GestureDetector(
                  onPanStart: (details) =>
                      _onDragStart(details, blockedHours, weekStart),
                  onPanUpdate: (details) =>
                      _onDragUpdate(details, blockedHours, weekStart),
                  onPanEnd: (_) => _onDragEnd(blockedHours, weekStart),
                  child: SingleChildScrollView(
                    child: Column(
                      key: _gridKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header-rij
                        Row(
                          children: [
                            const SizedBox(
                                width: _headerWidth, height: _headerHeight,),
                            for (int d = 0; d < 7; d++)
                              GestureDetector(
                                onTap: () => _onDayHeaderTap(
                                    d, blockedHours, weekStart,),
                                child: SizedBox(
                                  width: _cellWidth,
                                  height: _headerHeight,
                                  child: Center(
                                    child: Text(
                                      _dagLabels(context)[d],
                                      style: TextStyle(
                                        fontSize: _cellWidth > 40 ? 13 : 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Uur-rijen
                        for (int hour = 0; hour < 24; hour++)
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _onHourHeaderTap(
                                    hour, blockedHours, weekStart,),
                                child: SizedBox(
                                  width: _headerWidth,
                                  height: _cellHeight,
                                  child: Center(
                                    child: Text(
                                      '${hour.toString().padLeft(2, '0')}:00',
                                      style: TextStyle(
                                        fontSize: _cellHeight > 20 ? 10 : 8,
                                        color: context.rw.textTertiary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              for (int dayIndex = 0; dayIndex < 7; dayIndex++)
                                _buildCell(
                                    blockedHours, weekStart, dayIndex, hour,),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Legenda
              _buildLegend(context, blockedHours),
              // Rider profile
              _buildRiderProfile(context, blockedHours, weekStart),
              // "Klaar" knop wanneer vanuit onboarding
              if (widget.fromOnboarding)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('onboarding_complete', true);
                        if (mounted) context.go('/home');
                      },
                      child: Text(S.of(context).onboardingNext),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCell(
    Map<DateTime, BlockType> blockedHours,
    DateTime weekStart,
    int dayIndex,
    int hour,
  ) {
    final key = _cellKey(weekStart, dayIndex, hour);
    final isDragHighlighted = _isDragging && _draggedCells.contains(key);
    final rw = context.rw;
    final color = _cellColor(key, blockedHours, isDragHighlighted, rw);

    return GestureDetector(
      onTap: () => _onCellTap(key, blockedHours),
      child: Container(
        width: _cellWidth,
        height: _cellHeight,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: rw.border,
            width: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, Map<DateTime, BlockType> blockedHours) {
    final hasWork = blockedHours.values.any((b) => b == BlockType.work);
    final hasCalendar = blockedHours.values.any((b) => b == BlockType.calendar);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(Theme.of(context).colorScheme.surface, S.of(context).legendFree, context),
          _legendItem(context.rw.availCustom, S.of(context).legendBusy, context),
          if (hasWork)
            _legendItem(context.rw.availWork, S.of(context).legendWork, context),
          if (hasCalendar)
            _legendItem(context.rw.availCalendar, S.of(context).legendCalendar, context),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: context.rw.border, width: 0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildRiderProfile(
    BuildContext context,
    Map<DateTime, BlockType> blockedHours,
    DateTime weekStart,
  ) {
    final profile = _analyzeRiderProfile(context, blockedHours, weekStart);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            profile.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  profile.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Rider profile analyse ---

  ({String icon, String title, String description}) _analyzeRiderProfile(
    BuildContext context,
    Map<DateTime, BlockType> blockedHours,
    DateTime weekStart,
  ) {
    final s = S.of(context);
    int weekdayFreeHours = 0; // ma-vr
    int weekendFreeHours = 0; // za-zo
    int morningFree = 0; // 6-12
    int afternoonFree = 0; // 12-17
    int eveningFree = 0; // 17-22
    int totalFree = 0;

    for (int d = 0; d < 7; d++) {
      for (int h = 0; h < 24; h++) {
        final key = _cellKey(weekStart, d, h);
        final isBlocked = blockedHours.containsKey(key);
        if (!isBlocked) {
          totalFree++;
          if (d < 5) {
            weekdayFreeHours++;
          } else {
            weekendFreeHours++;
          }
          if (h >= 6 && h < 12) morningFree++;
          if (h >= 12 && h < 17) afternoonFree++;
          if (h >= 17 && h < 22) eveningFree++;
        }
      }
    }

    if (totalFree == 0) {
      return (
        icon: '\u{1F62E}',
        title: s.riderNoTime,
        description: s.riderNoTimeDesc,
      );
    }

    if (totalFree >= 140) {
      return (
        icon: '\u{1F6B4}',
        title: s.riderFulltime,
        description: s.riderFulltimeDesc,
      );
    }

    // Weekend warrior: meeste vrije uren in het weekend
    if (weekendFreeHours > weekdayFreeHours && weekendFreeHours >= 16) {
      return (
        icon: '\u{1F3D4}\u{FE0F}',
        title: s.riderWeekend,
        description: s.riderWeekendDesc,
      );
    }

    // Early bird: meeste vrije uren in de ochtend
    if (morningFree > afternoonFree && morningFree > eveningFree) {
      return (
        icon: '\u{1F305}',
        title: s.riderEarlyBird,
        description: s.riderEarlyBirdDesc,
      );
    }

    // After-work rider
    if (eveningFree > morningFree && eveningFree > afternoonFree) {
      return (
        icon: '\u{1F307}',
        title: s.riderAfterWork,
        description: s.riderAfterWorkDesc,
      );
    }

    // Lunch rider
    if (afternoonFree > morningFree && afternoonFree > eveningFree) {
      return (
        icon: '\u{2600}\u{FE0F}',
        title: s.riderAfternoon,
        description: s.riderAfternoonDesc,
      );
    }

    // Busy but making it work
    if (totalFree < 40) {
      return (
        icon: '\u{1F4AA}',
        title: s.riderBusy,
        description: s.riderBusyDesc,
      );
    }

    return (
      icon: '\u{1F6B2}',
      title: s.riderFlexible,
      description: s.riderFlexibleDesc,
    );
  }

  // --- Cell colors ---

  Color _cellColor(
    DateTime key,
    Map<DateTime, BlockType> blocked,
    bool isDragHighlighted,
    RideWindowTheme rw,
  ) {
    if (isDragHighlighted) {
      if (_dragBlocking) {
        return rw.availCustomLight;
      } else {
        return rw.availWorkLight;
      }
    }
    return switch (blocked[key]) {
      BlockType.work => rw.availWork,
      BlockType.custom => rw.availCustom,
      BlockType.calendar => rw.availCalendar,
      null => Theme.of(context).colorScheme.surface,
    };
  }

  // --- Single cell tap ---

  void _onCellTap(DateTime key, Map<DateTime, BlockType> blocked) {
    if (blocked[key] == BlockType.work || blocked[key] == BlockType.calendar) return;
    HapticFeedback.lightImpact();
    ref.read(availabilityProvider.notifier).toggleCustomHour(key);
  }

  // --- Drag-to-select ---

  ({int dayIndex, int hour})? _hitTest(Offset globalPosition) {
    final renderBox =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final local = renderBox.globalToLocal(globalPosition);

    final dayIndex = ((local.dx - _headerWidth) / _cellWidth).floor();
    final hour = ((local.dy - _headerHeight) / _cellHeight).floor();

    if (dayIndex < 0 || dayIndex > 6 || hour < 0 || hour > 23) return null;
    return (dayIndex: dayIndex, hour: hour);
  }

  void _onDragStart(
    DragStartDetails details,
    Map<DateTime, BlockType> blockedHours,
    DateTime weekStart,
  ) {
    final hit = _hitTest(details.globalPosition);
    if (hit == null) return;

    final key = _cellKey(weekStart, hit.dayIndex, hit.hour);
    if (blockedHours[key] == BlockType.work || blockedHours[key] == BlockType.calendar) return;

    setState(() {
      _isDragging = true;
      _dragBlocking = blockedHours[key] != BlockType.custom;
      _draggedCells.clear();
      _draggedCells.add(key);
    });
    HapticFeedback.lightImpact();
  }

  void _onDragUpdate(
    DragUpdateDetails details,
    Map<DateTime, BlockType> blockedHours,
    DateTime weekStart,
  ) {
    if (!_isDragging) return;
    final hit = _hitTest(details.globalPosition);
    if (hit == null) return;

    final key = _cellKey(weekStart, hit.dayIndex, hit.hour);
    if (blockedHours[key] == BlockType.work || blockedHours[key] == BlockType.calendar) return;

    if (!_draggedCells.contains(key)) {
      setState(() {
        _draggedCells.add(key);
      });
      HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(
    Map<DateTime, BlockType> blockedHours,
    DateTime weekStart,
  ) {
    if (!_isDragging) return;

    final cells = _draggedCells.toList();
    ref
        .read(availabilityProvider.notifier)
        .setCustomHours(cells, block: _dragBlocking);

    setState(() {
      _isDragging = false;
      _draggedCells.clear();
    });
  }

  // --- Header taps ---

  void _onDayHeaderTap(
    int dayIndex,
    Map<DateTime, BlockType> blockedHours,
    DateTime weekStart,
  ) {
    final keys = <DateTime>[];
    int customCount = 0;
    int freeCount = 0;

    for (int h = 0; h < 24; h++) {
      final key = _cellKey(weekStart, dayIndex, h);
      if (blockedHours[key] == BlockType.work || blockedHours[key] == BlockType.calendar) continue;
      keys.add(key);
      if (blockedHours[key] == BlockType.custom) {
        customCount++;
      } else {
        freeCount++;
      }
    }
    if (keys.isEmpty) return;

    final block = freeCount >= customCount;
    HapticFeedback.mediumImpact();
    ref.read(availabilityProvider.notifier).setCustomHours(keys, block: block);
  }

  void _onHourHeaderTap(
    int hour,
    Map<DateTime, BlockType> blockedHours,
    DateTime weekStart,
  ) {
    final keys = <DateTime>[];
    int customCount = 0;
    int freeCount = 0;

    for (int d = 0; d < 7; d++) {
      final key = _cellKey(weekStart, d, hour);
      if (blockedHours[key] == BlockType.work || blockedHours[key] == BlockType.calendar) continue;
      keys.add(key);
      if (blockedHours[key] == BlockType.custom) {
        customCount++;
      } else {
        freeCount++;
      }
    }
    if (keys.isEmpty) return;

    final block = freeCount >= customCount;
    HapticFeedback.mediumImpact();
    ref.read(availabilityProvider.notifier).setCustomHours(keys, block: block);
  }

  // --- Google Calendar import ---

  Future<void> _importFromCalendar(DateTime weekStart) async {
    setState(() => _isImporting = true);
    try {
      final weekEnd = weekStart.add(const Duration(days: 7));
      final events = await CalendarService().getEvents(weekStart, weekEnd);

      // Converteer event-ranges naar uurblokken
      final calendarBlocks = <DateTime, BlockType>{};
      for (final event in events) {
        var hour = DateTime.utc(
          event.start.year,
          event.start.month,
          event.start.day,
          event.start.hour,
        );
        final end = event.end;
        while (hour.isBefore(end)) {
          calendarBlocks[hour] = BlockType.calendar;
          hour = hour.add(const Duration(hours: 1));
        }
      }

      await ref
          .read(availabilityProvider.notifier)
          .importCalendarBlocks(calendarBlocks);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).calendarImportSuccess),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('geannuleerd') || e.toString().contains('cancelled')
                  ? S.of(context).calendarSignInCanceled
                  : S.of(context).calendarImportError,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // --- Helpers ---

  DateTime _cellKey(DateTime weekStart, int dayIndex, int hour) =>
      DateTime.utc(
        weekStart.year,
        weekStart.month,
        weekStart.day + dayIndex,
        hour,
      );
}
