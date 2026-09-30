// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_window_scorer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ook tijdens een refresh dezelfde laatst bekende voorspelling blijven
/// gebruiken. De weersfout staat al op Home; terugveren naar de planscore
/// zou een verslechterde rit ineens weer goed laten lijken.

@ProviderFor(rideWindowScorer)
final rideWindowScorerProvider = RideWindowScorerProvider._();

/// Ook tijdens een refresh dezelfde laatst bekende voorspelling blijven
/// gebruiken. De weersfout staat al op Home; terugveren naar de planscore
/// zou een verslechterde rit ineens weer goed laten lijken.

final class RideWindowScorerProvider extends $FunctionalProvider<
    RideWindowScorer?,
    RideWindowScorer?,
    RideWindowScorer?> with $Provider<RideWindowScorer?> {
  /// Ook tijdens een refresh dezelfde laatst bekende voorspelling blijven
  /// gebruiken. De weersfout staat al op Home; terugveren naar de planscore
  /// zou een verslechterde rit ineens weer goed laten lijken.
  RideWindowScorerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'rideWindowScorerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$rideWindowScorerHash();

  @$internal
  @override
  $ProviderElement<RideWindowScorer?> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RideWindowScorer? create(Ref ref) {
    return rideWindowScorer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RideWindowScorer? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RideWindowScorer?>(value),
    );
  }
}

String _$rideWindowScorerHash() => r'384f8ad7e08c2174092e74778ff22b862e8db980';
