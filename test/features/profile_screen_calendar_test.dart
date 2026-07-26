/// Widget-tests voor de Google Calendar status-rij in ProfileScreen
/// (backlog #36), uitgebreid met AUTH-07's mismatch-waarschuwing (Plan
/// 19-05).
///
/// Geen CalendarService-mocking: in de Flutter test-omgeving is er geen
/// geregistreerde platform-channel handler voor `google_sign_in`, dus elke
/// echte aanroep naar GoogleSignIn.instance gooit een MissingPluginException.
/// _checkCalendarConnection()'s try/catch vangt dit op en valt terug op
/// "Not connected" -- dit bewijst het eigen graceful-degradation-pad van de
/// app, niet een geslaagde platform-channel-aanroep.
///
/// AUTH-07-testbaarheidsnotitie (Task 3): _checkCalendarMismatch() wordt
/// alleen aangeroepen ná `_calendarConnected == true` (D-11), maar
/// `_calendarConnected` kan in deze test-omgeving nooit `true` worden --
/// dezelfde platform-channel-beperking hierboven. Task 2's implementatie is
/// klein genoeg om inline te blijven in de private State-klasse (geen apart
/// top-level pure-functie te extraheren die vanuit dit testbestand
/// aanroepbaar zou zijn -- Dart-privacy is per-bestand, dus een `_`-prefixed
/// top-level functie in profile_screen.dart is sowieso niet zichtbaar hier).
/// De tests hieronder bewijzen daarom het reëel bereikbare contract: de
/// mismatch-waarschuwing verschijnt nooit wanneer Calendar niet verbonden is
/// (het enige bereikbare pad in deze omgeving), ongeacht de
/// `authStateProvider`-staat -- inclusief het specifiek gevraagde
/// signed-out-geval.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/profile/profile_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/auth_notifier.dart';
import 'package:ridewindow/providers/gps_permission_notifier.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

// ---------------------------------------------------------------------------
// Fake Notifiers (zelfde patroon als profile_screen_location_test.dart)
// ---------------------------------------------------------------------------

class FakeProfileNotifier extends ProfileNotifier {
  final UserProfile fakeProfile;
  FakeProfileNotifier(this.fakeProfile);

  @override
  Future<UserProfile> build() async => fakeProfile;
}

class FakeGpsPermissionNotifier extends GpsPermissionNotifier {
  final LocationPermission fakePermission;
  FakeGpsPermissionNotifier(this.fakePermission);

  @override
  Future<LocationPermission> build() async => fakePermission;
}

class FakeLocationNotifier extends LocationNotifier {
  final LocationData fakeLocation;
  FakeLocationNotifier(this.fakeLocation);

  @override
  Future<LocationData> build() async => fakeLocation;
}

class FakeWeatherNotifier extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async => const [];
}

UserProfile _baseProfile() => const UserProfile(
      tolerances: WeatherTolerances(
        tempMinIdealC: 12.0,
        tempMaxIdealC: 26.0,
        windMaxIdealKmh: 15.0,
        rainMaxIdealMm: 0.5,
      ),
      allowedDurations: [2, 3, 5],
      theme: 'system',
      locationOverride: null,
      notifEveningBefore: false,
      notifMorningOf: false,
      notifWeeklyDigest: false,
    );

const _defaultLocation =
    LocationData(lat: 52.3676, lon: 4.9041, city: 'Amsterdam');

final _fakeSignedInUser = User(
  id: 'test-uid-456',
  appMetadata: const {},
  userMetadata: const {},
  aud: 'authenticated',
  createdAt: DateTime.now().toIso8601String(),
  email: 'rider@example.com',
);

Future<void> _pumpProfileScreen(
  WidgetTester tester, {
  Stream<User?>? authStream,
}) async {
  // Vergroot het test-viewport zodat de Google Calendar-rij (onderin de
  // OVER-sectie) binnen de sliver-viewport valt en dus gemount wordt --
  // zonder dit blijft de rij ongebouwd in de lazy ListView, ook met
  // skipOffstage: false (dat vindt alleen reeds-gemounte offstage widgets).
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileProvider.overrideWith(() => FakeProfileNotifier(_baseProfile())),
        gpsPermissionProvider.overrideWith(
          () => FakeGpsPermissionNotifier(LocationPermission.whileInUse),
        ),
        locationProvider.overrideWith(
          () => FakeLocationNotifier(_defaultLocation),
        ),
        weatherProvider.overrideWith(() => FakeWeatherNotifier()),
        authStateProvider.overrideWith(
          (ref) => authStream ?? Stream<User?>.value(null),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: ProfileScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Test 1 — Google Calendar-rij toont "Not connected" na graceful degradation',
      (tester) async {
    await _pumpProfileScreen(tester);

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    expect(find.text(s.googleCalendarLabel, skipOffstage: false), findsOneWidget);
    expect(
      find.text(s.calendarStatusNotConnected, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets(
      'Test 2 — geen Disconnect-knop zichtbaar als niet verbonden',
      (tester) async {
    await _pumpProfileScreen(tester);

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    expect(
      find.text(s.calendarDisconnectButton, skipOffstage: false),
      findsNothing,
    );
  });

  testWidgets(
      'Test 3 — AUTH-07: geen mismatch-waarschuwing als uitgelogd '
      '(geen ingelogde e-mail om mee te vergelijken, ongeacht Calendar-staat)',
      (tester) async {
    await _pumpProfileScreen(tester, authStream: Stream<User?>.value(null));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    // Calendar degradeert altijd naar "Not connected" in deze omgeving, dus
    // _checkCalendarMismatch() wordt nooit aangeroepen -- de waarschuwing mag
    // dan ook nooit verschijnen, ongeacht de authStateProvider-staat.
    expect(
      find.byIcon(Icons.warning_amber_rounded),
      findsNothing,
    );
    expect(
      find.text(
        s.calendarMismatchWarning('rider@example.com'),
        skipOffstage: false,
      ),
      findsNothing,
    );
  });

  testWidgets(
      'Test 4 — AUTH-07: geen mismatch-waarschuwing als ingelogd maar '
      'Calendar niet verbonden (mismatch-check is gated achter '
      '_calendarConnected == true, D-11)',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(_fakeSignedInUser),
    );

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(
      find.text(
        s.calendarMismatchWarning(_fakeSignedInUser.email!),
        skipOffstage: false,
      ),
      findsNothing,
    );
    // De bestaande subtitle-tekst blijft ongewijzigd -- geen Column/warning-
    // icoon toegevoegd wanneer er geen mismatch is (acceptance criterium).
    expect(
      find.text(s.calendarStatusNotConnected, skipOffstage: false),
      findsOneWidget,
    );
  });
}
