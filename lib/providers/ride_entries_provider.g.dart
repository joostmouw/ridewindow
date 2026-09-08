// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_entries_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Alle aankomende ritten, uit alle vier de bronnen, in chronologische
/// volgorde en met jouw rol erbij.
///
/// **Eén provider en niet vier losse watches per scherm.** Home en het
/// rittenscherm lieten allebei hun eigen deelverzameling zien -- Home toonde
/// eigen plus geaccepteerde ritten, "Mijn ritten" alleen de eigen, en wat je
/// organiseerde stond op geen van beide. Drie schermen die zelf beslissen wat
/// een rit is, geven drie antwoorden op dezelfde vraag.
///
/// Bewust `.value ?? const []` en geen `AsyncValue`: de gedeelde ritten komen
/// van het netwerk en de persoonlijke van de schijf. Op één ontbrekende
/// cloud-aanroep de hele lijst laten wachten zou een uitgelogde of offline
/// gebruiker zijn eigen geplande ritten afnemen, en Peloton is additief
/// (REQUIREMENTS.md regel 8).

@ProviderFor(rideEntries)
final rideEntriesProvider = RideEntriesProvider._();

/// Alle aankomende ritten, uit alle vier de bronnen, in chronologische
/// volgorde en met jouw rol erbij.
///
/// **Eén provider en niet vier losse watches per scherm.** Home en het
/// rittenscherm lieten allebei hun eigen deelverzameling zien -- Home toonde
/// eigen plus geaccepteerde ritten, "Mijn ritten" alleen de eigen, en wat je
/// organiseerde stond op geen van beide. Drie schermen die zelf beslissen wat
/// een rit is, geven drie antwoorden op dezelfde vraag.
///
/// Bewust `.value ?? const []` en geen `AsyncValue`: de gedeelde ritten komen
/// van het netwerk en de persoonlijke van de schijf. Op één ontbrekende
/// cloud-aanroep de hele lijst laten wachten zou een uitgelogde of offline
/// gebruiker zijn eigen geplande ritten afnemen, en Peloton is additief
/// (REQUIREMENTS.md regel 8).

final class RideEntriesProvider extends $FunctionalProvider<List<RideEntry>,
    List<RideEntry>, List<RideEntry>> with $Provider<List<RideEntry>> {
  /// Alle aankomende ritten, uit alle vier de bronnen, in chronologische
  /// volgorde en met jouw rol erbij.
  ///
  /// **Eén provider en niet vier losse watches per scherm.** Home en het
  /// rittenscherm lieten allebei hun eigen deelverzameling zien -- Home toonde
  /// eigen plus geaccepteerde ritten, "Mijn ritten" alleen de eigen, en wat je
  /// organiseerde stond op geen van beide. Drie schermen die zelf beslissen wat
  /// een rit is, geven drie antwoorden op dezelfde vraag.
  ///
  /// Bewust `.value ?? const []` en geen `AsyncValue`: de gedeelde ritten komen
  /// van het netwerk en de persoonlijke van de schijf. Op één ontbrekende
  /// cloud-aanroep de hele lijst laten wachten zou een uitgelogde of offline
  /// gebruiker zijn eigen geplande ritten afnemen, en Peloton is additief
  /// (REQUIREMENTS.md regel 8).
  RideEntriesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'rideEntriesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$rideEntriesHash();

  @$internal
  @override
  $ProviderElement<List<RideEntry>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<RideEntry> create(Ref ref) {
    return rideEntries(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<RideEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<RideEntry>>(value),
    );
  }
}

String _$rideEntriesHash() => r'809a344e250dc75203d771ecb93390fe0930a5c1';
