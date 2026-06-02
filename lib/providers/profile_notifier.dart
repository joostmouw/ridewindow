import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ridewindow/domain/models/weather_tolerances.dart';

part 'profile_notifier.g.dart';

/// Immutable data class die alle gebruikersinstellingen bevat.
/// Slaat WeatherTolerances op als nested object, rijlengte-voorkeuren als
/// `List<int>`, thema als String, en drie notificatie-toggles als bool.
class UserProfile {
  const UserProfile({
    required this.tolerances,
    required this.allowedDurations,
    required this.theme,
    this.locationOverride,
    required this.notifEveningBefore,
    required this.notifMorningOf,
    required this.notifWeeklyDigest,
  });

  final WeatherTolerances tolerances;
  final List<int> allowedDurations;
  final String theme;
  final String? locationOverride;
  final bool notifEveningBefore;
  final bool notifMorningOf;
  final bool notifWeeklyDigest;

  UserProfile copyWith({
    WeatherTolerances? tolerances,
    List<int>? allowedDurations,
    String? theme,
    Object? locationOverride = _sentinel,
    bool? notifEveningBefore,
    bool? notifMorningOf,
    bool? notifWeeklyDigest,
  }) {
    return UserProfile(
      tolerances: tolerances ?? this.tolerances,
      allowedDurations: allowedDurations ?? this.allowedDurations,
      theme: theme ?? this.theme,
      locationOverride: identical(locationOverride, _sentinel)
          ? this.locationOverride
          : locationOverride as String?,
      notifEveningBefore: notifEveningBefore ?? this.notifEveningBefore,
      notifMorningOf: notifMorningOf ?? this.notifMorningOf,
      notifWeeklyDigest: notifWeeklyDigest ?? this.notifWeeklyDigest,
    );
  }
}

/// Sentinel object voor nullable copyWith parameter.
const _sentinel = Object();

/// ProfileNotifier laadt alle scalaire gebruikersinstellingen uit SharedPreferences
/// op cold start en schrijft iedere update direct terug.
///
/// Iedere mutatiemethode: (1) schrijft naar SharedPreferences, (2) bouwt nieuw
/// UserProfile via copyWith, (3) zet state = AsyncData(next).
///
/// Volledig context-loos en testbaar via ProviderContainer.
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  static const _keyTempMin = 'profile.tempMinIdealC';
  static const _keyTempMax = 'profile.tempMaxIdealC';
  static const _keyWindMax = 'profile.windMaxIdealKmh';
  static const _keyRainMax = 'profile.rainMaxIdealMm';
  static const _keyDurations = 'profile.allowedDurations';
  static const _keyTheme = 'profile.theme';
  static const _keyLocation = 'profile.locationOverride';
  static const _keyNotifEvening = 'profile.notifEveningBefore';
  static const _keyNotifMorning = 'profile.notifMorningOf';
  static const _keyNotifWeekly = 'profile.notifWeeklyDigest';

  @override
  Future<UserProfile> build() async {
    final prefs = await SharedPreferences.getInstance();

    final tempMin = prefs.getDouble(_keyTempMin) ?? 12.0;
    final tempMax = prefs.getDouble(_keyTempMax) ?? 26.0;
    final windMax = prefs.getDouble(_keyWindMax) ?? 15.0;
    final rainMax = prefs.getDouble(_keyRainMax) ?? 0.5;

    final durationStrings =
        prefs.getStringList(_keyDurations) ?? ['2', '3', '5'];
    final durations = durationStrings
        .map((s) => int.tryParse(s) ?? 0)
        .where((d) => d > 0)
        .toList();

    final theme = prefs.getString(_keyTheme) ?? 'system';
    final locationOverride = prefs.getString(_keyLocation);
    final notifEvening = prefs.getBool(_keyNotifEvening) ?? false;
    final notifMorning = prefs.getBool(_keyNotifMorning) ?? false;
    final notifWeekly = prefs.getBool(_keyNotifWeekly) ?? false;

    return UserProfile(
      tolerances: WeatherTolerances(
        tempMinIdealC: tempMin,
        tempMaxIdealC: tempMax,
        windMaxIdealKmh: windMax,
        rainMaxIdealMm: rainMax,
      ),
      allowedDurations: durations.isEmpty ? [2, 3, 5] : durations,
      theme: theme,
      locationOverride: locationOverride,
      notifEveningBefore: notifEvening,
      notifMorningOf: notifMorning,
      notifWeeklyDigest: notifWeekly,
    );
  }

  /// Schrijft de vier tolerantie-waarden naar SharedPreferences en update state.
  Future<void> updateTolerances(WeatherTolerances tolerances) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyTempMin, tolerances.tempMinIdealC);
    await prefs.setDouble(_keyTempMax, tolerances.tempMaxIdealC);
    await prefs.setDouble(_keyWindMax, tolerances.windMaxIdealKmh);
    await prefs.setDouble(_keyRainMax, tolerances.rainMaxIdealMm);

    final current = await future;
    state = AsyncData(current.copyWith(tolerances: tolerances));
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyDurations,
      durations.map((d) => d.toString()).toList(),
    );

    state = AsyncData(current.copyWith(allowedDurations: durations));
  }

  /// Schrijft het thema ('system'|'light'|'dark') naar SharedPreferences en update state.
  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, theme);

    final current = await future;
    state = AsyncData(current.copyWith(theme: theme));
  }

  /// Schrijft de locatie-override naar SharedPreferences en update state.
  /// Geef null door om de override te wissen.
  Future<void> setLocationOverride(String? location) async {
    final prefs = await SharedPreferences.getInstance();
    if (location == null) {
      await prefs.remove(_keyLocation);
    } else {
      await prefs.setString(_keyLocation, location);
    }

    final current = await future;
    state = AsyncData(current.copyWith(locationOverride: location));
  }

  /// Schrijft een notificatie-toggle naar SharedPreferences en update state.
  Future<void> setNotifEveningBefore(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifEvening, value);

    final current = await future;
    state = AsyncData(current.copyWith(notifEveningBefore: value));
  }

  /// Schrijft een notificatie-toggle naar SharedPreferences en update state.
  Future<void> setNotifMorningOf(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifMorning, value);

    final current = await future;
    state = AsyncData(current.copyWith(notifMorningOf: value));
  }

  /// Schrijft een notificatie-toggle naar SharedPreferences en update state.
  Future<void> setNotifWeeklyDigest(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifWeekly, value);

    final current = await future;
    state = AsyncData(current.copyWith(notifWeeklyDigest: value));
  }
}
