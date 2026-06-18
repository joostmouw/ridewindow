// AVAIL-01, AVAIL-02, AVAIL-03: 7x24 interactief rooster
// D-06-04: ConsumerStatefulWidget - drag state + alle persistent state in AvailabilityNotifier
// D-06-05: huidige week, maandag als startdag
// D-06-06: BlockType.work is niet toggelbaar
// BACKLOG-15: drag-to-select + rij/kolom-header taps + full-width grid + legenda + rider profile

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ridewindow/providers/availability_notifier.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() =>
      _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  // Drag state
  bool _isDragging = false;
  bool _dragBlocking = true;
  final Set<DateTime> _draggedCells = {};

  static const List<String> _dagLabels = [
    'Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo',
  ];

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
          title: const Text('Mijn schema'),
          leading: const BackButton(),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Mijn schema'),
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
        title: const Text('Mijn schema'),
        leading: const BackButton(),
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
                                      _dagLabels[d],
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
                                        color: Colors.grey.shade600,
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
              _buildLegend(context),
              // Rider profile
              _buildRiderProfile(context, blockedHours, weekStart),
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
    final color = _cellColor(key, blockedHours, isDragHighlighted);

    return GestureDetector(
      onTap: () => _onCellTap(key, blockedHours),
      child: Container(
        width: _cellWidth,
        height: _cellHeight,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(Colors.white, 'Vrij', context),
          _legendItem(const Color(0xFFFF9800), 'Bezet', context),
          _legendItem(const Color(0xFFB0BEC5), 'Werk', context),
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
            border: Border.all(color: Colors.grey.shade400, width: 0.5),
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
    final profile = _analyzeRiderProfile(blockedHours, weekStart);
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
    Map<DateTime, BlockType> blockedHours,
    DateTime weekStart,
  ) {
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
        title: 'Helemaal geen tijd?',
        description: 'Maak wat uren vrij om je perfecte rijmomenten te vinden.',
      );
    }

    if (totalFree >= 140) {
      return (
        icon: '\u{1F6B4}',
        title: 'Fulltime fietser',
        description:
            'Je schema staat wagenwijd open. Genoeg keuze uit de beste momenten.',
      );
    }

    // Weekend warrior: meeste vrije uren in het weekend
    if (weekendFreeHours > weekdayFreeHours && weekendFreeHours >= 16) {
      return (
        icon: '\u{1F3D4}\u{FE0F}',
        title: 'Weekendstrijder',
        description:
            'Het weekend is jouw speeltuin. We vinden de beste zaterdag- en zondagvensters.',
      );
    }

    // Early bird: meeste vrije uren in de ochtend
    if (morningFree > afternoonFree && morningFree > eveningFree) {
      return (
        icon: '\u{1F305}',
        title: 'Vroege vogel',
        description:
            'Je fietst voordat de wereld wakker wordt. Ochtendslots zijn jouw sweet spot.',
      );
    }

    // After-work rider
    if (eveningFree > morningFree && eveningFree > afternoonFree) {
      return (
        icon: '\u{1F307}',
        title: 'Na-werk fietser',
        description:
            'De avond is jouw ontsnapping. We zoeken de beste avondvensters met het mooiste weer.',
      );
    }

    // Lunch rider
    if (afternoonFree > morningFree && afternoonFree > eveningFree) {
      return (
        icon: '\u{2600}\u{FE0F}',
        title: 'Middagfietser',
        description:
            'Je pakt de beste uren van de dag. Middagslots worden jouw ideale momenten.',
      );
    }

    // Busy but making it work
    if (totalFree < 40) {
      return (
        icon: '\u{1F4AA}',
        title: 'Druk maar doorzetter',
        description:
            'Krap schema, maar elke rit telt. We vinden de pareltjes in je vrije uren.',
      );
    }

    return (
      icon: '\u{1F6B2}',
      title: 'Flexibele fietser',
      description:
          'Een mooie mix van vrije tijd door de week. Je hebt altijd opties.',
    );
  }

  // --- Cell colors ---

  Color _cellColor(
    DateTime key,
    Map<DateTime, BlockType> blocked,
    bool isDragHighlighted,
  ) {
    if (isDragHighlighted) {
      if (_dragBlocking) {
        return const Color(0xFFFFCC80);
      } else {
        return const Color(0xFFE0E0E0);
      }
    }
    return switch (blocked[key]) {
      BlockType.work => const Color(0xFFB0BEC5),
      BlockType.custom => const Color(0xFFFF9800),
      null => Colors.white,
    };
  }

  // --- Single cell tap ---

  void _onCellTap(DateTime key, Map<DateTime, BlockType> blocked) {
    if (blocked[key] == BlockType.work) return;
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
    if (blockedHours[key] == BlockType.work) return;

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
    if (blockedHours[key] == BlockType.work) return;

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
      if (blockedHours[key] == BlockType.work) continue;
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
      if (blockedHours[key] == BlockType.work) continue;
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

  // --- Helpers ---

  DateTime _cellKey(DateTime weekStart, int dayIndex, int hour) =>
      DateTime.utc(
        weekStart.year,
        weekStart.month,
        weekStart.day + dayIndex,
        hour,
      );
}
