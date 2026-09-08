// test/features/rides_roles_test.dart
//
// De vier rollen op het rittenscherm (schets 008, variant A).
//
// Drie dingen die aan een screenshot van één rit niet te zien zijn, en die
// alle drie maanden fout hebben gestaan:
//
// 1. "Jij organiseert" en "Je gaat mee" droegen hetzelfde icoon; het verschil
//    zat in de sectiekop erboven, dus wie die kop niet las, las het verschil
//    niet.
// 2. Gedeelde ritten waren `ListTile`s zonder `onTap` -- ze zagen eruit als
//    een rij die ergens heen ging, maar deden niets.
// 3. De filterrij mag geen chip tonen die gegarandeerd een lege lijst
//    oplevert.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/planned_ride.dart';
import 'package:ridewindow/features/planned/planned_rides_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/services/peloton_gateway.dart';
import 'package:ridewindow/theme/app_theme.dart';

const _me = 'uid-me';
const _other = 'uid-other';

/// Alles relatief aan nu: de lijst snijdt weg wat voorbij is, dus een vaste
/// datum zou deze test op een dag stilletjes leeg maken.
DateTime _day(int offset, int hour) {
  final d = DateTime.now().add(Duration(days: offset));
  return DateTime(d.year, d.month, d.day, hour);
}

class _Gateway implements PelotonGateway {
  _Gateway(this.rides);

  final List<GroupRide> rides;

  @override
  Future<List<GroupRide>> listGroupRides() async => rides;

  @override
  Future<List<Friend>> listFriends() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} niet nodig');
}

class _FakePlannedRides extends PlannedRidesNotifier {
  _FakePlannedRides(this._rides);
  final List<PlannedRide> _rides;

  @override
  Future<List<PlannedRide>> build() async => _rides;
}

class _FakeWeather extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async => const [];
}

GroupRide _ride({
  required String id,
  required String ownerId,
  required int dayOffset,
  List<RideParticipant> participants = const [],
}) =>
    GroupRide(
      id: id,
      ownerId: ownerId,
      start: _day(dayOffset, 9),
      end: _day(dayOffset, 13),
      plannedScore: 80,
      ownerName: ownerId == _me ? 'Ik' : 'Peter',
      participants: participants,
    );

/// Waar een tik op een rit hoort uit te komen.
const _detailMarker = Key('detail-bereikt');

