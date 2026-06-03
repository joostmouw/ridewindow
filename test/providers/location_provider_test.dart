import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/core/config.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/providers/gps_permission_notifier.dart';
import 'package:ridewindow/providers/location_provider.dart';
import 'package:ridewindow/providers/profile_notifier.dart';

/// FakeGpsPermissionNotifier retourneert een gefixte LocationPermission voor tests.
class FakeGpsPermissionNotifier extends GpsPermissionNotifier {
  final LocationPermission fakePermission;
  FakeGpsPermissionNotifier(this.fakePermission);

  @override
  Future<LocationPermission> build() async => fakePermission;
}

/// FakeProfileNotifier retourneert een gepreconfigureerd UserProfile voor tests.
class FakeProfileNotifier extends ProfileNotifier {
  final UserProfile fakeProfile;
  FakeProfileNotifier(this.fakeProfile);

  @override
  Future<UserProfile> build() async => fakeProfile;
}

/// FakeLocationNotifier retourneert een gefixte LocationData voor tests.
class FakeLocationNotifier extends LocationNotifier {
  final LocationData fakeLocation;
  FakeLocationNotifier(this.fakeLocation);

  @override
  Future<LocationData> build() async => fakeLocation;
}

const _defaultTolerances = WeatherTolerances(
  tempMinIdealC: 12.0,
  tempMaxIdealC: 26.0,
  windMaxIdealKmh: 15.0,
  rainMaxIdealMm: 0.5,
);

/// Bouw een testprofiel met optionele locationOverride.
UserProfile _makeProfile({String? locationOverride}) {
  return UserProfile(
    tolerances: _defaultTolerances,
    allowedDurations: const [2, 3, 5],
    theme: 'system',
    locationOverride: locationOverride,
    notifEveningBefore: false,
    notifMorningOf: false,
    notifWeeklyDigest: false,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocationNotifier', () {
    test('city override aanwezig → juiste LocationData (LOC-05)', () async {
      final fakeProfile = _makeProfile(locationOverride: 'Rotterdam');

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(fakeProfile),
          ),
          gpsPermissionProvider.overrideWith(
            () => FakeGpsPermissionNotifier(LocationPermission.denied),
          ),
        ],
      );
      addTearDown(container.dispose);

      final location = await container.read(locationProvider.future);

      expect(location.city, equals('Rotterdam'));
      expect(location.lat, closeTo(51.9225, 0.001));
      expect(location.lon, closeTo(4.4792, 0.001));
    });

    test('geen override + permission denied → Amsterdam default (LOC-04)',
        () async {
      final fakeProfile = _makeProfile(locationOverride: null);

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(fakeProfile),
          ),
          gpsPermissionProvider.overrideWith(
            () => FakeGpsPermissionNotifier(LocationPermission.deniedForever),
          ),
        ],
      );
      addTearDown(container.dispose);

      final location = await container.read(locationProvider.future);

      expect(location.city, equals(kDefaultCity));
      expect(location.lat, closeTo(kDefaultLat, 0.001));
      expect(location.lon, closeTo(kDefaultLon, 0.001));
    });

    test(
        'geen override + permission whileInUse → build() completeert via FakeLocationNotifier',
        () async {
      const fakeLocation =
          LocationData(lat: 52.3676, lon: 4.9041, city: 'GPS');

      final container = ProviderContainer(
        overrides: [
          locationProvider.overrideWith(
            () => FakeLocationNotifier(fakeLocation),
          ),
        ],
      );
      addTearDown(container.dispose);

      final location = await container.read(locationProvider.future);

      expect(location.city, equals('GPS'));
      expect(location.lat, closeTo(52.3676, 0.001));
    });
  });
}
