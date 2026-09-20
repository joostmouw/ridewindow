// Geen kwadraatstreepjes in wat de gebruiker leest.
//
// Regel van Joost (2026-09-19): "never any em dashes within the app". Er stonden
// er toen 36 -- 34 in de twee ARB-bestanden en twee in de Agenda-code.
//
// Waarom dit een structuurtest is en geen afspraak in een document
// ---------------------------------------------------------------
// Een em-dash komt de app binnen via een zin die iemand schrijft, niet via
// code die iemand aanroept. Een widget-test ziet hem alleen als die ene zin
// toevallig in beeld staat; een code-review ziet hem alleen als de lezer op
// leestekens let. Deze test leest alle teksten tegelijk, ook die van morgen.
//
// Wat hier NIET onder valt: de en-dash. Die staat in bereiken (`Ma-Vr`,
// `06:00-09:00`, `17:00 - 19:00`) en betekent "tot en met" -- dat is een andere
// betekenis en een ander teken, en die blijft.
//
// Commentaar telt niet mee: dat leest alleen een ontwikkelaar. Logregels en
// assert-teksten wél -- een uitzondering daarvoor zou de regel tot een
// afweging maken, en dan glipt er weer eentje door.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _emDash = '—';

/// Haalt regelcommentaar weg, zodat een em-dash in een toelichting deze test
/// niet laat vallen. Zelfde aanpak als `back_affordance_test.dart`.
String _stripComments(String source) {
  final withoutBlocks = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return withoutBlocks
      .split('\n')
      .map((line) {
        final index = line.indexOf('//');
        return index == -1 ? line : line.substring(0, index);
      })
      .join('\n');
}

void main() {
  test('geen enkele vertaalde tekst draagt een em-dash', () {
    final offenders = <String>[];

    for (final name in const ['app_nl.arb', 'app_en.arb']) {
      final file = File('lib/l10n/$name');
      expect(file.existsSync(), isTrue, reason: '$name moet bestaan');

      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      map.forEach((key, value) {
        // Sleutels die met @ beginnen zijn metadata (placeholders,
        // beschrijvingen) en komen nooit op het scherm.
        if (key.startsWith('@')) return;
        if (value is String && value.contains(_emDash)) {
          offenders.add('$name → $key');
        }
      });
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Em-dashes horen niet in de app. Gebruik een dubbele punt als er '
          'een verklaring volgt, een komma bij een bijstelling, of een punt als '
          'het twee zinnen waren.\n${offenders.join('\n')}',
    );
  });

  test('geen enkele letterlijke tekst in lib/ draagt een em-dash', () {
    final offenders = <String>[];
    // Twee vormen: een enkel- en een dubbelgequote literal op een regel.
    // Zowel het letterlijke teken als de escape `\\u2014`: die tweede vorm
    // stond op 2026-09-20 nog zes keer in het ritdetail, als streepje voor een
    // ontbrekende meting, en glipte langs de eerste versie van deze test.
    final singleQuoted = RegExp("'[^'\\n]*(\u2014|\\\\u2014)[^'\\n]*'");
    final doubleQuoted = RegExp('"[^"\\n]*(\u2014|\\\\u2014)[^"\\n]*"');

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      // Gegenereerde bestanden volgen hun bron; die bron staat hierboven al
      // onder de loep.
      if (entity.path.endsWith('.g.dart') ||
          entity.path.endsWith('.freezed.dart') ||
          entity.path.contains('/l10n/')) {
        continue;
      }

      final source = _stripComments(entity.readAsStringSync());
      for (final match in [
        ...singleQuoted.allMatches(source),
        ...doubleQuoted.allMatches(source),
      ]) {
        // Ook logregels en assert-teksten: de regel is "geen em-dashes", en
        // een uitzondering voor ontwikkelaarsteksten maakt hem meteen een
        // kwestie van uitleggen welke tekst waar terechtkomt. Dat is precies
        // hoe er weer eentje binnenkomt.
        offenders.add('${entity.path}: ${match.group(0)}');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // De teksten die buiten `lib/` om bij een gebruiker komen. Joost las ze op
  // 2026-09-20 terug in de Play Store, vol kwadraatstreepjes: de regel gold
  // wel voor de app en niet voor de winkelpagina, en dus dreef het uit
  // elkaar. Wat een tester of een bezoeker leest, telt hier mee.
  test('geen em-dash in de teksten die buiten de app om gelezen worden', () {
    const paths = ['docs/store-listing.md', 'docs/testers/changelog.md'];
    final offenders = <String>[];

    for (final path in paths) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path bestaat niet meer');
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains(_emDash)) offenders.add('$path:${i + 1}: ${lines[i]}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Em-dashes horen ook niet in wat een tester of een bezoeker '
          'van de winkelpagina leest. Gebruik een dubbele punt of een punt.\n'
          '${offenders.join('\n')}',
    );
  });
}
