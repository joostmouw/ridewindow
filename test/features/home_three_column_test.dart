// test/features/home_three_column_test.dart
//
// Derde kolom op Home (quick-plan 261011-kb9, backlog #93): vanaf 1440 dp
// staat rechts van het detailpaneel een kolom met je ritten (RidesTab), zoals
// Google Calendar en Maps op een groot scherm. Wat daar staat, staat niet nog
// eens in de lijst: de Home-sectie met geplande ritten verdwijnt dan. Op 1280
// en 1439 blijft het lijst plus detail.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/planned_ride.dart';
import 'package:ridewindow/features/planned/planned_rides_screen.dart';

import 'home_test_harness.dart';

final _column = find.byKey(const ValueKey('home_rides_column'));
final _pane = find.byKey(const ValueKey('home_detail_pane'));

/// De Home-sectie met geplande ritten heeft de kop GEPLAND in de lijst.
Finder _plannedSectionInList(String label) => find.descendant(
      of: find.byType(CustomScrollView).first,
      matching: find.text(label),
    );

void main() {
  final slots = [
    testSlot(7, 9, 80),
    testSlot(11, 13, 95),
  ];

  // Eén ingeplande rit, overmorgen, zodat hij als aankomend telt.
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day + 2);
  final planned = [
    PlannedRide(
      start: DateTime(day.year, day.month, day.day, 10),
      end: DateTime(day.year, day.month, day.day, 12),
      plannedScore: 90,
    ),
  ];

  testWidgets('1600x900: derde kolom met RidesTab rechts van het detail',
      (tester) async {
    await ignoringTestFontOverflow(() async {
      await pumpHome(tester, const Size(1600, 900), slots);
      expect(_column, findsOneWidget);
      expect(
        find.descendant(of: _column, matching: find.byType(RidesTab)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _column, matching: find.text('Ritten')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(_column).dx,
        greaterThan(tester.getTopLeft(_pane).dx),
      );
      // Het detail houdt zijn leesbreedte (bijna) over.
      expect(tester.getSize(_pane).width, greaterThanOrEqualTo(600));
    });
  });

  for (final size in const [Size(1280, 800), Size(1439, 900)]) {
    testWidgets(
        '${size.width.toInt()}x${size.height.toInt()}: geen derde '
        'kolom, wel lijst plus detail', (tester) async {
      await ignoringTestFontOverflow(() async {
        await pumpHome(tester, size, slots);
        expect(_column, findsNothing);
        expect(find.byType(RidesTab), findsNothing);
        expect(_pane, findsOneWidget);
      });
    });
  }

  testWidgets(
      '1600x900 met een geplande rit: geen geplande-sectie in de '
      'lijst, de rit staat rechts', (tester) async {
    await ignoringTestFontOverflow(() async {
      await pumpHome(tester, const Size(1600, 900), slots, planned: planned);
      expect(_plannedSectionInList('GEPLAND'), findsNothing);
      expect(_column, findsOneWidget);
    });
  });

  testWidgets(
      '1280x800 met een geplande rit: de geplande-sectie staat er '
      'nog', (tester) async {
    await ignoringTestFontOverflow(() async {
      await pumpHome(tester, const Size(1280, 800), slots, planned: planned);
      expect(_plannedSectionInList('GEPLAND'), findsOneWidget);
    });
  });
}
