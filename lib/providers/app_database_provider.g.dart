// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton AppDatabase for the app lifetime.
/// keepAlive: true — database must survive provider disposal (always-on).

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Provides the singleton AppDatabase for the app lifetime.
/// keepAlive: true — database must survive provider disposal (always-on).

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Provides the singleton AppDatabase for the app lifetime.
  /// keepAlive: true — database must survive provider disposal (always-on).
  AppDatabaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appDatabaseProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'8c69eb46d45206533c176c88a926608e79ca927d';

/// Provides a stateless OpenMeteoClient.
/// AutoDispose is fine: the client holds no state.

@ProviderFor(openMeteoClient)
final openMeteoClientProvider = OpenMeteoClientProvider._();

/// Provides a stateless OpenMeteoClient.
/// AutoDispose is fine: the client holds no state.

final class OpenMeteoClientProvider extends $FunctionalProvider<OpenMeteoClient,
    OpenMeteoClient, OpenMeteoClient> with $Provider<OpenMeteoClient> {
  /// Provides a stateless OpenMeteoClient.
  /// AutoDispose is fine: the client holds no state.
  OpenMeteoClientProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'openMeteoClientProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$openMeteoClientHash();

  @$internal
  @override
  $ProviderElement<OpenMeteoClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  OpenMeteoClient create(Ref ref) {
    return openMeteoClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OpenMeteoClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OpenMeteoClient>(value),
    );
  }
}

String _$openMeteoClientHash() => r'be472006a7948f4dea3dae25081cc619db0bf512';

/// Provides a WeatherRepository wired to appDatabase + openMeteoClient.

@ProviderFor(weatherRepository)
final weatherRepositoryProvider = WeatherRepositoryProvider._();

/// Provides a WeatherRepository wired to appDatabase + openMeteoClient.

final class WeatherRepositoryProvider extends $FunctionalProvider<
    WeatherRepository,
    WeatherRepository,
    WeatherRepository> with $Provider<WeatherRepository> {
  /// Provides a WeatherRepository wired to appDatabase + openMeteoClient.
  WeatherRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'weatherRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$weatherRepositoryHash();

  @$internal
  @override
  $ProviderElement<WeatherRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WeatherRepository create(Ref ref) {
    return weatherRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeatherRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeatherRepository>(value),
    );
  }
}

String _$weatherRepositoryHash() => r'e4c72400052c577667da04dadfce8bef8a4f4036';
