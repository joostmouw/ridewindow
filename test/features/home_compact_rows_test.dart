// test/features/home_compact_rows_test.dart
//
// Compacte vensterrijen op een tablet (quick-plan 261011-l5k, schets 017 A):
// vanaf expanded staat er naast het detailpaneel een lijst als die van Gmail,
// met een gevuld scorebolletje, dag + tijd, een weerregel en de duur, zonder
// knoppen. De filterkop blijft bovenaan staan. Telefoon en medium houden de
// grote kaarten.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/features/detail/ride_detail_screen.dart';
import 'package:ridewindow/features/home/filled_score_badge.dart';
import 'package:ridewindow/features/home/home_screen.dart';
import 'package:ridewindow/features/shared/score_display.dart';
import 'package:ridewindow/theme/app_colors.dart';

import 'home_test_harness.dart';

final _pane = find.byKey(const ValueKey('home_detail_pane'));
final _pinned = find.byKey(const ValueKey('home_pinned_filters'));

Finder _inPane(Finder f) => find.descendant(of: _pane, matching: f);

Finder _inList(Finder f) => find.descendant(
      of: find.byType(CustomScrollView).first,
      matching: f,
    );

DateTime _paneStart(WidgetTester tester) => tester
    .widget<RideDetailScreen>(_inPane(find.byType(RideDetailScreen)))
    .slot
    .start;

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Finder _row(int hour) => find.byKey(
      ValueKey(
        'compact_row_${DateTime(2026, 6, 8, hour).millisecondsSinceEpoch}',
      ),
    );

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Of de rij gevuld is: de Ink van de rij draagt een kleur.
Color? _rowFill(WidgetTester tester, int hour) {
  final ink = tester.widget<Ink>(
    find.descendant(of: _row(hour), matching: find.byType(Ink)).first,
  );
  return (ink.decoration as BoxDecoration?)?.color;
}

