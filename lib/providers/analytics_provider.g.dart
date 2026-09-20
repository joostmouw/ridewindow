// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// De toestemmingsstand. Een `Notifier` en geen simpele lees-provider, omdat
/// Profiel hem moet kunnen omzetten en Home moet zien dat de vraag beantwoord is.

@ProviderFor(AnalyticsConsent)
final analyticsConsentProvider = AnalyticsConsentProvider._();

/// De toestemmingsstand. Een `Notifier` en geen simpele lees-provider, omdat
/// Profiel hem moet kunnen omzetten en Home moet zien dat de vraag beantwoord is.
final class AnalyticsConsentProvider
    extends $AsyncNotifierProvider<AnalyticsConsent, AnalyticsConsentStore> {
  /// De toestemmingsstand. Een `Notifier` en geen simpele lees-provider, omdat
  /// Profiel hem moet kunnen omzetten en Home moet zien dat de vraag beantwoord is.
  AnalyticsConsentProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'analyticsConsentProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$analyticsConsentHash();

  @$internal
  @override
  AnalyticsConsent create() => AnalyticsConsent();
}

String _$analyticsConsentHash() => r'a71fa2657102b94cbbd80b219991063ec343e1c3';

/// De toestemmingsstand. Een `Notifier` en geen simpele lees-provider, omdat
/// Profiel hem moet kunnen omzetten en Home moet zien dat de vraag beantwoord is.

abstract class _$AnalyticsConsent
    extends $AsyncNotifier<AnalyticsConsentStore> {
  FutureOr<AnalyticsConsentStore> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<AnalyticsConsentStore>, AnalyticsConsentStore>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<AnalyticsConsentStore>, AnalyticsConsentStore>,
        AsyncValue<AnalyticsConsentStore>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

/// De service zelf. Hangt aan dezelfde outbox als profiel, beschikbaarheid en
/// feedback -- zie `AnalyticsService` voor waarom.

@ProviderFor(analytics)
final analyticsProvider = AnalyticsProvider._();

/// De service zelf. Hangt aan dezelfde outbox als profiel, beschikbaarheid en
/// feedback -- zie `AnalyticsService` voor waarom.

final class AnalyticsProvider extends $FunctionalProvider<
        AsyncValue<AnalyticsService>,
        AnalyticsService,
        FutureOr<AnalyticsService>>
    with $FutureModifier<AnalyticsService>, $FutureProvider<AnalyticsService> {
  /// De service zelf. Hangt aan dezelfde outbox als profiel, beschikbaarheid en
  /// feedback -- zie `AnalyticsService` voor waarom.
  AnalyticsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'analyticsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$analyticsHash();

  @$internal
  @override
  $FutureProviderElement<AnalyticsService> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AnalyticsService> create(Ref ref) {
    return analytics(ref);
  }
}

String _$analyticsHash() => r'5f02729fa36584df30f69daf476b17b1ebd19f44';
