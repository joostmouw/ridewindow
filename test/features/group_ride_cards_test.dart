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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  Future<void> cancelOwnRide(RideEntry entry) async {}

  @override
  Future<bool> confirmRemove(RideEntry entry) async => true;

  @override
  void removePlanned(RideEntry entry) {}

  @override
  Future<void> voteOnOption(RideEntry entry, RideOption option,
      {required bool canRide}) async {}

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

void main() {
  group('RideRoleLine met groepsnaam', () {
    testWidgets('groepsnaam vooraan, dan de rolzin, op één regel',
        (tester) async {
      await _pumpAt360(
        tester,
        SizedBox(
            width: 328, child: RideRoleLine(entry: _groupEntry(_shortName))),
      );

      expect(find.text(_shortName), findsOneWidget);
      expect(find.text(' · '), findsOneWidget);
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
      expect(find.text(' · '), findsNothing);
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

            // De rolzin begint zichtbaar: hij krijgt minstens de helft van
            // de regel, hoe lang de groepsnaam ook is.
            final role = find.descendant(
              of: find.byKey(withKey),
              matching: find.textContaining('Anna vraagt'),
            );
            expect(role, findsOneWidget);
            expect(tester.getSize(role).width, greaterThan(width * 0.5));

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
            width: 328, child: RideRoleLine(entry: _groupEntry(_shortName))),
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
          expect(
            tester.getSize(find.byKey(groupKey)).height,
            tester.getSize(find.byKey(sharedKey)).height,
          );
        });
      }
    }
  });
}
