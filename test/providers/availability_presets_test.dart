import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/providers/availability_presets.dart';

void main() {
  // weekStart = Monday 2026-06-08
  final monday = DateTime(2026, 6, 8);
  // saturday = 2026-06-13 (5 days after monday)
  // ignore: unused_local_variable
  final saturday = DateTime(2026, 6, 13);

  group('buildPreset', () {
    test('Test 1: eveningsAndWeekends — maandag 00:00 is work, maandag 17:00 is vrij, zaterdag 00:00 is vrij', () {
      final map = buildPreset(AvailabilityPreset.eveningsAndWeekends, monday);

      // maandag 00:00 moet work zijn (vroeg ochtend is geblokkeerd)
      expect(map[DateTime(2026, 6, 8, 0)], BlockType.work);

      // maandag 17:00 moet VRIJ zijn (niet in map)
      expect(map.containsKey(DateTime(2026, 6, 8, 17)), isFalse);

      // zaterdag 00:00 moet VRIJ zijn (weekend geheel vrij)
      expect(map.containsKey(DateTime(2026, 6, 13, 0)), isFalse);
    });

    test('Test 2: morningsAndWeekends — maandag 06:00 is vrij, maandag 09:00 is work, zaterdag 00:00 is vrij', () {
      final map = buildPreset(AvailabilityPreset.morningsAndWeekends, monday);

      // maandag 06:00 moet VRIJ zijn (ochtend vrij)
      expect(map.containsKey(DateTime(2026, 6, 8, 6)), isFalse);

      // maandag 09:00 moet work zijn (na de vrije ochtend)
      expect(map[DateTime(2026, 6, 8, 9)], BlockType.work);

      // zaterdag 00:00 moet VRIJ zijn (weekend geheel vrij)
      expect(map.containsKey(DateTime(2026, 6, 13, 0)), isFalse);
    });

    test('Test 3: weekendsOnly — maandag 10:00 is work, zaterdag 10:00 is vrij', () {
      final map = buildPreset(AvailabilityPreset.weekendsOnly, monday);

      // maandag 10:00 moet work zijn (hele werkweek geblokkeerd)
      expect(map[DateTime(2026, 6, 8, 10)], BlockType.work);

      // zaterdag 10:00 moet VRIJ zijn
      expect(map.containsKey(DateTime(2026, 6, 13, 10)), isFalse);
    });

    test('Test 4: custom retourneert een lege map', () {
      final map = buildPreset(AvailabilityPreset.custom, monday);
      expect(map, isEmpty);
    });

    test('Test 5: de geretourneerde map heeft geen BlockType.custom entries', () {
      for (final preset in [
        AvailabilityPreset.eveningsAndWeekends,
        AvailabilityPreset.morningsAndWeekends,
        AvailabilityPreset.weekendsOnly,
      ]) {
        final map = buildPreset(preset, monday);
        expect(
          map.values.any((v) => v == BlockType.custom),
          isFalse,
          reason: 'Preset $preset mag geen BlockType.custom entries bevatten',
        );
      }
    });
  });
}