void main() {
  final slots = [
    testSlot(7, 9, 80),
    testSlot(11, 13, 95),
    testSlot(15, 17, 70),
  ];

  // Twaalf vensters verspreid over de dag; genoeg om de lijst te laten
  // scrollen. Bewust geen overlap, anders haalt de lijst ze samen.
  final many = [
    for (var h = 0; h < 12; h++) testSlot(h * 2, h * 2 + 2, 60 + h * 3.0),
  ];

  group('1280x800: compacte rijen', () {
    testWidgets('drie rijen met een gevuld bolletje en zonder knoppen',
        (tester) async {
      await ignoringTestFontOverflow(() async {
        await pumpHome(tester, const Size(1280, 800), slots);
        expect(_inList(find.byType(FilledScoreBadge)), findsNWidgets(3));
        expect(_inList(find.text('Inplannen')), findsNothing);
        expect(_inList(find.text('Rit inplannen')), findsNothing);
        expect(_inList(find.byType(BestChoicePill)), findsNothing);
        expect(_inList(find.byType(ScoreDisplay)), findsNothing);
        expect(_inList(find.text('Beste keuze')), findsOneWidget);
        // Het label staat in de rij van 11:00, het beste venster.
        expect(
          find.descendant(of: _row(11), matching: find.text('Beste keuze')),
          findsOneWidget,
        );
      });
    });

    testWidgets('een rij is ongeveer 64 px hoog', (tester) async {
      await ignoringTestFontOverflow(() async {
        await pumpHome(tester, const Size(1280, 800), slots);
        final h = tester.getSize(_row(7)).height;
        expect(h, inInclusiveRange(56, 80));
      });
    });

    testWidgets('tik zet het venster in het paneel, zonder push',
        (tester) async {
      await ignoringTestFontOverflow(() async {
        final router = await pumpHome(tester, const Size(1280, 800), slots);
        await tester.tap(_inList(find.textContaining('07:00 – 09:00')).first);
        await _settle(tester);
        expect(find.text(kDetailRouteText), findsNothing);
        expect(router.state.uri.toString(), '/');
        expect(_paneStart(tester), DateTime(2026, 6, 8, 7));
      });
    });

    testWidgets('de gekozen rij is gevuld, de andere niet', (tester) async {
      await ignoringTestFontOverflow(() async {
        await pumpHome(tester, const Size(1280, 800), slots);
        await tester.tap(_row(7));
        await _settle(tester);
        final cs = Theme.of(tester.element(_row(7))).colorScheme;
        expect(_rowFill(tester, 7), cs.surfaceContainerHighest);
        expect(_rowFill(tester, 11), isNull);
        expect(_rowFill(tester, 15), isNull);
      });
    });

    testWidgets('pijl omlaag gaat van 11 naar 07', (tester) async {
      await ignoringTestFontOverflow(() async {
        await pumpHome(tester, const Size(1280, 800), slots);
        expect(_paneStart(tester), DateTime(2026, 6, 8, 11));
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await _settle(tester);
        expect(_paneStart(tester), DateTime(2026, 6, 8, 7));
      });
    });
  });

  group('1280x800: vastgezette filterkop', () {
    testWidgets('de kop blijft staan als de lijst scrolt', (tester) async {
      await ignoringTestFontOverflow(() async {
        await pumpHome(tester, const Size(1280, 800), many);
        // Alles tonen, zodat er echt iets te scrollen valt.
        final showAll = _inList(find.text('Toon alle 12 momenten'));
        await tester.ensureVisible(showAll);
        await tester.tap(showAll);
        await _settle(tester);
        expect(_pinned, findsOneWidget);
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -600),
        );
        await _settle(tester);
        final top = tester.getTopLeft(_pinned).dy;
        expect(top, greaterThanOrEqualTo(0));
        expect(top, lessThan(200));
      });
    });

    testWidgets(
        'pijl omhoog tot de eerste rij zet die rij onder de kop, '
        'niet erachter', (tester) async {
      await ignoringTestFontOverflow(() async {
        await pumpHome(tester, const Size(1280, 800), many);
        final showAll = _inList(find.text('Toon alle 12 momenten'));
        await tester.ensureVisible(showAll);
        await tester.tap(showAll);
        await _settle(tester);
        // Beste eerst: de eerste rij is het hoogst scorende venster (22:00).
        // Naar de laatste rij en de lijst omlaag, zodat de eerste rij onder
        // de kop verdwenen is.
        for (var i = 0; i < 11; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await _settle(tester);
        }
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -2000),
        );
        await _settle(tester);
        final hidden = _row(22).evaluate().isEmpty ||
            tester.getTopLeft(_row(22)).dy < tester.getBottomLeft(_pinned).dy;
        expect(hidden, isTrue, reason: 'de eerste rij moet eerst uit beeld');
        for (var i = 0; i < 11; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await _settle(tester);
        }
        expect(_paneStart(tester), DateTime(2026, 6, 8, 22));
        await tester.pump(const Duration(seconds: 1));
        final first = _row(22);
        expect(first, findsOneWidget);
        expect(
          tester.getTopLeft(first).dy,
          greaterThanOrEqualTo(tester.getBottomLeft(_pinned).dy - 0.5),
        );
      });
    });
  });

  testWidgets('400x800: de grote kaarten zoals altijd', (tester) async {
    await ignoringTestFontOverflow(() async {
      await pumpHome(tester, const Size(400, 800), slots);
      expect(find.byType(FilledScoreBadge), findsNothing);
      expect(find.byType(ScoreDisplay), findsWidgets);
      expect(_pinned, findsNothing);
      expect(find.text('Inplannen'), findsWidgets);
    });
  });

  testWidgets('700x800 (medium): de grote kaarten zoals altijd',
      (tester) async {
    await ignoringTestFontOverflow(() async {
      await pumpHome(tester, const Size(700, 800), slots);
      expect(find.byType(FilledScoreBadge), findsNothing);
      expect(find.byType(ScoreDisplay), findsWidgets);
      expect(_pinned, findsNothing);
    });
  });

  test('de tekst in het bolletje haalt 4,5:1 op alle acht vullingen', () {
    const fills = [
      AppColors.lightScorePerfect,
      AppColors.lightScoreGreat,
      AppColors.lightScoreAcceptable,
      AppColors.lightScorePoor,
      AppColors.darkScorePerfect,
      AppColors.darkScoreGreat,
      AppColors.darkScoreAcceptable,
      AppColors.darkScorePoor,
    ];
    for (final fill in fills) {
      expect(
        _contrast(onScoreFill(fill), fill),
        greaterThanOrEqualTo(4.5),
        reason: 'vulling $fill',
      );
    }
  });
}
