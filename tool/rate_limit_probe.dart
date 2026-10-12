// PostgREST-probe voor de dagplafonds uit 0016 (fase 38, "Dicht huis").
//
// Waarom dit script bestaat
// -------------------------
// rate_limits_test.sql bewijst dat de trigger boven het plafond weigert,
// maar dat bewijs loopt via de SQL Editor: als eigenaar, zonder
// x-forwarded-for. Het gevaar waar fase 38 tegen gaat, loopt over een ander
// pad: PostgREST met de publieke anon-sleutel, die in elke APK en elke
// webbundel zit, met de code van builds die al bij testers staan en dus
// nooit een update krijgen (RATE-04). Alleen een echte aanroep daarlangs
// bewijst dat de afzendertelling ook op dat pad staat (D-12, F-05) en dat
// roterende device_id's niet helpen.
//
// Gebruik
// -------
//   dart run tool/rate_limit_probe.dart               # het volledige bewijs
//   dart run tool/rate_limit_probe.dart --verify-open # na de opruim-SQL
//
// Draai pas nadat 0016 is toegepast (draaiboek: tool/README-rate-limit-probe.md).
// De probe schrijft echte rijen in productie met vaste markers en verbruikt
// het feedback- en app_events-dagquota van het IP waarvandaan hij draait;
// de opruim-SQL geeft dat dezelfde dag terug.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:ridewindow/core/supabase_config.dart';

// Vaste markers zodat de opruim-SQL de proberijen zonder uitschieters vindt
// (README-rate-limit-probe.md, hoofdstuk Opruimen).
const _feedbackMarker = 'rate-limit-probe: opruimen na het bewijs';
const _eventName = 'rate_limit_probe';

// Plafonds uit 0016. De probe dwingt ze niet af maar gebruikt ze als rem:
// weigert de grens na plafond + 5 inserts nog niet, dan staat 0016
// vermoedelijk niet toegepast en moet hij ophouden in plaats van onbegrensd
// rijen blijven zaaien.
const _feedbackCeiling = 20;
const _appEventsCeiling = 120;
const _overshoot = 5;

final _random = Random.secure();

class _Afbreken implements Exception {
  _Afbreken(this.reden);
  final String reden;
}

class _Uitkomst {
  _Uitkomst(this.status, this.bericht, this.body);
  final int status;
  final String? bericht; // 'message' uit de fout-body, als die JSON was
  final String body;

  bool get aangenomen => status == 201;
  bool get geweigerd =>
      bericht != null && bericht!.startsWith('rw_rate_limited:');
}

