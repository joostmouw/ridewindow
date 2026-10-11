// test/features/home_hover_test.dart
//
// Hover op tikbare vlakken (quick-plan 261011-kb9, backlog #93): met muis of
// trackpad krijgt een dagchip op Home een klikcursor en een hover-laag uit het
// thema, in licht én donker (werkregel: altijd beide helderheden meten).

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/theme/app_colors.dart';
import 'package:ridewindow/theme/app_theme.dart';

import 'home_test_harness.dart';

void main() {
  final slots = [
    testSlot(7, 9, 80),
    testSlot(11, 13, 95),
  ];

  for (final brightness in Brightness.values) {
    testWidgets(
        '1280x800 ${brightness.name}: dagchip toont klikcursor en '
        'hover-laag', (tester) async {
      await ignoringTestFontOverflow(() async {
        final theme = buildAppTheme(brightness);
        await pumpHome(tester, const Size(1280, 800), slots, theme: theme);

        // De dagchips van de weekstrip: de InkWells met de hover-laag uit het
        // thema, op de compacte vensterrijen na (quick-plan 261011-l5k), die
        // dezelfde laag dragen.
        final overlay = hoverOverlay(theme.colorScheme);
        expect(overlay.a, greaterThan(0));
        final chips = find.byWidgetPredicate(
          (w) =>
              w is InkWell &&
              w.hoverColor == overlay &&
              !(w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>)
                      .value
                      .startsWith('compact_row_')),
        );
        expect(chips, findsNWidgets(7));
        final chip = chips.first;
        final dayNumber = find
            .descendant(
              of: chip,
              matching: find.byWidgetPredicate(
                (w) => w is Text && int.tryParse(w.data ?? '') != null,
              ),
            )
            .first;

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          pointer: 1,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await gesture.moveTo(tester.getCenter(dayNumber));
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
          SystemMouseCursors.click,
        );

        // Een tik filtert nog steeds op die dag: het dagnummer wordt vet.
        await tester.tap(chip);
        await tester.pump(const Duration(milliseconds: 600));
        final style = tester.widget<Text>(dayNumber).style;
        expect(style?.fontWeight, FontWeight.w800);
        await gesture.moveTo(Offset.zero);
        await tester.pump(const Duration(milliseconds: 300));
      });
    });
  }
}
