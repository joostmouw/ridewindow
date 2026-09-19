/// Het aaneengesloten goede dagdeel waar losse vensters in liggen.
///
/// **Waarom dit bestaat.** Een tester kreeg op één zaterdag drie regels onder
/// elkaar -- 09:00-11:00 (100), 06:00-09:00 (99) en 11:00-13:00 (95) -- en
/// vroeg: *"waarom geeft die dan niet van 8-11 of van 9-13?"* Er was niets
/// stuk: `SlotGenerator.dedup` gooit 08:00-11:00 weg omdat het voor 67%
/// overlapt met het beter scorende 09:00-11:00. Maar de app beantwoordt
/// daarmee *"welk venster van N uur is het beste"*, terwijl zij vroeg
/// *"wanneer is het vandaag goed, en hoe lang kan ik weg"* (backlog #69).
///
/// **Waarom opgebouwd uit vensters en niet uit uurscores.** De vensters zijn al
/// door de hele molen: toleranties, beschikbaarheid, toegestane duur, de
/// grenzen van 6 tot 22 uur. Opnieuw beginnen bij de uurscores zou al die
/// regels een tweede keer moeten nabouwen, en dan twee antwoorden geven op
/// dezelfde vraag. Het blok is simpelweg de som van wat de app al rijdbaar
/// vindt.
library;

import 'package:ridewindow/domain/models/ride_slot.dart';

/// Een aaneengesloten stuk dag waarin de app rijden de moeite vindt.
class RideBlock {
  const RideBlock({
    required this.start,
    required this.end,
    required this.best,
    required this.slots,
  });

  /// Begin van het vroegste venster in dit blok.
  final DateTime start;

  /// Einde van het laatste venster in dit blok.
  final DateTime end;

  /// Het best scorende venster erin -- de donkere markering op de balk.
  final RideSlot best;

  /// Alle vensters in dit blok, chronologisch.
  final List<RideSlot> slots;

  /// Hoe lang je aaneengesloten weg kunt. Dit is het getal waar de vraag
  /// werkelijk over ging.
  int get hours => end.difference(start).inHours;

  /// De dag waar dit blok in valt.
  DateTime get day => DateTime(start.year, start.month, start.day);
}

/// Voegt [slots] samen tot aaneengesloten blokken.
///
/// Twee vensters horen bij elkaar als ze overlappen óf op elkaar aansluiten:
/// 06:00-09:00 en 09:00-11:00 raken elkaar en beschrijven samen één ochtend.
/// Zit er een gat tussen -- de app vond die uren niet rijdbaar -- dan zijn het
/// twee blokken, en dat is dan ook de waarheid.
///
/// Blokken komen chronologisch terug.
List<RideBlock> buildRideBlocks(List<RideSlot> slots) {
  if (slots.isEmpty) return const [];

  final sorted = [...slots]..sort((a, b) => a.start.compareTo(b.start));

  final blocks = <RideBlock>[];
  var current = <RideSlot>[sorted.first];
  var end = sorted.first.end;

  for (final slot in sorted.skip(1)) {
    // `!slot.start.isAfter(end)` en niet `isBefore`: aansluiten telt als
    // aaneengesloten, anders valt Ingrids ochtend alsnog in tweeën.
    if (!slot.start.isAfter(end)) {
      current.add(slot);
      if (slot.end.isAfter(end)) end = slot.end;
    } else {
      blocks.add(_toBlock(current, end));
      current = [slot];
      end = slot.end;
    }
  }
  blocks.add(_toBlock(current, end));

  return blocks;
}

RideBlock _toBlock(List<RideSlot> slots, DateTime end) {
  var best = slots.first;
  for (final slot in slots.skip(1)) {
    // Bij een gelijke score wint het vroegste venster -- dezelfde afspraak als
    // `indexOfBestSlot`: van twee even goede ritten is de eerstvolgende de
    // bruikbaarste.
    if (slot.overallScore > best.overallScore) best = slot;
  }
  return RideBlock(
    start: slots.first.start,
    end: end,
    best: best,
    slots: List.unmodifiable(slots),
  );
}
