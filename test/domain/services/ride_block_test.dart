// Het aaneengesloten goede dagdeel (backlog #69).
//
// De maat van deze test is Ingrids zaterdag: drie losse vensters -- 09:00-11:00
// met 100, 06:00-09:00 met 99 en 11:00-13:00 met 95 -- die samen één ochtend
// beschrijven. De app liet haar die ochtend zelf in elkaar zetten.

import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/services/ride_block.dart';

RideSlot _slot(int startHour, int endHour, double score, {int day = 19}) =>
    RideSlot(
      start: DateTime(2026, 9, day, startHour),
      end: DateTime(2026, 9, day, endHour),
      overallScore: score,
      tier: rideTierFromScore(score),
      hours: const [],
    );

void main() {
  group('Ingrids zaterdag', () {
    // Precies de drie vensters uit de melding van 9 september, in de volgorde
    // waarin ze op haar scherm stonden.
    final ingrid = [
      _slot(9, 11, 100),
      _slot(6, 9, 99),
      _slot(11, 13, 95),
    ];

    test('wordt één blok van 06:00 tot 13:00', () {
      final blocks = buildRideBlocks(ingrid);

      expect(blocks, hasLength(1), reason: 'drie regels, één ochtend');
      expect(blocks.single.start, DateTime(2026, 9, 19, 6));
      expect(blocks.single.end, DateTime(2026, 9, 19, 13));
    });

    test('het dagdeel duurt zeven uur', () {
      expect(buildRideBlocks(ingrid).single.hours, 7);
    });

    test('maar "hoe lang kan ik weg" is de langste rit erin, niet die zeven',
        () {
      // De eerste versie zette `hours` op die regel en beweerde daarmee dat je
      // zeven uur aaneengesloten kon fietsen. Op een mooie dag werd dat
      // vijftien uur, en dat is onzin: de vensters zijn al begrensd door de
      // toegestane ritduren uit het profiel.
      expect(buildRideBlocks(ingrid).single.longestRideHours, 3);
    });

    test('markeert het beste venster, niet het vroegste', () {
      final best = buildRideBlocks(ingrid).single.best;

      expect(best.overallScore, 100);
      expect(best.start.hour, 9);
      expect(best.end.hour, 11);
    });

    test('houdt alle drie de vensters bij elkaar, chronologisch', () {
      final slots = buildRideBlocks(ingrid).single.slots;

      expect(slots, hasLength(3));
      expect(slots.map((s) => s.start.hour), [6, 9, 11]);
    });
  });

  group('waar een blok ophoudt', () {
    test('een gat van een uur breekt het blok in tweeën', () {
      // 06-09 en 10-12: tussen negen en tien vond de app het niet rijdbaar, en
      // dat is dan ook de waarheid die de gebruiker hoort te zien.
      final blocks = buildRideBlocks([_slot(6, 9, 90), _slot(10, 12, 88)]);

      expect(blocks, hasLength(2));
      expect(blocks.first.hours, 3);
      expect(blocks.last.hours, 2);
    });

    test('aansluiten telt als aaneengesloten, niet als gat', () {
      final blocks = buildRideBlocks([_slot(6, 9, 90), _slot(9, 12, 88)]);

      expect(blocks, hasLength(1));
      expect(blocks.single.hours, 6);
    });

    test('overlappende vensters smelten samen', () {
      final blocks = buildRideBlocks([_slot(6, 10, 90), _slot(8, 12, 95)]);

      expect(blocks, hasLength(1));
      expect(blocks.single.start.hour, 6);
      expect(blocks.single.end.hour, 12);
      expect(blocks.single.best.overallScore, 95);
    });

    test('een venster dat helemaal in een ander ligt rekt het blok niet op',
        () {
      final blocks = buildRideBlocks([_slot(6, 14, 90), _slot(9, 11, 100)]);

      expect(blocks.single.start.hour, 6);
      expect(blocks.single.end.hour, 14);
      expect(blocks.single.best.overallScore, 100);
    });

    test('twee dagen zijn twee blokken, ook als de uren elkaar raken', () {
      final blocks = buildRideBlocks([
        _slot(20, 22, 80, day: 19),
        _slot(6, 9, 90, day: 20),
      ]);

      expect(blocks, hasLength(2));
      expect(blocks.first.day, DateTime(2026, 9, 19));
      expect(blocks.last.day, DateTime(2026, 9, 20));
    });
  });

  group('randgevallen', () {
    test('geen vensters, geen blokken', () {
      expect(buildRideBlocks(const []), isEmpty);
    });

    test('één venster is een blok van zichzelf', () {
      final blocks = buildRideBlocks([_slot(9, 11, 100)]);

      expect(blocks, hasLength(1));
      expect(blocks.single.best.overallScore, 100);
      expect(blocks.single.hours, 2);
    });

    test('de invoervolgorde doet er niet toe', () {
      final a = buildRideBlocks([_slot(6, 9, 99), _slot(9, 11, 100)]);
      final b = buildRideBlocks([_slot(9, 11, 100), _slot(6, 9, 99)]);

      expect(a.single.start, b.single.start);
      expect(a.single.end, b.single.end);
      expect(a.single.best.start, b.single.best.start);
    });

    test('bij gelijke score wint het vroegste venster', () {
      final block = buildRideBlocks([_slot(6, 8, 95), _slot(8, 10, 95)]).single;

      expect(block.best.start.hour, 6);
    });
  });

  group('longestRideHours', () {
    test('is de langste rit die de app werkelijk aanbiedt', () {
      final block = buildRideBlocks([
        _slot(6, 8, 90),
        _slot(8, 13, 95),
        _slot(13, 15, 88),
      ]).single;

      expect(block.hours, 9, reason: 'het dagdeel duurt negen uur');
      expect(block.longestRideHours, 5, reason: 'maar de langste rit is vijf');
    });

    test('bij één venster zijn ze gelijk', () {
      final block = buildRideBlocks([_slot(9, 11, 100)]).single;

      expect(block.hours, 2);
      expect(block.longestRideHours, 2);
    });
  });
}
