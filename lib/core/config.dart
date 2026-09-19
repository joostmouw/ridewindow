// lib/core/config.dart
// Configureerbare defaults voor locatie. Phase 7 vervangt dit met echte GPS.
// Geen riverpod_annotation nodig — puur Dart constanten.

const double kDefaultLat = 52.3676; // Amsterdam
const double kDefaultLon = 4.9041;
const String kDefaultCity = 'Amsterdam';

/// Het label voor een plek die uit GPS komt in plaats van uit de stadkeuze.
/// Geen echte stadsnaam -- de app doet geen reverse geocoding.
const String kGpsCityLabel = 'GPS';
