import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _withoutComments(String source) {
  return source
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
      .replaceAll(RegExp(r'//.*'), '');
}

void main() {
  test(
    'Profiel openen gebruikt geen promptende lightweight Google-authenticatie',
    () {
      final calendar = _withoutComments(
        File('lib/services/calendar_service.dart').readAsStringSync(),
      );
      final profile = _withoutComments(
        File('lib/features/profile/profile_screen.dart').readAsStringSync(),
      );

      expect(
        calendar,
        isNot(contains('attemptLightweightAuthentication')),
        reason: 'De Android-implementatie kan hiermee een accountkiezer tonen. '
            'Gebruik de lokale Calendar-identiteitscache.',
      );
      expect(profile, isNot(contains('currentGoogleEmail')));
      expect(profile, contains('cachedCalendarAccountEmail'));
    },
  );
}
