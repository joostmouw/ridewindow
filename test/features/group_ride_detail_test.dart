// test/features/group_ride_detail_test.dart
//
// Het ritdetail van een groepsrit (fase 35, plan 04).
//
// Wat hier vastligt:
// - het detail toont de gedeelde rit die je aantikte, ook als er twee op
//   hetzelfde tijdvak staan (35-01 laat ze allebei staan);
// - "Ik ga mee" / "Kan niet", afzeggen en alsnog meegaan werken op een
//   groepsrit, via respondToSharedRide (een upsert, want er is nog geen rij);
// - Home en de Ritten-tab geven het rit-id mee.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/detail/detail_args.dart';
import 'package:ridewindow/features/detail/ride_detail_screen.dart';
import 'package:ridewindow/features/planned/planned_rides_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/hourly_scores_provider.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';
const _anna = 'uid-anna';
const _mark = 'uid-mark';
const _jacco = 'uid-jacco';
const _ingrid = 'uid-ingrid';

DateTime _at(int dayOffset, int hour) {
  final d = DateTime.now().add(Duration(days: dayOffset));
  return DateTime(d.year, d.month, d.day, hour);
}

/// Morgen 09:00-13:00, dezelfde standaard als [FakeGroupGateway.groupRide].
final _start = _at(1, 9);
final _end = _at(1, 13);

PelotonGroup _onTheRoll({String name = 'On the Roll'}) => FakeGroupGateway.group(
      'g1',
      name,
      members: [
        FakeGroupGateway.member(_anna, role: GroupRole.admin, name: 'Anna'),
        FakeGroupGateway.member(_me, name: 'Joost', joinedDay: 1),
        FakeGroupGateway.member(_mark, name: 'Mark', joinedDay: 2),
        FakeGroupGateway.member(_jacco, name: 'Jacco', joinedDay: 3),
        FakeGroupGateway.member(_ingrid, name: 'Ingrid', joinedDay: 4),
      ],
    );

/// Jouw eigen gewone rit met Bram (r1) en Anna's groepsrit (r2), allebei op
/// hetzelfde tijdvak.
FakeGroupGateway _twoOnOneSlot({List<RideParticipant> r2Participants = const []}) {
  final fake = FakeGroupGateway(myName: 'Joost');
  fake.groups['g1'] = _onTheRoll();
  fake.rides.addAll([
    FakeGroupGateway.groupRide(
      'r1',
      ownerId: _me,
      ownerName: 'Joost',
      participants: const [
        RideParticipant(
          userId: 'uid-bram',
          status: ParticipantStatus.invited,
          displayName: 'Bram',
        ),
      ],
    ),
    FakeGroupGateway.groupRide(
      'r2',
      ownerId: _anna,
      ownerName: 'Anna',
      groupId: 'g1',
      participants: r2Participants,
    ),
  ]);
  return fake;
}

List<String> _responses(FakeGroupGateway fake) =>
    fake.calls.where((c) => c.startsWith('respondTo')).toList();

