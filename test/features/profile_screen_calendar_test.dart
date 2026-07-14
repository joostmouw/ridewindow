/// Widget-tests voor de Google Calendar status-rij in ProfileScreen
/// (backlog #36).
///
/// Geen CalendarService-mocking: in de Flutter test-omgeving is er geen
/// geregistreerde platform-channel handler voor `google_sign_in`, dus elke
/// echte aanroep naar GoogleSignIn.instance gooit een MissingPluginException.
/// _checkCalendarConnection()'s try/catch vangt dit op en valt terug op
/// "Not connected" -- dit bewijst het eigen graceful-degradation-pad van de
/// app, niet een geslaagde platform-channel-aanroep.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/profile/profile_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
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

Future<void> _pumpProfileScreen(WidgetTester tester) async {
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
}
