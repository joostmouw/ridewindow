// test/features/home_two_pane_test.dart
//
// Home als lijst-plus-detail vanaf expanded (quick-plannen 261011-jru en
// 261011-kb9): op een telefoon één kolom en een tik opent /detail; op 1280
// breed staat het volledige ritdetail van het beste venster rechts open, kiest
// een tik of een pijltje in de lijst wat daar staat, zonder te pushen, en
// blijft een rit die je in het paneel inplant daar staan -- zoals Gmail op een
// tablet, behalve de auto-advance.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/features/detail/ride_detail_screen.dart';
import 'package:ridewindow/core/safe_back_button.dart';

import 'home_test_harness.dart';

final _pane = find.byKey(const ValueKey('home_detail_pane'));

Finder _inPane(Finder f) => find.descendant(of: _pane, matching: f);

Finder _inList(Finder f) => find.descendant(
      of: find.byType(CustomScrollView).first,
      matching: f,
    );

/// De begintijd van het ritdetail in het paneel.
DateTime _paneStart(WidgetTester tester) => tester
    .widget<RideDetailScreen>(_inPane(find.byType(RideDetailScreen)))
    .slot
    .start;

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  // Drie vensters; 11:00-13:00 is het beste. Op "Beste eerst" staat de lijst
  // dus als 11, 7, 15.
  final slots = [
    testSlot(7, 9, 80),
    testSlot(11, 13, 95),
    testSlot(15, 17, 70),
  ];

  testWidgets('telefoon (400x800): geen detailpaneel, tik opent /detail',
      (tester) async {
    await ignoringTestFontOverflow(() async {
      await pumpHome(tester, const Size(400, 800), slots);
      expect(_pane, findsNothing);
      expect(find.byType(RideDetailScreen), findsNothing);

      final card = find.textContaining('07:00 – 09:00');
      await tester.scrollUntilVisible(
        card,
        200,
        scrollable: find
            .descendant(
              of: find.byType(CustomScrollView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(card.first);
      await _settle(tester);
      expect(find.text(kDetailRouteText), findsOneWidget);
    });
  });

  testWidgets('telefoon (400x800): pijltjes doen niets', (tester) async {
    await ignoringTestFontOverflow(() async {
      final router = await pumpHome(tester, const Size(400, 800), slots);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      expect(_pane, findsNothing);
      expect(find.text(kDetailRouteText), findsNothing);
      expect(router.state.uri.toString(), '/');
    });
  });

  testWidgets(
      '1280x800: het volledige ritdetail van het beste venster '
      'staat rechts, zonder terugknop', (tester) async {
    await ignoringTestFontOverflow(() async {
      await pumpHome(tester, const Size(1280, 800), slots);
      expect(_pane, findsOneWidget);
      expect(_inPane(find.byType(RideDetailScreen)), findsOneWidget);
      expect(_paneStart(tester), DateTime(2026, 6, 8, 11));
      final detail = tester
          .widget<RideDetailScreen>(_inPane(find.byType(RideDetailScreen)));
      expect(detail.embedded, isTrue);
      expect(_inPane(find.textContaining('11:00 – 13:00')), findsWidgets);
      expect(_inPane(find.text('WEER')), findsOneWidget);
      expect(_inPane(find.text('Rit inplannen')), findsOneWidget);
      expect(_inPane(find.byType(SafeBackButton)), findsNothing);
      expect(_inPane(find.byType(BackButton)), findsNothing);
      // De lijst staat links, het paneel rechts.
      expect(
        tester.getTopLeft(_pane).dx,
        greaterThan(tester.getTopLeft(find.byType(CustomScrollView).first).dx),
      );
    });
  });

  testWidgets('1280x800: tik in de lijst kiest het venster, zonder push',
      (tester) async {
    await ignoringTestFontOverflow(() async {
      final router = await pumpHome(tester, const Size(1280, 800), slots);

      await tester.tap(_inList(find.textContaining('07:00 – 09:00')).first);
      await _settle(tester);

      expect(find.text(kDetailRouteText), findsNothing);
      expect(router.state.uri.toString(), '/');
      expect(_paneStart(tester), DateTime(2026, 6, 8, 7));
      expect(_inPane(find.textContaining('07:00 – 09:00')), findsWidgets);
      expect(_inPane(find.textContaining('11:00 – 13:00')), findsNothing);
    });
  });

  testWidgets(
      '1280x800: Inplannen in het paneel laat dezelfde rit staan, '
      'nu als Ingepland', (tester) async {
    await ignoringTestFontOverflow(() async {
      final router = await pumpHome(tester, const Size(1280, 800), slots);

      final plan = _inPane(find.text('Rit inplannen'));
      await tester.ensureVisible(plan);
      await tester.tap(plan);
      await _settle(tester);

      expect(router.state.uri.toString(), '/');
      expect(find.text(kDetailRouteText), findsNothing);
      expect(_inPane(find.byType(RideDetailScreen)), findsOneWidget);
      expect(_paneStart(tester), DateTime(2026, 6, 8, 11));
      expect(_inPane(find.text('Ingepland')), findsOneWidget);
      expect(_inPane(find.text('Rit inplannen')), findsNothing);
      // Uit de lijst met vensters is hij wel weg (al gepland).
      expect(_inList(find.textContaining('11:00 – 13:00')), findsNothing);
    });
  });

  testWidgets(
      '1280x800: pijltjes lopen door de lijst, Enter en Esc '
      'verplaatsen de focus', (tester) async {
    await ignoringTestFontOverflow(() async {
      await pumpHome(tester, const Size(1280, 800), slots);
      expect(_paneStart(tester), DateTime(2026, 6, 8, 11));

      // Omhoog voorbij de bovenrand: niets.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await _settle(tester);
      expect(_paneStart(tester), DateTime(2026, 6, 8, 11));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await _settle(tester);
      expect(_paneStart(tester), DateTime(2026, 6, 8, 7));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await _settle(tester);
      expect(_paneStart(tester), DateTime(2026, 6, 8, 15));

      // Voorbij de onderrand: niets.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await _settle(tester);
      expect(_paneStart(tester), DateTime(2026, 6, 8, 15));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await _settle(tester);
      expect(_paneStart(tester), DateTime(2026, 6, 8, 7));

      // Enter: de focus naar het paneel.
      final paneScope = tester
          .widget<FocusScope>(
            find.descendant(of: _pane, matching: find.byType(FocusScope)).first,
          )
          .focusNode!;
      expect(paneScope.hasFocus, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      expect(paneScope.hasFocus, isTrue);

      // Pijltjes in het paneel veranderen de keuze niet.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await _settle(tester);
      expect(_paneStart(tester), DateTime(2026, 6, 8, 7));

      // Esc in het paneel: terug naar de lijst, keuze blijft.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(paneScope.hasFocus, isFalse);
      expect(_paneStart(tester), DateTime(2026, 6, 8, 7));

      // Esc in de lijst: terug naar het beste venster.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(_paneStart(tester), DateTime(2026, 6, 8, 11));
    });
  });

  testWidgets('1280x800 zonder vensters: geen crash, paneel leeg',
      (tester) async {
    await ignoringTestFontOverflow(() async {
      await pumpHome(tester, const Size(1280, 800), const []);
      expect(_pane, findsOneWidget);
      expect(_inPane(find.byType(RideDetailScreen)), findsNothing);
      expect(_inPane(find.text('Rit inplannen')), findsNothing);
      // Pijltjes bij nul vensters: niets, geen fout.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await _settle(tester);
      expect(_inPane(find.byType(RideDetailScreen)), findsNothing);
    });
  });
}
