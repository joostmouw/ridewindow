import 'package:ridewindow/providers/availability_notifier.dart';

/// Canonieke sleutel voor een geblokkeerd uur.
///
/// De hele app rekent in **lokale** tijd: Open-Meteo wordt met `timezone=auto`
/// bevraagd en levert dus lokale wandkloktijden, en daar worden alle slots tegen
/// gescoord. Een `DateTime.utc(...)` met dezelfde wandkloktijd is in Dart een
/// *andere* sleutel — `DateTime.==` vergelijkt ook `isUtc` — waardoor een
/// `containsKey()` stilzwijgend altijd faalt.
///
/// Deze functie is het enige punt waar een uur-sleutel gemaakt mag worden.
/// Voor een UTC-`DateTime` worden de UTC-componenten overgenomen (dus geen
/// zone-conversie): dat is precies wat oude grid-sleutels bedoelden, want die
/// stempelden een lokale wandkloktijd als UTC.
DateTime canonicalHourKey(DateTime t) =>
    DateTime(t.year, t.month, t.day, t.hour);

/// Rangorde bij een sleutelbotsing tijdens migratie: het "sterkste" blok wint.
/// Work is door de gebruiker of een preset gezet en is het meest structureel;
/// custom is het makkelijkst opnieuw te zetten.
int _precedence(BlockType t) => switch (t) {
      BlockType.work => 3,
      BlockType.calendar => 2,
      BlockType.custom => 1,
    };

/// Normaliseert een ruwe, mogelijk gemengde map naar canonieke sleutels.
///
/// Bestaande installs hebben beide sleutel-smaken in SharedPreferences staan
/// (zie `.planning/AUDIT-COHERENCE-260725.md`, bevinding C3). Zonder deze stap
/// blijven hun blokken kapot na de fix.
Map<DateTime, BlockType> normalizeBlockedHours(Map<DateTime, BlockType> raw) {
  final result = <DateTime, BlockType>{};
  for (final entry in raw.entries) {
    final key = canonicalHourKey(entry.key);
    final existing = result[key];
    if (existing == null || _precedence(entry.value) > _precedence(existing)) {
      result[key] = entry.value;
    }
  }
  return result;
}

/// Index over de geblokkeerde uren, opgebouwd voor herhaalde lookups.
///
/// Twee soorten blokken, met bewust verschillend gedrag:
/// - [BlockType.work] en [BlockType.custom] vormen een **terugkerend
///   weekpatroon**. Het beschikbaarheidsscherm toont één week met dag-afkortingen
///   en de presets seeden een werkweek, dus "elke dinsdag 9-17 werk" is wat de
///   gebruiker daar invult. Ze matchen op weekdag + uur, ongeacht de datum.
/// - [BlockType.calendar] is **datum-specifiek**. Een geïmporteerde afspraak van
///   dinsdag hoort niet elke dinsdag te blokkeren; die verloopt vanzelf.
class BlockedHours {
  BlockedHours(Map<DateTime, BlockType> blockedHours) {
    for (final entry in blockedHours.entries) {
      final key = canonicalHourKey(entry.key);
      if (entry.value == BlockType.calendar) {
        _exact[key] = entry.value;
      } else {
        _recurring[_slotOf(key)] = entry.value;
      }
    }
  }

  /// weekdag (1-7) * 24 + uur (0-23) → het terugkerende bloktype.
  final Map<int, BlockType> _recurring = {};

  /// Canonieke sleutel → het datum-specifieke bloktype.
  final Map<DateTime, BlockType> _exact = {};

  static int _slotOf(DateTime key) => key.weekday * 24 + key.hour;

  /// Het effectieve bloktype voor [hour], of null als het uur vrij is.
  /// Een datum-specifiek blok wint van het weekpatroon.
  BlockType? blockTypeAt(DateTime hour) {
    final key = canonicalHourKey(hour);
    return _exact[key] ?? _recurring[_slotOf(key)];
  }

  bool isBlocked(DateTime hour) => blockTypeAt(hour) != null;

  bool get isEmpty => _exact.isEmpty && _recurring.isEmpty;
}

/// Losse lookup voor plekken die maar één uur nakijken (bv. een grid-cel).
/// Bouwt de index per aanroep op; gebruik [BlockedHours] direct waar in een lus
/// gezocht wordt.
BlockType? blockTypeAt(DateTime hour, Map<DateTime, BlockType> blockedHours) =>
    BlockedHours(blockedHours).blockTypeAt(hour);

/// Zoals [blockTypeAt], maar alleen de ja/nee-vraag.
bool isHourBlocked(DateTime hour, Map<DateTime, BlockType> blockedHours) =>
    BlockedHours(blockedHours).isBlocked(hour);
