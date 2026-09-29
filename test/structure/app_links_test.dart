// Een gedeelde link opent de app pas als vijf bestanden het met elkaar eens
// zijn: de linkconstanten, het intent-filter, assetlinks.json, firebase.json
// en index.html. Gaat er één uit de pas, dan valt Android zonder melding terug
// op Chrome, en dat zie je pas op een toestel, na een deploy. Vandaar deze
// test, die alleen de bestanden leest.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/features/peloton/group_link.dart';
import 'package:ridewindow/features/peloton/invite_landing_screen.dart';

// De Play-sleutel (gelezen uit de Play-APK op de Oppo, build 61) en de
// uploadsleutel. De eerste tekent wat testers via Play krijgen.
const _playSigningSha256 =
    '17:A9:37:85:89:14:A2:E9:D9:BD:C7:CF:5B:DC:16:CA:C8:EB:EC:69:E0:D5:A1:73:BC:CF:67:5A:61:3A:1B:6F';

void main() {
  final invite = Uri.parse(kInviteLinkBase);
  final group = Uri.parse(kGroupLinkBase);
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  test('de links zijn padlinks op één host', () {
    expect(invite.fragment, isEmpty);
    expect(group.fragment, isEmpty);
    expect(invite.host, group.host);
    expect(invite.path, '/invite');
    expect(group.path, '/group');
  });

  test('het intent-filter verifieert die host en die paden', () {
    final filter = RegExp(
      r'<intent-filter android:autoVerify="true">(.*?)</intent-filter>',
      dotAll: true,
    ).firstMatch(manifest);
    expect(
      filter,
      isNotNull,
      reason: 'zonder autoVerify vraagt Android elke keer met welke app de '
          'link open moet',
    );
    final body = filter!.group(1)!;
    expect(body, contains('android:scheme="https"'));
    expect(body, contains('android:host="${invite.host}"'));
    expect(body, contains('android:pathPrefix="${invite.path}/"'));
    expect(body, contains('android:pathPrefix="${group.path}/"'));
  });

  test('assetlinks.json hoort bij deze app en de Play-sleutel', () {
    final gradle = File('android/app/build.gradle.kts').existsSync()
        ? File('android/app/build.gradle.kts').readAsStringSync()
        : File('android/app/build.gradle').readAsStringSync();
    final appId =
        RegExp(r'applicationId\s*=?\s*"([^"]+)"').firstMatch(gradle)!.group(1);

    final statements = jsonDecode(
      File('web/.well-known/assetlinks.json').readAsStringSync(),
    ) as List;
    final target = (statements.single as Map)['target'] as Map;
    expect(target['package_name'], appId);
    expect(target['sha256_cert_fingerprints'], contains(_playSigningSha256));
  });

  test('firebase.json rolt .well-known mee uit', () {
    final config =
        jsonDecode(File('firebase.json').readAsStringSync()) as Map;
    final ignore = (config['hosting'] as Map)['ignore'] as List;
    expect(
      ignore,
      isNot(contains('**/.*')),
      reason: 'dat patroon sluit elke map met een punt uit, ook .well-known',
    );
  });

  test('de website zet de padlink om naar de hash-route', () {
    final html = File('web/index.html').readAsStringSync();
    expect(html, contains('(invite|group)'));
    expect(html, contains("'/#/'"));
  });

  test('de app verklaart de site, voor "Openen in app" op de website', () {
    expect(manifest, contains('android:name="asset_statements"'));
    final strings =
        File('android/app/src/main/res/values/strings.xml').readAsStringSync();
    expect(strings, contains('https://${invite.host}'));
  });
}
