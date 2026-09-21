// test/features/peloton_options_test.dart
//
// Slice 2 van epic #65: meerdere vensters voorleggen, de groep kiest.
//
// Wat hier vastligt is niet "de knop bestaat" maar de drie onderscheidingen
// die deze functie inhoudelijk maken, en die geen van drieën uit een
// screenshot af te lezen zijn:
//
// 1. **Geen stem is iets anders dan "nee".** Wie nog niet geantwoord heeft
//    telt nergens mee; wie "kan niet" zei wél, want dat is een antwoord.
// 2. **Een venster is geen keuze.** Legt de organisator er maar een voor, dan
//    hoort er geen stemhokje omheen te staan.
// 3. **"Voorop" is niet hetzelfde als "hoogste score".** De volgorde is
//    stemmen, dan score, dan vroegste -- dezelfde die Home aanhoudt.

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

DateTime _day(int offset, int hour) {
  final d = DateTime.now().add(Duration(days: offset));
  return DateTime(d.year, d.month, d.day, hour);
}

RideOption _option({
  required String id,
  required int dayOffset,
  int hour = 9,
  double score = 80,
  List<OptionVote> votes = const [],
}) =>
    RideOption(
      id: id,
      rideId: 'ride',
      start: _day(dayOffset, hour),
      end: _day(dayOffset, hour + 2),
      plannedScore: score,
      votes: votes,
    );

GroupRide _ride({
  String ownerId = _other,
  List<RideOption> options = const [],
  List<RideParticipant>? participants,
}) =>
    GroupRide(
      id: 'ride',
      ownerId: ownerId,
      start: _day(1, 9),
      end: _day(1, 13),
      plannedScore: 80,
      ownerName: ownerId == _me ? 'Ik' : 'Peter',
      participants: participants ??
          const [
            RideParticipant(userId: _me, status: ParticipantStatus.accepted),
          ],
      options: options,
    );

class _RecordingGateway implements PelotonGateway {
  _RecordingGateway(this.rides);

  final List<GroupRide> rides;
  final votes = <({String optionId, bool canRide})>[];
  final chosen = <String>[];

  @override
  Future<List<GroupRide>> listGroupRides() async => rides;

  @override
  Future<List<Friend>> listFriends() async => const [];

  @override
  Future<void> voteOnOption({
    required String optionId,
    required bool canRide,
  }) async =>
      votes.add((optionId: optionId, canRide: canRide));

  @override
  Future<void> chooseOption({
    required String rideId,
    required RideOption option,
  }) async =>
      chosen.add(option.id);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} niet nodig');
}

/// De tegenhanger van [_RecordingGateway] voor de sweep "stille takken"
/// (2026-09-21): elke Peloton-aanroep faalt. Vóór de sweep deden de
/// antwoord-, stem- en kies-knoppen daar zichtbaar niets bij; deze gateway
/// bewijst dat er nu altijd een melding komt.
class _ThrowingGateway implements PelotonGateway {
  _ThrowingGateway(this.rides);

  final List<GroupRide> rides;

  @override
  Future<List<GroupRide>> listGroupRides() async => rides;

  @override
  Future<List<Friend>> listFriends() async => const [];

  @override
  Future<void> respondToRide({
    required String rideId,
    required bool accepted,
  }) async =>
      throw Exception('netwerk');

  @override
  Future<void> voteOnOption({
    required String optionId,
    required bool canRide,
  }) async =>
      throw Exception('netwerk');

  @override
  Future<void> chooseOption({
    required String rideId,
    required RideOption option,
  }) async =>
      throw Exception('netwerk');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} niet nodig');
}

class _FakePlannedRides extends PlannedRidesNotifier {
  @override
  Future<List<PlannedRide>> build() async => const [];
}

class _FakeWeather extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async => const [];
}

Future<_RecordingGateway> _pump(
  WidgetTester tester, {
  required List<GroupRide> rides,
}) async {
  final gateway = _RecordingGateway(rides);
  await _pumpGateway(tester, gateway);
  return gateway;
}

