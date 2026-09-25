import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';
import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/features/shared/ride_removal.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';

import '../helpers/fake_group_gateway.dart';

/// Geplande ritten in het geheugen, zodat verwijderen en terugzetten te zien is.
class _MemoryPlannedRides extends PlannedRidesNotifier {
  _MemoryPlannedRides(this._initial);
  final List<PlannedRide> _initial;

  @override
  Future<List<PlannedRide>> build() async => [..._initial];

  @override
  Future<void> add(PlannedRide ride) async =>
      state = AsyncData([...state.requireValue, ride]);

  @override
  Future<void> remove(PlannedRide ride) async => state = AsyncData(
        state.requireValue
            .where((r) => !r.start.isAtSameMomentAs(ride.start))
            .toList(),
      );
}

final _start = DateTime(2026, 9, 27, 18);
final _end = DateTime(2026, 9, 27, 20);
final _planned = PlannedRide(start: _start, end: _end, plannedScore: 96);

GroupRide _ride({String owner = 'uid-me'}) => GroupRide(
      id: 'r1',
      ownerId: owner,
      start: _start,
      end: _end,
      plannedScore: 96,
      participants: const [
        RideParticipant(userId: 'uid-jacco', status: ParticipantStatus.accepted),
      ],
    );

RideEntry _entry(RideRole role, {GroupRide? group, PlannedRide? planned}) =>
    RideEntry(
      start: _start,
      end: _end,
      plannedScore: 96,
      role: role,
      group: group,
      planned: planned,
    );

/// Een knop die [removeRide] aanroept en het resultaat laat zien.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  RideEntry entry,
  FakeGroupGateway gateway,
) async {
  final container = ProviderContainer(
    overrides: [
      pelotonGatewayProvider.overrideWithValue(gateway),
      plannedRidesProvider.overrideWith(() => _MemoryPlannedRides([_planned])),
    ],
  );
  addTearDown(container.dispose);
  await container.read(plannedRidesProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => removeRide(context, ref, entry),
              child: const Text('weg'),
            ),
          ),
        ),
      ),
    ),
  );
  return container;
}

List<PlannedRide> _plannedIn(ProviderContainer c) =>
    c.read(plannedRidesProvider).requireValue;

void main() {
  group('rit die je organiseert', () {
    testWidgets('na bevestigen weg uit de cloud én uit je planning',
        (tester) async {
      final gateway = FakeGroupGateway()..rides.add(_ride());
      final c = await _pump(
        tester,
        _entry(RideRole.organiser, group: _ride(), planned: _planned),
        gateway,
      );

      await tester.tap(find.text('weg'));
      await tester.pumpAndSettle();
      expect(find.text('Deze rit afzeggen?'), findsOneWidget);

      await tester.tap(find.text('Rit afzeggen'));
      await tester.pumpAndSettle();

      expect(gateway.rides, isEmpty);
      expect(_plannedIn(c), isEmpty);
      expect(find.text('Rit afgezegd'), findsOneWidget);
    });

    testWidgets('ook zonder planning op de kaart gaat je eigen rij eraf',
        (tester) async {
      // Het ritdetail en Home dragen de lokale rij niet altijd mee. Bleef hij
      // staan, dan kwam de rit terug als "Alleen jij".
      final gateway = FakeGroupGateway()..rides.add(_ride());
      final c = await _pump(
        tester,
        _entry(RideRole.organiser, group: _ride()),
        gateway,
      );

      await tester.tap(find.text('weg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rit afzeggen'));
      await tester.pumpAndSettle();

      expect(_plannedIn(c), isEmpty);
    });

    testWidgets('annuleren laat alles staan', (tester) async {
      final gateway = FakeGroupGateway()..rides.add(_ride());
      final c = await _pump(
        tester,
        _entry(RideRole.organiser, group: _ride(), planned: _planned),
        gateway,
      );

      await tester.tap(find.text('weg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuleren'));
      await tester.pumpAndSettle();

      expect(gateway.rides, hasLength(1));
      expect(_plannedIn(c), hasLength(1));
    });

    testWidgets('mislukt het in de cloud, dan blijft je planning staan en '
        'zegt de app het', (tester) async {
      // Niet van jou: de echte database raakt nul rijen, de gateway gooit.
      final gateway = FakeGroupGateway()..rides.add(_ride(owner: 'uid-anna'));
      final c = await _pump(
        tester,
        _entry(RideRole.organiser, group: _ride(), planned: _planned),
        gateway,
      );

      await tester.tap(find.text('weg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rit afzeggen'));
      await tester.pumpAndSettle();

      expect(gateway.rides, hasLength(1));
      expect(_plannedIn(c), hasLength(1));
      expect(
        find.text('Afzeggen is niet gelukt. Probeer het opnieuw.'),
        findsOneWidget,
      );
    });
  });

  group('rit van jou alleen', () {
    testWidgets('meteen weg zonder vraag, en terug met Ongedaan maken',
        (tester) async {
      final c = await _pump(
        tester,
        _entry(RideRole.solo, planned: _planned),
        FakeGroupGateway(),
      );

      await tester.tap(find.text('weg'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(_plannedIn(c), isEmpty);

      await tester.tap(find.text('Ongedaan maken'));
      await tester.pumpAndSettle();

      expect(_plannedIn(c), hasLength(1));
    });
  });
}
