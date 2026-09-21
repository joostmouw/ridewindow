// lib/features/welcome/spoke_track.dart
//
// Het spaakgeluid en de trillingen onder de welkomstintro (2026-09-21).
//
// **Wat er in het filmpje echt zit.** `welcome_ride.webp` is een morph: het
// RW-monogram waait naar de fiets, de renner stapt op, en pas in de laatste
// halve seconde sluiten de velgen. De wielen draaien nergens als wiel en
// hebben in het eindbeeld geen spaken (gemeten 2026-09-21, zie PLAN
// 260921-welkomstwielen-geluid-en-trilling); het bronfilmpje bevat alleen
// muziek. Het spaakgeluid bestaat dus niet en is verzonnen, met een ritme
// dat aan de gemeten fasen van het filmpje is afgeleid:
//
//   0,00-0,28 s  stille start
//   0,28-1,00 s  de tekening verschijnt
//   1,00-1,68 s  de morph waait naar de fiets     <- tikken beginnen, zacht
//   1,68-2,00 s  de renner stapt op               <- het wiel trekt op
//   2,00-2,16 s  velgen sluiten                   <- vol tempo
//   2,16-2,47 s  beeld stil, Flutter schuift omhoog <- doorrollen tot het eind
//
// De klanken zelf komen uit `tool/spoke_tick_sound.py` (deterministisch,
// licentievrij, alleen Python-stdlib); wil je een andere klank, draai dat
// script opnieuw en pas de constanten hieronder niet aan.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Eén spaaktik: wanneer hij valt (relatief aan het begin van de intro),
/// welke klank en hoe hard.
@immutable
class SpokeTick {
  const SpokeTick(this.at, {required this.tock, required this.volume});

  final Duration at;

  /// Tik en tock wisselen af. Acht dezelfde tikken per seconde klinken als
  /// een metronoom; een wiel dat rolt is onregelmatiger dan dat, en twee
  /// iets verschillende klanken geven die onregelmaat zonder het ritme te
  /// verliezen.
  final bool tock;

  /// 0,4 is zacht (de fiets krijgt vorm), 0,8 is vol aan (de rit rolt).
  final double volume;
}

/// De tijdlijn, afgeleid en niet gekozen (frameanalyse in het PLAN):
///
/// - fase 1, 1,0-1,68 s: interval 330 ms, volume 0,4. Tikken op 1000,
///   1330 en 1660 ms. De vierde vertrekt nog met het fase-1-interval van
///   zijn vertrekmoment (1660 + 330) en landt op 1990 ms.
/// - fase 2, 1,68-2,1 s: het interval trekt op van 330 naar 125 ms, het
///   volume van 0,4 naar 0,8. De tik van 1990 krijgt volume 0,7 (halverwege
///   de ophelling), die van 2169 valt al in fase 3 en is vol aan.
/// - fase 3, vanaf 2,1 s: interval 125 ms, volume 0,8. Tikken op 2294 en
///   2419 ms, en dan is het genoeg.
/// - na 2430 ms stopt de tijdlijn: de intro eindigt op 2472 ms en de laatste
///   tik moet nog binnen het beeld landen.
const kSpokeTicks = <SpokeTick>[
  SpokeTick(Duration(milliseconds: 1000), tock: false, volume: 0.4),
  SpokeTick(Duration(milliseconds: 1330), tock: true, volume: 0.4),
  SpokeTick(Duration(milliseconds: 1660), tock: false, volume: 0.4),
  SpokeTick(Duration(milliseconds: 1990), tock: true, volume: 0.7),
  SpokeTick(Duration(milliseconds: 2169), tock: false, volume: 0.8),
  SpokeTick(Duration(milliseconds: 2294), tock: true, volume: 0.8),
  SpokeTick(Duration(milliseconds: 2419), tock: false, volume: 0.8),
];

/// De klok van deze tijdlijn start in `initState`, samen met de
/// settle-timer van het scherm; het beeld begint pas als de eerste frame van
/// de WebP gedecodeerd is. Deze constante schuift de tikken evenver op als
/// die decodering naar verwachting duurt. De intro begint met 276 ms
/// stilstaand beeld, dus de schatting hoeft niet exact te zijn. Bijstellen
/// doe je op het toestel: valt de eerste tik duidelijk vóór de werveling,
/// verhoog dan; valt hij er ver na, verlaag dan.
const kSpokeTrackStartDelay = Duration(milliseconds: 150);

