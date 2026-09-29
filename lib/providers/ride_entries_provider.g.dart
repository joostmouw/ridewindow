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
/// Telt niet meer mee in het bolletje; dat telt [UnseenRideInvites].

@ProviderFor(unansweredRideCount)
final unansweredRideCountProvider = UnansweredRideCountProvider._();

/// Hoeveel ritten er op jouw antwoord wachten: losse uitnodigingen plus
/// groepsritten zonder jouw rij, alleen wat nog niet voorbij is.
///
/// Telt niet meer mee in het bolletje; dat telt [UnseenRideInvites].

final class UnansweredRideCountProvider
    extends $FunctionalProvider<int, int, int> with $Provider<int> {
  /// Hoeveel ritten er op jouw antwoord wachten: losse uitnodigingen plus
  /// groepsritten zonder jouw rij, alleen wat nog niet voorbij is.
  ///
  /// Telt niet meer mee in het bolletje; dat telt [UnseenRideInvites].
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
    r'5a55bb17df188e8a1b922aa87c6ffdbfb65e72b6';

/// De sleutels achter [unansweredRideCount].

@ProviderFor(pendingRideKeys)
final pendingRideKeysProvider = PendingRideKeysProvider._();

/// De sleutels achter [unansweredRideCount].

final class PendingRideKeysProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  /// De sleutels achter [unansweredRideCount].
  PendingRideKeysProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pendingRideKeysProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pendingRideKeysHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return pendingRideKeys(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$pendingRideKeysHash() => r'3b696f56be7378d06a96e818e158c397c5111a77';

/// De ritvragen die je nog niet op de tab Ritten zag. Zie [SeenIdsStore] voor
/// waarom gezien genoeg is: de kaart zelf blijft "vraagt je mee" zeggen tot je
/// antwoordt.

@ProviderFor(UnseenRideInvites)
final unseenRideInvitesProvider = UnseenRideInvitesProvider._();

/// De ritvragen die je nog niet op de tab Ritten zag. Zie [SeenIdsStore] voor
/// waarom gezien genoeg is: de kaart zelf blijft "vraagt je mee" zeggen tot je
/// antwoordt.
final class UnseenRideInvitesProvider
    extends $AsyncNotifierProvider<UnseenRideInvites, Set<String>> {
  /// De ritvragen die je nog niet op de tab Ritten zag. Zie [SeenIdsStore] voor
  /// waarom gezien genoeg is: de kaart zelf blijft "vraagt je mee" zeggen tot je
  /// antwoordt.
  UnseenRideInvitesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'unseenRideInvitesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$unseenRideInvitesHash();

  @$internal
  @override
  UnseenRideInvites create() => UnseenRideInvites();
}

String _$unseenRideInvitesHash() => r'af42593f475cd00f6b2e4a16321004ac06583029';

/// De ritvragen die je nog niet op de tab Ritten zag. Zie [SeenIdsStore] voor
/// waarom gezien genoeg is: de kaart zelf blijft "vraagt je mee" zeggen tot je
/// antwoordt.

abstract class _$UnseenRideInvites extends $AsyncNotifier<Set<String>> {
  FutureOr<Set<String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<String>>, Set<String>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<Set<String>>, Set<String>>,
        AsyncValue<Set<String>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

/// Het getal op de tab Ritten: ritvragen die je nog niet zag.

@ProviderFor(ridesTabAttentionCount)
final ridesTabAttentionCountProvider = RidesTabAttentionCountProvider._();

/// Het getal op de tab Ritten: ritvragen die je nog niet zag.

final class RidesTabAttentionCountProvider
    extends $FunctionalProvider<int, int, int> with $Provider<int> {
  /// Het getal op de tab Ritten: ritvragen die je nog niet zag.
  RidesTabAttentionCountProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'ridesTabAttentionCountProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$ridesTabAttentionCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return ridesTabAttentionCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$ridesTabAttentionCountHash() =>
    r'c25a040907240aa9203092569ebf0c463f5de484';

/// Het getal op de tab Peloton: groepsaanvragen en maatjes die je nog niet
/// zag.

@ProviderFor(pelotonTabAttentionCount)
final pelotonTabAttentionCountProvider = PelotonTabAttentionCountProvider._();

/// Het getal op de tab Peloton: groepsaanvragen en maatjes die je nog niet
/// zag.

final class PelotonTabAttentionCountProvider
    extends $FunctionalProvider<int, int, int> with $Provider<int> {
  /// Het getal op de tab Peloton: groepsaanvragen en maatjes die je nog niet
  /// zag.
  PelotonTabAttentionCountProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pelotonTabAttentionCountProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pelotonTabAttentionCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return pelotonTabAttentionCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$pelotonTabAttentionCountHash() =>
    r'67d534a29009178a0875df5f9b825beb0647c95f';

/// Het getal in het rode bolletje op Ritten in de onderbalk: de som van de
/// twee tabs.
///
/// **Elk bolletje staat op de tab waar het over gaat.** Tot build 61 las de
/// tab Peloton dit hele getal, ook de ritvragen die op de tab Ritten staan. In
/// de video van 29 september bleef "Peloton 1" daardoor staan terwijl Joost
/// naar zijn maatjes keek: de 1 was een ritvraag van Richard. En het telde
/// wat op antwoord wachtte in plaats van wat je nog niet zag.
///
/// Groepsaanvragen tellen mee sinds 2026-09-26 (Joost): zonder pushmeldingen
/// is er geen andere plek waar een beheerder ze ziet zonder de groep te
/// openen.

@ProviderFor(pelotonAttentionCount)
final pelotonAttentionCountProvider = PelotonAttentionCountProvider._();

/// Het getal in het rode bolletje op Ritten in de onderbalk: de som van de
/// twee tabs.
///
/// **Elk bolletje staat op de tab waar het over gaat.** Tot build 61 las de
/// tab Peloton dit hele getal, ook de ritvragen die op de tab Ritten staan. In
/// de video van 29 september bleef "Peloton 1" daardoor staan terwijl Joost
/// naar zijn maatjes keek: de 1 was een ritvraag van Richard. En het telde
/// wat op antwoord wachtte in plaats van wat je nog niet zag.
///
/// Groepsaanvragen tellen mee sinds 2026-09-26 (Joost): zonder pushmeldingen
/// is er geen andere plek waar een beheerder ze ziet zonder de groep te
/// openen.

final class PelotonAttentionCountProvider
    extends $FunctionalProvider<int, int, int> with $Provider<int> {
  /// Het getal in het rode bolletje op Ritten in de onderbalk: de som van de
  /// twee tabs.
  ///
  /// **Elk bolletje staat op de tab waar het over gaat.** Tot build 61 las de
  /// tab Peloton dit hele getal, ook de ritvragen die op de tab Ritten staan. In
  /// de video van 29 september bleef "Peloton 1" daardoor staan terwijl Joost
  /// naar zijn maatjes keek: de 1 was een ritvraag van Richard. En het telde
  /// wat op antwoord wachtte in plaats van wat je nog niet zag.
  ///
  /// Groepsaanvragen tellen mee sinds 2026-09-26 (Joost): zonder pushmeldingen
  /// is er geen andere plek waar een beheerder ze ziet zonder de groep te
  /// openen.
  PelotonAttentionCountProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pelotonAttentionCountProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pelotonAttentionCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return pelotonAttentionCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$pelotonAttentionCountHash() =>
    r'f4022d99e9ecf9084d6da70798159aa6e0a298d7';
