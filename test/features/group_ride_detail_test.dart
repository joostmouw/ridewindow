// test/features/group_ride_detail_test.dart
//
// Het ritdetail van een groepsrit (fase 35, plan 04).
//
// Wat hier vastligt:
// - het detail toont de gedeelde rit die je aantikte, ook als er twee op
//   hetzelfde tijdvak staan (35-01 laat ze allebei staan);
// - "Ik ga mee" / "Kan niet", afzeggen en alsnog meegaan werken op een
//   groepsrit, via respondToSharedRide (een upsert, want er is nog geen rij);
// - Home en de Ritten-tab geven het rit-id mee;
// - een groepsrit toont de groep als chip, een rij per huidig lid met het
//   statusicoon (check / prohibit / hourglass, #87), en de telregel
//   (schets 016) als enige telzin -- de zin van de teller zou hem dupliceren;
// - bij meerdere vensters staat per venster wie kan, met namen;
// - alles past op 360 dp met tekstschaal 1.3 en 2.0.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:ridewindow/theme/app_icons.dart';
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

  group('wie komt er op een groepsrit (CLUB-15, CLUB-16)', () {
    testWidgets('chip, een rij per lid met drie statussen en de telregel',
        (tester) async {
      await _pumpDetail(tester, _myGroupRide(), groupRideId: 'r3');

      // Chip met de groepsnaam bovenaan de kaart.
      expect(find.widgetWithText(ActionChip, 'On the Roll'), findsOneWidget);

      _expectRow(tester, _me, 'Joost (jij)', ParticipantStatus.accepted);
      _expectRow(tester, _anna, 'Anna', ParticipantStatus.accepted);
      _expectRow(tester, _mark, 'Mark', ParticipantStatus.declined);
      _expectRow(tester, _jacco, 'Jacco', ParticipantStatus.invited);
      _expectRow(tester, _ingrid, 'Ingrid', ParticipantStatus.invited);

      expect(
        tester.widget<Text>(find.byKey(const ValueKey('group-ride-tally'))).data,
        '2 gaan mee · 1 kan niet · 2 nog niet',
      );
    });

    testWidgets('volgorde: organisator, gaat mee, kan niet, nog niet',
        (tester) async {
      await _pumpDetail(tester, _myGroupRide(), groupRideId: 'r3');

      double y(String uid) =>
          tester.getTopLeft(find.byKey(ValueKey('member-row-$uid'))).dy;
      expect(y(_me), lessThan(y(_anna)));
      expect(y(_anna), lessThan(y(_mark)));
      expect(y(_mark), lessThan(y(_jacco)));
      expect(y(_jacco), lessThan(y(_ingrid)));
    });

    testWidgets('antwoorden van ex-leden staan er niet (T-35-10)',
        (tester) async {
      await _pumpDetail(tester, _myGroupRide(), groupRideId: 'r3');

      expect(find.text('Ex-lid'), findsNothing);
      expect(find.byKey(const ValueKey('member-row-uid-ex')), findsNothing);
    });

    testWidgets('niet de organisator: jouw rij met "(jij)" en jouw antwoord',
        (tester) async {
      final fake = _twoOnOneSlot(
        r2Participants: const [
          RideParticipant(userId: _me, status: ParticipantStatus.declined),
        ],
      );
      await _pumpDetail(tester, fake, groupRideId: 'r2');

      _expectRow(tester, _anna, 'Anna', ParticipantStatus.accepted);
      _expectRow(tester, _me, 'Joost (jij)', ParticipantStatus.declined);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('member-row-$_anna'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('member-row-$_me'))).dy,
        ),
      );
    });

    testWidgets('telregel laat nullen weg, "gaan mee" staat er altijd',
        (tester) async {
      final fake = FakeGroupGateway(myName: 'Joost');
      fake.groups['g1'] = FakeGroupGateway.group(
        'g1',
        'On the Roll',
        members: [
          FakeGroupGateway.member(_anna, role: GroupRole.admin, name: 'Anna'),
          FakeGroupGateway.member(_me, name: 'Joost', joinedDay: 1),
        ],
      );
      fake.rides.add(
        FakeGroupGateway.groupRide(
          'r4',
          ownerId: _anna,
          ownerName: 'Anna',
          groupId: 'g1',
          participants: const [
            RideParticipant(userId: _me, status: ParticipantStatus.accepted),
          ],
        ),
      );
      await _pumpDetail(tester, fake, groupRideId: 'r4');

      expect(
        tester.widget<Text>(find.byKey(const ValueKey('group-ride-tally'))).data,
        '2 gaan mee',
      );
    });

    testWidgets('tik op de chip opent het groepsscherm', (tester) async {
      final visited =
          await _pumpDetail(tester, _myGroupRide(), groupRideId: 'r3');

      await tester.tap(find.widgetWithText(ActionChip, 'On the Roll'));
      await tester.pumpAndSettle();

      expect(visited, ['/peloton/group/g1']);
      expect(find.text('groepsscherm'), findsOneWidget);
    });

    testWidgets('statuskleuren uit de tokens, licht en donker', (tester) async {
      for (final dark in [false, true]) {
        await _pumpDetail(tester, _myGroupRide(), groupRideId: 'r3', dark: dark);
        final context = tester.element(find.byType(RideDetailScreen));
        final rw = context.rw;
        final cs = Theme.of(context).colorScheme;
        Color? colorIn(String uid, IconData icon) => tester
            .widget<Icon>(
              find.descendant(
                of: find.byKey(ValueKey('member-row-$uid')),
                matching: find.byIcon(icon),
              ),
            )
            .color;
        expect(colorIn(_anna, AppIcons.check), rw.scorePerfect);
        expect(colorIn(_mark, AppIcons.prohibit), cs.error);
        expect(colorIn(_jacco, AppIcons.hourglass), rw.textTertiary);
      }
    });

    testWidgets('de teller herhaalt de telregel niet (#87)', (tester) async {
      await _pumpDetail(tester, _myGroupRide(), groupRideId: 'r3');

      // De fietsjes blijven staan, de zin ernaast niet: op het detail staat
      // direct eronder de telregel, en beide was precies de "dubbele tekst"
      // die de tester aanwees.
      expect(find.byIcon(AppIcons.personSimpleBike), findsWidgets);
      expect(find.text('2 gaan mee · 2 wachten nog'), findsNothing);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('group-ride-tally'))).data,
        '2 gaan mee · 1 kan niet · 2 nog niet',
      );
    });

    testWidgets('het statuswoord blijft bestaan als Semantics-label',
        (tester) async {
      await _pumpDetail(tester, _myGroupRide(), groupRideId: 'r3');

      // Er staat meer dan één Semantics-knoop in zo'n rij; het statuswoord
      // is de enige met een niet-leeg label, en er is precies één van.
      String? statusLabelOf(String uid) {
        final labeled = tester
            .widgetList<Semantics>(
              find.descendant(
                of: find.byKey(ValueKey('member-row-$uid')),
                matching: find.byType(Semantics),
              ),
            )
            .map((w) => w.properties.label)
            .where((label) => label != null && label.isNotEmpty)
            .toList();
        expect(labeled, hasLength(1), reason: 'statuslabel in de rij $uid');
        return labeled.first;
      }

      expect(statusLabelOf(_anna), 'gaat mee');
      expect(statusLabelOf(_mark), 'kan niet');
      expect(statusLabelOf(_jacco), 'nog geen antwoord');
      expect(statusLabelOf(_ingrid), 'nog geen antwoord');
    });

    testWidgets('gewone gedeelde rit: geen chip, deelnemers, geen telregel',
        (tester) async {
      await _pumpDetail(tester, _twoOnOneSlot(), groupRideId: 'r1');

      expect(find.byType(ActionChip), findsNothing);
      expect(find.byKey(const ValueKey('group-ride-tally')), findsNothing);
      expect(find.text('Bram'), findsOneWidget);
      expect(find.byIcon(AppIcons.hourglass), findsOneWidget);
      // Zonder groep is er geen telregel, dus draagt de teller zelf de zin.
      // De organisator telt bij een gewone gedeelde rit níét mee, dus 0+1.
      expect(
        find.text('Nog niemand geantwoord · 1 wacht nog'),
        findsOneWidget,
      );
    });

    testWidgets('groep niet (meer) bekend: deelnemerslijst zonder chip',
        (tester) async {
      final fake = FakeGroupGateway(myName: 'Joost');
      fake.rides.add(
        FakeGroupGateway.groupRide(
          'r5',
          ownerId: _me,
          ownerName: 'Joost',
          groupId: 'g-verlaten',
          participants: const [
            RideParticipant(
              userId: _anna,
              status: ParticipantStatus.accepted,
              displayName: 'Anna',
            ),
          ],
        ),
      );
      await _pumpDetail(tester, fake, groupRideId: 'r5');

      expect(find.byType(ActionChip), findsNothing);
      expect(find.byKey(const ValueKey('group-ride-tally')), findsNothing);
      expect(find.text('Anna'), findsOneWidget);
      expect(find.byIcon(AppIcons.check), findsOneWidget);
    });
  });

  group('per venster wie kan (CLUB-15)', () {
    testWidgets('groepsrit met twee vensters: namen per venster',
        (tester) async {
      await _pumpDetail(tester, _withOptions(groupId: 'g1'), groupRideId: 'r6');

      expect(find.text('Anna, Joost (jij)'), findsOneWidget);
      expect(find.text('Nog niemand'), findsOneWidget);
      // Venster 1 staat boven venster 2.
      expect(
        tester.getTopLeft(find.text('Anna, Joost (jij)')).dy,
        lessThan(tester.getTopLeft(find.text('Nog niemand')).dy),
      );
    });

    // Het detail toonde bij Richards rit nog een venster van twee dagen
    // eerder (toestelcontrole 63).
    testWidgets('een venster dat voorbij is, staat er niet bij',
        (tester) async {
      await _pumpDetail(
        tester,
        _withOptions(groupId: 'g1', withPastOption: true),
        groupRideId: 'r6',
      );

      expect(find.text('Anna, Joost (jij)'), findsOneWidget);
      expect(find.text('Nog niemand'), findsOneWidget);
      expect(find.text('Anna, Mark'), findsNothing);
    });

    testWidgets('gewone rit met twee vensters: zelfde blok', (tester) async {
      await _pumpDetail(tester, _withOptions(), groupRideId: 'r6');

      expect(find.text('Anna, Joost (jij)'), findsOneWidget);
      expect(find.text('Nog niemand'), findsOneWidget);
    });
  });

  group('past op 360 dp', () {
    // De testletter geeft elke letter een volle em breedte. Daardoor lopen
    // rijen elders op het detail (de tijdkop, de tijdschuivers, de
    // daglichtbalk) op 360 dp over, wat met een echte letter niet gebeurt en
    // niets met deze kaart te maken heeft. Die fouten laten we door; elke
    // fout binnen de pelotonkaart laat de test falen (les uit 35-03).
    for (final (scale, dark, rideId) in [
      (1.0, true, 'r3'),
      (1.3, false, 'r3'),
      (2.0, false, 'r3'),
      (1.3, false, 'r2'),
      (2.0, false, 'r2'),
    ]) {
      testWidgets(
          'lange namen, rit $rideId, tekstschaal $scale${dark ? ', donker' : ''}',
          (tester) async {
        final fake = _myGroupRide(
          groupName: 'Tour de Waterland Zondagochtend Clubrit',
          longMember: 'Maximiliaan van Oldenbarnevelt',
        );
        // r2: een groepsrit van Anna waarop je nog moet antwoorden, zodat de
        // knoppen "Kan niet" / "Ik ga mee" ook op de kaart staan.
        fake.rides.add(
          FakeGroupGateway.groupRide(
            'r2',
            ownerId: _anna,
            ownerName: 'Anna',
            groupId: 'g1',
            start: _at(3, 9),
          ),
        );
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;
        try {
          await _pumpDetail(
            tester,
            fake,
            groupRideId: rideId,
            width: 360,
            scale: scale,
            dark: dark,
          );
        } finally {
          FlutterError.onError = previous;
        }

        expect(find.byType(ActionChip), findsOneWidget);
        if (rideId == 'r2') expect(find.text('Ik ga mee'), findsOneWidget);
        final card =
            tester.renderObject(find.byKey(const ValueKey('peloton-card')));
        bool insideCard(RenderObject? node) {
          for (var n = node; n != null; n = n.parent) {
            if (identical(n, card)) return true;
          }
          return false;
        }

        RenderObject? overflowing(FlutterErrorDetails d) {
          for (final n in d.informationCollector?.call() ?? <DiagnosticsNode>[]) {
            if (n.value is RenderFlex) return n.value as RenderFlex;
          }
          return null;
        }

        final unexpected = errors
            .where((d) {
              final flex = overflowing(d);
              return flex == null || insideCard(flex);
            })
            .map((d) => d.toString())
            .toList();
        expect(unexpected, isEmpty, reason: unexpected.join('\n\n'));
      });
    }
  });
}

