// Uploadt een release-AAB naar Google Play via de Play Developer API v3.
//
// Waarom dit bestaat: de AAB is ~66 MB en het uploadgereedschap van een
// Claude-sessie weigert alles boven 10 MB, terwijl een AAB niet te splitsen
// is. Elke release was daardoor handwerk in de Play Console. De Developer API
// kent die grens niet — hij uploadt resumable, in brokken.
//
// Eenmalige inrichting (twee stappen vragen Joosts hand): zie
// tool/README-play-release.md.
//
// Gebruik:
//   dart run tool/play_upload.dart --track internal
//   dart run tool/play_upload.dart --track internal --dry-run
//   dart run tool/play_upload.dart --track production --status draft \
//       --notes en-US:release-notes/en-US.txt --notes nl-NL:release-notes/nl-NL.txt

import 'dart:convert';
import 'dart:io';

import 'package:googleapis/androidpublisher/v3.dart' as play;
import 'package:googleapis_auth/auth_io.dart' as auth;

const _packageName = 'ridewindow.joost.amsterdam';
const _defaultAab = 'build/app/outputs/bundle/release/app-release.aab';

/// De sleutel hoort buiten de repo te staan, dus de standaardplek ligt in
/// `~/.config`. Er is geen pad binnen het project waar hij per ongeluk in een
/// commit kan belanden.
String get _defaultKeyPath {
  final home = Platform.environment['HOME'] ?? '.';
  return '$home/.config/ridewindow/play-service-account.json';
}

/// Play accepteert alleen deze vier; een typefout hier kost anders een
/// mislukte upload van 66 MB.
const _validStatuses = {'completed', 'draft', 'halted', 'inProgress'};

const _usage = '''
Uploadt een release-AAB naar Google Play.

  --track <naam>     Play-track. Standaard: internal
                     (internal | alpha | beta | production)
  --aab <pad>        Het bundelbestand. Standaard: $_defaultAab
  --key <pad>        Service-account-JSON. Standaard: \$PLAY_SERVICE_ACCOUNT_JSON,
                     anders ~/.config/ridewindow/play-service-account.json
  --status <status>  completed | draft | halted | inProgress. Standaard: completed
  --notes <l:pad>    Release-notes per taal, herhaalbaar.
                     Bijv. --notes nl-NL:release-notes/nl-NL.txt
                     Een pad zonder taalcode geldt als en-US.
  --force            Upload ook als de AAB niet bij de huidige broncode lijkt te horen.
  --dry-run          Controleert alles en logt in, maar schrijft niets naar Play.
  --help             Deze tekst.
''';

Future<void> main(List<String> args) async {
  // Dart negeert de retourwaarde van main, dus de exitcode gaat via exitCode.
  exitCode = await _run(args);
}

