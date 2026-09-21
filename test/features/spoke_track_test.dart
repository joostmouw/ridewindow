/// Unit tests voor de tijdlijn van spaaktikken (`kSpokeTicks`).
///
/// De tijdlijn is een const lijst: wat hier bewaakt wordt zijn de
/// onveranderlijkheden die "op de maat van het filmpje" betekenen, afgeleid
/// uit de frameanalyse in PLAN 260921-welkomstwielen-geluid-en-trilling.
/// De speler zelf draait op het toestel; zijn timing is precies deze lijst,
/// dus de lijst testen is de synchronisatie testen.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/features/welcome/spoke_track.dart';

void main() {
  test('de eerste tik komt pas als de fiets vorm krijgt', () {
    // De morph waait vanaf circa 1,0 s naar de fiets; een tik daarvóór
    // hoort bij een wiel dat er nog niet is.
    expect(
      kSpokeTicks.first.at,
      greaterThanOrEqualTo(const Duration(milliseconds: 1000)),
    );
  });

  test('de laatste tik landt nog binnen het beeld', () {
    // De intro is op 2472 ms afgelopen; de tijdlijn belooft dat hij
    // uiterlijk op 2430 ms uitgetikt is.
    expect(
      kSpokeTicks.last.at,
      lessThanOrEqualTo(const Duration(milliseconds: 2430)),
    );
    expect(
      kSpokeTicks.last.at,
      lessThan(const Duration(milliseconds: 2472)),
    );
  });

  test('het ritme versnelt monotoon: nooit een stap terug', () {
    // De keuze van Joost: een optrekkende rit. Elke tussenpoos is hooguit
    // zo lang als de vorige; één terugval maakt er een schokkerend geheel van.
    for (var i = 1; i < kSpokeTicks.length; i++) {
      final gap = kSpokeTicks[i].at - kSpokeTicks[i - 1].at;
      final previousGap = i >= 2
          ? kSpokeTicks[i - 1].at - kSpokeTicks[i - 2].at
          : gap;
      expect(
        gap,
        lessThanOrEqualTo(previousGap),
        reason: 'tussenpoos bij tik $i is teruggevallen naar $gap',
      );
    }
  });

  test('tik en tock wisselen af', () {
    // Twee dezelfde tikken achter elkaar klinken als een metronoom; de
    // afwisseling is de onregelmaat die een rollend wiel geloofwaardig maakt.
    for (var i = 1; i < kSpokeTicks.length; i++) {
      expect(
        kSpokeTicks[i].tock,
        isNot(kSpokeTicks[i - 1].tock),
        reason: 'tik $i herhaalt dezelfde klank als de vorige',
      );
    }
  });

  test('het volume loopt alleen maar omhoog', () {
    // De rit trekt op; een tik die zachter terugkomt dan zijn voorganger
    // voelt als terugvallen.
    for (var i = 1; i < kSpokeTicks.length; i++) {
      expect(
        kSpokeTicks[i].volume,
        greaterThanOrEqualTo(kSpokeTicks[i - 1].volume),
        reason: 'volume bij tik $i zakt terug naar ${kSpokeTicks[i].volume}',
      );
    }
  });

  test('createSpokeTrackPlayer bestaat niet in de testomgeving', () {
    // In flutter test is er geen audioplatform, en de intro moet zonder
    // geluid doorlopen. Deze test pinned dat gedrag: faalt de bewaking,
    // dan gaan de bestaande welkomtests op het audioplatform breken.
    expect(createSpokeTrackPlayer(), isNull);
  });
}
