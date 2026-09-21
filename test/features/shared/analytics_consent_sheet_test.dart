// De toestemmingskaart moet dichtgaan als je hem beantwoordt.
//
// Waarom deze test bestaat
// ------------------------
// Tester Androidguju67 meldde op 1.0.35+46 dat "No thanks" en "Yes, go ahead"
// allebei zichtbaar niets deden: de kaart bleef staan. Na de app killen en
// opnieuw openen was de vraag wel weg, dus de keuze werd wel degelijk
// opgeslagen. Alleen het sluiten gebeurde niet.
//
// De oorzaak zat niet in de knoppen maar erachter. `analyticsConsentProvider`
// is auto-dispose en wordt op deze route alleen met `ref.read` benaderd, dus
// hij heeft geen luisteraar en wordt na elke read weggegooid. `setConsent`
// eindigt op `ref.invalidateSelf()`, en dat gooit op een weggegooide Ref een
// `UnmountedRefException`. Die ontsnapte door de `await` heen uit `setConsent`,
// waardoor de `Navigator.pop()` op de regel erna nooit werd uitgevoerd. De
// schrijfactie stond ervoor, dus die was al geslaagd -- exact het beeld dat de
// tester beschreef.
//
// Dat dit drie weken onopgemerkt bleef, komt doordat Profiel dezelfde
// `setConsent` aanroept vanuit een `ref.watch`. Daar houdt de watch de provider
// in leven en werkt alles. De enige route die de eigenaar zelf gebruikte, was
// de route die niet stuk was.
//
// Wat de test doet
// ----------------
// Test 1 en 2 dwingen af dat de kaart na beide knoppen daadwerkelijk weg is en
// dat het antwoord in prefs staat. Ze falen op de oude code op allebei die
// punten tegelijk (kaart blijft, plus een UnmountedRefException).
// Test 3 bewaakt de tweede laag: sluiten hangt niet af van het slagen van wat
// er ná de schrijfactie gebeurt.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/database/app_database.dart';
import 'package:ridewindow/data/repositories/analytics_consent_store.dart';
import 'package:ridewindow/features/shared/analytics_consent_sheet.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/analytics_provider.dart';
import 'package:ridewindow/providers/app_database_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async => db.close());

  /// Zet de kaart neer via een gewone `ref.read`-route, net als Home doet.
  ///
  /// Bewust géén `ref.watch` op `analyticsConsentProvider` in deze boom: juist
  /// het ontbreken van een luisteraar is wat de provider laat opruimen, en dat
  /// is de conditie waaronder de bug bestond. Een test die hier een watch
  /// neerzet, test de enige situatie die altijd al werkte.
  Future<void> pumpSheet(
    WidgetTester tester, {
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db), ...overrides],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showAnalyticsConsentSheet(context, ref),
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

  S localisatie(WidgetTester tester) =>
      S.of(tester.element(find.text('open')));

  testWidgets('Test 1 - "No thanks" sluit de kaart en legt de nee vast',
      (tester) async {
    await pumpSheet(tester);
    final s = localisatie(tester);
    expect(find.text(s.analyticsAskTitle), findsOneWidget);

    await tester.tap(find.text(s.analyticsAskNo));
    await tester.pumpAndSettle();

    expect(
      find.text(s.analyticsAskTitle),
      findsNothing,
      reason: 'De kaart moet meteen weg zijn, niet pas na een herstart.',
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AnalyticsConsentStore.kConsentKey), isFalse);
  });

  testWidgets('Test 2 - "Yes, go ahead" sluit de kaart en legt de ja vast',
      (tester) async {
    await pumpSheet(tester);
    final s = localisatie(tester);

    await tester.tap(find.text(s.analyticsAskYes));
    await tester.pumpAndSettle();

    expect(
      find.text(s.analyticsAskTitle),
      findsNothing,
      reason: 'De kaart moet meteen weg zijn, niet pas na een herstart.',
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AnalyticsConsentStore.kConsentKey), isTrue);
    expect(
      prefs.getString(AnalyticsConsentStore.kDeviceIdKey),
      isNotNull,
      reason: 'Een ja hoort een verse toestel-id op te leveren.',
    );
  });

  testWidgets('Test 3 - de kaart sluit ook als setConsent gooit',
      (tester) async {
    // De tweede laag. De oorzaak uit test 1 en 2 is weg, maar het sluiten mag
    // nooit meer afhangen van of de regel ervoor slaagt -- dat was de vorm van
    // de fout, los van de aanleiding.
    await pumpSheet(tester, overrides: [
      analyticsConsentProvider.overrideWith(_WerptBijAntwoord.new),
    ]);
    final s = localisatie(tester);

    await tester.tap(find.text(s.analyticsAskNo));

    // De fout wordt niet ingeslikt: de kaart meldt hem via
    // `FlutterError.reportError`. Dat is precies waarom hij hier op te halen
    // is. Zou de kaart hem doorgooien, dan verdween hij in de weggegooide
    // Future van `onPressed` en zag niemand hem -- in de test niet en in
    // logcat evenmin.
    expect(tester.takeException(), isA<StateError>());
    await tester.pumpAndSettle();

    expect(
      find.text(s.analyticsAskTitle),
      findsNothing,
      reason: 'Sluiten mag niet afhangen van wat er ná de schrijfactie gebeurt.',
    );
  });
}

/// Een toestemmings-notifier die op het antwoord stukloopt.
class _WerptBijAntwoord extends AnalyticsConsent {
  @override
  Future<AnalyticsConsentStore> build() async =>
      AnalyticsConsentStore(await SharedPreferences.getInstance());

  @override
  Future<void> setConsent(bool granted) async {
    throw StateError('boekhouding stuk');
  }
}
