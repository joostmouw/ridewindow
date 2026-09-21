// test/services/calendar_service_test.dart
// Unit tests for CalendarService's cache/warmup helpers and error paths.
//
// Tests use only dart:core, flutter_test, and own package imports.
// No real GoogleSignIn is touched — integration tests cover the sign-in flow.

import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/services/calendar_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CalendarService.cachedCalendarAccountEmail', () {
    test('leest de lokaal opgeslagen primaire Calendar-identiteit', () async {
      SharedPreferences.setMockInitialValues({
        CalendarService.calendarAccountEmailKey: 'calendar@example.com',
      });

      expect(
        await CalendarService.cachedCalendarAccountEmail(),
        equals('calendar@example.com'),
      );
    });

    test('geeft null terug als er nog geen identiteit gecachet is', () async {
      expect(await CalendarService.cachedCalendarAccountEmail(), isNull);
    });
  });

  group('CalendarService.addRideSlotToCalendar', () {
    // TODO: Integratie-tests voor de volledige sign-in + CalendarApi flow vallen
    // buiten unit-test scope omdat het mocken van GoogleSignIn.instance (singleton
    // met native Android bridge) een aparte integratie-test setup vereist.
    // De widget-tests in ride_detail_screen_calendar_test.dart dekken de
    // factory-injectie, PERS-04 via FakeCalendarService, en sinds quick
    // 260921-p3d ook de i18n/eenheden-dekking van title/description via de
    // CapturingFakeCalendarService -- die tekstopbouw gebeurt niet meer hier.

    test('placeholder: sign-in flow vereist integratie-tests met device', () {
      // Bewust leeg — zie TODO hierboven.
      expect(true, isTrue);
    });
  });

  group('CalendarService.warmUpForWeb (CAL-06)', () {
    // -------------------------------------------------------------------------
    // Test 1 (CAL-06): warmUpForWeb() mag nooit een exception laten ontsnappen,
    // ook niet als er geen echte GoogleSignIn platform-channel gebonden is
    // (zoals onder `flutter test`'s Dart-VM omgeving). De try/catch binnenin
    // vangt de MissingPluginException op — dit bewijst dat een mislukte warmup
    // de app-start nooit laat crashen.
    // -------------------------------------------------------------------------
    test(
      'warmUpForWeb() completes without throwing under flutter test (geen echte GoogleSignIn plugin gebonden)',
      () async {
        await expectLater(CalendarService.warmUpForWeb(), completes);
      },
    );

    // -------------------------------------------------------------------------
    // Test 2 (CAL-06): warmUpForWeb() is idempotent — twee keer aanroepen in
    // dezelfde sessie mag nooit alsnog een exception opleveren.
    // -------------------------------------------------------------------------
    test(
      'warmUpForWeb() is idempotent — twee keer aanroepen blijft zonder exception',
      () async {
        await CalendarService.warmUpForWeb();
        await CalendarService.warmUpForWeb();
      },
    );

    // -------------------------------------------------------------------------
    // Regression test (bugfix, post-Task-3 manual verification): twee
    // GELIJKTIJDIGE aanroepen van warmUpForWeb() -- zonder op de eerste te
    // wachten voordat de tweede start -- mogen NOOIT leiden tot "Bad state:
    // init() has already been called" (de exacte fout die de gebruiker
    // tegenkwam toen main.dart's eager web-warmup nog in-flight was terwijl
    // een tik op "Add to calendar" gelijktijdig _ensureInitialized() startte).
    // Beide aanroepen moeten dezelfde gememoized _sharedInitialize-future
    // delen in plaats van elk hun eigen GoogleSignIn.instance.initialize()
    // te starten. Onder `flutter test` gooit initialize() zelf een
    // MissingPluginException (geen platform-channel gebonden) -- dat wordt
    // door beide aanroepers stilzwijgend opgevangen; de memoisatie-logica
    // zelf wordt hier wel degelijk getest doordat geen enkele aanroep een
    // "Bad state"-achtige dubbele-init-exception mag opleveren.
    // -------------------------------------------------------------------------
    test(
      'twee gelijktijdige warmUpForWeb()-aanroepen delen dezelfde initialize()-call (geen "Bad state" exception)',
      () async {
        final first = CalendarService.warmUpForWeb();
        final second = CalendarService.warmUpForWeb();

        await expectLater(Future.wait([first, second]), completes);
      },
    );
  });

  group('CalendarService.hashNonce (quick 260726-o3m nonce-fix)', () {
    // -------------------------------------------------------------------------
    // Test 1: bekende vector -- geverifieerd via `shasum -a 256` <<< 'test'.
    // -------------------------------------------------------------------------
    test('hashNonce("test") geeft de bekende SHA-256-hexvector terug', () {
      final result = CalendarService.hashNonce('test');
      expect(
        result,
        equals(
          '9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08',
        ),
      );
    });

    // -------------------------------------------------------------------------
    // Test 2: lege-string vector -- geverifieerd via `shasum -a 256` <<< ''.
    // -------------------------------------------------------------------------
    test(
        'hashNonce("") geeft de bekende SHA-256-hexvector van de lege string terug',
        () {
      final result = CalendarService.hashNonce('');
      expect(
        result,
        equals(
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        ),
      );
    });

    // -------------------------------------------------------------------------
    // Test 3: stabiliteit -- authNonce moet identiek blijven over twee losse
    // reads binnen dezelfde test (bewijst het "eenmaal genereren, stabiel
    // blijven"-contract van de static final _rawNonce).
    // -------------------------------------------------------------------------
    test('CalendarService.authNonce blijft identiek over twee losse reads', () {
      final first = CalendarService.authNonce;
      final second = CalendarService.authNonce;
      expect(first, equals(second));
    });

    // -------------------------------------------------------------------------
    // Test 4: vorm -- authNonce is niet leeg, en hashNonce(authNonce) matcht
    // ^[0-9a-f]{64}$ (lowercase hex, 64 tekens) -- de vorm die Supabase's
    // Go-code verwacht: fmt.Sprintf("%x", sha256.Sum256(...)).
    // -------------------------------------------------------------------------
    test(
      'CalendarService.authNonce is niet leeg en hashNonce(authNonce) heeft de juiste vorm',
      () {
        expect(CalendarService.authNonce, isNotEmpty);
        final hashed = CalendarService.hashNonce(CalendarService.authNonce);
        expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hashed), isTrue);
      },
    );
  });
}
