import 'dart:io';

import 'package:test/test.dart';

const _forbidden = <String>[
  'package:flutter/',
  'dart:io',
  'dart:ui',
  'package:http',
  'package:drift',
  'package:shared_preferences',
  'package:hive',
  'package:path_provider',
];

void main() {
  test('lib/domain/ has zero Flutter/IO imports (SCOR-03)', () async {
    final domainDir = Directory('lib/domain');
    expect(domainDir.existsSync(), isTrue, reason: 'lib/domain/ must exist');

    final violations = <String>[];

    await for (final entity in domainDir.list(recursive: true)) {
      if (entity is! File) continue;
      final path = entity.path;
      if (!path.endsWith('.dart')) continue;
      // Generated files are exempt — they legitimately import package:freezed_annotation et al.
      if (path.endsWith('.freezed.dart') || path.endsWith('.g.dart')) continue;

      final source = await entity.readAsString();
      for (final forbidden in _forbidden) {
        final pattern = RegExp("import\\s+['\"]${RegExp.escape(forbidden)}");
        if (pattern.hasMatch(source)) {
          violations.add('$path: imports $forbidden');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
