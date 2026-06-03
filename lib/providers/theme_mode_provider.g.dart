// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Zet profile.theme (String) om naar ThemeMode.
/// Hercomputed automatisch als profileProvider een nieuwe waarde emitteert.
/// Valt terug op ThemeMode.system als de provider nog laadt of een fout heeft.

@ProviderFor(themeMode)
final themeModeProvider = ThemeModeProvider._();

/// Zet profile.theme (String) om naar ThemeMode.
/// Hercomputed automatisch als profileProvider een nieuwe waarde emitteert.
/// Valt terug op ThemeMode.system als de provider nog laadt of een fout heeft.

final class ThemeModeProvider
    extends $FunctionalProvider<ThemeMode, ThemeMode, ThemeMode>
    with $Provider<ThemeMode> {
  /// Zet profile.theme (String) om naar ThemeMode.
  /// Hercomputed automatisch als profileProvider een nieuwe waarde emitteert.
  /// Valt terug op ThemeMode.system als de provider nog laadt of een fout heeft.
  ThemeModeProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'themeModeProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$themeModeHash();

  @$internal
  @override
  $ProviderElement<ThemeMode> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThemeMode create(Ref ref) {
    return themeMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$themeModeHash() => r'b2058b1bb73e9a672ce22dd7fc28ed7b1d13d5e4';
