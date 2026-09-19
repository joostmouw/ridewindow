// test/features/shared/daylight_bar_test.dart
//
// De vierde balk hoort dezelfde taal te spreken als de andere drie.
//
// Joost zei dat twee keer. De eerste keer repareerde ik het label ónder de
// balk (`d072e45`) terwijl hij de **info** bedoelde: temperatuur, regen en
// wind openen een bottom sheet met een koprij, de algemene uitleg, en daaronder
// een blok over waarom déze meting híér deze score kreeg -- daglicht opende een
// `AlertDialog` met één alinea. En het gewicht ("half mee") stond op de balk,
// terwijl dat in de uitleg hoort.
//
// Deze test legt allebei vast, zodat het niet een derde keer gezegd hoeft te
// worden.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/features/shared/daylight_bar.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_theme.dart';

/// Amsterdam, een zomerdag: ruim licht, zodat de zonstand bestaat en de balk
/// niet in zijn poolnacht-tak valt.
const _lat = 52.37;
const _lon = 4.90;

Future<void> _pump(
  WidgetTester tester, {
  required DateTime start,
  required DateTime end,
  double darknessWeight = 0.5,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('nl'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      theme: ThemeData(extensions: const [RideWindowTheme.light]),
      home: Scaffold(
        body: DaylightBar(
          start: start,
          end: end,
          latitude: _lat,
          longitude: _lon,
          darknessWeight: darknessWeight,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final middayRide = (
    start: DateTime(2026, 6, 20, 10),
    end: DateTime(2026, 6, 20, 12),
  );

  testWidgets('het gewicht staat niet op de balk maar in de uitleg',
      (tester) async {
    // Een rit die deels in het donker valt: bij een rit volledig in het licht
    // noemt de uitleg terecht de rit als reden en niet de stand, en dan zou
    // deze test het verkeerde meten.
    await _pump(
      tester,
      start: DateTime(2026, 12, 20, 15),
      end: DateTime(2026, 12, 20, 18),
    );

    // "half mee" is de standaardstand. Op de balk hoort hij niet te staan.
    expect(find.textContaining('half'), findsNothing);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('half'), findsOneWidget);
  });

  testWidgets('de info is een sheet met een tweede blok, net als de andere drie',
      (tester) async {
    await _pump(tester, start: middayRide.start, end: middayRide.end);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    // Geen AlertDialog meer: dezelfde bottom sheet als bij temperatuur, regen
    // en wind.
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);

    // Kop, algemene uitleg, en het tweede blok.
    expect(find.text('Daglicht'), findsWidgets);
    expect(find.text('Wat daglicht met dit venster doet'), findsOneWidget);
    expect(find.textContaining('120 minuten'), findsOneWidget);
  });

  testWidgets('een rit volledig in het licht noemt dát de reden, niet de stand',
      (tester) async {
    // Dit ging mis op het toestel (2026-09-19): de uitleg zei "jouw
    // gevoeligheid staat op *donker telt een beetje*, dus daglicht verandert
    // de score niet" -- bij een rit die gewoon helemaal in het licht viel.
    // Nul aftrek heeft twee oorzaken en de zin moet zeggen wélke.
    await _pump(
      tester,
      start: middayRide.start,
      end: middayRide.end,
      darknessWeight: 0.25,
    );

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    // "Deze rit valt helemaal" en niet "helemaal in het licht": die kortere
    // zinsnede staat ook in de schaalzin eronder ("Een venster dat helemaal in
    // het licht valt verliest niets"), en dan meet de test twee dingen tegelijk.
    expect(find.textContaining('Deze rit valt helemaal'), findsOneWidget);
    expect(find.textContaining('gevoeligheid staat op'), findsNothing);
  });

  testWidgets('bij gevoeligheid nul zegt de uitleg dat, en geen "0 punten"',
      (tester) async {
    await _pump(
      tester,
      // Een rit die deels in het donker valt, zodat er zonder de stand wél
      // aftrek zou zijn.
      start: DateTime(2026, 12, 20, 15),
      end: DateTime(2026, 12, 20, 18),
      darknessWeight: 0,
    );

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('0 punten'), findsNothing);
    expect(find.textContaining('verandert de score'), findsOneWidget);
  });
}
