// Tests voor de feedbackdialoog (backlog #33, omgebouwd in fase 22).
//
// Dekt:
//   Test 1/2/3: de pure payload-opbouw (FB-02, FB-03) -- score, weerinvoer en
//                tolerances gaan mee, en een uitgelogde gebruiker levert een
//                rij met `user_id: null` op in plaats van een fout.
//   Test 4:      de dialoog toont titel en vijf sterren.
//   Test 5:      Verzenden blijft uit tot er een ster gekozen is.
//
// De verzendknop wordt in deze suite nooit ingedrukt: dat zou een Drift-database
// en een Supabase-client vergen. Wat er ná die tik gebeurt is gedekt door de
// pure functies hierboven en door de outbox-tests van fase 21.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/models/user_profile.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/domain/services/feedback_payload.dart';
import 'package:ridewindow/features/profile/feedback_dialog.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_theme.dart';

const _profile = UserProfile(
  tolerances: WeatherTolerances(
    tempMinIdealC: 12,
    tempMaxIdealC: 26,
    windMaxIdealKmh: 15,
    rainMaxIdealMm: 0.5,
  ),
  allowedDurations: [2, 3],
  theme: 'system',
  locale: 'nl',
  notifEveningBefore: false,
  notifMorningOf: false,
  notifWeeklyDigest: false,
);

Future<void> _pumpDialogTrigger(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        // RideWindowTheme-extensie is nodig: de sterrenrij leest
        // context.rw.scorePerfect voor de kleur van een gekozen ster.
        theme: ThemeData(extensions: const [RideWindowTheme.light]),
        locale: const Locale('en'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showFeedbackDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  test('Test 1 — context draagt score, weerinvoer én de eigen tolerances',
      () {
    // FB-02. Deze drie samen maken een melding bruikbaar: zonder de tolerances
    // is niet te beoordelen of een score van 70 terecht was voor déze fietser.
    final slot = RideSlot(
      start: DateTime.utc(2026, 9, 12, 9),
      end: DateTime.utc(2026, 9, 12, 11),
      overallScore: 91,
      tier: const Perfect(),
      hours: const [],
    );
    final context = buildFeedbackContext(
      profile: _profile,
      topSlot: slot,
      slotForecasts: [
        HourlyForecast(
          time: DateTime.utc(2026, 9, 12, 9),
          temperatureC: 18,
          apparentTemperatureC: 17,
          precipitationMm: 0,
          precipitationProbability: 5,
          windspeedKmh: 12,
          winddirectionDeg: 270,
        ),
      ],
      city: 'Amsterdam',
      appVersion: '1.0.23 (24)',
      platform: 'android',
    );

    expect(context['city'], 'Amsterdam');
    expect(context['app_version'], '1.0.23 (24)');
    expect((context['tolerances'] as Map)['temp_min_ideal_c'], 12.0);
    expect((context['tolerances'] as Map)['rain_max_ideal_mm'], 0.5);

    final top = context['top_slot'] as Map<String, dynamic>;
    expect(top['score'], 91.0);
    final weather = top['weather'] as List;
    expect(weather, hasLength(1));
    expect((weather.single as Map)['temp_c'], 18.0);
    expect((weather.single as Map)['wind_kmh'], 12.0);
  });

  test('Test 2 — zonder ritvenster blijft top_slot null in plaats van te gooien',
      () {
    // Feedback bij een lege lijst gaat waarschijnlijk juist over die lege
    // lijst, dus dit pad moet werken en niet stilvallen.
    final context = buildFeedbackContext(
      profile: _profile,
      appVersion: '1.0.23 (24)',
      platform: 'web',
    );

    expect(context['top_slot'], isNull);
    expect(context['tolerances'], isNotNull);
  });

  test('Test 3 — een uitgelogde gebruiker levert user_id null op (FB-03)', () {
    final row = buildFeedbackRow(
      id: 'ffffffff-ffff-4fff-bfff-ffffffffffff',
      userId: null,
      rating: 3,
      comment: '   ',
      context: const {},
    );

    expect(row['user_id'], isNull);
    expect(row['rating'], 3);
    // Een lege reactie wordt null en niet de lege string: dan is in de database
    // te zien dat er niets is ingevuld, in plaats van dat het leeg lijkt.
    expect(row['comment'], isNull);
  });

  testWidgets('Test 4 — dialoog toont titel en vijf sterren', (tester) async {
    await _pumpDialogTrigger(tester);

    final context = tester.element(find.text('open'));
    final s = S.of(context);

    expect(find.text(s.sendFeedback), findsOneWidget);
    for (var n = 1; n <= 5; n++) {
      expect(find.byKey(ValueKey('feedback_star_$n')), findsOneWidget);
    }
  });

  testWidgets('Test 5 — Verzenden blijft uit tot er een ster gekozen is',
      (tester) async {
    await _pumpDialogTrigger(tester);

    final context = tester.element(find.text('open'));
    final s = S.of(context);

    TextButton sendButton() => tester.widget<TextButton>(
          find.widgetWithText(TextButton, s.feedbackSendButton),
        );

    expect(sendButton().onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('feedback_star_3')));
    await tester.pump();

    expect(sendButton().onPressed, isNotNull);
  });
}