Future<void> _pumpGateway(
  WidgetTester tester,
  PelotonGateway gateway,
) async {
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const Scaffold(body: RidesTab())),
      GoRoute(path: '/detail', builder: (_, __) => const Scaffold()),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pelotonGatewayProvider.overrideWithValue(gateway),
        currentUserIdProvider.overrideWithValue(_me),
        plannedRidesProvider.overrideWith(_FakePlannedRides.new),
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
  group('het model', () {
    test('geen stem is iets anders dan "kan niet"', () {
      final option = _option(
        id: 'a',
        dayOffset: 1,
        votes: const [
          OptionVote(optionId: 'a', userId: _other, canRide: false),
        ],
      );

      expect(option.voteOf(_me), isNull, reason: 'ik heb niet geantwoord');
      expect(option.voteOf(_other), isFalse, reason: 'hij zei kan niet');
      expect(option.yesCount, 0);
    });

    test('een enkel venster is geen keuze', () {
      expect(_ride(options: [_option(id: 'a', dayOffset: 1)]).hasOpenChoice,
          isFalse);
      expect(_ride(options: const []).hasOpenChoice, isFalse);
      expect(
        _ride(options: [
          _option(id: 'a', dayOffset: 1),
          _option(id: 'b', dayOffset: 2),
        ]).hasOpenChoice,
        isTrue,
      );
    });

    test('voorop is stemmen, dan score, dan vroegste', () {
      // b scoort lager maar heeft een stem: stemmen gaan voor.
      final ride = _ride(options: [
        _option(id: 'a', dayOffset: 1, score: 95),
        _option(
          id: 'b',
          dayOffset: 2,
          score: 70,
          votes: const [
            OptionVote(optionId: 'b', userId: _other, canRide: true),
          ],
        ),
      ]);
      expect(ride.frontRunner?.id, 'b');

      // Zonder stemmen wint de hoogste score.
      final onScore = _ride(options: [
        _option(id: 'laag', dayOffset: 1, score: 70),
        _option(id: 'hoog', dayOffset: 2, score: 95),
      ]);
      expect(onScore.frontRunner?.id, 'hoog');

      // Gelijke score en gelijke stemmen: de vroegste.
      final onTime = _ride(options: [
        _option(id: 'laat', dayOffset: 3, score: 80),
        _option(id: 'vroeg', dayOffset: 1, score: 80),
      ]);
      expect(onTime.frontRunner?.id, 'vroeg');
    });
  });

  group('op de ritkaart', () {
    testWidgets('twee vensters leveren een keuze op, een venster niet',
        (tester) async {
      await _pump(tester, rides: [
        _ride(options: [_option(id: 'a', dayOffset: 1)]),
      ]);
      expect(find.text('Kies samen een venster'), findsNothing);

      await _pump(tester, rides: [
        _ride(options: [
          _option(id: 'a', dayOffset: 1),
          _option(id: 'b', dayOffset: 2),
        ]),
      ]);
      expect(find.text('Kies samen een venster'), findsOneWidget);
      expect(find.text('Ik kan'), findsNWidgets(2));
    });

    testWidgets('"Ik kan" stuurt mijn antwoord voor dat ene venster',
        (tester) async {
      final gateway = await _pump(tester, rides: [
        _ride(options: [
          _option(id: 'vroeg', dayOffset: 1, hour: 7, score: 90),
          _option(id: 'laat', dayOffset: 1, hour: 15, score: 60),
        ]),
      ]);

      // De hoogste score staat bovenaan zolang er niemand gestemd heeft.
      await tester.tap(find.text('Ik kan').first);
      await tester.pumpAndSettle();

      expect(gateway.votes, hasLength(1));
      expect(gateway.votes.single.optionId, 'vroeg');
      expect(gateway.votes.single.canRide, isTrue);
    });

    testWidgets('alleen de organisator kan de knoop doorhakken',
        (tester) async {
      final options = [
        _option(id: 'a', dayOffset: 1),
        _option(id: 'b', dayOffset: 2),
      ];

      await _pump(tester, rides: [_ride(ownerId: _other, options: options)]);
      expect(find.text('Kies dit'), findsNothing);

      final gateway =
          await _pump(tester, rides: [_ride(ownerId: _me, options: options)]);
      expect(find.text('Kies dit'), findsNWidgets(2));

      await tester.tap(find.text('Kies dit').first);
      await tester.pumpAndSettle();
      expect(gateway.chosen, hasLength(1));
    });

    // Sweep "stille takken" (2026-09-21): een mislukte aanroep deed voorheen
    // zichtbaar niets -- geen fout, geen melding. Deze drie bewijzen dat de
    // knoppen nu altijd antwoorden.

    testWidgets('een mislukt antwoord zegt het, in plaats van stil niets te doen',
        (tester) async {
      await _pumpGateway(
        tester,
        _ThrowingGateway([
          _ride(
            ownerId: _other,
            participants: const [
              RideParticipant(userId: _me, status: ParticipantStatus.invited),
            ],
          ),
        ]),
      );

      await tester.tap(find.text('Ik ga mee'));
      await tester.pumpAndSettle();

      expect(
        find.text('Je antwoord kon niet worden opgeslagen. Probeer het opnieuw.'),
        findsOneWidget,
      );
    });

    testWidgets('een mislukte stem zegt het, in plaats van stil niets te doen',
        (tester) async {
      await _pumpGateway(
        tester,
        _ThrowingGateway([
          _ride(options: [
            _option(id: 'a', dayOffset: 1),
            _option(id: 'b', dayOffset: 2),
          ]),
        ]),
      );

      await tester.tap(find.text('Ik kan').first);
      await tester.pumpAndSettle();

      expect(
        find.text('Je antwoord kon niet worden opgeslagen. Probeer het opnieuw.'),
        findsOneWidget,
      );
    });

    testWidgets('kiezen faalt: de foutmelding staat er, en het succes niet',
        (tester) async {
      await _pumpGateway(
        tester,
        _ThrowingGateway([
          _ride(ownerId: _me, options: [
            _option(id: 'a', dayOffset: 1),
            _option(id: 'b', dayOffset: 2),
          ]),
        ]),
      );

      await tester.tap(find.text('Kies dit').first);
      await tester.pumpAndSettle();

      expect(
        find.text(
            'De rit kon niet op het gekozen venster worden gezet. Probeer het opnieuw.'),
        findsOneWidget,
      );
      expect(find.text('De rit staat nu op dit venster'), findsNothing);
    });
  });
}
