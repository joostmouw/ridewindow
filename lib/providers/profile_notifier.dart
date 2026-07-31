import 'dart:ui' as ui;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/data/repositories/profile_repository.dart';
import 'package:ridewindow/domain/models/weather_tolerances.dart';
import 'package:ridewindow/domain/models/user_profile.dart';

export 'package:ridewindow/domain/models/user_profile.dart' show UserProfile;

part 'profile_notifier.g.dart';

/// Construeert de [ProfileRepository]. Gebruikt bewust `getInstance()`
/// (asynchroon), niet `sharedPrefsProvider` -- die gooit `UnimplementedError`
/// tenzij overschreven, en de bestaande profiel-tests leunen allemaal op
/// `SharedPreferences.setMockInitialValues` in combinatie met `getInstance()`.
@riverpod
Future<ProfileRepository> profileRepository(Ref ref) async {
  return ProfileRepository(await SharedPreferences.getInstance());
}

/// ProfileNotifier laadt alle scalaire gebruikersinstellingen uit SharedPreferences
/// op cold start en schrijft iedere update direct terug.
///
/// Persistentie loopt via [ProfileRepository]. Deze notifier is een dunne
/// laag: hij houdt de publieke API en de mutatie-logica, de repository is de
/// enige plek die het opslagformaat kent.
///
/// Iedere mutatiemethode: (1) leest de huidige state, (2) bouwt nieuw
/// UserProfile via copyWith, (3) schrijft via de repository, (4) zet
/// state = AsyncData(next).
///
/// Volledig context-loos en testbaar via ProviderContainer.
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Future<UserProfile> build() async {
    final repo = await ref.watch(profileRepositoryProvider.future);
    return repo.readLocal(
      systemLanguageCode: ui.PlatformDispatcher.instance.locale.languageCode,
    );
  }

  /// Schrijft de vier tolerantie-waarden naar SharedPreferences en update state.
  Future<void> updateTolerances(WeatherTolerances tolerances) async {
    final current = await future;
    final next = current.copyWith(tolerances: tolerances);
    final repo = await ref.read(profileRepositoryProvider.future);
    await repo.save(next);
    state = AsyncData(next);
  }

  /// Togglet een rijduur: verwijdert als aanwezig, voegt toe als afwezig.
  /// Heeft geen effect als het de enige geselecteerde duur is (minstens één blijft).
  Future<void> toggleDuration(int duration) async {
    final current = await future;
    final durations = List<int>.from(current.allowedDurations);

    if (durations.contains(duration)) {
      // Verwijder alleen als er meer dan één geselecteerd is
      if (durations.length > 1) {
        durations.remove(duration);
      }
    } else {
      durations.add(duration);
      durations.sort();
    }

    final next = current.copyWith(allowedDurations: durations);
    final repo = await ref.read(profileRepositoryProvider.future);
    await repo.save(next);
    state = AsyncData(next);
  }

  /// Schrijft de taalvoorkeur ('nl'|'en') naar SharedPreferences en update state.
  Future<void> setLocale(String locale) async {
    final current = await future;
    final next = current.copyWith(locale: locale);
    final repo = await ref.read(profileRepositoryProvider.future);
    await repo.save(next);
    state = AsyncData(next);
  }

  /// Schrijft het thema ('system'|'light'|'dark') naar SharedPreferences en update state.
  Future<void> setTheme(String theme) async {
    final current = await future;
    final next = current.copyWith(theme: theme);
    final repo = await ref.read(profileRepositoryProvider.future);
    await repo.save(next);
    state = AsyncData(next);
  }

  /// Schrijft de locatie-override naar SharedPreferences en update state.
  /// Geef null door om de override te wissen.
  Future<void> setLocationOverride(String? location) async {
    final current = await future;
    final next = current.copyWith(locationOverride: location);
    final repo = await ref.read(profileRepositoryProvider.future);
    await repo.save(next);
    state = AsyncData(next);
  }

  /// Schrijft de gebruikersnaam naar SharedPreferences en update state.
  /// Door de gebruiker getypt -- dit pad stempelt `profile.updatedAt` wel.
  Future<void> setUserName(String? name) async {
    final current = await future;
    final trimmed = name?.trim().isEmpty == true ? null : name?.trim();
    final next = current.copyWith(userName: trimmed);
    final repo = await ref.read(profileRepositoryProvider.future);
    await repo.save(next);
    state = AsyncData(next);
  }

  /// Schrijft de gebruikersnaam naar SharedPreferences zonder `profile.updatedAt`
  /// te bewegen (D-07).
  ///
  /// Deze schrijfactie komt van de app -- de automatische invulling van de
  /// naam bij inloggen -- en niet van de gebruiker. Zou hij wel stempelen,
  /// dan leest fase 21 elk eerste inloggen op een nieuw toestel als een
  /// echte wijziging en toont hij een conflictdialoog terwijl er niets aan
  /// de hand is. Gebruik [setUserName] voor door de gebruiker getypte namen.
  Future<void> setUserNameFromSignIn(String? name) async {
    final current = await future;
    final trimmed = name?.trim().isEmpty == true ? null : name?.trim();
    final next = current.copyWith(userName: trimmed);
    final repo = await ref.read(profileRepositoryProvider.future);
    await repo.save(next, stamp: false);
    state = AsyncData(next);
  }

  /// Schrijft een notificatie-toggle naar SharedPreferences en update state.
  Future<void> setNotifEveningBefore(bool value) async {
    final current = await future;
    final next = current.copyWith(notifEveningBefore: value);
    final repo = await ref.read(profileRepositoryProvider.future);
    await repo.save(next);
    state = AsyncData(next);
  }

  /// Schrijft een notificatie-toggle naar SharedPreferences en update state.
  Future<void> setNotifMorningOf(bool value) async {
    final current = await future;
    final next = current.copyWith(notifMorningOf: value);
    final repo = await ref.read(profileRepositoryProvider.future);
    await repo.save(next);
    state = AsyncData(next);
  }

  /// Schrijft een notificatie-toggle naar SharedPreferences en update state.
  Future<void> setNotifWeeklyDigest(bool value) async {
    final current = await future;
    final next = current.copyWith(notifWeeklyDigest: value);
    final repo = await ref.read(profileRepositoryProvider.future);
    await repo.save(next);
    state = AsyncData(next);
  }

  /// Wist alle 12 profiel-sleutels uit SharedPreferences en herbouwt de
  /// state met dezelfde default-constructielogica als [build] gebruikt --
  /// zodat een reset bitwise-identiek is aan een verse installatie, niet een
  /// handmatig gekopieerde benadering die kan afwijken (D-09).
  Future<void> resetToDefaults() async {
    final repo = await ref.read(profileRepositoryProvider.future);
    await repo.resetToDefaults();

    final systemLang = ui.PlatformDispatcher.instance.locale.languageCode;
    state = AsyncData(
      UserProfile(
        tolerances: const WeatherTolerances(
          tempMinIdealC: 12.0,
          tempMaxIdealC: 26.0,
          windMaxIdealKmh: 15.0,
          rainMaxIdealMm: 0.5,
        ),
        allowedDurations: const [2, 3, 5],
        theme: 'system',
        locale: systemLang == 'nl' ? 'nl' : 'en',
        notifEveningBefore: false,
        notifMorningOf: false,
        notifWeeklyDigest: false,
      ),
    );
  }
}