/// Jouw groepsrit in On the Roll: Anna gaat mee, Mark kan niet, Jacco en
/// Ingrid hebben geen rij. Plus een rij van een ex-lid die niet mag tellen.
FakeGroupGateway _myGroupRide({
  String groupName = 'On the Roll',
  String? longMember,
}) {
  final fake = FakeGroupGateway(myName: 'Joost');
  fake.groups['g1'] = FakeGroupGateway.group(
    'g1',
    groupName,
    members: [
      FakeGroupGateway.member(_anna, role: GroupRole.admin, name: 'Anna'),
      FakeGroupGateway.member(_me, name: 'Joost', joinedDay: 1),
      FakeGroupGateway.member(_mark, name: 'Mark', joinedDay: 2),
      FakeGroupGateway.member(_jacco, name: longMember ?? 'Jacco', joinedDay: 3),
      FakeGroupGateway.member(_ingrid, name: 'Ingrid', joinedDay: 4),
    ],
  );
  fake.rides.add(
    FakeGroupGateway.groupRide(
      'r3',
      ownerId: _me,
      ownerName: 'Joost',
      groupId: 'g1',
      participants: const [
        RideParticipant(
          userId: _mark,
          status: ParticipantStatus.declined,
          displayName: 'Mark',
        ),
        RideParticipant(
          userId: _anna,
          status: ParticipantStatus.accepted,
          displayName: 'Anna',
        ),
        RideParticipant(
          userId: 'uid-ex',
          status: ParticipantStatus.accepted,
          displayName: 'Ex-lid',
        ),
      ],
    ),
  );
  return fake;
}

