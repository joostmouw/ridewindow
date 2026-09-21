// test/features/shared/peloton_counter_test.dart
//
// De teller uit schets 014: een fietsje per persoon, de wachtenden
// doorzichtig, met de zin ernaast. Drie dingen die je op een screenshot van
// één rit niet ziet en die stilletjes fout kunnen gaan:
//
// 1. De fietsjes moeten de zin exact volgen -- "2 gaan mee · 1 wacht nog" is
//    twee volle en één doorzichtige, niet drie volle.
// 2. Bij een grote groep mag de rij niet doorlopen tot de zin eruit valt.
// 3. De teller hoort onder elke gedeelde rit, maar niet onder een afgezegde.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/peloton.dart';
import 'package:ridewindow/domain/models/ride_entry.dart';
import 'package:ridewindow/features/shared/peloton_counter.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';
import 'package:ridewindow/theme/app_theme.dart';

RideEntry _entry({
  required RideRole role,
  int accepted = 0,
  int invited = 0,
}) {
  final start = DateTime(2026, 9, 27, 9);
  return RideEntry(
    start: start,
    end: start.add(const Duration(hours: 4)),
    plannedScore: 82,
    role: role,
    group: role == RideRole.solo
        ? null
        : GroupRide(
            id: 'g',
            ownerId: 'uid-owner',
            start: start,
            end: start.add(const Duration(hours: 4)),
            plannedScore: 82,
            ownerName: 'Bram',
            participants: [
              for (var i = 0; i < accepted; i++)
                RideParticipant(
                  userId: 'a$i',
                  status: ParticipantStatus.accepted,
                ),
              for (var i = 0; i < invited; i++)
                RideParticipant(
                  userId: 'i$i',
                  status: ParticipantStatus.invited,
                ),
            ],
          ),
  );
}

Future<void> _pump(WidgetTester tester, RideEntry entry) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('nl'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      theme: ThemeData(extensions: const [RideWindowTheme.light]),
      home: Scaffold(body: PelotonCounter(entry: entry)),
    ),
  );
  await tester.pumpAndSettle();
}

List<Icon> _bikes(WidgetTester tester) => tester
    .widgetList<Icon>(find.byIcon(AppIcons.personSimpleBike))
    .toList(growable: false);

void main() {
  testWidgets('de fietsjes volgen de zin: volle en doorzichtige',
      (tester) async {
    await _pump(
      tester,
      _entry(role: RideRole.organiser, accepted: 2, invited: 1),
    );

    expect(find.text('2 gaan mee · 1 wacht nog'), findsOneWidget);

    final bikes = _bikes(tester);
    expect(bikes.length, 3);
    // De laatste is de wachter: zelfde kleur, lagere dekking.
    expect(bikes.take(2).every((b) => b.color!.a == 1.0), isTrue);
    expect(bikes.last.color!.a, lessThan(1.0));
  });

  testWidgets('een grote groep wordt een getal in plaats van een lange rij',
      (tester) async {
    await _pump(
      tester,
      _entry(role: RideRole.organiser, accepted: 6, invited: 2),
    );

    expect(_bikes(tester).length, 5, reason: 'meer dan vijf wordt een getal');
    expect(find.text('+3'), findsOneWidget);
  });

  testWidgets('ook onder andermans rit, maar niet onder een afgezegde',
      (tester) async {
    await _pump(tester, _entry(role: RideRole.joined, accepted: 3));
    expect(find.text('3 gaan mee'), findsOneWidget,
        reason: 'tot schets 014 stond deze zin alleen onder je eigen rit');

    await _pump(tester, _entry(role: RideRole.declined, accepted: 3));
    expect(find.text('3 gaan mee'), findsNothing);
    expect(_bikes(tester), isEmpty);
  });

  testWidgets('een rit van jou alleen heeft geen teller', (tester) async {
    await _pump(tester, _entry(role: RideRole.solo));
    expect(_bikes(tester), isEmpty);
    expect(find.byType(Text), findsNothing);
  });
}
