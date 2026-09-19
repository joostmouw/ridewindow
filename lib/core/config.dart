// lib/core/config.dart
// Configureerbare defaults voor locatie. Phase 7 vervangt dit met echte GPS.
// Geen riverpod_annotation nodig — puur Dart constanten.

const double kDefaultLat = 52.3676; // Amsterdam
const double kDefaultLon = 4.9041;
const String kDefaultCity = 'Amsterdam';

/// Het label voor een plek die uit GPS komt in plaats van uit de stadkeuze.
/// Geen echte stadsnaam -- de app doet geen reverse geocoding.
const String kGpsCityLabel = 'GPS';

/// De uren waarbinnen de app rijden overweegt: van [kRideDayStartHour] tot
/// [kRideDayEndHour], het eind exclusief. Een venster dat om 21:00 begint en om
/// 22:00 eindigt telt dus wel; een venster dat om 22:00 begint niet.
///
/// **Waarom dit één constante is.** Deze twee getallen stonden op drie plekken
/// los van elkaar: `slots_notifier.dart` gaf ze hardgecodeerd aan de generator,
/// de Agenda had een eigen urenlijst die één rij te ver liep (uur 22, dat de
/// motor nooit aanbiedt), en de dagbalk op Home had ze nog een derde keer.
/// Drie kopieën van dezelfde afspraak is twee te veel -- en de Agenda liep er
/// aantoonbaar al uit de pas.
const int kRideDayStartHour = 6;
const int kRideDayEndHour = 22;

/// De uren die de Agenda als rij toont: elk uur dat een rit kán beginnen.
/// Uur [kRideDayEndHour] hoort er niet bij -- dat is het einde, geen begin.
List<int> get kRideDayHours => [
      for (var h = kRideDayStartHour; h < kRideDayEndHour; h++) h,
    ];
