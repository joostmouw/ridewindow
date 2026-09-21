// lib/features/welcome/spoke_track.dart
//
// Het wielgeluid en de trillingen onder de welkomstintro (2026-09-21).
//
// **Wat er in het filmpje echt zit.** `welcome_ride.webp` is een morph: het
// RW-monogram waait naar de fiets, de renner stapt op, en pas in de laatste
// halve seconde sluiten de velgen. De wielen draaien nergens als wiel en
// hebben in het eindbeeld geen spaken (gemeten 2026-09-21, zie PLAN
// 260921-welkomstwielen-geluid-en-trilling); het bronfilmpje bevat alleen
// muziek. Het geluid bestaat dus niet in de bron en is eronder gezet.
//
// **Ronde 1: verzonnen tikken.** Zeven synthetische spaaktikken, op de
// gemeten fasen van het filmpje. Op de Oppo oordeelde Joost het als "slaat
// nergens op": te veel piep, te weinig wiel. De volledige ronde staat in de
// git-geschiedenis (af54d81); de lessen die bleven staan zijn de fasen van
// het filmpje en de koppeling van geluid en trilling aan één start/stop.
//
// **Ronde 2: de echte opname.** Joosts keuze: je hoort de fiets **opstarten
// en uitrijden**. Bron is een echte fietsopname waaruit `tool/
// rolling_intro_sound.py` het in-grijpende pedaal en de optrekkende rammel
// uit het begin haalt en de uitdunnende uitrij van het eind; de zeven
// seconden gelijkmatig geratel in het midden vervallen (zijn woorden: "haal
// het middenstuk eruit"). De clip duurt 2,03 s en begint op 1,0 s in de
// intro: zodra de morph de fiets vorm geeft, grijpt het pedaal in, trekt
// het geratel op met de renner die opstapt (1,68-2,0 s) en rijdt de uit de
// intro uit terwijl het geheel omhoog schuift.
//
// **Trillingen.** Elke puls volgt de hoorbaarheid van de clip zelf: het
// meetscript levert per puls een moment, dichter op elkaar waar het
// ratelt, verder uit elkaar in de uitrit. Het zijn er twintig, van de
// in-grijpende klik tot de laatste tok. Eén puls per tik was de keuze van
// Joost; bij een echte rammel is de trouwste vertaling daarvan de densiteit
// van het geluid volgen.
//
// **Eén speler, niet twee.** Ronde 1 speelde tik en tock op twee spelers,
// en op de Oppel bleek uit de logcat dat die twee elkaar bij elke tik de
// audioruimte betwistten (`onAudioFocusChange(-1)` rond elke afspeling):
// de tweede speler steelt de focus van de eerste. Eén speler kan dat
// zichzelf niet aandoen.

import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// De intro-tijd waarop de clip begint. Afgeleid, niet gekozen: de morph
/// waait vanaf circa 1,0 s naar de fiets, en het geluid hoort bij een fiets
/// die bestaat. De in-grijpende klik van het pedaal valt daardoor op circa
/// 1,06 s, vlak nadat de fiets vorm krijgt.
const kRollingClipStart = Duration(milliseconds: 1000);

/// Hoe lang de clip duurt. Ook afgeleid: 2,53 s gemeten (ronde 3: Joost
/// wilde de uitrij horen uitlopen "dat je hem uit hoort te trappen", dus het
/// eindsegment loopt door tot de opname zelf stopt), beginnend op 1,0 s
/// betekent dat de uitrij tot circa 3,5 s doorloopt. De intro zelf is op
/// 2,47 s afgelopen; het geluid rijdt die seconde erachter nog uit, en
/// daarna moet het stil zijn onder de titel.
const kRollingClipDuration = Duration(milliseconds: 2525);

