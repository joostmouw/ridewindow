/// Structuurtest voor de spaakgeluiden van de welkomstintro.
///
/// Het klassieke falingspad van een geluidsasset is stil: het bestand staat
/// in de repo maar niet in de pubspec-assets, en de build draait gewoon
/// door, alleen zonder geluid. Deze test bewaakt de drie onderdelen samen:
/// de bestanden zelf, de pubspec-registratie en het recept waarmee ze
/// gegenereerd zijn (tool/spoke_tick_sound.py), zodat de klank altijd
/// reproduceerbaar blijft.

library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('de spaakgeluiden bestaan, zijn echte wav-bestanden en zijn'
      ' geregistreerd', () {
    for (final name in ['spoke_tick.wav', 'spoke_tock.wav']) {
      final file = File('assets/sounds/$name');

      expect(
        file.existsSync(),
        isTrue,
        reason: 'assets/sounds/$name ontbreekt; genereer het met '
            'python3 tool/spoke_tick_sound.py',
      );

      final bytes = file.readAsBytesSync();
      expect(
        bytes.length,
        greaterThan(44),
        reason: 'assets/sounds/$name is te klein voor een wav met geluid',
      );

      // De RIFF-header: zonder dit is het geen wav, en de audioplugin
      // faalt dan pas op het toestel.
      expect(
        String.fromCharCodes(bytes.take(4)),
        'RIFF',
        reason: 'assets/sounds/$name heeft geen RIFF-header',
      );
    }

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      contains('assets/sounds/'),
      reason: 'staat de map niet in de pubspec-assets, dan is het geluid '
          'stil afwezig in de release-build: geen fout, alleen geen wiel',
    );

    expect(
      File('tool/spoke_tick_sound.py').existsSync(),
      isTrue,
      reason: 'het geluid is deterministisch gegenereerd; zonder het script '
          'is de klank niet meer aan te passen, alleen opnieuw te vinden',
    );
  });
}
