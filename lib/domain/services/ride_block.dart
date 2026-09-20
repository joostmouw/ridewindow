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
    this.candidates = const [],
  });

  /// Begin van het vroegste venster in dit blok.
  final DateTime start;

  /// Einde van het laatste venster in dit blok.
  final DateTime end;

  /// Het best scorende venster erin -- de donkere markering op de balk.
  final RideSlot best;

  /// Alle vensters in dit blok, chronologisch.
  final List<RideSlot> slots;

  /// Hoe lang het goede dagdeel duurt. Dit is de schaal van de balk, géén
  /// ritduur -- op een mooie dag is dit vijftien uur, en niemand fietst
  /// vijftien uur.
  int get hours => end.difference(start).inHours;

  /// De langste rit die in dit blok past.
  ///
  /// **Dit is het antwoord op "hoe lang kan ik weg"**, en niet [hours]. De
  /// eerste versie toonde [hours] en beweerde daarmee dat je vijftien uur
  /// aaneengesloten kon fietsen; Joost wees daar meteen op.
  ///
  /// **Waarom dit niet uit [slots] komt.** Dat was de tweede versie, en die
  /// zei vrijwel altijd "2 uur" -- ook op een dag met tien goede uren en alle
  /// ritlengtes aangevinkt. De oorzaak zit in `SlotGenerator.dedup`: die
  /// houdt van twee overlappende vensters het best scorende over, en een kort
  /// venster wint dat vrijwel altijd omdat het de beste uren eruit pikt. Een
  /// venster van vijf uur dat een venster van twee uur bevat, overlapt dat
  /// laatste voor 100% en verdwijnt dus. Wat overblijft is een lijst van korte
  /// vensters, en "de langste daarvan" is dan een uitspraak over `dedup`, niet
  /// over jouw mogelijkheden.
  ///
  /// Daarom kijkt deze regel naar de vensters van vóór die opschoning, voor
  /// zover ze binnen dit blok vallen. Gevonden op het toestel, 2026-09-20,
  /// toen Joost vroeg wat "Longest ride here: 2 hours" nu eigenlijk betekende.
  final List<RideSlot> candidates;

  int get longestRideHours => (candidates.isEmpty ? slots : candidates)
      .map((s) => s.end.difference(s.start).inHours)
      .reduce((a, b) => a > b ? a : b);

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
/// [candidates] zijn de vensters van vóór `dedup`. Ze bepalen niets aan de
/// indeling -- alleen [RideBlock.longestRideHours] leest ze, en alleen de
/// vensters die binnen het blok vallen tellen mee.
List<RideBlock> buildRideBlocks(
  List<RideSlot> slots, {
  List<RideSlot> candidates = const [],
}) {
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
      blocks.add(_toBlock(current, end, candidates));
      current = [slot];
      end = slot.end;
    }
  }
  blocks.add(_toBlock(current, end, candidates));

  return blocks;
}

RideBlock _toBlock(
  List<RideSlot> slots,
  DateTime end,
  List<RideSlot> candidates,
) {
  var best = slots.first;
  for (final slot in slots.skip(1)) {
    // Bij een gelijke score wint het vroegste venster -- dezelfde afspraak als
    // `indexOfBestSlot`: van twee even goede ritten is de eerstvolgende de
    // bruikbaarste.
    if (slot.overallScore > best.overallScore) best = slot;
  }
  final start = slots.first.start;
  return RideBlock(
    start: start,
    end: end,
    best: best,
    slots: List.unmodifiable(slots),
    // Alleen wat helemaal binnen het blok past: een venster dat eroverheen
    // steekt hoort bij het volgende stuk van de dag, niet bij dit.
    candidates: List.unmodifiable(
      candidates.where(
        (c) => !c.start.isBefore(start) && !c.end.isAfter(end),
      ),
    ),
  );
}


/// Alle blokken van één kalenderdag, plus het beste venster van die dag.
///
/// **Waarom een dag en niet een blok de kaart is.** De eerste versie toonde één
/// kaart per blok, met de balk geschaald op dat blok. Daarmee zag je wel dát
/// het goed was maar niet wáár in de dag, en al helemaal niet wat de rest van
/// de dag deed -- de vraag waar dit hele scherm over gaat. Joost wees daarop
/// zodra hij het zag. Eén kaart per dag, met de dag als schaal, zet het goede
/// stuk terug in zijn context.
class RideDay {
  const RideDay({required this.day, required this.blocks, required this.best});

  final DateTime day;

  /// De goede stukken van deze dag, chronologisch. Meestal één, soms twee --
  /// een ochtend en een avond met een natte middag ertussen.
  final List<RideBlock> blocks;

  /// Het beste venster van de hele dag.
  final RideSlot best;

  /// De langste rit die deze dag aanbiedt.
  int get longestRideHours =>
      blocks.map((b) => b.longestRideHours).reduce((a, b) => a > b ? a : b);
}

/// Groepeert [slots] per kalenderdag, met de blokken erbinnen.
List<RideDay> buildRideDays(
  List<RideSlot> slots, {
  List<RideSlot> candidates = const [],
}) {
  final byDay = <DateTime, List<RideSlot>>{};
  for (final slot in slots) {
    final day = DateTime(slot.start.year, slot.start.month, slot.start.day);
    (byDay[day] ??= []).add(slot);
  }

  final days = byDay.entries.map((entry) {
    final blocks = buildRideBlocks(entry.value, candidates: candidates);
    var best = blocks.first.best;
    for (final block in blocks.skip(1)) {
      if (block.best.overallScore > best.overallScore) best = block.best;
    }
    return RideDay(day: entry.key, blocks: blocks, best: best);
  }).toList()
    ..sort((a, b) => a.day.compareTo(b.day));

  return days;
}
