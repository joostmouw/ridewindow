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
// Hij hoort NERGENS in de repo: deze sleutel omzeilt RLS volledig en mag dus
// niet in een commit, niet in een chatlog en niet in een shell-history belanden.
//
// Standaardplek, hetzelfde patroon als `tool/play_upload.dart` met zijn
// dienstsleutel: een bestand in `~/.config/`, buiten het project, waar geen
// `git add .` bij kan.
//
//   mkdir -p ~/.config/ridewindow
//   (umask 077; cat > ~/.config/ridewindow/supabase-service-role.key)
//   <plak de sleutel, Enter, Ctrl-D>
//
// `umask 077` zet de rechten op 600 vóórdat er iets in staat -- schrijven en
// daarna chmod'en laat de sleutel een moment leesbaar achter.
//
// Een omgevingsvariabele werkt ook (`SUPABASE_SERVICE_ROLE_KEY`), maar die
// komt in je shell-history terecht zodra je hem een keer met `export` op de
// regel zet. Het bestand is de veiligere standaard.
//
// Gebruik
// -------
//   dart run tool/analytics_report.dart                # laatste 14 dagen
//   dart run tool/analytics_report.dart --days 30
//   dart run tool/analytics_report.dart --html rapport.html
//   dart run tool/analytics_report.dart --key /ander/pad

import 'dart:convert';
import 'dart:io';

const _projectUrl = 'https://hcdrydlgqpnmumfupgcx.supabase.co';
const _table = 'app_events';

/// Waar de sleutel standaard staat. Buiten de repo, met opzet.
String get _defaultKeyPath {
  final home = Platform.environment['HOME'] ?? '.';
  return '$home/.config/ridewindow/supabase-service-role.key';
}

/// Hoe een sleutel eruitziet. Twee vormen, want Supabase kent er twee:
///  * de klassieke JWT -- drie met punten gescheiden base64url-delen;
///  * het nieuwe formaat `sb_secret_...`, dat geen JWT is.
///
/// Alleen op de JWT controleren leek veiliger, maar zou een geldige sleutel van
/// het nieuwe soort botweg weigeren met "geen regel die op een JWT lijkt" -- een
/// foutmelding die naar de verkeerde kant wijst.
final _keyPattern = RegExp(
  r'^(?:[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'
  r'|sb_secret_[A-Za-z0-9_-]+)$',
);

/// Leest de sleutel uit -- eerst `--key`, dan de omgeving, dan het
/// standaardbestand. Geeft null als hij nergens staat of nergens op lijkt.
///
/// **Waarom hier een vormcontrole staat.** De eerste versie gaf de ruwe
/// bestandsinhoud rechtstreeks door aan een HTTP-header. Stond er iets anders
/// in dan een sleutel -- op 2026-09-19 was dat de commandoregel die per ongeluk
/// was meegeplakt -- dan gooide Dart een `FormatException` met *de volledige
/// waarde erin*. Daarmee lekte een service-role sleutel naar de uitvoer, en
/// die moest ingetrokken worden. Een sleutel hoort nooit in een foutmelding te
/// kunnen belanden.
///
/// Vandaar twee dingen: er wordt gezocht naar de eerste regel die op een JWT
/// lijkt (zodat een meegeplakte regel ervoor of erna niets breekt), en wat er
/// niet op lijkt wordt geweigerd zónder de inhoud te tonen.
String? _readKey(List<String> args) {
  final fromArg = _stringArg(args, '--key');

  if (fromArg == null) {
    final fromEnv = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) {
      return _firstKey(fromEnv);
    }
  }

  final file = File(fromArg ?? _defaultKeyPath);
  if (!file.existsSync()) return null;
  return _firstKey(file.readAsStringSync());
}

/// De eerste regel die de vorm van een sleutel heeft, of null.
String? _firstKey(String raw) {
  for (final line in raw.split('\n')) {
    final candidate = line.trim();
    if (_keyPattern.hasMatch(candidate)) return candidate;
  }
  return null;
}

Future<void> main(List<String> args) async {
  final key = _readKey(args);
  if (key == null) {
    stderr.writeln('Geen bruikbare service-role sleutel gevonden.');
    stderr.writeln('');
    stderr
        .writeln('Als het bestand wél bestaat: er staat geen regel in die de');
    stderr.writeln(
      'vorm van een sleutel heeft (JWT of sb_secret_...). De inhoud',
    );
    stderr.writeln('wordt met opzet niet getoond.');
    stderr.writeln('');
    stderr.writeln('Gezocht in:');
    stderr.writeln('  SUPABASE_SERVICE_ROLE_KEY (omgevingsvariabele)');
    stderr.writeln('  $_defaultKeyPath');
    stderr.writeln('');
    stderr.writeln('De sleutel staat in Supabase > Project Settings > API >');
    stderr.writeln('service_role. Zo zet je hem neer zonder dat hij in je');
    stderr.writeln('shell-history belandt:');
    stderr.writeln('');
    stderr.writeln('  mkdir -p ~/.config/ridewindow');
    stderr.writeln(
      '  (umask 077; cat > ~/.config/ridewindow/supabase-service-role.key)',
    );
    stderr.writeln('  <plak de sleutel, Enter, Ctrl-D>');
    exitCode = 1;
    return;
  }

  final days = _intArg(args, '--days') ?? 14;
  final htmlPath = _stringArg(args, '--html');
  final since = DateTime.now().toUtc().subtract(Duration(days: days));

  final List<Map<String, dynamic>> events;
  try {
    events = await _fetchEvents(key: key, since: since);
  } on HttpException catch (e) {
    // Een nette regel in plaats van een stacktrace: de meest voorkomende fout
    // hier is een ingetrokken of verkeerd geplakte sleutel, en daar helpt een
    // Dart-stack niemand mee.
    stderr.writeln(e.message);
    stderr.writeln('');
    stderr
        .writeln('Bij 401: de sleutel klopt niet meer. Haal een verse op bij');
    stderr
        .writeln('Supabase > Project Settings > API > service_role en zet hem');
    stderr.writeln('opnieuw neer met het commando hierboven.');
    exitCode = 1;
    return;
  }
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

  // Wat deze regel wel en niet zegt
  // -------------------------------
  // Dit is geen install-verloop. Wie de app eenmaal opent en nooit terugkomt,
  // krijgt de toestemmingsvraag nooit en blijft dus onzichtbaar -- onder elke
  // opzet, niet alleen deze. Het echte verloop van installatie naar eerste
  // start staat in de Play Console, en dat getal is eerlijker dan wat wij hier
  // kunnen meten. Deze regel gaat over de toestellen die terugkwamen: van hen
  // is te zien wie de onboarding had afgemaakt en wie niet.
  if (r.firstRuns > 0) {
    final pct = (r.onboardingDone / r.firstRuns * 100).round();
    b.writeln('  Eerste minuut    ${r.onboardingDone} van ${r.firstRuns} '
        'toestellen die terugkwamen hadden de onboarding af ($pct%)');
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
