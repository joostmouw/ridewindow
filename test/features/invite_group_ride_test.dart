// test/features/invite_group_ride_test.dart
//
// CLUB-12 (fase 35): vanuit het uitnodigscherm een rit uitzetten voor de hele
// groep. Schets 016 "Met wie rijd je?".
//
// Wat hier vastligt:
// - wie in geen groep zit, ziet het oude scherm;
// - een groep en losse maatjes sluiten elkaar uit (een participant-rij van
//   een niet-lid op een groepsrit geeft geen toegang, 0012);
// - een groepsrit krijgt group_id en geen participant-rijen;
// - een tweede groepsrit op exact hetzelfde tijdvak komt er niet;
// - het maatjespad hergebruikt nooit een groepsrit of andermans rit.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/peloton_group.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/peloton/group_crest.dart';
import 'package:ridewindow/features/peloton/invite_buddies_sheet.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/slots_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

import '../helpers/fake_group_gateway.dart';

const _me = 'uid-me';

DateTime _at(int dayOffset, int hour) {
  final d = DateTime.now().add(Duration(days: dayOffset));
  return DateTime(d.year, d.month, d.day, hour);
}

/// Het tijdvak waar de gebruiker vandaan komt: morgen 09:00-13:00, dezelfde
/// standaard als [FakeGroupGateway.groupRide].
final _start = _at(1, 9);
final _end = _at(1, 13);

/// Een tweede venster uit de slot-generator, zodat er iets te kiezen valt.
final _otherSlot = RideSlot(
  start: _at(2, 9),
  end: _at(2, 13),
  overallScore: 75,
  tier: rideTierFromScore(75),
  hours: const [],
);

class _FakeSlots extends SlotsNotifier {
  @override
  SlotsState build() => SlotsLoaded([_otherSlot]);
}

class _FakeProfile extends ProfileNotifier {
  @override
  Future<UserProfile> build() async => const UserProfile(
        tolerances: WeatherTolerances(
          tempMinIdealC: 12,
          tempMaxIdealC: 26,
          windMaxIdealKmh: 15,
          rainMaxIdealMm: 0.5,
          darknessWeight: 0.5,
        ),
        allowedDurations: [2],
        theme: 'system',
        locationOverride: null,
        userName: 'Ik',
        locale: 'nl',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      );
}

PelotonGroup _onTheRoll({String name = 'On the Roll'}) => FakeGroupGateway.group(
      'g1',
      name,
      members: [
        FakeGroupGateway.member(_me, role: GroupRole.admin, name: 'Ik'),
        FakeGroupGateway.member('uid-b', name: 'Bram', joinedDay: 1),
      ],
    );

const _fleur = Friend(userId: 'uid-f', displayName: 'Fleur');

FakeGroupGateway _gateway({
  bool withGroup = true,
  bool withFriend = true,
  String groupName = 'On the Roll',
}) {
  final g = _onTheRoll(name: groupName);
  return FakeGroupGateway(
    groups: withGroup ? {g.id: g} : {},
    friends: withFriend ? [_fleur] : [],
  );
}

