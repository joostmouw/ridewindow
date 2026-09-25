// test/features/group_ride_cards_test.dart
//
// Groepsritten op de ritkaarten (fase 35, plan 03).
//
// Joost: "Het moet passen op het scherm, dat is het belangrijkste." De
// groepsnaam staat daarom vooraan in de bestaande rolregel (schets 016, vraag
// 2 B) en niet op een eigen regel of als chip. Deze tests bewijzen dat op
// 360 dp, ook met grote tekstschaal: geen overflow, de rolzin blijft leesbaar,
// en een kaart met een groepsrit is precies even hoog als dezelfde kaart met
// een gewone gedeelde rit.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/planned_rides_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/domain/models/units.dart';
import 'package:ridewindow/features/planned/planned_rides_screen.dart';
import 'package:ridewindow/features/shared/ride_role_style.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';
import 'package:ridewindow/theme/app_theme.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';
const _anna = 'uid-anna';

/// Veertig tekens: langer dan een groepsnaam in de praktijk wordt.
const _longName = 'Tour de Waterland Zondagochtend Clubrit';
const _shortName = 'On the Roll';

PelotonGroup _group(String name) => FakeGroupGateway.group(
      'g1',
      name,
      members: [
        FakeGroupGateway.member(_anna, role: GroupRole.admin, name: 'Anna'),
        FakeGroupGateway.member(_me, name: 'Ik', joinedDay: 1),
        FakeGroupGateway.member('uid-b', name: 'Bas', joinedDay: 2),
        FakeGroupGateway.member('uid-c', name: 'Cor', joinedDay: 3),
        FakeGroupGateway.member('uid-d', name: 'Dirk', joinedDay: 4),
      ],
    );

/// Een groepsrit van Anna waarop jij (en drie anderen) nog niet antwoordden:
/// 1 gaat mee (Anna zelf), 4 nog niet.
RideEntry _groupEntry(String name, {RideRole role = RideRole.pending}) {
  final ride = FakeGroupGateway.groupRide(
    'r-group',
    ownerId: role == RideRole.organiser ? _me : _anna,
    ownerName: role == RideRole.organiser ? 'Ik' : 'Anna',
    groupId: 'g1',
  );
  return RideEntry(
    start: ride.start,
    end: ride.end,
    plannedScore: ride.plannedScore,
    role: role,
    group: ride,
    pelotonGroup: _group(name),
  );
}

/// Dezelfde rit als gewone gedeelde rit, met gelijke tellingen: 1 gaat mee,
/// 4 wachten nog.
RideEntry _sharedEntry({RideRole role = RideRole.pending}) {
  final ride = FakeGroupGateway.groupRide(
    'r-shared',
    ownerId: _anna,
    ownerName: 'Anna',
    participants: const [
      RideParticipant(userId: 'uid-x', status: ParticipantStatus.accepted),
      RideParticipant(userId: _me, status: ParticipantStatus.invited),
      RideParticipant(userId: 'uid-b', status: ParticipantStatus.invited),
      RideParticipant(userId: 'uid-c', status: ParticipantStatus.invited),
      RideParticipant(userId: 'uid-d', status: ParticipantStatus.invited),
    ],
  );
  return RideEntry(
    start: ride.start,
    end: ride.end,
    plannedScore: ride.plannedScore,
    role: role,
    group: ride,
  );
}

class _Host implements RideCardHost {
  @override
  bool get busy => false;

  @override
  Future<void> respond(RideEntry entry, {required bool accepted}) async {}

  @override
  Future<void> withdraw(RideEntry entry) async {}

  @override
  Future<bool> remove(RideEntry entry) async => true;

  @override
  Future<void> voteOnOption(
    RideEntry entry,
    RideOption option, {
    required bool canRide,
  }) async {}

  @override
  Future<void> chooseOption(RideEntry entry, RideOption option) async {}
}

