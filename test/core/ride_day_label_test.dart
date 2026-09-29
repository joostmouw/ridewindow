import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ridewindow/core/ride_day_label.dart';
import 'package:ridewindow/l10n/app_localizations.dart';
import 'package:ridewindow/l10n/app_localizations_en.dart';
import 'package:ridewindow/l10n/app_localizations_nl.dart';

void main() {
  final S nl = SNl();
  final S en = SEn();
  // Dinsdag 29 september 2026, 's avonds laat: de rand van de dag is precies
  // waar een telling in 24-uursblokken de fout in gaat.
  final now = DateTime(2026, 9, 29, 23, 30);

  setUpAll(() async {
    await initializeDateFormatting('nl_NL');
    await initializeDateFormatting('en_US');
  });

  test('vandaag en morgen zijn woorden, ook vlak voor middernacht', () {
    expect(rideDayLabel(DateTime(2026, 9, 29, 7), nl, now: now), 'Vandaag');
    expect(rideDayLabel(DateTime(2026, 9, 30, 0, 30), nl, now: now), 'Morgen');
    expect(rideDayLabel(DateTime(2026, 9, 30, 9), en, now: now), 'Tomorrow');
  });

  test('verder weg: weekdag met datum, met een hoofdletter', () {
    expect(
      rideDayLabel(DateTime(2026, 10, 1, 9), nl, now: now),
      startsWith('Donderdag 1 okt'),
    );
    expect(
      rideDayLabel(DateTime(2026, 10, 3, 10), en, now: now),
      'Saturday 3 Oct',
    );
  });

  test('een rit over een week heet anders dan die van deze week', () {
    final thisSaturday = rideDayLabel(DateTime(2026, 10, 3, 10), en, now: now);
    final nextSaturday = rideDayLabel(DateTime(2026, 10, 10, 10), en, now: now);
    expect(thisSaturday, isNot(nextSaturday));
  });

  test('de zomertijdwissel verschuift geen dag', () {
    // Zondag 25 oktober 2026 duurt 25 uur in Amsterdam.
    final saturdayNight = DateTime(2026, 10, 24, 23);
    expect(
      rideDayLabel(DateTime(2026, 10, 25, 23, 30), en, now: saturdayNight),
      'Tomorrow',
    );
  });

  test('over de jaargrens', () {
    expect(
      rideDayLabel(DateTime(2027, 1, 1, 10), en, now: DateTime(2026, 12, 31)),
      'Tomorrow',
    );
  });

  test('de absolute vorm zegt nooit vandaag of morgen', () {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect(rideDayLabelAbsolute(tomorrow, en), isNot('Tomorrow'));
    expect(rideDayLabelAbsolute(DateTime(2026, 10, 3), en), 'Saturday 3 Oct');
  });
}
