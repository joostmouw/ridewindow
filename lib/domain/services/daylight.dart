/// Zonsopgang en zonsondergang, lokaal uitgerekend.
///
/// **Waarom dit hier staat en niet uit Open-Meteo komt.** Open-Meteo levert
/// `daily=sunrise,sunset` gratis mee, maar dan zou het bewaard moeten worden:
/// de voorspelling wordt in Drift gecachet als een rij per uur, en zon-tijden
/// zijn per dag. Dat is een nieuwe tabel plus een migratie, voor een getal dat
/// alleen van breedtegraad en datum afhangt en dus net zo goed te berekenen is.
/// Lokaal rekenen werkt bovendien op de gecachete voorspelling én offline, en
/// het levert de exacte minuut in plaats van het uur waarin de zon ondergaat.
///
/// **Waarom de zonshoogte en niet de zonsopgangsvergelijking.** De eerste twee
/// versies van dit bestand gebruikten de gesloten formule uit die vergelijking.
/// Die zat er tot 175 seconden naast op Tromsø en 104 in Amsterdam, en de fout
/// groeide met de breedtegraad en rond de equinox — de declinatie verschuift
/// daar ~0,4° per dag, en één waarde voor de hele dag is dan niet goed genoeg,
/// ook niet na twee iteraties. Deze versie rekent de werkelijke hoogte van de
/// zon uit en zoekt het moment waarop die de horizon kruist. Dat is meer werk
/// per aanroep en een orde nauwkeuriger: `daylight_test.dart` toetst hem tegen
/// de waarden die Open-Meteo zelf teruggeeft, voor vier plaatsen van Tromsø tot
/// Sydney, en de afwijking blijft binnen een minuut.
library;

import 'dart:math' as math;

const double _deg = math.pi / 180;
const double _rad = 180 / math.pi;

/// De hoogte waarop de zon "op" of "onder" heet te gaan: de bovenrand raakt de
/// horizon (-0,267°) en de atmosfeer buigt het licht daar nog eens ~0,566°
/// overheen. Samen de conventionele -0,833°.
const double _horizonAltitudeDeg = -0.833;

/// De hoogte van de zon boven de horizon, in graden, op [utc].
///
/// Lage-precisiereeks uit de Astronomical Almanac: goed tot ongeveer 0,01°,
/// ruim genoeg voor een tijdstip op de seconde.
double solarAltitudeDeg({
  required double latitude,
  required double longitude,
  required DateTime utc,
}) {
  final jd = utc.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
  final n = jd - 2451545.0;

  final meanLongitude = (280.460 + 0.9856474 * n) % 360.0;
  final meanAnomaly = ((357.528 + 0.9856003 * n) % 360.0) * _deg;
  final lambda = (meanLongitude +
          1.915 * math.sin(meanAnomaly) +
          0.020 * math.sin(2 * meanAnomaly)) *
      _deg;
  final obliquity = (23.439 - 0.0000004 * n) * _deg;

  final rightAscension = math.atan2(
    math.cos(obliquity) * math.sin(lambda),
    math.cos(lambda),
  );
  final declination = math.asin(math.sin(obliquity) * math.sin(lambda));

  // Greenwich-sterrentijd, en daarmee de uurhoek van de zon op deze lengtegraad.
  final gmstDeg = (280.46061837 + 360.98564736629 * n) % 360.0;
  final hourAngle =
      ((gmstDeg + longitude - rightAscension * _rad) % 360.0) * _deg;

  final phi = latitude * _deg;
  final sinAltitude = math.sin(phi) * math.sin(declination) +
      math.cos(phi) * math.cos(declination) * math.cos(hourAngle);
  return math.asin(sinAltitude.clamp(-1.0, 1.0)) * _rad;
}

