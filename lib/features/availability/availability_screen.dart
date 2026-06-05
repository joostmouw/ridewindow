// AVAIL-01, AVAIL-02, AVAIL-03: 7×24 interactief rooster
// D-06-04: ConsumerWidget — alle state zit in AvailabilityNotifier
// D-06-05: huidige week, maandag als startdag
// D-06-06: BlockType.work is niet toggelbaar

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ridewindow/providers/availability_notifier.dart';

/// AvailabilityScreen — volledig 7×24 interactief beschikbaarheidsrooster.
///
/// Drie celstaten:
///   - vrij         → wit (Colors.white)
///   - custom-blok  → oranje (0xFFFF9800)
///   - werk-blok    → grijs-blauw (0xFFB0BEC5) — niet toggelbaar (D-06-06)
///
/// Celtaps persisteren direct via AvailabilityNotifier.toggleCustomHour().
/// Slotherberekening verloopt automatisch via Riverpod-reactiviteit (SlotsNotifier).
class AvailabilityScreen extends ConsumerWidget {
  const AvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        body: Center(child: Text('Fout: $e')),
      ),
      data: (blockedHours) {
        // Weekstart: maandag van de huidige week (D-06-05)
        final now = DateTime.now();
        final weekStart =
            now.subtract(Duration(days: now.weekday - DateTime.monday));
        return _buildGrid(context, ref, blockedHours, weekStart);
      },
    );
  }

  /// Bouwt het roosterscherm: AppBar + SingleChildScrollView met header + rijen.
  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    Map<DateTime, BlockType> blockedHours,
    DateTime weekStart,
  ) {
    const dagLabels = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijn schema'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header-rij: lege cel + 7 dag-labels
              Row(
                children: [
                  // Lege hoek-cel (boven uur-labels)
                  const SizedBox(width: 32, height: 24),
                  for (final dag in dagLabels)
                    SizedBox(
                      width: 36,
                      height: 24,
                      child: Center(
                        child: Text(
                          dag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Uur-rijen: 0 t/m 23
              for (int hour = 0; hour < 24; hour++)
                Row(
                  children: [
                    // Uur-label
                    SizedBox(
                      width: 32,
                      height: 24,
                      child: Center(
                        child: Text(
                          '$hour',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    // 7 cellen voor deze rij
                    for (int dayIndex = 0; dayIndex < 7; dayIndex++)
                      _buildCell(
                        ref,
                        blockedHours,
                        weekStart,
                        dayIndex,
                        hour,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bouwt één cel voor dagIndex en uur.
  Widget _buildCell(
    WidgetRef ref,
    Map<DateTime, BlockType> blockedHours,
    DateTime weekStart,
    int dayIndex,
    int hour,
  ) {
    final key = _cellKey(weekStart, dayIndex, hour);
    final color = _cellColor(key, blockedHours);

    return GestureDetector(
      onTap: () => _onCellTap(key, blockedHours, ref),
      child: Container(
        width: 36,
        height: 24,
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

  /// Celkleur op basis van BlockType (D-06-06: werk = grijs/blauw).
  Color _cellColor(DateTime key, Map<DateTime, BlockType> blocked) {
    return switch (blocked[key]) {
      BlockType.work => const Color(0xFFB0BEC5),
      BlockType.custom => const Color(0xFFFF9800),
      null => Colors.white,
    };
  }

  /// Tap: sla werk-blokken over (D-06-06).
  void _onCellTap(
    DateTime key,
    Map<DateTime, BlockType> blocked,
    WidgetRef ref,
  ) {
    if (blocked[key] == BlockType.work) return;
    HapticFeedback.lightImpact();
    ref.read(availabilityProvider.notifier).toggleCustomHour(key);
  }

  /// Sleutel: altijd UTC voor consistentie met persistentielaag.
  DateTime _cellKey(DateTime weekStart, int dayIndex, int hour) =>
      DateTime.utc(
        weekStart.year,
        weekStart.month,
        weekStart.day + dayIndex,
        hour,
      );
}
