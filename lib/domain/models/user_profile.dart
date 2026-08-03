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

  /// Bouwt de Postgres-rij voor `public.profiles` (SYNC-01, SYNC-02).
  ///
  /// Exact de 13 kolommen die plan 21-02 op het live project heeft aangelegd
  /// (12 datakolommen + `user_id`) — `updated_at`/`created_at` horen hier
  /// bewust niet bij: de `BEFORE UPDATE`-trigger stempelt `updated_at`
  /// server-side, dus de client stuurt die nooit mee.
  Map<String, dynamic> toRow(String userId) => {
        'user_id': userId,
        'temp_min_ideal_c': tolerances.tempMinIdealC,
        'temp_max_ideal_c': tolerances.tempMaxIdealC,
        'wind_max_ideal_kmh': tolerances.windMaxIdealKmh,
        'rain_max_ideal_mm': tolerances.rainMaxIdealMm,
        'allowed_durations': allowedDurations,
        'theme': theme,
        'locale': locale,
        'location_override': locationOverride,
        'user_name': userName,
        'notif_evening_before': notifEveningBefore,
        'notif_morning_of': notifMorningOf,
        'notif_weekly_digest': notifWeeklyDigest,
      };

  /// Reconstrueert een [UserProfile] uit een cloud-rij van `public.profiles`.
  ///
  /// Anders dan [ProfileRepository.readLocal] wordt hier **niets** op een
  /// toestel-default teruggevallen: een cloud-rij is compleet of de
  /// aanroeper had al `null` teruggekregen van `maybeSingle()`. Elke kolom
  /// wordt rechtstreeks gelezen.
  factory UserProfile.fromRow(Map<String, dynamic> row) {
    return UserProfile(
      tolerances: WeatherTolerances(
        tempMinIdealC: (row['temp_min_ideal_c'] as num).toDouble(),
        tempMaxIdealC: (row['temp_max_ideal_c'] as num).toDouble(),
        windMaxIdealKmh: (row['wind_max_ideal_kmh'] as num).toDouble(),
        rainMaxIdealMm: (row['rain_max_ideal_mm'] as num).toDouble(),
      ),
      allowedDurations: (row['allowed_durations'] as List)
          .map((d) => (d as num).toInt())
          .toList(),
      theme: row['theme'] as String,
      locale: row['locale'] as String,
      locationOverride: row['location_override'] as String?,
      userName: row['user_name'] as String?,
      notifEveningBefore: row['notif_evening_before'] as bool,
      notifMorningOf: row['notif_morning_of'] as bool,
      notifWeeklyDigest: row['notif_weekly_digest'] as bool,
    );
  }

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