/// Zonsopgang en -ondergang voor de kalenderdag waar [dayLocal] in valt.
///
/// [dayLocal] hoeft alleen de juiste dag aan te duiden; het tijdstip erin doet
/// niet mee. De teruggegeven momenten staan in dezelfde tijdzone als
/// [dayLocal], zodat ze rechtstreeks met de uren uit de voorspelling te
/// vergelijken zijn.
///
/// Boven de poolcirkel bestaat er niet altijd een opgang of ondergang. Dan zijn
/// [SunTimes.sunrise] en [SunTimes.sunset] `null` en zegt
/// [SunTimes.polarDaylight] of het de hele dag licht is of de hele dag donker.
SunTimes sunTimes({
  required double latitude,
  required double longitude,
  required DateTime dayLocal,
}) {
  final key = _CacheKey(latitude, longitude, dayLocal.isUtc, dayLocal.year,
      dayLocal.month, dayLocal.day);
  final cached = _cache[key];
  if (cached != null) return cached;

  final dayStart = dayLocal.isUtc
      ? DateTime.utc(dayLocal.year, dayLocal.month, dayLocal.day)
      : DateTime(dayLocal.year, dayLocal.month, dayLocal.day);

  double altitudeAtOffset(int seconds) => solarAltitudeDeg(
        latitude: latitude,
        longitude: longitude,
        utc: dayStart.add(Duration(seconds: seconds)).toUtc(),
      );

  // Elke tien minuten door de dag lopen en kijken waar de zon de drempel
  // kruist. Grof genoeg om snel te zijn, fijn genoeg om geen kruising te
  // missen: de zon doet er zelfs op hoge breedte langer dan tien minuten over
  // om de horizon te passeren.
  const step = 600;
  const stepsPerDay = 86400 ~/ step;

  int? riseOffset;
  int? setOffset;
  var previous = altitudeAtOffset(0) - _horizonAltitudeDeg;
  final startedAbove = previous >= 0;

  for (var i = 1; i <= stepsPerDay; i++) {
    final t = i * step;
    final current = altitudeAtOffset(t) - _horizonAltitudeDeg;
    if (previous < 0 && current >= 0 && riseOffset == null) {
      riseOffset = _bisect(altitudeAtOffset, t - step, t);
    } else if (previous >= 0 && current < 0 && setOffset == null) {
      setOffset = _bisect(altitudeAtOffset, t - step, t);
    }
    previous = current;
  }

  final SunTimes result;
  if (riseOffset == null || setOffset == null) {
    // Geen volledige op-en-ondergang binnen deze dag: poolnacht of
    // middernachtszon. Welke van de twee zegt de stand aan het begin van de dag.
    result = SunTimes._polar(polarDaylight: startedAbove);
  } else {
    result = SunTimes._(
      sunrise: dayStart.add(Duration(seconds: riseOffset)),
      sunset: dayStart.add(Duration(seconds: setOffset)),
    );
  }

  // Home rekent honderden vensters door en elk venster vraagt zijn dag op.
  // Zonder geheugen zou dezelfde dag tientallen keren opnieuw worden gezocht.
  if (_cache.length > 400) _cache.clear();
  _cache[key] = result;
  return result;
}

