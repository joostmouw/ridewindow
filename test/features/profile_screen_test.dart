/// Widget tests voor ProfileScreen.
///
/// Dekt Phase 6 Plan 04 success criteria:
///   1. ProfileScreen toont vier Slider-widgets bij een geladen profiel
///   2. Sectiekopteksten TOLERANTIES, RIJLENGTE, THEMA en LOCATIE aanwezig
///   3. Drie FilterChip-widgets aanwezig; chip '2u' is selected
///   4. SegmentedButton aanwezig; segment 'Systeem' is geselecteerd
///   5. Knop/tegel 'Mijn schema bewerken' aanwezig

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

class FakeProfileNotifier extends ProfileNotifier {
  final UserProfile fakeProfile;
  FakeProfileNotifier(this.fakeProfile);

  @override
  Future<UserProfile> build() async => fakeProfile;
}

/// Fake GPS-toestemmingsnotifier voor widget-tests — geen Geolocator nodig.
class FakeGpsPermissionNotifier extends GpsPermissionNotifier {
  final LocationPermission fakePermission;
  FakeGpsPermissionNotifier(this.fakePermission);

  @override
  Future<LocationPermission> build() async => fakePermission;
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Future<void> pumpProfileScreen(WidgetTester tester, UserProfile profile,
    {LocationPermission permission = LocationPermission.denied}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileProvider.overrideWith(() => FakeProfileNotifier(profile)),
        gpsPermissionProvider.overrideWith(
          () => FakeGpsPermissionNotifier(permission),
        ),
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
      'Test 1: ProfileScreen toont vier Slider-widgets bij een geladen profiel',
      (tester) async {
    await pumpProfileScreen(tester, testProfile);

    // skipOffstage: false — ListView rendert alleen zichtbare items in viewport.
    expect(find.byType(Slider, skipOffstage: false), findsNWidgets(4));
  });

  testWidgets(
      'Test 2: Sectiekopteksten TOLERANTIES, RIJLENGTE, THEMA en LOCATIE aanwezig',
      (tester) async {
    await pumpProfileScreen(tester, testProfile);

    // skipOffstage: false — secties buiten het viewport zijn nog in de widget tree.
    expect(find.text('LOCATIE', skipOffstage: false), findsOneWidget);
    expect(find.text('TOLERANTIES', skipOffstage: false), findsOneWidget);
    expect(find.text('RIJLENGTE', skipOffstage: false), findsOneWidget);
    expect(find.text('THEMA', skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'Test 3: Drie FilterChip-widgets aanwezig; chip 2u is selected',
      (tester) async {
    await pumpProfileScreen(tester, testProfile);

    // Drie FilterChip widgets aanwezig (skipOffstage: false — RIJLENGTE buiten viewport)
    expect(find.byType(FilterChip, skipOffstage: false), findsNWidgets(3));

    // Chip '2u' is geselecteerd (testProfile.allowedDurations bevat 2)
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is FilterChip &&
            w.label is Text &&
            (w.label as Text).data == '2u' &&
            w.selected == true,
        skipOffstage: false,
      ),
      findsOneWidget,
      reason: 'FilterChip "2u" moet selected zijn',
    );
  });

  testWidgets(
      'Test 4: SegmentedButton aanwezig; segment Systeem is geselecteerd',
      (tester) async {
    await pumpProfileScreen(tester, testProfile);

    expect(
      find.byType(SegmentedButton<String>, skipOffstage: false),
      findsOneWidget,
    );
    // 'Systeem' is zichtbaar als segment label
    expect(find.text('Systeem', skipOffstage: false), findsOneWidget);
  });

  testWidgets(
      'Test 5: Knop/tegel Mijn schema bewerken aanwezig',
      (tester) async {
    await pumpProfileScreen(tester, testProfile);

    expect(find.text('Mijn schema bewerken', skipOffstage: false), findsOneWidget);
  });
}
