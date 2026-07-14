/// Widget tests voor AvailabilityScreen.
///
/// Dekt Phase 6 Plan 03 success criteria:
///   1. AvailabilityScreen is een ConsumerWidget (geen StatelessWidget meer)
///   2. 7×24 rooster met kolom-headers (Ma t/m Zo) en uur-labels (0–23)
///   3. Celkleuren: wit (vrij) / oranje (custom) / grijs-blauw (werk)
///   4. Tappen op vrije/custom-cellen roept toggleCustomHour aan
///   5. Tappen op werk-cellen heeft geen effect (guard aanwezig)
///   6. AppBar 'Mijn schema' met terugpijl aanwezig
///
/// Dekt Phase 6 Plan 04 success criteria:
///   P04-1: AppBar toont 'Mijn schema'
///   P04-2: Dag-kopteksten 'Ma' aanwezig
///   P04-3: Werk-cel heeft kleur 0xFFB0BEC5 (grijs-blauw)
///   P04-4: Custom-cel heeft kleur 0xFFFF9800 (oranje)
///   P04-5: Tappen op werk-cel wijzigt celkleur niet (tap-tap-guard)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/features/availability/availability_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/availability_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Fake Notifiers
// ---------------------------------------------------------------------------

/// Lege beschikbaarheidsmap — alle cellen zijn vrij.
class FakeEmptyAvailabilityNotifier extends AvailabilityNotifier {
  @override
  Future<Map<DateTime, BlockType>> build() async => {};
}

/// Map met één custom-geblokkeerd uur.
class FakeFilledAvailabilityNotifier extends AvailabilityNotifier {
  final Map<DateTime, BlockType> fakeMap;
  FakeFilledAvailabilityNotifier(this.fakeMap);

