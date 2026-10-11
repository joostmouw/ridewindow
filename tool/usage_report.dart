// Leest de dagtelling van `public.usage_daily_counts` uit en maakt er een
// rapport van: per bron en per dag hoeveel rijen er bijkwamen, van hoeveel
// verschillende afzenders, en hoeveel rijen de drukste afzender aanmaakte.
//
// Waarom dit een lokaal script is
// -------------------------------
// De repo is publiek (F-01). Getallen horen daarom niet in een commit, niet in
// een Action-log en niet in een job summary. De dagelijkse wacht
// (`.github/workflows/usage-watch.yml`) zegt alleen *dát* er iets ongewoons
// is, met bron en regel; de getallen zelf bekijk je hier, op je eigen machine
// (D-09). Geen scherm in de app, geen dashboard-view.
//
// Het script roept de rpc aan met de service-role sleutel. De functie geeft
// alleen dagtotalen terug, nooit een rij, id, code of e-mailadres (migratie
// 0014).
//
// Eenmalige inrichting
// --------------------
// Dezelfde sleutel als `tool/analytics_report.dart`, op dezelfde plek; zie de
// kop van dat script. De leescode is gedeeld (`tool/src/service_role_key.dart`),
// dus hier verandert niets als daar iets verandert.
//
// Uitschieters
// ------------
// Het rapport markeert dezelfde dagen als de Action, met dezelfde regel uit
// `tool/usage/usage_rule.dart` (D-16). Vandaag loopt nog en wordt niet
// getoetst.
//
// Gebruik
// -------
//   dart run tool/usage_report.dart                # laatste 14 dagen
//   dart run tool/usage_report.dart --days 30
//   dart run tool/usage_report.dart --html usage.html
//   dart run tool/usage_report.dart --key /ander/pad

import 'dart:convert';
import 'dart:io';

import 'src/service_role_key.dart';
import 'usage/usage_floors.dart';
import 'usage/usage_rule.dart';

const _projectUrl = 'https://hcdrydlgqpnmumfupgcx.supabase.co';

/// De regel kijkt 28 dagen terug; zoveel extra dagen halen we op zodat ook de
/// oudste getoonde dag een volledige basislijn heeft.
const _baselineDays = 28;

/// Bovengrens op wat we opvragen (tien jaar), zodat een tikfout in `--days`
/// geen onzinnig grote telling vraagt.
const _maxFetchDays = 3660;

/// Vaste voetnoot (D-06, F-02): welke getallen een ondergrens zijn.
const _footnote = <String>[
  'Ondergrens: geteld worden rijen die nu nog bestaan. Voor deze bronnen kan',
  'een vroegere dag dus drukker geweest zijn dan hier staat:',
  '  friend_invites      ingetrokken, of mee weg met een verwijderd account',
  '  group_invites       ingetrokken, of mee weg met een opgeheven groep',
  '  group_rides         verwijderd door de eigenaar, of met zijn account',
  '  group_ride_options  gewist bij elke keuze of bewerking van de rit --',
  '                      de zwakste ondergrens van allemaal',
  '  accounts_*          verwijderde accounts tellen niet meer mee',
  'feedback_anoniem kent geen afzender (feedback heeft geen device_id), dus',
  'alleen rijen; feedback van een verwijderd account schuift daarheen.',
];

Future<void> main(List<String> args) async {
  final key = readServiceRoleKey(args);
  if (key == null) {
    printMissingKeyHelp();
    exitCode = 1;
    return;
  }

  final days = (intArg(args, '--days') ?? 14).clamp(1, _maxFetchDays);
  final htmlPath = stringArg(args, '--html');
  final fetchDays = (days + _baselineDays).clamp(1, _maxFetchDays);

  final List<DayCount> counts;
  try {
    counts = await _fetchCounts(key: key, days: fetchDays);
  } on HttpException catch (e) {
    // Een nette regel in plaats van een stacktrace, zoals analytics_report.
    stderr.writeln(e.message);
    stderr.writeln('');
    stderr
        .writeln('Bij 401: de sleutel klopt niet meer. Haal een verse op bij');
    stderr
        .writeln('Supabase > Project Settings > API > service_role en zet hem');
    stderr.writeln('opnieuw neer (zie de kop van tool/analytics_report.dart).');
    stderr.writeln('Bij 404: migratie 0014 is nog niet gedraaid; de functie');
    stderr.writeln('usage_daily_counts bestaat dan nog niet.');
    exitCode = 1;
    return;
  }
  if (counts.isEmpty) {
    stdout.writeln('De telling is leeg. Dat hoort niet: de functie geeft een');
    stdout.writeln('dicht rooster terug, ook voor dagen zonder rijen.');
    exitCode = 1;
    return;
  }

  final report = _buildReport(counts, days: days);
  stdout.write(_renderText(report));

  if (htmlPath != null) {
    await File(htmlPath).writeAsString(_renderHtml(report));
    stdout.writeln('\nHTML geschreven naar $htmlPath');
  }
}

