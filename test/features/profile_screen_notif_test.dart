// test/features/profile_screen_notif_test.dart
// Widget-tests voor ProfileScreen NOTIFICATIES sectie.
// Dekt Phase 8 Plan 05 success criteria (NOTIF-01, NOTIF-02, NOTIF-03).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/profile/profile_screen.dart';
import 'package:ridewindow/providers/gps_permission_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';

// ---------------------------------------------------------------------------
// Test fixture
// ---------------------------------------------------------------------------

const testProfile = UserProfile(
  tolerances: WeatherTolerances(
    tempMinIdealC: 12.0,
    tempMaxIdealC: 26.0,
    windMaxIdealKmh: 15.0,
    rainMaxIdealMm: 0.5,
  ),
  allowedDurations: [2, 3, 5],
  theme: 'system',
  notifEveningBefore: false,
  notifMorningOf: false,
  notifWeeklyDigest: false,
);

// ---------------------------------------------------------------------------
// Fake Notifiers
// ---------------------------------------------------------------------------

/// FakeProfileNotifier met registratie van setNotifEveningBefore aanroepen.
class FakeProfileNotifier extends ProfileNotifier {
  final UserProfile fakeProfile;
  bool setNotifEveningBeforeCalled = false;
  bool setNotifEveningBeforeValue = false;

  FakeProfileNotifier(this.fakeProfile);

  @override
  Future<UserProfile> build() async => fakeProfile;

  @override
  Future<void> setNotifEveningBefore(bool value) async {
    setNotifEveningBeforeCalled = true;
    setNotifEveningBeforeValue = value;
    state = AsyncData(fakeProfile.copyWith(notifEveningBefore: value));
  }

  @override
  Future<void> setNotifMorningOf(bool value) async {
    state = AsyncData(fakeProfile.copyWith(notifMorningOf: value));
  }

  @override
  Future<void> setNotifWeeklyDigest(bool value) async {
    state = AsyncData(fakeProfile.copyWith(notifWeeklyDigest: value));
  }
}

/// GPS-permissie stub — geen Geolocator nodig.
class FakeGpsPermissionNotifier extends GpsPermissionNotifier {
  @override
  Future<LocationPermission> build() async => LocationPermission.denied;
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Future<Widget> _buildProfileScreen(FakeProfileNotifier notifier) async {
  return ProviderScope(
    overrides: [
      profileProvider.overrideWith(() => notifier),
      gpsPermissionProvider
          .overrideWith(() => FakeGpsPermissionNotifier()),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Test 1: Toont NOTIFICATIES sectie met 3 SwitchListTile widgets',
    (tester) async {
      final notifier = FakeProfileNotifier(testProfile);
      await tester.pumpWidget(await _buildProfileScreen(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // NOTIFICATIES sectie-koptekst zichtbaar
      expect(find.text('NOTIFICATIES', skipOffstage: false), findsOneWidget);

      // Drie SwitchListTile widgets aanwezig
      expect(
        find.byType(SwitchListTile, skipOffstage: false),
        findsNWidgets(3),
      );
    },
  );

  testWidgets(
    "Test 2: 'Avond van tevoren' toggle zichtbaar met label",
    (tester) async {
      final notifier = FakeProfileNotifier(testProfile);
      await tester.pumpWidget(await _buildProfileScreen(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Avond van tevoren', skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    "Test 3: 'Ochtend van de dag' toggle zichtbaar met label",
    (tester) async {
      final notifier = FakeProfileNotifier(testProfile);
      await tester.pumpWidget(await _buildProfileScreen(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Ochtend van de dag', skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    "Test 4: 'Wekelijks overzicht' toggle zichtbaar met label",
    (tester) async {
      final notifier = FakeProfileNotifier(testProfile);
      await tester.pumpWidget(await _buildProfileScreen(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Wekelijks overzicht', skipOffstage: false),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Test 5: Tap op eerste SwitchListTile roept setNotifEveningBefore(true) aan',
    (tester) async {
      final notifier = FakeProfileNotifier(testProfile);
      await tester.pumpWidget(await _buildProfileScreen(notifier));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap de eerste SwitchListTile — dit is "Avond van tevoren"
      // skipOffstage: false + scrollIntoView om de widget bereikbaar te maken
      final firstSwitch = find.byType(SwitchListTile, skipOffstage: false).first;
      await tester.scrollUntilVisible(firstSwitch, 100);
      await tester.tap(firstSwitch);
      await tester.pump();

      // Verifieer dat setNotifEveningBefore(true) werd aangeroepen
      expect(notifier.setNotifEveningBeforeCalled, isTrue);
      expect(notifier.setNotifEveningBeforeValue, isTrue);
    },
  );
}
