// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// De huidige tijd, als provider zodat hij in tests te overriden is.
///
/// De slot-pipeline knipt vensters weg die al begonnen zijn. Zonder deze
/// indirectie zou elke test die door `SlotsNotifier` heen loopt een fixture met
/// een vaste datum in het verleden moeten hebben — en die vallen dan allemaal
/// weg achter de cut-off.

@ProviderFor(now)
final nowProvider = NowProvider._();

/// De huidige tijd, als provider zodat hij in tests te overriden is.
///
/// De slot-pipeline knipt vensters weg die al begonnen zijn. Zonder deze
/// indirectie zou elke test die door `SlotsNotifier` heen loopt een fixture met
/// een vaste datum in het verleden moeten hebben — en die vallen dan allemaal
/// weg achter de cut-off.

final class NowProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// De huidige tijd, als provider zodat hij in tests te overriden is.
  ///
  /// De slot-pipeline knipt vensters weg die al begonnen zijn. Zonder deze
  /// indirectie zou elke test die door `SlotsNotifier` heen loopt een fixture met
  /// een vaste datum in het verleden moeten hebben — en die vallen dan allemaal
  /// weg achter de cut-off.
  NowProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'nowProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$nowHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return now(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$nowHash() => r'6ce0b0f491f51ecbcb4c9775ab2b7eab5f0d9d39';
