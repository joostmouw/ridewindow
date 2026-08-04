import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ridewindow/core/app_version.dart';

/// Houdt `lib/core/app_version.dart` gelijk aan `pubspec.yaml`.
///
/// Dit bestaat omdat het profielscherm maandenlang `'1.0.0'` toonde terwijl de
/// app allang veel verder was. Onschuldig ogend, maar in fase 21 kostte
/// "welke build draait hier?" twee toestelsessies — één keer serveerde Play een
/// oudere track, één keer was een lokale build niet ververst. Een versieregel
/// die liegt maakt dat soort diagnose alleen maar trager.
void main() {
  test('kAppVersionName/kAppBuildNumber komen overeen met pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*(\S+)\+(\S+)\s*$', multiLine: true).firstMatch(pubspec);

    expect(
      match,
      isNotNull,
      reason: 'pubspec.yaml moet een regel "version: <naam>+<build>" hebben',
    );

    expect(
      kAppVersionName,
      match!.group(1),
      reason: 'werk lib/core/app_version.dart bij na een versiebump',
    );
    expect(
      kAppBuildNumber,
      match.group(2),
      reason: 'werk lib/core/app_version.dart bij na een versiebump',
    );
  });

  test('de weergavevorm bevat zowel versienaam als buildnummer', () {
    expect(kAppVersionDisplay, contains(kAppVersionName));
    expect(kAppVersionDisplay, contains(kAppBuildNumber));
  });
}