Future<_Uitkomst> _insert(String tabel, Map<String, dynamic> rij) async {
  final http.Response response;
  try {
    response = await http
        .post(
          Uri.parse('$supabaseUrl/rest/v1/$tabel'),
          headers: {
            'apikey': supabaseAnonKey,
            'Authorization': 'Bearer $supabaseAnonKey',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
          body: jsonEncode(rij),
        )
        .timeout(const Duration(seconds: 15));
  } on SocketException catch (e) {
    throw _Afbreken('Geen verbinding met $supabaseUrl: ${e.message}');
  } on http.ClientException catch (e) {
    throw _Afbreken('Verzoek naar $supabaseUrl brak af: ${e.message}');
  } on TimeoutException {
    throw _Afbreken('$supabaseUrl antwoordde niet binnen 15 seconden.');
  }

  String? bericht;
  if (response.statusCode != 201) {
    try {
      final gedecodeerd = jsonDecode(response.body);
      if (gedecodeerd is Map && gedecodeerd['message'] is String) {
        bericht = gedecodeerd['message'] as String;
      }
    } on FormatException {
      // Geen JSON-body: het volledige body wordt elders afgedrukt.
    }
  }
  return _Uitkomst(response.statusCode, bericht, response.body);
}

String _nieuweUuid() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

Map<String, dynamic> _feedbackRij({String? deviceId}) => {
      'rating': 5,
      'comment': _feedbackMarker,
      if (deviceId != null) 'device_id': deviceId,
    };

Map<String, dynamic> _gebeurtenisRij() => {
      'id': _nieuweUuid(),
      'device_id': _nieuweUuid(),
      'name': _eventName,
      'platform': 'web',
      'app_version': 'probe',
      'occurred_at': DateTime.now().toUtc().toIso8601String(),
    };

Future<void> main(List<String> args) async {
  try {
    if (args.contains('--verify-open')) {
      await _controleerOpen();
    } else {
      await _draaiBewijs();
    }
  } on _Afbreken catch (e) {
    stderr.writeln('');
    stderr.writeln('AFGEBROKEN: ${e.reden}');
    exitCode = 1;
  }
}

// ---------------------------------------------------------------------------
// --verify-open: de laatste controle uit het draaiboek, ná de opruim-SQL.
// ---------------------------------------------------------------------------

Future<void> _controleerOpen() async {
  stdout.writeln(
    'Eén probe-insert om te laten zien dat de grens weer open staat.',
  );
  final u = await _insert('feedback', _feedbackRij());
  if (u.aangenomen) {
    stdout.writeln('  aangenomen (201): de grens staat open. Ruim deze laatste');
    stdout.writeln('  rij op met dezelfde opruim-SQL als daarnet.');
    return;
  }
  stdout.writeln('  niet aangenomen (status ${u.status}):');
  stdout.writeln('  ${u.bericht ?? u.body}');
  stdout.writeln('  Bij een weigering staat de opruim-SQL er nog niet of niet');
  stdout.writeln('  volledig door: plak die eerst (README-rate-limit-probe.md).');
  exitCode = 1;
}

// ---------------------------------------------------------------------------
// Het volledige bewijs, in drie fasen.
// ---------------------------------------------------------------------------

Future<void> _draaiBewijs() async {
  stdout.writeln('Rate-limit-probe, ${DateTime.now().toIso8601String()}');
  stdout.writeln('Pad van de productiebuild: PostgREST met de publieke sleutel.');
  stdout.writeln('Schrijft gemarkeerde rijen; opruimen staat in de README.');
  stdout.writeln('');

  // Fase A — de vorm van build 70: geen device_id, precies wat de oude
  // builds bij testers sturen. Vult de afzendertelling tot het plafond.
  var faseAOntvangen = 0;
  var faseAGeweigerdBij = 0;
  String? faseABericht;
  stdout.writeln('Fase A — feedback in de vorm van build 70 (zonder device_id)');
  for (var i = 1; i <= _feedbackCeiling + _overshoot; i++) {
    final u = await _insert('feedback', _feedbackRij());
    if (u.aangenomen) {
      faseAOntvangen++;
      if (i % 10 == 0) stdout.writeln('  $i aangenomen (201)');
      continue;
    }
    if (u.geweigerd) {
      faseAGeweigerdBij = i;
      faseABericht = u.bericht;
      stdout.writeln('  insert $i geweigerd: ${u.bericht}');
      break;
    }
    throw _Afbreken(
      'insert $i: onverwachte status ${u.status}, volledige body: ${u.body}',
    );
  }
  if (faseAGeweigerdBij == 0) {
    throw _Afbreken(
      'Na ${_feedbackCeiling + _overshoot} feedback-inserts nog geen weigering: '
      '0016 staat vermoedelijk nog niet toegepast. De rijen zijn gemarkeerd en '
      'gaan weg met de opruim-SQL. Pas eerst 0016 toe en draai daarna opnieuw.',
    );
  }

  // Fase B — de aanvaller die de nieuwe vorm nabootst: per rij een vers
  // device_id. Als de afzendertelling klopt, helpt dat niets.
  stdout.writeln('');
  stdout.writeln('Fase B — zelfde insert, nu met een vers device_id');
  final b = await _insert('feedback', _feedbackRij(deviceId: _nieuweUuid()));
  String? faseBBericht;
  if (b.geweigerd) {
    faseBBericht = b.bericht;
    stdout.writeln('  geweigerd: ${b.bericht}');
  } else if (b.aangenomen) {
    stdout.writeln('  aangenomen (201) — dat had niet gemogen.');
  } else {
    throw _Afbreken(
      'vers device_id: onverwachte status ${b.status}, volledige body: ${b.body}',
    );
  }

  // Fase C — app_events in de aanvallersvorm: elke gebeurtenis een eigen
  // toestel. De afzender is het enige dat blijft tellen.
  var faseCOntvangen = 0;
  var faseCGeweigerdBij = 0;
  String? faseCBericht;
  stdout.writeln('');
  stdout.writeln('Fase C — app_events, per rij een vers device_id');
  for (var i = 1; i <= _appEventsCeiling + _overshoot; i++) {
    final u = await _insert('app_events', _gebeurtenisRij());
    if (u.aangenomen) {
      faseCOntvangen++;
      if (i % 20 == 0) stdout.writeln('  $i aangenomen (201)');
      continue;
    }
    if (u.geweigerd) {
      faseCGeweigerdBij = i;
      faseCBericht = u.bericht;
      stdout.writeln('  insert $i geweigerd: ${u.bericht}');
      break;
    }
    throw _Afbreken(
      'insert $i: onverwachte status ${u.status}, volledige body: ${u.body}',
    );
  }
  if (faseCGeweigerdBij == 0) {
    throw _Afbreken(
      'Na ${_appEventsCeiling + _overshoot} app_events-inserts nog geen '
      'weigering: er staat iets anders dan 0016 op de tabel, of het plafond '
      'is gewijzigd. Kijk in de SQL Editor naar de triggers op app_events.',
    );
  }

  stdout.writeln('');
  stdout.writeln('BEWIJS');
  _regel(
    'Publieke sleutel, vorm van build 70: aangenomen tot het plafond, erboven '
    'geweigerd (RATE-04)',
    faseABericht == 'rw_rate_limited:feedback:sender',
    'A: $faseAOntvangen aangenomen, insert $faseAGeweigerdBij geweigerd '
    '($faseABericht)',
  );
  _regel(
    'Ander device_id kiezen helpt niet (D-12)',
    faseBBericht == 'rw_rate_limited:feedback:sender',
    'B: vers device_id, geweigerd ($faseBBericht)',
  );
  _regel(
    'app_events valt onder dezelfde grenzen',
    faseCBericht == 'rw_rate_limited:app_events:sender',
    'C: $faseCOntvangen aangenomen, insert $faseCGeweigerdBij geweigerd '
    '($faseCBericht)',
  );
  if (faseAGeweigerdBij != _feedbackCeiling + 1 ||
      faseCGeweigerdBij != _appEventsCeiling + 1) {
    stdout.writeln('');
    stdout.writeln(
      'Let op: de weigering kwam vóór het plafond. Vandaag stond er al telling ',
    );
    stdout.writeln(
      'op dit IP (of de plafonds zijn gewijzigd ten opzichte van 0016).',
    );
  }

  stdout.writeln('');
  stdout.writeln('Opruimen: plak de SQL uit tool/README-rate-limit-probe.md in');
  stdout.writeln('de SQL Editor, en draai daarna:');
  stdout.writeln('  dart run tool/rate_limit_probe.dart --verify-open');
}

void _regel(String omschrijving, bool ok, String details) {
  stdout.writeln('  ${ok ? 'OK      ' : 'MISLUKT'}  $omschrijving');
  stdout.writeln('            $details');
  if (!ok) exitCode = 1;
}
