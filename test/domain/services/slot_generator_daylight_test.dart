// test/domain/services/slot_generator_daylight_test.dart
//
// De aansluiting van het daglicht op de scoring (backlog #68).
//
// `daylight_test.dart` bewaakt de zonstand zelf; dit bewaakt dat de aftrek ook
// werkelijk op de ritscore landt, en dat hij ophoudt waar hij moet ophouden.
// Ingrid's melding ging precies hierover: de app zette donderdag 20:00-22:00 op
// score 100 terwijl de zon om 20:07 onderging.

import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/hourly_score.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/services/daylight.dart';
import 'package:ridewindow/domain/services/slot_generator.dart';

// Amsterdam. Op 10 september gaat de zon daar om 20:07 lokaal onder.
const _lat = 52.37;
const _lon = 4.90;

RideSlot _slot(int startHour, int endHour, {double score = 100}) => RideSlot(
      start: DateTime(2026, 9, 10, startHour),
      end: DateTime(2026, 9, 10, endHour),
      overallScore: score,
      tier: rideTierFromScore(score),
      hours: const <HourlyScore>[],
    );

void main() {
  final generator = SlotGenerator();

  List<RideSlot> apply(List<RideSlot> slots, {double weight = 0.5}) =>
      generator.applyDaylight(
        slots,
        latitude: _lat,
        longitude: _lon,
        darknessWeight: weight,
      );

  test('het gewraakte venster van 20:00-22:00 verliest zijn 100', () {
    final result = apply([_slot(20, 22)]).single;
    expect(result.overallScore, lessThan(85),
        reason: 'zonsondergang 20:07 -- bijna het hele venster is donker');
    expect(result.tier, isNot(isA<Perfect>()));
  });

  test('een venster midden op de dag blijft ongemoeid', () {
    final before = _slot(9, 11);
    final after = apply([before]).single;
    expect(after.overallScore, before.overallScore);
    expect(identical(after, before), isTrue,
        reason: 'zonder donker deel hoeft er geen nieuw object te komen');
  });

  test('het daglichtvenster komt boven het avondvenster te staan', () {
    // Beide scoren 100 op het weer. Alleen het daglicht scheidt ze.
    final result = apply([_slot(20, 22), _slot(9, 11)]);
    final evening = result.firstWhere((s) => s.start.hour == 20);
    final morning = result.firstWhere((s) => s.start.hour == 9);
    expect(morning.overallScore, greaterThan(evening.overallScore));
  });

  test('de schuif helemaal links laat alles staan', () {
    final result = apply([_slot(20, 22)], weight: 0).single;
    expect(result.overallScore, 100);
  });

  test('de schuif helemaal rechts kost het maximum, maar laat de rit staan',
      () {
    final result = apply([_slot(20, 22)], weight: 1).single;
    expect(result.overallScore,
        closeTo(100 * (1 - kMaxDarknessPenalty), kMaxDarknessPenalty * 100));
    expect(result.overallScore, greaterThan(0),
        reason: 'ook op de zwaarste stand verdwijnt een avondrit niet -- in '
            'december zou een avondfietser anders niets overhouden');
  });

  test('de tier schuift mee met de nieuwe score, niet met de oude', () {
    final result = apply([_slot(20, 22, score: 88)], weight: 1).single;
    expect(result.tier, rideTierFromScore(result.overallScore));
  });
}