Future<int> _run(List<String> args) async {
  final Map<String, String> opts;
  final List<String> notesArgs;
  final Set<String> flags;
  try {
    (opts, notesArgs, flags) = _parseArgs(args);
  } on FormatException catch (e) {
    stderr.writeln('✗ ${e.message}\n\n$_usage');
    return 64; // EX_USAGE
  }

  if (flags.contains('help')) {
    stdout.write(_usage);
    return 0;
  }

  final track = opts['track'] ?? 'internal';
  final aabPath = opts['aab'] ?? _defaultAab;
  final keyPath = opts['key'] ??
      Platform.environment['PLAY_SERVICE_ACCOUNT_JSON'] ??
      _defaultKeyPath;
  final status = opts['status'] ?? 'completed';
  final dryRun = flags.contains('dry-run');

  if (!_validStatuses.contains(status)) {
    stderr.writeln('✗ Onbekende status "$status". '
        'Kies uit: ${_validStatuses.join(', ')}.');
    return 64;
  }

  final aab = File(aabPath);
  if (!aab.existsSync()) {
    stderr.writeln('✗ Geen AAB op $aabPath.\n'
        '  Bouw hem eerst: flutter build appbundle --release');
    return 66; // EX_NOINPUT
  }

  final version = _readPubspecVersion();
  if (version == null) {
    stderr.writeln('✗ Geen "version:" regel in pubspec.yaml gevonden.');
    return 65; // EX_DATAERR
  }

  // De echte valkuil is niet een ontbrekende AAB maar een oude: 66 MB uploaden
  // die de wijziging van vanmiddag niet bevat, en dat pas merken als een tester
  // klaagt. Twee controles, van scherp naar grof.
  final staleness = _checkStaleness(aab, version);
  if (staleness != null) {
    if (flags.contains('force')) {
      stdout.writeln('⚠ $staleness (genegeerd wegens --force)');
    } else {
      stderr.writeln('✗ $staleness\n'
          '  Bouw opnieuw met: flutter build appbundle --release\n'
          '  Of geef --force als je zeker weet dat deze AAB de juiste is.');
      return 65;
    }
  }

  // De in-app versie staat hard in lib/core/app_version.dart — dat is een
  // bewuste keuze (zie de kop van dat bestand), maar hij kan uit de pas lopen
  // met pubspec.yaml. `flutter test` vangt dat; dit script is de laatste poort
  // vóór Play, en een build die zichzelf "1.0.24 (25)" noemt terwijl Play hem
  // als 26 kent maakt elk testersrapport onbetrouwbaar.
  final displayed = _readDisplayedVersion();
  if (displayed != null && displayed != '${version.name} (${version.code})') {
    stderr.writeln('✗ De app toont zichzelf als "$displayed", maar pubspec.yaml '
        'zegt ${version.name} (${version.code}).\n'
        '  Werk lib/core/app_version.dart bij en bouw opnieuw.');
    return 65;
  }

  final releaseNotes = _readNotes(notesArgs);

  final sizeMb = (aab.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
  stdout.writeln('Ridewindow ${version.name} (${version.code})');
  stdout.writeln('  bundel  $aabPath  ($sizeMb MB)');
  stdout.writeln('  track   $track  ($status)');
  stdout.writeln('  notes   ${releaseNotes.isEmpty ? '—' : releaseNotes.map(
        (n) => n.language,
      ).join(', ')}');

  final key = File(keyPath);
  if (!key.existsSync()) {
    stderr.writeln('\n✗ Geen service-account-sleutel op $keyPath.\n'
        '  Zie tool/README-play-release.md — het is een eenmalige inrichting.');
    return 66;
  }

  final auth.ServiceAccountCredentials credentials;
  try {
    credentials = auth.ServiceAccountCredentials.fromJson(
      jsonDecode(key.readAsStringSync()) as Map<String, dynamic>,
    );
  } on FormatException catch (e) {
    stderr.writeln('\n✗ $keyPath is geen geldige service-account-JSON: ${e.message}');
    return 65;
  }

  final client = await auth.clientViaServiceAccount(
    credentials,
    [play.AndroidPublisherApi.androidpublisherScope],
  );

  try {
    stdout.writeln('\n✓ Ingelogd als ${credentials.email}');

    if (dryRun) {
      stdout.writeln('\n— dry-run: alles staat klaar, er is niets naar Play '
          'geschreven.');
      return 0;
    }

    final api = play.AndroidPublisherApi(client);
    return await _publish(
      api,
      aab: aab,
      track: track,
      status: status,
      releaseNotes: releaseNotes,
      version: version,
    );
  } finally {
    client.close();
  }
}

/// De edit-cyclus: insert → upload → track → commit. Alles binnen één edit;
/// mislukt er iets halverwege, dan wordt de edit weggegooid zodat er geen
/// halve release in de console blijft hangen.
Future<int> _publish(
  play.AndroidPublisherApi api, {
  required File aab,
  required String track,
  required String status,
  required List<play.LocalizedText> releaseNotes,
  required _Version version,
}) async {
  final edit = await api.edits.insert(play.AppEdit(), _packageName);
  final editId = edit.id!;
  stdout.writeln('✓ Edit $editId geopend');

  try {
    // Resumable, want een simple upload duwt 66 MB in één request. De brokken
    // moeten een veelvoud van 256 KB zijn.
    final bundle = await api.edits.bundles.upload(
      _packageName,
      editId,
      uploadMedia: play.Media(aab.openRead(), aab.lengthSync()),
      uploadOptions: play.ResumableUploadOptions(chunkSize: 8 * 1024 * 1024),
    );
    final uploaded = bundle.versionCode;
    stdout.writeln('✓ Bundel geüpload — versionCode $uploaded');

    if (uploaded != version.code) {
      // Play leest de versionCode uit de bundel zelf. Wijkt die af van
      // pubspec.yaml, dan is er een andere AAB verstuurd dan bedoeld.
      throw StateError(
        'De geüploade bundel heeft versionCode $uploaded, '
        'pubspec.yaml zegt ${version.code}.',
      );
    }

    await api.edits.tracks.update(
      play.Track(
        track: track,
        releases: [
          play.TrackRelease(
            name: '${version.name} (${version.code})',
            versionCodes: ['$uploaded'],
            status: status,
            releaseNotes: releaseNotes.isEmpty ? null : releaseNotes,
          ),
        ],
      ),
      _packageName,
      editId,
      track,
    );
    stdout.writeln('✓ Track "$track" bijgewerkt');

    await api.edits.commit(_packageName, editId);
    stdout.writeln('✓ Edit doorgevoerd\n');
    stdout.writeln('${version.name} (${version.code}) staat op $track.');
    return 0;
  } catch (e) {
    stderr.writeln('\n✗ Mislukt: $e');
    try {
      await api.edits.delete(_packageName, editId);
      stderr.writeln('  Edit $editId is opgeruimd.');
    } catch (_) {
      stderr.writeln('  Let op: edit $editId kon niet worden opgeruimd. '
          'Verlopen edits ruimt Play zelf op.');
    }
    return 70; // EX_SOFTWARE
  }
}

typedef _Version = ({String name, int code});

