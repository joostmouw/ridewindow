// lib/platform/device_timezone.dart
//
// De tijdzone van het toestel, ook in de achtergrondtaak (#74, #77).
//
// **Waarom dit een eigen bestand is.** Meldingen plannen met `zonedSchedule`
// rekent in `tz.local`. Op de voorgrond zet `main.dart` die op de tijdzone
// van het toestel. De WorkManager-taak draait in een eigen isolate, en daar
// staat `tz.local` op UTC tot iemand hem zet -- dan gaat een melding voor
// 19:00 om 21:00 af in de zomer. Dat is dezelfde klasse fout als de
// Aruba-melding van 2026-09-19, en de reden dat plannen tot nu toe alleen op
// de voorgrond gebeurde.
//
// Twee bronnen, in deze volgorde:
// 1. Het toestel zelf vragen (`flutter_timezone`). Werkt in de isolate zodra
//    `DartPluginRegistrant.ensureInitialized()` gedraaid heeft, en is de enige
//    bron die klopt als iemand net naar een andere tijdzone is gereisd.
// 2. De laatste waarde die de voorgrond bewaarde. Voor als de peiling in de
//    isolate faalt.
// Kent geen van beide een geldige zone, dan is het antwoord `null` en plant
// de aanroeper niets. Geen melding is beter dan een melding op het verkeerde
// uur -- een gok op Europe/Amsterdam zou precies de fout zijn die dit
// bestand moet voorkomen.

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// SharedPreferences-sleutel met de IANA-naam die het laatst gezien is.
const kDeviceTimezoneKey = 'device.timezone';

/// Vraagt het toestel om zijn IANA-tijdzone. Los te vervangen in tests.
typedef TimezoneLookup = Future<String> Function();

Future<String> _lookupFromDevice() async =>
    (await FlutterTimezone.getLocalTimezone()).identifier;

/// Bepaalt de tijdzone, bewaart hem, en zet `tz.local` erop.
///
/// Verwacht dat `tz.initializeTimeZones()` al gedraaid heeft. Geeft de
/// gebruikte IANA-naam terug, of `null` als er geen geldige zone bekend is --
/// dan is `tz.local` niet aangeraakt.
Future<String?> applyDeviceTimezone(
  SharedPreferences prefs, {
  TimezoneLookup lookup = _lookupFromDevice,
}) async {
  String? fromDevice;
  try {
    fromDevice = await lookup();
  } catch (_) {
    // Valt terug op de bewaarde waarde hieronder.
  }

  for (final name in [fromDevice, prefs.getString(kDeviceTimezoneKey)]) {
    if (name == null || name.isEmpty) continue;
    final tz.Location location;
    try {
      location = tz.getLocation(name);
    } on tz.LocationNotFoundException {
      continue;
    }
    tz.setLocalLocation(location);
    if (prefs.getString(kDeviceTimezoneKey) != name) {
      await prefs.setString(kDeviceTimezoneKey, name);
    }
    return name;
  }
  return null;
}
