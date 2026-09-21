/// Structuurtest voor het wielgeluid van de welkomstintro.
///
/// Het klassieke falingspad van een geluidsasset is stil: het bestand staat
/// in de repo maar niet in de pubspec-assets, en de build draait gewoon
/// door, alleen zonder geluid. Deze test bewaakt de onderdelen samen: het
/// bestand zelf, de pubspec-registratie, het gereedschapsscript waarmee de
/// clip uit de bronopname is gesmeed, en de koppeling tussen de wav en de
/// duur-constante in Dart.

library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/features/welcome/spoke_track.dart';

void main() {
  test('de intro-clip is een echte wav, geregistreerd, en even lang als de'
      ' tijdlijn zegt', () {
    const path = 'assets/sounds/welcome_roll.wav';
    final file = File(path);

    expect(
      file.existsSync(),
      isTrue,
      reason: '$path ontbreekt; genereer de clip met '
          'python3 tool/rolling_intro_sound.py',
    );

    final bytes = file.readAsBytesSync();
    expect(
      bytes.length,
      greaterThan(44),
      reason: '$path is te klein voor een wav met geluid',
    );

    // De RIFF-header: zonder dit is het geen wav, en de audioplugin faalt
    // dan pas op het toestel.
    expect(
      String.fromCharCodes(bytes.take(4)),
      'RIFF',
      reason: '$path heeft geen RIFF-header',
    );

    // De duur uit de wav zelf naast de Dart-constante: drift tussen de
    // clip en de tijdlijn betekent trillingen die los van het geluid gaan.
    final sampleRate =
        bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);
    final dataIndex = _findDataChunk(bytes);
    expect(dataIndex, greaterThan(0), reason: '$path heeft geen data-chunk');
    final dataSize = bytes[dataIndex + 4] |
        (bytes[dataIndex + 5] << 8) |
        (bytes[dataIndex + 6] << 16) |
        (bytes[dataIndex + 7] << 24);
    final duration = Duration(
      milliseconds: (dataSize / (sampleRate * 2) * 1000).round(),
    );
    expect(
      (duration - kRollingClipDuration).inMilliseconds.abs(),
      lessThanOrEqualTo(10),
      reason: 'de wav duurt $duration maar de tijdlijn zegt '
          '$kRollingClipDuration; draai tool/rolling_intro_sound.py en neem '
          'de geprinte duur over',
    );

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      contains('assets/sounds/'),
      reason: 'staat de map niet in de pubspec-assets, dan is het geluid '
          'stil afwezig in de release-build: geen fout, alleen geen wiel',
    );

    expect(
      File('tool/rolling_intro_sound.py').existsSync(),
      isTrue,
      reason: 'de clip komt uit Joosts bronopname en is door dit script '
          'gesmeed; zonder het script is het geluid niet reproduceerbaar',
    );
  });
}

/// Zoekt de `data`-chunk in een RIFF-bestand. De fmt-chunk staat vooraan,
/// maar zijn lengte mag variëren, dus hard gecodeerde posities zijn drift.
int _findDataChunk(List<int> bytes) {
  var offset = 12; // na "RIFF" + grootte + "WAVE"
  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final size = bytes[offset + 4] |
        (bytes[offset + 5] << 8) |
        (bytes[offset + 6] << 16) |
        (bytes[offset + 7] << 24);
    if (id == 'data') return offset;
    offset += 8 + size + (size.isOdd ? 1 : 0); // chunks lopen op woordgrenzen
  }
  return -1;
}
