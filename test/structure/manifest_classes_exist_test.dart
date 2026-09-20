// Elke klasse die AndroidManifest.xml noemt, moet ook echt bestaan.
//
// Waarom deze test bestaat
// ------------------------
// Op 2026-06-03 kwam er een receiver in de manifest te staan:
// `be.tramckrijte.workmanager.RescheduleOnBootReceiver`. Die klasse bestond
// toen al niet meer -- workmanager heet sinds 0.6 `dev.fluttercommunity.
// workmanager` en heeft helemaal geen boot-receiver. Niets merkte het: de
// build slaagt, `flutter analyze` kijkt niet in XML, en Android instantieert
// een receiver pas op het moment dat hij vuurt. Drie maanden later, op een
// toestel dat opnieuw opstartte, crashte het proces met een
// ClassNotFoundException voordat er een scherm was. Gevonden in de logcat van
// build 45, op 2026-09-20.
//
// Een klassenaam in XML is een string die niemand controleert. Deze test is
// die controle: staat er een component in de manifest, dan hoort er code bij.
//
// Wat de test doet
// ----------------
// Eigen klassen (`.MainActivity`, of de volledige naam onder het eigen
// pakket) moeten een `.kt`-bestand hebben. Klassen van derden kunnen we hier
// niet compileren, dus die staan in `_vanDerden` met de reden erbij -- een
// nieuwe naam toevoegen vraagt dan om een bewuste regel, niet om een gok.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _manifest = 'android/app/src/main/AndroidManifest.xml';
const _eigenPakket = 'com.fanalists.ridewindow.ridewindow';
const _kotlinRoot = 'android/app/src/main/kotlin';

/// Klassen van buiten het project, met de reden waarom ze hier mogen staan.
const _vanDerden = <String, String>{
  'androidx.work.impl.foreground.SystemForegroundService':
      'Komt uit androidx.work, dat workmanager_android meebrengt. Staat hier '
          'alleen om er foregroundServiceType="dataSync" aan te hangen.',
};

void main() {
  test('elke component in AndroidManifest.xml wijst naar bestaande code', () {
    final file = File(_manifest);
    expect(file.existsSync(), isTrue, reason: '$_manifest ontbreekt');

    // Commentaar eruit: een klassenaam in een toelichting (zoals de uitleg bij
    // de verwijderde receiver) is geen declaratie.
    final xml = file.readAsStringSync().replaceAll(
          RegExp(r'<!--.*?-->', dotAll: true),
          '',
        );

    // Alleen de componenten zelf. Permissies, intent-acties en meta-data
    // dragen ook een android:name, maar dat zijn geen klassen.
    final componenten = RegExp(
      r'<(activity|service|receiver|provider)\b[^>]*?android:name="([^"]+)"',
      dotAll: true,
    );

    final ontbreekt = <String>[];

    for (final match in componenten.allMatches(xml)) {
      final naam = match.group(2)!;
      final volledig = naam.startsWith('.') ? '$_eigenPakket$naam' : naam;

      if (volledig.startsWith('$_eigenPakket.')) {
        final pad = '$_kotlinRoot/${volledig.replaceAll('.', '/')}.kt';
        if (!File(pad).existsSync()) {
          ontbreekt.add('$naam -> geen bestand op $pad');
        }
        continue;
      }

      if (!_vanDerden.containsKey(volledig)) {
        ontbreekt.add(
          '$naam -> klasse van buiten het project en niet in _vanDerden. '
          'Controleer of de klasse echt bestaat in de versie die in '
          'pubspec.lock staat, en zet hem daarna met een reden in de lijst.',
        );
      }
    }

    expect(
      ontbreekt,
      isEmpty,
      reason: 'AndroidManifest.xml noemt code die er niet is. Android merkt '
          'dat pas als het component vuurt, en dan crasht de app:\n'
          '${ontbreekt.join('\n')}',
    );
  });
}
