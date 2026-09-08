// Tests voor de feedbackdialoog (backlog #33, omgebouwd in fase 22).
//
// Dekt:
//   Test 1/2/3: de pure payload-opbouw (FB-02, FB-03) -- score, weerinvoer en
//                tolerances gaan mee, en een uitgelogde gebruiker levert een
//                rij met `user_id: null` op in plaats van een fout.
//   Test 4:      de dialoog toont titel en vijf sterren.
//   Test 5:      Verzenden blijft uit tot er een ster gekozen is.
//   Test 6:      de gekozen ster en alles ervoor worden gevuld.
//   Test 7:      verzenden zet niet alleen een rij in de outbox maar start ook
//                meteen een drain.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/providers/app_database_provider.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/cloud_sync_reconciler_provider.dart';
import 'package:ridewindow/services/sync_outbox_service.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';
import 'package:ridewindow/domain/models/user_profile.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/domain/services/feedback_payload.dart';
import 'package:ridewindow/features/profile/feedback_dialog.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/theme/app_icons.dart';
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

/// Legt vast of [drain] werkelijk is aangeroepen, zonder echt werk te doen.
/// Zelfde vorm als `_RecordingSyncOutboxService` in
/// `test/providers/outbox_drain_wiring_test.dart`; de superconstructor wil een
/// echte dao maar raakt hem nooit aan.
class _RecordingSyncOutboxService extends SyncOutboxService {
  _RecordingSyncOutboxService(super.dao);

  var drainCalled = false;

  @override
  Future<void> drain({
    required Future<void> Function(
      String entity,
      String entityKey,
      Map<String, dynamic> payload,
    ) upsertFn,
    required Future<void> Function(String entity, String entityKey) deleteFn,
  }) async {
    drainCalled = true;
  }
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

  testWidgets(
      'Test 6 — de gekozen ster en alles ervoor worden gevuld, de rest niet',
      (tester) async {
    // Regressie. Hier stond `selected ? AppIcons.star : AppIcons.star`: bij de
    // Phosphor-migratie zijn Icons.star en Icons.star_border allebei op
    // hetzelfde icoon uitgekomen, waardoor een aangeklikte ster alleen nog van
    // kleur veranderde. Joost las dat niet als "aan" (2026-09-08).
    //
    // De twee families delen hun codepunten, dus alleen `fontFamily`
    // onderscheidt gevuld van omlijnd -- een verschil dat geen enkele
    // screenshot-vergelijking op kleur zou opmerken.
    await _pumpDialogTrigger(tester);

    IconData glyphOf(int n) => tester
        .widget<Icon>(
          find.descendant(
            of: find.byKey(ValueKey('feedback_star_$n')),
            matching: find.byType(Icon),
          ),
        )
        .icon!;

    for (var n = 1; n <= 5; n++) {
      expect(glyphOf(n), AppIcons.star, reason: 'ster $n staat nog uit');
    }

    await tester.tap(find.byKey(const ValueKey('feedback_star_3')));
    await tester.pump();

    for (var n = 1; n <= 3; n++) {
      expect(glyphOf(n), AppIconsFill.star, reason: 'ster $n hoort gevuld');
    }
    for (var n = 4; n <= 5; n++) {
      expect(glyphOf(n), AppIcons.star, reason: 'ster $n hoort leeg');
    }
  });

  testWidgets(
      'Test 7 — verzenden zet een rij in de outbox én start meteen een drain',
      (tester) async {
    // De bug. `_submit` schreef alleen naar de outbox en toonde "bedankt";
    // de rij vertrok pas als de app toevallig een voorgrondovergang maakte.
    // De app zei dus dat het gelukt was terwijl er in Supabase niets stond
    // (Joost, 2026-09-08).
    //
    // De outbox blijft de vangnetlaag -- mislukt de drain, dan blijft de rij
    // staan voor de volgende. Wat hier bewaakt wordt is dat de poging
    // überhaupt gedaan wordt.
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final outbox = _RecordingSyncOutboxService(db.syncOutboxDao);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          syncOutboxServiceProvider.overrideWith((ref) => outbox),
          currentUserIdProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
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

    final s = S.of(tester.element(find.text('open')));
    await tester.tap(find.byKey(const ValueKey('feedback_star_4')));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, s.feedbackSendButton));
    await tester.pumpAndSettle();

    expect((await db.syncOutboxDao.pendingRows()).length, 1,
        reason: 'de rij hoort in de outbox te staan');
    expect(outbox.drainCalled, isTrue,
        reason: 'verzenden moet meteen een drain starten');
  });
}
