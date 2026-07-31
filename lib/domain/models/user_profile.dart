import 'package:ridewindow/domain/models/weather_tolerances.dart';

/// Immutable data class die alle gebruikersinstellingen bevat.
/// Slaat WeatherTolerances op als nested object, rijlengte-voorkeuren als
/// `List<int>`, thema als String, en drie notificatie-toggles als bool.
class UserProfile {
  const UserProfile({
    required this.tolerances,
    required this.allowedDurations,
    required this.theme,
    this.locale = 'nl',
    this.locationOverride,
    this.userName,
    required this.notifEveningBefore,
    required this.notifMorningOf,
    required this.notifWeeklyDigest,
  });

  final WeatherTolerances tolerances;
  final List<int> allowedDurations;
  final String theme;
  final String locale; // 'nl' or 'en'
  final String? locationOverride;
  final String? userName;
  final bool notifEveningBefore;
  final bool notifMorningOf;
  final bool notifWeeklyDigest;

  UserProfile copyWith({
    WeatherTolerances? tolerances,
    List<int>? allowedDurations,
    String? theme,
    String? locale,
    Object? locationOverride = _sentinel,
    Object? userName = _sentinel,
    bool? notifEveningBefore,
    bool? notifMorningOf,
    bool? notifWeeklyDigest,
  }) {
    return UserProfile(
      tolerances: tolerances ?? this.tolerances,
      allowedDurations: allowedDurations ?? this.allowedDurations,
      theme: theme ?? this.theme,
      locale: locale ?? this.locale,
      locationOverride: identical(locationOverride, _sentinel)
          ? this.locationOverride
          : locationOverride as String?,
      userName: identical(userName, _sentinel)
          ? this.userName
          : userName as String?,
      notifEveningBefore: notifEveningBefore ?? this.notifEveningBefore,
      notifMorningOf: notifMorningOf ?? this.notifMorningOf,
      notifWeeklyDigest: notifWeeklyDigest ?? this.notifWeeklyDigest,
    );
  }
}

/// Sentinel object voor nullable copyWith parameter.
const _sentinel = Object();
