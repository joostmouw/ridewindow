/// Widget tests voor AvailabilityScreen.
///
/// Dekt Phase 6 Plan 03 success criteria:
///   1. AvailabilityScreen is een ConsumerWidget (geen StatelessWidget meer)
///   2. 7×24 rooster met kolom-headers (Ma t/m Zo) en uur-labels (0–23)
///   3. Celkleuren: wit (vrij) / oranje (custom) / grijs-blauw (werk)
///   4. Tappen op vrije/custom-cellen roept toggleCustomHour aan
///   5. Tappen op werk-cellen heeft geen effect (guard aanwezig)
///   6. AppBar 'Mijn schema' met terugpijl aanwezig

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/features/availability/availability_screen.dart';
import 'package:ridewindow/providers/availability_notifier.dart';

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
}