/// De trillingsmomenten, gemeten aan de clip zelf (tool/
/// rolling_intro_sound.py): de som van de genormaliseerde amplitude bepaalt
/// wanneer de volgende puls valt, met een minimale tussenpoes van 70 ms --
/// korter voelt aan als één zoem in plaats van als een rit. De reeks
/// versnelt van de in-grijpende klik (61 ms in de clip) via de volle rammel
/// (pulsen op de 70 ms-vloer) naar de uitdunnende uitrij, die in ronde 3
/// lang doorloopt: de laatste tussenpozen zijn 146, 189 en 236 ms.
/// Intro-tijd = clip-tijd + 1000.
const kRollingHaptics = <Duration>[
  Duration(milliseconds: 1061),
  Duration(milliseconds: 1152),
  Duration(milliseconds: 1276),
  Duration(milliseconds: 1346),
  Duration(milliseconds: 1416),
  Duration(milliseconds: 1486),
  Duration(milliseconds: 1556),
  Duration(milliseconds: 1626),
  Duration(milliseconds: 1696),
  Duration(milliseconds: 1766),
  Duration(milliseconds: 1836),
  Duration(milliseconds: 1906),
  Duration(milliseconds: 1976),
  Duration(milliseconds: 2046),
  Duration(milliseconds: 2116),
  Duration(milliseconds: 2186),
  Duration(milliseconds: 2256),
  Duration(milliseconds: 2326),
  Duration(milliseconds: 2396),
  Duration(milliseconds: 2466),
  Duration(milliseconds: 2536),
  Duration(milliseconds: 2606),
  Duration(milliseconds: 2752),
  Duration(milliseconds: 2941),
  Duration(milliseconds: 3177),
];

/// De klok van deze tijdlijn start in `initState`, samen met de
/// settle-timer van het scherm; het beeld begint pas als de eerste frame van
/// de WebP gedecodeerd is. Deze constante schuift het geluid evenver op als
/// die decodering naar verwachting duurt. De intro begint met 276 ms
/// stilstaand beeld, dus de schatting hoeft niet exact te zijn. Bijstellen
/// doe je op het toestel: valt de in-grijpende klik duidelijk vóór de
/// werveling, verhoog dan; valt hij er ver na, verlaag dan.
const kSpokeTrackStartDelay = Duration(milliseconds: 150);

/// Speelt de clip en de trillingen. Die twee zitten bewust samen achter één
/// start/stop: ze delen één tijdlijn en kunnen zo nooit van elkaar
/// afdriften.
abstract class SpokeTrackPlayer {
  /// Start de tijdlijn op de klok van nu. Twee keer starten hoort niet voor
  /// te komen; het scherm start één keer en stopt bij overslaan of
  /// afbraak.
  void start();

  /// Breekt de rit af: geen geluid meer, geen trilling meer. Idempotent.
  void stop();
}

/// De echte speler: één `AudioPlayer` in lowLatency-stand (SoundPool op
/// Android, bedoeld voor korte geluiden) voor de clip, en
/// `HapticFeedback.selectionClick` per puls, het korte klikje dat de app
/// ook elders voor kleine bevestigingen gebruikt.
class AudioSpokeTrackPlayer implements SpokeTrackPlayer {
  AudioSpokeTrackPlayer() : _player = AudioPlayer();

  final AudioPlayer _player;
  final List<Timer> _timers = [];
  bool _stopped = false;
  bool _audioFailureLogged = false;

  @override
  void start() {
    if (_stopped) return;
    // De speler opzetten kost een platform-kanaalronde; de clip zit ruim
    // een seconde verder, dus niet awaiten: de tijdlijn vertrekt op de
    // klok van de intro, niet op die van de audiostack.
    unawaited(_prepare());
    _timers.add(
      Timer(
        kSpokeTrackStartDelay + kRollingClipStart,
        _playClip,
      ),
    );
    for (final pulse in kRollingHaptics) {
      _timers.add(
        Timer(
          kSpokeTrackStartDelay + pulse,
          _pulse,
        ),
      );
    }
  }

  Future<void> _prepare() async {
    try {
      await _player.setPlayerMode(PlayerMode.lowLatency);
    } catch (error) {
      _logBrokenAudio(error);
    }
  }

  void _pulse() {
    if (_stopped) return;
    // De trilling zonder bewaking van de audiostack: het trillingskanaal
    // is er altijd, en de rit mag nooit afhangen van het geluid.
    HapticFeedback.selectionClick();
  }

  void _playClip() {
    if (_stopped) return;
    unawaited(() async {
      try {
        // De clip is door het meetscript op piek 0,75 genormaliseerd; op
        // vol volume blijft hij onder de overstuur en draagt hij ver
        // genoeg door op een telefoonspeaker.
        await _player.play(
          AssetSource('sounds/welcome_roll.wav'),
          volume: 1.0,
        );
      } catch (error) {
        _logBrokenAudio(error);
      }
    }());
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
    unawaited(_player.dispose());
  }

  void _logBrokenAudio(Object error) {
    // Eén keer melden, niet per afspeling: ontbreekt het audioplatform dan
    // faalt elke afspeling op dezelfde manier. En dit is geen "stille tak"
    // voor de gebruiker: op de intro valt niets op te lossen, en hij moet
    // doorlopen, met of zonder wiel.
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
