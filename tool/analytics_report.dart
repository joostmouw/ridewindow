// Leest `public.app_events` uit en maakt er een rapport van.
//
// Waarom dit een lokaal script is en geen scherm in de app
// -------------------------------------------------------
// `app_events` heeft met opzet geen select-grant: de app schrijft en leest
// nooit terug (migratie 0008, zelfde regel als bij feedback). Lezen kan dus
// alleen met de service-role sleutel, en die hoort nergens in een build.
//
// Een gepubliceerd artifact kan het ook niet: de CSP daar blokkeert fetch naar
// elke host buiten de toegestane CDN's, Supabase incluis. Vandaar: hier lezen,
// en desgewenst een HTML-bestand uitdraaien dat je daarna kunt delen.
//
// Eenmalige inrichting
// --------------------
// De service-role sleutel staat in Supabase onder Project Settings > API.
// Zet hem in je omgeving, niet in de repo:
//
//   export SUPABASE_SERVICE_ROLE_KEY='eyJ...'
//
// Gebruik
// -------
//   dart run tool/analytics_report.dart                # laatste 14 dagen
//   dart run tool/analytics_report.dart --days 30
//   dart run tool/analytics_report.dart --html rapport.html

import 'dart:convert';
import 'dart:io';

const _projectUrl = 'https://hcdrydlgqpnmumfupgcx.supabase.co';
const _table = 'app_events';

Future<void> main(List<String> args) async {
  final key = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
  if (key == null || key.isEmpty) {
    stderr.writeln('SUPABASE_SERVICE_ROLE_KEY ontbreekt.');
    stderr.writeln('Supabase > Project Settings > API > service_role.');
    stderr.writeln("  export SUPABASE_SERVICE_ROLE_KEY='eyJ...'");
    exitCode = 1;
    return;
  }

  final days = _intArg(args, '--days') ?? 14;
  final htmlPath = _stringArg(args, '--html');
  final since = DateTime.now().toUtc().subtract(Duration(days: days));

  final events = await _fetchEvents(key: key, since: since);
  if (events.isEmpty) {
    stdout.writeln('Geen gebeurtenissen in de laatste $days dagen.');
    stdout.writeln('');
    stdout.writeln(
      'Dat kan drie dingen betekenen, in volgorde van waarschijnlijkheid:',
    );
    stdout.writeln(
      '  1. Nog geen tester heeft de toestemmingsvraag met ja beantwoord.',
    );
    stdout.writeln('  2. De build met statistiek staat nog niet op de track.');
    stdout.writeln('  3. Migratie 0008 is nog niet gedraaid.');
    return;
  }

  final report = _buildReport(events, days: days, since: since);
  stdout.write(_renderText(report));

  if (htmlPath != null) {
    await File(htmlPath).writeAsString(_renderHtml(report));
    stdout.writeln('\nHTML geschreven naar $htmlPath');
  }
}

// ---------------------------------------------------------------------------
// Ophalen
// ---------------------------------------------------------------------------

Future<List<Map<String, dynamic>>> _fetchEvents({
  required String key,
  required DateTime since,
}) async {
  final client = HttpClient();
  final all = <Map<String, dynamic>>[];
  const pageSize = 1000;
  var offset = 0;

  try {
    // PostgREST levert maximaal 1000 rijen per verzoek; doorbladeren tot een
    // pagina niet meer vol is.
    while (true) {
      final uri = Uri.parse('$_projectUrl/rest/v1/$_table').replace(
        queryParameters: {
          'select': 'device_id,name,props,platform,app_version,occurred_at',
          'occurred_at': 'gte.${since.toIso8601String()}',
          'order': 'occurred_at.asc',
          'limit': '$pageSize',
          'offset': '$offset',
        },
      );

      final request = await client.getUrl(uri);
      request.headers.set('apikey', key);
      request.headers.set('Authorization', 'Bearer $key');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw HttpException('Supabase gaf ${response.statusCode}: $body');
      }

      final page = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
      all.addAll(page);
      if (page.length < pageSize) break;
      offset += pageSize;
    }
  } finally {
    client.close();
  }

  return all;
}

