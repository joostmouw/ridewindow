import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/providers/gps_permission_notifier.dart';

/// FakeGpsPermissionNotifier retourneert een geconfigureerde toestemmingswaarde
/// zonder de echte Geolocator aan te roepen.
class FakeGpsPermissionNotifier extends GpsPermissionNotifier {
  final LocationPermission fakePermission;
  FakeGpsPermissionNotifier(this.fakePermission);

  @override
  Future<LocationPermission> build() async => fakePermission;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GpsPermissionNotifier', () {
    test('build() geeft geconfigureerde fakePermission terug', () async {
      final container = ProviderContainer(
        overrides: [
          gpsPermissionProvider.overrideWith(
            () => FakeGpsPermissionNotifier(LocationPermission.whileInUse),
          ),
        ],
      );
      addTearDown(container.dispose);

      final permission = await container.read(gpsPermissionProvider.future);

      expect(permission, equals(LocationPermission.whileInUse));
    });

    test(
        'gpsPermissionProvider initial state is AsyncData wanneer FakeNotifier gebruikt wordt',
        () async {
      final container = ProviderContainer(
        overrides: [
          gpsPermissionProvider.overrideWith(
            () =>
                FakeGpsPermissionNotifier(LocationPermission.deniedForever),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(gpsPermissionProvider.future);

      final state = container.read(gpsPermissionProvider);
      expect(state, isA<AsyncData<LocationPermission>>());
      expect(state.value, equals(LocationPermission.deniedForever));
    });
  });
}
