import 'package:intl/intl.dart';

import 'package:ridewindow/l10n/app_localizations.dart';

/// De dag van een rit zoals een kaart hem toont: "Vandaag", "Morgen", en
/// verder weg de weekdag met een korte datum ("Zaterdag 3 okt.").
///
/// Alleen de weekdag was dubbelzinnig: PLANNED toont de eerstvolgende drie
/// ritten, niet die van één week, dus een rit over tien dagen heette net zo
/// "Zaterdag" als die van deze zaterdag.
String rideDayLabel(DateTime start, S s, {DateTime? now}) {
  final days = _calendarDaysBetween(now ?? DateTime.now(), start);
  if (days == 0) return s.dayToday;
  if (days == 1) return s.dayTomorrow;
  return rideDayLabelAbsolute(start, s);
}

/// Weekdag met korte datum, zonder "Vandaag" of "Morgen".
///
/// Voor tekst die een ander leest, op een ander moment: in een gedeeld bericht
/// betekent "morgen" wat de lezer ervan maakt.
String rideDayLabelAbsolute(DateTime start, S s) {
  final locale = s.localeName == 'en' ? 'en_US' : 'nl_NL';
  final text = DateFormat('EEEE d MMM', locale).format(start);
  // intl schrijft Nederlandse weekdagen met een kleine letter; bovenaan een
  // kaart hoort een hoofdletter, zoals de rest van de app de dag schrijft.
  return text[0].toUpperCase() + text.substring(1);
}

/// Kalenderdagen, niet blokken van 24 uur: 23:00 en 01:00 zijn twee dagen, en
/// over de zomertijdwissel is een dag 23 of 25 uur lang. Via UTC-middernacht
/// valt dat verschil weg.
int _calendarDaysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}