/// Speelt [kSpokeTicks]: geluid en een korte trilling per tik. Die twee
/// zitten bewust samen achter één start/stop. "Elke tik geeft een korte
/// trilling op hetzelfde ritme" was de keuze van Joost (2026-09-21), en
/// samen in één object kunnen geluid en trilling nooit van elkaar
/// afdriften.
abstract class SpokeTrackPlayer {
  /// Start de tijdlijn op de klok van nu. Twee keer starten hoort niet
  /// voor te komen; het scherm start één keer en stopt bij overslaan of
  /// afbraak.
  void start();

  /// Breekt de rit af: geen tik meer, geen trilling meer. Idempotent.
  void stop();
}

/// De echte speler: twee `AudioPlayer`s (tik en tock) in lowLatency-stand
/// (SoundPool op Android, bedoeld voor korte snel herhaalde geluiden) en
/// `HapticFeedback.selectionClick` per tik, het korte klikje dat de app ook
/// elders voor kleine bevestigingen gebruikt.
class AudioSpokeTrackPlayer implements SpokeTrackPlayer {
  AudioSpokeTrackPlayer() : _players = [AudioPlayer(), AudioPlayer()];

  final List<AudioPlayer> _players;
  final List<Timer> _timers = [];
  bool _stopped = false;
  bool _audioFailureLogged = false;

  @override
  void start() {
    if (_stopped) return;
    // De speler opzetten kost een platform-kanaalronde; de eerste tik zit
    // ruim een seconde verder, dus niet awaiten: de tijdlijn vertrekt op
    // de klok van de intro, niet op die van de audiostack.
    unawaited(_prepare());
    for (final tick in kSpokeTicks) {
      _timers.add(Timer(kSpokeTrackStartDelay + tick.at, () => _tick(tick)));
    }
  }

  Future<void> _prepare() async {
    try {
      for (final player in _players) {
        await player.setPlayerMode(PlayerMode.lowLatency);
      }
    } catch (error) {
      _logBrokenAudio(error);
    }
  }

  void _tick(SpokeTick tick) {
    if (_stopped) return;
    // De trilling eerst: het trillingskanaal is er altijd, en de intro mag
    // nooit afhangen van de audiostack.
    HapticFeedback.selectionClick();
    unawaited(_play(tick));
  }

  Future<void> _play(SpokeTick tick) async {
    try {
      await _players[tick.tock ? 1 : 0].play(
        AssetSource('sounds/spoke_${tick.tock ? 'tock' : 'tick'}.wav'),
        volume: tick.volume,
      );
    } catch (error) {
      _logBrokenAudio(error);
    }
  }

  @override
  void stop() {
    if (_stopped) return;
    _stopped = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    // lowLatency-spelers horen vrijgegeven te worden; audioplayers laat
    // ze anders op de SoundPool liggen.
    for (final player in _players) {
      unawaited(player.dispose());
    }
  }

  void _logBrokenAudio(Object error) {
    // Eén keer melden, niet per tik: ontbreekt het audioplatform dan faalt
    // elke tik op dezelfde manier. En dit is geen "stille tak" voor de
    // gebruiker: op de intro valt niets op te lossen, en hij moet doorlopen,
    // met of zonder wiel.
    if (_audioFailureLogged) return;
    _audioFailureLogged = true;
    debugPrint('SpokeTrack: geluid afspelen mislukt, intro loopt door: $error');
  }
}

/// De speler voor het scherm: alleen waar hij echt kan bestaan.
///
/// - Op web: niets. De browser blokkeert autoplay op een intro die zonder
///   tik van de gebruiker start, en trillingen bestaan daar niet. Zelfde
///   kIsWeb-wacht als `emailRedirectTo`.
/// - In de testomgeving: niets. Daar is geen audioplatform en de intro moet
///   zonder geluid doorlopen; widget-tests injecteren hun eigen fake.
/// - Anders: de echte speler.
SpokeTrackPlayer? createSpokeTrackPlayer() {
  if (kIsWeb) return null;
  if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
  return AudioSpokeTrackPlayer();
}