// ---------------------------------------------------------------------------
// Ophalen
// ---------------------------------------------------------------------------

/// PostgREST geeft per verzoek hoogstens zoveel rijen terug (Supabase-standaard
/// `max-rows`). Tien bronnen per dag betekent dat alles boven honderd dagen
/// stilzwijgend werd afgekapt -- het rapport toonde dan een oude dag als
/// "vandaag". Daarom halen we in pagina's op met `offset`/`limit` in de query
/// (een `Range`-header negeert PostgREST bij een POST-rpc); de functie sorteert
/// vast op dag en bron, dus de pagina's sluiten op elkaar aan.
const _pageSize = 1000;

Future<List<DayCount>> _fetchCounts({
  required String key,
  required int days,
}) async {
  final client = HttpClient();
  try {
    final all = <DayCount>[];
    // Tien bronnen per dag: meer pagina's dan dit kan niet, ook niet bij de
    // maximale --days. Een vangnet tegen een eindeloze lus.
    final maxPages = (days * kUsageSources.length) ~/ _pageSize + 2;
    for (var page = 0; page < maxPages; page++) {
      final uri = Uri.parse(
        '$_projectUrl/rest/v1/rpc/usage_daily_counts'
        '?offset=${all.length}&limit=$_pageSize',
      );
      final request = await client.postUrl(uri);
      request.headers.set('apikey', key);
      request.headers.set('Authorization', 'Bearer $key');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'p_days': days}));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Supabase gaf ${response.statusCode}${_postgrestReason(body)}',
        );
      }

      final rows = (jsonDecode(body) as List)
          .cast<Map<String, dynamic>>()
          .map(DayCount.fromJson)
          .toList();
      all.addAll(rows);
      if (rows.length < _pageSize) return all;
    }
    throw const HttpException(
        'meer pagina\'s dan verwacht; telling afgebroken');
  } finally {
    client.close();
  }
}

/// Alleen `message` en `hint` uit een PostgREST-fout, nooit de ruwe body:
/// die gaat door niemands handen behalve de onze, maar een verzoek-echo hoort
/// er niet in.
String _postgrestReason(String body) {
  try {
    final json = jsonDecode(body);
    if (json is Map) {
      final parts = [
        if (json['message'] is String) json['message'] as String,
        if (json['hint'] is String) 'hint: ${json['hint']}',
      ];
      if (parts.isNotEmpty) return ': ${parts.join(' -- ')}';
    }
  } on FormatException {
    // geen JSON; dan alleen de status
  }
  return '';
}

// ---------------------------------------------------------------------------
// Samenvatten
// ---------------------------------------------------------------------------

class _Row {
  _Row(this.count, this.isToday, this.outliers);

  final DayCount count;
  final bool isToday;
  final List<OutlierRule> outliers;
}

class _Report {
  _Report({
    required this.days,
    required this.today,
    required this.perSource,
    required this.configError,
  });

  final int days;
  final DateTime today;

  /// Per bron (volgorde kUsageSources, daarna onbekende), nieuwste dag boven.
  final Map<String, List<_Row>> perSource;

  /// Als de regel niet kon draaien (bron zonder vloer): de reden.
  final String? configError;
}

_Report _buildReport(List<DayCount> counts, {required int days}) {
  // De functie levert een dicht rooster dat eindigt op vandaag (Amsterdam);
  // de laatste dag in de telling is dus vandaag, zonder dat we hier zelf
  // tijdzones hoeven te rekenen.
  final today = counts.map((c) => c.day).reduce((a, b) => a.isAfter(b) ? a : b);
  final shown = <DateTime>[
    for (var i = 0; i < days; i++)
      DateTime.utc(today.year, today.month, today.day - i),
  ];

  // Uitschieters per dag, met dezelfde regel als de Action.
  final outliersByDay = <DateTime, List<Outlier>>{};
  String? configError;
  for (final d in shown) {
    if (d == today) continue;
    if (!counts.any((c) => c.day == d)) continue;
    try {
      outliersByDay[d] = findOutliers(counts, d);
    } on UsageConfigError catch (e) {
      configError = e.message;
      break;
    }
  }

  final sources = [
    ...kUsageSources,
    ...{for (final c in counts) c.source}
        .where((s) => !kUsageSources.contains(s)),
  ];
  final perSource = <String, List<_Row>>{};
  for (final s in sources) {
    final rows = <_Row>[];
    for (final d in shown) {
      final c = counts.where((c) => c.source == s && c.day == d);
      if (c.isEmpty) continue;
      final rules = [
        for (final o in outliersByDay[d] ?? const <Outlier>[])
          if (o.source == s) o.rule,
      ];
      rows.add(_Row(c.first, d == today, rules));
    }
    if (rows.isNotEmpty) perSource[s] = rows;
  }

  return _Report(
    days: days,
    today: today,
    perSource: perSource,
    configError: configError,
  );
}