/// Anna's rit met twee vensters; Anna en jij kunnen op venster 1, niemand op
/// venster 2. Met [groupId] een groepsrit, anders een gewone rit.
FakeGroupGateway _withOptions({String? groupId, bool withPastOption = false}) {
  final fake = FakeGroupGateway(myName: 'Joost');
  fake.groups['g1'] = _onTheRoll();
  final o1 = RideOption(
    id: 'o1',
    rideId: 'r6',
    start: _start,
    end: _end,
    plannedScore: 80,
    votes: const [
      OptionVote(optionId: 'o1', userId: _anna, canRide: true),
      OptionVote(optionId: 'o1', userId: _me, canRide: true),
      OptionVote(optionId: 'o1', userId: _mark, canRide: false),
    ],
  );
  final o2 = RideOption(
    id: 'o2',
    rideId: 'r6',
    start: _at(2, 9),
    end: _at(2, 13),
    plannedScore: 70,
    votes: const [
      OptionVote(optionId: 'o2', userId: _mark, canRide: false),
    ],
  );
  fake.rides.add(
    FakeGroupGateway.groupRide(
      'r6',
      ownerId: _anna,
      ownerName: 'Anna',
      groupId: groupId,
      participants: [
        const RideParticipant(
          userId: _me,
          status: ParticipantStatus.accepted,
          displayName: 'Joost',
        ),
        if (groupId == null)
          const RideParticipant(
            userId: _mark,
            status: ParticipantStatus.invited,
            displayName: 'Mark',
          ),
      ],
      options: [
        o1,
        o2,
        if (withPastOption)
          RideOption(
            id: 'o-oud',
            rideId: 'r6',
            start: _at(-2, 18),
            end: _at(-2, 20),
            plannedScore: 94,
            votes: const [
              OptionVote(optionId: 'o-oud', userId: _anna, canRide: true),
              OptionVote(optionId: 'o-oud', userId: _mark, canRide: true),
            ],
          ),
      ],
    ),
  );
  return fake;
}

