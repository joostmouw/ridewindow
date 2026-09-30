// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_score_alerts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ScoreDropThreshold)
final scoreDropThresholdProvider = ScoreDropThresholdProvider._();

final class ScoreDropThresholdProvider
    extends $AsyncNotifierProvider<ScoreDropThreshold, int> {
  ScoreDropThresholdProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'scoreDropThresholdProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$scoreDropThresholdHash();

  @$internal
  @override
  ScoreDropThreshold create() => ScoreDropThreshold();
}

String _$scoreDropThresholdHash() =>
    r'3828a344d9f732dbe8cda611cb3d240a0d80cb25';

abstract class _$ScoreDropThreshold extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<int>, int>, AsyncValue<int>, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(rideScoreAlertService)
final rideScoreAlertServiceProvider = RideScoreAlertServiceProvider._();

final class RideScoreAlertServiceProvider extends $FunctionalProvider<
        AsyncValue<RideScoreAlerts>, RideScoreAlerts, FutureOr<RideScoreAlerts>>
    with $FutureModifier<RideScoreAlerts>, $FutureProvider<RideScoreAlerts> {
  RideScoreAlertServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'rideScoreAlertServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$rideScoreAlertServiceHash();

  @$internal
  @override
  $FutureProviderElement<RideScoreAlerts> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<RideScoreAlerts> create(Ref ref) {
    return rideScoreAlertService(ref);
  }
}

String _$rideScoreAlertServiceHash() =>
    r'5227255741dd710fea7e5ae26356c0ee7c8d8f58';

@ProviderFor(monitorRideScores)
final monitorRideScoresProvider = MonitorRideScoresProvider._();

final class MonitorRideScoresProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  MonitorRideScoresProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'monitorRideScoresProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$monitorRideScoresHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return monitorRideScores(ref);
  }
}

String _$monitorRideScoresHash() => r'7c8e80bfa742698529befe957bf795395e5a10ee';
