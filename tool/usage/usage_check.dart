// Toetsscript van de dagelijkse wacht (`.github/workflows/usage-watch.yml`,
// MEET-02): leest de telling die psql als CSV wegschreef en toetst één dag
// met de uitschieterregel uit `usage_rule.dart`.
//
//   dart run usage_check.dart --csv counts.csv --day 2026-10-10
//
// Exitcodes
// ---------
//   0  rustig                 -> 'geen uitschieter'
//   2  uitschieter            -> per uitschieter '::error::uitschieter: ...'
//   1  infrafout              -> '::error::infrafout: <korte reden>'
// Zo is in de log (en in de mail van GitHub) te zien of er iets ongewoons
// gebeurt, of dat de wacht zelf stuk is (D-11).
//
// Wat er nooit in de uitvoer komt
// -------------------------------
// De repo is publiek, en daarmee de Action-log (F-01). Daarom: geen enkel
// getal uit de telling, geen datum naast een getal, en bij een fout nooit de
// invoer zelf -- in een kapotte CSV kan een psql-foutmelding met een
// verbindingsstring staan. Een onverwachte uitzondering noemt alleen zijn type.
//
// Alleen `dart:io` en relatieve imports: de Action kopieert `tool/usage/` naar
// een map buiten de repo en draait dit met een kale `dart run`, zonder pub get.
// Daarom ook een eigen mini-parser voor de argumenten in plaats van de helpers
// uit `tool/src/`.

import 'dart:io';

import 'usage_rule.dart';

Future<void> main(List<String> args) async {
  exitCode = await _check(args);
}

Future<int> _check(List<String> args) async {
  try {
    final csvPath = _arg(args, '--csv');
    if (csvPath == null) return _infra('csv ontbreekt');
    final dayArg = _arg(args, '--day');
    final day = dayArg == null ? null : _parseDay(dayArg);
    if (day == null) return _infra('dag ontbreekt of is ongeldig');

    final file = File(csvPath);
    if (!file.existsSync()) return _infra('csv ontbreekt');

    final List<DayCount> counts;
    try {
      counts = parseCountsCsv(await file.readAsString());
    } on FormatException {
      return _infra('telling onleesbaar');
    }

    final List<Outlier> outliers;
    try {
      outliers = findOutliers(counts, day);
    } on UsageConfigError catch (e) {
      return _infra(
        e.message == 'dag ontbreekt in de telling'
            ? 'dag ontbreekt in de telling'
            : 'bron zonder vloer',
      );
    }

    if (outliers.isEmpty) {
      stdout.writeln('geen uitschieter');
      return 0;
    }
    for (final o in outliers) {
      stdout.writeln('::error::${o.message}');
    }
    return 2;
  } on Object catch (e) {
    // Alleen het type: een boodschap kan invoer bevatten.
    return _infra('onverwachte fout (${e.runtimeType})');
  }
}

int _infra(String reason) {
  stdout.writeln('::error::infrafout: $reason');
  return 1;
}

String? _arg(List<String> args, String flag) {
  final i = args.indexOf(flag);
  if (i < 0 || i + 1 >= args.length) return null;
  return args[i + 1];
}

final _dayPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

DateTime? _parseDay(String s) {
  final m = _dayPattern.firstMatch(s);
  if (m == null) return null;
  final d = DateTime.utc(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
  // 2026-02-31 zou stil doorrollen naar maart; dat is een ongeldige dag.
  return d.toIso8601String().startsWith(s) ? d : null;
}