String _day(DateTime d) => d.toIso8601String().substring(0, 10);

String _n(int? v) => v == null ? '-' : '$v';

String _ruleLabel(OutlierRule r) => switch (r) {
      OutlierRule.totaal => 'totaal',
      OutlierRule.eenAfzender => 'één afzender',
    };

// ---------------------------------------------------------------------------
// Weergeven
// ---------------------------------------------------------------------------

String _renderText(_Report r) {
  final b = StringBuffer();
  b.writeln('');
  b.writeln('Ridewindow — aanmaak per bron over ${r.days} dagen '
      '(t/m ${_day(r.today)})');
  b.writeln('=' * 64);
  if (r.configError != null) {
    b.writeln('');
    b.writeln('  Let op: de uitschieterregel kon niet draaien '
        '(${r.configError}).');
    b.writeln('  Vul tool/usage/usage_floors.dart aan.');
  }

  for (final e in r.perSource.entries) {
    b.writeln('');
    b.writeln('  ${e.key}');
    b.writeln('    ${'datum'.padRight(10)}  ${'rijen'.padLeft(6)}  '
        '${'afzenders'.padLeft(9)}  ${'max/afz.'.padLeft(8)}');
    for (final row in e.value) {
      final c = row.count;
      final note = row.isToday
          ? '  (vandaag, loopt nog)'
          : row.outliers
              .map((o) => '  <- uitschieter (${_ruleLabel(o)})')
              .join();
      b.writeln('    ${_day(c.day)}  ${_n(c.rows).padLeft(6)}  '
          '${_n(c.distinctSenders).padLeft(9)}  '
          '${_n(c.maxRowsOneSender).padLeft(8)}$note');
    }
  }

  b.writeln('');
  for (final line in _footnote) {
    b.writeln('  $line');
  }
  b.writeln('');
  return b.toString();
}

String _renderHtml(_Report r) {
  final sections = StringBuffer();
  for (final e in r.perSource.entries) {
    sections.writeln('<h2>${_escape(e.key)}</h2>');
    sections.writeln('<table><tr><th>datum</th><th class="n">rijen</th>'
        '<th class="n">afzenders</th><th class="n">max per afzender</th>'
        '<th></th></tr>');
    for (final row in e.value) {
      final c = row.count;
      final cls = row.outliers.isNotEmpty && !row.isToday ? ' class="uit"' : '';
      final note = row.isToday
          ? 'vandaag, loopt nog'
          : row.outliers
              .map((o) => 'uitschieter (${_ruleLabel(o)})')
              .join(', ');
      sections.writeln('<tr$cls><td>${_day(c.day)}</td>'
          '<td class="n">${_n(c.rows)}</td>'
          '<td class="n">${_n(c.distinctSenders)}</td>'
          '<td class="n">${_n(c.maxRowsOneSender)}</td>'
          '<td>${_escape(note)}</td></tr>');
    }
    sections.writeln('</table>');
  }

  final warning = r.configError == null
      ? ''
      : '<p class="warn">De uitschieterregel kon niet draaien '
          '(${_escape(r.configError!)}). Vul tool/usage/usage_floors.dart aan.</p>';

  return '''<!doctype html>
<html lang="nl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Ridewindow — aanmaak per bron</title>
<style>
  :root { color-scheme: light dark; }
  body { font: 15px/1.6 system-ui, sans-serif; max-width: 760px;
         margin: 0 auto; padding: 32px 20px 64px; }
  h1 { font-size: 24px; margin: 0 0 4px; }
  .sub { color: #888; margin: 0 0 28px; }
  h2 { font-size: 15px; text-transform: uppercase; letter-spacing: .08em;
       color: #888; margin: 28px 0 8px; }
  table { width: 100%; border-collapse: collapse; }
  th { text-align: left; font-weight: 600; font-size: 13px; color: #888; }
  td, th { padding: 6px 8px; border-bottom: 1px solid #8882; }
  .n { text-align: right; font-variant-numeric: tabular-nums; width: 90px; }
  tr.uit td { background: #e5393533; }
  .warn { background: #f9a82533; padding: 10px 14px; border-radius: 8px; }
  .foot { color: #888; font-size: 13px; margin-top: 32px; white-space: pre-wrap; }
</style></head><body>
<h1>Ridewindow — aanmaak per bron</h1>
<p class="sub">${r.days} dagen, t/m ${_day(r.today)}</p>
$warning
$sections
<p class="foot">${_escape(_footnote.join('\n'))}</p>
</body></html>''';
}

String _escape(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