/// Geeft een uitleg terug als de AAB niet bij de huidige broncode hoort, of
/// null als hij in orde lijkt.
///
/// De scherpe controle leest de versionCode die Gradle in de gebouwde bundel
/// heeft gezet — die is exact, en hij kost niets omdat AGP het gemergede
/// manifest naast de build laat staan. Ontbreekt dat pad (schone checkout,
/// andere AGP-versie), dan valt hij terug op tijdstempels van wat er
/// daadwerkelijk in de bundel terechtkomt: lib/ en assets/. pubspec.yaml telt
/// bewust niet mee — een dev-dependency erbij maakt een prima build niet oud.
String? _checkStaleness(File aab, _Version version) {
  final manifests = Directory('build/app/intermediates/packaged_manifests')
      .existsSync()
      ? Directory('build/app/intermediates/packaged_manifests')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('AndroidManifest.xml'))
      : const <File>[];

  for (final manifest in manifests) {
    final code = RegExp(r'android:versionCode="(\d+)"')
        .firstMatch(manifest.readAsStringSync())
        ?.group(1);
    if (code == null) continue;
    if (int.parse(code) != version.code) {
      return 'De gebouwde bundel draagt versionCode $code, '
          'pubspec.yaml zegt ${version.code}.';
    }
    return null; // Exact bewijs dat de build actueel is; verder kijken hoeft niet.
  }

  final builtAt = aab.lastModifiedSync();
  for (final dir in ['lib', 'assets']) {
    final root = Directory(dir);
    if (!root.existsSync()) continue;
    for (final entity in root.listSync(recursive: true).whereType<File>()) {
      if (entity.lastModifiedSync().isAfter(builtAt)) {
        return 'De AAB is van $builtAt, maar ${entity.path} is daarna gewijzigd.';
      }
    }
  }
  return null;
}

/// `version: 1.0.25+26` → name 1.0.25, code 26.
_Version? _readPubspecVersion() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) return null;
  for (final line in pubspec.readAsLinesSync()) {
    final match = RegExp(r'^version:\s*(\S+)\+(\d+)\s*$').firstMatch(line);
    if (match != null) {
      return (name: match.group(1)!, code: int.parse(match.group(2)!));
    }
  }
  return null;
}

/// Wat het profielscherm toont, uit `lib/core/app_version.dart`, of null als
/// dat bestand er niet is of anders is opgebouwd dan verwacht.
String? _readDisplayedVersion() {
  final file = File('lib/core/app_version.dart');
  if (!file.existsSync()) return null;
  final source = file.readAsStringSync();
  final name = RegExp(r"kAppVersionName = '([^']+)'").firstMatch(source);
  final build = RegExp(r"kAppBuildNumber = '([^']+)'").firstMatch(source);
  if (name == null || build == null) return null;
  return '${name.group(1)} (${build.group(1)})';
}

List<play.LocalizedText> _readNotes(List<String> specs) {
  final notes = <play.LocalizedText>[];
  for (final spec in specs) {
    // Een taalcode bevat geen "/", een pad kan wel een ":" bevatten — dus
    // splitsen op de eerste ":" en alleen als het linkerdeel op een taalcode lijkt.
    final colon = spec.indexOf(':');
    final looksTagged =
        colon > 0 && RegExp(r'^[a-z]{2}(-[A-Z]{2})?$').hasMatch(spec.substring(0, colon));
    final language = looksTagged ? spec.substring(0, colon) : 'en-US';
    final path = looksTagged ? spec.substring(colon + 1) : spec;

    final file = File(path);
    if (!file.existsSync()) {
      throw FormatException('Geen release-notes op $path.');
    }
    final text = file.readAsStringSync().trim();
    if (text.length > 500) {
      // Play kapt af op 500 tekens; liever hier stoppen dan een halve zin op de
      // winkelpagina.
      throw FormatException(
        'Release-notes voor $language zijn ${text.length} tekens; '
        'Play staat er 500 toe.',
      );
    }
    notes.add(play.LocalizedText(language: language, text: text));
  }
  return notes;
}

(Map<String, String>, List<String>, Set<String>) _parseArgs(List<String> args) {
  final opts = <String, String>{};
  final notes = <String>[];
  final flags = <String>{};
  const valueOptions = {'track', 'aab', 'key', 'status'};
  const boolFlags = {'help', 'dry-run', 'force'};

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (!arg.startsWith('--')) {
      throw FormatException('Onverwacht argument "$arg".');
    }
    final name = arg.substring(2);
    if (boolFlags.contains(name)) {
      flags.add(name);
    } else if (name == 'notes') {
      if (++i >= args.length) throw const FormatException('--notes mist een waarde.');
      notes.add(args[i]);
    } else if (valueOptions.contains(name)) {
      if (++i >= args.length) throw FormatException('--$name mist een waarde.');
      opts[name] = args[i];
    } else {
      throw FormatException('Onbekende optie "$arg".');
    }
  }
  return (opts, notes, flags);
}