/// Het statusicoon dat bij elke status hoort (zelfde afspraak als de app).
IconData _statusIcon(ParticipantStatus status) => switch (status) {
      ParticipantStatus.accepted => AppIcons.check,
      ParticipantStatus.declined => AppIcons.prohibit,
      ParticipantStatus.invited => AppIcons.hourglass,
    };

void _expectRow(
  WidgetTester tester,
  String uid,
  String name,
  ParticipantStatus status,
) {
  final row = find.byKey(ValueKey('member-row-$uid'));
  expect(row, findsOneWidget, reason: 'rij voor $uid');
  expect(
    find.descendant(of: row, matching: find.text(name)),
    findsOneWidget,
    reason: 'naam $name',
  );
  expect(
    find.descendant(of: row, matching: find.byIcon(_statusIcon(status))),
    findsOneWidget,
    reason: '$name: statusicoon',
  );
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

Widget _scope(FakeGroupGateway fake, Widget child) => ProviderScope(
      overrides: [
        pelotonGatewayProvider.overrideWithValue(fake),
        currentUserIdProvider.overrideWithValue(_me),
        locationProvider.overrideWith(_FakeLocation.new),
        profileProvider.overrideWith(_FakeProfile.new),
        weatherProvider.overrideWith(_FakeWeather.new),
        allHourlyScoresProvider.overrideWithValue(const []),
        plannedRidesProvider.overrideWith(_FakePlannedRides.new),
      ],
      retry: (_, __) => null,
      child: child,
    );

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
    _scope(
      fake,
      MaterialApp.router(
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
    _scope(
      fake,
      MaterialApp.router(
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
