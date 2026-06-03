/// Widget-tests voor locatie-UI in ProfileScreen.
///
/// Dekt Phase 7 Plan 05 success criteria (LOC-01 t/m LOC-05):
///   LOC-01: gpsPermissionProvider wordt bevraagd (test 2/5)
///   LOC-02: GPS-locatie retourneer-pad (test 1)
///   LOC-03: Stad-keuze via ProfileNotifier (test 2)
///   LOC-04: deniedForever banner getest (test 5)
///   LOC-05: Override heeft voorrang (test 2)
///
/// Tests gebruiken FakeNotifier-subklassen (extends concrete klasse, niet _$abstract)
/// conform het gevestigde patroon uit Phase 3/6.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/profile/profile_screen.dart';
import 'package:ridewindow/providers/gps_permission_notifier.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/providers/weather_notifier.dart';

// ---------------------------------------------------------------------------
// Fake Notifiers
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

/// Minimale WeatherNotifier die geen echte HTTP-aanroepen doet.
class FakeWeatherNotifier extends WeatherNotifier {
  @override
  Future<List<HourlyForecast>> build() async => const [];
}

// ---------------------------------------------------------------------------
// Helper: basisprofielfixture
// ---------------------------------------------------------------------------

UserProfile baseProfile({String? locationOverride}) => UserProfile(
      tolerances: const WeatherTolerances(
        tempMinIdealC: 12.0,
        tempMaxIdealC: 26.0,
        windMaxIdealKmh: 15.0,
        rainMaxIdealMm: 0.5,
      ),
      allowedDurations: const [2, 3, 5],
      theme: 'system',
      locationOverride: locationOverride,
      notifEveningBefore: false,
      notifMorningOf: false,
      notifWeeklyDigest: false,
    );

const _defaultLocation = LocationData(lat: 52.3676, lon: 4.9041, city: 'Amsterdam');

Future<void> _pumpProfileScreen(
  WidgetTester tester, {
  required UserProfile profile,
  LocationPermission permission = LocationPermission.whileInUse,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileProvider.overrideWith(() => FakeProfileNotifier(profile)),
        gpsPermissionProvider.overrideWith(
          () => FakeGpsPermissionNotifier(permission),
        ),
        locationProvider.overrideWith(
          () => FakeLocationNotifier(_defaultLocation),
        ),
        weatherProvider.overrideWith(() => FakeWeatherNotifier()),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Test 1 — toont GPS (automatisch) als geen override actief',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      profile: baseProfile(locationOverride: null),
      permission: LocationPermission.whileInUse,
    );

    // LOCATIE tegel toont 'GPS (automatisch)' als locationOverride null is
    expect(
      find.text('GPS (automatisch)', skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets(
      'Test 2 — toont stadsnaam als override actief',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      profile: baseProfile(locationOverride: 'Rotterdam'),
    );

    // LOCATIE tegel toont stadsnaam 'Rotterdam' (LOC-05: override heeft voorrang)
    expect(find.text('Rotterdam', skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'Test 3 — toont wis-knop (Icons.clear) als override actief',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      profile: baseProfile(locationOverride: 'Groningen'),
    );

    // IconButton met Icons.clear aanwezig als locationOverride != null
    expect(find.byIcon(Icons.clear, skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'Test 4 — toont geen wis-knop als geen override actief',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      profile: baseProfile(locationOverride: null),
    );

    // Geen IconButton met Icons.clear als locationOverride == null
    expect(find.byIcon(Icons.clear, skipOffstage: false), findsNothing);
  });

  testWidgets(
      'Test 5 — toont GPS-geblokkeerd banner als toestemming deniedForever is',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      profile: baseProfile(locationOverride: null),
      permission: LocationPermission.deniedForever,
    );

    // Banner-tekst zichtbaar (LOC-04)
    expect(
      find.text('Locatie-toegang geblokkeerd', skipOffstage: false),
      findsOneWidget,
    );
    // 'Instellingen openen' knop zichtbaar
    expect(
      find.text('Instellingen openen', skipOffstage: false),
      findsOneWidget,
    );
  });
}