Future<void> _pump(WidgetTester tester, FakeGroupGateway gateway) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pelotonGatewayProvider.overrideWithValue(gateway),
        currentUserIdProvider.overrideWithValue(_me),
        slotsProvider.overrideWith(_FakeSlots.new),
        profileProvider.overrideWith(_FakeProfile.new),
      ],
      retry: (_, __) => null,
      child: MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: ThemeData(extensions: const [RideWindowTheme.light]),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              // Het profiel vast laden, zoals op het detail al gebeurd is.
              ref.watch(profileProvider);
              return Center(
                child: ElevatedButton(
                  onPressed: () => showInviteBuddiesSheet(
                    context,
                    ref,
                    start: _start,
                    end: _end,
                    plannedScore: 80,
                  ),
                  child: const Text('open'),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Finder get _nextButton =>
    find.widgetWithText(FilledButton, 'Verder: kies vensters');

bool _enabled(WidgetTester tester, Finder button) =>
    tester.widget<FilledButton>(button).onPressed != null;

CheckboxListTile _friendTile(WidgetTester tester) =>
    tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Fleur'),
    );

RadioListTile<String> _groupTile(WidgetTester tester) =>
    tester.widget<RadioListTile<String>>(find.byType(RadioListTile<String>));

/// Bevestigt het vensterscherm; met [extraWindow] ook het tweede venster.
Future<void> _confirmWindows(
  WidgetTester tester, {
  bool extraWindow = false,
}) async {
  expect(find.text('Welke vensters leg je voor?'), findsOneWidget);
  if (extraWindow) {
    await tester.tap(find.byType(CheckboxListTile).at(1));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.widgetWithText(FilledButton, 'Uitnodigen'));
  await tester.pumpAndSettle();
}

void main() {
  group('zonder groep', () {
    testWidgets('het scherm is het oude: titel, geen koppen, knop Uitnodigen',
        (tester) async {
      await _pump(tester, _gateway(withGroup: false));
      await _open(tester);

      expect(find.text('Wie gaat er mee?'), findsOneWidget);
      expect(find.text('Met wie rijd je?'), findsNothing);
      expect(find.text('Een groep'), findsNothing);
      expect(find.text('Of losse maatjes'), findsNothing);
      expect(find.byType(RadioListTile<String>), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Uitnodigen'), findsOneWidget);
    });

    testWidgets('zonder maatjes en zonder groepen: de oude melding',
        (tester) async {
      await _pump(tester, _gateway(withGroup: false, withFriend: false));
      await _open(tester);

      expect(
        find.text('Voeg eerst een maatje toe via Ritten, tab Peloton.'),
        findsOneWidget,
      );
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('met een groep', () {
    testWidgets('groep boven de maatjes, met kenteken, naam en ledental',
        (tester) async {
      await _pump(tester, _gateway());
      await _open(tester);

      expect(find.text('Met wie rijd je?'), findsOneWidget);
      expect(find.text('Een groep'), findsOneWidget);
      expect(find.text('Of losse maatjes'), findsOneWidget);
      expect(find.text('On the Roll'), findsOneWidget);
      expect(find.text('2 leden'), findsOneWidget);
      expect(find.byType(GroupCrest), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Een groep')).dy,
        lessThan(tester.getTopLeft(find.text('Of losse maatjes')).dy),
      );
      expect(_enabled(tester, _nextButton), isFalse);
    });

    testWidgets('groep kiezen zet de maatjes uit; nog eens tikken maakt het ongedaan',
        (tester) async {
      await _pump(tester, _gateway());
      await _open(tester);

      await tester.tap(find.text('On the Roll'));
      await tester.pumpAndSettle();

      expect(_friendTile(tester).onChanged, isNull);
      expect(_enabled(tester, _nextButton), isTrue);
      expect(find.text('2 leden · ieder lid ziet de rit'), findsOneWidget);

      await tester.tap(find.text('On the Roll'));
      await tester.pumpAndSettle();

      expect(_friendTile(tester).onChanged, isNotNull);
      expect(_enabled(tester, _nextButton), isFalse);
      expect(find.text('2 leden'), findsOneWidget);
    });

    testWidgets('een maatje aanvinken zet de groep uit', (tester) async {
      await _pump(tester, _gateway());
      await _open(tester);

      await tester.tap(find.text('Fleur'));
      await tester.pumpAndSettle();

      expect(_groupTile(tester).enabled, isFalse);
      expect(_enabled(tester, _nextButton), isTrue);
    });

    testWidgets('geen maatjes maar wel een groep: de kiezer opent',
        (tester) async {
      await _pump(tester, _gateway(withFriend: false));
      await _open(tester);

      expect(find.text('Met wie rijd je?'), findsOneWidget);
      expect(find.text('Of losse maatjes'), findsNothing);
      expect(
        find.text('Voeg eerst een maatje toe via Ritten, tab Peloton.'),
        findsNothing,
      );
    });

    testWidgets('groep + een venster: groepsrit met group_id, geen uitnodigingen',
        (tester) async {
      final gateway = _gateway();
      await _pump(tester, gateway);
      await _open(tester);

      await tester.tap(find.text('On the Roll'));
      await tester.pumpAndSettle();
      await tester.tap(_nextButton);
      await tester.pumpAndSettle();
      await _confirmWindows(tester);

      expect(gateway.calls, contains('createGroupRide:g1'));
      expect(gateway.calls.where((c) => c.startsWith('inviteToRide')), isEmpty);
      expect(
        gateway.calls.where((c) => c.startsWith('proposeOptions')),
        isEmpty,
      );
      final ride = gateway.rides.single;
      expect(ride.groupId, 'g1');
      expect(ride.participants, isEmpty);
      expect(find.text('Rit uitgezet voor On the Roll'), findsOneWidget);
    });

    testWidgets('groep + twee vensters: groepsrit en een keuze uit twee',
        (tester) async {
      final gateway = _gateway();
      await _pump(tester, gateway);
      await _open(tester);

      await tester.tap(find.text('On the Roll'));
      await tester.pumpAndSettle();
      await tester.tap(_nextButton);
      await tester.pumpAndSettle();
      await _confirmWindows(tester, extraWindow: true);

      expect(gateway.calls, contains('createGroupRide:g1'));
      expect(gateway.calls, contains('proposeOptions:ride-new-1:2'));
      expect(find.text('2 vensters voorgelegd'), findsOneWidget);
    });

    testWidgets('al een groepsrit van deze groep op dit tijdvak: geen tweede',
        (tester) async {
      final gateway = _gateway();
      // Van een ander lid: ook dan geen tweede.
      gateway.rides.add(
        FakeGroupGateway.groupRide('bestaand', ownerId: 'uid-b', groupId: 'g1'),
      );
      await _pump(tester, gateway);
      await _open(tester);

      await tester.tap(find.text('On the Roll'));
      await tester.pumpAndSettle();
      await tester.tap(_nextButton);
      await tester.pumpAndSettle();

      expect(find.text('Welke vensters leg je voor?'), findsNothing);
      expect(
        gateway.calls.where((c) => c.startsWith('createGroupRide')),
        isEmpty,
      );
      expect(
        find.text('Er staat al een groepsrit van On the Roll op dit tijdstip'),
        findsOneWidget,
      );
    });

    testWidgets('losse maatjes naast een groepsrit: een nieuwe gewone rit',
        (tester) async {
      final gateway = _gateway();
      gateway.rides.addAll([
        FakeGroupGateway.groupRide('groep', ownerId: _me, groupId: 'g1'),
        // Andermans gewone rit waar ik op sta: ook niet hergebruiken.
        FakeGroupGateway.groupRide(
          'van-bram',
          ownerId: 'uid-b',
          participants: const [
            RideParticipant(userId: _me, status: ParticipantStatus.accepted),
          ],
        ),
      ]);
      await _pump(tester, gateway);
      await _open(tester);

      await tester.tap(find.text('Fleur'));
      await tester.pumpAndSettle();
      await tester.tap(_nextButton);
      await tester.pumpAndSettle();
      await _confirmWindows(tester);

      expect(gateway.calls, contains('createGroupRide:-'));
      expect(gateway.calls, contains('inviteToRide:ride-new-1:uid-f'));
      expect(find.text('Uitnodiging verstuurd'), findsOneWidget);
    });

    testWidgets('losse maatjes: een eigen gewone rit op dit tijdvak wordt hergebruikt',
        (tester) async {
      final gateway = _gateway();
      gateway.rides.add(FakeGroupGateway.groupRide('mijn-rit', ownerId: _me));
      await _pump(tester, gateway);
      await _open(tester);

      await tester.tap(find.text('Fleur'));
      await tester.pumpAndSettle();
      await tester.tap(_nextButton);
      await tester.pumpAndSettle();
      await _confirmWindows(tester);

      expect(
        gateway.calls.where((c) => c.startsWith('createGroupRide')),
        isEmpty,
      );
      expect(gateway.calls, contains('inviteToRide:mijn-rit:uid-f'));
    });

    testWidgets('past op 360 dp met tekstschaal 1.3 en een lange groepsnaam',
        (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _pump(
        tester,
        _gateway(groupName: 'Toerclub De Snelle Jongens van Oost-Zuid'),
      );
      await _open(tester);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(RadioListTile<String>));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
