// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AvailabilityNotifier beheert de geblokkeerde uren als `Map<DateTime, BlockType>`.
///
/// Persistentie via SharedPreferences: entries worden opgeslagen als
/// "ISO8601|blocktype" strings (bv. "2026-06-14T09:00:00.000Z|custom")
/// onder de sleutel 'availability.blockedHours'.
///
/// Volledig context-loos en testbaar via ProviderContainer.

@ProviderFor(AvailabilityNotifier)
final availabilityProvider = AvailabilityNotifierProvider._();

/// AvailabilityNotifier beheert de geblokkeerde uren als `Map<DateTime, BlockType>`.
///
/// Persistentie via SharedPreferences: entries worden opgeslagen als
/// "ISO8601|blocktype" strings (bv. "2026-06-14T09:00:00.000Z|custom")
/// onder de sleutel 'availability.blockedHours'.
///
/// Volledig context-loos en testbaar via ProviderContainer.
final class AvailabilityNotifierProvider extends $AsyncNotifierProvider<
    AvailabilityNotifier, Map<DateTime, BlockType>> {
  /// AvailabilityNotifier beheert de geblokkeerde uren als `Map<DateTime, BlockType>`.
  ///
  /// Persistentie via SharedPreferences: entries worden opgeslagen als
  /// "ISO8601|blocktype" strings (bv. "2026-06-14T09:00:00.000Z|custom")
  /// onder de sleutel 'availability.blockedHours'.
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
    r'bdb0a3c743ccb3acba8e7b2a53b878324261c86b';

/// AvailabilityNotifier beheert de geblokkeerde uren als `Map<DateTime, BlockType>`.
///
/// Persistentie via SharedPreferences: entries worden opgeslagen als
/// "ISO8601|blocktype" strings (bv. "2026-06-14T09:00:00.000Z|custom")
/// onder de sleutel 'availability.blockedHours'.
///
/// Volledig context-loos en testbaar via ProviderContainer.

abstract class _$AvailabilityNotifier
    extends $AsyncNotifier<Map<DateTime, BlockType>> {
  FutureOr<Map<DateTime, BlockType>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref
        as $Ref<AsyncValue<Map<DateTime, BlockType>>, Map<DateTime, BlockType>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<Map<DateTime, BlockType>>,
            Map<DateTime, BlockType>>,
        AsyncValue<Map<DateTime, BlockType>>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
