import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridewindow/data/repositories/ride_score_alert_store.dart';
import 'package:ridewindow/features/profile/ride_score_alert_settings.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/platform/notification_service.dart';

class _Notifications extends NotificationService {
  bool permitted = true;
  int requests = 0;
  @override
  Future<void> init({required S strings}) async {}
  @override
  Future<bool> requestPostNotificationsPermission() async {
    requests++;
    return permitted;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<_Notifications> pump(
    WidgetTester tester, {
    bool permitted = true,
  }) async {
    final notifications = _Notifications()..permitted = permitted;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('nl'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: RideScoreAlertSettings(notifications: notifications),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return notifications;
  }

  testWidgets('opt-in vraagt toestemming en start met 10 procentpunt',
      (tester) async {
    final notifications = await pump(tester);
    expect(notifications.requests, 0);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(notifications.requests, 1);
    expect(find.text('10 procentpunt'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getInt(kScoreDropThresholdKey),
      10,
    );
  });

  testWidgets('weigering laat de schakelaar uit en vertelt hoe verder',
      (tester) async {
    await pump(tester, permitted: false);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      false,
    );
    expect(
      find.text('Meldingen staan uit in de systeeminstellingen.'),
      findsOneWidget,
    );
    expect(
      (await SharedPreferences.getInstance()).getInt(kScoreDropThresholdKey),
      isNull,
    );
  });

  testWidgets('drempel naar 5 en uitzetten worden opgeslagen', (tester) async {
    final notifications = await pump(tester);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 procentpunt').last);
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getInt(kScoreDropThresholdKey),
      5,
    );
    final requests = notifications.requests;
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getInt(kScoreDropThresholdKey),
      0,
    );
    expect(notifications.requests, requests);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
  });
}
