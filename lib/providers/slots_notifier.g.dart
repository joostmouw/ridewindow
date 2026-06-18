// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slots_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SlotsNotifier combineert weer, profiel en beschikbaarheid tot gefilterde
/// `List<RideSlot>`. Riverpod hercomputed automatisch als een van de drie
/// providers een nieuwe waarde emit — geen handmatige refresh nodig.
///
/// Gebruikt synchrone `Notifier<SlotsState>` zodat de UI nooit hoeft te wachten
/// op een Future; loading-propagatie wordt via het [SlotsLoaded] leeg-pad gedaan.

@ProviderFor(SlotsNotifier)
final slotsProvider = SlotsNotifierProvider._();

/// SlotsNotifier combineert weer, profiel en beschikbaarheid tot gefilterde
/// `List<RideSlot>`. Riverpod hercomputed automatisch als een van de drie
/// providers een nieuwe waarde emit — geen handmatige refresh nodig.
///
/// Gebruikt synchrone `Notifier<SlotsState>` zodat de UI nooit hoeft te wachten
/// op een Future; loading-propagatie wordt via het [SlotsLoaded] leeg-pad gedaan.
final class SlotsNotifierProvider
    extends $NotifierProvider<SlotsNotifier, SlotsState> {
  /// SlotsNotifier combineert weer, profiel en beschikbaarheid tot gefilterde
  /// `List<RideSlot>`. Riverpod hercomputed automatisch als een van de drie
  /// providers een nieuwe waarde emit — geen handmatige refresh nodig.
  ///
  /// Gebruikt synchrone `Notifier<SlotsState>` zodat de UI nooit hoeft te wachten
  /// op een Future; loading-propagatie wordt via het [SlotsLoaded] leeg-pad gedaan.
  SlotsNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'slotsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$slotsNotifierHash();

  @$internal
  @override
  SlotsNotifier create() => SlotsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SlotsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SlotsState>(value),
    );
  }
}

String _$slotsNotifierHash() => r'ea9f6997826a83faab920f9620e505cca6add8c8';

/// SlotsNotifier combineert weer, profiel en beschikbaarheid tot gefilterde
/// `List<RideSlot>`. Riverpod hercomputed automatisch als een van de drie
/// providers een nieuwe waarde emit — geen handmatige refresh nodig.
///
/// Gebruikt synchrone `Notifier<SlotsState>` zodat de UI nooit hoeft te wachten
/// op een Future; loading-propagatie wordt via het [SlotsLoaded] leeg-pad gedaan.

abstract class _$SlotsNotifier extends $Notifier<SlotsState> {
  SlotsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SlotsState, SlotsState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<SlotsState, SlotsState>, SlotsState, Object?, Object?>;
    element.handleCreate(ref, build);
  }
}