Future<void> _pumpAt360(
  WidgetTester tester,
  Widget child, {
  double scale = 1.0,
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('nl'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      // Het echte thema: knoppen en tekststijlen bepalen of iets past.
      theme: buildAppTheme(dark ? Brightness.dark : Brightness.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Tekst op een ritkaart. Sinds 35-05 staat de groepsnaam ook als chip boven
/// de lijst (CLUB-26); deze tests gaan over de kaart.
Finder _onCard(String text) =>
    find.descendant(of: find.byType(RideCard), matching: find.text(text));

void main() {
  group('RideRoleLine met groepsnaam', () {
    testWidgets('groepsnaam vooraan, dan de rolzin, op één regel',
        (tester) async {
      await _pumpAt360(
        tester,
        SizedBox(
          width: 328,
          child: RideRoleLine(entry: _groupEntry(_shortName)),
        ),
      );

      expect(find.text(_shortName), findsOneWidget);
      expect(find.text('·'), findsOneWidget);
      expect(find.text('Anna vraagt of je meegaat'), findsOneWidget);

      final nameBox = tester.getRect(find.text(_shortName));
      final roleBox = tester.getRect(find.text('Anna vraagt of je meegaat'));
      expect(nameBox.left, lessThan(roleBox.left));
      expect(nameBox.center.dy, closeTo(roleBox.center.dy, 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('zonder groepsnaam precies de regel van nu', (tester) async {
      await _pumpAt360(
        tester,
        SizedBox(width: 328, child: RideRoleLine(entry: _sharedEntry())),
      );

      expect(find.text('Anna vraagt of je meegaat'), findsOneWidget);
      expect(find.text('·'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(RideRoleLine),
          matching: find.byType(LayoutBuilder),
        ),
        findsNothing,
      );
    });

    testWidgets('de organisator houdt de megafoon vooraan', (tester) async {
      await _pumpAt360(
        tester,
        SizedBox(
          width: 328,
          child: RideRoleLine(
            entry: _groupEntry(_shortName, role: RideRole.organiser),
          ),
        ),
      );

      final icon = tester.getRect(find.byIcon(AppIcons.megaphoneSimple));
      final name = tester.getRect(find.text(_shortName));
      final role = tester.getRect(find.text('Jij organiseert'));
      expect(icon.left, lessThan(name.left));
      expect(name.left, lessThan(role.left));
    });

    for (final width in [180.0, 328.0]) {
      for (final dense in [true, false]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          testWidgets(
              'lange naam op $width dp, dense $dense, tekstschaal $scale: '
              'past, rol leesbaar, even hoog', (tester) async {
            const withKey = Key('met-groep');
            const withoutKey = Key('zonder-groep');
            await _pumpAt360(
              tester,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: width,
                    child: RideRoleLine(
                      key: withKey,
                      entry: _groupEntry(_longName),
                      dense: dense,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: RideRoleLine(
                      key: withoutKey,
                      entry: _sharedEntry(),
                      dense: dense,
                    ),
                  ),
                ],
              ),
              scale: scale,
            );

            expect(tester.takeException(), isNull);

            // De rolzin begint zichtbaar: de naam neemt hooguit 45 procent,
            // de rol krijgt de rest na het icoon en het scheidingsteken.
            final role = find.descendant(
              of: find.byKey(withKey),
              matching: find.textContaining('Anna vraagt'),
            );
            expect(role, findsOneWidget);
            final line = tester.getRect(find.byKey(withKey));
            final icon = tester.getRect(find.byIcon(AppIcons.hourglass).first);
            final dot = tester.getRect(find.text('·'));
            final roleRect = tester.getRect(role);
            // Vóór de rol: icoon + 6, de naam (hooguit 45 procent) en het
            // scheidingsteken (punt + 2 x 4 lucht). Meer niet.
            final iconSpace = icon.right + 6 - line.left;
            expect(
              roleRect.left - line.left,
              lessThanOrEqualTo(iconSpace + width * 0.45 + dot.width + 8 + 0.5),
            );
            expect(roleRect.width, greaterThan(0));
            expect(roleRect.right, closeTo(line.right, 0.5));

            // De naam is afgekapt, niet uitgerekt.
            final name = find.text(_longName);
            expect(tester.getSize(name).width, lessThanOrEqualTo(width * 0.45));

            expect(
              tester.getSize(find.byKey(withKey)).height,
              tester.getSize(find.byKey(withoutKey)).height,
            );
          });
        }
      }
    }

    testWidgets('leest als één zin voor de schermlezer', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpAt360(
        tester,
        SizedBox(
          width: 328,
          child: RideRoleLine(entry: _groupEntry(_shortName)),
        ),
      );
      expect(
        find.bySemanticsLabel('$_shortName, Anna vraagt of je meegaat'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('RideCard op 360 dp', () {
    Widget card(RideEntry entry, Key key) => SizedBox(
          width: 360,
          child: RideCard(
            key: key,
            entry: entry,
            host: _Host(),
            units: UnitPrefs.defaults,
            myUserId: _me,
            allScores: const [],
            forecasts: const [],
            cityName: 'Amsterdam',
            location: null,
          ),
        );

    for (final scale in [1.0, 1.3, 2.0]) {
      for (final dark in [false, true]) {
        if (dark && scale != 1.0) continue;
        testWidgets(
            'groepsrit even hoog als gewone gedeelde rit '
            '(tekstschaal $scale${dark ? ', donker' : ''})', (tester) async {
          const groupKey = Key('groepsrit');
          const sharedKey = Key('gedeeld');
          await _pumpAt360(
            tester,
            Column(
              children: [
                card(_groupEntry(_longName), groupKey),
                card(_sharedEntry(), sharedKey),
              ],
            ),
            scale: scale,
            dark: dark,
          );

          expect(tester.takeException(), isNull);
          expect(find.text(_longName), findsOneWidget);
          // De antwoordknoppen staan rechts, ook als ze onder elkaar vallen.
          final accept = tester
              .getRect(find.widgetWithText(FilledButton, 'Ik ga mee').first);
          expect(
            accept.center.dx,
            greaterThan(tester.getRect(find.byKey(groupKey)).center.dx),
          );
          expect(
            tester.getSize(find.byKey(groupKey)).height,
            tester.getSize(find.byKey(sharedKey)).height,
          );
        });
      }
    }
  });

  group('antwoorden op een groepsrit vanaf de kaart (CLUB-14)', () {
    testWidgets('"Ik ga mee" voegt je eigen rij in, met je naam',
        (tester) async {
      final fake = await _pumpRidesTab(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Ik ga mee'));
      await tester.pumpAndSettle();

      expect(_responses(fake), ['respondToGroupRide:gr1:true']);
      final mine =
          fake.rides.single.participants.singleWhere((p) => p.userId == _me);
      expect(mine.status, ParticipantStatus.accepted);
      expect(mine.displayName, 'Joost');

      // Eén keer in de lijst, met de nieuwe rol en de groepsnaam.
      expect(find.byType(RideCard), findsOneWidget);
      expect(find.text('Je gaat mee met Anna'), findsOneWidget);
      expect(_onCard(_shortName), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Ik ga mee'), findsNothing);
    });

    testWidgets('"Kan niet" zet hem onder Afgezegd', (tester) async {
      final fake = await _pumpRidesTab(tester, withSoloRide: true);

      await tester.tap(find.widgetWithText(TextButton, 'Kan niet'));
      await tester.pumpAndSettle();

      expect(_responses(fake), ['respondToGroupRide:gr1:false']);
      // Uit de gewone lijst: alleen de eigen rit staat er nog.
      expect(_onCard(_shortName), findsNothing);
      expect(find.byType(RideCard), findsOneWidget);

      await tester.tap(find.text('Afgezegd'));
      await tester.pumpAndSettle();
      expect(_onCard(_shortName), findsOneWidget);
      expect(find.text('Je zei nee tegen Anna'), findsOneWidget);
    });

    testWidgets('afzeggen na "Ik ga mee" en ongedaan maken', (tester) async {
      final fake = await _pumpRidesTab(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Ik ga mee'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Toch niet'));
      await tester.pumpAndSettle();

      expect(find.text('Je doet niet meer mee aan deze rit'), findsOneWidget);
      expect(find.text('Je gaat mee met Anna'), findsNothing);

      await tester.tap(find.text('Ongedaan maken'));
      await tester.pumpAndSettle();

      expect(_responses(fake), [
        'respondToGroupRide:gr1:true',
        'respondToGroupRide:gr1:false',
        'respondToGroupRide:gr1:true',
      ]);
      expect(find.text('Je gaat mee met Anna'), findsOneWidget);
      expect(find.byType(RideCard), findsOneWidget);
    });

    testWidgets('een gewone uitnodiging gaat nog via respondToRide',
        (tester) async {
      final fake = await _pumpRidesTab(
        tester,
        rides: [
          FakeGroupGateway.groupRide(
            'r2',
            ownerId: _anna,
            ownerName: 'Anna',
            participants: const [
              RideParticipant(userId: _me, status: ParticipantStatus.invited),
            ],
          ),
        ],
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Ik ga mee'));
      await tester.pumpAndSettle();

      expect(_responses(fake), ['respondToRide:r2:true']);
      expect(find.text('Je gaat mee met Anna'), findsOneWidget);
    });

    testWidgets('twee snelle tikken geven één antwoord', (tester) async {
      // Het antwoord blijft onderweg tot de test het loslaat, zoals op een
      // traag netwerk. Zonder die rem is de fake al klaar voor de tweede tik.
      final slow = _SlowGateway();
      await _pumpRidesTab(tester, fake: slow);

      final accept = find.widgetWithText(FilledButton, 'Ik ga mee');
      await tester.tap(accept);
      await tester.tap(accept, warnIfMissed: false);
      slow.gate.complete();
      await tester.pumpAndSettle();

      expect(_responses(slow), ['respondToGroupRide:gr1:true']);
    });

    testWidgets('wie de groep verlaat, ziet de groepsrit niet meer (CLUB-13)',
        (tester) async {
      final fake = await _pumpRidesTab(tester, withSoloRide: true);
      expect(find.text('Anna vraagt of je meegaat'), findsOneWidget);

      await fake.leaveGroup('g1');
      ProviderScope.containerOf(tester.element(find.byType(RidesTab)))
          .invalidate(groupRidesProvider);
      await tester.pumpAndSettle();

      expect(find.text('Anna vraagt of je meegaat'), findsNothing);
      expect(_onCard(_shortName), findsNothing);
    });
  });
}

// --- RidesTab met FakeGroupGateway -------------------------------------------

class _SlowGateway extends FakeGroupGateway {
  final gate = Completer<void>();

  @override
  Future<void> respondToGroupRide({
    required String rideId,
    required bool accepted,
    String? displayName,
  }) async {
    await gate.future;
    return super.respondToGroupRide(
      rideId: rideId,
      accepted: accepted,
      displayName: displayName,
    );
  }
}

List<String> _responses(FakeGroupGateway fake) =>
    fake.calls.where((c) => c.startsWith('respondTo')).toList();

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

/// De Ritten-tab met groep g1 (Anna en jij) en standaard één groepsrit van
/// Anna waarop jij nog niet antwoordde.
Future<FakeGroupGateway> _pumpRidesTab(
  WidgetTester tester, {
  List<GroupRide>? rides,
  bool withSoloRide = false,
  FakeGroupGateway? fake,
}) async {
  SharedPreferences.setMockInitialValues({});
  fake ??= FakeGroupGateway();
  fake.groups['g1'] = FakeGroupGateway.group(
    'g1',
    _shortName,
    members: [
      FakeGroupGateway.member(_anna, role: GroupRole.admin, name: 'Anna'),
      FakeGroupGateway.member(_me, name: 'Joost', joinedDay: 1),
    ],
  );
  fake.rides.addAll(
    rides ??
        [
          FakeGroupGateway.groupRide(
            'gr1',
            ownerId: _anna,
            ownerName: 'Anna',
            groupId: 'g1',
          ),
        ],
  );
  final soon = DateTime.now().add(const Duration(days: 4));
  final planned = [
    if (withSoloRide)
      PlannedRide(
        start: DateTime(soon.year, soon.month, soon.day, 7),
        end: DateTime(soon.year, soon.month, soon.day, 9),
        plannedScore: 61,
      ),
  ];
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: RidesTab()),
      ),
      GoRoute(
        path: '/detail',
        builder: (_, __) => const Scaffold(body: Text('detail')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pelotonGatewayProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue(_me),
        plannedRidesProvider.overrideWith(() => _FakePlannedRides(planned)),
        weatherProvider.overrideWith(_FakeWeather.new),
        profileProvider.overrideWith(_FakeProfile.new),
      ],
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
  return fake;
}
