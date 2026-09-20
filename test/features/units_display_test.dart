// De eenheidskeuze uit Profiel moet ook werkelijk op de schermen landen.
//
// Joost, 2026-09-20: "voor wind moet je ook op windkracht kunnen kiezen of voor
// km u. Temperatuur ook voor Fahrenheit."
//
// Wat hier vastligt is het onderscheid dat de hele opzet draagt: de motor blijft
// in Celsius en km/u rekenen, en er wordt pas omgerekend op het moment dat een
// getal tekst wordt. Zou dat dieper zitten, dan kan een ingestelde grens in een
// andere eenheid belanden dan de meting ernaast -- en dat merk je pas als
// iemand zich afvraagt waarom een score niet klopt.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/units.dart';
import 'package:ridewindow/domain/models/weather_verdict.dart';
import 'package:ridewindow/features/shared/weather_indicator_bar.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';
import 'package:ridewindow/theme/app_theme.dart';

Future<void> _pumpBar(
  WidgetTester tester, {
  required WeatherMetric metric,
  required double value,
  required String unit,
  double Function(double)? convert,
  double? idealMin,
  required double idealMax,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: ThemeData(extensions: const [RideWindowTheme.light]),
        home: Scaffold(
          body: WeatherIndicatorBar(
            metric: metric,
            icon: AppIcons.thermometerSimple,
            label: 'Test',
            value: value,
            unit: unit,
            convert: convert,
            idealMin: idealMin,
            idealMax: idealMax,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('zonder omrekening blijft de balk in Celsius', (tester) async {
    await _pumpBar(
      tester,
      metric: WeatherMetric.temperature,
      value: 20,
      unit: '°',
      idealMin: 12,
      idealMax: 26,
    );

    expect(find.textContaining('20'), findsWidgets);
    expect(find.textContaining('12–26'), findsOneWidget);
  });

  testWidgets('met Fahrenheit verandert de waarde én jouw bereik',
      (tester) async {
    await _pumpBar(
      tester,
      metric: WeatherMetric.temperature,
      value: 20,
      unit: '°F',
      convert: (v) => convertTemp(v, TempUnit.fahrenheit),
      idealMin: 12,
      idealMax: 26,
    );

    // 20 °C is 68 °F, en het bereik 12-26 wordt 54-79.
    expect(find.textContaining('68'), findsWidgets);
    expect(
      find.textContaining('54–79'),
      findsOneWidget,
      reason: 'staat je bereik nog in Celsius naast een waarde in Fahrenheit, '
          'dan vergelijkt de gebruiker twee verschillende schalen',
    );
  });

  testWidgets('wind in Beaufort toont een heel getal, geen tiende',
      (tester) async {
    await _pumpBar(
      tester,
      metric: WeatherMetric.wind,
      value: 25,
      unit: ' Bft',
      convert: (v) => convertWind(v, WindUnit.beaufort),
      idealMax: 15,
    );

    // 25 km/u is windkracht 4; de grens van 15 km/u is windkracht 3.
    expect(find.textContaining('4'), findsWidgets);
    expect(find.textContaining('≤3'), findsOneWidget);
    expect(find.textContaining(','), findsNothing);
  });
}
