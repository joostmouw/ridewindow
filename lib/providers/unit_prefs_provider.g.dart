// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit_prefs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// De gekozen eenheden, en de enige plek die ze verandert.
///
/// Synchroon leesbaar na de eerste laadbeurt, want elk scherm dat een getal
/// toont heeft ze nodig: een `AsyncValue` zou betekenen dat elke weerbalk een
/// laadtoestand moet kunnen tekenen voor een instelling die in microseconden
/// van schijf komt. Vandaar dezelfde vorm als `profile_notifier.dart`:
/// `getInstance()` binnen `build`, en daarna gewone waarden.

@ProviderFor(UnitPrefsNotifier)
final unitPrefsProvider = UnitPrefsNotifierProvider._();

/// De gekozen eenheden, en de enige plek die ze verandert.
///
/// Synchroon leesbaar na de eerste laadbeurt, want elk scherm dat een getal
/// toont heeft ze nodig: een `AsyncValue` zou betekenen dat elke weerbalk een
/// laadtoestand moet kunnen tekenen voor een instelling die in microseconden
/// van schijf komt. Vandaar dezelfde vorm als `profile_notifier.dart`:
/// `getInstance()` binnen `build`, en daarna gewone waarden.
final class UnitPrefsNotifierProvider
    extends $AsyncNotifierProvider<UnitPrefsNotifier, UnitPrefs> {
  /// De gekozen eenheden, en de enige plek die ze verandert.
  ///
  /// Synchroon leesbaar na de eerste laadbeurt, want elk scherm dat een getal
  /// toont heeft ze nodig: een `AsyncValue` zou betekenen dat elke weerbalk een
  /// laadtoestand moet kunnen tekenen voor een instelling die in microseconden
  /// van schijf komt. Vandaar dezelfde vorm als `profile_notifier.dart`:
  /// `getInstance()` binnen `build`, en daarna gewone waarden.
  UnitPrefsNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'unitPrefsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$unitPrefsNotifierHash();

  @$internal
  @override
  UnitPrefsNotifier create() => UnitPrefsNotifier();
}

String _$unitPrefsNotifierHash() => r'16962a3af0c49300f985b980b73cfa5b5973a6df';

/// De gekozen eenheden, en de enige plek die ze verandert.
///
/// Synchroon leesbaar na de eerste laadbeurt, want elk scherm dat een getal
/// toont heeft ze nodig: een `AsyncValue` zou betekenen dat elke weerbalk een
/// laadtoestand moet kunnen tekenen voor een instelling die in microseconden
/// van schijf komt. Vandaar dezelfde vorm als `profile_notifier.dart`:
/// `getInstance()` binnen `build`, en daarna gewone waarden.

abstract class _$UnitPrefsNotifier extends $AsyncNotifier<UnitPrefs> {
  FutureOr<UnitPrefs> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UnitPrefs>, UnitPrefs>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<UnitPrefs>, UnitPrefs>,
        AsyncValue<UnitPrefs>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

/// Wat een scherm werkelijk nodig heeft: de eenheden, of de standaard zolang
/// ze nog geladen worden. Een weerbalk die op een instelling wacht, is een
/// weerbalk die knippert.

@ProviderFor(units)
final unitsProvider = UnitsProvider._();

/// Wat een scherm werkelijk nodig heeft: de eenheden, of de standaard zolang
/// ze nog geladen worden. Een weerbalk die op een instelling wacht, is een
/// weerbalk die knippert.

final class UnitsProvider
    extends $FunctionalProvider<UnitPrefs, UnitPrefs, UnitPrefs>
    with $Provider<UnitPrefs> {
  /// Wat een scherm werkelijk nodig heeft: de eenheden, of de standaard zolang
  /// ze nog geladen worden. Een weerbalk die op een instelling wacht, is een
  /// weerbalk die knippert.
  UnitsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'unitsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$unitsHash();

  @$internal
  @override
  $ProviderElement<UnitPrefs> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UnitPrefs create(Ref ref) {
    return units(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UnitPrefs value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UnitPrefs>(value),
    );
  }
}

String _$unitsHash() => r'3c6f539bcd83bc7067129946f79518b054bd9b68';