// ---------------------------------------------------------------------------
// Samenvatten
// ---------------------------------------------------------------------------

class _Report {
  _Report({
    required this.days,
    required this.since,
    required this.total,
    required this.devices,
    required this.perName,
    required this.perPlatform,
    required this.perDay,
    required this.returningDevices,
    required this.onboardingDone,
    required this.firstRuns,
    required this.locationWarnings,
  });

  final int days;
  final DateTime since;
  final int total;
  final int devices;
  final Map<String, int> perName;
  final Map<String, int> perPlatform;
  final Map<String, int> perDay;
  final int returningDevices;
  final int onboardingDone;
  final int firstRuns;
  final Map<String, int> locationWarnings;
}

_Report _buildReport(
  List<Map<String, dynamic>> events, {
  required int days,
  required DateTime since,
}) {
  final perName = <String, int>{};
  final perPlatform = <String, int>{};
  final perDay = <String, int>{};
  final opensPerDevice = <String, int>{};
  final devices = <String>{};
  final locationWarnings = <String, int>{};

  for (final e in events) {
    final name = e['name'] as String;
    final device = e['device_id'] as String;
    final day = (e['occurred_at'] as String).substring(0, 10);

    devices.add(device);
    perName[name] = (perName[name] ?? 0) + 1;
    perPlatform[e['platform'] as String] =
        (perPlatform[e['platform'] as String] ?? 0) + 1;
    perDay[day] = (perDay[day] ?? 0) + 1;

    if (name == 'app_open') {
      opensPerDevice[device] = (opensPerDevice[device] ?? 0) + 1;
    }
    if (name == 'location_warning') {
      final props = (e['props'] as Map?) ?? const {};
      final soort = props['clock_mismatch'] == true
          ? 'klok hoort bij een ander werelddeel'
          : 'plek is een gok (${props['source'] ?? 'onbekend'})';
      locationWarnings[soort] = (locationWarnings[soort] ?? 0) + 1;
    }
  }

  return _Report(
    days: days,
    since: since,
    total: events.length,
    devices: devices.length,
    perName: perName,
    perPlatform: perPlatform,
    perDay: perDay,
    // De vraag van de wervingsfase: hoeveel testers komen terug? Google telt
    // aanmeldingen, niet gebruik, en juist dat laatste is waar de aanvraag op
    // beoordeeld wordt.
    returningDevices: opensPerDevice.values.where((n) => n > 1).length,
    onboardingDone: perName['onboarding_done'] ?? 0,
    firstRuns: perName['first_run'] ?? 0,
    locationWarnings: locationWarnings,
  );
}

// ---------------------------------------------------------------------------
// Weergeven
// ---------------------------------------------------------------------------

String _renderText(_Report r) {
  final b = StringBuffer();
  final sinceDay = r.since.toIso8601String().substring(0, 10);

  b.writeln('');
  b.writeln('Ridewindow — gebruik over ${r.days} dagen (sinds $sinceDay)');
  b.writeln('=' * 60);
  b.writeln('');
  b.writeln('  Toestellen       ${r.devices}');
  b.writeln('  Gebeurtenissen   ${r.total}');
  b.writeln('  Kwamen terug     ${r.returningDevices} van ${r.devices}'
      '${r.devices > 0 ? ' (${(r.returningDevices / r.devices * 100).round()}%)' : ''}');
  b.writeln('');

  if (r.firstRuns > 0) {
    final pct = (r.onboardingDone / r.firstRuns * 100).round();
    b.writeln('  Eerste minuut    ${r.onboardingDone} van ${r.firstRuns} '
        'nieuwe toestellen rondden de onboarding af ($pct%)');
    b.writeln('');
  }

  b.writeln('  Per platform');
  _writeCounts(b, r.perPlatform);
  b.writeln('');

  b.writeln('  Per gebeurtenis');
  _writeCounts(b, r.perName);
  b.writeln('');

  if (r.locationWarnings.isNotEmpty) {
    b.writeln('  Locatie-waarschuwingen  (zie de Aruba-diagnose van 19-09)');
    _writeCounts(b, r.locationWarnings);
    b.writeln('');
  }

  b.writeln('  Per dag');
  _writeCounts(b, r.perDay, sortByKey: true);
  b.writeln('');
  return b.toString();
}

