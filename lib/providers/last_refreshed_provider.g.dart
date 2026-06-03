// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_refreshed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Leest de lastRefreshed timestamp uit SharedPreferences.
/// Retourneert null als er nog nooit een fetch is geweest.
/// Gegenereerde naam: lastRefreshedProvider

@ProviderFor(LastRefreshedNotifier)
final lastRefreshedProvider = LastRefreshedNotifierProvider._();

/// Leest de lastRefreshed timestamp uit SharedPreferences.
/// Retourneert null als er nog nooit een fetch is geweest.
/// Gegenereerde naam: lastRefreshedProvider
final class LastRefreshedNotifierProvider
    extends $AsyncNotifierProvider<LastRefreshedNotifier, DateTime?> {
  /// Leest de lastRefreshed timestamp uit SharedPreferences.
  /// Retourneert null als er nog nooit een fetch is geweest.
  /// Gegenereerde naam: lastRefreshedProvider
  LastRefreshedNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'lastRefreshedProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$lastRefreshedNotifierHash();

  @$internal
  @override
  LastRefreshedNotifier create() => LastRefreshedNotifier();
}

String _$lastRefreshedNotifierHash() =>
    r'722ab3c99effdcf876381b04ee1ff69bb05c1e95';

/// Leest de lastRefreshed timestamp uit SharedPreferences.
/// Retourneert null als er nog nooit een fetch is geweest.
/// Gegenereerde naam: lastRefreshedProvider

abstract class _$LastRefreshedNotifier extends $AsyncNotifier<DateTime?> {
  FutureOr<DateTime?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DateTime?>, DateTime?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<DateTime?>, DateTime?>,
        AsyncValue<DateTime?>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
