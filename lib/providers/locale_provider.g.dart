// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Zet profile.locale (String) om naar Locale.
/// Hercomputed automatisch als profileProvider een nieuwe waarde emitteert.

@ProviderFor(appLocale)
final appLocaleProvider = AppLocaleProvider._();

/// Zet profile.locale (String) om naar Locale.
/// Hercomputed automatisch als profileProvider een nieuwe waarde emitteert.

final class AppLocaleProvider
    extends $FunctionalProvider<Locale, Locale, Locale> with $Provider<Locale> {
  /// Zet profile.locale (String) om naar Locale.
  /// Hercomputed automatisch als profileProvider een nieuwe waarde emitteert.
  AppLocaleProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'appLocaleProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$appLocaleHash();

  @$internal
  @override
  $ProviderElement<Locale> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Locale create(Ref ref) {
    return appLocale(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Locale value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Locale>(value),
    );
  }
}

String _$appLocaleHash() => r'38373e9ffbe103db71b3d23d5f45dc5a74846b74';
