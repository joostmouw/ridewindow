// De drie meldingsschakelaars in Profiel deden niets: ze sloegen een voorkeur
// op en niemand las hem ooit om iets te plannen. Deze test is het vangnet dat
// die stilte niet terugkeert -- elke schakelaar leidt hier aantoonbaar tot een
// plan, of aantoonbaar tot niets.

import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/models/user_profile.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/domain/services/notification_plan.dart';

void main() {
  UserProfile profileWith({
    bool evening = false,
    bool morning = false,
    bool weekly = false,
  }) {
    return UserProfile(
      tolerances: const WeatherTolerances(
        tempMinIdealC: 12,
        tempMaxIdealC: 26,
        windMaxIdealKmh: 15,
        rainMaxIdealMm: 0.5,
        darknessWeight: 0.5,
      ),
      allowedDurations: const [2],
      theme: 'system',
      locationOverride: null,
      userName: null,
      locale: 'nl',
      notifEveningBefore: evening,
      notifMorningOf: morning,
      notifWeeklyDigest: weekly,
    );
  }

  RideSlot slotAt(DateTime start, {int hours = 2}) => RideSlot(
        start: start,
        end: start.add(Duration(hours: hours)),
        overallScore: 98,
        tier: const Perfect(),
        hours: const [],
      );

  // Dinsdag 09:00, ruim in de toekomst gezien vanaf maandagochtend.
  final now = DateTime(2026, 9, 21, 8, 0); // maandag 08:00
  final slot = slotAt(DateTime(2026, 9, 22, 9, 0));

  group('alles uit', () {
    test('levert geen enkel plan', () {
      expect(
        planNotifications(profile: profileWith(), nextSlot: slot, now: now),
        isEmpty,
      );
    });
  });

  group('avond van tevoren', () {
    test('plant voor een venster van morgen', () {
      final plans = planNotifications(
        profile: profileWith(evening: true),
        nextSlot: slot,
        now: now,
      );
      final plan = plans.single as EveningBeforePlan;
      expect(plan.slotDay, slot.start);
      expect(plan.slotTitle, '09:00–11:00');
    });

    test('plant niets als die avond al voorbij is', () {
      // Maandag 20:00 -- de avond-van-tevoren voor dinsdag was om 19:00.
      final plans = planNotifications(
        profile: profileWith(evening: true),
        nextSlot: slot,
        now: DateTime(2026, 9, 21, 20, 0),
      );
      expect(plans, isEmpty);
    });

    test('plant niets voor een venster van vandaag', () {
      final vandaag = slotAt(DateTime(2026, 9, 21, 17, 0));
      final plans = planNotifications(
        profile: profileWith(evening: true),
        nextSlot: vandaag,
        now: now,
      );
      expect(plans, isEmpty);
    });
  });

  group('ochtend van de dag', () {
    test('plant twee uur voor de start', () {
      final plans = planNotifications(
        profile: profileWith(morning: true),
        nextSlot: slot,
        now: now,
      );
      final plan = plans.single as MorningOfPlan;
      expect(plan.slotStart, slot.start);
    });

    test('plant niets als die twee uur al zijn ingegaan', () {
      final zometeen = slotAt(DateTime(2026, 9, 21, 9, 0));
      final plans = planNotifications(
        profile: profileWith(morning: true),
        nextSlot: zometeen,
        now: DateTime(2026, 9, 21, 8, 0), // nog maar 1 uur ervoor
      );
      expect(plans, isEmpty);
    });
  });

  group('weekoverzicht', () {
    test('hangt aan de kalender, niet aan het weer', () {
      // Geen venster -- toch een plan, want het overzicht gaat over de week.
      final plans = planNotifications(
        profile: profileWith(weekly: true),
        nextSlot: null,
        now: now,
      );
      expect(plans.single, isA<WeeklyDigestPlan>());
    });
  });

  group('zonder venster', () {
    test('blijven de twee weerafhankelijke meldingen achterwege', () {
      final plans = planNotifications(
        profile: profileWith(evening: true, morning: true),
        nextSlot: null,
        now: now,
      );
      expect(plans, isEmpty);
    });
  });

  group('alle drie aan', () {
    test('levert alle drie de plannen', () {
      final plans = planNotifications(
        profile: profileWith(evening: true, morning: true, weekly: true),
        nextSlot: slot,
        now: now,
      );
      expect(plans, hasLength(3));
      expect(plans.whereType<EveningBeforePlan>(), hasLength(1));
      expect(plans.whereType<MorningOfPlan>(), hasLength(1));
      expect(plans.whereType<WeeklyDigestPlan>(), hasLength(1));
    });
  });

  group('formatSlotTitle', () {
    test('gebruikt een gedachtestreepje, net als het ritdetail', () {
      expect(
        formatSlotTitle(slotAt(DateTime(2026, 9, 22, 6, 0), hours: 3)),
        '06:00–09:00',
      );
    });
  });
}