void main() {
  group('welke rit het detail toont (CLUB-14)', () {
    testWidgets('met groupRideId r2: de aangetikte groepsrit', (tester) async {
      await _pumpDetail(tester, _twoOnOneSlot(), groupRideId: 'r2');

      expect(find.text('ANNA VRAAGT OF JE MEEGAAT'), findsOneWidget);
      expect(find.text('Ik ga mee'), findsOneWidget);
      expect(find.text('Kan niet'), findsOneWidget);
      expect(find.text('JIJ ORGANISEERT'), findsNothing);
    });

    testWidgets('met groupRideId r1: je eigen rit op hetzelfde tijdvak',
        (tester) async {
      await _pumpDetail(tester, _twoOnOneSlot(), groupRideId: 'r1');

      expect(find.text('JIJ ORGANISEERT'), findsOneWidget);
      expect(find.text('Ik ga mee'), findsNothing);
    });

    testWidgets('zonder groupRideId: de eerste gedeelde rit op het tijdvak',
        (tester) async {
      await _pumpDetail(tester, _twoOnOneSlot());

      // Openstaande uitnodigingen staan vooraan (voorrang pending).
      expect(find.text('ANNA VRAAGT OF JE MEEGAAT'), findsOneWidget);
    });

    testWidgets('een rit die er niet meer is: terug naar het tijdvak',
        (tester) async {
      await _pumpDetail(tester, _twoOnOneSlot(), groupRideId: 'weg');

      expect(find.text('ANNA VRAAGT OF JE MEEGAAT'), findsOneWidget);
    });
  });

  group('antwoorden op het detail van een groepsrit (CLUB-14)', () {
    testWidgets('"Ik ga mee" maakt je rij aan en toont daarna "Toch niet"',
        (tester) async {
      final fake = _twoOnOneSlot();
      await _pumpDetail(tester, fake, groupRideId: 'r2');

      await tester.tap(find.text('Ik ga mee'));
      await tester.pumpAndSettle();

      expect(_responses(fake), ['respondToGroupRide:r2:true']);
      expect(find.text('JE GAAT MEE MET ANNA'), findsOneWidget);
      expect(find.text('Toch niet'), findsOneWidget);
    });

    testWidgets('"Kan niet" gaat ook via de upsert', (tester) async {
      final fake = _twoOnOneSlot();
      await _pumpDetail(tester, fake, groupRideId: 'r2');

      await tester.tap(find.text('Kan niet'));
      await tester.pumpAndSettle();

      expect(_responses(fake), ['respondToGroupRide:r2:false']);
    });

    testWidgets('afzeggen, en ongedaan maken zet je weer op ja',
        (tester) async {
      final fake = _twoOnOneSlot(
        r2Participants: const [
          RideParticipant(userId: _me, status: ParticipantStatus.accepted),
        ],
      );
      await _pumpDetail(tester, fake, groupRideId: 'r2');

      await tester.tap(find.text('Toch niet'));
      await tester.pumpAndSettle();
      expect(_responses(fake), ['respondToGroupRide:r2:false']);

      await tester.tap(find.text('Ongedaan maken'));
      await tester.pumpAndSettle();
      expect(_responses(fake), [
        'respondToGroupRide:r2:false',
        'respondToGroupRide:r2:true',
      ]);
    });

    testWidgets('alsnog meegaan na afzeggen', (tester) async {
      final fake = _twoOnOneSlot(
        r2Participants: const [
          RideParticipant(userId: _me, status: ParticipantStatus.declined),
        ],
      );
      await _pumpDetail(tester, fake, groupRideId: 'r2');

      await tester.tap(find.text('Toch meegaan'));
      await tester.pumpAndSettle();

      expect(_responses(fake), ['respondToGroupRide:r2:true']);
      expect(find.text('Je gaat toch mee'), findsOneWidget);
    });
  });

  group('de Ritten-tab geeft het rit-id mee', () {
    testWidgets('tik op een groepsritkaart: DetailArgs.groupRideId is r2',
        (tester) async {
      DetailArgs? pushed;
      await _pumpRidesTab(tester, _twoOnOneSlot(), (args) => pushed = args);

      await tester.tap(find.text('Anna vraagt of je meegaat'));
      await tester.pumpAndSettle();

      expect(pushed, isNotNull);
      expect(pushed!.groupRideId, 'r2');
    });
  });
}

// --- harnas ------------------------------------------------------------------

class _FakeLocation extends LocationNotifier {
  @override
  Future<LocationData> build() async => const LocationData(
        lat: 52.3676,
        lon: 4.9041,
        city: 'Amsterdam',
        source: LocationSource.override,
      );
}

class _FakeWeather extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async => const [];
}

class _FakePlannedRides extends PlannedRidesNotifier {
  @override
  Future<List<PlannedRide>> build() async => const [];
}

class _FakeProfile extends ProfileNotifier {
  @override
  Future<UserProfile> build() async => const UserProfile(
        tolerances: WeatherTolerances(
          tempMinIdealC: 10.0,
          tempMaxIdealC: 30.0,
          windMaxIdealKmh: 25.0,
          rainMaxIdealMm: 1.0,
        ),
        allowedDurations: [2, 3],
        theme: 'system',
        userName: 'Joost',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      );
}

List<Override> _overrides(FakeGroupGateway fake) => [
      pelotonGatewayProvider.overrideWithValue(fake),
      currentUserIdProvider.overrideWithValue(_me),
      locationProvider.overrideWith(_FakeLocation.new),
      profileProvider.overrideWith(_FakeProfile.new),
      weatherProvider.overrideWith(_FakeWeather.new),
      allHourlyScoresProvider.overrideWithValue(const []),
      plannedRidesProvider.overrideWith(_FakePlannedRides.new),
    ];

/// Het detail in een GoRouter, zodat een tik op de groepschip ergens heen kan.
/// [width] en [scale] voor de pastests op 360 dp.
Future<List<String>> _pumpDetail(
  WidgetTester tester,
  FakeGroupGateway fake, {
  String? groupRideId,
  double width = 800,
  double scale = 1.0,
  bool dark = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = Size(width * 2, 6000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  final slot = RideSlot(
    start: _start,
    end: _end,
    overallScore: 80,
    tier: rideTierFromScore(80),
    hours: const [],
  );
  final visited = <String>[];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => RideDetailScreen(
          slot: slot,
          forecasts: const [],
          groupRideId: groupRideId,
        ),
      ),
      GoRoute(
        path: '/peloton/group/:groupId',
        builder: (_, state) {
          visited.add(state.uri.path);
          return const Scaffold(body: Text('groepsscherm'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(fake),
      retry: (_, __) => null,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: buildAppTheme(dark ? Brightness.dark : Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return visited;
}

Future<void> _pumpRidesTab(
  WidgetTester tester,
  FakeGroupGateway fake,
  void Function(DetailArgs) onDetail,
) async {
  SharedPreferences.setMockInitialValues({});
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: RidesTab()),
      ),
      GoRoute(
        path: '/detail',
        builder: (_, state) {
          onDetail(state.extra! as DetailArgs);
          return const Scaffold(body: Text('detail'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(fake),
      retry: (_, __) => null,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: buildAppTheme(Brightness.light),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
