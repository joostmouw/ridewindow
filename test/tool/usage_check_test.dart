// Toetsscript van de dagelijkse wacht (MEET-02). Draait het script als
// subprocess, zoals de Action het doet, en bewaakt de exitcodes en dat er
// nooit een getal uit de telling in de (publieke) uitvoer staat (F-01, D-11).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/usage/usage_floors.dart';

const _day = '2026-10-10';

/// Getallen die niet in de datum of de bronnamen voorkomen, zodat hun
/// aanwezigheid in de uitvoer alleen uit de invoer kan komen.
const _rows = 777;
const _senders = 913;
const _spike = 98765;

/// Een dicht rooster van 30 dagen t/m [_day], alle bronnen rustig.
List<String> _calmLines({String? skipDay}) {
  final end = DateTime.utc(2026, 10, 10);
  final out = <String>[];
  for (var i = 29; i >= 0; i--) {
    final d = DateTime.utc(end.year, end.month, end.day - i);
    final ds = d.toIso8601String().substring(0, 10);
    if (ds == skipDay) continue;
    for (final s in kUsageSources) {
      final senderless = kSenderlessSources.contains(s);
      // Rustig: geen sprong ten opzichte van de mediaan; bij app_events een
      // tamelijk hoog totaal (onder de vloer) met veel afzenders.
      final rows = s == 'app_events' ? _rows : 1;
      out.add([
        ds,
        s,
        '$rows',
        senderless ? '' : (s == 'app_events' ? '$_senders' : '1'),
        senderless ? '' : '1',
        senderless ? '' : '1.5',
      ].join(','));
    }
  }
  return out;
}

List<String> _replace(
  List<String> lines,
  String source,
  String Function(String line) f,
) =>
    [
      for (final l in lines)
        l.startsWith('$_day,$source,') ? f(l) : l,
    ];

String _withMax(String line, int max) {
  final p = line.split(',');
  p[4] = '$max';
  return p.join(',');
}

String _withRows(String line, int rows) {
  final p = line.split(',');
  p[2] = '$rows';
  return p.join(',');
}

late Directory _tmp;

Future<ProcessResult> _run(List<String> args) =>
    Process.run('dart', ['run', 'tool/usage/usage_check.dart', ...args]);

Future<ProcessResult> _runCsv(List<String> lines, {String day = _day}) async {
  final f = File('${_tmp.path}/counts.csv');
  await f.writeAsString('${lines.join('\n')}\n');
  return _run(['--csv', f.path, '--day', day]);
}

String _out(ProcessResult r) => '${r.stdout}${r.stderr}';

void _expectNoInputNumbers(ProcessResult r) {
  final out = _out(r);
  for (final n in [_rows, _senders, _spike, 4321]) {
    expect(out, isNot(contains('$n')), reason: 'getal $n lekte naar uitvoer');
  }
}

void main() {
  setUp(() async {
    _tmp = await Directory.systemTemp.createTemp('usage_check_test');
  });
  tearDown(() async {
    await _tmp.delete(recursive: true);
  });

  test('rustige dag: exit 0, geen uitschieter, geen getallen', () async {
    final r = await _runCsv(_calmLines());
    expect(r.exitCode, 0, reason: _out(r));
    expect(r.stdout, contains('geen uitschieter'));
    expect(_out(r), isNot(contains('::error::')));
    _expectNoInputNumbers(r);
    // Ook de datum zelf staat er niet in: geen dag naast getallen.
    expect(
      _out(r).replaceAll(RegExp(r'\s'), ''),
      isNot(matches(RegExp(r'\d{3,}'))),
    );
  });

  test('één afzender van app_events boven de vloer: exit 2', () async {
    final lines = _replace(
      _calmLines(),
      'app_events',
      (l) => _withMax(l, kFloorSender['app_events']! + 4321),
    );
    final r = await _runCsv(lines);
    expect(r.exitCode, 2, reason: _out(r));
    expect(
      r.stdout,
      contains('::error::uitschieter: app_events, één afzender boven de vloer'),
    );
    _expectNoInputNumbers(r);
  });

  test('twee bronnen met uitschieter: twee ::error::-regels, exit 2', () async {
    var lines = _replace(
      _calmLines(),
      'app_events',
      (l) => _withMax(l, kFloorSender['app_events']! + 4321),
    );
    lines = _replace(lines, 'feedback_anoniem', (l) => _withRows(l, _spike));
    final r = await _runCsv(lines);
    expect(r.exitCode, 2, reason: _out(r));
    final errors = '${r.stdout}'
        .split('\n')
        .where((l) => l.startsWith('::error::uitschieter: '))
        .toList();
    expect(errors, hasLength(2));
    expect(errors.join('\n'), contains('feedback_anoniem'));
    _expectNoInputNumbers(r);
  });

  test('dag ontbreekt in de telling: infrafout, exit 1', () async {
    final r = await _runCsv(_calmLines(skipDay: _day));
    expect(r.exitCode, 1, reason: _out(r));
    expect(r.stdout, startsWith('::error::infrafout: '));
    expect(_out(r), contains('dag ontbreekt in de telling'));
    _expectNoInputNumbers(r);
  });

  test('kapotte regel: infrafout zonder invoerinhoud, exit 1', () async {
    final lines = [
      ..._calmLines(),
      'psql: error: connection to server at secret-host failed $_spike',
    ];
    final r = await _runCsv(lines);
    expect(r.exitCode, 1, reason: _out(r));
    expect(r.stdout, startsWith('::error::infrafout: '));
    expect(_out(r), contains('telling onleesbaar'));
    expect(_out(r), isNot(contains('secret-host')));
    _expectNoInputNumbers(r);
  });

  test('onbekende bron: infrafout, exit 1', () async {
    final lines = [..._calmLines(), '$_day,nieuwe_bron,$_rows,1,1,1'];
    final r = await _runCsv(lines);
    expect(r.exitCode, 1, reason: _out(r));
    expect(r.stdout, startsWith('::error::infrafout: '));
    expect(_out(r), contains('bron zonder vloer'));
    _expectNoInputNumbers(r);
  });

  test('csv-bestand bestaat niet: infrafout, exit 1', () async {
    final r =
        await _run(['--csv', '${_tmp.path}/bestaat-niet.csv', '--day', _day]);
    expect(r.exitCode, 1, reason: _out(r));
    expect(r.stdout, startsWith('::error::infrafout: '));
  });

  test('--csv ontbreekt: infrafout, exit 1', () async {
    final r = await _run(['--day', _day]);
    expect(r.exitCode, 1, reason: _out(r));
    expect(r.stdout, startsWith('::error::infrafout: '));
  });

  test('--day ontbreekt of is ongeldig: infrafout, exit 1', () async {
    final f = File('${_tmp.path}/counts.csv');
    await f.writeAsString(_calmLines().join('\n'));
    for (final args in [
      ['--csv', f.path],
      ['--csv', f.path, '--day', 'gisteren'],
    ]) {
      final r = await _run(args);
      expect(r.exitCode, 1, reason: _out(r));
      expect(r.stdout, startsWith('::error::infrafout: '));
    }
  });
}
