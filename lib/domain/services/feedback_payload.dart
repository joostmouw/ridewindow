// lib/domain/services/feedback_payload.dart
// Bouwt de rij die naar `public.feedback` gaat. Puur, zodat de vorm ervan
// toetsbaar is zonder Supabase, een netwerk of een widgetboom.

import 'package:ridewindow/domain/models/hourly_forecast.dart';
import 'package:ridewindow/domain/models/ride_slot.dart';
import 'package:ridewindow/domain/models/user_profile.dart';

/// De context die automatisch met feedback meegaat (FB-02).
///
/// **Waarom dit een aparte, pure functie is.** Feedback zonder context is
/// "de score klopte niet" zonder dat iemand kan nagaan wélke score, bij welk
/// weer, en met welke persoonlijke grenzen. Precies die drie samen maken een
/// melding bruikbaar -- en ze zijn achteraf niet te reconstrueren, want het
/// weerbericht van vorige week is weg en de gebruiker heeft zijn schuifjes
/// intussen misschien verzet. Vandaar dat ze op het moment van versturen
/// worden ingevroren.
///
/// Wat er bewust **niet** in zit: geen locatie op coördinaatniveau (alleen de
/// stadsnaam die de gebruiker zelf ziet), geen e-mailadres, geen uid. Het uid
/// staat al in de kolom `user_id` wanneer iemand is ingelogd, en verder heeft
/// niemand iets aan persoonsgegevens in een vrij tekstveld.
Map<String, dynamic> buildFeedbackContext({
  required UserProfile profile,
  RideSlot? topSlot,
  List<HourlyForecast> slotForecasts = const [],
  String? city,
  required String appVersion,
  required String platform,
}) {
  final t = profile.tolerances;
  return {
    'app_version': appVersion,
    'platform': platform,
    'locale': profile.locale,
    'city': city,
    // De grenzen van de gebruiker zelf. Zonder deze is een score niet te
    // beoordelen: 18 graden is voor de een perfect en voor de ander koud.
    'tolerances': {
      'temp_min_ideal_c': t.tempMinIdealC,
      'temp_max_ideal_c': t.tempMaxIdealC,
      'wind_max_ideal_kmh': t.windMaxIdealKmh,
      'rain_max_ideal_mm': t.rainMaxIdealMm,
      'allowed_durations': profile.allowedDurations,
    },
    // Het venster waar de gebruiker naar kijkt op het moment van versturen,
    // plus het weer waaruit die score is berekend. `null` als er geen enkel
    // venster is -- dat is zelf ook informatie: feedback bij een lege lijst
    // gaat waarschijnlijk over precies dat.
    'top_slot': topSlot == null
        ? null
        : {
            'start': topSlot.start.toUtc().toIso8601String(),
            'end': topSlot.end.toUtc().toIso8601String(),
            'score': topSlot.overallScore,
            'weather': [
              for (final f in slotForecasts)
                {
                  'time': f.time.toUtc().toIso8601String(),
                  'temp_c': f.temperatureC,
                  'feels_like_c': f.apparentTemperatureC,
                  'precip_mm': f.precipitationMm,
                  'wind_kmh': f.windspeedKmh,
                },
            ],
          },
  };
}

/// De volledige rij voor `public.feedback`.
///
/// [userId] is `null` voor een uitgelogde gebruiker. Dat is geen randgeval maar
/// een eis (FB-03): feedback die alleen van ingelogde gebruikers komt, komt van
/// een minderheid, en juist wie nog geen account nam heeft vaak het meest te
/// melden. De insertpolicy staat `user_id is null` expliciet toe.
///
/// [id] wordt door de client gezet en niet door de database, omdat de rij eerst
/// in de lokale outbox belandt (FB-04). De outbox sleutelt op die id, zodat twee
/// keer versturen twee rijen oplevert en een herhaalde poging na een mislukte
/// verzending er precies één.
Map<String, dynamic> buildFeedbackRow({
  required String id,
  required String? userId,
  required int rating,
  required String comment,
  required Map<String, dynamic> context,
}) {
  final trimmed = comment.trim();
  return {
    'id': id,
    'user_id': userId,
    'rating': rating,
    'comment': trimmed.isEmpty ? null : trimmed,
    'context': context,
  };
}
