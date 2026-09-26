// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Welke bron de update-melding raadpleegt. Eigen provider zodat een test hem
/// kan overriden: de echte vraagt het aan Play of aan de webserver.

@ProviderFor(appUpdateService)
final appUpdateServiceProvider = AppUpdateServiceProvider._();

/// Welke bron de update-melding raadpleegt. Eigen provider zodat een test hem
/// kan overriden: de echte vraagt het aan Play of aan de webserver.

final class AppUpdateServiceProvider extends $FunctionalProvider<
    AppUpdateService,
    AppUpdateService,
    AppUpdateService> with $Provider<AppUpdateService> {
  /// Welke bron de update-melding raadpleegt. Eigen provider zodat een test hem
  /// kan overriden: de echte vraagt het aan Play of aan de webserver.
  AppUpdateServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appUpdateServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appUpdateServiceHash();

  @$internal
  @override
  $ProviderElement<AppUpdateService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppUpdateService create(Ref ref) {
    return appUpdateService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUpdateService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUpdateService>(value),
    );
  }
}

String _$appUpdateServiceHash() => r'a580c2610d3c4676195044681f4dd8b48aa6d2d7';