/// Zoekt binnen [lo]–[hi] seconden het moment waarop de hoogte de drempel
/// kruist, op de seconde nauwkeurig.
int _bisect(double Function(int) altitude, int lo, int hi) {
  var low = lo, high = hi;
  final lowAbove = altitude(low) - _horizonAltitudeDeg >= 0;
  while (high - low > 1) {
    final mid = low + (high - low) ~/ 2;
    final midAbove = altitude(mid) - _horizonAltitudeDeg >= 0;
    if (midAbove == lowAbove) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return high;
}

class _CacheKey {
  const _CacheKey(
      this.lat, this.lon, this.isUtc, this.year, this.month, this.day);
  final double lat, lon;
  final bool isUtc;
  final int year, month, day;

  @override
  bool operator ==(Object other) =>
      other is _CacheKey &&
      other.lat == lat &&
      other.lon == lon &&
      other.isUtc == isUtc &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(lat, lon, isUtc, year, month, day);
}

final Map<_CacheKey, SunTimes> _cache = {};

class SunTimes {
  const SunTimes._({this.sunrise, this.sunset, this.polarDaylight = false});

  const SunTimes._polar({required this.polarDaylight})
      : sunrise = null,
        sunset = null;

  final DateTime? sunrise;
  final DateTime? sunset;

  /// Alleen betekenisvol als [sunrise] en [sunset] `null` zijn: `true` bij
  /// middernachtszon, `false` bij poolnacht.
  final bool polarDaylight;

  bool get hasSunTimes => sunrise != null && sunset != null;

  /// Of het op [moment] licht is.
  bool isLightAt(DateTime moment) {
    if (!hasSunTimes) return polarDaylight;
    return !moment.isBefore(sunrise!) && moment.isBefore(sunset!);
  }
}

/// Welk deel van [start] tot [end] in het donker valt, van 0,0 tot 1,0.
///
/// Rekent in minuten en niet in hele uren, met opzet: het venster waar dit voor
/// gebouwd is — donderdag 20:00–22:00 met zonsondergang om 20:07 — is voor 94%
/// donker, terwijl "één van de twee uren is donker" 50% zou zeggen. Dat verschil
/// bepaalt of de app hem nog steeds bovenaan zet.
double darkFraction({
  required DateTime start,
  required DateTime end,
  required double latitude,
  required double longitude,
}) {
  final totalMinutes = end.difference(start).inMinutes;
  if (totalMinutes <= 0) return 0;

  var darkMinutes = 0;
  // Per dag, want een venster kan over middernacht lopen en dan gelden er twee
  // zonsondergangen.
  var cursor = start;
  while (cursor.isBefore(end)) {
    final midnight = cursor.isUtc
        ? DateTime.utc(cursor.year, cursor.month, cursor.day)
        : DateTime(cursor.year, cursor.month, cursor.day);
    final dayEnd = midnight.add(const Duration(days: 1));
    final chunkEnd = dayEnd.isBefore(end) ? dayEnd : end;
    final sun = sunTimes(
      latitude: latitude,
      longitude: longitude,
      dayLocal: cursor,
    );

    final chunkMinutes = chunkEnd.difference(cursor).inMinutes;
    if (!sun.hasSunTimes) {
      if (!sun.polarDaylight) darkMinutes += chunkMinutes;
    } else {
      // Het lichte deel is de doorsnede van [cursor, chunkEnd) met
      // [sunrise, sunset); al het overige binnen dit stuk is donker.
      final lightStart = cursor.isAfter(sun.sunrise!) ? cursor : sun.sunrise!;
      final lightEnd = chunkEnd.isBefore(sun.sunset!) ? chunkEnd : sun.sunset!;
      final lightMinutes = lightEnd.isAfter(lightStart)
          ? lightEnd.difference(lightStart).inMinutes
          : 0;
      darkMinutes += chunkMinutes - lightMinutes;
    }
    cursor = chunkEnd;
  }

  return (darkMinutes / totalMinutes).clamp(0.0, 1.0);
}

/// De aftrek op de ritscore voor een venster dat [fraction] donker is,
/// geschaald met de gevoeligheid die de gebruiker heeft ingesteld.
///
/// **Waarom een aftrek en geen uitsluiting.** Donkere uren wegfilteren breekt de
/// winter: in december is het in Nederland licht van 08:45 tot 16:30, en dan
/// houdt een avondfietser niets over — het type "Na-werk fietser" zou een type
/// zonder ritten worden. Een aftrek laat een avondrit met verlichting gewoon
/// vindbaar, maar zet hem achter elk daglichtvenster dat er die week ook is.
/// Keuze van Joost, 2026-09-09.
///
/// Bij de standaardgevoeligheid zakt een volledig donker venster van 100 naar
/// 80 en blijft daarmee "Goed". Onderling verandert de rangschikking van donkere
/// vensters niet, want ze krijgen allemaal dezelfde aftrek — precies wat je in
/// december wilt.
double darknessPenalty(
  double fraction, {
  double weight = kDefaultDarknessWeight,
}) =>
    fraction.clamp(0.0, 1.0) * weight.clamp(0.0, 1.0) * kMaxDarknessPenalty;

/// De aftrek voor een volledig donker venster bij gevoeligheid 1,0.
const double kMaxDarknessPenalty = 0.40;

/// Waar de schuif in Profiel standaard staat: half. Een volledig donker venster
/// verliest daarmee 20 punten van de 100.
const double kDefaultDarknessWeight = 0.5;
