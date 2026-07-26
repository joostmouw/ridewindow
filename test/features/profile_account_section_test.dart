/// Widget-tests voor AccountSection (Plan 19-03) in de uitgelogde en
/// ingelogde toestand, gepumpt via ProfileScreen zodat Task 2's inbedding
/// ook wordt bewezen.
///
/// Zelfde Fake*Notifier + ProviderScope-overridepatroon als
/// profile_screen_calendar_test.dart. `authStateProvider` is een gewone
/// `@Riverpod`-functieprovider (`Stream&lt;User?&gt;`), geen class-based
/// Notifier -- daarom gebruikt de override hier
/// `.overrideWith((ref) =&gt; stream)` in plaats van de
/// `Fake*Notifier.overrideWith(() =&gt; Fake...())`-vorm die de andere
/// providers in dit bestand gebruiken.
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
// Fake Notifiers (zelfde patroon als profile_screen_calendar_test.dart)
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

final _fakeUser = User(
  id: 'test-uid-123',
  appMetadata: const {},
  userMetadata: const {'full_name': 'Rider Test'},
  aud: 'authenticated',
  createdAt: DateTime.now().toIso8601String(),
  email: 'rider@example.com',
);

Future<void> _pumpProfileScreen(
  WidgetTester tester, {
  required Stream<User?> authStream,
}) async {
  // Vergroot het test-viewport zodat de nieuwe Account-sectie (bovenaan) en
  // de bestaande secties allemaal binnen de sliver-viewport vallen en dus
  // gemount worden.
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
        authStateProvider.overrideWith((ref) => authStream),
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
      'Test 1 — uitgelogd toont Inloggen met Google + belofteregel, geen Uitloggen',
      (tester) async {
    await _pumpProfileScreen(tester, authStream: Stream<User?>.value(null));

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    expect(find.text(s.signInWithGoogle, skipOffstage: false), findsOneWidget);
    expect(find.text(s.accountSyncPromise, skipOffstage: false), findsOneWidget);
    expect(find.text(s.accountSignOut, skipOffstage: false), findsNothing);
  });

  testWidgets(
      'Test 2 — ingelogd toont naam + e-mail + Uitloggen, geen Inloggen met Google',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(_fakeUser),
    );

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    expect(find.text('Rider Test', skipOffstage: false), findsOneWidget);
    expect(find.text('rider@example.com', skipOffstage: false), findsOneWidget);
    expect(find.text(s.accountSignOut, skipOffstage: false), findsOneWidget);
    expect(find.text(s.signInWithGoogle, skipOffstage: false), findsNothing);
  });

  testWidgets(
      'Test 3 — tik op Uitloggen opent bevestigingsdialoog (D-12)',
      (tester) async {
    await _pumpProfileScreen(
      tester,
      authStream: Stream<User?>.value(_fakeUser),
    );

    final context = tester.element(find.byType(ProfileScreen));
    final s = S.of(context);

    // Geen pumpAndSettle: ProfileScreen's animated rain/wind widgets gebruiken
    // AnimationController.repeat(), wat pumpAndSettle laat timeouten (zelfde
    // patroon als home_screen_test.dart, zie STATE.md 04-05).
    await tester.tap(find.text(s.accountSignOut, skipOffstage: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(s.accountSignOutConfirmTitle), findsOneWidget);
    expect(find.text(s.accountSignOutConfirmBody), findsOneWidget);
  });
}
