// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AvailabilityNotifier beheert de set geblokkeerde uren als `Set<DateTime>`.
///
/// Persistentie via SharedPreferences: DateTime-waarden worden opgeslagen als
/// ISO-8601 strings onder de sleutel 'availability.blockedHours'.
///
/// Volledig context-loos en testbaar via ProviderContainer.

@ProviderFor(AvailabilityNotifier)
final availabilityProvider = AvailabilityNotifierProvider._();

/// AvailabilityNotifier beheert de set geblokkeerde uren als `Set<DateTime>`.
///
/// Persistentie via SharedPreferences: DateTime-waarden worden opgeslagen als
/// ISO-8601 strings onder de sleutel 'availability.blockedHours'.
///
/// Volledig context-loos en testbaar via ProviderContainer.
final class AvailabilityNotifierProvider
    extends $AsyncNotifierProvider<AvailabilityNotifier, Set<DateTime>> {
  /// AvailabilityNotifier beheert de set geblokkeerde uren als `Set<DateTime>`.
  ///
  /// Persistentie via SharedPreferences: DateTime-waarden worden opgeslagen als
  /// ISO-8601 strings onder de sleutel 'availability.blockedHours'.
  ///
  /// Volledig context-loos en testbaar via ProviderContainer.
  AvailabilityNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'availabilityProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$availabilityNotifierHash();

  @$internal
  @override
  AvailabilityNotifier create() => AvailabilityNotifier();
}

String _$availabilityNotifierHash() =>
    r'96b09c52562235bbb95c2790c17f829cddeaa532';

/// AvailabilityNotifier beheert de set geblokkeerde uren als `Set<DateTime>`.
///
/// Persistentie via SharedPreferences: DateTime-waarden worden opgeslagen als
/// ISO-8601 strings onder de sleutel 'availability.blockedHours'.
///
/// Volledig context-loos en testbaar via ProviderContainer.

abstract class _$AvailabilityNotifier extends $AsyncNotifier<Set<DateTime>> {
  FutureOr<Set<DateTime>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<DateTime>>, Set<DateTime>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<Set<DateTime>>, Set<DateTime>>,
        AsyncValue<Set<DateTime>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
