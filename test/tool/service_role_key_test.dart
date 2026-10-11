import 'dart:io';

import 'package:test/test.dart';

import '../../tool/src/service_role_key.dart';

void main() {
  group('firstKey', () {
    test('slaat een meegeplakte regel voor de sleutel over', () {
      expect(firstKey('commandoregel\neyJa.eyJb.sig\n'), 'eyJa.eyJb.sig');
    });

    test('accepteert het sb_secret_-formaat', () {
      expect(firstKey('sb_secret_abc_DEF-1'), 'sb_secret_abc_DEF-1');
    });

    test('geeft null bij tekst die nergens op lijkt', () {
      expect(firstKey('geen sleutel hier'), isNull);
    });

    test('geeft null bij een JWT met maar twee delen', () {
      expect(firstKey('eyJa.eyJb'), isNull);
    });
  });

  group('readServiceRoleKey', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('srk_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('leest het bestand achter --key', () {
      final path = '${dir.path}/key';
      File(path).writeAsStringSync('meegeplakt\nsb_secret_uitbestand\n');
      expect(readServiceRoleKey(['--key', path]), 'sb_secret_uitbestand');
    });

    test('geeft null als het bestand achter --key ontbreekt', () {
      expect(readServiceRoleKey(['--key', '${dir.path}/bestaat-niet']), isNull);
    });

    test('geeft null als het bestand geen sleutelvormige regel heeft', () {
      final path = '${dir.path}/key';
      File(path).writeAsStringSync('dart run tool/analytics_report.dart\n');
      expect(readServiceRoleKey(['--key', path]), isNull);
    });
  });

  group('argumenten', () {
    test('stringArg geeft de waarde na de vlag', () {
      expect(stringArg(['--days', '30'], '--days'), '30');
    });

    test('stringArg geeft null als de waarde ontbreekt', () {
      expect(stringArg(['--days'], '--days'), isNull);
    });

    test('intArg geeft null bij een niet-getal', () {
      expect(intArg(['--days', 'x'], '--days'), isNull);
    });

    test('intArg leest een getal', () {
      expect(intArg(['--days', '7'], '--days'), 7);
    });
  });
}
