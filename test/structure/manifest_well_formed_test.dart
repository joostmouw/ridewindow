// AndroidManifest.xml moet geldige XML zijn.
//
// Waarom deze test bestaat
// ------------------------
// Op 2026-09-21 kwam er een toelichting bij het nieuwe `<queries>`-blok te
// staan, in dezelfde schrijfstijl als de rest van de repo. Die stijl gebruikt
// `--` als gedachtestreepje, en in XML is `--` binnen een comment verboden. De
// manifest werd daarmee onparseerbaar.
//
// Niets merkte het. `flutter analyze` kijkt niet in XML, `flutter test` kwam er
// niet langs, en de fout kwam pas boven bij `assembleRelease`, als
// `ManifestMerger2$MergeFailureException` met alleen "Error parsing" erbij. Op
// een dag waarop niemand toevallig een release-APK bouwt, was dit meegegaan
// naar de volgende build die wél moest slagen.
//
// Dit is dezelfde familie als `manifest_classes_exist_test.dart`: de manifest
// is een bestand dat niemand controleert tot Android er over valt. Die test
// bewaakt de inhoud, deze de vorm.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

const _manifests = <String>[
  'android/app/src/main/AndroidManifest.xml',
  'android/app/src/debug/AndroidManifest.xml',
  'android/app/src/profile/AndroidManifest.xml',
];

void main() {
  for (final pad in _manifests) {
    test('$pad is geldige XML', () {
      final bestand = File(pad);
      if (!bestand.existsSync()) return; // debug/profile zijn optioneel

      final bron = bestand.readAsStringSync();

      expect(
        () => XmlDocument.parse(bron),
        returnsNormally,
        reason: 'Onparseerbare manifest.',
      );

      // Apart gecontroleerd, want het `xml`-pakket is hier toegeeflijker dan
      // Android. De XML-spec verbiedt `--` binnen een comment; `XmlDocument`
      // slikt het, de manifest-merger van AGP niet. Die geeft dan alleen
      // "Error parsing" zonder regelnummer, tijdens `assembleRelease`, dus
      // uren nadat je het hebt geschreven. Precies wat er op 2026-09-21
      // gebeurde.
      for (final match
          in RegExp(r'<!--(.*?)-->', dotAll: true).allMatches(bron)) {
        expect(
          match.group(1),
          isNot(contains('--')),
          reason: 'Comment in $pad bevat `--`. In XML mag dat niet. Gebruik '
              'een komma of een puntkomma in plaats van het gedachtestreepje '
              'dat de rest van deze repo gebruikt.',
        );
      }
    });
  }

  test('AndroidManifest declareert queries voor https, anders zwijgen links',
      () {
    // Zonder dit blok geeft `canLaunchUrl` op Android 11+ false voor elke
    // https-URL, ook met een browser op het toestel. Dat is hoe de rij "Privacy
    // Policy" in Profiel maandenlang niets deed. `url_launcher_android` brengt
    // deze declaratie niet zelf mee, dus hij moet hier staan.
    final doc = XmlDocument.parse(
      File(_manifests.first).readAsStringSync(),
    );

    final heeftHttpsView = doc
        .findAllElements('queries')
        .expand((q) => q.findElements('intent'))
        .any((intent) {
      final actie = intent.findElements('action').any((a) =>
          a.getAttribute('android:name') == 'android.intent.action.VIEW');
      final https = intent
          .findElements('data')
          .any((d) => d.getAttribute('android:scheme') == 'https');
      return actie && https;
    });

    expect(
      heeftHttpsView,
      isTrue,
      reason: 'Geen <queries> met VIEW + scheme https. Elke externe link in de '
          'app opent dan mogelijk niets op Android 11+.',
    );
  });

  test('AndroidManifest declareert het ridewindow-schema voor de '
      'e-mailbevestiging', () {
    // De bevestigingsmail van Supabase stuurt de browser door naar
    // ridewindow://confirm?code=... (kEmailConfirmRedirect). Zonder dit
    // intent-filter vangt niemand die URL op en eindigt de bevestiging op
    // een dood adres. De SDK verwerkt de code zelf; dit filter is de enige
    // Android-kant die de app zelf moet declareren.
    final doc = XmlDocument.parse(
      File(_manifests.first).readAsStringSync(),
    );

    final mainActivity = doc
        .findAllElements('activity')
        .firstWhere((a) => a.getAttribute('android:name') == '.MainActivity');

    final heeftDeepLink = mainActivity
        .findAllElements('intent-filter')
        .any((filter) {
      final view = filter
          .findElements('action')
          .any((a) => a.getAttribute('android:name') == 'android.intent.action.VIEW');
      final browsable = filter
          .findElements('category')
          .any((c) => c.getAttribute('android:name') == 'android.intent.category.BROWSABLE');
      final schema = filter
          .findElements('data')
          .any((d) => d.getAttribute('android:scheme') == 'ridewindow');
      return view && browsable && schema;
    });

    expect(
      heeftDeepLink,
      isTrue,
      reason: 'MainActivity mist het intent-filter voor het ridewindow-schema. '
          'De e-mailbevestiging kan dan nooit terug naar de app.',
    );
  });
}
