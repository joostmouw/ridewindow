/// Unit tests voor de tijdlijn van het wielgeluid en de trillingen.
///
/// De tijdlijn is const: wat hier bewaakt wordt zijn de onveranderlijkheden
/// van "opstarten en uitrijden", afgeleid uit de clipmeting van
/// tool/rolling_intro_sound.py. De speler zelf draait op het toestel; zijn
/// timing is precies deze constanten, dus die testen is de synchronisatie
/// testen.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/features/welcome/spoke_track.dart';

void main() {
  test('de clip begint pas als de fiets vorm krijgt', () {
    // De morph waait vanaf circa 1,0 s naar de fiets; geluid daarvóór hoort
    // bij een fiets die er nog niet is.
    expect(
      kRollingClipStart,
      greaterThanOrEqualTo(const Duration(milliseconds: 1000)),
    );
  });

  test('de uitrij is voorbij voordat de titel er lang stil bij staat', () {
    // De intro is op 2.472 ms afgelopen; de uitrij mag er nog een seconde
    // achteraan (Joost wilde hem horen uitlopen), en daarna moet het stil
    // zijn.
    expect(
      kRollingClipStart + kRollingClipDuration,
      lessThanOrEqualTo(const Duration(milliseconds: 3600)),
    );
  });

  test('elke trillingspuls valt binnen de clip', () {
    // Een puls buiten de clip is een trilling zonder geluid: precies het
    // loszinnige gevoel dat ronde 1 op het toestel opleverde.
    for (final pulse in kRollingHaptics) {
      expect(
        pulse,
        greaterThanOrEqualTo(kRollingClipStart),
        reason: 'puls op ${pulse.inMilliseconds} ms valt vóór de clip',
      );
      expect(
        pulse,
        lessThanOrEqualTo(kRollingClipStart + kRollingClipDuration),
        reason: 'puls op ${pulse.inMilliseconds} ms valt ná de clip',
      );
    }
  });

  test('de eerste puls volgt de in-grijpende klik meteen', () {
    // De opname begint met het pedaal dat in-grijpt; die klik is het start-
    // schot van de rit en moet dus voelbaar zijn zodra de clip begint.
    expect(
      kRollingHaptics.first - kRollingClipStart,
      lessThanOrEqualTo(const Duration(milliseconds: 100)),
    );
  });

  test('de tussenpozen van de pulsen blijven voelbaar gescheiden', () {
    // Korter dan 70 ms voelt aan als één zoem in plaats van als een rit;
    // de meetscript-vloer staat er dus ook in de code.
    for (var i = 1; i < kRollingHaptics.length; i++) {
      expect(
        kRollingHaptics[i] - kRollingHaptics[i - 1],
        greaterThanOrEqualTo(const Duration(milliseconds: 70)),
        reason: 'puls $i zit te dicht op zijn voorganger',
      );
    }
  });

  test('het ritme versnelt in het begin en dunt uit aan het eind', () {
    // De optrekkende rit: de eerste tussenpoos is ruimer dan de kleinste,
    // en de laatste (de uitrij) is dat ook. De kleinste tussenpoos hoort in
    // de volle rammel thuis, niet aan de randen.
    final gaps = <Duration>[
      for (var i = 1; i < kRollingHaptics.length; i++)
        kRollingHaptics[i] - kRollingHaptics[i - 1],
    ];
    final minGap = gaps.reduce((a, b) => a < b ? a : b);

    expect(
      gaps.first,
      greaterThan(minGap),
      reason: 'de rit begint al op volle snelheid: nergens een optrek',
    );
    expect(
      gaps.last,
      greaterThan(minGap),
      reason: 'de uitrij dunt niet uit: de rit stopt in plaats van weg te '
          'rijden',
    );
  });

  test('er zit ritme in: minstens vijftien pulsen', () {
    expect(kRollingHaptics.length, greaterThanOrEqualTo(15));
  });

  test('createSpokeTrackPlayer bestaat niet in de testomgeving', () {
    // In flutter test is er geen audioplatform, en de intro moet zonder
    // geluid doorlopen. Deze test pinned dat gedrag: faalt de bewaking,
    // dan gaan de bestaande welkomtests op het audioplatform breken.
    expect(createSpokeTrackPlayer(), isNull);
  });
}
