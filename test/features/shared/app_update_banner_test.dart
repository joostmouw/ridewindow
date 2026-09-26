// test/features/shared/app_update_banner_test.dart
//
// De update-melding bovenaan: hij verschijnt alleen als er echt iets nieuwers
// klaarstaat, wegklikken geldt voor die ene build, en een fout in de bron
// levert geen balk op (een sideload kan Play niet bijwerken).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/core/app_version.dart';
import 'package:ridewindow/core/platform_info.dart';
import 'package:ridewindow/data/repositories/update_banner_store.dart';
import 'package:ridewindow/features/shared/app_update_banner.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/app_update_provider.dart';
import 'package:ridewindow/services/app_update_service.dart';

final _here = int.parse(kAppBuildNumber);

class _FakeUpdates implements AppUpdateService {
  _FakeUpdates(this.build);

  final int? build;
  int applied = 0;

  @override
  Future<int?> availableBuild() async => build;

  @override
  Future<void> apply() async => applied++;
}

Future<void> _pump(
  WidgetTester tester,
  AppUpdateService service, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appUpdateServiceProvider.overrideWithValue(service)],
      child: const MaterialApp(
        locale: Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: Column(children: [AppUpdateBanner()])),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => debugIsWebOverride = null);

  group('balk', () {
    testWidgets('niets nieuwers: geen balk', (tester) async {
      await _pump(tester, _FakeUpdates(null));
      expect(find.text('Er staat een nieuwe versie klaar'), findsNothing);
    });

    testWidgets('een nieuwere build: balk met Bijwerken op Android',
        (tester) async {
      debugIsWebOverride = false;
      final service = _FakeUpdates(_here + 1);
      await _pump(tester, service);
      expect(find.text('Er staat een nieuwe versie klaar'), findsOneWidget);
      await tester.tap(find.text('Bijwerken'));
      await tester.pumpAndSettle();
      expect(service.applied, 1);
    });

    testWidgets('op web heet de knop Vernieuwen', (tester) async {
      debugIsWebOverride = true;
      await _pump(tester, _FakeUpdates(_here + 1));
      expect(find.text('Vernieuwen'), findsOneWidget);
    });

    testWidgets('wegklikken geldt voor deze build en wordt onthouden',
        (tester) async {
      await _pump(tester, _FakeUpdates(_here + 1));
      await tester.tap(find.byTooltip('Sluiten'));
      await tester.pumpAndSettle();
      expect(find.text('Er staat een nieuwe versie klaar'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(UpdateBannerStore(prefs).dismissedBuild, _here + 1);
    });

    testWidgets('weggeklikt voor deze build: geen balk', (tester) async {
      await _pump(
        tester,
        _FakeUpdates(_here + 1),
        prefs: {UpdateBannerStore.kDismissedBuildKey: _here + 1},
      );
      expect(find.text('Er staat een nieuwe versie klaar'), findsNothing);
    });

    testWidgets('een nog nieuwere build komt wel terug', (tester) async {
      await _pump(
        tester,
        _FakeUpdates(_here + 2),
        prefs: {UpdateBannerStore.kDismissedBuildKey: _here + 1},
      );
      expect(find.text('Er staat een nieuwe versie klaar'), findsOneWidget);
    });
  });

  group('isNewerBuild', () {
    test('alleen strikt hoger telt', () {
      expect(isNewerBuild(61, current: '60'), isTrue);
      expect(isNewerBuild(60, current: '60'), isFalse);
      expect(isNewerBuild(59, current: '60'), isFalse);
      expect(isNewerBuild(null, current: '60'), isFalse);
    });
  });

  group('WebAppUpdateService', () {
    final base = Uri.parse('https://my-project-joost.web.app/');

    WebAppUpdateService service(http.Client client) =>
        WebAppUpdateService(client: client, base: base);

    test('leest build_number uit version.json naast de bundel', () async {
      late Uri asked;
      final client = MockClient((request) async {
        asked = request.url;
        return http.Response(
          jsonEncode({'version': '9.9.9', 'build_number': '${_here + 1}'}),
          200,
        );
      });
      expect(await service(client).availableBuild(), _here + 1);
      expect(asked.path, '/version.json');
      expect(asked.queryParameters.containsKey('t'), isTrue);
    });

    test('dezelfde build: niets te melden', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({'build_number': kAppBuildNumber}),
          200,
        ),
      );
      expect(await service(client).availableBuild(), isNull);
    });

    test('een fout of rommel levert niets op en gooit niet', () async {
      expect(
        await service(MockClient((_) async => http.Response('', 500)))
            .availableBuild(),
        isNull,
      );
      expect(
        await service(MockClient((_) async => http.Response('<html>', 200)))
            .availableBuild(),
        isNull,
      );
      expect(
        await service(MockClient((_) async => throw Exception('offline')))
            .availableBuild(),
        isNull,
      );
    });
  });

  test('showUpdateBanner', () {
    expect(showUpdateBanner(available: null, dismissed: null), isFalse);
    expect(showUpdateBanner(available: 61, dismissed: null), isTrue);
    expect(showUpdateBanner(available: 61, dismissed: 61), isFalse);
    expect(showUpdateBanner(available: 62, dismissed: 61), isTrue);
  });
}