void _writeCounts(
  StringBuffer b,
  Map<String, int> counts, {
  bool sortByKey = false,
}) {
  if (counts.isEmpty) {
    b.writeln('    (niets)');
    return;
  }
  final entries = counts.entries.toList()
    ..sort(
      (a, c) => sortByKey
          ? a.key.compareTo(c.key)
          : c.value.compareTo(
              a.value,
            ),
    );
  final width =
      entries.map((e) => e.key.length).reduce((a, c) => a > c ? a : c);
  final max = entries.map((e) => e.value).reduce((a, c) => a > c ? a : c);

  for (final e in entries) {
    final bar =
        '#' * ((e.value / max) * 28).round().clamp(e.value > 0 ? 1 : 0, 28);
    b.writeln(
      '    ${e.key.padRight(width)}  ${e.value.toString().padLeft(5)}  $bar',
    );
  }
}

String _renderHtml(_Report r) {
  String rows(Map<String, int> m, {bool sortByKey = false}) {
    final entries = m.entries.toList()
      ..sort(
        (a, c) => sortByKey
            ? a.key.compareTo(c.key)
            : c.value.compareTo(
                a.value,
              ),
      );
    if (entries.isEmpty) return '<tr><td colspan="2">(niets)</td></tr>';
    return entries
        .map(
          (e) => '<tr><td>${_escape(e.key)}</td>'
              '<td class="n">${e.value}</td></tr>',
        )
        .join('\n');
  }

  final sinceDay = r.since.toIso8601String().substring(0, 10);
  final terug = r.devices > 0
      ? '${(r.returningDevices / r.devices * 100).round()}%'
      : '—';

  return '''<!doctype html>
<html lang="nl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Ridewindow — gebruik</title>
<style>
  :root { color-scheme: light dark; }
  body { font: 15px/1.6 system-ui, sans-serif; max-width: 760px;
         margin: 0 auto; padding: 32px 20px 64px; }
  h1 { font-size: 24px; margin: 0 0 4px; }
  .sub { color: #666; margin: 0 0 28px; }
  .tiles { display: flex; flex-wrap: wrap; gap: 16px; margin-bottom: 32px; }
  .tile { flex: 1 1 140px; border: 1px solid #0002; border-radius: 8px;
          padding: 14px 16px; }
  .tile b { display: block; font-size: 26px; font-variant-numeric: tabular-nums; }
  .tile span { font-size: 12px; color: #666; text-transform: uppercase;
               letter-spacing: .08em; }
  h2 { font-size: 15px; text-transform: uppercase; letter-spacing: .08em;
       color: #666; margin: 28px 0 8px; }
  table { width: 100%; border-collapse: collapse; }
  td { padding: 6px 0; border-bottom: 1px solid #0001; }
  td.n { text-align: right; font-variant-numeric: tabular-nums; width: 80px; }
</style></head><body>
<h1>Ridewindow — gebruik</h1>
<p class="sub">${r.days} dagen, sinds $sinceDay</p>
<div class="tiles">
  <div class="tile"><b>${r.devices}</b><span>toestellen</span></div>
  <div class="tile"><b>$terug</b><span>kwam terug</span></div>
  <div class="tile"><b>${r.total}</b><span>gebeurtenissen</span></div>
</div>
<h2>Per gebeurtenis</h2><table>${rows(r.perName)}</table>
<h2>Per platform</h2><table>${rows(r.perPlatform)}</table>
<h2>Per dag</h2><table>${rows(r.perDay, sortByKey: true)}</table>
${r.locationWarnings.isEmpty ? '' : '<h2>Locatie-waarschuwingen</h2><table>${rows(r.locationWarnings)}</table>'}
</body></html>''';
}

String _escape(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

int? _intArg(List<String> args, String flag) {
  final v = _stringArg(args, flag);
  return v == null ? null : int.tryParse(v);
}

String? _stringArg(List<String> args, String flag) {
  final i = args.indexOf(flag);
  return (i >= 0 && i + 1 < args.length) ? args[i + 1] : null;
}
