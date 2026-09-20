// OK in een infovenster mag nooit het scherm eronder weghalen.
//
// Joost, 2026-09-20: "als je bij de tolerances in je profiel op info klikt en
// daar op ok drukt krijg je een zwart scherm."
//
// De oorzaak, en waarom geen enkele bestaande test hem zag
// -------------------------------------------------------
// De OK-knop deed `Navigator.of(context).pop()` met de context van het
// profielscherm in plaats van die van de dialoog. In een gewone `MaterialApp`
// is dat dezelfde navigator en valt er niets op: de bovenste route is dan de
// dialoog, en die verdwijnt netjes. In de echte app zit het profielscherm
// binnen een go_router-shell met een eigen navigator, terwijl `showDialog` zijn
// route standaard op de root-navigator zet. De pop haalde dan de *pagina* weg
// onder de dialoog, en wat overbleef was zwart.
//
// Deze test zet daarom een geneste navigator neer, precies zoals de shell dat
// doet. Zonder die nesting bewijst de test niets -- dat is de hele reden dat
// `profile_screen_test.dart` hier jarenlang langs kon kijken.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/features/profile/profile_screen.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/providers/gps_permission_notifier.dart';
import 'package:ridewindow/providers/profile_notifier.dart';
import 'package:ridewindow/theme/app_theme.dart';

const _profile = UserProfile(
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

class _FakeProfile extends ProfileNotifier {
  @override
  Future<UserProfile> build() async => _profile;
}

class _FakeGps extends GpsPermissionNotifier {
  @override
  Future<LocationPermission> build() async => LocationPermission.denied;
}

Future<void> _pump(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(400, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileProvider.overrideWith(_FakeProfile.new),
        gpsPermissionProvider.overrideWith(_FakeGps.new),
      ],
      child: MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        theme: ThemeData(extensions: const [RideWindowTheme.light]),
        // De geneste navigator die de go_router-shell in productie ook is.
        home: Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            builder: (_) => const ProfileScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('OK sluit het infovenster en laat het profielscherm staan',
      (tester) async {
    await _pump(tester);

    // De vier infoknoppen bij TOLERANTIES dragen hun titel als tooltip.
    final infoButton = find.byTooltip('Temperatuurbereik');
    expect(infoButton, findsOneWidget);

    await tester.tap(infoButton);
    // Geen `pumpAndSettle`: ergens op dit scherm loopt een animatie die nooit
    // uitdooft (de bestaande profieltests vermijden hem om dezelfde reden).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsNothing,
        reason: 'de dialoog moet dicht');
    expect(
      find.byType(ProfileScreen),
      findsOneWidget,
      reason: 'en het scherm eronder moet blijven staan -- popt OK de pagina '
          'in plaats van de dialoog, dan kijk je tegen zwart aan',
    );
  });
}
