import 'dart:io';

import 'package:test/test.dart';

import '../../tool/usage/usage_floors.dart';
import '../../tool/usage/usage_rule.dart';

final _yesterday = DateTime.utc(2026, 10, 10);

DayCount _c(
  DateTime day,
  String source,
  int rows, {
  int? max,
  int? distinct,
}) =>
    DayCount(
      day: day,
      source: source,
      rows: rows,
      distinctSenders: distinct,
      maxRowsOneSender: max,
      p95RowsOneSender: null,
    );

/// 28 dagen vóór [_yesterday], elk met [rows] rijen voor [source].
List<DayCount> _baseline(String source, int rows) => [
      for (var i = 1; i <= 28; i++)
        _c(DateTime.utc(2026, 10, 10 - i), source, rows),
    ];

const _floorTotal = {'app_events': 40, 'feedback_anoniem': 40};
const _floorSender = {'app_events': 20};

void main() {
  group('median', () {
    test('lege lijst is 0', () => expect(median([]), 0));
    test('oneven aantal', () => expect(median([3, 1, 2]), 2));
    test('even aantal', () => expect(median([1, 2, 3, 4]), 2.5));
  });

  group('findOutliers, regel totaal', () {
    test('60 tegen een mediaan van 10 en vloer 40 is een uitschieter', () {
      final out = findOutliers(
        [..._baseline('app_events', 10), _c(_yesterday, 'app_events', 60)],
        _yesterday,
        floorTotal: _floorTotal,
        floorSender: _floorSender,
      );
      expect(out, hasLength(1));
      expect(out.single.source, 'app_events');
      expect(out.single.rule, OutlierRule.totaal);
    });

    test('45 is niet boven vijf keer 10', () {
      final out = findOutliers(
        [..._baseline('app_events', 10), _c(_yesterday, 'app_events', 45)],
        _yesterday,
        floorTotal: _floorTotal,
        floorSender: _floorSender,
      );
      expect(out, isEmpty);
    });

    test('ontbrekende voorgaande dagen tellen als 0: 30 blijft onder de vloer',
        () {
      final out = findOutliers(
        [_c(_yesterday, 'app_events', 30)],
        _yesterday,
        floorTotal: _floorTotal,
        floorSender: _floorSender,
      );
      expect(out, isEmpty);
    });

    test('ontbrekende voorgaande dagen tellen als 0: 41 gaat over de vloer',
        () {
      final out = findOutliers(
        [_c(_yesterday, 'app_events', 41)],
        _yesterday,
        floorTotal: _floorTotal,
        floorSender: _floorSender,
      );
      expect(out.map((o) => o.rule), [OutlierRule.totaal]);
    });
  });

  group('findOutliers, regel eenAfzender', () {
    test('één afzender boven de vloer, ook als het totaal normaal is', () {
      final out = findOutliers(
        [
          ..._baseline('app_events', 30),
          _c(_yesterday, 'app_events', 30, max: 21),
        ],
        _yesterday,
        floorTotal: _floorTotal,
        floorSender: _floorSender,
      );
      expect(out.map((o) => o.rule), [OutlierRule.eenAfzender]);
    });

    test('bron zonder afzender wordt niet op eenAfzender getoetst', () {
      final out = findOutliers(
        [
          ..._baseline('feedback_anoniem', 30),
          _c(_yesterday, 'feedback_anoniem', 30),
        ],
        _yesterday,
        floorTotal: _floorTotal,
        floorSender: _floorSender,
      );
      expect(out, isEmpty);
    });

    test('beide regels op dezelfde bron geven elk een eigen Outlier', () {
      final out = findOutliers(
        [
          ..._baseline('app_events', 10),
          _c(_yesterday, 'app_events', 60, max: 50),
        ],
        _yesterday,
        floorTotal: _floorTotal,
        floorSender: _floorSender,
      );
      expect(
        out.map((o) => o.rule).toSet(),
        {OutlierRule.totaal, OutlierRule.eenAfzender},
      );
      expect(out, hasLength(2));
    });
  });

  group('findOutliers, configuratie', () {
    test('bron zonder vloer gooit UsageConfigError', () {
      expect(
        () => findOutliers(
          [_c(_yesterday, 'nieuwe_bron', 1)],
          _yesterday,
          floorTotal: _floorTotal,
          floorSender: _floorSender,
        ),
        throwsA(isA<UsageConfigError>()),
      );
    });

    test('bron met afzender maar zonder afzendervloer gooit UsageConfigError',
        () {
      expect(
        () => findOutliers(
          [_c(_yesterday, 'feedback_anoniem', 1, max: 1)],
          _yesterday,
          floorTotal: _floorTotal,
          floorSender: _floorSender,
        ),
        throwsA(isA<UsageConfigError>()),
      );
    });

    test('ontbrekende dag gooit UsageConfigError', () {
      expect(
        () => findOutliers(
          _baseline('app_events', 10),
          _yesterday,
          floorTotal: _floorTotal,
          floorSender: _floorSender,
        ),
        throwsA(isA<UsageConfigError>()),
      );
    });

    test('de standaardvloeren dekken elke bron uit kUsageSources', () {
      final counts = [
        for (final s in kUsageSources)
          _c(
            _yesterday,
            s,
            0,
            max: kSenderlessSources.contains(s) ? null : 0,
          ),
      ];
      expect(findOutliers(counts, _yesterday), isEmpty);
    });
  });

  group('Outlier.message', () {
    for (final rule in OutlierRule.values) {
      test('${rule.name}: bron en regel, geen cijfer', () {
        final m = Outlier('app_events', rule).message;
        expect(m, startsWith('uitschieter: app_events, '));
        expect(m, matches(RegExp(r'^uitschieter: [a-z_]+, ')));
        expect(RegExp(r'\d').hasMatch(m), isFalse);
      });
    }

    test('UsageConfigError noemt geen cijfer', () {
      try {
        findOutliers(
          [_c(_yesterday, 'onbekend', 12345)],
          _yesterday,
          floorTotal: _floorTotal,
          floorSender: _floorSender,
        );
        fail('verwachtte UsageConfigError');
      } on UsageConfigError catch (e) {
        expect(RegExp(r'\d').hasMatch(e.toString()), isFalse);
      }
    });
  });

  group('parseCountsCsv', () {
    test('leest twee regels, lege velden worden null', () {
      final rows = parseCountsCsv(
        '2026-10-10,app_events,12,3,8,6.5\n'
        '2026-10-10,feedback_anoniem,0,,,\n',
      );
      expect(rows, hasLength(2));
      expect(rows[0].day, DateTime.utc(2026, 10, 10));
      expect(rows[0].source, 'app_events');
      expect(rows[0].rows, 12);
      expect(rows[0].distinctSenders, 3);
      expect(rows[0].maxRowsOneSender, 8);
      expect(rows[0].p95RowsOneSender, 6.5);
      expect(rows[1].source, 'feedback_anoniem');
      expect(rows[1].rows, 0);
      expect(rows[1].distinctSenders, isNull);
      expect(rows[1].maxRowsOneSender, isNull);
      expect(rows[1].p95RowsOneSender, isNull);
    });

    test('kapotte regel gooit FormatException zonder invoerinhoud', () {
      const geheim = 'postgres://usage_monitor:wachtwoord@pooler';
      try {
        parseCountsCsv('2026-10-10,app_events,12,3,8,6.5\n$geheim\n');
        fail('verwachtte FormatException');
      } on FormatException catch (e) {
        expect(e.message, isNot(contains('wachtwoord')));
        expect(e.message, isNot(contains('usage_monitor')));
        expect(e.source, isNull);
      }
    });

    test('niet-getal gooit FormatException zonder invoerinhoud', () {
      try {
        parseCountsCsv('2026-10-10,app_events,veel,3,8,6.5\n');
        fail('verwachtte FormatException');
      } on FormatException catch (e) {
        expect(e.message, isNot(contains('veel')));
        expect(e.source, isNull);
      }
    });
  });

  group('DayCount.fromJson', () {
    test('leest de rpc-vorm', () {
      final c = DayCount.fromJson({
        'day': '2026-10-10',
        'source': 'app_events',
        'rows': 12,
        'distinct_senders': 3,
        'max_rows_one_sender': 8,
        'p95_rows_one_sender': 6.5,
      });
      expect(c.day, DateTime.utc(2026, 10, 10));
      expect(c.source, 'app_events');
      expect(c.rows, 12);
      expect(c.distinctSenders, 3);
      expect(c.maxRowsOneSender, 8);
      expect(c.p95RowsOneSender, 6.5);
    });

    test('nulls en een p95 als int', () {
      final c = DayCount.fromJson({
        'day': '2026-10-10',
        'source': 'accounts_google',
        'rows': 2,
        'distinct_senders': null,
        'max_rows_one_sender': null,
        'p95_rows_one_sender': 4,
      });
      expect(c.distinctSenders, isNull);
      expect(c.maxRowsOneSender, isNull);
      expect(c.p95RowsOneSender, 4.0);
    });
  });

  group('vloeren en bronnen', () {
    test('kFloorTotal dekt precies de tien bronnen', () {
      expect(kUsageSources, hasLength(10));
      expect(kFloorTotal.keys.toSet(), kUsageSources.toSet());
    });

    test('kFloorSender dekt precies de zes bronnen met afzender', () {
      expect(kFloorSender, hasLength(6));
      expect(
        kFloorSender.keys.toSet(),
        kUsageSources.toSet().difference(kSenderlessSources),
      );
    });

    final migration = File('supabase/migrations/0014_usage_daily_counts.sql');
    test(
      'elke bron staat in migratie 0014',
      () {
        final sql = migration.readAsStringSync();
        for (final s in kUsageSources) {
          expect(sql, contains("'$s'"), reason: s);
        }
      },
      skip: migration.existsSync() ? false : 'migratie 0014 bestaat nog niet',
    );
  });
}
