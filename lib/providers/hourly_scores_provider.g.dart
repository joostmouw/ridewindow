// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hourly_scores_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Exposes scored hourly weather data for ALL forecast hours (not just slot hours).
/// Used by the agenda screen to color every hour block.

@ProviderFor(allHourlyScores)
final allHourlyScoresProvider = AllHourlyScoresProvider._();

/// Exposes scored hourly weather data for ALL forecast hours (not just slot hours).
/// Used by the agenda screen to color every hour block.

final class AllHourlyScoresProvider extends $FunctionalProvider<
    List<HourlyScore>,
    List<HourlyScore>,
    List<HourlyScore>> with $Provider<List<HourlyScore>> {
  /// Exposes scored hourly weather data for ALL forecast hours (not just slot hours).
  /// Used by the agenda screen to color every hour block.
  AllHourlyScoresProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'allHourlyScoresProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$allHourlyScoresHash();

  @$internal
  @override
  $ProviderElement<List<HourlyScore>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<HourlyScore> create(Ref ref) {
    return allHourlyScores(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<HourlyScore> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<HourlyScore>>(value),
    );
  }
}

String _$allHourlyScoresHash() => r'00f9043518f73f62251cb9ce86a09b3c61851141';
