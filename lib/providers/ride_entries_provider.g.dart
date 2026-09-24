// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_entries_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Alle aankomende ritten, uit alle vijf de bronnen, in chronologische
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

/// Alle aankomende ritten, uit alle vijf de bronnen, in chronologische
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
  /// Alle aankomende ritten, uit alle vijf de bronnen, in chronologische
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

String _$rideEntriesHash() => r'f31a206e0eb523606fa0e5986f8439e72bb65b9f';

/// Hoeveel ritten er op jouw antwoord wachten: losse uitnodigingen plus
/// groepsritten zonder jouw rij, alleen wat nog niet voorbij is.
///
/// CLUB-25 optie A (schets 016): de onderbalk en de Peloton-tab lezen allebei
/// dit getal, zodat ze nooit iets anders zeggen. Open groepsaanvragen voor
/// beheerders tellen bewust niet mee; die staan op de groepskaart (34-05,
/// bevestigd door Joost 2026-09-24).

@ProviderFor(unansweredRideCount)
final unansweredRideCountProvider = UnansweredRideCountProvider._();

/// Hoeveel ritten er op jouw antwoord wachten: losse uitnodigingen plus
/// groepsritten zonder jouw rij, alleen wat nog niet voorbij is.
///
/// CLUB-25 optie A (schets 016): de onderbalk en de Peloton-tab lezen allebei
/// dit getal, zodat ze nooit iets anders zeggen. Open groepsaanvragen voor
/// beheerders tellen bewust niet mee; die staan op de groepskaart (34-05,
/// bevestigd door Joost 2026-09-24).

final class UnansweredRideCountProvider
    extends $FunctionalProvider<int, int, int> with $Provider<int> {
  /// Hoeveel ritten er op jouw antwoord wachten: losse uitnodigingen plus
  /// groepsritten zonder jouw rij, alleen wat nog niet voorbij is.
  ///
  /// CLUB-25 optie A (schets 016): de onderbalk en de Peloton-tab lezen allebei
  /// dit getal, zodat ze nooit iets anders zeggen. Open groepsaanvragen voor
  /// beheerders tellen bewust niet mee; die staan op de groepskaart (34-05,
  /// bevestigd door Joost 2026-09-24).
  UnansweredRideCountProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'unansweredRideCountProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$unansweredRideCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return unansweredRideCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$unansweredRideCountHash() =>
    r'7e8a77d5ea14db69746e6fee609224d90c026df6';