  @override
  Future<Map<DateTime, BlockType>> build() async => fakeMap;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SC-1: AppBar toont "Mijn schema"', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availabilityProvider.overrideWith(() => FakeEmptyAvailabilityNotifier()),
        ],
        child: const MaterialApp(home: AvailabilityScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Mijn schema'), findsOneWidget);
  });

  testWidgets('SC-2a: Dag-headers (Ma t/m Zo) zijn zichtbaar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availabilityProvider.overrideWith(() => FakeEmptyAvailabilityNotifier()),
        ],
        child: const MaterialApp(home: AvailabilityScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    for (final dag in ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo']) {
      expect(find.text(dag), findsOneWidget, reason: 'Dag-header "$dag" ontbreekt');
    }
  });

  testWidgets('SC-2b: Uur-labels 0 en 23 zijn zichtbaar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availabilityProvider.overrideWith(() => FakeEmptyAvailabilityNotifier()),
        ],
        child: const MaterialApp(home: AvailabilityScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('23'), findsOneWidget);
  });

  testWidgets('SC-3: Rooster toont 168 cellen (7×24)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availabilityProvider.overrideWith(() => FakeEmptyAvailabilityNotifier()),
        ],
        child: const MaterialApp(home: AvailabilityScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 7 kolommen × 24 uren = 168 cellen (GestureDetectors inclusief mogelijke extras van BackButton etc.)
    expect(find.byType(GestureDetector), findsAtLeastNWidgets(168));
  });

  testWidgets('SC-4: Rooster toont "Mijn schema" AppBar na data load',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availabilityProvider.overrideWith(() => FakeEmptyAvailabilityNotifier()),
        ],
        child: const MaterialApp(home: AvailabilityScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Mijn schema'), findsOneWidget);
    // Alle dag-headers zijn zichtbaar
    expect(find.text('Ma'), findsOneWidget);
    expect(find.text('Zo'), findsOneWidget);
  });

  testWidgets('SC-5: Werk-cel is zichtbaar in rooster', (tester) async {
    final now = DateTime.now();
    final weekStart =
        now.subtract(Duration(days: now.weekday - DateTime.monday));
    // Maandag, uur 9 = werk-cel
    final werkCelKey = DateTime.utc(
      weekStart.year,
      weekStart.month,
      weekStart.day,
      9,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availabilityProvider.overrideWith(
            () => FakeFilledAvailabilityNotifier({werkCelKey: BlockType.work}),
          ),
        ],
        child: const MaterialApp(home: AvailabilityScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Rooster geladen en zichtbaar
    expect(find.text('Mijn schema'), findsOneWidget);
    // 168 cellen aanwezig
    expect(find.byType(GestureDetector), findsAtLeastNWidgets(168));
  });

  // ---------------------------------------------------------------------------
  // Phase 6 Plan 04 tests — celkleur verificatie en tap-guard
  // ---------------------------------------------------------------------------

  testWidgets('P04-1: AppBar toont "Mijn schema"', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availabilityProvider
              .overrideWith(() => FakeEmptyAvailabilityNotifier()),
        ],
        child: const MaterialApp(home: AvailabilityScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Mijn schema'), findsOneWidget);
  });

  testWidgets('P04-2: Dag-kopteksten inclusief "Ma" aanwezig', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availabilityProvider
              .overrideWith(() => FakeEmptyAvailabilityNotifier()),
        ],
        child: const MaterialApp(home: AvailabilityScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ma'), findsOneWidget);
  });

  testWidgets(
      'P04-3: Werk-cel (uur 9, dag 0) heeft werk-kleur 0xFFB0BEC5',
      (tester) async {
    final now = DateTime.now();
    final weekStart =
        now.subtract(Duration(days: now.weekday - DateTime.monday));
    final mapWithWork = {
      DateTime.utc(weekStart.year, weekStart.month, weekStart.day, 9):
          BlockType.work,
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availabilityProvider.overrideWith(
            () => FakeFilledAvailabilityNotifier(mapWithWork),
          ),
        ],
        child: const MaterialApp(home: AvailabilityScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Minstens één Container met werk-kleur aanwezig (inclusief off-screen cellen)
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.color ==
                const Color(0xFFB0BEC5),
        skipOffstage: false,
      ),
      findsWidgets,
      reason: 'Minstens één cel met werk-kleur (0xFFB0BEC5) verwacht',
    );
  });

  testWidgets(
      'P04-4: Custom-cel (uur 10, dag 0) heeft custom-kleur 0xFFFF9800',
      (tester) async {
    final now = DateTime.now();
    final weekStart =
        now.subtract(Duration(days: now.weekday - DateTime.monday));
    final mapWithCustom = {
      DateTime.utc(weekStart.year, weekStart.month, weekStart.day, 10):
          BlockType.custom,
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availabilityProvider.overrideWith(
            () => FakeFilledAvailabilityNotifier(mapWithCustom),
          ),
        ],
        child: const MaterialApp(home: AvailabilityScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Minstens één Container met custom-kleur aanwezig (inclusief off-screen cellen)
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.color ==
                const Color(0xFFFF9800),
        skipOffstage: false,
      ),
      findsWidgets,
      reason: 'Minstens één cel met custom-kleur (0xFFFF9800) verwacht',
    );
  });

  testWidgets(
      'P04-5: Werk-tap-guard: tappen op werk-cel wijzigt celkleur niet',
      (tester) async {
    final now = DateTime.now();
    final weekStart =
        now.subtract(Duration(days: now.weekday - DateTime.monday));
    // Uur 0, dag 0 = werk-cel (zichtbaar zonder scrollen)
    final mapWithWork = {
      DateTime.utc(weekStart.year, weekStart.month, weekStart.day, 0):
          BlockType.work,
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          availabilityProvider.overrideWith(
            () => FakeFilledAvailabilityNotifier(mapWithWork),
          ),
        ],
        child: const MaterialApp(home: AvailabilityScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Zoek de werk-kleur cel (uur 0, dag 0 — zichtbaar in viewport)
    final werkCelFinder = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          (w.decoration as BoxDecoration?)?.color == const Color(0xFFB0BEC5),
      skipOffstage: false,
    );
    expect(werkCelFinder, findsWidgets,
        reason: 'Werk-cel (0xFFB0BEC5) aanwezig vóór tap');

    // Tap de eerste GestureDetector in de werk-cel-rij
    // (Cel uur 0 staat bovenaan het rooster — zichtbaar in viewport)
    final werkGestureDetectors = find.byWidgetPredicate(
      (w) => w is GestureDetector,
    );
    // Er zijn minstens 7 GestureDetectors in rij 0 (één per dag)
    expect(werkGestureDetectors, findsWidgets);

    // Tik op de eerste zichtbare GestureDetector in het rooster
    await tester.tap(werkGestureDetectors.first);
    await tester.pump();

    // Na tap: werk-kleur cel nog steeds aanwezig (tap had geen effect)
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.color == const Color(0xFFB0BEC5),
        skipOffstage: false,
      ),
      findsWidgets,
      reason: 'Werk-cel (0xFFB0BEC5) moet na tap ongewijzigd blijven',
    );
  });

  // ---------------------------------------------------------------------------
  // BACKLOG-35: drag run indicator
  // ---------------------------------------------------------------------------

  group('BACKLOG-35: drag run indicator', () {
    testWidgets(
        'shows "3 losse tijdvakken geselecteerd" during a 3-day drag and disappears after drag ends',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availabilityProvider.overrideWith(() => FakeEmptyAvailabilityNotifier()),
          ],
          child: MaterialApp(
            locale: const Locale('nl'),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            theme: ThemeData(extensions: const [RideWindowTheme.light]),
            home: const AvailabilityScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Fixed viewport (800x1400, devicePixelRatio 1.0, AppBar toolbarHeight 56.0,
      // no status-bar padding in test env) resolves to:
      //   cellWidth = (800 - 36) / 7 ≈ 109.14
      //   cellHeight = (1344 - 140 - 32 - 28) / 24 ≈ 47.67
      const cellWidth = (800 - 36) / 7;
      const cellHeight = (1344 - 140 - 32 - 28) / 24;
      const hour = 1; // stays comfortably inside the viewport, avoids hour-0 boundary rounding
      Offset cellCenter(int dayIndex) => Offset(
            36 + (dayIndex + 0.5) * cellWidth,
            56 + 32 + 28 + (hour + 0.5) * cellHeight,
          );

      final day0Hour1Center = cellCenter(0);
      final day1Hour1Center = cellCenter(1);
      final day2Hour1Center = cellCenter(2);

      // One continuous horizontal drag across 3 day-columns at the same hour —
      // mirrors the backlog's Mon/Tue/Wed 17:00 example (3 separate 1-hour runs).
      final gesture = await tester.startGesture(day0Hour1Center);
      // PanGestureRecognizer (kPanSlop = 36 logical px) does not fire onPanStart on
      // the raw pointer-down — it fires once the pointer moves past the pan slop.
      // Nudge 40px horizontally (comfortably within day0's ~109px-wide column, well
      // under kPanSlop's threshold for the outer GestureDetector to win the arena
      // against the inner SingleChildScrollView) so onPanStart registers day0's
      // own cell before the drag moves on to day1/day2.
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.moveTo(day1Hour1Center);
      await tester.pump();
      await gesture.moveTo(day2Hour1Center);
      await tester.pump();

      expect(find.text('3 losse tijdvakken geselecteerd'), findsOneWidget);

      await gesture.up();
      await tester.pump();

      expect(find.textContaining('geselecteerd'), findsNothing);
      expect(find.byIcon(Icons.touch_app), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // BACKLOG-rne: two-tap range-select
  // ---------------------------------------------------------------------------

  group('BACKLOG-rne: two-tap range-select', () {
    const cellWidth = (800 - 36) / 7;
    const cellHeight = (1344 - 140 - 32 - 28) / 24;

    Offset cellCenter(int dayIndex, int hour) => Offset(
          36 + (dayIndex + 0.5) * cellWidth,
          56 + 32 + 28 + (hour + 0.5) * cellHeight,
        );

    DateTime weekStartFor(DateTime now) =>
        now.subtract(Duration(days: now.weekday - DateTime.monday));

    DateTime cellKey(DateTime weekStart, int dayIndex, int hour) =>
        DateTime.utc(
          weekStart.year,
          weekStart.month,
          weekStart.day + dayIndex,
          hour,
        );

    // Grid cells have no borderRadius (unlike the 14x14 legend swatches,
    // which use BorderRadius.circular(3)) — exclude the legend swatch so
    // these finders only match actual grid cells.
    Finder customColorFinder() => find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.color ==
                  const Color(0xFFFF9800) &&
              (w.decoration as BoxDecoration?)?.borderRadius == null,
          skipOffstage: false,
        );

    Finder workColorFinder() => find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.color ==
                  const Color(0xFFB0BEC5) &&
              (w.decoration as BoxDecoration?)?.borderRadius == null,
          skipOffstage: false,
        );

    Finder pendingBorderFinder() => find.byWidgetPredicate(
          (w) =>
              w is Container &&
              (w.decoration as BoxDecoration?)?.border is Border &&
              (((w.decoration as BoxDecoration).border! as Border)
                      .top
                      .width ==
                  2.0),
          skipOffstage: false,
        );

    Future<void> pumpScreen(
      WidgetTester tester,
      AvailabilityNotifier Function() notifierFactory,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availabilityProvider.overrideWith(notifierFactory),
          ],
          child: MaterialApp(
            locale: const Locale('nl'),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            theme: ThemeData(extensions: const [RideWindowTheme.light]),
            home: const AvailabilityScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets(
        'Test 1: same-day two-tap opens then fills-and-closes a block',
        (tester) async {
      await pumpScreen(tester, () => FakeEmptyAvailabilityNotifier());

      await tester.tapAt(cellCenter(0, 1));
      await tester.pump();

      expect(customColorFinder(), findsNWidgets(1));
      expect(pendingBorderFinder(), findsNWidgets(1));

      await tester.tapAt(cellCenter(0, 3));
      await tester.pump();

      expect(customColorFinder(), findsNWidgets(3));
      expect(pendingBorderFinder(), findsNothing);
    });

    testWidgets('Test 2: re-tapping the anchor cancels the pending block',
        (tester) async {
      await pumpScreen(tester, () => FakeEmptyAvailabilityNotifier());

      await tester.tapAt(cellCenter(1, 5));
      await tester.pump();

      expect(customColorFinder(), findsNWidgets(1));
      expect(pendingBorderFinder(), findsNWidgets(1));

      await tester.tapAt(cellCenter(1, 5));
      await tester.pump();

      expect(customColorFinder(), findsNothing);
      expect(pendingBorderFinder(), findsNothing);
    });

    testWidgets(
        'Test 3: counter bar reacts to an open pending anchor, not only drag state',
        (tester) async {
      await pumpScreen(tester, () => FakeEmptyAvailabilityNotifier());

      await tester.tapAt(cellCenter(0, 9));
      await tester.pump();

      expect(find.text('1 tijdvak geselecteerd'), findsOneWidget);

      await tester.tapAt(cellCenter(0, 11));
      await tester.pump();

      expect(find.textContaining('geselecteerd'), findsNothing);
    });

    testWidgets(
        'Test 4: closing a block always opens a brand-new independent anchor on the next empty tap',
        (tester) async {
      await pumpScreen(tester, () => FakeEmptyAvailabilityNotifier());

      await tester.tapAt(cellCenter(0, 9));
      await tester.pump();
      await tester.tapAt(cellCenter(0, 11));
      await tester.pump();

      expect(customColorFinder(), findsNWidgets(3));
      expect(pendingBorderFinder(), findsNothing);

      await tester.tapAt(cellCenter(0, 15));
      await tester.pump();

      expect(pendingBorderFinder(), findsNWidgets(1));
      expect(customColorFinder(), findsNWidgets(4)); // 9,10,11 + 15

      await tester.tapAt(cellCenter(0, 17));
      await tester.pump();

      expect(customColorFinder(), findsNWidgets(6)); // 9,10,11,15,16,17
      expect(pendingBorderFinder(), findsNothing);
    });

    testWidgets(
        'Test 5: work/calendar no-op guard applies even while a pending anchor is open',
        (tester) async {
      final now = DateTime.now();
      final weekStart = weekStartFor(now);
      final workKey = cellKey(weekStart, 0, 5);

      await pumpScreen(
        tester,
        () => FakeFilledAvailabilityNotifier({workKey: BlockType.work}),
      );

      await tester.tapAt(cellCenter(0, 2));
      await tester.pump();

      expect(pendingBorderFinder(), findsNWidgets(1));
      expect(customColorFinder(), findsNWidgets(1));
      expect(workColorFinder(), findsWidgets);

      await tester.tapAt(cellCenter(0, 5));
      await tester.pump();

      // No-op: work cell unchanged, no fill, anchor still open on hour 2 only.
      expect(workColorFinder(), findsWidgets);
      expect(customColorFinder(), findsNWidgets(1));
      expect(pendingBorderFinder(), findsNWidgets(1));
    });

    testWidgets(
        'Test 6: a tap on a different day closes the old anchor standalone and opens a new one',
        (tester) async {
      await pumpScreen(tester, () => FakeEmptyAvailabilityNotifier());

      await tester.tapAt(cellCenter(0, 2));
      await tester.pump();

      expect(pendingBorderFinder(), findsNWidgets(1));
      expect(customColorFinder(), findsNWidgets(1));

      await tester.tapAt(cellCenter(1, 4));
      await tester.pump();

      // Day 0 hour 2 remains a standalone closed 1-hour block (no border);
      // day 1 hour 4 becomes the new open anchor.
      expect(customColorFinder(), findsNWidgets(2));
      expect(pendingBorderFinder(), findsNWidgets(1));
    });

    testWidgets(
        'Test 7: pending-anchor counter is scoped to the anchor\'s own day, not the whole week',
        (tester) async {
      final now = DateTime.now();
      final weekStart = weekStartFor(now);
      final preseeded = {
        cellKey(weekStart, 1, 8): BlockType.custom,
        cellKey(weekStart, 1, 9): BlockType.custom,
        cellKey(weekStart, 1, 10): BlockType.custom,
      };

      await pumpScreen(
        tester,
        () => FakeFilledAvailabilityNotifier(preseeded),
      );

      await tester.tapAt(cellCenter(0, 1));
      await tester.pump();

      expect(find.text('1 tijdvak geselecteerd'), findsOneWidget);
      expect(find.textContaining('2 losse'), findsNothing);
    });

    testWidgets(
        'Test 8: toggling off a non-anchor already-custom cell leaves the open anchor untouched',
        (tester) async {
      final now = DateTime.now();
      final weekStart = weekStartFor(now);
      final preseeded = {
        cellKey(weekStart, 0, 20): BlockType.custom,
      };

      await pumpScreen(
        tester,
        () => FakeFilledAvailabilityNotifier(preseeded),
      );

      await tester.tapAt(cellCenter(0, 5));
      await tester.pump();

      expect(pendingBorderFinder(), findsNWidgets(1));
      expect(customColorFinder(), findsNWidgets(2)); // hour 20 (preseeded) + hour 5 (new anchor)

      await tester.tapAt(cellCenter(0, 20));
      await tester.pump();

      expect(customColorFinder(), findsNWidgets(1)); // only hour 5 remains
      expect(pendingBorderFinder(), findsNWidgets(1)); // anchor still open on hour 5
    });
  });
}
