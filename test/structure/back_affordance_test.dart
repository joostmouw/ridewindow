// Elk scherm buiten de onderbalk moet een eigen terugknop hebben.
//
// Waarom dit een structuurtest is en geen widget-test
// ---------------------------------------------------
// Op Android brengt de systeemveeg je altijd terug, dus een ontbrekende knop
// valt daar niet op. Op de iOS-webapp in standalone-modus bestaat die veeg
// niet en is er ook geen browserbalk: een scherm zonder knop is dan een
// doodlopende weg. Dat is precies wat backlog #63 meldde -- een iPhone-tester
// die niet uit het beschikbaarheidsscherm kwam.
//
// Flutter's impliciete terugknop is hier geen vangnet, eerder het tegendeel:
// die verschijnt alleen als er iets te poppen valt. Kom je binnen via
// `context.go()` of via een deeplink, dan is er niets te poppen en toont
// Flutter dus géén knop -- juist in het geval waarin je hem het hardst nodig
// hebt. `SafeBackButton` valt in dat geval terug op Home.
//
// Een widget-test zou één scherm dekken. Deze test dekt ze allemaal, ook die
// nog niet bestaan.

import 'dart:io';

import 'package:test/test.dart';

/// Schermen die in de `StatefulShellRoute` zitten. Daar is de onderbalk de weg
/// terug, dus een eigen knop zou een tweede, tegenstrijdige uitweg zijn.
///
/// Staat een scherm hier ten onrechte in, dan is het gevolg een doodlopende
/// weg op iOS. Voeg hier dus alleen iets toe als het werkelijk een tab is.
const _shellScreens = <String>{
  'lib/features/home/home_screen.dart',
  'lib/features/agenda/week_agenda_screen.dart',
  'lib/features/planned/planned_rides_screen.dart',
  'lib/features/profile/profile_screen.dart',
};

/// Schermen met een eigen, bewust andere uitweg dan `SafeBackButton`.
const _ownAffordance = <String, String>{
  // Onboarding heeft een eigen caretLeft naar /welcome: van daaruit terug naar
  // Home zou je de preset-keuze laten overslaan die het scherm juist vraagt.
  'lib/features/onboarding/onboarding_screen.dart':
      'eigen caretLeft-knop naar /welcome',
};


/// Haalt regelcommentaar weg, zodat een uitleg over een knop niet voor de knop
/// zelf wordt aangezien. Strings met `//` erin bestaan in deze bestanden niet
/// op een manier die hier misgaat; het gaat om een vangnet, niet om een parser.
String _withoutComments(String source) => source
    .split('\n')
    .map((line) {
      final i = line.indexOf('//');
      return i < 0 ? line : line.substring(0, i);
    })
    .join('\n');

void main() {
  test('elk scherm buiten de onderbalk heeft een SafeBackButton', () async {
    final featuresDir = Directory('lib/features');
    expect(featuresDir.existsSync(), isTrue);

    final violations = <String>[];

    await for (final entity in featuresDir.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final path = entity.path;
      if (_shellScreens.contains(path)) continue;
      if (_ownAffordance.containsKey(path)) continue;

      // Commentaar eruit vóór we iets toetsen. De eerste versie van deze test
      // vond `SafeBackButton` terug in een commentaarregel die uitlegde waarom
      // de knop er stond -- en gaf groen terwijl de knop zelf was verdwenen.
      final source = _withoutComments(await entity.readAsString());

      // Alleen schermen met een eigen AppBar: sheets, kaarten en losse widgets
      // leven binnen een scherm dat de uitweg al heeft.
      final hasAppBar = source.contains('appBar: AppBar(') ||
          source.contains('appBar: _buildAppBar(');
      if (!hasAppBar) continue;

      // Met haakje: de aanroep, niet de naam.
      if (!source.contains('SafeBackButton(')) {
        violations.add(path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Deze schermen hebben een AppBar maar geen SafeBackButton, en '
          'zijn daardoor een doodlopende weg op de iOS-webapp:\n'
          '  ${violations.join('\n  ')}\n\n'
          'Zit het scherm in de onderbalk, zet het dan in _shellScreens. '
          'Heeft het bewust een andere uitweg, zet het in _ownAffordance.',
    );
  });

  test('de vier tabs van de onderbalk bestaan nog', () async {
    // Verdwijnt een tab uit de shell zonder dat hij een knop krijgt, dan moet
    // deze test omvallen in plaats van stilletjes mee te bewegen.
    for (final path in _shellScreens) {
      expect(
        File(path).existsSync(),
        isTrue,
        reason: '$path staat in _shellScreens maar bestaat niet meer -- '
            'controleer of dat scherm nog een uitweg heeft.',
      );
    }

    final router = await File('lib/app/router.dart').readAsString();
    expect(router.contains('StatefulShellRoute'), isTrue);
    for (final path in ['/home', '/agenda', '/rides', '/profile']) {
      expect(
        router.contains("path: '$path'"),
        isTrue,
        reason: '$path hoort een tab in de shell te zijn',
      );
    }
  });
}
