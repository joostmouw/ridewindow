// lib/core/app_version.dart
//
// De versie zoals de app hem aan de gebruiker toont.
//
// Waarom een constante en geen `package_info_plus`: dat zou een nieuwe
// dependency zijn voor één regel tekst, en de tech-stack in CLAUDE.md is
// bewust kort gehouden. De prijs van een constante is dat hij kan gaan
// afwijken van `pubspec.yaml` — precies wat hier gebeurd was, waar
// `profile_screen.dart` `'1.0.0'` toonde terwijl de app op 1.0.18+19 stond.
//
// Die prijs wordt betaald door `test/core/app_version_test.dart`: die leest
// `pubspec.yaml` en faalt zodra deze twee uit de pas lopen. Bump je de versie,
// dan wijst de test je hierheen.
//
// Het buildnummer staat er bewust bij. Fase 21 heeft twee sessies verloren aan
// "welke build draait hier eigenlijk?" — één keer omdat Play een oudere track
// serveerde, één keer omdat een lokale build niet ververst was. Een versienaam
// zonder buildnummer beantwoordt die vraag niet.
const kAppVersionName = '1.0.18';
const kAppBuildNumber = '19';

/// Wat het profielscherm toont: `1.0.18 (19)`.
const kAppVersionDisplay = '$kAppVersionName ($kAppBuildNumber)';
