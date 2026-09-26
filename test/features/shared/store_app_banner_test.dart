// test/features/shared/store_app_banner_test.dart
//
// De store-balk op de website: alleen voor Android-bezoekers, "Doe mee" opent
// de drie teststappen, en wegklikken sluimert met eigen sleutels (los van de
// iOS-installatiebalk).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/core/app_version.dart';
import 'package:ridewindow/core/platform_info.dart';
import 'package:ridewindow/core/pwa_display_mode.dart';
import 'package:ridewindow/data/repositories/install_hint_store.dart';
import 'package:ridewindow/features/shared/store_app_banner.dart';
import 'package:ridewindow/features/shared/top_banners.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/app_update_provider.dart';
import 'package:ridewindow/services/app_update_service.dart';

const _bannerText = 'Ridewindow is er ook als Android-app';

class _FakeUpdates implements AppUpdateService {
  _FakeUpdates(this.build);

  final int? build;

  @override
  Future<int?> availableBuild() async => build;

  @override
  Future<void> apply() async {}
}

Future<void> _pump(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  Widget child = const Column(children: [StoreAppBanner()]),
  int? updateBuild,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appUpdateServiceProvider.overrideWithValue(_FakeUpdates(updateBuild)),
      ],
      child: MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    debugIsWebOverride = null;
    debugIsAndroidWebOverride = null;
    debugIsIosBrowserOverride = null;
    debugIsStandaloneOverride = null;
  });

  testWidgets('in de native app: geen balk', (tester) async {
    debugIsWebOverride = false;
    debugIsAndroidWebOverride = true;
    await _pump(tester);
    expect(find.text(_bannerText), findsNothing);
  });

  testWidgets('op web maar niet op Android: geen balk', (tester) async {
    debugIsWebOverride = true;
    debugIsAndroidWebOverride = false;
    await _pump(tester);
    expect(find.text(_bannerText), findsNothing);
  });

  testWidgets('op Android-web: balk, en Doe mee toont de drie stappen',
      (tester) async {
    debugIsWebOverride = true;
    debugIsAndroidWebOverride = true;
    await _pump(tester);
    expect(find.text(_bannerText), findsOneWidget);

    await tester.tap(find.text('Doe mee'));
    await tester.pumpAndSettle();
    expect(find.text('Test de Android-app'), findsOneWidget);
    expect(find.text('Word lid van de testgroep'), findsOneWidget);
    expect(find.text('Meld je aan als tester'), findsOneWidget);
    expect(find.text('Installeer Ridewindow via Play'), findsOneWidget);
    expect(find.text('Openen'), findsNWidgets(3));
  });

  testWidgets('wegklikken onthoudt het met eigen sleutels', (tester) async {
    debugIsWebOverride = true;
    debugIsAndroidWebOverride = true;
    await _pump(tester);
    await tester.tap(find.byTooltip('Sluiten'));
    await tester.pumpAndSettle();
    expect(find.text(_bannerText), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(InstallHintStore.storeApp(prefs).dismissCount, 1);
    expect(InstallHintStore(prefs).dismissCount, 0);
  });

  testWidgets('na drie keer wegklikken komt hij niet meer', (tester) async {
    debugIsWebOverride = true;
    debugIsAndroidWebOverride = true;
    await _pump(
      tester,
      prefs: {InstallHintStore.kStoreDismissCountKey: 3},
    );
    expect(find.text(_bannerText), findsNothing);
  });

  testWidgets('met een update erbij staan beide balken onder elkaar',
      (tester) async {
    debugIsWebOverride = true;
    debugIsAndroidWebOverride = true;
    await _pump(
      tester,
      child: const Stack(children: [TopBanners()]),
      updateBuild: int.parse(kAppBuildNumber) + 1,
    );
    final update = find.text('Er staat een nieuwe versie klaar');
    final store = find.text(_bannerText);
    expect(update, findsOneWidget);
    expect(store, findsOneWidget);
    expect(
      tester.getRect(update).bottom <= tester.getTopLeft(store).dy,
      isTrue,
    );
  });
}
