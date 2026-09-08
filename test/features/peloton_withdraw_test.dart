// test/features/peloton_withdraw_test.dart
//
// Afzeggen ná "ik ga mee" (Joost, 2026-09-08). De gateway kon het al -- de
// knop ontbrak, en daarmee zat je aan een geaccepteerde rit vast.
//
// Wat hier bewaakt wordt is niet alleen dát de knop er is, maar dat hij de
// juiste kant op stuurt: `accepted: false` bij afzeggen en `accepted: true`
// bij ongedaan maken. Die twee verwisselen levert een knop op die precies het
// tegenovergestelde doet van wat er op staat, en dat is niet aan de UI te zien.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/features/peloton/peloton_tab.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/peloton_providers.dart';
import 'package:ridewindow/services/peloton_gateway.dart';

const _me = 'uid-me';
const _owner = 'uid-owner';

/// Legt vast wat er naar `respondToRide` ging, en past de status meteen aan
/// zodat een volgende uitlezing de nieuwe werkelijkheid ziet -- net als de
/// echte poort plus een `invalidate`.
class _RecordingGateway implements PelotonGateway {
  _RecordingGateway(this._rides);

  List<GroupRide> _rides;
  final calls = <({String rideId, bool accepted})>[];

  @override
  Future<List<GroupRide>> listGroupRides() async => _rides;

  @override
  Future<List<Friend>> listFriends() async => const [];

  @override
  Future<void> respondToRide({
    required String rideId,
    required bool accepted,
  }) async {
    calls.add((rideId: rideId, accepted: accepted));
    _rides = [
      for (final ride in _rides)
        if (ride.id != rideId)
          ride
        else
          GroupRide(
            id: ride.id,
            ownerId: ride.ownerId,
            start: ride.start,
            end: ride.end,
            plannedScore: ride.plannedScore,
            ownerName: ride.ownerName,
            participants: [
              RideParticipant(
                userId: _me,
                status: accepted
                    ? ParticipantStatus.accepted
                    : ParticipantStatus.declined,
              ),
            ],
          ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} niet nodig');
}

GroupRide _acceptedRide() => GroupRide(
      id: 'ride-1',
      ownerId: _owner,
      start: DateTime(2026, 9, 12, 9),
      end: DateTime(2026, 9, 12, 13),
      plannedScore: 91,
      ownerName: 'Maatje',
      participants: const [
        RideParticipant(userId: _me, status: ParticipantStatus.accepted),
      ],
    );

Future<_RecordingGateway> _pumpTab(WidgetTester tester) async {
  final gateway = _RecordingGateway([_acceptedRide()]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pelotonGatewayProvider.overrideWithValue(gateway),
        currentUserIdProvider.overrideWithValue(_me),
      ],
      child: MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const Scaffold(body: PelotonTab()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return gateway;
}

void main() {
  testWidgets('een geaccepteerde rit draagt een afzegknop', (tester) async {
    await _pumpTab(tester);
    expect(find.text('Toch niet'), findsOneWidget);
  });

  testWidgets('afzeggen stuurt accepted: false en haalt de rit uit de lijst',
      (tester) async {
    final gateway = await _pumpTab(tester);

    await tester.tap(find.text('Toch niet'));
    await tester.pumpAndSettle();

    expect(gateway.calls, [(rideId: 'ride-1', accepted: false)]);
    // De rit is nu `declined` en valt daarmee uit alle drie de lijsten.
    expect(find.text('Toch niet'), findsNothing);
  });

  testWidgets('de snackbar biedt ongedaan maken, en dat zet hem terug',
      (tester) async {
    final gateway = await _pumpTab(tester);

    await tester.tap(find.text('Toch niet'));
    await tester.pumpAndSettle();
    expect(find.text('Je doet niet meer mee aan deze rit'), findsOneWidget);

    await tester.tap(find.text('Ongedaan maken'));
    await tester.pumpAndSettle();

    expect(gateway.calls.last, (rideId: 'ride-1', accepted: true));
    // En de rit staat weer in "ritten waar je aan meedoet".
    expect(find.text('Toch niet'), findsOneWidget);
  });
}