Future<void> _pump(
  WidgetTester tester, {
  List<GroupRide> rides = const [],
  List<PlannedRide> planned = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: RidesTab()),
      ),
      GoRoute(
        path: '/detail',
        builder: (_, __) =>
            const Scaffold(body: Text('detail', key: _detailMarker)),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pelotonGatewayProvider.overrideWithValue(_Gateway(rides)),
        currentUserIdProvider.overrideWithValue(_me),
        plannedRidesProvider.overrideWith(() => _FakePlannedRides(planned)),
        weatherProvider.overrideWith(_FakeWeather.new),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: ThemeData(extensions: const [RideWindowTheme.light]),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('elke rol draagt zijn eigen regel op de rit zelf',
      (tester) async {
    await _pump(
      tester,
      planned: [
        PlannedRide(
          start: _day(5, 7),
          end: _day(5, 9),
          plannedScore: 61,
        ),
      ],
      rides: [
        _ride(id: 'invite', ownerId: _other, dayOffset: 1, participants: const [
          RideParticipant(userId: _me, status: ParticipantStatus.invited),
        ]),
        _ride(id: 'mine', ownerId: _me, dayOffset: 2, participants: const [
          RideParticipant(
              userId: 'a',
              status: ParticipantStatus.accepted,
              displayName: 'Sanne'),
          RideParticipant(userId: 'b', status: ParticipantStatus.invited),
        ]),
        _ride(id: 'theirs', ownerId: _other, dayOffset: 3, participants: const [
          RideParticipant(userId: _me, status: ParticipantStatus.accepted),
        ]),
      ],
    );

    expect(find.text('Peter vraagt of je meegaat'), findsOneWidget);
    expect(find.text('Jij organiseert'), findsOneWidget);
    expect(find.text('Je gaat mee met Peter'), findsOneWidget);
    expect(find.text('Alleen jij'), findsOneWidget);

    // En bij de rit die jij organiseert staat hoe het ervoor staat, niet
    // alleen dát je hem organiseert.
    expect(find.text('1 gaat mee · 1 wacht nog'), findsOneWidget);
  });

  testWidgets('een gedeelde rit van een ander gaat door naar het detailscherm',
      (tester) async {
    await _pump(
      tester,
      rides: [
        _ride(id: 'theirs', ownerId: _other, dayOffset: 3, participants: const [
          RideParticipant(userId: _me, status: ParticipantStatus.accepted),
        ]),
      ],
    );

    expect(find.byKey(_detailMarker), findsNothing);
    await tester.tap(find.text('Je gaat mee met Peter'));
    await tester.pumpAndSettle();

    expect(find.byKey(_detailMarker), findsOneWidget,
        reason: 'dit deed niets zolang de rij een ListTile zonder onTap was');
  });

  testWidgets('de filterrij toont per rol een telling en filtert erop',
      (tester) async {
    await _pump(
      tester,
      planned: [
        PlannedRide(start: _day(5, 7), end: _day(5, 9), plannedScore: 61),
      ],
      rides: [
        _ride(id: 'mine1', ownerId: _me, dayOffset: 2),
        _ride(id: 'mine2', ownerId: _me, dayOffset: 4),
      ],
    );

    expect(find.text('Ik organiseer'), findsOneWidget);
    expect(find.text('Alles'), findsOneWidget);
    // De telling is het punt van de rij: hij beantwoordt de vraag al vóór je
    // erop tikt.
    expect(find.text('3'), findsOneWidget); // Alles
    expect(find.text('2'), findsOneWidget); // Ik organiseer

    expect(find.text('Jij organiseert'), findsNWidgets(2));
    expect(find.text('Alleen jij'), findsOneWidget);

    await tester.tap(find.text('Ik organiseer'));
    await tester.pumpAndSettle();

    expect(find.text('Jij organiseert'), findsNWidgets(2));
    expect(find.text('Alleen jij'), findsNothing);
  });

  testWidgets(
      'een rol zonder ritten krijgt geen filterchip -- die zou gegarandeerd '
      'leeg opleveren', (tester) async {
    await _pump(
      tester,
      planned: [
        PlannedRide(start: _day(5, 7), end: _day(5, 9), plannedScore: 61),
      ],
      rides: [_ride(id: 'mine1', ownerId: _me, dayOffset: 2)],
    );

    expect(find.text('Ik organiseer'), findsOneWidget);
    expect(find.text('Ik ga mee'), findsNothing);
    expect(find.text('Wacht op jou'), findsNothing);
  });

  testWidgets('met maar één soort rit verbergt de filterrij zichzelf',
      (tester) async {
    await _pump(
      tester,
      planned: [
        PlannedRide(start: _day(5, 7), end: _day(5, 9), plannedScore: 61),
      ],
    );

    expect(find.text('Alleen jij'), findsOneWidget);
    expect(find.text('Alles'), findsNothing,
        reason: 'één rol plus "alles" is geen keuze, alleen ruis');
  });

  testWidgets('een openstaande uitnodiging is te beantwoorden vanuit de lijst',
      (tester) async {
    await _pump(
      tester,
      rides: [
        _ride(id: 'invite', ownerId: _other, dayOffset: 1, participants: const [
          RideParticipant(userId: _me, status: ParticipantStatus.invited),
        ]),
      ],
    );

    expect(find.text('Ik ga mee'), findsOneWidget);
    expect(find.text('Kan niet'), findsOneWidget);
  });
}
